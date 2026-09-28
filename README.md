# Matchmaking Dashboard: Innovative Cities & Infrastructure Programme

R Shiny app for exploring practice-partner and researcher submissions. It has connected filters (Country → Big topic → Actors), a detail view per submission with contact details, a Country × Topic match grid and Excel export.

## Branches
| Branch | App | Data it reads | Deployed? |
|---|---|---|---|
| `main` | original app, with names, emails and LinkedIn | raw MS Forms exports in the local `Data/` folder | **no**: run locally by the programme team |
| `momo` | anonymised app, no contact details | `data_public/submissions.csv` (built by `scripts/anonymise_data.R`) | yes, on Posit Connect Cloud |

## Data and privacy
`Data/` holds real people's names, emails and LinkedIn profiles. It is gitignored and must **never** be committed. The same applies to `data_cache/` and to any Excel exports from the app.

### Updating the data
Put the new exports into `Data/`. The newest file of each kind is used, and the file with "researcher" in its name is the researcher export. If a file is open in Excel, the app falls back to the last cached copy in `data_cache/submissions.rds`.

## Run locally
```bash
Rscript -e "shiny::runApp('.')"
MATCHMAKING_DATA_DIR=<dir> Rscript -e "shiny::runApp('.')"   # different data folder
```
In RStudio, open `app.R` → **Run App**.
