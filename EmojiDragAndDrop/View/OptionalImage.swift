//
//  OptionalImage.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 21/04/2021.
//

import SwiftUI


struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
