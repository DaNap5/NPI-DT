import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/language_selection_screen.dart';
import 'auth/session_state.dart';
import 'events/event_catalog.dart';
import 'home/home_screen.dart';
import 'storage/local_store.dart';

class NpiApp extends StatefulWidget {
  const NpiApp({super.key, this.loadPreferences});
  final Future<SharedPreferences> Function()? loadPreferences;
  @override
  State<NpiApp> createState() => _NpiAppState();
}

class _NpiAppState extends State<NpiApp> {
  late Future<void> _startup;
  late LocalStore _store;
  final _catalog = EventCatalog();
  SessionState? _session;

  @override
  void initState() {
    super.initState();
    _startup = _initialize();
  }

  Future<void> _initialize() async {
    final preferences =
        await (widget.loadPreferences?.call() ??
            SharedPreferences.getInstance());
    if (!mounted) return;
    _store = LocalStore(preferences);
    _session?.dispose();
    _session = SessionState(_store);
    await _session!.restore();
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NPI Student View',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
      useMaterial3: true,
    ),
    home: FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los datos locales.'),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _startup = _initialize();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _store.onboardingCompleted
            ? HomeScreen(session: _session!, store: _store, catalog: _catalog)
            : LanguageSelectionScreen(
                session: _session!,
                store: _store,
                catalog: _catalog,
              );
      },
    ),
  );
}
