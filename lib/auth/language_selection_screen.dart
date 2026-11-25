import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:flutter/material.dart';

import 'package:npi/auth/sign_in_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  const LanguageSelectionScreen({
    super.key,
    required this.session,
    required this.store,
    required this.catalog,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const _languages = ['Español', 'Italiano', 'Inglés'];
  bool _isContinuing = false;

  Future<void> _handleLanguageTap(String language) async {
    if (language == 'Español') {
      if (_isContinuing) return;
      setState(() => _isContinuing = true);
      try {
        await _navigateToNextScreen();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo guardar el idioma. Inténtalo de nuevo.',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isContinuing = false);
      }
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El idioma "$language" aún no está implementado.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToNextScreen() async {
    await widget.store.completeOnboarding();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SignInScreen(
          session: widget.session,
          store: widget.store,
          catalog: widget.catalog,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64.0, bottom: 32.0),
              child: Text(
                'Idioma',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  for (final language in _languages) ...[
                    _LanguageListItem(
                      languageName: language,
                      isEnabled: language == 'Español',
                      onTap: () => _handleLanguageTap(language),
                    ),
                    if (language != _languages.last) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageListItem extends StatelessWidget {
  const _LanguageListItem({
    required this.languageName,
    required this.isEnabled,
    required this.onTap,
  });

  final String languageName;
  final bool isEnabled;
  final VoidCallback onTap;

  String get _flag => switch (languageName) {
    'Español' => '🇪🇸',
    'Italiano' => '🇮🇹',
    'Inglés' => '🇬🇧',
    _ => '🏳️',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 8.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      tileColor: isEnabled ? const Color(0xFF0D47A1) : const Color(0xFFBBDEFB),
      leading: Text(_flag, style: const TextStyle(fontSize: 28)),
      title: Text(
        languageName,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
          color: isEnabled ? Colors.white : const Color(0xFF0D47A1),
        ),
      ),
    );
  }
}
