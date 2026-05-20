'use client';

import { useState } from 'react';
import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { Sparkles, Send, Bot, User, X, FileText, ArrowRight, CornerDownLeft } from 'lucide-react';

interface AIAssistantProps {
  onClose: () => void;
  onAutofillPenalty?: (extractedData: {
    severity: string;
    parentId: number;
    amount: number;
    observations: string;
    partnerName?: string;
  }) => void;
  catalog?: any[];
}

export default function AIAssistant({ onClose, onAutofillPenalty, catalog }: AIAssistantProps) {
  const [activeMode, setActiveMode] = useState<'chat' | 'autofill'>('chat');
  const [autofillText, setAutofillText] = useState('');
  const [autofillLoading, setAutofillLoading] = useState(false);
  const [autofillResult, setAutofillResult] = useState<any | null>(null);

  // Local input state for chat
  const [input, setInput] = useState('');
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => setInput(e.target.value);

  // Vercel AI SDK useChat
  const { messages, sendMessage, status } = useChat({
    transport: new DefaultChatTransport({
      api: '/api/chat',
      body: { mode: 'chat' },
    }),
  });

  const isLoading = status === 'submitted' || status === 'streaming';

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;
    sendMessage({ text: input });
    setInput('');
  };

  const handleAutofillExtract = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!autofillText.trim()) return;

    setAutofillLoading(true);
    setAutofillResult(null);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          mode: 'extract',
          text: autofillText,
          catalog: catalog,
        }),
      });

      if (!response.ok) throw new Error('Error al extraer infracción');
      const data = await response.json();
      setAutofillResult(data);
    } catch (e) {
      console.error(e);
    } finally {
      setAutofillLoading(false);
    }
  };

  const applyAutofill = () => {
    if (autofillResult && onAutofillPenalty) {
      onAutofillPenalty(autofillResult);
      setActiveMode('chat');
      setAutofillResult(null);
      setAutofillText('');
    }
  };

  return (
    <div className="w-96 bg-slate-900 border-l border-slate-800 flex flex-col h-full shadow-2xl relative animate-fade-in z-25">
      {/* Header */}
      <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-900/80 sticky top-0 z-10">
        <div className="flex items-center space-x-2 text-indigo-400">
          <Sparkles className="w-5 h-5 fill-indigo-400/25" />
          <h3 className="font-bold text-white text-sm">Asistente Copiloto IA</h3>
        </div>
        <button
          onClick={onClose}
          className="text-slate-400 hover:text-slate-200 p-1.5 rounded-lg hover:bg-slate-800 transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-800 text-xs">
        <button
          onClick={() => setActiveMode('chat')}
          className={`flex-1 py-2.5 font-semibold text-center border-b-2 transition-colors ${
            activeMode === 'chat'
              ? 'border-indigo-500 text-white bg-indigo-500/5'
              : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          Conversación
        </button>
        <button
          onClick={() => setActiveMode('autofill')}
          className={`flex-1 py-2.5 font-semibold text-center border-b-2 transition-colors ${
            activeMode === 'autofill'
              ? 'border-indigo-500 text-white bg-indigo-500/5'
              : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          Auto-llenar Sanción
        </button>
      </div>

      {/* Content Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {activeMode === 'chat' ? (
          <>
            {/* Conversation Mode */}
            {messages.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full text-center p-6 space-y-3">
                <Bot className="w-10 h-10 text-indigo-500 bg-indigo-500/10 p-2 rounded-xl" />
                <div>
                  <h4 className="text-slate-200 font-semibold text-sm">¿Cómo puedo ayudarte hoy?</h4>
                  <p className="text-slate-400 text-xs mt-1">
                    Puedes hacerme preguntas sobre los catálogos de auditoría, las sanciones leves/graves, o cómo rellenar los datos de las aerolíneas.
                  </p>
                </div>
              </div>
            ) : (
              messages.map((m) => (
                <div
                  key={m.id}
                  className={`flex space-x-2.5 ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {m.role !== 'user' && (
                    <div className="w-7 h-7 rounded-lg bg-indigo-600 flex items-center justify-center flex-shrink-0 text-white text-xs font-bold">
                      IA
                    </div>
                  )}
                  <div
                    className={`p-3 rounded-xl max-w-[80%] text-xs leading-relaxed ${
                      m.role === 'user'
                        ? 'bg-indigo-600 text-white rounded-tr-none'
                        : 'bg-slate-850 text-slate-200 border border-slate-800 rounded-tl-none'
                    }`}
                  >
                    {m.parts.map((part, idx) => {
                      if (part.type === 'text') return <span key={idx}>{part.text}</span>;
                      if (part.type === 'reasoning') return <span key={idx} className="italic text-slate-500 block mb-1">{part.text}</span>;
                      return null;
                    })}
                  </div>
                  {m.role === 'user' && (
                    <div className="w-7 h-7 rounded-lg bg-slate-800 flex items-center justify-center flex-shrink-0 text-slate-400 text-xs font-bold border border-slate-700">
                      Yo
                    </div>
                  )}
                </div>
              ))
            )}
            {isLoading && (
              <div className="flex items-center space-x-2.5">
                <div className="w-7 h-7 rounded-lg bg-indigo-600 flex items-center justify-center text-white text-xs font-bold animate-pulse">
                  IA
                </div>
                <div className="bg-slate-850 border border-slate-800 p-3 rounded-xl rounded-tl-none">
                  <div className="flex space-x-1.5">
                    <div className="w-1.5 h-1.5 bg-slate-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                    <div className="w-1.5 h-1.5 bg-slate-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                    <div className="w-1.5 h-1.5 bg-slate-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                  </div>
                </div>
              </div>
            )}
          </>
        ) : (
          /* Auto-fill Incident Extraction Mode */
          <div className="space-y-4">
            <div className="p-3 bg-indigo-500/5 border border-indigo-500/10 rounded-lg">
              <h4 className="text-xs font-bold text-indigo-400 mb-1 flex items-center">
                <FileText className="w-3.5 h-3.5 mr-1" />
                Extractor de Infracciones
              </h4>
              <p className="text-slate-400 text-[11px] leading-relaxed">
                Describe el suceso en texto natural (ej: local, hora, lo sucedido). La IA determinará la clasificación, el monto y las observaciones automáticamente.
              </p>
            </div>

            <form onSubmit={handleAutofillExtract} className="space-y-3">
              <textarea
                required
                placeholder="Ej: El local de comida rápida BurgerZone en el hall de arribos nacionales no tenía habilitado el paso de emergencias y se encontraba con cajas acumuladas obstruyendo la salida hoy a las 8:30am."
                value={autofillText}
                onChange={(e) => setAutofillText(e.target.value)}
                className="glass-input w-full p-3 text-xs h-32 resize-none"
                disabled={autofillLoading}
              />
              <button
                type="submit"
                disabled={autofillLoading || !autofillText.trim()}
                className="w-full py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center space-x-1.5 transition-colors disabled:opacity-50"
              >
                {autofillLoading ? (
                  <>
                    <div className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    <span>Procesando texto...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="w-3.5 h-3.5" />
                    <span>Analizar Incidente</span>
                  </>
                )}
              </button>
            </form>

            {autofillResult && (
              <div className="p-4 bg-slate-850 border border-indigo-500/20 rounded-xl space-y-3 animate-fade-in">
                <h5 className="text-xs font-bold text-white uppercase tracking-wider">Resultado del Análisis</h5>
                <div className="space-y-1.5 text-xs">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Gravedad:</span>
                    <span className={`font-semibold ${
                      autofillResult.severity === 'Muy Grave' ? 'text-rose-400' :
                      autofillResult.severity === 'Grave' ? 'text-amber-400' : 'text-sky-400'
                    }`}>{autofillResult.severity}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Multa Estimada:</span>
                    <span className="font-semibold text-slate-200">${autofillResult.amount}</span>
                  </div>
                  {autofillResult.partnerName && (
                    <div className="flex justify-between">
                      <span className="text-slate-400">Infractor:</span>
                      <span className="font-semibold text-indigo-400 truncate max-w-[150px]">{autofillResult.partnerName}</span>
                    </div>
                  )}
                  <div className="flex flex-col pt-1.5 border-t border-slate-800">
                    <span className="text-slate-400 mb-1">Observaciones Generadas:</span>
                    <p className="text-slate-350 text-[11px] bg-slate-900/50 p-2 rounded leading-relaxed">
                      {autofillResult.observations}
                    </p>
                  </div>
                </div>

                <button
                  onClick={applyAutofill}
                  className="w-full py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center space-x-1 transition-colors"
                >
                  <span>Cargar Datos al Formulario</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Input Area (Only for chat mode) */}
      {activeMode === 'chat' && (
        <form onSubmit={handleSubmit} className="p-4 border-t border-slate-800 bg-slate-900 sticky bottom-0">
          <div className="relative flex items-center">
            <input
              type="text"
              placeholder="Escribe tu duda aquí..."
              value={input}
              onChange={handleInputChange}
              className="glass-input w-full py-2.5 pl-4 pr-10 text-xs"
              disabled={isLoading}
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="absolute right-1 p-2 text-indigo-400 hover:text-indigo-300 disabled:opacity-50 transition-colors"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
