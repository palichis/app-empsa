'use client';

import { useState, useEffect } from 'react';
import { db, AssignmentTest, InspectionPhoto } from '@/db/indexedDB';
import { ArrowLeft, Save, Send, Camera, Trash2, CheckCircle2, User } from 'lucide-react';
import { useNetwork } from '@/hooks/useNetwork';

interface SecurityTestFormProps {
  testId: number;
  onClose: () => void;
  onSave: () => void;
  nationalities: any[];
}

export default function SecurityTestForm({ testId, onClose, onSave, nationalities }: SecurityTestFormProps) {
  const isOnline = useNetwork();
  
  // Local Form state
  const [formData, setFormData] = useState<Partial<AssignmentTest>>({
    id: testId,
    site_test: 1,
    brand: '',
    model: '',
    hiding_site: '',
    detected: false,
    corrective_action: false,
    collaborator_name: '',
    collaborator_nationality: 1,
    collaborator_identity: '',
    collaborator_email: '',
    authorization: false,
    observation: '',
    recommendation: '',
    made_to: 1,
    status: 'En progreso',
    synced: 0,
  });

  const [photos, setPhotos] = useState<InspectionPhoto[]>([]);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  // Load existing test details from IndexedDB
  useEffect(() => {
    async function loadTest() {
      const localTest = await db.assignments_tests.get(testId);
      if (localTest) {
        setFormData(localTest);
      }
      
      const testPhotos = await db.inspection_photos
        .where('inspection_id')
        .equals(testId)
        .filter(p => p.section === 'security_test')
        .toArray();
      setPhotos(testPhotos);
    }
    loadTest();
  }, [testId]);

  const handleChange = (field: keyof AssignmentTest, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files) return;
    const files = Array.from(e.target.files);

    files.forEach(file => {
      const reader = new FileReader();
      reader.onload = async () => {
        const base64 = reader.result as string;
        const newPhoto: InspectionPhoto = {
          inspection_id: testId,
          section: 'security_test',
          path: base64,
          caption: '',
          timestamp: new Date().toISOString(),
          synced: 0,
        };
        const photoId = await db.inspection_photos.add(newPhoto);
        setPhotos(prev => [...prev, { ...newPhoto, id: photoId }]);
      };
      reader.readAsDataURL(file);
    });
  };

  const handlePhotoDelete = async (photoId: number) => {
    await db.inspection_photos.delete(photoId);
    setPhotos(prev => prev.filter(p => p.id !== photoId));
  };

  const handlePhotoCaptionChange = async (photoId: number, caption: string) => {
    await db.inspection_photos.update(photoId, { caption });
    setPhotos(prev => prev.map(p => p.id === photoId ? { ...p, caption } : p));
  };

  const saveToLocalDB = async (finalStatus: 'En progreso' | 'Finalizada') => {
    const updatedTest: AssignmentTest = {
      ...(formData as AssignmentTest),
      status: finalStatus,
      synced: 0,
    };
    await db.assignments_tests.put(updatedTest);
    return updatedTest;
  };

  const handleSaveDraft = async () => {
    setLoading(true);
    await saveToLocalDB('En progreso');
    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      onSave();
    }, 1000);
  };

  const handleSubmitTest = async () => {
    setLoading(true);
    const testData = await saveToLocalDB('Finalizada');

    // Create a pending mutation for syncing
    const mutation = {
      type: 'sync_test',
      inspectionId: testId,
      payload: testData,
      timestamp: Date.now(),
      status: 'pending',
    };
    // Save to mutation queue
    await db.mutations.add(mutation);

    // Also queue photo sync if present
    if (photos.length > 0) {
      await db.mutations.add({
        type: 'sync_photos',
        inspectionId: testId,
        payload: {
          id: testId,
          isTest: true,
          photos: photos.map(p => ({ filename: `photo_${p.id}.png`, caption: p.caption, base64: p.path.split(',')[1] })),
        },
        timestamp: Date.now(),
        status: 'pending',
      });
    }

    setLoading(false);
    setSuccess(true);
    setTimeout(() => {
      setSuccess(false);
      onSave();
    }, 1000);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 shadow-xl max-w-4xl mx-auto animate-fade-in space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-slate-800">
        <button
          onClick={onClose}
          className="flex items-center space-x-1.5 text-xs text-slate-400 hover:text-slate-200 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Volver a Asignaciones</span>
        </button>
        <h3 className="text-md font-bold text-white">Prueba de Seguridad (ID: {testId})</h3>
        <div className="w-20"></div> {/* spacer */}
      </div>

      {success && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/25 text-emerald-300 text-sm rounded-lg flex items-center space-x-2">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span>¡Guardado con éxito localmente! Se sincronizará al detectar conexión.</span>
        </div>
      )}

      {/* Form Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
        {/* Left Column: Test Details */}
        <div className="space-y-4">
          <h4 className="text-indigo-400 font-bold uppercase tracking-wider text-[11px] pb-1 border-b border-slate-850">
            Detalles de la Prueba
          </h4>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-slate-400 mb-1">Marca del Objeto</label>
              <input
                type="text"
                placeholder="Ej. Smiths"
                value={formData.brand || ''}
                onChange={e => handleChange('brand', e.target.value)}
                className="glass-input w-full p-2"
              />
            </div>
            <div>
              <label className="block text-slate-400 mb-1">Modelo del Objeto</label>
              <input
                type="text"
                placeholder="Ej. Heimann"
                value={formData.model || ''}
                onChange={e => handleChange('model', e.target.value)}
                className="glass-input w-full p-2"
              />
            </div>
          </div>

          <div>
            <label className="block text-slate-400 mb-1">Lugar de Ocultamiento</label>
            <input
              type="text"
              placeholder="Ej. Fondo falso de maleta de mano"
              value={formData.hiding_site || ''}
              onChange={e => handleChange('hiding_site', e.target.value)}
              className="glass-input w-full p-2"
            />
          </div>

          <div className="grid grid-cols-2 gap-4 pt-2">
            <label className="flex items-center space-x-2.5 p-2.5 bg-slate-950/30 rounded-lg border border-slate-850 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.detected || false}
                onChange={e => handleChange('detected', e.target.checked)}
                className="accent-indigo-600 h-4 w-4 rounded"
              />
              <div>
                <span className="block text-slate-200 font-semibold">¿Detectado?</span>
                <span className="block text-slate-500 text-[10px]">El agente detectó la amenaza</span>
              </div>
            </label>

            <label className="flex items-center space-x-2.5 p-2.5 bg-slate-950/30 rounded-lg border border-slate-850 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.corrective_action || false}
                onChange={e => handleChange('corrective_action', e.target.checked)}
                className="accent-indigo-600 h-4 w-4 rounded"
              />
              <div>
                <span className="block text-slate-200 font-semibold">¿Acción Correctiva?</span>
                <span className="block text-slate-500 text-[10px]">Se aplicó correctiva inmediata</span>
              </div>
            </label>
          </div>

          <div className="space-y-3">
            <div>
              <label className="block text-slate-400 mb-1">Observaciones</label>
              <textarea
                placeholder="Observaciones de la prueba..."
                value={formData.observation || ''}
                onChange={e => handleChange('observation', e.target.value)}
                className="glass-input w-full p-2.5 h-16 resize-none"
              />
            </div>
            <div>
              <label className="block text-slate-400 mb-1">Recomendaciones</label>
              <textarea
                placeholder="Recomendaciones sugeridas..."
                value={formData.recommendation || ''}
                onChange={e => handleChange('recommendation', e.target.value)}
                className="glass-input w-full p-2.5 h-16 resize-none"
              />
            </div>
          </div>
        </div>

        {/* Right Column: Collaborator & Photos */}
        <div className="space-y-4">
          <h4 className="text-indigo-400 font-bold uppercase tracking-wider text-[11px] pb-1 border-b border-slate-850">
            Datos del Colaborador Evaluado
          </h4>

          <div>
            <label className="block text-slate-400 mb-1">Nombre Completo</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-2.5 flex items-center text-slate-500">
                <User className="w-4 h-4" />
              </span>
              <input
                type="text"
                required
                placeholder="Ej. Juan Carlos Ramos"
                value={formData.collaborator_name || ''}
                onChange={e => handleChange('collaborator_name', e.target.value)}
                className="glass-input w-full py-2 pl-9 pr-3"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-slate-400 mb-1">Identidad / Cédula</label>
              <input
                type="text"
                placeholder="Ej. 1726554312"
                value={formData.collaborator_identity || ''}
                onChange={e => handleChange('collaborator_identity', e.target.value)}
                className="glass-input w-full p-2"
              />
            </div>
            <div>
              <label className="block text-slate-400 mb-1">Nacionalidad</label>
              <select
                value={formData.collaborator_nationality || 1}
                onChange={e => handleChange('collaborator_nationality', parseInt(e.target.value))}
                className="glass-input w-full p-2 bg-slate-900"
              >
                {nationalities.map(n => (
                  <option key={n.id} value={n.id}>
                    {n.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4">
            <div>
              <label className="block text-slate-400 mb-1">Email</label>
              <input
                type="email"
                placeholder="colaborador@aeropuertoquito.gob.ec"
                value={formData.collaborator_email || ''}
                onChange={e => handleChange('collaborator_email', e.target.value)}
                className="glass-input w-full p-2"
              />
            </div>
          </div>

          <label className="flex items-center space-x-2.5 p-2 bg-slate-950/30 rounded-lg border border-slate-850 cursor-pointer">
            <input
              type="checkbox"
              checked={formData.authorization || false}
              onChange={e => handleChange('authorization', e.target.checked)}
              className="accent-indigo-600 h-4 w-4 rounded"
            />
            <div>
              <span className="block text-slate-200 font-semibold">¿Autorización del Colaborador?</span>
              <span className="block text-slate-500 text-[10px]">Acepta el registro y evaluación</span>
            </div>
          </label>

          {/* Photo attachments */}
          <div className="space-y-2.5">
            <div className="flex justify-between items-center">
              <label className="block text-slate-400 font-semibold">Fotos Evidencia</label>
              <label className="cursor-pointer bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-1 rounded-lg flex items-center space-x-1 transition-colors">
                <Camera className="w-3.5 h-3.5" />
                <span>Adjuntar Foto</span>
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={handlePhotoUpload}
                  className="hidden"
                />
              </label>
            </div>

            {/* Photos thumbnail preview list */}
            {photos.length === 0 ? (
              <p className="text-slate-500 text-[10px] italic">No se han adjuntado fotos todavía.</p>
            ) : (
              <div className="grid grid-cols-2 gap-3 max-h-[140px] overflow-y-auto pr-1">
                {photos.map(p => (
                  <div key={p.id} className="bg-slate-950/40 p-2 rounded-lg border border-slate-850 flex space-x-2">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={p.path}
                      alt="Preview"
                      className="w-10 h-10 object-cover rounded"
                    />
                    <div className="flex-1 flex flex-col justify-between">
                      <input
                        type="text"
                        placeholder="Nota..."
                        value={p.caption}
                        onChange={e => handlePhotoCaptionChange(p.id!, e.target.value)}
                        className="glass-input p-1 text-[9px] w-full"
                      />
                      <button
                        onClick={() => handlePhotoDelete(p.id!)}
                        className="text-rose-400 hover:text-rose-300 self-end p-0.5"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end space-x-3 pt-4 border-t border-slate-800 text-xs">
        <button
          onClick={onClose}
          className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold rounded-lg transition-colors"
        >
          Cancelar
        </button>
        <button
          onClick={handleSaveDraft}
          disabled={loading}
          className="px-4 py-2 bg-indigo-500/10 border border-indigo-500/25 hover:bg-indigo-500/20 text-indigo-300 font-semibold rounded-lg flex items-center space-x-1.5 transition-colors"
        >
          <Save className="w-4 h-4" />
          <span>Guardar Borrador</span>
        </button>
        <button
          onClick={handleSubmitTest}
          disabled={loading}
          className="px-5 py-2 bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-750 text-white font-semibold rounded-lg flex items-center space-x-1.5 transition-colors"
        >
          <Send className="w-4 h-4" />
          <span>Finalizar e Iniciar Sync</span>
        </button>
      </div>
    </div>
  );
}
