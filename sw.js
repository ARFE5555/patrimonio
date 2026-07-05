const CACHE = "patrimonio-v2";

self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((ks) =>
      Promise.all(ks.map((k) => (k !== CACHE ? caches.delete(k) : null)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  const url = new URL(req.url);

  // HTML / navegación: red primero (así siempre baja la última versión)
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req)
        .then((r) => {
          const copy = r.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
          return r;
        })
        .catch(() => caches.match(req).then((r) => r || caches.match("./index.html")))
    );
    return;
  }

  // Precios: siempre desde la red, con respaldo a caché sin conexión
  if (url.hostname.includes("coingecko") || url.hostname.includes("coinpaprika")) {
    e.respondWith(fetch(req).catch(() => caches.match(req)));
    return;
  }

  // Librerías e íconos: usa caché y actualiza en segundo plano
  e.respondWith(
    caches.match(req).then((cached) => {
      const net = fetch(req)
        .then((r) => {
          const copy = r.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
          return r;
        })
        .catch(() => cached);
      return cached || net;
    })
  );
});
