import 'package:epmsa_mobile/features/inspections/departures/data/departures_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/domain/international_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';

class NationalDeparturesService {
  final DeparturesRepository _departuresRepository;

  NationalDeparturesService(this._departuresRepository);

  Future<void> save(NationalDepartures departure) async {
    await _departuresRepository.saveNationalDeparture(departure);
    print("✅ Registro de salida nacional enviado a SQLite");
  }

  Future<NationalDepartures?> loadNationalDepartureForInspection(
      int inspectionId) {
    return _departuresRepository.getNationalDepartureByInspection(inspectionId);
  }
}
