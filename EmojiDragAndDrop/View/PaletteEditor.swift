//
//  PaletteEditor.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 26/04/2021.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var choosenPallete: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Palette Editor")
                .font(.headline)
                .padding()
            Divider()
            Text(choosenPallete)
                .padding()
            Spacer()
        }
    }
}
