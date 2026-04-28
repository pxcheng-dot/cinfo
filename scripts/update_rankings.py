#!/usr/bin/env python3
"""
update_rankings.py
──────────────────
Scrapes the latest QS, Times, USNews, and Shanghai rankings, then updates
universities.csv — keeping only the most recent MAX_YEARS years and rolling
off the oldest when a new year is added.

Usage
-----
    # Install dependencies once:
    pip install requests beautifulsoup4

    # Run (defaults to current calendar year, CSV at ../cinfo/universities.csv):
    python3 update_rankings.py

    # Specify a year or CSV path:
    python3 update_rankings.py --year 2027
    python3 update_rankings.py --year 2027 --csv /path/to/universities.csv

    # Update only specific systems:
    python3 update_rankings.py --systems qs times

Output
------
    • Prints a per-system summary (how many universities were updated)
    • Lists scraped university names that did NOT match any row in the CSV
      (so you can decide whether to add them manually)
    • Writes the updated CSV in-place
"""

import argparse
import csv
import io
import json
import re
import sys
import time
from datetime import date
from difflib import SequenceMatcher
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# ── Configuration ──────────────────────────────────────────────────────────────

MAX_YEARS = 5  # How many years of history to retain in the CSV

# Path relative to this script file
DEFAULT_CSV = Path(__file__).resolve().parent.parent / "cinfo" / "universities.csv"

SYSTEMS = ["rankQS", "rankTimes", "rankUSNews", "rankShanghai"]
FIXED_COLS = ["name", "country", "description", "tuitionUSD", "websiteURL"]

# ── Name aliases ───────────────────────────────────────────────────────────────
# Maps each CSV name to alternative spellings that ranking sites might use.
# Add entries here whenever a scraped name fails to match automatically.

NAME_ALIASES: dict[str, list[str]] = {
    "Massachusetts Institute of Technology":    ["MIT", "Massachusetts Institute of Technology (MIT)"],
    "University of California, Berkeley":       ["UC Berkeley", "University of California Berkeley"],
    "University of California, Los Angeles":    ["UCLA", "University of California Los Angeles"],
    "University of California, San Diego":      ["UC San Diego", "University of California San Diego"],
    "University of California, Davis":          ["UC Davis"],
    "University of California, Santa Barbara":  ["UC Santa Barbara"],
    "University of California, Irvine":         ["UC Irvine"],
    "University of Michigan–Ann Arbor":         ["University of Michigan", "University of Michigan Ann Arbor"],
    "University of Wisconsin–Madison":          ["University of Wisconsin-Madison", "University of Wisconsin Madison"],
    "University of Minnesota–Twin Cities":      ["University of Minnesota", "University of Minnesota Twin Cities"],
    "Washington University in St. Louis":       ["WashU", "Washington University in Saint Louis"],
    "HKUST":                                    ["Hong Kong University of Science and Technology", "HKUST - Hong Kong University of Science and Technology"],
    "KAIST":                                    ["Korea Advanced Institute of Science and Technology"],
    "POSTECH":                                  ["Pohang University of Science and Technology"],
    "LMU Munich":                               ["Ludwig Maximilian University of Munich", "Ludwig-Maximilians-Universität München"],
    "Technical University of Munich":           ["TU Munich", "TUM", "Technische Universität München"],
    "Technical University of Berlin":           ["TU Berlin", "Technische Universität Berlin"],
    "RWTH Aachen University":                   ["RWTH Aachen"],
    "Karlsruhe Institute of Technology":        ["KIT"],
    "Humboldt University of Berlin":            ["Humboldt-Universität zu Berlin"],
    "Free University of Berlin":                ["Freie Universität Berlin", "FU Berlin"],
    "Heidelberg University":                    ["Ruprecht-Karls-Universität Heidelberg"],
    "University of Hamburg":                    ["Universität Hamburg"],
    "ETH Zurich":                               ["ETH Zürich", "Swiss Federal Institute of Technology Zurich"],
    "EPFL":                                     ["École Polytechnique Fédérale de Lausanne", "Ecole Polytechnique Federale de Lausanne"],
    "PSL University":                           ["Université PSL", "PSL Research University", "PSL - Université Paris Sciences et Lettres"],
    "Université Paris-Saclay":                  ["Paris-Saclay University", "University of Paris-Saclay"],
    "Institut Polytechnique de Paris":          ["IP Paris", "Institut Polytechnique de Paris"],
    "Sorbonne University":                      ["Sorbonne Université"],
    "KU Leuven":                                ["Katholieke Universiteit Leuven"],
    "Delft University of Technology":           ["TU Delft"],
    "Karolinska Institute":                     ["Karolinska Institutet"],
    "University of Hong Kong":                  ["HKU", "The University of Hong Kong"],
    "Chinese University of Hong Kong":          ["CUHK", "The Chinese University of Hong Kong"],
    "National Taiwan University":               ["NTU"],
    "Sungkyunkwan University":                  ["SKKU"],
    "Seoul National University":                ["SNU"],
    "Tokyo Institute of Technology":            ["Tokyo Tech", "Institute of Science Tokyo"],
    "Tohoku University":                        ["Tohoku University, Japan"],
    "Hebrew University of Jerusalem":           ["The Hebrew University of Jerusalem"],
    "Technion – Israel Institute of Technology":["Technion - Israel Institute of Technology", "Technion"],
    "Xi'an Jiaotong University":                ["Xi an Jiaotong University", "Xian Jiaotong University"],
    "University of Science and Technology of China": ["USTC"],
    "Huazhong University of Science and Technology": ["HUST"],
    "South China University of Technology":     ["SCUT"],
}

# ── HTTP helpers ───────────────────────────────────────────────────────────────

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json, text/html, */*",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.google.com/",
}


def get(url: str, **kwargs) -> requests.Response | None:
    try:
        r = requests.get(url, headers=HEADERS, timeout=20, **kwargs)
        r.raise_for_status()
        return r
    except Exception as e:
        print(f"    ✗ {e}")
        return None


# ── Name matching ──────────────────────────────────────────────────────────────

def _norm(name: str) -> str:
    """Lowercase, strip punctuation/spaces for robust comparison."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


def best_match(scraped_name: str, csv_names: list[str]) -> tuple[str | None, float]:
    """
    Returns (csv_name, confidence) for the best matching row in csv_names.
    Returns (None, 0.0) if no match exceeds the 0.82 threshold.
    """
    sn = _norm(scraped_name)
    # Exact alias match first (fastest, most reliable)
    for csv_name in csv_names:
        for alias in [csv_name] + NAME_ALIASES.get(csv_name, []):
            if _norm(alias) == sn:
                return csv_name, 1.0
    # Fuzzy fallback
    best, best_score = None, 0.0
    for csv_name in csv_names:
        for alias in [csv_name] + NAME_ALIASES.get(csv_name, []):
            score = SequenceMatcher(None, sn, _norm(alias)).ratio()
            if score > best_score:
                best_score, best = score, csv_name
    return (best, best_score) if best_score >= 0.82 else (None, 0.0)


# ── Rank string parser ─────────────────────────────────────────────────────────

def parse_rank(rank_str) -> int | None:
    """
    Converts rank strings to integers:
      '1'       → 1
      '=5'      → 5   (tied)
      '401-410' → 401 (range → take lower bound)
      '401–450' → 401
    """
    if not rank_str:
        return None
    s = str(rank_str).strip().lstrip("=").split("-")[0].split("–")[0].replace(",", "")
    try:
        return int(s)
    except ValueError:
        return None


# ── Scrapers ───────────────────────────────────────────────────────────────────

def fetch_qs(year: int) -> dict[str, int]:
    """
    QS World University Rankings.
    Tries the known JSON endpoint; the node ID (nid) shifts each year.
    If the primary endpoint fails we attempt to scrape the rankings page.
    """
    print(f"  Fetching QS {year}…")

    # Known endpoint for QS 2026; nid may change for future years.
    # If this fails, edit the nid from the network tab of your browser on
    # https://www.topuniversities.com/world-university-rankings
    primary_url = (
        "https://www.topuniversities.com/rankings/endpoint"
        "?nid=3897671&page=0&items_per_page=500"
        "&tab=indicators&sort_by=rank&order_by=asc"
    )

    r = get(primary_url)
    if r:
        try:
            payload = r.json()
            nodes = (payload.get("score_nodes")
                     or payload.get("data")
                     or [])
            results = {}
            for node in nodes:
                name = (node.get("title") or node.get("name") or "").strip()
                rank = parse_rank(node.get("rank_display") or node.get("rank"))
                if name and rank and rank <= 600:
                    results[name] = rank
            if results:
                print(f"    → {len(results)} universities")
                return results
        except Exception as e:
            print(f"    JSON parse error: {e}")

    # Fallback: HTML scrape of the rankings page
    r = get(f"https://www.topuniversities.com/world-university-rankings/{year}")
    if r:
        soup = BeautifulSoup(r.text, "html.parser")
        results = {}
        for row in soup.select("table.ranking-table tbody tr, tr.odd, tr.even"):
            rank_el = row.select_one("td.rank, .rank-display")
            name_el = row.select_one("td.uni-name a, .uni-link")
            if rank_el and name_el:
                rank = parse_rank(rank_el.get_text(strip=True))
                name = name_el.get_text(strip=True)
                if name and rank and rank <= 600:
                    results[name] = rank
        if results:
            print(f"    → {len(results)} universities (HTML fallback)")
            return results

    print("    → Could not fetch QS data")
    return {}


def fetch_the(year: int) -> dict[str, int]:
    """
    Times Higher Education World University Rankings.
    Uses the JSON data endpoint that powers their rankings table.
    """
    print(f"  Fetching THE {year}…")
    results = {}
    page = 1

    while True:
        start = (page - 1) * 200
        url = (
            f"https://www.timeshighereducation.com/world-university-rankings"
            f"/{year}/world-ranking/data"
            f"?rankingDataType=overall&page={page}&length=200&start={start}"
        )
        r = get(url)
        if not r:
            break
        try:
            data = r.json()
            rows = data.get("data", [])
            if not rows:
                break
            for row in rows:
                name = (row.get("name") or row.get("university_name") or "").strip()
                rank = parse_rank(row.get("rank") or row.get("rank_order"))
                if name and rank and rank <= 600:
                    results[name] = rank
            if len(rows) < 200:
                break
            page += 1
            time.sleep(0.4)
        except Exception as e:
            print(f"    JSON parse error (page {page}): {e}")
            break

    if results:
        print(f"    → {len(results)} universities")
    else:
        print("    → Could not fetch THE data")
    return results


def fetch_arwu(year: int) -> dict[str, int]:
    """
    Shanghai (ARWU) Academic Ranking of World Universities.
    Parses the HTML table on shanghairanking.com.
    """
    print(f"  Fetching Shanghai/ARWU {year}…")

    # Try JSON API first (present on newer versions of the site)
    api_url = f"https://www.shanghairanking.com/api/pub/v1/arwu/rankingList?year={year}&start=1&rows=600"
    r = get(api_url)
    if r:
        try:
            data = r.json()
            items = data.get("data", {}).get("universities", data.get("universities", []))
            results = {}
            for item in items:
                name = (item.get("univNameEn") or item.get("name") or "").strip()
                rank = parse_rank(item.get("ranking") or item.get("rank"))
                if name and rank and rank <= 600:
                    results[name] = rank
            if results:
                print(f"    → {len(results)} universities (API)")
                return results
        except Exception:
            pass

    # HTML fallback
    r = get(f"https://www.shanghairanking.com/rankings/arwu/{year}")
    if r:
        soup = BeautifulSoup(r.text, "html.parser")
        results = {}
        for row in soup.select("table tbody tr"):
            cells = row.find_all("td")
            if len(cells) < 2:
                continue
            rank_text = cells[0].get_text(strip=True)
            name_tag = cells[1].find("a") or cells[1]
            name = name_tag.get_text(strip=True)
            rank = parse_rank(rank_text)
            if name and rank and rank <= 600:
                results[name] = rank
        if results:
            print(f"    → {len(results)} universities (HTML)")
            return results

    print("    → Could not fetch ARWU data")
    return {}


def fetch_usnews(year: int) -> dict[str, int]:
    """
    US News Best Global Universities Rankings.
    Tries their search/data endpoint, then falls back to page scraping.
    """
    print(f"  Fetching USNews {year}…")
    results = {}

    # JSON endpoint (works when logged out)
    for url in [
        "https://www.usnews.com/education/best-global-universities/search?format=json&numRecords=500",
        "https://www.usnews.com/education/best-global-universities/rankings?format=json&page=1",
    ]:
        r = get(url)
        if not r:
            continue
        try:
            data = r.json()
            items = (data.get("data", {}).get("items")
                     or data.get("items")
                     or data.get("results")
                     or [])
            for item in items:
                name = (item.get("name") or item.get("displayName") or "").strip()
                rank = parse_rank(
                    item.get("globalRank") or item.get("rankDisplay") or item.get("rank")
                )
                if name and rank and rank <= 600:
                    results[name] = rank
            if results:
                break
        except Exception:
            continue

    # HTML fallback — page-by-page scrape
    if not results:
        for p in range(1, 6):
            r = get(f"https://www.usnews.com/education/best-global-universities/rankings?page={p}")
            if not r:
                break
            soup = BeautifulSoup(r.text, "html.parser")
            for item in soup.select("li[class*='RankListItem'], article[class*='RankItem']"):
                rank_el = item.select_one("[class*='rank'], [class*='Rank']")
                name_el = item.select_one("h3, h2, [class*='name'], [class*='Name']")
                if rank_el and name_el:
                    rank = parse_rank(rank_el.get_text(strip=True))
                    name = name_el.get_text(strip=True)
                    if name and rank and rank <= 600:
                        results[name] = rank
            if not results:
                break
            time.sleep(0.4)

    if results:
        print(f"    → {len(results)} universities")
    else:
        print("    → Could not fetch USNews data")
    return results


# ── CSV update logic ───────────────────────────────────────────────────────────

def read_csv(path: Path) -> tuple[list[dict], list[str]]:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        return rows, list(reader.fieldnames or [])


def detect_years(fieldnames: list[str]) -> list[int]:
    """Returns detected ranking years, newest first."""
    years: set[int] = set()
    for col in fieldnames:
        parts = col.split("_")
        if len(parts) == 2 and parts[0] in SYSTEMS:
            try:
                years.add(int(parts[1]))
            except ValueError:
                pass
    return sorted(years, reverse=True)


def build_headers(years_to_keep: list[int]) -> list[str]:
    headers = list(FIXED_COLS)
    for sys in SYSTEMS:
        for yr in years_to_keep:
            headers.append(f"{sys}_{yr}")
    return headers


def update_csv(
    csv_path: Path,
    new_year: int,
    rankings_by_system: dict[str, dict[str, int]],
    max_years: int = MAX_YEARS,
) -> None:
    rows, fieldnames = read_csv(csv_path)
    existing_years = detect_years(fieldnames)

    # Determine which years to keep
    all_years = sorted(set(existing_years) | {new_year}, reverse=True)
    years_to_keep = all_years[:max_years]
    dropped = set(existing_years) - set(years_to_keep)

    if dropped:
        print(f"\n  Rolling off year(s): {sorted(dropped)}")

    new_headers = build_headers(years_to_keep)
    csv_names = [row["name"] for row in rows]

    system_map = {
        "rankQS":       rankings_by_system.get("qs",       {}),
        "rankTimes":    rankings_by_system.get("times",    {}),
        "rankUSNews":   rankings_by_system.get("usnews",   {}),
        "rankShanghai": rankings_by_system.get("shanghai", {}),
    }

    updated:   dict[str, int]        = {s: 0 for s in SYSTEMS}
    unmatched: dict[str, list[str]]  = {s: [] for s in SYSTEMS}

    for sys_key, scraped in system_map.items():
        if not scraped:
            continue
        col_name = f"{sys_key}_{new_year}"
        for scraped_name, rank in scraped.items():
            csv_name, score = best_match(scraped_name, csv_names)
            if csv_name:
                for row in rows:
                    if row["name"] == csv_name:
                        row[col_name] = str(rank)
                        updated[sys_key] += 1
                        break
            else:
                unmatched[sys_key].append(f"{scraped_name}  (rank {rank})")

    # Write updated CSV
    out = io.StringIO()
    writer = csv.DictWriter(
        out, fieldnames=new_headers,
        quoting=csv.QUOTE_ALL, extrasaction="ignore"
    )
    writer.writeheader()
    for row in rows:
        for col in new_headers:
            if col not in row:
                row[col] = ""
        writer.writerow(row)

    with open(csv_path, "w", encoding="utf-8", newline="") as f:
        f.write(out.getvalue())

    # ── Summary ────────────────────────────────────────────────────────────────
    print(f"\n{'─'*60}")
    print(f"✓  CSV written: {csv_path}")
    print(f"   Years retained : {years_to_keep}")
    print(f"   New year added : {new_year}")
    print()
    for sys_key, count in updated.items():
        scraped_total = len(system_map.get(sys_key, {}))
        status = f"{count}/{scraped_total}" if scraped_total else "skipped"
        print(f"   {sys_key:<18} {status} universities matched")
    for sys_key, names in unmatched.items():
        if names:
            print(f"\n   ⚠  {sys_key} — {len(names)} scraped names NOT in CSV "
                  f"(add manually if desired):")
            for n in names[:15]:
                print(f"      • {n}")
            if len(names) > 15:
                print(f"      … and {len(names) - 15} more")
    print(f"{'─'*60}\n")


# ── Entry point ────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Update universities.csv with the latest ranking data."
    )
    parser.add_argument(
        "--year", type=int, default=date.today().year,
        help="Ranking year to fetch (default: current calendar year)"
    )
    parser.add_argument(
        "--csv", type=Path, default=DEFAULT_CSV,
        help=f"Path to universities.csv (default: {DEFAULT_CSV})"
    )
    parser.add_argument(
        "--systems", nargs="+",
        choices=["qs", "times", "usnews", "shanghai", "all"],
        default=["all"],
        help="Which systems to update (default: all)"
    )
    args = parser.parse_args()

    systems = ({"qs", "times", "usnews", "shanghai"}
               if "all" in args.systems else set(args.systems))

    if not args.csv.exists():
        print(f"✗  CSV not found: {args.csv}")
        sys.exit(1)

    print(f"{'─'*60}")
    print(f"  Ranking year : {args.year}")
    print(f"  CSV          : {args.csv}")
    print(f"  Systems      : {', '.join(sorted(systems))}")
    print(f"{'─'*60}\n")

    rankings: dict[str, dict[str, int]] = {}
    if "qs"       in systems: rankings["qs"]       = fetch_qs(args.year)
    if "times"    in systems: rankings["times"]    = fetch_the(args.year)
    if "usnews"   in systems: rankings["usnews"]   = fetch_usnews(args.year)
    if "shanghai" in systems: rankings["shanghai"] = fetch_arwu(args.year)

    if not any(rankings.values()):
        print("\n✗  No data was fetched from any source — CSV not modified.")
        sys.exit(1)

    update_csv(args.csv, args.year, rankings)


if __name__ == "__main__":
    main()
