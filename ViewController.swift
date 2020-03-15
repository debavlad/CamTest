//
//  ViewController.swift
//  CamTest
//
//  Created by debavlad on 07.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
	
	var redBtn: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.backgroundColor = .systemRed
		button.layer.cornerRadius = 25
		return button
	}()
	
	let lightBtn: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27.5), forImageIn: .normal)
		button.setImage(UIImage(systemName: "bolt"), for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.imageView!.addShadow(2.5, 0.3)
		button.tintColor = .white
		button.layer.cornerRadius = 25
		button.alpha = 0.5
		return button
	}()
	
	let lockBtn: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27.5), forImageIn: .normal)
		button.setImage(UIImage(systemName: "lock"), for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.imageView!.addShadow(2.5, 0.3)
		button.tintColor = .white
		button.layer.cornerRadius = 25
		button.alpha = 0.5
		return button
	}()
	
	let poiView: UIImageView = {
		let image = UIImage(systemName: "viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 70, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = .systemYellow
		imageView.addShadow(1, 0.125)
//		imageView.alpha = 0.5
		return imageView
	}()
	
	var progressBar: UIView!
	
	var captureSession: AVCaptureSession?
	var captureDevice: AVCaptureDevice?
	var previewLayer: AVCaptureVideoPreviewLayer?
	var videoFileOutput: AVCaptureMovieFileOutput?
	var filePath: URL?
	
	var isRecording: Bool = false
	var exposureBar, focusBar: VerticalProgressBar!
	var activeBar: VerticalProgressBar?
	var touchOffset: CGPoint?
	var progressAnim: UIViewPropertyAnimator?
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.layer.cornerRadius = 6
		view.clipsToBounds = true
		
		setCamera()
		setButtons()
		setSliders()
		setPoint()
		setGrid()
		setProgressBar()
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard touchOffset == nil, let touch = touches.first?.location(in: view),
			poiView.frame.contains(touch) else { return }

		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.poiView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
			self.touchOffset = CGPoint(x: touch.x - self.poiView.frame.origin.x,
															 y: touch.y - self.poiView.frame.origin.y)
			self.poiView.alpha = 1
		}, completion: nil)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = touchOffset {
			// Point of interest
			poiView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			let point = previewLayer?.captureDevicePointConverted(fromLayerPoint: touch)
			do {
				try captureDevice?.lockForConfiguration()
				captureDevice?.exposurePointOfInterest = point!
				captureDevice?.exposureMode = .autoExpose
				captureDevice?.unlockForConfiguration()
			} catch { }
			
		} else {
			// Progress bar
			if activeBar == nil {
				activeBar = touch.x > view.frame.width/2 ? focusBar : exposureBar
				activeBar?.touchesBegan(touches, with: event)
			} else {
				activeBar?.touchesMoved(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeBar?.touchesEnded(touches, with: event)
		activeBar = nil; touchOffset = nil
		
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
			self.poiView.transform = CGAffineTransform(scaleX: 1, y: 1)
//			self.poiView.alpha = 0.5
		}, completion: nil)
	}
}


extension ViewController {
	
	private func setGrid() {
		let v1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5, y: 0, width: 1, height: view.frame.height))
		let v2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5, y: 0, width: 1, height: view.frame.height))
		let h1 = UIView(frame: CGRect(x: 0, y: view.frame.height/3 - 0.5,	width: view.frame.width, height: 1))
		let h2 = UIView(frame: CGRect(x: 0, y: view.frame.height*2/3 - 0.5, width: view.frame.width, height: 1))
		
		for line in [v1, v2, h1, h2] {
			line.alpha = 0.2
			line.backgroundColor = .white
			line.addShadow(1, 0.6)
			view.addSubview(line)
		}
	}
	
	private func setCamera() {
		// Session
		captureSession = AVCaptureSession()
		captureSession?.sessionPreset = .hd1920x1080
		
		// Devices
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		captureDevice = devices.first { $0.position == .back }
		
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setFocusModeLocked(lensPosition: 0.5, completionHandler: nil)
			captureDevice?.setExposureTargetBias(-1, completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
		
		// Input-output
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice!)
			captureSession?.addInput(deviceInput)
			
			let audioDevice = AVCaptureDevice.default(for: .audio)
			let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
			captureSession?.addInput(audioInput)
			
			videoFileOutput = AVCaptureMovieFileOutput()
			videoFileOutput?.movieFragmentInterval = CMTime.invalid
			captureSession?.addOutput(videoFileOutput!)
			videoFileOutput!.connection(with: .video)!.preferredVideoStabilizationMode = .cinematic
		} catch {}
		
		let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		filePath = documentsURL.appendingPathComponent("output.mov")
		
		// Preview layer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		previewLayer?.videoGravity = .resizeAspectFill
		previewLayer?.frame = view.frame
		previewLayer?.connection?.videoOrientation = .portrait
		self.view.layer.insertSublayer(previewLayer!, at: 0)
		
		captureSession?.startRunning()
	}
	
	private func setButtons() {
		// Recording
		let whiteCircle = UIButton()
		whiteCircle.translatesAutoresizingMaskIntoConstraints = false
		whiteCircle.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
		whiteCircle.layer.cornerRadius = 32.5
		whiteCircle.layer.borderColor = UIColor.white.cgColor
		whiteCircle.layer.borderWidth = 5
		whiteCircle.addShadow(2.5, 0.15)
		view.addSubview(whiteCircle)
		NSLayoutConstraint.activate([
			whiteCircle.widthAnchor.constraint(equalToConstant: 65),
			whiteCircle.heightAnchor.constraint(equalToConstant: 65),
			whiteCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			whiteCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35)
		])
		
		view.insertSubview(redBtn, belowSubview: whiteCircle)
		whiteCircle.addTarget(self, action: #selector(shotTouchDown), for: .touchDown)
		whiteCircle.addTarget(self, action: #selector(shotTouchUp), for: .touchUpInside)
		whiteCircle.addTarget(self, action: #selector(shotTouchUp), for: .touchUpOutside)
		NSLayoutConstraint.activate([
			redBtn.widthAnchor.constraint(equalToConstant: 50),
			redBtn.heightAnchor.constraint(equalToConstant: 50),
			redBtn.centerXAnchor.constraint(equalTo: whiteCircle.centerXAnchor),
			redBtn.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor)
		])
		
		// Light
		let offset = view.frame.width/3
		view.addSubview(lightBtn)
		lightBtn.addTarget(self, action: #selector(btnTouchDown(button:)), for: .touchDown)
		lightBtn.addTarget(self, action: #selector(btnTouchUp(button:)), for: [.touchUpInside, .touchUpOutside])
		lightBtn.addTarget(self, action: #selector(lightTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			lightBtn.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor),
			lightBtn.widthAnchor.constraint(equalToConstant: 50),
			lightBtn.heightAnchor.constraint(equalToConstant: 50),
			lightBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
		])
		
		view.addSubview(lockBtn)
		lockBtn.addTarget(self, action: #selector(btnTouchDown(button:)), for: .touchDown)
		lockBtn.addTarget(self, action: #selector(btnTouchUp(button:)), for: [.touchUpInside, .touchUpOutside])
		lockBtn.addTarget(self, action: #selector(lockTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			lockBtn.centerYAnchor.constraint(equalTo: whiteCircle.centerYAnchor),
			lockBtn.widthAnchor.constraint(equalToConstant: 50),
			lockBtn.heightAnchor.constraint(equalToConstant: 50),
			lockBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -offset)
		])
	}
	
	private func setSliders() {
		exposureBar = VerticalProgressBar(frame: CGRect(x: 0, y: view.frame.midY, width: 55, height: 250), true, "sun.max.fill", "sun.min")
		exposureBar.valueChanged = exposureValueChanged
		exposureBar.alpha = 0
		exposureBar.setValue(-1)
		view.addSubview(exposureBar)

		focusBar = VerticalProgressBar(frame: CGRect(x: view.frame.maxX, y: view.frame.midY, width: 55, height: 260), false, "plus.magnifyingglass", "minus.magnifyingglass")
		focusBar.valueChanged = focusValueChanged
		focusBar.alpha = 0
		focusBar.setValue(0.5)
		view.addSubview(focusBar)
	}
	
	private func setPoint() {
		guard let p = previewLayer?.layerPointConverted(fromCaptureDevicePoint: captureDevice!.exposurePointOfInterest) else { return }
		poiView.center = p
		view.addSubview(poiView)
	}
	
	private func setProgressBar() {
		progressBar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 3))
		progressBar.backgroundColor = .white
		progressBar.layer.cornerRadius = 1.5
		progressBar.addShadow(2.5, 0.15)
		view.addSubview(progressBar)
	}
	
	
	@objc private func shotTouchDown() {
		let scale: CGFloat = isRecording ? 0.45 : 0.9
		UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.redBtn.transform = CGAffineTransform(scaleX: scale, y: scale)
		}, completion: nil)
	}
	
	@objc private func shotTouchUp() {
		let settings: (CGFloat, CGFloat) = isRecording ? (1, 25) : (0.55, 10)
		isRecording = !isRecording
		if isRecording {
			videoFileOutput!.startRecording(to: filePath!, recordingDelegate: self)
			progressAnim = UIViewPropertyAnimator(duration: 15, curve: .linear, animations: {
				self.progressBar.frame.size.width = self.view.frame.width
			})
			progressAnim?.addCompletion({ (_) in self.shotTouchUp() })
			progressAnim?.startAnimation()
			
		} else {
			videoFileOutput?.stopRecording()
			progressAnim?.stopAnimation(true)
			progressAnim = nil
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.5, options: .curveEaseOut, animations: {
				self.progressBar.frame.size.width = 0
			}, completion: nil)
		}
		
		UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.redBtn.transform = CGAffineTransform(scaleX: settings.0, y: settings.0)
			self.redBtn.layer.cornerRadius = settings.1
		}, completion: nil)
	}
	
	@objc private func btnTouchDown(button: UIButton) {
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
			button.transform = CGAffineTransform(scaleX: 1, y: 1)
			button.alpha = 0.5
		}, completion: nil)
	}
	
	@objc private func btnTouchUp(button: UIButton) {
		UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
			button.transform = CGAffineTransform(scaleX: 1, y: 1)
		}, completion: nil)
	}
	
	@objc private func lockTouchUp() {
		let isLocked = captureDevice?.exposureMode == .locked
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.exposureMode = isLocked ? .continuousAutoExposure : .locked
			UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
			captureDevice?.unlockForConfiguration()
		} catch {}
		lockBtn.setImage(UIImage(systemName: isLocked ? "lock" : "lock.fill"), for: .normal)
		lockBtn.alpha = isLocked ? 0.5 : 1
	}
	
	@objc private func lightTouchUp() {
		if captureDevice!.hasTorch {
			let torchEnabled = captureDevice!.isTorchActive
			do {
				try captureDevice?.lockForConfiguration()
				captureDevice?.torchMode = torchEnabled ? .off : .on
				UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
				captureDevice?.unlockForConfiguration()
			} catch {}
			lightBtn.setImage(UIImage(systemName: torchEnabled ? "bolt.slash" : "bolt.fill"), for: .normal)
			lightBtn.alpha = torchEnabled ? 0.5 : 1
		}
	}
	
	
	private func exposureValueChanged() {
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setExposureTargetBias(Float(exposureBar!.indicatorValue), completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	private func focusValueChanged() {
		do {
			try captureDevice?.lockForConfiguration()
			captureDevice?.setFocusModeLocked(lensPosition: Float(focusBar!.indicatorValue), completionHandler: nil)
			captureDevice?.unlockForConfiguration()
		} catch {}
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		let playerView = PlayerController()
		playerView.url = outputFileURL
		playerView.modalPresentationStyle = .overFullScreen
		present(playerView, animated: true)
//		playerView.viewDidLoad()
//		playerView.view.transform = CGAffineTransform(scaleX: 0, y: 0)
//		addChild(playerView)
//		view.addSubview(playerView.view)
//		UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
//			playerView.view.transform = CGAffineTransform(scaleX: 1, y: 1)
//
//		}, completion: nil)
//		UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
	}
}

extension UIView {
	func addShadow(_ radius: CGFloat, _ opacity: Float) {
		self.layer.shadowColor = UIColor.black.cgColor
		self.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
		self.layer.shadowOpacity = opacity
		self.layer.shadowRadius = radius
		self.clipsToBounds = false
	}
}
