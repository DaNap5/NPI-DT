import asyncio
import json
import time
import websockets

LEAP_URI = "ws://127.0.0.1:6437/v6.json"
SERVER_HOST = "0.0.0.0"
SERVER_PORT = 8765

# Parametri di taratura (modificabili durante i test)
SWIPE_COOLDOWN = 0.75      # Secondi di pausa tra due swipe
PINCH_COOLDOWN = 0.80      # Secondi di pausa tra due pinch
POSE_HOLD_TIME = 0.45      # Secondi di mantenimento per mano aperta / pugno chiuso
SMOOTHING_ALPHA = 0.35     # 0.0 - 1.0 (più basso = movimento più fluido, più alto = più reattivo)

connected_clients = set()


def clamp(val: float, min_val: float = 0.0, max_val: float = 1.0) -> float:
    return max(min_val, min(max_val, val))


async def broadcast(payload: dict):
    if not connected_clients:
        return
    message = json.dumps(payload)
    await asyncio.gather(
        *(client.send(message) for client in list(connected_clients)),
        return_exceptions=True,
    )


async def flutter_client_handler(websocket):
    connected_clients.add(websocket)
    print(f"[Flutter] Client connesso ({len(connected_clients)} attivi)")
    try:
        # Invia stato iniziale pulito appena Flutter si connette
        await websocket.send(json.dumps({
            "type": "tracking",
            "handDetected": False,
            "x": 0.5,
            "y": 0.5,
            "progress": 0.0,
        }))
        await websocket.wait_closed()
    finally:
        connected_clients.discard(websocket)
        print(f"[Flutter] Client disconnesso ({len(connected_clients)} attivi)")


async def leap_reader_loop():
    last_swipe_time = 0.0
    last_pinch_time = 0.0

    # Stato per il riconoscimento pose (openHand / closedFist)
    current_pose = None
    pose_start_time = 0.0
    pose_triggered = False

    # Coordinate smoothed
    smooth_x = 0.5
    smooth_y = 0.5
    was_hand_detected = False

    while True:
        try:
            async with websockets.connect(LEAP_URI) as leap_ws:
                print("[Leap Motion] Connesso a v6.json (SDK v2.3.1)")
                await leap_ws.send(json.dumps({"enableGestures": True}))
                await leap_ws.send(json.dumps({"background": True}))

                async for raw_msg in leap_ws:
                    frame = json.loads(raw_msg)
                    now = time.time()

                    # Ignora messaggi di stato iniziale (version/serviceVersion)
                    if "hands" not in frame:
                        continue

                    hands = frame.get("hands", [])
                    gestures = frame.get("gestures", [])
                    ibox = frame.get("interactionBox", {})

                    # 1. Gestione assenza mano
                    if not hands:
                        current_pose = None
                        pose_triggered = False
                        if was_hand_detected:
                            was_hand_detected = False
                            await broadcast({
                                "type": "tracking",
                                "handDetected": False,
                                "x": round(smooth_x, 3),
                                "y": round(smooth_y, 3),
                                "progress": 0.0,
                            })
                        continue

                    was_hand_detected = True
                    hand = hands[0]  # Mano principale

                    # 2. Normalizzazione coordinate (0.0 - 1.0) rispetto all'InteractionBox
                    palm = hand.get("palmPosition", [0.0, 200.0, 0.0])
                    center = ibox.get("center", [0.0, 200.0, 0.0])
                    size = ibox.get("size", [235.0, 235.0, 147.0])

                    raw_x = (palm[0] - center[0]) / max(size[0], 1.0) + 0.5
                    raw_y = 1.0 - ((palm[1] - center[1]) / max(size[1], 1.0) + 0.5)

                    smooth_x = SMOOTHING_ALPHA * clamp(raw_x) + (1 - SMOOTHING_ALPHA) * smooth_x
                    smooth_y = SMOOTHING_ALPHA * clamp(raw_y) + (1 - SMOOTHING_ALPHA) * smooth_y

                    # 3. Riconoscimento Swipe nativi Leap v2 (prioritario rispetto alle pose statiche)
                    swipe_detected = False
                    for g in gestures:
                        if g.get("type") == "swipe" and g.get("state") == "stop":
                            if (now - last_swipe_time) < SWIPE_COOLDOWN:
                                continue

                            dx, dy, _ = g.get("direction", [0.0, 0.0, 0.0])
                            last_swipe_time = now
                            swipe_detected = True

                            # Azzera eventuali pose in corso per evitare falsi positivi
                            current_pose = None
                            pose_triggered = False

                            if abs(dx) >= abs(dy):
                                gesture_name = "swipeRight" if dx > 0 else "swipeLeft"
                            else:
                                gesture_name = "swipeUp" if dy > 0 else "swipeDown"

                            print(f"[Gesto] {gesture_name}")
                            await broadcast({
                                "type": "gesture",
                                "gesture": gesture_name,
                            })
                            break

                    # 4. Riconoscimento Pinch rapido (solo se la mano non è chiusa a pugno)
                    grab = hand.get("grabStrength", 0.5)
                    pinch = hand.get("pinchStrength", 0.0)

                    if not swipe_detected and pinch >= 0.88 and grab < 0.65 and (now - last_pinch_time) >= PINCH_COOLDOWN:
                        last_pinch_time = now
                        current_pose = None
                        pose_triggered = False
                        print("[Gesto] pinch")
                        await broadcast({
                            "type": "gesture",
                            "gesture": "pinch",
                        })

                    # 5. Riconoscimento Pose (Mano Aperta / Pugno Chiuso) con Dwell Time
                    detected_pose = None
                    if not swipe_detected:
                        if grab >= 0.85:
                            detected_pose = "closedFist"
                        elif grab <= 0.12 and pinch < 0.3:
                            detected_pose = "openHand"

                    progress = 0.0
                    if detected_pose != current_pose:
                        current_pose = detected_pose
                        pose_start_time = now
                        pose_triggered = False
                    elif current_pose is not None and not pose_triggered:
                        elapsed = now - pose_start_time
                        progress = clamp(elapsed / POSE_HOLD_TIME)
                        if elapsed >= POSE_HOLD_TIME:
                            pose_triggered = True
                            print(f"[Gesto] {current_pose}")
                            await broadcast({
                                "type": "gesture",
                                "gesture": current_pose,
                            })

                    # 6. Invia aggiornamento continuo di tracking per HUD / cursore / inclinazione schede
                    await broadcast({
                        "type": "tracking",
                        "handDetected": True,
                        "x": round(smooth_x, 3),
                        "y": round(smooth_y, 3),
                        "progress": round(progress, 2),
                    })

        except (OSError, websockets.WebSocketException) as e:
            print(f"[Leap Motion] In attesa del servizio Leap Motion ({e})... Riprovo tra 2s")
            await asyncio.sleep(2)


async def main():
    print(f"Avvio server gestuale su ws://{SERVER_HOST}:{SERVER_PORT} ...")
    async with websockets.serve(flutter_client_handler, SERVER_HOST, SERVER_PORT):
        await leap_reader_loop()


if __name__ == "__main__":
    asyncio.run(main())