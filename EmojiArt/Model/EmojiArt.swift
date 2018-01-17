//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Chris Huang on 17/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import Foundation

struct EmojiArt {
	
	// MARK: Properties
	
	var url: URL
	var emojis = [EmojiInfo]()
	
	struct EmojiInfo {
		let x: Int
		let y: Int
		let text: String
		let size: Int
	}
	
	// MARK: Initialzier
	
	init(url: URL, emojis: [EmojiInfo]) {
		self.url = url
		self.emojis = emojis
	}
}
