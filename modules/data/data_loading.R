# =============================================================================
# DATA LOADING - Read the anonymised submissions (data_public/submissions.csv)
# =============================================================================
# The CSV is produced locally by scripts/anonymise_data.R from the raw exports
# in Data/ (which never leave this machine). It holds no contact details.
#
# Outputs (globals used by the UI and server):
#   SUBMISSIONS   one row per submission, both actors
#   ACTOR_LINKS   long lookup: one row per (submission, country) -> filters
#   ALL_COUNTRIES, ALL_TOPICS, DATA_AS_OF
# =============================================================================

#' Read the public CSV and restore types (countries back to a list-column)
#' @param path Path to the anonymised CSV
#' @return A tibble in the shape the app expects
read_public_submissions <- function(path = PUBLIC_DATA_FILE) {
  if (!file.exists(path)) {
    stop(sprintf("'%s' not found. Run scripts/anonymise_data.R to create it.", path),
         call. = FALSE)
  }
  df <- utils::read.csv(path, encoding = "UTF-8", fileEncoding = "UTF-8",
                        stringsAsFactors = FALSE, na.strings = "", check.names = FALSE)
  df <- tibble::as_tibble(df)
  df$ukraine   <- as.logical(df$ukraine)
  df$submitted <- as.Date(df$submitted)
  df$countries <- lapply(df$countries, split_multi)
  df$countries[lengths(df$countries) == 0] <- list(NOT_SPECIFIED)
  df
}

SUBMISSIONS <- read_public_submissions()
DATA_AS_OF  <- max(SUBMISSIONS$submitted, na.rm = TRUE)

# Display string for the (multi-valued) country field
SUBMISSIONS$country_label <- vapply(SUBMISSIONS$countries, paste, character(1), collapse = ", ")

# Long lookup driving all filters: one row per (submission, country)
ACTOR_LINKS <- SUBMISSIONS |>
  select(uid, actor, topic, countries) |>
  unnest_longer(countries, values_to = "country")

ALL_COUNTRIES <- sort_with_na_last(ACTOR_LINKS$country)
ALL_TOPICS    <- sort_with_na_last(ACTOR_LINKS$topic)
