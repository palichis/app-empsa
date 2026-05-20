import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo_item.dart';

class AirsideEntry implements CriteriaItem {
  final int? id;
  final int? cargoId;
  final int sequence;
  final String parent; // <- clave del bloque (quality/security/environment)
  final String name;
  final double maxValue;
  final double controlValue;
  final double percentage;
  final String? qualification;
  final String? note;

  AirsideEntry({
    this.id,
    this.cargoId,
    required this.sequence,
    required this.parent,
    required this.name,
    required this.maxValue,
    required this.controlValue,
    required this.percentage,
    this.qualification,
    this.note,
    //this.photo,
  });

  factory AirsideEntry.fromJson(Map<String, dynamic> json) {
    return AirsideEntry(
      id: json['id'],
      cargoId: json['cargo_id'],
      sequence: (json['sequence'] ?? 0) as int,
      parent: json['parent'] ?? '',
      name: json['name'] ?? '',
      maxValue: (json['max_value'] ?? 0).toDouble(),
      controlValue: (json['control_value'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      qualification: json['qualification'],
      note: json['note'] ?? '',
      //photo: json['photo'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cargo_id': cargoId,
      'sequence': sequence,
      'parent': parent,
      'name': name,
      'max_value': maxValue,
      'control_value': controlValue,
      'percentage': percentage,
      'qualification': qualification,
      'note': note,
      //if (photo != null) 'photo': photo,
    };
  }

  static const List<String> airSideDetailKeys = [
    'airside_national_international_quality',
    'airside_national_international_security',
    'airside_national_international_environment',
  ];

  static List<AirsideEntry> apiJsonToEntries(Map<String, dynamic> block) {
    final List<AirsideEntry> out = [];

    for (final key in airSideDetailKeys) {
      final list = block[key];
      if (list is! List) continue;

      for (final item in list) {
        out.add(
          AirsideEntry.fromJson(item as Map<String, dynamic>)
              .copyWithField('parent', key),
        );
      }
    }
    return out;
  }

  static List<AirsideEntry> fromJsonList(List<dynamic> list) {
    return list.map((item) => AirsideEntry.fromJson(item)).toList();
  }

  @override
  AirsideEntry copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return AirsideEntry.fromJson(json);
  }
}
