import 'dart:convert';
import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/data/international_arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/data/national_arrivals_repository.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/data/baggage_repository.dart';
import 'package:epmsa_mobile/features/inspections/cargo/data/cargo_repository.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/checkins_counter_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/departures_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_check_counter_number_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_options_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/preboarding_repository.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_assigned_counters.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/shared/data/public_halls_repository.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/services.dart' show rootBundle;

class InspectionsRepository {
  final SqliteHandler _dbHandler;

  InspectionsRepository(this._dbHandler);

  Future<Inspection?> getInspectionbyId(int inspectionId) async {
    final db = await _dbHandler.database;

    // 1. Cargar cabecera
    final res = await db.query(
      'epmsatca_inspections',
      where: 'id = ?',
      whereArgs: [inspectionId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    final inspection = Inspection.fromJson(res.first);
    return inspection;
  }

  Future<Map<String, dynamic>> buildNationalArrivalInspectionJson(
    Inspection inspection,
  ) async {
    final repo = NationalArrivalsRepository(_dbHandler);
    final arrival = await repo.getArrivalByInspection(inspection.id!);
    if (arrival == null) throw Exception("Arrival no encontrado");

    final publicHallOptions = await PublicHallOptionRepository(_dbHandler)
        .getPublicHallsDetails(inspection.id!);
    final baggageArea = arrival.baggageArea;

    final baggageTime = await BaggageRepository(_dbHandler)
        .getNationalArrivalBaggageDetails(arrival.id!);

    return {
      "id": inspection.id,
      "name": inspection.name,
      "date": inspection.date?.toIso8601String(),
      "start_time": inspection.startTime?.toIso8601String(),
      "end_time": inspection.endTime?.toIso8601String(),
      "employee": inspection.employee.toJson(),
      "supervisors": inspection.supervisors.map((s) => s.toJson()).toList(),
      "operation": inspection.operation,
      "type": inspection.type,
      "state": inspection.state,
      "date_str": inspection.dateStr,
      "planned": inspection.planned,
      "executed": inspection.executed,
      "detail": {
        "id": arrival.id,
        "measurement_date": arrival.general.measurementDate?.toIso8601String(),
        "peak_hour": arrival.general.peakHour,
        "flight_count": arrival.general.flightCount,
        //"prepared_by": {arrival.general.preparedBy},
        "prepared_by": {
          "id": arrival.general.preparedById,
          "name": arrival.general.preparedBy
        },
        'public_hall_id': publicHallOptions.map((e) => e.toJson()).toList(),
        "public_hall_time": arrival.publicHall.time,
        "public_hall_pax_waiting_area": arrival.publicHall.paxWaiting,
        "used_belts_123": baggageArea.belts,
        "used_belts_456": baggageArea.belts,
        "notes_belts": baggageArea.notes_belts,
        "baggage_claim_time_1": baggageArea.time1,
        "baggage_claim_pax_waiting_area_1": baggageArea.pax1,
        "baggage_claim_time_2": baggageArea.time2,
        "baggage_claim_pax_waiting_area_2": baggageArea.pax2,
        "baggage_claim_time_3": baggageArea.time3,
        "baggage_claim_pax_waiting_area_3": baggageArea.pax3,
        "observations_event_time": arrival.observations.eventTime,
        "observations_location": arrival.observations.location,
        "observations_description": arrival.observations.description,
        "observations_consequence": arrival.observations.consequence,
        "baggage_claim_lines": baggageTime.map((e) => e.toJson()).toList(),
      },
    };
  }

  Future<Map<String, dynamic>> buildInternationalArrivalInspectionJson(
    Inspection inspection,
  ) async {
    final repo = InternationalArrivalRepository(_dbHandler);
    final arrival = await repo.getArrivalByInspection(inspection.id!);
    if (arrival == null) throw Exception("Arrival no encontrado");
    final publicHallOptions = await PublicHallOptionRepository(_dbHandler)
        .getPublicHallsDetails(inspection.id!);
    final baggageArea = arrival.baggageArea;

    final baggageTime = await BaggageRepository(_dbHandler)
        .getInternationalArrivalBaggageDetails(arrival.id!);

    List<Map<String, dynamic>> migrationOptions = [
      {
        "id": 60,
        "name": "Migración (Con apoyo salas Bravo)",
        "selected": false
      },
      {
        "id": 33,
        "name": "Migración (Sin apoyo salas Bravo)",
        "selected": false
      },
    ];
    for (var opt in migrationOptions) {
      opt["selected"] = (opt["id"] == arrival.migration.migrationId);
    }

    return {
      "id": inspection.id,
      "name": inspection.name,
      "date": inspection.date?.toIso8601String(),
      "start_time": inspection.startTime?.toIso8601String(),
      "end_time": inspection.endTime?.toIso8601String(),
      "employee": inspection.employee.toJson(),
      "supervisors": inspection.supervisors.map((s) => s.toJson()).toList(),
      "operation": inspection.operation,
      "type": inspection.type,
      "state": inspection.state,
      "date_str": inspection.dateStr,
      "planned": inspection.planned,
      "executed": inspection.executed,
      "detail": {
        "id": arrival.id,
        "measurement_date": arrival.general.measurementDate?.toIso8601String(),
        "peak_hour": arrival.general.peakHour,
        "flight_count": arrival.general.flightCount,
        //"prepared_by": {arrival.general.preparedBy},
        "prepared_by": {
          "id": arrival.general.preparedById,
          "name": arrival.general.preparedBy
        },
        'public_hall_id': publicHallOptions.map((e) => e.toJson()).toList(),
        "public_hall_time": arrival.publicHall.time,
        "public_hall_pax_waiting_area": arrival.publicHall.paxWaiting,
        "used_belts_123": baggageArea.belts,
        "used_belts_456": baggageArea.belts,
        "notes_belts": baggageArea.notes_belts,
        "baggage_claim_time_1": baggageArea.time1,
        "baggage_claim_pax_waiting_area_1": baggageArea.pax1,
        "baggage_claim_time_2": baggageArea.time2,
        "baggage_claim_pax_waiting_area_2": baggageArea.pax2,
        "baggage_claim_time_3": baggageArea.time3,
        "baggage_claim_pax_waiting_area_3": baggageArea.pax3,

        "migration_id": migrationOptions
            .map((opt) => {
                  "id": opt["id"],
                  "name": opt["name"],
                  "selected": opt["selected"],
                })
            .toList(),

        "migration_area_time": arrival.migration.hour,

        // Migración – Nacional (área)
        "migration_area_national_working_counters":
            arrival.migration.areaNational.counters,
        "migration_area_national_pax_waiting_area":
            arrival.migration.areaNational.paxArea,
        "migration_area_national_offline_time":
            arrival.migration.areaNational.offlineTime,

        // Migración – Internacional (área)
        "migration_area_international_working_counters":
            arrival.migration.areaInternational.counters,
        "migration_area_international_pax_waiting_area":
            arrival.migration.areaInternational.paxArea,
        "migration_area_national_waiting_area_occupancy":
            arrival.migration.areaInternational.occupancy,
        "migration_area_international_offline_time":
            arrival.migration.areaInternational.offlineTime,
        "migration_area_international_waiting_area_occupancy":
            arrival.migration.areaInternational.occupancy,

        // Migración – Tiempo
        // Tiempo de atención por pax – Nacional
        "migration_time_national_attention_time_per_pax_1":
            arrival.migration.timeNational.paxAttentionMed1,
        "migration_time_national_attention_time_per_pax_2":
            arrival.migration.timeNational.paxAttentionMed2,
        "migration_time_national_attention_time_per_pax_3":
            arrival.migration.timeNational.paxAttentionMed3,
        /* "attention_time_per_pax_avg_national":
            arrival.migration.timeNational.average,*/
        "migration_time_national_attention_time_per_pax_max":
            arrival.migration.timeNational.maxWaitingTime,

        // Tiempo de atención por pax – Internacional
        "migration_time_international_pax_waiting_time_1":
            arrival.migration.timeInternational.paxAttentionMed1,
        "migration_time_international_pax_waiting_time_2":
            arrival.migration.timeInternational.paxAttentionMed2,
        "migration_time_international_pax_waiting_time_3":
            arrival.migration.timeInternational.paxAttentionMed3,
        /*"attention_time_per_pax_avg_international":
            arrival.migration.timeInternational.average,*/
        "migration_time_international_pax_waiting_time_max":
            arrival.migration.timeInternational.maxWaitingTime,

        /*"migration_nds_area": arrival.migration.ndsArea,
        "migration_nds_time": arrival.migration.ndsTime,*/

        // Aduana (Customs)
        "customs_time": arrival.customs.time,
        "customs_maq_rx_oper": arrival.customs.rxMachineOperating,
        "customs_kiosko_pass": arrival.customs.passportScannerKiosks,
        "customs_pax_waiting_area": arrival.customs.paxWaitingArea,
        "customs_area_occupancy": arrival.customs.occupancyArea,
        "customs_offline_time": arrival.customs.offlineTime,
        "customs_waiting_time_max": arrival.customs.maxWaitingTime,
        /*"customs_nds_area": arrival.customs.ndsArea,
        "customs_nds_time": arrival.customs.ndsTime,*/

        "observations_event_time": arrival.observations.eventTime,
        "observations_location": arrival.observations.location,
        "observations_description": arrival.observations.description,
        "observations_consequence": arrival.observations.consequence,
        "baggage_claim_lines": baggageTime.map((e) => e.toJson()).toList(),
      },
    };
  }

  Future<Map<String, dynamic>> buildInternationalDepartureInspectionJson(
    Inspection inspection,
  ) async {
    final repo = DeparturesRepository(_dbHandler);
    final departure =
        await repo.getInternationalDepartureByInspection(inspection.id!);
    if (departure == null) throw Exception("Departure no encontrado");

    final publicHallOptions = await PublicHallOptionRepository(_dbHandler)
        .getPublicHallsDetails(inspection.id!);

    final flightOptions = await FlightOptionsRepository(_dbHandler)
        .getInternationalFlightOptionsDetails(departure.id!);

    final flightCheckCounterNumber =
        await FlightCheckCounterNumberRepository(_dbHandler)
            .getFlightCheckCounterNumberDetails(
                departureId: departure.id!, isNational: false);

    final flightPreboardingRoom =
        await FlightPreboardingRoomRepository(_dbHandler)
            .getPreboardingRoomDetails(
                departureId: departure.id!, isNational: false);
    /*
    final selectedFlightCheckCounterNumber =
        await repo.getSelectedCounterId.getInternationalFlightCheckCounterNumberDetails(departure.id!,false);
            */

    final preboarding = await PreboardingRepository(_dbHandler)
        .getInternationalPreboardingDetails(departure.id!);

    final checkinAssignedCounterNumber =
        await CheckinCounterRepository(_dbHandler).getCounterNumberDetails(
            departureId: departure.id!, isNational: true);

    // Atajos a las secciones del modelo
    final general = departure.general;
    final publicHall = departure.publicHall;
    final kiosks = departure.selfCheckinKiosks;
    final countersArea = departure.checkinCounterArea;
    final countersTime = departure.checkinCounterTime;
    final securityArea = departure.securityFiltersArea;
    final securityTime = departure.securityFiltersTime;
    final flightDetail = departure.flight;
    //final preboarding = departure.;
    final migration = departure.migration;
    final observations = departure.observations;

    return {
      "id": inspection.id,
      "name": inspection.name,
      "date": inspection.date?.toIso8601String(),
      "start_time": inspection.startTime?.toIso8601String(),
      "end_time": inspection.endTime?.toIso8601String(),
      "employee": inspection.employee.toJson(),
      "supervisors": inspection.supervisors.map((s) => s.toJson()).toList(),
      "operation": inspection.operation,
      "type": inspection.type,
      "state": inspection.state,
      "date_str": inspection.dateStr,
      "planned": inspection.planned,
      "executed": inspection.executed,
      "detail": {
        'id': departure.id,
        'name': inspection.name,
        'measurement_date': general.measurementDate?.toIso8601String(),
        'peak_hour': general.peakHour,
        'prepared_by': {
          'id': general.preparedById,
          'name': general.preparedBy,
        },
        'flight_count': general.flightCount,
        'flight_pax_number': flightDetail.flightPaxNumber,
        'flight_number': flightOptions.map((e) => e.toJson()).toList(),
        'flight_check_counter_number':
            flightCheckCounterNumber.map((e) => e.toJson()).toList(),
        'flight_preboarding_room':
            flightPreboardingRoom.map((e) => e.toJson()).toList(),
        'flight_scheduled_time': flightDetail.flightScheduledTime,
        'flight_actual_departure_time': flightDetail.flightActualDepartureTime,
        'public_hall_id': publicHallOptions.map((e) => e.toJson()).toList(),
        'public_hall_time': publicHall.time,
        'public_hall_pax_waiting_area': publicHall.paxWaiting,
        'self_checkin_kiosks_time': kiosks.selfCheckinKiosksTime,
        'self_checkin_kiosks_service_time_per_pax_1':
            kiosks.selfCheckinKiosksServiceTimePerPax1,
        'self_checkin_kiosks_service_time_per_pax_2':
            kiosks.selfCheckinKiosksServiceTimePerPax2,
        'self_checkin_kiosks_maximum_waiting_time':
            kiosks.selfCheckinKiosksMaximumWaitingTime,
        'checkin_counter_time': countersArea.checkinCounterTime,
        'checkin_counter_assigned_counters_zone':
            checkinAssignedCounterNumber.map((e) => e.toJson()).toList(),
        'checkin_counter_assigned_counters':
            countersArea.checkinCounterAssignedCounters,
        'checkin_counter_operating_counters':
            countersArea.checkinCounterOperatingCounters,
        'checkin_counter_pax_waiting_area':
            countersArea.checkinCounterPaxWaitingArea,
        'checkin_counter_offline_time': countersArea.checkinCounterOfflineTime,
        'checkin_counter_attention_time_per_pax_1':
            countersTime.checkinCounterAttentionTimePerPax1,
        'checkin_counter_attention_time_per_pax_2':
            countersTime.checkinCounterAttentionTimePerPax2,
        'checkin_counter_attention_time_per_pax_3':
            countersTime.checkinCounterAttentionTimePerPax3,
        'checkin_counter_attention_time_per_pax_4':
            countersTime.checkinCounterAttentionTimePerPax4,
        'checkin_counter_attention_time_per_pax_5':
            countersTime.checkinCounterAttentionTimePerPax5,
        'checkin_counter_attention_time_per_pax_max':
            countersTime.checkinCounterAttentionTimePerPaxMax,
        'security_filters_time': securityArea.securityFiltersTime,
        'security_filters_observed_domestic_operators':
            securityArea.securityFiltersObservedDomesticOperators,
        'security_filters_observed_international_operators':
            securityArea.securityFiltersObservedInternationalOperators,
        'security_filters_observed_document_review_agents':
            securityArea.securityFiltersObservedDocumentReviewAgents,
        'security_filters_pax_waiting_area':
            securityArea.securityFiltersPaxWaitingArea,
        'security_filters_offline_time':
            securityArea.securityFiltersOfflineTime,
        'security_filters_attention_time_per_pax_1':
            securityTime.securityFiltersAttentionTimePerPax1,
        'security_filters_attention_time_per_pax_2':
            securityTime.securityFiltersAttentionTimePerPax2,
        'security_filters_attention_time_per_pax_3':
            securityTime.securityFiltersAttentionTimePerPax3,
        'security_filters_attention_time_per_pax_4':
            securityTime.securityFiltersAttentionTimePerPax4,
        'security_filters_attention_time_per_pax_5':
            securityTime.securityFiltersAttentionTimePerPax5,
        //'preboarding_time': preboarding.time,
        'observations_event_time': observations.eventTime,
        'observations_location': observations.location,
        'observations_description': observations.description,
        'observations_consequence': observations.consequence,
        'preboarding_line_ids': preboarding.map((e) => e.toJson()).toList(),
        'migration_area_time': migration.hour,
        'migration_area_national_working_counters':
            migration.areaNational.counters,
        'migration_area_national_pax_waiting_area':
            migration.areaNational.paxArea,
        'migration_area_national_waiting_area_occupancy':
            migration.areaInternational.occupancy,
        'migration_area_national_offline_time':
            migration.areaNational.offlineTime,
        'migration_area_international_working_counters':
            migration.areaInternational.counters,
        'migration_area_international_pax_waiting_area':
            migration.areaInternational.paxArea,
        'migration_area_international_waiting_area_occupancy':
            migration.areaInternational.occupancy,
        'migration_area_international_offline_time':
            migration.areaInternational.offlineTime,
        'migration_time_national_attention_time_per_pax_1':
            migration.timeNational.paxAttentionMed1,
        'migration_time_national_attention_time_per_pax_2':
            migration.timeNational.paxAttentionMed2,
        'migration_time_national_attention_time_per_pax_3':
            migration.timeNational.paxAttentionMed3,
        'migration_time_national_attention_time_per_pax_max':
            migration.timeNational.maxWaitingTime,
        'migration_time_international_pax_waiting_time_1':
            migration.timeInternational.paxAttentionMed1,
        'migration_time_international_pax_waiting_time_2':
            migration.timeInternational.paxAttentionMed2,
        'migration_time_international_pax_waiting_time_3':
            migration.timeInternational.paxAttentionMed3,
        'migration_time_international_pax_waiting_time_max':
            migration.timeInternational.maxWaitingTime,
      }
    };
  }

  Future<Map<String, dynamic>> buildNationalDepartureInspectionJson(
    Inspection inspection,
  ) async {
    final repo = DeparturesRepository(_dbHandler);
    final departure =
        await repo.getNationalDepartureByInspection(inspection.id!);
    if (departure == null) throw Exception("Departure no encontrado");
    final publicHallOptions = await PublicHallOptionRepository(_dbHandler)
        .getPublicHallsDetails(inspection.id!);

    final flightOptions = await FlightOptionsRepository(_dbHandler)
        .getNationalFlightOptionsDetails(departure.id!);

    final flightCheckCounterNumber =
        await FlightCheckCounterNumberRepository(_dbHandler)
            .getFlightCheckCounterNumberDetails(
                departureId: departure.id!, isNational: true);

    final flightPreboardingRoom =
        await FlightPreboardingRoomRepository(_dbHandler)
            .getPreboardingRoomDetails(
                departureId: departure.id!, isNational: true);

    final preboarding = await PreboardingRepository(_dbHandler)
        .getNationalPreboardingDetails(departure.id!);

    final checkinAssignedCounterNumber =
        await CheckinCounterRepository(_dbHandler).getCounterNumberDetails(
            departureId: departure.id!, isNational: true);

    // Secciones
    final general = departure.general;
    final publicHall = departure.publicHall;
    final kiosks = departure.selfCheckinKiosks;
    final countersArea = departure.checkinCounterArea;
    final countersTime = departure.checkinCounterTime;
    final securityArea = departure.securityFiltersArea;
    final securityTime = departure.securityFiltersTime;
    final flightDetail = departure.flight;
    //final preboarding = departure.;
    //final migration = departure;
    final observations = departure.observations;

    return {
      "id": inspection.id,
      "name": inspection.name,
      "date": inspection.date?.toIso8601String(),
      "start_time": inspection.startTime?.toIso8601String(),
      "end_time": inspection.endTime?.toIso8601String(),
      "employee": inspection.employee.toJson(),
      "supervisors": inspection.supervisors.map((s) => s.toJson()).toList(),
      "operation": inspection.operation,
      "type": inspection.type,
      "state": inspection.state,
      "date_str": inspection.dateStr,
      "planned": inspection.planned,
      "executed": inspection.executed,
      "detail": {
        "id": departure.id,
        'name': inspection.name,
        'measurement_date': general.measurementDate?.toIso8601String(),
        'peak_hour': general.peakHour,
        'prepared_by': {
          'id': general.preparedById,
          'name': general.preparedBy,
        },
        'flight_count': general.flightCount,
        'flight_pax_number': flightDetail.flightPaxNumber,
        'flight_number': flightOptions.map((e) => e.toJson()).toList(),
        'flight_check_counter_number':
            flightCheckCounterNumber.map((e) => e.toJson()).toList(),
        'flight_preboarding_room':
            flightPreboardingRoom.map((e) => e.toJson()).toList(),
        'flight_scheduled_time': flightDetail.flightScheduledTime,
        'flight_actual_departure_time': flightDetail.flightActualDepartureTime,
        'public_hall_id': publicHallOptions.map((e) => e.toJson()).toList(),
        'public_hall_time': publicHall.time,
        'public_hall_pax_waiting_area': publicHall.paxWaiting,
        'self_checkin_kiosks_time': kiosks.selfCheckinKiosksTime,
        'self_checkin_kiosks_service_time_per_pax_1':
            kiosks.selfCheckinKiosksServiceTimePerPax1,
        'self_checkin_kiosks_service_time_per_pax_2':
            kiosks.selfCheckinKiosksServiceTimePerPax2,
        'self_checkin_kiosks_maximum_waiting_time':
            kiosks.selfCheckinKiosksMaximumWaitingTime,
        'checkin_counter_time': countersArea.checkinCounterTime,
        'checkin_counter_assigned_counters_zone':
            checkinAssignedCounterNumber.map((e) => e.toJson()).toList(),
        'checkin_counter_assigned_counters':
            countersArea.checkinCounterAssignedCounters,
        'checkin_counter_operating_counters':
            countersArea.checkinCounterOperatingCounters,
        'checkin_counter_pax_waiting_area':
            countersArea.checkinCounterPaxWaitingArea,
        'checkin_counter_offline_time': countersArea.checkinCounterOfflineTime,
        'checkin_counter_attention_time_per_pax_1':
            countersTime.checkinCounterAttentionTimePerPax1,
        'checkin_counter_attention_time_per_pax_2':
            countersTime.checkinCounterAttentionTimePerPax2,
        'checkin_counter_attention_time_per_pax_3':
            countersTime.checkinCounterAttentionTimePerPax3,
        'checkin_counter_attention_time_per_pax_4':
            countersTime.checkinCounterAttentionTimePerPax4,
        'checkin_counter_attention_time_per_pax_5':
            countersTime.checkinCounterAttentionTimePerPax5,
        'checkin_counter_attention_time_per_pax_max':
            countersTime.checkinCounterAttentionTimePerPaxMax,
        'security_filters_time': securityArea.securityFiltersTime,
        'security_filters_observed_domestic_operators':
            securityArea.securityFiltersObservedDomesticOperators,
        'security_filters_observed_international_operators':
            securityArea.securityFiltersObservedInternationalOperators,
        'security_filters_observed_document_review_agents':
            securityArea.securityFiltersObservedDocumentReviewAgents,
        'security_filters_pax_waiting_area':
            securityArea.securityFiltersPaxWaitingArea,
        'security_filters_offline_time':
            securityArea.securityFiltersOfflineTime,
        'security_filters_attention_time_per_pax_1':
            securityTime.securityFiltersAttentionTimePerPax1,
        'security_filters_attention_time_per_pax_2':
            securityTime.securityFiltersAttentionTimePerPax2,
        'security_filters_attention_time_per_pax_3':
            securityTime.securityFiltersAttentionTimePerPax3,
        'security_filters_attention_time_per_pax_4':
            securityTime.securityFiltersAttentionTimePerPax4,
        'security_filters_attention_time_per_pax_5':
            securityTime.securityFiltersAttentionTimePerPax5,
        //'preboarding_time': preboarding.time,
        'observations_event_time': observations.eventTime,
        'observations_location': observations.location,
        'observations_description': observations.description,
        'observations_consequence': observations.consequence,
        'preboarding_line_ids': preboarding.map((e) => e.toJson()).toList(),
      }
    };
  }

  Future<Map<String, dynamic>> buildCargoInspectionJson(
    Inspection inspection,
  ) async {
    final repo = CargoRepository(_dbHandler);

    // General (cargo_detail)
    final cargo = await repo.getCargoByInspectionId(inspection.id!);
    if (cargo == null) throw Exception("Cargo no encontrado");

    // LANDSIDE: agrupar por parent
    final landsideList =
        (await repo.getLandsideEntriesForCargo(cargo.id!)) ?? <LandsideEntry>[];
    final Map<String, List<Map<String, dynamic>>> landsideGrouped = {};
    for (final e in landsideList) {
      final parent = e.parent ?? '';
      (landsideGrouped[parent] ??= []).add(_lineFromLandside(e));
    }

    // AIRSIDE: listas por tipo
    final airsideList =
        (await repo.getAirsideEntriesForCargo(cargo.id!)) ?? <AirsideEntry>[];
    final airside = Airside.fromEntries(airsideList);

    // Helpers
    String? _iso(DateTime? d) => d?.toIso8601String();

    return <String, dynamic>{
      "id": inspection.id,
      "name": inspection.name,
      "date": _iso(inspection.date), // ISO completo (como otros)
      "start_time": _iso(inspection.startTime),
      "end_time": _iso(inspection.endTime),
      "operation": inspection.operation ?? "none",
      "type": inspection.type ?? "none", // <- antes era "type_"
      "state": inspection.state ?? "pending",
      "date_str": inspection.dateStr, // si lo usas en backend, ok
      "planned": inspection.planned == true,
      "executed": inspection.executed == true,
      "flight_type": "cargo",
      "employee": inspection.employee.toJson(), // igual que otros builders
      "supervisors": inspection.supervisors.map((s) => s.toJson()).toList(),

      "detail": {
        "id": cargo.id!,
        "name": null,

        "measurement_date": _iso(cargo.general.measurementDate),

        "hour": cargo.general.hour,
        "prepared_by": {
          "id": cargo.general.preparedById ?? 0,
          "name": cargo.general.preparedBy,
        },

        // Horas
        "earthside_national_hour": cargo.earthsideNationalHour,
        "earthside_international_hour": cargo.earthsideInternationalHour,
        "earthside_international_building_hour":
            cargo.earthsideInternationalBuildingHour,
        "airside_national_international_hour":
            cargo.airsideNationalInternationalHour,

        // LANDSIDE
        "earthside_national_quality":
            landsideGrouped["earthside_national_quality"] ?? [],
        "earthside_national_security":
            landsideGrouped["earthside_national_security"] ?? [],
        "earthside_national_environment":
            landsideGrouped["earthside_national_environment"] ?? [],
        "earthside_international_quality":
            landsideGrouped["earthside_international_quality"] ?? [],
        "earthside_international_security":
            landsideGrouped["earthside_international_security"] ?? [],
        "earthside_international_environment":
            landsideGrouped["earthside_international_environment"] ?? [],
        "earthside_international_building_quality":
            landsideGrouped["earthside_international_building_quality"] ?? [],
        "earthside_international_building_security":
            landsideGrouped["earthside_international_building_security"] ?? [],
        "earthside_international_building_environment":
            landsideGrouped["earthside_international_building_environment"] ??
                [],

        // AIRSIDE
        "airside_national_international_quality":
            airside.quality.map(_lineFromAirside).toList(),
        "airside_national_international_security":
            airside.security.map(_lineFromAirside).toList(),
        "airside_national_international_environment":
            airside.environment.map(_lineFromAirside).toList(),
      }
    };
  }

// Helpers
  Map<String, dynamic> _lineFromLandside(LandsideEntry e) => {
        "id": e.id,
        "sequence": e.sequence ?? 0,
        "name": e.name,
        "qualification": e.qualification,
        "note": e.note,
        "max_value": _asDouble(e.maxValue),
        "control_value": _asDouble(e.controlValue),
        "percentage": _asInt(e.percentage),
        //"photo": _asBool(e.photo),
      };

  Map<String, dynamic> _lineFromAirside(AirsideEntry e) => {
        "id": e.id,
        "sequence": e.sequence ?? 0,
        "name": e.name,
        "qualification": e.qualification,
        "note": e.note,
        "max_value": _asDouble(e.maxValue),
        "control_value": _asDouble(e.controlValue),
        "percentage": _asInt(e.percentage),
        //"photo": _asBool(e.photo),
      };

  double _asDouble(dynamic v) => v == null
      ? 0.0
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
  int _asInt(dynamic v) => v == null
      ? 0
      : (v is int
          ? v
          : (v is double ? v.round() : int.tryParse(v.toString()) ?? 0));

  Map<String, dynamic> _mapLine(Map<String, dynamic> row) {
    return {
      "id": row['id'],
      "sequence": row['sequence'] ?? 0,
      "name": row['name'],
      "qualification": row['qualification'],
      "note": row['note'],
      "max_value": _asDouble(row['max_value']),
      "control_value": _asDouble(row['control_value']),
      "percentage": _asInt(row['percentage']),
      //"photo": _asBool(row['photo']),
    };
  }

/*
  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }*/

  Future<List<InspectionPhoto>> getPhotosByInspection(int inspectionId) async {
    final db = await _dbHandler.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'epmsatca_inspection_photos',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
    return List.generate(maps.length, (i) => InspectionPhoto.fromJson(maps[i]));
  }

  Future<int> deletePhotosByInspection(int inspectionId) async {
    final db = await _dbHandler.database;
    return await db.delete(
      'epmsatca_inspection_photos',
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
    );
  }
}
