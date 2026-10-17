import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../services/realtime_service.dart';
import 'home_sos_screen.dart';
import 'alerts_screen.dart';
import 'safety_tips_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        RealtimeService.connect(alertProvider, notificationProvider, user);
      }
    });
  }

  final List<Widget> _screens = const [
    HomeSosScreen(),
    AlertsScreen(),
    SafetyTipsScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1B365D), // Deep Blue
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          elevation: 0, // Handled by container shadow
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: lang.isArabic ? 'الرئيسية' : 'SOS',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.warning_amber_rounded),
              activeIcon: const Icon(Icons.warning),
              label: lang.isArabic ? 'الإنذارات' : 'Alertes',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shield_outlined),
              activeIcon: const Icon(Icons.shield),
              label: lang.isArabic ? 'النصائح' : 'Conseils',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: lang.isArabic ? 'الملف الشخصي' : 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
