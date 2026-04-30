# Updating University Rankings

The `scripts/update_rankings.py` script scrapes the latest QS, Times, USNews,
and Shanghai rankings and updates `cinfo/universities.csv` automatically.
It keeps the most recent 5 years and drops the oldest when a new year is added.

## Setup (one-time)

```bash
cd /Users/SarePhil/Desktop/cinfo
pip install -r requirements.txt
```

## Usage

```bash
# Update all ranking systems for the current calendar year
python3 scripts/update_rankings.py

# Specify a year explicitly
python3 scripts/update_rankings.py --year 2027

# Update only specific systems
python3 scripts/update_rankings.py --year 2027 --systems qs shanghai

# Point to a different CSV file
python3 scripts/update_rankings.py --csv /path/to/universities.csv
```

## After updating

Commit and push `cinfo/universities.csv` to GitHub.
The app will silently download the new file within 24 hours via RemoteDataService.

```bash
cd /Users/SarePhil/Desktop/cinfo
git add cinfo/universities.csv
git commit -m "Update rankings 2026"
git push
```

## If a scraper breaks

Ranking sites occasionally change their HTML. If a system returns 0 results:
1. Open `scripts/update_rankings.py`
2. Find the relevant `fetch_qs()`, `fetch_the()`, `fetch_arwu()`, or `fetch_usnews()` function
3. Update the URL/selector to match the current site structure
4. Or fill in that year's column manually in `cinfo/universities.csv`

## CSV column format

Each ranking system has one column per year, newest first:

```
rankQS_2026, rankQS_2025, rankQS_2024, rankQS_2023, rankQS_2022
rankTimes_2026, ...
rankUSNews_2026, ...
rankShanghai_2026, ...
```

Leave a cell empty if a university has no rank in that system for that year.
