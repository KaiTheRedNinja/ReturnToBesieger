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

struct PhysicsManualMoveTarget<Content: View>: View {
    var object: any PhysicsObject
    var manager: PhysicsManager
    var content: Content

    @State private var preservedPosition: CGPoint?
    @State private var preservedAngle: Angle?

    @State private var lastDragTime: Date?
    @State private var throwVelocity: CGPoint?

    init(object: any PhysicsObject, manager: PhysicsManager, @ViewBuilder content: () -> Content) {
        self.object = object
        self.manager = manager
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
        }
        .simultaneousGesture(
            RotationGesture()
                .onChanged { angle in
                    if preservedAngle == nil {
                        preservedAngle = object.hitbox.angle
                    }
                    manager.changeObjectProperties(object.id, angle: preservedAngle! + angle)
                    print("Angle rotated to: \(angle.degrees)")
                }
                .onEnded { angle in
                    defer {
                        preservedAngle = nil
                    }
                    manager.changeObjectProperties(object.id, angle: preservedAngle! + angle)
                    print("Angle stopped at: \(angle.degrees)")
                }
        )
        .simultaneousGesture(
            DragGesture(coordinateSpace: .named("game"))
                .onChanged { value in
                    let now = Date.now
                    defer { lastDragTime = now }
                    if preservedPosition == nil {
                        preservedPosition = object.hitbox.center
                    }
                    let displacement = CGPoint(x: value.translation.width, y: -value.translation.height)
                    let newVelocity: CGPoint? = if let lastDragTime, lastDragTime < now {
                        // v = s / t = (1/t) * s
                        (1 / now.timeIntervalSince(lastDragTime)) * (preservedPosition! + displacement - object.hitbox.center)
                    } else { nil }
                    print("Displacement changed to: \(displacement)")
                    throwVelocity = newVelocity
                    manager.changeObjectProperties(
                        object.id,
                        center: preservedPosition! + displacement,
                        velocity: .zero
                    )
                }
                .onEnded { value in
                    defer {
                        lastDragTime = nil
                        preservedPosition = nil
                        throwVelocity = nil
                    }

                    print("Displacement stopped at: \(value.translation)")
                    let displacement = CGPoint(x: value.translation.width, y: -value.translation.height)
                    manager.changeObjectProperties(
                        object.id,
                        center: preservedPosition! + displacement,
                        velocity: throwVelocity
                    )
                }
        )
    }
}

// from Keysmash app
struct Star: Shape {
    // store how many corners the star has, and how smooth/pointed it is
    let corners: Int
    let smoothness: Double

    func path(in rect: CGRect) -> Path {
        // ensure we have at least two corners, otherwise send back an empty path
        guard corners >= 2 else { return Path() }

        // draw from the center of our rectangle
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)

        // start from directly upwards (as opposed to down or to the right)
        var currentAngle = -CGFloat.pi / 2

        // calculate how much we need to move with each star corner
        let angleAdjustment = .pi * 2 / Double(corners * 2)

        // figure out how much we need to move X/Y for the inner points of the star
        let innerX = center.x * smoothness
        let innerY = center.y * smoothness

        // we're ready to start with our path now
        var path = Path()

        // move to our initial position
        path.move(to: CGPoint(x: center.x * cos(currentAngle), y: center.y * sin(currentAngle)))

        // track the lowest point we draw to, so we can center later
        var bottomEdge: Double = 0

        // loop over all our points/inner points
        for corner in 0..<corners * 2  {
            // figure out the location of this point
            let sinAngle = sin(currentAngle)
            let cosAngle = cos(currentAngle)
            let bottom: Double

            // if we're a multiple of 2 we are drawing the outer edge of the star
            if corner.isMultiple(of: 2) {
                // store this Y position
                bottom = center.y * sinAngle

                // …and add a line to there
                path.addLine(to: CGPoint(x: center.x * cosAngle, y: bottom))
            } else {
                // we're not a multiple of 2, which means we're drawing an inner point

                // store this Y position
                bottom = innerY * sinAngle

                // …and add a line to there
                path.addLine(to: CGPoint(x: innerX * cosAngle, y: bottom))
            }

            // if this new bottom point is our lowest, stash it away for later
            if bottom > bottomEdge {
                bottomEdge = bottom
            }

            // move on to the next corner
            currentAngle += angleAdjustment
        }

        // figure out how much unused space we have at the bottom of our drawing rectangle
        let unusedSpace = (rect.height / 2 - bottomEdge) / 2

        // create and apply a transform that moves our path down by that amount, centering the shape vertically
        let transform = CGAffineTransform(translationX: center.x, y: center.y + unusedSpace)
        return path.applying(transform)
    }
}
