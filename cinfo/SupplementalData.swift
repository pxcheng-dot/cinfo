// SupplementalData.swift
// cinfo
//
// Static supplemental data for all 211 covered universities.
//
// Fields
// ──────
// acceptanceRate  Undergraduate acceptance rate (%, 0–100).
//                 US/UK/AU/CA/SG: standard undergraduate acceptance rate.
//                 Chinese top universities: effective admission rate for
//                   competitive applicants via Gaokao (~0.04–0.08 % of
//                   all sitters qualify for top-tier institutions).
//                 European public universities: approximate offer rate
//                   (many operate near-open enrollment, hence 70–90 %).
//
// endowmentBn     Total institutional endowment in USD billions (2024).
//                 Converted from local currency at approximate 2024 rates.
//                 German/French public universities report no formal endowment;
//                   values reflect the closest available financial equivalent.
//
// awardCount      Cumulative count of affiliated Nobel Prize, Fields Medal,
//                 and Turing Award laureates (alumni + faculty, all-time).
//
// studentCount    Total enrolled students (all levels, full + part-time),
//                 approximate as of 2023–2024 academic year.
//
// facultyCount    Full-time equivalent academic faculty (professors, lecturers,
//                 researchers with teaching/research appointments), approx.
//
// schoolCount     Number of degree-granting academic schools, colleges, or
//                 faculties (not individual departments). A technical institute
//                 with 4–6 divisions scores very differently from a mega-
//                 university with 40+ faculties.
//                 Used as the departmental-breadth proxy for the focus score.
//
// Sources: QS World University Rankings, Times Higher Education, Wikipedia,
//          institutional annual reports, Nobel Prize organisation (2023–2024).
//

import Foundation

struct UniversitySupplemental {
    let acceptanceRate: Double?   // % (0–100)
    let endowmentBn:    Double?   // USD billions
    let awardCount:     Int?      // Nobel + Fields + Turing, all-time affiliates
    let studentCount:   Int?      // total enrolled
    let facultyCount:   Int?      // full-time equivalent academic staff
    let schoolCount:    Int?      // number of schools / colleges / faculties
    let locationScore:  Double?   // 0–100, metro-area size / city centrality

    static let unknown = UniversitySupplemental(
        acceptanceRate: nil, endowmentBn: nil, awardCount: nil,
        studentCount: nil,   facultyCount: nil, schoolCount: nil,
        locationScore: nil)
}

enum SupplementalData {

    static func get(_ name: String) -> UniversitySupplemental {
        db[name] ?? .unknown
    }

    // ─────────────────────────────────────────────────────────────────────
    // Data table  (name must match universities.csv exactly)
    // Columns:  acceptanceRate, endowmentBn, awardCount, studentCount,
    //           facultyCount, schoolCount, locationScore
    // ─────────────────────────────────────────────────────────────────────
    static let db: [String: UniversitySupplemental] = [

        // ── United States ─────────────────────────────────────────────────
        // Acceptance rates: class of 2028/2029 actual figures (2024–2025).
        // Endowments: FY2024 from official annual reports.
        // Award counts: Wikipedia "List of Nobel laureates by university affiliation"
        //   using at-announcement affiliation, all-time (as of late 2024).
        "Massachusetts Institute of Technology":
            .init(acceptanceRate: 4.5,  endowmentBn: 24.6, awardCount: 97,
                  studentCount: 11_500,  facultyCount: 1_050, schoolCount: 5, locationScore: 82),
        "Harvard University":
            .init(acceptanceRate: 3.6,  endowmentBn: 53.2, awardCount: 161,
                  studentCount: 21_000,  facultyCount: 2_400, schoolCount: 12, locationScore: 82),
        "Stanford University":
            .init(acceptanceRate: 3.7,  endowmentBn: 37.6, awardCount: 85,
                  studentCount: 17_000,  facultyCount: 2_300, schoolCount: 7, locationScore: 88),
        // Caltech FY2024 endowment $4.1B per NACUBO; 76 total affiliated Nobel laureates (Wikipedia,
        // at-announcement, includes short-term academic visitors; Caltech's own stricter count = 48).
        "California Institute of Technology":
            .init(acceptanceRate: 6.0,  endowmentBn: 4.1,  awardCount: 76,
                  studentCount:  2_400, facultyCount:   310, schoolCount: 6, locationScore: 90),
        // Princeton: 81 affiliated Nobel laureates per Wikipedia Princeton page (Oct 2025).
        "Princeton University":
            .init(acceptanceRate: 4.6,  endowmentBn: 34.1, awardCount: 81,
                  studentCount:  8_500, facultyCount: 1_100, schoolCount: 4, locationScore: 38),
        // Yale FY2024 endowment $41.4B per official Yale report; accept 3.7% class of 2028.
        "Yale University":
            .init(acceptanceRate: 3.7,  endowmentBn: 41.4, awardCount: 65,
                  studentCount: 14_000,  facultyCount: 4_800, schoolCount: 14, locationScore: 58),
        // Columbia FY2024 endowment $14.8B per official Columbia report.
        "Columbia University":
            .init(acceptanceRate: 3.9,  endowmentBn: 14.8, awardCount: 96,
                  studentCount: 36_000,  facultyCount: 4_000, schoolCount: 20, locationScore: 100),
        // Penn FY2024 endowment $22.4B per Wikipedia/NACUBO; accept 5.0% class of 2028/29.
        "University of Pennsylvania":
            .init(acceptanceRate: 5.0,  endowmentBn: 22.4, awardCount: 36,
                  studentCount: 22_000,  facultyCount: 5_200, schoolCount: 12, locationScore: 78),
        // JHU FY2024 endowment $13.1B per NACUBO; 39 Nobel affiliates.
        "Johns Hopkins University":
            .init(acceptanceRate: 7.0,  endowmentBn: 13.1, awardCount: 39,
                  studentCount: 25_000,  facultyCount: 5_400, schoolCount: 10, locationScore: 70),
        // CMU FY2024 endowment $4.0B per NACUBO (not to be confused with the separate Duke Endowment foundation).
        "Carnegie Mellon University":
            .init(acceptanceRate: 15.0, endowmentBn: 4.0,  awardCount: 20,
                  studentCount: 15_000,  facultyCount: 1_400, schoolCount: 8, locationScore: 65),
        // Chicago FY2024 endowment $10.1B per NACUBO.
        "University of Chicago":
            .init(acceptanceRate: 7.0,  endowmentBn: 10.1, awardCount: 100,
                  studentCount: 17_000,  facultyCount: 2_300, schoolCount: 8, locationScore: 92),
        "University of Michigan–Ann Arbor":
            .init(acceptanceRate: 20.0, endowmentBn: 17.0, awardCount: 26,
                  studentCount: 47_000,  facultyCount: 6_800, schoolCount: 19, locationScore: 60),
        // Duke FY2024 endowment $11.9B per NACUBO; 5.0% accept (5.44% class of 2028; 4.8% class of 2029).
        "Duke University":
            .init(acceptanceRate: 5.0,  endowmentBn: 11.9, awardCount: 15,
                  studentCount: 16_000,  facultyCount: 3_600, schoolCount: 10, locationScore: 50),
        // Northwestern FY2024 endowment $14.2B per Wikipedia/NACUBO.
        "Northwestern University":
            .init(acceptanceRate: 7.0,  endowmentBn: 14.2, awardCount: 12,
                  studentCount: 21_000,  facultyCount: 3_200, schoolCount: 12, locationScore: 90),
        // Cornell FY2024 endowment $10.7B per NACUBO; 8.5% accept (8.41% class of 2028); 61 Nobel affiliates.
        "Cornell University":
            .init(acceptanceRate: 8.5,  endowmentBn: 10.7, awardCount: 61,
                  studentCount: 24_000,  facultyCount: 2_700, schoolCount: 16, locationScore: 28),
        "New York University":
            .init(acceptanceRate: 16.0, endowmentBn: 6.3,  awardCount: 38,
                  studentCount: 58_000,  facultyCount: 7_500, schoolCount: 18, locationScore: 100),
        // Brown FY2024 endowment $6.7B per NACUBO; 5.2% accept.
        "Brown University":
            .init(acceptanceRate: 5.2,  endowmentBn: 6.7,  awardCount: 6,
                  studentCount: 10_000,  facultyCount: 1_000, schoolCount: 9, locationScore: 60),
        // Dartmouth: 6.0% accept (5.41% class of 2028; 6.0% class of 2029).
        "Dartmouth College":
            .init(acceptanceRate: 6.0,  endowmentBn: 8.5,  awardCount: 2,
                  studentCount:  6_700, facultyCount: 1_000, schoolCount: 4, locationScore: 25),
        "Rice University":
            .init(acceptanceRate: 9.0,  endowmentBn: 8.1,  awardCount: 5,
                  studentCount:  4_200, facultyCount:   700, schoolCount: 7, locationScore: 82),
        // Vanderbilt FY2024 endowment $10.3B per NACUBO.
        "Vanderbilt University":
            .init(acceptanceRate: 9.0,  endowmentBn: 10.3, awardCount: 5,
                  studentCount: 13_000,  facultyCount: 4_600, schoolCount: 10, locationScore: 65),
        // WashU FY2024 endowment $12.0B per NACUBO.
        "Washington University in St. Louis":
            .init(acceptanceRate: 14.0, endowmentBn: 12.0, awardCount: 25,
                  studentCount: 15_000,  facultyCount: 3_700, schoolCount: 10, locationScore: 65),
        "Emory University":
            .init(acceptanceRate: 19.0, endowmentBn: 10.9, awardCount: 3,
                  studentCount: 15_000,  facultyCount: 3_900, schoolCount: 9, locationScore: 82),
        // Notre Dame: 11% accept (11.27% class of 2028; 9.0% class of 2029).
        // FY2024 endowment $17.9B per Wikipedia/NACUBO.
        "University of Notre Dame":
            .init(acceptanceRate: 11.0, endowmentBn: 17.9, awardCount: 3,
                  studentCount: 12_500,  facultyCount: 1_100, schoolCount: 7, locationScore: 35),
        "Georgetown University":
            .init(acceptanceRate: 15.0, endowmentBn: 2.8,  awardCount: 2,
                  studentCount: 20_000,  facultyCount: 2_600, schoolCount: 10, locationScore: 85),
        "Tufts University":
            .init(acceptanceRate: 11.0, endowmentBn: 2.6,  awardCount: 2,
                  studentCount: 12_000,  facultyCount: 1_200, schoolCount: 8, locationScore: 80),
        "Case Western Reserve University":
            .init(acceptanceRate: 29.0, endowmentBn: 2.5,  awardCount: 5,
                  studentCount: 12_000,  facultyCount: 4_600, schoolCount: 8, locationScore: 62),
        // USC FY2024 endowment $8.2B per NACUBO; 9.3% accept (record-low 2024; 82k applicants, 7.6k admitted).
        "University of Southern California":
            .init(acceptanceRate: 9.3,  endowmentBn: 8.2,  awardCount: 8,
                  studentCount: 48_000,  facultyCount: 4_500, schoolCount: 21, locationScore: 92),
        "Boston University":
            .init(acceptanceRate: 22.0, endowmentBn: 3.4,  awardCount: 7,
                  studentCount: 34_000,  facultyCount: 3_700, schoolCount: 17, locationScore: 82),
        "Georgia Institute of Technology":
            .init(acceptanceRate: 17.0, endowmentBn: 2.7,  awardCount: 5,
                  studentCount: 35_000,  facultyCount: 1_200, schoolCount: 6, locationScore: 82),
        // Berkeley: 110 (Jan 2025 blog) + John Clarke (Physics 2025) + Omar Yaghi (Chemistry 2025) = 112.
        "University of California, Berkeley":
            .init(acceptanceRate: 14.3, endowmentBn: 7.1,  awardCount: 112,
                  studentCount: 42_000,  facultyCount: 1_600, schoolCount: 14, locationScore: 88),
        // UCLA: 25 Nobel affiliates per comprehensive ranking table.
        "University of California, Los Angeles":
            .init(acceptanceRate: 14.4, endowmentBn: 7.9,  awardCount: 25,
                  studentCount: 44_000,  facultyCount: 4_200, schoolCount: 15, locationScore: 92),
        // UCSD: 27 Nobel affiliates per comprehensive ranking table.
        "University of California, San Diego":
            .init(acceptanceRate: 34.0, endowmentBn: 2.0,  awardCount: 27,
                  studentCount: 39_000,  facultyCount: 2_800, schoolCount: 7, locationScore: 78),
        // UCSB: +2 for 2025 Nobel Physics (Devoret and Martinis, both UCSB faculty at award time).
        "University of California, Santa Barbara":
            .init(acceptanceRate: 36.0, endowmentBn: 1.5,  awardCount: 17,
                  studentCount: 26_000,  facultyCount: 1_100, schoolCount: 6, locationScore: 48),
        "University of California, Davis":
            .init(acceptanceRate: 49.0, endowmentBn: 1.7,  awardCount: 6,
                  studentCount: 38_000,  facultyCount: 2_200, schoolCount: 9, locationScore: 55),
        "University of California, Irvine":
            .init(acceptanceRate: 37.0, endowmentBn: 0.7,  awardCount: 8,
                  studentCount: 35_000,  facultyCount: 1_900, schoolCount: 7, locationScore: 88),
        "University of Virginia":
            .init(acceptanceRate: 21.0, endowmentBn: 14.2, awardCount: 6,
                  studentCount: 25_000,  facultyCount: 2_500, schoolCount: 11, locationScore: 42),
        "University of North Carolina at Chapel Hill":
            .init(acceptanceRate: 19.0, endowmentBn: 5.0,  awardCount: 7,
                  studentCount: 29_000,  facultyCount: 3_700, schoolCount: 14, locationScore: 52),
        "University of Pittsburgh":
            .init(acceptanceRate: 65.0, endowmentBn: 5.3,  awardCount: 20,
                  studentCount: 33_000,  facultyCount: 5_600, schoolCount: 16, locationScore: 65),
        "University of Rochester":
            .init(acceptanceRate: 36.0, endowmentBn: 2.8,  awardCount: 15,
                  studentCount: 11_000,  facultyCount:   900, schoolCount: 8, locationScore: 58),
        "University of Massachusetts Amherst":
            .init(acceptanceRate: 64.0, endowmentBn: 0.7,  awardCount: 3,
                  studentCount: 32_000,  facultyCount: 1_400, schoolCount: 11, locationScore: 40),
        "North Carolina State University":
            .init(acceptanceRate: 45.0, endowmentBn: 0.9,  awardCount: 3,
                  studentCount: 36_000,  facultyCount: 2_300, schoolCount: 10, locationScore: 60),
        "University of Washington":
            .init(acceptanceRate: 52.0, endowmentBn: 5.0,  awardCount: 11,
                  studentCount: 54_000,  facultyCount: 4_200, schoolCount: 18, locationScore: 85),
        "Ohio State University":
            .init(acceptanceRate: 54.0, endowmentBn: 7.4,  awardCount: 6,
                  studentCount: 61_000,  facultyCount: 7_000, schoolCount: 19, locationScore: 65),
        "Pennsylvania State University":
            .init(acceptanceRate: 55.0, endowmentBn: 4.0,  awardCount: 5,
                  studentCount: 92_000,  facultyCount: 7_000, schoolCount: 24, locationScore: 30),
        "Michigan State University":
            .init(acceptanceRate: 76.0, endowmentBn: 3.9,  awardCount: 5,
                  studentCount: 50_000,  facultyCount: 5_200, schoolCount: 17, locationScore: 52),
        "Indiana University Bloomington":
            .init(acceptanceRate: 80.0, endowmentBn: 3.2,  awardCount: 5,
                  studentCount: 46_000,  facultyCount: 4_500, schoolCount: 14, locationScore: 35),
        "Texas A&M University":
            .init(acceptanceRate: 63.0, endowmentBn: 2.5,  awardCount: 3,
                  studentCount: 74_000,  facultyCount: 5_500, schoolCount: 15, locationScore: 35),
        "University of Texas at Austin":
            .init(acceptanceRate: 31.0, endowmentBn: 3.9,  awardCount: 9,
                  studentCount: 51_000,  facultyCount: 3_100, schoolCount: 18, locationScore: 72),
        "Purdue University":
            .init(acceptanceRate: 67.0, endowmentBn: 3.4,  awardCount: 13,
                  studentCount: 50_000,  facultyCount: 2_800, schoolCount: 12, locationScore: 35),
        "University of Illinois Urbana-Champaign":
            .init(acceptanceRate: 62.0, endowmentBn: 3.1,  awardCount: 30,
                  studentCount: 57_000,  facultyCount: 3_100, schoolCount: 16, locationScore: 38),
        "University of Maryland, College Park":
            .init(acceptanceRate: 53.0, endowmentBn: 0.9,  awardCount: 5,
                  studentCount: 40_000,  facultyCount: 3_700, schoolCount: 13, locationScore: 80),
        // Minnesota: 30 Nobel affiliates per comprehensive ranking table.
        "University of Minnesota–Twin Cities":
            .init(acceptanceRate: 75.0, endowmentBn: 4.2,  awardCount: 30,
                  studentCount: 54_000,  facultyCount: 4_000, schoolCount: 19, locationScore: 75),
        // Wisconsin: 26 Nobel affiliates per comprehensive ranking table.
        "University of Wisconsin–Madison":
            .init(acceptanceRate: 57.0, endowmentBn: 3.8,  awardCount: 26,
                  studentCount: 49_000,  facultyCount: 2_300, schoolCount: 20, locationScore: 55),
        "University of Florida":
            .init(acceptanceRate: 31.0, endowmentBn: 2.4,  awardCount: 5,
                  studentCount: 57_000,  facultyCount: 4_600, schoolCount: 18, locationScore: 38),
        "University of Colorado Boulder":
            .init(acceptanceRate: 87.0, endowmentBn: 1.0,  awardCount: 5,
                  studentCount: 40_000,  facultyCount: 2_800, schoolCount: 12, locationScore: 68),
        "University of Arizona":
            .init(acceptanceRate: 85.0, endowmentBn: 1.1,  awardCount: 3,
                  studentCount: 55_000,  facultyCount: 3_300, schoolCount: 20, locationScore: 58),
        "Arizona State University":
            .init(acceptanceRate: 89.0, endowmentBn: 1.8,  awardCount: 3,
                  studentCount: 135_000, facultyCount: 5_700, schoolCount: 30, locationScore: 80),

        // ── United Kingdom ────────────────────────────────────────────────
        "University of Oxford":
            .init(acceptanceRate: 17.5, endowmentBn: 9.5,  awardCount: 72,
                  studentCount: 24_000,  facultyCount: 7_000, schoolCount: 4, locationScore: 42),
        "University of Cambridge":
            .init(acceptanceRate: 18.0, endowmentBn: 9.5,  awardCount: 121,
                  studentCount: 24_000,  facultyCount: 6_000, schoolCount: 6, locationScore: 42),
        "Imperial College London":
            .init(acceptanceRate: 14.0, endowmentBn: 1.6,  awardCount: 15,
                  studentCount: 19_000,  facultyCount: 3_500, schoolCount: 4, locationScore: 97),
        // UCL: 34 Nobel affiliates per comprehensive ranking table.
        "University College London":
            .init(acceptanceRate: 63.0, endowmentBn: 1.6,  awardCount: 34,
                  studentCount: 42_000,  facultyCount: 7_000, schoolCount: 11, locationScore: 97),
        "University of Edinburgh":
            .init(acceptanceRate: 19.0, endowmentBn: 1.7,  awardCount: 20,
                  studentCount: 35_000,  facultyCount: 5_000, schoolCount: 3, locationScore: 60),
        "University of Manchester":
            .init(acceptanceRate: 59.0, endowmentBn: 1.1,  awardCount: 25,
                  studentCount: 40_000,  facultyCount: 4_500, schoolCount: 10, locationScore: 72),
        "King's College London":
            .init(acceptanceRate: 55.0, endowmentBn: 0.9,  awardCount: 15,
                  studentCount: 33_000,  facultyCount: 5_000, schoolCount: 9, locationScore: 97),
        "London School of Economics":
            .init(acceptanceRate: 22.0, endowmentBn: 1.6,  awardCount: 18,
                  studentCount: 12_000,  facultyCount: 1_200, schoolCount: 22, locationScore: 97),
        "University of Bristol":
            .init(acceptanceRate: 73.0, endowmentBn: 0.4,  awardCount: 12,
                  studentCount: 29_000,  facultyCount: 3_200, schoolCount: 6, locationScore: 60),
        "University of Glasgow":
            .init(acceptanceRate: 73.0, endowmentBn: 0.4,  awardCount: 8,
                  studentCount: 32_000,  facultyCount: 3_500, schoolCount: 4, locationScore: 62),
        "University of Sheffield":
            .init(acceptanceRate: 76.0, endowmentBn: 0.4,  awardCount: 6,
                  studentCount: 30_000,  facultyCount: 3_000, schoolCount: 6, locationScore: 58),
        "University of Birmingham":
            .init(acceptanceRate: 75.0, endowmentBn: 0.5,  awardCount: 8,
                  studentCount: 38_000,  facultyCount: 4_000, schoolCount: 5, locationScore: 72),
        "University of Leeds":
            .init(acceptanceRate: 78.0, endowmentBn: 0.4,  awardCount: 5,
                  studentCount: 38_000,  facultyCount: 4_000, schoolCount: 8, locationScore: 68),
        "University of Warwick":
            .init(acceptanceRate: 64.0, endowmentBn: 0.6,  awardCount: 5,
                  studentCount: 27_000,  facultyCount: 2_800, schoolCount: 4, locationScore: 50),
        "University of Nottingham":
            .init(acceptanceRate: 74.0, endowmentBn: 0.4,  awardCount: 3,
                  studentCount: 34_000,  facultyCount: 3_400, schoolCount: 5, locationScore: 60),
        "University of Southampton":
            .init(acceptanceRate: 79.0, endowmentBn: 0.3,  awardCount: 5,
                  studentCount: 26_000,  facultyCount: 2_600, schoolCount: 6, locationScore: 58),
        "University of Liverpool":
            .init(acceptanceRate: 82.0, endowmentBn: 0.3,  awardCount: 9,
                  studentCount: 27_000,  facultyCount: 2_500, schoolCount: 7, locationScore: 62),
        "Queen Mary University of London":
            .init(acceptanceRate: 75.0, endowmentBn: 0.3,  awardCount: 3,
                  studentCount: 26_000,  facultyCount: 2_500, schoolCount: 5, locationScore: 95),
        "Durham University":
            .init(acceptanceRate: 47.0, endowmentBn: 0.5,  awardCount: 3,
                  studentCount: 20_000,  facultyCount: 2_000, schoolCount: 3, locationScore: 42),
        "University of St Andrews":
            .init(acceptanceRate: 38.0, endowmentBn: 0.6,  awardCount: 3,
                  studentCount:  9_500, facultyCount: 1_000, schoolCount: 4, locationScore: 20),
        "Newcastle University":
            .init(acceptanceRate: 78.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 28_000,  facultyCount: 2_800, schoolCount: 6, locationScore: 62),
        "University of York":
            .init(acceptanceRate: 82.0, endowmentBn: 0.3,  awardCount: 5,
                  studentCount: 18_000,  facultyCount: 1_500, schoolCount: 7, locationScore: 42),
        "Lancaster University":
            .init(acceptanceRate: 84.0, endowmentBn: 0.2,  awardCount: 2,
                  studentCount: 14_000,  facultyCount: 1_300, schoolCount: 8, locationScore: 38),
        "University of Exeter":
            .init(acceptanceRate: 73.0, endowmentBn: 0.4,  awardCount: 3,
                  studentCount: 23_000,  facultyCount: 2_000, schoolCount: 7, locationScore: 38),
        "Cardiff University":
            .init(acceptanceRate: 82.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 30_000,  facultyCount: 2_800, schoolCount: 6, locationScore: 55),
        "University of Bath":
            .init(acceptanceRate: 78.0, endowmentBn: 0.1,  awardCount: 2,
                  studentCount: 18_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 50),
        "University of Reading":
            .init(acceptanceRate: 80.0, endowmentBn: 0.2,  awardCount: 2,
                  studentCount: 18_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 62),
        "Loughborough University":
            .init(acceptanceRate: 85.0, endowmentBn: 0.1,  awardCount: 1,
                  studentCount: 19_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 35),
        "Queen's University Belfast":
            .init(acceptanceRate: 80.0, endowmentBn: 0.2,  awardCount: 3,
                  studentCount: 17_000,  facultyCount: 1_500, schoolCount: 5, locationScore: 60),

        // ── Australia ─────────────────────────────────────────────────────
        "University of Melbourne":
            .init(acceptanceRate: 70.0, endowmentBn: 2.0,  awardCount: 6,
                  studentCount: 50_000,  facultyCount: 5_000, schoolCount: 11, locationScore: 85),
        "University of New South Wales":
            .init(acceptanceRate: 73.0, endowmentBn: 1.0,  awardCount: 5,
                  studentCount: 57_000,  facultyCount: 5_000, schoolCount: 9, locationScore: 87),
        "University of Sydney":
            .init(acceptanceRate: 50.0, endowmentBn: 1.3,  awardCount: 5,
                  studentCount: 60_000,  facultyCount: 5_500, schoolCount: 16, locationScore: 87),
        "Australian National University":
            .init(acceptanceRate: 40.0, endowmentBn: 1.0,  awardCount: 7,
                  studentCount: 22_000,  facultyCount: 1_800, schoolCount: 7, locationScore: 50),
        "University of Queensland":
            .init(acceptanceRate: 55.0, endowmentBn: 1.0,  awardCount: 4,
                  studentCount: 53_000,  facultyCount: 4_200, schoolCount: 8, locationScore: 72),
        "Monash University":
            .init(acceptanceRate: 80.0, endowmentBn: 1.0,  awardCount: 3,
                  studentCount: 82_000,  facultyCount: 6_000, schoolCount: 10, locationScore: 83),
        "University of Adelaide":
            .init(acceptanceRate: 75.0, endowmentBn: 0.8,  awardCount: 5,
                  studentCount: 25_000,  facultyCount: 2_200, schoolCount: 6, locationScore: 62),
        "University of Western Australia":
            .init(acceptanceRate: 80.0, endowmentBn: 0.5,  awardCount: 2,
                  studentCount: 25_000,  facultyCount: 2_000, schoolCount: 6, locationScore: 65),
        "Queensland University of Technology":
            .init(acceptanceRate: 80.0, endowmentBn: 0.3,  awardCount: 1,
                  studentCount: 45_000,  facultyCount: 2_000, schoolCount: 4, locationScore: 72),
        "Macquarie University":
            .init(acceptanceRate: 82.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 44_000,  facultyCount: 2_000, schoolCount: 4, locationScore: 85),
        "University of Newcastle":
            .init(acceptanceRate: 85.0, endowmentBn: 0.2,  awardCount: 1,
                  studentCount: 38_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 52),
        "University of Wollongong":
            .init(acceptanceRate: 85.0, endowmentBn: 0.2,  awardCount: 0,
                  studentCount: 30_000,  facultyCount: 1_200, schoolCount: 7, locationScore: 58),
        "Deakin University":
            .init(acceptanceRate: 85.0, endowmentBn: 0.3,  awardCount: 0,
                  studentCount: 61_000,  facultyCount: 2_500, schoolCount: 4, locationScore: 75),
        "La Trobe University":
            .init(acceptanceRate: 85.0, endowmentBn: 0.2,  awardCount: 0,
                  studentCount: 37_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 82),
        "Curtin University":
            .init(acceptanceRate: 85.0, endowmentBn: 0.2,  awardCount: 0,
                  studentCount: 56_000,  facultyCount: 2_000, schoolCount: 5, locationScore: 65),
        "RMIT University":
            .init(acceptanceRate: 85.0, endowmentBn: 0.2,  awardCount: 0,
                  studentCount: 91_000,  facultyCount: 3_000, schoolCount: 4, locationScore: 87),
        "University of Technology Sydney":
            .init(acceptanceRate: 85.0, endowmentBn: 0.3,  awardCount: 0,
                  studentCount: 47_000,  facultyCount: 2_500, schoolCount: 8, locationScore: 87),
        "University of Otago":
            .init(acceptanceRate: 72.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 21_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 40),

        // ── Singapore ─────────────────────────────────────────────────────
        "National University of Singapore":
            .init(acceptanceRate: 16.0, endowmentBn: 5.0,  awardCount: 5,
                  studentCount: 38_000,  facultyCount: 2_900, schoolCount: 17, locationScore: 92),
        "Nanyang Technological University":
            .init(acceptanceRate: 17.0, endowmentBn: 2.2,  awardCount: 3,
                  studentCount: 33_000,  facultyCount: 3_000, schoolCount: 8, locationScore: 92),

        // ── Canada ────────────────────────────────────────────────────────
        "University of Toronto":
            .init(acceptanceRate: 43.0, endowmentBn: 3.0,  awardCount: 11,
                  studentCount: 97_000,  facultyCount: 14_000, schoolCount: 18, locationScore: 87),
        "McGill University":
            .init(acceptanceRate: 40.0, endowmentBn: 1.5,  awardCount: 12,
                  studentCount: 40_000,  facultyCount: 1_700, schoolCount: 11, locationScore: 82),
        "University of British Columbia":
            .init(acceptanceRate: 52.0, endowmentBn: 1.9,  awardCount: 7,
                  studentCount: 65_000,  facultyCount: 6_000, schoolCount: 18, locationScore: 80),
        "McMaster University":
            .init(acceptanceRate: 67.0, endowmentBn: 0.8,  awardCount: 5,
                  studentCount: 35_000,  facultyCount: 3_000, schoolCount: 7, locationScore: 65),
        "University of Alberta":
            .init(acceptanceRate: 78.0, endowmentBn: 1.1,  awardCount: 5,
                  studentCount: 40_000,  facultyCount: 4_200, schoolCount: 18, locationScore: 62),
        "University of Waterloo":
            .init(acceptanceRate: 47.0, endowmentBn: 1.0,  awardCount: 2,
                  studentCount: 42_000,  facultyCount: 1_300, schoolCount: 6, locationScore: 55),
        "Queen's University":
            .init(acceptanceRate: 65.0, endowmentBn: 0.8,  awardCount: 2,
                  studentCount: 24_000,  facultyCount: 1_700, schoolCount: 8, locationScore: 42),
        "Western University":
            .init(acceptanceRate: 58.0, endowmentBn: 0.8,  awardCount: 3,
                  studentCount: 40_000,  facultyCount: 3_200, schoolCount: 11, locationScore: 55),

        // ── Ireland ───────────────────────────────────────────────────────
        "University College Dublin":
            .init(acceptanceRate: 58.0, endowmentBn: 0.4,  awardCount: 3,
                  studentCount: 29_000,  facultyCount: 1_800, schoolCount: 5, locationScore: 75),

        // ── China (mainland) ──────────────────────────────────────────────
        // Acceptance rates are effective Gaokao top-tier admission rates;
        // exceptionally low due to the national examination system.
        "Tsinghua University":
            .init(acceptanceRate: 0.04, endowmentBn: 2.5,  awardCount: 15,
                  studentCount: 37_000,  facultyCount: 3_500, schoolCount: 20, locationScore: 97),
        "Peking University":
            .init(acceptanceRate: 0.04, endowmentBn: 2.5,  awardCount: 10,
                  studentCount: 45_000,  facultyCount: 3_000, schoolCount: 30, locationScore: 97),
        "Fudan University":
            .init(acceptanceRate: 0.05, endowmentBn: 1.5,  awardCount: 5,
                  studentCount: 34_000,  facultyCount: 2_800, schoolCount: 18, locationScore: 98),
        "Shanghai Jiao Tong University":
            .init(acceptanceRate: 0.06, endowmentBn: 1.8,  awardCount: 5,
                  studentCount: 48_000,  facultyCount: 5_000, schoolCount: 27, locationScore: 98),
        "Zhejiang University":
            .init(acceptanceRate: 0.06, endowmentBn: 1.5,  awardCount: 3,
                  studentCount: 58_000,  facultyCount: 5_000, schoolCount: 22, locationScore: 82),
        "Nanjing University":
            .init(acceptanceRate: 0.07, endowmentBn: 1.2,  awardCount: 3,
                  studentCount: 34_000,  facultyCount: 2_500, schoolCount: 24, locationScore: 82),
        "University of Science and Technology of China":
            .init(acceptanceRate: 0.05, endowmentBn: 1.0,  awardCount: 5,
                  studentCount: 15_000,  facultyCount: 1_500, schoolCount: 11, locationScore: 78),
        "Harbin Institute of Technology":
            .init(acceptanceRate: 0.08, endowmentBn: 0.8,  awardCount: 2,
                  studentCount: 40_000,  facultyCount: 2_500, schoolCount: 22, locationScore: 72),
        "Tongji University":
            .init(acceptanceRate: 0.08, endowmentBn: 0.5,  awardCount: 1,
                  studentCount: 45_000,  facultyCount: 2_800, schoolCount: 12, locationScore: 98),
        "Wuhan University":
            .init(acceptanceRate: 0.07, endowmentBn: 0.8,  awardCount: 2,
                  studentCount: 52_000,  facultyCount: 3_500, schoolCount: 28, locationScore: 87),
        "Beijing Normal University":
            .init(acceptanceRate: 0.06, endowmentBn: 0.6,  awardCount: 2,
                  studentCount: 26_000,  facultyCount: 2_000, schoolCount: 18, locationScore: 97),
        "Beijing Institute of Technology":
            .init(acceptanceRate: 0.07, endowmentBn: 0.5,  awardCount: 1,
                  studentCount: 25_000,  facultyCount: 2_000, schoolCount: 15, locationScore: 97),
        "Sun Yat-sen University":
            .init(acceptanceRate: 0.07, endowmentBn: 0.8,  awardCount: 2,
                  studentCount: 58_000,  facultyCount: 4_000, schoolCount: 35, locationScore: 95),
        "Huazhong University of Science and Technology":
            .init(acceptanceRate: 0.07, endowmentBn: 0.8,  awardCount: 2,
                  studentCount: 51_000,  facultyCount: 4_500, schoolCount: 22, locationScore: 87),
        "Shandong University":
            .init(acceptanceRate: 0.07, endowmentBn: 0.5,  awardCount: 1,
                  studentCount: 60_000,  facultyCount: 3_500, schoolCount: 30, locationScore: 80),
        "South China University of Technology":
            .init(acceptanceRate: 0.08, endowmentBn: 0.5,  awardCount: 1,
                  studentCount: 43_000,  facultyCount: 2_800, schoolCount: 15, locationScore: 95),
        "Beihang University":
            .init(acceptanceRate: 0.08, endowmentBn: 0.8,  awardCount: 1,
                  studentCount: 36_000,  facultyCount: 3_000, schoolCount: 15, locationScore: 97),
        "Xi'an Jiaotong University":
            .init(acceptanceRate: 0.07, endowmentBn: 0.8,  awardCount: 2,
                  studentCount: 45_000,  facultyCount: 4_500, schoolCount: 22, locationScore: 80),

        // ── Hong Kong ─────────────────────────────────────────────────────
        "University of Hong Kong":
            .init(acceptanceRate: 10.0, endowmentBn: 1.5,  awardCount: 5,
                  studentCount: 30_000,  facultyCount: 2_300, schoolCount: 10, locationScore: 93),
        "Chinese University of Hong Kong":
            .init(acceptanceRate: 15.0, endowmentBn: 1.0,  awardCount: 4,
                  studentCount: 21_000,  facultyCount: 1_600, schoolCount: 9, locationScore: 90),
        "HKUST":
            .init(acceptanceRate: 10.0, endowmentBn: 0.5,  awardCount: 3,
                  studentCount: 13_000,  facultyCount:   600, schoolCount: 4, locationScore: 88),
        "Hong Kong Polytechnic University":
            .init(acceptanceRate: 30.0, endowmentBn: 0.3,  awardCount: 1,
                  studentCount: 30_000,  facultyCount: 2_000, schoolCount: 8, locationScore: 92),
        "City University of Hong Kong":
            .init(acceptanceRate: 25.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 20_000,  facultyCount: 1_000, schoolCount: 8, locationScore: 92),
        "Hong Kong Baptist University":
            .init(acceptanceRate: 40.0, endowmentBn: 0.1,  awardCount: 1,
                  studentCount:  8_000, facultyCount:   600, schoolCount: 7, locationScore: 90),

        // ── Japan ─────────────────────────────────────────────────────────
        "University of Tokyo":
            .init(acceptanceRate: 31.0, endowmentBn: 1.5,  awardCount: 16,
                  studentCount: 28_000,  facultyCount: 4_000, schoolCount: 10, locationScore: 98),
        "Kyoto University":
            .init(acceptanceRate: 33.0, endowmentBn: 0.5,  awardCount: 19,
                  studentCount: 23_000,  facultyCount: 3_500, schoolCount: 10, locationScore: 72),
        "Osaka University":
            .init(acceptanceRate: 45.0, endowmentBn: 0.4,  awardCount: 11,
                  studentCount: 24_000,  facultyCount: 3_000, schoolCount: 16, locationScore: 95),
        "Tohoku University":
            .init(acceptanceRate: 53.0, endowmentBn: 0.3,  awardCount: 6,
                  studentCount: 17_000,  facultyCount: 2_500, schoolCount: 10, locationScore: 68),
        "Nagoya University":
            .init(acceptanceRate: 47.0, endowmentBn: 0.3,  awardCount: 6,
                  studentCount: 16_000,  facultyCount: 2_500, schoolCount: 13, locationScore: 90),
        "Tokyo Institute of Technology":
            .init(acceptanceRate: 10.0, endowmentBn: 0.3,  awardCount: 3,
                  studentCount: 10_000,  facultyCount: 1_200, schoolCount: 6, locationScore: 98),
        "Keio University":
            .init(acceptanceRate: 25.0, endowmentBn: 0.8,  awardCount: 3,
                  studentCount: 34_000,  facultyCount: 2_600, schoolCount: 10, locationScore: 98),
        "Waseda University":
            .init(acceptanceRate: 38.0, endowmentBn: 0.5,  awardCount: 2,
                  studentCount: 44_000,  facultyCount: 2_000, schoolCount: 13, locationScore: 98),
        "Kyushu University":
            .init(acceptanceRate: 52.0, endowmentBn: 0.2,  awardCount: 2,
                  studentCount: 19_000,  facultyCount: 2_500, schoolCount: 12, locationScore: 82),
        "Hokkaido University":
            .init(acceptanceRate: 57.0, endowmentBn: 0.2,  awardCount: 2,
                  studentCount: 18_000,  facultyCount: 2_000, schoolCount: 12, locationScore: 72),

        // ── South Korea ───────────────────────────────────────────────────
        "Seoul National University":
            .init(acceptanceRate: 16.0, endowmentBn: 0.5,  awardCount: 2,
                  studentCount: 28_000,  facultyCount: 2_600, schoolCount: 16, locationScore: 97),
        "KAIST":
            .init(acceptanceRate: 18.0, endowmentBn: 0.4,  awardCount: 1,
                  studentCount: 10_000,  facultyCount:   600, schoolCount: 5, locationScore: 65),
        "POSTECH":
            .init(acceptanceRate: 10.0, endowmentBn: 0.4,  awardCount: 1,
                  studentCount:  3_200, facultyCount:   250, schoolCount: 5, locationScore: 48),
        "Korea University":
            .init(acceptanceRate: 20.0, endowmentBn: 0.5,  awardCount: 1,
                  studentCount: 27_000,  facultyCount: 1_800, schoolCount: 18, locationScore: 97),
        "Yonsei University":
            .init(acceptanceRate: 23.0, endowmentBn: 0.6,  awardCount: 1,
                  studentCount: 35_000,  facultyCount: 2_200, schoolCount: 21, locationScore: 97),
        "Sungkyunkwan University":
            .init(acceptanceRate: 30.0, endowmentBn: 0.5,  awardCount: 1,
                  studentCount: 30_000,  facultyCount: 1_500, schoolCount: 6, locationScore: 95),

        // ── Taiwan ────────────────────────────────────────────────────────
        "National Taiwan University":
            .init(acceptanceRate: 28.0, endowmentBn: 0.8,  awardCount: 5,
                  studentCount: 33_000,  facultyCount: 2_200, schoolCount: 11, locationScore: 88),

        // ── Switzerland ───────────────────────────────────────────────────
        "ETH Zurich":
            .init(acceptanceRate: 27.0, endowmentBn: 11.0, awardCount: 32,
                  studentCount: 24_000,  facultyCount:   500, schoolCount: 16, locationScore: 72),
        "EPFL":
            .init(acceptanceRate: 30.0, endowmentBn: 4.4,  awardCount: 5,
                  studentCount: 13_000,  facultyCount:   350, schoolCount: 5, locationScore: 52),
        "University of Zurich":
            .init(acceptanceRate: 30.0, endowmentBn: 2.5,  awardCount: 12,
                  studentCount: 27_000,  facultyCount:   700, schoolCount: 7, locationScore: 72),
        "University of Bern":
            .init(acceptanceRate: 70.0, endowmentBn: 0.5,  awardCount: 10,
                  studentCount: 18_000,  facultyCount:   500, schoolCount: 8, locationScore: 52),
        "University of Geneva":
            .init(acceptanceRate: 70.0, endowmentBn: 0.8,  awardCount: 13,
                  studentCount: 18_000,  facultyCount:   600, schoolCount: 7, locationScore: 58),
        "University of Basel":
            .init(acceptanceRate: 75.0, endowmentBn: 0.5,  awardCount: 9,
                  studentCount: 14_000,  facultyCount:   600, schoolCount: 7, locationScore: 60),

        // ── Germany ───────────────────────────────────────────────────────
        // German public universities have near-open enrollment; acceptance
        // rates reflect typical competitive programme offer rates.
        "LMU Munich":
            .init(acceptanceRate: 85.0, endowmentBn: 0.3,  awardCount: 41,
                  studentCount: 51_000,  facultyCount:   750, schoolCount: 18, locationScore: 78),
        "Technical University of Munich":
            .init(acceptanceRate: 80.0, endowmentBn: 0.3,  awardCount: 18,
                  studentCount: 45_000,  facultyCount:   600, schoolCount: 8, locationScore: 78),
        // Heidelberg: 27 Nobel affiliates per Wikipedia at-announcement count.
        // (Heidelberg claims ~56 by their own inclusive methodology.)
        "Heidelberg University":
            .init(acceptanceRate: 85.0, endowmentBn: 0.5,  awardCount: 27,
                  studentCount: 29_000,  facultyCount:   600, schoolCount: 12, locationScore: 45),
        "University of Hamburg":
            .init(acceptanceRate: 86.0, endowmentBn: 0.1,  awardCount: 6,
                  studentCount: 42_000,  facultyCount:   700, schoolCount: 8, locationScore: 72),
        "University of Bonn":
            .init(acceptanceRate: 87.0, endowmentBn: 0.1,  awardCount: 11,
                  studentCount: 35_000,  facultyCount:   500, schoolCount: 7, locationScore: 65),
        "RWTH Aachen University":
            .init(acceptanceRate: 84.0, endowmentBn: 0.2,  awardCount: 3,
                  studentCount: 46_000,  facultyCount:   540, schoolCount: 9, locationScore: 52),
        "Technical University of Berlin":
            .init(acceptanceRate: 85.0, endowmentBn: 0.1,  awardCount: 3,
                  studentCount: 35_000,  facultyCount:   500, schoolCount: 8, locationScore: 82),
        // Humboldt: 57 Nobel affiliates per comprehensive ranking table
        // (extensive historical associations with early 20th-century German physics/chemistry).
        "Humboldt University of Berlin":
            .init(acceptanceRate: 85.0, endowmentBn: 0.1,  awardCount: 57,
                  studentCount: 34_000,  facultyCount:   500, schoolCount: 11, locationScore: 82),
        "Free University of Berlin":
            .init(acceptanceRate: 85.0, endowmentBn: 0.1,  awardCount: 5,
                  studentCount: 37_000,  facultyCount:   600, schoolCount: 12, locationScore: 80),
        "Karlsruhe Institute of Technology":
            .init(acceptanceRate: 83.0, endowmentBn: 0.2,  awardCount: 5,
                  studentCount: 23_000,  facultyCount:   600, schoolCount: 11, locationScore: 58),

        // ── France ────────────────────────────────────────────────────────
        "PSL University":
            .init(acceptanceRate: 3.0,  endowmentBn: 0.5,  awardCount: 30,
                  studentCount: 20_000,  facultyCount: 4_500, schoolCount: 10, locationScore: 97),
        "Institut Polytechnique de Paris":
            .init(acceptanceRate: 3.0,  endowmentBn: 0.5,  awardCount: 10,
                  studentCount:  9_000, facultyCount: 1_500, schoolCount: 5, locationScore: 85),
        "Sorbonne University":
            .init(acceptanceRate: 28.0, endowmentBn: 0.3,  awardCount: 20,
                  studentCount: 55_000,  facultyCount: 2_500, schoolCount: 6, locationScore: 97),
        "Université Paris-Saclay":
            .init(acceptanceRate: 20.0, endowmentBn: 0.8,  awardCount: 15,
                  studentCount: 48_000,  facultyCount: 3_000, schoolCount: 20, locationScore: 82),

        // ── Netherlands ───────────────────────────────────────────────────
        "University of Amsterdam":
            .init(acceptanceRate: 25.0, endowmentBn: 0.8,  awardCount: 12,
                  studentCount: 35_000,  facultyCount: 2_800, schoolCount: 7, locationScore: 75),
        "Leiden University":
            .init(acceptanceRate: 30.0, endowmentBn: 0.8,  awardCount: 16,
                  studentCount: 32_000,  facultyCount: 1_500, schoolCount: 7, locationScore: 50),
        "Delft University of Technology":
            .init(acceptanceRate: 25.0, endowmentBn: 1.5,  awardCount: 3,
                  studentCount: 26_000,  facultyCount: 2_000, schoolCount: 8, locationScore: 72),
        "University of Groningen":
            .init(acceptanceRate: 55.0, endowmentBn: 0.3,  awardCount: 13,
                  studentCount: 37_000,  facultyCount: 1_500, schoolCount: 7, locationScore: 48),
        "Wageningen University & Research":
            .init(acceptanceRate: 50.0, endowmentBn: 1.0,  awardCount: 3,
                  studentCount: 14_000,  facultyCount:   900, schoolCount: 6, locationScore: 28),
        "Erasmus University Rotterdam":
            .init(acceptanceRate: 35.0, endowmentBn: 0.6,  awardCount: 8,
                  studentCount: 32_000,  facultyCount: 2_500, schoolCount: 6, locationScore: 68),
        "Utrecht University":
            .init(acceptanceRate: 30.0, endowmentBn: 0.7,  awardCount: 12,
                  studentCount: 36_000,  facultyCount: 2_500, schoolCount: 7, locationScore: 58),
        "Eindhoven University of Technology":
            .init(acceptanceRate: 20.0, endowmentBn: 0.5,  awardCount: 3,
                  studentCount: 15_000,  facultyCount:   400, schoolCount: 9, locationScore: 55),

        // ── Scandinavia ───────────────────────────────────────────────────
        "KTH Royal Institute of Technology":
            .init(acceptanceRate: 20.0, endowmentBn: 0.4,  awardCount: 3,
                  studentCount: 15_000,  facultyCount:   500, schoolCount: 5, locationScore: 78),
        "Lund University":
            .init(acceptanceRate: 50.0, endowmentBn: 0.4,  awardCount: 10,
                  studentCount: 47_000,  facultyCount: 2_600, schoolCount: 8, locationScore: 50),
        "Stockholm University":
            .init(acceptanceRate: 45.0, endowmentBn: 0.3,  awardCount: 8,
                  studentCount: 33_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 78),
        "Uppsala University":
            .init(acceptanceRate: 55.0, endowmentBn: 0.4,  awardCount: 8,
                  studentCount: 45_000,  facultyCount: 2_000, schoolCount: 9, locationScore: 45),
        "Chalmers University of Technology":
            .init(acceptanceRate: 25.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 10_000,  facultyCount:   350, schoolCount: 5, locationScore: 65),
        "University of Copenhagen":
            .init(acceptanceRate: 40.0, endowmentBn: 0.5,  awardCount: 9,
                  studentCount: 38_000,  facultyCount: 2_000, schoolCount: 6, locationScore: 75),
        "Aarhus University":
            .init(acceptanceRate: 55.0, endowmentBn: 0.3,  awardCount: 4,
                  studentCount: 38_000,  facultyCount: 1_500, schoolCount: 4, locationScore: 55),
        "Technical University of Denmark":
            .init(acceptanceRate: 25.0, endowmentBn: 0.3,  awardCount: 2,
                  studentCount: 13_000,  facultyCount:   600, schoolCount: 5, locationScore: 73),
        "University of Oslo":
            .init(acceptanceRate: 60.0, endowmentBn: 0.5,  awardCount: 8,
                  studentCount: 26_000,  facultyCount: 1_500, schoolCount: 8, locationScore: 68),
        "Aalto University":
            .init(acceptanceRate: 15.0, endowmentBn: 0.3,  awardCount: 3,
                  studentCount: 15_000,  facultyCount:   500, schoolCount: 6, locationScore: 78),
        "University of Helsinki":
            .init(acceptanceRate: 40.0, endowmentBn: 0.4,  awardCount: 4,
                  studentCount: 35_000,  facultyCount: 1_500, schoolCount: 11, locationScore: 78),

        // ── Belgium ───────────────────────────────────────────────────────
        "KU Leuven":
            .init(acceptanceRate: 30.0, endowmentBn: 1.0,  awardCount: 5,
                  studentCount: 63_000,  facultyCount: 3_000, schoolCount: 14, locationScore: 55),
        "Ghent University":
            .init(acceptanceRate: 55.0, endowmentBn: 0.5,  awardCount: 3,
                  studentCount: 44_000,  facultyCount: 2_000, schoolCount: 11, locationScore: 52),

        // ── Italy ─────────────────────────────────────────────────────────
        "University of Bologna":
            .init(acceptanceRate: 80.0, endowmentBn: 0.2,  awardCount: 5,
                  studentCount: 85_000,  facultyCount: 2_800, schoolCount: 33, locationScore: 65),
        "Sapienza University of Rome":
            .init(acceptanceRate: 75.0, endowmentBn: 0.2,  awardCount: 3,
                  studentCount: 110_000, facultyCount: 4_500, schoolCount: 65, locationScore: 88),
        "University of Padova":
            .init(acceptanceRate: 82.0, endowmentBn: 0.2,  awardCount: 5,
                  studentCount: 65_000,  facultyCount: 2_000, schoolCount: 32, locationScore: 60),
        "Politecnico di Milano":
            .init(acceptanceRate: 60.0, endowmentBn: 0.2,  awardCount: 2,
                  studentCount: 47_000,  facultyCount: 1_000, schoolCount: 12, locationScore: 85),

        // ── Spain ─────────────────────────────────────────────────────────
        "University of Barcelona":
            .init(acceptanceRate: 70.0, endowmentBn: 0.2,  awardCount: 5,
                  studentCount: 50_000,  facultyCount: 3_500, schoolCount: 18, locationScore: 90),
        "Autonomous University of Madrid":
            .init(acceptanceRate: 70.0, endowmentBn: 0.1,  awardCount: 3,
                  studentCount: 36_000,  facultyCount: 2_000, schoolCount: 12, locationScore: 92),
        "Complutense University of Madrid":
            .init(acceptanceRate: 75.0, endowmentBn: 0.1,  awardCount: 4,
                  studentCount: 70_000,  facultyCount: 4_000, schoolCount: 28, locationScore: 92),

        // ── Austria ───────────────────────────────────────────────────────
        "University of Vienna":
            .init(acceptanceRate: 85.0, endowmentBn: 0.2,  awardCount: 20,
                  studentCount: 93_000,  facultyCount: 2_000, schoolCount: 20, locationScore: 80),

        // ── Ireland ───────────────────────────────────────────────────────
        "Trinity College Dublin":
            .init(acceptanceRate: 42.0, endowmentBn: 0.9,  awardCount: 5,
                  studentCount: 18_000,  facultyCount: 1_000, schoolCount: 3, locationScore: 78),

        // ── Israel ────────────────────────────────────────────────────────
        "Hebrew University of Jerusalem":
            .init(acceptanceRate: 40.0, endowmentBn: 0.8,  awardCount: 15,
                  studentCount: 23_000,  facultyCount: 1_500, schoolCount: 7, locationScore: 60),
        "Technion – Israel Institute of Technology":
            .init(acceptanceRate: 25.0, endowmentBn: 0.8,  awardCount: 4,
                  studentCount: 15_000,  facultyCount:   600, schoolCount: 6, locationScore: 55),
        "Tel Aviv University":
            .init(acceptanceRate: 35.0, endowmentBn: 0.7,  awardCount: 6,
                  studentCount: 30_000,  facultyCount: 1_400, schoolCount: 9, locationScore: 85),

        // ── New Zealand ───────────────────────────────────────────────────
        "University of Auckland":
            .init(acceptanceRate: 70.0, endowmentBn: 0.7,  awardCount: 3,
                  studentCount: 45_000,  facultyCount: 1_300, schoolCount: 8, locationScore: 68),

        // ── Karolinska (Sweden – standalone medical university) ────────────
        "Karolinska Institute":
            .init(acceptanceRate: 15.0, endowmentBn: 0.8,  awardCount: 32,
                  studentCount:  6_000, facultyCount:   800, schoolCount: 4, locationScore: 78),
    ]
}
