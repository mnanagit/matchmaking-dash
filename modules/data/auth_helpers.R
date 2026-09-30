# =============================================================================
# AUTH HELPERS - ETH Domain email + one-time code login (pure, testable)
# =============================================================================
# The dashboard is only open to ETH Domain addresses. Ownership of the address
# is proven by a 6-digit code sent by email (modules/server/auth.R).
#
# Mail is sent with curl::send_mail() using these environment variables
# (Posit Connect Cloud secrets, or a local, gitignored .Renviron):
#   SMTP_SERVER    e.g. smtp://mail.ethz.ch:587
#   SMTP_USER      SMTP login
#   SMTP_PASSWORD  SMTP password
#   SMTP_FROM      sender address
# Local testing without SMTP: MATCHMAKING_DEV_OTP=1 writes the code to the
# R console instead of sending it. Never set this on the deployed app.
# =============================================================================

ETH_DOMAINS <- c("ethz.ch", "epfl.ch", "psi.ch", "wsl.ch", "empa.ch", "eawag.ch")

OTP_TTL_MIN           <- 10L  # code validity
OTP_MAX_ATTEMPTS      <- 5L   # wrong codes before a new code is required
OTP_RESEND_COOLDOWN_S <- 60L  # minimum gap between two codes
OTP_MAX_SENDS_PER_HOUR <- 5L  # codes per address per hour

# Code state per address, shared by all sessions of this R process, so a new
# tab cannot reset the cooldown or the attempt counter. Keyed by a hash of the
# normalised address. Record: code_hash, expires, attempts, sent_at (POSIXct).
OTP_STORE <- new.env(parent = emptyenv())

#' Trim and lower-case an email address (NULL/NA become "")
normalise_email <- function(x) {
  if (length(x) == 0 || is.na(x[1])) return("")
  tolower(trimws(x[1]))
}

#' TRUE when `x` is a well-formed address on exactly one of ETH_DOMAINS
#' (subdomains such as alumni.ethz.ch are not accepted)
is_eth_domain_email <- function(x) {
  x <- normalise_email(x)
  if (!grepl("^[a-z0-9._%+'-]+@[a-z0-9.-]+$", x)) return(FALSE)
  sub("^.*@", "", x) %in% ETH_DOMAINS
}

#' Random 6-digit code as a string (cryptographic RNG; modulo bias is negligible)
generate_otp <- function() {
  n <- sum(as.numeric(openssl::rand_bytes(4)) * 256^(0:3))
  sprintf("%06d", as.integer(n %% 1e6))
}

#' Hash of a code; only the hash is kept in memory
hash_otp <- function(code) digest::digest(trimws(code), algo = "sha256", serialize = FALSE)

otp_key <- function(email) digest::digest(email, algo = "sha256", serialize = FALSE)

#' Stored record for an address (empty record when none)
otp_get <- function(email) {
  rec <- OTP_STORE[[otp_key(email)]]
  if (!is.null(rec)) return(rec)
  list(code_hash = NULL, expires = NULL, attempts = 0L, sent_at = Sys.time()[0])
}

otp_put <- function(email, rec) assign(otp_key(email), rec, envir = OTP_STORE)

#' Why a new code may not be sent now (NULL when allowed)
#' @return NULL or a user-facing message
otp_send_block <- function(email, now = Sys.time()) {
  sent <- otp_get(email)$sent_at
  recent <- sent[as.numeric(difftime(now, sent, units = "secs")) < 3600]
  if (length(recent) >= OTP_MAX_SENDS_PER_HOUR) {
    return("Too many codes requested for this address. Please try again in an hour.")
  }
  wait <- if (length(recent)) OTP_RESEND_COOLDOWN_S -
    as.numeric(difftime(now, max(recent), units = "secs")) else 0
  if (wait > 0) return(sprintf("Please wait %d s before requesting a new code.", ceiling(wait)))
  NULL
}

#' Record a freshly sent code (replaces any earlier one)
otp_issue <- function(email, code, now = Sys.time()) {
  rec <- otp_get(email)
  rec$sent_at   <- c(rec$sent_at[as.numeric(difftime(now, rec$sent_at, units = "secs")) < 3600], now)
  rec$code_hash <- hash_otp(code)
  rec$expires   <- now + OTP_TTL_MIN * 60
  rec$attempts  <- 0L
  otp_put(email, rec)
}

#' Check a code for an address; the code is consumed on success, expiry or lockout
#' @return "ok", "none", "expired", "wrong" or "locked"
otp_check <- function(email, code, now = Sys.time()) {
  rec <- otp_get(email)
  if (is.null(rec$code_hash)) return("none")
  result <- if (now > rec$expires) "expired" else
    if (identical(hash_otp(code), rec$code_hash)) "ok" else "wrong"
  if (result == "wrong") {
    rec$attempts <- rec$attempts + 1L
    if (rec$attempts >= OTP_MAX_ATTEMPTS) result <- "locked"
  }
  if (result != "wrong") rec$code_hash <- NULL
  otp_put(email, rec)
  result
}

#' Attempts left for the current code of an address
otp_attempts_left <- function(email) OTP_MAX_ATTEMPTS - otp_get(email)$attempts

#' Which delivery channel is available: "smtp", "dev" (console) or "none"
otp_delivery_mode <- function() {
  if (nzchar(Sys.getenv("SMTP_SERVER"))) return("smtp")
  if (identical(Sys.getenv("MATCHMAKING_DEV_OTP"), "1")) return("dev")
  "none"
}

#' RFC 5322 message carrying the code
build_otp_email <- function(to, code, from = Sys.getenv("SMTP_FROM")) {
  paste0(
    "From: ", from, "\r\n",
    "To: ", to, "\r\n",
    "Subject: Your Matchmaking Dashboard login code\r\n",
    "Content-Type: text/plain; charset=utf-8\r\n",
    "\r\n",
    "Your login code for the Innovative Cities & Infrastructure Programme ",
    "Matchmaking Dashboard is:\r\n\r\n    ", code, "\r\n\r\n",
    "It is valid for ", OTP_TTL_MIN, " minutes.\r\n\r\n",
    "If you didn't request this, please ignore this email. ",
    "Your account remains secure and no changes have been made.\r\n"
  )
}

#' Deliver a code; returns TRUE on success, FALSE otherwise
send_otp_email <- function(to, code) {
  mode <- otp_delivery_mode()
  if (mode == "dev") {
    message("[dev] login code: ", code)
    return(TRUE)
  }
  if (mode == "none") return(FALSE)
  tryCatch({
    curl::send_mail(
      mail_from   = Sys.getenv("SMTP_FROM"),
      mail_rcpt   = to,
      message     = build_otp_email(to, code),
      smtp_server = Sys.getenv("SMTP_SERVER"),
      username    = Sys.getenv("SMTP_USER"),
      password    = Sys.getenv("SMTP_PASSWORD"),
      use_ssl     = "force",
      verbose     = FALSE
    )
    TRUE
  }, error = function(e) {
    # SMTP errors can echo the recipient: mask any address before logging
    message("Login code email failed: ",
            gsub("[^[:space:]<>]+@[^[:space:]<>]+", "<address>", conditionMessage(e)))
    FALSE
  })
}
