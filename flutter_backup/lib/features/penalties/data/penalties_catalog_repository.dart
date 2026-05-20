import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty_catalog.dart';
import 'package:epmsa_mobile/features/penalties/services/penalties_service.dart';

class PenaltiesCatalogRepository {
  final SqliteHandler _dbHandler;
  final PenaltiesService _penaltiesService;
  PenaltiesCatalogRepository(this._dbHandler, this._penaltiesService);

  /// Obtiene penalizaciones desde SQLite o API si está vacío
  Future<List<PenaltyCatalog>> getPenalties(String? sessionId) async {
    try {
      List<PenaltyCatalog> penalties = await _dbHandler.getPenaltiesCatalog();
      print("📢 Buscando en la BD...");
      if (penalties.isEmpty && sessionId != null) {
        print("📢 Base de datos vacía, obteniendo desde API...");
        penalties = await _penaltiesService.fetchPenalties(sessionId);
        await savePenaltiesToLocal(penalties);
      }
      return penalties;
    } catch (e) {
      print("❌ Error al obtener penalizaciones: $e");
      throw Exception("No se pudo recuperar las penalizaciones.");
    }
  }

  /// Guarda las penalizaciones en SQLite
  Future<void> savePenaltiesToLocal(List<PenaltyCatalog> penalties) async {
    try {
      await _dbHandler.savePenaltiesCatalog(penalties);
      print("✅ Penalizaciones guardadas en SQLite.");
    } catch (e) {
      print("❌ Error al guardar penalizaciones en SQLite: $e");
      throw Exception("No se pudo guardar las penalizaciones.");
    }
  }
}
