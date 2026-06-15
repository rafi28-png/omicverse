{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap: skip service worker to avoid timeout issues on GitHub Pages.
// The service worker cache can get stale and block new deployments from loading.
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
