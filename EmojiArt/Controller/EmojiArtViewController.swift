//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Chris Huang on 15/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController {
	
	// MARK: Model
	
	var emojis = "🍎🤣🐼🐴🏹🚘🚥🎈🛎❤️❓🇹🇼".map { String($0) }
	
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
	
	@IBOutlet weak var emojiCollectionView: UICollectionView! {
		didSet {
			emojiCollectionView.dataSource = self
			emojiCollectionView.delegate = self
			emojiCollectionView.dragDelegate = self // embedded drag delegate to UICollectionView
		}
	}
	
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
	
	private var font: UIFont { // adapt accessiblity and dynamic type
		return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
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

// MARK: UICollectionViewDataSouce, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension EmojiArtViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return emojis.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
		if let emojiCell = cell as? EmojiCollectionViewCell {
 			let attributedText = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
			emojiCell.label.attributedText = attributedText
		}
		return cell
	}
}

// MARK: UICollectionViewDragDelegate

extension EmojiArtViewController: UICollectionViewDragDelegate {
	
	private func dragItem(at indexPath: IndexPath) -> [UIDragItem] {
		if let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
			let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString)) // between apps drag
			dragItem.localObject = attributedString // within apps drag
			return [dragItem]
		} else {
			return []
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] { // required delegate method
		return dragItem(at: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] { // drag multiple items optional delegate method 
		return dragItem(at: indexPath)
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
