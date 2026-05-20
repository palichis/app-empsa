'use client';

import { useState, useEffect } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, Penalty, User, PenaltyCatalog } from '@/db/indexedDB';
import { Sparkles, Save, Search, AlertTriangle, FileText, CheckCircle2, History, BookOpen, Clock } from 'lucide-react';
import { useNetwork } from '@/hooks/useNetwork';

interface PenaltiesDashboardProps {
  catalog: PenaltyCatalog[];
}

export default function PenaltiesDashboard({ catalog }: PenaltiesDashboardProps) {
  const isOnline = useNetwork();
  
  // Panel Active Section
  const [activeSec, setActiveSec] = useState<'create' | 'history' | 'catalog'>('create');

  // Form States
  const [selectedPartnerId, setSelectedPartnerId] = useState<number>(0);
  const [selectedSeverity, setSelectedSeverity] = useState<number>(2); // 2 = Leve, 3 = Grave, 4 = Muy Grave
  const [selectedPenaltyId, setSelectedPenaltyId] = useState<number>(0);
  const [amount, setAmount] = useState<number>(50);
  const [observations, setObservations] = useState('');
  
  // Search states
  const [partnerQuery, setPartnerQuery] = useState('');
  const [showPartnerResults, setShowPartnerResults] = useState(false);
  const [aiInput, setAiInput] = useState('');
  const [aiLoading, setAiLoading] = useState(false);

  // Status flags
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  // Live Queries from Dexie DB
  const partners = useLiveQuery(
    () => db.users.where('active').equals(1).toArray()
  ) || [];

  const loggedPenalties = useLiveQuery(
    () => db.penalties.reverse().toArray()
  ) || [];

  // Filter partners list based on query
  const filteredPartners = partners.filter(p =>
    p.name.toLowerCase().includes(partnerQuery.toLowerCase())
  );

  // Sync amount based on selected severity
  useEffect(() => {
    if (selectedSeverity === 2) setAmount(50);
    else if (selectedSeverity === 3) setAmount(100);
    else if (selectedSeverity === 4) setAmount(200);
  }, [selectedSeverity]);

  // Filter penalties catalog dropdown depending on active severity
  const filteredCatalog = catalog.filter(c => c.parentId === selectedSeverity);

  // Natural Language AI Auto-Fill Handler
  const handleAIAutofill = async () => {
    if (!aiInput.trim()) return;
    setAiLoading(true);
    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          mode: 'extract',
          text: aiInput,
          catalog: catalog,
        }),
      });

      if (response.ok) {
        const result = await response.json();
        if (result.parentId) setSelectedSeverity(result.parentId);
        if (result.amount) setAmount(result.amount);
        if (result.observations) setObservations(result.observations);
        
        // Search infractor if extracted name
        if (result.partnerName) {
          setPartnerQuery(result.partnerName);
          const match = partners.find(p => p.name.toLowerCase().includes(result.partnerName.toLowerCase()));
          if (match) {
            setSelectedPartnerId(match.id);
            setPartnerQuery(match.name);
          }
        }
      }
    } catch (e) {
      console.error(e);
    } finally {
      setAiLoading(false);
      setAiInput('');
    }
  };

  // Submit Penalty form handler
  const handleCreatePenalty = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedPartnerId === 0) {
      alert('Por favor selecciona un infractor de la lista.');
      return;
    }
    setLoading(true);

    const newPenalty: Penalty = {
      partnerId: selectedPartnerId,
      parentId: selectedSeverity,
      penaltyId: selectedPenaltyId || (filteredCatalog[0]?.serverId ?? 0),
      date: new Date().toISOString().substring(0, 10),
      amount: amount,
      status: 'pending',
      observations: observations,
      synced: 0,
    };

    // Save to Local DB
    const localId = await db.penalties.add(newPenalty);

    // Queue mutation for Odoo sync
    await db.mutations.add({
      type: 'create_penalty',
      inspectionId: localId,
      payload: newPenalty,
      timestamp: Date.now(),
      status: 'pending',
    });

    // Reset Form
    setSelectedPartnerId(0);
    setPartnerQuery('');
    setSelectedPenaltyId(0);
    setObservations('');
    
    setLoading(false);
    setSuccess(true);
    setTimeout(() => setSuccess(false), 2000);
  };

  const getSeverityName = (parentId: number) => {
    if (parentId === 2) return 'Leve';
    if (parentId === 3) return 'Grave';
    return 'Muy Grave';
  };

  const getSeverityStyle = (parentId: number) => {
    if (parentId === 2) return 'text-sky-400 bg-sky-500/10 border-sky-500/25';
    if (parentId === 3) return 'text-amber-400 bg-amber-500/10 border-amber-500/25';
    return 'text-rose-400 bg-rose-500/10 border-rose-500/25';
  };

  const renderNavTab = (id: 'create' | 'history' | 'catalog', label: string, icon: any) => {
    const Icon = icon;
    const isAct = activeSec === id;
    return (
      <button
        onClick={() => setActiveSec(id)}
        className={`flex items-center space-x-1.5 px-4 py-2 text-xs font-semibold border-b-2 transition-colors ${
          isAct
            ? 'border-indigo-500 text-white bg-indigo-500/5'
            : 'border-transparent text-slate-400 hover:text-slate-200'
        }`}
      >
        <Icon className="w-3.5 h-3.5" />
        <span>{label}</span>
      </button>
    );
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto p-2">
      {/* Navigation tabs */}
      <div className="flex border-b border-slate-800">
        {renderNavTab('create', 'Registrar Infracción', AlertTriangle)}
        {renderNavTab('history', 'Historial Local', History)}
        {renderNavTab('catalog', 'Catálogo de Multas', BookOpen)}
      </div>

      {success && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/25 text-emerald-300 text-sm rounded-lg flex items-center space-x-2 animate-fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span>Infracción registrada localmente y añadida a la cola de sincronización.</span>
        </div>
      )}

      {/* CREATE TAB */}
      {activeSec === 'create' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Form Side */}
          <div className="md:col-span-2 glass-card p-6 shadow-xl space-y-4">
            <h3 className="text-sm font-bold text-white uppercase border-b border-slate-800 pb-2 flex items-center">
              <FileText className="w-4 h-4 mr-2 text-indigo-400" />
              Nueva Infracción / Acta
            </h3>

            <form onSubmit={handleCreatePenalty} className="space-y-4 text-xs">
              {/* Partner selection search */}
              <div className="relative">
                <label className="block text-slate-400 mb-1">Empresa / Infractor</label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 pl-2.5 flex items-center text-slate-500">
                    <Search className="w-4 h-4" />
                  </span>
                  <input
                    type="text"
                    placeholder="Escribe para buscar infractor..."
                    value={partnerQuery}
                    onChange={e => {
                      setPartnerQuery(e.target.value);
                      setShowPartnerResults(true);
                    }}
                    onFocus={() => setShowPartnerResults(true)}
                    className="glass-input w-full py-2 pl-9 pr-4"
                  />
                </div>
                {/* Search suggestions dropdown */}
                {showPartnerResults && partnerQuery.trim() !== '' && (
                  <div className="absolute left-0 right-0 mt-1 max-h-40 overflow-y-auto bg-slate-900 border border-slate-850 rounded-lg shadow-xl z-20">
                    {filteredPartners.length === 0 ? (
                      <p className="p-2 text-slate-500 italic text-[11px]">No se encontraron infractores</p>
                    ) : (
                      filteredPartners.map(p => (
                        <button
                          key={p.id}
                          type="button"
                          onClick={() => {
                            setSelectedPartnerId(p.id);
                            setPartnerQuery(p.name);
                            setShowPartnerResults(false);
                          }}
                          className="w-full text-left p-2.5 hover:bg-indigo-600 hover:text-white text-slate-350 text-[11px] transition-colors border-b border-slate-850/50"
                        >
                          {p.name}
                        </button>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Severity and fine code */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-400 mb-1">Gravedad</label>
                  <select
                    value={selectedSeverity}
                    onChange={e => {
                      const sev = parseInt(e.target.value);
                      setSelectedSeverity(sev);
                      setSelectedPenaltyId(0); // reset sub-category
                    }}
                    className="glass-input w-full p-2 bg-slate-900"
                  >
                    <option value={2}>Leve ($50)</option>
                    <option value={3}>Grave ($100)</option>
                    <option value={4}>Muy Grave ($200)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">Monto de Multa</label>
                  <span className="block p-2 bg-slate-950/40 border border-slate-850 rounded text-slate-200 font-bold text-center">
                    ${amount}
                  </span>
                </div>
              </div>

              {/* Penalty code dropdown */}
              <div>
                <label className="block text-slate-400 mb-1">Artículo / Catálogo de Penalizaciones</label>
                <select
                  value={selectedPenaltyId}
                  onChange={e => setSelectedPenaltyId(parseInt(e.target.value))}
                  className="glass-input w-full p-2 bg-slate-900 text-[11px]"
                >
                  <option value={0}>Selecciona del catálogo...</option>
                  {filteredCatalog.map(item => (
                    <option key={item.serverId} value={item.serverId}>
                      {item.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Observations */}
              <div>
                <label className="block text-slate-400 mb-1">Descripción del Incidente / Observaciones</label>
                <textarea
                  required
                  placeholder="Detalles sobre lo ocurrido, lugar, personas involucradas..."
                  value={observations}
                  onChange={e => setObservations(e.target.value)}
                  className="glass-input w-full p-2.5 h-24 resize-none"
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg font-semibold flex items-center justify-center space-x-1.5 transition-colors shadow-lg shadow-indigo-650/10"
              >
                <Save className="w-4 h-4" />
                <span>Registrar Sanción Local</span>
              </button>
            </form>
          </div>

          {/* AI Helper Side */}
          <div className="glass-card p-5 shadow-xl border border-indigo-500/10 space-y-3.5">
            <div className="flex items-center space-x-2 text-indigo-400">
              <Sparkles className="w-5 h-5 fill-indigo-400/25 animate-pulse" />
              <h4 className="font-bold text-white text-xs">Asistente de Relleno IA</h4>
            </div>
            
            <p className="text-[11px] text-slate-400 leading-relaxed">
              ¿Quieres rellenar este acta rápidamente? Escribe la descripción completa en tus propias palabras y la IA determinará la clasificación y el infractor por ti.
            </p>

            <div className="space-y-3">
              <textarea
                placeholder="Ej: Local SweetBite no tenía los extinguidores recargados hoy en la mañana a las 9am. Le notificamos al supervisor Ramos."
                value={aiInput}
                onChange={e => setAiInput(e.target.value)}
                className="glass-input w-full p-2.5 text-[11px] h-28 resize-none"
                disabled={aiLoading}
              />
              <button
                type="button"
                onClick={handleAIAutofill}
                disabled={aiLoading || !aiInput.trim()}
                className="w-full py-2 bg-indigo-550 hover:bg-indigo-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center space-x-1.5 transition-colors"
              >
                {aiLoading ? (
                  <>
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    <span>Procesando...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="w-3.5 h-3.5" />
                    <span>Llenar con IA</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* HISTORY TAB */}
      {activeSec === 'history' && (
        <div className="glass-card p-6 shadow-xl space-y-4">
          <h3 className="text-sm font-bold text-white uppercase border-b border-slate-800 pb-2">
            Infracciones Registradas Localmente
          </h3>

          {loggedPenalties.length === 0 ? (
            <p className="text-slate-500 text-center py-8 italic text-xs">No hay infracciones registradas en esta sesión local.</p>
          ) : (
            <div className="overflow-x-auto border border-slate-800 rounded-lg">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-900 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
                    <th className="p-3">Infractor</th>
                    <th className="p-3">Gravedad</th>
                    <th className="p-3 text-center">Monto</th>
                    <th className="p-3">Fecha</th>
                    <th className="p-3">Observaciones</th>
                    <th className="p-3 text-center">Estado Odoo</th>
                  </tr>
                </thead>
                <tbody>
                  {loggedPenalties.map(p => {
                    const partnerName = partners.find(partner => partner.id === p.partnerId)?.name || `ID Partner: ${p.partnerId}`;
                    return (
                      <tr key={p.id} className="border-b border-slate-850 hover:bg-slate-850/20">
                        <td className="p-3 font-semibold text-slate-200 max-w-[150px] truncate">{partnerName}</td>
                        <td className="p-3">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-semibold border ${getSeverityStyle(p.parentId)}`}>
                            {getSeverityName(p.parentId)}
                          </span>
                        </td>
                        <td className="p-3 text-center font-bold text-slate-200">${p.amount}</td>
                        <td className="p-3 text-slate-450">{p.date}</td>
                        <td className="p-3 text-slate-400 max-w-[200px] truncate" title={p.observations}>{p.observations}</td>
                        <td className="p-3 text-center">
                          <span
                            className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                              p.synced === 1
                                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                                : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                            }`}
                          >
                            {p.synced === 1 ? 'Sincronizado' : 'Pendiente'}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* STATIC CATALOG TAB */}
      {activeSec === 'catalog' && (
        <div className="glass-card p-6 shadow-xl space-y-4">
          <h3 className="text-sm font-bold text-white uppercase border-b border-slate-800 pb-2">
            Catálogo de Multas y Penalidades EPMSA
          </h3>

          <div className="grid grid-cols-3 gap-2 pb-2">
            <button
              onClick={() => setSelectedSeverity(2)}
              className={`py-2 px-3 rounded-lg text-xs font-semibold border transition-all ${
                selectedSeverity === 2
                  ? 'bg-indigo-600 border-indigo-500 text-white'
                  : 'bg-slate-900 border-slate-800 text-slate-400'
              }`}
            >
              Leves ($50)
            </button>
            <button
              onClick={() => setSelectedSeverity(3)}
              className={`py-2 px-3 rounded-lg text-xs font-semibold border transition-all ${
                selectedSeverity === 3
                  ? 'bg-indigo-600 border-indigo-500 text-white'
                  : 'bg-slate-900 border-slate-800 text-slate-400'
              }`}
            >
              Graves ($100)
            </button>
            <button
              onClick={() => setSelectedSeverity(4)}
              className={`py-2 px-3 rounded-lg text-xs font-semibold border transition-all ${
                selectedSeverity === 4
                  ? 'bg-indigo-600 border-indigo-500 text-white'
                  : 'bg-slate-900 border-slate-800 text-slate-400'
              }`}
            >
              Muy Graves ($200)
            </button>
          </div>

          <div className="space-y-2 max-h-96 overflow-y-auto pr-1">
            {filteredCatalog.map(item => (
              <div key={item.id} className="p-3 bg-slate-950/20 border border-slate-850 rounded-lg text-xs">
                <p className="font-bold text-slate-200">{item.name}</p>
                <span className="text-[10px] text-slate-500 mt-1 block">Código Odoo: {item.serverId}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
