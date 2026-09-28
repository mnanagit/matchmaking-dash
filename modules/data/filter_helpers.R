# =============================================================================
# FILTER HELPERS - Pure functions behind the Country -> Topic -> Actor filters
# =============================================================================
# Kept free of Shiny so they can be tested directly (and reused by both the
# sidebar UI, for initial choices, and the server, for cascading updates).
# =============================================================================

#' Filter the long links table; an empty/NULL selection means "no restriction"
#' @param links ACTOR_LINKS-shaped tibble (uid, actor, topic, country)
#' @param countries,topics,actors Selected values (character or NULL)
#' @return The matching rows of `links`
apply_filters <- function(links, countries = NULL, topics = NULL, actors = NULL) {
  if (length(countries) > 0) links <- links[links$country %in% countries, ]
  if (length(topics) > 0)    links <- links[links$topic %in% topics, ]
  if (length(actors) > 0)    links <- links[links$actor %in% actors, ]
  links
}

#' Named choice vector "Value (n_pp · n_res)" = "Value", in `levels` order
#' @param links Links already restricted to the relevant subset
#' @param field "country" or "topic"
#' @param levels Values to offer (defaults to those present in `links`)
#' @return Named character vector for pickerInput choices
choice_labels <- function(links, field, levels = sort_with_na_last(links[[field]])) {
  counts <- links |>
    distinct(uid, actor, value = .data[[field]]) |>
    count(value, actor) |>
    pivot_wider(names_from = actor, values_from = n, values_fill = 0)
  if (length(levels) == 0) return(character(0))
  setNames(levels, sprintf("%s  (%d · %d)", levels,
                           count_by_level(counts, ACTOR_PP, levels),
                           count_by_level(counts, ACTOR_RES, levels)))
}

#' Per-level count for one actor from a pivoted count table (0 when absent)
#' @param counts Wide table with a `value` column and one column per actor
#' @param actor Actor column to read
#' @param levels Values to return counts for, in order
#' @return Integer vector aligned with `levels`
count_by_level <- function(counts, actor, levels) {
  # An actor absent from the subset has no column after pivoting
  n <- if (actor %in% names(counts)) counts[[actor]][match(levels, counts$value)] else NA
  n <- rep_len(as.integer(n), length(levels))
  n[is.na(n)] <- 0L
  n
}
