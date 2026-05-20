'use client';

import { useEffect } from 'react';

export default function PWARegister() {
  useEffect(() => {
    if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker
          .register('/service-worker.js')
          .then((registration) => {
            console.log('Service Worker registrado con éxito: ', registration.scope);
          })
          .catch((error) => {
            console.error('Error al registrar el Service Worker: ', error);
          });
      });
    }
  }, []);

  return null;
}
