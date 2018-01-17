//
//  DocumentBrowserViewController.swift
//  EmojiArt
//
//  Created by Chris Huang on 17/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
	
	// MARK: View Life Cycles
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// configure UIDocumentBrowserViewController
        delegate = self
		allowsPickingMultipleItems = false
        allowsDocumentCreation = false
		
		// only able to create new document on iPad
		if UIDevice.current.userInterfaceIdiom == .pad {
			// put template file in applicationSupportDirectory which is invisible to user and perminent
			template = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
				// .appendingPathComponent("Untitled.json")
				.appendingPathComponent("Untitled.emojiart")
			
			/* Edit in project setting for Exported UTIs
			A. Documents Types
				Name: EmojiArt, Types: edu.stanford.cs193p.emojiart
				Additional properties
				CFBundleTypeRoleL: Editor, LSHandlerRank: Owner
			B. Exported UTIs
				Descirptions: EmojiArt
				identifier: edu.stanford.cs193p.emojiart
				Conforms to: public.data
				Additional properties
				UTTypeTagSpecification: Dictionary
					public.filename-extension: emojiart (String)
			*/
			
			// create empty contents template file
			if template != nil {
				allowsDocumentCreation = FileManager.default.createFile(atPath: template!.path, contents: Data())
			}
		}
    }
	
	// MARK: Properties
	
	var template: URL? // point to a blank file url
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
		importHandler(template, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
		print(template!.path) // need to test on real device or documentURLs is [] in simulator...
		presentDocument(at: template!)
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
		// better to put alertController here
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
		
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		let documentViewController = storyBoard.instantiateViewController(withIdentifier: "DocumentMVC")
		if let emojiArtViewController = documentViewController.contents as? EmojiArtViewController {
			emojiArtViewController.document = EmojiArtDocument(fileURL: documentURL)
			/* Configure project settings Info -> Document Types -> Name: JSON, Types: public.json */
		}
        present(documentViewController, animated: true, completion: nil)
    }
}

