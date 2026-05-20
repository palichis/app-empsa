import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/domain/national_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
//import 'package:sqflite/sqflite.dart';

class NationalArrivalsRepository implements ArrivalsRepository {
  final SqliteHandler _dbHandler;

  NationalArrivalsRepository(this._dbHandler);

  @override
  Future<NationalArrival?> getArrivalByInspection(int inspectionId) async {
    final db = await _dbHandler.database;

    // 1. Cargar cabecera
    final res = await db.query(
      'epmsatca_national_arrivals',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    return NationalArrival.fromJson(res.first);
  }

  @override
  Future<void> saveArrival(InspectionDetails arrival) async {
    try {
      final db = await _dbHandler.database;
      final data = await db.query(
        'epmsatca_national_arrivals',
        where: 'inspection_id = ?',
        whereArgs: [arrival.inspectionId],
      );

      if (data.isEmpty) {
        print("❌ Non-Existing");
        await db.insert('epmsatca_national_arrivals', arrival.toJson());
      } else {
        print("✅ Existing");
        await db.update(
          'epmsatca_national_arrivals',
          arrival.toJson(),
          where: 'inspection_id = ?',
          whereArgs: [arrival.inspectionId],
        );
      }
      print("✅ Llegada nacional guardada en SQLite");
    } catch (e) {
      print("❌ Error al guardar llegada nacional: $e");
    }
  }

  Future<void> saveAllArrivals(String jsonBody) async {
    final db = await _dbHandler.database;

    await db.transaction((txn) async {
      await txn.delete('arrivals');
      await txn.insert(
        'arrivals',
        {
          'json_all': jsonBody,
        },
      );
    });
  }


  Future<String> getAllArrivals() async {
    final db = await _dbHandler.database;

    final result = await db.query(
      'arrivals',
      columns: ['json_all'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['json_all'] as String;
    }
    return '';
  }
}
