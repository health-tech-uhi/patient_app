class Doctor {
  final String id;
  final String fullName;
  final String specialization;
  final String? qualification;
  final int? experienceYears;
  final String? bio;
  final List<String>? languagesSpoken;
  final double? consultationFeeInr;
  final bool? isAcceptingPatients;
  final String? verificationStatus;
  final String? clinicId;

  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.qualification,
    this.experienceYears,
    this.bio,
    this.languagesSpoken,
    this.consultationFeeInr,
    this.isAcceptingPatients,
    this.verificationStatus,
    this.clinicId,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final langs = json['languages_spoken'];
    return Doctor(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      qualification: json['qualification']?.toString(),
      experienceYears: _parseInt(json['experience_years']),
      bio: json['bio']?.toString(),
      languagesSpoken: langs is List
          ? langs.map((e) => e.toString()).toList()
          : null,
      // API may send DECIMAL as JSON string, e.g. "1000.00"
      consultationFeeInr: _parseDouble(json['consultation_fee_inr']),
      isAcceptingPatients: json['is_accepting_patients'] as bool?,
      verificationStatus: json['verification_status']?.toString(),
      clinicId: json['clinic_id']?.toString(),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
