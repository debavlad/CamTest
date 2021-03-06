//
//  MovablePoint.swift
//  Flaneur
//
//  Created by debavlad on 27.03.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import UIKit

final class MovablePoint : UIImageView {
	
	var cam: Camera?
	private var touchOffset: CGPoint?
	var moved, ended: (() -> ())?
	
	init(symbolName: String? = nil) {
    let image = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48, weight: .ultraLight))
		super.init(image: image)
		isUserInteractionEnabled = true
		tintColor = .systemYellow
		
		if let name = symbolName {
			let image = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .thin))
			let imageView = UIImageView(image: image)
			imageView.tintColor = .white
			imageView.center = center
			addSubview(imageView)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchPoint = touches.first!.location(in: superview!)
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		})
		touchOffset = CGPoint(x: touchPoint.x - frame.origin.x, y: touchPoint.y - frame.origin.y)
		UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let touchPoint = touches.first!.location(in: superview!)
		if let offset = touchOffset {
			UIViewPropertyAnimator(duration: 0.05, curve: .easeOut) {
				self.frame.origin = CGPoint(x: touchPoint.x - offset.x, y: touchPoint.y - offset.y)
			}.startAnimation()
			moved?()
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchOffset = nil
		if frame.maxY > superview!.frame.height - 80 {
			UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .allowUserInteraction, animations: {
        self.center.y = self.superview!.frame.height - self.frame.height/2 - 95
        #warning("HARDCODED PIECE OF SHIT")
			})
		}
		ended?()
		UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.curveEaseOut, .allowUserInteraction], animations: {
			self.transform = .identity
		})
	}
}
