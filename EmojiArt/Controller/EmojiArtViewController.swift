//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Chris Huang on 15/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit
import MobileCoreServices

extension EmojiArt.EmojiInfo { // ok to extension here because it's related to UI
	
	init?(label: UILabel) { // failabel initializer
		if let attributedString = label.attributedText, let font = attributedString.font {
			x = Int(label.center.x)
			y = Int(label.center.y)
			text = attributedString.string
			size = Int(font.pointSize)
		} else {
			return nil
		}
	}
}

class EmojiArtViewController: UIViewController {
	
	// MARK: Model
	
	var emojis = "🍎🤣🐼🐴🏹🚘🚥🎈🛎❤️❓🇹🇼".map { String($0) } // for UICollectionView
	
	var emojiArt: EmojiArt? { // a computed property to keep UI in-sync
		get {
			if let url = emojiBackgroundImage.url {
				let emojis = emojiArtView.subviews.flatMap { $0 as? UILabel }
											      .flatMap { EmojiArt.EmojiInfo(label: $0) }
				return EmojiArt(url: url, emojis: emojis)
			}
			return nil
		}
		set {
			// clear out contents
			emojiBackgroundImage = (nil, nil)
			// clear out UI
			emojiArtView.subviews.flatMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
			// re-fetch url and image
			if let url = newValue?.url {
				imageFetcher = ImageFetcher(fetch: url) { (url, image) in
					DispatchQueue.main.async {
						// update contents
						self.emojiBackgroundImage = (url, image)
						// update UI ( add labels back )
						newValue?.emojis.forEach {
							let attributedText = $0.text.attributedString(withTextStyle: .body,
																		  ofSize: CGFloat($0.size))
							self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
						}
					}
				}
			}
		}
	}
	
	// MARK: Storyboard
	
	@IBOutlet weak var dropZone: UIView! {
		didSet {
			dropZone.addInteraction(UIDropInteraction(delegate: self))
		}
	}
	
	private var emojiArtView = EmojiArtView()
//	private lazy var emojiArtView: EmojiArtView = {
//		let eav = EmojiArtView()
//		eav.delegate = self
//		return eav
//	}()
	
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
			emojiCollectionView.dragInteractionEnabled = true // enabled drag on iPhone as well
		}
	}
	
	@IBAction func addEmoji(_ sender: UIButton) {
		addingEmoji = true
		emojiCollectionView.reloadSections(IndexSet(integer: 0))
	}
	
	/* view the document in File app, opt-in in info.plist: Supports Document Browser: Yes */ 
	
	// replace to UIDocument APIs for read/write/save/close
	var document: EmojiArtDocument?
	
	// save Data object to UIDocument, since autosave, use delegation from EmojiArtView to do so
	func documentChanged() { // also remove save UIBarButtonItem in storyboard
		document?.emojiArt = emojiArt
		if document?.emojiArt != nil {
			document?.updateChangeCount(.done) // autosave
		}
	}
	
	// close UIDocument ( save before close )
	@IBAction func close(_ sender: UIBarButtonItem? = nil) {
		// remove emojiArtView observe whenever it's closed
		if let observer = emojiArtViewObserver { NotificationCenter.default.removeObserver(observer) }
		
		if document?.emojiArt != nil {
			document?.thumbnail = emojiArtView.snapshot
		}
		presentingViewController?.dismiss(animated: true) {
			self.document?.close { (success) in
				// remove document observer after document is closed
				if let observer = self.documentObserver { NotificationCenter.default.removeObserver(observer) }
			}
		}
	}
	
	@IBOutlet weak var embeddedDocInfoHeight: NSLayoutConstraint!
	@IBOutlet weak var embeddedDocInfoWidth: NSLayoutConstraint!
	private var embeddedDocumentInfo: DocumentInfoViewController? // to track in Embed segue
	
	@IBOutlet weak var cameraButton: UIBarButtonItem! {
		didSet {
			cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
		}
	}
	
	@IBAction func takeBackgroundPhoto(_ sender: UIBarButtonItem) {
		let picker = UIImagePickerController()
		picker.sourceType = .camera
		picker.mediaTypes = [kUTTypeImage as String] // import MobileCoreService
		picker.allowsEditing = true
		picker.delegate = self
		present(picker, animated: true)
	}
	
	// MARK: View Life Cycles
	
	/*
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// set UIDocument to be "Untitled.json"
		if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Untitled.json") {
			document = EmojiArtDocument(fileURL: url)
		}
	} */
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if document?.documentState != .normal { // fix with UIImagePickerController
			// set document observer to obeserve document state
			documentObserver = NotificationCenter.default.addObserver(
				forName: NSNotification.Name.UIDocumentStateChanged,  // name of broadcaster
				object: document,                                     // the broadcaster
				queue: OperationQueue.main,                           // normally on the main queue
				using: { (notification) in
					print("document state changed to \(self.document!.documentState)")
					
					// update Embed document info
					if self.document!.documentState == .normal, let docInfoVC = self.embeddedDocumentInfo {
						// set its model
						docInfoVC.document = self.document
						// optimized its outlook
						self.embeddedDocInfoWidth.constant = docInfoVC.preferredContentSize.width
						self.embeddedDocInfoHeight.constant = docInfoVC.preferredContentSize.height
						// also set view to clear and disable user interaction in storyboard
					}
			}
			)
			
			// load Data object from UIDocument
			document?.open { success in
				if success {
					self.title = self.document?.localizedName
					self.emojiArt = self.document?.emojiArt // update model from UIDocument
					// observe EmojiArtView changed
					self.emojiArtViewObserver = NotificationCenter.default.addObserver(
						forName: .EmojiArtViewDidChange,
						object: self.emojiArtView,
						queue: OperationQueue.main, // could be nil here
						using: { (notification) in
							self.documentChanged()
					}
					)
				}
			}
		}
	}
	
	// MARK: Properties
	
	var imageFetcher: ImageFetcher!
	
	private var _emojiArtBackgroundImageURL: URL? // capture the imageURL
	
	var emojiBackgroundImage: (url: URL?, image: UIImage?) { // change from UIImage to Tuple
		get {
			return (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
		}
		set {
			_emojiArtBackgroundImageURL = newValue.url
			scrollView?.zoomScale = 1.0
			emojiArtView.backgroundImage = newValue.image
			let size = newValue.image?.size ?? .zero
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
	private var suppressBadURLWarning = false
	
	private var documentObserver: NSObjectProtocol?
	private var emojiArtViewObserver: NSObjectProtocol?
	
	// MARK: Navigations
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowDocumentInfo" {
			if let destination = segue.destination.contents as? DocumentInfoViewController {
				document?.thumbnail = emojiArtView.snapshot 
				destination.document = document
				// adapt popover on iPhone as well and impement delegate method
				if let ppc = destination.popoverPresentationController {
					ppc.delegate = self
				}
			}
		} else if segue.identifier == "EmbedDocumentInfo" {
			embeddedDocumentInfo = segue.destination.contents as? DocumentInfoViewController
		}
	}
	
	@IBAction func close(bySegue: UIStoryboardSegue) { close() }
}

/* replace with Notification
// MARK: EmojiArtViewDelegate

extension EmojiArtViewController: EmojiArtViewDelegate {
	
	func emojiArtViewDidChange(_ sender: EmojiArtView) {
		documentChanged()
	}
} */

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
				self.emojiBackgroundImage = (url, image) // fetch url and image
			}
		}
		
		session.loadObjects(ofClass: NSURL.self) { (nsurls) in // on the main queue
			if let url = nsurls.first as? URL {
				// self.imageFetcher.fetch(url)
				
				// fetch image directly without ImageFetcher()
				DispatchQueue.global(qos: .userInitiated).async {
					if let imageData = try? Data(contentsOf: url.imageURL), let image = UIImage(data: imageData) {
						DispatchQueue.main.async {
							self.emojiBackgroundImage = (url, image)
							self.documentChanged()
						}
					} else {
						self.presentBadURLWarning(url: url)
					}
				}
			}
		}
		session.loadObjects(ofClass: UIImage.self) { (images) in
			if let image = images.first as? UIImage {
				self.imageFetcher.backup = image
			}
		}
	}
	
	private func presentBadURLWarning(url: URL?) {
		if !suppressBadURLWarning {
			let alert = UIAlertController(
				title: "Image Transfer Failed",
				message: "Couldn't trasfer the dropped image from its source\nShow this warning in the future?",
				preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Keep Warning", style: .default))
			alert.addAction(UIAlertAction(title: "Stop Warning", style: .destructive) { (action) in
				self.suppressBadURLWarning = true
			})
			present(alert, animated: true)
		}
	}
}

// MARK: UIPopoverPresentationControllerDelegate

extension EmojiArtViewController: UIPopoverPresentationControllerDelegate {
	
	// adapt popover on iPhone as well and impement delegate method
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none // not adapt 
	}
}

// MARK: UIImagePickerControllerDelegate

extension EmojiArtViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	// Be aware of viewController life cycle
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if let image = ((info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage)?.scaled(by: 0.25) {
			// create a url with image created date but not good ( can't store in iCloud )
			let url = image.storeLocallyAsJPEG(named: String(Date.timeIntervalSinceReferenceDate))
			emojiBackgroundImage = (url, image)
			documentChanged()
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.presentingViewController?.dismiss(animated: true) // more explicit even its self
	}
}
