import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

class AlertProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch alerts matching user's governorate or 'all'
  Future<void> fetchAlerts(String governorate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAlertsByZone(governorate);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alertsData = data['alerts'] ?? [];
        _alerts = alertsData.map((json) => AlertModel.fromJson(json)).toList();
        
        // Sort alerts: high/critical severity first, then most recent
        _alerts.sort((a, b) {
          final aSev = _severityWeight(a.severity);
          final bSev = _severityWeight(b.severity);
          if (aSev != bSev) {
            return bSev.compareTo(aSev); // higher weight first
          }
          return b.createdAt.compareTo(a.createdAt); // more recent first
        });
      } else {
        _error = 'Erreur lors du chargement des alertes.';
      }
    } catch (e) {
      _error = 'Erreur de connexion lors du chargement des alertes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _severityWeight(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  void addAlert(AlertModel alert) {
    if (_alerts.any((a) => a.id == alert.id)) return;
    _alerts.insert(0, alert);
    _alerts.sort((a, b) {
      final aSev = _severityWeight(a.severity);
      final bSev = _severityWeight(b.severity);
      if (aSev != bSev) {
        return bSev.compareTo(aSev); // higher weight first
      }
      return b.createdAt.compareTo(a.createdAt); // more recent first
    });
    notifyListeners();
  }
}
