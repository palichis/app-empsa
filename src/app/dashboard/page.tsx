'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, PenaltyCatalog } from '@/db/indexedDB';
import { OdooService } from '@/services/odooService';
import Sidebar from '@/components/dashboard/Sidebar';
import Header from '@/components/dashboard/Header';
import AssignmentsDashboard from '@/components/dashboard/AssignmentsDashboard';
import PenaltiesDashboard from '@/components/dashboard/PenaltiesDashboard';
import SettingsDashboard from '@/components/dashboard/SettingsDashboard';
import AIAssistant from '@/components/dashboard/AIAssistant';
import { useNetwork } from '@/hooks/useNetwork';
import { Sparkles } from 'lucide-react';

export default function DashboardPage() {
  const router = useRouter();
  const isOnline = useNetwork();
  
  // Dashboard Shell states
  const [activeTab, setActiveTab] = useState('assignments');
  const [session, setSession] = useState<any>(null);
  const [showAIAssistant, setShowAIAssistant] = useState(false);

  // Catalogs
  const [employees, setEmployees] = useState<any[]>([]);
  const [nationalities, setNationalities] = useState<any[]>([]);
  const [penaltiesCatalog, setPenaltiesCatalog] = useState<PenaltyCatalog[]>([]);

  // Load session from localstorage
  useEffect(() => {
    const sessionStr = localStorage.getItem('epmsa_session');
    if (!sessionStr) {
      router.replace('/login');
      return;
    }
    try {
      const parsed = JSON.parse(sessionStr);
      console.log('[v0] Loaded session - uid:', parsed.uid, 'sessionId length:', parsed.sessionId?.length);
      setSession(parsed);
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

    const configStr = localStorage.getItem('epmsa_odoo_config');
    const sessionStr = localStorage.getItem('epmsa_session');
    if (!configStr || !sessionStr) return;

    const config = JSON.parse(configStr);
    const session = JSON.parse(sessionStr);

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
          const reasons = validation.conflicts.map((c: any) => c.issue).join(', ');
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
          await OdooService.syncAssignmentTest(config, session.sessionId, finalPayload);
          if (mut.inspectionId) {
            await db.assignments_tests.update(mut.inspectionId, { synced: 1 });
          }
        } else if (mut.type === 'sync_photos') {
          if (finalPayload.isTest) {
            await OdooService.syncAssignmentTestPhotos(config, session.sessionId, finalPayload);
          } else {
            await OdooService.syncPhotos(config, session.sessionId, finalPayload);
          }
        }

        await db.mutations.update(mut.id!, { status: 'synced' });
        console.log(`Mutation ${mut.id} successfully synced with Odoo.`);
      } catch (err: any) {
        console.error(`Sync error on mutation ${mut.id}:`, err);
        await db.mutations.update(mut.id!, {
          status: 'failed',
          error: err.message || 'Error de conexión con Odoo proxy',
        });
      }
    }
  }, []);

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
  // Refresh assignments handler
  // ----------------------------------------------------
  const handleRefreshAssignments = async () => {
    const configStr = localStorage.getItem('epmsa_odoo_config');
    if (!configStr || !session) return;
    const config = JSON.parse(configStr);

    try {
      // 1. Fetch Assigned daily Controls
      const controls = await OdooService.fetchAssignedControls(config, session.sessionId, session.uid);
      if (controls && controls.length > 0) {
        // Cache them in local db
        await db.inspections.bulkPut(controls.map((c: any) => ({
          id: c.id,
          type: c.type || 'none',
          operation: c.operation || 'none',
          flightType: c.flight_type,
          assigned_user: session.name,
          status: 'Asignada',
          synced: 1,
        })));
      }

      // 2. Fetch Assignments Inspections & Tests
      const insResult = await OdooService.fetchInspections(config, session.sessionId);
      if (insResult && insResult.data) {
        // map/cache general inspections
      }

      const testsResult = await OdooService.fetchTests(config, session.sessionId);
      if (testsResult && testsResult.data) {
        await db.assignments_tests.bulkPut(testsResult.data.map((t: any) => ({
          id: t.id,
          site_test: t.site_test_id,
          date_test: t.date_test,
          time_test: t.time_test,
          type: t.type_test_name || 'Procedimiento',
          status: 'Asignada',
          synced: 1,
        })));
      }

      // 3. Sync User list / Infractors catalog
      const userList = await OdooService.fetchUsersList(config, session.sessionId);
      if (userList && userList.length > 0) {
        await db.users.bulkPut(userList.map((u: any) => ({
          id: u.id,
          name: u.name,
          active: 1,
        })));
        const dbUsers = await db.users.where('active').equals(1).toArray();
        setEmployees(dbUsers);
      }

      // 4. Sync Penalty Catalog
      const penaltyList = await OdooService.fetchPenaltiesCatalog(config, session.sessionId);
      if (penaltyList && penaltyList.length > 0) {
        await db.penalties_catalog.bulkPut(penaltyList.map((p: any) => ({
          id: String(p.id),
          serverId: p.id,
          parentId: p.parent_id,
          name: p.name,
          active: 1,
        })));
        const dbCatalog = await db.penalties_catalog.toArray();
        setPenaltiesCatalog(dbCatalog);
      }

    } catch (e) {
      console.error('Refresh assignments failed:', e);
      throw e;
    }
  };

  return (
    <div className="flex h-screen bg-slate-950 overflow-hidden">
      {/* Sidebar Navigation */}
      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        userName={session?.name}
      />

      {/* Main Panel Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
        <Header
          activeTab={activeTab}
          onRefresh={handleRefreshAssignments}
          onSync={syncOfflineQueue}
        />

        <main className="flex-1 overflow-y-auto p-8 bg-slate-950">
          {activeTab === 'assignments' && (
            <AssignmentsDashboard
              employees={employees}
              nationalities={nationalities}
            />
          )}

          {activeTab === 'penalties' && (
            <PenaltiesDashboard
              catalog={penaltiesCatalog}
            />
          )}

          {activeTab === 'settings' && (
            <SettingsDashboard
              onSync={syncOfflineQueue}
            />
          )}
        </main>

        {/* Floating Copilot Trigger Button */}
        {!showAIAssistant && (
          <button
            onClick={() => setShowAIAssistant(true)}
            className="absolute bottom-6 right-6 p-4 bg-indigo-650 hover:bg-indigo-600 text-white rounded-full shadow-2xl flex items-center space-x-1.5 transition-all duration-200 hover:scale-105 active:scale-95 animate-pulse z-40"
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
              const partnerInput = document.querySelector('input[placeholder="Escribe para buscar infractor..."]') as HTMLInputElement;
              if (partnerInput && data.partnerName) {
                partnerInput.value = data.partnerName;
                partnerInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
              const severitySelect = document.querySelector('select') as HTMLSelectElement;
              if (severitySelect) {
                severitySelect.value = String(data.parentId);
                severitySelect.dispatchEvent(new Event('change', { bubbles: true }));
              }
              const obsTextArea = document.querySelector('textarea[placeholder="Detalles sobre lo ocurrido, lugar, personas involucradas..."]') as HTMLTextAreaElement;
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
