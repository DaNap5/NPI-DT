import 'package:flutter/foundation.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:npi/events/event.dart';

import 'schedule_item.dart';
import 'sample_schedule.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this.session,
    required this.store,
    required this.catalog,
  }) {
    session.addListener(loadSchedule);
  }
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  bool _disposed = false;
  int _request = 0;
  bool get isRegistered => session.isSignedIn;
  String? get username => session.username;
  String _selectedDay = 'M';
  String get selectedDay => _selectedDay;
  bool isLoading = false;
  String? error;
  List<Event> _userEvents = [];
  List<ScheduleItem> get items => getItemsForDay(selectedDay);

  void selectDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> loadSchedule() async {
    final request = ++_request;
    final owner = username;
    isLoading = true;
    error = null;
    _userEvents = [];
    notifyListeners();
    try {
      if (owner != null) {
        final ids = store.readSavedEventIds(owner).take(4).toList();
        final all = ids.isEmpty ? <Event>[] : await catalog.loadEvents();
        if (_disposed || request != _request || username != owner) return;
        _userEvents = [
          for (final id in ids) ...all.where((event) => event.id == id),
        ];
      }
    } catch (_) {
      if (!_disposed && request == _request) {
        error = 'No se pudo cargar el horario.';
      }
    } finally {
      if (!_disposed && request == _request) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> logout() async {
    try {
      await session.signOut();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeUserEvent(String id) async {
    final owner = username;
    if (owner == null || !_userEvents.any((event) => event.id == id)) {
      return false;
    }
    try {
      await store.removeSavedEvent(owner, id);
      await loadSchedule();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<ScheduleItem> getItemsForDay(String day) => !isRegistered
      ? sampleEventsForDay(day)
      : [...sampleClassesForDay(day), ..._getUserEventsForDay(day)];

  List<ScheduleItem> _getUserEventsForDay(String day) {
    final List<Event> selectedEvents = [];

    switch (day) {
      case 'L':
        if (_userEvents.isNotEmpty) selectedEvents.add(_userEvents[0]);
        break;
      case 'X':
        if (_userEvents.length > 1) selectedEvents.add(_userEvents[1]);
        if (_userEvents.length > 2) selectedEvents.add(_userEvents[2]);
        break;
      case 'J':
        if (_userEvents.length > 3) selectedEvents.add(_userEvents[3]);
        break;
    }

    return selectedEvents.map(_mapEventToScheduleItem).toList();
  }

  ScheduleItem _mapEventToScheduleItem(Event event) {
    final hour = event.date.hour.toString().padLeft(2, '0');
    final minute = event.date.minute.toString().padLeft(2, '0');
    final day = event.date.day.toString().padLeft(2, '0');
    final month = event.date.month.toString().padLeft(2, '0');

    return ScheduleItem(
      id: event.id,
      time: '$hour:$minute',
      title: '${event.emoji} ${event.title}',
      subtitle: '${event.location} ($day/$month)',
      location: ScheduleItem.facultyEntranceLocation,
      isEvent: true,
      isSavedEvent: true,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    session.removeListener(loadSchedule);
    super.dispose();
  }
}
