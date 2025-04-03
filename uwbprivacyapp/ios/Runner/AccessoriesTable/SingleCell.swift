/*
 * @file      SingleCell.swift
 *
 * @brief     Class to handle components inside Table's View Prototype Cell
 *
 * @author    Decawave Applications
 *
 * @attention Copyright (c) 2021 - 2022, Qorvo US, Inc.
 * All rights reserved
 * Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice, this
 *  list of conditions, and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *  this list of conditions and the following disclaimer in the documentation
 *  and/or other materials provided with the distribution.
 * 3. You may only use this software, with or without any modification, with an
 *  integrated circuit developed by Qorvo US, Inc. or any of its affiliates
 *  (collectively, "Qorvo"), or any module that contains such integrated circuit.
 * 4. You may not reverse engineer, disassemble, decompile, decode, adapt, or
 *  otherwise attempt to derive or gain access to the source code to any software
 *  distributed under this license in binary or object code form, in whole or in
 *  part.
 * 5. You may not use any Qorvo name, trademarks, service marks, trade dress,
 *  logos, trade names, or other symbols or insignia identifying the source of
 *  Qorvo's products or services, or the names of any of Qorvo's developers to
 *  endorse or promote products derived from this software without specific prior
 *  written permission from Qorvo US, Inc. You must not call products derived from
 *  this software "Qorvo", you must not have "Qorvo" appear in their name, without
 *  the prior permission from Qorvo US, Inc.
 * 6. Qorvo may publish revised or new version of this license from time to time.
 *  No one other than Qorvo US, Inc. has the right to modify the terms applicable
 *  to the software provided under this license.
 * THIS SOFTWARE IS PROVIDED BY QORVO US, INC. "AS IS" AND ANY EXPRESS OR IMPLIED
 *  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. NEITHER
 *  QORVO, NOR ANY PERSON ASSOCIATED WITH QORVO MAKES ANY WARRANTY OR
 *  REPRESENTATION WITH RESPECT TO THE COMPLETENESS, SECURITY, RELIABILITY, OR
 *  ACCURACY OF THE SOFTWARE, THAT IT IS ERROR FREE OR THAT ANY DEFECTS WILL BE
 *  CORRECTED, OR THAT THE SOFTWARE WILL OTHERWISE MEET YOUR NEEDS OR EXPECTATIONS.
 * IN NO EVENT SHALL QORVO OR ANYBODY ASSOCIATED WITH QORVO BE LIABLE FOR ANY
 *  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 *
 */
import UIKit

enum asset: String {
    case actionButton = "Button to Connect"
    case connecting   = "Animated Icon"
    case miniLocation = "Panel with TWR info"
}

class SingleCell: UITableViewCell {
    
    let backgroundContainer: UIView
    let accessoryButton: UIButton
    let miniLocation: UIView
    let actionButton: UIButton
    let connecting: UIImageView
    let bottomBar: UIImageView
    let detailsButton: UIButton

    let azimuthLabel: UITextField
    let miniArrow: UIImageView
    let pipe: UIImageView
    let distanceLabel: UITextField

    var imageLoading = [UIImage]()
    var uniqueID: Int = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        backgroundContainer = UIView()
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainer.layer.cornerRadius = 12
        backgroundContainer.clipsToBounds = true
        backgroundContainer.backgroundColor = .white
        
        accessoryButton = UIButton()
        accessoryButton.titleLabel?.font = .dinNextRegular_s
        accessoryButton.setTitleColor(.black, for: .normal)
        accessoryButton.contentHorizontalAlignment = .left
        accessoryButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        accessoryButton.translatesAutoresizingMaskIntoConstraints = false

        miniLocation = UIView()
        miniLocation.translatesAutoresizingMaskIntoConstraints = false

        azimuthLabel = UITextField()
        azimuthLabel.translatesAutoresizingMaskIntoConstraints = false
        azimuthLabel.font = .dinNextMedium_s
        azimuthLabel.textAlignment = .right
        azimuthLabel.textColor = .black
        azimuthLabel.text = "StartDegrees".localized

        miniArrow = UIImageView(image: UIImage(named: "arrow_small"))
        miniArrow.translatesAutoresizingMaskIntoConstraints = false

        pipe = UIImageView(image: UIImage(named: "subheading"))
        pipe.contentMode = .scaleAspectFit
        pipe.translatesAutoresizingMaskIntoConstraints = false

        distanceLabel = UITextField()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = .dinNextMedium_s
        distanceLabel.textAlignment = .right
        distanceLabel.textColor = .black
        distanceLabel.text = "StartMeters".localized

        actionButton = UIButton()
        actionButton.titleLabel?.font = .dinNextMedium_m
        actionButton.setTitleColor(.qorvoBlue, for: .normal)
        actionButton.setTitle("Connect".localized, for: .normal)
        actionButton.contentHorizontalAlignment = .right
        actionButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        detailsButton = UIButton(type: .system)
                detailsButton.setTitle("Details", for: .normal)
                detailsButton.setTitleColor(.systemBlue, for: .normal)
                detailsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                 detailsButton.isHidden = false
                detailsButton.translatesAutoresizingMaskIntoConstraints = false
        connecting = UIImageView()
        connecting.contentMode = .scaleAspectFit
        connecting.translatesAutoresizingMaskIntoConstraints = false

        bottomBar = UIImageView(image: UIImage(named: "bar"))
        bottomBar.contentMode = .scaleAspectFit
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        // Assemble miniLocation view
        miniLocation.addSubview(distanceLabel)
        miniLocation.addSubview(pipe)
        miniLocation.addSubview(miniArrow)
        miniLocation.addSubview(azimuthLabel)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(backgroundContainer)
        backgroundContainer.addSubview(accessoryButton)
        backgroundContainer.addSubview(miniLocation)
        backgroundContainer.addSubview(actionButton)
        backgroundContainer.addSubview(detailsButton)
        backgroundContainer.addSubview(connecting)
        backgroundContainer.addSubview(bottomBar)

        // Spinner animation
        if let imageSmall = UIImage(named: "spinner_small") {
            for i in 0...24 {
                if let rotated = imageSmall.rotate(radians: Float(i) * .pi / 12) {
                    imageLoading.append(rotated)
                }
            }
        }
        connecting.animationImages = imageLoading
        connecting.animationDuration = 1

        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            backgroundContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            backgroundContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            backgroundContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            accessoryButton.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            accessoryButton.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
            accessoryButton.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            accessoryButton.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),

            actionButton.centerYAnchor.constraint(equalTo: backgroundContainer.centerYAnchor),
            actionButton.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor, constant: -20),
            actionButton.widthAnchor.constraint(equalToConstant: ACTION_BUTTON_WIDTH_CONSTRAINT),
            
            detailsButton.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor, constant: -20),
                        detailsButton.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor, constant: -8),
                        detailsButton.heightAnchor.constraint(equalToConstant: 28),
                        detailsButton.widthAnchor.constraint(equalToConstant: 100),
            
            connecting.centerYAnchor.constraint(equalTo: backgroundContainer.centerYAnchor),
            connecting.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor, constant: -20),
            connecting.widthAnchor.constraint(equalToConstant: CONNECTING_SIDE_CONSTRAINT),
            connecting.heightAnchor.constraint(equalToConstant: CONNECTING_SIDE_CONSTRAINT),

            bottomBar.centerXAnchor.constraint(equalTo: backgroundContainer.centerXAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor, constant: -1),
            bottomBar.widthAnchor.constraint(equalToConstant: BOTTOM_BAR_WIDTH_CONSTRAINT),
            bottomBar.heightAnchor.constraint(equalToConstant: BOTTOM_BAR_HEIGHT_CONSTRAINT),

            miniLocation.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            miniLocation.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor),
            miniLocation.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            miniLocation.widthAnchor.constraint(equalToConstant: MINI_LOCATION_WIDTH_CONSTRAINT),

            distanceLabel.centerYAnchor.constraint(equalTo: miniLocation.centerYAnchor),
            distanceLabel.trailingAnchor.constraint(equalTo: miniLocation.trailingAnchor, constant: -20),
            distanceLabel.widthAnchor.constraint(equalToConstant: DISTANCE_LABEL_WIDTH_CONSTRAINT),

            pipe.centerYAnchor.constraint(equalTo: miniLocation.centerYAnchor),
            pipe.trailingAnchor.constraint(equalTo: distanceLabel.leadingAnchor),
            pipe.widthAnchor.constraint(equalToConstant: PIPE_SIDE_CONSTRAINT),
            pipe.heightAnchor.constraint(equalToConstant: PIPE_SIDE_CONSTRAINT),

            miniArrow.centerYAnchor.constraint(equalTo: miniLocation.centerYAnchor),
            miniArrow.trailingAnchor.constraint(equalTo: pipe.leadingAnchor, constant: -6),
            miniArrow.widthAnchor.constraint(equalToConstant: MINI_ARROW_SIDE_CONSTRAINT),
            miniArrow.heightAnchor.constraint(equalToConstant: MINI_ARROW_SIDE_CONSTRAINT),

            azimuthLabel.centerYAnchor.constraint(equalTo: miniLocation.centerYAnchor),
            azimuthLabel.trailingAnchor.constraint(equalTo: miniArrow.leadingAnchor, constant: -6),
            azimuthLabel.widthAnchor.constraint(equalToConstant: AZIMUTH_LABEL_WIDTH_CONSTRAINT)
        ])

        backgroundColor = .clear
        selectAsset(.actionButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundContainer.backgroundColor = .white
        accessoryButton.setTitleColor(.black, for: .normal)
    }

    func selectAsset(_ asset: asset) {
        switch asset {
        case .actionButton:
            miniLocation.isHidden = true
            actionButton.isHidden = false
            connecting.isHidden   = true
            detailsButton.isHidden = true
            connecting.stopAnimating()
        case .connecting:
            miniLocation.isHidden = true
            actionButton.isHidden = true
            connecting.isHidden   = false
            detailsButton.isHidden = true
            connecting.startAnimating()
        case .miniLocation:
            miniLocation.isHidden = false
            actionButton.isHidden = true
            connecting.isHidden   = true
            detailsButton.isHidden = false
            connecting.stopAnimating()
        }
    }
}
