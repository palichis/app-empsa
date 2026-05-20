class Test {
  Test({
    required this.result,
  });

  final List<Result> result;

  factory Test.fromJson(Map<String, dynamic> json){
    return Test(
      result: json["result"] == null ? [] : List<Result>.from(json["result"]!.map((x) => Result.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "result": result.map((x) => x?.toJson()).toList(),
  };

  @override
  String toString(){
    return "$result, ";
  }
}

class Result {
  Result({
    required this.id,
    required this.name,
    required this.version,
    required this.code,
    required this.date,
    required this.testNumber,
    required this.dateTest,
    required this.timeTest,
    required this.siteTest,
    required this.state,
    required this.type,
    required this.madeBy,
    required this.brand,
    required this.model,
    required this.itemIds,
    required this.hidingSite,
    required this.detected,
    required this.correctiveAction,
    required this.collaboratorName,
    required this.collaboratorNacionality,
    required this.collaboratorIdentity,
    required this.collaboratorEmail,
    required this.autorization,
    required this.observation,
    required this.recomendation,
  });

  final int? id;
  final String? name;
  final String? version;
  final String? code;
  final DateTime? date;
  final String? testNumber;
  final dynamic dateTest;
  final dynamic timeTest;
  final dynamic siteTest;
  final String? state;
  final dynamic type;
  final List<dynamic> madeBy;
  final dynamic brand;
  final dynamic model;
  final List<List<dynamic>> itemIds;
  final dynamic hidingSite;
  final dynamic detected;
  final dynamic correctiveAction;
  final dynamic collaboratorName;
  final dynamic collaboratorNacionality;
  final dynamic collaboratorIdentity;
  final dynamic collaboratorEmail;
  final dynamic autorization;
  final dynamic observation;
  final dynamic recomendation;
  //

  factory Result.fromJson(Map<String, dynamic> json){
    return Result(
      id: json["id"],
      name: json["name"],
      version: json["version"],
      code: json["code"],
      date: DateTime.tryParse(json["date"] ?? ""),
      testNumber: json["test_number"],
      dateTest: json["date_test"],
      timeTest: json["time_test"],
      siteTest: json["site_test"],
      state: json["state"],
      type: json["type"],
      madeBy: json["made_by"] == null ? [] : List<dynamic>.from(json["made_by"]!.map((x) => x)),
      brand: json["brand"],
      model: json["model"],
      itemIds: json["item_ids"] == null ? [] : List<List<dynamic>>.from(json["item_ids"]!.map((x) => x == null ? [] : List<dynamic>.from(x!.map((x) => x)))),
      hidingSite: json["hiding_site"],
      detected: json["detected"],
      correctiveAction: json["corrective_action"],
      collaboratorName: json["collaborator_name"],
      collaboratorNacionality: json["collaborator_nacionality"],
      collaboratorIdentity: json["collaborator_identity"],
      collaboratorEmail: json["collaborator_email"],
      autorization: json["autorization"],
      observation: json["observation"],
      recomendation: json["recomendation"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "version": version,
    "code": code,
    "date": "${date.toString()}",
    "test_number": testNumber,
    "date_test": dateTest,
    "time_test": timeTest,
    "site_test": siteTest,
    "state": state,
    "type": type,
    "made_by": madeBy.map((x) => x).toList(),
    "brand": brand,
    "model": model,
    "item_ids": itemIds.map((x) => x.map((x) => x).toList()).toList(),
    "hiding_site": hidingSite,
    "detected": detected,
    "corrective_action": correctiveAction,
    "collaborator_name": collaboratorName,
    "collaborator_nacionality": collaboratorNacionality,
    "collaborator_identity": collaboratorIdentity,
    "collaborator_email": collaboratorEmail,
    "autorization": autorization,
    "observation": observation,
    "recomendation": recomendation,
  };

  @override
  String toString(){
    return "$id, $name, $version, $code, $date, $testNumber, $dateTest, $timeTest, $siteTest, $state, $type, $madeBy, $brand, $model, $itemIds, $hidingSite, $detected, $correctiveAction, $collaboratorName, $collaboratorNacionality, $collaboratorIdentity, $collaboratorEmail, $autorization, $observation, $recomendation, ";
  }
}
