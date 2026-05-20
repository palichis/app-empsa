import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/core/providers/auth_provider.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/international_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/domain/national_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/providers/cargo_provider.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/domain/international_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/providers/depatures_provider.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/public_halls_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_options.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/header/data/inspections_repository.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/services/inspections_service.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/inspections_photo_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/services/inspection_photo_service.dart';
import 'package:epmsa_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assignedInspectionsProvider =
    FutureProvider<List<Inspection>>((ref) async {
  final service = ref.watch(inspectionsServiceProvider);
  return await service.fetchAssignedInspections(ref);
});

final inspectionsRepositoryProvider = Provider<InspectionsRepository>((ref) {
  final db = ref.watch(sqliteHandlerProvider);
  return InspectionsRepository(db);
});

final inspectionsServiceProvider = Provider<InspectionsService>((ref) {
  final repo = ref.watch(inspectionsRepositoryProvider);
  final session = ref.watch(authProvider);
  return InspectionsService(repo, session!);
});

final photoServiceProvider = Provider<InspectionPhotoService>((ref) {
  return InspectionPhotoService(InspectionPhotoRepository(SqliteHandler()));
});

/*
final inspectionServiceProvider =
    Provider.family<dynamic, Inspection>((ref, inspection) {
  if (inspection is NationalArrival) {
    return ref.read(nationalArrivalServiceProvider);
  } else if (inspection is InternationalArrival) {
    return ref.read(internationalArrivalServiceProvider);
  } else if (inspection is NationalDepartures) {
    return ref.read(NationaldeparturesServiceProvider);
  } else if (inspection is InternationalDepartures) {
    return ref.read(InternationaldeparturesServiceProvider);
  } else {
    throw UnimplementedError('Tipo de inspección no soportado');
  }
});*/

final inspectionProvider =
    StateNotifierProvider<InspectionNotifier, Inspection?>(
  (ref) => InspectionNotifier(),
);

final inspectionDetailsProvider =
    StateNotifierProvider<InspectionDetailsNotifier, InspectionDetails?>(
  (ref) => InspectionDetailsNotifier(),
);

final inspectionServiceSelectorProvider =
    Provider.family<dynamic, InspectionDetails>((ref, inspection) {
  if (inspection is NationalArrival) {
    return ref.read(nationalArrivalServiceProvider);
  } else if (inspection is InternationalArrival) {
    return ref.read(internationalArrivalServiceProvider);
  } else if (inspection is NationalDepartures) {
    return ref.read(NationaldeparturesServiceProvider);
  } else if (inspection is InternationalDepartures) {
    return ref.read(InternationaldeparturesServiceProvider);
  } else {
    throw UnimplementedError(
        'Tipo de Arrival no soportado: ${inspection.runtimeType}');
  }
});

/*final publicHallOptionServiceProvider = Provider<PublicHallOption>((ref) {
  final optionsRepo = ref.watch(flightOptionsRepositoryProvider);
  return PublicHallOptionService(optionsRepo);
});*/

final publicHallOptionRepositoryProvider =
    Provider<PublicHallOptionRepository>((ref) {
  final handler = ref.watch(sqliteHandlerProvider);
  return PublicHallOptionRepository(handler);
});

class InspectionNotifier extends StateNotifier<Inspection?> {
  InspectionNotifier() : super(null);

  void setInspection(Inspection inspection) {
    state = inspection;
  }

  void updateField(String field, dynamic value) {
    if (state != null) {
      state = state!.copyWithField(field, value);
    }
  }
}

class InspectionDetailsNotifier extends StateNotifier<InspectionDetails?> {
  InspectionDetailsNotifier() : super(null);

  void setInspectionDetails(InspectionDetails inspection) {
    state = inspection;
  }

  void updateField(String field, dynamic value) {
    if (state != null) {
      state = state!.copyWithField(field, value);
    }
  }
}
