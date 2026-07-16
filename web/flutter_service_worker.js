// SELF-DESTRUCT service worker. Earlier builds shipped Flutter's PWA worker,
// which cached the app so aggressively that new builds never appeared
// ("changes aren't visible"). We now build with --pwa-strategy=none; this file
// exists ONLY so browsers that already registered the old worker update to
// this one, which wipes every cache and unregisters itself, then reloads.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((k) => caches.delete(k)));
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    for (const c of clients) c.navigate(c.url);
  })());
});
