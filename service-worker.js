const CACHE = 'water-pump-v3';
const urlsToCache = [
  'index.html',
  'manifest.json'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(urlsToCache))
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(clients.claim());
});

self.addEventListener('fetch', e => {
  if (e.request.url.startsWith('http')) {
    // Network-first for index.html, cache-first for everything else
    if (e.request.url.endsWith('index.html') || e.request.url.endsWith('/')) {
      e.respondWith(
        fetch(e.request).then(res => {
          return caches.open(CACHE).then(cache => {
            cache.put(e.request, res.clone());
            return res;
          });
        }).catch(() => caches.match(e.request).then(res => res || new Response('Offline', { status: 503 })))
      );
    } else {
      e.respondWith(
        caches.match(e.request).then(res => res || fetch(e.request).catch(() => new Response('Offline', { status: 503 })))
      );
    }
  }
});
