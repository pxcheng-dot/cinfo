# Kaggle Data Supplements

Authoritative ranking CSV files placed here are **always preferred over live scraping**.
The script `rebuild_rankings.py` checks for these files first; scraping only runs as a
fallback when no local file is found.

## File naming convention (per-year files — preferred)

Name each file `{prefix}_{year}.csv`. The **first three columns must be**:

| Column | Description |
|--------|-------------|
| `year` | 4-digit year (e.g. `2026`) |
| `rank` | Numeric rank (ties like `=3` are normalised automatically) |
| `university` | University name as it appears in the source |

Additional columns (scores, country, etc.) are ignored for ranking updates but
will be used later to build composite metrics.

### System prefixes

| System | Prefix | Example files |
|--------|--------|---------------|
| QS World University Rankings | `qs` | `qs_2022.csv` … `qs_2026.csv` |
| Times Higher Education | `the` | `the_2022.csv` … `the_2026.csv` |
| Shanghai / ARWU | `arwu` | `arwu_2022.csv` … `arwu_2025.csv` (2026 not yet released) |
| US News Best Global Universities | `usnews` | `usnews_2022.csv` … `usnews_2026.csv` |

### Currently available files

| File | Rows | Notes |
|------|------|-------|
| `qs_2022.csv` – `qs_2026.csv` | 999 – 1 502 | Full QS top-1 500 |
| `the_2022.csv` – `the_2024.csv` | 1 000 – 2 670 | Full THE top-2 000+ |
| `the_2025.csv` | 1 000 | THE top-1 000 (Kaggle subset) |
| `the_2026.csv` | 56 | Curated subset (Kaggle) |
| `arwu_2022.csv` – `arwu_2025.csv` | 999 | Full ARWU top-1 000 |

> **THE 2025 & 2026 authority update**: Rankings for these two years were
> re-scraped in Apr 2026 from [timeshighereducation.com](https://www.timeshighereducation.com/world-university-rankings/2025/world-ranking)
> (2025) and [the 2026 edition](https://www.timeshighereducation.com/world-university-rankings/latest/world-ranking)
> via the XuanXiao mirror (pages 1–5, top 250). Applied directly to
> `universities.csv` via `scripts/update_the_2025_2026.py`.
> 165 cells updated for 2025; 162 cells updated for 2026.

USNews rankings are managed separately via `scripts/update_usnews_*.py` which
reads from XuanXiao.org and writes directly to `universities.csv`.

THE 2025 & 2026 rankings are managed via `scripts/update_the_2025_2026.py`
(scraped from XuanXiao.org / timeshighereducation.com).

## Legacy merged-file fallback

The script also accepts a single merged file per system (all years combined):

| System | Legacy filename | Required columns |
|--------|-----------------|-----------------|
| QS | `qs_rankings.csv` | `year`, `university`, `rank` |
| THE | `the_rankings.csv` | `year`, `university`, `rank` |
| ARWU | `arwu_rankings.csv` | `year`, `university`, `rank` |
| US News | `usnews_rankings.csv` | `year`, `university`, `rank` |

Per-year files take precedence over the legacy merged file.

## Running the rebuild

```bash
# Update QS + THE + ARWU from Kaggle files (preserves USNews columns):
python3 scripts/rebuild_rankings.py --systems qs the arwu

# Update a specific year only:
python3 scripts/rebuild_rankings.py --systems qs the arwu --years 2026

# Preview without writing:
python3 scripts/rebuild_rankings.py --systems qs the arwu --dry-run

# Full rebuild including live scraping fallback for USNews:
python3 scripts/rebuild_rankings.py
```
