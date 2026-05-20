// Odoo API Client Service
// All endpoints are called through the backend Next.js proxy to bypass CORS.

import type {
  OdooConfig,
  UserSession,
  Area,
  Nationality,
  Employee,
  Process,
  Category,
  Criticality,
  PenaltyCatalog,
  Penalty,
  Inspection,
  InspectionResult,
  TestResult,
  Novelty,
  InspectionRequirement,
  QualificationFromSpanish,
} from '@/types';

export type { OdooConfig };

export class OdooService {
  private static async callProxy(
    config: OdooConfig,
    path: string,
    method: 'POST' | 'GET',
    body?: unknown,
    sessionId?: string
  ) {
    const cookie = sessionId ? `session_id=${sessionId}` : undefined;
    console.log('[v0] callProxy - path:', path, 'hasSessionId:', !!sessionId);

    const response = await fetch('/api/odoo/proxy', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        targetUrl: config.serverUrl,
        path,
        method,
        body,
        cookie,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Proxy error: ${response.status} - ${errText}`);
    }

    const data = await response.json();

    // Log if there's an error in the response
    if (data.error) {
      console.log('[v0] Odoo error response:', data.error.message || data.error);
    }

    return { data, headers: response.headers };
  }

  // ==========================================
  // Authentication
  // ==========================================

  static async authenticate(
    config: OdooConfig,
    login: string,
    password: string
  ): Promise<UserSession> {
    const payload = {
      jsonrpc: '2.0',
      params: {
        db: config.dbName,
        login,
        password,
      },
    };

    const response = await fetch('/api/odoo/proxy', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        targetUrl: config.serverUrl,
        path: '/web/session/authenticate',
        method: 'POST',
        body: payload,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Proxy error: ${response.status} - ${errText}`);
    }

    const data = await response.json();

    if (data.error) {
      throw new Error(
        data.error.data?.message || data.error.message || 'Error de autenticación'
      );
    }

    if (!data.result) {
      throw new Error('Respuesta inválida de Odoo (Falta result)');
    }

    const result = data.result;
    const uid = result.uid;
    const name = result.name;

    // Try to get session_id from result body first
    let sessionId = result.session_id;

    // If not in body, try to extract from set-cookie header
    if (!sessionId) {
      const setCookie = response.headers.get('set-cookie');
      if (setCookie) {
        const match = setCookie.match(/session_id=([^;]+)/);
        if (match) {
          sessionId = match[1];
        }
      }
    }

    console.log(
      '[v0] Auth result - uid:',
      uid,
      'sessionId:',
      sessionId ? 'present' : 'missing'
    );

    if (!sessionId) {
      throw new Error('No se pudo obtener el session_id de Odoo');
    }

    return {
      uid,
      sessionId,
      name,
      company: result.company_name,
    };
  }

  // ==========================================
  // Master Data (Catalogs)
  // ==========================================

  static async fetchAreas(config: OdooConfig, sessionId: string): Promise<Area[]> {
    const { data } = await this.callProxy(config, '/api/get-areas', 'GET', undefined, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result || [];
  }

  static async fetchNationalities(config: OdooConfig, sessionId: string): Promise<Nationality[]> {
    const { data } = await this.callProxy(config, '/api/get-nationalities', 'GET', undefined, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result || [];
  }

  static async fetchEmployees(config: OdooConfig, sessionId: string): Promise<Employee[]> {
    const { data } = await this.callProxy(config, '/api/get-employees', 'GET', undefined, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result || [];
  }

  static async fetchProcess(config: OdooConfig, sessionId: string): Promise<Process[]> {
    const { data } = await this.callProxy(config, '/api/get-process', 'GET', undefined, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result || [];
  }

  static async fetchUsersList(config: OdooConfig, sessionId: string): Promise<Employee[]> {
    const { data } = await this.callProxy(config, '/api/users_list', 'POST', {}, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result?.data || [];
  }

  // ==========================================
  // Penalties Module
  // ==========================================

  static async fetchPenaltiesCatalog(config: OdooConfig, sessionId: string): Promise<PenaltyCatalog[]> {
    const { data } = await this.callProxy(config, '/api/penalties_list', 'POST', {}, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result?.data || [];
  }

  static async createPenalty(
    config: OdooConfig,
    sessionId: string,
    penalty: Omit<Penalty, 'id' | 'synced'>
  ): Promise<{ id: number }> {
    // Format date from DD/MM/YYYY to YYYY-MM-DD if needed
    let formattedDate = penalty.date;
    if (penalty.date.includes('/')) {
      const [day, month, year] = penalty.date.split('/');
      formattedDate = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
    }

    const payload = {
      jsonrpc: '2.0',
      params: {
        ...penalty,
        date: formattedDate,
      },
    };

    const { data } = await this.callProxy(config, '/api/create_penalty', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al crear la sanción');
    return data.result;
  }

  // ==========================================
  // Flight Inspections Module
  // ==========================================

  static async fetchAssignedControls(
    config: OdooConfig,
    sessionId: string,
    uid: number
  ): Promise<Inspection[]> {
    const today = new Date().toISOString().substring(0, 10);
    const payload = {
      domain: [
        ['date', '=', today],
        ['employee_id.user_id', '=', uid],
      ],
    };

    const { data } = await this.callProxy(config, '/api/get-controls', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error fetching controls');
    return data.result || [];
  }

  static async syncControl(
    config: OdooConfig,
    sessionId: string,
    controlData: unknown
  ): Promise<unknown> {
    const { data } = await this.callProxy(config, '/api/sync-controls', 'POST', controlData, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar inspección');
    return data.result || data;
  }

  static async syncControlPhotos(
    config: OdooConfig,
    sessionId: string,
    photoData: { inspection_id: number; photos: { data: string; name: string }[] }
  ): Promise<unknown> {
    const { data } = await this.callProxy(config, '/api/sync-photos', 'POST', photoData, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar fotos');
    return data.result || data;
  }

  // ==========================================
  // Assignments Module (Inspections & Tests)
  // ==========================================

  static async fetchInspections(
    config: OdooConfig,
    sessionId: string
  ): Promise<{ result: InspectionResult[] } | null> {
    const { data } = await this.callProxy(config, '/api/get-inspections', 'POST', {}, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data || null;
  }

  static async fetchTests(
    config: OdooConfig,
    sessionId: string
  ): Promise<{ result: TestResult[] } | null> {
    const { data } = await this.callProxy(config, '/api/get-tests', 'POST', {}, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data || null;
  }

  static async syncAssignmentInspection(
    config: OdooConfig,
    sessionId: string,
    uid: number,
    inspectionId: number,
    observations: string,
    qualifications: Map<number, string>
  ): Promise<unknown> {
    // Map Spanish qualifications to English
    const qualificationMap: Record<string, string> = {
      'Satisfactorio': 'Satifactory',
      'Poco satisfactorio': 'Unsatisfactory',
      'No cumple': 'Notcomply',
      'No aplica': 'Notapply',
      'No observado': 'Notobserved',
    };

    const inspectionRequirementIds = Array.from(qualifications.entries()).map(([id, valueEs]) => ({
      id,
      qualification: qualificationMap[valueEs] || 'Notapply',
    }));

    const payload = {
      id: inspectionId,
      made_by: uid,
      audited: 'Analista',
      inspection_requirement_ids: inspectionRequirementIds,
      observations,
    };

    const { data } = await this.callProxy(config, '/api/sync-inspections', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar inspección');
    return data.result || data;
  }

  static async syncAssignmentTest(
    config: OdooConfig,
    sessionId: string,
    uid: number,
    testData: {
      id: number;
      siteTest: number;
      dateTest: string;
      timeTest: string;
      type?: string;
      madeTo: number;
      brand: string;
      model: string;
      hidingSite: string;
      detected: boolean;
      correctiveAction: boolean;
      collaboratorName: string;
      collaboratorNacionality: number;
      collaboratorIdentity: string;
      collaboratorEmail: string;
      autorization: boolean;
      observation: string;
      recomendation: string;
    }
  ): Promise<unknown> {
    const payload = {
      id: testData.id,
      site_test: testData.siteTest,
      date_test: testData.dateTest,
      time_test: testData.timeTest,
      type: testData.type || 'procedure',
      made_by: uid,
      made_to: testData.madeTo,
      brand: testData.brand,
      model: testData.model,
      hiding_site: testData.hidingSite,
      detected: testData.detected ? 'yes' : 'no',
      corrective_action: testData.correctiveAction ? 'yes' : 'no',
      collaborator_name: testData.collaboratorName,
      collaborator_nacionality: testData.collaboratorNacionality,
      collaborator_identity: testData.collaboratorIdentity,
      collaborator_email: testData.collaboratorEmail,
      autorization: testData.autorization ? 'yes' : 'no',
      observation: testData.observation,
      recomendation: testData.recomendation,
    };

    const { data } = await this.callProxy(config, '/api/sync-tests', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar prueba');
    return data.result || data;
  }

  static async syncAssignmentInspectionPhotos(
    config: OdooConfig,
    sessionId: string,
    inspectionId: number,
    photos: { data: string; name: string }[]
  ): Promise<unknown> {
    const payload = {
      inspection_id: inspectionId,
      photos,
    };

    const { data } = await this.callProxy(config, '/api/sync-inspections-photos', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar fotos');
    return data.result || data;
  }

  static async syncAssignmentTestPhotos(
    config: OdooConfig,
    sessionId: string,
    testId: number,
    photos: { data: string; name: string }[]
  ): Promise<unknown> {
    const payload = {
      test_id: testId,
      photos,
    };

    const { data } = await this.callProxy(config, '/api/sync-tests-photos', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar fotos');
    return data.result || data;
  }

  // ==========================================
  // Novedades (Tickets) Module
  // ==========================================

  static async fetchTicketLevels(config: OdooConfig, sessionId: string): Promise<Criticality[]> {
    const { data } = await this.callProxy(config, '/api/get-ticket-levels', 'GET', undefined, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result || [];
  }

  static async fetchTicketCategories(config: OdooConfig, sessionId: string): Promise<Category[]> {
    const { data } = await this.callProxy(config, '/api/get-ticket-categories', 'GET', undefined, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result || [];
  }

  static async createInspectionTicket(
    config: OdooConfig,
    sessionId: string,
    novelty: Novelty
  ): Promise<boolean> {
    const payload = {
      name: novelty.name,
      description: novelty.description,
      date: novelty.date,
      category_id: novelty.categoryId,
      criticality_id: novelty.criticalityId,
      place: novelty.place,
      inspection_report_id: novelty.inspectionId,
    };

    const { data } = await this.callProxy(config, '/api/create-inspection-ticket', 'POST', payload, sessionId);
    if (data.error) {
      console.error('Error creating inspection ticket:', data.error);
      return false;
    }
    return true;
  }

  static async createTestTicket(
    config: OdooConfig,
    sessionId: string,
    novelty: Novelty
  ): Promise<boolean> {
    const payload = {
      name: novelty.name,
      description: novelty.description,
      date: novelty.date,
      category_id: novelty.categoryId,
      criticality_id: novelty.criticalityId,
      place: novelty.place,
      test_report_id: novelty.inspectionId,
    };

    const { data } = await this.callProxy(config, '/api/create-test-ticket', 'POST', payload, sessionId);
    if (data.error) {
      console.error('Error creating test ticket:', data.error);
      return false;
    }
    return true;
  }

  // Unified method to create ticket based on type
  static async createTicket(
    config: OdooConfig,
    sessionId: string,
    novelty: Novelty
  ): Promise<boolean> {
    if (novelty.isInspection) {
      return this.createInspectionTicket(config, sessionId, novelty);
    } else {
      return this.createTestTicket(config, sessionId, novelty);
    }
  }
}
