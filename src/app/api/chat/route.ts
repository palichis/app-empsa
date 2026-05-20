import { NextResponse } from 'next/server';
import { streamText, generateObject } from 'ai';
import { google } from '@ai-sdk/google';
import { openai } from '@ai-sdk/openai';
import { z } from 'zod';

// Helper to get active AI provider model
function getModel() {
  if (process.env.GEMINI_API_KEY) {
    return google('gemini-1.5-flash');
  } else if (process.env.OPENAI_API_KEY) {
    return openai('gpt-4o-mini');
  } else {
    return null;
  }
}

const infractionExtractionSchema = z.object({
  severity: z.enum(['Leve', 'Grave', 'Muy Grave']).describe('Gravedad de la infracción determinada a partir del texto'),
  parentId: z.number().describe('ID de gravedad correspondiente: 2 para Leve, 3 para Grave, 4 para Muy Grave'),
  amount: z.number().describe('Monto de la multa correspondiente: 50 para Leve, 100 para Grave, 200 para Muy Grave'),
  observations: z.string().describe('Resumen profesional y estructurado del suceso en español'),
  partnerName: z.string().optional().describe('Nombre del infractor, supervisor, local comercial o aerolínea implicada, si se menciona'),
});

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { mode = 'chat', messages, text, catalog } = body;

    const model = getModel();

    if (!model) {
      // Fallback response if no AI keys are configured
      if (mode === 'extract') {
        return NextResponse.json({
          severity: 'Leve',
          parentId: 2,
          amount: 50,
          observations: text || 'Infracción procesada por fallback local (sin API Key).',
          partnerName: '',
        });
      } else {
        // Simple chat fallback
        return NextResponse.json({
          text: 'Hola, soy el asistente de EPMSA. Para habilitar las respuestas inteligentes con IA, configura la variable GEMINI_API_KEY o OPENAI_API_KEY en tu entorno.',
        });
      }
    }

    if (mode === 'extract') {
      const prompt = `
        Analiza el siguiente texto escrito por un inspector de aeropuerto sobre un incidente o infracción en las instalaciones.
        Extrae la gravedad de la infracción (Leve, Grave, Muy Grave) basándote en la descripción.
        Calcula el monto correspondiente ($50, $100, $200).
        Clasifica con parentId: 2 = Leve, 3 = Grave, 4 = Muy Grave.
        Genera un resumen profesional del incidente para colocarlo en las observaciones del acta.
        Si se menciona un infractor (empresa, local, aerolínea o persona), extráelo en partnerName.
        
        Catálogo de referencia de sanciones (si aplica):
        ${JSON.stringify(catalog || [], null, 2)}

        Texto a analizar:
        "${text}"
      `;

      const result = await generateObject({
        model,
        schema: infractionExtractionSchema,
        prompt,
      });

      return NextResponse.json(result.object);
    }

    // Default: Chat Assistant streaming
    const systemPrompt = `
      Eres el Asistente de IA de EPMSA (Empresa Pública Metropolitana de Servicios Aeroportuarios del Aeropuerto de Quito).
      Ayudas a los inspectores de calidad y seguridad en la terminal del aeropuerto a realizar auditorías, verificar reglas y completar registros.
      Debes responder en español, con un tono profesional, preciso y servicial.
      Puedes responder dudas sobre cómo llenar formularios de arribos/salidas, clasificar sanciones o resolver problemas frecuentes.
      Si te preguntan por normativas generales:
      - Infracciones Leves tienen multa de $50 (ej. descuidos menores, falta de gafete en zona visible).
      - Infracciones Graves tienen multa de $100 (ej. obstrucción menor de pasillos, desaseo leve).
      - Infracciones Muy Graves tienen multa de $200 (ej. violaciones de seguridad en rampa, agresiones, accesos no autorizados).
    `;

    const result = await streamText({
      model,
      system: systemPrompt,
      messages,
    });

    return result.toTextStreamResponse();
  } catch (error: any) {
    console.error('Chat API Error:', error);
    return NextResponse.json({ error: error.message || 'Error en el asistente AI' }, { status: 500 });
  }
}
