import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/leap_websocket_service.dart';
import 'ui/auth/language/widgets/language_selection_screen.dart';
import 'ui/home/view_models/schedule_controller.dart';
import 'ui/home/widgets/schedule_screen.dart';
import 'ui/qr/widgets/leap_hud_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted =
      prefs.getBool('language_onboarding_completed') ?? false;

  final scheduleController = ScheduleController();
  final leapService = LeapWebSocketService()..connect();

  runApp(
    MyApp(
      controller: scheduleController,
      leapService: leapService,
      showLanguageOnboarding: !onboardingCompleted,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ScheduleController controller;
  final LeapWebSocketService? leapService;
  final bool showLanguageOnboarding;

  const MyApp({
    super.key,
    required this.controller,
    this.leapService,
    this.showLanguageOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeLeapService = leapService ?? LeapWebSocketService();

    return MaterialApp(
      title: 'NPI Student View',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return LeapHudOverlay(service: activeLeapService, child: child);
      },
      home: showLanguageOnboarding
          ? const LanguageSelectionScreen()
          : ScheduleScreen(
              controller: controller,
              leapService: activeLeapService,
            ),
    );
  }
}
