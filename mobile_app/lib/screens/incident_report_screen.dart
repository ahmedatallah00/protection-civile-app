import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../providers/language_provider.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  String? _selectedType;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  File? _mediaFile;
  bool _isSubmitting = false;

  // Text description and Voice note variables
  final TextEditingController _descriptionController = TextEditingController();
  File? _voiceFile;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Mock player variables
  bool _isPlaying = false;
  double _playProgress = 0.0;
  Timer? _playTimer;

  final List<Map<String, dynamic>> _incidentTypes = [
    {'id': 'fire', 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'id': 'accident', 'icon': Icons.car_crash, 'color': Colors.orange},
    {'id': 'flood', 'icon': Icons.water, 'color': Colors.blue},
    {'id': 'collapse', 'icon': Icons.domain_disabled, 'color': Colors.brown},
    {'id': 'rescue', 'icon': Icons.medical_services, 'color': Colors.green},
    {'id': 'other', 'icon': Icons.help_outline, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _recordingTimer?.cancel();
    _playTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // Fetch live GPS location
  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final position = await _locationService.getCurrentLocation();
    
    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
    });
  }

  String _getTypeLabel(String id, LanguageProvider lang) {
    switch (id) {
      case 'fire':
        return lang.isArabic ? 'حريق' : 'Incendie';
      case 'accident':
        return lang.isArabic ? 'حادث مرور' : 'Accident';
      case 'flood':
        return lang.isArabic ? 'فيضان' : 'Inondation';
      case 'collapse':
        return lang.isArabic ? 'انهيار' : 'Effondrement';
      case 'rescue':
        return lang.isArabic ? 'نجدة وإسعاف' : 'Secours';
      case 'other':
      default:
        return lang.isArabic ? 'آخر' : 'Autre';
    }
  }

  // Pick image/video
  Future<void> _pickMedia(ImageSource source, LanguageProvider lang, {bool isVideo = false}) async {
    try {
      XFile? file;
      if (isVideo) {
        file = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 30));
      } else {
        file = await _picker.pickImage(source: source, imageQuality: 80);
      }

      if (file != null) {
        setState(() {
          _mediaFile = File(file!.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.isArabic ? 'تعذر الوصول إلى الكاميرا أو المعرض.' : 'Impossible d\'accéder à l\'appareil photo ou à la galerie.')),
      );
    }
  }

  // Audio recording methods using record package
  Future<void> _startRecording() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = Directory.systemTemp;
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
          _voiceFile = null;
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.isArabic ? 'الرجاء تفعيل إذن تسجيل الصوت.' : 'Veuillez autoriser l\'enregistrement audio.')),
        );
      }
    } catch (e) {
      print("AUDIO RECORD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.isArabic ? 'خطأ في بدء التسجيل: $e' : 'Erreur lors du démarrage de l\'enregistrement: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _voiceFile = File(path);
        });
      } else {
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.isArabic ? 'خطأ في إيقاف التسجيل.' : 'Erreur lors de l\'arrêt de l\'enregistrement.')),
      );
    }
  }

  void _deleteVoiceNote() {
    _playTimer?.cancel();
    setState(() {
      _voiceFile = null;
      _isPlaying = false;
      _playProgress = 0.0;
    });
  }

  void _togglePlayVoiceNote() {
    if (_isPlaying) {
      _playTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
        if (_playProgress >= 1.0) _playProgress = 0.0;
      });
      const totalTicks = 50;
      final tickDuration = Duration(milliseconds: (_recordingSeconds * 1000) ~/ totalTicks);
      _playTimer = Timer.periodic(tickDuration, (timer) {
        setState(() {
          _playProgress += 1.0 / totalTicks;
          if (_playProgress >= 1.0) {
            _playProgress = 1.0;
            _isPlaying = false;
            timer.cancel();
          }
        });
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Submit Incident Report
  Future<void> _submitReport(LanguageProvider lang) async {
    if (_selectedType == null || _currentPosition == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final responseStream = await _apiService.reportIncident(
        type: _selectedType!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text.trim() : null,
        mediaFile: _mediaFile,
        voiceFile: _voiceFile,
      );

      final response = await httpResponseFromStream(responseStream);

      if (response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog(lang);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang.isArabic ? 'حدث خطأ أثناء إرسال البلاغ.' : 'Erreur lors de la soumission du rapport.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.isArabic ? 'حدث خطأ في الشبكة أثناء الإرسال.' : 'Erreur réseau lors de la soumission.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Convert streamed response to standard response helper
  Future<dynamic> httpResponseFromStream(dynamic streamResponse) async {
    final responseBytes = await streamResponse.stream.toBytes();
    final responseString = String.fromCharCodes(responseBytes);
    return _MockResponse(streamResponse.statusCode, responseString);
  }

  void _showSuccessDialog(LanguageProvider lang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Text(
                lang.isArabic ? 'تم إرسال البلاغ' : 'Signalement Envoyé',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            lang.isArabic
                ? 'تم إرسال بلاغك بنجاح إلى مصالح الحماية المدنية. تم إخطار فرق الإنقاذ بموقعك الجغرافي.'
                : 'Votre signalement a été transmis avec succès aux services de la Protection Civile. Les secours ont été notifiés de votre position GPS.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B365D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
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
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isFormValid = _selectedType != null && _currentPosition != null;

    return Directionality(
      textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text(
            lang.isArabic ? 'الإبلاغ عن حادث' : 'Signaler un Incident',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1B365D),
          foregroundColor: Colors.white,
          actions: [
            _buildLanguageSwitch(lang),
            const SizedBox(width: 15),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step 1: Selection du type d'incident
                Text(
                  lang.isArabic ? '١. نوع الحادث' : '1. Type d\'incident',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _incidentTypes.length,
                  itemBuilder: (context, index) {
                    final type = _incidentTypes[index];
                    final isSelected = _selectedType == type['id'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = type['id'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? type['color'].withOpacity(0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? type['color'] : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type['icon'],
                              color: isSelected ? type['color'] : Colors.grey[700],
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getTypeLabel(type['id'], lang),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? type['color'] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Step 2: Preuves Médias (Photo/Vidéo)
                Text(
                  lang.isArabic ? '٢. دليل الوسائط (اختياري)' : '2. Preuve multimédia (Optionnel)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      if (_mediaFile != null) ...[
                        // Media preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              _mediaFile!.path.endsWith('.mp4') || _mediaFile!.path.endsWith('.mov')
                                  ? Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: Colors.black,
                                      child: const Center(
                                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                                      ),
                                    )
                                  : Image.file(
                                      _mediaFile!,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
                                onPressed: () {
                                  setState(() {
                                    _mediaFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _mediaFile!.path.split('/').last,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        // Option buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickMedia(ImageSource.camera, lang),
                                icon: const Icon(Icons.camera_alt),
                                label: Text(lang.isArabic ? 'صورة' : 'Photo'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.primaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickMedia(ImageSource.camera, lang, isVideo: true),
                                icon: const Icon(Icons.videocam),
                                label: Text(lang.isArabic ? 'فيديو' : 'Vidéo'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.primaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _pickMedia(ImageSource.gallery, lang),
                          icon: const Icon(Icons.photo_library),
                          label: Text(lang.isArabic ? 'اختر من المعرض' : 'Choisir de la galerie'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Step 3: Description textuelle ou vocale (Optionnel)
                Text(
                  lang.isArabic ? '٣. وصف الحادث أو رسالة صوتية (اختياري)' : '3. Description textuelle ou vocale (Optionnel)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Text Description Input
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: lang.isArabic ? 'تفاصيل ووصف الحادث' : 'Description de l\'incident',
                          hintText: lang.isArabic ? 'اكتب هنا أي تفاصيل إضافية...' : 'Saisissez des détails supplémentaires...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Voice note recorder simulator
                      if (_voiceFile == null && !_isRecording) ...[
                        OutlinedButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.mic, color: Color(0xFFE71D36)),
                          label: Text(
                            lang.isArabic ? 'تسجيل رسالة صوتية' : 'Enregistrer une note vocale',
                            style: const TextStyle(color: Color(0xFFE71D36)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE71D36)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ] else if (_isRecording) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang.isArabic ? 'جاري التسجيل... ' : 'Enregistrement... ',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                  Text(
                                    _formatDuration(_recordingSeconds),
                                    style: const TextStyle(fontFamily: 'monospace', color: Colors.red),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop, color: Colors.red, size: 28),
                                onPressed: _stopRecording,
                              ),
                            ],
                          ),
                        ),
                      ] else if (_voiceFile != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B365D).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B365D).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: const Color(0xFF1B365D),
                                ),
                                onPressed: _togglePlayVoiceNote,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.isArabic ? 'رسالة صوتية مسجلة' : 'Message vocal enregistré',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B365D)),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: _playProgress,
                                      backgroundColor: Colors.grey[300],
                                      color: const Color(0xFF1B365D),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDuration(_recordingSeconds),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: _deleteVoiceNote,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Step 4: Localisation GPS
                Text(
                  lang.isArabic ? '٤. الموقع الجغرافي (GPS)' : '4. Localisation GPS',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _currentPosition != null ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentPosition != null ? Icons.gps_fixed : Icons.gps_off,
                          color: _currentPosition != null ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isLoadingLocation) ...[
                              const SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang.isArabic ? 'جاري البحث عن الإحداثيات...' : 'Recherche des coordonnées...',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ] else if (_currentPosition != null) ...[
                              Text(
                                '${lang.isArabic ? 'خط العرض' : 'Latitude'}: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                              ),
                              Text(
                                '${lang.isArabic ? 'خط الطول' : 'Longitude'}: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                              ),
                              Text(
                                lang.isArabic ? 'تم تحديد الموقع بنجاح' : 'Localisation acquise avec succès',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                            ] else ...[
                              Text(
                                lang.isArabic ? 'تعذر العثور على الإحداثيات' : 'Coordonnées introuvables',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              Text(
                                lang.isArabic ? 'قم بتفعيل الـ GPS لإرسال البلاغ.' : 'Activez le GPS pour envoyer le rapport.',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ]
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF1B365D)),
                        onPressed: _isLoadingLocation ? null : _fetchLocation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Submit Button
                ElevatedButton(
                  onPressed: (!isFormValid || _isSubmitting) ? null : () => _submitReport(lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B365D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          lang.isArabic ? 'إرسال البلاغ' : 'Soumettre le signalement',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockResponse {
  final int statusCode;
  final String body;
  _MockResponse(this.statusCode, this.body);
}
