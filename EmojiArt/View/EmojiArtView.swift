//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Chris Huang on 15/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

extension Notification.Name {
	static let EmojiArtViewDidChange = Notification.Name("EmojiArtViewDidChange")
}

protocol EmojiArtViewDelegate: class {
	func emojiArtViewDidChange(_ sender: EmojiArtView)
}

class EmojiArtView: UIView {
	
	// MARK: Properties
	
	var backgroundImage: UIImage? { didSet { setNeedsDisplay() } }
	
	weak var delegate: EmojiArtViewDelegate?
	
	// MARK: Draw
	
	override func draw(_ rect: CGRect) { backgroundImage?.draw(in: bounds) }
	
	// MARK: Initializer
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		addInteraction(UIDropInteraction(delegate: self))
	}
	
	// MARK: View Life Cycles
	
	private var labelObservation = [UIView: NSKeyValueObservation]()

	override func willRemoveSubview(_ subview: UIView) {
		super.willRemoveSubview(subview)
		if labelObservation[subview] != nil {
			labelObservation[subview] = nil
		}
	}
}

// MARK: UIDropInteractionDelegate

extension EmojiArtView: UIDropInteractionDelegate {
	
	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		return session.canLoadObjects(ofClass: NSAttributedString.self)
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		// drop NSAttributedString as UILabel
		session.loadObjects(ofClass: NSAttributedString.self) { (providers) in
			let dropPoint = session.location(in: self)
			for attributedString in providers as? [NSAttributedString] ?? [] {
				self.addLabel(with: attributedString, centeredAt: dropPoint)
				self.delegate?.emojiArtViewDidChange(self)
				// good to set custom Notification.Name by extension
				NotificationCenter.default.post( name: .EmojiArtViewDidChange, object: self)
			}
		}
	}
	
	func addLabel(with attributedString: NSAttributedString, centeredAt point: CGPoint) {
		let label = UILabel()
		label.backgroundColor = .clear
		label.attributedText = attributedString
		label.sizeToFit()
		label.center = point
		addEmojiArtGestureRecognizers(to: label)
		addSubview(label)
		// add KVO observation for label center changed
		labelObservation[label] = label.observe(\.center) { (label, change) in
			self.delegate?.emojiArtViewDidChange(self)
			NotificationCenter.default.post( name: .EmojiArtViewDidChange, object: self)
		}
	}
}
