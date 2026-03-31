enum AppointmentStatus {
  requested,
  accepted,
  rejected,
  completed,
  cancelled,
}

enum AppointmentMode {
  inPerson,
  teleconsultation,
}

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String? clinicId;
  final DateTime requestedDatetime;
  final DateTime? confirmedDatetime;
  final AppointmentStatus status;
  final AppointmentMode? mode;
  final String? chiefComplaint;
  final String? rejectionReason;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.clinicId,
    required this.requestedDatetime,
    this.confirmedDatetime,
    required this.status,
    this.mode,
    this.chiefComplaint,
    this.rejectionReason,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      clinicId: json['clinic_id']?.toString(),
      requestedDatetime: DateTime.tryParse(
            json['requested_datetime']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      confirmedDatetime: json['confirmed_datetime'] != null
          ? DateTime.tryParse(json['confirmed_datetime'].toString())
          : null,
      status: _parseStatus(json['status']?.toString()),
      mode: _parseMode(json['appointment_mode']?.toString()),
      chiefComplaint: json['chief_complaint']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static AppointmentStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted':
        return AppointmentStatus.accepted;
      case 'rejected':
        return AppointmentStatus.rejected;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'requested':
      default:
        return AppointmentStatus.requested;
    }
  }

  static AppointmentMode? _parseMode(String? s) {
    switch (s) {
      case 'teleconsultation':
        return AppointmentMode.teleconsultation;
      case 'in_person':
        return AppointmentMode.inPerson;
      default:
        return null;
    }
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.requested:
        return 'Requested';
      case AppointmentStatus.accepted:
        return 'Accepted';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
