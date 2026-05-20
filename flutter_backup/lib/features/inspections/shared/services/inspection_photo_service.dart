import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/inspections_photo_repository.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../domain/inspection_photo.dart';

class InspectionPhotoService {
  final InspectionPhotoRepository _photoRepository;

  InspectionPhotoService(this._photoRepository);

  Future<void> savePhoto(InspectionPhoto photo) async {
    await _photoRepository.savePhoto(photo);
    print(
        "✅ Foto guardada para la inspección ${photo.inspectionId} a través del servicio: ${photo.path}");
  }

  Future<List<InspectionPhoto>> getPhotosBySection(
      int inspectionId, String section) async {
    return await _photoRepository.getPhotosByInspection(inspectionId, section);
  }

  Future<String> _createZip(List<File> files) async {
    final tempDir = Directory.systemTemp;
    final zipFile = File('${tempDir.path}/inspection_photos.zip');
    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);

    for (var file in files) {
      encoder.addFile(file);
    }

    encoder.close();
    return zipFile.path;
  }

  Future<String> syncPhotos(int inspectionId, String sessionId) async {
    try {
      final photos = await _photoRepository.getUnsyncedPhotos(inspectionId);
      if (photos.isEmpty) {
        return "No hay fotos nuevas para sincronizar en la inspección $inspectionId";
      }

      List<File> imageFiles = photos.map((photo) => File(photo.path)).toList();

      var jsonData = jsonEncode({
        "photos": photos
            .map((photo) => {
                  "inspection_id": photo.inspectionId,
                  "section": photo.section,
                  "file_name": photo.path.split('/').last,
                  "timestamp": photo.timestamp.toIso8601String()
                })
            .toList(),
        "other_data": {
          "inspection_id": inspectionId,
          "photo_count": photos.length
        }
      });

      final Uri url = Uri.parse("http://odoo-server/api/sync-photos");

      String zipPath = await _createZip(imageFiles);
      File zipFile = File(zipPath);

      var request = http.MultipartRequest(
        'POST',
        url,
      );

      // Cabecera con sesión
      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        "Cookie": "session_id=$sessionId",
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'zip_file',
          zipFile.path,
        ),
      );

      request.fields['json_data'] = jsonData;
      var response = await request.send();

      if (response.statusCode == 200) {
        for (var photo in photos) {
          await _photoRepository.updateSyncStatus(photo.id!);
        }
        return "Sincronización exitosa para la inspección $inspectionId";
      } else {
        return "❌ Error al subir imágenes: ${response.statusCode} - ${await response.stream.bytesToString()}";
      }
    } catch (e) {
      return "❌ Error: $e";
    }
  }
}
