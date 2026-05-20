import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:epmsa_mobile/core/services/api_service.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/international_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/providers/cargo_provider.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_assigned_counters.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_check_counter_number.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_option.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/preboarding_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/domain/international_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/providers/depatures_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/domain/national_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_options.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/data/inspections_repository.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

enum InspectionType {
  nationalArrival,
  internationalArrival,
  nationalDeparture,
  internationalDeparture,
  cargo
}

class InspectionsService {
  final InspectionsRepository _inspectionRepository;
  final Map<String, dynamic> session;

  InspectionsService(this._inspectionRepository, this.session);

  InspectionType getInspectionTypeFromInspection(Inspection inspection) {
    if (inspection.operation == 'departure' && inspection.type == 'D') {
      return InspectionType.nationalDeparture;
    }
    if (inspection.operation == 'departure' && inspection.type == 'I') {
      return InspectionType.internationalDeparture;
    }
    if (inspection.operation == 'arrival' && inspection.type == 'D') {
      return InspectionType.nationalArrival;
    }
    if (inspection.operation == 'arrival' && inspection.type == 'I') {
      return InspectionType.internationalArrival;
    }
    if (inspection.operation == 'none' &&
        inspection.type == 'none' &&
        inspection.flightType == 'cargo') {
      return InspectionType.cargo;
    }
    throw UnsupportedError('Tipo de inspección no reconocido');
  }

  Future<List<Inspection>> fetchAssignedInspections(Ref ref) async {
    final String? sid = session['session_id'] ?? null;
    final int uid = session['uid'] ?? 0;

    if (sid == null) throw Exception('No hay sesión guardada');

    /*if (sessionId == null) {
      throw Exception("❌ Error al obtener inspecciones");
    }*/
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/get-controls");
    final today = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(today);

    String responseBody='';
    final service = ref.read(nationalArrivalServiceProvider);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "session_id=$sid",
        },
        body: jsonEncode({
          "domain": [
            ["date", "=", formattedDate],
            ["employee_id.user_id", "=", uid]
          ]
        }),
      );
      responseBody = response.body;
      await service.saveAll(responseBody);
    }catch(e){
        responseBody = await service.getAllArrivals();
    }


    final decoded = json.decode(responseBody);

    print("Response from API: ${decoded}");

    final List<dynamic> jsonList = decoded['result'];
    //['data'];
    final inspections = <Inspection>[];

    for (final item in jsonList) {
      final inspection = Inspection.fromJson(item);
      inspections.add(inspection);

      final operation = item['operation'];
      final type = item['type'] ?? item['type_'];
      final detail = item['detail'];
      final flightType = item['flight_type'];

      if (operation == 'arrival' && type == 'D' && detail != null) {
   //     await preloadNationalArrival(item, ref);
      }
      if (operation == 'arrival' && type == 'I' && detail != null) {
     //   await preloadInternationalArrival(item, ref);
      }
      if (operation == 'departure' && type == 'I' && detail != null) {
        print("PRE-LOADING INTERNATIONAL DEPARTURE");
     //   await preloadInternationalDeparture(item, ref);
      }
      if (operation == 'departure' && type == 'D' && detail != null) {
        print("PRE-LOADING NATIONAL DEPARTURE");
       // await preloadNationalDeparture(item, ref);
      }
      if (operation == 'none' && type == 'none' && flightType == 'cargo') {
        print("PRE-LOADING CARGO");
     //   await preloadCargo(item, ref);
      }
    }

    return inspections;
  }

  Future<void> preloadNationalArrival(
      Map<String, dynamic> inspectionJson, Ref ref) async {
    final String operation = inspectionJson['operation'];
    final String type = inspectionJson['type'] ?? inspectionJson['type_'];

    // Verifica si es arribo nacional
    if (operation == 'arrival' && type == 'D') {
      final detail = inspectionJson['detail'];
      if (detail == null) return;

      final int inspectionId = inspectionJson['id'];

      final enrichedDetail = {
        'id': detail['id'],
        'general_data_measurement_date': detail['measurement_date'],
        'general_data_peak_hour': detail['peak_hour'],
        'general_data_flight_count': detail['flight_count'],
        //'general_data_prepared_by': detail['prepared_by'][1],
        'general_data_prepared_by': detail['prepared_by']?['name'],
        'general_data_prepared_by_id': detail['prepared_by']?['id'],
        'general_data_reviewed_by': '',
        'public_hall_time': detail['public_hall_time'],
        'public_hall_pax_waiting_area': detail['public_hall_pax_waiting_area'],
        'baggage_claim_belts': ([
          ...((detail['used_belts_123'] as List?) ?? const []),
          ...((detail['used_belts_456'] as List?) ?? const []),
        ]).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).join(','),
        'notes_belts': detail['notes_belts'],
        'baggage_area_used_belts_area': detail['used_belts_area'],
        'baggage_claim_time_1': detail['baggage_claim_time_1'],
        'baggage_claim_pax_waiting_area_1':
            detail['baggage_claim_pax_waiting_area_1'],
        'baggage_claim_time_2': detail['baggage_claim_time_2'],
        'baggage_claim_pax_waiting_area_2':
            detail['baggage_claim_pax_waiting_area_2'],
        'baggage_claim_time_3': detail['baggage_claim_time_3'],
        'baggage_claim_pax_waiting_area_3':
            detail['baggage_claim_pax_waiting_area_3'],
        'observations_event_time': detail['observations_event_time'],
        'observations_location': detail['observations_location'],
        'observations_description': detail['observations_description'],
        'observations_consequence': detail['observations_consequence'],
        'inspection_id': inspectionId,
      };

      final arrival = NationalArrival.fromJson(enrichedDetail);

      final service = ref.read(nationalArrivalServiceProvider);
      await service.save(arrival);
      print("arribo nacional ${arrival.id} precargado");
      if (detail['public_hall_id'] is List &&
          detail['public_hall_id'].isNotEmpty) {
        print("🟢 precargando public_hall_id lines...");
        await preloadPublicHalls(
          lines: detail['public_hall_id'],
          inspectionId: inspectionId,
          ref: ref,
        );
      }
      print("lista baggage time precargados");
      await preloadBaggageTimeList(
          rawLines: detail['baggage_claim_lines'],
          arrivalId: detail['id'],
          type: type,
          ref: ref);
    }
  }

  Future<void> preloadInternationalArrival(
      Map<String, dynamic> inspectionJson, Ref ref) async {
    final String operation = inspectionJson['operation'];
    final String type = inspectionJson['type'] ?? inspectionJson['type_'];

    // Verifica si es arribo internacional
    if (operation == 'arrival' && type == 'I') {
      final detail = inspectionJson['detail'];
      if (detail == null) return;

      final int inspectionId = inspectionJson['id'];

      final enrichedDetail = {
        'id': detail['id'],
        'general_data_measurement_date': detail['measurement_date'],
        'general_data_peak_hour': detail['peak_hour'],
        'general_data_flight_count': detail['flight_count'],
        //'general_data_prepared_by': detail['prepared_by'][1], //cargo el nombre
        'general_data_prepared_by': detail['prepared_by']?['name'],
        'general_data_prepared_by_id': detail['prepared_by']?['id'],
        'general_data_reviewed_by': '',
        'public_hall_time': detail['public_hall_time'],
        'public_hall_pax_waiting_area': detail['public_hall_pax_waiting_area'],
        'baggage_claim_belts': ([
          ...((detail['used_belts_123'] as List?) ?? const []),
          ...((detail['used_belts_456'] as List?) ?? const []),
        ]).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).join(','),
        'notes_belts': detail['notes_belts'],
        'baggage_area_used_belts_area': detail['used_belts_area'],
        'baggage_claim_time_1': detail['baggage_claim_time_1'],
        'baggage_claim_pax_waiting_area_1':
            detail['baggage_claim_pax_waiting_area_1'],
        'baggage_claim_time_2': detail['baggage_claim_time_2'],
        'baggage_claim_pax_waiting_area_2':
            detail['baggage_claim_pax_waiting_area_2'],
        'baggage_claim_time_3': detail['baggage_claim_time_3'],
        'baggage_claim_pax_waiting_area_3':
            detail['baggage_claim_pax_waiting_area_3'],
        'observations_event_time': detail['observations_event_time'],
        'observations_location': detail['observations_location'],
        'observations_description': detail['observations_description'],
        'observations_consequence': detail['observations_consequence'],
        'inspection_id': inspectionId,

        // Customs
        'customs_time': detail['customs_time'],
        'customs_maq_rx_oper': detail['customs_maq_rx_oper'],
        'customs_kiosko_pass': detail['customs_kiosko_pass'],
        'customs_pax_waiting_area': detail['customs_pax_waiting_area'],
        'customs_offline_time': detail['customs_offline_time'],
        'customs_waiting_time_max': detail['customs_waiting_time_max'],

        // Migration Area (NATIONAL)
        'migration_area_national_working_counters':
            detail['migration_area_national_working_counters'],
        'migration_area_national_pax_waiting_area':
            detail['migration_area_national_pax_waiting_area'],
        'migration_area_national_offline_time':
            detail['migration_area_national_offline_time'],

        // Migration Time (NATIONAL)
        'migration_time_national_attention_time_per_pax_1':
            detail['migration_time_national_attention_time_per_pax_1'],
        'migration_time_national_attention_time_per_pax_2':
            detail['migration_time_national_attention_time_per_pax_2'],
        'migration_time_national_attention_time_per_pax_3':
            detail['migration_time_national_attention_time_per_pax_3'],
        'migration_time_national_attention_time_per_pax_max':
            detail['migration_time_national_attention_time_per_pax_max'],

        // Migration Area (INTERNATIONAL)
        'migration_area_international_working_counters':
            detail['migration_area_international_working_counters'],
        'migration_area_international_pax_waiting_area':
            detail['migration_area_international_pax_waiting_area'],
        'migration_area_international_offline_time':
            detail['migration_area_international_offline_time'],

        // Migration Time (INTERNATIONAL)
        'migration_time_international_pax_waiting_time_1':
            detail['migration_time_international_pax_waiting_time_1'],
        'migration_time_international_pax_waiting_time_2':
            detail['migration_time_international_pax_waiting_time_2'],
        'migration_time_international_pax_waiting_time_3':
            detail['migration_time_international_pax_waiting_time_3'],
        'migration_time_international_pax_waiting_time_max':
            detail['migration_time_international_pax_waiting_time_max'],
      };

      final arrival = InternationalArrival.fromJson(enrichedDetail);

      final service = ref.read(internationalArrivalServiceProvider);
      await service.save(arrival);
      print("arribo internacional ${arrival.id} precargado");

      if (detail['public_hall_id'] is List &&
          detail['public_hall_id'].isNotEmpty) {
        print("🟢 precargando public_hall_id lines...");
        await preloadPublicHalls(
          lines: detail['public_hall_id'],
          inspectionId: inspectionId,
          ref: ref,
        );
      }
      await preloadBaggageTimeList(
          rawLines: detail['baggage_claim_lines'],
          arrivalId: detail['id'],
          type: type,
          ref: ref);
      print("lista baggage time precargados");
    }
  }

  Future<void> preloadBaggageTimeList({
    required List<dynamic> rawLines,
    required int arrivalId,
    required String type,
    required Ref ref,
  }) async {
    final baggageService = ref.read(baggageServiceProvider);

    for (final raw in rawLines) {
      final record = {
        'flight_number': raw['flight_number'],
        'origin': raw['origin'],
        'scheduled_time_a_hhmm': raw['scheduled_time_a_hhmm'],
        'arrival_time_b_hhmm': raw['arrival_time_b_hhmm'],
        'first_pax_arrival_c_hhmm': raw['first_pax_arrival_c_hhmm'],
        'first_bag_arrival_d_hhmm': raw['first_bag_arrival_d_hhmm'],
        'last_bag_arrival_e_hhmm': raw['last_bag_arrival_e_hhmm'],
        'assigned_belt': raw['assigned_belt'],
        // Campos calculados
        /*'diff_ba': null,
        'diff_dc': null,
        'diff_ed': null,
        'nds_time_function': null,*/
      };

      record['id'] = raw['id'];

      final data = BaggageTimeData.fromJson(record);

      if (type == 'D') {
        await baggageService.saveNationalArrivalBaggageField(
          arrivalId,
          raw['id'],
          data,
        );
      }

      if (type == 'I') {
        await baggageService.saveInternationalArrivalBaggageField(
          arrivalId,
          raw['id'],
          data,
        );
      }
    }
  }

  Future<void> preloadPreboardingLines(
      {required List<dynamic> lines,
      required int departureId,
      required Ref ref,
      required bool isNational}) async {
    final service = ref.read(preboardingServiceProvider);
    print(
        "---------------------PRELOADING PREBOARDING LINE OF INTERNATIONAL DEPARTURE: $departureId ");
    for (final line in lines) {
      final lineData = {
        'id': line['id'],
        //'departure_id': departureId,
        'area': line['area'],
        'used': line['used'],
        'used_chairs': line['used_chairs'],
        'available_chairs': line['available_chairs'],
        'used_area': line['used_area'],
        'available_area': line['available_area'],
        'occupancy_percentage': line['occupancy_percentage']
      };

      final preboardingLine = Preboarding.fromJson(lineData);

      if (isNational) {
        await service.saveNationalLine(
            departureId, line['id'], preboardingLine);
      } else {
        await service.saveInternationalLine(
            departureId, line['id'], preboardingLine);
      }
    }

    print("✅ líneas de preembarque precargadas para salida $departureId");
  }

  Future<void> preloadNationalDeparture(
      Map<String, dynamic> inspectionJson, Ref ref) async {
    final String operation = inspectionJson['operation'];
    final String type = inspectionJson['type'] ?? inspectionJson['type_'];

    if (operation == 'departure' && type == 'D') {
      final detail = inspectionJson['detail'];
      if (detail == null) return;

      final int inspectionId = inspectionJson['id'];

      final enrichedDetail = {
        'id': detail['id'],
        'inspection_id': inspectionId,
        'synced': 0,

        // General
        'general_data_measurement_date': detail['measurement_date'],
        'general_data_peak_hour': detail['peak_hour'],
        'general_data_flight_count': detail['flight_count'],
        'general_data_prepared_by': detail['prepared_by']?['name'],
        'general_data_prepared_by_id': detail['prepared_by']?['id'],
        'general_data_reviewed_by': '',

        // Public Hall
        'public_hall_time': detail['public_hall_time'],
        'public_hall_pax_waiting_area': detail['public_hall_pax_waiting_area'],

        // Flight Details
        'flight_count': detail['flight_count'],
        'flight_number': detail['flight_number'],
        'flight_pax_number': detail['flight_pax_number'],
        //'flight_destiny': detail['flight_destiny'],
        'flight_check_counter_number': detail['flight_check_counter_number'],
        'flight_preboarding_room': detail['flight_preboarding_room'],
        'flight_scheduled_time': detail['flight_scheduled_time'],
        'flight_actual_departure_time': detail['flight_actual_departure_time'],

        // Self Check-in Kiosk
        'self_checkin_kiosks_time': detail['self_checkin_kiosks_time'],
        'self_checkin_kiosks_service_time_per_pax_1':
            detail['self_checkin_kiosks_service_time_per_pax_1'],
        'self_checkin_kiosks_service_time_per_pax_2':
            detail['self_checkin_kiosks_service_time_per_pax_2'],
        'self_checkin_kiosks_maximum_waiting_time':
            detail['self_checkin_kiosks_maximum_waiting_time'],

        // Check-in Counter
        'checkin_counter_time': detail['checkin_counter_time'],
        'checkin_counter_assigned_counters_zone':
            detail['checkin_counter_assigned_counters_zone'],
        'checkin_counter_assigned_counters':
            detail['checkin_counter_assigned_counters'],
        'checkin_counter_operating_counters':
            detail['checkin_counter_operating_counters'],
        'checkin_counter_pax_waiting_area':
            detail['checkin_counter_pax_waiting_area'],
        'checkin_counter_offline_time': detail['checkin_counter_offline_time'],
        'checkin_counter_attention_time_per_pax_1':
            detail['checkin_counter_attention_time_per_pax_1'],
        'checkin_counter_attention_time_per_pax_2':
            detail['checkin_counter_attention_time_per_pax_2'],
        'checkin_counter_attention_time_per_pax_3':
            detail['checkin_counter_attention_time_per_pax_3'],
        'checkin_counter_attention_time_per_pax_4':
            detail['checkin_counter_attention_time_per_pax_4'],
        'checkin_counter_attention_time_per_pax_5':
            detail['checkin_counter_attention_time_per_pax_5'],
        'checkin_counter_attention_time_per_pax_max':
            detail['checkin_counter_attention_time_per_pax_max'],

        // Security Filters
        'security_filters_time': detail['security_filters_time'],
        'security_filters_observed_domestic_operators':
            detail['security_filters_observed_domestic_operators'],
        'security_filters_observed_international_operators':
            detail['security_filters_observed_international_operators'],
        'security_filters_observed_document_review_agents':
            detail['security_filters_observed_document_review_agents'],
        'security_filters_pax_waiting_area':
            detail['security_filters_pax_waiting_area'],
        'security_filters_offline_time':
            detail['security_filters_offline_time'],
        'security_filters_attention_time_per_pax_1':
            detail['security_filters_attention_time_per_pax_1'],
        'security_filters_attention_time_per_pax_2':
            detail['security_filters_attention_time_per_pax_2'],
        'security_filters_attention_time_per_pax_3':
            detail['security_filters_attention_time_per_pax_3'],
        'security_filters_attention_time_per_pax_4':
            detail['security_filters_attention_time_per_pax_4'],
        'security_filters_attention_time_per_pax_5':
            detail['security_filters_attention_time_per_pax_5'],

        // Preboarding
        //'preboarding_time': detail['preboarding_time'],

        // Observations
        'observations_event_time': detail['observations_event_time'],
        'observations_location': detail['observations_location'],
        'observations_description': detail['observations_description'],
        'observations_consequence': detail['observations_consequence'],
      };
      final departure = NationalDepartures.fromJson(enrichedDetail);
      final service = ref.read(NationaldeparturesServiceProvider);
      await service.save(departure);
      print("🟢 Salida nacional ${departure.id} precargada");

      if (detail['public_hall_id'] is List &&
          detail['public_hall_id'].isNotEmpty) {
        print("🟢 precargando public_hall_id lines...");
        await preloadPublicHalls(
          lines: detail['public_hall_id'],
          inspectionId: inspectionId,
          ref: ref,
        );
      }

      if (detail['preboarding_line_ids'] is List &&
          detail['preboarding_line_ids'].isNotEmpty) {
        print("🟢 precargando preboarding lines...");
        await preloadPreboardingLines(
          lines: detail['preboarding_line_ids'],
          departureId: departure.id!,
          ref: ref,
          isNational: true,
        );
      }

      print("🟢 API: flight number lines...");
      print(detail['flight_number']);
      if (detail['flight_number'] is List &&
          detail['flight_number'].isNotEmpty) {
        print("🟢 precargando flight options lines...");
        await preloadFlightOptions(
          lines: detail['flight_number'],
          departureId: departure.id!,
          ref: ref,
          isNational: true,
        );
      }

      if (detail['flight_check_counter_number'] is List &&
          detail['flight_check_counter_number'].isNotEmpty) {
        print("🟢 precargando flight counter number lines (nacional)...");
        await preloadFlightCounterNumbers(
          lines: detail['flight_check_counter_number'],
          departureId: departure.id!,
          ref: ref,
          isNational: true,
        );
      }

      if (detail['flight_preboarding_room'] is List &&
          detail['flight_preboarding_room'].isNotEmpty) {
        print("🟢 precargando preboarding rooms (nacional)...");
        await preloadFlightPreboardingRooms(
          lines: detail['flight_preboarding_room'],
          departureId: departure.id!,
          ref: ref,
          isNational: true,
        );
      }
      if (detail['checkin_counter_assigned_counters_zone'] is List &&
          detail['checkin_counter_assigned_counters_zone'].isNotEmpty) {
        print("🟢 checkin assigned counters (nacional)...");
        await preloadCheckinAssignedCounters(
          lines: detail['checkin_counter_assigned_counters_zone'],
          departureId: departure.id!,
          ref: ref,
          isNational: true,
        );
      }
    }
  }

  Future<void> preloadInternationalDeparture(
      Map<String, dynamic> inspectionJson, Ref ref) async {
    final String operation = inspectionJson['operation'];
    final String type = inspectionJson['type'] ?? inspectionJson['type_'];

    if (operation == 'departure' && type == 'I') {
      final detail = inspectionJson['detail'];
      if (detail == null) return;

      final int inspectionId = inspectionJson['id'];

      final enrichedDetail = {
        'id': detail['id'],
        'inspection_id': inspectionId,
        'synced': 0,

        // General
        'general_data_measurement_date': detail['measurement_date'],
        'general_data_peak_hour': detail['peak_hour'],
        'general_data_flight_count': detail['flight_count'],
        'general_data_prepared_by': detail['prepared_by']?['name'],
        'general_data_prepared_by_id': detail['prepared_by']?['id'],
        'general_data_reviewed_by': '',

        // Public Hall
        'public_hall_time': detail['public_hall_time'],
        'public_hall_pax_waiting_area': detail['public_hall_pax_waiting_area'],

        // Flight Details
        'flight_count': detail['flight_count'],
        'flight_number': detail['flight_number'],
        'flight_pax_number': detail['flight_pax_number'],
        //'flight_destiny': detail['flight_destiny'],
        'flight_check_counter_number': detail['flight_check_counter_number'],
        'flight_preboarding_room': detail['flight_preboarding_room'],
        'flight_scheduled_time': detail['flight_scheduled_time'],
        'flight_actual_departure_time': detail['flight_actual_departure_time'],

        // Self Check-in Kiosk
        'self_checkin_kiosks_time': detail['self_checkin_kiosks_time'],
        'self_checkin_kiosks_service_time_per_pax_1':
            detail['self_checkin_kiosks_service_time_per_pax_1'],
        'self_checkin_kiosks_service_time_per_pax_2':
            detail['self_checkin_kiosks_service_time_per_pax_2'],
        'self_checkin_kiosks_maximum_waiting_time':
            detail['self_checkin_kiosks_maximum_waiting_time'],

        // Check-in Counter
        'checkin_counter_time': detail['checkin_counter_time'],
        'checkin_counter_assigned_counters_zone':
            detail['checkin_counter_assigned_counters_zone'],
        'checkin_counter_assigned_counters':
            detail['checkin_counter_assigned_counters'],
        'checkin_counter_operating_counters':
            detail['checkin_counter_operating_counters'],
        'checkin_counter_pax_waiting_area':
            detail['checkin_counter_pax_waiting_area'],
        'checkin_counter_offline_time': detail['checkin_counter_offline_time'],
        'checkin_counter_attention_time_per_pax_1':
            detail['checkin_counter_attention_time_per_pax_1'],
        'checkin_counter_attention_time_per_pax_2':
            detail['checkin_counter_attention_time_per_pax_2'],
        'checkin_counter_attention_time_per_pax_3':
            detail['checkin_counter_attention_time_per_pax_3'],
        'checkin_counter_attention_time_per_pax_4':
            detail['checkin_counter_attention_time_per_pax_4'],
        'checkin_counter_attention_time_per_pax_5':
            detail['checkin_counter_attention_time_per_pax_5'],
        'checkin_counter_attention_time_per_pax_max':
            //'checkin_counter_attention_time_per_pax_max':
            detail['checkin_counter_attention_time_per_pax_max'],

        // Security Filters
        'security_filters_time': detail['security_filters_time'],
        'security_filters_observed_domestic_operators':
            detail['security_filters_observed_domestic_operators'],
        'security_filters_observed_international_operators':
            detail['security_filters_observed_international_operators'],
        'security_filters_observed_document_review_agents':
            detail['security_filters_observed_document_review_agents'],
        'security_filters_pax_waiting_area':
            detail['security_filters_pax_waiting_area'],
        'security_filters_offline_time':
            detail['security_filters_offline_time'],
        'security_filters_attention_time_per_pax_1':
            detail['security_filters_attention_time_per_pax_1'],
        'security_filters_attention_time_per_pax_2':
            detail['security_filters_attention_time_per_pax_2'],
        'security_filters_attention_time_per_pax_3':
            detail['security_filters_attention_time_per_pax_3'],
        'security_filters_attention_time_per_pax_4':
            detail['security_filters_attention_time_per_pax_4'],
        'security_filters_attention_time_per_pax_5':
            detail['security_filters_attention_time_per_pax_5'],
        //migration area national
        'migration_area_national_working_counters':
            detail['migration_area_national_working_counters'],
        'migration_area_national_pax_waiting_area':
            detail['migration_area_national_pax_waiting_area'],
        'migration_area_national_offline_time':
            detail['migration_area_national_offline_time'],
        'migration_area_national_waiting_area_occupancy':
            detail['migration_area_national_waiting_area_occupancy'],
        //migration time national
        //'migration_time_national_pax_waiting_time_1':
        'migration_time_national_attention_time_per_pax_1':
            detail['migration_time_national_attention_time_per_pax_1'],
        'migration_time_national_attention_time_per_pax_2':
            detail['migration_time_national_attention_time_per_pax_2'],
        'migration_time_national_attention_time_per_pax_3':
            detail['migration_time_national_attention_time_per_pax_3'],
        'migration_time_national_attention_time_per_pax_max':
            detail['migration_time_national_attention_time_per_pax_max'],
        //migration area international
        'migration_area_international_working_counters':
            detail['migration_area_international_working_counters'],
        'migration_area_international_pax_waiting_area':
            detail['migration_area_international_pax_waiting_area'],
        'migration_area_international_offline_time':
            detail['migration_area_international_offline_time'],
        'migration_area_international_waiting_area_occupancy':
            detail['migration_area_international_waiting_area_occupancy'],
        //migration time international
        'migration_time_international_pax_waiting_time_1':
            detail['migration_time_international_pax_waiting_time_1'],
        'migration_time_international_pax_waiting_time_2':
            detail['migration_time_international_pax_waiting_time_2'],
        'migration_time_international_pax_waiting_time_3':
            detail['migration_time_international_pax_waiting_time_3'],
        'migration_time_international_pax_waiting_time_max':
            detail['migration_time_international_pax_waiting_time_max'],

        // Observations
        'observations_event_time': detail['observations_event_time'],
        'observations_location': detail['observations_location'],
        'observations_description': detail['observations_description'],
        'observations_consequence': detail['observations_consequence'],
      };

      print("🔵 Salida internacional pre json");
      debugPrint("$enrichedDetail");
      final departure = InternationalDepartures.fromJson(enrichedDetail);
      final service = ref.read(InternationaldeparturesServiceProvider);
      await service.save(departure);
      print("🔵 Salida internacional ${departure.id} precargada");

      if (detail['public_hall_id'] is List &&
          detail['public_hall_id'].isNotEmpty) {
        print("🟢 precargando public_hall_id lines...");
        await preloadPublicHalls(
          lines: detail['public_hall_id'],
          inspectionId: inspectionId,
          ref: ref,
        );
      }

      if (detail['preboarding_line_ids'] is List &&
          detail['preboarding_line_ids'].isNotEmpty) {
        print("🟢 precargando preboarding lines...");
        await preloadPreboardingLines(
          lines: detail['preboarding_line_ids'],
          departureId: departure.id!,
          ref: ref,
          isNational: false,
        );
      }

      print("🟢 API: flight number lines...");
      print(detail['flight_number']);
      if (detail['flight_number'] is List &&
          detail['flight_number'].isNotEmpty) {
        print("🟢 precargando flight options lines...");
        await preloadFlightOptions(
          lines: detail['flight_number'],
          departureId: departure.id!,
          ref: ref,
          isNational: false,
        );
      }

      print("🟢 API: flight check counter number lines...");
      print(detail['flight_check_counter_number']);
      if (detail['flight_check_counter_number'] is List &&
          detail['flight_check_counter_number'].isNotEmpty) {
        print("🟢 precargando flight counter number lines...");
        await preloadFlightCounterNumbers(
          lines: detail['flight_check_counter_number'],
          departureId: departure.id!,
          ref: ref,
          isNational: false,
        );
      }

      if (detail['flight_preboarding_room'] is List &&
          detail['flight_preboarding_room'].isNotEmpty) {
        print("🟢 precargando preboarding rooms (nacional)...");
        await preloadFlightPreboardingRooms(
          lines: detail['flight_preboarding_room'],
          departureId: departure.id!,
          ref: ref,
          isNational: false,
        );
      }
      if (detail['checkin_counter_assigned_counters_zone'] is List &&
          detail['checkin_counter_assigned_counters_zone'].isNotEmpty) {
        print("🟢 checkin assigned counters (nacional)...");
        await preloadCheckinAssignedCounters(
          lines: detail['checkin_counter_assigned_counters_zone'],
          departureId: departure.id!,
          ref: ref,
          isNational: true,
        );
      }
    }
  }

  Future<void> preloadFlightOptions({
    required List<dynamic> lines,
    required int departureId,
    required Ref ref,
    required bool isNational,
  }) async {
    final flightRepo = ref.read(flightOptionsRepositoryProvider);

    print("--- FLIGHT OPTIONS----");
    for (final line in lines) {
      final option = FlightOption.fromJson(line as Map<String, dynamic>);

      print(line);

      await flightRepo.saveFlightOptionsLine(
        departureId: departureId,
        item: option,
        isNational: isNational,
      );
    }
  }

  Future<void> preloadFlightPreboardingRooms({
    required List<dynamic> lines,
    required int departureId,
    required Ref ref,
    required bool isNational,
  }) async {
    final repo = ref.read(preboardingRoomRepositoryProvider);

    print("--- FLIGHT PREBOARDING ROOM ---");
    for (final line in lines) {
      final room = FlightPreboardingRoom.fromJson(line as Map<String, dynamic>);

      await repo.savePreboardingRoomLine(
        line: room,
        departureId: departureId,
        isNational: isNational,
      );
    }
    print(
        "✅ ${lines.length} preboarding rooms precargados para salida $departureId");
  }

  Future<void> preloadFlightCounterNumbers(
      {required List<dynamic> lines,
      required int departureId,
      required Ref ref,
      required bool isNational}) async {
    final flightRepo = ref.read(flightCheckCounterNumberRepositoryProvider);

    print("--- FLIGHT COUNTER NUMBER----");
    for (final line in lines) {
      final option =
          FlightCheckCounterNumber.fromJson(line as Map<String, dynamic>);

      await flightRepo.saveFlightCheckCounterNumberLine(
        departureId: departureId,
        isNational: isNational,
        line: option,
      );
    }
  }

  Future<void> preloadCheckinAssignedCounters(
      {required List<dynamic> lines,
      required int departureId,
      required Ref ref,
      required bool isNational}) async {
    final checkinRepo = ref.read(checkinCounterRepositoryProvider);

    print("--- CHECKIN COUNTER NUMBER----");
    for (final line in lines) {
      final option =
          CheckinAssignedCounter.fromJson(line as Map<String, dynamic>);

      await checkinRepo.saveCounterNumberLine(
        departureId: departureId,
        isNational: isNational,
        line: option,
      );
    }
  }

  Future<void> preloadPublicHalls({
    required List<dynamic> lines,
    required int inspectionId,
    required Ref ref,
  }) async {
    final publicHallRepo = ref.read(publicHallOptionRepositoryProvider);

    print("--- PUBLIC HALLS----");
    for (final line in lines) {
      final option = PublicHallOption.fromJson(line as Map<String, dynamic>);

      await publicHallRepo.savePublicHallsLine(
        inspectionId: inspectionId,
        line: option,
      );
    }
  }

  Future<void> preloadCargo(
    Map<String, dynamic> inspectionJson,
    Ref ref,
  ) async {
    /* ---------- 1. Filtro rápido ---------- */
    final op = inspectionJson['operation'];
    final typ = inspectionJson['type'] ?? inspectionJson['type_'];
    final fTyp = inspectionJson['flight_type'];
    if (op != 'none' || typ != 'none' || fTyp != 'cargo') return;

    final detail = inspectionJson['detail'];
    if (detail == null) return;

    /* ---------- 2. Header ---------- */
    final cargoHeader = {
      'id': detail['id'],
      'inspection_id': inspectionJson['id'],
      'synced': 0,
      // GENERAL
      'general_data_measurement_date': detail['measurement_date'],
      'general_data_hour': detail['hour'],
      'general_data_prepared_by_id': detail['prepared_by']?['id'],
      'general_data_prepared_by': detail['prepared_by']?['name'],
      'general_data_reviewed_by': '',
      // LANDSIDE (horas)
      'earthside_national_hour': detail['earthside_national_hour'],
      'earthside_international_hour': detail['earthside_international_hour'],
      'earthside_international_building_hour':
          detail['earthside_international_building_hour'],
      // AIRSIDE (hora)
      'airside_national_international_hour':
          detail['airside_national_international_hour'],
    };

    final cargoService = ref.read(cargoServiceProvider);
    final cargo = Cargo.fromJson(cargoHeader);
    await cargoService.saveCargo(cargo);

    final dbCargo = ref.read(cargoRepositoryProvider);
    final int cargoId = cargo.id!; // id ya persistido

    final List<LandsideEntry> landsideEntries =
        LandsideEntry.apiJsonToEntries(detail)
            .map((e) => e.copyWithField('cargo_id', cargoId))
            .toList();

    await dbCargo.saveLandside(landsideEntries, cargoId);

    final List<AirsideEntry> airsideEntries =
        AirsideEntry.apiJsonToEntries(detail)
            .map((e) => e.copyWithField('cargo_id', cargoId))
            .toList();

    await dbCargo.saveAirside(airsideEntries, cargoId);
    /*
    await dbCargo.saveAirside(
        AirsideEntry.fromJsonList(
            detail['airside_national_international_quality'] ?? []),
        cargoId,
        'quality');

    await dbCargo.saveAirside(
        AirsideEntry.fromJsonList(
            detail['airside_national_international_security'] ?? []),
        cargoId,
        'security');

    await dbCargo.saveAirside(
        AirsideEntry.fromJsonList(
            detail['airside_national_international_environment'] ?? []),
        cargoId,
        'environment');
      */
    print('✅ Cargo $cargoId precargado y almacenado en SQLite');
  }

  Future<bool> syncInspection(Inspection inspection) async {
    String? sessionId = session["session_id"] ?? null;
    String baseUrl = await ApiService.getBaseUrl();
    if (session["session_id"] == null) {
      throw Exception("❌ Error al obtener inspecciones");
    }

    late Map<String, dynamic> inspectionData;
    if (inspection.operation == 'departure') {
      if (inspection.type == 'I') {
        print("SALIDA INTERNACIONAL");
        inspectionData = await this
            ._inspectionRepository
            .buildInternationalDepartureInspectionJson(inspection);
      }
      if (inspection.type == 'D') {
        print("SALIDA NACIONAL");
        inspectionData = await this
            ._inspectionRepository
            .buildNationalDepartureInspectionJson(inspection);
      }
    }
    if (inspection.operation == 'arrival') {
      if (inspection.type == 'I') {
        print("ARRIBO INTERNACIONAL");
        inspectionData = await this
            ._inspectionRepository
            .buildInternationalArrivalInspectionJson(inspection);
      }
      if (inspection.type == 'D') {
        print("ARRIBO NACIONAL");
        inspectionData = await this
            ._inspectionRepository
            .buildNationalArrivalInspectionJson(inspection);
      }
    }

    // === CARGO ===
    final isCargo = (inspection.flightType == 'cargo') &&
        (inspection.operation == 'none' && inspection.type == 'none');
    if (isCargo) {
      print("CARGA");
      inspectionData =
          await _inspectionRepository.buildCargoInspectionJson(inspection);
    }
    print("Sync CARGA json");
    debugPrint("${inspectionData}");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync-controls'),
        headers: {
          'Content-Type': 'application/json',
          "Cookie": "session_id=$sessionId",
        },
        body: json.encode(inspectionData),
      );

      print("RESPONSE FROM API: ${response.body}");

      if (response.statusCode == 200) {
        print("Inspección sincronizada con éxito");
        return true;
      } else {
        print(
            "Code error: ${response.statusCode} Error al sincronizar: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Excepción al sincronizar: $e");
      return false;
    }
  }

  Future<bool> syncPhotos(int inspectionId) async {
    final String? sid = session['session_id'];
    if (sid == null) {
      debugPrint("❌ No hay sesión para sincronizar fotos");
      return false;
    }

    final String baseUrl = await ApiService.getBaseUrl();
    final photos =
        await _inspectionRepository.getPhotosByInspection(inspectionId);
    debugPrint(
        "🔄 Fotos pendientes de sincronización (${inspectionId}): ${photos.length}");
    if (photos.isEmpty) {
      debugPrint("ℹ️ No hay fotos para sincronizar.");
      return true;
    }

    try {
      final jsonData = await compressInspectionPhotosToJson(inspectionId);

      //print("PHOTO DATA");
      //debugPrint("${jsonData}");

      final uri = Uri.parse('$baseUrl/api/sync-photos');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Cookie': 'session_id=$sid',
            },
            body: jsonEncode(jsonData),
          )
          .timeout(const Duration(minutes: 2));

      debugPrint(
          "🛰️ RESP SYNC-PHOTOS: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        /*await _deleteLocalPhotoFiles(photos.map((p) => p.path).toList());

        try {
          await _inspectionRepository.deletePhotosByInspection(inspectionId);
        } catch (_) {
          debugPrint("⚠️ No se pudieron eliminar registros en SQLite");
        }*/

        debugPrint(
            "✅ Fotos de la inspección $inspectionId sincronizadas y limpiadas localmente");
        return true;
      } else {
        debugPrint(
            "❌ Error al sincronizar fotos: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Excepción en syncPhotos: $e");
      return false;
    }
  }

  Future<void> _deleteLocalPhotoFiles(List<String> paths) async {
    for (final path in paths) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
          debugPrint("🗑️ Archivo eliminado: $path");
        }
      } catch (e) {
        debugPrint("⚠️ No se pudo eliminar $path: $e");
      }
    }
  }

  Future<Map<String, dynamic>> compressInspectionPhotosToJson(
      int inspectionId) async {
    try {
      final photos =
          await _inspectionRepository.getPhotosByInspection(inspectionId);
      final archive = Archive();
      final photoDataList = [];

      for (var photo in photos) {
        final file = File(photo.path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = file.path.split('/').last;
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          photoDataList.add(photo.toJson());
        }
      }

      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/inspection_$inspectionId.zip';
      final zipFile = File(zipPath)..writeAsBytesSync(zipData!);
      final zipBytes = await zipFile.readAsBytes();
      final base64Zip = base64Encode(zipBytes);

      await zipFile.delete();

      return {
        'inspection_id': inspectionId,
        'photo_count': photoDataList.length,
        'photos': photoDataList,
        'compressed_photos': base64Zip,
      };
    } catch (e) {
      print("❌ Error al comprimir fotos: \$e");
      throw Exception("Error al comprimir fotos: \$e");
    }
  }
}
