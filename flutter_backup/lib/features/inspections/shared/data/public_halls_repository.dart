import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_options.dart';

class PublicHallOptionRepository {
  final SqliteHandler _dbHandler;
  PublicHallOptionRepository(this._dbHandler);

  Future<void> savePublicHallsLine({
    required PublicHallOption line,
    required int inspectionId,
  }) async {
    try {
      final db = await _dbHandler.database;

      final data = {
        'id': line.id,
        'name': line.name,
        'selected': line.selected,
        'inspection_id': inspectionId,
      };

      print('🔵 Guardando línea de public_halls: {$data}');

      final existing = await db.query(
        'inspections_public_halls',
        /*where: 'id = ?',
        whereArgs: [id],*/
        where: 'id = ? AND inspection_id = ?',
        whereArgs: [line.id, inspectionId],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'inspections_public_halls',
          data,
          where: 'id = ? AND inspection_id = ?',
          whereArgs: [line.id, inspectionId],
        );
        print('🔵 Línea public_hall actualizada: ${line.id}');
      } else {
        await db.insert(
          'inspections_public_halls',
          data,
        );
        print('🔵 Línea public_hall insertada: ${line.id}');
      }
    } catch (e) {
      print('❌ Error al guardar línea public_hall ID {${line.id}: $e}');
    }
  }

  Future<List<PublicHallOption>> getPublicHallsDetails(int inspectionId) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'inspections_public_halls',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Registros de (public halls) salida id:${inspectionId} cargados: ${result.length}");
    return result.map((row) => PublicHallOption.fromJson(row)).toList();
  }

  Future<void> markOptionSelected({
    required int inspectionId,
    required int id,
  }) async {
    final db = await _dbHandler.database;

    await db.transaction((txn) async {
      await txn.update(
        'inspections_public_halls',
        {'selected': 0},
        where: 'inspection_id = ?',
        whereArgs: [inspectionId],
      );
      await txn.update(
        'inspections_public_halls',
        {'selected': 1},
        where: 'id = ? AND inspection_id = ?',
        whereArgs: [id, inspectionId],
      );
      print("setting as selected id: $id in DB");
    });
  }
}
