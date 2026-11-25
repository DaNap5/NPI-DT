import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:npi/events/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.showBookmarks = false,
    this.isSaving = false,
    this.onBookmark,
  });
  final Event event;
  final bool showBookmarks;
  final bool isSaving;
  final VoidCallback? onBookmark;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,

      /// Ensures that the content of the card is clipped to its rounded corners.
      child: InkWell(
        onTap: null,

        /// Calls the onTap callback when the card is tapped.
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          event.category.name,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  if (showBookmarks)
                    isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            tooltip: 'Guardar evento',
                            onPressed: onBookmark,
                          ),
                ],
              ),
              const SizedBox(height: 12),
              Text(event.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(event.location)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(_formatDate(event.date)),
                ],
              ),
              if (event.url != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final uri = event.url!;

                      try {
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );

                        if (!launched) {
                          debugPrint('No se pudo abrir la URL: $uri');
                        }
                      } catch (e) {
                        debugPrint('Error al abrir la URL: $e');
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Más información'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year · $hour:$minute';
  }
}
