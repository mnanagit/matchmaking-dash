# =============================================================================
# SETUP AND DATA - Main data loader
# =============================================================================
# Sources all data modules in order. Called by ui_main.R before building the UI.
# Reads the raw exports in Data/ (personal data, local only - never in git).
# =============================================================================

source("modules/data/libraries.R")
source("modules/data/color_palettes.R")   # ACTOR_* constants used below
source("modules/data/shared.R")
source("modules/data/raw_import.R")
source("modules/data/data_loading.R")
source("modules/data/filter_helpers.R")
