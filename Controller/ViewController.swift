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
	
	var cam: Camera!
	
	var exposureSlider, focusSlider: Slider!
	var activeSlider: Slider?
	var touchOffset: CGPoint?

	
	let blurView: UIVisualEffectView = {
		let effect = UIBlurEffect(style: .regular)
		let effectView = UIVisualEffectView(effect: effect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 0
		return effectView
	}()
	
	private let exposurePointView: UIImageView = {
		let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .ultraLight))
		let imageView = UIImageView(image: image)
		imageView.tintColor = Colors.yellow
		return imageView
	}()
	
	private let recordButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.backgroundColor = .black
		return button
	}()

	private let redCircle: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isUserInteractionEnabled = false
		view.backgroundColor = Colors.red
		view.layer.cornerRadius = 10
		return view
	}()
	
	var pc: PlayerController?
	private var lockButton, torchButton: UIButton!
	var stackView: UIStackView!
	
	
	// MARK: - Touch functions
	
	override func viewDidLoad() {
		modalPresentationStyle = .fullScreen
		super.viewDidLoad()
		view.backgroundColor = .black
		
		cam = Camera()
		cam.attach(to: view)
		
		setupSecondary()
		setupBottomButtons()
		setupSliders()
		attachActions()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		exposurePointView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
		UIView.animate(withDuration: 0.5, delay: 0.05, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform.identity
		})
	}
	
	override func viewDidLayoutSubviews() {
		stackView.arrangedSubviews.first?.roundCorners(corners: [.topLeft, .bottomLeft], radius: 18.5)
		stackView.arrangedSubviews.last?.roundCorners(corners: [.topRight, .bottomRight], radius: 18.5)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard touchOffset == nil, let touch = touches.first?.location(in: view),
			exposurePointView.frame.contains(touch) else { return }
		
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		})
		touchOffset = CGPoint(x: touch.x - exposurePointView.frame.origin.x, y: touch.y - exposurePointView.frame.origin.y)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first?.location(in: view) else { return }
		if let offset = touchOffset {
			UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
				self.exposurePointView.frame.origin = CGPoint(x: touch.x - offset.x, y: touch.y - offset.y)
			}.startAnimation()
			cam.setExposure(touch, .autoExpose)
			
		} else {
			if let slider = activeSlider {
				slider.touchesMoved(touches, with: event)
			} else {
				activeSlider = touch.x > view.frame.width/2 ? focusSlider : exposureSlider
				activeSlider?.touchesBegan(touches, with: event)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		activeSlider?.touchesEnded(touches, with: event)
		activeSlider = nil
		
		var pointOfInterest: CGPoint?
		if let _ = touchOffset, exposurePointView.frame.maxY > view.frame.height - 80 {
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.25, options: .curveEaseOut, animations: {
				self.exposurePointView.center.y = self.view.frame.height - 85 - self.exposurePointView.frame.height/2
			})
			pointOfInterest = exposurePointView.center
		}
		
		touchOffset = nil
		if let point = pointOfInterest {
			cam.setExposure(point, Settings.shared.exposureMode)
		} else {
			cam.setExposure(Settings.shared.exposureMode)
		}
		
		UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
			self.exposurePointView.transform = CGAffineTransform.identity
		})
	}
}


extension ViewController {
	
	private func setupBottomButtons() {
		lockButton = menuButton("lock.fill")
		torchButton = menuButton("bolt.fill")
		let buttons: [UIButton] = [torchButton, recordButton, lockButton]
		for button in buttons {
			NSLayoutConstraint.activate([
				button.widthAnchor.constraint(equalToConstant: 57.5),
				button.heightAnchor.constraint(equalToConstant: 55)
			])
		}
		
		stackView = UIStackView(arrangedSubviews: buttons)
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.distribution = .fillProportionally
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		])
		
		view.insertSubview(redCircle, aboveSubview: recordButton)
		NSLayoutConstraint.activate([
			redCircle.widthAnchor.constraint(equalToConstant: 20),
			redCircle.heightAnchor.constraint(equalToConstant: 20),
			redCircle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
			redCircle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor)
		])
		
		view.bringSubviewToFront(exposurePointView)
	}
	
	private func setupSliders() {
		let y = UIApplication.shared.windows[0].safeAreaInsets.top + 5
		let popup = Popup(CGPoint(x: view.center.x, y: y))
		view.addSubview(popup)
		
		exposureSlider = Slider(CGSize(width: 40, height: 280), view.frame, .left)
		exposureSlider.setImage("sun.max.fill")
		exposureSlider.customRange(-3, 3, -0.5)
		exposureSlider.popup = popup
		exposureSlider.delegate = updateExposureTargetBias
		view.addSubview(exposureSlider)
		
		focusSlider = Slider(CGSize(width: 40, height: 280), view.frame, .right)
		focusSlider.setImage("globe")
		focusSlider.customRange(0, 1, 0.4)
		focusSlider.popup = popup
		focusSlider.delegate = updateLensPosition
		view.addSubview(focusSlider)
	}
	
	private func setupSecondary() {
		// MARK:- Grid
		let v1 = UIView(frame: CGRect(x: view.frame.width/3 - 0.5, y: 0, width: 1, height: view.frame.height))
		let v2 = UIView(frame: CGRect(x: view.frame.width/3*2 - 0.5, y: 0, width: 1, height: view.frame.height))
		let h1 = UIView(frame: CGRect(x: 0, y: view.frame.height/3 - 0.5,	width: view.frame.width, height: 1))
		let h2 = UIView(frame: CGRect(x: 0, y: view.frame.height*2/3 - 0.5, width: view.frame.width, height: 1))
		for line in [v1, v2, h1, h2] {
			line.alpha = 0.2
			line.backgroundColor = .white
			line.layer.shadowColor = UIColor.black.cgColor
			line.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
			line.layer.shadowOpacity = 0.6
			line.layer.shadowRadius = 1
			line.clipsToBounds = false
			view.addSubview(line)
		}
		
		// MARK:- Exposure point & blur
		exposurePointView.center = view.center
		view.addSubview(exposurePointView)
		
		blurView.frame = view.bounds
		view.insertSubview(blurView, belowSubview: exposurePointView)
	}
	
	private func attachActions() {
		for button in [lockButton, torchButton] {
			button!.addTarget(self, action: #selector(menuButtonTouchDown(sender:)), for: .touchDown)
		}
		lockButton.addTarget(self, action: #selector(lockTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchDown), for: .touchDown)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpInside)
		recordButton.addTarget(self, action: #selector(recordTouchUp), for: .touchUpOutside)
		torchButton.addTarget(self, action: #selector(torchTouchDown), for: .touchDown)
		
		NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
	}
	
	
	@objc private func didEnterBackground() {
		if let vc = presentedViewController as? PlayerController {
			vc.queuePlayer.pause()
		} else if cam.isRecording {
			recordTouchUp()
		}
		cam.stopSession()
	}
	
	@objc private func didBecomeActive() {
		cam.startSession()
		if let vc = presentedViewController as? PlayerController {
			vc.queuePlayer.play()
		} else if Settings.shared.torchEnabled {
			cam.setTorch(.on)
		}
	}
	
	public func resetControls() {
		view.isUserInteractionEnabled = true
	}
	
	// MARK: - TouchUp & TouchDown
	
	@objc private func recordTouchDown() {
		redCircle.transform = CGAffineTransform.identity
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform(translationX: 0, y: 5)
				.scaledBy(x: 0.75, y: 0.75).rotated(by: .pi/6)
			self.recordButton.backgroundColor = Colors.recordButtonDown
		})
	}
	
	@objc private func recordTouchUp() {
		if !cam.isRecording {
			cam.startRecording(self)
			recordButton.backgroundColor = Colors.recordButtonUp
			cam.durationAnim?.addCompletion({ _ in self.recordTouchUp() })
			cam.durationAnim?.startAnimation()
		} else {
			cam.stopRecording()
			if cam.output.recordedDuration.seconds > 0.25 {
				view.isUserInteractionEnabled = false
				UIView.animate(withDuration: 0.25, delay: 0.4, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
					self.blurView.alpha = 1
				})
			}
		}
		
		let args: (CGFloat, UIColor) = cam.isRecording ? (3.5, Colors.recordButtonUp) : (10, .black)
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.redCircle.transform = CGAffineTransform.identity
			self.redCircle.layer.cornerRadius = args.0
			if !self.cam.isRecording {
				self.recordButton.backgroundColor = args.1
			}
		})
	}
	
	@objc private func lockTouchDown() {
		let isLocked = cam.device.exposureMode == .locked
		let mode: AVCaptureDevice.ExposureMode = isLocked ? .continuousAutoExposure : .locked
		Settings.shared.exposureMode = mode
		cam.setExposure(mode)
	}
	
	@objc private func menuButtonTouchDown(sender: UIButton) {
		if sender.tag == 0 {
			sender.tintColor = Colors.enabledButton
			sender.tag = 1
		} else {
			sender.tintColor = Colors.disabledButton
			sender.tag = 0
		}
		
		sender.imageView?.transform = CGAffineTransform(rotationAngle: .pi/4)
		UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [.curveLinear, .allowUserInteraction], animations: {
			sender.imageView?.transform = CGAffineTransform.identity
		})
	}
	
	@objc private func torchTouchDown() {
		let torchEnabled = cam.device.isTorchActive
		let mode: AVCaptureDevice.TorchMode = torchEnabled ? .off : .on
		Settings.shared.torchEnabled = !torchEnabled
		cam.setTorch(mode)
	}
	
	// MARK: - Secondary
	
	private func updateExposureTargetBias() {
		cam.setTargetBias(Float(exposureSlider.value))
	}
	
	private func updateLensPosition() {
		cam.setLensPosition(Float(focusSlider.value))
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	private func menuButton(_ imageName: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: imageName), for: .normal)
		button.backgroundColor = .black
		button.tintColor = Colors.disabledButton
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		return button
	}
}


extension ViewController: AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
		
		if output.recordedDuration.seconds > 0.25 {
			pc = PlayerController()
			pc?.modalPresentationStyle = .overFullScreen
			if Settings.shared.torchEnabled {
				cam.setTorch(.off)
			}
			
			pc!.setupPlayer(outputFileURL) { [weak self, weak pc] (ready) in
				if ready {
					self?.present(pc!, animated: true)
				} else {
					self?.resetControls()
					UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
						self?.blurView.alpha = 0
					})
					let error = Notification("Not enough memory", CGPoint(x: self!.view.center.x, y: self!.view.frame.height - 130))
					self?.view.addSubview(error)
					error.show()
				}
			}
		}
	}
}
