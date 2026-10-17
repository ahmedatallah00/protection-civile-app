import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
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
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(lang.getText('notifications_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B365D),
          foregroundColor: Colors.white,
          centerTitle: false,
          actions: [
            _buildLanguageSwitch(lang),
            const SizedBox(width: 16),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Info Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, color: Color(0xFF1B365D), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.getText('notif_banner_desc'),
                        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),

              // Notifications list
              Expanded(
                child: notificationProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notificationProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(notificationProvider.error!, style: const TextStyle(color: Colors.grey)),
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
                        : notificationProvider.notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.mail_outline, size: 60, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      lang.getText('no_notifications'),
                                      style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: notificationProvider.notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = notificationProvider.notifications[index];
                                  final isCrit = notif.title.toLowerCase().contains('urg') ||
                                      notif.title.toLowerCase().contains('alert') ||
                                      notif.body.toLowerCase().contains('urg') ||
                                      notif.title.contains('عاجل') ||
                                      notif.body.contains('عاجل');
                                  final borderCol = isCrit ? const Color(0xFFE71D36) : const Color(0xFF1B365D);
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
                                            left: !lang.isArabic ? BorderSide(color: borderCol, width: 6) : BorderSide.none,
                                            right: lang.isArabic ? BorderSide(color: borderCol, width: 6) : BorderSide.none,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: borderCol.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    notif.targetType == 'user'
                                                        ? lang.getText('notif_target_personal')
                                                        : notif.targetType == 'region'
                                                            ? lang.getText('notif_target_regional')
                                                            : lang.getText('notif_target_general'),
                                                    style: TextStyle(
                                                      color: borderCol,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _timeAgo(notif.createdAt, lang.isArabic),
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              notif.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0C2340),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              notif.body,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
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
