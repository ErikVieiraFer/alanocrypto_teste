importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Configuração do Firebase (copiada de firebase_options.dart - Web)
firebase.initializeApp({
  apiKey: "AIzaSyD25JZdaoYY2TUIKr3Ey3ylS9r-xrQ0d8U",
  authDomain: "alanocryptofx-v2.firebaseapp.com",
  projectId: "alanocryptofx-v2",
  storageBucket: "alanocryptofx-v2.firebasestorage.app",
  messagingSenderId: "508290889017",
  appId: "1:508290889017:web:4e7b52875cfee66008e4e8"
});

const messaging = firebase.messaging();

// Handler para notificações em background
messaging.onBackgroundMessage((payload) => {
  console.log('📬 Notificação FCM recebida (background):', payload);

  const notificationTitle = payload.notification?.title || 'AlanoCryptoFX';
  const notificationOptions = {
    body: payload.notification?.body || 'Nova notificação',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'default',
    data: payload.data,
    requireInteraction: false,
    vibrate: [200, 100, 200],
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Criar BroadcastChannel para comunicação
const channel = new BroadcastChannel('notification_channel');

// Quando usuário clica na notificação
self.addEventListener('notificationclick', (event) => {
  console.log('🔔 Notificação clicada:', event.notification.data);
  event.notification.close();

  const data = event.notification.data || {};

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Enviar mensagem via BroadcastChannel
      channel.postMessage({
        type: 'NOTIFICATION_CLICK',
        notifType: data.type,
        data: data
      });

      console.log('📡 Mensagem enviada via BroadcastChannel:', data.type);

      // Focar ou abrir janela
      for (let client of clientList) {
        if (client.url.includes(self.location.origin)) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

// Quando o service worker é instalado
self.addEventListener('install', (event) => {
  console.log('✅ Service Worker FCM instalado');
  self.skipWaiting();
});

// Quando o service worker é ativado
self.addEventListener('activate', (event) => {
  console.log('✅ Service Worker FCM ativado');
  event.waitUntil(clients.claim());
});
