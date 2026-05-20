import 'package:epmsa_mobile/core/providers/auth_provider.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty_catalog.dart';
import 'package:epmsa_mobile/features/penalties/data/penalties_catalog_repository.dart';
import 'package:epmsa_mobile/features/penalties/services/penalties_service.dart';
import 'package:epmsa_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final penaltiescatalogProvider =
    StateNotifierProvider<PenaltiesCatalogNotifier, List<PenaltyCatalog>>(
        (ref) {
  final session = ref.watch(authProvider);
  final sqliteHandler = ref.watch(sqliteHandlerProvider);
  final penaltiesService = PenaltiesService();
  return PenaltiesCatalogNotifier(
      PenaltiesCatalogRepository(sqliteHandler, penaltiesService), session!);
});

class PenaltiesCatalogNotifier extends StateNotifier<List<PenaltyCatalog>> {
  final PenaltiesCatalogRepository _repository;
  final Map<String, dynamic> _session;

  PenaltiesCatalogNotifier(this._repository, this._session) : super([]) {
    //if (_sessionId != null) {
    loadPenaltiesCatalog(); // Carga automáticamente los datos si hay sesión
    // }
  }

  List<PenaltyCatalog> get leves =>
      state.where((p) => p.parentId == 2).toList();
  List<PenaltyCatalog> get graves =>
      state.where((p) => p.parentId == 3).toList();
  List<PenaltyCatalog> get muyGraves =>
      state.where((p) => p.parentId == 4).toList();
  Future<void> loadPenaltiesCatalog() async {
    final String? sid = _session['session_id'] as String?;
    final data = await _repository.getPenalties(sid);
    state = data; // Actualiza el estado
  }
}
