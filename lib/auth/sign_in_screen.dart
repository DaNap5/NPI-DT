import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:flutter/material.dart';

import 'package:npi/auth/login_page.dart';
import 'package:npi/auth/sign_in_view_model.dart';
import 'package:npi/home/home_screen.dart';
import 'package:npi/qr/qr_scanner_screen.dart';

class SignInScreen extends StatefulWidget {
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  final Future<String?> Function(BuildContext context)? scanQr;

  const SignInScreen({
    super.key,
    required this.session,
    required this.store,
    required this.catalog,
    this.scanQr,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final SignInViewModel _viewModel;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _viewModel = SignInViewModel(widget.session);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _scanTui() async {
    if (_isScanning || _viewModel.isLoading) {
      return;
    }

    setState(() => _isScanning = true);
    try {
      final scanResult =
          await (widget.scanQr?.call(context) ??
              Navigator.of(context).push<String>(
                MaterialPageRoute<String>(
                  builder: (_) => const QrScannerScreen(),
                ),
              ));
      if (!mounted || scanResult == null || scanResult.trim().isEmpty) return;

      await _viewModel.signInWithQr(scanResult);
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(
            session: widget.session,
            store: widget.store,
            catalog: widget.catalog,
          ),
        ),
        (route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint('Error al procesar el escaneo de la TUI: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido completar el escaneo.')),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _continueAsGuest() async {
    try {
      await _viewModel.continueAsGuest();
    } catch (error, stackTrace) {
      debugPrint('Error al guardar la sesión de invitado: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido continuar como invitado.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => HomeScreen(
          session: widget.session,
          store: widget.store,
          catalog: widget.catalog,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final isBusy = _viewModel.isLoading || _isScanning;

        return Scaffold(
          appBar: AppBar(title: const Text('Iniciar sesión')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Inicia sesión',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: isBusy ? null : _scanTui,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(76),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: _isScanning
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_scanner),
                    label: const Text('Puedo escanear la TUI'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => LoginPage(
                                  session: widget.session,
                                  store: widget.store,
                                  catalog: widget.catalog,
                                ),
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(76),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.person),
                    label: const Text('Tengo correo y contraseña'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: isBusy ? null : _continueAsGuest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size.fromHeight(68),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Continuar sin credenciales'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
