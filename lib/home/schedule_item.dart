enum ScheduleEventCategory { music, gaming, educational, other }

class ScheduleItem {
  static const facultyEntranceLocation = 'Entrada principal';

  final String id;
  final String time;
  final String title;
  final String subtitle;
  final String? location;
  final bool isEvent;
  final bool isSavedEvent;
  final ScheduleEventCategory category;

  const ScheduleItem({
    required this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    this.location,
    this.isEvent = false,
    this.isSavedEvent = false,
    this.category = ScheduleEventCategory.other,
  });
}
