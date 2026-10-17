class UserModel {
  final String id;
  final String fullName;
  final String cin;
  final String phone;
  final String email;
  final String governorate;
  final String delegation;
  final String address;
  final String bloodType;
  final int age;
  final String medicalInfo;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool consentGiven;
  final bool isVolunteer;

  UserModel({
    required this.id,
    required this.fullName,
    required this.cin,
    required this.phone,
    required this.email,
    required this.governorate,
    required this.delegation,
    required this.address,
    required this.bloodType,
    required this.age,
    required this.medicalInfo,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.consentGiven,
    required this.isVolunteer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      cin: json['cin'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      governorate: json['governorate'] ?? '',
      delegation: json['delegation'] ?? '',
      address: json['address'] ?? '',
      bloodType: json['bloodType'] ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      medicalInfo: json['medicalInfo'] ?? '',
      emergencyContactName: json['emergencyContact']?['name'] ?? '',
      emergencyContactPhone: json['emergencyContact']?['phone'] ?? '',
      consentGiven: json['consentGiven'] ?? false,
      isVolunteer: json['isVolunteer'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'cin': cin,
      'phone': phone,
      'email': email,
      'governorate': governorate,
      'delegation': delegation,
      'address': address,
      'bloodType': bloodType,
      'age': age,
      'medicalInfo': medicalInfo,
      'emergencyContact': {
        'name': emergencyContactName,
        'phone': emergencyContactPhone,
      },
      'consentGiven': consentGiven,
      'isVolunteer': isVolunteer,
    };
  }
}
