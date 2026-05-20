class Inspections {
  Inspections({
    required this.result,
  });

  final List<Result> result;

  factory Inspections.fromJson(Map<String, dynamic> json){
    return Inspections(
      result: json["result"] == null ? [] : List<Result>.from(json["result"]!.map((x) => Result.fromJson(x))),
    );
  }

  @override
  String toString(){
    return "$result, ";
  }
}

class Result {
  Result({
    required this.id,
    required this.version,
    required this.code,
    required this.name,
    required this.date,
    required this.guideId,
    required this.state,
    required this.madeBy,
    required this.audited,
    required this.inspectionRequirementIds,
    required this.observations,
    required this.processId,
  });

  final int? id;
  final String? version;
  final String? code;
  final String? name;
  final DateTime? date;
  final List<dynamic> guideId;
  final String? state;
  final List<dynamic> madeBy;
  final dynamic audited;
  final List<List<dynamic>> inspectionRequirementIds;
  final dynamic observations;
  final List<dynamic> processId;
  //inspection_number
  //methodology

  factory Result.fromJson(Map<String, dynamic> json){
    return Result(
      id: json["id"],
      version: json["version"],
      code: json["code"],
      name: json["name"],
      date: DateTime.tryParse(json["date"] ?? ""),
      guideId: json["guide_id"] == null ? [] : List<dynamic>.from(json["guide_id"]!.map((x) => x)),
      processId: json["process_id"] == null ? [] : List<dynamic>.from(json["process_id"]!.map((x) => x)),
      state: json["state"],
      madeBy: json["made_by"] == null ? [] : List<dynamic>.from(json["made_by"]!.map((x) => x)),
      audited: json["audited"],
      inspectionRequirementIds: json["inspection_requirement_ids"] == null ? [] : List<List<dynamic>>.from(json["inspection_requirement_ids"]!.map((x) => x == null ? [] : List<dynamic>.from(x!.map((x) => x)))),
      observations: json["observations"],
    );
  }

  @override
  String toString(){
    return "$id, $version, $code, $name, $date, $guideId, $state, $madeBy, $audited, $inspectionRequirementIds, $observations,$processId, ";
  }
}
