import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/preboarding_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';
import 'package:sqflite/sqflite.dart';

class PreboardingRepository {
  final SqliteHandler _dbHandler;

  PreboardingRepository(this._dbHandler);

  Future<List<Preboarding>> getNationalPreboardingDetails(
      int departureId) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'departures_preboarding_details',
      where: 'national_departure_id = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Registros de inspección id:${departureId} cargados: ${result.length}");
    return result.map((row) => Preboarding.fromJson(row)).toList();
  }

  Future<List<Preboarding>> getInternationalPreboardingDetails(
      int departureId) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'departures_preboarding_details',
      where: 'international_departure_id = ?',
      whereArgs: [departureId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Registros de inspección id:${departureId} cargados: ${result.length}");
    return result.map((row) => Preboarding.fromJson(row)).toList();
  }

  Future<void> saveNationalPreboardingLine(
      {required Preboarding line,
      required int departureId,
      required int id}) async {
    try {
      final db = await _dbHandler.database;

      final data = {
        'id': id,
        'area': line.area,
        'used': (line.used ?? false) ? 1 : 0,
        'used_chairs': line.usedChairs,
        'available_chairs': line.availableChairs,
        'used_area': line.usedArea,
        'available_area': line.availableArea,
        'national_departure_id': departureId,
        'occupancy_percentage': line.occupancyPercentage
      };

      print('🟢 Guardando línea de preembarque nacional: {$data}');

      final existing = await db.query(
        'departures_preboarding_details',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'departures_preboarding_details',
          data,
          where: 'id = ?',
          whereArgs: [id],
        );
        print('🟢 Línea nacional actualizada: {$id}');
      } else {
        await db.insert(
          'departures_preboarding_details',
          data,
        );
        print('🟢 Línea nacional insertada: {$id}');
      }
    } catch (e) {
      print('❌ Error al guardar línea nacional ID {$id: $e}');
    }
  }

  Future<void> saveInternationalPreboardingLine(
      {required Preboarding line,
      required int departureId,
      required int id}) async {
    try {
      final db = await _dbHandler.database;

      final data = {
        'id': id,
        'area': line.area,
        'used': (line.used ?? false) ? 1 : 0,
        'used_chairs': line.usedChairs,
        'available_chairs': line.availableChairs,
        'used_area': line.usedArea,
        'available_area': line.availableArea,
        'international_departure_id': departureId,
        'occupancy_percentage': line.occupancyPercentage
      };

      print('🔵 Guardando línea de preembarque internacional: {$data}');

      final existing = await db.query(
        'departures_preboarding_details',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'departures_preboarding_details',
          data,
          where: 'id = ?',
          whereArgs: [id],
        );
        print('🔵 Línea internacional actualizada: {$id}');
      } else {
        await db.insert(
          'departures_preboarding_details',
          data,
        );
        print('🔵 Línea internacional insertada: {$id}');
      }
    } catch (e) {
      print('❌ Error al guardar línea internacional ID {$id: $e}');
    }
  }
}
