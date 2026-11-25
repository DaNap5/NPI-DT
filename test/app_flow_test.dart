import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:npi/app.dart';
import 'package:npi/auth/language_selection_screen.dart';
import 'package:npi/auth/sign_in_screen.dart';
import 'package:npi/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'cold start restores a signed-in Home and logout clears live identity',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_session': 'alice',
        'language_onboarding_completed': true,
      });
      await tester.pumpWidget(const NpiApp());
      await tester.pumpAndSettle();
      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.session.username, 'alice');
      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(home.session.username, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('user_session'),
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'first launch keeps language then access flow and unsupported choices',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const NpiApp());
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      await tester.tap(find.text('Italiano'));
      await tester.pump();
      expect(
        find.text('El idioma "Italiano" aún no está implementado.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      await tester.tap(find.text('Continuar sin credenciales'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).session.isSignedIn,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('startup failure is visible and retry initializes the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language_onboarding_completed': true,
    });
    var attempts = 0;
    await tester.pumpWidget(
      NpiApp(
        loadPreferences: () async {
          if (attempts++ == 0) throw StateError('Disk unavailable');
          return SharedPreferences.getInstance();
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar los datos locales.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
