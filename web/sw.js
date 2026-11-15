// Offline support: serve app files from cache, refresh them in the background.
// Bump CACHE_NAME (and APP_VERSION in app.js) whenever files change.
// Voice clips (voices/<id>/*.wav) are not listed here: they are cached when first played/preloaded.
const CACHE_NAME = "pickle-score-v0.4.1";
const FILES = [
  "./",
  "./index.html",
  "./style.css",
  "./app.js",
  "./core.js",
  "./voice.js",
  "./history.js",
  "./img/dogs/ohagi.png",
  "./img/dogs/kinako.png",
  "./img/dogs/shiratama.png",
  "./img/dogs/dorayaki.png",
  "./img/dogs/yokan.png",
  "./img/dogs/ohagi_face.png",
  "./voice-words.json",
  "./voices/voices.json",
  "./fonts/mplus-rounded-bold.woff2",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/apple-touch-icon.png",
];

self.addEventListener("install", (event) => {
  // cache: "reload" skips the browser's HTTP cache so a new version never stores old files.
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((c) => c.addAll(FILES.map((f) => new Request(f, { cache: "reload" }))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET" || new URL(req.url).origin !== self.location.origin) return;
  event.respondWith(
    caches.open(CACHE_NAME).then(async (cache) => {
      const cached = await cache.match(req, { ignoreSearch: true });
      // Page loads (navigate) cannot take extra options; other files skip the HTTP cache.
      const network = (req.mode === "navigate" ? fetch(req) : fetch(req, { cache: "no-cache" }))
        .then((res) => { if (res.ok) cache.put(req, res.clone()); return res; })
        .catch(() => null);
      if (cached) { event.waitUntil(network); return cached; }
      const res = await network;
      return res || (req.mode === "navigate" ? cache.match("./index.html") : Response.error());
    }),
  );
});
