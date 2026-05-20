import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';
import 'package:flutter/rendering.dart';

class CargoRepository {
  final SqliteHandler _dbHandler;
  CargoRepository(this._dbHandler);

  Future<void> saveCargo(Cargo cargo) async {
    final db = await _dbHandler.database;
    final exists = await db.query(
      'epmsatca_inspection_cargo',
      where: 'id = ?',
      whereArgs: [cargo.id],
    );

    if (exists.isEmpty) {
      await db.insert(
          'epmsatca_inspection_cargo', {...cargo.toJson(), 'id': cargo.id});
    } else {
      await db.update(
        'epmsatca_inspection_cargo',
        cargo.toJson(),
        where: 'id = ?',
        whereArgs: [cargo.id],
      );
    }
  }

  /* ---------- LANDSIDE ---------- */
  Future<void> saveLandside(List<LandsideEntry> items, int cargoId) async {
    final db = await _dbHandler.database;
    for (final entry in items) {
      final data = entry.toJson()..['cargo_id'] = cargoId;

      debugPrint("PRELOADING from REPOSITORY");
      debugPrint("${data}");

      final exists = await db.query(
        'cargo_landside',
        where: 'cargo_id = ? AND "parent" = ? AND sequence = ?',
        whereArgs: [cargoId, entry.parent, entry.sequence],
      );
      debugPrint("NOW");
      debugPrint("${exists}");

      if (exists.isEmpty) {
        await db.insert('cargo_landside', data);
      } else {
        await db.update('cargo_landside', data,
            where: 'cargo_id = ? AND "parent" = ? AND sequence = ?',
            whereArgs: [cargoId, entry.parent, entry.sequence]);
      }
    }
  }

  /* ---------- AIRSIDE ---------- */
  Future<void> saveAirside(List<AirsideEntry> items, int cargoId) async {
    final db = await _dbHandler.database;
    for (final entry in items) {
      final data = entry.toJson()..['cargo_id'] = cargoId;

      debugPrint("PRELOADING from REPOSITORY");
      debugPrint("${data}");

      final exists = await db.query(
        'cargo_airside',
        where: 'cargo_id = ? AND "parent" = ? AND sequence = ?',
        whereArgs: [cargoId, entry.parent, entry.sequence],
      );
      debugPrint("NOW");
      debugPrint("${exists}");

      if (exists.isEmpty) {
        await db.insert('cargo_airside', data);
      } else {
        await db.update('cargo_airside', data,
            where: 'cargo_id = ? AND "parent" = ? AND sequence = ?',
            whereArgs: [cargoId, entry.parent, entry.sequence]);
      }
    }
  }

  Future<Cargo?> getCargoById(int cargoId) async {
    try {
      final db = await _dbHandler.database;

      final result = await db.query(
        'epmsatca_inspection_cargo',
        where: 'id = ?',
        whereArgs: [cargoId],
      );

      if (result.isEmpty) {
        print('❌ No se encontró cargo con ID: $cargoId');
        return null;
      }

      final cargo = Cargo.fromJson(result.first);
      return cargo;
    } catch (e, st) {
      print('❌ Error al obtener cargo por ID: $e\n$st');
      return null;
    }
  }

  Future<Cargo?> getCargoByInspectionId(int inspectionId) async {
    final db = await _dbHandler.database;

    final rows = await db.query(
      'epmsatca_inspection_cargo', // tabla cabecera
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final cargo = Cargo.fromJson(rows.first);

    return cargo;
  }

  Future<List<LandsideEntry>?> getLandsideEntriesForCargo(int cargoId) async {
    final db = await _dbHandler.database;

    final rows = await db.query(
      'cargo_landside',
      where: 'cargo_id = ?',
      whereArgs: [cargoId],
    );

    if (rows.isEmpty) return null;

    final List<LandsideEntry> result = [];
    for (final row in rows) {
      result.add(LandsideEntry.fromJson(row));
    }
    return result;
  }

  Future<List<AirsideEntry>?> getAirsideEntriesForCargo(int cargoId) async {
    final db = await _dbHandler.database;

    final rows = await db.query(
      'cargo_airside',
      where: 'cargo_id = ?',
      whereArgs: [cargoId],
    );

    if (rows.isEmpty) return null;

    final List<AirsideEntry> result = [];
    for (final row in rows) {
      result.add(AirsideEntry.fromJson(row));
    }
    return result;
  }
}
