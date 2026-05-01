#!/usr/bin/env python3
"""
save_srs_scores.py
──────────────────
Replicates the Swift SRS compositeScore formula, computes a score for every
university in universities.csv, and writes the result as a new `srsScore`
column (rounded to one decimal place).

Formula mirrors College.swift compositeScore (v3):
  Component 1  Academic rankings     45 %  temporal-weighted cross-system avg
  Component 2  Selectivity          13.5%  max(0, 100 - acceptanceRate)
  Component 3  Endowment/student    19 %  log-scale, Princeton $4 012 K → 100
  Component 4  Research awards      12 %  log-scale, Harvard 162 → 100
  Component 5  Institutional focus   8.5%  enrollment + school count
  Component 6  Location              2 %  metro-area pre-scored 0-100

Missing-data policy: if a supplemental field is nil, its weight is
redistributed proportionally to available components (no penalty for gaps).
"""

import csv, re, math, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH    = ROOT / "cinfo" / "universities.csv"
SUPPL_PATH  = ROOT / "cinfo" / "SupplementalData.swift"

CURRENT_YEAR  = 2026
ALPHA         = 0.75   # temporal decay
RANK_FLOOR    = 249.0  # rank beyond which score = 0
ENDOW_ANCHOR  = 4012.0 # $K/student → Princeton endowment per student ≈ 100
AWARD_ANCHOR  = 162.0  # Harvard all-time laureates


# ── 1. Parse SupplementalData.swift ──────────────────────────────────────────

def _parse_supplemental(path: Path) -> dict:
    """Return dict  name → {acceptanceRate, endowmentBn, awardCount,
                             studentCount, schoolCount, locationScore}"""
    text = path.read_text(encoding="utf-8")

    # Each entry spans 1-3 lines, e.g.:
    #   "Harvard University":     .init(acceptanceRate: 3.2, endowmentBn: 53.2,
    #                                   awardCount: 161, studentCount: 21_000,
    #                                   facultyCount: 2_400, schoolCount: 13, locationScore: 95),

    # Collapse the block into one long string so we can match across lines
    # Strategy: find each "Name": .init( ... ), block
    pattern = re.compile(
        r'"([^"]+)"\s*:\s*\.init\(([^)]+)\)',
        re.DOTALL
    )

    def _val(blob: str, key: str) -> float | None:
        m = re.search(rf'\b{key}\s*:\s*([\d_\.]+)', blob)
        if not m:
            return None
        return float(m.group(1).replace("_", ""))

    result = {}
    for m in pattern.finditer(text):
        name = m.group(1)
        blob = m.group(2)
        result[name] = {
            "acceptanceRate": _val(blob, "acceptanceRate"),
            "endowmentBn":    _val(blob, "endowmentBn"),
            "awardCount":     _val(blob, "awardCount"),
            "studentCount":   _val(blob, "studentCount"),
            "schoolCount":    _val(blob, "schoolCount"),
            "locationScore":  _val(blob, "locationScore"),
        }
    return result


# ── 2. Temporal-weighted average rank ────────────────────────────────────────

def _temporal_avg(year_vals: dict) -> float | None:
    """year_vals: {year: rank_int_or_None}  → weighted avg rank"""
    w_sum, w_tot = 0.0, 0.0
    for age in range(5):          # age 0 = currentYear, age 4 = currentYear-4
        year = CURRENT_YEAR - age
        v = year_vals.get(year)
        if v is not None:
            w = ALPHA ** age
            w_sum += w * v
            w_tot += w
    return w_sum / w_tot if w_tot else None


# ── 3. Composite SRS score ────────────────────────────────────────────────────

def _composite(name: str, rankings: dict, sup: dict) -> float | None:
    """
    rankings: {"QS": {2026: 1, 2025: 1, …}, "Times": {…}, …}
    sup:      dict from _parse_supplemental
    Returns compositeScore 0-100 or None.
    """
    # --- Academic rankings component ---
    sys_avgs = []
    for sys_ranks in rankings.values():
        avg = _temporal_avg(sys_ranks)
        if avg is not None:
            sys_avgs.append(avg)
    if not sys_avgs:
        return None
    r_bar      = sum(sys_avgs) / len(sys_avgs)
    rank_score = max(0.0, 100.0 * (1.0 - (r_bar - 1.0) / RANK_FLOOR))

    parts = [(0.45, rank_score)]   # (weight, score)

    # --- Selectivity ---
    a = sup.get("acceptanceRate")
    if a is not None:
        parts.append((0.135, max(0.0, min(100.0, 100.0 - a))))

    # --- Endowment per student ---
    e = sup.get("endowmentBn")
    s = sup.get("studentCount")
    if e and s and e > 0 and s > 0:
        k_usd = e * 1_000_000.0 / s
        score = min(100.0, max(0.0,
                    math.log(max(1.0, k_usd)) / math.log(ENDOW_ANCHOR) * 100.0))
        parts.append((0.19, score))

    # --- Research awards ---
    n = sup.get("awardCount")
    if n is not None:
        score = min(100.0, max(0.0,
                    math.log(max(1, n) + 1.0) / math.log(AWARD_ANCHOR) * 100.0))
        parts.append((0.12, score))

    # --- Institutional focus ---
    enroll_focus = None
    dept_focus   = None
    sc = sup.get("studentCount")
    dc = sup.get("schoolCount")
    if sc is not None:
        c = max(sc, 2_000.0)
        enroll_focus = min(100.0, max(0.0,
            (math.log(150_000.0) - math.log(c)) /
            (math.log(150_000.0) - math.log(2_000.0)) * 100.0))
    if dc is not None:
        c = max(dc, 4.0)
        dept_focus = min(100.0, max(0.0,
            (math.log(65.0) - math.log(c)) /
            (math.log(65.0) - math.log(4.0)) * 100.0))
    if enroll_focus is not None or dept_focus is not None:
        subs = [x for x in [enroll_focus, dept_focus] if x is not None]
        parts.append((0.085, sum(subs) / len(subs)))

    # --- Location ---
    loc = sup.get("locationScore")
    if loc is not None:
        parts.append((0.02, loc))

    # --- Weighted blend (missing-data policy: redistribute weights) ---
    total_w = sum(w for w, _ in parts)
    w_sum   = sum(w * sc for w, sc in parts)
    return round(w_sum / total_w, 1) if total_w else None


# ── 4. Main ───────────────────────────────────────────────────────────────────

def main():
    supplemental = _parse_supplemental(SUPPL_PATH)
    print(f"Parsed supplemental data for {len(supplemental)} universities.")

    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows   = list(reader)

    # Remove any existing srsScore column
    if "srsScore" in header:
        idx = header.index("srsScore")
        header.pop(idx)
        rows = [r[:idx] + r[idx+1:] for r in rows]

    # Build column index for ranking columns
    name_col = header.index("name")
    rank_cols: dict[str, dict] = {}   # e.g. "QS" → {2026: col_idx, …}
    for i, col in enumerate(header):
        parts = col.split("_")
        if len(parts) == 2 and parts[0].startswith("rank") and parts[1].isdigit():
            sys_key = parts[0][4:]   # "QS", "Times", "USNews", "Shanghai"
            year    = int(parts[1])
            rank_cols.setdefault(sys_key, {})[year] = i

    computed = 0
    missing  = []
    out_rows = []

    for row in rows:
        if not any(row):
            out_rows.append(row + [""])
            continue

        def safe(i):
            return row[i] if i < len(row) else ""

        name = safe(name_col).strip('"')

        # Build rankings dict  system → {year: rank}
        rankings: dict[str, dict] = {}
        for sys_key, year_map in rank_cols.items():
            for year, col_i in year_map.items():
                val = safe(col_i)
                rankings.setdefault(sys_key, {})[year] = int(val) if val.isdigit() else None

        sup = supplemental.get(name, {})
        score = _composite(name, rankings, sup)

        if score is None:
            missing.append(name)
            out_rows.append(row + [""])
        else:
            out_rows.append(row + [str(score)])
            computed += 1

    # Write output
    header.append("srsScore")
    with open(CSV_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)
        writer.writerows(out_rows)

    print(f"✓  srsScore written for {computed} universities.")
    if missing:
        print(f"   No score (missing ranking data): {', '.join(missing)}")


if __name__ == "__main__":
    main()
