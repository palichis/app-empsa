import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/data/international_arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/international_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/data/national_arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/data/baggage_repository.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/domain/national_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/providers/arrival_notifier.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:epmsa_mobile/features/inspections/shared/services/arrivals_service.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/services/baggage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nationalArrivalServiceProvider = Provider<NationalArrivalsService>((ref) {
  final dbHandler = SqliteHandler();
  final repository = NationalArrivalsRepository(dbHandler);
  return NationalArrivalsService(repository);
});

final arrivalProvider =
    StateNotifierProvider<ArrivalNotifier, InspectionDetails?>(
  (ref) => ArrivalNotifier(),
);

final baggageServiceProvider = Provider<BaggageService>((ref) {
  final dbHandler = SqliteHandler();
  final repository = BaggageRepository(dbHandler);
  return BaggageService(repository);
});

final internationalArrivalServiceProvider =
    Provider<InternationalArrivalService>((ref) {
  final dbHandler = SqliteHandler();
  final repository = InternationalArrivalRepository(dbHandler);
  return InternationalArrivalService(repository);
});
