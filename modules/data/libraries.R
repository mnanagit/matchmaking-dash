# =============================================================================
# LIBRARIES - Required packages for the Matchmaking Dashboard
# =============================================================================

# --- Core Shiny & UI ---
library(shiny)
library(bslib)        # Bootstrap 5 theming, sidebar layout, navset
library(shinyWidgets) # pickerInput, checkboxGroupButtons

# --- Data ---
library(dplyr)
library(tidyr)
library(readxl)       # Read the MS Forms .xlsx exports
library(writexl)      # Excel download of filtered tables

# --- Tables ---
library(DT)

# --- Utilities ---
library(htmltools)
library(digest)       # cache-busting hashes for www/ assets
