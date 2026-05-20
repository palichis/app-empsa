import 'package:epmsa_mobile/features/inspections/arrivals/national/data/baggage_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';

class BaggageService {
  final BaggageRepository _baggageRepository;

  BaggageService(this._baggageRepository);

  Future<void> saveNationalArrivalBaggageField(
      int arrivalId, int id, BaggageTimeData baggageData) async {
    await _baggageRepository.saveNationalArrivalBaggageField(
        arrivalId: arrivalId, id: id, data: baggageData);
  }

  Future<void> saveInternationalArrivalBaggageField(
      int arrivalId, int id, BaggageTimeData baggageData) async {
    await _baggageRepository.saveInternationalArrivalBaggageField(
        arrivalId: arrivalId, id: id, data: baggageData);
  }

  Future<List<BaggageTimeData>> loadBaggageTimeDataforNationalArrival(
      int nationalArrivalId) {
    return _baggageRepository
        .getNationalArrivalBaggageDetails(nationalArrivalId);
  }

  Future<List<BaggageTimeData>> loadBaggageTimeDataforInternationalArrival(
      int nationalArrivalId) {
    return _baggageRepository
        .getInternationalArrivalBaggageDetails(nationalArrivalId);
  }
}
