let Hooks = {};

// Native HTML5 drag-and-drop reordering (no JS dependency).
//
// Markup contract on the container (the element carrying phx-hook="Sortable"):
//   - each reorderable child has [data-sortable-item] and data-id="<id>"
//   - a drag affordance inside each child has [data-drag-handle]
// Dragging is enabled only while a handle is pressed, so inputs/buttons in the
// row stay usable. On drop, the new order of ids is pushed as a "reposition"
// event ({ids: [...]}). Listeners live on the stable container so they survive
// LiveView DOM patching when the list re-renders.
Hooks.Sortable = {
  mounted() {
    const el = this.el;
    this.dragging = null;

    el.addEventListener("mousedown", (e) => {
      const handle = e.target.closest("[data-drag-handle]");
      if (!handle) return;
      const item = handle.closest("[data-sortable-item]");
      if (item) item.draggable = true;
    });

    el.addEventListener("dragstart", (e) => {
      this.dragging = e.target.closest("[data-sortable-item]");
      if (this.dragging) e.dataTransfer.effectAllowed = "move";
    });

    el.addEventListener("dragover", (e) => {
      if (!this.dragging) return;
      e.preventDefault();
      const target = e.target.closest("[data-sortable-item]");
      if (!target || target === this.dragging) return;
      const rect = target.getBoundingClientRect();
      const after = (e.clientY - rect.top) / rect.height > 0.5;
      el.insertBefore(this.dragging, after ? target.nextSibling : target);
    });

    el.addEventListener("dragend", (e) => {
      const item = e.target.closest("[data-sortable-item]");
      if (item) item.draggable = false;
    });

    el.addEventListener("drop", (e) => {
      e.preventDefault();
      if (!this.dragging) return;
      this.dragging = null;
      const ids = Array.from(el.querySelectorAll("[data-sortable-item]")).map(
        (i) => i.dataset.id,
      );
      this.pushEvent("reposition", { ids });
    });
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

Hooks.RestTimer = {
  mounted() {
    this.remaining = 0;
    this.interval = null;
    this.display = this.el.querySelector("[data-role=display]");

    const format = (s) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    const render = () => {
      this.display.textContent = format(Math.max(this.remaining, 0));
    };

    this.stop = () => {
      if (this.interval) {
        clearInterval(this.interval);
        this.interval = null;
      }
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

    this.start = (seconds) => {
      this.stop();
      this.remaining = seconds;
      render();
      this.interval = setInterval(() => {
        this.remaining -= 1;
        render();
        if (this.remaining <= 0) {
          this.stop();
          this.beep();
          this.el.classList.add("ring-2", "ring-success");
          setTimeout(() => this.el.classList.remove("ring-2", "ring-success"), 1500);
        }
      }, 1000);
    };

    this.el.querySelectorAll("[data-rest]").forEach((btn) => {
      btn.addEventListener("click", () => this.start(parseInt(btn.dataset.rest, 10)));
    });
    this.el.querySelector("[data-role=reset]").addEventListener("click", () => {
      this.stop();
      this.remaining = 0;
      render();
    });

    render();
  },

  destroyed() {
    this.stop();
  },
};

export default Hooks;
