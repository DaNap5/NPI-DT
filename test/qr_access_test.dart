import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npi/auth/sign_in_view_model.dart';
import 'package:npi/auth/sign_in_screen.dart';
import 'package:npi/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late SessionState session;
  late EventCatalog catalog;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'guest_session': true});
    store = LocalStore(await SharedPreferences.getInstance());
    session = SessionState(store);
    await session.restore();
    catalog = EventCatalog();
  });

  tearDown(() => session.dispose());

  test('any nonblank QR text replaces the guest session', () async {
    final viewModel = SignInViewModel(session);
    addTearDown(viewModel.dispose);

    expect(
      await viewModel.signInWithQr('  arbitrary QR text  '),
      'arbitrary QR text',
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('user_session'), 'arbitrary QR text');
    expect(preferences.containsKey('guest_session'), isFalse);
    expect(viewModel.isLoading, isFalse);
  });

  test('blank QR text does not create a session', () async {
    final viewModel = SignInViewModel(session);
    addTearDown(viewModel.dispose);

    await expectLater(viewModel.signInWithQr('  '), throwsArgumentError);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('user_session'), isNull);
    expect(preferences.getBool('guest_session'), isTrue);
    expect(viewModel.isLoading, isFalse);
  });

  testWidgets('cancelling a scan stays on access selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(
          session: session,
          store: store,
          catalog: catalog,
          scanQr: (_) async => null,
        ),
      ),
    );

    await tester.tap(find.text('Puedo escanear la TUI'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('user_session'), isNull);
  });

  testWidgets('scanned text opens Home with the mock user', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignInScreen(
          session: session,
          store: store,
          catalog: catalog,
          scanQr: (_) async => '  test-user  ',
        ),
      ),
    );

    await tester.tap(find.text('Puedo escanear la TUI'));
    await tester.pumpAndSettle();

    final screen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(screen.session.username, 'test-user');
    expect(screen.session.isSignedIn, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('user_session'), 'test-user');

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
