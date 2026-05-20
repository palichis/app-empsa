import 'package:epmsa_mobile/features/inspections/departures/data/departures_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/domain/international_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';

class InternationalDeparturesService {
  final DeparturesRepository _departuresRepository;

  InternationalDeparturesService(this._departuresRepository);

  Future<void> save(InternationalDepartures departure) async {
    await _departuresRepository.saveInternationalDeparture(departure);
    print("✅ Registro de salida internacional enviado a SQLite");
  }

  Future<InternationalDepartures?> loadInternationalDepartureForInspection(
      int inspectionId) {
    return _departuresRepository
        .getInternationalDepartureByInspection(inspectionId);
  }
}
