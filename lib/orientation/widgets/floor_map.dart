import 'package:flutter/material.dart';
import 'package:npi/orientation/map_zone.dart';

// All supplied floor renders have the same 1024 × 768 canvas.
Rect floorImageRect(Size viewport) {
  const source = Size(1024, 768);
  final fitted = applyBoxFit(BoxFit.contain, source, viewport);
  return Alignment.center.inscribe(fitted.destination, Offset.zero & viewport);
}

Offset projectMapPoint(Rect imageRect, Offset point) => Offset(
  imageRect.left + point.dx * imageRect.width,
  imageRect.top + point.dy * imageRect.height,
);

class FloorMap extends StatelessWidget {
  const FloorMap({
    super.key,
    required this.asset,
    required this.label,
    required this.zones,
    this.onZoneTap,
    this.onPolygonTap,
    this.selectedZoneId,
  });
  final String asset;
  final String label;
  final List<MapZone> zones;
  final ValueChanged<MapZone>? onZoneTap;
  final ValueChanged<MapZone>? onPolygonTap;
  final String? selectedZoneId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rect = floorImageRect(constraints.biggest);
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onPolygonTap == null
                ? null
                : (details) {
                    for (final zone in zones.reversed) {
                      if (zonePath(
                        zone,
                        rect,
                      ).contains(details.localPosition)) {
                        onPolygonTap!(zone);
                        break;
                      }
                    }
                  },
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              semanticLabel: label,
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: ZonePainter(zones, rect, selectedZoneId: selectedZoneId),
            ),
          ),
          for (final zone in zones)
            Positioned(
              left: projectMapPoint(rect, zone.marker).dx - 24,
              top: projectMapPoint(rect, zone.marker).dy - 24,
              child: Semantics(
                label: '${zone.number}. ${zone.name}',
                button: onZoneTap != null,
                selected: zone.id == selectedZoneId,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onZoneTap == null ? null : () => onZoneTap!(zone),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        key: ValueKey('zone-marker-${zone.id}'),
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: zone.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${zone.number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Even-odd fill leaves interior contours transparent, regardless of winding.
Path zonePath(MapZone zone, Rect imageRect) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final contour in [...zone.polygons, ...zone.holes]) {
    if (contour.length < 3) continue;
    path.addPolygon(
      contour.map((p) => projectMapPoint(imageRect, p)).toList(),
      true,
    );
  }
  return path;
}

class ZonePainter extends CustomPainter {
  ZonePainter(this.zones, this.imageRect, {this.selectedZoneId});
  final String? selectedZoneId;
  final List<MapZone> zones;
  final Rect imageRect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(imageRect);
    for (final zone in zones) {
      final path = zonePath(zone, imageRect);
      canvas.drawPath(
        path,
        Paint()
          ..color = zone.color.withValues(
            alpha: zone.id == selectedZoneId ? .4 : .25,
          ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = zone.color.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = zone.id == selectedZoneId ? 2 : 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZonePainter oldDelegate) =>
      oldDelegate.zones != zones ||
      oldDelegate.imageRect != imageRect ||
      oldDelegate.selectedZoneId != selectedZoneId;
}
