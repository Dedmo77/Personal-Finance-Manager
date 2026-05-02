import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserPassword = 'user_password';
  static const _keyBaseCurrency = 'base_currency';

  final SharedPreferences _prefs;

  AuthService(this._prefs);

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  String get userName => _prefs.getString(_keyUserName) ?? '';
  String get userEmail => _prefs.getString(_keyUserEmail) ?? '';
  String get baseCurrency => _prefs.getString(_keyBaseCurrency) ?? 'USD';

  Future<bool> login(String email, String password) async {
    final registeredEmail = _prefs.getString(_keyUserEmail);
    final registeredPassword = _prefs.getString(_keyUserPassword);

    if (registeredEmail == null) return false;

    if (registeredEmail == email && registeredPassword == password) {
      await _prefs.setBool(_keyIsLoggedIn, true);
      return true;
    }
    return false;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String baseCurrency,
  }) async {
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserPassword, password);
    await _prefs.setString(_keyBaseCurrency, baseCurrency);
    await _prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Updates profile fields. Pass null to leave a field unchanged.
  /// Returns an error message string, or null on success.
  Future<String?> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    // If the user wants to change their password, verify the current one first.
    if (newPassword != null && newPassword.isNotEmpty) {
      final stored = _prefs.getString(_keyUserPassword);
      if (currentPassword == null || currentPassword != stored) {
        return 'Current password is incorrect';
      }
      await _prefs.setString(_keyUserPassword, newPassword);
    }

    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserEmail, email);
    return null; // success
  }

  Future<void> setBaseCurrency(String currency) async {
    await _prefs.setString(_keyBaseCurrency, currency);
  }

  Future<void> logout() async {
    await _prefs.setBool(_keyIsLoggedIn, false);
  }
}