import 'package:flutter/foundation.dart';

import 'session_state.dart';

class SignInViewModel extends ChangeNotifier {
  SignInViewModel(this.session);
  final SessionState session;
  bool isLoading = false;
  bool _disposed = false;

  Future<void> _run(Future<void> Function() action) async {
    if (isLoading) throw StateError('An access operation is already running.');
    isLoading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String> signInWithQr(String text) async {
    final username = text.trim();
    if (username.isEmpty) throw ArgumentError.value(text, 'text');
    await _run(() => session.signIn(username));
    return username;
  }

  Future<void> continueAsGuest() => _run(session.continueAsGuest);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
