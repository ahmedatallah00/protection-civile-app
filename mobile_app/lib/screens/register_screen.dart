import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/governorates.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _fullNameController = TextEditingController();
  final _cinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalInfoController = TextEditingController();

  // Dropdown States
  String? _selectedGovernorate;
  String? _selectedDelegation;
  String? _selectedBloodType;
  bool _consentGiven = false;
  bool _isVolunteer = false;

  final List<String> _bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _cinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _ageController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submit(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.isArabic
                ? 'يجب عليك إعطاء موافقتك لمشاركة البيانات الطبية والموقع في حالات SOS.'
                : 'Vous devez donner votre consentement pour le partage des données médicales et de localisation en cas de SOS.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final userData = {
      'fullName': _fullNameController.text.trim(),
      'cin': _cinController.text.trim().toUpperCase(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _cinController.text.trim().toUpperCase(),
      'governorate': _selectedGovernorate,
      'delegation': _selectedDelegation,
      'address': _addressController.text.trim(),
      'bloodType': _selectedBloodType,
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'medicalInfo': _medicalInfoController.text.trim(),
      'emergencyContact': {
        'name': _emergencyNameController.text.trim(),
        'phone': _emergencyPhoneController.text.trim(),
      },
      'consentGiven': _consentGiven,
      'isVolunteer': _isVolunteer,
    };

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final otpSent = await authProvider.sendOtp(
      _phoneController.text.trim(),
      _cinController.text.trim().toUpperCase(),
    );

    if (mounted) {
      Navigator.pop(context); // Close spinner
    }

    if (otpSent && mounted) {
      _showOtpDialog(userData, lang, authProvider);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? (lang.isArabic ? 'فشل إرسال رمز التحقق.' : 'Échec de l\'envoi du code OTP.')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showOtpDialog(Map<String, dynamic> userData, LanguageProvider lang, AuthProvider authProvider) async {
    final otpController = TextEditingController();
    final localFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(lang.isArabic ? 'التحقق من الهاتف' : 'Vérification du téléphone'),
            content: Form(
              key: localFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.isArabic
                        ? 'أدخل رمز التحقق (OTP) المكون من 6 أرقام المرسل إلى هاتفك :'
                        : 'Veuillez saisir le code de vérification (OTP) à 6 chiffres envoyé à votre numéro :',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length != 6) {
                        return lang.isArabic ? 'الرجاء إدخال رمز مكون من 6 أرقام' : 'Code de 6 chiffres requis';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.isArabic ? 'إلغاء' : 'Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!localFormKey.currentState!.validate()) return;
                  
                  final otp = otpController.text.trim();
                  userData['otpCode'] = otp;
                  
                  Navigator.pop(context); // Close OTP Dialog
                  
                  // Show loading spinner
                  showDialog(
                    context: this.context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  final success = await authProvider.register(userData);
                  
                  if (this.mounted) {
                    Navigator.pop(this.context); // Close spinner
                  }
                  
                  if (success && this.mounted) {
                    Navigator.pushNamedAndRemoveUntil(this.context, '/home', (route) => false);
                  } else if (this.mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.error ?? (lang.isArabic ? 'رمز التحقق غير صحيح.' : 'Code de vérification incorrect.')),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Text(lang.isArabic ? 'تأكيد' : 'Confirmer'),
              ),
            ],
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
    final lang = Provider.of<LanguageProvider>(context);

    // Get delegations list based on selected governorate
    List<String> delegations = [];
    if (_selectedGovernorate != null && governoratesData.containsKey(_selectedGovernorate)) {
      delegations = governoratesData[_selectedGovernorate]!;
    }

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(lang.getText('create_account'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B365D),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            _buildLanguageSwitch(lang),
            const SizedBox(width: 16),
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
                  // Section 1: Informations Personnelles
                  _buildCardSection(
                    title: lang.getText('personal_info_section'),
                    icon: Icons.person_outline,
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: lang.getText('full_name'),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return lang.isArabic ? 'هذا الحقل مطلوب.' : 'Ce champ est requis.';
                          }
                          if (value.trim().split(' ').length < 2) {
                            return lang.isArabic ? 'الرجاء إدخال الاسم الكامل (الاسم واللقب).' : 'Veuillez saisir votre nom complet.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cinController,
                        decoration: InputDecoration(
                          labelText: lang.getText('cin_number'),
                          prefixIcon: const Icon(Icons.fingerprint_outlined),
                          hintText: lang.isArabic ? '8 أرقام (مثال: 01234567)' : '8 chiffres (ex: 01234567)',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return lang.isArabic ? 'هذا الحقل مطلوب.' : 'Ce champ est requis.';
                          }
                          if (value.trim().length != 8) {
                            return lang.isArabic ? 'يجب أن تتكون بطاقة التعريف من 8 أرقام.' : 'La CIN doit comporter exactement 8 chiffres.';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return lang.isArabic ? 'يجب أن تكون بطاقة التعريف رقمية فقط.' : 'La CIN doit être numérique.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: lang.getText('phone_number'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          hintText: 'Ex: 99123456',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return lang.isArabic ? 'هذا الحقل مطلوب.' : 'Ce champ est requis.';
                          }
                          if (value.trim().length < 8) {
                            return lang.isArabic ? 'رقم هاتف غير صالح (على الأقل 8 أرقام).' : 'Numéro invalide (minimum 8 chiffres).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: lang.getText('email_address'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return lang.isArabic ? 'هذا الحقل مطلوب.' : 'Ce champ est requis.';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return lang.isArabic ? 'صيغة البريد الإلكتروني غير صالحة.' : 'Format d\'email invalide.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Localisation
                  _buildCardSection(
                    title: lang.isArabic ? 'الموقع الجغرافي' : 'Localisation',
                    icon: Icons.location_on_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedGovernorate,
                        hint: Text(lang.isArabic ? 'اختر الولاية' : 'Sélectionner le Gouvernorat'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        dropdownColor: Colors.white,
                        items: governoratesData.keys.map((String gov) {
                          return DropdownMenuItem<String>(
                            value: gov,
                            child: Text(gov),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGovernorate = value;
                            _selectedDelegation = null; // Reset delegation on gov change
                          });
                        },
                        validator: (value) => value == null ? (lang.isArabic ? 'الرجاء اختيار الولاية.' : 'Veuillez sélectionner un gouvernorat.') : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDelegation,
                        hint: Text(lang.isArabic ? 'اختر المعتمدية' : 'Sélectionner la Délégation'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        dropdownColor: Colors.white,
                        items: delegations.map((String del) {
                          return DropdownMenuItem<String>(
                            value: del,
                            child: Text(del),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDelegation = value;
                          });
                        },
                        validator: (value) => value == null ? (lang.isArabic ? 'الرجاء اختيار المعتمدية.' : 'Veuillez sélectionner une délégation.') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: lang.getText('address'),
                          prefixIcon: const Icon(Icons.home_outlined),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? (lang.isArabic ? 'الرجاء إدخال عنوانك السكني.' : 'Veuillez saisir votre adresse.')
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Fiche Médicale
                  _buildCardSection(
                    title: lang.getText('medical_info_section'),
                    icon: Icons.medical_services_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        hint: Text(lang.isArabic ? 'اختر فصيلة الدم' : 'Sélectionner le Groupe Sanguin'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.bloodtype_outlined),
                        ),
                        dropdownColor: Colors.white,
                        items: _bloodTypes.map((String blood) {
                          return DropdownMenuItem<String>(
                            value: blood,
                            child: Text(blood),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBloodType = value;
                          });
                        },
                        validator: (value) => value == null ? (lang.isArabic ? 'الرجاء اختيار فصيلة الدم.' : 'Veuillez sélectionner un groupe sanguin.') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: lang.getText('age'),
                          prefixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return lang.isArabic ? 'هذا الحقل مطلوب.' : 'Ce champ est requis.';
                          }
                          final parsedAge = int.tryParse(value.trim());
                          if (parsedAge == null || parsedAge <= 0 || parsedAge > 120) {
                            return lang.isArabic ? 'الرجاء إدخال عمر صحيح.' : 'Veuillez saisir un âge valide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _medicalInfoController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: lang.getText('medical_info'),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 24.0),
                            child: Icon(Icons.description_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Contact d'Urgence
                  _buildCardSection(
                    title: lang.getText('emergency_contact_section'),
                    icon: Icons.contact_emergency_outlined,
                    children: [
                      TextFormField(
                        controller: _emergencyNameController,
                        decoration: InputDecoration(
                          labelText: lang.getText('emergency_contact_name'),
                          prefixIcon: const Icon(Icons.contact_phone_outlined),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? (lang.isArabic ? 'الرجاء إدخال اسم الشخص للاتصال به عند الطوارئ.' : 'Veuillez saisir le nom de votre contact d\'urgence.')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyPhoneController,
                        decoration: InputDecoration(
                          labelText: lang.getText('emergency_contact_phone'),
                          prefixIcon: const Icon(Icons.phone_android_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return lang.isArabic ? 'هذا الحقل مطلوب.' : 'Ce champ est requis.';
                          }
                          if (value.trim().length < 8) {
                            return lang.isArabic ? 'رقم هاتف غير صالح.' : 'Numéro invalide.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Consent Checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        lang.getText('consent_text'),
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      value: _consentGiven,
                      activeColor: const Color(0xFF1B365D),
                      onChanged: (value) {
                        setState(() {
                          _consentGiven = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Volunteer Checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        lang.isArabic
                            ? 'هل تريد التطوع كمساعد للحماية المدنية؟ (متطوع)'
                            : 'Souhaitez-vous être bénévole pour la Protection Civile ?',
                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      value: _isVolunteer,
                      activeColor: const Color(0xFF1B365D),
                      onChanged: (value) {
                        setState(() {
                          _isVolunteer = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : () => _submit(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D36), // Tunisian Red
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            lang.getText('register_button'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                Icon(icon, color: const Color(0xFF1B365D), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B365D),
                  ),
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
}
