//
//  GameView+Objects.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 28/11/26.
//

import SwiftUI

struct BallProjectileView: View {
    var ballProjectile: BallProjectile
    var manager: GameManager

    var body: some View {
        PhysicsManualMoveTarget(object: ballProjectile, manager: manager, enabled: manager.levelPhase == .placeWalls) {
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
}

struct WallObstacleView: View {
    var wallObstacle: WallObstacle
    var manager: GameManager

    var body: some View {
        PhysicsManualMoveTarget(object: wallObstacle, manager: manager, enabled: wallObstacle.moveable && manager.levelPhase == .placeWalls) {
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
        } isValidPosition: { candidateCenter in
            // walls must be placed in the RHS of the field
            guard candidateCenter.x > 0 else { return false }

            var mutableObstacle = wallObstacle
            mutableObstacle.updateCenter(to: candidateCenter)

            // wall must not overlap anything else
            return !manager.candidateOverlapsOthers(mutableObstacle)
        }
        .border(.red, width: wallObstacle.moveable ? 0 : 5)
        .frame(width: wallObstacle.hitbox.size.width, height: wallObstacle.hitbox.size.height)
        .rotationEffect(wallObstacle.hitbox.angle) // SwiftUI is clockwise positive but math is anticlockwise positive so i invert here
        .overlay {
            // if its outside bounds during placing time, it will be marked as to be deleted
            if manager.levelPhase == .placeWalls, !manager.bounds.intersects(wallObstacle.hitbox.frame) {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.red)
            }

            // its health
            Text("\(wallObstacle.currentHealth)")
        }
    }
}

struct KingView: View {
    var king: King

    var body: some View {
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
}

struct ProjectileFactoryView: View {
    var factory: ProjectileFactory

    var body: some View {
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

struct PhysicsObjectView: View {
    var object: any PhysicsObject
    var manager: GameManager

    var body: some View {
        Group {
            if let ball = object as? Ball {
                viewFor(ball: ball)
            } else if let wall = object as? Wall {
                viewFor(wall: wall)
            } else if let ballProjectile = object as? BallProjectile {
                BallProjectileView(ballProjectile: ballProjectile, manager: manager)
            } else if let wallObstacle = object as? WallObstacle {
                WallObstacleView(wallObstacle: wallObstacle, manager: manager)
            } else if let king = object as? King {
                KingView(king: king)
            } else if let factory = object as? ProjectileFactory {
                ProjectileFactoryView(factory: factory)
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
}
