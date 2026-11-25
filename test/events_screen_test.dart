import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:npi/events/events_screen.dart';
import 'package:npi/events/widgets/event_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feature_state_test.dart' show csv;

void main() {
  testWidgets(
    'manual swipe, recovery and reset share one catalogue without sensors',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      try {
        SharedPreferences.setMockInitialValues({
          'user_session': 'alice',
          'has_seen_events_swipe_tutorial': true,
        });
        final store = LocalStore(await SharedPreferences.getInstance());
        final session = SessionState(store);
        await session.restore();
        addTearDown(session.dispose);
        var reads = 0;
        final catalog = EventCatalog(
          readCsv: () async {
            reads++;
            return csv;
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: EventsScreen(
              session: session,
              store: store,
              catalog: catalog,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(reads, 1);
        final top = tester.widget<EventCard>(find.byType(EventCard)).event.id;
        await tester.drag(find.byType(EventCard), const Offset(-500, 0));
        await tester.pumpAndSettle();
        expect(store.readDiscardedEventIds('alice'), [top]);
        await tester.tap(find.text('Discarded events'));
        await tester.pumpAndSettle();
        expect(tester.widget<EventCard>(find.byType(EventCard)).event.id, top);
        await tester.tap(find.byTooltip('Guardar evento'));
        await tester.pumpAndSettle();
        expect(store.readSavedEventIds('alice'), [top]);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(store.readSavedEventIds('alice'), isEmpty);
        expect(store.readDiscardedEventIds('alice'), isEmpty);
        expect(find.byType(EventCard), findsOneWidget);
        expect(reads, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
