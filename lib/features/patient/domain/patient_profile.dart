class AllergyEntry {
  final String allergenName;
  final String severity;
  final String? reaction;

  const AllergyEntry({
    required this.allergenName,
    required this.severity,
    this.reaction,
  });

  Map<String, dynamic> toJson() => {
        'allergen_name': allergenName,
        'severity': severity,
        'reaction': reaction,
        'substance_id': null,
      };

  factory AllergyEntry.fromJson(Map<String, dynamic> json) {
    return AllergyEntry(
      allergenName: json['allergen_name']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'unknown',
      reaction: json['reaction']?.toString(),
    );
  }
}

class PatientProfile {
  final String id;
  final String? profileId;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<AllergyEntry> allergies;

  const PatientProfile({
    required this.id,
    this.profileId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.allergies = const [],
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final allergiesRaw = json['allergies'];
    final allergies = <AllergyEntry>[];
    if (allergiesRaw is List) {
      for (final e in allergiesRaw) {
        if (e is Map<String, dynamic>) {
          allergies.add(AllergyEntry.fromJson(e));
        }
      }
    }
    return PatientProfile(
      id: json['id']?.toString() ?? json['profile_id']?.toString() ?? '',
      profileId: json['profile_id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      allergies: allergies,
    );
  }

  Map<String, dynamic> toUpdatePayload({
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? emergencyContactName,
    String? emergencyContactPhone,
    required List<AllergyEntry> allergies,
  }) {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender == 'Not Specified' ? null : gender,
      'blood_group': bloodGroup == 'Unknown' ? null : bloodGroup,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'allergies': allergies.map((a) => a.toJson()).toList(),
    };
  }
}
