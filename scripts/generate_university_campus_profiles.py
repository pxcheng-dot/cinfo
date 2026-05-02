#!/usr/bin/env python3
"""Emit cinfo/university_campus_profiles.json — keys must match universities.csv `name` exactly."""

from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "cinfo" / "universities.csv"
OUT_PATH = ROOT / "cinfo" / "university_campus_profiles.json"

# US — main campus city / state (or DC).
US_LOCATION: dict[str, str] = {
    "Massachusetts Institute of Technology": "Cambridge, MA",
    "Stanford University": "Stanford, CA",
    "Harvard University": "Cambridge, MA",
    "California Institute of Technology": "Pasadena, CA",
    "University of Chicago": "Chicago, IL",
    "University of Pennsylvania": "Philadelphia, PA",
    "Cornell University": "Ithaca, NY",
    "University of California, Berkeley": "Berkeley, CA",
    "Yale University": "New Haven, CT",
    "Johns Hopkins University": "Baltimore, MD",
    "Princeton University": "Princeton, NJ",
    "Columbia University": "New York, NY",
    "Northwestern University": "Evanston, IL",
    "University of Michigan–Ann Arbor": "Ann Arbor, MI",
    "University of California, Los Angeles": "Los Angeles, CA",
    "Carnegie Mellon University": "Pittsburgh, PA",
    "New York University": "New York, NY",
    "Duke University": "Durham, NC",
    "University of California, San Diego": "La Jolla, CA",
    "University of Texas at Austin": "Austin, TX",
    "Brown University": "Providence, RI",
    "University of Illinois Urbana-Champaign": "Urbana-Champaign, IL",
    "University of Washington": "Seattle, WA",
    "Pennsylvania State University": "University Park, PA",
    "Boston University": "Boston, MA",
    "Purdue University": "West Lafayette, IN",
    "University of California, Davis": "Davis, CA",
    "University of Wisconsin–Madison": "Madison, WI",
    "Rice University": "Houston, TX",
    "Georgia Institute of Technology": "Atlanta, GA",
    "University of North Carolina at Chapel Hill": "Chapel Hill, NC",
    "Texas A&M University": "College Station, TX",
    "University of Southern California": "Los Angeles, CA",
    "Michigan State University": "East Lansing, MI",
    "Washington University in St. Louis": "St. Louis, MO",
    "University of California, Santa Barbara": "Santa Barbara, CA",
    "Emory University": "Atlanta, GA",
    "Ohio State University": "Columbus, OH",
    "University of Maryland, College Park": "College Park, MD",
    "University of Minnesota–Twin Cities": "Minneapolis–Saint Paul, MN",
    "University of Florida": "Gainesville, FL",
    "University of Rochester": "Rochester, NY",
    "Dartmouth College": "Hanover, NH",
    "University of Massachusetts Amherst": "Amherst, MA",
    "Vanderbilt University": "Nashville, TN",
    "North Carolina State University": "Raleigh, NC",
    "University of Virginia": "Charlottesville, VA",
    "University of Pittsburgh": "Pittsburgh, PA",
    "Georgetown University": "Washington, DC",
    "University of Arizona": "Tucson, AZ",
    "University of California, Irvine": "Irvine, CA",
    "Case Western Reserve University": "Cleveland, OH",
    "University of Notre Dame": "Notre Dame, IN",
    "University of Colorado Boulder": "Boulder, CO",
    "Arizona State University": "Tempe, AZ",
    "Indiana University Bloomington": "Bloomington, IN",
    "Tufts University": "Medford, MA",
}

US_PUBLIC = {
    "University of California, Berkeley",
    "University of California, Los Angeles",
    "University of California, San Diego",
    "University of California, Davis",
    "University of California, Santa Barbara",
    "University of California, Irvine",
    "University of Michigan–Ann Arbor",
    "University of Texas at Austin",
    "University of Illinois Urbana-Champaign",
    "University of Washington",
    "Pennsylvania State University",
    "Purdue University",
    "University of Wisconsin–Madison",
    "Georgia Institute of Technology",
    "University of North Carolina at Chapel Hill",
    "Texas A&M University",
    "Michigan State University",
    "Ohio State University",
    "University of Maryland, College Park",
    "University of Minnesota–Twin Cities",
    "University of Florida",
    "University of Massachusetts Amherst",
    "North Carolina State University",
    "University of Virginia",
    "University of Pittsburgh",
    "University of Arizona",
    "University of Colorado Boulder",
    "Arizona State University",
    "Indiana University Bloomington",
}

# Non‑US — city / region (UK uses England / Scotland / Wales / N. Ireland where helpful).
INT_PROFILE: dict[str, tuple[str, str]] = {
    # United Kingdom — public research universities
    "Imperial College London": ("London, England", "public"),
    "University of Oxford": ("Oxford, England", "public"),
    "University of Cambridge": ("Cambridge, England", "public"),
    "University College London": ("London, England", "public"),
    "King's College London": ("London, England", "public"),
    "University of Edinburgh": ("Edinburgh, Scotland", "public"),
    "University of Manchester": ("Manchester, England", "public"),
    "University of Bristol": ("Bristol, England", "public"),
    "London School of Economics": ("London, England", "public"),
    "University of Warwick": ("Coventry, England", "public"),
    "University of Birmingham": ("Birmingham, England", "public"),
    "University of Glasgow": ("Glasgow, Scotland", "public"),
    "University of Leeds": ("Leeds, England", "public"),
    "University of Southampton": ("Southampton, England", "public"),
    "University of Sheffield": ("Sheffield, England", "public"),
    "Durham University": ("Durham, England", "public"),
    "University of Nottingham": ("Nottingham, England", "public"),
    "Queen Mary University of London": ("London, England", "public"),
    "University of St Andrews": ("St Andrews, Scotland", "public"),
    "University of Bath": ("Bath, England", "public"),
    "Newcastle University": ("Newcastle upon Tyne, England", "public"),
    "University of Liverpool": ("Liverpool, England", "public"),
    "University of Exeter": ("Exeter, England", "public"),
    "Lancaster University": ("Lancaster, England", "public"),
    "University of York": ("York, England", "public"),
    "Cardiff University": ("Cardiff, Wales", "public"),
    "University of Reading": ("Reading, England", "public"),
    "Queen's University Belfast": ("Belfast, Northern Ireland", "public"),
    "Loughborough University": ("Loughborough, England", "public"),
    # Australia — public
    "University of Melbourne": ("Melbourne, Victoria", "public"),
    "University of New South Wales": ("Sydney, New South Wales", "public"),
    "University of Sydney": ("Sydney, New South Wales", "public"),
    "Australian National University": ("Canberra, Australian Capital Territory", "public"),
    "Monash University": ("Melbourne, Victoria", "public"),
    "University of Queensland": ("Brisbane, Queensland", "public"),
    "University of Western Australia": ("Perth, Western Australia", "public"),
    "University of Adelaide": ("Adelaide, South Australia", "public"),
    "University of Technology Sydney": ("Sydney, New South Wales", "public"),
    "University of Newcastle": ("Newcastle, New South Wales", "public"),
    "University of Wollongong": ("Wollongong, New South Wales", "public"),
    "Queensland University of Technology": ("Brisbane, Queensland", "public"),
    "La Trobe University": ("Melbourne, Victoria", "public"),
    "Deakin University": ("Geelong, Victoria", "public"),
    # Australian mixed / public status — Macquarie, Curtin, RMIT often described as public universities
    "RMIT University": ("Melbourne, Victoria", "public"),
    "Macquarie University": ("Sydney, New South Wales", "public"),
    "Curtin University": ("Perth, Western Australia", "public"),
    # Singapore — public autonomous universities
    "National University of Singapore": ("Singapore", "public"),
    "Nanyang Technological University": ("Singapore", "public"),
    # Canada — public
    "McGill University": ("Montreal, Quebec", "public"),
    "University of Toronto": ("Toronto, Ontario", "public"),
    "University of British Columbia": ("Vancouver, British Columbia", "public"),
    "University of Alberta": ("Edmonton, Alberta", "public"),
    "University of Waterloo": ("Waterloo, Ontario", "public"),
    "McMaster University": ("Hamilton, Ontario", "public"),
    "Western University": ("London, Ontario", "public"),
    "Queen's University": ("Kingston, Ontario", "public"),
    # China — public
    "Peking University": ("Beijing", "public"),
    "Tsinghua University": ("Beijing", "public"),
    "Fudan University": ("Shanghai", "public"),
    "Zhejiang University": ("Hangzhou", "public"),
    "Shanghai Jiao Tong University": ("Shanghai", "public"),
    "University of Science and Technology of China": ("Hefei", "public"),
    "Nanjing University": ("Nanjing", "public"),
    "Tongji University": ("Shanghai", "public"),
    "Wuhan University": ("Wuhan", "public"),
    "Beijing Normal University": ("Beijing", "public"),
    "Harbin Institute of Technology": ("Harbin", "public"),
    "Beijing Institute of Technology": ("Beijing", "public"),
    "Sun Yat-sen University": ("Guangzhou", "public"),
    "Xi'an Jiaotong University": ("Xi'an", "public"),
    "Huazhong University of Science and Technology": ("Wuhan", "public"),
    "Shandong University": ("Jinan", "public"),
    "South China University of Technology": ("Guangzhou", "public"),
    "Beihang University": ("Beijing", "public"),
    # Switzerland — public / cantonal
    "ETH Zurich": ("Zurich", "public"),
    "EPFL": ("Lausanne", "public"),
    "University of Zurich": ("Zurich", "public"),
    "University of Geneva": ("Geneva", "public"),
    "University of Basel": ("Basel", "public"),
    "University of Bern": ("Bern", "public"),
    # Germany — public
    "Technical University of Munich": ("Munich", "public"),
    "LMU Munich": ("Munich", "public"),
    "Heidelberg University": ("Heidelberg", "public"),
    "Free University of Berlin": ("Berlin", "public"),
    "Karlsruhe Institute of Technology": ("Karlsruhe", "public"),
    "RWTH Aachen University": ("Aachen", "public"),
    "Humboldt University of Berlin": ("Berlin", "public"),
    "University of Bonn": ("Bonn", "public"),
    "Technical University of Berlin": ("Berlin", "public"),
    "University of Hamburg": ("Hamburg", "public"),
    # France — public
    "PSL University": ("Paris", "public"),
    "Université Paris-Saclay": ("Paris-Saclay", "public"),
    "Sorbonne University": ("Paris", "public"),
    "Institut Polytechnique de Paris": ("Palaiseau", "public"),
    # Netherlands — public
    "Delft University of Technology": ("Delft", "public"),
    "University of Amsterdam": ("Amsterdam", "public"),
    "Utrecht University": ("Utrecht", "public"),
    "Leiden University": ("Leiden", "public"),
    "Wageningen University & Research": ("Wageningen", "public"),
    "Eindhoven University of Technology": ("Eindhoven", "public"),
    "Erasmus University Rotterdam": ("Rotterdam", "public"),
    "University of Groningen": ("Groningen", "public"),
    # Sweden — public
    "Karolinska Institute": ("Stockholm", "public"),
    "Lund University": ("Lund", "public"),
    "KTH Royal Institute of Technology": ("Stockholm", "public"),
    "Uppsala University": ("Uppsala", "public"),
    "Stockholm University": ("Stockholm", "public"),
    "Chalmers University of Technology": ("Gothenburg", "public"),
    # Denmark — public
    "University of Copenhagen": ("Copenhagen", "public"),
    "Aarhus University": ("Aarhus", "public"),
    "Technical University of Denmark": ("Kongens Lyngby", "public"),
    # Belgium — public (KU Leuven Catholic but state-funded; commonly classed public HE)
    "KU Leuven": ("Leuven", "public"),
    "Ghent University": ("Ghent", "public"),
    # Norway / Finland / Austria / Ireland — public
    "University of Oslo": ("Oslo", "public"),
    "Aalto University": ("Espoo", "public"),
    "University of Helsinki": ("Helsinki", "public"),
    "University of Vienna": ("Vienna", "public"),
    "Trinity College Dublin": ("Dublin", "public"),
    "University College Dublin": ("Dublin", "public"),
    # Italy — public
    "Politecnico di Milano": ("Milan", "public"),
    "Sapienza University of Rome": ("Rome", "public"),
    "University of Bologna": ("Bologna", "public"),
    "University of Padova": ("Padua", "public"),
    # Spain — public
    "University of Barcelona": ("Barcelona", "public"),
    "Complutense University of Madrid": ("Madrid", "public"),
    "Autonomous University of Madrid": ("Madrid", "public"),
    # Hong Kong — public / government-funded
    "University of Hong Kong": ("Hong Kong", "public"),
    "Chinese University of Hong Kong": ("Hong Kong", "public"),
    "HKUST": ("Hong Kong", "public"),
    "Hong Kong Polytechnic University": ("Hong Kong", "public"),
    "City University of Hong Kong": ("Hong Kong", "public"),
    "Hong Kong Baptist University": ("Hong Kong", "public"),
    # Japan — national / private
    "University of Tokyo": ("Tokyo", "public"),
    "Kyoto University": ("Kyoto", "public"),
    "Osaka University": ("Osaka", "public"),
    "Tokyo Institute of Technology": ("Tokyo", "public"),
    "Tohoku University": ("Sendai", "public"),
    "Nagoya University": ("Nagoya", "public"),
    "Hokkaido University": ("Sapporo", "public"),
    "Kyushu University": ("Fukuoka", "public"),
    "Waseda University": ("Tokyo", "private"),
    "Keio University": ("Tokyo", "private"),
    # South Korea — national / private
    "Seoul National University": ("Seoul", "public"),
    "KAIST": ("Daejeon", "public"),
    "POSTECH": ("Pohang", "public"),
    "Yonsei University": ("Seoul", "private"),
    "Korea University": ("Seoul", "private"),
    "Sungkyunkwan University": ("Seoul", "private"),
    # Taiwan — public
    "National Taiwan University": ("Taipei", "public"),
    # New Zealand — public
    "University of Auckland": ("Auckland", "public"),
    "University of Otago": ("Dunedin", "public"),
    # Israel — public / research
    "Hebrew University of Jerusalem": ("Jerusalem", "public"),
    "Tel Aviv University": ("Tel Aviv", "public"),
    "Technion – Israel Institute of Technology": ("Haifa", "public"),
}


def main() -> None:
    with CSV_PATH.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    names = [r["name"] for r in rows]

    out: dict[str, dict[str, str]] = {}
    missing_loc: list[str] = []

    for name in names:
        country = next(r["country"] for r in rows if r["name"] == name)
        if country == "United States":
            loc = US_LOCATION.get(name)
            if loc is None:
                missing_loc.append(name)
                continue
            own = "public" if name in US_PUBLIC else "private"
        else:
            pair = INT_PROFILE.get(name)
            if pair is None:
                missing_loc.append(name)
                continue
            loc, own = pair
        out[name] = {"location": loc, "ownership": own}

    if missing_loc:
        raise SystemExit(f"Missing campus profile for:\n" + "\n".join(missing_loc))

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(out)} profiles to {OUT_PATH}")


if __name__ == "__main__":
    main()
