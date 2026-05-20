'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { db, PenaltyCatalog } from '@/db/indexedDB';
import { OdooService } from '@/services/odooService';
import type { Inspection, InspectionType, UserSession, OdooConfig } from '@/types';

// Layout Components
import Sidebar from '@/components/dashboard/Sidebar';
import Header from '@/components/dashboard/Header';

// Dashboard Views
import HomeDashboard from '@/components/dashboard/HomeDashboard';
import AssignmentsDashboard from '@/components/dashboard/AssignmentsDashboard';
import PenaltiesDashboard from '@/components/dashboard/PenaltiesDashboard';
import SettingsDashboard from '@/components/dashboard/SettingsDashboard';
import InspectionsDashboard from '@/components/dashboard/InspectionsDashboard';
import FlightInspectionForm from '@/components/dashboard/FlightInspectionForm';
import NovedadesDashboard from '@/components/dashboard/NovedadesDashboard';
import AIAssistant from '@/components/dashboard/AIAssistant';

import { useNetwork } from '@/hooks/useNetwork';
import { Sparkles } from 'lucide-react';

export default function DashboardPage() {
  const router = useRouter();
  const isOnline = useNetwork();

  // Dashboard Shell states
  const [activeTab, setActiveTab] = useState('home');
  const [session, setSession] = useState<UserSession | null>(null);
  const [config, setConfig] = useState<OdooConfig | null>(null);
  const [showAIAssistant, setShowAIAssistant] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Flight Inspections
  const [flightInspections, setFlightInspections] = useState<Inspection[]>([]);
  const [selectedInspection, setSelectedInspection] = useState<Inspection | null>(null);
  const [selectedInspectionType, setSelectedInspectionType] = useState<InspectionType | null>(null);

  // Catalogs
  const [employees, setEmployees] = useState<{ id: number; name: string }[]>([]);
  const [nationalities, setNationalities] = useState<{ id: number; name: string }[]>([]);
  const [penaltiesCatalog, setPenaltiesCatalog] = useState<PenaltyCatalog[]>([]);

  // Pending counts for home dashboard
  const [pendingSync, setPendingSync] = useState(0);

  // Load session from localStorage
  useEffect(() => {
    const sessionStr = localStorage.getItem('epmsa_session');
    const configStr = localStorage.getItem('epmsa_odoo_config');
    
    if (!sessionStr) {
      router.replace('/login');
      return;
    }
    
    try {
      const parsedSession = JSON.parse(sessionStr);
      console.log('[v0] Loaded session - uid:', parsedSession.uid, 'sessionId length:', parsedSession.sessionId?.length);
      setSession(parsedSession);
      
      if (configStr) {
        setConfig(JSON.parse(configStr));
      }
    } catch {
      router.replace('/login');
    }
  }, [router]);

  // Load static catalogs from Local IndexedDB
  useEffect(() => {
    async function loadLocalCatalogs() {
      const dbCatalog = await db.penalties_catalog.toArray();
      setPenaltiesCatalog(dbCatalog);

      const dbUsers = await db.users.where('active').equals(1).toArray();
      setEmployees(dbUsers);

      // Count pending mutations
      const pending = await db.mutations.where('status').equals('pending').count();
      setPendingSync(pending);

      // Default fallback nationalities if empty
      setNationalities([
        { id: 1, name: 'Ecuatoriana' },
        { id: 2, name: 'Colombiana' },
        { id: 3, name: 'Venezolana' },
        { id: 4, name: 'Peruana' },
        { id: 5, name: 'Estadounidense' },
      ]);
    }
    loadLocalCatalogs();
  }, []);

  // ----------------------------------------------------
  // Sync Pipeline: AI Schema Checker & Odoo Proxy
  // ----------------------------------------------------
  const syncOfflineQueue = useCallback(async () => {
    const pending = await db.mutations.where('status').equals('pending').toArray();
    if (pending.length === 0) return;

    if (!config || !session) return;

    console.log(`Starting sync for ${pending.length} pending writes...`);

    for (const mut of pending) {
      await db.mutations.update(mut.id!, { status: 'processing' });

      try {
        // 1. Validate mutation details with serverless AI endpoint
        const valResponse = await fetch('/api/sync/validate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ mutation: mut }),
        });

        if (!valResponse.ok) {
          throw new Error('AI validator route failed');
        }

        const validation = await valResponse.json();

        if (!validation.isValid && validation.conflicts && validation.conflicts.length > 0) {
          const reasons = validation.conflicts.map((c: { issue: string }) => c.issue).join(', ');
          await db.mutations.update(mut.id!, {
            status: 'conflict',
            conflictReason: reasons,
          });
          console.warn(`Sync Conflict for mutation ${mut.id}: ${reasons}`);
          continue;
        }

        // Apply corrected payload proposed by AI if applicable
        const finalPayload = validation.suggestedPayload || mut.payload;

        // 2. Commit transaction to Odoo backend via proxy
        if (mut.type === 'create_penalty') {
          await OdooService.createPenalty(config, session.sessionId, finalPayload);
          if (mut.inspectionId) {
            await db.penalties.update(mut.inspectionId, { synced: 1 });
          }
        } else if (mut.type === 'sync_control') {
          await OdooService.syncControl(config, session.sessionId, finalPayload);
          if (mut.inspectionId) {
            await db.inspections.update(mut.inspectionId, { synced: 1 });
          }
        } else if (mut.type === 'sync_test') {
          await OdooService.syncAssignmentTest(config, session.sessionId, session.uid, finalPayload);
          if (mut.inspectionId) {
            await db.assignments_tests.update(mut.inspectionId, { synced: 1 });
          }
        } else if (mut.type === 'sync_photos') {
          if (finalPayload.isTest) {
            await OdooService.syncAssignmentTestPhotos(config, session.sessionId, finalPayload.testId, finalPayload.photos);
          } else {
            await OdooService.syncControlPhotos(config, session.sessionId, finalPayload);
          }
        }

        await db.mutations.update(mut.id!, { status: 'synced' });
        console.log(`Mutation ${mut.id} successfully synced with Odoo.`);
      } catch (err) {
        const error = err as Error;
        console.error(`Sync error on mutation ${mut.id}:`, error);
        await db.mutations.update(mut.id!, {
          status: 'failed',
          error: error.message || 'Error de conexion con Odoo proxy',
        });
      }
    }

    // Update pending count
    const newPending = await db.mutations.where('status').equals('pending').count();
    setPendingSync(newPending);
  }, [config, session]);

  // Trigger sync queue on network recovery or mount
  useEffect(() => {
    if (isOnline) {
      syncOfflineQueue();
    }
  }, [isOnline, syncOfflineQueue]);

  // Sync polling every 30 seconds if online
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isOnline) {
      interval = setInterval(() => {
        syncOfflineQueue();
      }, 30000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isOnline, syncOfflineQueue]);

  // ----------------------------------------------------
  // Refresh all data handler
  // ----------------------------------------------------
  const handleRefreshAssignments = async () => {
    if (!config || !session) return;
    setIsLoading(true);

    try {
      // 1. Fetch Assigned daily Controls (Flight Inspections)
      const controls = await OdooService.fetchAssignedControls(config, session.sessionId, session.uid);
      if (controls && controls.length > 0) {
        setFlightInspections(controls);
        // Cache them in local db
        await db.inspections.bulkPut(
          controls.map((c: Inspection) => ({
            id: c.id,
            type: c.type || 'none',
            operation: c.operation || 'none',
            flightType: c.flightType,
            assigned_user: session.name,
            status: 'Asignada',
            synced: 1,
          }))
        );
      }

      // 2. Fetch Assignments Inspections & Tests
      const insResult = await OdooService.fetchInspections(config, session.sessionId);
      if (insResult && insResult.result) {
        // Cache inspections assignments
      }

      const testsResult = await OdooService.fetchTests(config, session.sessionId);
      if (testsResult && testsResult.result) {
        await db.assignments_tests.bulkPut(
          testsResult.result.map((t) => ({
            id: t.id!,
            site_test: t.siteTest || 0,
            date_test: t.dateTest || '',
            time_test: t.timeTest || '',
            type: t.type || 'Procedimiento',
            status: 'Asignada',
            synced: 1,
          }))
        );
      }

      // 3. Sync User list / Infractors catalog
      const userList = await OdooService.fetchUsersList(config, session.sessionId);
      if (userList && userList.length > 0) {
        await db.users.bulkPut(
          userList.map((u) => ({
            id: u.id,
            name: u.name,
            active: 1,
          }))
        );
        const dbUsers = await db.users.where('active').equals(1).toArray();
        setEmployees(dbUsers);
      }

      // 4. Sync Penalty Catalog
      const penaltyList = await OdooService.fetchPenaltiesCatalog(config, session.sessionId);
      if (penaltyList && penaltyList.length > 0) {
        await db.penalties_catalog.bulkPut(
          penaltyList.map((p) => ({
            id: String(p.id),
            serverId: p.id,
            parentId: p.parentId,
            name: p.name,
            active: 1,
          }))
        );
        const dbCatalog = await db.penalties_catalog.toArray();
        setPenaltiesCatalog(dbCatalog);
      }

      // 5. Fetch ticket categories and levels for Novedades
      try {
        const categories = await OdooService.fetchTicketCategories(config, session.sessionId);
        const levels = await OdooService.fetchTicketLevels(config, session.sessionId);
        // Store in localStorage for now
        localStorage.setItem('epmsa_ticket_categories', JSON.stringify(categories));
        localStorage.setItem('epmsa_ticket_levels', JSON.stringify(levels));
      } catch (e) {
        console.warn('Could not fetch ticket catalogs:', e);
      }
    } catch (e) {
      console.error('Refresh assignments failed:', e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  };

  // Handle inspection selection
  const handleSelectInspection = (inspection: Inspection, type: InspectionType) => {
    setSelectedInspection(inspection);
    setSelectedInspectionType(type);
    
    // Navigate to the appropriate tab based on type
    switch (type) {
      case 'nationalArrival':
        setActiveTab('arrivals-national');
        break;
      case 'internationalArrival':
        setActiveTab('arrivals-international');
        break;
      case 'nationalDeparture':
        setActiveTab('departures-national');
        break;
      case 'internationalDeparture':
        setActiveTab('departures-international');
        break;
      case 'cargo':
        setActiveTab('cargo');
        break;
    }
  };

  // Render active view
  const renderActiveView = () => {
    switch (activeTab) {
      case 'home':
        return (
          <HomeDashboard
            setActiveTab={setActiveTab}
            pendingInspections={flightInspections.filter((i) => i.state === 'pending').length}
            pendingPenalties={0}
            pendingSync={pendingSync}
          />
        );

      case 'assignments':
        return <AssignmentsDashboard employees={employees} nationalities={nationalities} />;

      case 'penalties':
        return <PenaltiesDashboard catalog={penaltiesCatalog} />;

      case 'inspections':
        return (
          <InspectionsDashboard
            inspections={flightInspections}
            onSelectInspection={handleSelectInspection}
            onRefresh={handleRefreshAssignments}
            isLoading={isLoading}
          />
        );

      case 'arrivals-national':
      case 'arrivals-international':
      case 'departures-national':
      case 'departures-international':
      case 'cargo':
        if (selectedInspection && selectedInspectionType) {
          return (
            <FlightInspectionForm
              inspection={selectedInspection}
              inspectionType={selectedInspectionType}
              onClose={() => {
                setSelectedInspection(null);
                setSelectedInspectionType(null);
                setActiveTab('inspections');
              }}
              onSave={() => {
                setSelectedInspection(null);
                setSelectedInspectionType(null);
                setActiveTab('inspections');
                handleRefreshAssignments();
              }}
            />
          );
        }
        return (
          <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-12 text-center">
            <h2 className="text-xl font-semibold text-white mb-2">
              {activeTab === 'arrivals-national' && 'Arribos Nacionales'}
              {activeTab === 'arrivals-international' && 'Arribos Internacionales'}
              {activeTab === 'departures-national' && 'Salidas Nacionales'}
              {activeTab === 'departures-international' && 'Salidas Internacionales'}
              {activeTab === 'cargo' && 'Carga'}
            </h2>
            <p className="text-slate-400 mb-4">
              Selecciona una inspeccion desde el panel de Inspecciones de Vuelos
            </p>
            <button
              onClick={() => setActiveTab('inspections')}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors"
            >
              Ver Inspecciones
            </button>
          </div>
        );

      case 'novedades':
        return <NovedadesDashboard session={session} config={config} />;

      case 'settings':
        return <SettingsDashboard onSync={syncOfflineQueue} />;

      default:
        return <HomeDashboard setActiveTab={setActiveTab} />;
    }
  };

  return (
    <div className="flex h-screen bg-slate-950 overflow-hidden">
      {/* Sidebar Navigation */}
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} userName={session?.name} />

      {/* Main Panel Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
        <Header activeTab={activeTab} onRefresh={handleRefreshAssignments} onSync={syncOfflineQueue} />

        <main className="flex-1 overflow-y-auto p-8 bg-slate-950">{renderActiveView()}</main>

        {/* Floating Copilot Trigger Button */}
        {!showAIAssistant && (
          <button
            onClick={() => setShowAIAssistant(true)}
            className="absolute bottom-6 right-6 p-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full shadow-2xl flex items-center gap-1.5 transition-all duration-200 hover:scale-105 active:scale-95 z-40"
            title="Abrir Asistente Copiloto IA"
          >
            <Sparkles className="w-5 h-5 fill-white/20" />
            <span className="text-xs font-bold uppercase tracking-wider pr-1">Copiloto IA</span>
          </button>
        )}
      </div>

      {/* Right AI Copilot Drawer */}
      {showAIAssistant && (
        <AIAssistant
          onClose={() => setShowAIAssistant(false)}
          catalog={penaltiesCatalog}
          onAutofillPenalty={(data) => {
            setActiveTab('penalties');
            // Auto fill fields
            setTimeout(() => {
              const partnerInput = document.querySelector(
                'input[placeholder="Escribe para buscar infractor..."]'
              ) as HTMLInputElement;
              if (partnerInput && data.partnerName) {
                partnerInput.value = data.partnerName;
                partnerInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
              const severitySelect = document.querySelector('select') as HTMLSelectElement;
              if (severitySelect) {
                severitySelect.value = String(data.parentId);
                severitySelect.dispatchEvent(new Event('change', { bubbles: true }));
              }
              const obsTextArea = document.querySelector(
                'textarea[placeholder="Detalles sobre lo ocurrido, lugar, personas involucradas..."]'
              ) as HTMLTextAreaElement;
              if (obsTextArea) {
                obsTextArea.value = data.observations;
                obsTextArea.dispatchEvent(new Event('input', { bubbles: true }));
              }
            }, 500);
          }}
        />
      )}
    </div>
  );
}
