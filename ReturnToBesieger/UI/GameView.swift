//
//  GameView.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI
import Combine

struct GameView: View {
    @State var physics: PhysicsManager = .init(
        objects: [
            Ball(
                hitbox: .init(radius: 30, center: .init(x: 0, y: 0)),
                velocity: .init(x: 1, y: 0)
            ),
            Ball(
                hitbox: .init(radius: 20, center: .init(x: 100, y: 30)),
                velocity: .init(x: -1, y: 0)
            )
//            Wall(
//                hitbox: .init(size: .init(width: 100, height: 200), center: .init(x: 200, y: 10), angle: .degrees(45)),
//                velocity: .zero
//            )
        ]
    )

    @State var gameClock = Timer.publish(every: 1/60, on: .main, in: .default).autoconnect()

    var body: some View {
        ZStack {
            ForEach(physics.objects, id: \.id) { object in
                Group {
                    if let ball = object as? Ball {
                        Circle()
                            .frame(width: ball.hitbox.radius*2, height: ball.hitbox.radius*2)
                    } else if let wall = object as? Wall {
                        Rectangle()
                            .frame(width: wall.hitbox.size.width, height: wall.hitbox.size.height)
                            .rotationEffect(wall.hitbox.angle) // SwiftUI is clockwise positive but math is anticlockwise positive so i invert here
                    }
                }
                .offset(x: object.hitbox.center.x, y: -object.hitbox.center.y)

                if let wall = object as? Wall {
                    ForEach(wall.hitbox.corners.enumerated(), id: \.offset) { (_, corner) in
                        Circle()
                            .fill(.blue)
                            .frame(width: 10, height: 10)
                            .offset(x: corner.x, y: -corner.y)
                    }
                }
            }
        }
        .onReceive(gameClock) { _ in
            physics.update(dt: 1/60)
        }
    }
}
