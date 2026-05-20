import 'dart:convert';
import 'dart:io';

import 'package:epmsa_mobile/features/assignments/data/datasource/photos_remote_ds.dart';
import 'package:epmsa_mobile/features/assignments/data/model/entities/employee_dto.dart';
import 'package:epmsa_mobile/features/assignments/data/model/entities/process_dto.dart';
import 'package:http/http.dart' as http;

import '../../../../core/helpers/session_helper.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/model/photo_item.dart';
import '../model/entities/area_dto.dart';
import '../model/entities/inspections.dart';
import '../model/entities/nationality_dto.dart';
import '../model/entities/test.dart';

class InspectionsRemoteDS{
  InspectionsRemoteDS();

  Future<List<AreaDto>> fetchAreas() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-areas");

    final response = await http.get(url,
      headers: {
      "Content-Type": "application/json",
      "Cookie": "session_id=$sid",
    },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> result = data['result'];
      return result.map((json) => AreaDto.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener las áreas: ${response.statusCode}");
    }
  }

  Future<List<NationalityDto>> fetchNationalities() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-nationalities");

    final response = await http.get(url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sid",
      },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> result = data['result'];
      return result.map((json) => NationalityDto.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener las NationalityDto: ${response.statusCode}");
    }
  }

  Future<List<EmployeeDto>> fetchEmployees() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-employees");

    final response = await http.get(url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sid",
      },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> result = data['result'];
      return result.map((json) => EmployeeDto.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener las employees: ${response.statusCode}");
    }
  }

  Future<List<ProcessDto>> fetchProcess() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-process");

    final response = await http.get(url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sid",
      },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> result = data['result'];
      return result.map((json) => ProcessDto.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener los ProcessDto: ${response.statusCode}");
    }
  }

  Future<Inspections?> getAssignedInspections() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-inspections");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "session_id=$sid",
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("Response from API: ${decoded}");
        return Inspections.fromJson(decoded);
      }
    }catch(e){
      print(e);
    }

    return null;
  }

  Future<Test?> getAssignedTests() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-tests");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sid",
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print("Response from API: ${decoded}");
      return  Test.fromJson(decoded);
    }

    return null;
  }

  void sendInspection(int idInspection, String observations, Map<int, String> qualifications,
      {required List<PhotoItem> photos}) async {
    String baseUrl = await ApiService.getBaseUrl();
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    final int uid =cached["uid"];
    final Uri url = Uri.parse("$baseUrl/api/sync-inspections");

    if(photos.isNotEmpty)
      PhotoRemoteDS().putPictures(false, photos, idInspection);

    // Mapeo de Español → Inglés
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
        "qualification": qualificationMap[valueEs] ?? "Notapply",
      };
    }).toList();

    final Map<String, dynamic> payload = {
      "id": idInspection,
      "made_by": uid,
      "audited": "Analista",
      "inspection_requirement_ids": lqualifications,
      "observations": observations
    };
    print('***********************');
print(jsonEncode(payload));
    print(url);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": "session_id=$sid",
        },
        body: jsonEncode(payload),
      );
print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Inspección enviada correctamente");
        print("Respuesta: ${response.body}");
      } else {
        print("⚠️ Error al enviar inspección: ${response.statusCode}");
        print("Detalles: ${response.body}");
      }
    } catch (e) {
      print("❌ Excepción al enviar inspección: $e");
    }
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
      required List<PhotoItem> photos
      }) async {
    String baseUrl = await ApiService.getBaseUrl();
    final cached = await SessionManager.load();
    final String? sid = cached["session_id"];
    final int uid =cached["uid"];
    final Uri url = Uri.parse("$baseUrl/api/sync-tests");
    if(photos.isNotEmpty)
      PhotoRemoteDS().putPictures(true, photos, id);

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

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": "session_id=$sid",
        },
        body: jsonEncode(payload),
      );
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Inspección enviada correctamente");
        print("Respuesta: ${response.body}");
      } else {
        print("⚠️ Error al enviar inspección: ${response.statusCode}");
        print("Detalles: ${response.body}");
      }
    } catch (e) {
      print("❌ Excepción al enviar inspección: $e");
    }
  }
}