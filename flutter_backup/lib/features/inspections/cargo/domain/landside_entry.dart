import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo_item.dart';

class LandsideEntry implements CriteriaItem {
  final int? id;
  final int? cargoId;
  final int sequence;
  final String parent;
  final String name;
  final double maxValue;
  final double controlValue;
  final double percentage;
  final String? qualification;
  final String? note;

  @override
  String toString() {
    return 'LandsideEntry{id: $id, cargoId: $cargoId, sequence: $sequence, parent: $parent, name: $name, maxValue: $maxValue, controlValue: $controlValue, percentage: $percentage, qualification: $qualification, note: $note}';
  }

  LandsideEntry({
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
  });

  factory LandsideEntry.fromJson(Map<String, dynamic> json) {
    return LandsideEntry(
      id: json['id'],
      cargoId: json['cargoId'],
      sequence: json['sequence'] ?? 0,
      parent: json['parent'] ?? '',
      name: json['name'] ?? '',
      maxValue: (json['max_value'] ?? 0).toDouble(),
      controlValue: (json['control_value'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      qualification: json['qualification'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence,
      'parent': parent,
      'name': name,
      'max_value': maxValue,
      'control_value': controlValue,
      'percentage': percentage,
      'qualification': qualification,
      'note': note,
    };
  }

  static List<LandsideEntry> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => LandsideEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static const List<String> landSideDetailKeys = [
    'earthside_national_quality',
    'earthside_national_security',
    'earthside_national_environment',
    'earthside_international_quality',
    'earthside_international_security',
    'earthside_international_environment',
    'earthside_international_building_quality',
    'earthside_international_building_security',
    'earthside_international_building_environment',
  ];

  /// Clasifica las entries de landside por grupo
  static List<LandsideEntry> apiJsonToEntries(Map<String, dynamic> block) {
    final List<LandsideEntry> out = [];

    for (final key in landSideDetailKeys) {
      final list = block[key];
      if (list is! List) continue;

      for (final item in list) {
        out.add(
          LandsideEntry.fromJson(item as Map<String, dynamic>)
              .copyWithField('parent', key),
        );
      }
    }
    return out;
  }

  static Map<String, List<Map<String, dynamic>>> entriesToApiJson(
      List<LandsideEntry> list) {
    final Map<String, List<Map<String, dynamic>>> out = {
      for (final k in landSideDetailKeys) k: [],
    };

    for (final e in list) {
      if (!landSideDetailKeys.contains(e.parent)) continue;
      out[e.parent]!.add(e.toJson());
    }
    return out;
  }

  @override
  LandsideEntry copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return LandsideEntry.fromJson(json);
  }
}
