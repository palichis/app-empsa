import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room.dart';

class FlightPreboardingRoomRepository {
  final SqliteHandler _dbHandler;

  FlightPreboardingRoomRepository(this._dbHandler);

  Future<void> savePreboardingRoomLine({
    required FlightPreboardingRoom line,
    required int departureId,
    required bool isNational, // true = nacional, false = internacional
  }) async {
    final db = await _dbHandler.database;

    final fkCol =
        isNational ? 'national_departure_id' : 'international_departure_id';

    final data = <String, dynamic>{
      'id': line.id,
      fkCol: departureId,
      'name': line.name,
      'selected': line.selected, // 0/1
    };

    final rows = await db.update(
      'departure_flight_preboarding_rooms',
      data,
      where: 'id = ? AND $fkCol = ?',
      whereArgs: [line.id, departureId],
    );

    if (rows == 0) {
      await db.insert('departure_flight_preboarding_rooms', data);
    }
  }

  Future<List<FlightPreboardingRoom>> getPreboardingRoomDetails({
    required int departureId,
    required bool isNational,
  }) async {
    final db = await _dbHandler.database;
    final fkCol =
        isNational ? 'national_departure_id' : 'international_departure_id';

    final result = await db.query(
      'departure_flight_preboarding_rooms',
      where: '$fkCol = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );

    print("✈️ Catálogo de (preboarding rooms) cargados: ${result.length}");
    return result.map((row) => FlightPreboardingRoom.fromJson(row)).toList();
  }

  Future<void> setSelected({
    required int departureId,
    required bool isNational,
    required int roomId,
    required bool selected,
  }) async {
    final db = await _dbHandler.database;
    final whereCol =
        isNational ? 'national_departure_id' : 'international_departure_id';

    await db.update(
      'departure_flight_preboarding_rooms',
      {'selected': selected ? 1 : 0},
      where: 'id = ? AND $whereCol = ?',
      whereArgs: [roomId, departureId],
    );
  }

  Future<void> markSynced(List<int> apiIds) async {
    if (apiIds.isEmpty) return;
    final db = await _dbHandler.database;
    await db.update(
      'departure_flight_preboarding_rooms',
      {'synced': 1},
      where: 'id IN (${List.filled(apiIds.length, '?').join(',')})',
      whereArgs: apiIds,
    );
  }
}
