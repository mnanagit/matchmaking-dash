# =============================================================================
# UI: LOGIN PANEL - ETH Domain email + one-time code (shown inside ui_main.R's
# #login-page shell; server logic in modules/server/auth.R, page and step
# switching in www/matchmaking.js)
# =============================================================================

login_panel_ui <- function() {
  div(
    class = "about-card login-card",

    div(
      class = "about-header-row",
      tags$img(src = "eth_logo.png", height = "44px", alt = "ETH Zurich")
    ),
    tags$h1("Sign in with your ETH Domain email", class = "about-title"),
    tags$hr(class = "about-hr-top"),

    tags$p(
      class = "about-body-text-muted",
      "The dashboard is open to members of the ETH Domain. Enter your institutional ",
      "email address and we will send you a one-time login code."
    ),
    tags$p(class = "login-domains", paste0("@", ETH_DOMAINS, collapse = "  ·  ")),
    tags$p(
      class = "about-body-text-muted",
      icon("circle-info"), " Use your official address without a department or lab ",
      "subdomain, e.g. ", tags$strong("HTanu@epfl.ch"), ", not HTanu@lab.epfl.ch."
    ),

    # Step A: email
    div(
      id = "login-step-email",
      class = "login-step",
      textInput("login_email", "Email address", placeholder = "HTanu@epfl.ch", width = "100%"),
      actionButton("login_send", "Send code", class = "btn-primary")
    ),

    # Step B: code (revealed by the server via the "mm-login-step" message)
    div(
      id = "login-step-code",
      class = "login-step",
      textInput("login_code", "6-digit code", placeholder = "123456", width = "100%"),
      actionButton("login_verify", "Verify", class = "btn-primary")
    ),

    uiOutput("login_status"),

    tags$hr(class = "about-hr-bottom"),
    tags$button(id = "login-back-btn", type = "button", class = "btn btn-link login-back",
                "← Back to the overview")
  )
}
