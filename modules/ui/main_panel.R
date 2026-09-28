# =============================================================================
# UI: MAIN PANEL - KPI cards + tabbed tables
# =============================================================================

main_panel_ui <- function() {
  div(
    class = "main-panel",

    # KPI row (rendered in modules/server/tables.R)
    uiOutput("kpi_cards"),

    tab_panel_shell_ui(
      condition = "true",
      navset_id = "main_tabs",

      nav_panel(
        title = tagList(icon(ACTOR_ICONS[[ACTOR_PP]]), " Practice partners ",
                        textOutput("tab_count_pp", inline = TRUE)),
        value = ACTOR_PP,
        div(class = "table-hint", icon("hand-pointer"), " Click a row to see the full submission."),
        DTOutput("pp_table")
      ),

      nav_panel(
        title = tagList(icon(ACTOR_ICONS[[ACTOR_RES]]), " Researchers ",
                        textOutput("tab_count_res", inline = TRUE)),
        value = ACTOR_RES,
        div(class = "table-hint", icon("hand-pointer"), " Click a row to see the full submission."),
        DTOutput("res_table")
      ),

      nav_panel(
        title = tagList(icon("table-cells"), " Match overview"),
        value = "overview",
        div(
          class = "table-hint",
          tags$span(class = "legend-chip both", "partners · researchers"),
          " Highlighted cells have both actors in the same country and topic. ",
          "Click a cell to see who they are."
        ),
        uiOutput("overview_grid")
      ),

      nav_spacer(),
      nav_item(
        downloadButton("download_xlsx", "Download Excel", class = "btn-sm btn-outline-primary",
                       title = "Download the filtered tables as an Excel file")
      )
    )
  )
}
