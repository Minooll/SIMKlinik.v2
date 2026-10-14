class PatientProfileModel {
  final String id;
  final String userId;
  final String? nik;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String? phone;
  final String? address;
  final String? bloodType;

  const PatientProfileModel({
    required this.id,
    required this.userId,
    this.nik,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.phone,
    this.address,
    this.bloodType,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nik: json['nik'] as String?,
      fullName: json['full_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      bloodType: json['blood_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'nik': nik,
    'full_name': fullName,
    'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
    'gender': gender,
    'phone': phone,
    'address': address,
    'blood_type': bloodType,
  };
}
