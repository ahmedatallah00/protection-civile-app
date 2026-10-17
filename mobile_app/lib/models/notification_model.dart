class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String targetType;
  final String? governorate;
  final String? userPhone;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.targetType,
    this.governorate,
    this.userPhone,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetType: json['targetType'] ?? 'all',
      governorate: json['governorate'],
      userPhone: json['userPhone'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
