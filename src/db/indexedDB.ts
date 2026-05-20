import Dexie, { type Table } from 'dexie';

// ----------------------------------------------------
// Entity Interfaces
// ----------------------------------------------------

export interface User {
  id: number; // Odoo UID
  name: string;
  active: number; // 1 = active, 0 = inactive
}

export interface PenaltyCatalog {
  id: string; // unique ID
  serverId: number; // unique Odoo ID
  parentId: number; // 2 = Leve, 3 = Grave, 4 = Muy Grave
  name: string;
  active: number;
}

export interface Penalty {
  id?: number;
  name?: string; // Acta number
  partnerId: number; // Infractor ID
  parentId: number; // Severity parent ID
  penaltyId: number; // Catalog item ID
  date: string; // Format: yyyy-MM-dd
  amount: number;
  status: 'pending' | 'paid';
  observations: string;
  synced: number; // 0 = pending, 1 = synced
}

export interface Inspection {
  id: number;
  type: 'D' | 'I' | 'none'; // National / International / None (cargo)
  operation: 'departure' | 'arrival' | 'none';
  flightType?: string; // e.g. 'cargo'
  assigned_user: string;
  status: 'Asignada' | 'En progreso' | 'Finalizada';
  started_at?: string;
  synced: number; // 0 = no, 1 = yes
  date?: string; // string representation from api
}

export interface NationalArrival {
  id?: number;
  inspection_id: number;
  general_data_measurement_date?: string;
  general_data_peak_hour?: string;
  general_data_hour?: string;
  general_data_flight_count?: number;
  general_data_prepared_by_id?: number;
  general_data_prepared_by?: string;
  general_data_reviewed_by_id?: number;
  general_data_reviewed_by?: string;

  public_hall_time?: string;
  public_hall_pax_waiting_area?: number;
  public_hall_nds_area?: string;
  public_hall_nds_time?: string;

  baggage_claim_belts?: string;
  notes_belts?: string;
  baggage_claim_time_1?: string;
  baggage_claim_pax_waiting_area_1?: number;
  baggage_claim_time_2?: string;
  baggage_claim_pax_waiting_area_2?: number;
  baggage_claim_time_3?: string;
  baggage_claim_pax_waiting_area_3?: number;
  baggage_claim_area_function?: string;

  observations_event_time?: string;
  observations_location?: string;
  observations_description?: string;
  observations_consequence?: string;
  synced: number;
}

export interface InternationalArrival extends NationalArrival {
  migration_id?: number;
  migration_area_time?: string;
  migration_area_national_working_counters?: number;
  migration_area_national_pax_waiting_area?: number;
  migration_area_national_occupancy?: number;
  migration_area_national_offline_time?: string;
  migration_area_international_working_counters?: number;
  migration_area_international_pax_waiting_area?: number;
  migration_area_international_occupancy?: number;
  migration_area_international_offline_time?: string;

  migration_time_national_attention_time_per_pax_1?: string;
  migration_time_national_attention_time_per_pax_2?: string;
  migration_time_national_attention_time_per_pax_3?: string;
  migration_time_national_attention_time_per_pax_max?: string;
  migration_time_national_average?: string;

  migration_time_international_pax_waiting_time_1?: string;
  migration_time_international_pax_waiting_time_2?: string;
  migration_time_international_pax_waiting_time_3?: string;
  migration_time_international_pax_waiting_time_max?: string;
  migration_time_international_average?: string;

  migration_total_counters_attending?: number;
  migration_total_pax_waiting_area?: number;
  migration_max_waiting_time?: string;
  migration_nds_area?: string;
  migration_nds_time?: string;

  customs_time?: string;
  customs_maq_rx_oper?: number;
  customs_kiosko_pass?: number;
  customs_pax_waiting_area?: number;
  customs_area_occupancy?: number;
  customs_offline_time?: string;
  customs_waiting_time_max?: string;
  customs_nds_area?: string;
  customs_nds_time?: string;
}

export interface BaggageTimeDetail {
  id?: number;
  national_arrival_id?: number;
  international_arrival_id?: number;
  flight_number?: string;
  origin?: string;
  scheduled_time_a_hhmm?: string;
  arrival_time_b_hhmm?: string;
  assigned_belt?: string;
  first_pax_arrival_c_hhmm?: string;
  first_bag_arrival_d_hhmm?: string;
  last_bag_arrival_e_hhmm?: string;
  synced: number;
}

export interface NationalDeparture {
  id?: number;
  inspection_id: number;
  general_data_measurement_date?: string;
  general_data_peak_hour?: string;
  general_data_hour?: string;
  general_data_flight_count?: number;
  general_data_prepared_by_id?: number;
  general_data_prepared_by?: string;
  general_data_reviewed_by_id?: number;
  general_data_reviewed_by?: string;

  flight_count?: number;
  flight_pax_number?: number;
  flight_number?: string;
  flight_destiny?: string;
  flight_check_counter_number?: number;
  flight_preboarding_room?: string;
  flight_scheduled_time?: string;
  flight_actual_departure_time?: string;

  public_hall_time?: string;
  public_hall_pax_waiting_area?: number;
  public_hall_nds_area?: string;
  public_hall_nds_time?: string;

  self_checkin_kiosks_time?: string;
  self_checkin_kiosks_service_time_per_pax_1?: string;
  self_checkin_kiosks_service_time_per_pax_2?: string;
  self_checkin_kiosks_average?: string;
  self_checkin_kiosks_maximum_waiting_time?: string;
  self_checkin_kiosks_nds_time_function?: string;

  checkin_counter_time?: string;
  checkin_counter_assigned_counters?: number;
  checkin_counter_operating_counters?: number;
  checkin_counter_pax_waiting_area?: number;
  checkin_counter_waiting_area_occupancy_percentage?: number;
  checkin_counter_offline_time?: string;
  checkin_counter_nds_area_function?: string;
  checkin_counter_attention_time_per_pax_1?: string;
  checkin_counter_attention_time_per_pax_2?: string;
  checkin_counter_attention_time_per_pax_3?: string;
  checkin_counter_attention_time_per_pax_4?: string;
  checkin_counter_attention_time_per_pax_5?: string;
  checkin_counter_attention_time_average?: string;
  checkin_counter_attention_time_per_pax_max?: string;
  checkin_counter_nds_time_area_function?: string;

  security_filters_time?: string;
  security_filters_observed_domestic_operators?: number;
  security_filters_observed_international_operators?: number;
  security_filters_observed_document_review_agents?: number;
  security_filters_pax_waiting_area?: number;
  security_filters_waiting_area_occupancy?: number;
  security_filters_offline_time?: string;
  security_filters_nds_area?: string;
  security_filters_attention_time_per_pax_1?: string;
  security_filters_attention_time_per_pax_2?: string;
  security_filters_attention_time_per_pax_3?: string;
  security_filters_attention_time_per_pax_4?: string;
  security_filters_attention_time_per_pax_5?: string;
  security_filters_waiting_time_average?: string;
  security_filters_nds_time_function?: string;

  preboarding_rooms_area_time?: number;
  preboarding_rooms_area_occupancy?: number;
  preboarding_rooms_area_pax_number?: number;
  preboarding_rooms_area_area_function_a_rooms?: string;
  preboarding_rooms_area_occupancy_pax_other_rooms?: string;
  preboarding_rooms_area_area_function_b_d_rooms?: string;
  preboarding_rooms_time_total_occupancy?: number;
  preboarding_rooms_time_occupancy_function?: string;

  observations_event_time?: string;
  observations_location?: string;
  observations_description?: string;
  observations_consequence?: string;
  synced: number;
}

export interface InternationalDeparture extends NationalDeparture {
  migration_id?: number;
  migration_area_time?: string;
  migration_area_national_working_counters?: number;
  migration_area_national_pax_waiting_area?: number;
  migration_area_national_waiting_area_occupancy?: number;
  migration_area_national_offline_time?: string;
  migration_area_national_occupancy?: number;
  migration_area_international_working_counters?: number;
  migration_area_international_pax_waiting_area?: number;
  migration_area_international_waiting_area_occupancy?: number;
  migration_area_international_offline_time?: string;
  migration_area_international_occupancy?: number;
  migration_area_total_working_counters?: number;
  migration_area_total_pax_waiting_area?: number;
  migration_area_waiting_area_occupancy_standard?: string;
  migration_time_nds_function_area?: string;
  migration_total_counters_attending?: number;
  migration_total_pax_waiting_area?: number;
  migration_max_waiting_time?: string;
  migration_nds_area?: string;
  migration_nds_time?: string;

  migration_time_national_attention_time_per_pax_1?: string;
  migration_time_national_attention_time_per_pax_2?: string;
  migration_time_national_attention_time_per_pax_3?: string;
  migration_time_national_attention_time_per_pax_max?: string;
  migration_time_national_max_waiting_time?: string;
  migration_time_national_nds_function_time?: string;
  migration_time_national_average?: string;

  migration_time_international_pax_waiting_time_1?: string;
  migration_time_international_pax_waiting_time_2?: string;
  migration_time_international_pax_waiting_time_3?: string;
  migration_time_international_pax_waiting_time_max?: string;
  migration_time_international_average?: string;
  migration_time_international_nds_function_time?: string;
}

export interface DeparturePreboardingDetail {
  id?: number;
  national_departure_id?: number;
  international_departure_id?: number;
  area: string;
  used: number;
  used_chairs: number;
  available_chairs: number;
  used_area: number;
  available_area: number;
  occupancy_percentage: number;
  synced: number;
}

export interface FlightOption {
  id: number;
  national_departure_id?: number;
  international_departure_id?: number;
  name: string;
  destiny: string;
  time: string;
  selected: number; // 0 or 1
  synced: number;
}

export interface FlightCheckCounter {
  id?: number;
  national_departure_id?: number;
  international_departure_id?: number;
  name: string;
  selected: number;
  synced: number;
}

export interface FlightPreboardingRoom {
  id?: number;
  national_departure_id?: number;
  international_departure_id?: number;
  name: string;
  selected: number;
  synced: number;
}

export interface CheckinAssignedCounter {
  id?: number;
  national_departure_id?: number;
  international_departure_id?: number;
  name: string;
  selected: number;
  synced: number;
}

export interface CargoInspection {
  id: number;
  inspection_id: number;
  general_data_measurement_date?: string;
  general_data_prepared_by_id?: number;
  general_data_prepared_by?: string;
  general_data_reviewed_by_id?: number;
  general_data_reviewed_by?: string;
  general_data_peak_hour?: string;
  general_data_hour?: string;
  general_data_flight_count?: number;

  earthside_national_hour?: string;
  earthside_international_hour?: string;
  earthside_international_building_hour?: string;
  airside_national_international_hour?: string;
  synced: number;
}

export interface CargoItem {
  id?: number;
  apiId?: number; // Odoo ID
  cargo_id: number;
  parent: string; // 'landside' | 'airside' | 'galley' etc.
  type?: string;
  sequence: number;
  name: string;
  qualification: string; // Satisfactorio, No cumple, No aplica, etc.
  note: string;
  max_value?: number;
  control_value?: number;
  percentage?: number;
  synced: number;
}

export interface InspectionPhoto {
  id?: number;
  inspection_id: number;
  section: string; // 'public_hall', 'observations', 'customs', etc.
  path: string; // Local ObjectURL or base64
  blob?: Blob; // Actual photo blob
  caption: string;
  timestamp: string;
  synced: number;
}

export interface PublicHallOption {
  id?: number;
  apiId?: number;
  inspection_id: number;
  name: string;
  selected: number;
  synced: number;
}

export interface AssignmentTest {
  id: number; // unique Test assignment ID
  site_test?: number;
  date_test?: string;
  time_test?: string;
  type?: string; // 'procedure', etc.
  brand?: string;
  model?: string;
  hiding_site?: string;
  detected?: boolean;
  corrective_action?: boolean;
  collaborator_name?: string;
  collaborator_nationality?: number;
  collaborator_identity?: string;
  collaborator_email?: string;
  authorization?: boolean;
  observation?: string;
  recommendation?: string;
  made_to?: number;
  status: 'Asignada' | 'En progreso' | 'Finalizada';
  synced: number;
}

export interface OfflineMutation {
  id?: number;
  type: 'create_penalty' | 'sync_control' | 'sync_photos' | 'sync_test';
  inspectionId?: number; // associated inspection or test id if applicable
  payload: any; // payload details
  timestamp: number;
  status: 'pending' | 'processing' | 'conflict' | 'failed' | 'synced';
  error?: string;
  conflictReason?: string;
}

// ----------------------------------------------------
// Dexie Database Class
// ----------------------------------------------------

class EPMSADatabase extends Dexie {
  users!: Table<User, number>;
  penalties_catalog!: Table<PenaltyCatalog, string>;
  penalties!: Table<Penalty, number>;
  inspections!: Table<Inspection, number>;
  national_arrivals!: Table<NationalArrival, number>;
  arrival_baggage_time_details!: Table<BaggageTimeDetail, number>;
  international_arrivals!: Table<InternationalArrival, number>;
  inspection_photos!: Table<InspectionPhoto, number>;
  national_departures!: Table<NationalDeparture, number>;
  international_departures!: Table<InternationalDeparture, number>;
  departures_preboarding_details!: Table<DeparturePreboardingDetail, number>;
  departure_flight_options!: Table<FlightOption, number>;
  departure_flight_check_counters!: Table<FlightCheckCounter, number>;
  departure_flight_preboarding_rooms!: Table<FlightPreboardingRoom, number>;
  departure_checkin_assigned_counters!: Table<CheckinAssignedCounter, number>;
  cargo_inspections!: Table<CargoInspection, number>;
  cargo_items!: Table<CargoItem, number>;
  inspections_public_halls!: Table<PublicHallOption, number>;
  assignments_tests!: Table<AssignmentTest, number>;
  mutations!: Table<OfflineMutation, number>;

  constructor() {
    super('EPMSADatabase');
    this.version(1).stores({
      users: 'id, name, active',
      penalties_catalog: 'id, serverId, parentId, name, active',
      penalties: '++id, partnerId, penaltyId, synced',
      inspections: 'id, type, status, synced',
      national_arrivals: '++id, inspection_id, synced',
      arrival_baggage_time_details: '++id, national_arrival_id, international_arrival_id, synced',
      international_arrivals: '++id, inspection_id, synced',
      inspection_photos: '++id, inspection_id, section, synced',
      national_departures: '++id, inspection_id, synced',
      international_departures: '++id, inspection_id, synced',
      departures_preboarding_details: '++id, national_departure_id, international_departure_id, synced',
      departure_flight_options: '++id, national_departure_id, international_departure_id, synced',
      departure_flight_check_counters: '++id, national_departure_id, international_departure_id, synced',
      departure_flight_preboarding_rooms: '++id, national_departure_id, international_departure_id, synced',
      departure_checkin_assigned_counters: '++id, national_departure_id, international_departure_id, synced',
      cargo_inspections: '++id, inspection_id, synced',
      cargo_items: '++id, cargo_id, parent, synced',
      inspections_public_halls: '++id, inspection_id, synced',
      assignments_tests: 'id, status, synced',
      mutations: '++id, type, status, timestamp'
    });
  }
}

export const db = new EPMSADatabase();
