//
//  PlayerController.swift
//  CamTest
//
//  Created by debavlad on 14.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerController: UIViewController {
	
	var url: URL!
	
	let exportButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "arrow.down"), for: .normal)
		button.setTitle("Export", for: .normal)
		button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
		button.titleEdgeInsets.right = -8
		button.imageEdgeInsets.left = -8
		button.backgroundColor = .black
		button.tintColor = .systemGray
		button.setTitleColor(.systemGray, for: .normal)
		button.adjustsImageWhenHighlighted = false
		button.imageView?.clipsToBounds = false
		button.imageView?.contentMode = .center
		return button
	}()
	
	let backButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18), forImageIn: .normal)
		button.setImage(UIImage(systemName: "xmark"), for: .normal)
		button.tintColor = .systemGray3
		button.backgroundColor = .black
		button.adjustsImageWhenHighlighted = false
		return button
	}()
	
	var stackView: UIStackView!
	
	let blurEffectView: UIVisualEffectView = {
		let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
		let effectView = UIVisualEffectView(effect: blurEffect)
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.alpha = 1
		return effectView
	}()
	
	private let progressView: UIView = {
		let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.5))
		bar.backgroundColor = .systemGray2
		bar.layer.cornerRadius = 0.25
		return bar
	}()

	override func viewDidLayoutSubviews() {
		exportButton.roundCorners(corners: [.topLeft, .bottomLeft], radius: 17.5)
		backButton.roundCorners(corners: [.topRight, .bottomRight], radius: 17.5)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
//		setupPlayer()
		setupView()
		print("didload")
		
		view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		UIViewPropertyAnimator(duration: 3, curve: .easeOut) {
			self.view.transform = CGAffineTransform.identity
		}.startAnimation()
	}
	
	public func setupView() {
		view.clipsToBounds = true
		transitioningDelegate = self
		view.backgroundColor = .black
		
		view.addSubview(progressView)
		progressView.frame.origin.y = view.frame.height - 0.5
		
		exportButton.addTarget(self, action: #selector(exportTouchDown), for: .touchDown)
		exportButton.addTarget(self, action: #selector(exportTouchUp), for: [.touchUpInside, .touchUpOutside])
		backButton.addTarget(self, action: #selector(backTouchDown), for: .touchDown)
		backButton.addTarget(self, action: #selector(backTouchUp), for: [.touchUpInside, .touchUpOutside])
		NSLayoutConstraint.activate([
			exportButton.widthAnchor.constraint(equalToConstant: 110),
			exportButton.heightAnchor.constraint(equalToConstant: 50),
			backButton.widthAnchor.constraint(equalToConstant: 50),
			backButton.heightAnchor.constraint(equalToConstant: 50)
		])
		stackView = UIStackView(arrangedSubviews: [exportButton, backButton])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .center
		stackView.distribution = .equalSpacing
		stackView.clipsToBounds = true
		stackView.spacing = -5
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35)
		])
		
    blurEffectView.frame = view.bounds
		view.addSubview(blurEffectView)
	}
	
	public func setupPlayer(_ url: URL, handler: @escaping () -> ()) {
		let item = AVPlayerItem(url: url)
		let queuePlayer = AVQueuePlayer(playerItem: item)
		looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
		let layer = AVPlayerLayer(player: queuePlayer)
		layer.frame = view.frame
		layer.videoGravity = .resizeAspectFill
		layer.cornerRadius = 17.5
		layer.masksToBounds = true
		view.layer.addSublayer(layer)
		queuePlayer.play()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
			handler()
		}
	}
	
//	public func setupPlayer() {
//		queuePlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(USEC_PER_SEC)), queue: .main) { (time) in
//			guard time.seconds > 0, item.duration.seconds > 0 else {
//				self.progressView.frame.size.width = 0
//				return
//			}
//			let duration = CGFloat(time.seconds/item.duration.seconds)
//			UIViewPropertyAnimator(duration: 0.09, curve: .linear) {
//				self.progressView.frame.size.width = duration * self.view.frame.width
//			}.startAnimation()
//		}
//	}
	
	private var looper: AVPlayerLooper?
	
	@objc private func exportTouchDown() {
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.exportButton.backgroundColor = .systemGray6
		}, completion: nil)
	}
	
	@objc private func exportTouchUp() {
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform  = CGAffineTransform.identity
			self.exportButton.backgroundColor = .black
		}, completion: nil)
	}
	
	@objc private func backTouchDown() {
		UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1.25, options: [.curveLinear, .allowUserInteraction], animations: {
			self.stackView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
			self.backButton.backgroundColor = .systemRed
			self.backButton.tintColor = .white
		}, completion: nil)
		UIViewPropertyAnimator(duration: 0.4, curve: .easeOut) {
			self.view.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.95, y: 0.95)
		}.startAnimation()
	}
	
	@objc private func backTouchUp() {
		UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.stackView.transform  = CGAffineTransform.identity
//			self.backButton.backgroundColor = .black
		}, completion: nil)
		dismiss(animated: true, completion: nil)
	}
}

extension PlayerController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(0.4, .present)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return AnimationController(2, .dismiss)
	}
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
