# =============================================================================
# SERVER MAIN - Main server function
# =============================================================================
# Modules are sourced with local = TRUE so they run inside the server function
# and share input/output/session and each other's reactives.
# =============================================================================

server <- function(input, output, session) {

  # Country -> Topic -> Actor filters; defines filtered_uids() / filtered_links()
  source("modules/server/filters.R", local = TRUE)

  # KPI cards + practice partner / researcher tables + details modal
  source("modules/server/tables.R", local = TRUE)

  # Country x Topic match overview grid
  source("modules/server/overview.R", local = TRUE)

  # Excel export of the filtered tables
  source("modules/server/downloads.R", local = TRUE)
}
