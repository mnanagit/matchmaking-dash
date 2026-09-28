/* matchmaking.js
 * 1. Page switching About <-> Login <-> Dashboard (same page pattern as the
 *    mondial-dashboard template). The dashboard opens only after the server
 *    confirms the ETH Domain login ("mm-auth" message, modules/server/auth.R);
 *    the server also withholds all data until then.
 * 2. Match overview: clicking a grid cell sends {country, topic} to Shiny
 *    as input$overview_pick (server shows the drill-down modal).
 * 3. Table row click sends the submission uid as input$row_click (server
 *    shows the details modal); links inside the row keep their own action.
 */

var mmAuthed = false;

function showOnly(pageId) {
  ["about-page", "login-page", "dashboard-page"].forEach(function (id) {
    document.getElementById(id).style.display = "none";
  });
  // about-page is flex via CSS; login/dashboard are display:none in CSS
  var shown = { "about-page": "", "login-page": "block", "dashboard-page": "flex" };
  document.getElementById(pageId).style.display = shown[pageId];
}

function enterLogin() {
  showOnly("login-page");
  var email = document.getElementById("login_email");
  if (email) email.focus();
}

function enterDashboard() {
  showOnly("dashboard-page");
  // Tables/pickers were laid out while hidden: let them re-measure
  window.dispatchEvent(new Event("resize"));
  if (window.jQuery && jQuery.fn.dataTable) {
    jQuery.fn.dataTable.tables({ visible: true, api: true }).columns.adjust();
  }
}

function enterAbout() {
  showOnly("about-page");
}

if (window.jQuery) {
  jQuery(document).on("shiny:connected", function () {
    Shiny.addCustomMessageHandler("mm-auth", function (msg) {
      if (msg && msg.ok) { mmAuthed = true; enterDashboard(); }
    });
    // Reveal the code field once a code has been sent
    Shiny.addCustomMessageHandler("mm-login-step", function (msg) {
      if (msg && msg.step === "code") {
        document.getElementById("login-step-code").style.display = "block";
        document.getElementById("login_code").focus();
      }
    });
  });
}

// Enter in a login field presses the matching button
document.addEventListener("keydown", function (e) {
  if (e.key !== "Enter") return;
  var target = { login_email: "login_send", login_code: "login_verify" }[e.target.id];
  if (target) { e.preventDefault(); document.getElementById(target).click(); }
});

document.addEventListener("click", function (e) {
  if (e.target.closest("#enter-dashboard-btn")) { mmAuthed ? enterDashboard() : enterLogin(); return; }
  if (e.target.closest("#login-back-btn"))      { enterAbout(); return; }
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
