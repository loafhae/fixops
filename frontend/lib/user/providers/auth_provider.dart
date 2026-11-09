import 'package:flutter/material.dart';
import 'package:fixops_frontend/core/api_service.dart';
import 'package:fixops_frontend/core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  final ApiService _api = ApiService();

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.init();
      if (_api.authToken != null) {
        final data = await _api.get('/auth/me');
        _currentUser = UserModel.fromJson(data);
      }
    } catch (e) {
      await _api.setAuthToken(null);
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.post(
        '/auth/login',
        body: {'email': email.trim(), 'password': password},
      );

      final token = data['access_token'];
      await _api.setAuthToken(token);
      _currentUser = UserModel.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String fullName,
    required String password,
    String department = 'General',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.post(
        '/auth/register',
        body: {
          'email': email.trim(),
          'full_name': fullName.trim(),
          'password': password,
          'department': department.trim(),
        },
      );

      final token = data['access_token'];
      await _api.setAuthToken(token);
      _currentUser = UserModel.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.setAuthToken(null);
    _currentUser = null;
    notifyListeners();
  }
}
