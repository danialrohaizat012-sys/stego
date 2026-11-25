// Kill-switch for the old Stego PWA service worker (cache-first, v14).
// Browsers that still run the old worker fetch this file on their next visit,
// install it, wipe every cache, unregister, and reload into the new Flutter app.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
      await self.registration.unregister();
      const clients = await self.clients.matchAll({ type: 'window' });
      for (const client of clients) client.navigate(client.url);
    })(),
  );
});
