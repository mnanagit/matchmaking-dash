# =============================================================================
# SHARED - Constants/helpers used by both the app (data_loading.R) and the
# local anonymisation script (raw_import.R, scripts/anonymise_data.R)
# =============================================================================

PUBLIC_DATA_FILE <- file.path("data_public", "submissions.csv")

NOT_SPECIFIED <- "Not specified"
UKRAINE       <- "Ukraine"

#' Split a ";"-separated multi-select answer into a clean character vector
split_multi <- function(x) {
  if (is.na(x)) return(character(0))
  parts <- trimws(strsplit(x, ";", fixed = TRUE)[[1]])
  unique(parts[parts != ""])
}

#' Sort alphabetically but keep "Not specified" last
sort_with_na_last <- function(x) {
  x <- sort(unique(x))
  c(setdiff(x, NOT_SPECIFIED), intersect(x, NOT_SPECIFIED))
}
