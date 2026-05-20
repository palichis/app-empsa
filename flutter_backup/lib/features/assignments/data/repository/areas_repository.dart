import '../datasource/inspectios_remote_ds.dart';
import '../model/entities/area_dto.dart';

class AreasRepository {
  AreasRepository._privateConstructor();
  static final AreasRepository _instance = AreasRepository._privateConstructor();
  factory AreasRepository() => _instance;

  List<AreaDto> _areas = [];
  List<AreaDto> get areas => _areas;

  Future<List<AreaDto>> fetchAreas() async {
    if(_areas.length>0)
      return _areas;
    print('getRemote');
    return InspectionsRemoteDS().fetchAreas();
  }
}
