# =============================================================================
# RAW IMPORT - Parse the two MS Forms .xlsx exports in Data/ (LOCAL ONLY)
# =============================================================================
# Sourced by setup_and_data.R. The raw exports contain personal data (names,
# emails, LinkedIn) and must stay out of git.
#
#   - Practice partner export: "...Submit your project idea (<date>).xlsx"
#   - Researcher export:       "...Submit your project idea (For researchers)...xlsx"
# The newest file of each kind is used.
# =============================================================================

RAW_DATA_DIR <- Sys.getenv("MATCHMAKING_DATA_DIR", "Data")

# -----------------------------------------------------------------------------
# File discovery / reading
# -----------------------------------------------------------------------------

#' Newest .xlsx in RAW_DATA_DIR whose name matches (or not) "researcher"
#' @param researchers TRUE for the researcher export, FALSE for practice partners
#' @return Path to the file, or NA if none found
find_data_file <- function(researchers) {
  files <- list.files(RAW_DATA_DIR, pattern = "\\.xlsx$", full.names = TRUE)
  files <- files[!startsWith(basename(files), "~$")]  # Excel lock files
  is_res <- grepl("researcher", basename(files), ignore.case = TRUE)
  files <- files[is_res == researchers]
  if (length(files) == 0) return(NA_character_)
  files[which.max(file.mtime(files))]
}

#' Read an export; a locked file (open in Excel / syncing) gives a clear error
#' @param path Path to the .xlsx file
#' @return A tibble with whitespace-normalised column names
read_submissions <- function(path) {
  df <- tryCatch(
    read_excel(path, sheet = 1),
    error = function(e) {
      stop(sprintf(
        "Could not read '%s' (%s). If the file is open in Excel, close it and try again.",
        basename(path), conditionMessage(e)
      ), call. = FALSE)
    }
  )
  names(df) <- trimws(gsub("\\s+", " ", names(df)))
  df
}

#' Pick a column by header regex (headers are long and vary between forms)
#' @return The column as trimmed character (empty -> NA), or all-NA if absent
col_by_prefix <- function(df, pattern) {
  hit <- grep(pattern, names(df), ignore.case = TRUE)
  if (length(hit) == 0) return(rep(NA_character_, nrow(df)))
  out <- trimws(as.character(df[[hit[1]]]))
  out[out == ""] <- NA_character_
  out
}

#' Tidy a URL-ish answer so it can be used in an href
as_url <- function(x) {
  x <- trimws(x)
  bad <- is.na(x) | !grepl("\\.", x) | grepl("^(n/?a|none|-)$", x, ignore.case = TRUE)
  x[bad] <- NA_character_
  needs_scheme <- !is.na(x) & !grepl("^https?://", x, ignore.case = TRUE)
  x[needs_scheme] <- paste0("https://", x[needs_scheme])
  x
}

# -----------------------------------------------------------------------------
# Harmonisation (shared fields for both actors)
# -----------------------------------------------------------------------------

#' Fields common to both forms
#' @param df Raw export
#' @param role_pattern Header regex of the "role / value" question (differs)
common_fields <- function(df, role_pattern) {
  ukraine <- grepl("^yes", col_by_prefix(df, "^Are you interested in a project focused on Ukraine"),
                   ignore.case = TRUE)

  countries <- lapply(col_by_prefix(df, "^Select the focus countries"), split_multi)
  countries <- Map(function(cs, ukr) {
    if (ukr) cs <- unique(c(UKRAINE, cs))
    if (length(cs) == 0) cs <- NOT_SPECIFIED
    cs
  }, countries, ukraine)

  # One merged "big topic": Ukraine track topic, else the general topic
  topic <- dplyr::coalesce(
    col_by_prefix(df, "^Select a topic that closest reflects your focus area"),
    col_by_prefix(df, "^Select the topic that most closely reflects")
  )
  topic <- sub("\\s*\\*+$", "", topic)
  topic[is.na(topic)] <- NOT_SPECIFIED

  tibble(
    ukraine            = ukraine,
    countries          = countries,
    topic              = topic,
    title              = col_by_prefix(df, "^Title$"),
    summary            = col_by_prefix(df, "^Short summary"),
    keywords           = col_by_prefix(df, "^Top 3 ?- ?5 keywords"),
    partner_identified = sub(",.*$", "", col_by_prefix(df, "^Have you already identified")),
    partner_named      = col_by_prefix(df, "^If yes, kindly share"),
    rationale          = col_by_prefix(df, "^Please provide a clear rationale"),
    role               = col_by_prefix(df, role_pattern),
    submitted          = as.Date(suppressWarnings(as.POSIXct(col_by_prefix(df, "^Completion time"))))
  )
}

clean_partners <- function(df) {
  bind_cols(
    tibble(
      uid         = paste0("PP-", seq_len(nrow(df))),
      actor       = ACTOR_PP,
      name        = col_by_prefix(df, "^Name of organisation"),
      category    = col_by_prefix(df, "^Type of organisation"),
      institution = NA_character_,
      contact     = col_by_prefix(df, "^Full Name \\(Point of contact"),
      email       = col_by_prefix(df, "^Email address \\(Point of contact"),
      website     = as_url(col_by_prefix(df, "^Link to website")),
      linkedin    = as_url(col_by_prefix(df, "^LinkedIn"))
    ),
    common_fields(df, "^What role do you envision")
  )
}

clean_researchers <- function(df) {
  full_name <- col_by_prefix(df, "^Full name$")
  bind_cols(
    tibble(
      uid         = paste0("R-", seq_len(nrow(df))),
      actor       = ACTOR_RES,
      name        = full_name,
      category    = col_by_prefix(df, "^Position"),
      institution = vapply(col_by_prefix(df, "^ETH Domain institution"),
                           function(x) paste(split_multi(x), collapse = ", "), character(1),
                           USE.NAMES = FALSE),
      contact     = full_name,
      email       = col_by_prefix(df, "^Email address$"),
      website     = as_url(col_by_prefix(df, "^Chair/group webpage")),
      linkedin    = NA_character_
    ),
    common_fields(df, "^What value do you envision")
  )
}

#' Read both raw exports into one harmonised (still personal) tibble
#' @return list(submissions, as_of, files)
load_raw_submissions <- function() {
  pp_file  <- find_data_file(researchers = FALSE)
  res_file <- find_data_file(researchers = TRUE)
  if (is.na(pp_file) || is.na(res_file)) {
    stop(sprintf("Expected a practice-partner and a researcher .xlsx export in '%s/'.",
                 RAW_DATA_DIR), call. = FALSE)
  }
  list(
    submissions = bind_rows(
      clean_partners(read_submissions(pp_file)),
      clean_researchers(read_submissions(res_file))
    ),
    as_of = as.Date(max(file.mtime(c(pp_file, res_file)))),
    files = basename(c(pp_file, res_file))
  )
}
