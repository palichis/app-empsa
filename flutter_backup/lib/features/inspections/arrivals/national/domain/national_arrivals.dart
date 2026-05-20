import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/observations_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';

import '../../../shared/domain/baggage_area_data.dart';

class NationalArrival implements InspectionDetails {
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
  final BaggageAreaData baggageArea;
  @override
  final ObservationsData observations;

  NationalArrival({
    this.id,
    required this.general,
    required this.publicHall,
    required this.baggageArea,
    required this.observations,
    required this.inspectionId,
    this.synced = 0,
  });

  factory NationalArrival.fromJson(Map<String, dynamic> json) {
    return NationalArrival(
      general: GeneralData.fromJson(json),
      publicHall: PublicHallData.fromJson(json),
      baggageArea: BaggageAreaData.fromJson(json),
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
      ...baggageArea.toJson(),
      ...observations.toJson(),
      'inspection_id': inspectionId,
      'synced': synced,
      'id': id,
    };
  }

  @override
  NationalArrival copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return NationalArrival.fromJson(json);
  }
}
