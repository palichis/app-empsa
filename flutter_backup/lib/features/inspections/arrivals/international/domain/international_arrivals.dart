import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/customs.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_area_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/observations_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';

class InternationalArrival implements InspectionDetails {
  @override
  final int? id;
  @override
  final int inspectionId;
  @override
  final int synced;

  @override
  final GeneralData general;
  @override
  final PublicHallData publicHall;
  //final BaggageTimeData baggageTime;
  final BaggageAreaData baggageArea;
  final MigrationData migration;
  final CustomsData customs;
  @override
  final ObservationsData observations;

  InternationalArrival({
    this.id,
    required this.general,
    required this.publicHall,
    //required this.baggageTime,
    required this.baggageArea,
    required this.migration,
    required this.customs,
    required this.observations,
    required this.inspectionId,
    this.synced = 0,
  });

  factory InternationalArrival.fromJson(Map<String, dynamic> json) {
    return InternationalArrival(
      general: GeneralData.fromJson(json),
      publicHall: PublicHallData.fromJson(json),
      //baggageTime: BaggageTimeData.fromJson(json['baggage_time'] ?? {}),
      baggageArea: BaggageAreaData.fromJson(json),
      migration: MigrationData.fromJson(json),
      customs: CustomsData.fromJson(json),
      observations: ObservationsData.fromJson(json),
      inspectionId: json['inspection_id'] ?? 0,
      synced: json['synced'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...general.toJson(),
      ...publicHall.toJson(),
      //'baggage_time': baggageTime.toJson(),
      ...baggageArea.toJson(),
      ...migration.toJson(),
      ...customs.toJson(),
      ...observations.toJson(),
      'inspection_id': inspectionId,
      'synced': synced,
      'id': id,
    };
  }

  @override
  InternationalArrival copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    print('🛠 Modificando $field = $value');
    print('🧾 JSON modificado: $json');
    return InternationalArrival.fromJson(json);
  }
}
