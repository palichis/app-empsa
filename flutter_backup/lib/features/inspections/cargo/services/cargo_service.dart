import 'package:epmsa_mobile/features/inspections/cargo/data/cargo_repository.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';

class CargoService {
  final CargoRepository _repository;

  CargoService(this._repository);

  Future<void> saveCargo(Cargo cargo) async {
    await _repository.saveCargo(cargo);
  }

  Future<Cargo?> getCargoById(int id) async {
    return await _repository.getCargoById(id);
  }

  Future<Cargo?> loadCargoForInspection(int inspectionId) {
    return _repository.getCargoByInspectionId(inspectionId);
  }

  Future<List<LandsideEntry>?> loadLandsideForCargo(int cargoId) {
    return _repository.getLandsideEntriesForCargo(cargoId);
  }

  Future<List<AirsideEntry>?> loadAirsideForCargo(int cargoId) {
    return _repository.getAirsideEntriesForCargo(cargoId);
  }

  Future<void> saveLandside(
      List<LandsideEntry> landsideList, int cargoId) async {
    await _repository.saveLandside(landsideList, cargoId);
  }

  Future<void> saveAirside(List<AirsideEntry> airsideList, int cargoId) async {
    await _repository.saveAirside(airsideList, cargoId);
  }
}
