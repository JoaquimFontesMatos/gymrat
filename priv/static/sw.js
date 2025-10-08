// This event fires when the service worker is first installed.
self.addEventListener("install", (event) => {
  console.log("Service Worker: Installed");
});

// This event fires every time the browser fetches a URL from your site.
// We're not doing anything with it now, but it's where you'd add caching logic.
self.addEventListener("fetch", (event) => {
  // Let the browser handle the request as it normally would.
});
