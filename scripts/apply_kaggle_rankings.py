#!/usr/bin/env python3
"""
apply_kaggle_rankings.py
────────────────────────
Reads the per-year Kaggle CSV files in scripts/kaggle/ and writes QS, THE, and
ARWU ranking columns into universities.csv.  USNews columns are left untouched.

No third-party libraries required — stdlib only.

Usage:
  python3 scripts/apply_kaggle_rankings.py
  python3 scripts/apply_kaggle_rankings.py --systems qs the arwu --years 2026
  python3 scripts/apply_kaggle_rankings.py --dry-run
"""
from __future__ import annotations
import argparse, csv, io, re, sys
from difflib import SequenceMatcher
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT   = SCRIPT_DIR.parent
CSV_PATH    = REPO_ROOT / "cinfo" / "universities.csv"
KAGGLE_DIR  = SCRIPT_DIR / "kaggle"

SYSTEM_PREFIX = {          # system_key  ->  kaggle file prefix
    "rankQS":       "qs",
    "rankTimes":    "the",
    "rankShanghai": "arwu",
    "rankUSNews":   "usnews",
}
FIXED_COLS  = ["name", "country", "description", "tuitionUSD", "websiteURL"]
ALL_SYSTEMS = ["rankQS", "rankTimes", "rankShanghai", "rankUSNews"]
ALL_YEARS   = [2022, 2023, 2024, 2025, 2026]
MAX_RANK    = 700

# ── Name normalisation ────────────────────────────────────────────────────────
ALIASES: dict[str, list[str]] = {
    "Massachusetts Institute of Technology": ["MIT", "Massachusetts Institute of Technology (MIT)"],
    "University of California, Berkeley":    ["UC Berkeley", "Univ California Berkeley"],
    "University of California, Los Angeles": ["UCLA", "UC Los Angeles"],
    "University of California, San Diego":   ["UC San Diego", "UCSD"],
    "University of California, Davis":       ["UC Davis"],
    "University of California, Santa Barbara": ["UC Santa Barbara", "UCSB"],
    "University of California, Irvine":      ["UC Irvine", "UCI"],
    "University of Michigan–Ann Arbor":      ["University of Michigan", "Univ Michigan",
                                              "University of Michigan-Ann Arbor"],
    "University of Wisconsin–Madison":       ["University of Wisconsin-Madison", "UW Madison",
                                              "University of Wisconsin - Madison"],
    "University of Minnesota–Twin Cities":   ["University of Minnesota"],
    "Washington University in St. Louis":    ["WashU", "Washington Univ St Louis",
                                              "Washington University in St Louis"],
    "HKUST": ["Hong Kong University of Science and Technology",
               "HKUST - Hong Kong University of Science and Technology"],
    "KAIST": ["Korea Advanced Institute of Science and Technology",
               "Korea Advanced Institute of Science & Technology (KAIST)"],
    "POSTECH": ["Pohang University of Science and Technology"],
    "LMU Munich": ["Ludwig Maximilian University of Munich",
                   "Ludwig-Maximilians-Universitat Munchen",
                   "Ludwig-Maximilians-Universität München",
                   "Ludwig-Maximilians-Universitat München",
                   "Ludwig Maximilian University Munich"],
    "Technical University of Munich": ["TU Munich", "TUM",
                                       "Technische Universitat Munchen",
                                       "Technische Universität München",
                                       "Technical University Munich"],
    "Technical University of Berlin": ["TU Berlin", "Technische Universitat Berlin"],
    "RWTH Aachen University":         ["RWTH Aachen", "Rheinisch-Westfalische Technische Hochschule Aachen"],
    "Karlsruhe Institute of Technology": ["KIT"],
    "Humboldt University of Berlin":  ["Humboldt-Universitat zu Berlin",
                                       "Humboldt-Universität zu Berlin",
                                       "Humboldt University Berlin"],
    "Free University of Berlin":      ["Freie Universitat Berlin", "FU Berlin",
                                       "Freie Universität Berlin"],
    "Heidelberg University":          ["Ruprecht-Karls-Universitat Heidelberg",
                                       "Ruprecht Karls University Heidelberg",
                                       "Universität Heidelberg"],
    "ETH Zurich":  ["ETH Zürich", "Swiss Federal Institute of Technology Zurich",
                    "Swiss Federal Institute of Technology in Zurich"],
    "EPFL":        ["Ecole Polytechnique Federale de Lausanne",
                    "École Polytechnique Fédérale de Lausanne",
                    "Ecole Polytechnique Fédérale de Lausanne"],
    "PSL University": ["Universite PSL", "PSL Research University",
                       "PSL - Universite Paris Sciences et Lettres",
                       "Université Paris Sciences et Lettres",
                       "Universite Paris Sciences et Lettres (PSL)"],
    "Université Paris-Saclay": ["Paris-Saclay University", "University of Paris-Saclay"],
    "Institut Polytechnique de Paris": ["IP Paris"],
    "Sorbonne University":  ["Sorbonne Universite", "Sorbonne Université"],
    "KU Leuven":            ["Katholieke Universiteit Leuven"],
    "Delft University of Technology": ["TU Delft", "Technische Universiteit Delft"],
    "Karolinska Institute":           ["Karolinska Institutet"],
    "University of Hong Kong":        ["HKU", "The University of Hong Kong"],
    "Chinese University of Hong Kong":["CUHK", "The Chinese University of Hong Kong"],
    "National Taiwan University":     ["NTU"],
    "Sungkyunkwan University":        ["SKKU"],
    "Seoul National University":      ["SNU"],
    "Tokyo Institute of Technology":  ["Tokyo Tech", "Institute of Science Tokyo"],
    "Hebrew University of Jerusalem": ["The Hebrew University of Jerusalem"],
    "Technion – Israel Institute of Technology":
        ["Technion - Israel Institute of Technology", "Technion",
         "Technion Israel Institute of Technology"],
    "Xi'an Jiaotong University":      ["Xian Jiaotong University", "Xi an Jiaotong University"],
    "University of Science and Technology of China": ["USTC"],
    "Huazhong University of Science and Technology": ["HUST",
        "Huazhong University of Construction"],
    "University of Adelaide":         ["Adelaide University"],
    "University of New South Wales":  ["UNSW Sydney", "UNSW"],
    "University of Tokyo":            ["The University of Tokyo"],
    "University of Melbourne":        ["The University of Melbourne"],
    "University of Sydney":           ["The University of Sydney"],
    "University of Queensland":       ["The University of Queensland"],
    "University of Western Australia":["The University of Western Australia"],
    "Ohio State University":          ["The Ohio State University"],
    "University of Minnesota–Twin Cities": ["University of Minnesota"],
    "Nanyang Technological University": ["Nanyang Technological University, Singapore"],
    "National University of Singapore": ["NUS", "NUS Singapore",
                                         "National University of Singapore (NUS)"],
    "California Institute of Technology": ["Caltech",
        "California Institute of Technology (Caltech)"],
    "University of Chicago":        ["Univ of Chicago", "UChicago"],
    "University of Toronto":        ["Univ of Toronto", "U of Toronto"],
    "University of Tokyo":          ["Univ of Tokyo", "The Univ of Tokyo",
                                     "University of Tokyo (UTokyo)"],
    "Kyoto University":             ["Kyoto Univ"],
    "University of Sydney":         ["Univ of Sydney"],
    "University of Melbourne":      ["Univ of Melbourne"],
    "University of Queensland":     ["Univ of Queensland"],
    "University of New South Wales":["UNSW", "UNSW Sydney",
                                     "The University of New South Wales",
                                     "The University of New South Wales (UNSW Sydney)",
                                     "University of New South Wales (UNSW Sydney)"],
    "London School of Economics":   ["LSE",
                                     "London School of Economics and Political Science",
                                     "London School of Economics and Political Science (LSE)",
                                     "The London School of Economics and Political Science",
                                     "The London School of Economics and Political Science (LSE)"],
    "Trinity College Dublin":       ["Trinity College Dublin, The University of Dublin",
                                     "Trinity College Dublin (TCD)"],
    "New York University":          ["NYU", "New York University (NYU)"],
    "University of Amsterdam":      ["Univ of Amsterdam"],
    "University of Edinburgh":      ["Univ of Edinburgh"],
    "University of Manchester":     ["Univ of Manchester"],
    "University of Glasgow":        ["Univ of Glasgow"],
    "University of Birmingham":     ["Univ of Birmingham"],
    "University of Leeds":          ["Univ of Leeds"],
    "University of Sheffield":      ["Univ of Sheffield"],
    "University of Bristol":        ["Univ of Bristol"],
    "University of Warwick":        ["Univ of Warwick"],
    "University of Nottingham":     ["Univ of Nottingham"],
    "University of Southampton":    ["Univ of Southampton"],
    "University of Liverpool":      ["Univ of Liverpool"],
    "University of Oslo":           ["Univ of Oslo"],
    "University of Copenhagen":     ["Univ of Copenhagen"],
    "Uppsala University":           ["Univ of Uppsala"],
    "Universidade de São Paulo":    ["Univ of Sao Paulo", "Univ of São Paulo",
                                     "University of Sao Paulo"],
    "Purdue University":            ["Purdue University - West Lafayette",
                                     "Purdue University West Lafayette"],
    "University of Padova":         ["University of Padua (UNIPD)", "University of Padua"],
    "University of Bologna":        ["Alma Mater Studiorum - University of Bologna"],
    "Sorbonne University":          ["Sorbonne Universite", "Sorbonne Université",
                                     "Sorbonne University (merged from Paris IV & UPMC)"],
    "KU Leuven":                    ["Catholic University of Leuven",
                                     "Katholieke Universiteit Leuven"],
}

def _norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())

def best_match(scraped: str, csv_names: list[str], threshold: float = 0.82):
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

def parse_rank(v) -> int | None:
    if v is None:
        return None
    s = str(v).strip().lstrip("=").split("-")[0].split("–")[0].replace(",", "")
    try:
        n = int(float(s))
        return n if 1 <= n <= MAX_RANK else None
    except (ValueError, TypeError):
        return None

# ── Load one per-year Kaggle file ─────────────────────────────────────────────
def load_file(path: Path, year: int) -> dict[str, int]:
    results: dict[str, int] = {}
    # Try UTF-8 first, fall back to latin-1 (covers most Western-European accents)
    for enc in ("utf-8", "latin-1", "utf-8-sig"):
        try:
            with open(path, newline="", encoding=enc) as f:
                content = f.read()
            break
        except UnicodeDecodeError:
            continue
    else:
        print(f"  ✗  {path.name}: could not decode with utf-8/latin-1/utf-8-sig")
        return {}
    try:
        import io as _io
        reader = csv.DictReader(_io.StringIO(content))
        hdrs = reader.fieldnames or []
        year_col = next((c for c in hdrs if c.lower().strip() == "year"), None)
        name_col = next((c for c in hdrs if c.lower().strip() in
                         ("university", "name", "institution", "school",
                          "university_name")), None)
        rank_col = next((c for c in hdrs if c.lower().strip() in
                         ("rank", "world_rank", "ranking")), None)
        if not (name_col and rank_col):
            print(f"  ⚠  {path.name}: cannot identify name/rank columns")
            return {}
        for row in reader:
            if year_col:
                row_year = str(row.get(year_col, "")).strip()
                # Only filter when year value is non-empty (some files leave it blank,
                # relying on the filename to convey the year)
                if row_year and row_year != str(year):
                    continue
            name = row.get(name_col, "").strip()
            rank = parse_rank(row.get(rank_col))
            if name and rank:
                results[name] = rank
    except Exception as e:
        print(f"  ✗  {path.name}: {e}")
        return {}
    return results

# ── Main update logic ─────────────────────────────────────────────────────────
def apply(systems: list[str], years: list[int], dry_run: bool) -> None:
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader   = csv.DictReader(f)
        old_hdrs = list(reader.fieldnames or [])
        rows     = list(reader)

    csv_names = [r["name"] for r in rows]

    # Build output headers: keep existing order, add any missing ranking columns
    years_desc = sorted(years, reverse=True)
    new_headers = list(old_hdrs)
    for sys in ALL_SYSTEMS:
        for yr in sorted(ALL_YEARS, reverse=True):
            col = f"{sys}_{yr}"
            if col not in new_headers:
                new_headers.append(col)
    # Ensure every row has all keys
    for row in rows:
        for h in new_headers:
            if h not in row:
                row[h] = ""

    # Clear only columns being processed, then refill from Kaggle files
    for sys in systems:
        prefix = SYSTEM_PREFIX[sys]
        for yr in years:
            col = f"{sys}_{yr}"
            for row in rows:
                row[col] = ""

    total_filled: dict[str, dict[int, int]] = {s: {y: 0 for y in years} for s in systems}
    unmatched:    dict[str, dict[str, int]] = {s: {} for s in systems}

    for sys in systems:
        prefix = SYSTEM_PREFIX[sys]
        for yr in years:
            path = KAGGLE_DIR / f"{prefix}_{yr}.csv"
            if not path.exists():
                print(f"  — {path.name} not found, skipping")
                continue
            print(f"  [{sys}] {yr}  ← {path.name}")
            data = load_file(path, yr)
            if not data:
                print(f"      (no rows loaded)")
                continue
            print(f"      {len(data)} source entries")
            col = f"{sys}_{yr}"
            for src_name, rank in data.items():
                csv_name, score = best_match(src_name, csv_names)
                if csv_name:
                    for row in rows:
                        if row["name"] == csv_name:
                            row[col] = str(rank)
                            total_filled[sys][yr] += 1
                            break
                else:
                    prev = unmatched[sys].get(src_name)
                    if prev is None or rank < prev:
                        unmatched[sys][src_name] = rank

    # Summary
    print(f"\n{'═'*60}")
    for sys in systems:
        for yr in years:
            n = total_filled[sys][yr]
            print(f"  {sys}_{yr}: {n} rows filled")
    print()
    for sys in systems:
        nm = unmatched[sys]
        if nm:
            print(f"  ⚠  {sys}: {len(nm)} source names not matched in CSV:")
            for name in sorted(nm, key=lambda x: nm[x])[:15]:
                print(f"       #{nm[name]:4d}  {name}")
            if len(nm) > 15:
                print(f"       … and {len(nm)-15} more")
    print(f"{'═'*60}")

    if dry_run:
        print("  --dry-run: CSV not written.")
        return

    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=new_headers,
                            quoting=csv.QUOTE_ALL, extrasaction="ignore")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)

    with open(CSV_PATH, "w", encoding="utf-8", newline="") as f:
        f.write(out.getvalue())
    print(f"  ✓  Written → {CSV_PATH}")

# ── CLI ───────────────────────────────────────────────────────────────────────
def main() -> None:
    p = argparse.ArgumentParser(description="Apply Kaggle ranking CSVs to universities.csv")
    p.add_argument("--systems", nargs="+",
                   choices=["qs", "the", "arwu", "usnews", "all"],
                   default=["qs", "the", "arwu"],
                   help="Systems to update (default: qs the arwu)")
    p.add_argument("--years", nargs="+", type=int, default=ALL_YEARS)
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    sys_map = {"qs": "rankQS", "the": "rankTimes",
               "arwu": "rankShanghai", "usnews": "rankUSNews"}
    if "all" in args.systems:
        systems = list(SYSTEM_PREFIX.keys())
    else:
        systems = [sys_map[s] for s in args.systems]

    print(f"Systems : {systems}")
    print(f"Years   : {sorted(args.years)}")
    print(f"Kaggle  : {KAGGLE_DIR}\n")
    apply(systems, sorted(args.years), dry_run=args.dry_run)

if __name__ == "__main__":
    main()
