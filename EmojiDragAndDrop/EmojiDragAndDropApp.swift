//
//  EmojiDragAndDropApp.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 21/04/2021.
//

import SwiftUI

@main
struct EmojiDragAndDropApp: App {
    let store = EmojiArtDocumentStore(named: "Emoji Arts")
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser()
                .environmentObject(store)
        }
    }
}
