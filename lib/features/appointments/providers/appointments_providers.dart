import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment.dart';

final appointmentsListProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final auth = ref.watch(authNotifierProvider);
  if (auth.status != AuthStatus.authenticated ||
      !auth.isRegisteredAsPatient) {
    return [];
  }
  return ref.read(appointmentsRepositoryProvider).listAppointments();
});
