import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/alert_model.dart';
import '../models/notification_model.dart';
import '../providers/alert_provider.dart';
import '../providers/notification_provider.dart';
import 'location_service.dart';

class RealtimeService {
  static IO.Socket? _socket;
  static AlertProvider? _alertProvider;
  static NotificationProvider? _notificationProvider;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Timer? _locationTimer;

  static const String _channelId = 'realtime_channel';
  static const String _channelName = 'Alertes & Notifications Direct';
  static const String _channelDesc = 'Réception en temps réel des bulletins d\'alerte et messages ONPC';

  // Initialize notifications plugin for realtime service if not already initialized
  static Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  // Connect to Socket.io server and join rooms
  static void connect(
    AlertProvider alertProvider,
    NotificationProvider notificationProvider,
    UserModel user,
  ) {
    _alertProvider = alertProvider;
    _notificationProvider = notificationProvider;
    
    if (_socket != null && _socket!.connected) {
      // Re-join rooms if already connected
      _joinRooms(user);
      _startLocationPings(user);
      return;
    }

    // Get Socket URL from API config (remove /api suffix)
    final socketUrl = ApiConfig.baseUrl.replaceFirst('/api', '');
    debugPrint('🔌 Connecting to Socket.io: $socketUrl');

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // Use WebSocket transport for speed and stability
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('⚡ Realtime Socket connected: ${_socket!.id}');
      _joinRooms(user);
      _startLocationPings(user);
    });

    _socket!.onDisconnect((_) {
      debugPrint('⚡ Realtime Socket disconnected');
      _locationTimer?.cancel();
      _locationTimer = null;
    });

    _socket!.onConnectError((data) {
      debugPrint('❌ Realtime Socket connection error: $data');
    });

    // Listen for new alerts
    _socket!.on('new_alert', (data) {
      debugPrint('🚨 Realtime alert received: $data');
      _handleNewAlert(data);
    });

    // Listen for new notifications
    _socket!.on('new_notification', (data) {
      debugPrint('🔔 Realtime notification received: $data');
      _handleNewNotification(data);
    });
  }

  // Disconnect from Socket.io
  static void disconnect() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _alertProvider = null;
      _notificationProvider = null;
      debugPrint('🔌 Socket connection closed manually');
    }
  }

  // Periodic Location Updates
  static void _startLocationPings(UserModel user) {
    _locationTimer?.cancel();
    _pingLocation(user);
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _pingLocation(user);
    });
  }

  static void _pingLocation(UserModel user) async {
    if (_socket == null || !_socket!.connected) return;
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos != null) {
        _socket!.emit('update_location', {
          'userId': user.id,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        });
      } else {
        _socket!.emit('update_location', {
          'userId': user.id,
        });
      }
    } catch (e) {
      debugPrint('Error sending location ping: $e');
    }
  }

  // Join rooms corresponding to user ID and governorate
  static void _joinRooms(UserModel user) {
    if (_socket == null || !_socket!.connected) return;

    debugPrint('👤 Joining rooms for User ID: ${user.id}, Governorate: ${user.governorate}');
    _socket!.emit('join_user', user.id);
    _socket!.emit('join_governorate', user.governorate);
  }

  // Handle incoming alert
  static void _handleNewAlert(dynamic data) {
    try {
      final alertMap = Map<String, dynamic>.from(data);
      final alert = AlertModel.fromJson(alertMap);

      if (_alertProvider != null) {
        // Add to alert provider (this automatically updates the UI list in real-time)
        _alertProvider!.addAlert(alert);
      }

      // Show local push notification
      _showLocalPushNotification(
        id: alert.id.hashCode,
        title: '⚠️ ALERTE : ${alert.title}',
        body: alert.message,
        category: alert.severity, // can be critical, high, etc.
      );
    } catch (e) {
      debugPrint('Error parsing realtime alert: $e');
    }
  }

  // Handle incoming notification
  static void _handleNewNotification(dynamic data) {
    try {
      final notifMap = Map<String, dynamic>.from(data);
      final notif = NotificationModel.fromJson(notifMap);

      if (_notificationProvider != null) {
        // Add to notification provider (this automatically increments the badge count)
        _notificationProvider!.addNotification(notif);
      }

      // Show local push notification
      _showLocalPushNotification(
        id: notif.id.hashCode,
        title: '🔔 MESSAGE ONPC : ${notif.title}',
        body: notif.body,
        category: notif.targetType,
      );
    } catch (e) {
      debugPrint('Error parsing realtime notification: $e');
    }
  }

  // Trigger Android system notification popup (like Facebook banner)
  static Future<void> _showLocalPushNotification({
    required int id,
    required String title,
    required String body,
    String? category,
  }) async {
    await initNotifications();

    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: const Color(0xFFE71D36), // Tunisian Red
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
