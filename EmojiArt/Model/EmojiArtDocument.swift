//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Chris Huang on 17/01/2018.
//  Copyright © 2018 Chris Huang. All rights reserved.
//

import UIKit

class EmojiArtDocument: UIDocument {
	
	var emojiArt: EmojiArt? // need model as well
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode document with an instance of Data or NSFileWrapper
        return emojiArt?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load document from contents
		if let json = contents as? Data {
			emojiArt = EmojiArt(json: json)
		}
    }
}
