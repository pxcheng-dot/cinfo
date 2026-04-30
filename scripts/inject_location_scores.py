#!/usr/bin/env python3
"""
inject_location_scores.py
Adds locationScore to every entry in SupplementalData.swift.

Scoring guide (metro-area population / centrality, 0-100):
  95-100  Major global megacities (NYC, London central, Tokyo, Shanghai, Beijing, Paris)
  85-94   Top regional cities (LA, Bay Area, Chicago, Seoul, Singapore, Hong Kong,
          Sydney/Melbourne CBD, DC, Osaka)
  75-84   Large metro (Boston, Berlin, Toronto, Houston, Atlanta, Zurich area,
          Munich, Stockholm, Copenhagen, Helsinki)
  60-74   Medium cities (Pittsburgh, Nashville, Edinburgh, Manchester, Brisbane,
          Vienna, Amsterdam, Baltimore, New Haven, Dublin, Kyoto)
  45-59   Smaller cities / semi-rural (Ann Arbor, Madison, Adelaide, Canberra,
          Lausanne, Bern, Lund, Uppsala, Geneva, Bologna, Padua)
  20-44   College towns / small cities (Princeton, Oxford, Cambridge UK, Ithaca,
          Hanover, South Bend, St Andrews, Wageningen)
"""

import re
import sys

LOCATION_SCORES = {
    # ── USA ──────────────────────────────────────────────────────────────────
    "Massachusetts Institute of Technology":   82,  # Cambridge MA, Boston metro 4.9M
    "Harvard University":                      82,  # Cambridge MA
    "Stanford University":                     88,  # Palo Alto, Bay Area 7.7M
    "California Institute of Technology":      90,  # Pasadena, LA metro 13M
    "Princeton University":                    38,  # Princeton NJ, 30k pop; near NYC/Philly
    "Yale University":                         58,  # New Haven, metro 570k
    "Columbia University":                    100,  # Morningside Heights, NYC
    "University of Pennsylvania":              78,  # Philadelphia metro 6.2M
    "Johns Hopkins University":                70,  # Baltimore metro 2.9M
    "Carnegie Mellon University":              65,  # Pittsburgh metro 2.4M
    "University of Chicago":                   92,  # Hyde Park, Chicago metro 9.5M
    "University of Michigan\u2013Ann Arbor":   60,  # Ann Arbor (Detroit metro, college-town feel)
    "Duke University":                         50,  # Durham NC, Research Triangle 1.9M
    "Northwestern University":                 90,  # Evanston, Chicago metro
    "Cornell University":                      28,  # Ithaca NY, metro 102k
    "New York University":                    100,  # Greenwich Village, NYC
    "Brown University":                        60,  # Providence RI, metro 1.6M
    "Dartmouth College":                       18,  # Hanover NH, metro 84k (very rural)
    "Rice University":                         82,  # Houston metro 7.3M
    "Vanderbilt University":                   65,  # Nashville metro 2.1M
    "Washington University in St. Louis":      65,  # St. Louis metro 2.8M
    "Emory University":                        82,  # Atlanta metro 6.3M
    "University of Notre Dame":                35,  # South Bend IN, metro 320k
    "Georgetown University":                   85,  # Washington DC metro 6.4M
    "Tufts University":                        80,  # Medford MA, Boston metro
    "Case Western Reserve University":         62,  # Cleveland metro 2.1M
    "University of Southern California":       92,  # Los Angeles
    "Boston University":                       82,  # Boston
    "Georgia Institute of Technology":         82,  # Atlanta metro 6.3M
    "University of California, Berkeley":      88,  # Bay Area
    "University of California, Los Angeles":   92,  # Los Angeles
    "University of California, San Diego":     78,  # San Diego metro 3.3M
    "University of California, Santa Barbara": 48,  # Santa Barbara metro 450k
    "University of California, Davis":         55,  # Davis, Sacramento metro 2.4M
    "University of California, Irvine":        88,  # Orange County, LA metro
    "University of Virginia":                  42,  # Charlottesville VA, metro 220k
    "University of North Carolina at Chapel Hill": 52, # Chapel Hill, Research Triangle
    "University of Pittsburgh":                65,  # Pittsburgh metro 2.4M
    "University of Rochester":                 58,  # Rochester NY metro 1.2M
    "University of Massachusetts Amherst":     40,  # Amherst MA, metro 310k
    "North Carolina State University":         60,  # Raleigh, Research Triangle
    "University of Washington":                85,  # Seattle metro 4.0M
    "Ohio State University":                   65,  # Columbus metro 2.1M
    "Pennsylvania State University":           30,  # State College PA, metro 165k
    "Michigan State University":               52,  # East Lansing, Lansing metro 560k
    "Indiana University Bloomington":          35,  # Bloomington IN, metro 170k
    "Texas A&M University":                    35,  # College Station TX, metro 265k
    "University of Texas at Austin":           72,  # Austin metro 2.3M
    "Purdue University":                       35,  # West Lafayette IN, metro 225k
    "University of Illinois Urbana-Champaign": 38,  # Champaign-Urbana, metro 230k
    "University of Maryland, College Park":    80,  # DC metro, 15mi from city
    "University of Minnesota\u2013Twin Cities":75,  # Minneapolis metro 3.7M
    "University of Wisconsin\u2013Madison":    55,  # Madison WI, metro 680k
    "University of Florida":                   38,  # Gainesville FL, metro 330k
    "University of Colorado Boulder":          68,  # Boulder, Denver metro 2.9M
    "University of Arizona":                   58,  # Tucson metro 1.1M
    "Arizona State University":                80,  # Phoenix metro 5.1M

    # ── UK ───────────────────────────────────────────────────────────────────
    "University of Oxford":                    42,  # Oxford, metro 160k (60mi from London)
    "University of Cambridge":                 42,  # Cambridge, metro 125k (60mi from London)
    "Imperial College London":                 97,  # South Kensington, London metro 14.8M
    "University College London":               97,  # Bloomsbury, London
    "University of Edinburgh":                 60,  # Edinburgh metro 530k
    "University of Manchester":                72,  # Manchester metro 3.4M
    "King's College London":                   97,  # Strand, London
    "London School of Economics":              97,  # Aldwych, London
    "University of Bristol":                   60,  # Bristol metro 700k
    "University of Glasgow":                   62,  # Glasgow metro 1.0M
    "University of Sheffield":                 58,  # Sheffield metro 750k
    "University of Birmingham":                72,  # Birmingham metro 2.9M
    "University of Leeds":                     68,  # Leeds metro 1.9M
    "University of Warwick":                   50,  # Coventry metro 400k
    "University of Nottingham":                60,  # Nottingham metro 830k
    "University of Southampton":               58,  # Southampton metro 650k
    "University of Liverpool":                 62,  # Liverpool metro 1.0M
    "Queen Mary University of London":         95,  # Mile End, London
    "Durham University":                       42,  # Durham metro 250k
    "University of St Andrews":                20,  # St Andrews, metro 18k
    "Newcastle University":                    62,  # Newcastle metro 1.0M
    "University of York":                      42,  # York, metro 210k
    "Lancaster University":                    38,  # Lancaster, metro 140k
    "University of Exeter":                    38,  # Exeter, metro 130k
    "Cardiff University":                      55,  # Cardiff metro 480k
    "University of Bath":                      50,  # Bath metro 100k (near Bristol)
    "University of Reading":                   62,  # Reading metro 340k (near London)
    "Loughborough University":                 35,  # Loughborough, metro 70k
    "Queen's University Belfast":              60,  # Belfast metro 680k

    # ── Australia ────────────────────────────────────────────────────────────
    "University of Melbourne":                 85,  # Melbourne metro 5.1M
    "University of New South Wales":           87,  # Sydney metro 5.3M
    "University of Sydney":                    87,  # Sydney
    "Australian National University":          50,  # Canberra metro 420k
    "University of Queensland":                72,  # Brisbane metro 2.5M
    "Monash University":                       83,  # Melbourne metro (Clayton)
    "University of Adelaide":                  62,  # Adelaide metro 1.4M
    "University of Western Australia":         65,  # Perth metro 2.1M
    "Queensland University of Technology":     72,  # Brisbane metro 2.5M
    "Macquarie University":                    85,  # Sydney metro (North Ryde)
    "University of Newcastle":                 52,  # Newcastle NSW metro 450k
    "University of Wollongong":                58,  # Wollongong metro 300k
    "Deakin University":                       75,  # Melbourne metro (Geelong/Burwood)
    "La Trobe University":                     82,  # Melbourne metro (Bundoora)
    "Curtin University":                       65,  # Perth metro
    "RMIT University":                         87,  # Melbourne CBD
    "University of Technology Sydney":         87,  # Sydney CBD

    # ── New Zealand ───────────────────────────────────────────────────────────
    "University of Otago":                     40,  # Dunedin, metro 125k
    "University of Auckland":                  68,  # Auckland metro 1.7M

    # ── Singapore ────────────────────────────────────────────────────────────
    "National University of Singapore":        92,  # Singapore (global hub, 5.9M)
    "Nanyang Technological University":        92,  # Singapore

    # ── Canada ───────────────────────────────────────────────────────────────
    "University of Toronto":                   87,  # Toronto metro 6.4M
    "McGill University":                       82,  # Montreal metro 4.3M
    "University of British Columbia":          80,  # Vancouver metro 2.8M
    "McMaster University":                     65,  # Hamilton, Toronto metro area
    "University of Alberta":                   62,  # Edmonton metro 1.4M
    "University of Waterloo":                  55,  # Kitchener-Waterloo metro 590k
    "Queen's University":                      42,  # Kingston ON, metro 173k
    "Western University":                      55,  # London ON, metro 550k

    # ── Ireland ───────────────────────────────────────────────────────────────
    "University College Dublin":               75,  # Dublin metro 1.3M
    "Trinity College Dublin":                  78,  # Dublin city centre

    # ── China ────────────────────────────────────────────────────────────────
    "Tsinghua University":                     97,  # Beijing metro 22M
    "Peking University":                       97,  # Beijing
    "Fudan University":                        98,  # Shanghai metro 26M
    "Shanghai Jiao Tong University":           98,  # Shanghai
    "Zhejiang University":                     82,  # Hangzhou metro 8.0M
    "Nanjing University":                      82,  # Nanjing metro 9.0M
    "University of Science and Technology of China": 78, # Hefei metro 8.0M
    "Harbin Institute of Technology":          72,  # Harbin metro 5.3M
    "Tongji University":                       98,  # Shanghai
    "Wuhan University":                        87,  # Wuhan metro 12.0M
    "Beijing Normal University":               97,  # Beijing
    "Beijing Institute of Technology":         97,  # Beijing
    "Sun Yat-sen University":                  95,  # Guangzhou metro 18.0M
    "Huazhong University of Science and Technology": 87, # Wuhan
    "Shandong University":                     80,  # Jinan metro 8.5M
    "South China University of Technology":    95,  # Guangzhou
    "Beihang University":                      97,  # Beijing
    "Xi\u2019an Jiaotong University":          80,  # Xi'an metro 8.5M

    # ── Hong Kong ────────────────────────────────────────────────────────────
    "University of Hong Kong":                 93,  # HK metro 7.5M
    "Chinese University of Hong Kong":         90,  # Shatin, HK
    "HKUST":                                   88,  # Clear Water Bay, HK
    "Hong Kong Polytechnic University":        92,  # Hung Hom, HK
    "City University of Hong Kong":            92,  # Kowloon, HK
    "Hong Kong Baptist University":            90,  # Kowloon Tong, HK

    # ── Japan ────────────────────────────────────────────────────────────────
    "University of Tokyo":                     98,  # Hongo, Tokyo metro 37M
    "Kyoto University":                        72,  # Kyoto metro 2.7M
    "Osaka University":                        95,  # Osaka metro 19M
    "Tohoku University":                       62,  # Sendai metro 1.1M
    "Nagoya University":                       82,  # Nagoya metro 5.5M
    "Tokyo Institute of Technology":           98,  # Tokyo
    "Keio University":                         98,  # Tokyo (Shinjuku/Mita)
    "Waseda University":                       98,  # Tokyo (Shinjuku)
    "Kyushu University":                       72,  # Fukuoka metro 2.5M
    "Hokkaido University":                     72,  # Sapporo metro 2.5M

    # ── Korea ────────────────────────────────────────────────────────────────
    "Seoul National University":               97,  # Seoul metro 25M
    "KAIST":                                   65,  # Daejeon metro 1.5M
    "POSTECH":                                 48,  # Pohang metro 510k
    "Korea University":                        97,  # Seoul
    "Yonsei University":                       97,  # Seoul
    "Sungkyunkwan University":                 95,  # Seoul/Suwon

    # ── Taiwan ───────────────────────────────────────────────────────────────
    "National Taiwan University":              88,  # Taipei metro 7.0M

    # ── Switzerland ──────────────────────────────────────────────────────────
    "ETH Zurich":                              72,  # Zurich metro 1.4M
    "EPFL":                                    52,  # Lausanne metro 420k
    "University of Zurich":                    72,  # Zurich
    "University of Bern":                      52,  # Bern metro 430k
    "University of Geneva":                    58,  # Geneva metro 600k
    "University of Basel":                     60,  # Basel metro 830k

    # ── Germany ──────────────────────────────────────────────────────────────
    "LMU Munich":                              78,  # Munich metro 2.8M
    "Technical University of Munich":          78,  # Munich
    "Heidelberg University":                   45,  # Heidelberg metro 155k
    "University of Hamburg":                   72,  # Hamburg metro 1.8M
    "University of Bonn":                      65,  # Bonn metro 600k (near Cologne 3.5M)
    "RWTH Aachen University":                  52,  # Aachen metro 260k
    "Technical University of Berlin":          82,  # Berlin metro 3.5M
    "Humboldt University of Berlin":           82,  # Berlin
    "Free University of Berlin":               80,  # Dahlem, Berlin
    "Karlsruhe Institute of Technology":       58,  # Karlsruhe metro 600k

    # ── France ───────────────────────────────────────────────────────────────
    "PSL University":                          97,  # Paris metro 12.5M
    "Institut Polytechnique de Paris":         85,  # Palaiseau, 30km from Paris centre
    "Sorbonne University":                     97,  # Paris
    "Universit\u00e9 Paris-Saclay":            82,  # Orsay/Saclay, ~20km from Paris

    # ── Netherlands ──────────────────────────────────────────────────────────
    "University of Amsterdam":                 75,  # Amsterdam metro 1.1M
    "Leiden University":                       50,  # Leiden metro 125k (Randstad)
    "Delft University of Technology":          72,  # Delft, Randstad metro 8M
    "University of Groningen":                 48,  # Groningen metro 230k
    "Wageningen University & Research":        28,  # Wageningen, metro 38k (rural)
    "Erasmus University Rotterdam":            68,  # Rotterdam metro 1.0M
    "Utrecht University":                      58,  # Utrecht metro 370k
    "Eindhoven University of Technology":      55,  # Eindhoven metro 400k

    # ── Scandinavia ──────────────────────────────────────────────────────────
    "KTH Royal Institute of Technology":       78,  # Stockholm metro 2.4M
    "Lund University":                         50,  # Lund metro 120k (near Malmö)
    "Stockholm University":                    78,  # Stockholm
    "Uppsala University":                      45,  # Uppsala metro 200k (70km from Stockholm)
    "Chalmers University of Technology":       65,  # Gothenburg metro 1.0M
    "University of Copenhagen":                75,  # Copenhagen metro 1.3M
    "Aarhus University":                       55,  # Aarhus metro 360k
    "Technical University of Denmark":         73,  # Kongens Lyngby, Copenhagen metro
    "University of Oslo":                      68,  # Oslo metro 1.0M
    "Aalto University":                        78,  # Espoo, Helsinki metro 1.5M
    "University of Helsinki":                  78,  # Helsinki

    # ── Belgium ──────────────────────────────────────────────────────────────
    "KU Leuven":                               55,  # Leuven metro 100k (30km from Brussels 2.1M)
    "Ghent University":                        52,  # Ghent metro 280k

    # ── Italy ────────────────────────────────────────────────────────────────
    "University of Bologna":                   65,  # Bologna metro 1.0M
    "Sapienza University of Rome":             88,  # Rome metro 4.2M
    "University of Padova":                    60,  # Padua metro 930k
    "Politecnico di Milano":                   85,  # Milan metro 3.5M

    # ── Spain ────────────────────────────────────────────────────────────────
    "University of Barcelona":                 90,  # Barcelona metro 5.6M
    "Autonomous University of Madrid":         92,  # Madrid metro 6.9M
    "Complutense University of Madrid":        92,  # Madrid

    # ── Austria ──────────────────────────────────────────────────────────────
    "University of Vienna":                    80,  # Vienna metro 2.6M

    # ── Israel ───────────────────────────────────────────────────────────────
    "Hebrew University of Jerusalem":          60,  # Jerusalem metro 870k
    "Technion \u2013 Israel Institute of Technology": 55, # Haifa metro 500k
    "Tel Aviv University":                     85,  # Tel Aviv metro 4.0M

    # ── Medical / Specialist ─────────────────────────────────────────────────
    "Karolinska Institute":                    78,  # Solna, Stockholm metro
}

def inject_location_scores(path: str) -> None:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Track current university name as we scan line by line.
    lines = content.splitlines(keepends=True)
    result = []
    current_name: str | None = None

    for line in lines:
        # Detect university name line: starts with spaces, then a quoted string, then ":"
        name_match = re.match(r'\s+"([^"]+)":\s*$', line)
        if name_match:
            current_name = name_match.group(1)
            result.append(line)
            continue

        # Detect closing of .init(...) — the line ending with "),\n" or "),"
        if current_name is not None and re.search(r'schoolCount:\s*\d+\s*\)', line):
            score = LOCATION_SCORES.get(current_name)
            if score is not None:
                # Insert locationScore before closing paren
                line = re.sub(
                    r'(schoolCount:\s*\d+)\s*\)',
                    rf'\1, locationScore: {score})',
                    line
                )
            current_name = None

        result.append(line)

    new_content = "".join(result)
    with open(path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("Done — locationScore injected.")

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else \
        "/Users/SarePhil/Desktop/cinfo/cinfo/SupplementalData.swift"
    inject_location_scores(target)
