import Foundation
import SwiftUI

struct InitializationSUIV: View {
    @State var isAnimation: Bool = false
    var body: some View {
        fourDotsLoading()
            .onAppear() {
                self.isAnimation.toggle()
            }
    }
}

extension InitializationSUIV {
    func fourDotsLoading() -> some View {
        HStack {
            ForEach(0..<4) { index in
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isAnimation ? 1.0 : 0.5)
                    .animation(Animation.easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index)*0.2))
            }
        }
    }
}
