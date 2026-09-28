# ============================================================================
# MATCHMAKING DASHBOARD - MAIN APPLICATION
# Innovative Cities & Infrastructure Programme
# ============================================================================

library(shiny)
library(bslib)

source("ui_main.R")
source("server_main.R")

shinyApp(ui = ui, server = server)
