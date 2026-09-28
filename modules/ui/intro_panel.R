# =============================================================================
# UI: INTRO PANEL - About & How to Use page (shown inside ui_main.R's
# #about-page shell; page switching lives in www/matchmaking.js)
# =============================================================================

about_section <- function(icon_name, title) {
  div(
    class = "about-section-header",
    tags$span(class = "about-section-icon", icon(icon_name)),
    tags$h3(title, class = "about-section-title")
  )
}

intro_panel_ui <- function() {
  n_pp  <- sum(SUBMISSIONS$actor == ACTOR_PP)
  n_res <- sum(SUBMISSIONS$actor == ACTOR_RES)

  div(
    class = "about-card",

    div(
      class = "about-header-row",
      tags$img(src = "eth_logo.png", height = "56px", alt = "ETH Zurich")
    ),
    tags$h1("Innovative Cities & Infrastructure Programme · Matchmaking Dashboard",
            class = "about-title"),
    tags$hr(class = "about-hr-top"),

    about_section("handshake", "About the Matchmaking"),
    tags$p(
      class = "about-body-text",
      "This dashboard brings together the project ideas submitted to the Innovative Cities & ",
      "Infrastructure Programme by ", tags$strong("practice partners"), " from eligible countries ",
      "and by ", tags$strong("researchers"), " from ETH Domain institutions. ",
      "It helps identify where both sides share a focus country and a thematic area, ",
      "so that promising partnerships can be connected."
    ),
    div(
      class = "about-stats",
      div(class = "about-stat pp", tags$strong(n_pp), tags$span("practice partner submissions")),
      div(class = "about-stat res", tags$strong(n_res), tags$span("researcher submissions")),
      div(class = "about-stat", tags$strong(length(setdiff(ALL_COUNTRIES, NOT_SPECIFIED))),
          tags$span("focus countries"))
    ),

    about_section("compass", "How to Use"),
    tags$ol(
      class = "about-body-list",
      tags$li(tags$strong("Country:"), " pick one or more focus countries (leave empty for all). ",
              "The numbers show practice partners · researchers per country."),
      tags$li(tags$strong("Big topic:"), " the list narrows to the topics present in the chosen countries."),
      tags$li(tags$strong("Actors:"), " show practice partners, researchers, or both."),
      tags$li(tags$strong("Tables:"), " click any row to read the full submission ",
              "(summary, rationale, envisioned role) and see potential matches."),
      tags$li(tags$strong("Match overview:"), " a country × topic grid; highlighted cells have ",
              "both a practice partner and a researcher. Click a cell to see who they are."),
      tags$li(tags$strong("Download:"), " export the filtered tables to Excel.")
    ),

    about_section("database", "Data"),
    tags$p(
      class = "about-body-text-muted",
      "Submissions from the programme's online registration forms. Ukraine-track submissions ",
      "use the Ukraine thematic focus list; all topics are merged into one list here. ",
      "Data last updated: ", tags$strong(format(DATA_AS_OF, "%d %B %Y")), "."
    ),
    tags$p(
      class = "about-body-text-muted",
      icon("lock"), " To protect submitters' privacy, names and contact details are not published ",
      "here, and personal details have been removed from the texts. ",
      "To connect with a practice partner or researcher, please contact the programme team."
    ),

    tags$hr(class = "about-hr-bottom"),

    div(
      class = "about-button-row",
      tags$button(id = "enter-dashboard-btn", type = "button",
                  class = "about-enter-btn", "Open the Dashboard →")
    )
  )
}
