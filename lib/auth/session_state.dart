import 'package:flutter/foundation.dart';
import 'package:npi/storage/local_store.dart';

class SessionState extends ChangeNotifier {
  SessionState(this._store);
  final LocalStore _store;
  String? _username;
  String? get username => _username;
  bool get isSignedIn => _username != null;
  bool _busy = false;
  bool _disposed = false;

  Future<void> restore() async {
    if (_busy) throw StateError('A session change is already running.');
    _username = _store.readUsername();
    if (!_disposed) notifyListeners();
  }

  Future<void> _change(Future<void> Function() save, String? username) async {
    if (_busy) throw StateError('A session change is already running.');
    _busy = true;
    try {
      await save();
      _username = username;
      if (!_disposed) notifyListeners();
    } finally {
      _busy = false;
    }
  }

  Future<void> signIn(String username) {
    final value = username.trim();
    if (value.isEmpty) {
      return Future.error(ArgumentError.value(username, 'username'));
    }
    return _change(() => _store.saveUsername(value), value);
  }

  Future<void> continueAsGuest() => _change(_store.saveGuestSession, null);
  Future<void> signOut() => _change(_store.clearSession, null);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
