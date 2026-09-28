# =============================================================================
# SERVER: DOWNLOADS - Excel export of the filtered tables
# =============================================================================

#' Readable export columns for one actor
export_sheet <- function(d, actor) {
  d <- d[d$actor == actor, ]
  out <- data.frame(
    Name               = d$name,
    Contact            = d$contact,
    Email              = d$email,
    Type               = d$category,
    Institution        = d$institution,
    Website            = d$website,
    LinkedIn           = d$linkedin,
    Countries          = d$country_label,
    Topic              = d$topic,
    `Project title`    = d$title,
    Summary            = d$summary,
    Keywords           = d$keywords,
    `Partner identified` = d$partner_identified,
    `Partner named`    = d$partner_named,
    Rationale          = d$rationale,
    `Role / value`     = d$role,
    Submitted          = d$submitted,
    check.names = FALSE
  )
  # Drop columns that never apply to this actor
  out[, colSums(!is.na(out)) > 0 | nrow(out) == 0, drop = FALSE]
}

output$download_xlsx <- downloadHandler(
  filename = function() sprintf("matchmaking_%s.xlsx", format(Sys.Date(), "%Y-%m-%d")),
  content = function(file) {
    subs <- filtered_subs()
    shown <- if (length(input$f_actor) == 0) ACTOR_TYPES else input$f_actor
    filters <- data.frame(
      Filter = c("Countries", "Big topics", "Actors", "Exported"),
      Value  = c(
        if (length(input$f_country)) paste(input$f_country, collapse = "; ") else "All",
        if (length(input$f_topic)) paste(input$f_topic, collapse = "; ") else "All",
        paste(shown, collapse = "; "),
        format(Sys.time(), "%Y-%m-%d %H:%M")
      )
    )
    sheets <- setNames(lapply(shown, function(a) export_sheet(subs, a)), shown)
    writexl::write_xlsx(c(sheets, list(Filters = filters)), file)
  }
)
