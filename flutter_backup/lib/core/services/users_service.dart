import 'package:epmsa_mobile/core/models/user.dart';
import 'package:epmsa_mobile/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersService {
  Future<List<User>> fetchUsersFromApi(String sessionId) async {
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/users_list");

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
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception(
          "❌ Error al obtener datos de la API: ${response.statusCode}");
    }
  }
}
