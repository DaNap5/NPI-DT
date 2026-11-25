import 'package:flutter/foundation.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';

import 'event.dart';
import 'event_catalog.dart';
import 'event_ordering.dart';

class EventsViewModel extends ChangeNotifier {
  EventsViewModel({
    required this.session,
    required this.store,
    required this.catalog,
    this.discardedOnly = false,
  }) {
    session.addListener(loadEvents);
  }
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  final bool discardedOnly;
  List<Event> _events = [];
  List<Event> get events => List.unmodifiable(_events);
  bool isLoading = false;
  bool isMutating = false;
  String? error;
  bool _disposed = false;
  int _request = 0;
  bool get isLoggedIn => session.isSignedIn;

  Future<void> loadEvents() async {
    final request = ++_request;
    final username = session.username;
    final owner = username ?? LocalStore.guestEventOwner;
    isLoading = true;
    error = null;
    _events = [];
    notifyListeners();
    try {
      final all = await catalog.loadEvents();
      if (_disposed || request != _request || session.username != username) {
        return;
      }
      final discarded = store.readDiscardedEventIds(owner).toSet();
      final saved = store.readSavedEventIds(owner).toSet();
      final selected = all.where(
        (event) =>
            event.date.isAfter(DateTime.now()) &&
            (discardedOnly
                ? discarded.contains(event.id)
                : !discarded.contains(event.id) && !saved.contains(event.id)),
      );
      final sorted = orderEvents(
        selected,
        store.readPreferredCategories(owner),
      );
      _events = discardedOnly ? sorted : sorted.reversed.toList();
    } catch (_) {
      if (!_disposed && request == _request) {
        error = 'No se pudieron cargar los eventos.';
      }
    } finally {
      if (!_disposed && request == _request) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _mutate(Future<void> Function(String owner) action) async {
    if (isMutating || _disposed) return;
    final owner = session.username ?? LocalStore.guestEventOwner;
    isMutating = true;
    error = null;
    notifyListeners();
    try {
      await action(owner);
      if (!_disposed) await loadEvents();
    } catch (_) {
      if (!_disposed) {
        error = 'No se pudo guardar el cambio. Inténtalo de nuevo.';
      }
      rethrow;
    } finally {
      isMutating = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> saveEvent(Event event) async {
    // Guest swipes remove the card for this visit without creating a saved event.
    if (!session.isSignedIn) {
      _events.removeWhere((item) => item.id == event.id);
      notifyListeners();
      return;
    }
    await _mutate((owner) => store.saveEvent(owner, event.id));
  }

  Future<void> discardEvent(Event event) =>
      _mutate((owner) => store.discardEvent(owner, event.id));
  Future<void> saveCurrentEvent() async {
    if (_events.isNotEmpty) await saveEvent(_events.last);
  }

  Future<void> discardCurrentEvent() async {
    if (_events.isNotEmpty) await discardEvent(_events.last);
  }

  Future<void> resetEvents() async {
    if (!session.isSignedIn) return;
    await _mutate(store.resetEvents);
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    session.removeListener(loadEvents);
    super.dispose();
  }
}
