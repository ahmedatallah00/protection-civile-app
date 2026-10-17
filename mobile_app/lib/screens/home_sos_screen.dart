import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/medical_notification_service.dart';

class HomeSosScreen extends StatefulWidget {
  const HomeSosScreen({super.key});

  @override
  State<HomeSosScreen> createState() => _HomeSosScreenState();
}

class _HomeSosScreenState extends State<HomeSosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  bool _isSosSending = false;
  bool _isLiveSending = false;
  bool _isLiveActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Fetch alerts for the user's governorate and notifications on load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<AlertProvider>(context, listen: false).fetchAlerts(user.governorate);
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
        
        // Initialize and display persistent lock screen Medical ID notification
        try {
          await MedicalNotificationService.init();
          await MedicalNotificationService.showMedicalNotification(user);
        } catch (e) {
          debugPrint("Failed to initialize/show medical notification: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Start video live stream
  Future<void> _startLive() async {
    if (_isLiveSending) return;
    
    setState(() {
      _isLiveSending = true;
    });

    double lat = 36.8065;
    double lng = 10.1815;
    try {
      final position = await _locationService.getCurrentLocation().timeout(const Duration(seconds: 2));
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      // Fallback to default Tunis coordinates
    }

    try {
      final response = await _apiService.startLive(lat, lng);
      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _isLiveActive = true;
        });
        if (mounted) {
          _showLiveSimulation();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de lancer le direct vidéo.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur réseau lors du lancement du direct.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLiveSending = false;
      });
    }
  }

  // Stop video live stream
  Future<void> _stopLive() async {
    try {
      await _apiService.stopLive();
    } catch (e) {
      // ignore
    }
    if (mounted) {
      setState(() {
        _isLiveActive = false;
      });
    }
  }

  // Blinking direct viewport modal
  // Blinking direct viewport modal with live camera preview
  void _showLiveSimulation() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _LiveOverlayDialog(
          onStop: _stopLive,
        );
      },
    );
  }

  // Trigger SOS Incident submission
  Future<void> _triggerSos() async {
    setState(() {
      _isSosSending = true;
    });

    // 1. Show Countdown Dialog to prevent accidental triggers
    int count = 3;
    bool isCancelled = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Timer? timer;
            if (timer == null) {
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (count > 1) {
                  setStateDialog(() {
                    count--;
                  });
                } else {
                  t.cancel();
                  Navigator.of(dialogContext).pop(); // close dialog to execute SOS
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFE71D36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text('ALERTE SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Envoi automatique de votre position GPS aux secours dans :',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Un appel vers le 198 sera également lancé.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                    timer?.cancel();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('ANNULER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );

    if (isCancelled) {
      setState(() {
        _isSosSending = false;
      });
      return;
    }

    // 2. Fetch user coordinates
    double lat = 36.8065; // default Tunis lat
    double lng = 10.1815; // default Tunis lng
    try {
      final position = await _locationService.getCurrentLocation().timeout(const Duration(seconds: 2));
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      // Fallback to default Tunis coordinates
    }

    try {
      // 3. Post SOS incident to backend
      final streamedResponse = await _apiService.reportIncident(
        type: 'SOS',
        latitude: lat,
        longitude: lng,
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        // Show simulated Call screen
        if (mounted) {
          _showCallSimulation('198 (Protection Civile)');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de la transmission GPS. Lancement de l\'appel téléphonique direct...'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          _showCallSimulation('198 (Protection Civile)');
        }
      }
    } catch (e) {
      if (mounted) {
        _showCallSimulation('198 (Protection Civile)');
      }
    } finally {
      setState(() {
        _isSosSending = false;
      });
    }
  }

  // Show a simulated call window to wow the user
  void _showCallSimulation(String numberLabel) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Directionality(
          textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFF0C2340), // Deep blue theme for call screen
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Column(
                      children: [
                        Text(
                          lang.isArabic ? 'اتصال طوارئ' : 'APPEL D\'URGENCE',
                          style: const TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          numberLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang.isArabic ? 'جاري الاتصال...' : 'Connexion en cours...',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Pulse icon animation
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_in_talk,
                        size: 60,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: Column(
                      children: [
                        Text(
                          lang.isArabic
                              ? 'تم إرسال موقعك الجغرافي (GPS) إلى فرق الإنقاذ.'
                              : 'Votre position GPS a été transmise aux secours.',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 30),
                        FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lang.isArabic ? 'إنهاء المكالمة' : 'RACCROCHER',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
    final authProvider = Provider.of<AuthProvider>(context);
    final alertProvider = Provider.of<AlertProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = authProvider.user;

    // Filter active alerts for user's zone
    final activeAlertsCount = alertProvider.alerts.length;

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: CustomScrollView(
          slivers: [
            // Header / Banner Custom Silver App Bar
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF1B365D),
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
                          right: 6,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B365D), Color(0xFF0C2340)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isArabic ? 'مرحباً،' : 'Bonjour,',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                          ),
                          Text(
                            user?.fullName ?? (lang.isArabic ? 'مواطن' : 'Citoyen'),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.redAccent[100], size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${user?.delegation}, ${user?.governorate}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health and Alert Info Badges
                  Row(
                    children: [
                      // Blood Badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bloodtype, color: Colors.red, size: 24),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.isArabic ? 'الفصيلة' : 'Groupe',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  Text(
                                    user?.bloodType ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B365D)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Active Alerts Badge
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/alerts'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: activeAlertsCount > 0 ? Colors.orange : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.isArabic ? 'إنذارات منطقتك' : 'Alertes Zone',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                    Text(
                                      lang.isArabic ? '$activeAlertsCount نشطة' : '$activeAlertsCount Actives',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: activeAlertsCount > 0 ? Colors.orange : const Color(0xFF1B365D),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Emergency Contact display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE71D36), Color(0xFFC1121F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.getText('emergency_contact_section').toUpperCase(),
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.emergencyContactName ?? (lang.isArabic ? 'غير مهيأ' : 'Non configuré'),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user?.emergencyContactPhone ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_forwarded, color: Colors.white, size: 30),
                          onPressed: user?.emergencyContactPhone != null
                              ? () => _showCallSimulation('${user!.emergencyContactName} (${user.emergencyContactPhone})')
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Central SOS and Live Buttons
                  Center(
                    child: Column(
                      children: [
                        Text(
                          lang.isArabic ? 'حالة طوارئ قصوى؟' : 'URGENCE ABSOLUE ?',
                          style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang.isArabic
                              ? 'أرسل نجدة SOS أو ابدأ بثاً مباشراً بالفيديو'
                              : 'Déclarez un SOS ou diffusez un direct vidéo',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SOS Button
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 145,
                                  height: 145,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4 * _pulseController.value),
                                        blurRadius: 20 * _pulseController.value,
                                        spreadRadius: 6 * _pulseController.value,
                                      ),
                                    ],
                                  ),
                                  child: Center(child: child),
                                );
                              },
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(context, '/incident-report'),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 125,
                                  height: 125,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFE71D36), Color(0xFF9B2226)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.touch_app, color: Colors.white, size: 32),
                                        const SizedBox(height: 4),
                                        Text(
                                          lang.isArabic ? 'نجدة SOS' : 'SOS',
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang.isArabic ? 'إبلاغ عن طوارئ' : 'Signaler urgence',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 24),
                            
                            // Ouvrir Live Button
                            Container(
                              width: 145,
                              height: 145,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange.withOpacity(0.1),
                              ),
                              child: Center(
                                child: InkWell(
                                  onTap: _isLiveSending ? null : _startLive,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 125,
                                    height: 125,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: _isLiveSending 
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.videocam, color: Colors.white, size: 32),
                                              const SizedBox(height: 4),
                                              Text(
                                                lang.isArabic ? 'بث مباشر' : 'LIVE',
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                lang.isArabic ? 'بدء البث' : 'Ouvrir Live',
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Quick Call Hotlines Header
                  Text(
                    lang.getText('emergency_numbers'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                  ),
                  const SizedBox(height: 12),
                  
                  // Grid of Rapid Calling Buttons
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _buildHotlineButton('198', lang.getText('prot_civile'), Icons.local_fire_department, const Color(0xFFE71D36)),
                      _buildHotlineButton('190', lang.getText('samu'), Icons.medical_services, Colors.blue),
                      _buildHotlineButton('197', lang.getText('police'), Icons.local_police, Colors.teal),
                      _buildHotlineButton('193', lang.getText('garde_nationale'), Icons.shield, Colors.blueGrey),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Section Header: Mes Signalements & Statuts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.isArabic ? 'بلاغاتي وحالتها' : (lang.isEnglish ? 'My Incidents & Status' : 'Mes Signalements & Statuts'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                      ),
                      InkWell(
                        onTap: () => _openMyIncidentsModal(context),
                        child: Text(
                          lang.isArabic ? 'عرض الكل' : (lang.isEnglish ? 'View History' : 'Voir l\'historique'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE71D36)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Banner Card: Mes Signalements & Statuts
                  InkWell(
                    onTap: () => _openMyIncidentsModal(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B365D), Color(0xFF2C4D75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B365D).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_toggle_off, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.isArabic ? 'سجل البلاغات الخاصة بك' : (lang.isEnglish ? 'My Reported Incidents' : 'Historique de mes Signalements'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  lang.isArabic ? 'انقر لمتابعة حالة بلاغاتك ورجال الإطفاء المخصصين' : (lang.isEnglish ? 'Track status of your alerts & assigned units' : 'Suivez le statut de vos alertes et unités affectées'),
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHotlineButton(String number, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => _showCallSimulation('$number ($label)'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMyIncidentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MyIncidentsModalContent(apiService: _apiService);
      },
    );
  }
}

class _LiveOverlayDialog extends StatefulWidget {
  final VoidCallback onStop;

  const _LiveOverlayDialog({super.key, required this.onStop});

  @override
  State<_LiveOverlayDialog> createState() => _LiveOverlayDialogState();
}

class _LiveOverlayDialogState extends State<_LiveOverlayDialog> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasError = false;
  Timer? _frameTimer;
  bool _isTakingPicture = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _hasError = true);
        return;
      }

      // Try to find the back camera first, otherwise use any
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startFrameStreaming();
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _startFrameStreaming() {
    _frameTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) async {
      if (!_isCameraInitialized || _cameraController == null || _isTakingPicture) {
        return;
      }

      try {
        _isTakingPicture = true;
        final file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        await _apiService.uploadFrame(bytes);
      } catch (e) {
        debugPrint("Error capturing/streaming frame: $e");
      } finally {
        _isTakingPicture = false;
      }
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EN DIRECT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '1080p HD',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Preview or black background
                      Positioned.fill(
                        child: _isCameraInitialized && _cameraController != null
                            ? AspectRatio(
                                aspectRatio: _cameraController!.value.aspectRatio,
                                child: CameraPreview(_cameraController!),
                              )
                            : Container(
                                color: const Color(0xFF0F0F0F),
                                child: Center(
                                  child: _hasError
                                      ? const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 40),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Impossible d'accéder à la caméra",
                                              style: TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                          ],
                                        )
                                      : const CircularProgressIndicator(color: Colors.red),
                                ),
                              ),
                      ),
                      
                      // Viewfinder indicators
                      if (_isCameraInitialized) ...[
                        Positioned(
                          top: 16, left: 16,
                          child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white70, width: 1.5), left: BorderSide(color: Colors.white70, width: 1.5)))),
                        ),
                        Positioned(
                          top: 16, right: 16,
                          child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white70, width: 1.5), right: BorderSide(color: Colors.white70, width: 1.5)))),
                        ),
                        Positioned(
                          bottom: 16, left: 16,
                          child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white70, width: 1.5), left: BorderSide(color: Colors.white70, width: 1.5)))),
                        ),
                        Positioned(
                          bottom: 16, right: 16,
                          child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white70, width: 1.5), right: BorderSide(color: Colors.white70, width: 1.5)))),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  const Text(
                    'Les secours reçoivent votre localisation et votre flux vidéo.',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onStop();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.videocam_off, color: Colors.white),
                    label: const Text('COUPE LE DIRECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D36),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyIncidentsModalContent extends StatefulWidget {
  final ApiService apiService;
  const _MyIncidentsModalContent({super.key, required this.apiService});

  @override
  State<_MyIncidentsModalContent> createState() => _MyIncidentsModalContentState();
}

class _MyIncidentsModalContentState extends State<_MyIncidentsModalContent> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _incidents = [];

  @override
  void initState() {
    super.initState();
    _fetchMyIncidents();
  }

  Future<void> _fetchMyIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.apiService.getMyIncidents();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['incidents'] != null) {
          if (mounted) {
            setState(() {
              _incidents = data['incidents'];
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger vos incidents.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion au serveur.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Top Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B365D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history, color: Color(0xFF1B365D), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lang.isArabic ? 'سجل البلاغات الخاصة بك' : (lang.isEnglish ? 'My Incidents History' : 'Historique de mes Signalements'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B365D),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF1B365D)),
                        onPressed: _isLoading ? null : _fetchMyIncidents,
                        tooltip: 'Rafraîchir',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1B365D)),
                          SizedBox(height: 12),
                          Text('Chargement de vos signalements...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchMyIncidents,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B365D)),
                              ),
                            ],
                          ),
                        )
                      : _incidents.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.inbox_outlined, size: 54, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      lang.isArabic ? 'لم تقم بالإبلاغ عن أي حوادث حتى الآن' : 'Aucun incident signalé pour le moment',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B365D)),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      lang.isArabic ? 'جميع البلاغات التي ترسلها ستظهر هنا مع حالتها الحالية.' : 'Toutes les alertes que vous envoyez apparaîtront ici avec leur statut de traitement.',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _incidents.length,
                              itemBuilder: (context, index) {
                                return _buildIncidentCard(_incidents[index], lang);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> inc, LanguageProvider lang) {
    final type = (inc['type'] ?? 'other').toString();
    final status = (inc['status'] ?? 'pending').toString();
    final assignedUnit = inc['assignedUnit'];
    final description = inc['description'];
    final createdAtStr = inc['createdAt'];
    DateTime? dt;
    if (createdAtStr != null) {
      try {
        dt = DateTime.parse(createdAtStr.toString());
      } catch (_) {}
    }

    // Translate Type
    String typeLabel = type.toUpperCase();
    IconData typeIcon = Icons.warning_amber_rounded;
    Color typeColor = Colors.orange;

    switch (type.toLowerCase()) {
      case 'sos':
        typeLabel = 'ALERTE SOS';
        typeIcon = Icons.touch_app;
        typeColor = const Color(0xFFE71D36);
        break;
      case 'fire':
        typeLabel = lang.isArabic ? 'حريق' : 'Incendie';
        typeIcon = Icons.local_fire_department;
        typeColor = Colors.red;
        break;
      case 'accident':
        typeLabel = lang.isArabic ? 'حادث مرور' : 'Accident';
        typeIcon = Icons.car_crash;
        typeColor = Colors.orange;
        break;
      case 'flood':
        typeLabel = lang.isArabic ? 'فيضان' : 'Inondation';
        typeIcon = Icons.water;
        typeColor = Colors.blue;
        break;
      case 'collapse':
        typeLabel = lang.isArabic ? 'انهيار' : 'Effondrement';
        typeIcon = Icons.domain_disabled;
        typeColor = Colors.brown;
        break;
      case 'rescue':
        typeLabel = lang.isArabic ? 'نجدة وإسعاف' : 'Secours';
        typeIcon = Icons.medical_services;
        typeColor = Colors.teal;
        break;
      default:
        typeLabel = lang.isArabic ? 'آخر' : 'Autre incident';
        typeIcon = Icons.help_outline;
        typeColor = Colors.purple;
    }

    // Status formatting
    String statusLabel = 'En attente';
    Color statusBg = Colors.orange.shade50;
    Color statusColor = Colors.orange.shade900;
    IconData statusIcon = Icons.access_time_rounded;

    switch (status.toLowerCase()) {
      case 'dispatched':
      case 'in_progress':
        statusLabel = lang.isArabic ? 'فرقة التدخل في الطريق 🚒' : 'Intervention en cours 🚒';
        statusBg = Colors.blue.shade50;
        statusColor = Colors.blue.shade900;
        statusIcon = Icons.local_shipping;
        break;
      case 'resolved':
        statusLabel = lang.isArabic ? 'تم التعامل بنجاح ✅' : 'Résolu & Traité ✅';
        statusBg = Colors.green.shade50;
        statusColor = Colors.green.shade900;
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        statusLabel = lang.isArabic ? 'مغلق' : 'Clôturé';
        statusBg = Colors.grey.shade100;
        statusColor = Colors.grey.shade800;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusLabel = lang.isArabic ? 'قيد الانتظار ⏳' : 'En attente ⏳';
        statusBg = Colors.amber.shade50;
        statusColor = Colors.amber.shade900;
        statusIcon = Icons.schedule;
        break;
    }

    // Format Date
    String dateFormatted = '';
    if (dt != null) {
      dateFormatted = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    // Geolocation address
    String? address;
    if (inc['geolocation'] != null && inc['geolocation']['address'] != null) {
      address = inc['geolocation']['address'].toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Assigned Unit Banner if present
            if (assignedUnit != null && assignedUnit.toString().trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B365D).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1B365D).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fire_truck, color: Color(0xFF1B365D), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${lang.isArabic ? 'الوحدة المخصصة' : 'Unité affectée'}: ${assignedUnit.toString()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B365D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Description if present
            if (description != null && description.toString().trim().isNotEmpty) ...[
              Text(
                '"${description.toString().trim()}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Date and Location Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (dateFormatted.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatted,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                if (address != null && address.isNotEmpty)
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
