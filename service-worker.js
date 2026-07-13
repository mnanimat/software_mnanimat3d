const CACHE = 'mnanimat3d-v13';
const CORE = [
  './', './index.html', './styles.css', './src/app.js?v=13', './src/engine.js?v=13', './src/icons.js?v=13',
  './assets/icon.svg', './manifest.webmanifest', './lib/three/three.module.js', './lib/three/three.core.js',
  './lib/three/addons/controls/OrbitControls.js', './lib/three/addons/controls/TransformControls.js',
  './lib/three/addons/loaders/GLTFLoader.js', './lib/three/addons/loaders/OBJLoader.js',
  './lib/three/addons/exporters/GLTFExporter.js', './lib/three/addons/exporters/OBJExporter.js',
  './lib/three/addons/utils/BufferGeometryUtils.js'
];

self.addEventListener('install', event => event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(CORE)).then(() => self.skipWaiting())));
self.addEventListener('activate', event => event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim())));
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  if (new URL(event.request.url).pathname.endsWith('.glb')) {
    event.respondWith(fetch(event.request));
    return;
  }
  event.respondWith(caches.match(event.request).then(cached => cached || fetch(event.request).then(response => {
    if (response.ok && response.type === 'basic') caches.open(CACHE).then(cache => cache.put(event.request, response.clone()));
    return response;
  })));
});
