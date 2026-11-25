import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:npi/events/events_view_model.dart';
import 'package:npi/home/home_view_model.dart';
import 'package:npi/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const csv =
    'id,title,emoji,category,description,location,date,url\n'
    'a,First,!,music,Description,Entrance,2099-01-01T10:00:00,\n'
    'b,Second,!,sports,Description,Entrance,2099-01-02T10:00:00,\n'
    'c,Third,!,music,Description,Entrance,2099-01-03T10:00:00,\n'
    'd,Fourth,!,music,Description,Entrance,2099-01-04T10:00:00,\n'
    'e,Fifth,!,music,Description,Entrance,2099-01-05T10:00:00,\n';

class FailingEventStore extends LocalStore {
  FailingEventStore(super.preferences);
  @override
  Future<void> saveEvent(String username, String id) async =>
      throw StateError('Disk unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStore store;
  late SessionState session;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_session': 'alice'});
    store = LocalStore(await SharedPreferences.getInstance());
    session = SessionState(store);
    await session.restore();
  });
  tearDown(() => session.dispose());

  test(
    'catalogue shares pending/cached loads and allows retry after failure',
    () async {
      var reads = 0;
      final pending = Completer<String>();
      final catalog = EventCatalog(
        readCsv: () {
          reads++;
          return pending.future;
        },
      );
      final first = catalog.loadEvents();
      final second = catalog.loadEvents();
      pending.complete(csv);
      expect(await first, same(await second));
      expect(await catalog.loadEvents(), same(await first));
      expect(reads, 1);
      var attempts = 0;
      final retry = EventCatalog(
        readCsv: () async {
          if (attempts++ == 0) throw StateError('Read failed');
          return csv;
        },
      );
      await expectLater(retry.loadEvents(), throwsStateError);
      expect(await retry.loadEvents(), hasLength(5));
    },
  );

  test(
    'save, discard, recover and reset update one owner after persistence',
    () async {
      final catalog = EventCatalog(readCsv: () async => csv);
      final vm = EventsViewModel(
        session: session,
        store: store,
        catalog: catalog,
      );
      final recovery = EventsViewModel(
        session: session,
        store: store,
        catalog: catalog,
        discardedOnly: true,
      );
      addTearDown(vm.dispose);
      addTearDown(recovery.dispose);
      await vm.loadEvents();
      final event = vm.events.last;
      await vm.discardEvent(event);
      expect(store.readDiscardedEventIds('alice'), [event.id]);
      expect(vm.events.any((item) => item.id == event.id), isFalse);
      await recovery.loadEvents();
      expect(recovery.events.single.id, event.id);
      await recovery.saveEvent(event);
      expect(recovery.events, isEmpty);
      expect(store.readSavedEventIds('alice'), [event.id]);
      await vm.resetEvents();
      expect(vm.events, hasLength(5));
      expect(store.readSavedEventIds('alice'), isEmpty);
      expect(store.readDiscardedEventIds('alice'), isEmpty);
    },
  );

  test(
    'a failed mutation keeps the visible card and reports an error',
    () async {
      final vm = EventsViewModel(
        session: session,
        store: FailingEventStore(await SharedPreferences.getInstance()),
        catalog: EventCatalog(readCsv: () async => csv),
      );
      addTearDown(vm.dispose);
      await vm.loadEvents();
      final before = vm.events;
      await expectLater(vm.saveCurrentEvent(), throwsStateError);
      expect(vm.events, before);
      expect(vm.error, isNotNull);
      expect(vm.isMutating, isFalse);
    },
  );

  test('late catalogue results cannot restore an old session or notify disposed state', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_events',
      jsonEncode({
        'alice': ['a'],
        'bob': ['b'],
      }),
    );
    final pending = Completer<String>();
    final catalog = EventCatalog(readCsv: () => pending.future);
    final home = HomeViewModel(
      session: session,
      store: store,
      catalog: catalog,
    );
    final events = EventsViewModel(
      session: session,
      store: store,
      catalog: catalog,
    );
    addTearDown(home.dispose);
    final oldLoad = home.loadSchedule();
    final disposedLoad = events.loadEvents();
    events.dispose();
    await session.signIn('bob');
    pending.complete(csv);
    await oldLoad;
    await disposedLoad;
    await home.loadSchedule();
    expect(home.username, 'bob');
    expect(
      home.getItemsForDay('L').where((item) => item.isSavedEvent).single.id,
      'b',
    );
  });

  test('Home preserves the four-event limit and guest day samples', () async {
    await (await SharedPreferences.getInstance()).setString(
      'user_events',
      jsonEncode({
        'alice': ['a', 'b', 'c', 'd', 'e'],
      }),
    );
    final vm = HomeViewModel(
      session: session,
      store: store,
      catalog: EventCatalog(readCsv: () async => csv),
    );
    addTearDown(vm.dispose);
    await vm.loadSchedule();
    final saved = [
      'L',
      'M',
      'X',
      'J',
      'V',
    ].expand(vm.getItemsForDay).where((item) => item.isSavedEvent);
    expect(saved, hasLength(4));
    await session.continueAsGuest();
    expect(vm.isRegistered, isFalse);
    expect(vm.getItemsForDay('M').single.id, 'evt_m1');
  });
}
