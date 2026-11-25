import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Returns the first nonblank QR text, or null when the user goes back.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );
  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted || _hasResult) return;

    for (final barcode in capture.barcodes) {
      final text = barcode.rawValue?.trim();
      if (text == null || text.isEmpty) continue;

      _hasResult = true;
      unawaited(_controller.stop());
      Navigator.of(context).pop(text);
      return;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasResult || !_controller.value.hasCameraPermission) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.start());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Escanear QR'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) => IconButton(
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanAreaSize = constraints.maxWidth * 0.7;
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: scanAreaSize,
            height: scanAreaSize,
          );

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                onDetect: _onDetect,
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ScannerOverlayPainter(scanWindow: scanWindow),
              ),
              Positioned(
                top: scanWindow.bottom + 24,
                left: 0,
                right: 0,
                child: const Text(
                  'Coloca el código QR dentro del recuadro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  _ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 28.0;
    const double radius = 16.0;

    final path = Path();

    // Esquina superior izquierda
    path.moveTo(scanWindow.left, scanWindow.top + cornerLength);
    path.lineTo(scanWindow.left, scanWindow.top + radius);
    path.arcToPoint(
      Offset(scanWindow.left + radius, scanWindow.top),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanWindow.left + cornerLength, scanWindow.top);

    // Esquina superior derecha
    path.moveTo(scanWindow.right - cornerLength, scanWindow.top);
    path.lineTo(scanWindow.right - radius, scanWindow.top);
    path.arcToPoint(
      Offset(scanWindow.right, scanWindow.top + radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanWindow.right, scanWindow.top + cornerLength);

    // Esquina inferior derecha
    path.moveTo(scanWindow.right, scanWindow.bottom - cornerLength);
    path.lineTo(scanWindow.right, scanWindow.bottom - radius);
    path.arcToPoint(
      Offset(scanWindow.right - radius, scanWindow.bottom),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanWindow.right - cornerLength, scanWindow.bottom);

    // Esquina inferior izquierda
    path.moveTo(scanWindow.left + cornerLength, scanWindow.bottom);
    path.lineTo(scanWindow.left + radius, scanWindow.bottom);
    path.arcToPoint(
      Offset(scanWindow.left, scanWindow.bottom - radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanWindow.left, scanWindow.bottom - cornerLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
