let Hooks = {};

// Pointer-based drag-and-drop reordering (works with mouse AND touch — no JS
// dependency).
//
// Markup contract on the container (the element carrying phx-hook="Sortable"):
//   - each reorderable child has [data-sortable-item] and data-id="<id>"
//   - a drag affordance inside each child has [data-drag-handle] (give it the
//     `touch-none` class so a touch drag doesn't scroll the page)
// Dragging starts only from a handle, so inputs/buttons in the row stay usable.
// The list reorders live under the pointer (visual feedback) and the dragged
// row is highlighted; on release the new order of ids is pushed as a
// "reposition" event ({ids: [...]}).
Hooks.Sortable = {
  mounted() {
    const el = this.el;
    const DRAG_CLASSES = ["opacity-60", "ring-2", "ring-primary", "shadow-lg"];
    this.dragEl = null;

    const ids = () =>
      Array.from(el.querySelectorAll("[data-sortable-item]")).map((i) => i.dataset.id);

    this.onMove = (e) => {
      if (!this.dragEl) return;
      e.preventDefault();
      const items = Array.from(el.querySelectorAll("[data-sortable-item]"));
      const over = items.find((it) => {
        if (it === this.dragEl) return false;
        const r = it.getBoundingClientRect();
        return e.clientY >= r.top && e.clientY <= r.bottom;
      });
      if (over) {
        const r = over.getBoundingClientRect();
        const after = e.clientY > r.top + r.height / 2;
        el.insertBefore(this.dragEl, after ? over.nextSibling : over);
      }
    };

    this.onUp = () => {
      if (!this.dragEl) return;
      this.dragEl.classList.remove(...DRAG_CLASSES);
      this.dragEl = null;
      document.removeEventListener("pointermove", this.onMove);
      document.removeEventListener("pointerup", this.onUp);
      document.removeEventListener("pointercancel", this.onUp);
      this.pushEvent("reposition", { ids: ids() });
    };

    this.onDown = (e) => {
      const handle = e.target.closest("[data-drag-handle]");
      if (!handle) return;
      const item = handle.closest("[data-sortable-item]");
      if (!item) return;
      e.preventDefault();
      this.dragEl = item;
      item.classList.add(...DRAG_CLASSES);
      document.addEventListener("pointermove", this.onMove, { passive: false });
      document.addEventListener("pointerup", this.onUp);
      document.addEventListener("pointercancel", this.onUp);
    };

    el.addEventListener("pointerdown", this.onDown);
  },

  destroyed() {
    document.removeEventListener("pointermove", this.onMove);
    document.removeEventListener("pointerup", this.onUp);
    document.removeEventListener("pointercancel", this.onUp);
  },
};

Hooks.ChartLoader = {
  mounted() {
    this.pushEvent("load_chart_data", {});
  },
};

Hooks.Share = {
  mounted() {
    this.el.addEventListener("share-plan", (e) => {
      const { share_token, name } = e.detail;

      // Check if the Web Share API is supported by the browser
      if (navigator.share) {
        navigator
          .share({
            title: `Gymrat Plan: ${name}`,
            text: `Here is the ID for the workout plan "${name}": ${share_token}`,
            // You could also add a URL if you have a public page for plans
            // url: `https://yourapp.com/plans/${share_token}`
          })
          .then(() => console.log("Successful share"))
          .catch((error) => console.log("Error sharing", error));
      } else {
        // Fallback for desktop browsers: copy UUID to clipboard
        navigator.clipboard
          .writeText(share_token)
          .then(() => {
            alert("Plan ID copied to clipboard!"); // Simple feedback
          })
          .catch((err) => {
            console.error("Failed to copy: ", err);
            alert("Failed to copy ID.");
          });
      }
    });
  },
};

Hooks.Chart = {
  mounted() {
    import("chart.js/auto").then(({ default: Chart }) => {
      const data = JSON.parse(this.el.dataset.chart);
      const ctx = this.el.getContext("2d");
      const yAxisTitle = this.el.dataset.yAxisTitle || "Value";

      this.chart = new Chart(ctx, {
        type: "line",
        data: data,
        options: {
          segment: {
            borderDash: (ctx) =>
              ctx.p0.skip || ctx.p1.skip ? [6, 6] : undefined,
          },
          spanGaps: true,
          responsive: true,
          plugins: {
            legend: { display: true },
          },
          scales: {
            y: {
              title: { display: true, text: yAxisTitle },
              grace: "10%",
            },

            x: { title: { display: true, text: "Time" } },
          },
        },
      });
    });
  },
};

// The countdown is stored as an absolute end-time (epoch ms) in localStorage,
// so it survives a page reload or navigation and is recomputed each tick rather
// than decremented — which also keeps it accurate when the tab is backgrounded
// (setInterval is throttled there). Override the storage key with
// data-timer-key if a page needs an independent timer.
Hooks.RestTimer = {
  mounted() {
    this.key = this.el.dataset.timerKey || "gymrat:rest-timer";
    this.interval = null;
    this.display = this.el.querySelector("[data-role=display]");

    // When data-on-complete is set (guided rest screen) and the user has the
    // auto-skip toggle on, finishing the countdown pushes that event to advance.
    const onComplete = this.el.dataset.onComplete;
    const autoskipKey = "gymrat:rest-autoskip";
    const autoskipOn = () => localStorage.getItem(autoskipKey) === "1";

    const format = (s) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    const remaining = () => {
      const end = parseInt(localStorage.getItem(this.key) || "0", 10);
      return Math.max(Math.ceil((end - Date.now()) / 1000), 0);
    };
    const render = () => {
      this.display.textContent = format(remaining());
    };

    this.stop = () => {
      if (this.interval) {
        clearInterval(this.interval);
        this.interval = null;
      }
    };

    this.clear = () => {
      this.stop();
      localStorage.removeItem(this.key);
      render();
    };

    this.beep = () => {
      try {
        const ctx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = "sine";
        osc.frequency.value = 880;
        gain.gain.setValueAtTime(0.1, ctx.currentTime);
        osc.start();
        osc.stop(ctx.currentTime + 0.2);
      } catch (e) {
        /* Web Audio unavailable — fail silently */
      }
    };

    const tick = () => {
      render();
      if (remaining() <= 0) {
        this.stop();
        localStorage.removeItem(this.key);
        this.beep();
        this.el.classList.add("ring-2", "ring-success");
        setTimeout(() => this.el.classList.remove("ring-2", "ring-success"), 1500);
        if (onComplete && autoskipOn()) this.pushEvent(onComplete, {});
      }
    };

    this.run = () => {
      this.stop();
      this.interval = setInterval(tick, 250);
    };

    this.start = (seconds) => {
      localStorage.setItem(this.key, String(Date.now() + seconds * 1000));
      render();
      this.run();
    };

    // Push the end-time forward (the "+15s" control). Extends from whatever is
    // left, or from now if the countdown already lapsed.
    this.extend = (seconds) => {
      const end = Math.max(parseInt(localStorage.getItem(this.key) || "0", 10), Date.now());
      localStorage.setItem(this.key, String(end + seconds * 1000));
      render();
      this.run();
    };

    this.el.querySelectorAll("[data-rest]").forEach((btn) => {
      btn.addEventListener("click", () => this.start(parseInt(btn.dataset.rest, 10)));
    });
    this.el.querySelectorAll("[data-rest-add]").forEach((btn) => {
      btn.addEventListener("click", () => this.extend(parseInt(btn.dataset.restAdd, 10)));
    });
    // Optional controls — absent on the guided rest screen.
    const resetBtn = this.el.querySelector("[data-role=reset]");
    if (resetBtn) resetBtn.addEventListener("click", () => this.clear());

    // Auto-skip toggle — its choice persists across rest steps and reloads.
    const autoskipBox = this.el.querySelector("[data-role=autoskip]");
    if (autoskipBox) {
      autoskipBox.checked = autoskipOn();
      autoskipBox.addEventListener("change", () => {
        localStorage.setItem(autoskipKey, autoskipBox.checked ? "1" : "0");
      });
    }

    // Resume an in-progress countdown after a reload; otherwise auto-start from
    // data-autostart-seconds (guided rest screen) or drop a stale entry.
    render();
    const autostart = parseInt(this.el.dataset.autostartSeconds || "0", 10);
    if (remaining() > 0) {
      this.run();
    } else if (autostart > 0) {
      this.start(autostart);
    } else {
      localStorage.removeItem(this.key);
    }
  },

  destroyed() {
    this.stop();
  },
};

export default Hooks;
