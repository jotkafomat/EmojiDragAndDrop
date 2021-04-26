//
//  PaletteEditor.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 26/04/2021.
//

import SwiftUI

struct PaletteEditor: View {
    
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var choosenPalette: String
    @State private var paletteName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Palette Editor")
                .font(.headline)
                .padding()
            Divider()
            TextField("Palette Name", text: $paletteName, onEditingChanged: { editingStatus in
                if !editingStatus {
                    document.renamePalette(choosenPalette, to: paletteName)
                }
                
            })
                .padding()
            Spacer()
        }
        .onAppear {
            paletteName = document.paletteNames[choosenPalette] ?? ""
        }
    }
}
