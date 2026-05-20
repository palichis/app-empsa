import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/core/models/user.dart';
import 'package:epmsa_mobile/core/services/users_service.dart';

class UsersRepository {
  final SqliteHandler _sqliteHandler;
  final UsersService _usersService;

  UsersRepository(this._sqliteHandler, this._usersService);

  Future<List<User>> getUsers(String sessionId) async {
    // Intentar obtener los datos desde la base de datos local primero
    List<User> localUsers = await _sqliteHandler.getUsers();

    if (localUsers.isNotEmpty) {
      return localUsers;
    } else {
      // Si no hay datos en local, obtener desde la API
      List<User> apiUsers = await _usersService.fetchUsersFromApi(sessionId);
      
      // Guardar en SQLite para futuras consultas
      await _sqliteHandler.saveUsers(apiUsers);

      return apiUsers;
    }
  }
}
