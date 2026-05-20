'use client';

import { 
  ClipboardList, 
  AlertTriangle, 
  Plane,
  FileText,
  ChevronRight,
  Clock,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';

interface HomeDashboardProps {
  setActiveTab: (tab: string) => void;
  pendingInspections?: number;
  pendingPenalties?: number;
  pendingSync?: number;
}

export default function HomeDashboard({ 
  setActiveTab, 
  pendingInspections = 0,
  pendingPenalties = 0,
  pendingSync = 0
}: HomeDashboardProps) {
  const cards = [
    {
      id: 'assignments',
      title: 'Mis Asignaciones',
      description: 'Inspecciones y pruebas asignadas',
      icon: ClipboardList,
      color: 'bg-blue-500',
      hoverColor: 'hover:bg-blue-600',
      badge: pendingInspections > 0 ? pendingInspections : null,
    },
    {
      id: 'inspections',
      title: 'Inspecciones de Vuelos',
      description: 'Arribos, salidas y carga',
      icon: Plane,
      color: 'bg-emerald-500',
      hoverColor: 'hover:bg-emerald-600',
      badge: null,
    },
    {
      id: 'penalties',
      title: 'Sanciones',
      description: 'Registro de infracciones',
      icon: AlertTriangle,
      color: 'bg-amber-500',
      hoverColor: 'hover:bg-amber-600',
      badge: pendingPenalties > 0 ? pendingPenalties : null,
    },
    {
      id: 'novedades',
      title: 'Novedades',
      description: 'Tickets y reportes',
      icon: FileText,
      color: 'bg-purple-500',
      hoverColor: 'hover:bg-purple-600',
      badge: null,
    },
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">Panel de Control</h1>
        <p className="text-slate-400 mt-1">
          Bienvenido al sistema de auditoria interna EPMSA
        </p>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-blue-500/20 rounded-lg">
            <Clock className="w-6 h-6 text-blue-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Pendientes Hoy</p>
            <p className="text-2xl font-bold text-white">{pendingInspections}</p>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-emerald-500/20 rounded-lg">
            <CheckCircle2 className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Completadas</p>
            <p className="text-2xl font-bold text-white">0</p>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-amber-500/20 rounded-lg">
            <AlertCircle className="w-6 h-6 text-amber-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Por Sincronizar</p>
            <p className="text-2xl font-bold text-white">{pendingSync}</p>
          </div>
        </div>
      </div>

      {/* Navigation Cards */}
      <div>
        <h2 className="text-lg font-semibold text-white mb-4">Acceso Rapido</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {cards.map((card) => {
            const Icon = card.icon;
            return (
              <button
                key={card.id}
                onClick={() => setActiveTab(card.id)}
                className="group relative bg-slate-800/50 border border-slate-700 rounded-xl p-6 text-left transition-all duration-200 hover:border-slate-600 hover:bg-slate-800"
              >
                {card.badge && (
                  <span className="absolute top-4 right-4 bg-rose-500 text-white text-xs font-bold px-2 py-0.5 rounded-full">
                    {card.badge}
                  </span>
                )}
                
                <div className={`w-12 h-12 ${card.color} rounded-xl flex items-center justify-center mb-4 transition-transform group-hover:scale-110`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
                
                <h3 className="font-semibold text-white mb-1">{card.title}</h3>
                <p className="text-sm text-slate-400 mb-4">{card.description}</p>
                
                <div className="flex items-center text-sm text-indigo-400 group-hover:text-indigo-300">
                  <span>Ir al modulo</span>
                  <ChevronRight className="w-4 h-4 ml-1 transition-transform group-hover:translate-x-1" />
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Recent Activity Placeholder */}
      <div>
        <h2 className="text-lg font-semibold text-white mb-4">Actividad Reciente</h2>
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-6">
          <div className="text-center py-8">
            <FileText className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <p className="text-slate-400">No hay actividad reciente</p>
            <p className="text-sm text-slate-500 mt-1">
              Las inspecciones y sanciones registradas apareceran aqui
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
