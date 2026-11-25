// Domain model of events
enum EventCategory {
  technology,
  sports,
  music,
  culture,
  education,
  socialevents,
  other;

  String get label {
    return name;
  }

  String get emoji {
    switch (this) {
      case EventCategory.technology:
        return '💻';
      case EventCategory.sports:
        return '⚽';
      case EventCategory.music:
        return '🎵';
      case EventCategory.culture:
        return '🎨';
      case EventCategory.education:
        return '📚';
      case EventCategory.socialevents:
        return '🤝';
      case EventCategory.other:
        return '📌';
    }
  }
}

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.emoji,
    required this.category,
    required this.description,
    required this.location,
    required this.date,
    this.url,
  });

  final String id;
  final String title;
  final String emoji;
  final EventCategory category;
  final String description;
  final String location;
  final DateTime date;
  final Uri? url;

  factory Event.fromCsvRow(List<dynamic> row) {
    return Event(
      id: row[0].toString(),
      title: row[1].toString(),
      emoji: row[2].toString(),
      category: EventCategory.values.firstWhere(
        (e) => e.name == row[3].toString(),
        orElse: () => EventCategory.technology,
      ),
      description: row[4].toString(),
      location: row[5].toString(),
      date: DateTime.parse(row[6].toString()),
      url: row[7] != null && row[7].toString().isNotEmpty
          ? Uri.parse(row[7].toString())
          : null,
    );
  }
  @override
  String toString() {
    return 'Event(id: $id, title: $title, emoji: $emoji, category: $category, description: $description, location: $location, date: $date, url: $url)';
  }
}
