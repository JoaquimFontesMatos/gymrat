import { openobserveRum } from "@openobserve/browser-rum";

// Authentication links contain one-time tokens in their paths. Do not start
// recording when a visitor arrives at one of those pages.
const sensitivePath = /^\/users\/(?:log-in\/|settings\/confirm-email\/)/;

function unsafeReplayUrl(value) {
  try {
    const url = new URL(value, window.location.href);
    return sensitivePath.test(url.pathname) || !!url.search || !!url.hash;
  } catch (_) {
    return true;
  }
}

function sanitizedUrl(value) {
  try {
    const url = new URL(value, window.location.origin);
    url.search = "";
    url.hash = "";
    url.pathname = url.pathname
      .replace(/^(\/users\/(?:log-in|settings\/confirm-email)\/)[^/]+/, "$1:redacted")
      .replace(/\b[0-9a-f]{8}-[0-9a-f-]{27,}\b/gi, ":id");
    return url.toString();
  } catch (_) {
    return "";
  }
}

export function setupRum() {
  if (!document.querySelector('meta[name="gymrat-rum"]') || unsafeReplayUrl(location.href)) return;

  // Replay snapshots contain the full current URL. Stop before SPA navigation
  // to a token-bearing path or URL with a query/fragment can be snapshotted.
  for (const method of ["pushState", "replaceState"]) {
    const original = history[method];
    history[method] = function (...args) {
      if (args[2] && unsafeReplayUrl(args[2])) openobserveRum.stopSessionReplayRecording();
      return original.apply(this, args);
    };
  }
  window.addEventListener("popstate", () => {
    if (unsafeReplayUrl(location.href)) openobserveRum.stopSessionReplayRecording();
  });

  openobserveRum.init({
    applicationId: "gymrat",
    // The actual token is injected by Gymrat's server-side intake proxy.
    clientToken: "gymrat-proxy",
    site: location.host,
    insecureHTTP: location.protocol === "http:",
    organizationIdentifier: "default",
    service: "gymrat",
    env: "production",
    sessionSampleRate: 100,
    sessionReplaySampleRate: 100,
    defaultPrivacyLevel: "mask",
    trackUserInteractions: false,
    trackResources: true,
    trackLongTasks: true,
    beforeSend(event) {
      // The SDK only permits modifying certain fields. Drop errors whose
      // unmodifiable fields could contain secrets; retain safe error counts.
      if (event.type === "error" && event.error) {
        const error = event.error;
        const safeTypes = ["Error", "TypeError", "RangeError", "ReferenceError", "SyntaxError", "URIError", "EvalError"];
        if ((error.type && !safeTypes.includes(error.type)) || error.causes?.length || error.component_stack || error.csp) return false;
        for (const key of ["message", "stack", "handling_stack", "fingerprint"]) {
          if (typeof error[key] === "string") error[key] = "[redacted]";
        }
        if (error.resource?.url) error.resource.url = "[redacted]";
      }
      if (event.context) event.context = {};
      if (event.view?.url) {
        const path = new URL(event.view.url, location.origin).pathname;
        if (sensitivePath.test(path)) {
          openobserveRum.stopSessionReplayRecording();
          // The SDK does not allow view events to be dropped. Redact their URL
          // below; all other event types for this path can be discarded.
          if (event.type !== "view") return false;
        }
        event.view.url = sanitizedUrl(event.view.url);
      }
      if (event.view?.referrer) event.view.referrer = sanitizedUrl(event.view.referrer);
      if (event.resource?.url) event.resource.url = sanitizedUrl(event.resource.url);
      return true;
    },
  });
}
