{{flutter_js}}
{{flutter_build_config}}

// Actively unregister any stale service workers from previous builds.
// GitHub Pages cannot reliably serve the cache-control headers needed
// for safe SW updates, so we opt out entirely.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function(registrations) {
    registrations.forEach(function(reg) { reg.unregister(); });
  });
}

// Load Flutter without registering a new service worker.
_flutter.loader.load();
