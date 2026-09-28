# =============================================================================
# SERVER: OVERVIEW - Country x Topic match grid
# =============================================================================
# Cells show "practice partners · researchers" for the current filters.
# Clicks are sent by www/matchmaking.js as input$overview_pick
# ({country, topic}); the server answers with a modal listing both sides.
# =============================================================================

#' Counts per (country, topic) with one column per actor (0 when absent)
#' @param links Filtered ACTOR_LINKS
count_country_topic <- function(links) {
  counts <- links |>
    distinct(uid, actor, country, topic) |>
    count(country, topic, actor) |>
    pivot_wider(names_from = actor, values_from = n, values_fill = 0)
  for (a in ACTOR_TYPES) if (!a %in% names(counts)) counts[[a]] <- 0L
  counts
}

#' One grid cell; row `i` of `counts`, or an empty cell when `i` is NA
overview_cell <- function(counts, i) {
  if (is.na(i)) return(tags$td(class = "mm-cell empty"))
  country <- counts$country[i]
  topic   <- counts$topic[i]
  n_pp    <- counts[[ACTOR_PP]][i]
  n_res   <- counts[[ACTOR_RES]][i]
  state <- if (n_pp > 0 && n_res > 0) "both" else if (n_pp > 0) "pp" else "res"
  tags$td(
    class = paste("mm-cell", state),
    `data-country` = country, `data-topic` = topic,
    title = sprintf("%s · %s: %d practice partner(s), %d researcher(s)",
                    country, topic, n_pp, n_res),
    tags$span(class = "n-pp", n_pp), tags$span(class = "sep", "·"),
    tags$span(class = "n-res", n_res)
  )
}

#' One table row (country) of the grid
overview_row <- function(counts, country, topics) {
  idx <- match(paste(country, topics, sep = "\r"), paste(counts$country, counts$topic, sep = "\r"))
  tags$tr(
    tags$th(class = "country-head", country),
    lapply(idx, function(i) overview_cell(counts, i))
  )
}

build_overview_table <- function(counts) {
  topics <- sort_with_na_last(counts$topic)
  div(
    class = "overview-scroll",
    tags$table(
      class = "overview-table",
      tags$thead(tags$tr(
        tags$th(class = "corner", "Country \\ Topic"),
        lapply(topics, function(t) tags$th(class = "topic-head", t))
      )),
      tags$tbody(lapply(sort_with_na_last(counts$country), function(cn) {
        overview_row(counts, cn, topics)
      }))
    )
  )
}

output$overview_grid <- renderUI({
  counts <- count_country_topic(filtered_links())
  if (nrow(counts) == 0) {
    return(div(class = "empty-state", icon("filter-circle-xmark"),
               tags$p("No submissions match the current filters.")))
  }
  build_overview_table(counts)
})

# -----------------------------------------------------------------------------
# Cell drill-down
# -----------------------------------------------------------------------------

#' One side (actor) of the drill-down modal
pick_side <- function(subs, actor) {
  s <- subs[subs$actor == actor, ]
  items <- if (nrow(s) == 0) tags$p(class = "muted", "None") else
    tags$ul(lapply(seq_len(nrow(s)), function(i) {
      tags$li(tags$strong(s$name[i]),
              tags$span(class = "muted mm-clamp", title = s$title[i], s$title[i]))
    }))
  div(
    class = paste("pick-side", if (actor == ACTOR_PP) "pp" else "res"),
    tags$h6(icon(ACTOR_ICONS[[actor]]), sprintf(" %s (%d)", actor, nrow(s))),
    items
  )
}

last_pick <- reactiveVal(NULL)

observeEvent(input$overview_pick, {
  pick <- input$overview_pick
  req(pick$country, pick$topic)

  in_cell <- filtered_links()
  in_cell <- in_cell[in_cell$country == pick$country & in_cell$topic == pick$topic, ]
  subs <- SUBMISSIONS[SUBMISSIONS$uid %in% in_cell$uid, ]

  last_pick(pick)
  showModal(modalDialog(
    title = sprintf("%s · %s", pick$country, pick$topic),
    size = "l",
    easyClose = TRUE,
    div(class = "pick-grid", pick_side(subs, ACTOR_PP), pick_side(subs, ACTOR_RES)),
    footer = tagList(
      actionButton("apply_pick", tagList(icon("filter"), " Filter tables to this pair"),
                   class = "btn-primary"),
      modalButton("Close")
    )
  ))
})

observeEvent(input$apply_pick, {
  pick <- last_pick()
  req(pick)
  removeModal()
  apply_pair(pick$country, pick$topic)
  nav_select("main_tabs", if (length(input$f_actor) == 1) input$f_actor else ACTOR_PP)
})
