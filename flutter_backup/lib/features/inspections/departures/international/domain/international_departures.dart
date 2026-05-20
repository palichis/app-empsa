import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_time_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_option.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_time_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/self_checkin_kiosks_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration_area.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration_time.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/observations_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';

class InternationalDepartures implements InspectionDetails {
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
  final MigrationData migration;
  /*final MigrationAreaData migrationAreaNational;
  final MigrationTimeData migrationTimeNational;
  final MigrationAreaData migrationAreaInternational;
  final MigrationTimeData migrationTimeInternational;*/
  @override
  final ObservationsData observations;

  InternationalDepartures({
    this.id,
    required this.inspectionId,
    required this.synced,
    required this.general,
    required this.publicHall,
    required this.flight,
    required this.selfCheckinKiosks,
    required this.checkinCounterArea,
    required this.checkinCounterTime,
    required this.securityFiltersArea,
    required this.securityFiltersTime,
    required this.migration,
    required this.observations,
  });

  factory InternationalDepartures.fromJson(Map<String, dynamic> json) {
    return InternationalDepartures(
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
      /*migration: MigrationData(
          areaNational: MigrationAreaData.fromJson(json, 'national'),
          areaInternational: MigrationAreaData.fromJson(json, 'international'),
          timeNational: MigrationTimeData.fromJson(json, 'national'),
          timeInternational: MigrationTimeData.fromJson(json, 'international')),*/
      migration: MigrationData.fromJson(json),
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
      ...migration.toJson(),
      /*
      ...migrationAreaNational.toJson(),
      ...migrationTimeNational.toJson(),
      ...migrationAreaInternational.toJson(),
      ...migrationTimeInternational.toJson(),
      */
      ...observations.toJson(),
    };
  }

  @override
  int? get inspectionDetailId => id;

  @override
  InternationalDepartures copyWithField(String key, dynamic value) {
    final map = toJson();
    map[key] = value;
    return InternationalDepartures.fromJson(map);
  }
}
