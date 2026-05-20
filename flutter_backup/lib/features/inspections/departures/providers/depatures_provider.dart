import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/checkins_counter_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/departures_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_check_counter_number_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_options_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/preboarding_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/services/international_departures_service.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/services/national_departures_service.dart';
import 'package:epmsa_mobile/features/inspections/departures/services/flight_details_service.dart';
import 'package:epmsa_mobile/features/inspections/departures/services/preboarding_service.dart';
import 'package:epmsa_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NationaldeparturesServiceProvider =
    Provider<NationalDeparturesService>((ref) {
  final dbHandler = SqliteHandler();
  final repository = DeparturesRepository(dbHandler);
  return NationalDeparturesService(repository);
});

final InternationaldeparturesServiceProvider =
    Provider<InternationalDeparturesService>((ref) {
  final dbHandler = SqliteHandler();
  final repository = DeparturesRepository(dbHandler);
  return InternationalDeparturesService(repository);
});

final preboardingServiceProvider = Provider<PreboardingService>((ref) {
  final dbHandler = SqliteHandler();
  final repository = PreboardingRepository(dbHandler);
  return PreboardingService(repository);
});

// providers/flight_details_providers.dart
final flightDetailsServiceProvider = Provider<FlightDetailsService>((ref) {
  final optionsRepo = ref.watch(flightOptionsRepositoryProvider);
  final countersRepo = ref.watch(flightCheckCounterNumberRepositoryProvider);
  final preboardingroomsRepo = ref.watch(preboardingRoomRepositoryProvider);
  return FlightDetailsService(optionsRepo, countersRepo, preboardingroomsRepo);
});

final flightOptionsRepositoryProvider =
    Provider<FlightOptionsRepository>((ref) {
  final handler = ref.watch(sqliteHandlerProvider);
  return FlightOptionsRepository(handler);
});

final flightCheckCounterNumberRepositoryProvider =
    Provider<FlightCheckCounterNumberRepository>((ref) =>
        FlightCheckCounterNumberRepository(ref.watch(sqliteHandlerProvider)));

final preboardingRoomRepositoryProvider =
    Provider<FlightPreboardingRoomRepository>((ref) =>
        FlightPreboardingRoomRepository(ref.watch(sqliteHandlerProvider)));

final checkinCounterRepositoryProvider = Provider<CheckinCounterRepository>(
    (ref) => CheckinCounterRepository(ref.watch(sqliteHandlerProvider)));
