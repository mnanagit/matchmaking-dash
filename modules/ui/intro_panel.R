# =============================================================================
# UI: INTRO PANEL - About & How to Use page (shown inside ui_main.R's
# #about-page shell; page switching lives in www/matchmaking.js)
# =============================================================================

APPLICATION_FORM_URL <- "https://forms.cloud.microsoft/e/gA1rcxT6z4"
CONTACT_EMAIL        <- "churchill.agutu@nadel.ethz.ch"

about_section <- function(icon_name, title) {
  div(
    class = "about-section-header",
    tags$span(class = "about-section-icon", icon(icon_name)),
    tags$h3(title, class = "about-section-title")
  )
}

intro_panel_ui <- function() {
  n_pp <- sum(SUBMISSIONS$actor == ACTOR_PP)

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
      div(class = "about-stat", tags$strong(length(setdiff(ALL_COUNTRIES, NOT_SPECIFIED))),
          tags$span("focus countries"))
    ),

    about_section("compass", "How to Use"),
    tags$p(class = "about-body-text",
           "The dashboard has a panel on the left with the following filtering options:"),
    tags$ol(
      class = "about-body-list",
      tags$li(tags$strong("Country:"), " pick one or more focus countries (leave empty for all). ",
              "The numbers show practice partners · researchers per country."),
      tags$li(tags$strong("Topic areas:"),
              " the list narrows to the topics present in the chosen countries."),
      tags$li(tags$strong("Practice partner / ETH Domain researcher toggle:"),
              " filter for researchers at the ETH Domain or for practice partners.")
    ),

    about_section("user-graduate",
                  "If you are an ETH Domain researcher looking for a potential partner"),
    tags$ol(
      class = "about-body-list",
      tags$li("Fill in the ",
              tags$a(class = "about-link", href = APPLICATION_FORM_URL, target = "_blank",
                     rel = "noopener", "application form"), "."),
      tags$li("Review the existing projects on the matchmaking dashboard ",
              tags$span(class = "muted", "(login with an ETH Domain email address)."),
              " A one-time login code is sent to you by email (valid for ", OTP_TTL_MIN,
              " minutes). ", tags$strong("Please check your spam folder as well."))
    ),

    about_section("circle-info", "Please Note:"),
    tags$p(class = "about-body-text",
           "Date last updated: ", tags$strong(format(DATA_AS_OF, "%d %B %Y"))),
    tags$ul(
      class = "about-body-list",
      tags$li("This dashboard contains project ideas submitted by practice partners to the ",
              "ETH4D Innovative Cities & Infrastructure call."),
      tags$li("Take a look at the practice partner matchmaking dashboard for more information, ",
              "and reach out to make the connection if you find a project of interest.",
              tags$br(),
              tags$a(class = "about-link", href = paste0("mailto:", CONTACT_EMAIL), CONTACT_EMAIL)),
      tags$li("These project ideas are online submissions and have not been vetted by ETH4D. ",
              "Before starting a collaboration, researchers should check directly with the ",
              "submitting organisation that the project meets all call eligibility requirements, ",
              "including the evaluation criteria and the definition of a local non-academic ",
              "practice partner."),
      tags$li("This overview is only meant to give you a sense of the project ideas submitted."),
      tags$li("For further information about the INCI programme or the ETHZ Urban Research Grant, ",
              "please refer to the Innovative Cities & Infrastructure Programme website and the ",
              "Call for Proposals Guidelines."),
      tags$li("This dashboard is a service offered for ETH4D and is not a formal part of the ",
              "application process for ETH Zurich Urban Grants.")
    ),

    tags$hr(class = "about-hr-bottom"),

    div(
      class = "about-button-row",
      tags$button(id = "enter-dashboard-btn", type = "button",
                  class = "about-enter-btn", "Open the Dashboard →")
    )
  )
}
