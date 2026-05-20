class AuditoriaTestDto {
  final int id;
  final int siteTest;
  final String dateTest;
  final String timeTest;
  final String type;
  final int madeBy;
  final int madeTo;
  final String brand;
  final String model;
  final String hidingSite;
  final String detected;
  final String correctiveAction;
  final String collaboratorName;
  final int collaboratorNacionality;
  final String collaboratorIdentity;
  final String collaboratorEmail;
  final String autorization;
  final String observation;
  final String recomendation;

  AuditoriaTestDto({
    required this.id,
    required this.siteTest,
    required this.dateTest,
    required this.timeTest,
    required this.type,
    required this.madeBy,
    required this.madeTo,
    required this.brand,
    required this.model,
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

  // 👇 Convertir JSON → Objeto
  factory AuditoriaTestDto.fromJson(Map<String, dynamic> json) {
    return AuditoriaTestDto(
      id: json['id'] ?? 0,
      siteTest: json['site_test'] ?? 0,
      dateTest: json['date_test'] ?? '',
      timeTest: json['time_test'] ?? '',
      type: json['type'] ?? '',
      madeBy: json['made_by'] ?? 0,
      madeTo: json['made_to'] ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      hidingSite: json['hiding_site'] ?? '',
      detected: json['detected'] ?? '',
      correctiveAction: json['corrective_action'] ?? '',
      collaboratorName: json['collaborator_name'] ?? '',
      collaboratorNacionality: json['collaborator_nacionality'] ?? 0,
      collaboratorIdentity: json['collaborator_identity'] ?? '',
      collaboratorEmail: json['collaborator_email'] ?? '',
      autorization: json['autorization'] ?? '',
      observation: json['observation'] ?? '',
      recomendation: json['recomendation'] ?? '',
    );
  }

  // 👇 Convertir Objeto → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_test': siteTest,
      'date_test': dateTest,
      'time_test': timeTest,
      'type': type,
      'made_by': madeBy,
      'made_to': madeTo,
      'brand': brand,
      'model': model,
      'hiding_site': hidingSite,
      'detected': detected,
      'corrective_action': correctiveAction,
      'collaborator_name': collaboratorName,
      'collaborator_nacionality': collaboratorNacionality,
      'collaborator_identity': collaboratorIdentity,
      'collaborator_email': collaboratorEmail,
      'autorization': autorization,
      'observation': observation,
      'recomendation': recomendation,
    };
  }

  @override
  String toString() {
    return 'AuditoriaTestDto{id: $id, siteTest: $siteTest, dateTest: $dateTest, timeTest: $timeTest, type: $type, madeBy: $madeBy, madeTo: $madeTo, brand: $brand, model: $model, hidingSite: $hidingSite, detected: $detected, correctiveAction: $correctiveAction, collaboratorName: $collaboratorName, collaboratorNacionality: $collaboratorNacionality, collaboratorIdentity: $collaboratorIdentity, collaboratorEmail: $collaboratorEmail, autorization: $autorization, observation: $observation, recomendation: $recomendation}';
  }
}
