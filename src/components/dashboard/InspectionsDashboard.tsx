'use client';

import { useState, useEffect } from 'react';
import { 
  PlaneLanding, 
  PlaneTakeoff, 
  Package, 
  Clock, 
  MapPin,
  User,
  ChevronRight,
  RefreshCw,
  AlertCircle
} from 'lucide-react';
import type { Inspection, InspectionType } from '@/types';

interface InspectionsDashboardProps {
  inspections: Inspection[];
  onSelectInspection: (inspection: Inspection, type: InspectionType) => void;
  onRefresh: () => Promise<void>;
  isLoading?: boolean;
}

function getInspectionType(inspection: Inspection): InspectionType {
  if (inspection.operation === 'departure' && inspection.type === 'D') {
    return 'nationalDeparture';
  }
  if (inspection.operation === 'departure' && inspection.type === 'I') {
    return 'internationalDeparture';
  }
  if (inspection.operation === 'arrival' && inspection.type === 'D') {
    return 'nationalArrival';
  }
  if (inspection.operation === 'arrival' && inspection.type === 'I') {
    return 'internationalArrival';
  }
  if (inspection.operation === 'none' && inspection.flightType === 'cargo') {
    return 'cargo';
  }
  return 'nationalArrival';
}

function getInspectionIcon(type: InspectionType) {
  switch (type) {
    case 'nationalArrival':
    case 'internationalArrival':
      return PlaneLanding;
    case 'nationalDeparture':
    case 'internationalDeparture':
      return PlaneTakeoff;
    case 'cargo':
      return Package;
    default:
      return PlaneLanding;
  }
}

function getInspectionLabel(type: InspectionType): string {
  switch (type) {
    case 'nationalArrival':
      return 'Arribo Nacional';
    case 'internationalArrival':
      return 'Arribo Internacional';
    case 'nationalDeparture':
      return 'Salida Nacional';
    case 'internationalDeparture':
      return 'Salida Internacional';
    case 'cargo':
      return 'Carga';
    default:
      return 'Inspeccion';
  }
}

function getInspectionColor(type: InspectionType): string {
  switch (type) {
    case 'nationalArrival':
      return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
    case 'internationalArrival':
      return 'bg-cyan-500/20 text-cyan-400 border-cyan-500/30';
    case 'nationalDeparture':
      return 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
    case 'internationalDeparture':
      return 'bg-teal-500/20 text-teal-400 border-teal-500/30';
    case 'cargo':
      return 'bg-amber-500/20 text-amber-400 border-amber-500/30';
    default:
      return 'bg-slate-500/20 text-slate-400 border-slate-500/30';
  }
}

export default function InspectionsDashboard({
  inspections,
  onSelectInspection,
  onRefresh,
  isLoading = false,
}: InspectionsDashboardProps) {
  const [refreshing, setRefreshing] = useState(false);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await onRefresh();
    } finally {
      setRefreshing(false);
    }
  };

  // Group inspections by type
  const groupedInspections = inspections.reduce((acc, inspection) => {
    const type = getInspectionType(inspection);
    if (!acc[type]) {
      acc[type] = [];
    }
    acc[type].push(inspection);
    return acc;
  }, {} as Record<InspectionType, Inspection[]>);

  const pendingCount = inspections.filter(i => i.state === 'pending').length;
  const completedCount = inspections.filter(i => i.state === 'done').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Inspecciones de Vuelos</h1>
          <p className="text-slate-400 mt-1">
            {inspections.length} inspecciones asignadas para hoy
          </p>
        </div>
        <button
          onClick={handleRefresh}
          disabled={refreshing || isLoading}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-lg transition-colors"
        >
          <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
          <span>Actualizar</span>
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-blue-500/20 rounded-lg">
            <Clock className="w-6 h-6 text-blue-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Pendientes</p>
            <p className="text-2xl font-bold text-white">{pendingCount}</p>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-emerald-500/20 rounded-lg">
            <PlaneLanding className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Completadas</p>
            <p className="text-2xl font-bold text-white">{completedCount}</p>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-amber-500/20 rounded-lg">
            <AlertCircle className="w-6 h-6 text-amber-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Total Hoy</p>
            <p className="text-2xl font-bold text-white">{inspections.length}</p>
          </div>
        </div>
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <RefreshCw className="w-8 h-8 text-indigo-400 animate-spin" />
        </div>
      )}

      {/* Empty State */}
      {!isLoading && inspections.length === 0 && (
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-12 text-center">
          <PlaneLanding className="w-16 h-16 text-slate-600 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-white mb-2">
            No hay inspecciones asignadas
          </h3>
          <p className="text-slate-400 max-w-md mx-auto">
            No tienes inspecciones de vuelos asignadas para hoy. Presiona actualizar para verificar nuevas asignaciones.
          </p>
        </div>
      )}

      {/* Inspections List */}
      {!isLoading && inspections.length > 0 && (
        <div className="space-y-6">
          {Object.entries(groupedInspections).map(([type, items]) => {
            const inspectionType = type as InspectionType;
            const Icon = getInspectionIcon(inspectionType);
            const label = getInspectionLabel(inspectionType);
            const colorClass = getInspectionColor(inspectionType);

            return (
              <div key={type}>
                <div className="flex items-center gap-2 mb-3">
                  <div className={`p-1.5 rounded-lg border ${colorClass}`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <h2 className="text-lg font-semibold text-white">{label}</h2>
                  <span className="text-sm text-slate-400">({items.length})</span>
                </div>

                <div className="grid gap-3">
                  {items.map((inspection) => (
                    <button
                      key={inspection.id}
                      onClick={() => onSelectInspection(inspection, inspectionType)}
                      className="w-full bg-slate-800/50 border border-slate-700 rounded-xl p-4 text-left transition-all hover:border-slate-600 hover:bg-slate-800 group"
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-2">
                            <h3 className="font-semibold text-white">
                              {inspection.name || `Inspeccion #${inspection.id}`}
                            </h3>
                            <span
                              className={`text-xs px-2 py-0.5 rounded-full ${
                                inspection.state === 'done'
                                  ? 'bg-emerald-500/20 text-emerald-400'
                                  : 'bg-amber-500/20 text-amber-400'
                              }`}
                            >
                              {inspection.state === 'done' ? 'Completada' : 'Pendiente'}
                            </span>
                          </div>

                          <div className="flex flex-wrap items-center gap-4 text-sm text-slate-400">
                            {inspection.dateStr && (
                              <div className="flex items-center gap-1.5">
                                <Clock className="w-4 h-4" />
                                <span>{inspection.dateStr}</span>
                              </div>
                            )}
                            {inspection.employee?.name && (
                              <div className="flex items-center gap-1.5">
                                <User className="w-4 h-4" />
                                <span>{inspection.employee.name}</span>
                              </div>
                            )}
                          </div>

                          {inspection.supervisors && inspection.supervisors.length > 0 && (
                            <div className="mt-2 flex items-center gap-1.5 text-sm text-slate-500">
                              <MapPin className="w-4 h-4" />
                              <span>
                                Supervisores: {inspection.supervisors.map(s => s.name).join(', ')}
                              </span>
                            </div>
                          )}
                        </div>

                        <ChevronRight className="w-5 h-5 text-slate-500 group-hover:text-indigo-400 transition-colors" />
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
