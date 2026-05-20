'use client';

import { useState } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, Inspection, AssignmentTest } from '@/db/indexedDB';
import { ClipboardList, Play, Eye, FileSpreadsheet, ShieldCheck, CheckCircle2, RefreshCw, Clock } from 'lucide-react';
import InspectionForms from './InspectionForms';
import SecurityTestForm from './SecurityTestForm';

interface AssignmentsDashboardProps {
  employees: any[];
  nationalities: any[];
}

export default function AssignmentsDashboard({ employees, nationalities }: AssignmentsDashboardProps) {
  const [selectedInspection, setSelectedInspection] = useState<Inspection | null>(null);
  const [selectedTestId, setSelectedTestId] = useState<number | null>(null);
  const [activeFilter, setActiveFilter] = useState<'all' | 'operational' | 'security'>('all');

  // Live Query from Dexie
  const inspections = useLiveQuery(() => db.inspections.toArray()) || [];
  const securityTests = useLiveQuery(() => db.assignments_tests.toArray()) || [];

  const handleCloseForm = () => {
    setSelectedInspection(null);
    setSelectedTestId(null);
  };

  const getStatusStyle = (status: string) => {
    switch (status) {
      case 'Finalizada':
        return 'bg-emerald-500/10 border-emerald-500/25 text-emerald-400';
      case 'En progreso':
        return 'bg-indigo-500/10 border-indigo-500/25 text-indigo-400';
      default:
        return 'bg-amber-500/10 border-amber-500/25 text-amber-400';
    }
  };

  const renderFilterButton = (id: 'all' | 'operational' | 'security', label: string) => (
    <button
      onClick={() => setActiveFilter(id)}
      className={`px-3 py-1.5 rounded-lg text-xs font-semibold border transition-all ${
        activeFilter === id
          ? 'bg-indigo-600 border-indigo-500 text-white shadow-md shadow-indigo-650/10'
          : 'bg-slate-900 border-slate-800 text-slate-400 hover:text-slate-200 hover:border-slate-750'
      }`}
    >
      {label}
    </button>
  );

  // If a form is currently open, render it instead of the list
  if (selectedInspection) {
    return (
      <InspectionForms
        inspection={selectedInspection}
        onClose={handleCloseForm}
        onSave={handleCloseForm}
        employees={employees}
      />
    );
  }

  if (selectedTestId !== null) {
    return (
      <SecurityTestForm
        testId={selectedTestId}
        onClose={handleCloseForm}
        onSave={handleCloseForm}
        nationalities={nationalities}
      />
    );
  }

  return (
    <div className="space-y-6 max-w-6xl mx-auto p-2">
      {/* Filters */}
      <div className="flex space-x-2">
        {renderFilterButton('all', 'Todos los Trabajos')}
        {renderFilterButton('operational', 'Inspecciones Operacionales')}
        {renderFilterButton('security', 'Pruebas de Seguridad')}
      </div>

      {/* Grid of Jobs */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Operational Inspections Section */}
        {(activeFilter === 'all' || activeFilter === 'operational') && (
          <div className="space-y-3">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center">
              <FileSpreadsheet className="w-4 h-4 mr-1.5 text-indigo-400" />
              Auditorías Operacionales ({inspections.length})
            </h3>

            {inspections.length === 0 ? (
              <div className="glass p-8 text-center text-slate-500 text-xs italic rounded-xl border border-slate-850">
                Ninguna inspección asignada para hoy.
              </div>
            ) : (
              <div className="space-y-2.5">
                {inspections.map((ins) => {
                  const label = ins.type === 'I' ? 'Internacional' : 'Nacional';
                  const operationLabel = ins.operation === 'arrival' ? 'Arribo' : ins.operation === 'departure' ? 'Salida' : 'Inspección';
                  return (
                    <div
                      key={ins.id}
                      className="glass-card p-4 hover:border-slate-700 transition-all flex items-center justify-between"
                    >
                      <div className="space-y-1 text-xs">
                        <div className="flex items-center space-x-2">
                          <span className="font-bold text-slate-200">
                            Inspección {operationLabel}
                          </span>
                          <span className="text-[10px] text-indigo-400 bg-indigo-500/10 px-2 py-0.5 rounded">
                            {label}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500">ID Odoo: {ins.id} • Asignado a: {ins.assigned_user}</p>
                        {ins.date && <p className="text-[10px] text-slate-650 flex items-center"><Clock className="w-3 h-3 mr-1" />{ins.date}</p>}
                      </div>

                      <div className="flex items-center space-x-3">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold border ${getStatusStyle(ins.status)}`}>
                          {ins.status}
                        </span>

                        <button
                          onClick={() => setSelectedInspection(ins)}
                          className="p-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs flex items-center space-x-1 transition-colors"
                        >
                          {ins.status === 'Finalizada' ? (
                            <>
                              <Eye className="w-3.5 h-3.5" />
                              <span>Ver</span>
                            </>
                          ) : (
                            <>
                              <Play className="w-3.5 h-3.5" />
                              <span>Iniciar</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Security Tests Section */}
        {(activeFilter === 'all' || activeFilter === 'security') && (
          <div className="space-y-3">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center">
              <ShieldCheck className="w-4 h-4 mr-1.5 text-emerald-400" />
              Pruebas de Seguridad ({securityTests.length})
            </h3>

            {securityTests.length === 0 ? (
              <div className="glass p-8 text-center text-slate-500 text-xs italic rounded-xl border border-slate-850">
                Ninguna prueba de seguridad asignada.
              </div>
            ) : (
              <div className="space-y-2.5">
                {securityTests.map((test) => {
                  const typeLabel = test.type || 'Evaluación de Procedimiento';
                  return (
                    <div
                      key={test.id}
                      className="glass-card p-4 hover:border-slate-700 transition-all flex items-center justify-between"
                    >
                      <div className="space-y-1 text-xs">
                        <div className="flex items-center space-x-2">
                          <span className="font-bold text-slate-200 truncate max-w-[180px]">
                            {typeLabel}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500">ID Odoo: {test.id}</p>
                        {test.date_test && <p className="text-[10px] text-slate-650 flex items-center"><Clock className="w-3 h-3 mr-1" />{test.date_test}</p>}
                      </div>

                      <div className="flex items-center space-x-3">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold border ${getStatusStyle(test.status)}`}>
                          {test.status}
                        </span>

                        <button
                          onClick={() => setSelectedTestId(test.id)}
                          className="p-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs flex items-center space-x-1 transition-colors"
                        >
                          {test.status === 'Finalizada' ? (
                            <>
                              <Eye className="w-3.5 h-3.5" />
                              <span>Ver</span>
                            </>
                          ) : (
                            <>
                              <Play className="w-3.5 h-3.5" />
                              <span>Iniciar</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
