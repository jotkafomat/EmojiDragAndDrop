//
//  EmojiArtDocumentView.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 21/04/2021.
//

import SwiftUI
import Combine

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var selectedEmoji = Set<EmojiArt.Emoji>()
    @State private var chosenPalette = ""
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                .onAppear {
                    chosenPalette = document.defaultPalette
                }
            }
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTabToZoom(in: geometry.size))
                    if isLoading {
                        VStack {
                            Image(systemName: "timer").imageScale(.large)
                                .spinning()
                            Text("Image is loading .....")
                        }
                    } else {
                        ForEach(document.emojis) { emoji in
                            Text(emoji.text)
                                .background(selectedEmoji.containsEmoji(emoji) ? Color(.magenta): Color(.clear))
                                .font(animatableWithSize: emoji.fontSize * zoomScale)
                                .position(position(for: emoji, in: geometry.size))
                                .offset(selectedEmoji.containsEmoji(emoji) ? emojiDragOffset : .zero)
                                .scaleEffect(selectedEmoji.containsEmoji(emoji) ? gestureZoomScale : 1)
                                .gesture(emojiDragGesture())
                                .onTapGesture(count: 3) {
                                    document.remove(emoji)
                                }
                                .onLongPressGesture {
                                    selectedEmoji.toggleMatching(emoji)
                                    print(selectedEmoji)
                                }
                        }
                    }
                }
                .clipped()
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(document.$backgroundImage) { backgroundImage in
                    zoomToFit(backgroundImage, size: geometry.size)
                }
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .onTapGesture {
                    selectedEmoji.removeAll()
                    print(selectedEmoji)
                }
                .navigationBarItems(trailing: Button(action: {
                    if let url = UIPasteboard.general.url {
                        document.backgroundURL = url
                        confirmBackgroundPaste = true
                    } else {
                        explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard")
                        .imageScale(.large)
                        .alert(isPresented: $explainBackgroundPaste) {
                            return Alert(
                                title: Text("Paste Background"),
                                message: Text("Copy URL of an image and touch this button to make it the background your document"),
                                dismissButton: .default(Text("OK")))
                        }
                }))
            }
            .alert(isPresented: $confirmBackgroundPaste) {
                Alert(title: Text("Paste Background"),
                      message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nithing")"),
                      primaryButton: .default(Text("OK")) {
                        document.backgroundURL = UIPasteboard.general.url },
                      secondaryButton: .cancel())
            }

        }
    }
    //    DoubleTap Gesture
    private var zoomScale: CGFloat {
        if selectedEmoji.isEmpty {
            return steadyStatezoomScale * gestureZoomScale
        } else {
            return steadyStatezoomScale
        }
    }
    
    private func zoomToFit(_ image: UIImage?, size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStatezoomScale = min(hZoom, vZoom)
        }
    }
    
    private func doubleTabToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, size: size)
                }
            }
    }
    
    //    Pinch Gesture
    @State var steadyStatezoomScale: CGFloat = 1.0
    @GestureState var gestureZoomScale: CGFloat = 1.0
    
    func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureState, gestureZoomScale, transaction in
                if selectedEmoji.isEmpty {
                    gestureZoomScale = latestGestureState
                } else {
                    gestureZoomScale = latestGestureState / zoomScale
                }
            }
            .onEnded { finalGestureScale in
                if selectedEmoji.isEmpty {
                    steadyStatezoomScale *= finalGestureScale
                } else {
                    selectedEmoji.forEach {
                        document.scaleEmoji($0, by: (finalGestureScale / zoomScale))
                    }
                }
            }
    }
    
    //    Pan Gesture
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    //DragGestureEmoji
    
    @State private var emojiStateDragOffset: CGSize = .zero
    @GestureState private var gestureDragOffset: CGSize = .zero
    
    var emojiDragOffset: CGSize {
        (emojiStateDragOffset + gestureDragOffset) * zoomScale
    }
    
    private func emojiDragGesture() -> some Gesture {
        DragGesture()
            .updating($gestureDragOffset) { latestGestureValue, gestureDragOffset, transaction in
                gestureDragOffset = latestGestureValue.translation / zoomScale
                
            }
            .onEnded { finalDragGestureValue in
                selectedEmoji.forEach { emoji in
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale)
                }
            }
    }
    
    private func font(for emoji: EmojiArt.Emoji) -> Font {
        Font.system(size: emoji.fontSize * zoomScale)
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        if selectedEmoji.containsEmoji(emoji) {
            location = CGPoint(
                x: location.x * zoomScale / gestureZoomScale,
                y: location.y * zoomScale / gestureZoomScale)
        } else {
            location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        }
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil 
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
