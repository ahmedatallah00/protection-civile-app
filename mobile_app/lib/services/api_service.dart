import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;

  // Retrieve token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get common authorization headers
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // POST: Send OTP verification code
  Future<http.Response> sendOtp(String phone, String cin) async {
    final url = Uri.parse('$baseUrl/auth/send-otp');
    final response = await http.post(
      url,
      headers: await _getHeaders(requireAuth: false),
      body: jsonEncode({
        'phone': phone,
        'cin': cin,
      }),
    );
    return response;
  }

  // POST: Register User
  Future<http.Response> register(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: await _getHeaders(requireAuth: false),
      body: jsonEncode(userData),
    );
    return response;
  }

  // POST: Login User
  Future<http.Response> login(String identifier, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(requireAuth: false),
      body: jsonEncode({
        'identifier': identifier, // can be email, phone or CIN
        'password': password,
      }),
    );
    return response;
  }

  // GET: Fetch User Profile
  Future<http.Response> getProfile() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await http.get(
      url,
      headers: await _getHeaders(requireAuth: true),
    );
    return response;
  }

  // PUT: Update User Profile
  Future<http.Response> updateProfile(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await http.put(
      url,
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode(userData),
    );
    return response;
  }

  // DELETE: Delete Account
  Future<http.Response> deleteAccount() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await http.delete(
      url,
      headers: await _getHeaders(requireAuth: true),
    );
    return response;
  }

  // GET: Fetch all alerts
  Future<http.Response> getAlerts() async {
    final url = Uri.parse('$baseUrl/alerts');
    final response = await http.get(
      url,
      headers: await _getHeaders(requireAuth: false),
    );
    return response;
  }

  // GET: Fetch alerts for specific governorate
  Future<http.Response> getAlertsByZone(String governorate) async {
    final url = Uri.parse('$baseUrl/alerts/zone/$governorate');
    final response = await http.get(
      url,
      headers: await _getHeaders(requireAuth: false),
    );
    return response;
  }

  // GET: Fetch targeted notifications for user
  Future<http.Response> getNotifications() async {
    final url = Uri.parse('$baseUrl/notifications');
    final response = await http.get(
      url,
      headers: await _getHeaders(requireAuth: true),
    );
    return response;
  }

  // POST: Report Incident with optional media file, voice note and GPS coordinates
  Future<http.StreamedResponse> reportIncident({
    required String type,
    required double latitude,
    required double longitude,
    String? description,
    File? mediaFile,
    File? voiceFile,
  }) async {
    final url = Uri.parse('$baseUrl/incidents');
    final token = await _getToken();

    final request = http.MultipartRequest('POST', url);
    
    // Add auth header
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add fields
    request.fields['type'] = type;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (description != null) {
      request.fields['description'] = description;
    }

    // Add media file if provided
    if (mediaFile != null) {
      final fileStream = http.ByteStream(mediaFile.openRead());
      final length = await mediaFile.length();
      
      String mimeType = 'image/jpeg';
      final extension = mediaFile.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'mp4') {
        mimeType = 'video/mp4';
      } else if (extension == 'mov') {
        mimeType = 'video/quicktime';
      } else if (extension == 'avi') {
        mimeType = 'video/x-msvideo';
      } else if (extension == 'webm') {
        mimeType = 'video/webm';
      }
      
      final multipartFile = http.MultipartFile(
        'media', // Must match the multer field name on the backend
        fileStream,
        length,
        filename: mediaFile.path.split(Platform.pathSeparator).last,
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
    }

    // Add voice file if provided
    if (voiceFile != null) {
      final fileStream = http.ByteStream(voiceFile.openRead());
      final length = await voiceFile.length();
      
      String mimeType = 'audio/mpeg';
      final extension = voiceFile.path.split('.').last.toLowerCase();
      if (extension == 'wav') {
        mimeType = 'audio/wav';
      } else if (extension == 'm4a') {
        mimeType = 'audio/mp4';
      } else if (extension == 'aac') {
        mimeType = 'audio/aac';
      }
      
      final multipartFile = http.MultipartFile(
        'voice', // Must match the multer field name on the backend
        fileStream,
        length,
        filename: voiceFile.path.split(Platform.pathSeparator).last,
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
    }

    return await request.send();
  }

  // GET: Fetch User's reported incidents
  Future<http.Response> getMyIncidents() async {
    final url = Uri.parse('$baseUrl/incidents/mine');
    final response = await http.get(
      url,
      headers: await _getHeaders(requireAuth: true),
    );
    return response;
  }

  // POST: Start Live Stream
  Future<http.Response> startLive(double latitude, double longitude) async {
    final url = Uri.parse('$baseUrl/lives/start');
    final response = await http.post(
      url,
      headers: await _getHeaders(requireAuth: true),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return response;
  }

  // POST: Stop Live Stream
  Future<http.Response> stopLive() async {
    final url = Uri.parse('$baseUrl/lives/stop');
    final response = await http.post(
      url,
      headers: await _getHeaders(requireAuth: true),
    );
    return response;
  }

  // POST: Upload Camera Frame (raw image bytes)
  Future<http.Response> uploadFrame(List<int> imageBytes) async {
    final url = Uri.parse('$baseUrl/lives/frame');
    final headers = await _getHeaders(requireAuth: true);
    headers['Content-Type'] = 'image/jpeg';
    
    final response = await http.post(
      url,
      headers: headers,
      body: imageBytes,
    );
    return response;
  }

  // GET: Fetch safety tips from backend
  Future<http.Response> getSafetyTips() async {
    final url = Uri.parse('$baseUrl/safety-tips');
    final response = await http.get(
      url,
      headers: await _getHeaders(requireAuth: true),
    );
    return response;
  }
}
