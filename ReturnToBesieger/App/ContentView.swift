import SwiftUI
import Playgrounds

nonisolated let screenSize: CGSize = .init(width: 1920, height: 1080)
nonisolated let toolbarWidth: CGFloat = 200
nonisolated let simulationSize: CGSize = .init(width: 1920 - toolbarWidth, height: 1080)

struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / screenSize.width,
                proxy.size.height / screenSize.height,
            )

            ZStack(alignment: .center) {
                GameView()
            }
            .frame(width: screenSize.width, height: screenSize.height, alignment: .center)
            .clipped()
            .scaleEffect(.init(width: scale, height: scale), anchor: .center)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
