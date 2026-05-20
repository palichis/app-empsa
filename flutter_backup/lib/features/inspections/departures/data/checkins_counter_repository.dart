import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_assigned_counters.dart';

class CheckinCounterRepository {
  final SqliteHandler _dbHandler;

  CheckinCounterRepository(this._dbHandler);

  Future<void> saveCounterNumberLine({
    required CheckinAssignedCounter line,
    required int departureId,
    required bool isNational, // true = nacional, false = internacional
  }) async {
    final db = await _dbHandler.database;

    // Define qué columna usar según el tipo de salida
    final fkCol =
        isNational ? 'national_departure_id' : 'international_departure_id';

    final data = <String, dynamic>{
      'id': line.id,
      fkCol: departureId,
      'name': line.name,
      'selected': line.selected, // bool → 0/1
    };

    print("DATA CHECK COUNTER NUMBER DEPARTURE {$departureId}");
    print(data);

    print(data['id']);
    print(data['selected']);

    final rows = await db.update(
      'departure_checkin_assigned_counters',
      data,
      where: 'id = ? AND $fkCol = ?',
      whereArgs: [line.id, departureId],
    );

    if (rows == 0) {
      await db.insert('departure_checkin_assigned_counters', data);
    }
  }

  Future<List<CheckinAssignedCounter>> getCounterNumberDetails({
    required int departureId,
    required bool isNational,
  }) async {
    final db = await _dbHandler.database;
    final fkCol =
        isNational ? 'national_departure_id' : 'international_departure_id';
    final result = await db.query(
      'departure_checkin_assigned_counters',
      where: '$fkCol = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Catálogo de (checkins counters details) cargados: ${result.length}");
    return result.map((row) => CheckinAssignedCounter.fromJson(row)).toList();
  }

  Future<void> setSelected({
    required int departureId,
    required bool isNational,
    required int counterId,
    required bool newValue,
  }) async {
    final db = await _dbHandler.database;
    final whereCol =
        isNational ? 'national_departure_id' : 'international_departure_id';

    await db.update(
      'departure_checkin_assigned_counters',
      {'selected': newValue ? 1 : 0},
      where: 'id = ? AND $whereCol = ?',
      whereArgs: [counterId, departureId],
    );
  }

  Future<void> markSynced(List<int> apiIds) async {
    if (apiIds.isEmpty) return;
    final db = await _dbHandler.database;
    await db.update(
      'departure_checkin_assigned_counters',
      {'synced': 1},
      where: 'id IN (${List.filled(apiIds.length, '?').join(',')})',
      whereArgs: apiIds,
    );
  }
}
