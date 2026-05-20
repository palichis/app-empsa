import 'package:epmsa_mobile/features/inspections/cargo/domain/airside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';

class Cargo {
  final int? id;
  final int inspectionId;
  final int synced;
  final GeneralData general;

  String? earthsideNationalHour;
  String? earthsideInternationalHour;
  String? earthsideInternationalBuildingHour;
  String? airsideNationalInternationalHour;

  Cargo({
    this.id,
    required this.inspectionId,
    required this.general,
    this.earthsideNationalHour,
    this.earthsideInternationalHour,
    this.earthsideInternationalBuildingHour,
    this.airsideNationalInternationalHour,
    this.synced = 0,
  });

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(
      id: json['id'],
      inspectionId: json['inspection_id'] ?? 0,
      synced: json['synced'] ?? 0,
      general: GeneralData.fromJson(json),
      earthsideNationalHour: json['earthside_national_hour'] ?? '',
      earthsideInternationalHour: json['earthside_international_hour'] ?? '',
      earthsideInternationalBuildingHour:
          json['earthside_international_building_hour'] ?? '',
      airsideNationalInternationalHour:
          json['airside_national_international_hour'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...general.toJson(),
      'earthside_national_hour': earthsideNationalHour,
      'earthside_international_hour': earthsideInternationalHour,
      'earthside_international_building_hour':
          earthsideInternationalBuildingHour,
      'airside_national_international_hour': airsideNationalInternationalHour,
      'inspection_id': inspectionId,
      'synced': synced,
      'id': id,
    };
  }

  Cargo copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return Cargo.fromJson(data);
  }
}
