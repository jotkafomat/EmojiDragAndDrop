//
//  EmojiArtDocumentView.swift
//  EmojiDragAndDrop
//
//  Created by Krzysztof Jankowski on 21/04/2021.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var selectedEmoji = Set<EmojiArt.Emoji>()
    
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: self.defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTabToZoom(in: geometry.size))
                    
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
                .clipped()
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
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
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
