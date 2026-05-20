import 'dart:convert';

import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/domain/international_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class DeparturesRepository {
  final SqliteHandler _dbHandler;

  DeparturesRepository(this._dbHandler);

  Future<void> saveNationalDeparture(NationalDepartures departure) async {
    try {
      final db = await _dbHandler.database;

      final existing = await db.query(
        'epmsatca_national_departures',
        where: 'inspection_id = ?',
        whereArgs: [departure.inspectionId],
      );

      if (existing.isEmpty) {
        print('❌ Non-Existing (Nat)');
        await db.insert('epmsatca_national_departures', departure.toJson());
      } else {
        print('✅ Existing (Nat)');
        await db.update(
          'epmsatca_national_departures',
          departure.toJson(),
          where: 'inspection_id = ?',
          whereArgs: [departure.inspectionId],
        );
      }
      print('✅ Salida nacional guardada en SQLite');
    } catch (e, st) {
      debugPrint('❌ Error al guardar salida nacional: $e, $st');
    }
  }

  Future<void> saveInternationalDeparture(
      InternationalDepartures departure) async {
    try {
      print("REPOSITORY DEPARTURE -----------------------------------------");
      print(departure.id);
      final db = await _dbHandler.database;
      final data = Map<String, dynamic>.from(departure.toJson());

      if (data['flight_number'] is List) {
        data['flight_number'] = jsonEncode(data['flight_number']);
      }
      final existing = await db.query(
        'epmsatca_international_departures',
        where: 'inspection_id = ?',
        whereArgs: [departure.inspectionId],
      );

      if (existing.isEmpty) {
        print('❌ Non-Existing');
        await db.insert('epmsatca_international_departures', data);
      } else {
        print('✅ Existing');
        await db.update(
          'epmsatca_international_departures',
          data,
          where: 'inspection_id = ?',
          whereArgs: [departure.inspectionId],
        );
      }
      print('✅ Salida internacional guardada en SQLite');
      debugPrint("${data}");
    } catch (e) {
      debugPrint('❌ Error al guardar salida internacional: $e');
    }
  }

  Future<NationalDepartures?> getNationalDepartureByInspection(
      int inspectionId) async {
    final db = await _dbHandler.database;

    // 1. Cargar cabecera
    final res = await db.query(
      'epmsatca_national_departures',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    final departure = NationalDepartures.fromJson(res.first);

    /*
    final baggageTimeRes = await db.query(
      'arrival_baggage_time_details',
      where: 'arrival_id = ?',
      whereArgs: [arrival.id],
    );

    arrival.baggageTimeDetails =
        baggageTimeRes.map((row) => ArrivalBaggageTime.fromMap(row)).toList();
    */
    return departure;
  }

  Future<InternationalDepartures?> getInternationalDepartureByInspection(
      int inspectionId) async {
    final db = await _dbHandler.database;

    final res = await db.query(
      'epmsatca_international_departures',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    final row = Map<String, dynamic>.from(res.last);

    if (row['flight_number'] is String) {
      row['flight_number'] = jsonDecode(row['flight_number'] as String);
    }
    row['flight_data'] = {
      'flight_number': row['flight_number'],
      'flight_count': row['flight_count'],
      'flight_pax_number': row['flight_pax_number'],
      'flight_check_counter_number': row['flight_check_counter_number'],
      'flight_preboarding_room': row['flight_preboarding_room'],
      'flight_scheduled_time': row['flight_scheduled_time'],
      'flight_actual_departure_time': row['flight_actual_departure_time'],
    };

    final departure = InternationalDepartures.fromJson(row);
    return departure;
  }

  Future<int?> getSelectedCounterId({
    required int departureId,
    required bool isNational,
  }) async {
    final db = await _dbHandler.database;
    final table = isNational
        ? 'epmsatca_national_departures'
        : 'epmsatca_international_departures';

    final rows = await db.query(
      table,
      columns: ['flight_counter_id'],
      where: 'id = ?',
      whereArgs: [departureId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['flight_counter_id'] as int? : null;
  }
}
