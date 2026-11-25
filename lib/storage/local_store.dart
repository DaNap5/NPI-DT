import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._preferences);
  final SharedPreferences _preferences;
  Future<void>? _pending;
  static const guestEventOwner = '__unregistered__';

  Future<void> _mutate(Future<void> Function() action) {
    final operation = (_pending ?? Future<void>.value()).then((_) => action());
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _check(Future<bool> operation) async {
    if (!await operation) throw StateError('Local data could not be saved.');
  }

  String? readUsername() {
    final value = _preferences.getString('user_session')?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveUsername(String username) => _mutate(() async {
    if (username.trim().isEmpty) {
      throw ArgumentError.value(username, 'username');
    }
    await _check(_preferences.setString('user_session', username.trim()));
    await _check(_preferences.remove('guest_session'));
  });

  Future<void> saveGuestSession() => _mutate(() async {
    await _check(_preferences.remove('user_session'));
    await _check(_preferences.setBool('guest_session', true));
  });

  Future<void> clearSession() => _mutate(() async {
    await _check(_preferences.remove('user_session'));
    await _check(_preferences.remove('guest_session'));
  });

  Map<String, List<String>> _readEvents(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (owner, ids) =>
          MapEntry(owner, (ids as List).cast<String>().toSet().toList()),
    );
  }

  List<String> readSavedEventIds(String username) =>
      List.unmodifiable(_readEvents('user_events')[username] ?? <String>[]);
  List<String> readDiscardedEventIds(String username) => List.unmodifiable(
    _readEvents('discarded_events')[username] ?? <String>[],
  );

  Future<void> _changeEvents(
    String username,
    void Function(Set<String>, Set<String>) change,
  ) => _mutate(() async {
    final saved = _readEvents('user_events');
    final discarded = _readEvents('discarded_events');
    final savedIds = (saved[username] ?? <String>[]).toSet();
    final discardedIds = (discarded[username] ?? <String>[]).toSet();
    change(savedIds, discardedIds);
    saved[username] = savedIds.toList();
    discarded[username] = discardedIds.toList();
    await _check(_preferences.setString('user_events', jsonEncode(saved)));
    await _check(
      _preferences.setString('discarded_events', jsonEncode(discarded)),
    );
  });

  Future<void> saveEvent(String username, String id) =>
      _changeEvents(username, (saved, discarded) {
        saved.add(id);
        discarded.remove(id);
      });
  Future<void> discardEvent(String username, String id) =>
      _changeEvents(username, (saved, discarded) {
        discarded.add(id);
        saved.remove(id);
      });
  Future<void> removeSavedEvent(String username, String id) =>
      _changeEvents(username, (saved, discarded) {
        saved.remove(id);
      });
  Future<void> resetEvents(String username) =>
      _changeEvents(username, (saved, discarded) {
        saved.clear();
        discarded.clear();
      });

  List<String> readPreferredCategories(String username) {
    final raw = _preferences.getString('usuarios');
    if (raw == null) return [];
    for (final user in jsonDecode(raw) as List) {
      if (user['username'] == username) {
        return (user['categorias_preferidas'] as List? ?? [])
            .whereType<String>()
            .toList();
      }
    }
    return [];
  }

  bool get onboardingCompleted =>
      _preferences.getBool('language_onboarding_completed') ?? false;
  Future<void> completeOnboarding() => _mutate(
    () => _check(_preferences.setBool('language_onboarding_completed', true)),
  );
  bool get eventsTutorialSeen =>
      _preferences.getBool('has_seen_events_swipe_tutorial') ?? false;
  Future<void> markEventsTutorialSeen() => _mutate(
    () => _check(_preferences.setBool('has_seen_events_swipe_tutorial', true)),
  );
  bool get floorTutorialCompleted =>
      _preferences.getBool('inside_orientation_tutorial_completed') ?? false;
  Future<void> completeFloorTutorial() => _mutate(
    () => _check(
      _preferences.setBool('inside_orientation_tutorial_completed', true),
    ),
  );
}
