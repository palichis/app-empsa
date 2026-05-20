'use client';

import { useNetwork } from '@/hooks/useNetwork';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '@/db/indexedDB';
import { Wifi, WifiOff, RefreshCw, AlertCircle } from 'lucide-react';
import { useState } from 'react';

interface HeaderProps {
  activeTab: string;
  onRefresh?: () => Promise<void>;
  onSync?: () => Promise<void>;
}

export default function Header({ activeTab, onRefresh, onSync }: HeaderProps) {
  const isOnline = useNetwork();
  const [syncing, setSyncing] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  // Subscribe to pending mutations count in Dexie
  const pendingCount = useLiveQuery(
    () => db.mutations.where('status').equals('pending').count()
  ) ?? 0;

  const tabTitles: Record<string, string> = {
    assignments: 'Mis Asignaciones y Auditorías',
    penalties: 'Registro de Sanciones e Infracciones',
    settings: 'Configuración y Diagnósticos',
  };

  const handleRefresh = async () => {
    if (!onRefresh) return;
    setRefreshing(true);
    try {
      await onRefresh();
    } catch (e) {
      console.error(e);
    } finally {
      setRefreshing(false);
    }
  };

  const handleSync = async () => {
    if (!onSync) return;
    setSyncing(true);
    try {
      await onSync();
    } catch (e) {
      console.error(e);
    } finally {
      setSyncing(false);
    }
  };

  return (
    <header className="h-16 border-b border-slate-800 bg-slate-900/50 backdrop-blur-md px-8 flex items-center justify-between sticky top-0 z-30">
      {/* Title */}
      <h2 className="text-lg font-semibold text-slate-200">
        {tabTitles[activeTab] || 'EPMSA Audits'}
      </h2>

      {/* Control Actions & Status */}
      <div className="flex items-center space-x-4">
        {/* Sync Queue State */}
        {pendingCount > 0 && (
          <div className="flex items-center space-x-2 bg-indigo-500/10 border border-indigo-500/20 px-3 py-1 rounded-lg text-indigo-300 text-xs font-semibold">
            <AlertCircle className="w-3.5 h-3.5 text-indigo-400" />
            <span>{pendingCount} pendientes</span>
            {isOnline && (
              <button
                disabled={syncing}
                onClick={handleSync}
                className="ml-2 hover:text-white flex items-center space-x-1 underline text-indigo-400 disabled:opacity-50"
              >
                <RefreshCw className={`w-3 h-3 ${syncing ? 'animate-spin' : ''}`} />
                <span>Sincronizar</span>
              </button>
            )}
          </div>
        )}

        {/* Network Badge */}
        <div
          className={`flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-semibold border ${
            isOnline
              ? 'bg-emerald-500/10 border-emerald-500/25 text-emerald-400'
              : 'bg-amber-500/10 border-amber-500/25 text-amber-400 animate-pulse'
          }`}
        >
          {isOnline ? (
            <>
              <Wifi className="w-3.5 h-3.5" />
              <span>En Línea</span>
            </>
          ) : (
            <>
              <WifiOff className="w-3.5 h-3.5" />
              <span>Sin Conexión</span>
            </>
          )}
        </div>

        {/* Refresh Assignments Button (Only shown on Assignments tab) */}
        {activeTab === 'assignments' && onRefresh && (
          <button
            onClick={handleRefresh}
            disabled={refreshing || !isOnline}
            className="flex items-center space-x-2 px-3 py-1.5 rounded-lg bg-slate-800 border border-slate-700 hover:bg-slate-750 text-slate-350 hover:text-slate-100 text-xs font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            title={isOnline ? 'Recargar asignaciones desde Odoo' : 'Conéctate para recargar asignaciones'}
          >
            <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
            <span>Actualizar</span>
          </button>
        )}
      </div>
    </header>
  );
}
