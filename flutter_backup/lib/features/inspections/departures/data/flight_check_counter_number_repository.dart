import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_check_counter_number.dart';

class FlightCheckCounterNumberRepository {
  final SqliteHandler _dbHandler;

  FlightCheckCounterNumberRepository(this._dbHandler);

  Future<void> saveFlightCheckCounterNumberLine({
    required FlightCheckCounterNumber line,
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
      'departure_flight_check_counters',
      data,
      where: 'id = ? AND $fkCol = ?',
      whereArgs: [line.id, departureId],
    );

    if (rows == 0) {
      await db.insert('departure_flight_check_counters', data);
    }
  }

  Future<List<FlightCheckCounterNumber>> getFlightCheckCounterNumberDetails({
    required int departureId,
    required bool isNational,
  }) async {
    final db = await _dbHandler.database;
    final fkCol =
        isNational ? 'national_departure_id' : 'international_departure_id';
    final result = await db.query(
      'departure_flight_check_counters',
      where: '$fkCol = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Catálogo de (flight check counters details) cargados: ${result.length}");
    return result.map((row) => FlightCheckCounterNumber.fromJson(row)).toList();
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
      'departure_flight_check_counters',
      {'selected': newValue ? 1 : 0},
      where: 'id = ? AND $whereCol = ?',
      whereArgs: [counterId, departureId],
    );
  }

  Future<void> markSynced(List<int> apiIds) async {
    if (apiIds.isEmpty) return;
    final db = await _dbHandler.database;
    await db.update(
      'departure_flight_check_counters',
      {'synced': 1},
      where: 'id IN (${List.filled(apiIds.length, '?').join(',')})',
      whereArgs: apiIds,
    );
  }
}
