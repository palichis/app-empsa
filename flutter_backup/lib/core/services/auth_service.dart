import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epmsa_mobile/core/helpers/session_helper.dart';
import 'package:epmsa_mobile/core/services/api_service.dart';
import 'package:http/http.dart' as http;

class AuthService {
  Future<Map<String, dynamic>> authenticate(
      String username, String password) async {
    String baseUrl = await ApiService.getBaseUrl();
    String dbName = await ApiService.getDbName();
    final Uri url = Uri.parse("$baseUrl/web/session/authenticate");
    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "jsonrpc": "2.0",
              "params": {"db": dbName, "login": username, "password": password}
            }),
          )
          .timeout(const Duration(seconds: 10));
      ;
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("result") && data["result"] != null) {
          int uid = data["result"]["uid"] ?? 0;
          // Extrae el `session_id` de las cookies
          String? sessionId = response.headers['set-cookie']
              ?.split(';')
              .firstWhere((cookie) => cookie.startsWith("session_id="),
                  orElse: () => "")
              .replaceAll("session_id=", "");
          if (sessionId != null) await SessionManager.save(sessionId, uid);
          return {'session_id': sessionId, 'uid': uid};
          ;
        } else {
          throw Exception('Respuesta inválida del servidor');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        throw Exception('Error del servidor. Inténtalo más tarde');
      }
    } on SocketException {
      final cached = await SessionManager.load();
      if (cached != null) return cached;
      throw Exception('Sin conexión. Verifica tu internet');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intenta más tarde');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado');
    }
  }
}
