import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:flutter/material.dart';

import 'package:npi/auth/login_view_model.dart';
import 'package:npi/auth/login_form.dart';
import 'package:npi/home/home_screen.dart';

class LoginPage extends StatefulWidget {
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  const LoginPage({
    super.key,
    required this.session,
    required this.store,
    required this.catalog,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(widget.session);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();

    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    try {
      await _viewModel.login(email: email);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            session: widget.session,
            store: widget.store,
            catalog: widget.catalog,
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha producido un error al iniciar sesión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Iniciar sesión')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: LoginForm(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _viewModel.isLoading,
                onSubmit: _iniciarSesion,
              ),
            ),
          ),
        );
      },
    );
  }
}
