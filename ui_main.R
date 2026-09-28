# =============================================================================
# UI MAIN - Main user interface definition
# =============================================================================

source("setup_and_data.R")

source("modules/ui/panel_helpers.R")
source("modules/ui/intro_panel.R")
source("modules/ui/login_panel.R")
source("modules/ui/sidebar.R")
source("modules/ui/main_panel.R")

#' Asset path with a content hash so browsers never serve a stale copy
versioned_asset <- function(file) {
  paste0(file, "?v=", digest::digest(file = file.path("www", file), algo = "md5"))
}

# =============================================================================
# Three separate pages, only one visible at a time (same pattern as the
# mondial-dashboard template); switching is wired in www/matchmaking.js:
#   #about-page    : shown on load
#   #login-page    : shown when #enter-dashboard-btn is clicked before login
#   #dashboard-page: shown once the ETH Domain login succeeded
# =============================================================================

ui <- fluidPage(

  theme = bs_theme(version = 5, bootswatch = "flatly", primary = "#215CAF"),

  tags$head(
    tags$title("Matchmaking Dashboard"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", type = "text/css", href = versioned_asset("styles.css")),
    tags$script(src = versioned_asset("matchmaking.js"))
  ),

  # PAGE 1: ABOUT
  div(id = "about-page", intro_panel_ui()),

  # PAGE 2: LOGIN (ETH Domain email + one-time code)
  div(id = "login-page", login_panel_ui()),

  # PAGE 3: DASHBOARD
  div(
    id = "dashboard-page",

    div(
      class = "app-navbar",
      div(
        class = "app-navbar-brand",
        tags$img(src = "eth_logo.png", height = "30px", alt = "ETH Zurich", class = "navbar-logo"),
        tags$span(class = "navbar-title", "Matchmaking Dashboard"),
        tags$span(class = "navbar-subtitle", "Innovative Cities & Infrastructure Programme")
      ),
      tags$button(
        id = "about-info-btn",
        type = "button",
        HTML("&#x2139;"),
        class = "about-info-btn",
        title = "About & How to Use"
      )
    ),

    div(
      class = "dashboard-content",
      layout_sidebar(
        sidebar = sidebar_ui(),
        fill = TRUE,
        main_panel_ui()
      )
    )
  )
)
