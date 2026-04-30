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

---

## SRS Algorithm  (v3 — current)

> **Files:** algorithm → `cinfo/College.swift`  |  supplemental data → `cinfo/SupplementalData.swift`

The **Synaptic Ranking System (SRS)** is a six-factor composite that rewards **concentrated
excellence**: a smaller, focused institution with high resources and many
affiliated laureates outscores a large institution with the same absolute
numbers diluted across a massive student body.

### Six components

| # | Component | Base weight | Data source |
|---|-----------|-------------|-------------|
| 1 | **Academic rankings** | 49 % | QS / Times / USNews / Shanghai, 2022–2026 |
| 2 | **Endowment per student** | 15 % | Endowment ÷ total enrollment (USD, 2024) |
| 3 | **Selectivity** | 13.5 % | Undergraduate acceptance rate (%) |
| 4 | **Research awards** | 12 % | All-time affiliated Nobel / Fields / Turing laureates |
| 5 | **Institutional focus** | 8.5 % | Inverse-log of enrollment size × inverse-log of school count |
| 6 | **Location** | 2 % | Metro-area size / city centrality, pre-scored 0–100 |

---

### Component 1 — Academic rankings  (49 %)

**Step 1a — Per-system temporal-weighted average rank**

For each system S ∈ {QS, Times, USNews, Shanghai}:

```
weight(Y) = α ^ (currentYear − Y)      α = 0.75

r(S) = Σ[ weight(Y) · rank(S,Y) ] / Σ[ weight(Y) ]
       for all Y ∈ [currentYear−4 … currentYear] with data
```

Effective weights when all 5 years are present (normalised):

| Year | Raw weight | Share |
|------|------------|-------|
| 2026 | 1.0000 | 32.8 % |
| 2025 | 0.7500 | 24.6 % |
| 2024 | 0.5625 | 18.4 % |
| 2023 | 0.4219 | 13.8 % |
| 2022 | 0.3164 | 10.4 % |

Missing years are excluded from both numerator and denominator.

**Step 1b — Cross-system mean**

```
r̄ = mean( r(S) )   for all S with ≥ 1 data point
```

All four systems weighted equally (equal expertise representation).

**Step 1c — Normalise to 0–100**

```
rankScore = max(0,  100 × (1 − (r̄ − 1) / 249))
```

| r̄  | rankScore |
|----|-----------|
| 1  | 100.0 |
| 25 | 90.4 |
| 50 | 80.3 |
| 125 | 50.2 |
| 250 | 0.0 |

---

### Component 2 — Selectivity  (13.5 %)

```
selScore = max(0, min(100, 100 − acceptanceRate))
```

| Acceptance rate | selScore |
|-----------------|----------|
| 0–3 % (elite US; Chinese top schools via Gaokao) | ≥ 97 |
| 7 % (Ivy-tier) | 93 |
| 15 % | 85 |
| 50 % | 50 |
| 85 % (European public) | 15 |

> **Note on Chinese universities:** acceptance rates reflect the
> effective probability of qualifying for top-tier institutions via
> the national Gaokao examination (~0.04–0.08 % of all sitters), a
> valid measure of selectivity but not directly comparable to western
> per-applicant rates.

---

### Component 3 — Endowment per student  (15 %)

Rewards **concentrated** financial resources.  A $34 B endowment for
8,500 students (Princeton ≈ $4 M/student) outscores a $53 B endowment
spread across 21,000 students (Harvard ≈ $2.5 M/student).

```
endPerStudentKUSD = endowmentBn × 10^6 / studentCount   (USD thousands)
endPerStudentScore = min(100,  ln(max(1, endPerStudentKUSD)) / ln(4012) × 100)
```

Anchored at Princeton's ~$4,012 K per student → 100.

| University | USD / student | Score |
|-----------|--------------|-------|
| Princeton ($34.1 B / 8 500) | $4 012 K | 100 |
| Yale ($41.4 B / 14 000) | $2 957 K | 94.4 |
| Stanford ($37.6 B / 17 000) | $2 212 K | 91.9 |
| Harvard ($53.2 B / 21 000) | $2 533 K | 92.9 |
| MIT ($24.6 B / 11 500) | $2 139 K | 91.4 |
| Caltech ($4.1 B / 2 400) | $1 708 K | 89.5 |
| ETH Zurich ($11 B / 24 000) | $458 K | 73.7 |
| Michigan ($17 B / 47 000) | $362 K | 71.2 |
| Ohio State ($7.4 B / 61 000) | $121 K | 57.9 |
| ASU ($1.8 B / 135 000) | $13 K | 30.8 |

---

### Component 4 — Research awards  (12 %)

Rewards absolute **prestige of research output** — the total number of
all-time affiliated Nobel Prize, Fields Medal, and Turing Award laureates.
Log-scaled so that marginal additional laureates have diminishing effect.

```
researchAwardsScore = min(100,  ln(max(1, awardCount) + 1) / ln(162) × 100)
```

Anchored at Harvard's 161 laureates → 100.

| University | Laureates | Score |
|-----------|-----------|-------|
| Harvard | 161 | 100 |
| Cambridge | 121 | 96.4 |
| Berkeley | 112 | 95.3 |
| Chicago | 100 | 93.9 |
| MIT | 97 | 93.5 |
| Stanford | 85 | 91.8 |
| Caltech | 76 | 90.5 |
| Oxford | 72 | 90.0 |
| Princeton | 81 | 91.2 |
| ETH Zurich | 32 | 75.3 |
| 0 laureates | 0 | 0 |

---

### Component 5 — Institutional focus  (8.5 %)

Combines two sub-signals with equal weight.  Captures the user's intuition
that a small, focused institution is intrinsically different from a large
comprehensive one with the same absolute resources.

**a) Enrollment focus** — smaller student body = more focused mission

```
studentFocus = (ln(150 000) − ln(max(studentCount, 2 000)))
               / (ln(150 000) − ln(2 000))  × 100
```

Anchored: 2 000 students → 100,  150 000 students → 0.

**b) Departmental focus** — fewer schools/colleges = narrower academic scope

```
deptFocus = (ln(65) − ln(max(schoolCount, 4)))
            / (ln(65) − ln(4))  × 100
```

Anchored: 4 schools → 100,  65 schools → 0.

```
focusScore = (studentFocus + deptFocus) / 2
```

| University | Students | Schools | Focus score |
|-----------|---------|---------|------------|
| Caltech | 2 400 | 6 | 90.7 |
| POSTECH | 3 200 | 5 | 90.8 |
| Karolinska | 6 000 | 4 | 87.5 |
| Princeton | 8 500 | 4 | 82.5 |
| MIT | 11 500 | 5 | 76.9 |
| Harvard | 21 000 | 12 | 53.2 |
| Ohio State | 61 000 | 19 | 32.5 |
| Sapienza | 110 000 | 65 | 3.6 |

---

### Component 6 — Location  (2 %)

Pre-scored on a 0–100 scale based on the metropolitan area in which each campus sits.
Scoring reflects city size (metro population), global connectivity, and industry density.

```
locationScore  (0–100, from SupplementalData.swift)
```

| Tier | Score | Example campuses |
|------|-------|-----------------|
| Major global megacities | 95–100 | Columbia/NYU (NYC), UCL/LSE (London), UTokyo, Fudan/SJTU (Shanghai) |
| Top regional metros | 85–94 | UCLA/Stanford (LA/Bay Area), Chicago, Seoul, Singapore, Sydney CBD |
| Large city metros | 75–84 | Boston (MIT/Harvard), Berlin, Toronto, Houston, Atlanta |
| Mid-size cities | 60–74 | Pittsburgh (CMU), Nashville, Edinburgh, Manchester, Osaka |
| Smaller cities | 45–59 | Ann Arbor, Adelaide, Canberra, Lausanne, Lund |
| College towns | 20–44 | Princeton, Oxford/Cambridge UK, Ithaca (Cornell), Hanover (Dartmouth) |

Log-scaling is not applied — the raw score is used directly, giving a linear
advantage to urban campuses commensurate with the 2 % weight.

---

### Weighted blend & missing-data policy

```
compositeScore = Σ(w_i × score_i) / Σ(w_i)
                 over all available components
```

If a supplemental field is `nil` (data unavailable), its base weight is
redistributed proportionally to the remaining available components.
This ensures no implicit zero-penalty for unknown fields.

```
averageRank = 100 − compositeScore        (lower = better, preserves sort order)
```

Universities are sorted ascending by `averageRank`.  
Position in that list = **SRS** badge displayed on the card.

---

### Constants

| Constant | Value | Role |
|----------|-------|------|
| `temporalDecay` α | 0.75 | 75 % retention per year of history |
| `currentYear` | 2026 | Anchor year — update each release cycle |
| `historyWindow` | 5 years | currentYear−4 … currentYear |
| `rankFloor` | 250 | Ranks beyond this → rankScore = 0 |
| `endPerStudentAnchorK` | 4 012 | Princeton USD thousands / student |
| `researchAwardsAnchor` | 162 | Harvard 161 laureates + 1 (log base) |
| `enrollAnchorMin / Max` | 2 000 / 150 000 | Enrollment focus bounds |
| `deptAnchorMin / Max` | 4 / 65 | School-count focus bounds |
| Weight split | 49 / 13.5 / 15 / 12 / 8.5 / 2 | Rankings / Selectivity / EndowPerStudent / ResearchAwards / Focus / Location |

---

### Supplemental data

All raw values stored in `cinfo/SupplementalData.swift`.  
Entries cover all 211 universities; fields left `nil` where data is
unavailable or not meaningfully comparable cross-nationally.

**Seven fields per university**

| Field | Description |
|-------|-------------|
| `acceptanceRate` | Undergraduate acceptance rate (%) |
| `endowmentBn` | Total endowment, USD billions (2024) |
| `awardCount` | All-time Nobel + Fields + Turing affiliates |
| `studentCount` | Total enrolled students (all levels, 2023–24) |
| `facultyCount` | Full-time equivalent academic faculty |
| `schoolCount` | Number of degree-granting schools / colleges / faculties |
| `locationScore` | Metro-area centrality score (0–100, pre-assigned) |

**Sources**
- Acceptance rates: QS World Rankings, Wikipedia, official university websites (2023–2024)
- Endowments: institutional annual reports, Wikipedia (converted to USD, 2024 rates)
- Award counts: Nobel Prize organisation, university honour records (as of 2024)
- Student / faculty / school counts: institutional fact sheets, Wikipedia (2023–2024)
- Location scores: assigned from metro-area population and global city indices (2024)

---

## SRS Algorithm  (v1 — superseded by v2, then v3)

> Replaced by v2. Kept for historical reference.

### Step 1 — Per-system temporal weighted average

```
weight(Y) = α ^ (currentYear − Y)      α = 0.75
score(S)  = Σ[ weight(Y) · rank(S,Y) ] / Σ[ weight(Y) ]
```

### Step 2 — Cross-system average

```
averageRank = mean( score(S) )  for all S with ≥ 1 data point
```

### Step 3 — Positional rank

Sort ascending by `averageRank`; position = SRS rank.

### Constants

| Constant | Value |
|----------|-------|
| `temporalDecay` | 0.75 |
| `currentYear` | 2026 |
| `historyWindow` | 5 yrs |
