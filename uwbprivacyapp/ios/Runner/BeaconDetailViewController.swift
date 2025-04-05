//
//  BeaconDetailViewController 2.swift
//  Runner
//
//  Created by Harika Arimilli on 4/5/25.
//

import UIKit

class BeaconDetailViewController: UIViewController {
    
    // MARK: - Passed-in Data
    var deviceID: Int = -1
    var deviceName: String?

    // MARK: - UI Elements
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .darkGray
        return label
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        populateData()
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .white
        title = deviceName ?? "Beacon Details"
        view.addSubview(infoLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func populateData() {
        infoLabel.text = """
        📡 Beacon Details

        Device Name: \(deviceName ?? "Unknown")
        Device ID: \(deviceID)
        """
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

