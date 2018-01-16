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
			emojiCollectionView.dropDelegate = self // embedded drop delegate to UICollectionView
		}
	}
	
	@IBAction func addEmoji(_ sender: UIButton) {
		addingEmoji = true
		emojiCollectionView.reloadSections(IndexSet(integer: 0))
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
	
	private var addingEmoji = false
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
	
	// UICollectionViewDataSouce
	
	// AddEmojiButtonCell and EmojiInputCell are in section 0
	func numberOfSections(in collectionView: UICollectionView) -> Int { return 2 }
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case 0 : return 1 // only show AddEmojiButtonCell or EmojiInputCell
		case 1 : return emojis.count
		default : return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if indexPath.section == 1 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
			if let emojiCell = cell as? EmojiCollectionViewCell {
				let attributedText = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
				emojiCell.label.attributedText = attributedText
			}
			return cell
		} else if addingEmoji {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
			if let inputCell = cell as? TextFieldCollectionViewCell {
				// callback from textFieldDidEndEditing(), be aware of memeory cycles
				inputCell.resignationHandler = { [weak self, unowned inputCell] in
					if let text = inputCell.textField.text {
						self?.emojis = (text.map { String($0) } + self!.emojis).uniquified
					}
					self?.addingEmoji = false
					self?.emojiCollectionView.reloadData()
				}
			}
			return cell
		} else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
			return cell
		}
	}
	
	// UICollectionViewDelegateFlowLayout
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if addingEmoji && indexPath.section == 0 {
			return CGSize(width: 300, height: 80) // for wider textField
		} else {
			return CGSize(width: 80, height: 80)
		}
	}
	
	// UICollectionViewDelegate
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let inputCell = cell as? TextFieldCollectionViewCell {
			inputCell.textField.becomeFirstResponder()
		}
	}
}

// MARK: UICollectionViewDragDelegate

extension EmojiArtViewController: UICollectionViewDragDelegate {
	
	private func dragItem(at indexPath: IndexPath) -> [UIDragItem] {
		// disable dragging while adding emoji
		if !addingEmoji, let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
			let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString)) // between apps drag
			dragItem.localObject = attributedString // within apps drag, configure for below perform drop usage
			return [dragItem]
		} else {
			return []
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] { // required delegate method
		// configure the localContext for below drop didUpdate know its within collectionView
		session.localContext = collectionView
		return dragItem(at: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] { // drag multiple items optional delegate method 
		return dragItem(at: indexPath)
	}
}

// MARK: UICollectionViewDropDelegate

extension EmojiArtViewController: UICollectionViewDropDelegate {
	
	func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
		return session.canLoadObjects(ofClass: NSAttributedString.self)
	}
	
	func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
		if let indexPath = destinationIndexPath, indexPath.section == 1 {
			// check if the drag item whether from within collectionView or not
			let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
			return UICollectionViewDropProposal(operation: isSelf ? .move : .copy,
												intent: .insertAtDestinationIndexPath)
		} else { // don't allow drop in section 0
			return UICollectionViewDropProposal(operation: .cancel)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) { // required delegate method
		
		/* must update the model here, drop happens from a. within collectionView b. other apps or elsewhere */
		
		// check out the destination to be dropped
		let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
		
		// check out all the items in coordinator
		for item in coordinator.items {
			
			// drop from local
			if let sourceIndexPath = item.sourceIndexPath {
				if let attributedString = item.dragItem.localObject as? NSAttributedString {
					collectionView.performBatchUpdates({ // for multiple items in-sync
						// update the model
						emojis.remove(at: sourceIndexPath.item)
						emojis.insert(attributedString.string, at: destinationIndexPath.item)
						// update the collectionView
						collectionView.deleteItems(at: [sourceIndexPath])
						collectionView.insertItems(at: [destinationIndexPath])
					})
					// to peform drop animation
					coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
				}
				
			/* drop from global & insert, might be time-consuming async, utlizing placeholder cell in collectionView
			   also set prototype cell in storyboard, better with activity indicator */
			} else {
				let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath,
												    reuseIdentifier: "DropPlaceholderCell"))
				item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self, completionHandler: { (provider, error) in // execute off the main queue
					DispatchQueue.main.async {
						if let attributedString = provider as? NSAttributedString {
							placeholderContext.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
								// update the model where to be inserted
								self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
							})
						} else {
							placeholderContext.deletePlaceholder() // if something wrong, delete placeholder
						}
					}
				})
			}
		}
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
