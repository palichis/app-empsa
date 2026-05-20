// ==========================================
// Core Types - Session & Config
// ==========================================

export interface OdooConfig {
  serverUrl: string;
  dbName: string;
}

export interface UserSession {
  uid: number;
  sessionId: string;
  name: string;
  company?: string;
}

// ==========================================
// Common Entity Types
// ==========================================

export interface BaseEntity {
  id: number;
  name: string;
}

export type Area = BaseEntity;
export type Nationality = BaseEntity;
export type Employee = BaseEntity;
export type Process = BaseEntity;
export type Category = BaseEntity;
export type Criticality = BaseEntity;

// ==========================================
// Assignments Module Types
// ==========================================

export interface InspectionRequirement {
  id: number;
  qualification: QualificationType;
}

export type QualificationType = 
  | 'Satifactory' 
  | 'Unsatisfactory' 
  | 'Notcomply' 
  | 'Notapply' 
  | 'Notobserved';

export const QualificationLabels: Record<QualificationType, string> = {
  'Satifactory': 'Satisfactorio',
  'Unsatisfactory': 'Poco satisfactorio',
  'Notcomply': 'No cumple',
  'Notapply': 'No aplica',
  'Notobserved': 'No observado',
};

export const QualificationFromSpanish: Record<string, QualificationType> = {
  'Satisfactorio': 'Satifactory',
  'Poco satisfactorio': 'Unsatisfactory',
  'No cumple': 'Notcomply',
  'No aplica': 'Notapply',
  'No observado': 'Notobserved',
};

export interface TaskItem {
  id: number;
  codigo: string;
  descripcion: string;
}

export interface Task {
  id: number;
  title: string;
  code: string;
  date: string;
  time: string;
  duration: string;
  assignedTo: string;
  description: string;
  status: string;
  isInspection: boolean;
  inspectionRequirementIds: [number, string][];
  version?: string;
  itemIds: TaskItem[];
}

export interface InspectionResult {
  id: number | null;
  version: string | null;
  code: string | null;
  name: string | null;
  date: string | null;
  guideId: (number | string)[];
  state: string | null;
  madeBy: (number | string)[];
  audited: string | null;
  inspectionRequirementIds: [number, string][];
  observations: string | null;
  processId: (number | string)[];
}

export interface TestResult {
  id: number | null;
  name: string | null;
  version: string | null;
  code: string | null;
  date: string | null;
  testNumber: string | null;
  dateTest: string | null;
  timeTest: string | null;
  siteTest: number | null;
  state: string | null;
  type: string | null;
  madeBy: (number | string)[];
  brand: string | null;
  model: string | null;
  itemIds: [number, string][];
  hidingSite: string | null;
  detected: string | null;
  correctiveAction: string | null;
  collaboratorName: string | null;
  collaboratorNacionality: number | null;
  collaboratorIdentity: string | null;
  collaboratorEmail: string | null;
  autorization: string | null;
  observation: string | null;
  recomendation: string | null;
}

export interface AuditoriaTest {
  id: number;
  siteTest: number;
  dateTest: string;
  timeTest: string;
  type: string;
  madeBy: number;
  madeTo: number;
  brand: string;
  model: string;
  hidingSite: string;
  detected: string;
  correctiveAction: string;
  collaboratorName: string;
  collaboratorNacionality: number;
  collaboratorIdentity: string;
  collaboratorEmail: string;
  autorization: string;
  observation: string;
  recomendation: string;
}

// ==========================================
// Flight Inspections Module Types
// ==========================================

export type InspectionOperationType = 'arrival' | 'departure' | 'none';
export type InspectionFlightType = 'D' | 'I'; // D = Domestic/National, I = International
export type InspectionCargoType = 'passenger' | 'cargo';
export type InspectionState = 'pending' | 'done';

export interface Supervisor {
  id: number;
  name: string;
}

export interface InspectionEmployee {
  id: number;
  name: string;
}

export interface Inspection {
  id: number | null;
  name: string | null;
  date: string | null;
  startTime: string | null;
  endTime: string | null;
  employee: InspectionEmployee;
  supervisors: Supervisor[];
  operation: InspectionOperationType | null;
  type: InspectionFlightType | null;
  state: InspectionState;
  flightType: InspectionCargoType | null;
  dateStr: string | null;
  planned: boolean;
  executed: boolean;
  detail?: InspectionDetail;
}

export type InspectionType = 
  | 'nationalArrival'
  | 'internationalArrival'
  | 'nationalDeparture'
  | 'internationalDeparture'
  | 'cargo';

// ==========================================
// Inspection Details - Shared Types
// ==========================================

export interface GeneralData {
  measurementDate: string | null;
  peakHour: string | null;
  flightCount: number | null;
  preparedBy: string | null;
  preparedById: number | null;
  reviewedBy: string | null;
}

export interface PublicHallData {
  time: string | null;
  paxWaitingArea: number | null;
}

export interface ObservationsData {
  eventTime: string | null;
  location: string | null;
  description: string | null;
  consequence: string | null;
}

export interface BaggageAreaData {
  belts: string | null;
  notesBelts: string | null;
  usedBeltsArea: string | null;
  claimTime1: string | null;
  paxWaitingArea1: number | null;
  claimTime2: string | null;
  paxWaitingArea2: number | null;
  claimTime3: string | null;
  paxWaitingArea3: number | null;
}

export interface BaggageTimeData {
  id: number;
  flightNumber: string | null;
  origin: string | null;
  scheduledTimeA: string | null;
  arrivalTimeB: string | null;
  firstPaxArrivalC: string | null;
  firstBagArrivalD: string | null;
  lastBagArrivalE: string | null;
  assignedBelt: string | null;
}

export interface PublicHallOption {
  id: number;
  area: string;
  occupancy: number;
}

// ==========================================
// National Arrival Types
// ==========================================

export interface NationalArrival {
  id: number | null;
  inspectionId: number;
  synced: number;
  general: GeneralData;
  publicHall: PublicHallData;
  baggageArea: BaggageAreaData;
  observations: ObservationsData;
  publicHallLines?: PublicHallOption[];
  baggageTimeLines?: BaggageTimeData[];
}

// ==========================================
// International Arrival Types
// ==========================================

export interface CustomsData {
  time: string | null;
  maqRxOper: number | null;
  kioskoPass: number | null;
  paxWaitingArea: number | null;
  offlineTime: string | null;
  waitingTimeMax: string | null;
}

export interface MigrationAreaData {
  workingCounters: number | null;
  paxWaitingArea: number | null;
  offlineTime: string | null;
}

export interface MigrationTimeData {
  attentionTimePax1: string | null;
  attentionTimePax2: string | null;
  attentionTimePax3: string | null;
  attentionTimePaxMax: string | null;
}

export interface InternationalArrival {
  id: number | null;
  inspectionId: number;
  synced: number;
  general: GeneralData;
  publicHall: PublicHallData;
  baggageArea: BaggageAreaData;
  observations: ObservationsData;
  customs: CustomsData;
  migrationAreaNational: MigrationAreaData;
  migrationTimeNational: MigrationTimeData;
  migrationAreaInternational: MigrationAreaData;
  migrationTimeInternational: MigrationTimeData;
  publicHallLines?: PublicHallOption[];
  baggageTimeLines?: BaggageTimeData[];
}

// ==========================================
// Departure Types - Shared Components
// ==========================================

export interface FlightData {
  flightCount: number | null;
  flightNumber: string | null;
  paxNumber: number | null;
  checkCounterNumber: string | null;
  preboardingRoom: string | null;
  scheduledTime: string | null;
  actualDepartureTime: string | null;
}

export interface SelfCheckinKiosksData {
  time: string | null;
  serviceTimePerPax1: string | null;
  serviceTimePerPax2: string | null;
  maximumWaitingTime: string | null;
}

export interface CheckinCounterAreaData {
  time: string | null;
  assignedCountersZone: string | null;
  assignedCounters: number | null;
  operatingCounters: number | null;
  paxWaitingArea: number | null;
  offlineTime: string | null;
}

export interface CheckinCounterTimeData {
  attentionTimePax1: string | null;
  attentionTimePax2: string | null;
  attentionTimePax3: string | null;
  attentionTimePax4: string | null;
  attentionTimePax5: string | null;
  attentionTimeMax: string | null;
}

export interface SecurityFiltersAreaData {
  time: string | null;
  operatingLanes: number | null;
  paxWaitingArea: number | null;
  offlineTime: string | null;
}

export interface SecurityFiltersTimeData {
  attentionTimePax1: string | null;
  attentionTimePax2: string | null;
  attentionTimePax3: string | null;
  attentionTimeMax: string | null;
}

export interface PreboardingData {
  id: number;
  area: string;
  used: boolean;
  usedChairs: number;
  availableChairs: number;
  usedArea: number;
  availableArea: number;
  occupancyPercentage: number;
}

// ==========================================
// National Departure Types
// ==========================================

export interface NationalDeparture {
  id: number | null;
  inspectionId: number;
  synced: number;
  general: GeneralData;
  publicHall: PublicHallData;
  flight: FlightData;
  selfCheckinKiosks: SelfCheckinKiosksData;
  checkinCounterArea: CheckinCounterAreaData;
  checkinCounterTime: CheckinCounterTimeData;
  securityFiltersArea: SecurityFiltersAreaData;
  securityFiltersTime: SecurityFiltersTimeData;
  observations: ObservationsData;
  preboardingLines?: PreboardingData[];
}

// ==========================================
// International Departure Types
// ==========================================

export interface MigrationDepartureAreaData {
  time: string | null;
  workingCounters: number | null;
  paxWaitingArea: number | null;
  offlineTime: string | null;
}

export interface MigrationDepartureTimeData {
  attentionTimePax1: string | null;
  attentionTimePax2: string | null;
  attentionTimePax3: string | null;
  attentionTimeMax: string | null;
}

export interface InternationalDeparture {
  id: number | null;
  inspectionId: number;
  synced: number;
  general: GeneralData;
  publicHall: PublicHallData;
  flight: FlightData;
  selfCheckinKiosks: SelfCheckinKiosksData;
  checkinCounterArea: CheckinCounterAreaData;
  checkinCounterTime: CheckinCounterTimeData;
  securityFiltersArea: SecurityFiltersAreaData;
  securityFiltersTime: SecurityFiltersTimeData;
  migrationArea: MigrationDepartureAreaData;
  migrationTime: MigrationDepartureTimeData;
  observations: ObservationsData;
  preboardingLines?: PreboardingData[];
}

// ==========================================
// Cargo Types
// ==========================================

export interface CargoEntry {
  id: number;
  time: string | null;
  vehicleCount: number | null;
  paxCount: number | null;
  observations: string | null;
}

export interface Cargo {
  id: number | null;
  inspectionId: number;
  synced: number;
  general: GeneralData;
  observations: ObservationsData;
  landsideEntries?: CargoEntry[];
  airsideEntries?: CargoEntry[];
}

// Unified type for inspection details
export type InspectionDetail = 
  | NationalArrival 
  | InternationalArrival 
  | NationalDeparture 
  | InternationalDeparture 
  | Cargo;

// ==========================================
// Penalties Module Types
// ==========================================

export interface PenaltyCatalog {
  id: number;
  name: string;
  amount?: number;
  parentId?: number;
}

export interface Penalty {
  id?: number;
  name?: string;
  partnerId: number;
  parentId: number;
  penaltyId: number;
  date: string;
  amount: number;
  status: string;
  observations?: string;
  synced: number; // 0 = Not synced, 1 = Synced
}

// ==========================================
// Novedades (Novelty/Ticket) Module Types
// ==========================================

export interface Novelty {
  id?: number;
  name: string;
  description: string;
  date: string;
  categoryId: number;
  criticalityId: number;
  place: string;
  inspectionId: number;
  isInspection: boolean;
  synced?: number;
}

// ==========================================
// Photo Types
// ==========================================

export interface PhotoItem {
  file: File | Blob;
  caption: string;
  dataUrl?: string; // For preview
}

export interface UploadedPhoto {
  id: number;
  url: string;
  caption: string;
}

// ==========================================
// API Response Types
// ==========================================

export interface OdooJsonRpcResponse<T = unknown> {
  jsonrpc: string;
  id: number | null;
  result?: T;
  error?: {
    code: number;
    message: string;
    data?: {
      message?: string;
      debug?: string;
    };
  };
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// ==========================================
// Sync Types
// ==========================================

export interface SyncStatus {
  lastSync: string | null;
  pendingCount: number;
  isOnline: boolean;
}

export interface PendingSyncItem {
  id: string;
  type: 'inspection' | 'test' | 'penalty' | 'novelty';
  data: unknown;
  createdAt: string;
  retryCount: number;
}
