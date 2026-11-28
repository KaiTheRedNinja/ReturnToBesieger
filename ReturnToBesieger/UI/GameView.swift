//
//  GameView.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI
import Combine

struct GameView: View {
    @State var physics: GameManager = .init(
        objects: []
    )

    @State var gameClock = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            simulationView
                .frame(width: screenSize.width - 200)

            ZStack {
                Color(white: 0.7)
                VStack {
                    Spacer()
                        .frame(height: 30)

                    Text("Click to add")

                    if let budget = physics.level?.budget {
                        ForEach(budget.enumerated(), id: \.offset) { (index, budgetItem) in
                            Group {
                                viewFor(object: budgetItem.object)
                                    .scaledToFit()
                            }
                            .frame(width: 200)
                            .overlay(alignment: .bottomTrailing) {
                                Text("\(budgetItem.count)")
                                    .foregroundStyle(.black)
                                    .padding(5)
                                    .background {
                                        Circle().fill(.white)
                                    }
                            }
                            .onTapGesture {
                                physics.addInstance(budgetIndex: index)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .frame(width: 200)
        }
        .onAppear {
            physics.load(
                level: .init(
                    name: "Testing",
                    myKing: .init(isPlayerKing: true, position: .init(x: 300, y: 0), velocity: .zero),
                    budget: [
                        .init(
                            object: WallObstacle(
                                kind: .wood,
                                hitbox: .init(size: .init(width: 80, height: 100), center: .zero, angle: .zero),
                                velocity: .zero,
                                moveable: true
                            ),
                            count: 1
                        ),
                        .init(
                            object: WallObstacle(
                                kind: .stone,
                                hitbox: .init(size: .init(width: 80, height: 100), center: .zero, angle: .zero),
                                velocity: .zero,
                                moveable: true
                            ),
                            count: 1
                        ),
                        .init(
                            object: WallObstacle(
                                kind: .metal,
                                hitbox: .init(size: .init(width: 80, height: 100), center: .zero, angle: .zero),
                                velocity: .zero,
                                moveable: true
                            ),
                            count: 1
                        ),
                        .init(
                            object: WallObstacle(
                                kind: .stone,
                                hitbox: .init(size: .init(width: 80, height: 100), center: .zero, angle: .zero),
                                velocity: .zero,
                                moveable: true,
                                oneWay: true
                            ),
                            count: 1
                        ),
                    ],
                    enemyKing: .init(isPlayerKing: false, position: .init(x: -300, y: 0), velocity: .zero),
                    enemyStructure: [
                        ProjectileFactory(kind: .slinger, position: .init(x: -300, y: 200), fixedAngle: .zero, velocity: .zero),
                        ProjectileFactory(kind: .cannon, position: .init(x: -300, y: 400), fixedAngle: .zero, velocity: .zero),
                        ProjectileFactory(kind: .dragon, position: .init(x: -300, y: -200), fixedAngle: .zero, velocity: .zero)
                    ]
                )
            )
        }
    }

    var simulationView: some View {
        ZStack {
            HStack(spacing: 0) {
                Color(rgb: "5c7305")
                Color(rgb: "7cac04")
            }
            ForEach(physics.objects, id: \.id) { object in
                viewFor(object: object)
            }
        }
        .onReceive(gameClock) { _ in
            physics.update(dt: 1/60)
        }
        .coordinateSpace(.named("game"))
        .toolbar {
            if physics.physicsEnabled {
                Button {
                    physics.endSimulation()
                } label: {
                    Image(systemName: "pause")
                }
            } else {
                Button {
                    physics.startSimulation()
                } label: {
                    Image(systemName: "play")
                }
            }

            Button {
                physics.resetToBackup()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
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
            } else if let king = object as? King {
                viewFor(king: king)
            } else if let factory = object as? ProjectileFactory {
                viewFor(factory: factory)
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
        PhysicsManualMoveTarget(object: ballProjectile, manager: physics, enabled: !physics.physicsEnabled) {
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
        PhysicsManualMoveTarget(object: wallObstacle, manager: physics, enabled: wallObstacle.moveable && !physics.physicsEnabled) {
            Group { switch wallObstacle.kind {
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
            }}
            .overlay {
                if wallObstacle.oneWay {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .padding()
                }
            }
        }
        .frame(width: wallObstacle.hitbox.size.width, height: wallObstacle.hitbox.size.height)
        .rotationEffect(wallObstacle.hitbox.angle) // SwiftUI is clockwise positive but math is anticlockwise positive so i invert here
    }

    func viewFor(king: King) -> some View {
        Group {
            if king.isPlayerKing {
                Circle()
                    .fill(.yellow)
            } else {
                Circle()
                    .fill(.purple)
            }
        }
        .overlay {
            Text("\(king.currentHealth)")
                .foregroundStyle(.black)
        }
        .frame(width: king.hitbox.radius*2, height: king.hitbox.radius*2)
    }

    func viewFor(factory: ProjectileFactory) -> some View {
        Group {
            switch factory.kind {
            case .slinger:
                Rectangle()
                    .fill(Color.brown)
                    .stroke(Color.black, lineWidth: 2)
            case .cannon:
                Rectangle()
                    .fill(Color(white: 0.4))
                    .stroke(Color.black, lineWidth: 2)
            case .dragon:
                Rectangle()
                    .fill(Color.red)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
        .frame(width: factory.hitbox.size.width, height: factory.hitbox.size.height)
        .rotationEffect(factory.hitbox.angle) // SwiftUI is clockwise positive but math is anticlockwise positive so i invert here
    }
}

extension Color {
    init(rgb hexString: String, fallback: Color = .clear) {
        let hex = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard hex.count == 6,
              let value = UInt64(hex, radix: 16) else {
            self = fallback
            return
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self = Color(red: red, green: green, blue: blue)
    }
}
