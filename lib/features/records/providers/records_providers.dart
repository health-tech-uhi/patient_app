import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/records_repository.dart';
import '../domain/medical_record_file.dart';

final medicalRecordsListProvider =
    FutureProvider.autoDispose<List<MedicalRecordFile>>((ref) async {
  final auth = ref.watch(authNotifierProvider);
  if (auth.status != AuthStatus.authenticated ||
      !auth.isRegisteredAsPatient) {
    return [];
  }
  final profile = await ref.watch(patientProfileProvider.future);
  if (profile == null) return [];
  return ref.read(recordsRepositoryProvider).listFiles(profile.id);
});
