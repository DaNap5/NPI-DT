import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'event.dart';

class EventCatalog {
  EventCatalog({Future<String> Function()? readCsv})
    : _readCsv =
          readCsv ??
          (() => rootBundle.loadString('assets/expanded_events.csv'));
  final Future<String> Function() _readCsv;
  Future<List<Event>>? _loading;
  List<Event>? _cached;

  Future<List<Event>> loadEvents() {
    if (_cached != null) return Future.value(_cached);
    return _loading ??= _load();
  }

  Future<List<Event>> _load() async {
    try {
      final rows = Csv().decode(await _readCsv());
      final events = rows.skip(1).map(Event.fromCsvRow).toList();
      return _cached = List.unmodifiable(events);
    } finally {
      _loading = null;
    }
  }
}
