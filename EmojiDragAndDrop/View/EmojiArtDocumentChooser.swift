//
//  EmojiArtDocumentChooser.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 26/04/2021.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore 
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(
                        destination: EmojiArtDocumentView(document: document)
                            .navigationBarTitle(store.name(for: document))) {
                        Text(store.name(for: document))
                    }
                }
                .onDelete(perform: { indexSet in
                    indexSet.map { store.documents[$0] }.forEach { (document) in
                        store.removeDocument(document)
                    }
                })
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle(store.name)
            .navigationBarItems(leading: Button(action: {
                store.addDocument()
            }, label: {
                Image(systemName: "plus")
                    .imageScale(.large)
            }), trailing: EditButton())
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
