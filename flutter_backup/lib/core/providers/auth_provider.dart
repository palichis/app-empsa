import 'package:epmsa_mobile/core/helpers/session_helper.dart';
import 'package:epmsa_mobile/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, Map<String, dynamic>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<Map<String, dynamic>> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super({}) {
    _bootstrap();
  }

  Future<void> _bootstrap() async => state = await SessionManager.load();

  Future<bool> login(String username, String password) async {
    try {
      final session = await _authService.authenticate(username, password);
      //if (session["session_id"] != null) {
      state = session;
      return true;
      //}
      //return false; // Credenciales inválidas
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  void logout() {
    state = {}; // Limpia la sesión
  }
}
