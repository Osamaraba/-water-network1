const CACHE = 'water-pump-v1';
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
    e.respondWith(
      caches.match(e.request).then(res => res || fetch(e.request).catch(() => new Response('Offline', { status: 503 })))
    );
  }
});
