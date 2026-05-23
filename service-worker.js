const CACHE = 'water-pump-v4';
const urlsToCache = [
  'index.html',
  'manifest.json'
];

self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(clients.claim());
  // Delete old caches
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
  );
});

self.addEventListener('fetch', e => {
  if (e.request.url.startsWith('http')) {
    e.respondWith(
      fetch(e.request).then(res => {
        // Only cache same-origin GET requests
        if (e.request.method === 'GET' && e.request.url.startsWith(self.location.origin)) {
          return caches.open(CACHE).then(cache => {
            cache.put(e.request, res.clone());
            return res;
          });
        }
        return res;
      }).catch(() => caches.match(e.request).then(res => res || new Response('Offline', { status: 503 })))
    );
  }
});
