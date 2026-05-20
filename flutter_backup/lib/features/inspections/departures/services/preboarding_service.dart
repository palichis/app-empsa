import 'package:epmsa_mobile/features/inspections/arrivals/national/data/baggage_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/preboarding_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/preboarding_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';

class PreboardingService {
  final PreboardingRepository _preboardingRepository;

  PreboardingService(this._preboardingRepository);

  Future<void> saveNationalLine(
      int departureId, int id, Preboarding data) async {
    await _preboardingRepository.saveNationalPreboardingLine(
      line: data,
      departureId: departureId,
      id: id,
    );
  }

  Future<void> saveInternationalLine(
      int departureId, int id, Preboarding data) async {
    await _preboardingRepository.saveInternationalPreboardingLine(
      line: data,
      departureId: departureId,
      id: id,
    );
  }

  Future<List<Preboarding>> loadNationalPreboardingData(int departureId) {
    return _preboardingRepository.getNationalPreboardingDetails(departureId);
  }

  Future<List<Preboarding>> loadInternationalPreboardingData(int departureId) {
    return _preboardingRepository
        .getInternationalPreboardingDetails(departureId);
  }
}
