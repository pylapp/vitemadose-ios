//
//  HomeViewController.swift
//  ViteMaDose
//
//  Created by Victor Sarda on 07/04/2021.
//

import UIKit
import SafariServices

class HomeViewController: UIViewController, Storyboarded {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var settingsButton: UIBarButtonItem!

    private lazy var homeHeaderView: HomeHeaderView = {
        let view: HomeHeaderView = HomeHeaderView.instanceFromNib()
        view.delegate = self
        return view
    }()

    private lazy var viewModel: HomeViewModelProvider = {
        let viewModel = HomeViewModel()
        viewModel.delegate = self
        return viewModel
    }()

    private lazy var countySelectionViewController: CountySelectionViewController = {
        guard let storyboard = self.storyboard else {
            fatalError("Could not find HomeViewController storyboard")
        }
        let viewController: CountySelectionViewController = storyboard.instantiateViewController(
            identifier: CountySelectionViewController.className
        )
        viewController.delegate = self
        return viewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        viewModel.fetchCounties()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.tableHeaderView = homeHeaderView
        tableView.tableHeaderView?.layoutIfNeeded()
    }

    private func configureViewController() {
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .mercury
    }

    @IBAction func settingsButtonTapped(_ sender: Any) {
        // TODO: Settings VC
    }
}

// MARK: - HomeViewModelDelegate

extension HomeViewController: HomeViewModelDelegate {
    func reloadTableView(isEmpty: Bool) {
        tableView.reloadData()
    }

    func updateLoadingState(isLoading: Bool) {
        // TODO: Loader
    }

    func displayError(withMessage message: String) {
        let errorAlert = UIAlertController(
            title: "Oops, Something Went Wrong :(",
            message: message,
            preferredStyle: .alert
        )
        present(errorAlert, animated: true)
    }
}

// MARK: - HomeHeaderViewDelegate

extension HomeViewController: HomeHeaderViewDelegate {
    func didTapSearchBarView(_ searchBarView: UIView) {
        countySelectionViewController.viewModel = CountySelectionViewModel(counties: viewModel.counties)
        present(countySelectionViewController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let cellViewModel = viewModel.cellViewModel(at: indexPath)
        cell.textLabel?.text = cellViewModel?.nom
        cell.detailTextLabel?.text = cellViewModel?.plateforme
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookingUrl = viewModel.bookingLink(at: indexPath) else {
            // TODO: Error
            return
        }

        let safariViewControllerConfig = SFSafariViewController.Configuration()
        let safariViewController = SFSafariViewController(url: bookingUrl, configuration: safariViewControllerConfig)
        present(safariViewController, animated: true)
    }
}

// MARK: - CountySelectionViewControllerDelegate

extension HomeViewController: CountySelectionViewControllerDelegate {
    func didSelect(county: County) {
        viewModel.fetchVaccinationCentre(for: county)
        homeHeaderView.updateTitle(for: county)
    }
}
