import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/medical_notification_service.dart';
import '../services/realtime_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear previous errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Attempt auto-login using stored JWT token
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) {
      return false;
    }

    _token = prefs.getString('auth_token');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = UserModel.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Token might have expired or is invalid
        await logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Impossible de se connecter au serveur.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Send OTP verification code
  Future<bool> sendOtp(String phone, String cin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendOtp(phone, cin);
      final data = jsonDecode(response.body);

      _isLoading = false;
      if (response.statusCode == 200) {
        final debugOtp = data['debugOtp'];
        if (debugOtp != null) {
          await MedicalNotificationService.showOtpNotification(debugOtp.toString());
        }
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur lors de l\'envoi de l\'OTP.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Impossible de se connecter au serveur.';
      notifyListeners();
      return false;
    }
  }

  // Register a new user
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(userData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _user = UserModel.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur lors de l\'inscription.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Impossible de se connecter au serveur.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Log in user
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(identifier, password);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = UserModel.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Identifiants incorrects.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Impossible de se connecter au serveur.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(userData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(data['user']);
        
        // Update persistent medical ID notification
        try {
          await MedicalNotificationService.showMedicalNotification(_user!);
        } catch (e) {
          debugPrint("Failed to update medical notification: $e");
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur lors de la mise à jour.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Impossible de se connecter au serveur.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteAccount();
      if (response.statusCode == 200) {
        await logout();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Erreur lors de la suppression du compte.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Impossible de se connecter au serveur.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Log out user
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    // Disconnect realtime socket connection
    RealtimeService.disconnect();
    
    // Clear lock screen notification
    try {
      await MedicalNotificationService.cancelNotification();
    } catch (e) {
      debugPrint("Failed to cancel medical notification: $e");
    }
    notifyListeners();
  }
}
