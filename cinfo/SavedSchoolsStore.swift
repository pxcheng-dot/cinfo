//
//  SavedSchoolsStore.swift
//  cinfo
//
//  Persists saved universities ("My Schools") with Likelihood + App Status per school.
//  `universityName` matches universities.csv exactly for Discover heart + lookups.
//

import Foundation
import Combine

// MARK: – Categories

enum SchoolLikelihood: String, Codable, CaseIterable, Identifiable {
    case dream
    case target
    case safety
    case financialSafety

    var id: String { rawValue }

    func localized(_ lang: String) -> String {
        switch self {
        case .dream:             return l("likelihood_dream", lang)
        case .target:            return l("likelihood_target", lang)
        case .safety:            return l("likelihood_safety", lang)
        case .financialSafety:   return l("likelihood_financial_safety", lang)
        }
    }
}

enum SchoolAppStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress
    case applied
    case accepted
    case waitlisted
    case rejected
    case attending

    var id: String { rawValue }

    func localized(_ lang: String) -> String {
        switch self {
        case .inProgress: return l("status_in_progress", lang)
        case .applied:    return l("status_applied", lang)
        case .accepted:   return l("status_accepted", lang)
        case .waitlisted: return l("status_waitlisted", lang)
        case .rejected:   return l("status_rejected", lang)
        case .attending:  return l("status_attending", lang)
        }
    }
}

struct SavedSchoolEntry: Codable, Equatable {
    var universityName: String
    var likelihood:     SchoolLikelihood
    var appStatus:      SchoolAppStatus
}

// MARK: – Store

@MainActor
final class SavedSchoolsStore: ObservableObject {

    private static let storageKey = "mySchoolsEntries"
    /// Previous UserDefaults key storing `[String]` names only.
    private static let legacyNamesKey = "mySchoolsOrderedNames"
    /// Canonical names mentioned in Match assistant replies (substring match vs `College.name`).
    private static let aiRecommendedKey = "matchAIRecommendedCollegeNames"
    /// Names the user explicitly saved via the Discover heart (vs Match auto-add).
    private static let myChoiceKey = "mySchoolsMyChoiceNames"

    @Published private(set) var entries: [SavedSchoolEntry] = []
    @Published private(set) var aiRecommendedCollegeNames: Set<String> = []
    @Published private(set) var myChoiceCollegeNames: Set<String> = []

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([SavedSchoolEntry].self, from: data) {
            entries = decoded
        } else if let data = UserDefaults.standard.data(forKey: Self.legacyNamesKey),
                  let legacyNames = try? JSONDecoder().decode([String].self, from: data) {
            entries = legacyNames.map {
                SavedSchoolEntry(universityName: $0,
                                 likelihood: .target,
                                 appStatus: .inProgress)
            }
            persist()
            UserDefaults.standard.removeObject(forKey: Self.legacyNamesKey)
        }

        if let names = UserDefaults.standard.stringArray(forKey: Self.aiRecommendedKey) {
            aiRecommendedCollegeNames = Set(names)
        }

        if UserDefaults.standard.object(forKey: Self.myChoiceKey) != nil {
            myChoiceCollegeNames = Set(UserDefaults.standard.stringArray(forKey: Self.myChoiceKey) ?? [])
        } else {
            // First install or upgrade: existing entries were saved via heart only.
            myChoiceCollegeNames = Set(entries.map(\.universityName))
            persistMyChoice()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func persistAIRecommended() {
        UserDefaults.standard.set(Array(aiRecommendedCollegeNames.sorted()), forKey: Self.aiRecommendedKey)
    }

    private func persistMyChoice() {
        UserDefaults.standard.set(Array(myChoiceCollegeNames.sorted()), forKey: Self.myChoiceKey)
    }

    func isAIRecommended(_ universityName: String) -> Bool {
        aiRecommendedCollegeNames.contains(universityName)
    }

    func isMyChoice(_ universityName: String) -> Bool {
        myChoiceCollegeNames.contains(universityName)
    }

    /// Records canonical college names from a Match reply and marks them AI-recommended.
    /// When `addToMySchools` is true, appends any missing matches to My Schools.
    func ingestMatchAssistantRecommendations(fromAssistantText text: String,
                                           colleges: [College],
                                           addToMySchools: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var matched: Set<String> = []
        for college in colleges.sorted(by: { $0.name.count > $1.name.count }) {
            if text.range(of: college.name, options: .caseInsensitive) != nil {
                matched.insert(college.name)
            }
        }
        guard !matched.isEmpty else { return }

        var nextRec = aiRecommendedCollegeNames
        nextRec.formUnion(matched)
        aiRecommendedCollegeNames = nextRec
        persistAIRecommended()

        guard addToMySchools else { return }

        var nextEntries = entries
        let sortedNew = matched.filter { name in !nextEntries.contains(where: { $0.universityName == name }) }
            .sorted()
        guard !sortedNew.isEmpty else { return }
        for name in sortedNew {
            nextEntries.append(SavedSchoolEntry(universityName: name,
                                                 likelihood: .target,
                                                 appStatus: .inProgress))
        }
        entries = nextEntries
        persist()
    }

    func contains(_ universityName: String) -> Bool {
        entries.contains { $0.universityName == universityName }
    }

    func entry(for universityName: String) -> SavedSchoolEntry? {
        entries.first { $0.universityName == universityName }
    }

    func toggle(_ universityName: String) {
        if let idx = entries.firstIndex(where: { $0.universityName == universityName }) {
            entries.remove(at: idx)
            var choices = myChoiceCollegeNames
            choices.remove(universityName)
            myChoiceCollegeNames = choices
            persistMyChoice()
        } else {
            entries.append(SavedSchoolEntry(universityName: universityName,
                                           likelihood: .target,
                                           appStatus: .inProgress))
            var choices = myChoiceCollegeNames
            choices.insert(universityName)
            myChoiceCollegeNames = choices
            persistMyChoice()
        }
        persist()
    }

    func remove(_ universityName: String) {
        entries.removeAll { $0.universityName == universityName }
        var choices = myChoiceCollegeNames
        choices.remove(universityName)
        myChoiceCollegeNames = choices
        persist()
        persistMyChoice()
    }

    func setLikelihood(_ universityName: String, _ value: SchoolLikelihood) {
        guard let i = entries.firstIndex(where: { $0.universityName == universityName }) else { return }
        var next = entries
        next[i].likelihood = value
        entries = next
        persist()
    }

    func setAppStatus(_ universityName: String, _ value: SchoolAppStatus) {
        guard let i = entries.firstIndex(where: { $0.universityName == universityName }) else { return }
        var next = entries
        next[i].appStatus = value
        entries = next
        persist()
    }
}
