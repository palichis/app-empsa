import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { targetUrl, path, method = 'POST', body, cookie } = await request.json();

    if (!targetUrl) {
      return NextResponse.json({ error: 'Falta la URL de destino (targetUrl)' }, { status: 400 });
    }

    if (!path) {
      return NextResponse.json({ error: 'Falta la ruta del endpoint (path)' }, { status: 400 });
    }

    // Ensure HTTPS is used (force port 443)
    let normalizedUrl = targetUrl.replace(/\/$/, '');
    if (!normalizedUrl.startsWith('https://')) {
      normalizedUrl = normalizedUrl.replace(/^http:\/\//, 'https://');
    }

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (cookie) {
      headers['Cookie'] = cookie;
    }

    const targetFullUrl = `${normalizedUrl}${path}`;
    console.log(`Proxying request: [${method}] ${targetFullUrl}`);

    const options: RequestInit = {
      method,
      headers,
      // @ts-expect-error - Next.js extends RequestInit with next options
      next: { revalidate: 0 },
    };

    if (method === 'POST' && body) {
      options.body = typeof body === 'string' ? body : JSON.stringify(body);
    }

    // Create AbortController for timeout (30 seconds)
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 30000);
    options.signal = controller.signal;

    let response: Response;
    try {
      response = await fetch(targetFullUrl, options);
    } catch (fetchError: any) {
      clearTimeout(timeoutId);
      // Handle specific connection errors
      if (fetchError.name === 'AbortError') {
        throw new Error(`Timeout de conexion a ${normalizedUrl} (30s)`);
      }
      if (fetchError.cause?.code === 'ECONNREFUSED') {
        throw new Error(`Conexion rechazada a ${normalizedUrl}. Verifica que el servidor este activo.`);
      }
      if (fetchError.cause?.code === 'ETIMEDOUT' || fetchError.message?.includes('ConnectTimeoutError')) {
        throw new Error(`Timeout de conexion a ${normalizedUrl}. El puerto 443 puede estar bloqueado.`);
      }
      throw fetchError;
    }
    clearTimeout(timeoutId);

    const text = await response.text();

    let jsonResponse;
    try {
      jsonResponse = JSON.parse(text);
    } catch {
      jsonResponse = { raw: text };
    }

    // Forward the set-cookie header if Odoo sets a session id
    const resHeaders = new Headers();
    const setCookie = response.headers.get('set-cookie');
    if (setCookie) {
      resHeaders.append('set-cookie', setCookie);
    }

    return new NextResponse(JSON.stringify(jsonResponse), {
      status: response.status,
      headers: resHeaders,
    });
  } catch (error: any) {
    console.error('Proxy Error:', error);
    return NextResponse.json(
      { error: error.message || 'Error en el proxy de Odoo' },
      { status: 500 }
    );
  }
}
