'use client';

import { useState, useEffect } from 'react';
import { ArrowLeft, Save, Send, RefreshCw, CheckCircle2 } from 'lucide-react';
import { db } from '@/db/indexedDB';
import { OdooService } from '@/services/odooService';
import type { Inspection, InspectionType, OdooConfig, UserSession } from '@/types';

interface FlightInspectionFormProps {
  inspection: Inspection;
  inspectionType: InspectionType;
  onClose: () => void;
  onSave: () => void;
}

const tabConfigs: Record<InspectionType, { id: string; label: string }[]> = {
  nationalArrival: [
    { id: 'general', label: 'Datos Generales' },
    { id: 'publicHall', label: 'Hall Publico' },
    { id: 'baggageArea', label: 'Retiro Equipaje (Area)' },
    { id: 'baggageTime', label: 'Retiro Equipaje (Tiempo)' },
    { id: 'observations', label: 'Observaciones' },
  ],
  internationalArrival: [
    { id: 'general', label: 'Datos Generales' },
    { id: 'publicHall', label: 'Hall Publico' },
    { id: 'migration', label: 'Migracion' },
    { id: 'customs', label: 'Aduanas' },
    { id: 'baggageArea', label: 'Retiro Equipaje (Area)' },
    { id: 'baggageTime', label: 'Retiro Equipaje (Tiempo)' },
    { id: 'observations', label: 'Observaciones' },
  ],
  nationalDeparture: [
    { id: 'general', label: 'Datos Generales' },
    { id: 'publicHall', label: 'Hall Publico' },
    { id: 'selfCheckin', label: 'Self Check-in' },
    { id: 'checkinCounter', label: 'Mostrador Check-in' },
    { id: 'securityFilters', label: 'Filtros Seguridad' },
    { id: 'preboarding', label: 'Preembarque' },
    { id: 'observations', label: 'Observaciones' },
  ],
  internationalDeparture: [
    { id: 'general', label: 'Datos Generales' },
    { id: 'publicHall', label: 'Hall Publico' },
    { id: 'selfCheckin', label: 'Self Check-in' },
    { id: 'checkinCounter', label: 'Mostrador Check-in' },
    { id: 'securityFilters', label: 'Filtros Seguridad' },
    { id: 'migration', label: 'Migracion' },
    { id: 'preboarding', label: 'Preembarque' },
    { id: 'observations', label: 'Observaciones' },
  ],
  cargo: [
    { id: 'general', label: 'Datos Generales' },
    { id: 'landside', label: 'Lado Tierra' },
    { id: 'airside', label: 'Lado Aire' },
    { id: 'observations', label: 'Observaciones' },
  ],
};

const typeLabels: Record<InspectionType, string> = {
  nationalArrival: 'Arribo Nacional',
  internationalArrival: 'Arribo Internacional',
  nationalDeparture: 'Salida Nacional',
  internationalDeparture: 'Salida Internacional',
  cargo: 'Carga',
};

export default function FlightInspectionForm({
  inspection,
  inspectionType,
  onClose,
  onSave,
}: FlightInspectionFormProps) {
  const [activeTab, setActiveTab] = useState('general');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  // Form data state
  const [generalData, setGeneralData] = useState({
    measurementDate: new Date().toISOString().substring(0, 10),
    hour: '',
    peakHour: '',
    flightCount: 0,
    preparedBy: inspection.employee?.name || '',
    preparedById: inspection.employee?.id || 0,
    reviewedBy: '',
    reviewedById: 0,
  });

  const [publicHall, setPublicHall] = useState({
    time: '',
    paxWaitingArea: 0,
  });

  const [observations, setObservations] = useState({
    eventTime: '',
    location: '',
    description: '',
    consequence: '',
  });

  // Load existing data
  useEffect(() => {
    async function loadData() {
      // Load from IndexedDB based on inspection type
      const inspectionId = inspection.id;
      if (!inspectionId) return;

      try {
        let record;
        if (inspectionType === 'nationalArrival') {
          record = await db.national_arrivals.where('inspection_id').equals(inspectionId).first();
        } else if (inspectionType === 'internationalArrival') {
          record = await db.international_arrivals.where('inspection_id').equals(inspectionId).first();
        } else if (inspectionType === 'nationalDeparture') {
          record = await db.national_departures.where('inspection_id').equals(inspectionId).first();
        } else if (inspectionType === 'internationalDeparture') {
          record = await db.international_departures.where('inspection_id').equals(inspectionId).first();
        } else if (inspectionType === 'cargo') {
          record = await db.cargo_inspections.where('inspection_id').equals(inspectionId).first();
        }

        if (record) {
          setGeneralData({
            measurementDate: record.general_data_measurement_date || new Date().toISOString().substring(0, 10),
            hour: record.general_data_hour || '',
            peakHour: record.general_data_peak_hour || '',
            flightCount: record.general_data_flight_count || 0,
            preparedBy: record.general_data_prepared_by || '',
            preparedById: record.general_data_prepared_by_id || 0,
            reviewedBy: record.general_data_reviewed_by || '',
            reviewedById: record.general_data_reviewed_by_id || 0,
          });
          setPublicHall({
            time: record.public_hall_time || '',
            paxWaitingArea: record.public_hall_pax_waiting_area || 0,
          });
          setObservations({
            eventTime: record.observations_event_time || '',
            location: record.observations_location || '',
            description: record.observations_description || '',
            consequence: record.observations_consequence || '',
          });
        }
      } catch (e) {
        console.error('Error loading inspection data:', e);
      }
    }

    loadData();
  }, [inspection.id, inspectionType]);

  const tabs = tabConfigs[inspectionType] || [];

  const handleSaveDraft = async () => {
    setLoading(true);
    try {
      await saveToLocalDB('pending');
      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
      }, 2000);
    } catch (e) {
      console.error('Error saving draft:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    setLoading(true);
    try {
      await saveToLocalDB('done');

      // Create mutation for sync
      const payload = buildSyncPayload();
      await db.mutations.add({
        type: 'sync_control',
        inspectionId: inspection.id,
        payload,
        timestamp: Date.now(),
        status: 'pending',
      });

      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
        onSave();
      }, 1500);
    } catch (e) {
      console.error('Error submitting inspection:', e);
    } finally {
      setLoading(false);
    }
  };

  const saveToLocalDB = async (status: 'pending' | 'done') => {
    const inspectionId = inspection.id;
    if (!inspectionId) return;

    const baseData = {
      inspection_id: inspectionId,
      general_data_measurement_date: generalData.measurementDate,
      general_data_hour: generalData.hour,
      general_data_peak_hour: generalData.peakHour,
      general_data_flight_count: generalData.flightCount,
      general_data_prepared_by: generalData.preparedBy,
      general_data_prepared_by_id: generalData.preparedById,
      general_data_reviewed_by: generalData.reviewedBy,
      general_data_reviewed_by_id: generalData.reviewedById,
      public_hall_time: publicHall.time,
      public_hall_pax_waiting_area: publicHall.paxWaitingArea,
      observations_event_time: observations.eventTime,
      observations_location: observations.location,
      observations_description: observations.description,
      observations_consequence: observations.consequence,
      synced: 0,
    };

    // Save to appropriate table based on type
    if (inspectionType === 'nationalArrival') {
      await db.national_arrivals.put({ ...baseData, id: inspectionId });
    } else if (inspectionType === 'internationalArrival') {
      await db.international_arrivals.put({ ...baseData, id: inspectionId });
    } else if (inspectionType === 'nationalDeparture') {
      await db.national_departures.put({ ...baseData, id: inspectionId });
    } else if (inspectionType === 'internationalDeparture') {
      await db.international_departures.put({ ...baseData, id: inspectionId });
    } else if (inspectionType === 'cargo') {
      await db.cargo_inspections.put({ ...baseData, id: inspectionId });
    }

    // Update inspection status
    await db.inspections.update(inspectionId, { status: status === 'done' ? 'Finalizada' : 'En progreso' });
  };

  const buildSyncPayload = () => {
    return {
      id: inspection.id,
      type: inspectionType,
      general: generalData,
      publicHall,
      observations,
    };
  };

  const renderTabContent = () => {
    switch (activeTab) {
      case 'general':
        return (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-white mb-4">Datos Generales</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Fecha de Medicion</label>
                <input
                  type="date"
                  value={generalData.measurementDate}
                  onChange={(e) => setGeneralData({ ...generalData, measurementDate: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Hora Pico</label>
                <input
                  type="time"
                  value={generalData.peakHour}
                  onChange={(e) => setGeneralData({ ...generalData, peakHour: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Cantidad de Vuelos</label>
                <input
                  type="number"
                  value={generalData.flightCount}
                  onChange={(e) => setGeneralData({ ...generalData, flightCount: parseInt(e.target.value) || 0 })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Elaborado Por</label>
                <input
                  type="text"
                  value={generalData.preparedBy}
                  onChange={(e) => setGeneralData({ ...generalData, preparedBy: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Revisado Por</label>
                <input
                  type="text"
                  value={generalData.reviewedBy}
                  onChange={(e) => setGeneralData({ ...generalData, reviewedBy: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>
        );

      case 'publicHall':
        return (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-white mb-4">Hall Publico</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Hora</label>
                <input
                  type="time"
                  value={publicHall.time}
                  onChange={(e) => setPublicHall({ ...publicHall, time: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Pasajeros en Area de Espera</label>
                <input
                  type="number"
                  value={publicHall.paxWaitingArea}
                  onChange={(e) => setPublicHall({ ...publicHall, paxWaitingArea: parseInt(e.target.value) || 0 })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>
        );

      case 'observations':
        return (
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-white mb-4">Observaciones y Novedades</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Hora del Evento</label>
                <input
                  type="time"
                  value={observations.eventTime}
                  onChange={(e) => setObservations({ ...observations, eventTime: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Ubicacion</label>
                <input
                  type="text"
                  value={observations.location}
                  onChange={(e) => setObservations({ ...observations, location: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm text-slate-400 mb-1">Descripcion</label>
                <textarea
                  value={observations.description}
                  onChange={(e) => setObservations({ ...observations, description: e.target.value })}
                  rows={3}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm text-slate-400 mb-1">Consecuencias</label>
                <textarea
                  value={observations.consequence}
                  onChange={(e) => setObservations({ ...observations, consequence: e.target.value })}
                  rows={3}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                />
              </div>
            </div>
          </div>
        );

      default:
        return (
          <div className="text-center py-12">
            <p className="text-slate-400">
              Seccion &quot;{tabs.find(t => t.id === activeTab)?.label}&quot; en desarrollo
            </p>
          </div>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={onClose}
          className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          <span>Volver</span>
        </button>
        <h1 className="text-xl font-bold text-white">
          {typeLabels[inspectionType]} - {inspection.name || `#${inspection.id}`}
        </h1>
        <div className="w-24" />
      </div>

      {/* Success Message */}
      {success && (
        <div className="bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 rounded-lg p-4 flex items-center gap-3">
          <CheckCircle2 className="w-5 h-5" />
          <span>Guardado exitosamente</span>
        </div>
      )}

      {/* Tab Navigation */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${
              activeTab === tab.id
                ? 'bg-indigo-600 text-white'
                : 'bg-slate-800 text-slate-400 hover:bg-slate-700 hover:text-white'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Form Content */}
      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-6">
        {renderTabContent()}
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end gap-3">
        <button
          onClick={onClose}
          className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg transition-colors"
        >
          Cancelar
        </button>
        <button
          onClick={handleSaveDraft}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors disabled:opacity-50"
        >
          {loading ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
          <span>Guardar Borrador</span>
        </button>
        <button
          onClick={handleSubmit}
          disabled={loading}
          className="flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors disabled:opacity-50"
        >
          {loading ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
          <span>Finalizar</span>
        </button>
      </div>
    </div>
  );
}
