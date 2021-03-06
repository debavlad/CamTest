//
//  User.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import AVFoundation

final class User {
	static let shared = User()
	
	var exposureMode: AVCaptureDevice.ExposureMode
	var focusMode: AVCaptureDevice.FocusMode
	var torchEnabled: Bool
	var deviceHasNotch: Bool
	var bottomInset: CGFloat
	
	private init() {
		exposureMode = .continuousAutoExposure
		focusMode = .continuousAutoFocus
		torchEnabled = false
		deviceHasNotch = false
		bottomInset = 0
	}
}
