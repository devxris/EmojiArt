//
//  EmojiArtDocumentTableViewController.swift
//  EmojiArt
//
//  Created by Chris Huang on 15/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class EmojiArtDocumentTableViewController: UITableViewController {
	
	// MARK: Model
	
	var emojiArtDocuments = ["One", "Two", "Three"]
	
	// MARK: Storyboard
	
	@IBAction func newEmojiArt(_ sender: UIBarButtonItem) {
		emojiArtDocuments += ["Untitled".madeUnique(withRespectTo: emojiArtDocuments)]
		tableView.reloadData()
	}

	// MARK: UITableViewDataSource
	
	override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return emojiArtDocuments.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
		cell.textLabel?.text = emojiArtDocuments[indexPath.row]
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			emojiArtDocuments.remove(at: indexPath.row)        // in-sync with tableView
			tableView.deleteRows(at: [indexPath], with: .fade) // in-sync with model
		}
	}
	
	// MARK: UISplitViewController preferred display mode
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if splitViewController?.preferredDisplayMode != .primaryOverlay {
			splitViewController?.preferredDisplayMode = .primaryOverlay
		}
	} 
}
