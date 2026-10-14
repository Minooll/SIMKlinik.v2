class AppointmentModel {
  final String id;
  final String bookingReference;
  final String patientId;
  final String userId;
  final String scheduleId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final String? doctorName;
  final String? specialtyName;
  final String? clinicName;
  final DateTime? scheduleDate;
  final String? startTime;
  final String? endTime;
  final String? ticketCode;

  const AppointmentModel({
    required this.id,
    required this.bookingReference,
    required this.patientId,
    required this.userId,
    required this.scheduleId,
    required this.status,
    this.notes,
    required this.createdAt,
    this.doctorName,
    this.specialtyName,
    this.clinicName,
    this.scheduleDate,
    this.startTime,
    this.endTime,
    this.ticketCode,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      bookingReference: json['booking_reference'] as String,
      patientId: json['patient_id'] as String,
      userId: json['user_id'] as String,
      scheduleId: json['schedule_id'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      doctorName: json['doctor_schedules']?['doctors']?['full_name'] as String?,
      specialtyName:
          json['doctor_schedules']?['doctors']?['specialties']?['name']
              as String?,
      clinicName: json['doctor_schedules']?['clinics']?['name'] as String?,
      scheduleDate: json['doctor_schedules']?['schedule_date'] != null
          ? DateTime.parse(json['doctor_schedules']['schedule_date'] as String)
          : null,
      startTime: json['doctor_schedules']?['start_time'] as String?,
      endTime: json['doctor_schedules']?['end_time'] as String?,
      ticketCode:
          json['queue_tickets'] != null &&
              (json['queue_tickets'] as List).isNotEmpty
          ? (json['queue_tickets'] as List).first['ticket_code'] as String?
          : null,
    );
  }
}
