// lib/features/inspections/departures/services/flight_details_service.dart
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room_repository.dart';

import '../data/flight_options_repository.dart';
import '../data/flight_check_counter_number_repository.dart';
import '../domain/flight_option.dart';
import '../domain/flight_check_counter_number.dart';

class FlightDetailsService {
  final FlightOptionsRepository _optionsRepo;
  final FlightCheckCounterNumberRepository _counterRepo;
  final FlightPreboardingRoomRepository _preboardingRepo;

  FlightDetailsService(
      this._optionsRepo, this._counterRepo, this._preboardingRepo);

  // ---------- FLIGHT OPTIONS ----------
  Future<List<FlightOption>> loadFlightOptions(
    int departureId, {
    bool isNational = false,
  }) {
    return isNational
        ? _optionsRepo.getNationalFlightOptionsDetails(departureId)
        : _optionsRepo.getInternationalFlightOptionsDetails(departureId);
  }

  Future<void> markFlightOptionSelected({
    required int departureId,
    required bool isNational,
    required int optionId,
  }) async {
    await _optionsRepo.setSelected(
      departureId: departureId,
      isNational: isNational,
      optionId: optionId,
    );
  }

  Future<void> saveFlightOptions({
    required int departureId,
    required List<FlightOption> list,
    bool isNational = false,
  }) async {
    for (final o in list) {
      if (isNational) {
        await _optionsRepo.saveNationalFlightOptionLine(
          line: o,
          departureId: departureId,
          id: o.id,
        );
      } else {
        await _optionsRepo.saveInternationalFlightOptionLine(
          line: o,
          departureId: departureId,
          id: o.id,
        );
      }
    }
  }

  // ---------- COUNTERS ----------
  Future<List<FlightCheckCounterNumber>> loadFlightCounters(
    int departureId, {
    bool isNational = false,
  }) {
    return _counterRepo.getFlightCheckCounterNumberDetails(
      departureId: departureId,
      isNational: isNational,
    );
  }

  Future<void> markCounterSelected(
      {required int departureId,
      required bool isNational,
      required int counterId,
      required bool newValue}) async {
    await _counterRepo.setSelected(
      departureId: departureId,
      isNational: isNational,
      counterId: counterId,
      newValue: newValue,
    );
  }

  Future<void> saveFlightCounters({
    required int departureId,
    required List<FlightCheckCounterNumber> list,
    bool isNational = false,
  }) async {
    for (final c in list) {
      await _counterRepo.saveFlightCheckCounterNumberLine(
        line: c,
        departureId: departureId,
        isNational: isNational, // <-- antes estaba fijo en false
      );
      // Si tienes un método nacional aparte, pon el if/else como en options.
    }
  }

  // ---------- PREBOARDING ROOMS ----------
  Future<List<FlightPreboardingRoom>> loadPreboardingRooms(
    int departureId, {
    bool isNational = false,
  }) {
    return _preboardingRepo.getPreboardingRoomDetails(
      departureId: departureId,
      isNational: isNational,
    );
  }

  Future<void> markPreboardingSelected({
    required int departureId,
    required bool isNational,
    required int roomId,
    required bool newValue,
  }) async {
    await _preboardingRepo.setSelected(
      departureId: departureId,
      isNational: isNational,
      roomId: roomId,
      selected: newValue,
    );
  }

  Future<void> savePreboardingRooms({
    required int departureId,
    required List<FlightPreboardingRoom> list,
    bool isNational = false,
  }) async {
    for (final r in list) {
      await _preboardingRepo.savePreboardingRoomLine(
        line: r,
        departureId: departureId,
        isNational: isNational,
      );
    }
  }
}
