#!/usr/bin/env python3
"""
Update only rankUSNews_2025 in universities.csv using data
scraped from xuanxiao.org/en/rankings/usnews/global-rankings/2025 pages 1-5.
All other columns are left untouched.
"""

import csv, sys, os

CSV_PATH = os.path.join(os.path.dirname(__file__), "../cinfo/universities.csv")

USNEWS_2025 = {
    # Page 1 (1-50)
    "Harvard University": 1,
    "Massachusetts Institute of Technology": 2,
    "Stanford University": 3,
    "University of Oxford": 4,
    "University of California, Berkeley": 5,
    "University of Cambridge": 6,
    "University of Washington": 7,
    "University College London": 7,
    "Columbia University": 9,
    "Yale University": 10,
    "University of California, Los Angeles": 11,
    "Imperial College London": 12,
    "Johns Hopkins University": 13,
    "University of Pennsylvania": 14,
    "Princeton University": 18,
    "Cornell University": 19,
    "University of Michigan–Ann Arbor": 19,
    "Tsinghua University": 16,
    "University of Toronto": 17,
    "University of California, San Diego": 21,
    "California Institute of Technology": 23,
    "Northwestern University": 24,
    "University of Chicago": 25,
    "Duke University": 26,
    "University of Melbourne": 27,
    "Nanyang Technological University": 27,
    "University of Sydney": 29,
    "Washington University in St. Louis": 30,
    "Peking University": 31,
    "New York University": 32,
    "University of Amsterdam": 33,
    "ETH Zurich": 33,
    "Monash University": 35,
    "King's College London": 36,
    "University of New South Wales": 36,
    "University of Edinburgh": 38,
    "University of British Columbia": 39,
    "University of Queensland": 41,
    "Chinese University of Hong Kong": 42,
    "University of Hong Kong": 44,
    "University of Copenhagen": 44,
    "Utrecht University": 46,
    "University of North Carolina at Chapel Hill": 47,
    "Humboldt University of Berlin": 48,
    "KU Leuven": 48,
    "University of Pittsburgh": 50,
    # Page 2 (51-100)
    "Karolinska Institute": 51,
    "Zhejiang University": 51,
    "LMU Munich": 53,
    "Shanghai Jiao Tong University": 54,
    "Heidelberg University": 55,
    "Leiden University": 56,
    "University of Texas at Austin": 56,
    "McGill University": 56,
    "Sorbonne University": 56,
    "University of Zurich": 60,
    "Ohio State University": 61,
    "University of Glasgow": 61,
    "University of Minnesota–Twin Cities": 63,
    "Emory University": 63,
    "Vanderbilt University": 63,
    "Free University of Berlin": 66,
    "Hong Kong Polytechnic University": 67,
    "University of Manchester": 67,
    "Georgia Institute of Technology": 70,
    "Erasmus University Rotterdam": 70,
    "University of Maryland, College Park": 72,
    "Boston University": 73,
    "University of Wisconsin–Madison": 74,
    "Université Paris-Saclay": 76,
    "University of Groningen": 76,
    "University of Southern California": 79,
    "University of Barcelona": 79,
    "Technical University of Munich": 82,
    "University of Science and Technology of China": 82,
    "University of Tokyo": 84,
    "Australian National University": 85,
    "University of Technology Sydney": 85,
    "Fudan University": 85,
    "EPFL": 88,
    "University of California, Davis": 89,
    "University of California, Santa Barbara": 89,
    "University of Western Australia": 91,
    "Queen Mary University of London": 92,
    "University of Adelaide": 92,
    "University of Birmingham": 94,
    "Pennsylvania State University": 96,
    "University of Bristol": 96,
    "University of Colorado Boulder": 98,
    "Nanjing University": 98,
    "University of California, Irvine": 100,
    # Page 3 (100-150)
    "University of Illinois Urbana-Champaign": 100,
    "Huazhong University of Science and Technology": 100,
    "University of Oslo": 104,
    "HKUST": 105,
    "Sun Yat-sen University": 106,
    "Wuhan University": 108,
    "Ghent University": 109,
    "University of Bern": 111,
    "PSL University": 112,
    "University of Helsinki": 113,
    "Wageningen University & Research": 113,
    "University of Arizona": 115,
    "Aarhus University": 117,
    "University of Geneva": 119,
    "University of Exeter": 122,
    "Michigan State University": 123,
    "University of Southampton": 123,
    "Lund University": 125,
    "University of Virginia": 125,
    "McMaster University": 127,
    "University of Padova": 130,
    "University of Bologna": 130,
    "University of Auckland": 132,
    "Carnegie Mellon University": 134,
    "Indiana University Bloomington": 135,
    "Seoul National University": 135,
    "University of Liverpool": 137,
    "Sapienza University of Rome": 140,
    "University of Leeds": 141,
    "University of Alberta": 150,
    # Page 4 (150-201)
    "Uppsala University": 150,
    "Brown University": 153,
    "Stockholm University": 153,
    "Tongji University": 153,
    "University of Bonn": 157,
    "University of Sheffield": 160,
    "Case Western Reserve University": 160,
    "Harbin Institute of Technology": 160,
    "Curtin University": 164,
    "Purdue University": 167,
    "Kyoto University": 168,
    "University of Basel": 168,
    "Texas A&M University": 171,
    "University of Warwick": 172,
    "University of Massachusetts Amherst": 175,
    "Deakin University": 177,
    "Tel Aviv University": 177,
    "Xi'an Jiaotong University": 179,
    "Beijing Institute of Technology": 179,
    "Cardiff University": 184,
    "Queensland University of Technology": 184,
    "Technical University of Denmark": 184,
    "Delft University of Technology": 187,
    "South China University of Technology": 187,
    "Macquarie University": 192,
    "University of Waterloo": 192,
    "RMIT University": 195,
    "University of Rochester": 199,
    # Page 5 (201-253)
    "University of Wollongong": 204,
    "Yonsei University": 205,
    "Trinity College Dublin": 206,
    "Beijing Normal University": 206,
    "University of Vienna": 215,
    "Newcastle University": 235,
    "London School of Economics": 239,
    "Beihang University": 227,
}

def main():
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    col = "rankUSNews_2025"
    if col not in fieldnames:
        print(f"ERROR: column '{col}' not found")
        sys.exit(1)

    updated = 0
    unchanged = 0
    not_found = []

    for row in rows:
        name = row["name"]
        if name in USNEWS_2025:
            new_val = str(USNEWS_2025[name])
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
    print(f"  {len(not_found)} universities not in 2025 top-250 (rank left unchanged):")
    for n in not_found:
        print(f"    - {n}")

if __name__ == "__main__":
    main()
