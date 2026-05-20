// Odoo API Client Service
// All endpoints are called through the backend next.js proxy to bypass CORS.

export interface OdooConfig {
  serverUrl: string;
  dbName: string;
}

export class OdooService {
  private static async callProxy(
    config: OdooConfig,
    path: string,
    method: 'POST' | 'GET',
    body?: any,
    sessionId?: string
  ) {
    const cookie = sessionId ? `session_id=${sessionId}` : undefined;
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
    return { data, headers: response.headers };
  }

  // 1. Authenticate user
  static async authenticate(config: OdooConfig, login: string, password: string) {
    const payload = {
      jsonrpc: '2.0',
      params: {
        db: config.dbName,
        login,
        password,
      },
    };

    const { data } = await this.callProxy(config, '/web/session/authenticate', 'POST', payload);

    if (data.error) {
      throw new Error(data.error.data?.message || data.error.message || 'Error de autenticación');
    }

    if (!data.result) {
      throw new Error('Respuesta inválida de Odoo (Falta result)');
    }

    const result = data.result;
    // Extract session id from response if present, otherwise search for set-cookie headers
    // Note: Vercel/Next server sets headers. For security, we can read uid and session id from result
    const uid = result.uid;
    const sessionId = result.session_id;
    const name = result.name;

    return {
      uid,
      sessionId,
      name,
      company: result.company_name,
    };
  }

  // 2. Fetch assigned controls for today
  static async fetchAssignedControls(config: OdooConfig, sessionId: string, uid: number) {
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

  // 3. Fetch users list
  static async fetchUsersList(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/users_list', 'POST', {}, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result?.data || [];
  }

  // 4. Fetch penalties catalog
  static async fetchPenaltiesCatalog(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/penalties_list', 'POST', {}, sessionId);
    if (data.error) throw new Error(data.error.message);
    return data.result?.data || [];
  }

  // 5. Create / Sync Penalty
  static async createPenalty(config: OdooConfig, sessionId: string, penaltyData: any) {
    const payload = {
      jsonrpc: '2.0',
      params: penaltyData,
    };
    const { data } = await this.callProxy(config, '/api/create_penalty', 'POST', payload, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al crear la sanción');
    return data.result;
  }

  // 6. Sync Inspection Controls
  static async syncControl(config: OdooConfig, sessionId: string, controlData: any) {
    const { data } = await this.callProxy(config, '/api/sync-controls', 'POST', controlData, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar inspección');
    return data.result || data;
  }

  // 7. Sync Photos
  static async syncPhotos(config: OdooConfig, sessionId: string, photoData: any) {
    const { data } = await this.callProxy(config, '/api/sync-photos', 'POST', photoData, sessionId);
    if (data.error) throw new Error(data.error.message || 'Error al sincronizar fotos');
    return data.result || data;
  }

  // 8. Fetch Areas
  static async fetchAreas(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/get-areas', 'GET', undefined, sessionId);
    return data.result || [];
  }

  // 9. Fetch Nationalities
  static async fetchNationalities(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/get-nationalities', 'GET', undefined, sessionId);
    return data.result || [];
  }

  // 10. Fetch Employees
  static async fetchEmployees(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/get-employees', 'GET', undefined, sessionId);
    return data.result || [];
  }

  // 11. Fetch Processes
  static async fetchProcess(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/get-process', 'GET', undefined, sessionId);
    return data.result || [];
  }

  // 12. Fetch Inspections (assignments)
  static async fetchInspections(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/get-inspections', 'POST', {}, sessionId);
    return data.result || null;
  }

  // 13. Fetch Tests (assignments)
  static async fetchTests(config: OdooConfig, sessionId: string) {
    const { data } = await this.callProxy(config, '/api/get-tests', 'POST', {}, sessionId);
    return data.result || null;
  }

  // 14. Sync Assignments Inspection
  static async syncAssignmentInspection(config: OdooConfig, sessionId: string, payload: any) {
    const { data } = await this.callProxy(config, '/api/sync-inspections', 'POST', payload, sessionId);
    return data.result || data;
  }

  // 15. Sync Assignment Test
  static async syncAssignmentTest(config: OdooConfig, sessionId: string, payload: any) {
    const { data } = await this.callProxy(config, '/api/sync-tests', 'POST', payload, sessionId);
    return data.result || data;
  }

  // 16. Sync Assignment Inspection Photos
  static async syncAssignmentInspectionPhotos(config: OdooConfig, sessionId: string, payload: any) {
    const { data } = await this.callProxy(config, '/api/sync-inspections-photos', 'POST', payload, sessionId);
    return data.result || data;
  }

  // 17. Sync Assignment Test Photos
  static async syncAssignmentTestPhotos(config: OdooConfig, sessionId: string, payload: any) {
    const { data } = await this.callProxy(config, '/api/sync-tests-photos', 'POST', payload, sessionId);
    return data.result || data;
  }
}
