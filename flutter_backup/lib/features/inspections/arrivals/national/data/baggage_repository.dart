import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';
import 'package:flutter/material.dart';

class BaggageRepository {
  final SqliteHandler _dbHandler;

  BaggageRepository(this._dbHandler);

  Future<void> saveNationalArrivalBaggageField({
    required int arrivalId,
    required int id,
    required BaggageTimeData data,
  }) async {
    try {
      final db = await _dbHandler.database;

      final existing = await db.query(
        'arrival_baggage_time_details',
        where: 'national_arrival_id = ? AND id = ?',
        whereArgs: [arrivalId, id],
        limit: 1,
      );

      late BaggageTimeData fullData;
      if (existing.isEmpty) {
        print("❌ Baggage Time No existe. Se crea nuevo");
        fullData = data;
      } else {
        final existingData = BaggageTimeData.fromJson(existing.first);
        fullData = existingData.mergeWith(data);
      }

      final jsonData = {
        ...fullData.toJson(),
        'national_arrival_id': arrivalId,
        'id': id,
      };

      debugPrint(" Baggage Time DATA LUEGO DL MERGE WITH ${jsonData}");

      if (existing.isEmpty) {
        print("❌ Detalle vuelo $id no existente");
        await db.insert('arrival_baggage_time_details', jsonData);
      } else {
        print("✅ Detalle vuelo $id existente");
        await db.update(
          'arrival_baggage_time_details',
          jsonData,
          where: 'national_arrival_id = ? AND id = ?',
          whereArgs: [arrivalId, id],
        );
      }

      print("💾 Detalle de equipaje guardado correctamente (vuelo $id)");
    } catch (e) {
      print("❌ Error al guardar detalle de equipaje: $e");
    }
  }

  Future<void> saveInternationalArrivalBaggageField({
    required int arrivalId,
    required int id,
    required BaggageTimeData data,
  }) async {
    try {
      final db = await _dbHandler.database;

      final existing = await db.query(
        'arrival_baggage_time_details',
        where: 'international_arrival_id = ? AND id = ?',
        whereArgs: [arrivalId, id],
        limit: 1,
      );

      late BaggageTimeData fullData;
      if (existing.isEmpty) {
        print("❌  Baggage Time No existe. Se crea nuevo");
        fullData = data;
      } else {
        final existingData = BaggageTimeData.fromJson(existing.first);
        fullData = existingData.mergeWith(data);
      }

      final jsonData = {
        ...fullData.toJson(),
        'international_arrival_id': arrivalId,
        'id': id,
      };

      if (existing.isEmpty) {
        print("❌ Detalle vuelo $id no existente");
        await db.insert('arrival_baggage_time_details', jsonData);
      } else {
        print("✅ Detalle vuelo $id existente");
        await db.update(
          'arrival_baggage_time_details',
          jsonData,
          where: 'international_arrival_id = ? AND id = ?',
          whereArgs: [arrivalId, id],
        );
      }

      print("💾 Detalle de equipaje guardado correctamente (vuelo $id)");
    } catch (e) {
      print("❌ Error al guardar detalle de equipaje: $e");
    }
  }

  Future<List<BaggageTimeData>> getNationalArrivalBaggageDetails(
      int nationalArrivalId) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'arrival_baggage_time_details',
      where: 'national_arrival_id = ?',
      whereArgs: [nationalArrivalId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Registros de inspección id:${nationalArrivalId} cargados: ${result.length}");
    return result.map((row) => BaggageTimeData.fromJson(row)).toList();
  }

  Future<List<BaggageTimeData>> getInternationalArrivalBaggageDetails(
      int internationalArrivalId) async {
    final db = await _dbHandler.database;
    final result = await db.query(
      'arrival_baggage_time_details',
      where: 'international_arrival_id = ?',
      whereArgs: [internationalArrivalId],
      orderBy: 'id ASC',
    );
    print(
        "✈️ Registros de inspección id:${internationalArrivalId} cargados: ${result.length}");
    return result.map((row) => BaggageTimeData.fromJson(row)).toList();
  }
}
