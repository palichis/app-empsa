import 'dart:convert';

import 'package:epmsa_mobile/features/novedades/data/model/categories_dto.dart';
import 'package:epmsa_mobile/features/novedades/data/model/criticality_dto.dart';
import 'package:http/http.dart' as http;

import '../../../../core/helpers/session_helper.dart';
import '../../../../core/services/api_service.dart';

class NoveltyRemoteDS{

  Future<List<CriticalityDTO>> fetchCriticality() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-ticket-levels");

    final response = await http.get(url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sid",
      },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> result = data['result'];
      return result.map((json) => CriticalityDTO.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener las CriticalityDTO: ${response.statusCode}");
    }
  }

  Future<List<CategoriesDTO>> fetchCategories() async {
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-ticket-categories");

    final response = await http.get(url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sid",
      },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> result = data['result'];
      return result.map((json) => CategoriesDTO.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener las categories: ${response.statusCode}");
    }
  }

  Future<bool> syncNovelty({
    required String name,
    required String description,
    required String date,
    required int categoryId,
    required int criticalityId,
    required String place,
    required int inspectionId,
    required bool isInspection
  }) async {
    try{
      final cached = await SessionManager.load();
      final String? sid = cached["session_id"];
      String baseUrl = await ApiService.getBaseUrl();
      final Uri url = Uri.parse(
          "$baseUrl/api/create-${isInspection ? 'inspection' : 'test'}-ticket");

      final body = {
        "name": name,
        "description": description,
        "date": date,
        "category_id": categoryId,
        "criticality_id": criticalityId,
        "place": place,
        (isInspection ? "inspection_report_id" : 'test_report_id'):
            inspectionId,
      };
      print(url);
      print(body);

      final response = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "Cookie": "session_id=$sid",
          },
          body: jsonEncode(body));
      print(body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        return true;
      } else {
        return false;
      }
    }catch(e){
      print(e);
      return false;
    }
  }
}