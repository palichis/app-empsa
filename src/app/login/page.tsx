'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { Settings, Lock, User, Server, AlertCircle } from 'lucide-react';
import { OdooService, OdooConfig } from '@/services/odooService';

export default function LoginPage() {
  const router = useRouter();
  
  // State variables
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Odoo config states
  const [showConfigModal, setShowConfigModal] = useState(false);
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
      } catch (e) {
        console.error('Error loading config', e);
      }
    }
  }, []);

  const handleSaveConfig = (e: React.FormEvent) => {
    e.preventDefault();
    const config: OdooConfig = { serverUrl, dbName };
    localStorage.setItem('epmsa_odoo_config', JSON.stringify(config));
    setShowConfigModal(false);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const config: OdooConfig = { serverUrl, dbName };
    localStorage.setItem('epmsa_odoo_config', JSON.stringify(config));

    try {
      console.log('Attempting authentication with config:', config);
      const authResult = await OdooService.authenticate(config, username, password);
      
      console.log('[v0] Auth successful - sessionId length:', authResult.sessionId?.length);
      
      // Save session details
      localStorage.setItem('epmsa_session', JSON.stringify(authResult));
      
      // Redirect to dashboard
      router.push('/dashboard');
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Error de conexión con el servidor de Odoo.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col flex-1 min-h-screen items-center justify-center bg-slate-950 px-4 relative overflow-hidden">
      {/* Background Gradients */}
      <div className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] rounded-full bg-indigo-900/10 blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] rounded-full bg-emerald-950/10 blur-[120px] pointer-events-none"></div>

      <div className="w-full max-w-md animate-fade-in z-10">
        {/* App Logo & Title */}
        <div className="flex flex-col items-center mb-8 text-center">
          <div className="relative w-44 h-20 mb-2">
            <Image
              src="/logo-epmsa.png"
              alt="Logo EPMSA"
              fill
              className="object-contain"
              priority
            />
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white mt-2">
            Auditorías e Infracciones
          </h1>
          <p className="text-slate-400 text-sm mt-1">
            Gestión interna de calidad y seguridad - Terminal UIO
          </p>
        </div>

        {/* Login Form Card */}
        <div className="glass-card p-8 shadow-2xl relative">
          {error && (
            <div className="mb-6 p-4 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-300 text-sm flex items-start space-x-2">
              <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-5">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
                Usuario Odoo
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-500">
                  <User className="w-5 h-5" />
                </span>
                <input
                  type="text"
                  required
                  placeholder="ej. juan.perez"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="glass-input w-full py-2.5 pl-10 pr-4 text-sm"
                  disabled={loading}
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">
                Contraseña
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-500">
                  <Lock className="w-5 h-5" />
                </span>
                <input
                  type="password"
                  required
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="glass-input w-full py-2.5 pl-10 pr-4 text-sm"
                  disabled={loading}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 px-4 rounded-lg bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 text-white font-semibold text-sm transition-all duration-200 shadow-lg shadow-indigo-600/20 disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center"
            >
              {loading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                  Iniciando sesión...
                </>
              ) : (
                'Iniciar Sesión'
              )}
            </button>
          </form>

          {/* Config Trigger */}
          <div className="mt-6 pt-6 border-t border-slate-800 text-center">
            <button
              onClick={() => setShowConfigModal(true)}
              className="inline-flex items-center text-xs text-indigo-400 hover:text-indigo-300 font-medium transition-colors"
            >
              <Settings className="w-3.5 h-3.5 mr-1" />
              Configurar Servidor Odoo
            </button>
          </div>
        </div>
      </div>

      {/* Dynamic Odoo Server Config Modal */}
      {showConfigModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="glass-card max-w-md w-full p-6 shadow-2xl animate-fade-in">
            <div className="flex items-center space-x-2 text-indigo-400 mb-4">
              <Server className="w-6 h-6" />
              <h2 className="text-lg font-bold text-white">Servidor Odoo ERP</h2>
            </div>
            
            <p className="text-xs text-slate-400 mb-4">
              Configura la conexión del servidor de Odoo donde se sincronizarán los formularios e infracciones.
            </p>

            <form onSubmit={handleSaveConfig} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-1.5">
                  URL del Servidor
                </label>
                <input
                  type="url"
                  required
                  placeholder="https://erppruebas.aeropuertoquito.gob.ec"
                  value={serverUrl}
                  onChange={(e) => setServerUrl(e.target.value)}
                  className="glass-input w-full py-2 px-3 text-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-1.5">
                  Base de Datos
                </label>
                <input
                  type="text"
                  required
                  placeholder="epmsa_pruebas"
                  value={dbName}
                  onChange={(e) => setDbName(e.target.value)}
                  className="glass-input w-full py-2 px-3 text-sm"
                />
              </div>

              <div className="flex space-x-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowConfigModal(false)}
                  className="flex-1 py-2 px-4 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-sm font-semibold transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 px-4 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-semibold transition-colors"
                >
                  Guardar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
