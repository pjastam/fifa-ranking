# Runbook

Operational reference for three recurring tasks specific to this fork
([pjastam/fifa-ranking](https://github.com/pjastam/fifa-ranking) of
[Dato-Futbol/fifa-ranking](https://github.com/Dato-Futbol/fifa-ranking)).
The live app runs on [Posit Connect Cloud](https://connect.posit.cloud)
and auto-deploys from the `wc2026` branch. Public URL:
<https://pjastam-fifa-ranking.share.connect.posit.cloud>.

## 1. Adding a new FIFA ranking release (live updates during WC 2026)

When FIFA publishes a new Men's World Ranking, follow these steps to
extend `ranking_fifa_historical.csv`.

### a. Find the release's schedule ID and date

1. Open <https://inside.fifa.com/fifa-world-ranking/men> in Chrome.
2. Open DevTools (`Cmd+Opt+I`) → Console tab → paste:
   ```js
   JSON.parse(document.getElementById('__NEXT_DATA__').textContent)
       .props.pageProps.pageData.ranking.allAvailableDates.slice(0, 5);
   ```
3. The most recent release is the first entry. Copy its `id` and `date`.

The `id` follows one of two patterns:
- Legacy: `idXXXXX` (used through 2025-09-18)
- New: `FRS_Male_Football_YYYYMMDD` (from 2025-10-17 onwards); the
  encoded date refers to the *previous* release, not the publication
  date — use the `date` field, not the encoded ID date.

### b. Add the release and run the scraper

The scraper lives outside this repo at `~/Workspace/agents/tools/fetch-fifa-rankings.R`.

1. Open it and prepend a row to the `releases` tribble:
   ```r
   releases <- tribble(
       ~date,         ~id,
       "2026-XX-XX",  "FRS_Male_Football_YYYYMMDD",  # ← new line
       "2026-04-01",  "FRS_Male_Football_20260119",
       ...
   )
   ```
2. From this repo's root:
   ```bash
   Rscript ~/Workspace/agents/tools/fetch-fifa-rankings.R
   ```

The script is idempotent (re-runs replace existing rows for the same
date) and re-sorts the CSV strictly date-desc with `arrange(desc(date))`.
You can safely re-run it without producing duplicates or shuffling
within-date rank order.

### c. Verify and commit

```bash
head -5 ranking_fifa_historical.csv      # newest release at top
git add ranking_fifa_historical.csv
git commit -m "data: add YYYY-MM-DD release"
git push
```

Connect Cloud picks up the push automatically and redeploys within ~30
seconds. No `manifest.json` regeneration is needed for a data-only
change (only the CSV moved).

## 2. Submitting an upstream pull request

Some commits on this fork are generally useful and could go upstream.
Others are pjastam-specific and should stay local.

### Candidates for upstream PR

| SHA | Subject | Notes |
|---|---|---|
| `e3241cb` | add WC 2026 participants filter | Generic feature |
| `c7fd44e` | remove deprecated wrappers and invalid stat="density" arg | Bug/warning cleanup |
| `fb0817a` | backfill ranking data through April 2026 | Data refresh |

### Fork-specific commits — DO NOT upstream

| SHA | Subject | Why local |
|---|---|---|
| `1e1080c` | read CSV from local file instead of upstream's raw URL | Upstream expects a remote URL |
| `a5982f1` | default selection: WC 2026 first-round group with the Netherlands | Reflects Dutch-fan preference, not upstream defaults |

### Procedure

```bash
git checkout -b upstream-pr-wc2026 master
git cherry-pick e3241cb c7fd44e fb0817a
git push -u origin upstream-pr-wc2026
gh pr create --repo Dato-Futbol/fifa-ranking \
    --base master --head pjastam:upstream-pr-wc2026 \
    --title "WC 2026 filter, deprecation cleanup, and data through April 2026" \
    --body-file -  # then paste a short body
```

### Caveat — the data-backfill commit is large

`fb0817a` re-sorts the entire CSV and rewrites ~70k rows. Upstream may
prefer just the new releases appended in their existing order. If so:
drop `fb0817a` from the cherry-pick and create a new commit that only
appends the 11 new rows without touching pre-existing ordering. The
scraper's `arrange(desc(date))` makes this awkward — for an upstream-
friendly variant, run the script once, then manually move only the new
rows back to the end of the file before committing.

## 3. Maintaining the Connect Cloud deployment

The app deploys automatically on each push to `wc2026`. Manual deploys,
branch changes, or access-setting changes happen from the
[Connect Cloud dashboard](https://connect.posit.cloud). Live URL:
<https://pjastam-fifa-ranking.share.connect.posit.cloud>.

### When to regenerate manifest.json

`manifest.json` pins R and every CRAN package version that the remote
builder installs. Regenerate it whenever any of the following changes:

- A new `library(...)` call is added (or an existing one removed) in
  `global.R`, `ui.R`, or `server.R`.
- The local R version is upgraded (current pin: 4.6.0).
- A pinned package needs a different version (e.g. for a bug fix).

Data-only changes (CSV updates from §1) do not need a regenerate.

### Regenerate procedure

From the repo root:

```bash
Rscript -e 'rsconnect::writeManifest()'
git add manifest.json
git commit -m "refresh manifest.json (<reason>)"
git push
```

### Diagnosing a failed deploy

1. Open the content's logs in the Connect Cloud dashboard. The build
   log shows the `git fetch`, package install, and Shiny start phases.
2. Most failures fall into two buckets:
   - **Missing manifest** or **stale manifest** (a `library()` call
     references a package not in `packages`): regenerate per above.
   - **Package install failure on remote** (CRAN version mismatch, OS
     library missing, etc.): pin to a known-good local R + package set
     and regenerate; or downgrade the offending package locally and
     regenerate.
3. To roll back: in the dashboard, redeploy a previous commit. The
   `git push` history on `wc2026` shows all candidate SHAs.
