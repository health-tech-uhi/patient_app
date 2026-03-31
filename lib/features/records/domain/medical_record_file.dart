class MedicalRecordFile {
  final String id;
  final String patientId;
  final String fileName;
  final String fileType;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? description;
  final String? uploaderName;
  final DateTime createdAt;

  const MedicalRecordFile({
    required this.id,
    required this.patientId,
    required this.fileName,
    required this.fileType,
    this.fileSizeBytes,
    this.mimeType,
    this.description,
    this.uploaderName,
    required this.createdAt,
  });

  factory MedicalRecordFile.fromJson(Map<String, dynamic> json) {
    return MedicalRecordFile(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      mimeType: json['mime_type']?.toString(),
      description: json['description']?.toString(),
      uploaderName: json['uploader_name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
