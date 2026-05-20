import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_time_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_time_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/self_checkin_kiosks_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/observations_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';

class NationalDepartures implements InspectionDetails {
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
  final FlightData flight;
  final SelfCheckinKiosksData selfCheckinKiosks;
  final CheckinCounterAreaData checkinCounterArea;
  final CheckinCounterTimeData checkinCounterTime;
  final SecurityFiltersAreaData securityFiltersArea;
  final SecurityFiltersTimeData securityFiltersTime;
  @override
  final ObservationsData observations;

  NationalDepartures({
    this.id,
    required this.general,
    required this.publicHall,
    required this.flight,
    required this.selfCheckinKiosks,
    required this.checkinCounterArea,
    required this.checkinCounterTime,
    required this.securityFiltersArea,
    required this.securityFiltersTime,
    required this.observations,
    required this.inspectionId,
    this.synced = 0,
  });

  factory NationalDepartures.fromJson(Map<String, dynamic> json) {
    return NationalDepartures(
      id: json['id'],
      inspectionId: json['inspection_id'],
      synced: json['synced'],
      general: GeneralData.fromJson(json),
      publicHall: PublicHallData.fromJson(json),
      flight: FlightData.fromJson(json),
      selfCheckinKiosks: SelfCheckinKiosksData.fromJson(json),
      checkinCounterArea: CheckinCounterAreaData.fromJson(json),
      checkinCounterTime: CheckinCounterTimeData.fromJson(json),
      securityFiltersArea: SecurityFiltersAreaData.fromJson(json),
      securityFiltersTime: SecurityFiltersTimeData.fromJson(json),
      observations: ObservationsData.fromJson(json),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'synced': synced,
      ...general.toJson(),
      ...publicHall.toJson(),
      ...flight.toJson(),
      ...selfCheckinKiosks.toJson(),
      ...checkinCounterArea.toJson(),
      ...checkinCounterTime.toJson(),
      ...securityFiltersArea.toJson(),
      ...securityFiltersTime.toJson(),
      ...observations.toJson(),
    };
  }

  @override
  NationalDepartures copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return NationalDepartures.fromJson(json);
  }
}
