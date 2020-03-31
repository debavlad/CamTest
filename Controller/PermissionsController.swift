//
//  PermissionsController.swift
//  CamTest
//
//  Created by debavlad on 21.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import Photos
import AudioToolbox

class PermissionsController: UIViewController {
	
	let bottomLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = "Grant to start"
		label.textColor = Colors.backIcon
		label.font = UIFont.systemFont(ofSize: 19, weight: .light)
		return label
	}()
	
	var cameraButton, libraryButton, micButton: UIButton!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = Colors.permissionBackground
		setupView()
	}
	
	private func setupView() {
		libraryButton = grantButton("photo.fill")
		setButtonAppearance(libraryButton, PHPhotoLibrary.authorizationStatus() == .authorized)
		libraryButton.addTarget(self, action: #selector(libraryButtonTouchDown), for: .touchDown)
		view.addSubview(libraryButton)
		NSLayoutConstraint.activate([
			libraryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			libraryButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -15),
		])
		
		cameraButton = grantButton("camera.fill")
		setButtonAppearance(cameraButton, AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
		cameraButton.addTarget(self, action: #selector(cameraButtonTouchDown), for: .touchDown)
		view.addSubview(cameraButton)
		NSLayoutConstraint.activate([
			cameraButton.trailingAnchor.constraint(equalTo: libraryButton.leadingAnchor, constant: -15),
			cameraButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor)
		])

		micButton = grantButton("mic.fill")
		setButtonAppearance(micButton, AVAudioSession.sharedInstance().recordPermission == .granted)
		micButton.addTarget(self, action: #selector(micButtonTouchDown), for: .touchDown)
		view.addSubview(micButton)
		NSLayoutConstraint.activate([
			micButton.leadingAnchor.constraint(equalTo: libraryButton.trailingAnchor, constant: 15),
			micButton.centerYAnchor.constraint(equalTo: libraryButton.centerYAnchor)
		])

		view.addSubview(bottomLabel)
		NSLayoutConstraint.activate([
			bottomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			bottomLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
		])

		// MARK: - Animation

		UIView.animate(withDuration: 0.5, delay: 0.12, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [], animations: {
			self.libraryButton.transform = CGAffineTransform(translationX: 0, y: 20)
			self.cameraButton.transform = CGAffineTransform(translationX: 0, y: 20)
			self.micButton.transform = CGAffineTransform(translationX: 0, y: 20)
			self.libraryButton.alpha = 1
			self.cameraButton.alpha = 1
			self.micButton.alpha = 1
		})
	}
	
	
	@objc private func libraryButtonTouchDown() {
		if PHPhotoLibrary.authorizationStatus() == .denied {
			showAlert("Photo Library Access Denied", "Photo Library access was previously denied. You must grant it through system settings")
		} else {
			PHPhotoLibrary.requestAuthorization { (status) in
				if status != .authorized { return }
				self.setButtonAppearance(self.libraryButton, true)
			}
		}
	}
	
	@objc private func cameraButtonTouchDown() {
		if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
			showAlert("Camera Access Denied", "Camera access was previously denied. You must grant it through system settings")
		} else {
			AVCaptureDevice.requestAccess(for: .video) { (granted) in
				if !granted { return }
				self.setButtonAppearance(self.cameraButton, true)
			}
		}
	}
	
	@objc private func micButtonTouchDown() {
		if AVAudioSession.sharedInstance().recordPermission == .denied {
			showAlert("Microphone Access Denied", "Microphone access was previously denied. You must grant it through system settings")
		} else {
			AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
				if !granted { return }
				self.setButtonAppearance(self.micButton, true)
			}
		}
	}
	
	
	private func grantButton(_ imageName: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27, weight: .light), forImageIn: .normal)
		button.setImage(UIImage(systemName: imageName), for: .normal)
		button.tintColor = Colors.permissionIcon
		button.layer.borderWidth = 1.5
		button.layer.borderColor = Colors.permissionBorder.cgColor
		button.layer.cornerRadius = 17.5
		button.alpha = 0
		button.adjustsImageWhenHighlighted = false
		
		NSLayoutConstraint.activate([
			button.widthAnchor.constraint(equalToConstant: 70),
			button.heightAnchor.constraint(equalToConstant: 70)
		])
		return button
	}
	
	private func showAlert(_ title: String, _ message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
		alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) in
			if let url = URL(string: UIApplication.openSettingsURLString) {
				if UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}
			}
		}))
		present(alert, animated: true)
	}
	
	private func setButtonAppearance(_ button: UIButton, _ accessGranted: Bool) {
		DispatchQueue.main.async {
			switch accessGranted {
				case true:
					button.backgroundColor = Colors.permissionIcon
					button.layer.borderColor = Colors.permissionIcon.cgColor
					button.tintColor = Colors.permissionBackground
				case false:
					button.backgroundColor = Colors.permissionBackground
					button.layer.borderColor = Colors.permissionBorder.cgColor
					button.tintColor = Colors.permissionIcon
			}
			
			if PermissionsController.grantedCount() == 3 {
				let vc = CameraController()
				vc.modalPresentationStyle = .fullScreen
				self.present(vc, animated: true)
			}
		}
	}
	
	static func grantedCount() -> Int {
		var granted = 0
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			granted += 1
		}
		if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
			granted += 1
		}
		if AVAudioSession.sharedInstance().recordPermission == .granted {
			granted += 1
		}
		return granted
	}
}
