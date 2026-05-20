class TaskDto {
  final int id;
  final String title;
  final String code;
  final String date;
  final String time;
  final String duration;
  final String assignedTo;
  final String description;
  final String status;
  final bool isInspection;
  final List<List<dynamic>> inspectionRequirementIds;

  //testExclusive
  final String? version;
  final List<ItemDTO> itemIds;

  TaskDto({
    required this.itemIds,
    required this.version,
    required this.id,
    required this.title,
    required this.code,
    required this.date,
    required this.time,
    required this.duration,
    required this.assignedTo,
    required this.description,
    required this.status,
    required this.isInspection,
    required this.inspectionRequirementIds,
  });
}

class ItemDTO {
  final int id;
  final String codigo;
  final String descripcion;

  ItemDTO({required this.id, required this.codigo, required this.descripcion});
}

