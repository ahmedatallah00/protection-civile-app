import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isEditing = false;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _ageController;
  late TextEditingController _medicalInfoController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _emergencyNameController = TextEditingController(text: user?.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: user?.emergencyContactPhone ?? '');
    _ageController = TextEditingController(text: user?.age.toString() ?? '');
    _medicalInfoController = TextEditingController(text: user?.medicalInfo ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _ageController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final updatedData = {
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'medicalInfo': _medicalInfoController.text.trim(),
      'emergencyContact': {
        'name': _emergencyNameController.text.trim(),
        'phone': _emergencyPhoneController.text.trim(),
      }
    };

    final success = await authProvider.updateProfile(updatedData);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isArabic ? 'تم تحديث الملف الشخصي بنجاح.' : 'Profil mis à jour avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? (lang.isArabic ? 'حدث خطأ أثناء التحديث.' : 'Erreur lors de la mise à jour.')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(LanguageProvider lang) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  lang.isArabic ? 'حذف الحساب؟' : 'Supprimer le compte ?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              lang.isArabic
                  ? 'هذا الإجراء غير قابل للتراجع. سيتم حذف جميع بياناتك الشخصية وبلاغاتك نهائياً.'
                  : 'Cette action est irréversible. Toutes vos informations personnelles et vos déclarations d\'incidents seront définitivement effacées.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  lang.isArabic ? 'إلغاء' : 'ANNULER',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // close dialog
                  final success = await authProvider.deleteAccount();
                  if (success && mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.error ?? (lang.isArabic ? 'خطأ أثناء الحذف.' : 'Erreur lors de la suppression.')),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  lang.isArabic ? 'تأكيد الحذف' : 'SUPPRIMER',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            lang.isArabic ? 'ميثاق السرية وخصوصية البيانات' : 'Charte de Confidentialité',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.isArabic ? 'جمع بيانات الموقع (GPS) :' : 'Collecte des données GPS :',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.isArabic
                      ? 'يجمع تطبيق الحماية المدنية التونسية بيانات موقعك الجغرافي فقط عند إرسال بلاغ SOS أو الإبلاغ عن حادث (حريق، حادث مرور، فيضان) لتمكين فرق الإنقاذ من الوصول إليك بدقة وسرعة.'
                      : 'L\'application Protection Civile Tunisie collecte vos données de localisation en direct uniquement lorsque vous signalez volontairement un incident (Incendie, Accident, Inondation, etc.) ou lors d\'un appel SOS pour nous permettre de dépêcher les secours à votre position exacte.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  lang.isArabic ? 'أمن وحماية بياناتك الشخصية :' : 'Sécurité de vos données :',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.isArabic
                      ? 'جميع الاتصالات مشفرة بالكامل. لا نقوم بمشاركة أو بيع بياناتك لأي طرف ثالث، ويتم تخزينها طبقاً للتشريعات الجاري بها العمل في الجمهورية التونسية (الهيئة الوطنية لحماية المعطيات الشخصية INPDP).'
                      : 'Toutes les communications entre l\'application mobile et nos serveurs sont chiffrées. Vos données de profil et vos coordonnées ne sont jamais vendues à des tiers et sont conservées conformément à la réglementation tunisienne sur la protection des données personnelles (INPDP).',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                lang.isArabic ? 'إغلاق' : 'FERMER',
                style: const TextStyle(color: Color(0xFF1B365D), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
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
    final user = authProvider.user;
    final lang = Provider.of<LanguageProvider>(context);

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(lang.getText('profile_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B365D),
          foregroundColor: Colors.white,
          actions: [
            _buildLanguageSwitch(lang),
            const SizedBox(width: 8),
            if (!_isEditing) ...[
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
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: () => _saveChanges(lang),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _phoneController.text = user?.phone ?? '';
                    _addressController.text = user?.address ?? '';
                    _emergencyNameController.text = user?.emergencyContactName ?? '';
                    _emergencyPhoneController.text = user?.emergencyContactPhone ?? '';
                    _ageController.text = user?.age.toString() ?? '';
                    _medicalInfoController.text = user?.medicalInfo ?? '';
                  });
                },
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top user badge header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B365D).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 50, color: Color(0xFF1B365D)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.fullName ?? (lang.isArabic ? 'مواطن' : 'Citoyen'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0C2340)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE71D36).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'CIN : ${user?.cin != null && user!.cin.length > 3 ? '*' * (user.cin.length - 3) + user.cin.substring(user.cin.length - 3) : user?.cin ?? ''}',
                                style: const TextStyle(color: Color(0xFFE71D36), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: (user?.isVolunteer == true)
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (user?.isVolunteer == true)
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (user?.isVolunteer == true)
                                    ? (lang.isArabic ? 'متطوع' : 'Bénévole')
                                    : (lang.isArabic ? 'غير متطوع' : 'Non bénévole'),
                                style: TextStyle(
                                  color: (user?.isVolunteer == true) ? Colors.green[700] : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Card 1: Coordonnées de Contact
                  _buildCardSection(
                    title: lang.isArabic ? 'معلومات الاتصال' : 'Coordonnées',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      if (!_isEditing) ...[
                        _buildInfoRow(lang.getText('phone_number'), user?.phone ?? '', lang),
                        _buildInfoRow(lang.getText('email_address'), user?.email ?? '', lang),
                        _buildInfoRow(lang.getText('address'), user?.address ?? '', lang),
                      ] else ...[
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(labelText: lang.getText('phone_number')),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.trim().isEmpty ? (lang.isArabic ? 'مطلوب.' : 'Requis.') : null,
                        ),
                        const SizedBox(height: 12),
                        _buildReadOnlyRow(lang.getText('email_address'), user?.email ?? ''),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(labelText: lang.getText('address')),
                          maxLines: 2,
                          validator: (value) => value == null || value.trim().isEmpty ? (lang.isArabic ? 'مطلوب.' : 'Requis.') : null,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Card 2: Zone Administrative
                  _buildCardSection(
                    title: lang.isArabic ? 'المنطقة الإدارية' : 'Zone Administrative (Fixe)',
                    icon: Icons.map_outlined,
                    children: [
                      _buildInfoRow(lang.getText('governorate'), user?.governorate ?? '', lang),
                      _buildInfoRow(lang.getText('delegation'), user?.delegation ?? '', lang),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Card 3: Médical & Urgence
                  _buildCardSection(
                    title: lang.isArabic ? 'الصحة والطوارئ' : 'Santé & Urgence',
                    icon: Icons.health_and_safety_outlined,
                    children: [
                      _buildInfoRow(lang.getText('blood_type'), user?.bloodType ?? '', lang),
                      if (!_isEditing) ...[
                        _buildInfoRow(lang.getText('age'), '${user?.age ?? 0} ${lang.isArabic ? 'سنة' : 'ans'}', lang),
                        _buildInfoRow(lang.getText('medical_info'), user?.medicalInfo != null && user!.medicalInfo.isNotEmpty ? user.medicalInfo : lang.isArabic ? 'لا يوجد' : 'Aucune', lang),
                        _buildInfoRow(lang.getText('emergency_contact_name'), user?.emergencyContactName ?? '', lang),
                        _buildInfoRow(lang.getText('emergency_contact_phone'), user?.emergencyContactPhone ?? '', lang),
                      ] else ...[
                        const SizedBox(height: 8),
                        _buildReadOnlyRow(lang.getText('blood_type'), user?.bloodType ?? ''),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ageController,
                          decoration: InputDecoration(labelText: lang.getText('age')),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return (lang.isArabic ? 'مطلوب.' : 'Requis.');
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) return (lang.isArabic ? 'الرجاء إدخال عمر صحيح.' : 'Veuillez saisir un âge valide.');
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _medicalInfoController,
                          decoration: InputDecoration(labelText: lang.getText('medical_info')),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emergencyNameController,
                          decoration: InputDecoration(labelText: lang.getText('emergency_contact_name')),
                          validator: (value) => value == null || value.trim().isEmpty ? (lang.isArabic ? 'مطلوب.' : 'Requis.') : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          decoration: InputDecoration(labelText: lang.getText('emergency_contact_phone')),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.trim().isEmpty ? (lang.isArabic ? 'مطلوب.' : 'Requis.') : null,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Other Actions
                  OutlinedButton.icon(
                    onPressed: () => _showPrivacyPolicy(lang),
                    icon: const Icon(Icons.privacy_tip_outlined, color: Colors.blueGrey),
                    label: Text(
                      lang.isArabic ? 'الخصوصية وحماية البيانات' : 'Confidentialité & Données',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueGrey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Log out
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.orange),
                    label: Text(
                      lang.isArabic ? 'تسجيل الخروج' : 'Se déconnecter',
                      style: const TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Delete Account
                  ElevatedButton.icon(
                    onPressed: () => _confirmDeleteAccount(lang),
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: Text(
                      lang.isArabic ? 'حذف حساب المواطن الخاص بي' : 'Supprimer mon compte citoyen',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B365D), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? (lang.isArabic ? 'لم يحدد' : 'Non renseigné') : value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0C2340), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
