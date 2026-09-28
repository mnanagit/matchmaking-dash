# Matchmaking Dashboard: Innovative Cities & Infrastructure Programme

R Shiny app for exploring practice-partner and researcher submissions. It has connected filters (Country → Big topic → Actors), a detail view per submission, a Country × Topic match grid and Excel export.

## Data and privacy
| Folder | Content | In git? |
|---|---|---|
| `Data/` | raw MS Forms exports (names, emails, LinkedIn) | **never** (gitignored, local only) |
| `data_public/` | anonymised copy: the only data the app reads | yes |

`scripts/anonymise_data.R` builds `data_public/submissions.csv` from `Data/`. It does three things:
- drops contact names, emails, LinkedIn profiles, researcher names/webpages and named partners
- scrubs emails, URLs, phone numbers and submitters' names from the free text
- stops without writing anything if any personal data is left over

The dashboard shows no contact details. The programme team connects people using the local originals.

### Updating the data
1. Put the new exports into `Data/`. The newest file of each kind is used; the file with "researcher" in its name is the researcher export. Close them in Excel first.
2. `Rscript scripts/anonymise_data.R`
3. Review `data_public/submissions.csv`, then commit and push. The hosted app redeploys automatically.

## Run locally
```bash
Rscript -e "shiny::runApp('.')"
```
In RStudio, open `app.R` → **Run App**.

## Deploy (Posit Connect Cloud)
The app is published from this GitHub repo. `manifest.json` pins the R packages. After adding a package, regenerate it with:
```r
rsconnect::writeManifest(appFiles = c("app.R", "ui_main.R", "server_main.R", "setup_and_data.R",
  list.files("modules", recursive = TRUE, full.names = TRUE),
  list.files("www", recursive = TRUE, full.names = TRUE),
  "data_public/submissions.csv"))
```
