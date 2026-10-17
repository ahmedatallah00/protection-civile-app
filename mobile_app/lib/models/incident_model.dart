class IncidentModel {
  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final String? mediaUrl;
  final String status;
  final String reporterId;
  final DateTime createdAt;

  IncidentModel({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.mediaUrl,
    required this.status,
    required this.reporterId,
    required this.createdAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    // Geolocation from backend is GeoJSON: { type: "Point", coordinates: [lng, lat] }
    double lat = 0.0;
    double lng = 0.0;
    if (json['geolocation'] != null && json['geolocation']['coordinates'] != null) {
      final coords = json['geolocation']['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    return IncidentModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      latitude: lat,
      longitude: lng,
      mediaUrl: json['mediaUrl'],
      status: json['status'] ?? 'pending',
      reporterId: json['reporter'] is Map ? (json['reporter']['_id'] ?? '') : (json['reporter'] ?? ''),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
