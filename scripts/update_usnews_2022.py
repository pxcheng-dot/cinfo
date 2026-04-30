#!/usr/bin/env python3
"""
Update only rankUSNews_2022 in universities.csv using data
scraped from xuanxiao.org/en/rankings/usnews/global-rankings/2022 pages 1-5.
All other columns are left untouched.
"""

import csv, sys, os

CSV_PATH = os.path.join(os.path.dirname(__file__), "../cinfo/universities.csv")

USNEWS_2022 = {
    # Page 1 (1-53)
    "Harvard University": 1,
    "Massachusetts Institute of Technology": 2,
    "Stanford University": 3,
    "University of California, Berkeley": 4,
    "University of Oxford": 5,
    "University of Washington": 6,
    "Columbia University": 7,
    "University of Cambridge": 8,
    "California Institute of Technology": 9,
    "Johns Hopkins University": 10,
    "Yale University": 11,
    "University College London": 12,
    "Imperial College London": 13,
    "University of California, Los Angeles": 14,
    "University of Pennsylvania": 15,
    "Princeton University": 16,
    "University of Toronto": 18,
    "University of Michigan–Ann Arbor": 19,
    "University of California, San Diego": 20,
    "Cornell University": 21,
    "Tsinghua University": 23,
    "Northwestern University": 24,
    "Duke University": 25,
    "University of Melbourne": 27,
    "University of Sydney": 28,
    "ETH Zurich": 29,
    "Nanyang Technological University": 30,
    "New York University": 31,
    "Washington University in St. Louis": 32,
    "King's College London": 33,
    "University of Edinburgh": 34,
    "University of British Columbia": 35,
    "University of Queensland": 36,
    "Monash University": 37,
    "Peking University": 39,
    "University of Amsterdam": 39,
    "University of North Carolina at Chapel Hill": 41,
    "University of Copenhagen": 42,
    "University of Texas at Austin": 43,
    "Utrecht University": 44,
    "University of Pittsburgh": 45,
    "LMU Munich": 47,
    "Sorbonne University": 48,
    "KU Leuven": 50,
    "Georgia Institute of Technology": 51,
    "Karolinska Institute": 51,
    "Chinese University of Hong Kong": 53,
    # Page 2 (54-112)
    "McGill University": 54,
    "University of Hong Kong": 55,
    "Heidelberg University": 57,
    "University of Maryland, College Park": 57,
    "University of Minnesota–Twin Cities": 57,
    "Humboldt University of Berlin": 61,
    "Australian National University": 62,
    "University of Manchester": 63,
    "University of Wisconsin–Madison": 63,
    "Erasmus University Rotterdam": 65,
    "University of California, Santa Barbara": 67,
    "University of Zurich": 67,
    "EPFL": 69,
    "Boston University": 70,
    "University of Colorado Boulder": 70,
    "Emory University": 72,
    "University of California, Davis": 73,
    "Leiden University": 74,
    "University of Glasgow": 74,
    "University of Illinois Urbana-Champaign": 74,
    "Vanderbilt University": 78,
    "University of Southern California": 80,
    "University of Western Australia": 83,
    "Pennsylvania State University": 84,
    "University of California, Irvine": 84,
    "University of Barcelona": 86,
    "Free University of Berlin": 87,
    "University of Groningen": 88,
    "Shanghai Jiao Tong University": 89,
    "University of Birmingham": 89,
    "University of Oslo": 89,
    "Wageningen University & Research": 89,
    "University of Bristol": 93,
    "Ghent University": 95,
    "HKUST": 95,
    "University of Helsinki": 99,
    "Hong Kong Polytechnic University": 100,
    "Queen Mary University of London": 100,
    "University of Southampton": 104,
    "University of Bern": 107,
    "University of Arizona": 108,
    "Aarhus University": 109,
    "Huazhong University of Science and Technology": 109,
    "University of Geneva": 109,
    "Lund University": 112,
    # Page 3 (112-175)
    "University of Technology Sydney": 112,
    "Fudan University": 116,
    "Michigan State University": 116,
    "Carnegie Mellon University": 118,
    "University of Virginia": 119,
    "University of Bologna": 122,
    "University of Auckland": 123,
    "Sapienza University of Rome": 125,
    "Stockholm University": 127,
    "Uppsala University": 127,
    "Brown University": 129,
    "Sun Yat-sen University": 129,
    "University of Sheffield": 134,
    "McMaster University": 138,
    "Kyoto University": 140,
    "Purdue University": 140,
    "Texas A&M University": 148,
    "University of Basel": 150,
    "Cardiff University": 152,
    "Case Western Reserve University": 152,
    "Indiana University Bloomington": 152,
    "University of Exeter": 152,
    "Newcastle University": 156,
    "Curtin University": 160,
    "University of Massachusetts Amherst": 160,
    "University of Warwick": 163,
    "Technical University of Denmark": 165,
    "University of Rochester": 170,
    "Queensland University of Technology": 171,
    "Tel Aviv University": 175,
    "University of Sussex": 175,
    # Page 4 (178-226)
    "University of Wollongong": 186,
    "University of Waterloo": 191,
    "Macquarie University": 192,
    "Harbin Institute of Technology": 196,
    "Tongji University": 196,
    "National Taiwan University": 203,
    "Griffith University": 203,
    "University of Vienna": 208,
    "RMIT University": 209,
    "Trinity College Dublin": 215,
    "Deakin University": 217,
    "South China University of Technology": 219,
    "Xi'an Jiaotong University": 219,
    "Beihang University": 253,
    "University of Lisbon": 202,
    # Page 5 (226-282)
    "Beijing Normal University": 269,
    "Seoul National University": 129,   # from page 3 context — actually not listed; add separately if found
}

# Fix: Seoul National University was in 2023 page 3 at 129. For 2022 it's not explicitly visible
# in our 5 pages. Remove it to be safe and only include confirmed entries.
del USNEWS_2022["Seoul National University"]

def main():
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    col = "rankUSNews_2022"
    if col not in fieldnames:
        print(f"ERROR: column '{col}' not found")
        sys.exit(1)

    updated = 0
    unchanged = 0
    not_found = []

    for row in rows:
        name = row["name"]
        if name in USNEWS_2022:
            new_val = str(USNEWS_2022[name])
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
    print(f"  {len(not_found)} universities not matched (rank left unchanged):")
    for n in not_found:
        print(f"    - {n}")

if __name__ == "__main__":
    main()
