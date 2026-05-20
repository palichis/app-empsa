import 'dart:convert';
import 'dart:io';

import 'package:epmsa_mobile/features/assignments/data/datasource/photos_remote_ds.dart';
import 'package:path/path.dart' as p;

import '../../../../core/handlers/sqlite_handler.dart';
import '../../../../core/helpers/session_helper.dart';
import '../../domain/model/photo_item.dart';

class InspectionsLocalDS{
  void sendInspection(int idInspection, String observations, Map<int, String> qualifications,
      {required List<PhotoItem> photos}) async {
    try {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    final int uid =cached["uid"];

    const Map<String, String> qualificationMap = {
      "Satisfactorio": "Satifactory",
      "Poco satisfactorio": "Unsatisfactory",
      "No cumple": "Notcomply",
      "No aplica": "Notapply",
      "No observado": "Notobserved",
    };
    List lqualifications=qualifications.entries.map((entry) {
      final int id = entry.key;
      final String valueEs = entry.value;
      return {
        "id": id,
        "qualification": qualificationMap[valueEs] ?? "",
      };
    }).toList();

    final Map<String, dynamic> payload = {
      "id": idInspection,
      "made_by": uid,
      "audited": "Analista",
      "inspection_requirement_ids": lqualifications,
      "observations": observations
    };

    final Map<String, dynamic> payloadPhotos = {
      "id": idInspection,
      "photos": photos.map((file) {
        return {
          "path": p.basename(file.file.path), // solo el nombre del archivo
          "filePath": file.file.path, // ruta completa
          "note": file.caption,
        };
      }).toList(),
    };

    final sqlite = SqliteHandler();

    await sqlite.insertAuditoriaInspeccion(
      idInspeccion: idInspection,
      jsonInspeccion: jsonEncode(payload),
      jsonPhotos: jsonEncode(payloadPhotos),
    );

    } catch (e) {
      print("❌ Excepción al enviar inspección local: $e");
    }
  }

  Future<Map<String, dynamic>?> getInspectionById(int idInspection) async {
    final sqlite = SqliteHandler();
    Map<String, dynamic>? datos=await sqlite.getAuditoriaInspeccionById(idInspection);

    return datos;
  }


  //tests
  Future<Map<String, dynamic>?> getTestById(int id) async {
    final sqlite = SqliteHandler();
    Map<String, dynamic>? datos=await sqlite.getAuditoriaTestById(id);

    return datos;
  }


  Future<void> sendTest(
      {required int id,
      required int site_test,
      required String date_test,
      required String time_test,
      String type = "procedure",
      required String brand,
      required String model,
      required String hiding_site,
      required bool detected,
      required bool corrective_action,
      required String collaborator_name,
      required int collaborator_nacionality,
      required String collaborator_identity,
      required String collaborator_email,
      required bool autorization,
      required String observation,
      required String recomendation,
      required int madeTo,
      required List<PhotoItem> photos}) async {
    try {
      final cached = await SessionManager.load();
      final int uid = cached["uid"];

      final Map<String, dynamic> payload = {
        "id": id,
        "site_test": site_test,
        "date_test": date_test,
        "time_test": time_test,
        "type": type,
        "made_by": uid,
        "made_to": madeTo,
        "brand": brand,
        "model": model,
        "hiding_site": hiding_site,
        "detected": detected ? "yes" : "no",
        "corrective_action": corrective_action ? "yes" : "no",
        "collaborator_name": collaborator_name,
        "collaborator_nacionality": collaborator_nacionality,
        "collaborator_identity": collaborator_identity,
        "collaborator_email": collaborator_email,
        "autorization": autorization ? "yes" : "no",
        "observation": observation,
        "recomendation": recomendation
      };

      final Map<String, dynamic> payloadPhotos = {
        "id": id,
        "photos": photos.map((file) {
          return {
            "path": p.basename(file.file.path), // solo el nombre del archivo
            "filePath": file.file.path, // ruta completa
            "note": file.caption,
          };
        }).toList(),
      };

      final sqlite = SqliteHandler();
      await sqlite.insertAuditoriaTest(
        idPrueba: id,
        jsonPrueba: jsonEncode(payload),
        jsonPhotos: jsonEncode(payloadPhotos),
      );
    } catch (e) {
      print("❌ Excepción al enviar inspección local: $e");
    }
  }
}