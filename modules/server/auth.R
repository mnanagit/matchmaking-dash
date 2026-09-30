# =============================================================================
# SERVER: AUTH - ETH Domain email + one-time code login
# =============================================================================
# Defines (used by the other server modules):
#   authed()  TRUE once the user proved ownership of an ETH Domain address.
#             Every data output req()s it (directly or via filtered_links()),
#             so no submission data reaches the browser before login.
# Code state (cooldown, attempts) lives in the process-wide OTP_STORE of
# modules/data/auth_helpers.R, not in the session. The address is never logged.
# =============================================================================

auth <- reactiveValues(
  email   = NULL,  # set on successful login
  pending = NULL   # address the current code was sent to
)

authed <- reactive(!is.null(auth$email))

login_msg <- reactiveVal(NULL)

#' Status line under the login form
#' @param type "info" or "error"
set_login_msg <- function(type, ...) login_msg(list(type = type, text = paste0(...)))

output$login_status <- renderUI({
  msg <- login_msg()
  req(msg)
  div(class = paste("login-status", msg$type), role = "status", msg$text)
})

#' Validate the address, then generate, store and send a new code
request_code <- function(email) {
  if (!is_eth_domain_email(email)) {
    return(set_login_msg("error", "Please use an ETH Domain address ending in ",
                         paste0("@", ETH_DOMAINS, collapse = ", "),
                         " (no subdomains such as lab.epfl.ch)."))
  }
  if (otp_delivery_mode() == "none") {
    return(set_login_msg("error", "Login is not configured yet. Please contact the programme team."))
  }
  blocked <- otp_send_block(email)
  if (!is.null(blocked)) return(set_login_msg("error", blocked))

  code <- generate_otp()
  if (!send_otp_email(email, code)) {
    return(set_login_msg("error", "The code could not be sent. Please try again later."))
  }
  otp_issue(email, code)
  auth$pending <- email
  message("Login code sent")
  session$sendCustomMessage("mm-login-step", list(step = "code"))
  set_login_msg("info", "We sent a code to ", email, ". It is valid for ", OTP_TTL_MIN, " minutes.")
}

#' Check a submitted code for the address it was sent to
verify_code <- function(code) {
  if (is.null(auth$pending)) return(set_login_msg("error", "Please request a code first."))
  result <- otp_check(auth$pending, code)
  if (result == "ok") {
    auth$email   <- auth$pending
    auth$pending <- NULL
    login_msg(NULL)
    message("Login ok")
    return(session$sendCustomMessage("mm-auth", list(ok = TRUE)))
  }
  switch(result,
    none    = set_login_msg("error", "Please request a code first."),
    expired = set_login_msg("error", "This code has expired. Please request a new one."),
    locked  = set_login_msg("error", "Too many wrong codes. Please request a new one."),
    wrong   = set_login_msg("error", "Wrong code. ", otp_attempts_left(auth$pending),
                            " attempt(s) left.")
  )
}

observeEvent(input$login_send, request_code(normalise_email(input$login_email)))
observeEvent(input$login_verify, verify_code(input$login_code %||% ""))
