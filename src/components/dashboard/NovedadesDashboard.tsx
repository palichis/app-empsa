'use client';

import { useState, useEffect } from 'react';
import { 
  FileText, 
  Send, 
  Clock, 
  MapPin, 
  Tag, 
  AlertTriangle,
  CheckCircle2,
  RefreshCw,
  Plus,
  X
} from 'lucide-react';
import { db } from '@/db/indexedDB';
import { OdooService } from '@/services/odooService';
import type { Category, Criticality, Novelty, OdooConfig, UserSession } from '@/types';

interface NovedadesDashboardProps {
  session: UserSession | null;
  config: OdooConfig | null;
}

export default function NovedadesDashboard({ session, config }: NovedadesDashboardProps) {
  const [isCreating, setIsCreating] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState(new Date().toISOString().substring(0, 16));
  const [place, setPlace] = useState('');
  const [categoryId, setCategoryId] = useState<number>(0);
  const [criticalityId, setCriticalityId] = useState<number>(0);
  const [inspectionId, setInspectionId] = useState<number>(0);
  const [isInspection, setIsInspection] = useState(true);

  // Catalogs
  const [categories, setCategories] = useState<Category[]>([]);
  const [criticalities, setCriticalities] = useState<Criticality[]>([]);

  // Load catalogs from localStorage
  useEffect(() => {
    const storedCategories = localStorage.getItem('epmsa_ticket_categories');
    const storedLevels = localStorage.getItem('epmsa_ticket_levels');

    if (storedCategories) {
      try {
        const parsed = JSON.parse(storedCategories);
        setCategories(parsed);
        if (parsed.length > 0) setCategoryId(parsed[0].id);
      } catch (e) {
        console.error('Error parsing categories:', e);
      }
    }

    if (storedLevels) {
      try {
        const parsed = JSON.parse(storedLevels);
        setCriticalities(parsed);
        if (parsed.length > 0) setCriticalityId(parsed[0].id);
      } catch (e) {
        console.error('Error parsing criticalities:', e);
      }
    }
  }, []);

  // Fetch catalogs from API
  const fetchCatalogs = async () => {
    if (!config || !session) return;

    try {
      const [cats, levels] = await Promise.all([
        OdooService.fetchTicketCategories(config, session.sessionId),
        OdooService.fetchTicketLevels(config, session.sessionId),
      ]);

      setCategories(cats);
      setCriticalities(levels);
      localStorage.setItem('epmsa_ticket_categories', JSON.stringify(cats));
      localStorage.setItem('epmsa_ticket_levels', JSON.stringify(levels));

      if (cats.length > 0) setCategoryId(cats[0].id);
      if (levels.length > 0) setCriticalityId(levels[0].id);
    } catch (e) {
      console.error('Error fetching catalogs:', e);
    }
  };

  const resetForm = () => {
    setName('');
    setDescription('');
    setDate(new Date().toISOString().substring(0, 16));
    setPlace('');
    setInspectionId(0);
    setIsInspection(true);
    if (categories.length > 0) setCategoryId(categories[0].id);
    if (criticalities.length > 0) setCriticalityId(criticalities[0].id);
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name.trim()) {
      setError('El titulo es requerido');
      return;
    }
    if (!description.trim()) {
      setError('La descripcion es requerida');
      return;
    }
    if (!place.trim()) {
      setError('El lugar es requerido');
      return;
    }

    setLoading(true);
    setError(null);

    const novelty: Novelty = {
      name,
      description,
      date: new Date(date).toISOString(),
      categoryId,
      criticalityId,
      place,
      inspectionId,
      isInspection,
    };

    try {
      if (config && session) {
        // Try to sync immediately if online
        const result = await OdooService.createTicket(config, session.sessionId, novelty);
        if (result) {
          setSuccess(true);
          setTimeout(() => {
            setSuccess(false);
            setIsCreating(false);
            resetForm();
          }, 2000);
        } else {
          // Save locally for later sync
          await saveLocally(novelty);
        }
      } else {
        // Save locally
        await saveLocally(novelty);
      }
    } catch (err) {
      console.error('Error creating novelty:', err);
      // Save locally on error
      await saveLocally(novelty);
    } finally {
      setLoading(false);
    }
  };

  const saveLocally = async (novelty: Novelty) => {
    // Save to IndexedDB mutations queue
    await db.mutations.add({
      type: 'create_novelty',
      payload: novelty,
      timestamp: Date.now(),
      status: 'pending',
    });
    
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      setIsCreating(false);
      resetForm();
    }, 2000);
  };

  if (isCreating) {
    return (
      <div className="max-w-2xl mx-auto">
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-6">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-white">Nueva Novedad</h2>
            <button
              onClick={() => {
                setIsCreating(false);
                resetForm();
              }}
              className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
            >
              <X className="w-5 h-5 text-slate-400" />
            </button>
          </div>

          {/* Success Message */}
          {success && (
            <div className="mb-4 bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 rounded-lg p-4 flex items-center gap-3">
              <CheckCircle2 className="w-5 h-5" />
              <span>Novedad creada exitosamente</span>
            </div>
          )}

          {/* Error Message */}
          {error && (
            <div className="mb-4 bg-rose-500/20 border border-rose-500/30 text-rose-400 rounded-lg p-4 flex items-center gap-3">
              <AlertTriangle className="w-5 h-5" />
              <span>{error}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm text-slate-400 mb-1">Titulo</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Titulo de la novedad"
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-slate-400 mb-1">Descripcion</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Descripcion detallada del incidente"
                rows={3}
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                required
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Fecha y Hora</label>
                <input
                  type="datetime-local"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Lugar</label>
                <input
                  type="text"
                  value={place}
                  onChange={(e) => setPlace(e.target.value)}
                  placeholder="Ubicacion del incidente"
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Categoria</label>
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(parseInt(e.target.value))}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {categories.map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                  {categories.length === 0 && (
                    <option value={0}>Cargando categorias...</option>
                  )}
                </select>
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-1">Criticidad</label>
                <select
                  value={criticalityId}
                  onChange={(e) => setCriticalityId(parseInt(e.target.value))}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {criticalities.map((crit) => (
                    <option key={crit.id} value={crit.id}>
                      {crit.name}
                    </option>
                  ))}
                  {criticalities.length === 0 && (
                    <option value={0}>Cargando niveles...</option>
                  )}
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm text-slate-400 mb-1">Tipo de Reporte</label>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    checked={isInspection}
                    onChange={() => setIsInspection(true)}
                    className="w-4 h-4 text-indigo-600"
                  />
                  <span className="text-white">Inspeccion</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    checked={!isInspection}
                    onChange={() => setIsInspection(false)}
                    className="w-4 h-4 text-indigo-600"
                  />
                  <span className="text-white">Prueba</span>
                </label>
              </div>
            </div>

            <div>
              <label className="block text-sm text-slate-400 mb-1">
                ID de {isInspection ? 'Inspeccion' : 'Prueba'} (opcional)
              </label>
              <input
                type="number"
                value={inspectionId || ''}
                onChange={(e) => setInspectionId(parseInt(e.target.value) || 0)}
                placeholder={`ID de ${isInspection ? 'inspeccion' : 'prueba'} relacionada`}
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="flex gap-3 pt-4">
              <button
                type="button"
                onClick={() => {
                  setIsCreating(false);
                  resetForm();
                }}
                className="flex-1 px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={loading}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors disabled:opacity-50"
              >
                {loading ? (
                  <RefreshCw className="w-4 h-4 animate-spin" />
                ) : (
                  <Send className="w-4 h-4" />
                )}
                <span>Enviar</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Novedades</h1>
          <p className="text-slate-400 mt-1">
            Registro de tickets e incidentes
          </p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={fetchCatalogs}
            className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            <span>Actualizar Catalogos</span>
          </button>
          <button
            onClick={() => setIsCreating(true)}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>Nueva Novedad</span>
          </button>
        </div>
      </div>

      {/* Info Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-blue-500/20 rounded-lg">
            <Tag className="w-6 h-6 text-blue-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Categorias</p>
            <p className="text-2xl font-bold text-white">{categories.length}</p>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-amber-500/20 rounded-lg">
            <AlertTriangle className="w-6 h-6 text-amber-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Niveles de Criticidad</p>
            <p className="text-2xl font-bold text-white">{criticalities.length}</p>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 bg-emerald-500/20 rounded-lg">
            <FileText className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <p className="text-sm text-slate-400">Estado</p>
            <p className="text-lg font-semibold text-emerald-400">
              {config && session ? 'Conectado' : 'Sin conexion'}
            </p>
          </div>
        </div>
      </div>

      {/* Empty State */}
      <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-12 text-center">
        <FileText className="w-16 h-16 text-slate-600 mx-auto mb-4" />
        <h3 className="text-lg font-semibold text-white mb-2">
          Registro de Novedades
        </h3>
        <p className="text-slate-400 max-w-md mx-auto mb-6">
          Crea tickets de novedades e incidentes relacionados con inspecciones o pruebas de seguridad.
        </p>
        <button
          onClick={() => setIsCreating(true)}
          className="inline-flex items-center gap-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>Crear Nueva Novedad</span>
        </button>
      </div>

      {/* Categories List */}
      {categories.length > 0 && (
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-4">Categorias Disponibles</h3>
          <div className="flex flex-wrap gap-2">
            {categories.map((cat) => (
              <span
                key={cat.id}
                className="px-3 py-1.5 bg-slate-700 text-slate-200 rounded-lg text-sm"
              >
                {cat.name}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Criticality Levels */}
      {criticalities.length > 0 && (
        <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-4">Niveles de Criticidad</h3>
          <div className="flex flex-wrap gap-2">
            {criticalities.map((crit, index) => {
              const colors = [
                'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
                'bg-amber-500/20 text-amber-400 border-amber-500/30',
                'bg-rose-500/20 text-rose-400 border-rose-500/30',
              ];
              return (
                <span
                  key={crit.id}
                  className={`px-3 py-1.5 rounded-lg text-sm border ${colors[index % colors.length]}`}
                >
                  {crit.name}
                </span>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
