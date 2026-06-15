{{flutter_js}}
{{flutter_build_config}}

// Skip service worker (causes 4000ms timeout on GitHub Pages static hosting).
// Let Flutter auto-initialize with all other defaults unchanged.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: null
  }
});
