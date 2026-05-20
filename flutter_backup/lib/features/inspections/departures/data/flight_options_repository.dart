// lib/features/inspections/departures/data/flight_options_repository.dart
import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/flight_option.dart';

class FlightOptionsRepository {
  final SqliteHandler _dbHandler;

  FlightOptionsRepository(this._dbHandler);

  // ---------- Helpers ----------
  String _depCol(bool isNational) =>
      isNational ? 'national_departure_id' : 'international_departure_id';

  Map<String, Object?> _toRow({
    required FlightOption line,
    required int departureId,
    required bool isNational,
  }) {
    return {
      'id': line.id,
      'name': line.name,
      'selected': line.selected,
      'destiny': line.destiny,
      'time':line.time,
      _depCol(isNational): departureId,
    };
  }

  Future<bool> _existsByIdAndDeparture({
    required Database db,
    required int id,
    required int departureId,
    required bool isNational,
  }) async {
    final whereCol = _depCol(isNational);
    final existing = await db.query(
      'departure_flight_options',
      where: 'id = ? AND $whereCol = ?',
      whereArgs: [id, departureId],
      limit: 1,
    );
    return existing.isNotEmpty;
  }

  // ---------- GET ----------
  Future<List<FlightOption>> getInternationalFlightOptionsDetails(
    int departureId,
  ) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'departure_flight_options',
      where: 'international_departure_id = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );
    print(
        '✈️ (INT) flight_options cargados: ${result.length} dep:$departureId');
    return result.map((row) => FlightOption.fromJson(row)).toList();
  }

  Future<List<FlightOption>> getNationalFlightOptionsDetails(
    int departureId,
  ) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'departure_flight_options',
      where: 'national_departure_id = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );
    print(
        '✈️ (NAT) flight_options cargados: ${result.length} dep:$departureId');
    return result.map((row) => FlightOption.fromJson(row)).toList();
  }

  // Guardar UNA línea (helper público por si lo quieres usar directo)
  Future<void> saveFlightOptionsLine({
    required int departureId,
    required FlightOption item,
    bool isNational = false,
  }) async {
    if (isNational) {
      await saveNationalFlightOptionLine(
        line: item,
        departureId: departureId,
        id: item.id,
      );
    } else {
      await saveInternationalFlightOptionLine(
        line: item,
        departureId: departureId,
        id: item.id,
      );
    }
  }

  // Guardar LISTA completa
  Future<void> saveFlightOptions({
    required int departureId,
    required List<FlightOption> list,
    bool isNational = false,
  }) async {
    for (final o in list) {
      if (isNational) {
        await saveNationalFlightOptionLine(
          line: o,
          departureId: departureId,
          id: o.id,
        );
      } else {
        await saveInternationalFlightOptionLine(
          line: o,
          departureId: departureId,
          id: o.id,
        );
      }
    }
  }

  // ---------- SAVE (una línea) ----------
  Future<void> saveInternationalFlightOptionLine({
    required FlightOption line,
    required int departureId,
    required int id,
  }) async {
    try {
      final db = await _dbHandler.database;
      final data =
          _toRow(line: line, departureId: departureId, isNational: false);

      final exists = await _existsByIdAndDeparture(
        db: db,
        id: id,
        departureId: departureId,
        isNational: false,
      );

      if (exists) {
        final rows = await db.update(
          'departure_flight_options',
          data,
          where: 'id = ? AND international_departure_id = ?',
          whereArgs: [id, departureId],
        );
        print(
            '🔵 (INT) flight_option actualizado id:$id dep:$departureId (rows:$rows)');
      } else {
        final rowId = await db.insert(
          'departure_flight_options',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print(
            '🔵 (INT) flight_option insertado id:$id dep:$departureId (rowId:$rowId)');
      }
    } catch (e) {
      print(
          '❌ Error guardando (INT) flight_option id:$id dep:$departureId -> $e');
    }
  }

  Future<void> saveNationalFlightOptionLine({
    required FlightOption line,
    required int departureId,
    required int id,
  }) async {
    try {
      final db = await _dbHandler.database;
      final data =
          _toRow(line: line, departureId: departureId, isNational: true);

      final exists = await _existsByIdAndDeparture(
        db: db,
        id: id,
        departureId: departureId,
        isNational: true,
      );

      if (exists) {
        final rows = await db.update(
          'departure_flight_options',
          data,
          where: 'id = ? AND national_departure_id = ?',
          whereArgs: [id, departureId],
        );
        print(
            '🔵 (NAT) flight_option actualizado id:$id dep:$departureId (rows:$rows)');
      } else {
        final rowId = await db.insert(
          'departure_flight_options',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print(
            '🔵 (NAT) flight_option insertado id:$id dep:$departureId (rowId:$rowId)');
      }
    } catch (e) {
      print(
          '❌ Error guardando (NAT) flight_option id:$id dep:$departureId -> $e');
    }
  }

  // ---------- SELECTED EXCLUSIVO ----------
  Future<void> setSelected({
    required int departureId,
    required bool isNational,
    required int optionId,
  }) async {
    final db = await _dbHandler.database;
    final whereCol = _depCol(isNational);

    await db.transaction((txn) async {
      // Pone todos en 0 para ese departure
      await txn.update(
        'departure_flight_options',
        {'selected': 0},
        where: '$whereCol = ?',
        whereArgs: [departureId],
      );
      // Pone 1 al seleccionado
      final rows = await txn.update(
        'departure_flight_options',
        {'selected': 1},
        where: 'id = ? AND $whereCol = ?',
        whereArgs: [optionId, departureId],
      );
      print(
          '✅ setSelected dep:$departureId ${isNational ? "(NAT)" : "(INT)"} id:$optionId (rows:$rows)');
    });
  }

  // ---------- MARCAR SYNC ----------
  Future<void> markSynced(List<int> apiIds) async {
    if (apiIds.isEmpty) return;
    final db = await _dbHandler.database;
    await db.update(
      'departure_flight_options',
      {'synced': 1},
      where: 'id IN (${List.filled(apiIds.length, '?').join(',')})',
      whereArgs: apiIds,
    );
  }
}
