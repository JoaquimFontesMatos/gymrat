let Hooks = {};

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

export default Hooks;
