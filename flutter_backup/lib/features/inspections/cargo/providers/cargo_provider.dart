import 'package:epmsa_mobile/features/inspections/cargo/data/cargo_repository.dart';
import 'package:epmsa_mobile/features/inspections/cargo/services/cargo_service.dart';
import 'package:epmsa_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cargoRepositoryProvider = Provider<CargoRepository>((ref) {
  final dbHandler = ref.read(sqliteHandlerProvider);
  return CargoRepository(dbHandler);
});

final cargoServiceProvider = Provider<CargoService>((ref) {
  final repository = ref.read(cargoRepositoryProvider);
  return CargoService(repository);
});
