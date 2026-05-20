'use client';

import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { ClipboardList, AlertTriangle, Settings, LogOut, ShieldAlert } from 'lucide-react';

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

  const navItems = [
    { id: 'assignments', label: 'Mis Asignaciones', icon: ClipboardList },
    { id: 'penalties', label: 'Sanciones', icon: AlertTriangle },
    { id: 'settings', label: 'Configuración', icon: Settings },
  ];

  return (
    <aside className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col h-full">
      {/* Brand Header */}
      <div className="p-6 border-b border-slate-850 flex flex-col items-center">
        <div className="relative w-32 h-14 mb-1">
          <Image
            src="/logo-epmsa.png"
            alt="Logo EPMSA"
            fill
            className="object-contain"
            priority
          />
        </div>
        <div className="flex items-center space-x-1.5 mt-2 bg-indigo-500/10 text-indigo-400 px-2 py-0.5 rounded-full text-xs font-semibold">
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>Auditoría Interna</span>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 px-4 py-6 space-y-1.5">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/10'
                  : 'text-slate-400 hover:bg-slate-850 hover:text-slate-200'
              }`}
            >
              <Icon className="w-5 h-5 flex-shrink-0" />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* User Status / Logout */}
      <div className="p-4 border-t border-slate-850 bg-slate-900/50">
        <div className="mb-3 px-2">
          <p className="text-xs text-slate-500 uppercase tracking-wider font-semibold">Inspector</p>
          <p className="text-sm font-semibold text-slate-200 truncate">{userName || 'Usuario Odoo'}</p>
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center space-x-3 px-4 py-2.5 rounded-lg text-sm font-medium text-rose-400 hover:bg-rose-500/10 transition-colors"
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          <span>Cerrar Sesión</span>
        </button>
      </div>
    </aside>
  );
}
