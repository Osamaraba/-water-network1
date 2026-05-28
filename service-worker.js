var CACHE='water-pump-v6';

self.addEventListener('install',function(e){
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(function(cache){
    return cache.addAll(['manifest.json',
      'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.css',
      'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js']);
  }));
});

self.addEventListener('activate',function(e){
  e.waitUntil(clients.claim());
  e.waitUntil(caches.keys().then(function(keys){
    return Promise.all(keys.filter(function(k){return k!==CACHE;}).map(function(k){return caches.delete(k);}));
  }));
});

self.addEventListener('fetch',function(e){
  // Never cache index.html - always fetch fresh
  if(e.request.url.indexOf('index.html')>-1||e.request.url===self.location.origin||e.request.url===self.location.origin+'/'){
    e.respondWith(fetch(e.request).catch(function(){return new Response('تعذر الاتصال',{status:503});}));
    return;
  }
  e.respondWith(
    caches.match(e.request).then(function(res){
      return res||fetch(e.request).catch(function(){return new Response('',{status:503});});
    })
  );
});
