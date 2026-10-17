class AlertModel {
  final String id;
  final String title;
  final String message;
  final String governorate;
  final String severity;
  final String category;
  final DateTime expiryDate;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.governorate,
    required this.severity,
    required this.category,
    required this.expiryDate,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      governorate: json['governorate'] ?? 'all',
      severity: json['severity'] ?? 'medium',
      category: json['category'] ?? 'general',
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
