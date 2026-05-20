class Preboarding {
  final int? id;
  final String? area;
  final bool? used;
  final int? usedChairs;
  final int? availableChairs;
  final int? usedArea;
  final int? availableArea;
  final int? occupancyPercentage;
  final int? nationalDepartureId;
  final int? internationalDepartureId;

  Preboarding(
      {this.id,
      required this.area,
      required this.used,
      required this.usedChairs,
      required this.availableChairs,
      required this.usedArea,
      required this.availableArea,
      required this.occupancyPercentage,
      this.nationalDepartureId,
      this.internationalDepartureId});

  factory Preboarding.fromJson(Map<String, dynamic> json) {
    return Preboarding(
      id: json['id'],
      area: json['area'],
      used: (json['used'] ?? 0) == 1,
      usedChairs: int.tryParse('${json['used_chairs']}') ?? 0,
      availableChairs: int.tryParse('${json['available_chairs']}') ?? 0,
      usedArea: int.tryParse('${json['used_area']}') ?? 0,
      availableArea: int.tryParse('${json['available_area']}') ?? 0,
      occupancyPercentage: (json['occupancy_percentage'] as num?)?.toInt() ??
          int.tryParse(json['occupancy_percentage']?.toString() ?? '') ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area': area,
      'used': used == true ? 1 : 0,
      'used_chairs': usedChairs,
      'available_chairs': availableChairs,
      'used_area': usedArea,
      'available_area': availableArea,
      'occupancy_percentage': occupancyPercentage,
    };
  }

  Preboarding copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return Preboarding.fromJson(data);
  }
}
