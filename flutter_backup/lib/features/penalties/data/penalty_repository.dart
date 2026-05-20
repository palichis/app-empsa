import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty.dart';
import 'package:sqflite/sqflite.dart';

class PenaltyRepository {
  final SqliteHandler _dbHandler;

  PenaltyRepository(this._dbHandler);

  /// Guarda una nueva penalización en SQLite
  Future<void> savePenalty(Penalty penalty) async {
    try {
      final db = await _dbHandler.database;
      await db.insert(
        'epmsatca_penalties',
        penalty.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print("✅ Penalización guardada en SQLite.");
    } catch (e) {
      print("❌ Error al guardar penalización: $e");
    }
  }

  /// Obtiene todas las penalizaciones almacenadas en SQLite
  Future<List<Penalty>> getPenalties() async {
    try {
      final db = await _dbHandler.database;
      final List<Map<String, dynamic>> maps = await db.query('penalties');
      return maps.map((penalty) => Penalty.fromJson(penalty)).toList();
    } catch (e) {
      print("❌ Error obteniendo penalizaciones: $e");
      return [];
    }
  }

  /// Obtiene solo las penalizaciones pendientes de sincronización
  Future<List<Penalty>> getPendingPenalties() async {
    try {
      final db = await _dbHandler.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'epmsatca_penalties',
        where: 'synced = 0',
      );
      return maps.map((penalty) => Penalty.fromJson(penalty)).toList();
    } catch (e) {
      print("❌ Error obteniendo penalizaciones pendientes: $e");
      return [];
    }
  }

  /// Elimina una penalización de SQLite después de sincronizarla con el servidor
  Future<void> deletePenalty(int id) async {
    try {
      final db = await _dbHandler.database;
      await db.delete('epmsatca_penalties', where: 'id = ?', whereArgs: [id]);
      print("✅ Penalización eliminada de SQLite.");
    } catch (e) {
      print("❌ Error eliminando penalización: $e");
    }
  }
}
