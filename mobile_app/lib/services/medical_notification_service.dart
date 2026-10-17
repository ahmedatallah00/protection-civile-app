import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user_model.dart';

class MedicalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 999;
  static const String _channelId = 'medical_id_channel_v1';
  static const String _channelName = 'Fiche Médicale d\'Urgence';
  static const String _channelDesc = 'Affiche vos informations médicales critiques sur l\'écran de verrouillage';

  // Initialize the notification plugin
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Show or update the persistent Medical ID notification
  static Future<void> showMedicalNotification(UserModel user) async {
    final emergencyName = user.emergencyContactName ?? 'Non renseigné';
    final emergencyPhone = user.emergencyContactPhone ?? 'Non renseigné';
    final medicalInfo = user.medicalInfo?.trim().isNotEmpty == true ? user.medicalInfo! : 'Aucune';

    // Rich multi-line content
    final String medicalDetails = 
        '👤 NOM: ${user.fullName}\n'
        '📞 URGENCE: $emergencyPhone ($emergencyName)\n'
        '🩸 GROUPE SANGUIN: ${user.bloodType}\n'
        '⚠️ INFOS MEDICALES: $medicalInfo';

    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      medicalDetails,
      htmlFormatBigText: false,
      contentTitle: '🚑 FICHE MÉDICALE D\'URGENCE',
      htmlFormatContentTitle: false,
      summaryText: 'Groupe sanguin: ${user.bloodType}',
      htmlFormatSummaryText: false,
    );

    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Make it persistent / non-dismissible
      autoCancel: false, // Prevent dismissal on click
      styleInformation: bigTextStyleInformation,
      color: const Color(0xFFE71D36), // Tunisian Red theme
      icon: '@mipmap/ic_launcher',
      showWhen: false, // Don't show timestamp
      visibility: NotificationVisibility.public, // Show FULL content on lock screen!
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(
      _notificationId,
      '🚑 FICHE MÉDICALE D\'URGENCE',
      'Groupe sanguin: ${user.bloodType} | Maladie: $medicalInfo',
      notificationDetails,
    );
  }

  // Clear/cancel the persistent notification (e.g. on logout)
  static Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(_notificationId);
  }

  // Show standard one-shot OTP code notification
  static Future<void> showOtpNotification(String otpCode) async {
    const String otpChannelId = 'otp_channel_id';
    const String otpChannelName = 'Notifications OTP';
    const String otpChannelDesc = 'Affiche le code de vérification OTP pour l\'inscription';

    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      otpChannelId,
      otpChannelName,
      channelDescription: otpChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true, // Dismiss on click
      color: Color(0xFF1B365D), // Deep Blue theme color
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Notification ID is 888 to avoid overlapping with medical id 999
    await _notificationsPlugin.show(
      888,
      '🔑 Code de vérification OTP',
      'Votre code OTP est : $otpCode. Il expirera dans 5 minutes.',
      notificationDetails,
    );
  }
}
