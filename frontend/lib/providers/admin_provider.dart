import 'package:flutter/material.dart';
import 'package:fixops_frontend/core/api_service.dart';
import 'package:fixops_frontend/models/user_model.dart';
import 'package:fixops_frontend/models/audit_log_model.dart';

class AdminProvider extends ChangeNotifier {
  Map<String, dynamic>? _stats;
  List<UserModel> _users = [];
  List<AuditLogModel> _auditLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get stats => _stats;
  List<UserModel> get users => _users;
  List<AuditLogModel> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _api = ApiService();

  Future<void> fetchStats() async {
    try {
      final data = await _api.get('/stats/');
      _stats = data;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/users/');
      if (data is List) {
        _users = data.map((j) => UserModel.fromJson(j)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserRole(String userId, String role, {bool? isActive}) async {
    try {
      await _api.patch('/users/$userId', body: {
        'role': role,
        if (isActive != null) 'is_active': isActive,
      });
      await fetchUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAuditLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/audit-logs/?limit=100');
      if (data is List) {
        _auditLogs = data.map((j) => AuditLogModel.fromJson(j)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

