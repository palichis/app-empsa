// lib/features/inspections/departures/services/flight_details_service.dart
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/public_halls_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_options.dart';

class PublicHallsService {
  final PublicHallOptionRepository _publicHallRepo;

  PublicHallsService(this._publicHallRepo);

  Future<void> savePublicHalls({
    required int inspectionId,
    required List<PublicHallOption> list,
  }) async {
    for (final c in list) {
      await _publicHallRepo.savePublicHallsLine(
          line: c, inspectionId: inspectionId);
    }
  }

  Future<List<PublicHallOption>> loadPreboardingRooms(int inspectionId) {
    return _publicHallRepo.getPublicHallsDetails(inspectionId);
  }

  Future<void> markPreboardingSelected({
    required int inspectionId,
    required int id,
  }) async {
    await _publicHallRepo.markOptionSelected(
      inspectionId: inspectionId,
      id: id,
    );
  }
}
