class DoctorModel {
  final String id;
  final String specialtyId;
  final String clinicId;
  final String fullName;
  final String? sipNumber;
  final String? bio;
  final String? photoUrl;
  final String? specialtyName;
  final String? clinicName;
  final bool isActive;

  const DoctorModel({
    required this.id,
    required this.specialtyId,
    required this.clinicId,
    required this.fullName,
    this.sipNumber,
    this.bio,
    this.photoUrl,
    this.specialtyName,
    this.clinicName,
    this.isActive = true,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      specialtyId: json['specialty_id'] as String,
      clinicId: json['clinic_id'] as String,
      fullName: json['full_name'] as String,
      sipNumber: json['sip_number'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      specialtyName: json['specialties'] != null
          ? (json['specialties'] as Map<String, dynamic>)['name'] as String?
          : null,
      clinicName: json['clinics'] != null
          ? (json['clinics'] as Map<String, dynamic>)['name'] as String?
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'specialty_id': specialtyId,
    'clinic_id': clinicId,
    'full_name': fullName,
    'sip_number': sipNumber,
    'bio': bio,
    'photo_url': photoUrl,
    'is_active': isActive,
  };
}
