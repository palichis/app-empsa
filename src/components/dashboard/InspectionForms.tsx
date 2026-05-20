'use client';

import { useState, useEffect } from 'react';
import { db, Inspection, NationalArrival, InternationalArrival, NationalDeparture, InternationalDeparture, CargoInspection, CargoItem, BaggageTimeDetail, DeparturePreboardingDetail, InspectionPhoto } from '@/db/indexedDB';
import { ArrowLeft, Save, Send, Camera, Trash2, CheckCircle2, User, Clock, AlertTriangle, Plus, ClipboardList } from 'lucide-react';
import { useNetwork } from '@/hooks/useNetwork';

interface InspectionFormsProps {
  inspection: Inspection;
  onClose: () => void;
  onSave: () => void;
  employees: any[];
}

export default function InspectionForms({ inspection, onClose, onSave, employees }: InspectionFormsProps) {
  const isOnline = useNetwork();
  const [activeTab, setActiveTab] = useState('general');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  // ----------------------------------------------------
  // Dynamic Form States
  // ----------------------------------------------------
  const [generalData, setGeneralData] = useState<any>({
    measurementDate: new Date().toISOString().substring(0, 10),
    hour: '',
    peakHour: '',
    flightCount: 0,
    preparedById: 0,
    preparedBy: '',
    reviewedById: 0,
    reviewedBy: '',
  });

  const [publicHall, setPublicHall] = useState({
    time: '',
    paxWaitingArea: 0,
  });

  // Arrival Specifics
  const [baggageBelts, setBaggageBelts] = useState('');
  const [notesBelts, setNotesBelts] = useState('');
  const [baggageDetails, setBaggageDetails] = useState<BaggageTimeDetail[]>([]);
  const [migrationArrival, setMigrationArrival] = useState({
    nationalCounters: 0,
    nationalPax: 0,
    nationalOffline: '',
    internationalCounters: 0,
    internationalPax: 0,
    internationalOffline: '',
  });
  const [customs, setCustoms] = useState({
    time: '',
    maqRx: 0,
    kioskos: 0,
    pax: 0,
    offlineTime: '',
    waitingMax: '',
  });

  // Departure Specifics
  const [selfCheckin, setSelfCheckin] = useState({
    time: '',
    serviceTime1: '',
    serviceTime2: '',
    maxWaiting: '',
  });
  const [checkinCounter, setCheckinCounter] = useState({
    time: '',
    assignedCounters: 0,
    operatingCounters: 0,
    pax: 0,
    offlineTime: '',
    att1: '',
    att2: '',
    att3: '',
    att4: '',
    att5: '',
    attMax: '',
  });
  const [securityFilters, setSecurityFilters] = useState({
    time: '',
    observedDomestic: 0,
    observedIntl: 0,
    observedDocs: 0,
    pax: 0,
    offlineTime: '',
    att1: '',
    att2: '',
    att3: '',
    att4: '',
    att5: '',
  });
  const [preboardingLines, setPreboardingLines] = useState<DeparturePreboardingDetail[]>([]);

  // Cargo Specifics
  const [cargoTimes, setCargoTimes] = useState({
    earthsideNational: '',
    earthsideIntl: '',
    earthsideIntlBldg: '',
    airsideNationalIntl: '',
  });
  const [cargoItems, setCargoItems] = useState<CargoItem[]>([]);

  // Observations & Photos
  const [observations, setObservations] = useState({
    eventTime: '',
    location: '',
    description: '',
    consequence: '',
  });
  const [photos, setPhotos] = useState<InspectionPhoto[]>([]);

  // ----------------------------------------------------
  // Initial Database Preloading
  // ----------------------------------------------------
  const isArrival = inspection.operation === 'arrival';
  const isDeparture = inspection.operation === 'departure';
  const isCargo = inspection.flightType === 'cargo' && inspection.operation === 'none';
  const isIntl = inspection.type === 'I';

  useEffect(() => {
    async function loadFormDetails() {
      // 1. Load General Data
      if (isArrival) {
        const table = isIntl ? db.international_arrivals : db.national_arrivals;
        const record = await table.where('inspection_id').equals(inspection.id).first();
        if (record) {
          setGeneralData({
            measurementDate: record.general_data_measurement_date || '',
            hour: record.general_data_hour || '',
            peakHour: record.general_data_peak_hour || '',
            flightCount: record.general_data_flight_count || 0,
            preparedById: record.general_data_prepared_by_id || 0,
            preparedBy: record.general_data_prepared_by || '',
            reviewedById: record.general_data_reviewed_by_id || 0,
            reviewedBy: record.general_data_reviewed_by || '',
          });
          setPublicHall({
            time: record.public_hall_time || '',
            paxWaitingArea: record.public_hall_pax_waiting_area || 0,
          });
          setBaggageBelts(record.baggage_claim_belts || '');
          setNotesBelts(record.notes_belts || '');
          setObservations({
            eventTime: record.observations_event_time || '',
            location: record.observations_location || '',
            description: record.observations_description || '',
            consequence: record.observations_consequence || '',
          });

          if (isIntl) {
            const intlRec = record as InternationalArrival;
            setMigrationArrival({
              nationalCounters: intlRec.migration_area_national_working_counters || 0,
              nationalPax: intlRec.migration_area_national_pax_waiting_area || 0,
              nationalOffline: intlRec.migration_area_national_offline_time || '',
              internationalCounters: intlRec.migration_area_international_working_counters || 0,
              internationalPax: intlRec.migration_area_international_pax_waiting_area || 0,
              internationalOffline: intlRec.migration_area_international_offline_time || '',
            });
            setCustoms({
              time: intlRec.customs_time || '',
              maqRx: intlRec.customs_maq_rx_oper || 0,
              kioskos: intlRec.customs_kiosko_pass || 0,
              pax: intlRec.customs_pax_waiting_area || 0,
              offlineTime: intlRec.customs_offline_time || '',
              waitingMax: intlRec.customs_waiting_time_max || '',
            });
          }
        }

        // Load Baggage Claim Lines
        const bagLines = await db.arrival_baggage_time_details
          .where(isIntl ? 'international_arrival_id' : 'national_arrival_id')
          .equals(inspection.id)
          .toArray();
        setBaggageDetails(bagLines);
      } else if (isDeparture) {
        const table = isIntl ? db.international_departures : db.national_departures;
        const record = await table.where('inspection_id').equals(inspection.id).first();
        if (record) {
          setGeneralData({
            measurementDate: record.general_data_measurement_date || '',
            hour: record.general_data_hour || '',
            peakHour: record.general_data_peak_hour || '',
            flightCount: record.general_data_flight_count || 0,
            preparedById: record.general_data_prepared_by_id || 0,
            preparedBy: record.general_data_prepared_by || '',
            reviewedById: record.general_data_reviewed_by_id || 0,
            reviewedBy: record.general_data_reviewed_by || '',
          });
          setPublicHall({
            time: record.public_hall_time || '',
            paxWaitingArea: record.public_hall_pax_waiting_area || 0,
          });
          setSelfCheckin({
            time: record.self_checkin_kiosks_time || '',
            serviceTime1: record.self_checkin_kiosks_service_time_per_pax_1 || '',
            serviceTime2: record.self_checkin_kiosks_service_time_per_pax_2 || '',
            maxWaiting: record.self_checkin_kiosks_maximum_waiting_time || '',
          });
          setCheckinCounter({
            time: record.checkin_counter_time || '',
            assignedCounters: record.checkin_counter_assigned_counters || 0,
            operatingCounters: record.checkin_counter_operating_counters || 0,
            pax: record.checkin_counter_pax_waiting_area || 0,
            offlineTime: record.checkin_counter_offline_time || '',
            att1: record.checkin_counter_attention_time_per_pax_1 || '',
            att2: record.checkin_counter_attention_time_per_pax_2 || '',
            att3: record.checkin_counter_attention_time_per_pax_3 || '',
            att4: record.checkin_counter_attention_time_per_pax_4 || '',
            att5: record.checkin_counter_attention_time_per_pax_5 || '',
            attMax: record.checkin_counter_attention_time_per_pax_max || '',
          });
          setSecurityFilters({
            time: record.security_filters_time || '',
            observedDomestic: record.security_filters_observed_domestic_operators || 0,
            observedIntl: record.security_filters_observed_international_operators || 0,
            observedDocs: record.security_filters_observed_document_review_agents || 0,
            pax: record.security_filters_pax_waiting_area || 0,
            offlineTime: record.security_filters_offline_time || '',
            att1: record.security_filters_attention_time_per_pax_1 || '',
            att2: record.security_filters_attention_time_per_pax_2 || '',
            att3: record.security_filters_attention_time_per_pax_3 || '',
            att4: record.security_filters_attention_time_per_pax_4 || '',
            att5: record.security_filters_attention_time_per_pax_5 || '',
          });
          setObservations({
            eventTime: record.observations_event_time || '',
            location: record.observations_location || '',
            description: record.observations_description || '',
            consequence: record.observations_consequence || '',
          });
        }

        // Load Preboarding lines
        const prebLines = await db.departures_preboarding_details
          .where(isIntl ? 'international_departure_id' : 'national_departure_id')
          .equals(inspection.id)
          .toArray();
        setPreboardingLines(prebLines);
      } else if (isCargo) {
        const record = await db.cargo_inspections.where('inspection_id').equals(inspection.id).first();
        if (record) {
          setGeneralData({
            measurementDate: record.general_data_measurement_date || '',
            hour: record.general_data_hour || '',
            preparedById: record.general_data_prepared_by_id || 0,
            preparedBy: record.general_data_prepared_by || '',
            reviewedById: record.general_data_reviewed_by_id || 0,
            reviewedBy: record.general_data_reviewed_by || '',
          });
          setCargoTimes({
            earthsideNational: record.earthside_national_hour || '',
            earthsideIntl: record.earthside_international_hour || '',
            earthsideIntlBldg: record.earthside_international_building_hour || '',
            airsideNationalIntl: record.airside_national_international_hour || '',
          });
        }

        // Load cargo items
        const cItems = await db.cargo_items.where('cargo_id').equals(inspection.id).toArray();
        if (cItems.length > 0) {
          setCargoItems(cItems);
        } else {
          // Initialize cargo checklist checkpoints default if none exists
          const defaults: Partial<CargoItem>[] = [
            { parent: 'landside', sequence: 1, name: 'Control de Acceso Terrestre', qualification: 'Satisfactorio', note: '' },
            { parent: 'landside', sequence: 2, name: 'Uso de EPP de Seguridad', qualification: 'Satisfactorio', note: '' },
            { parent: 'landside', sequence: 3, name: 'Registro de Vehículos de Carga', qualification: 'Satisfactorio', note: '' },
            { parent: 'airside', sequence: 4, name: 'Inspección Física de Carga Aérea', qualification: 'Satisfactorio', note: '' },
            { parent: 'airside', sequence: 5, name: 'Control de Seguridad de Rampa', qualification: 'Satisfactorio', note: '' },
          ];
          const initialItems: CargoItem[] = [];
          for (const item of defaults) {
            const finalItem = { ...item, cargo_id: inspection.id, synced: 0 } as CargoItem;
            const id = await db.cargo_items.add(finalItem);
            initialItems.push({ ...finalItem, id });
          }
          setCargoItems(initialItems);
        }
      }

      // Load Photos
      const insPhotos = await db.inspection_photos.where('inspection_id').equals(inspection.id).toArray();
      setPhotos(insPhotos);
    }

    loadFormDetails();
  }, [inspection.id, isArrival, isDeparture, isCargo, isIntl]);

  // ----------------------------------------------------
  // Form Mutations Handlers
  // ----------------------------------------------------
  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files) return;
    const files = Array.from(e.target.files);

    files.forEach(file => {
      const reader = new FileReader();
      reader.onload = async () => {
        const base64 = reader.result as string;
        const newPhoto: InspectionPhoto = {
          inspection_id: inspection.id,
          section: activeTab,
          path: base64,
          caption: '',
          timestamp: new Date().toISOString(),
          synced: 0,
        };
        const photoId = await db.inspection_photos.add(newPhoto);
        setPhotos(prev => [...prev, { ...newPhoto, id: photoId }]);
      };
      reader.readAsDataURL(file);
    });
  };

  const handlePhotoDelete = async (photoId: number) => {
    await db.inspection_photos.delete(photoId);
    setPhotos(prev => prev.filter(p => p.id !== photoId));
  };

  const handlePhotoCaptionChange = async (photoId: number, caption: string) => {
    await db.inspection_photos.update(photoId, { caption });
    setPhotos(prev => prev.map(p => p.id === photoId ? { ...p, caption } : p));
  };

  // Baggage details handlers
  const handleAddBaggageLine = async () => {
    const newLine: BaggageTimeDetail = {
      national_arrival_id: isIntl ? undefined : inspection.id,
      international_arrival_id: isIntl ? inspection.id : undefined,
      flight_number: '',
      origin: '',
      scheduled_time_a_hhmm: '',
      arrival_time_b_hhmm: '',
      assigned_belt: '',
      first_pax_arrival_c_hhmm: '',
      first_bag_arrival_d_hhmm: '',
      last_bag_arrival_e_hhmm: '',
      synced: 0,
    };
    const id = await db.arrival_baggage_time_details.add(newLine);
    setBaggageDetails(prev => [...prev, { ...newLine, id }]);
  };

  const handleUpdateBaggageLine = async (id: number, field: keyof BaggageTimeDetail, value: any) => {
    await db.arrival_baggage_time_details.update(id, { [field]: value });
    setBaggageDetails(prev => prev.map(line => line.id === id ? { ...line, [field]: value } : line));
  };

  const handleDeleteBaggageLine = async (id: number) => {
    await db.arrival_baggage_time_details.delete(id);
    setBaggageDetails(prev => prev.filter(line => line.id !== id));
  };

  // Cargo Checklist qualifiers
  const handleCargoQualifyChange = async (id: number, field: 'qualification' | 'note', value: string) => {
    await db.cargo_items.update(id, { [field]: value });
    setCargoItems(prev => prev.map(item => item.id === id ? { ...item, [field]: value } : item));
  };

  // ----------------------------------------------------
  // Save & Sync Pipelines
  // ----------------------------------------------------
  const saveToLocalDB = async (finalStatus: 'En progreso' | 'Finalizada') => {
    // Save Inspection status
    await db.inspections.update(inspection.id, { status: finalStatus });

    const sharedGeneral = {
      general_data_measurement_date: generalData.measurementDate,
      general_data_hour: generalData.hour,
      general_data_peak_hour: generalData.peakHour,
      general_data_flight_count: parseInt(generalData.flightCount) || 0,
      general_data_prepared_by_id: parseInt(generalData.preparedById) || 0,
      general_data_prepared_by: generalData.preparedBy,
      general_data_reviewed_by_id: parseInt(generalData.reviewedById) || 0,
      general_data_reviewed_by: generalData.reviewedBy,
      public_hall_time: publicHall.time,
      public_hall_pax_waiting_area: parseInt(publicHall.paxWaitingArea as any) || 0,
      observations_event_time: observations.eventTime,
      observations_location: observations.location,
      observations_description: observations.description,
      observations_consequence: observations.consequence,
      synced: 0,
    };

    let fullData: any = { ...sharedGeneral };

    if (isArrival) {
      const record = {
        ...sharedGeneral,
        inspection_id: inspection.id,
        baggage_claim_belts: baggageBelts,
        notes_belts: notesBelts,
      };

      if (isIntl) {
        const intlRecord = {
          ...record,
          migration_area_national_working_counters: migrationArrival.nationalCounters,
          migration_area_national_pax_waiting_area: migrationArrival.nationalPax,
          migration_area_national_offline_time: migrationArrival.nationalOffline,
          migration_area_international_working_counters: migrationArrival.internationalCounters,
          migration_area_international_pax_waiting_area: migrationArrival.internationalPax,
          migration_area_international_offline_time: migrationArrival.internationalOffline,
          customs_time: customs.time,
          customs_maq_rx_oper: customs.maqRx,
          customs_kiosko_pass: customs.kioskos,
          customs_pax_waiting_area: customs.pax,
          customs_offline_time: customs.offlineTime,
          customs_waiting_time_max: customs.waitingMax,
        };
        await db.international_arrivals.put({ ...intlRecord, id: inspection.id });
        fullData = intlRecord;
      } else {
        await db.national_arrivals.put({ ...record, id: inspection.id });
        fullData = record;
      }
    } else if (isDeparture) {
      const record = {
        ...sharedGeneral,
        inspection_id: inspection.id,
        self_checkin_kiosks_time: selfCheckin.time,
        self_checkin_kiosks_service_time_per_pax_1: selfCheckin.serviceTime1,
        self_checkin_kiosks_service_time_per_pax_2: selfCheckin.serviceTime2,
        self_checkin_kiosks_maximum_waiting_time: selfCheckin.maxWaiting,
        checkin_counter_time: checkinCounter.time,
        checkin_counter_assigned_counters: checkinCounter.assignedCounters,
        checkin_counter_operating_counters: checkinCounter.operatingCounters,
        checkin_counter_pax_waiting_area: checkinCounter.pax,
        checkin_counter_offline_time: checkinCounter.offlineTime,
        checkin_counter_attention_time_per_pax_1: checkinCounter.att1,
        checkin_counter_attention_time_per_pax_2: checkinCounter.att2,
        checkin_counter_attention_time_per_pax_3: checkinCounter.att3,
        checkin_counter_attention_time_per_pax_4: checkinCounter.att4,
        checkin_counter_attention_time_per_pax_5: checkinCounter.att5,
        checkin_counter_attention_time_per_pax_max: checkinCounter.attMax,
        security_filters_time: securityFilters.time,
        security_filters_observed_domestic_operators: securityFilters.observedDomestic,
        security_filters_observed_international_operators: securityFilters.observedIntl,
        security_filters_observed_document_review_agents: securityFilters.observedDocs,
        security_filters_pax_waiting_area: securityFilters.pax,
        security_filters_offline_time: securityFilters.offlineTime,
        security_filters_attention_time_per_pax_1: securityFilters.att1,
        security_filters_attention_time_per_pax_2: securityFilters.att2,
        security_filters_attention_time_per_pax_3: securityFilters.att3,
        security_filters_attention_time_per_pax_4: securityFilters.att4,
        security_filters_attention_time_per_pax_5: securityFilters.att5,
      };

      if (isIntl) {
        const intlRecord = {
          ...record,
          // International departures specific maps could go here
        };
        await db.international_departures.put({ ...intlRecord, id: inspection.id });
        fullData = intlRecord;
      } else {
        await db.national_departures.put({ ...record, id: inspection.id });
        fullData = record;
      }
    } else if (isCargo) {
      const record = {
        inspection_id: inspection.id,
        general_data_measurement_date: generalData.measurementDate,
        general_data_hour: generalData.hour,
        general_data_prepared_by_id: parseInt(generalData.preparedById) || 0,
        general_data_prepared_by: generalData.preparedBy,
        general_data_reviewed_by_id: parseInt(generalData.reviewedById) || 0,
        general_data_reviewed_by: generalData.reviewedBy,
        earthside_national_hour: cargoTimes.earthsideNational,
        earthside_international_hour: cargoTimes.earthsideIntl,
        earthside_international_building_hour: cargoTimes.earthsideIntlBldg,
        airside_national_international_hour: cargoTimes.airsideNationalIntl,
        synced: 0,
      };
      await db.cargo_inspections.put({ ...record, id: inspection.id });
      fullData = record;
    }

    return fullData;
  };

  const handleSaveDraft = async () => {
    setLoading(true);
    await saveToLocalDB('En progreso');
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      onSave();
    }, 1000);
  };

  const handleSubmitInspection = async () => {
    setLoading(true);
    const savedData = await saveToLocalDB('Finalizada');

    // Queue operational sync mutation
    const mutation = {
      type: 'sync_control',
      inspectionId: inspection.id,
      payload: {
        id: inspection.id,
        operation: inspection.operation,
        type: inspection.type,
        flight_type: inspection.flightType,
        detail: savedData,
        baggage_lines: isArrival ? baggageDetails : [],
        preboarding_lines: isDeparture ? preboardingLines : [],
        cargo_items: isCargo ? cargoItems : [],
      },
      timestamp: Date.now(),
      status: 'pending',
    };
    await db.mutations.add(mutation);

    // Queue photo sync mutation if present
    if (photos.length > 0) {
      await db.mutations.add({
        type: 'sync_photos',
        inspectionId: inspection.id,
        payload: {
          inspection_id: inspection.id,
          photo_count: photos.length,
          photos: photos.map(p => ({ filename: `photo_${p.id}.png`, caption: p.caption, base64: p.path.split(',')[1] })),
        },
        timestamp: Date.now(),
        status: 'pending',
      });
    }

    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      onSave();
    }, 1000);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 shadow-xl max-w-5xl mx-auto animate-fade-in space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-slate-800">
        <button
          onClick={onClose}
          className="flex items-center space-x-1.5 text-xs text-slate-400 hover:text-slate-200 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Volver a Asignaciones</span>
        </button>
        <div className="text-center">
          <h3 className="text-sm font-bold text-white uppercase">
            Inspección de {isCargo ? 'Carga' : isArrival ? 'Arribos' : 'Salidas'} ({isIntl ? 'Internacional' : 'Nacional'})
          </h3>
          <span className="text-[10px] text-slate-500">ID Inspección: {inspection.id}</span>
        </div>
        <div className="w-20"></div>
      </div>

      {success && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/25 text-emerald-300 text-sm rounded-lg flex items-center space-x-2">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span>¡Guardado con éxito! Listo para la cola de sincronización.</span>
        </div>
      )}

      {/* Dynamic Tab Navigation */}
      <div className="flex flex-wrap border-b border-slate-800 text-xs">
        <button
          onClick={() => setActiveTab('general')}
          className={`px-4 py-2 font-semibold ${activeTab === 'general' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
        >
          Datos Generales
        </button>
        {!isCargo && (
          <button
            onClick={() => setActiveTab('public_hall')}
            className={`px-4 py-2 font-semibold ${activeTab === 'public_hall' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
          >
            Hall Público
          </button>
        )}
        {isArrival && (
          <button
            onClick={() => setActiveTab('baggage')}
            className={`px-4 py-2 font-semibold ${activeTab === 'baggage' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
          >
            Reclamo de Equipaje
          </button>
        )}
        {isArrival && isIntl && (
          <>
            <button
              onClick={() => setActiveTab('migration')}
              className={`px-4 py-2 font-semibold ${activeTab === 'migration' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Migración
            </button>
            <button
              onClick={() => setActiveTab('customs')}
              className={`px-4 py-2 font-semibold ${activeTab === 'customs' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Aduanas
            </button>
          </>
        )}
        {isDeparture && (
          <>
            <button
              onClick={() => setActiveTab('self_checkin')}
              className={`px-4 py-2 font-semibold ${activeTab === 'self_checkin' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Auto Check-in
            </button>
            <button
              onClick={() => setActiveTab('checkin_counter')}
              className={`px-4 py-2 font-semibold ${activeTab === 'checkin_counter' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Mostradores
            </button>
            <button
              onClick={() => setActiveTab('security_filters')}
              className={`px-4 py-2 font-semibold ${activeTab === 'security_filters' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Filtros Seguridad
            </button>
            <button
              onClick={() => setActiveTab('preboarding')}
              className={`px-4 py-2 font-semibold ${activeTab === 'preboarding' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Preembarque
            </button>
          </>
        )}
        {isCargo && (
          <>
            <button
              onClick={() => setActiveTab('cargo_landside')}
              className={`px-4 py-2 font-semibold ${activeTab === 'cargo_landside' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Carga Terrestre
            </button>
            <button
              onClick={() => setActiveTab('cargo_airside')}
              className={`px-4 py-2 font-semibold ${activeTab === 'cargo_airside' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
            >
              Carga Aérea
            </button>
          </>
        )}
        <button
          onClick={() => setActiveTab('observations')}
          className={`px-4 py-2 font-semibold ${activeTab === 'observations' ? 'border-b-2 border-indigo-500 text-white bg-indigo-500/5' : 'text-slate-400 hover:text-slate-200'}`}
        >
          Observaciones y Fotos
        </button>
      </div>

      {/* Tab Contents */}
      <div className="p-2 space-y-4 text-xs">
        {/* GENERAL TAB */}
        {activeTab === 'general' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Fecha de Medición</label>
                <input
                  type="date"
                  value={generalData.measurementDate}
                  onChange={e => setGeneralData({ ...generalData, measurementDate: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>

              {!isCargo && (
                <div>
                  <label className="block text-slate-400 mb-1">Hora Pico</label>
                  <input
                    type="time"
                    value={generalData.peakHour}
                    onChange={e => setGeneralData({ ...generalData, peakHour: e.target.value })}
                    className="glass-input w-full p-2"
                  />
                </div>
              )}

              {isCargo && (
                <div>
                  <label className="block text-slate-400 mb-1">Hora de Inspección</label>
                  <input
                    type="time"
                    value={generalData.hour}
                    onChange={e => setGeneralData({ ...generalData, hour: e.target.value })}
                    className="glass-input w-full p-2"
                  />
                </div>
              )}
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Inspector Asignado</label>
                <select
                  value={generalData.preparedById}
                  onChange={e => {
                    const emp = employees.find(emp => emp.id === parseInt(e.target.value));
                    setGeneralData({
                      ...generalData,
                      preparedById: parseInt(e.target.value),
                      preparedBy: emp ? emp.name : '',
                    });
                  }}
                  className="glass-input w-full p-2 bg-slate-900"
                >
                  <option value={0}>Selecciona Inspector...</option>
                  {employees.map(emp => (
                    <option key={emp.id} value={emp.id}>{emp.name}</option>
                  ))}
                </select>
              </div>

              {!isCargo && (
                <div>
                  <label className="block text-slate-400 mb-1">Número de Vuelos en Período</label>
                  <input
                    type="number"
                    value={generalData.flightCount}
                    onChange={e => setGeneralData({ ...generalData, flightCount: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-2"
                  />
                </div>
              )}
            </div>
          </div>
        )}

        {/* PUBLIC HALL TAB */}
        {activeTab === 'public_hall' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-slate-400 mb-1">Hora de Medición en Hall Público</label>
              <input
                type="time"
                value={publicHall.time}
                onChange={e => setPublicHall({ ...publicHall, time: e.target.value })}
                className="glass-input w-full p-2"
              />
            </div>
            <div>
              <label className="block text-slate-400 mb-1">Pasajeros en Espera (Conteo)</label>
              <input
                type="number"
                value={publicHall.paxWaitingArea}
                onChange={e => setPublicHall({ ...publicHall, paxWaitingArea: parseInt(e.target.value) || 0 })}
                className="glass-input w-full p-2"
              />
            </div>
          </div>
        )}

        {/* BAGGAGE TAB */}
        {activeTab === 'baggage' && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-slate-400 mb-1">Cintas Utilizadas (IDs separados por coma)</label>
                <input
                  type="text"
                  placeholder="Ej. C1, C2, C3"
                  value={baggageBelts}
                  onChange={e => setBaggageBelts(e.target.value)}
                  className="glass-input w-full p-2"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Notas de Cintas</label>
                <input
                  type="text"
                  placeholder="Observaciones de fajas..."
                  value={notesBelts}
                  onChange={e => setNotesBelts(e.target.value)}
                  className="glass-input w-full p-2"
                />
              </div>
            </div>

            <div className="flex justify-between items-center pt-2">
              <h4 className="font-bold text-indigo-400">Detalles de Tiempos de Equipaje</h4>
              <button
                onClick={handleAddBaggageLine}
                className="px-3 py-1 bg-indigo-650 hover:bg-indigo-600 rounded text-xs flex items-center space-x-1 font-semibold transition-colors"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Agregar Vuelo</span>
              </button>
            </div>

            <div className="overflow-x-auto border border-slate-800 rounded-lg">
              <table className="w-full text-[10px] text-left border-collapse bg-slate-950/20">
                <thead>
                  <tr className="bg-slate-900/60 text-slate-400 uppercase tracking-wider font-semibold border-b border-slate-800">
                    <th className="p-2.5">Vuelo</th>
                    <th className="p-2.5">Origen</th>
                    <th className="p-2.5">Sch. Time (A)</th>
                    <th className="p-2.5">Arr. Time (B)</th>
                    <th className="p-2.5">Faja</th>
                    <th className="p-2.5">1st Pax (C)</th>
                    <th className="p-2.5">1st Bag (D)</th>
                    <th className="p-2.5">Last Bag (E)</th>
                    <th className="p-2.5 text-center">Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {baggageDetails.length === 0 ? (
                    <tr>
                      <td colSpan={9} className="p-4 text-center text-slate-500 italic">No hay vuelos registrados en el periodo.</td>
                    </tr>
                  ) : (
                    baggageDetails.map(line => (
                      <tr key={line.id} className="border-b border-slate-850 hover:bg-slate-850/30">
                        <td className="p-1">
                          <input
                            type="text"
                            placeholder="EQ 312"
                            value={line.flight_number || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'flight_number', e.target.value)}
                            className="glass-input p-1 w-16"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="text"
                            placeholder="UIO"
                            value={line.origin || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'origin', e.target.value)}
                            className="glass-input p-1 w-14"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="time"
                            value={line.scheduled_time_a_hhmm || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'scheduled_time_a_hhmm', e.target.value)}
                            className="glass-input p-1 w-18"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="time"
                            value={line.arrival_time_b_hhmm || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'arrival_time_b_hhmm', e.target.value)}
                            className="glass-input p-1 w-18"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="text"
                            placeholder="3"
                            value={line.assigned_belt || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'assigned_belt', e.target.value)}
                            className="glass-input p-1 w-10 text-center"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="time"
                            value={line.first_pax_arrival_c_hhmm || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'first_pax_arrival_c_hhmm', e.target.value)}
                            className="glass-input p-1 w-18"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="time"
                            value={line.first_bag_arrival_d_hhmm || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'first_bag_arrival_d_hhmm', e.target.value)}
                            className="glass-input p-1 w-18"
                          />
                        </td>
                        <td className="p-1">
                          <input
                            type="time"
                            value={line.last_bag_arrival_e_hhmm || ''}
                            onChange={e => handleUpdateBaggageLine(line.id!, 'last_bag_arrival_e_hhmm', e.target.value)}
                            className="glass-input p-1 w-18"
                          />
                        </td>
                        <td className="p-1 text-center">
                          <button
                            onClick={() => handleDeleteBaggageLine(line.id!)}
                            className="text-rose-400 hover:text-rose-300 p-1"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* MIGRATION (ARRIVALS) TAB */}
        {activeTab === 'migration' && (
          <div className="space-y-4">
            <h4 className="font-bold text-indigo-400 uppercase tracking-wider text-[10px]">Cajas de Control Migratorio (Arribos)</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="p-4 bg-slate-950/20 border border-slate-800 rounded-lg space-y-3">
                <span className="font-bold text-slate-200 block border-b border-slate-800 pb-1">Ventanillas Nacionales</span>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-400 mb-0.5">Activas</label>
                    <input
                      type="number"
                      value={migrationArrival.nationalCounters}
                      onChange={e => setMigrationArrival({ ...migrationArrival, nationalCounters: parseInt(e.target.value) || 0 })}
                      className="glass-input w-full p-2"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 mb-0.5">Pasajeros Espera</label>
                    <input
                      type="number"
                      value={migrationArrival.nationalPax}
                      onChange={e => setMigrationArrival({ ...migrationArrival, nationalPax: parseInt(e.target.value) || 0 })}
                      className="glass-input w-full p-2"
                    />
                  </div>
                </div>
              </div>

              <div className="p-4 bg-slate-950/20 border border-slate-800 rounded-lg space-y-3">
                <span className="font-bold text-slate-200 block border-b border-slate-800 pb-1">Ventanillas Internacionales</span>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-400 mb-0.5">Activas</label>
                    <input
                      type="number"
                      value={migrationArrival.internationalCounters}
                      onChange={e => setMigrationArrival({ ...migrationArrival, internationalCounters: parseInt(e.target.value) || 0 })}
                      className="glass-input w-full p-2"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 mb-0.5">Pasajeros Espera</label>
                    <input
                      type="number"
                      value={migrationArrival.internationalPax}
                      onChange={e => setMigrationArrival({ ...migrationArrival, internationalPax: parseInt(e.target.value) || 0 })}
                      className="glass-input w-full p-2"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* CUSTOMS TAB */}
        {activeTab === 'customs' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Hora de Inspección Aduana</label>
                <input
                  type="time"
                  value={customs.time}
                  onChange={e => setCustoms({ ...customs, time: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-400 mb-1">Máquinas RX Operando</label>
                  <input
                    type="number"
                    value={customs.maqRx}
                    onChange={e => setCustoms({ ...customs, maqRx: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-2"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Kioskos Pasaporte</label>
                  <input
                    type="number"
                    value={customs.kioskos}
                    onChange={e => setCustoms({ ...customs, kioskos: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-2"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Pasajeros en Fila Esperando</label>
                <input
                  type="number"
                  value={customs.pax}
                  onChange={e => setCustoms({ ...customs, pax: parseInt(e.target.value) || 0 })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Tiempo de Espera Máximo (minutos)</label>
                <input
                  type="text"
                  placeholder="Ej. 12"
                  value={customs.waitingMax}
                  onChange={e => setCustoms({ ...customs, waitingMax: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
            </div>
          </div>
        )}

        {/* SELF CHECK-IN (DEPARTURES) TAB */}
        {activeTab === 'self_checkin' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Hora de Auditoría Auto Check-in</label>
                <input
                  type="time"
                  value={selfCheckin.time}
                  onChange={e => setSelfCheckin({ ...selfCheckin, time: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Tiempo Servicio Pax 1 (s)</label>
                <input
                  type="text"
                  placeholder="Ej. 45"
                  value={selfCheckin.serviceTime1}
                  onChange={e => setSelfCheckin({ ...selfCheckin, serviceTime1: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Tiempo Servicio Pax 2 (s)</label>
                <input
                  type="text"
                  placeholder="Ej. 55"
                  value={selfCheckin.serviceTime2}
                  onChange={e => setSelfCheckin({ ...selfCheckin, serviceTime2: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Tiempo de Espera Máximo (min)</label>
                <input
                  type="text"
                  placeholder="Ej. 5"
                  value={selfCheckin.maxWaiting}
                  onChange={e => setSelfCheckin({ ...selfCheckin, maxWaiting: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
            </div>
          </div>
        )}

        {/* CHECK-IN COUNTERS TAB */}
        {activeTab === 'checkin_counter' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Hora Auditoría Mostradores</label>
                <input
                  type="time"
                  value={checkinCounter.time}
                  onChange={e => setCheckinCounter({ ...checkinCounter, time: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-400 mb-1">Mostradores Asignados</label>
                  <input
                    type="number"
                    value={checkinCounter.assignedCounters}
                    onChange={e => setCheckinCounter({ ...checkinCounter, assignedCounters: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-2"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Mostradores Operando</label>
                  <input
                    type="number"
                    value={checkinCounter.operatingCounters}
                    onChange={e => setCheckinCounter({ ...checkinCounter, operatingCounters: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-2"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Pasajeros Espera Mostradores</label>
                <input
                  type="number"
                  value={checkinCounter.pax}
                  onChange={e => setCheckinCounter({ ...checkinCounter, pax: parseInt(e.target.value) || 0 })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">Tiempos Atención Muestra (segundos, sep. por comas)</label>
                <input
                  type="text"
                  placeholder="Ej. 120, 150, 90"
                  value={checkinCounter.attMax}
                  onChange={e => setCheckinCounter({ ...checkinCounter, attMax: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
            </div>
          </div>
        )}

        {/* SECURITY FILTERS TAB */}
        {activeTab === 'security_filters' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Hora Auditoría Filtros</label>
                <input
                  type="time"
                  value={securityFilters.time}
                  onChange={e => setSecurityFilters({ ...securityFilters, time: e.target.value })}
                  className="glass-input w-full p-2"
                />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-slate-400 text-[10px] mb-0.5">Operadores Nal.</label>
                  <input
                    type="number"
                    value={securityFilters.observedDomestic}
                    onChange={e => setSecurityFilters({ ...securityFilters, observedDomestic: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-1.5"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 text-[10px] mb-0.5">Operadores Intl.</label>
                  <input
                    type="number"
                    value={securityFilters.observedIntl}
                    onChange={e => setSecurityFilters({ ...securityFilters, observedIntl: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-1.5"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 text-[10px] mb-0.5">Agentes Rev.</label>
                  <input
                    type="number"
                    value={securityFilters.observedDocs}
                    onChange={e => setSecurityFilters({ ...securityFilters, observedDocs: parseInt(e.target.value) || 0 })}
                    className="glass-input w-full p-1.5"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-slate-400 mb-1">Pasajeros en Espera Filtro</label>
                <input
                  type="number"
                  value={securityFilters.pax}
                  onChange={e => setSecurityFilters({ ...securityFilters, pax: parseInt(e.target.value) || 0 })}
                  className="glass-input w-full p-2"
                />
              </div>
            </div>
          </div>
        )}

        {/* PREBOARDING TAB */}
        {activeTab === 'preboarding' && (
          <div className="space-y-4">
            <h4 className="font-bold text-indigo-400">Salas de Preembarque</h4>
            <p className="text-slate-500 text-[10px] italic">Muestra la capacidad y ocupación de las salas preembarque asignadas.</p>
            {/* Display list of preboarding rooms loaded */}
            {preboardingLines.length === 0 ? (
              <p className="text-slate-500 text-center py-4 italic border border-slate-800 rounded">No se pre-cargaron salas para esta salida.</p>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {preboardingLines.map(line => (
                  <div key={line.id} className="p-3 bg-slate-950/20 border border-slate-850 rounded-lg space-y-2 text-xs">
                    <span className="font-bold text-slate-200 block border-b border-slate-800 pb-1">Sala: {line.area}</span>
                    <div className="grid grid-cols-3 gap-2 text-[10px]">
                      <div>
                        <span className="block text-slate-500">Chairs Used</span>
                        <input
                          type="number"
                          value={line.used_chairs}
                          onChange={async e => {
                            const val = parseInt(e.target.value) || 0;
                            await db.departures_preboarding_details.update(line.id!, { used_chairs: val });
                            setPreboardingLines(prev => prev.map(p => p.id === line.id ? { ...p, used_chairs: val } : p));
                          }}
                          className="glass-input w-full p-1"
                        />
                      </div>
                      <div>
                        <span className="block text-slate-500">Chairs Avail</span>
                        <input
                          type="number"
                          value={line.available_chairs}
                          onChange={async e => {
                            const val = parseInt(e.target.value) || 0;
                            await db.departures_preboarding_details.update(line.id!, { available_chairs: val });
                            setPreboardingLines(prev => prev.map(p => p.id === line.id ? { ...p, available_chairs: val } : p));
                          }}
                          className="glass-input w-full p-1"
                        />
                      </div>
                      <div>
                        <span className="block text-slate-500">Occupancy %</span>
                        <span className="block p-1 text-slate-200 text-center font-bold">
                          {line.available_chairs + line.used_chairs > 0
                            ? Math.round((line.used_chairs / (line.available_chairs + line.used_chairs)) * 100)
                            : 0}%
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* CARGO CHECKLIST TABS */}
        {activeTab === 'cargo_landside' && (
          <div className="space-y-3">
            <h4 className="font-bold text-indigo-400 uppercase tracking-wider text-[10px]">Puntos de Control: Landside (Terrestre)</h4>
            <div className="space-y-2 border border-slate-800 rounded-lg overflow-hidden">
              {cargoItems.filter(i => i.parent === 'landside').map(item => (
                <div key={item.id} className="p-3 bg-slate-950/20 border-b border-slate-850 flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <div className="flex-1">
                    <span className="font-bold text-slate-200 text-xs block">{item.name}</span>
                  </div>
                  <div className="flex items-center space-x-3 text-xs">
                    <select
                      value={item.qualification}
                      onChange={e => handleCargoQualifyChange(item.id!, 'qualification', e.target.value)}
                      className="glass-input p-1 bg-slate-900 text-[11px] w-32"
                    >
                      <option value="Satisfactorio">Satisfactorio</option>
                      <option value="Poco satisfactorio">Poco satisfactorio</option>
                      <option value="No cumple">No cumple</option>
                      <option value="No aplica">No aplica</option>
                      <option value="No observado">No observado</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Nota / Observación..."
                      value={item.note}
                      onChange={e => handleCargoQualifyChange(item.id!, 'note', e.target.value)}
                      className="glass-input p-1 text-[11px] w-52"
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'cargo_airside' && (
          <div className="space-y-3">
            <h4 className="font-bold text-indigo-400 uppercase tracking-wider text-[10px]">Puntos de Control: Airside (Lado Aire)</h4>
            <div className="space-y-2 border border-slate-800 rounded-lg overflow-hidden">
              {cargoItems.filter(i => i.parent === 'airside').map(item => (
                <div key={item.id} className="p-3 bg-slate-950/20 border-b border-slate-850 flex flex-col md:flex-row md:items-center justify-between gap-3">
                  <div className="flex-1">
                    <span className="font-bold text-slate-200 text-xs block">{item.name}</span>
                  </div>
                  <div className="flex items-center space-x-3 text-xs">
                    <select
                      value={item.qualification}
                      onChange={e => handleCargoQualifyChange(item.id!, 'qualification', e.target.value)}
                      className="glass-input p-1 bg-slate-900 text-[11px] w-32"
                    >
                      <option value="Satisfactorio">Satisfactorio</option>
                      <option value="Poco satisfactorio">Poco satisfactorio</option>
                      <option value="No cumple">No cumple</option>
                      <option value="No aplica">No aplica</option>
                      <option value="No observado">No observado</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Nota / Observación..."
                      value={item.note}
                      onChange={e => handleCargoQualifyChange(item.id!, 'note', e.target.value)}
                      className="glass-input p-1 text-[11px] w-52"
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* OBSERVATIONS & PHOTOS TAB */}
        {activeTab === 'observations' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <h4 className="font-bold text-indigo-400 uppercase tracking-wider text-[10px] pb-1 border-b border-slate-850">Observaciones Generales</h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-400 mb-1">Hora Suceso</label>
                  <input
                    type="time"
                    value={observations.eventTime}
                    onChange={e => setObservations({ ...observations, eventTime: e.target.value })}
                    className="glass-input w-full p-2"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Ubicación</label>
                  <input
                    type="text"
                    placeholder="Ej. Filtro A"
                    value={observations.location}
                    onChange={e => setObservations({ ...observations, location: e.target.value })}
                    className="glass-input w-full p-2"
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 mb-1">Descripción del Evento</label>
                <textarea
                  placeholder="Detalles de la anomalía o evento observado..."
                  value={observations.description}
                  onChange={e => setObservations({ ...observations, description: e.target.value })}
                  className="glass-input w-full p-2 h-20 resize-none"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">Consecuencia / Acción</label>
                <textarea
                  placeholder="Consecuencia y acciones inmediatas ejecutadas..."
                  value={observations.consequence}
                  onChange={e => setObservations({ ...observations, consequence: e.target.value })}
                  className="glass-input w-full p-2 h-16 resize-none"
                />
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex justify-between items-center border-b border-slate-850 pb-1">
                <h4 className="font-bold text-indigo-400 uppercase tracking-wider text-[10px]">Fotos de Evidencia</h4>
                <label className="cursor-pointer bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-1 rounded-lg flex items-center space-x-1 transition-colors text-[10px] font-semibold">
                  <Camera className="w-3.5 h-3.5" />
                  <span>Adjuntar Foto</span>
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    onChange={handlePhotoUpload}
                    className="hidden"
                  />
                </label>
              </div>

              {photos.filter(p => p.section === activeTab).length === 0 ? (
                <p className="text-slate-500 text-center py-8 italic border border-dashed border-slate-800 rounded-lg">Ninguna foto adjuntada en esta sección.</p>
              ) : (
                <div className="grid grid-cols-2 gap-3 max-h-[220px] overflow-y-auto pr-1">
                  {photos.filter(p => p.section === activeTab).map(p => (
                    <div key={p.id} className="bg-slate-950/40 p-2 rounded-lg border border-slate-850 flex space-x-2">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={p.path}
                        alt="Preview"
                        className="w-10 h-10 object-cover rounded"
                      />
                      <div className="flex-1 flex flex-col justify-between">
                        <input
                          type="text"
                          placeholder="Nota..."
                          value={p.caption}
                          onChange={e => handlePhotoCaptionChange(p.id!, e.target.value)}
                          className="glass-input p-1 text-[9px] w-full"
                        />
                        <button
                          onClick={() => handlePhotoDelete(p.id!)}
                          className="text-rose-400 hover:text-rose-300 self-end p-0.5"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end space-x-3 pt-4 border-t border-slate-800 text-xs">
        <button
          onClick={onClose}
          className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-350 font-semibold rounded-lg transition-colors"
        >
          Cancelar
        </button>
        <button
          onClick={handleSaveDraft}
          disabled={loading}
          className="px-4 py-2 bg-indigo-500/10 border border-indigo-500/25 hover:bg-indigo-500/20 text-indigo-300 font-semibold rounded-lg flex items-center space-x-1.5 transition-colors"
        >
          <Save className="w-4 h-4" />
          <span>Guardar Borrador</span>
        </button>
        <button
          onClick={handleSubmitInspection}
          disabled={loading}
          className="px-5 py-2 bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-750 text-white font-semibold rounded-lg flex items-center space-x-1.5 transition-colors"
        >
          <Send className="w-4 h-4" />
          <span>Finalizar e Iniciar Sync</span>
        </button>
      </div>
    </div>
  );
}
