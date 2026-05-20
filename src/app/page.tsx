'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function RootPage() {
  const router = useRouter();

  useEffect(() => {
    const sessionStr = localStorage.getItem('epmsa_session');
    if (sessionStr) {
      try {
        const session = JSON.parse(sessionStr);
        if (session.sessionId) {
          router.replace('/dashboard');
          return;
        }
      } catch {
        // Clear corrupt session
        localStorage.removeItem('epmsa_session');
      }
    }
    router.replace('/login');
  }, [router]);

  return (
    <div className="flex flex-col flex-1 items-center justify-center min-h-screen bg-slate-950">
      <div className="flex flex-col items-center space-y-4">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-indigo-500"></div>
        <p className="text-slate-400 text-sm animate-pulse">Cargando EPMSA Auditor...</p>
      </div>
    </div>
  );
}
