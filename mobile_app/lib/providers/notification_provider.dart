import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notifData = data['notifications'] ?? [];
        _notifications = notifData.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        _error = 'Erreur lors du chargement des notifications.';
      }
    } catch (e) {
      _error = 'Erreur de connexion lors du chargement des notifications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addNotification(NotificationModel notification) {
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
