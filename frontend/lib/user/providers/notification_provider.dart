import 'package:flutter/material.dart';
import 'package:fixops_frontend/core/api_service.dart';
import 'package:fixops_frontend/core/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  String? _errorMessage;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _api.get(
        '/notifications/',
        queryParams: {'limit': 30},
      );
      if (data is List) {
        _notifications = data
            .map((item) => NotificationModel.fromJson(item))
            .toList();
      }
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markRead(String notificationId) async {
    try {
      await _api.patch('/notifications/$notificationId/read');
      _notifications = _notifications.map((item) {
        if (item.id != notificationId) return item;
        return NotificationModel(
          id: item.id,
          ticketId: item.ticketId,
          eventType: item.eventType,
          message: item.message,
          createdAt: item.createdAt,
          readAt: DateTime.now(),
        );
      }).toList();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      await _api.post('/notifications/read-all');
      final readAt = DateTime.now();
      _notifications = _notifications
          .map(
            (item) => NotificationModel(
              id: item.id,
              ticketId: item.ticketId,
              eventType: item.eventType,
              message: item.message,
              createdAt: item.createdAt,
              readAt: item.readAt ?? readAt,
            ),
          )
          .toList();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
