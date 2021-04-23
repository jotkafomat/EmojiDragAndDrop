//
//  Spinning .swift
//  EmojiArts
//
//  Created by Krzysztof Jankowski on 16/04/2021.
//

import SwiftUI

struct Spinning: ViewModifier {
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isVisible ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear { isVisible = true }
    }
}

extension View {
    func spinning() -> some View {
        self.modifier(Spinning())
    }
}
