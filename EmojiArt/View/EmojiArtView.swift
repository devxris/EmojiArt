//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Chris Huang on 15/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class EmojiArtView: UIView {

	// MARK: Properties
	
	var backgroundImage: UIImage? { didSet { setNeedsDisplay() } }
	
	// MARK: Draw
	
	override func draw(_ rect: CGRect) { backgroundImage?.draw(in: bounds) }
}
