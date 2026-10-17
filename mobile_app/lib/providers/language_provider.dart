import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  void setLanguage(String langCode) {
    _locale = Locale(langCode);
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'fr') {
      _locale = const Locale('ar');
    } else if (_locale.languageCode == 'ar') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('fr');
    }
    notifyListeners();
  }

  String getText(String key) {
    // Fallback English locale to French text for prototype mode
    final code = _locale.languageCode == 'en' ? 'fr' : _locale.languageCode;
    return _localizedValues[code]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'app_title': 'Protection Civile',
      'tunisia_service': 'TUNISIE - Service Citoyen',
      'identifiant_label': 'Identifiant (CIN, Tél ou Email)',
      'password_label': 'Mot de passe',
      'login_button': 'Se connecter',
      'register_prompt': 'Nouveau citoyen ? Créer un compte',
      'create_account': 'CRÉER UN COMPTE',
      'register_button': 'S\'inscrire',
      'login_prompt': 'Déjà inscrit ? Se connecter',
      'full_name': 'Nom complet',
      'cin_number': 'Numéro CIN',
      'phone_number': 'Numéro de Téléphone',
      'email_address': 'Adresse Email',
      'governorate': 'Gouvernorat',
      'delegation': 'Délégation',
      'address': 'Adresse Résidentielle',
      'blood_type': 'Groupe Sanguin',
      'age': 'Âge',
      'medical_info': 'Informations Médicales (Allergies, Maladies...)',
      'emergency_contact_name': 'Nom du contact d\'urgence',
      'emergency_contact_phone': 'Téléphone du contact d\'urgence',
      'consent_text': 'Je consens au partage de ma localisation et de mes données médicales avec la Protection Civile lors d\'un appel SOS.',
      'sos_button': 'S.O.S',
      'sos_subtitle': 'APPUYEZ EN CAS D\'URGENCE',
      'sos_description': 'Envoi immédiat de votre position et de votre fiche d\'urgence',
      'sos_sending': 'ENVOI DU SOS...',
      'live_button': 'Lancer le direct vidéo',
      'live_active': 'DIRECT VIDÉO ACTIVÉ',
      'emergency_numbers': 'Numéros d\'Urgence',
      'prot_civile': 'Protection Civile',
      'police': 'Police Secours',
      'garde_nationale': 'Garde Nationale',
      'samu': 'SAMU',
      'alerts_title': 'Bulletins d\'Alerte',
      'active_zone': 'Zone active : ',
      'no_alerts': 'Aucune alerte active dans votre zone.',
      'expiry_date': 'Expire le: ',
      'notifications_title': 'Messages ONPC',
      'notif_banner_desc': 'Messages et directives de l\'administration',
      'no_notifications': 'Aucun message de la Protection Civile.',
      'notif_target_general': 'Général',
      'notif_target_regional': 'Régional',
      'notif_target_personal': 'Personnel',
      'safety_tips_title': 'Conseils de Sécurité',
      'search_tips': 'Rechercher un conseil...',
      'category_all': 'Tous',
      'category_fire': 'Incendie',
      'category_flood': 'Inondation',
      'category_weather': 'Météo',
      'category_rescue': 'Sauvetage',
      'profile_title': 'Mon Profil Citoyen',
      'emergency_contact_section': 'Contact d\'Urgence',
      'medical_info_section': 'Informations Médicales',
      'personal_info_section': 'Informations Personnelles',
      'edit_profile': 'Modifier le Profil',
      'save_profile': 'Enregistrer',
      'cancel': 'Annuler',
    },
    'ar': {
      'app_title': 'الحماية المدنية',
      'tunisia_service': 'تونس - خدمة المواطن',
      'identifiant_label': 'معرف الحساب (بطاقة التعريف، الهاتف أو البريد)',
      'password_label': 'كلمة المرور',
      'login_button': 'تسجيل الدخول',
      'register_prompt': 'مواطن جديد؟ إنشاء حساب',
      'create_account': 'إنشاء حساب جديد',
      'register_button': 'تسجيل الحساب',
      'login_prompt': 'مسجل بالفعل؟ تسجيل الدخول',
      'full_name': 'الاسم الكامل',
      'cin_number': 'رقم بطاقة التعريف الوطنية',
      'phone_number': 'رقم الهاتف',
      'email_address': 'البريد الإلكتروني',
      'governorate': 'الولاية',
      'delegation': 'المعتمدية',
      'address': 'العنوان السكني',
      'blood_type': 'فصيلة الدم',
      'age': 'العمر',
      'medical_info': 'المعلومات الطبية (الحساسية، الأمراض...)',
      'emergency_contact_name': 'اسم الشخص للاتصال به في حالة الطوارئ',
      'emergency_contact_phone': 'هاتف الشخص للاتصال به في حالة الطوارئ',
      'consent_text': 'أوافق على مشاركة موقعي الجغرافي وبياناتي الطبية مع الحماية المدنية عند طلب نجدة SOS.',
      'sos_button': 'نجدة SOS',
      'sos_subtitle': 'اضغط في حالة الطوارئ',
      'sos_description': 'إرسال فوري لموقعك الجغرافي وملفك الطبي الطارئ',
      'sos_sending': 'جاري إرسال نجدة SOS...',
      'live_button': 'بدء بث مباشر للفيديو',
      'live_active': 'البث المباشر للفيديو نشط',
      'emergency_numbers': 'أرقام الطوارئ',
      'prot_civile': 'الحماية المدنية',
      'police': 'شرطة النجدة',
      'garde_nationale': 'الحرس الوطني',
      'samu': 'النجدة الطبية (SAMU)',
      'alerts_title': 'نشرات اليقظة والإنذارات',
      'active_zone': 'المنطقة النشطة: ',
      'no_alerts': 'لا توجد إنذارات نشطة في منطقتك حالياً.',
      'expiry_date': 'ينتهي في: ',
      'notifications_title': 'رسائل الحماية المدنية',
      'notif_banner_desc': 'رسائل وتوجيهات الإدارة العامة',
      'no_notifications': 'لا توجد رسائل من الحماية المدنية.',
      'notif_target_general': 'عام',
      'notif_target_regional': 'جهوي',
      'notif_target_personal': 'شخصي',
      'safety_tips_title': 'توجيهات ونصائح السلامة',
      'search_tips': 'البحث عن نصيحة...',
      'category_all': 'الكل',
      'category_fire': 'حرائق',
      'category_flood': 'فيضانات',
      'category_weather': 'طقس',
      'category_rescue': 'إنقاذ',
      'profile_title': 'الملف الشخصي للمواطن',
      'emergency_contact_section': 'الجهة الاتصال في الطوارئ',
      'medical_info_section': 'المعلومات الطبية الطارئة',
      'personal_info_section': 'المعلومات الشخصية',
      'edit_profile': 'تعديل الملف',
      'save_profile': 'حفظ التغييرات',
      'cancel': 'إلغاء',
    }
  };
}
