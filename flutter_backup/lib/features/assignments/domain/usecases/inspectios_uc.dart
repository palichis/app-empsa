import '../../data/datasource/inspectios_remote_ds.dart';
import '../../data/model/entities/inspections.dart' as inspection;
import '../../data/model/entities/test.dart' as test;
import '../model/task_dto.dart';

class InspectionsUC {

  Future<List<TaskDto>> getAllInspections() async {
    inspection.Inspections? dataInspections= await InspectionsRemoteDS().getAssignedInspections();
    List<TaskDto> allTaskDto=[];
    if(dataInspections!=null){
      for(inspection.Result dataInspection in dataInspections.result){
        try {
          allTaskDto.add(TaskDto(
            id: dataInspection.id ?? 0,
              title: dataInspection.name ?? '',
              description: (dataInspection.processId.length>0) ? dataInspection.processId[0][1]: 'N/D',
              assignedTo: (dataInspection.madeBy.length>0) ? dataInspection.madeBy[0]: 'N/D',
              code: dataInspection.code ?? '',
              date: dataInspection.date != null
                  ? dataInspection.date!.toIso8601String().split('T').first
                  : '',
              duration: 'N/D',
              status: 'Pendiente',
              time: '',
              isInspection: true,
              version: '',
              inspectionRequirementIds: dataInspection.inspectionRequirementIds,
              itemIds: []
          ));
        }catch(e){
          print(e);
        }
      }
    }
    test.Test? dataTest= await InspectionsRemoteDS().getAssignedTests();
    if(dataTest!=null){
      for(test.Result dataTest in dataTest.result){
        try {
          print( dataTest.itemIds);
          allTaskDto.add(TaskDto(
              id: dataTest.id ?? 0,
              version: dataTest.version,
              title: dataTest.name ?? '',
              description: dataTest.testNumber ?? '',
              assignedTo: (dataTest.madeBy.length>0) ? dataTest.madeBy[1]: 'N/D',
              code: dataTest.code ?? '',
              date: dataTest.date != null
                  ? dataTest.date!.toIso8601String().split('T').first
                  : '',
              duration: 'N/D',
              status: 'Pendiente',
              time: '',
              isInspection: false,
              inspectionRequirementIds: [],
              itemIds: dataTest.itemIds.map((item) {
                return ItemDTO(
                  id: item[0] as int,
                  codigo: item[1] as String,
                  descripcion: item[2] as String,
                );
              }).toList()
          ));
        }catch(e){
          print(e);
        }
      }
    }
    return allTaskDto;
  }
}