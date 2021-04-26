//
//  PaletteChooser.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 24/04/2021.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @State private var showPaletteEditor = false
    
    var body: some View {
            HStack {
                Stepper(
                    onIncrement: {
                        chosenPalette = document.palette(after: chosenPalette)
                    },
                    onDecrement: {
                        chosenPalette = document.palette(before: chosenPalette)
                    },
                    label: {
                        EmptyView()
                    })
                Text(document.paletteNames[chosenPalette] ?? "")
                Image(systemName: "keyboard").imageScale(.large)
                    .onTapGesture {
                        showPaletteEditor = true
                    }
                    .popover(isPresented: $showPaletteEditor, content: {
                        PaletteEditor(choosenPallete: $chosenPalette)
                            .frame(width: 300, height: 300)
                    })
            }
            .fixedSize(horizontal: true, vertical: false)
        }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
            .previewLayout(.sizeThatFits)
    }
}
