import 'package:epmsa_mobile/features/assignments/data/model/entities/process_dto.dart';

import '../datasource/inspectios_remote_ds.dart';
import '../model/entities/area_dto.dart';

class ProcessRepository {
  ProcessRepository._privateConstructor();
  static final ProcessRepository _instance = ProcessRepository._privateConstructor();
  factory ProcessRepository() => _instance;

  static List<ProcessDto> _processDto = [];
  static List<ProcessDto> get process => _processDto;

  static Future<List<ProcessDto>> fetchProcess() async {
    if(_processDto.length>0)
      return _processDto;

    return InspectionsRemoteDS().fetchProcess();
  }
}
