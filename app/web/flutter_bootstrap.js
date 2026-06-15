{{flutter_js}}
{{flutter_build_config}}

// Unregister stale service workers from previous builds.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function(regs) {
    regs.forEach(function(reg) { reg.unregister(); });
  });
}

// Load Flutter — no service worker, explicit engine init so Flutter
// renders on top of the HTML loading screen immediately.
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
