'use client';

import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { 
  ClipboardList, 
  AlertTriangle, 
  Settings, 
  LogOut, 
  ShieldAlert,
  Plane,
  PlaneLanding,
  PlaneTakeoff,
  Package,
  FileText,
  Home
} from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  userName?: string;
}

export default function Sidebar({ activeTab, setActiveTab, userName }: SidebarProps) {
  const router = useRouter();

  const handleLogout = () => {
    localStorage.removeItem('epmsa_session');
    router.push('/login');
  };

  const mainNavItems = [
    { id: 'home', label: 'Inicio', icon: Home },
    { id: 'assignments', label: 'Mis Asignaciones', icon: ClipboardList },
    { id: 'penalties', label: 'Sanciones', icon: AlertTriangle },
  ];

  const inspectionNavItems = [
    { id: 'inspections', label: 'Inspecciones Vuelos', icon: Plane },
    { id: 'arrivals-national', label: 'Arribos Nacionales', icon: PlaneLanding },
    { id: 'arrivals-international', label: 'Arribos Internacionales', icon: PlaneLanding },
    { id: 'departures-national', label: 'Salidas Nacionales', icon: PlaneTakeoff },
    { id: 'departures-international', label: 'Salidas Internacionales', icon: PlaneTakeoff },
    { id: 'cargo', label: 'Carga', icon: Package },
  ];

  const secondaryNavItems = [
    { id: 'novedades', label: 'Novedades', icon: FileText },
    { id: 'settings', label: 'Configuracion', icon: Settings },
  ];

  return (
    <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col h-full">
      {/* Brand Header */}
      <div className="p-6 border-b border-slate-800 flex flex-col items-center">
        <div className="relative w-32 h-14 mb-1">
          <Image
            src="/logo-epmsa.png"
            alt="Logo EPMSA"
            fill
            className="object-contain"
            priority
          />
        </div>
        <div className="flex items-center gap-1.5 mt-2 bg-indigo-500/10 text-indigo-400 px-2 py-0.5 rounded-full text-xs font-semibold">
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>Auditoria Interna</span>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-3 py-4 space-y-4 overflow-y-auto">
        {/* Main Navigation */}
        <div className="space-y-1">
          {mainNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150 ${
                  isActive
                    ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/10'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                }`}
              >
                <Icon className="w-5 h-5 flex-shrink-0" />
                <span>{item.label}</span>
              </button>
            );
          })}
        </div>

        {/* Inspections Section */}
        <div className="space-y-1">
          <p className="px-3 py-2 text-xs font-semibold text-slate-500 uppercase tracking-wider">
            Inspecciones
          </p>
          {inspectionNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-150 ${
                  isActive
                    ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/10'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                }`}
              >
                <Icon className="w-4 h-4 flex-shrink-0" />
                <span className="truncate">{item.label}</span>
              </button>
            );
          })}
        </div>

        {/* Secondary Navigation */}
        <div className="space-y-1 pt-2 border-t border-slate-800">
          {secondaryNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150 ${
                  isActive
                    ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/10'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                }`}
              >
                <Icon className="w-5 h-5 flex-shrink-0" />
                <span>{item.label}</span>
              </button>
            );
          })}
        </div>
      </nav>

      {/* User Status / Logout */}
      <div className="p-4 border-t border-slate-800 bg-slate-900/50">
        <div className="mb-3 px-2">
          <p className="text-xs text-slate-500 uppercase tracking-wider font-semibold">Inspector</p>
          <p className="text-sm font-semibold text-slate-200 truncate">{userName || 'Usuario Odoo'}</p>
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium text-rose-400 hover:bg-rose-500/10 transition-colors"
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          <span>Cerrar Sesion</span>
        </button>
      </div>
    </aside>
  );
}
