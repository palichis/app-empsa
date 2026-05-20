import 'package:epmsa_mobile/features/assignments/data/model/entities/employee_dto.dart';
import 'package:epmsa_mobile/features/assignments/data/model/entities/nationality_dto.dart';

import '../datasource/inspectios_remote_ds.dart';
import '../model/entities/area_dto.dart';

class NationalitiesRepository {
  NationalitiesRepository._privateConstructor();
  static final NationalitiesRepository _instance = NationalitiesRepository._privateConstructor();
  factory NationalitiesRepository() => _instance;

  List<NationalityDto> _nationalities = [];
  List<NationalityDto> get nationalities => _nationalities;

  Future<List<NationalityDto>> fetchNationalities() async {
    if(_nationalities.length>0)
      return _nationalities;

    return InspectionsRemoteDS().fetchNationalities();
  }

  Future<List<EmployeeDto>> fetchEmployees() async {
    return InspectionsRemoteDS().fetchEmployees();
  }
}
