//
//  DocumentInfoViewController.swift
//  EmojiArt
//
//  Created by Chris Huang on 18/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class DocumentInfoViewController: UIViewController {
	
	// MARK: Model
	
	var document: EmojiArtDocument? { didSet { updateUI() } }
	
	// MARK: ViewController Life Cycles
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateUI()
	}
	
	// a good place to put preferredContentSize because it's related to geomerty change
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if let fittedSize = topLevelView?.sizeThatFits(UILayoutFittingCompressedSize) {
			preferredContentSize = CGSize(width: fittedSize.width + 30, height: fittedSize.height + 30) // padding
		}
	}
	
	// MARK: Private funcs & properties
	
	private let shortDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}()
	
	private func updateUI() {
		if sizeLabel != nil && createdLabel != nil { // ensure outlets are set
			if let url = document?.fileURL,
			   let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
				sizeLabel.text = "\(attributes[.size] ?? 0) bytes"
				if let created = attributes[.creationDate] as? Date {
					createdLabel.text = shortDateFormatter.string(from: created)
				}
			}
		}
		if thumbnailImageView != nil, thumbnailAspectRatio != nil { // ensure outlets are set
			if let thumbnail = document?.thumbnail {
				thumbnailImageView.image = thumbnail
				
				// remove current constraint
				thumbnailImageView.removeConstraint(thumbnailAspectRatio)
				// configure a new constraint
				thumbnailAspectRatio = NSLayoutConstraint(
					item: thumbnailImageView,
					attribute: .width,
					relatedBy: .equal,
					toItem: thumbnailImageView,
					attribute: .height,
					multiplier: thumbnail.size.width / thumbnail.size.height,
					constant: 0)
				// add constraint back to imageView
				thumbnailImageView.addConstraint(thumbnailAspectRatio)
			}
		}
		// optimize outlook of popover in iPad ( not adapt on iPhone which needs a delegate )
		if presentationController is UIPopoverPresentationController {
			thumbnailImageView?.isHidden = true
			returnToDocumentButton?.isHidden = true
			view.backgroundColor = .clear
		}
	}

	// MARK: Storyboard
	
	@IBOutlet weak var thumbnailImageView: UIImageView!
	@IBOutlet weak var sizeLabel: UILabel!
	@IBOutlet weak var createdLabel: UILabel!
	@IBOutlet weak var returnToDocumentButton: UIButton!
	
	@IBOutlet weak var thumbnailAspectRatio: NSLayoutConstraint! // it's multiplier, so need to modify itself
	@IBOutlet weak var topLevelView: UIStackView!
	
	@IBAction func done() { presentingViewController?.dismiss(animated: true) }
}
