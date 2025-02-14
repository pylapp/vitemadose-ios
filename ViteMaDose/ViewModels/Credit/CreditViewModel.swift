// Software Name: vitemadose-ios
// SPDX-FileCopyrightText: Copyright (c) 2021 CovidTracker.fr
// SPDX-License-Identifier: GNU General Public License v3.0 or later
//
// This software is distributed under the GPL-3.0-or-later license.

import Foundation

// MARK: - Credit View Model Provider

protocol CreditViewModelProvider {
    var numberOfSections: Int { get }
    func numberOfRows(in section: Int) -> Int
    func cellViewModel(at indexPath: IndexPath) -> CreditCellViewDataProvider?
}

// MARK: - Credit View Model Delegate

protocol CreditViewModelDelegate: AnyObject {
    func reloadTableView(with credits: [Credit])
    func openURL(url: URL)
    func updateLoadingState(isLoading: Bool, isEmpty: Bool)
    func presentLoadError(_ error: Error)
}

// MARK: - Credit View Model

class CreditViewModel: CreditViewModelProvider {

    private let apiService: BaseAPIServiceProvider
    weak var delegate: CreditViewModelDelegate?

    private var allCredits: [Credit] = []
    private var isLoading = false {
        didSet {
            let isEmpty = allCredits.count == 0
            delegate?.updateLoadingState(isLoading: isLoading, isEmpty: isEmpty)
        }
    }

    var numberOfSections = 1

    func numberOfRows(in section: Int) -> Int {
        allCredits.count
    }

    // MARK: Init

    required init(
        apiService: BaseAPIServiceProvider = BaseAPIService(),
        credits: [Credit]
    ) {
        self.apiService = apiService
        self.allCredits = credits

        delegate?.reloadTableView(with: credits)
    }

    func cellViewModel(at indexPath: IndexPath) -> CreditCellViewDataProvider? {
        guard let credit = allCredits[safe: indexPath.row] else {
            assertionFailure("No credit found at IndexPath \(indexPath)")
            return nil
        }

        let creditLink: URL? = {
            if let url = URL(string: credit.site_web.emptyIfNil) {
                return url
            } else if let url = URL(string: (credit.links?.first?.url).emptyIfNil) {
                return url
            }
            return nil
        }()

        return CreditCellViewData(
            creditName: credit.shownName,
            creditRole: AccessibilityString(rawValue: pretty(toDiplay: credit.shownRole), vocalizedValue: pretty(toVocalize: credit.shownRole)),
            creditLink: creditLink,
            creditImage: credit.photo
        )
    }

    // MARK: - Utilities

    /// Improves the role to have something with correct syntaxes
    /// - Parameter role: The string to improve
    /// - Returns: String
    private func pretty(toDiplay role: String) -> String {
        return role
            .replacingOccurrences(of: "ios", with: "iOS")
            .replacingOccurrences(of: "android", with: "Android")
    }

    /// Improves the role to have something with better vocalization with Voice Over
    /// - Parameter role: The string to improve
    /// - Returns: String
    private func pretty(toVocalize role: String) -> String {
        return role
            .replacingOccurrences(of: "ios", with: "application iOS")
            .replacingOccurrences(of: "android", with: "application Androïd") // Vocalization (╯°□°)╯︵ ┻━┻
            .replacingOccurrences(of: "scrap", with: "analyse et traitement des données")
            .replacingOccurrences(of: "infra", with: "infrastructure")
            .replacingOccurrences(of: "web", with: "application web")
    }

    // MARK: Load of data

    func load() {
        guard !isLoading else { return }
        isLoading = true

        apiService.fetchCredits { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case let .success(credits):
                self.handleLoad(with: credits.contributors ?? [])
            case let .failure(status):
                self.handleError(status)
            }
        }
    }

    private func handleLoad(with credits: [Credit]) {
        self.allCredits = credits
            .unique(by: \.pseudo)
            .sorted(by: { $0.shownName < $1.shownName })
        delegate?.reloadTableView(with: self.allCredits)
    }

    private func handleError(_ error: Error) {
        delegate?.presentLoadError(error)
    }
}
