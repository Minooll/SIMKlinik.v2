class QueueTicketModel {
  final String id;
  final String queueSessionId;
  final String? appointmentId;
  final String patientId;
  final String userId;
  final int ticketNumber;
  final String ticketCode;
  final String qrToken;
  final String status;
  final DateTime? checkedInAt;
  final DateTime? calledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? estimatedWaitMinutes;
  final DateTime createdAt;
  final String? patientName;
  final String? doctorName;
  final String? specialtyName;
  final String? clinicName;
  final int currentSessionNumber;

  const QueueTicketModel({
    required this.id,
    required this.queueSessionId,
    this.appointmentId,
    required this.patientId,
    required this.userId,
    required this.ticketNumber,
    required this.ticketCode,
    required this.qrToken,
    required this.status,
    this.checkedInAt,
    this.calledAt,
    this.startedAt,
    this.completedAt,
    this.estimatedWaitMinutes,
    required this.createdAt,
    this.patientName,
    this.doctorName,
    this.specialtyName,
    this.clinicName,
    this.currentSessionNumber = 0,
  });

  int get peopleAhead => (ticketNumber - currentSessionNumber - 1).clamp(0, 99);

  factory QueueTicketModel.fromJson(Map<String, dynamic> json) {
    return QueueTicketModel(
      id: json['id'] as String,
      queueSessionId: json['queue_session_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      patientId: json['patient_id'] as String,
      userId: json['user_id'] as String,
      ticketNumber: json['ticket_number'] as int,
      ticketCode: json['ticket_code'] as String,
      qrToken: json['qr_token'] as String,
      status: json['status'] as String,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      calledAt: json['called_at'] != null
          ? DateTime.parse(json['called_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientName: json['patient_profiles']?['full_name'] as String?,
      doctorName: json['queue_sessions']?['doctors']?['full_name'] as String?,
      specialtyName:
          json['queue_sessions']?['doctors']?['specialties']?['name']
              as String?,
      clinicName: json['queue_sessions']?['clinics']?['name'] as String?,
      currentSessionNumber:
          json['queue_sessions']?['current_ticket_number'] as int? ?? 0,
    );
  }
}
