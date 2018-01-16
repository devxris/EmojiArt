//
//  TextFieldCollectionViewCell.swift
//  EmojiArt
//
//  Created by Chris Huang on 16/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
	
	// MARK: Storyboard
	
	@IBOutlet weak var textField: UITextField! { didSet { textField.delegate = self } }
	
	// MARK: UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
