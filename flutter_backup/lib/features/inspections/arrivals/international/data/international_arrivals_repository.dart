import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/international_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';

class InternationalArrivalRepository implements ArrivalsRepository {
  final SqliteHandler _dbHandler;

  InternationalArrivalRepository(this._dbHandler);

/*
  Future<void> saveInternationalArrival(Arrival arrival) async {
    try {
      final db = await _dbHandler.database;
      final existing = await db.query(
        'epmsatca_international_arrivals',
        where: 'inspection_id = ?',
        whereArgs: [arrival.inspectionId],
      );

      if (existing.isEmpty) {
        print("❌ Non-Existing (Intl)");
        await db.insert('epmsatca_international_arrivals', arrival.toJson());
      } else {
        print("✅ Existing (Intl)");
        await db.update(
          'epmsatca_international_arrivals',
          arrival.toJson(),
          where: 'inspection_id = ?',
          whereArgs: [arrival.inspectionId],
        );
      }
      print("✅ Llegada internacional guardada en SQLite");
    } catch (e) {
      print("❌ Error al guardar llegada internacional: $e");
    }
  }

  Future<InternationalArrival?> getInternationalArrivalByInspection(
      int inspectionId) async {
    final db = await _dbHandler.database;

    final res = await db.query(
      'epmsatca_international_arrivals',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    final arrival = InternationalArrival.fromJson(res.first);
    return arrival;
  }*/

  @override
  Future<InternationalArrival?> getArrivalByInspection(int inspectionId) async {
    final db = await _dbHandler.database;

    final res = await db.query(
      'epmsatca_international_arrivals',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    return InternationalArrival.fromJson(res.first);
  }

  @override
  Future<void> saveArrival(InspectionDetails arrival) async {
    try {
      final db = await _dbHandler.database;
      final data = await db.query(
        'epmsatca_international_arrivals',
        where: 'inspection_id = ?',
        whereArgs: [arrival.inspectionId],
      );

      if (data.isEmpty) {
        print("❌ Non-Existing (Intl)");
        await db.insert('epmsatca_international_arrivals', arrival.toJson());
      } else {
        print("✅ Existing (Intl)");
        await db.update(
          'epmsatca_international_arrivals',
          arrival.toJson(),
          where: 'inspection_id = ?',
          whereArgs: [arrival.inspectionId],
        );
      }
      print("✅ Llegada internacional guardada en SQLite");
    } catch (e) {
      print("❌ Error al guardar llegada internacional: $e");
    }
  }
}
