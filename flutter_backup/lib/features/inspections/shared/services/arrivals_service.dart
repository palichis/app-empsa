import 'package:epmsa_mobile/features/inspections/arrivals/international/data/international_arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/international_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/data/national_arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';

abstract class UniversalArrivalService {
  Future<InspectionDetails?> loadArrivalForInspection(int inspectionId);
  Future<void> save(InspectionDetails arrival);
}

class NationalArrivalsService implements UniversalArrivalService {
  final NationalArrivalsRepository _arrivalRepository;

  NationalArrivalsService(this._arrivalRepository);

  @override
  Future<void> save(InspectionDetails arrival) async {
    await _arrivalRepository.saveArrival(arrival);
  }

  Future<void> saveAll(String json) async {
    await _arrivalRepository.saveAllArrivals(json);
  }

  Future<String> getAllArrivals() async {
    return await _arrivalRepository.getAllArrivals();
  }

  Future<InspectionDetails?> loadArrivalForInspection(int inspectionId) {
    return _arrivalRepository.getArrivalByInspection(inspectionId);
  }
}

class InternationalArrivalService implements UniversalArrivalService {
  final InternationalArrivalRepository _repository;

  InternationalArrivalService(this._repository);

  @override
  Future<InspectionDetails?> loadArrivalForInspection(int inspectionId) async {
    return await _repository.getArrivalByInspection(inspectionId);
  }

  @override
  Future<void> save(InspectionDetails arrival) async {
    if (arrival is InternationalArrival) {
      await _repository.saveArrival(arrival);
    } else {
      throw Exception(
          'Tipo de arrival no compatible con InternationalArrivalService');
    }
  }
}
