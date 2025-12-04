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

messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message:', payload);

  const notificationType = payload.data?.type;

  if (notificationType === 'chat_grouped') {
    const count = parseInt(payload.data?.count || '1', 10);
    const title = payload.data?.title || (count === 1 ? '1 nova mensagem no chat' : `${count} novas mensagens no chat`);

    console.log('[SW] Chat grouped notification');
    console.log('[SW] Count:', count);
    console.log('[SW] Tag: chat_general');
    console.log('[SW] Renotify: true');

    const notificationOptions = {
      body: 'Toque para ver',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: 'chat_general',
      data: payload.data,
      requireInteraction: false,
      vibrate: [200, 100, 200],
      renotify: true,
      silent: false,
    };

    return self.registration.showNotification(`💬 ${title}`, notificationOptions);
  }

  const notificationTitle = payload.data?.notificationTitle || payload.notification?.title || 'AlanoCryptoFX';
  const notificationBody = payload.data?.body || payload.notification?.body || 'Nova notificação';

  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.postId || payload.data?.type || 'default',
    data: payload.data,
    requireInteraction: false,
    vibrate: [200, 100, 200],
    renotify: false,
  };

  console.log('[SW] Mostrando notificação:', notificationTitle);

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Quando usuário clica na notificação
self.addEventListener('notificationclick', (event) => {
  console.log('🔔 Notificação clicada:', event.notification.data);
  event.notification.close();

  const data = event.notification.data || {};
  const notifType = data.type;

  console.log('📋 Tipo de notificação:', notifType);

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((clientList) => {
      console.log(`🔍 Encontrados ${clientList.length} cliente(s)`);

      for (let client of clientList) {
        if (client.url.includes(self.location.origin)) {
          console.log('✅ Cliente encontrado, focando e enviando mensagem');

          client.postMessage({
            type: 'NOTIFICATION_CLICK',
            notifType: notifType,
            data: data
          });

          return client.focus();
        }
      }

      console.log('⚠️ Nenhum cliente aberto, abrindo nova janela');
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
