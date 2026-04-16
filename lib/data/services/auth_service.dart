import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyBaseCurrency = 'base_currency';

  final SharedPreferences _prefs;

  AuthService(this._prefs);

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  String get userName => _prefs.getString(_keyUserName) ?? '';
  String get userEmail => _prefs.getString(_keyUserEmail) ?? '';
  String get baseCurrency => _prefs.getString(_keyBaseCurrency) ?? 'USD';

  Future<bool> login(String email, String password) async {
    final registeredEmail = _prefs.getString(_keyUserEmail);
    final registeredPassword = _prefs.getString('user_password');

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
    await _prefs.setString('user_password', password);
    await _prefs.setString(_keyBaseCurrency, baseCurrency);
    await _prefs.setBool(_keyIsLoggedIn, true);
  }

  Future<void> logout() async {
    await _prefs.setBool(_keyIsLoggedIn, false);
  }
}