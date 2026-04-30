#!/usr/bin/env python3
"""
Update only rankUSNews_2026 in universities.csv using data
scraped from xuanxiao.org/en/rankings/usnews/global-rankings pages 1-5.
All other columns are left untouched.
"""

import csv, sys, os

CSV_PATH = os.path.join(os.path.dirname(__file__), "../cinfo/universities.csv")

# --- XuanXiao 2026 US News ranks (pages 1-5, verified) ---
# Key = name as it appears in our CSV
USNEWS_2026 = {
    # USA
    "Harvard University": 1,
    "Massachusetts Institute of Technology": 2,
    "Stanford University": 3,
    "University of Oxford": 4,
    "University of Cambridge": 5,
    "University of California, Berkeley": 6,
    "University College London": 7,
    "University of Washington": 8,
    "Yale University": 9,
    "Columbia University": 10,
    "Imperial College London": 11,
    "Tsinghua University": 11,
    "University of California, Los Angeles": 13,
    "Johns Hopkins University": 14,
    "University of Pennsylvania": 15,
    "Cornell University": 16,
    "Princeton University": 16,
    "University of Toronto": 16,
    "National University of Singapore": 20,
    "University of California, San Diego": 21,
    "University of Michigan–Ann Arbor": 21,
    "California Institute of Technology": 23,
    "Northwestern University": 24,
    "Peking University": 25,
    "University of Chicago": 26,
    "Duke University": 27,
    "Nanyang Technological University": 28,
    "University of Sydney": 29,
    "University of Melbourne": 30,
    "Washington University in St. Louis": 31,
    "New York University": 32,
    "University of Amsterdam": 33,
    "University of New South Wales": 34,
    "ETH Zurich": 35,
    "King's College London": 36,
    "Chinese University of Hong Kong": 37,
    "Monash University": 38,
    "University of Edinburgh": 39,
    "University of British Columbia": 41,
    "University of Copenhagen": 41,
    "University of Queensland": 43,
    "University of Hong Kong": 44,
    "Zhejiang University": 45,
    "Shanghai Jiao Tong University": 46,
    "Humboldt University of Berlin": 47,
    "Utrecht University": 49,
    "KU Leuven": 50,
    "University of North Carolina at Chapel Hill": 51,
    "Karolinska Institute": 52,
    "University of Pittsburgh": 52,
    "City University of Hong Kong": 54,
    "Leiden University": 56,
    "LMU Munich": 57,
    "Hong Kong Polytechnic University": 58,
    "Free University of Berlin": 59,
    "Heidelberg University": 59,
    "University of Zurich": 59,
    "McGill University": 62,
    "Sorbonne University": 62,
    "University of Glasgow": 62,
    "University of Texas at Austin": 65,
    "Vanderbilt University": 66,
    "Ohio State University": 66,
    "University of Manchester": 68,
    "Emory University": 69,
    "Fudan University": 70,
    "University of Science and Technology of China": 71,
    "University of Maryland, College Park": 72,
    "University of Minnesota–Twin Cities": 72,
    "University of Wisconsin–Madison": 72,
    "University of Groningen": 75,
    "Erasmus University Rotterdam": 76,
    "University of Southern California": 77,
    "Université Paris-Saclay": 78,
    "Georgia Institute of Technology": 79,
    "Technical University of Munich": 79,
    "University of Barcelona": 82,
    "University of Technology Sydney": 83,
    "University of Tokyo": 84,
    "Sun Yat-sen University": 85,
    "Australian National University": 86,
    "Boston University": 86,
    "EPFL": 86,
    "Nanjing University": 86,
    "Wuhan University": 90,
    "Huazhong University of Science and Technology": 91,
    "Pennsylvania State University": 91,
    "University of California, Santa Barbara": 91,
    "Queen Mary University of London": 94,
    "University of Birmingham": 94,
    "University of California, Davis": 96,
    "University of California, Irvine": 96,
    "University of Western Australia": 98,
    "University of Adelaide": 99,
    "University of Oslo": 100,
    "HKUST": 101,
    "PSL University": 105,
    "University of Bristol": 105,
    "Ghent University": 107,
    "University of Colorado Boulder": 107,
    "University of Illinois Urbana-Champaign": 109,
    "University of Florida": 109,
    "University of Helsinki": 113,
    "University of Bern": 114,
    "University of Arizona": 115,
    "Wageningen University & Research": 115,
    "Aarhus University": 117,
    "University of Southampton": 118,
    "University of Geneva": 120,
    "Lund University": 121,
    "Tongji University": 124,
    "Carnegie Mellon University": 126,
    "University of Exeter": 127,
    "Harbin Institute of Technology": 128,
    "University of Auckland": 128,
    "Michigan State University": 133,
    "Seoul National University": 133,
    "University of Leeds": 133,
    "University of Liverpool": 137,
    "University of Padova": 137,
    "University of Virginia": 137,
    "University of Bologna": 141,
    "University of Hamburg": 141,
    "Uppsala University": 141,
    "Xi'an Jiaotong University": 141,
    "McMaster University": 146,
    "Brown University": 150,
    "Curtin University": 152,
    "University of Nottingham": 153,
    "Beijing Institute of Technology": 156,
    "Stockholm University": 156,
    "University of Alberta": 156,
    "Sapienza University of Rome": 161,
    "University of Massachusetts Amherst": 162,
    "Indiana University Bloomington": 163,
    "University of Bonn": 164,
    "South China University of Technology": 166,
    "University of Sheffield": 166,
    "Newcastle University": 170,
    "Beijing Normal University": 173,
    "Deakin University": 173,
    "Purdue University": 173,
    "Case Western Reserve University": 176,
    "Macquarie University": 178,
    "Technical University of Denmark": 178,
    "University of Basel": 180,
    "Yonsei University": 180,
    "Queensland University of Technology": 182,
    "University of Warwick": 182,
    "Kyoto University": 187,
    "Texas A&M University": 187,
    "Arizona State University": 192,
    "Cardiff University": 192,
    "University of Waterloo": 197,
    "RMIT University": 198,
    "Tel Aviv University": 199,
    "University of Rochester": 201,
    "Beihang University": 207,
    "Trinity College Dublin": 207,
    "University of Vienna": 212,
    "University of Wollongong": 212,
    "Rice University": 219,
    "RWTH Aachen University": 225,
    "Queen's University Belfast": 230,
    "London School of Economics": 234,
}

def main():
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    col = "rankUSNews_2026"
    if col not in fieldnames:
        print(f"ERROR: column '{col}' not found")
        sys.exit(1)

    updated = 0
    unchanged = 0
    not_found = []

    for row in rows:
        name = row["name"]
        if name in USNEWS_2026:
            new_val = str(USNEWS_2026[name])
            old_val = row[col].strip()
            if old_val != new_val:
                row[col] = new_val
                updated += 1
                print(f"  Updated: {name:55s} {old_val or '(empty)':>8} → {new_val}")
            else:
                unchanged += 1
        else:
            not_found.append(name)

    with open(CSV_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\n✓ Updated {updated} values, {unchanged} already correct.")
    print(f"  {len(not_found)} universities not in the 2026 ranking (rank left unchanged):")
    for n in not_found:
        print(f"    - {n}")

if __name__ == "__main__":
    main()
