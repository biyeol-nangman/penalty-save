// 패널티킥 세이브 서비스 워커.
// 게임 화면은 오프라인에서도 열리게 저장해 두고, 순위표(Supabase) 요청은 건드리지 않습니다.
// 화면을 고쳐서 새로 배포했다면 아래 VERSION 숫자만 올리면 설치된 앱도 새 파일을 받습니다.
const VERSION = 'v1';
const CACHE = 'penalty-save-' + VERSION;
const SHELL = [
  './',
  'index.html',
  'config.js',
  'manifest.json',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/icon-maskable-512.png',
  'icons/apple-touch-icon.png',
  'icons/icon-32.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('penalty-save-') && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;   // Supabase, 구글 폰트 등은 그대로 통과

  // 화면과 설정 파일: 인터넷이 되면 항상 최신 파일, 안 되면 저장해 둔 파일
  const fresh = req.mode === 'navigate' || /\/(index\.html|config\.js|manifest\.json)$/.test(url.pathname) || url.pathname.endsWith('/');
  if (fresh) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
          return res;
        })
        .catch(() => caches.match(req).then((hit) => hit || caches.match('index.html')))
    );
    return;
  }

  // 아이콘 등: 저장해 둔 것을 먼저 사용
  event.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
      return res;
    }))
  );
});
