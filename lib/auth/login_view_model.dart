import 'package:flutter/foundation.dart';

import 'session_state.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this.session);
  final SessionState session;
  bool isLoading = false;
  bool _disposed = false;

  Future<void> login({required String email}) async {
    if (isLoading) throw StateError('A login is already running.');
    isLoading = true;
    notifyListeners();
    try {
      await session.signIn(email);
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
