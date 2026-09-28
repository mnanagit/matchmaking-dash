# =============================================================================
# UI: SIDEBAR - Filter panel
# =============================================================================
# Three connected filter levels (cascading logic in modules/server/filters.R):
# 1. Country     (multi-select; empty = all)
# 2. Topic areas (multi-select; choices narrow to the selected countries)
# 3. Practice partner / ETH Domain researcher toggle
# =============================================================================

# Display names on the actor toggle (values stay ACTOR_TYPES)
ACTOR_TOGGLE_LABELS <- c(
  "Practice partners" = "Practice partners",
  "Researchers"       = "ETH Domain researchers"
)

#' Shared pickerInput options for the multi-select filters
filter_picker_options <- function(none_text) {
  shinyWidgets::pickerOptions(
    actionsBox = TRUE,
    liveSearch = length(ALL_COUNTRIES) > 8,
    noneSelectedText = none_text,
    selectedTextFormat = "count > 2",
    countSelectedText = "{0} selected",
    selectAllText = "All",
    deselectAllText = "Clear",
    size = 10
  )
}

sidebar_ui <- function() {
  sidebar(
    width = 330,

    div(
      class = "sidebar-scroll-area",

      # =========================================================================
      # 1. COUNTRY
      # =========================================================================
      div(
        class = "measure-wizard",
        tags$label(class = "sidebar-step-label", `for` = "f_country",
                   tags$span(class = "step-num", "1"), "Country"),
        pickerInput(
          "f_country", label = NULL,
          choices = ALL_COUNTRIES,  # counts are added after login (filters.R)
          multiple = TRUE,
          options = filter_picker_options("All countries")
        )
      ),

      # =========================================================================
      # 2. TOPIC AREAS
      # =========================================================================
      div(
        class = "measure-wizard",
        tags$label(class = "sidebar-step-label", `for` = "f_topic",
                   tags$span(class = "step-num", "2"), "Topic areas"),
        pickerInput(
          "f_topic", label = NULL,
          choices = ALL_TOPICS,
          multiple = TRUE,
          options = filter_picker_options("All topic areas")
        )
      ),

      # =========================================================================
      # 3. PRACTICE PARTNER / ETH DOMAIN RESEARCHER
      # =========================================================================
      div(
        class = "measure-wizard",
        tags$label(class = "sidebar-step-label",
                   tags$span(class = "step-num", "3"),
                   "Practice partner / ETH Domain researcher"),
        checkboxGroupButtons(
          "f_actor", label = NULL,
          choiceNames = lapply(ACTOR_TYPES, function(a) tagList(icon(ACTOR_ICONS[[a]]), " ", ACTOR_TOGGLE_LABELS[[a]])),
          choiceValues = ACTOR_TYPES,
          selected = ACTOR_TYPES,
          justified = TRUE,
          size = "sm",
          status = "outline-primary"
        )
      ),

      div(class = "filter-hint", "Counts in brackets: practice partners · researchers."),

      # Live result summary + reset
      div(
        class = "filter-summary",
        uiOutput("filter_summary"),
        actionButton("reset_filters", tagList(icon("rotate-left"), " Reset filters"),
                     class = "btn-sm btn-outline-primary w-100 mt-2")
      )
    ),

    # =========================================================================
    # Footer
    # =========================================================================
    div(
      class = "sidebar-footer",
      tags$h5(class = "sidebar-footer-title", icon("city"), " Innovative Cities & Infrastructure"),
      tags$p(class = "sidebar-footer-text",
             "Submissions up to ", format(DATA_AS_OF, "%d %b %Y"))
    ),

    tags$script(src = versioned_asset("sidebar-resize.js"))
  )
}
