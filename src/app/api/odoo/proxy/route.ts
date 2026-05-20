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

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (cookie) {
      headers['Cookie'] = cookie;
    }

    const targetFullUrl = `${targetUrl.replace(/\/$/, '')}${path}`;
    console.log(`Proxying request: [${method}] ${targetFullUrl}`);

    const options: RequestInit = {
      method,
      headers,
    };

    if (method === 'POST' && body) {
      options.body = typeof body === 'string' ? body : JSON.stringify(body);
    }

    const response = await fetch(targetFullUrl, options);
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
    return NextResponse.json({ error: error.message || 'Error en el proxy de Odoo' }, { status: 500 });
  }
}
