# =============================================================================
# ANONYMISE DATA - Data/ (raw, personal, local only) -> data_public/ (tracked)
# =============================================================================
# Run from the project root after dropping a new export into Data/:
#   Rscript scripts/anonymise_data.R
# Then review data_public/submissions.csv before committing it.
#
# Removed: contact names, emails, LinkedIn, researcher names, researcher
#          webpages, named "identified partner", submission timestamps.
# Scrubbed in free text (title, summary, keywords, rationale, role):
#          emails, URLs, phone numbers, and the submitters' own name tokens.
# Prints counts only (never row contents) - see .claude/rules/data-privacy.md.
# =============================================================================

suppressMessages({
  source("modules/data/libraries.R")
  source("modules/data/color_palettes.R")
  source("modules/data/shared.R")
  source("modules/data/raw_import.R")
})

REDACTED <- "[removed]"
# Test submissions made while setting up the form; never published.
# uid is the row position in the export, so the guard below checks that these
# rows still predate the first real submission before dropping them.
EXCLUDED_UIDS <- paste0("PP-", 1L:5L)
TEST_PERIOD_END <- as.Date("2026-07-23")
FREE_TEXT_COLS <- c("title", "summary", "keywords", "rationale", "role")

EMAIL_RE  <- "[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}"
URL_RE    <- paste0("(https?://|www\\.)[^[:space:]]+|",
                    "\\b[[:alnum:]-]+(\\.[[:alnum:]-]+)*\\.(com|org|net|ch|edu|gov|io|info)",
                    "(/[^[:space:]]*)?\\b")
PHONE_CANDIDATE_RE <- "[+(]?\\d[\\d ()./-]{7,}\\d"
MIN_PHONE_DIGITS   <- 9L
MIN_NAME_TOKEN     <- 3L
# Name parts that are also places/common words in the text ("Viet Nam", "long-term")
NAME_TOKEN_ALLOWLIST <- c("nam", "viet", "long", "mark", "hope", "may", "will", "grace",
                          "joy", "jordan", "georgia", "victoria", "lady", "van", "thi")
# Titles/roles/organisation words people type into the "contact name" field;
# they are not personal and would otherwise wipe out ordinary words.
GENERIC_TOKENS <- c("mr", "mrs", "ms", "miss", "dr", "prof", "professor", "phd", "eng", "arch",
                    "msc", "mba", "ceo", "cto", "coo", "cfo", "director", "manager", "head",
                    "lead", "officer", "founder", "president", "chair", "coordinator", "team",
                    "senior", "junior", "assistant", "associate", "deputy", "executive",
                    "project", "programme", "program", "department", "dept", "unit", "office",
                    "university", "institute", "institution", "research", "researcher",
                    "centre", "center", "foundation", "association", "company", "group",
                    "agency", "ministry", "city", "municipality", "council", "development",
                    "urban", "and", "the", "for", "of", "ltd", "llc", "gmbh", "ngo")

# -----------------------------------------------------------------------------
# Scrubbing helpers
# -----------------------------------------------------------------------------

#' Replace regex matches and count them
#' @return list(text, n)
replace_count <- function(text, pattern, perl = FALSE, ignore_case = TRUE) {
  hits <- gregexpr(pattern, text, perl = perl, ignore.case = ignore_case)
  n <- sum(vapply(hits, function(h) sum(h > 0, na.rm = TRUE), integer(1)))
  list(text = gsub(pattern, REDACTED, text, perl = perl, ignore.case = ignore_case), n = n)
}

#' Phone numbers: digit runs with >= MIN_PHONE_DIGITS digits (spares years, "2025-2030")
scrub_phones <- function(text) {
  m <- gregexpr(PHONE_CANDIDATE_RE, text, perl = TRUE)
  found <- regmatches(text, m)
  n <- 0L
  regmatches(text, m) <- lapply(found, function(v) {
    is_phone <- nchar(gsub("\\D", "", v)) >= MIN_PHONE_DIGITS
    n <<- n + sum(is_phone)
    ifelse(is_phone, REDACTED, v)
  })
  list(text = text, n = n)
}

#' Name tokens of all submitters, in Title-case and UPPER-case forms
#' @param names Contact / researcher name fields
#' @param vocabulary Words from fixed category columns (org types, topics,
#'   countries, institutions) - never personal, so never treated as names
name_tokens <- function(names, vocabulary = character(0)) {
  tokens <- unlist(strsplit(names[!is.na(names)], "[^[:alpha:]]+"))
  tokens <- unique(tokens[nchar(tokens) >= MIN_NAME_TOKEN])
  vocab <- tolower(unlist(strsplit(vocabulary[!is.na(vocabulary)], "[^[:alpha:]]+")))
  tokens <- tokens[!tolower(tokens) %in% c(NAME_TOKEN_ALLOWLIST, GENERIC_TOKENS, vocab)]
  title <- paste0(toupper(substr(tokens, 1, 1)), tolower(substring(tokens, 2)))
  unique(c(tokens, title, toupper(tokens)))
}

#' Regex matching any of `tokens` as a whole word (Unicode-aware)
tokens_regex <- function(tokens) {
  if (length(tokens) == 0) return("(?!)")  # matches nothing
  escaped <- gsub("([.|()\\\\^{}+$*?\\[\\]])", "\\\\\\1", tokens)
  paste0("(?<!\\p{L})(", paste(escaped, collapse = "|"), ")(?!\\p{L})")
}

#' Apply all scrubbing rules to one text vector; returns list(text, counts)
scrub_text <- function(text, name_re) {
  counts <- c(email = 0L, url = 0L, phone = 0L, name = 0L)
  r <- replace_count(text, EMAIL_RE);                     text <- r$text; counts["email"] <- r$n
  r <- replace_count(text, URL_RE);                       text <- r$text; counts["url"]   <- r$n
  r <- scrub_phones(text);                                text <- r$text; counts["phone"] <- r$n
  r <- replace_count(text, name_re, perl = TRUE, ignore_case = FALSE)
  text <- r$text; counts["name"] <- r$n
  list(text = text, counts = counts)
}

# -----------------------------------------------------------------------------
# Build the public table
# -----------------------------------------------------------------------------
raw <- load_raw_submissions()
subs <- raw$submissions
is_excluded <- subs$uid %in% EXCLUDED_UIDS
if (sum(is_excluded) != length(EXCLUDED_UIDS) ||
    !isTRUE(all(as.Date(subs$submitted[is_excluded]) < TEST_PERIOD_END))) {
  stop("EXCLUDED_UIDS no longer point at the test submissions (export layout changed); ",
       "update them in scripts/anonymise_data.R.")
}
subs <- subs[!is_excluded, ]
vocabulary <- c(subs$category, subs$topic, subs$institution, unlist(subs$countries),
                ACTOR_TYPES)
name_re <- tokens_regex(name_tokens(c(subs$contact, subs$name[subs$actor == ACTOR_RES]),
                                    vocabulary))

totals <- c(email = 0L, url = 0L, phone = 0L, name = 0L)
for (col in FREE_TEXT_COLS) {
  r <- scrub_text(subs[[col]], name_re)
  subs[[col]] <- r$text
  totals <- totals + r$counts
}

is_res <- subs$actor == ACTOR_RES
subs$name[is_res] <- ifelse(is.na(subs$institution[is_res]), "Researcher",
                            paste("Researcher ·", subs$institution[is_res]))
subs$website[is_res] <- NA_character_  # personal / chair pages
# A partner website containing a submitter's name is a personal page -> drop it
personal_site <- grepl(name_re, subs$website, perl = TRUE)
subs$website[personal_site] <- NA_character_

public <- subs |>
  mutate(countries = vapply(countries, paste, character(1), collapse = "; ")) |>
  select(uid, actor, name, category, institution, website, ukraine, countries, topic,
         title, summary, keywords, partner_identified, rationale, role, submitted)

# -----------------------------------------------------------------------------
# Residual checks (counts only)
# -----------------------------------------------------------------------------
all_text <- unlist(public[, vapply(public, is.character, logical(1))])
person_text <- unlist(public[c(FREE_TEXT_COLS, "website")])  # where names must not remain
residual <- c(
  emails      = sum(grepl(EMAIL_RE, all_text, ignore.case = TRUE)),
  linkedin    = sum(grepl("linkedin", all_text, ignore.case = TRUE)),
  name_tokens = sum(grepl(name_re, person_text, perl = TRUE))
)
# Organisation names are kept by design; report (not block) any that contain a
# submitter's name so they can be reviewed by hand.
org_with_name <- sum(grepl(name_re, public$name[public$actor == ACTOR_PP], perl = TRUE))
if (any(residual > 0)) {
  per_col <- vapply(c(FREE_TEXT_COLS, "website"),
                    function(cl) sum(grepl(name_re, public[[cl]], perl = TRUE)), integer(1))
  stop("Residual personal data found (", paste(names(residual), residual, sep = "=", collapse = ", "),
       "; name hits per column: ", paste(names(per_col), per_col, sep = "=", collapse = ", "),
       "). Nothing written.", call. = FALSE)
}

dir.create("data_public", showWarnings = FALSE)
utils::write.csv(public, PUBLIC_DATA_FILE, row.names = FALSE, na = "", fileEncoding = "UTF-8")

writeLines(c(
  "# data_public",
  "",
  "Anonymised copy of the Innovative Cities & Infrastructure Programme matchmaking",
  "submissions. This is the only data the dashboard reads and the only data in git.",
  "",
  sprintf("- Generated: %s by `scripts/anonymise_data.R`", format(Sys.Date())),
  sprintf("- Source exports dated: %s", format(raw$as_of)),
  sprintf("- Rows: %d practice partners, %d researchers",
          sum(public$actor == ACTOR_PP), sum(public$actor == ACTOR_RES)),
  "",
  "Removed: contact names, emails, LinkedIn profiles, researcher names and webpages,",
  "named identified partners, submission timestamps.",
  "Scrubbed from free text: email addresses, URLs, phone numbers and submitters' names",
  sprintf("(replaced by `%s`). Researchers are shown as \"Researcher · <institution>\".", REDACTED),
  "",
  "The raw exports stay in the local, gitignored `Data/` folder."
), file.path("data_public", "README.md"), useBytes = TRUE)

message(sprintf("Wrote %s: %d practice partners, %d researchers.", PUBLIC_DATA_FILE,
                sum(public$actor == ACTOR_PP), sum(public$actor == ACTOR_RES)))
message("Replacements in free text: ", paste(names(totals), totals, sep = "=", collapse = ", "))
message(sprintf("Personal websites dropped: %d", sum(personal_site)))
message("Residual checks passed (0 emails, 0 LinkedIn, 0 submitter names in texts/websites).")
if (org_with_name > 0) {
  message(sprintf(paste("Note: %d organisation name(s) contain a submitter's name (e.g. a firm",
                        "named after its founder). Kept by design - review them in the CSV."),
                  org_with_name))
}
