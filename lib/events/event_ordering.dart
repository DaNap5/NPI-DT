import 'event.dart';

List<Event> orderEvents(Iterable<Event> events, List<String> preferences) {
  const aliases = {
    'tecnologia': 'technology',
    'deportes': 'sports',
    'deporte': 'sports',
    'musica': 'music',
    'cultura': 'culture',
    'educacion': 'education',
    'eventos sociales': 'socialevents',
    'eventos_sociales': 'socialevents',
    'otros': 'other',
  };
  final categories = preferences
      .map((value) {
        final normalized = value.trim().toLowerCase();
        return aliases[normalized] ?? normalized;
      })
      .toSet()
      .toList();
  final sorted = events.toList();
  int rank(Event event) {
    final index = categories.indexOf(event.category.name.toLowerCase());
    return index < 0 ? categories.length : index;
  }

  sorted.sort((a, b) {
    final category = rank(a).compareTo(rank(b));
    return category != 0 ? category : a.date.compareTo(b.date);
  });
  return sorted;
}
