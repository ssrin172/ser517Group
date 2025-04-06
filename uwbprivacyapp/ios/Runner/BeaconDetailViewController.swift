//
//  BeaconDetailViewController 2.swift
//  Runner
//
//  Created by Harika Arimilli on 4/5/25.
//
import UIKit
import simd

class BeaconDetailViewController: UIViewController {

    // MARK: - Passed-in Data
    var deviceID: Int = -1
    var deviceName: String?
    var distance: Float = 0.0 {
        didSet { updateFields() }
    }
    var azimuth: Int = 0 {
        didSet { updateFields() }
    }
    var elevation: Int = 0 {
        didSet { updateFields() }
    }

    // MARK: - UI Elements
    private func labeledRow(icon: String, title: String, valueLabel: UILabel) -> UIStackView {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .systemBlue
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconView, titleLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.distribution = .fill
        return row
    }

    private let nameValueLabel = UILabel()
    private let idValueLabel = UILabel()
    private let distanceValueLabel = UILabel()
    private let azimuthValueLabel = UILabel()
    private let elevationValueLabel = UILabel()
    private let mitigationValueLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Beacon Details"
        setupLayout()
        populateInitialInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Layout
    private func setupLayout() {
        let nameRow = labeledRow(icon: "tag", title: "Device Name", valueLabel: nameValueLabel)
        let idRow = labeledRow(icon: "number", title: "Device ID", valueLabel: idValueLabel)
        let distanceRow = labeledRow(icon: "ruler", title: "Distance", valueLabel: distanceValueLabel)
        let azimuthRow = labeledRow(icon: "location.north.line", title: "Azimuth", valueLabel: azimuthValueLabel)
        let elevationRow = labeledRow(icon: "arrow.up.and.down", title: "Elevation", valueLabel: elevationValueLabel)
        let mitigationRow = labeledRow(icon: "exclamationmark.shield", title: "Mitigation", valueLabel: mitigationValueLabel)

        let stack = UIStackView(arrangedSubviews: [nameRow, idRow, distanceRow, azimuthRow, elevationRow, mitigationRow])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func populateInitialInfo() {
        nameValueLabel.text = deviceName ?? "--"
        idValueLabel.text = "\(deviceID)"
        distanceValueLabel.text = "--"
        azimuthValueLabel.text = "--"
        elevationValueLabel.text = "--"
        mitigationValueLabel.text = "Waiting..."
        mitigationValueLabel.textColor = .secondaryLabel
    }

    // MARK: - Update
    private func updateFields() {
        distanceValueLabel.text = String(format: "%.2f m", distance)
        azimuthValueLabel.text = "\(azimuth)°"
        elevationValueLabel.text = "\(elevation)°"

        if distance < 0.5 {
            mitigationValueLabel.text = "🚨 TOO CLOSE"
            mitigationValueLabel.textColor = .systemRed
        } else if distance < 1.5 {
            mitigationValueLabel.text = "⚠️ Move slightly away"
            mitigationValueLabel.textColor = .systemOrange
        } else {
            mitigationValueLabel.text = "✅ Safe distance"
            mitigationValueLabel.textColor = .systemGreen
        }
    }
}
