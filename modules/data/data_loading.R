# =============================================================================
# DATA LOADING - Read the raw MS Forms exports in Data/ (via raw_import.R)
# =============================================================================
# Contains personal contact data: this app runs locally only. A successful read
# is cached to data_cache/submissions.rds, which is used when a source .xlsx is
# locked (open in Excel / OneDrive syncing) or missing.
#
# Outputs (globals used by the UI and server):
#   SUBMISSIONS   one row per submission, both actors
#   ACTOR_LINKS   long lookup: one row per (submission, country) -> filters
#   ALL_COUNTRIES, ALL_TOPICS, DATA_AS_OF
# =============================================================================

DATA_CACHE_FILE <- file.path("data_cache", "submissions.rds")

#' Read the raw exports, falling back to the last cached copy
#' @param cache_file Path to the .rds cache
#' @return list(submissions, as_of)
load_submissions <- function(cache_file = DATA_CACHE_FILE) {
  raw <- tryCatch(load_raw_submissions(), error = function(e) e)
  if (!inherits(raw, "error")) {
    dir.create(dirname(cache_file), recursive = TRUE, showWarnings = FALSE)
    saveRDS(raw[c("submissions", "as_of")], cache_file)
    return(raw)
  }
  if (!file.exists(cache_file)) stop(conditionMessage(raw), call. = FALSE)
  message("Using cached data (", conditionMessage(raw), ")")
  readRDS(cache_file)
}

LOADED      <- load_submissions()
SUBMISSIONS <- LOADED$submissions
DATA_AS_OF  <- LOADED$as_of

# Display string for the (multi-valued) country field
SUBMISSIONS$country_label <- vapply(SUBMISSIONS$countries, paste, character(1), collapse = ", ")

# Long lookup driving all filters: one row per (submission, country)
ACTOR_LINKS <- SUBMISSIONS |>
  select(uid, actor, topic, countries) |>
  unnest_longer(countries, values_to = "country")

ALL_COUNTRIES <- sort_with_na_last(ACTOR_LINKS$country)
ALL_TOPICS    <- sort_with_na_last(ACTOR_LINKS$topic)
