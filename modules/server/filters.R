# =============================================================================
# SERVER: FILTERS - Country -> Big topic -> Actors
# =============================================================================
# Defines (used by the other server modules):
#   filtered_links()  ACTOR_LINKS rows matching all three filters
#   filtered_subs()   SUBMISSIONS rows with at least one matching link
#   apply_pair(country, topic)  set both filters at once (overview drill-down)
# =============================================================================

filtered_links <- reactive({
  apply_filters(ACTOR_LINKS, input$f_country, input$f_topic, input$f_actor)
})

filtered_subs <- reactive({
  SUBMISSIONS[SUBMISSIONS$uid %in% filtered_links()$uid, ]
})

# -----------------------------------------------------------------------------
# Cascade: topic choices (and their counts) follow the selected countries.
# Selected topics that still exist are kept; `pending_topic` carries a topic
# set programmatically together with a country change (see apply_pair()).
# -----------------------------------------------------------------------------
pending_topic <- reactiveVal(NULL)

observeEvent(input$f_country, ignoreNULL = FALSE, ignoreInit = TRUE, {
  in_countries <- apply_filters(ACTOR_LINKS, countries = input$f_country)
  available <- sort_with_na_last(in_countries$topic)

  wanted <- if (!is.null(pending_topic())) pending_topic() else input$f_topic
  pending_topic(NULL)

  updatePickerInput(
    session, "f_topic",
    choices  = choice_labels(in_countries, "topic", available),
    selected = intersect(wanted, available)
  )
})

#' Set Country and Topic filters to a single pair (from the match overview)
apply_pair <- function(country, topic) {
  if (identical(input$f_country, country)) {
    updatePickerInput(session, "f_topic", selected = topic)
  } else {
    pending_topic(topic)
    updatePickerInput(session, "f_country", selected = country)
  }
}

# -----------------------------------------------------------------------------
# Reset
# -----------------------------------------------------------------------------
observeEvent(input$reset_filters, {
  # Only queue the topic reset when the country change will trigger the cascade
  if (length(input$f_country) > 0) pending_topic(character(0))
  updatePickerInput(session, "f_country", selected = character(0))
  updatePickerInput(session, "f_topic", selected = character(0))
  updateCheckboxGroupButtons(session, "f_actor", selected = ACTOR_TYPES)
})

# -----------------------------------------------------------------------------
# Actor filter shows/hides the matching table tab
# -----------------------------------------------------------------------------
observeEvent(input$f_actor, ignoreNULL = FALSE, {
  shown <- if (length(input$f_actor) == 0) ACTOR_TYPES else input$f_actor
  for (a in ACTOR_TYPES) {
    if (a %in% shown) nav_show("main_tabs", a) else nav_hide("main_tabs", a)
  }
  if (isTRUE(input$main_tabs %in% setdiff(ACTOR_TYPES, shown))) {
    nav_select("main_tabs", shown[1])
  }
})

# -----------------------------------------------------------------------------
# Result summary under the filters
# -----------------------------------------------------------------------------
output$filter_summary <- renderUI({
  subs <- filtered_subs()
  n_pp  <- sum(subs$actor == ACTOR_PP)
  n_res <- sum(subs$actor == ACTOR_RES)
  div(
    class = "filter-summary-text",
    tags$span(class = "dot pp"), tags$strong(n_pp), " practice partners",
    tags$br(),
    tags$span(class = "dot res"), tags$strong(n_res), " researchers",
    tags$span(class = "muted", " match the filters")
  )
})
