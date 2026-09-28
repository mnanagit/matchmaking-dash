# =============================================================================
# SERVER: TABLES - KPI cards, practice partner / researcher tables, details
# =============================================================================

# -----------------------------------------------------------------------------
# HTML cell helpers (all user text is escaped before it goes into a cell)
# -----------------------------------------------------------------------------
esc <- function(x) htmltools::htmlEscape(ifelse(is.na(x), "", x))

link_html <- function(text, url) {
  ifelse(is.na(url), esc(text),
         sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', esc(url), esc(text)))
}

#' Two-line clamp with the full text as tooltip
clamp_html <- function(x) sprintf('<span class="mm-clamp" title="%s">%s</span>', esc(x), esc(x))

topic_html <- function(x) sprintf('<span class="topic-chip">%s</span>', esc(x))

# -----------------------------------------------------------------------------
# KPI cards
# -----------------------------------------------------------------------------

#' Country-topic cells where both actors are present (the match opportunities)
match_cells <- function(links) {
  links |>
    distinct(country, topic, actor) |>
    count(country, topic) |>
    filter(n == length(ACTOR_TYPES), country != NOT_SPECIFIED, topic != NOT_SPECIFIED)
}

kpi_card <- function(value, label, icon_name, class = "") {
  div(
    class = paste("stat-card", class),
    tags$span(class = "stat-icon", icon(icon_name)),
    div(class = "stat-value", value),
    div(class = "stat-label", label)
  )
}

#' "matching / total" label for one actor
actor_share_label <- function(subs, actor) {
  sprintf("%d / %d", sum(subs$actor == actor), sum(SUBMISSIONS$actor == actor))
}

output$kpi_cards <- renderUI({
  subs  <- filtered_subs()
  links <- filtered_links()
  div(
    class = "stat-cards-row",
    kpi_card(actor_share_label(subs, ACTOR_PP), "Practice partners", ACTOR_ICONS[[ACTOR_PP]], "pp"),
    kpi_card(actor_share_label(subs, ACTOR_RES), "Researchers", ACTOR_ICONS[[ACTOR_RES]], "res"),
    kpi_card(length(setdiff(unique(links$country), NOT_SPECIFIED)), "Countries", "earth-europe", "neutral"),
    kpi_card(nrow(match_cells(links)), "Country × topic matches", "handshake", "match")
  )
})

output$tab_count_pp  <- renderText(sprintf("(%d)", sum(filtered_subs()$actor == ACTOR_PP)))
output$tab_count_res <- renderText(sprintf("(%d)", sum(filtered_subs()$actor == ACTOR_RES)))

# -----------------------------------------------------------------------------
# Tables
# -----------------------------------------------------------------------------
pp_data  <- reactive(filtered_subs()[filtered_subs()$actor == ACTOR_PP, ])
res_data <- reactive(filtered_subs()[filtered_subs()$actor == ACTOR_RES, ])

#' Render a submissions table with shared DT options
#' @param df Display data frame (HTML-escaped cells)
#' @param df Display data frame; its first column must be `uid` (hidden, read
#'   by www/matchmaking.js on row click to open the details modal)
#' @param wide_cols 0-based indices of the long-text columns
submissions_dt <- function(df, wide_cols) {
  datatable(
    df,
    escape = FALSE,
    rownames = FALSE,
    selection = "none",
    class = "compact hover mm-table",
    options = list(
      pageLength = 25,
      lengthMenu = c(10, 25, 50, 100),
      scrollX = TRUE,
      autoWidth = FALSE,
      dom = "<'dt-top'f>t<'dt-bottom'lip>",
      language = list(search = "", searchPlaceholder = "Search in table…",
                      emptyTable = "No submissions match the current filters."),
      columnDefs = list(
        list(visible = FALSE, searchable = FALSE, targets = 0),
        list(width = "260px", targets = wide_cols)
      )
    )
  )
}

output$pp_table <- renderDT({
  d <- pp_data()
  submissions_dt(
    data.frame(
      uid             = d$uid,
      Organisation    = link_html(d$name, d$website),
      Contact         = esc(d$contact),
      Type            = esc(d$category),
      Countries       = esc(d$country_label),
      Topic           = topic_html(d$topic),
      `Project title` = clamp_html(d$title),
      Keywords        = clamp_html(d$keywords),
      check.names = FALSE
    ),
    wide_cols = c(6, 7)
  )
})

output$res_table <- renderDT({
  d <- res_data()
  submissions_dt(
    data.frame(
      uid             = d$uid,
      Name            = link_html(d$name, d$website),
      Institution     = esc(d$institution),
      Position        = esc(d$category),
      Countries       = esc(d$country_label),
      Topic           = topic_html(d$topic),
      `Project title` = clamp_html(d$title),
      Keywords        = clamp_html(d$keywords),
      check.names = FALSE
    ),
    wide_cols = c(6, 7)
  )
})

# -----------------------------------------------------------------------------
# Details modal (row click)
# -----------------------------------------------------------------------------

#' Submissions of the other actor sharing the topic and at least one country
potential_matches <- function(sub) {
  other <- setdiff(ACTOR_TYPES, sub$actor)
  hits <- ACTOR_LINKS |>
    filter(actor == other, topic == sub$topic, topic != NOT_SPECIFIED,
           country %in% setdiff(sub$countries[[1]], NOT_SPECIFIED)) |>
    group_by(uid) |>
    summarise(shared = paste(sort(unique(country)), collapse = ", "), .groups = "drop")
  SUBMISSIONS |>
    inner_join(hits, by = "uid") |>
    select(uid, actor, name, title, shared)
}

detail_field <- function(label, value) {
  if (length(value) == 0 || all(is.na(value)) || identical(value, "")) value <- "—"
  div(class = "detail-field", tags$span(class = "detail-label", label), div(class = "detail-value", value))
}

detail_text <- function(label, text) {
  if (is.na(text)) return(NULL)
  div(class = "detail-section", tags$h6(label), tags$p(class = "long-text", text))
}

optional_link <- function(url, text) {
  if (is.na(url)) NULL else tags$a(href = url, target = "_blank", rel = "noopener", text)
}

mail_link <- function(email) {
  if (is.na(email)) NULL else tags$a(href = paste0("mailto:", email), email)
}

matches_list <- function(matches) {
  if (nrow(matches) == 0) return(tags$p(class = "muted", "None yet."))
  tags$ul(lapply(seq_len(nrow(matches)), function(i) {
    tags$li(tags$strong(matches$name[i]),
            tags$span(class = "muted", sprintf(" (%s) ", matches$shared[i])),
            tags$span(class = "muted mm-clamp", title = matches$title[i], matches$title[i]))
  }))
}

details_modal <- function(sub) {
  is_pp <- sub$actor == ACTOR_PP
  matches <- potential_matches(sub)

  modalDialog(
    title = div(
      class = "detail-title",
      tags$span(class = paste("actor-badge", if (is_pp) "pp" else "res"), icon(ACTOR_ICONS[[sub$actor]]),
                " ", if (is_pp) "Practice partner" else "Researcher"),
      tags$div(class = "detail-name", sub$name)
    ),
    size = "l",
    easyClose = TRUE,
    footer = modalButton("Close"),

    div(
      class = "detail-grid",
      detail_field(if (is_pp) "Organisation type" else "Position", sub$category),
      if (!is_pp) detail_field("Institution", sub$institution),
      detail_field("Focus countries", sub$country_label),
      detail_field("Big topic", sub$topic),
      if (is_pp) detail_field("Contact person", sub$contact),
      detail_field("Email", mail_link(sub$email)),
      if (is_pp) detail_field("LinkedIn", optional_link(sub$linkedin, "LinkedIn profile")),
      detail_field("Website", optional_link(sub$website,
                                            if (is_pp) "Organisation website" else "Chair / group webpage")),
      detail_field("Partner already identified", sub$partner_identified),
      if (!is.na(sub$partner_named)) detail_field("Partner named", sub$partner_named),
      detail_field("Submitted", format(sub$submitted, "%d %b %Y"))
    ),

    div(class = "detail-section", tags$h6("Project title"), tags$p(tags$strong(sub$title))),
    detail_text("Summary", sub$summary),
    detail_text("Keywords", sub$keywords),
    detail_text(if (is_pp) "Why an ETH Domain researcher is crucial" else "Why the practice partner is crucial",
                sub$rationale),
    detail_text(if (is_pp) "Envisioned role" else "Value brought to the collaboration", sub$role),

    div(
      class = "detail-section matches",
      tags$h6(icon("handshake"), sprintf(" Potential matches (%s in the same topic and country)",
                                         tolower(setdiff(ACTOR_TYPES, sub$actor)))),
      matches_list(matches)
    )
  )
}

# Row clicks arrive from www/matchmaking.js as input$row_click = uid
observeEvent(input$row_click, {
  sub <- SUBMISSIONS[SUBMISSIONS$uid == input$row_click, ]
  req(nrow(sub) == 1)
  showModal(details_modal(sub))
})
