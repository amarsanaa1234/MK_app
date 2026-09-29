import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers the last email/password used to log in, in the platform's secure storage
/// (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android) so the
/// login form can be prefilled next time instead of asking again.
class SavedCredentials {
  static const _storage = FlutterSecureStorage();
  static const _emailKey = 'saved_login_email';
  static const _passwordKey = 'saved_login_password';

  static Future<void> save(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<(String, String)?> load() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return (email, password);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
