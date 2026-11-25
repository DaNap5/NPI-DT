import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingSessionStore extends LocalStore {
  FailingSessionStore(super.preferences);
  bool fail = true;
  @override
  Future<void> saveUsername(String username) async {
    if (fail) throw StateError('Disk unavailable');
    await super.saveUsername(username);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late LocalStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_session': ' old-user ',
      'guest_session': true,
      'user_events': jsonEncode({
        'old-user': ['a', 'a'],
        'other': ['z'],
      }),
      'discarded_events': jsonEncode({
        'old-user': ['b'],
      }),
      'usuarios': jsonEncode([
        {
          'username': 'old-user',
          'categorias_preferidas': ['musica'],
        },
      ]),
    });
    preferences = await SharedPreferences.getInstance();
    store = LocalStore(preferences);
  });

  test(
    'legacy identity and preferences are restored without resetting data',
    () async {
      final session = SessionState(store);
      addTearDown(session.dispose);
      await session.restore();
      expect(session.username, 'old-user');
      expect(store.readSavedEventIds('old-user'), ['a']);
      expect(store.readPreferredCategories('old-user'), ['musica']);
      await session.continueAsGuest();
      expect(session.isSignedIn, isFalse);
      expect(store.readUsername(), isNull);
      await session.signIn(' new-user ');
      expect(session.username, 'new-user');
      expect(preferences.containsKey('guest_session'), isFalse);
      await session.signOut();
      expect(store.readSavedEventIds('other'), ['z']);
      expect(store.readSavedEventIds('old-user'), ['a']);
    },
  );

  test('concurrent collection changes serialize and recover after a failed operation', () async {
    await expectLater(store.saveUsername(' '), throwsArgumentError);
    await Future.wait([
      store.saveEvent('old-user', 'b'),
      store.saveEvent('old-user', 'c'),
      store.discardEvent('old-user', 'a'),
      store.saveEvent('old-user', 'c'),
    ]);
    expect(store.readSavedEventIds('old-user'), ['b', 'c']);
    expect(store.readDiscardedEventIds('old-user'), ['a']);
    await store.removeSavedEvent('old-user', 'b');
    expect(store.readDiscardedEventIds('old-user'), ['a']);
    await store.resetEvents('old-user');
    expect(store.readSavedEventIds('old-user'), isEmpty);
    expect(store.readDiscardedEventIds('old-user'), isEmpty);
    expect(store.readSavedEventIds('other'), ['z']);
  });

  test(
    'failed or overlapping session writes do not publish a new identity',
    () async {
      final failing = FailingSessionStore(preferences);
      final session = SessionState(failing);
      addTearDown(session.dispose);
      await session.restore();
      await expectLater(session.signIn('new-user'), throwsStateError);
      expect(session.username, 'old-user');
      failing.fail = false;
      final write = session.signIn('new-user');
      await expectLater(session.continueAsGuest(), throwsStateError);
      await write;
      expect(session.username, 'new-user');
    },
  );
}
