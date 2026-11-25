import 'package:npi/home/schedule_item.dart';
import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final bool isDetailView;
  final ValueChanged<ScheduleItem>? onTap;
  final ValueChanged<ScheduleItem>? onDelete;

  const ScheduleCard({
    super.key,
    required this.item,
    this.isDetailView = false,
    this.onTap,
    this.onDelete,
  });

  IconData _getEventIcon(ScheduleItem item) {
    switch (item.category) {
      case ScheduleEventCategory.music:
        return Icons.music_note;
      case ScheduleEventCategory.gaming:
        return Icons.sports_esports;
      case ScheduleEventCategory.educational:
        return Icons.menu_book;
      case ScheduleEventCategory.other:
        final text = '${item.title} ${item.subtitle}'.toLowerCase();
        if (text.contains('música') ||
            text.contains('musica') ||
            text.contains('concierto')) {
          return Icons.music_note;
        }
        if (text.contains('gaming') ||
            text.contains('torneo') ||
            text.contains('juego') ||
            text.contains('ajedrez')) {
          return Icons.sports_esports;
        }
        if (text.contains('taller') ||
            text.contains('conferencia') ||
            text.contains('charla') ||
            text.contains('curso') ||
            text.contains('libro')) {
          return Icons.menu_book;
        }
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = item.isEvent ? Colors.purple : Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.shade200),
          ),
          child: InkWell(
            onTap: isDetailView && onTap != null ? () => onTap!(item) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isEvent) ...[
                        Icon(
                          _getEventIcon(item),
                          color: color.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color.shade900,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: color.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Eliminar evento ${item.title}',
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red.shade700,
                          onPressed: () => onDelete!(item),
                        ),
                      ],
                    ],
                  ),
                  if (isDetailView) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: 16,
                          color: color.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.isEvent
                              ? 'Ubicación: ${item.location ?? item.subtitle}'
                              : 'Aula/Estructura Auxiliar ETSIIT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
