import 'dart:convert';

import 'package:epmsa_mobile/core/services/api_service.dart';
import 'package:epmsa_mobile/features/penalties/data/penalty_repository.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PenaltyService {
  final PenaltyRepository _penaltyRepository;

  PenaltyService(this._penaltyRepository);

  /// Guarda una nueva penalización en SQLite
  Future<void> savePenalty(Penalty penalty) async {
    await _penaltyRepository.savePenalty(penalty);
    print("✅ Penalización guardada en SQLite.");
  }

  /// Obtiene todas las penalizaciones almacenadas en SQLite
  Future<List<Penalty>> getPenalties() async {
    return await _penaltyRepository.getPenalties();
  }

  /// Obtiene solo las penalizaciones pendientes de sincronización
  Future<List<Penalty>> getPendingPenalties() async {
    return await _penaltyRepository.getPendingPenalties();
  }

  /// Elimina una penalización después de sincronizarla con el servidor
  Future<void> deletePenalty(int id) async {
    await _penaltyRepository.deletePenalty(id);
    print("✅ Penalización eliminada de SQLite tras sincronización.");
  }

  /// Envía las penalizaciones pendientes a la API
  Future<void> syncPenalties(String sessionId) async {
    final pendingPenalties = await getPendingPenalties();
    print("sanciones a sincronizar");
    print(pendingPenalties.length);
    String baseUrl = await ApiService.getBaseUrl();
    final Uri apiUrl = Uri.parse("$baseUrl/api/create_penalty");
    for (Penalty penalty in pendingPenalties) {
      print("penalty body");
      DateTime parsedDate = DateFormat("d/M/yyyy").parse(penalty.date);
      String formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);

      final jsonData = {
        ...penalty.toJson(),
        "date": formattedDate,
      };
      //print(jsonData);

      try {
        final response = await http.post(apiUrl,
            headers: {
              "Content-Type": "application/json",
              "Cookie": "session_id=$sessionId",
            },
            body: jsonEncode({"jsonrpc": "2.0", "params": jsonData}));
        print("response code:");
        print(response.statusCode);
        if (response.statusCode == 200) {
          // Código 201: Creado
          await _penaltyRepository.deletePenalty(penalty.id!);
          print(
              "✅ Penalización ${penalty.id} sincronizada y eliminada de SQLite.");
        } else {
          print(
              "⚠️ Error sincronizando penalización ${penalty.id}: ${response.body}");
        }
      } catch (e) {
        print(
            "❌ Error de conexión al sincronizar penalización ${penalty.id}: $e");
      }
    }
  }
}
