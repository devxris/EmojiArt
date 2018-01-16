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
	
	// MARK: Properties (closure)
	var resignationHandler: (() -> Void)?
	
	// MARK: UITextFieldDelegate
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		resignationHandler?() // execute closure
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
