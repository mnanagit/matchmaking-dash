# data_public

Anonymised copy of the Innovative Cities & Infrastructure Programme matchmaking
submissions. This is the only data the dashboard reads and the only data in git.

- Generated: 2026-09-28 by `scripts/anonymise_data.R`
- Source exports dated: 2026-09-25
- Rows: 60 practice partners, 4 researchers

Removed: contact names, emails, LinkedIn profiles, researcher names and webpages,
named identified partners, submission timestamps.
Scrubbed from free text: email addresses, URLs, phone numbers and submitters' names
(replaced by `[removed]`). Researchers are shown as "Researcher · <institution>".

The raw exports stay in the local, gitignored `Data/` folder.
