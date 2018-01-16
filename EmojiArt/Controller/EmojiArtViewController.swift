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
	
	private var emojiArtView = EmojiArtView()
	
	@IBOutlet weak var scrollView: UIScrollView! {
		didSet {
			scrollView.minimumZoomScale = 0.1
			scrollView.maximumZoomScale = 5.0
			scrollView.delegate = self
			scrollView.addSubview(emojiArtView)
		}
	}
	
	/* Keep emojiArtViewCentered automatically - make emojiArtView sticks to scrollView's contentSize
		- when zoom too small, it's keep centered with aspect ratio
	   	- when zoom too big, other constraints will take care because other's with higher proiority
		1. constrain scrollView centered vertically and horizontally
		2. constrain scrollView's width/height and outlets
		3. set width/height to low priority
		4. change width/height constant after first set image and after zooming ( scrollViewDidZoom delegate method )
	*/
	@IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
	@IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
	
	// MARK: Properties
	
	var imageFetcher: ImageFetcher!
	
	var emojiBackgroundImage: UIImage? {
		get {
			return emojiArtView.backgroundImage
		}
		set {
			scrollView?.zoomScale = 1.0
			emojiArtView.backgroundImage = newValue
			let size = newValue?.size ?? .zero
			emojiArtView.frame = CGRect(origin: .zero, size: size)
			scrollView?.contentSize = size
			scrollViewHeight?.constant = size.height
			scrollViewWidth?.constant = size.width
			if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
				scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width,
										    dropZone.bounds.size.height / size.height)
			}
		}
	}
}

// MARK: UIScrollViewDelegate

extension EmojiArtViewController: UIScrollViewDelegate {
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? { return emojiArtView }
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		scrollViewHeight.constant = scrollView.contentSize.height
		scrollViewWidth.constant = scrollView.contentSize.width
	}
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
				self.emojiBackgroundImage = image
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
