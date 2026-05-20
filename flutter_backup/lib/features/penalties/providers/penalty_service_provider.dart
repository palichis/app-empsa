import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epmsa_mobile/features/penalties/services/penalty_service.dart';
import 'package:epmsa_mobile/features/penalties/data/penalty_repository.dart';

// Provider que inicializa la BD
final sqlHandlerProvider = Provider<SqliteHandler>((ref) {
  return SqliteHandler();
});

// Provider para el repositorio de penalizaciones
final penaltyRepositoryProvider = Provider<PenaltyRepository>((ref) {
  final dbHandler = ref.watch(sqlHandlerProvider);
  return PenaltyRepository(dbHandler);
});

// Provider para PenaltyService inyectando el repositorio
final penaltyServiceProvider = Provider<PenaltyService>((ref) {
  final repository = ref.watch(penaltyRepositoryProvider);
  return PenaltyService(repository);
});

// Expone a través del provider la sincronización de penalizaciones
final syncPenaltiesProvider = FutureProvider.autoDispose<void>((ref) async {
  final penaltyService = ref.watch(penaltyServiceProvider);
  final session = ref.watch(authProvider);
  final String sid = session!['session_id'];
  //final int uid = session['uid'];

  //if (sid != null) {
  try {
    await penaltyService.syncPenalties(sid);
  } catch (e) {
    throw Exception("Error en la sincronización: $e");
  }
  //} else {
  // print("⚠️ No se pudo sincronizar: session_id es nulo");
  //}
});
