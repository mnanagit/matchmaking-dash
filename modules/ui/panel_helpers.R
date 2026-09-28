# =============================================================================
# UI: PANEL HELPERS - Shared UI-building blocks reused across analysis panels
# =============================================================================

#' Shared card/navset-pill wrapper for an analysis panel
#' @param condition JS condition string for the outer conditionalPanel (e.g.
#'   "true" -- the map panel was removed, so the descriptive panel is the only
#'   caller today and no longer needs a real condition)
#' @param navset_id The navset_pill's input ID
#' @param ... nav_panel()/nav_spacer()/nav_item() elements for the navset_pill
#' @return A conditionalPanel() UI fragment
tab_panel_shell_ui <- function(condition, navset_id, ...) {
  conditionalPanel(
    condition = condition,
    card(
      card_body(
        style = "padding: 10px;",
        div(
          style = paste(
            "display: flex; justify-content: space-between;",
            "align-items: center; margin-bottom: 6px;"
          ),
          div(
            style = "flex: 1;",
            navset_pill(id = navset_id, ...)
          )
        )
      )
    )
  )
}
