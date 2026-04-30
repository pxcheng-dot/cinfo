#!/usr/bin/env python3
from __future__ import annotations
"""
rebuild_rankings.py
────────────────────
Updates universities.csv ranking columns from authoritative local CSV files
(placed in scripts/kaggle/) or, as fallback, live web scraping.

Priority order (highest first):
  1. Per-year Kaggle files  → scripts/kaggle/{prefix}_{year}.csv
  2. Legacy merged file     → scripts/kaggle/{prefix}_rankings.csv
  3. Live scraping          → official / third-party websites

Per-year file naming (first 3 columns must be year, rank, university):
  QS:      qs_2022.csv … qs_2026.csv
  THE:     the_2022.csv … the_2026.csv
  ARWU:    arwu_2022.csv … arwu_2025.csv  (2026 not yet released)
  USNews:  usnews_2022.csv … usnews_2026.csv

Usage:
  pip install requests beautifulsoup4
  python3 scripts/rebuild_rankings.py                    # all systems, 2022-2026
  python3 scripts/rebuild_rankings.py --years 2025 2026
  python3 scripts/rebuild_rankings.py --systems qs the arwu
  python3 scripts/rebuild_rankings.py --dry-run          # print without writing
"""

import argparse
import csv
import io
import re
import sys
import time
from difflib import SequenceMatcher
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR  = Path(__file__).resolve().parent
REPO_ROOT   = SCRIPT_DIR.parent
CSV_PATH    = REPO_ROOT / "cinfo" / "universities.csv"
KAGGLE_DIR  = SCRIPT_DIR / "kaggle"

SYSTEMS     = ["rankQS", "rankTimes", "rankUSNews", "rankShanghai"]
FIXED_COLS  = ["name", "country", "description", "tuitionUSD", "websiteURL"]
MAX_RANK    = 600   # ignore scraped ranks above this

# ── HTTP ───────────────────────────────────────────────────────────────────────
SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept":          "application/json, text/html, */*",
    "Accept-Language": "en-US,en;q=0.9",
})

def get(url, **kw):
    try:
        r = SESSION.get(url, timeout=20, **kw)
        r.raise_for_status()
        return r
    except Exception as e:
        print(f"    ✗ {e}")
        return None

# ── Name normalisation & matching ──────────────────────────────────────────────
ALIASES = {
    "Massachusetts Institute of Technology": ["MIT"],
    "University of California, Berkeley":    ["UC Berkeley","Univ California Berkeley"],
    "University of California, Los Angeles": ["UCLA","UC Los Angeles"],
    "University of California, San Diego":   ["UC San Diego","UCSD"],
    "University of California, Davis":       ["UC Davis"],
    "University of California, Santa Barbara":["UC Santa Barbara","UCSB"],
    "University of California, Irvine":      ["UC Irvine","UCI"],
    "University of Michigan–Ann Arbor":      ["University of Michigan","Univ Michigan"],
    "University of Wisconsin–Madison":       ["University of Wisconsin-Madison","UW Madison"],
    "University of Minnesota–Twin Cities":   ["University of Minnesota"],
    "Washington University in St. Louis":    ["WashU","Washington Univ St Louis"],
    "HKUST":   ["Hong Kong University of Science and Technology",
                "HKUST - Hong Kong University of Science and Technology"],
    "KAIST":   ["Korea Advanced Institute of Science and Technology"],
    "POSTECH": ["Pohang University of Science and Technology"],
    "LMU Munich": ["Ludwig Maximilian University of Munich",
                   "Ludwig-Maximilians-Universitat Munchen",
                   "Ludwig-Maximilians-Universität München"],
    "Technical University of Munich":   ["TU Munich","TUM","Technische Universitat Munchen"],
    "Technical University of Berlin":   ["TU Berlin","Technische Universitat Berlin"],
    "RWTH Aachen University":           ["RWTH Aachen"],
    "Karlsruhe Institute of Technology":["KIT"],
    "Humboldt University of Berlin":    ["Humboldt-Universitat zu Berlin"],
    "Free University of Berlin":        ["Freie Universitat Berlin","FU Berlin"],
    "Heidelberg University":            ["Ruprecht-Karls-Universitat Heidelberg"],
    "ETH Zurich":    ["ETH Zurich","ETH Zürich","Swiss Federal Institute of Technology Zurich"],
    "EPFL":          ["Ecole Polytechnique Federale de Lausanne",
                      "École Polytechnique Fédérale de Lausanne"],
    "PSL University":["Universite PSL","PSL Research University",
                      "PSL - Universite Paris Sciences et Lettres"],
    "Université Paris-Saclay": ["Paris-Saclay University","University of Paris-Saclay"],
    "Institut Polytechnique de Paris": ["IP Paris"],
    "Sorbonne University":  ["Sorbonne Universite","Sorbonne Université"],
    "KU Leuven":            ["Katholieke Universiteit Leuven"],
    "Delft University of Technology":   ["TU Delft"],
    "Karolinska Institute":             ["Karolinska Institutet"],
    "University of Hong Kong":          ["HKU","The University of Hong Kong"],
    "Chinese University of Hong Kong":  ["CUHK","The Chinese University of Hong Kong"],
    "National Taiwan University":       ["NTU"],
    "Sungkyunkwan University":          ["SKKU"],
    "Seoul National University":        ["SNU"],
    "Tokyo Institute of Technology":    ["Tokyo Tech","Institute of Science Tokyo"],
    "Hebrew University of Jerusalem":   ["The Hebrew University of Jerusalem"],
    "Technion – Israel Institute of Technology":
        ["Technion - Israel Institute of Technology","Technion"],
    "Xi'an Jiaotong University":        ["Xian Jiaotong University"],
    "University of Science and Technology of China": ["USTC"],
    "Huazhong University of Science and Technology": ["HUST"],
    "Xi'an Jiaotong University":        ["Xi an Jiaotong University"],
}

def _norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())

def best_match(scraped, csv_names, threshold=0.82):
    sn = _norm(scraped)
    for cn in csv_names:
        for alias in [cn] + ALIASES.get(cn, []):
            if _norm(alias) == sn:
                return cn, 1.0
    best_cn, best_score = None, 0.0
    for cn in csv_names:
        for alias in [cn] + ALIASES.get(cn, []):
            s = SequenceMatcher(None, sn, _norm(alias)).ratio()
            if s > best_score:
                best_score, best_cn = s, cn
    return (best_cn, best_score) if best_score >= threshold else (None, 0.0)

def parse_rank(v):
    if v is None:
        return None
    s = str(v).strip().lstrip("=").split("-")[0].split("–")[0].replace(",","")
    try:
        n = int(float(s))
        return n if 1 <= n <= MAX_RANK else None
    except (ValueError, TypeError):
        return None

# ── QS scraper ─────────────────────────────────────────────────────────────────
def _qs_nid_for_year(year):
    """Fetch the rankings page and extract the Drupal nid used in the API call."""
    r = get(f"https://www.topuniversities.com/world-university-rankings/{year}")
    if not r:
        return None
    # The nid appears as data-nid="..." or nid=XXXX in inline JS / data attrs
    for pattern in [
        r'data-nid=["\'](\d+)["\']',
        r'"nid"\s*:\s*"?(\d+)"?',
        r'nid=(\d+)',
    ]:
        m = re.search(pattern, r.text)
        if m:
            return m.group(1)
    return None

def fetch_qs(year):
    print(f"    QS {year} – discovering nid …")
    nid = _qs_nid_for_year(year)
    if nid:
        print(f"      nid = {nid}")
    candidates = []
    if nid:
        candidates.append(
            f"https://www.topuniversities.com/rankings/endpoint"
            f"?nid={nid}&page=0&items_per_page=600&tab=indicators"
            f"&sort_by=rank&order_by=asc"
        )
    # Also try nid-less endpoints that some years support
    candidates += [
        f"https://www.topuniversities.com/rankings/endpoint"
        f"?nid=3897671&page=0&items_per_page=600&tab=indicators&sort_by=rank&order_by=asc",
        f"https://www.topuniversities.com/world-university-rankings/{year}/results",
    ]
    for url in candidates:
        r = get(url)
        if not r:
            continue
        try:
            data = r.json()
            nodes = data.get("score_nodes") or data.get("data") or []
            results = {}
            for node in nodes:
                name = (node.get("title") or node.get("name") or "").strip()
                rank = parse_rank(node.get("rank_display") or node.get("rank"))
                if name and rank:
                    results[name] = rank
            if results:
                return results
        except Exception:
            pass
    return {}

# ── THE scraper ────────────────────────────────────────────────────────────────
def fetch_the(year):
    results, page = {}, 1
    while True:
        url = (
            f"https://www.timeshighereducation.com/world-university-rankings"
            f"/{year}/world-ranking/data"
            f"?rankingDataType=overall&page={page}&length=200&start={(page-1)*200}"
        )
        r = get(url)
        if not r:
            break
        try:
            data  = r.json()
            rows  = data.get("data", [])
            if not rows:
                break
            for row in rows:
                name = (row.get("name") or row.get("university_name") or "").strip()
                rank = parse_rank(row.get("rank") or row.get("rank_order"))
                if name and rank:
                    results[name] = rank
            if len(rows) < 200:
                break
            page += 1
            time.sleep(0.3)
        except Exception as e:
            print(f"      page {page}: {e}")
            break
    return results

# ── ARWU scraper ───────────────────────────────────────────────────────────────
def fetch_arwu(year):
    # Try JSON API first
    r = get(
        f"https://www.shanghairanking.com/api/pub/v1/arwu/rankingList"
        f"?year={year}&start=1&rows=600"
    )
    if r:
        try:
            data  = r.json()
            items = (data.get("data", {}).get("universities")
                     or data.get("universities", []))
            results = {}
            for item in items:
                name = (item.get("univNameEn") or item.get("name") or "").strip()
                rank = parse_rank(item.get("ranking") or item.get("rank"))
                if name and rank:
                    results[name] = rank
            if results:
                return results
        except Exception:
            pass

    # HTML fallback
    r = get(f"https://www.shanghairanking.com/rankings/arwu/{year}")
    if not r:
        return {}
    soup    = BeautifulSoup(r.text, "html.parser")
    results = {}
    for row in soup.select("table tbody tr"):
        cells = row.find_all("td")
        if len(cells) < 2:
            continue
        name_tag = cells[1].find("a") or cells[1]
        name     = name_tag.get_text(strip=True)
        rank     = parse_rank(cells[0].get_text(strip=True))
        if name and rank:
            results[name] = rank
    return results

# ── USNews scraper ─────────────────────────────────────────────────────────────
def fetch_usnews(year):
    results = {}
    for url in [
        f"https://www.usnews.com/education/best-global-universities/search"
        f"?format=json&numRecords=500&year={year}",
        "https://www.usnews.com/education/best-global-universities/search"
        "?format=json&numRecords=500",
    ]:
        r = get(url)
        if not r:
            continue
        try:
            data  = r.json()
            items = (data.get("data", {}).get("items")
                     or data.get("items")
                     or data.get("results", []))
            for item in items:
                name = (item.get("name") or item.get("displayName") or "").strip()
                rank = parse_rank(
                    item.get("globalRank") or item.get("rankDisplay") or item.get("rank")
                )
                if name and rank:
                    results[name] = rank
            if results:
                break
        except Exception:
            continue

    if not results:
        for p in range(1, 8):
            r = get(
                f"https://www.usnews.com/education/best-global-universities/rankings"
                f"?page={p}"
            )
            if not r:
                break
            soup = BeautifulSoup(r.text, "html.parser")
            found = False
            for item in soup.select(
                "li[class*='RankListItem'], article[class*='RankItem'], "
                "div[class*='rankings-result']"
            ):
                rank_el = item.select_one("[class*='rank'],[class*='Rank']")
                name_el = item.select_one("h3,h2,[class*='name'],[class*='Name']")
                if rank_el and name_el:
                    rank = parse_rank(rank_el.get_text(strip=True))
                    name = name_el.get_text(strip=True)
                    if name and rank:
                        results[name] = rank
                        found = True
            if not found:
                break
            time.sleep(0.4)
    return results

# ── Kaggle / local CSV loader ──────────────────────────────────────────────────
# Per-year file prefix for each system (e.g. qs_2026.csv)
KAGGLE_PREFIXES = {
    "rankQS":       "qs",
    "rankTimes":    "the",
    "rankShanghai": "arwu",
    "rankUSNews":   "usnews",
}

# Legacy single-file fallback
KAGGLE_FILES = {
    "rankQS":       KAGGLE_DIR / "qs_rankings.csv",
    "rankTimes":    KAGGLE_DIR / "the_rankings.csv",
    "rankShanghai": KAGGLE_DIR / "arwu_rankings.csv",
    "rankUSNews":   KAGGLE_DIR / "usnews_rankings.csv",
}

def _load_kaggle_file(path, year):
    """Read name->rank from a CSV, filtering to rows where year column == year."""
    results = {}
    try:
        with open(path, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            hdrs = reader.fieldnames or []
            year_col = next((c for c in hdrs if c.lower().strip() == "year"), None)
            name_col = next((c for c in hdrs if c.lower().strip() in
                             ("university", "name", "institution", "school",
                              "university_name")), None)
            rank_col = next((c for c in hdrs if c.lower().strip() in
                             ("rank", "world_rank", "ranking")), None)
            if not (name_col and rank_col):
                print(f"      ⚠  {path.name}: cannot find name/rank columns "
                      f"(headers: {hdrs})")
                return {}
            for row in reader:
                if year_col and str(row.get(year_col, "")).strip() != str(year):
                    continue
                name = row.get(name_col, "").strip()
                rank = parse_rank(row.get(rank_col, ""))
                if name and rank:
                    results[name] = rank
    except Exception as e:
        print(f"      ✗ Kaggle load error ({path.name}): {e}")
    return results

def load_kaggle(system_key, year):
    """
    Load rankings from local CSV files (authoritative, preferred over scraping).

    Search order:
      1. Per-year file:  scripts/kaggle/{prefix}_{year}.csv
      2. Legacy merged:  scripts/kaggle/{prefix}_rankings.csv  (filtered by year)
    """
    # 1. Per-year file (e.g. qs_2026.csv) — authoritative, highest priority
    prefix = KAGGLE_PREFIXES.get(system_key, "")
    per_year = KAGGLE_DIR / f"{prefix}_{year}.csv"
    if per_year.exists():
        results = _load_kaggle_file(per_year, year)
        if results:
            print(f"      ✓ {len(results)} entries from {per_year.name}")
            return results

    # 2. Legacy merged file
    legacy = KAGGLE_FILES.get(system_key)
    if legacy and legacy.exists():
        results = _load_kaggle_file(legacy, year)
        if results:
            print(f"      ✓ {len(results)} entries from {legacy.name} (legacy)")
            return results

    return {}

# ── Scrape one system for one year ─────────────────────────────────────────────
def scrape(system_key, year):
    # Kaggle local files take precedence if present
    kdata = load_kaggle(system_key, year)
    if kdata:
        return kdata

    if system_key == "rankQS":       return fetch_qs(year)
    if system_key == "rankTimes":    return fetch_the(year)
    if system_key == "rankShanghai": return fetch_arwu(year)
    if system_key == "rankUSNews":   return fetch_usnews(year)
    return {}

# ── CSV rebuild ────────────────────────────────────────────────────────────────
def rebuild_csv(years, systems, dry_run=False):
    # Load existing CSV (keep name/country/description/tuitionUSD/websiteURL)
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader    = csv.DictReader(f)
        rows      = list(reader)
        old_hdrs  = list(reader.fieldnames or [])

    csv_names = [r["name"] for r in rows]
    years_desc = sorted(years, reverse=True)

    # Build new header: fixed cols + rankSYS_YEAR for ALL systems × years
    # (preserves columns for systems not being processed)
    new_headers = list(FIXED_COLS)
    for sys in SYSTEMS:
        for yr in years_desc:
            new_headers.append(f"{sys}_{yr}")
    # Also carry over any existing columns not in the standard set
    existing_extra = [h for h in old_hdrs if h not in new_headers]
    new_headers.extend(existing_extra)

    # Only clear ranking columns for the systems being processed —
    # columns for other systems (e.g. rankUSNews) are left untouched.
    for row in rows:
        for sys in [s for s in SYSTEMS if s in systems]:
            for yr in years_desc:
                row[f"{sys}_{yr}"] = ""

    # Scrape and fill
    total_updated = {sys: {yr: 0 for yr in years} for sys in SYSTEMS}
    all_unmatched  = {sys: {} for sys in SYSTEMS}   # sys -> {name: best_year_rank}

    for sys in [s for s in SYSTEMS if s in systems]:
        for year in sorted(years):
            print(f"\n  [{sys}] {year}")
            scraped = scrape(sys, year)
            if not scraped:
                print(f"    → no data retrieved")
                continue
            print(f"    → {len(scraped)} entries scraped")
            col = f"{sys}_{year}"
            for sname, rank in scraped.items():
                csv_name, score = best_match(sname, csv_names)
                if csv_name:
                    for row in rows:
                        if row["name"] == csv_name:
                            row[col] = str(rank)
                            total_updated[sys][year] += 1
                            break
                else:
                    # Keep for reporting; store lowest (best) rank seen
                    prev = all_unmatched[sys].get(sname)
                    if prev is None or rank < prev:
                        all_unmatched[sys][sname] = rank

    # ── Summary ────────────────────────────────────────────────────────────────
    print(f"\n{'═'*64}")
    print(f"  CSV: {CSV_PATH}")
    print(f"  Years: {sorted(years)}  Systems: {sorted(systems)}")
    print()
    for sys in [s for s in SYSTEMS if s in systems]:
        for year in sorted(years):
            n = total_updated[sys][year]
            print(f"  {sys}_{year}: {n} rows filled")
    print()
    for sys, names in all_unmatched.items():
        if names:
            print(f"  ⚠  {sys}: {len(names)} scraped universities NOT in CSV "
                  f"(consider adding manually):")
            for nm in sorted(names, key=lambda x: names[x])[:20]:
                print(f"     #{names[nm]:4d}  {nm}")
            extra = len(names) - 20
            if extra > 0:
                print(f"     … and {extra} more")
    print(f"{'═'*64}\n")

    if dry_run:
        print("  --dry-run: CSV not written.")
        return

    # Write
    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=new_headers,
                            quoting=csv.QUOTE_ALL, extrasaction="ignore")
    writer.writeheader()
    for row in rows:
        for h in new_headers:
            if h not in row:
                row[h] = ""
        writer.writerow(row)

    with open(CSV_PATH, "w", encoding="utf-8", newline="") as f:
        f.write(out.getvalue())
    print(f"  ✓  Written to {CSV_PATH}")

# ── Main ───────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Rebuild universities.csv from scraped actual rankings."
    )
    parser.add_argument(
        "--years", nargs="+", type=int,
        default=[2022, 2023, 2024, 2025, 2026],
        help="Years to scrape (default: 2022-2026)"
    )
    parser.add_argument(
        "--systems", nargs="+",
        choices=["qs","the","arwu","usnews","all"],
        default=["all"],
        help="Systems to scrape: qs the arwu usnews all"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print results without modifying the CSV"
    )
    args = parser.parse_args()

    sys_map = {"qs":"rankQS","the":"rankTimes","arwu":"rankShanghai","usnews":"rankUSNews"}
    if "all" in args.systems:
        systems = set(SYSTEMS)
    else:
        systems = {sys_map[s] for s in args.systems}

    print(f"{'═'*64}")
    print(f"  Rebuilding rankings — years: {sorted(args.years)}")
    print(f"  Systems : {sorted(systems)}")
    print(f"  Kaggle  : place CSVs in {KAGGLE_DIR} for offline data")
    print(f"{'═'*64}")

    rebuild_csv(set(args.years), systems, dry_run=args.dry_run)

if __name__ == "__main__":
    main()
