class ScheduleModel {
  final String id;
  final String clinicId;
  final String doctorId;
  final DateTime scheduleDate;
  final String startTime;
  final String endTime;
  final int capacity;
  final int bookedCount;
  final String status;
  final String? doctorName;
  final String? specialtyName;

  const ScheduleModel({
    required this.id,
    required this.clinicId,
    required this.doctorId,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.bookedCount,
    required this.status,
    this.doctorName,
    this.specialtyName,
  });

  int get availableSlots => (capacity - bookedCount).clamp(0, capacity);
  bool get isAvailable => status == 'available' && availableSlots > 0;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      doctorId: json['doctor_id'] as String,
      scheduleDate: DateTime.parse(json['schedule_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      capacity: json['capacity'] as int,
      bookedCount: json['booked_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'available',
      doctorName: json['doctors'] != null
          ? (json['doctors'] as Map<String, dynamic>)['full_name'] as String?
          : null,
      specialtyName: json['doctors']?['specialties'] != null
          ? (json['doctors']['specialties'] as Map<String, dynamic>)['name']
                as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clinic_id': clinicId,
    'doctor_id': doctorId,
    'schedule_date': scheduleDate.toIso8601String().split('T').first,
    'start_time': startTime,
    'end_time': endTime,
    'capacity': capacity,
    'booked_count': bookedCount,
    'status': status,
  };
}
