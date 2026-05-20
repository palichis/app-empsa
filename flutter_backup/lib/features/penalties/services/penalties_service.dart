import 'dart:convert';
import 'package:epmsa_mobile/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:epmsa_mobile/features/penalties/domain/penalty_catalog.dart';

class PenaltiesService {
  /// Obtiene penalizaciones desde la API de Odoo
  Future<List<PenaltyCatalog>> fetchPenalties(String sessionId) async {
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/penalties_list");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['result']['data'];
      return data.map((e) => PenaltyCatalog.fromJson(e)).toList();
    } else {
      throw Exception(
          "❌ Error al obtener datos de la API: ${response.statusCode}");
    }
  }
}
