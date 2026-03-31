import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/doctors_repository.dart';
import '../domain/doctor.dart';

final doctorsListProvider =
    FutureProvider.autoDispose<List<Doctor>>((ref) async {
  return ref.read(doctorsRepositoryProvider).listDoctors();
});
