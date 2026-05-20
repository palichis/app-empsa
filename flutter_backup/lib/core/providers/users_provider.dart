import 'package:epmsa_mobile/core/data/users_repository.dart';
import 'package:epmsa_mobile/core/models/user.dart';
import 'package:epmsa_mobile/core/services/users_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/core/providers/auth_provider.dart';

// Provider para gestionar usuarios
final usersProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<List<User>>>((ref) {
  final session = ref.watch(authProvider);
  final sqliteHandler = SqliteHandler();
  final usersService = UsersService();
  return UsersNotifier(UsersRepository(sqliteHandler, usersService), session!);
});

// StateNotifier que maneja la lista de usuarios ahora devuelve un async value
class UsersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final UsersRepository _repository;
  final Map<String, dynamic> _session;

  UsersNotifier(this._repository, this._session)
      : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    final String? sid = _session['session_id'] as String?;
    final int uid = _session['uid'] as int? ?? 0;

    if (sid == null) {
      state = AsyncValue.error("No hay sesión activa", StackTrace.current);
      return;
    }

    try {
      final data = await _repository.getUsers(sid);
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
