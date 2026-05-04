import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';

  AuthProvider(this._authService) { _checkAuthStatus(); }

  AuthStatus get status       => _status;
  String     get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _authService.isLoggedIn;
  String     get userName     => _authService.userName;
  String     get userEmail    => _authService.userEmail;
  String     get baseCurrency => _authService.baseCurrency;

  void _checkAuthStatus() {
    _status = _authService.isLoggedIn
        ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading; _errorMessage = ''; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    final ok = await _authService.login(email, password);
    _status = ok ? AuthStatus.authenticated : AuthStatus.error;
    if (!ok) _errorMessage = 'Invalid email or password';
    notifyListeners();
    return ok;
  }

  Future<void> register({
    required String name, required String email,
    required String password, required String baseCurrency,
  }) async {
    _status = AuthStatus.loading; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    await _authService.register(
        name: name, email: email, password: password, baseCurrency: baseCurrency);
    _status = AuthStatus.authenticated; notifyListeners();
  }

  Future<String?> updateProfile({
    required String name, required String email,
    String? currentPassword, String? newPassword,
  }) async {
    final err = await _authService.updateProfile(
        name: name, email: email,
        currentPassword: currentPassword, newPassword: newPassword);
    if (err == null) notifyListeners();
    return err;
  }

  Future<void> setBaseCurrency(String currency) async {
    await _authService.setBaseCurrency(currency);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _status = AuthStatus.unauthenticated; notifyListeners();
  }
}