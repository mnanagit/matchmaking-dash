# =============================================================================
# SHARED - Constants/helpers used by raw_import.R and data_loading.R
# =============================================================================

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
