/* sidebar-resize.js
 * Highcharts widgets only redraw on the browser's native "resize" event
 * (see htmlwidgets.js) -- but bslib's sidebar collapse/expand toggle
 * changes the main panel's width without firing one. Bridge the gap using
 * bslib's own documented "bslib.sidebar" custom event (dispatched with
 * {detail: {open: bool}} on the sidebar layout element whenever the
 * collapse toggle is used), re-firing a window resize once the CSS
 * collapse/expand transition finishes so any visible Highcharts chart
 * redraws to fit its new container width.
 */
document.addEventListener("bslib.sidebar", function (e) {
  var layout = e.target.closest(".bslib-sidebar-layout");
  if (!layout) return;

  var fireResize = function () {
    window.dispatchEvent(new Event("resize"));
  };

  layout.addEventListener("transitionend", fireResize, { once: true });
  // Fallback in case no CSS transition fires (e.g. reduced-motion preference)
  setTimeout(fireResize, 350);
});
