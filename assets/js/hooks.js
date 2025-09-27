let Hooks = {};

Hooks.Chart = {
  mounted() {
    import("chart.js/auto").then(({ default: Chart }) => {
      const data = JSON.parse(this.el.dataset.chart);
      const ctx = this.el.getContext("2d");

      this.chart = new Chart(ctx, {
        type: "line",
        data: data,
        options: {
          responsive: true,
          plugins: {
            legend: { display: true },
          },
          scales: {
            y: {
              beginAtZero: true,
              title: { display: true, text: "Weight (kg)" },
            },
            x: { title: { display: true, text: "Time" } },
          },
        },
      });
    });
  },
};

export default Hooks;
