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
    
    //    Editing states
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    
    var height: CGFloat {
        CGFloat((choosenPalette.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Palette Editor")
                .font(.headline)
                .padding()
            Divider()
            Form {
                Section(header: Text("Palette Name")) {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { editingStatus in
                        if !editingStatus {
                            document.renamePalette(choosenPalette, to: paletteName)
                        }
                        
                    })
                }
                Section(header: Text("Add Emoji")) {
                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { editingStatus in
                        if !editingStatus {
                            choosenPalette = document.addEmoji(emojisToAdd, toPalette: choosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    GridView(choosenPalette.map { String($0)}, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: fontSize))
                            .onTapGesture {
                                choosenPalette = document.removeEmoji(emoji, fromPalette: choosenPalette)
                            }
                    }
                    .frame(height: height)
                }
            }
        }
        .onAppear {
            paletteName = document.paletteNames[choosenPalette] ?? ""
        }
    }
}
