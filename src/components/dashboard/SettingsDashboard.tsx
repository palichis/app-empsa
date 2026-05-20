'use client';

import { useState, useEffect } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, OfflineMutation, Inspection, AssignmentTest, User, PenaltyCatalog } from '@/db/indexedDB';
import { Settings, Server, RefreshCw, Trash2, Database, AlertCircle, CheckCircle2, ShieldAlert, Play } from 'lucide-react';
import { useNetwork } from '@/hooks/useNetwork';

interface SettingsDashboardProps {
  onSync: () => Promise<void>;
}

export default function SettingsDashboard({ onSync }: SettingsDashboardProps) {
  const isOnline = useNetwork();
  const [syncing, setSyncing] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Odoo Config edit states
  const [serverUrl, setServerUrl] = useState('https://erppruebas.aeropuertoquito.gob.ec');
  const [dbName, setDbName] = useState('epmsa_pruebas');

  // Load config on mount
  useEffect(() => {
    const savedConfig = localStorage.getItem('epmsa_odoo_config');
    if (savedConfig) {
      try {
        const parsed = JSON.parse(savedConfig);
        if (parsed.serverUrl) setServerUrl(parsed.serverUrl);
        if (parsed.dbName) setDbName(parsed.dbName);
      } catch (e) {}
    }
  }, []);

  // Live Query of mutations
  const mutations = useLiveQuery(() => db.mutations.reverse().toArray()) || [];

  const handleSaveConfig = (e: React.FormEvent) => {
    e.preventDefault();
    localStorage.setItem('epmsa_odoo_config', JSON.stringify({ serverUrl, dbName }));
    setSuccessMsg('Configuración de Odoo guardada correctamente.');
    setTimeout(() => setSuccessMsg(null), 2500);
  };

  const handleManualSync = async () => {
    setSyncing(true);
    try {
      await onSync();
      setSuccessMsg('Sincronización completada.');
      setTimeout(() => setSuccessMsg(null), 2500);
    } catch (e) {
      console.error(e);
    } finally {
      setSyncing(false);
    }
  };

  const handleClearLocalDB = async () => {
    if (confirm('¿Estás seguro de que deseas vaciar todas las tablas locales? Se perderán borradores no guardados.')) {
      await db.users.clear();
      await db.penalties_catalog.clear();
      await db.penalties.clear();
      await db.inspections.clear();
      await db.national_arrivals.clear();
      await db.international_arrivals.clear();
      await db.arrival_baggage_time_details.clear();
      await db.national_departures.clear();
      await db.international_departures.clear();
      await db.departures_preboarding_details.clear();
      await db.cargo_inspections.clear();
      await db.cargo_items.clear();
      await db.inspection_photos.clear();
      await db.assignments_tests.clear();
      await db.mutations.clear();
      setSuccessMsg('Base de datos local limpia.');
      setTimeout(() => setSuccessMsg(null), 2500);
    }
  };

  const handleLoadDemoData = async () => {
    // Populate demo inspectors
    const demoUsers: User[] = [
      { id: 101, name: 'Inspector Roberto Narváez', active: 1 },
      { id: 102, name: 'Inspectora Sofía Benítez', active: 1 },
      { id: 103, name: 'Auditor Carlos Altamirano', active: 1 },
    ];
    await db.users.bulkPut(demoUsers);

    // Populate demo catalog penalties
    const demoCatalog: PenaltyCatalog[] = [
      { id: '1', serverId: 501, parentId: 2, name: 'Art. 12: Descuidos menores en el uso de credenciales de seguridad', active: 1 },
      { id: '2', serverId: 502, parentId: 2, name: 'Art. 15: No portar uniforme oficial o portarlo de forma incompleta', active: 1 },
      { id: '3', serverId: 503, parentId: 3, name: 'Art. 22: Obstrucción temporal de puertas de salida de emergencia', active: 1 },
      { id: '4', serverId: 504, parentId: 3, name: 'Art. 25: Desaseo o falta de mantenimiento de pasillos de tránsito', active: 1 },
      { id: '5', serverId: 505, parentId: 4, name: 'Art. 35: Conducción temeraria de vehículos de rampa en plataforma UIO', active: 1 },
      { id: '6', serverId: 506, parentId: 4, name: 'Art. 38: Ingreso no autorizado a la zona de clasificación de equipaje', active: 1 },
    ];
    await db.penalties_catalog.bulkPut(demoCatalog);

    // Populate demo inspections
    const demoInspections: Inspection[] = [
      { id: 2001, type: 'D', operation: 'departure', assigned_user: 'Sofía Benítez', status: 'Asignada', synced: 0, date: '2026-05-20' },
      { id: 2002, type: 'I', operation: 'arrival', assigned_user: 'Roberto Narváez', status: 'En progreso', synced: 0, date: '2026-05-20' },
      { id: 2003, type: 'none', operation: 'none', flightType: 'cargo', assigned_user: 'Carlos Altamirano', status: 'Asignada', synced: 0, date: '2026-05-20' },
    ];
    await db.inspections.bulkPut(demoInspections);

    // Prepopulate preboarding lines for Departure
    const demoPreb: DeparturePreboardingDetail[] = [
      { id: 1, national_departure_id: 2001, area: 'Sala A1', used: 1, used_chairs: 40, available_chairs: 60, used_area: 100, available_area: 200, occupancy_percentage: 40, synced: 0 },
      { id: 2, national_departure_id: 2001, area: 'Sala A2', used: 1, used_chairs: 15, available_chairs: 85, used_area: 100, available_area: 200, occupancy_percentage: 15, synced: 0 },
    ];
    await db.departures_preboarding_details.bulkPut(demoPreb);

    // Populate demo tests
    const demoTests: AssignmentTest[] = [
      {
        id: 3001,
        site_test: 1,
        date_test: '2026-05-20',
        time_test: '10:00',
        type: 'Evaluación de Procedimiento de Filtro',
        brand: 'Smiths',
        model: 'Detection',
        hiding_site: 'Fondo de maletín',
        status: 'Asignada',
        synced: 0,
      },
    ];
    await db.assignments_tests.bulkPut(demoTests);

    setSuccessMsg('Datos demo cargados con éxito. Recarga la pestaña de asignaciones.');
    setTimeout(() => setSuccessMsg(null), 3000);
  };

  const handleResolveConflict = async (mutationId: number, action: 'force' | 'discard') => {
    if (action === 'discard') {
      await db.mutations.delete(mutationId);
    } else {
      // Force change status back to pending to trigger retry
      await db.mutations.update(mutationId, { status: 'pending', error: undefined, conflictReason: undefined });
    }
  };

  const getMutationStatusBadge = (status: string) => {
    switch (status) {
      case 'synced':
        return 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20';
      case 'processing':
        return 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20';
      case 'conflict':
        return 'bg-rose-500/10 text-rose-400 border border-rose-500/20 animate-pulse';
      case 'failed':
        return 'bg-rose-550/10 text-rose-350 border border-rose-550/20';
      default:
        return 'bg-slate-800 text-slate-450 border border-slate-700';
    }
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto p-2 text-xs">
      {successMsg && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/25 text-emerald-300 text-sm rounded-lg flex items-center space-x-2 animate-fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span>{successMsg}</span>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Left Columns: Config & Queue */}
        <div className="md:col-span-2 space-y-6">
          {/* Odoo credentials edit */}
          <div className="glass-card p-6 shadow-xl space-y-4">
            <h3 className="text-sm font-bold text-white uppercase border-b border-slate-800 pb-2 flex items-center">
              <Server className="w-4 h-4 mr-2 text-indigo-400" />
              Parámetros de Servidor
            </h3>
            <form onSubmit={handleSaveConfig} className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-slate-450 mb-1">URL de Odoo</label>
                <input
                  type="url"
                  required
                  value={serverUrl}
                  onChange={e => setServerUrl(e.target.value)}
                  className="glass-input w-full p-2"
                />
              </div>
              <div>
                <label className="block text-slate-450 mb-1">Base de Datos</label>
                <input
                  type="text"
                  required
                  value={dbName}
                  onChange={e => setDbName(e.target.value)}
                  className="glass-input w-full p-2"
                />
              </div>
              <button
                type="submit"
                className="col-span-2 py-2 bg-indigo-650 hover:bg-indigo-600 text-white rounded-lg font-semibold transition-colors"
              >
                Guardar Conexión
              </button>
            </form>
          </div>

          {/* Sync Queue */}
          <div className="glass-card p-6 shadow-xl space-y-4">
            <div className="flex justify-between items-center border-b border-slate-800 pb-2">
              <h3 className="text-sm font-bold text-white uppercase flex items-center">
                <RefreshCw className="w-4 h-4 mr-2 text-indigo-400" />
                Cola de Sincronización Local ({mutations.length})
              </h3>
              {isOnline && mutations.length > 0 && (
                <button
                  onClick={handleManualSync}
                  disabled={syncing}
                  className="px-3 py-1 bg-indigo-600 hover:bg-indigo-500 rounded text-white font-semibold flex items-center space-x-1 transition-colors"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${syncing ? 'animate-spin' : ''}`} />
                  <span>Sincronizar Todo</span>
                </button>
              )}
            </div>

            {mutations.length === 0 ? (
              <p className="text-slate-500 italic text-center py-6">No hay mutaciones o escrituras en cola.</p>
            ) : (
              <div className="space-y-3 max-h-80 overflow-y-auto pr-1">
                {mutations.map(mut => (
                  <div key={mut.id} className="p-3 bg-slate-950/20 border border-slate-850 rounded-lg space-y-2">
                    <div className="flex justify-between items-center text-[10px]">
                      <span className="font-bold text-slate-200 uppercase tracking-wider">{mut.type}</span>
                      <span className={`px-2 py-0.5 rounded font-semibold ${getMutationStatusBadge(mut.status)}`}>
                        {mut.status}
                      </span>
                    </div>
                    
                    <p className="text-[11px] text-slate-400 truncate">
                      Payload: {JSON.stringify(mut.payload)}
                    </p>

                    {/* Conflict Resolution Block */}
                    {mut.status === 'conflict' && (
                      <div className="p-2.5 bg-rose-500/10 border border-rose-500/20 rounded text-xs space-y-2">
                        <p className="text-rose-300 font-semibold flex items-center">
                          <ShieldAlert className="w-4 h-4 mr-1 flex-shrink-0" />
                          Conflicto AI: {mut.conflictReason || 'Esquema o montos inconsistentes'}
                        </p>
                        <div className="flex space-x-2">
                          <button
                            onClick={() => handleResolveConflict(mut.id!, 'force')}
                            className="px-2 py-1 bg-indigo-600 hover:bg-indigo-500 text-white rounded text-[10px] font-semibold"
                          >
                            Forzar Reenvío
                          </button>
                          <button
                            onClick={() => handleResolveConflict(mut.id!, 'discard')}
                            className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded text-[10px] font-semibold"
                          >
                            Descartar
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Local DB Tools */}
        <div className="space-y-6">
          <div className="glass-card p-5 shadow-xl border border-slate-800 space-y-4">
            <h3 className="text-sm font-bold text-white uppercase border-b border-slate-800 pb-2 flex items-center">
              <Database className="w-4 h-4 mr-2 text-indigo-400" />
              Base de Datos
            </h3>

            <p className="text-slate-450 text-[11px] leading-relaxed">
              Herramientas de depuración y pruebas locales. Puedes cargar datos de demostración para realizar auditorías simuladas.
            </p>

            <div className="space-y-3 pt-2">
              <button
                type="button"
                onClick={handleLoadDemoData}
                className="w-full py-2 bg-indigo-500/10 border border-indigo-500/20 hover:bg-indigo-500/20 text-indigo-300 rounded-lg font-semibold flex items-center justify-center space-x-1.5 transition-colors"
              >
                <Database className="w-4 h-4" />
                <span>Cargar Datos Demo</span>
              </button>

              <button
                type="button"
                onClick={handleClearLocalDB}
                className="w-full py-2 bg-rose-500/10 border border-rose-500/20 hover:bg-rose-500/20 text-rose-300 rounded-lg font-semibold flex items-center justify-center space-x-1.5 transition-colors"
              >
                <Trash2 className="w-4 h-4" />
                <span>Vaciar DB Local</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
