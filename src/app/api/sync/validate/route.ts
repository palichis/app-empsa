import { NextResponse } from 'next/server';
import { generateObject } from 'ai';
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
    // If no keys are set, we will return a mock model proxy or mock handler below.
    return null;
  }
}

const validationSchema = z.object({
  isValid: z.boolean().describe('Indica si el registro es válido para enviarse a Odoo sin conflictos'),
  conflicts: z.array(
    z.object({
      field: z.string().describe('El campo que contiene el conflicto de datos'),
      issue: z.string().describe('Explicación clara del conflicto de esquema o negocio'),
      severity: z.enum(['low', 'medium', 'high']).describe('Severidad del conflicto'),
      resolution: z.string().describe('Sugerencia de cómo corregir el problema de forma automática o manual'),
    })
  ).describe('Listado de discrepancias o incoherencias halladas'),
  suggestedPayload: z.any().optional().describe('Payload corregido sugerido por la IA para evitar conflictos'),
});

export async function POST(request: Request) {
  try {
    const { mutation } = await request.json();

    if (!mutation) {
      return NextResponse.json({ error: 'Falta el objeto de mutación a validar' }, { status: 400 });
    }

    const model = getModel();

    // If no AI keys are configured, perform a local rule-based fallback validation
    if (!model) {
      console.warn('AI keys not configured. Falling back to local validation logic.');
      const localResult = performLocalValidation(mutation);
      return NextResponse.json(localResult);
    }

    const prompt = `
      Analiza esta mutación de datos locales que se intentará sincronizar con Odoo ERP.
      
      Tipo de Mutación: ${mutation.type}
      Payload de Datos: ${JSON.stringify(mutation.payload, null, 2)}
      
      Reglas de negocio de EPMSA:
      1. Sanciones (type == 'create_penalty'):
         - parentId define la gravedad: 2 = Leve ($50), 3 = Grave ($100), 4 = Muy Grave ($200).
         - El monto ('amount') DEBE corresponder exactamente al nivel de gravedad. Leve=50, Grave=100, MuyGrave=200.
         - partnerId debe ser un ID de infractor válido (no nulo, mayor que 0).
         - La fecha ('date') debe ser un formato yyyy-MM-dd coherente.
      2. Inspecciones (type == 'sync_control'):
         - inspection_id debe estar presente.
         - El inspector ('general_data_prepared_by_id') debe ser válido.
         - Si es arribo nacional/internacional o salida nacional/internacional, valida que los campos de hora y conteo de vuelos no sean nulos o incoherentes (ej. números negativos).
      
      Evalúa si hay alguna inconsistencia de esquema o lógica de negocio. Genera una respuesta estructurada con isValid, conflictos y, si es posible, un payload corregido (suggestedPayload) con las correcciones aplicadas.
    `;

    const result = await generateObject({
      model,
      schema: validationSchema,
      prompt,
    });

    return NextResponse.json(result.object);
  } catch (error: any) {
    console.error('Validation API Error:', error);
    return NextResponse.json({ error: error.message || 'Error en validación AI' }, { status: 500 });
  }
}

// Local validation fallback when no AI keys are configured
function performLocalValidation(mutation: any) {
  const conflicts: any[] = [];
  const payload = mutation.payload || {};

  if (mutation.type === 'create_penalty') {
    if (!payload.partnerId) {
      conflicts.push({
        field: 'partnerId',
        issue: 'El ID del infractor (partnerId) está vacío.',
        severity: 'high',
        resolution: 'Por favor, selecciona un infractor válido de la lista.',
      });
    }

    if (payload.parentId === 2 && payload.amount !== 50) {
      conflicts.push({
        field: 'amount',
        issue: 'El monto para infracción Leve debe ser $50.',
        severity: 'medium',
        resolution: 'Corregir el valor del monto a $50.',
      });
      payload.amount = 50;
    } else if (payload.parentId === 3 && payload.amount !== 100) {
      conflicts.push({
        field: 'amount',
        issue: 'El monto para infracción Grave debe ser $100.',
        severity: 'medium',
        resolution: 'Corregir el valor del monto a $100.',
      });
      payload.amount = 100;
    } else if (payload.parentId === 4 && payload.amount !== 200) {
      conflicts.push({
        field: 'amount',
        issue: 'El monto para infracción Muy Grave debe ser $200.',
        severity: 'medium',
        resolution: 'Corregir el valor del monto a $200.',
      });
      payload.amount = 200;
    }
  } else if (mutation.type === 'sync_control') {
    if (!payload.id) {
      conflicts.push({
        field: 'id',
        issue: 'El ID de la inspección no está definido.',
        severity: 'high',
        resolution: 'Verifique que la inspección local tenga un ID asignado.',
      });
    }
  }

  return {
    isValid: conflicts.length === 0,
    conflicts,
    suggestedPayload: conflicts.length > 0 ? payload : undefined,
  };
}
