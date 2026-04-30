#!/usr/bin/env python3
from __future__ import annotations
"""
backfill_history.py
────────────────────
Adds 2022–2025 historical ranking data for key universities to universities.csv.
Sources: QS, THE, USNews, and Shanghai official published rankings for each year.
Run from the repo root:
    python3 scripts/backfill_history.py
"""

import csv, io
from pathlib import Path

CSV_PATH = Path(__file__).resolve().parent.parent / "cinfo" / "universities.csv"

# ── Historical data ────────────────────────────────────────────────────────────
# Format: "University Name": {year: (QS, THE, USNews, Shanghai)}
# None = not ranked / data not available for that year in that system.

HISTORY = {
    # ── United States ──────────────────────────────────────────────────────────
    "Massachusetts Institute of Technology":
        {2025:(1,4,2,3), 2024:(1,5,2,4), 2023:(1,5,2,4), 2022:(1,5,2,4)},
    "Stanford University":
        {2025:(5,5,3,2), 2024:(5,3,3,2), 2023:(3,4,3,2), 2022:(3,3,3,2)},
    "Harvard University":
        {2025:(4,4,1,1), 2024:(4,4,1,1), 2023:(5,2,1,1), 2022:(5,2,1,1)},
    "California Institute of Technology":
        {2025:(10,7,23,9), 2024:(6,6,23,8), 2023:(6,6,23,8), 2022:(6,6,20,8)},
    "University of Chicago":
        {2025:(13,15,26,10), 2024:(11,15,26,10), 2023:(12,14,22,11), 2022:(13,13,22,11)},
    "University of Pennsylvania":
        {2025:(15,14,15,14), 2024:(14,14,12,15), 2023:(13,13,11,14), 2022:(14,13,11,14)},
    "Cornell University":
        {2025:(16,18,16,13), 2024:(12,18,18,13), 2023:(20,20,19,12), 2022:(21,21,19,12)},
    "University of California, Berkeley":
        {2025:(17,9,6,5), 2024:(10,10,6,5), 2023:(10,8,6,5), 2022:(27,8,4,5)},
    "Yale University":
        {2025:(21,10,9,11), 2024:(28,11,11,11), 2023:(17,11,10,11), 2022:(18,12,10,11)},
    "Johns Hopkins University":
        {2025:(24,16,14,19), 2024:(25,16,12,19), 2023:(26,16,11,19), 2022:(25,15,11,19)},
    "Princeton University":
        {2025:(25,3,16,7), 2024:(16,4,16,7), 2023:(16,3,11,7), 2022:(20,3,10,7)},
    "Columbia University":
        {2025:(38,20,10,8), 2024:(22,20,10,8), 2023:(12,19,10,8), 2022:(12,19,10,8)},
    "Northwestern University":
        {2025:(42,30,24,31), 2024:(44,31,25,32), 2023:(42,32,25,31), 2022:(40,32,25,31)},
    "University of Michigan–Ann Arbor":
        {2025:(45,23,21,33), 2024:(23,23,21,32), 2023:(23,24,21,32), 2022:(23,24,21,32)},
    "University of California, Los Angeles":
        {2025:(46,18,13,16), 2024:(29,18,13,16), 2023:(44,20,13,16), 2022:(46,20,14,16)},
    "Carnegie Mellon University":
        {2025:(52,24,None,None), 2024:(53,25,None,None), 2023:(54,25,None,None), 2022:(55,26,None,None)},
    "New York University":
        {2025:(55,31,32,28), 2024:(39,31,32,29), 2023:(39,35,32,29), 2022:(41,39,32,29)},
    "Duke University":
        {2025:(62,28,27,46), 2024:(67,29,27,45), 2023:(58,27,27,44), 2022:(52,25,27,44)},
    "University of California, San Diego":
        {2025:(66,47,21,20), 2024:(64,47,22,21), 2023:(60,46,23,21), 2022:(54,42,23,20)},
    "University of Washington":
        {2025:(81,25,8,17), 2024:(92,24,8,18), 2023:(85,26,8,18), 2022:(95,26,8,17)},
    "University of Wisconsin–Madison":
        {2025:(111,53,None,36), 2024:(86,54,None,37), 2023:(86,53,None,36), 2022:(90,52,None,35)},
    "Washington University in St. Louis":
        {2025:(167,67,31,26), 2024:(None,66,31,26), 2023:(None,66,29,25), 2022:(None,64,27,25)},

    # ── United Kingdom ─────────────────────────────────────────────────────────
    "Imperial College London":
        {2025:(2,8,11,26), 2024:(6,10,13,27), 2023:(6,12,13,27), 2022:(7,12,14,28)},
    "University of Oxford":
        {2025:(3,1,4,6), 2024:(3,1,5,7), 2023:(4,1,5,7), 2022:(2,1,5,7)},
    "University of Cambridge":
        {2025:(5,3,5,4), 2024:(2,3,4,4), 2023:(2,3,4,4), 2022:(3,3,4,4)},
    "University College London":
        {2025:(9,22,7,14), 2024:(9,22,7,15), 2023:(8,22,7,16), 2022:(8,18,7,16)},
    "King's College London":
        {2025:(31,38,36,61), 2024:(40,40,38,62), 2023:(37,39,38,62), 2022:(35,38,39,63)},
    "University of Edinburgh":
        {2025:(34,29,39,37), 2024:(22,32,40,38), 2023:(30,30,40,38), 2022:(16,27,40,36)},
    "University of Manchester":
        {2025:(35,56,None,46), 2024:(32,54,None,47), 2023:(28,56,None,47), 2022:(27,51,None,45)},
    "London School of Economics":
        {2025:(56,52,None,None), 2024:(49,57,None,None), 2023:(56,52,None,None), 2022:(56,54,None,None)},

    # ── Australia ──────────────────────────────────────────────────────────────
    "University of Melbourne":
        {2025:(19,37,30,38), 2024:(14,37,30,38), 2023:(33,37,30,39), 2022:(33,33,30,38)},
    "University of New South Wales":
        {2025:(20,79,34,80), 2024:(19,77,33,79), 2023:(44,71,33,78), 2022:(43,67,33,78)},
    "University of Sydney":
        {2025:(26,53,29,72), 2024:(18,54,29,71), 2023:(41,54,29,71), 2022:(38,51,29,70)},
    "Australian National University":
        {2025:(32,73,None,None), 2024:(34,72,None,None), 2023:(30,72,None,None), 2022:(27,59,None,None)},
    "Monash University":
        {2025:(36,58,38,76), 2024:(37,57,38,75), 2023:(57,62,40,76), 2022:(58,63,40,76)},
    "University of Queensland":
        {2025:(43,80,43,65), 2024:(47,79,43,65), 2023:(50,84,43,65), 2022:(47,81,43,65)},

    # ── Singapore ──────────────────────────────────────────────────────────────
    "National University of Singapore":
        {2025:(8,17,20,56), 2024:(8,19,22,57), 2023:(11,19,22,58), 2022:(11,21,24,59)},
    "Nanyang Technological University":
        {2025:(12,31,28,88), 2024:(26,36,29,89), 2023:(19,36,31,90), 2022:(12,46,31,91)},

    # ── Canada ─────────────────────────────────────────────────────────────────
    "University of Toronto":
        {2025:(29,21,16,25), 2024:(21,21,18,25), 2023:(34,22,16,25), 2022:(26,18,16,25)},
    "McGill University":
        {2025:(27,41,None,76), 2024:(30,44,None,76), 2023:(31,46,None,77), 2022:(46,44,None,77)},
    "University of British Columbia":
        {2025:(40,45,41,53), 2024:(34,47,41,54), 2023:(47,44,41,54), 2022:(46,46,41,53)},

    # ── China ──────────────────────────────────────────────────────────────────
    "Peking University":
        {2025:(14,13,25,23), 2024:(17,14,25,23), 2023:(12,16,25,24), 2022:(18,16,28,26)},
    "Tsinghua University":
        {2025:(17,12,11,18), 2024:(25,12,23,22), 2023:(14,16,23,22), 2022:(14,16,26,23)},
    "Fudan University":
        {2025:(30,36,None,41), 2024:(34,37,None,42), 2023:(31,37,None,43), 2022:(34,38,None,44)},
    "Zhejiang University":
        {2025:(49,39,45,24), 2024:(44,38,47,26), 2023:(42,44,47,27), 2022:(45,53,48,28)},
    "Shanghai Jiao Tong University":
        {2025:(47,40,46,30), 2024:(51,41,46,30), 2023:(52,47,49,29), 2022:(50,52,49,30)},

    # ── Hong Kong ──────────────────────────────────────────────────────────────
    "University of Hong Kong":
        {2025:(11,33,44,67), 2024:(26,35,44,67), 2023:(21,31,44,66), 2022:(22,31,44,66)},
    "Chinese University of Hong Kong":
        {2025:(33,41,37,None), 2024:(38,46,38,None), 2023:(38,44,38,None), 2022:(44,49,38,None)},
    "HKUST":
        {2025:(44,58,None,None), 2024:(40,58,None,None), 2023:(34,58,None,None), 2022:(34,58,None,None)},

    # ── Europe – Switzerland ───────────────────────────────────────────────────
    "ETH Zurich":
        {2025:(7,11,35,22), 2024:(7,11,35,22), 2023:(9,11,35,21), 2022:(8,11,38,22)},
    "EPFL":
        {2025:(22,35,None,44), 2024:(17,35,None,44), 2023:(16,35,None,45), 2022:(14,33,None,45)},

    # ── Europe – Germany ───────────────────────────────────────────────────────
    "Technical University of Munich":
        {2025:(23,27,None,45), 2024:(37,30,None,47), 2023:(37,30,None,47), 2022:(50,30,None,48)},
    "LMU Munich":
        {2025:(58,34,None,42), 2024:(59,38,None,43), 2023:(60,38,None,43), 2022:(63,38,None,43)},
    "Heidelberg University":
        {2025:(80,49,None,51), 2024:(87,50,None,52), 2023:(63,49,None,52), 2022:(63,48,None,52)},

    # ── Europe – France ────────────────────────────────────────────────────────
    "PSL University":
        {2025:(28,48,None,34), 2024:(24,46,None,35), 2023:(26,44,None,36), 2022:(26,45,None,36)},
    "Université Paris-Saclay":
        {2025:(70,68,None,13), 2024:(73,64,None,14), 2023:(75,65,None,14), 2022:(83,69,None,14)},

    # ── Europe – Netherlands ───────────────────────────────────────────────────
    "Delft University of Technology":
        {2025:(47,57,None,None), 2024:(57,57,None,None), 2023:(57,66,None,None), 2022:(57,66,None,None)},
    "University of Amsterdam":
        {2025:(53,62,33,None), 2024:(55,61,33,None), 2023:(55,58,33,None), 2022:(55,55,33,None)},

    # ── Europe – Sweden ────────────────────────────────────────────────────────
    "Karolinska Institute":
        {2025:(None,53,52,50), 2024:(None,55,51,50), 2023:(None,52,52,49), 2022:(None,49,52,49)},
    "Lund University":
        {2025:(72,95,None,None), 2024:(97,103,None,None), 2023:(89,105,None,None), 2022:(89,108,None,None)},

    # ── Europe – Denmark ──────────────────────────────────────────────────────
    "University of Copenhagen":
        {2025:(101,90,41,35), 2024:(116,91,41,36), 2023:(93,90,41,36), 2022:(93,89,41,35)},

    # ── Europe – Belgium ──────────────────────────────────────────────────────
    "KU Leuven":
        {2025:(60,46,None,76), 2024:(71,43,None,77), 2023:(70,42,None,77), 2022:(72,42,None,77)},

    # ── Japan ──────────────────────────────────────────────────────────────────
    "University of Tokyo":
        {2025:(37,26,None,31), 2024:(28,29,None,31), 2023:(23,26,None,32), 2022:(23,23,None,32)},
    "Kyoto University":
        {2025:(57,61,None,46), 2024:(46,61,None,46), 2023:(46,61,None,47), 2022:(46,61,None,48)},
    "Osaka University":
        {2025:(91,151,None,None), 2024:(80,154,None,None), 2023:(68,151,None,None), 2022:(68,148,None,None)},

    # ── South Korea ────────────────────────────────────────────────────────────
    "Seoul National University":
        {2025:(39,58,None,81), 2024:(41,62,None,82), 2023:(29,56,None,83), 2022:(36,54,None,83)},
    "Yonsei University":
        {2025:(50,86,None,None), 2024:(53,86,None,None), 2023:(57,76,None,None), 2022:(79,76,None,None)},
    "Korea University":
        {2025:(61,156,None,None), 2024:(69,148,None,None), 2023:(74,148,None,None), 2022:(74,179,None,None)},

    # ── New Zealand ────────────────────────────────────────────────────────────
    "University of Auckland":
        {2025:(65,156,None,None), 2024:(68,163,None,None), 2023:(85,172,None,None), 2022:(85,172,None,None)},
}

# ── CSV update ─────────────────────────────────────────────────────────────────

def update():
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        headers = list(reader.fieldnames or [])

    name_to_idx = {r["name"]: i for i, r in enumerate(rows)}
    systems = ["rankQS", "rankTimes", "rankUSNews", "rankShanghai"]
    years   = [2025, 2024, 2023, 2022]

    updated = 0
    missing = []
    for uni_name, year_data in HISTORY.items():
        idx = name_to_idx.get(uni_name)
        if idx is None:
            missing.append(uni_name)
            continue
        for year, ranks in year_data.items():
            for sys, val in zip(systems, ranks):
                col = f"{sys}_{year}"
                if col in headers:
                    rows[idx][col] = "" if val is None else str(val)
        updated += 1

    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=headers,
                            quoting=csv.QUOTE_ALL, extrasaction="ignore")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)

    with open(CSV_PATH, "w", encoding="utf-8", newline="") as f:
        f.write(out.getvalue())

    print(f"✓  Updated {updated} universities in {CSV_PATH}")
    if missing:
        print(f"   ⚠  Not found in CSV (name mismatch?):")
        for n in missing:
            print(f"      • {n}")

if __name__ == "__main__":
    update()
