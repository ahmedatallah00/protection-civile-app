import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      await Provider.of<AlertProvider>(context, listen: false).fetchAlerts(user.governorate);
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFF9B2226); // Dark crimson
      case 'high':
        return const Color(0xFFE71D36); // Red
      case 'medium':
        return const Color(0xFFF77F00); // Orange
      case 'low':
        return const Color(0xFF38B000); // Green
      default:
        return const Color(0xFF1B365D); // Blue
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'flood':
        return Icons.water_damage;
      case 'weather':
        return Icons.cloudy_snowing;
      case 'earthquake':
        return Icons.tsunami;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _timeAgo(DateTime dateTime, bool isArabic) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return isArabic ? 'منذ ${difference.inDays} يوم' : 'Il y a ${difference.inDays}j';
    } else if (difference.inHours >= 1) {
      return isArabic ? 'منذ ${difference.inHours} ساعة' : 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return isArabic ? 'منذ ${difference.inMinutes} دقيقة' : 'Il y a ${difference.inMinutes}m';
    } else {
      return isArabic ? 'الآن' : 'À l\'instant';
    }
  }

  Widget _buildLanguageSwitch(LanguageProvider lang) {
    return InkWell(
      onTap: () => lang.toggleLanguage(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FR',
              style: TextStyle(
                color: (!lang.isArabic && !lang.isEnglish) ? Colors.white : Colors.white54,
                fontWeight: (!lang.isArabic && !lang.isEnglish) ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const Text(' | ', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(
              'AR',
              style: TextStyle(
                color: lang.isArabic ? Colors.white : Colors.white54,
                fontWeight: lang.isArabic ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const Text(' | ', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(
              'EN',
              style: TextStyle(
                color: lang.isEnglish ? Colors.white : Colors.white54,
                fontWeight: lang.isEnglish ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = Provider.of<AlertProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    final lang = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(lang.getText('alerts_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B365D),
          foregroundColor: Colors.white,
          centerTitle: false,
          actions: [
            _buildLanguageSwitch(lang),
            const SizedBox(width: 8),
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                final count = notifProvider.notifications.length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    if (count > 0)
                      Positioned(
                        right: lang.isArabic ? null : 6,
                        left: lang.isArabic ? 6 : null,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE71D36), // Tunisian Red
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1B365D), width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Zone Info Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFE71D36), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      lang.getText('active_zone'),
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                    Text(
                      user?.governorate ?? (lang.isArabic ? 'كل الولايات' : 'Tunisie'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),

              // Alerts list
              Expanded(
                child: alertProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : alertProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(alertProvider.error!, style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _refreshData,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B365D)),
                                  child: Text(
                                    lang.isArabic ? 'إعادة المحاولة' : 'Réessayer',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : alertProvider.alerts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      lang.getText('no_alerts'),
                                      style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: alertProvider.alerts.length,
                                itemBuilder: (context, index) {
                                  final alert = alertProvider.alerts[index];
                                  final sevColor = _getSeverityColor(alert.severity);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                            left: !lang.isArabic ? BorderSide(color: sevColor, width: 6) : BorderSide.none,
                                            right: lang.isArabic ? BorderSide(color: sevColor, width: 6) : BorderSide.none,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      _getCategoryIcon(alert.category),
                                                      color: sevColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: sevColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        alert.severity.toUpperCase(),
                                                        style: TextStyle(
                                                          color: sevColor,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  _timeAgo(alert.createdAt, lang.isArabic),
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              alert.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0C2340),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              alert.message,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${lang.getText('expiry_date')}${alert.expiryDate.day}/${alert.expiryDate.month} ${lang.isArabic ? 'على الساعة' : 'à'} ${alert.expiryDate.hour}h${alert.expiryDate.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
