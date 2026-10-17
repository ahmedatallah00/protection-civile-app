import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../data/safety_tips_data.dart';

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key});

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  final ApiService _apiService = ApiService();
  List<SafetyTip> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      final response = await _apiService.getSafetyTips();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List<dynamic> list = decoded['data'];
          setState(() {
            _tips = list.map((item) {
              return SafetyTip(
                title: item['title'] ?? '',
                category: item['category'] ?? '',
                description: item['description'] ?? '',
                dos: List<String>.from(item['dos'] ?? []),
                donts: List<String>.from(item['donts'] ?? []),
                iconName: item['iconName'] ?? 'help_outline',
                titleAr: item['titleAr'] ?? '',
                categoryAr: item['categoryAr'] ?? '',
                descriptionAr: item['descriptionAr'] ?? '',
                dosAr: List<String>.from(item['dosAr'] ?? []),
                dontsAr: List<String>.from(item['dontsAr'] ?? []),
              );
            }).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading safety tips from API: $e');
    }

    // Fallback to static data if offline or error
    if (mounted) {
      setState(() {
        _tips = safetyTipsData;
        _isLoading = false;
      });
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'water_damage':
        return Icons.water_damage;
      case 'thermostat':
        return Icons.thermostat;
      case 'medical_services':
        return Icons.medical_services;
      case 'warning':
        return Icons.warning;
      case 'help_outline':
        return Icons.help_outline;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'favorite':
        return Icons.favorite;
      case 'wind_power':
        return Icons.wind_power;
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'incendie':
      case 'حرائق':
        return Colors.red[800]!;
      case 'inondation':
      case 'فيضانات':
        return Colors.blue[800]!;
      case 'météo':
      case 'طقس':
        return Colors.orange[800]!;
      case 'sauvetage':
      case 'إنقاذ':
        return Colors.green[800]!;
      default:
        return const Color(0xFF1B365D);
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
    final lang = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(lang.getText('safety_tips_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B365D),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.isArabic ? 'دليل المواطن للحماية والنجاة' : 'GUIDE DE SURVIE CITOYEN',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lang.isArabic
                          ? 'السلوكيات والخطوات الصحيحة التي يجب اتباعها في حالات الطوارئ.'
                          : 'Gestes et comportements à adopter face aux situations d\'urgence.',
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Tip list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B365D),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTips,
                        color: const Color(0xFF1B365D),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _tips.length,
                          itemBuilder: (context, index) {
                            final tip = _tips[index];
                            final displayTitle = lang.isArabic ? tip.titleAr : tip.title;
                            final displayCat = lang.isArabic ? tip.categoryAr : tip.category;
                            final displayDesc = lang.isArabic ? tip.descriptionAr : tip.description;
                            final catColor = _getCategoryColor(tip.category);

                            return Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              shadowColor: Colors.black.withOpacity(0.04),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconData(tip.iconName),
                                    color: catColor,
                                    size: 28,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        displayCat.toUpperCase(),
                                        style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      displayTitle,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0C2340)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayDesc,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  lang.isArabic ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  _showTipDetails(context, tip, lang);
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDetails(BuildContext context, SafetyTip tip, LanguageProvider lang) {
    final catColor = _getCategoryColor(tip.category);
    final displayTitle = lang.isArabic ? tip.titleAr : tip.title;
    final displayDesc = lang.isArabic ? tip.descriptionAr : tip.description;
    final dosList = lang.isArabic ? tip.dosAr : tip.dos;
    final dontsList = lang.isArabic ? tip.dontsAr : tip.donts;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            appBar: AppBar(
              title: Text(displayTitle),
              backgroundColor: catColor,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(_getIconData(tip.iconName), color: catColor, size: 50),
                          const SizedBox(height: 12),
                          Text(
                            displayTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0C2340)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayDesc,
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // À faire (Do's) - Green Card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                lang.isArabic ? 'سلوكيات مستحسنة / يجب فعلها' : 'À FAIRE',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
                          ...dosList.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // À éviter (Don'ts) - Red Card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red[800], size: 24),
                              const SizedBox(width: 8),
                              Text(
                                lang.isArabic ? 'سلوكيات يجب تجنبها / ممنوعة' : 'À ÉVITER / INTERDIT',
                                style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
                          ...dontsList.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.arrow_right, color: Colors.red[800]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
