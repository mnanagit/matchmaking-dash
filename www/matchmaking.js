/* matchmaking.js
 * 1. Page switching About <-> Dashboard (same two-page pattern as the
 *    mondial-dashboard template).
 * 2. Match overview: clicking a grid cell sends {country, topic} to Shiny
 *    as input$overview_pick (server shows the drill-down modal).
 * 3. Table row click sends the submission uid as input$row_click (server
 *    shows the details modal); links inside the row keep their own action.
 */

function enterDashboard() {
  document.getElementById("about-page").style.display = "none";
  document.getElementById("dashboard-page").style.display = "flex";
  // Tables/pickers were laid out while hidden: let them re-measure
  window.dispatchEvent(new Event("resize"));
  if (window.jQuery && jQuery.fn.dataTable) {
    jQuery.fn.dataTable.tables({ visible: true, api: true }).columns.adjust();
  }
}

function enterAbout() {
  document.getElementById("dashboard-page").style.display = "none";
  document.getElementById("about-page").style.display = "";
}

document.addEventListener("click", function (e) {
  if (e.target.closest("#enter-dashboard-btn")) { enterDashboard(); return; }
  if (e.target.closest("#about-info-btn"))      { enterAbout(); return; }

  var cell = e.target.closest(".overview-table td.mm-cell[data-country]");
  if (cell && window.Shiny) {
    Shiny.setInputValue("overview_pick", {
      country: cell.getAttribute("data-country"),
      topic:   cell.getAttribute("data-topic")
    }, { priority: "event" });
  }
});

// Table row click -> details modal. The row's hidden first column holds the
// submission uid; links inside the row (website / mailto) keep their own action.
document.addEventListener("click", function (e) {
  var tr = e.target.closest(".mm-table tbody tr");
  if (!tr || e.target.closest("a") || !window.jQuery || !window.Shiny) return;
  var data = jQuery(tr).closest("table").DataTable().row(tr).data();
  if (data && data[0]) Shiny.setInputValue("row_click", data[0], { priority: "event" });
});

// Re-adjust DataTable columns when switching tabs (hidden tables mis-measure)
document.addEventListener("shown.bs.tab", function () {
  if (window.jQuery && jQuery.fn.dataTable) {
    jQuery.fn.dataTable.tables({ visible: true, api: true }).columns.adjust();
  }
});
