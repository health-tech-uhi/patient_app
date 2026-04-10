/// Consultation summary list row from `GET /api/records/me/summaries`.
class ConsultationSummaryListItem {
  const ConsultationSummaryListItem({
    required this.id,
    required this.appointmentId,
    required this.consultationDate,
    this.doctorName,
    this.chiefComplaint,
  });

  final String id;
  final String appointmentId;
  final String? doctorName;
  final DateTime consultationDate;
  final String? chiefComplaint;

  factory ConsultationSummaryListItem.fromJson(Map<String, dynamic> json) {
    return ConsultationSummaryListItem(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      doctorName: json['doctor_name'] as String?,
      consultationDate: DateTime.parse(json['consultation_date'] as String),
      chiefComplaint: json['chief_complaint'] as String?,
    );
  }
}

/// Full consultation summary from `GET /api/records/me/summary/:summary_id`.
class ConsultationSummaryDetail {
  const ConsultationSummaryDetail({
    required this.id,
    required this.appointmentId,
    required this.consultationDate,
    this.doctorName,
    this.chiefComplaint,
    this.assessment,
    this.plan,
    this.diagnoses,
    this.medications,
    this.vitals,
    this.followUp,
    this.pdfDownloadUrl,
    this.approvedAt,
  });

  final String id;
  final String appointmentId;
  final String? doctorName;
  final DateTime consultationDate;
  final String? chiefComplaint;
  final String? assessment;
  final String? plan;
  final dynamic diagnoses;
  final dynamic medications;
  final dynamic vitals;
  final dynamic followUp;
  final String? pdfDownloadUrl;
  final DateTime? approvedAt;

  factory ConsultationSummaryDetail.fromJson(Map<String, dynamic> json) {
    return ConsultationSummaryDetail(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      doctorName: json['doctor_name'] as String?,
      consultationDate: DateTime.parse(json['consultation_date'] as String),
      chiefComplaint: json['chief_complaint'] as String?,
      assessment: json['assessment'] as String?,
      plan: json['plan'] as String?,
      diagnoses: json['diagnoses'],
      medications: json['medications'],
      vitals: json['vitals'],
      followUp: json['follow_up'],
      pdfDownloadUrl: json['pdf_download_url'] as String?,
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
    );
  }
}
