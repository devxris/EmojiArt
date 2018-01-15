//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Chris Huang on 15/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController {
	
	// MARK: Stroyboard
	
	@IBOutlet weak var dropZone: UIView! {
		didSet {
			dropZone.addInteraction(UIDropInteraction(delegate: self))
		}
	}
	
	@IBOutlet weak var emojiArtView: EmojiArtView!
	
	// MARK: Properties
	
	var imageFetcher: ImageFetcher!
}

// MARK: UIDropInteractionDelegate

extension EmojiArtViewController: UIDropInteractionDelegate {
	
	// a. specify can only drop item with both url and image
	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
	}
	
	// b. set proposal which allows copy, move, orbidden, or cancel
	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}
	
	// c. perform the "drop" with session ( able to be mulitple objects )
	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		
		imageFetcher = ImageFetcher() { (url, image) in // off the main queue
			DispatchQueue.main.async {
				self.emojiArtView.backgroundImage = image
			}
		}
		
		session.loadObjects(ofClass: NSURL.self) { (nsurls) in
			if let url = nsurls.first as? URL {
				self.imageFetcher.fetch(url)
			}
		}
		session.loadObjects(ofClass: UIImage.self) { (images) in
			if let image = images.first as? UIImage {
				self.imageFetcher.backup = image
			}
		}
	}
}
