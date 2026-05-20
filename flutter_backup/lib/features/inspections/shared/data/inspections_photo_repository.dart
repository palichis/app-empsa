import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/inspection_photo.dart';

class InspectionPhotoRepository {
  final SqliteHandler _dbHandler;

  InspectionPhotoRepository(this._dbHandler);

  Future<void> savePhoto(InspectionPhoto photo) async {
    final db = await _dbHandler.database;
    await db.insert(
      'epmsatca_inspection_photos',
      photo.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("✅ Foto guardada en SQLite: ${photo.path}");
  }

  Future<List<InspectionPhoto>> getPhotosByInspection(
      int inspectionId, String section) async {
    final db = await _dbHandler.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'epmsatca_inspection_photos',
      where: 'inspection_id = ? AND section = ?',
      whereArgs: [inspectionId, section],
    );
    return maps.map((e) => InspectionPhoto.fromJson(e)).toList();
  }

  Future<List<InspectionPhoto>> getUnsyncedPhotos(int inspectionId) async {
    final db = await _dbHandler.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'epmsatca_inspection_photos',
      where: 'synced = 0 AND inspection_id = ?',
      whereArgs: [inspectionId],
    );
    return maps.map((e) => InspectionPhoto.fromJson(e)).toList();
  }

  Future<void> updateSyncStatus(int id) async {
    final db = await _dbHandler.database;
    await db.update(
      'epmsatca_inspection_photos',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
