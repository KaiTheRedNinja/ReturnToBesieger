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
//            Ball(
//                hitbox: .init(radius: 20, center: .init(x: 0, y: 0)),
//                velocity: .init(x: 1, y: 0)
//            ),
//            Ball(
//                hitbox: .init(radius: 20, center: .init(x: 100, y: 0)),
//                velocity: .init(x: 0, y: 0)
//            ),
//            Ball(
//                hitbox: .init(radius: 20, center: .init(x: 140, y: 0)),
//                velocity: .init(x: 0, y: 0)
//            ),
//            Ball(
//                hitbox: .init(radius: 20, center: .init(x: 180, y: 0)),
//                velocity: .init(x: 0, y: 0)
//            ),
//            Ball(
//                hitbox: .init(radius: 20, center: .init(x: 220, y: 0)),
//                velocity: .init(x: 0, y: 0)
//            ),
//            Wall(
//                hitbox: .init(size: .init(width: 100, height: 200), center: .init(x: 300, y: 0), angle: .degrees(0)),
//                velocity: .zero
//            )
            BallProjectile(kind: .rock, hitbox: .init(radius: 20, center: .init(x: -200, y: 100)), velocity: .zero),
            BallProjectile(kind: .cannonball, hitbox: .init(radius: 20, center: .init(x: -200, y: 0)), velocity: .zero),
            BallProjectile(kind: .fireball, hitbox: .init(radius: 20, center: .init(x: -200, y: -100)), velocity: .zero),

            WallObstacle(kind: .wood, hitbox: .init(size: .init(width: 100, height: 100), center: .init(x: 0, y: 200), angle: .degrees(0)), velocity: .init(x: 0, y: 0)),
            WallObstacle(kind: .stone, hitbox: .init(size: .init(width: 100, height: 100), center: .init(x: 0, y: 75), angle: .degrees(0)), velocity: .init(x: 0, y: 0)),
            WallObstacle(kind: .metal, hitbox: .init(size: .init(width: 100, height: 100), center: .init(x: 0, y: -75), angle: .degrees(0)), velocity: .init(x: 0, y: 0)),
            WallObstacle(kind: .magical, hitbox: .init(size: .init(width: 100, height: 100), center: .init(x: 0, y: -200), angle: .degrees(0)), velocity: .init(x: 0, y: 0))
        ]
    )

    @State var gameClock = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ForEach(physics.objects, id: \.id) { object in
                viewFor(object: object)
            }
        }
        .onReceive(gameClock) { _ in
            physics.update(dt: 1/60)
        }
        .coordinateSpace(.named("game"))
    }

    func viewFor(object: any PhysicsObject) -> some View {
        Group {
            if let ball = object as? Ball {
                viewFor(ball: ball)
            } else if let wall = object as? Wall {
                viewFor(wall: wall)
            } else if let ballProjectile = object as? BallProjectile {
                viewFor(ballProjectile: ballProjectile)
            } else if let wallObstacle = object as? WallObstacle {
                viewFor(wallObstacle: wallObstacle)
            }
        }
        .offset(x: object.hitbox.center.x, y: -object.hitbox.center.y)
    }

    func viewFor(ball: Ball) -> some View  {
        Circle()
            .frame(width: ball.hitbox.radius*2, height: ball.hitbox.radius*2)
    }

    func viewFor(wall: Wall) -> some View {
        ZStack {
            Rectangle()
                .frame(width: wall.hitbox.size.width, height: wall.hitbox.size.height)
                .rotationEffect(wall.hitbox.angle) // SwiftUI is clockwise positive but math is anticlockwise positive so i invert here

            ForEach(wall.hitbox.corners.enumerated(), id: \.offset) { (_, corner) in
                Circle()
                    .fill(.blue)
                    .frame(width: 10, height: 10)
                    .offset(x: corner.x - wall.hitbox.center.x, y: -corner.y - wall.hitbox.center.y)
            }
        }
    }

    func viewFor(ballProjectile: BallProjectile) -> some View {
        PhysicsManualMoveTarget(object: ballProjectile, manager: physics) {
            switch ballProjectile.kind {
            case .rock:
                Circle()
                    .fill(Color(white: 0.3))
                    .stroke(Color.black, lineWidth: 2)
            case .cannonball:
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.8), Color(white: 0.2)],
                            center: .init(x: 0.7, y: 0.7),
                            startRadius: 0,
                            endRadius: ballProjectile.hitbox.radius * (1.0/0.7)
                        )
                    )
                    .stroke(Color.black, lineWidth: 2)
            case .fireball:
                Star(corners: 10, smoothness: 0.5)
                    .fill(
                        RadialGradient(
                            colors: [.yellow, .orange, .red],
                            center: .center,
                            startRadius: 0,
                            endRadius: ballProjectile.hitbox.radius
                        )
                    )
                    .stroke(Color.black, lineWidth: 2)
                    .saturation(2.0)
            }
        }
        .frame(width: ballProjectile.hitbox.radius*2, height: ballProjectile.hitbox.radius*2)
    }

    func viewFor(wallObstacle: WallObstacle) -> some View {
        PhysicsManualMoveTarget(object: wallObstacle, manager: physics) {
            switch wallObstacle.kind {
            case .wood:
                Rectangle()
                    .fill(Color.brown)
                    .stroke(Color.black, lineWidth: 2)
            case .stone:
                Rectangle()
                    .fill(Color(white: 0.4))
                    .stroke(Color.black, lineWidth: 2)
            case .metal:
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.2),
                                Color(white: 0.6),
                                Color(white: 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            case .magical:
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .purple,
                                .purple.exposureAdjust(2),
                                .purple
                            ],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
            }
        }
        .frame(width: wallObstacle.hitbox.size.width, height: wallObstacle.hitbox.size.height)
        .rotationEffect(wallObstacle.hitbox.angle) // SwiftUI is clockwise positive but math is anticlockwise positive so i invert here
    }
}
