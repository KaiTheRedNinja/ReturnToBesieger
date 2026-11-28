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
                .frame(width: simulationSize.width)
                .zIndex(physics.levelPhase == .placeWalls ? 100 : 0)

            inventoryView
                .frame(width: 200)
        }
        .foregroundStyle(.black)
        .onAppear {
            loadLevel()
        }
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

    func loadLevel() {
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
    }

    var inventoryView: some View {
        ZStack {
            Color(white: 0.7)
            VStack(spacing: 30) {
                Text("Click to add, drag back here to delete")
                    .multilineTextAlignment(.center)

                if let budget = physics.level?.budget {
                    ForEach(budget.enumerated(), id: \.offset) { (index, budgetItem) in
                        Group {
                            viewFor(object: budgetItem.object)
                        }
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
                        .opacity(budgetItem.count > 0 ? 1 : 0.7)
                        .grayscale(budgetItem.count > 0 ? 0 : 1.0)
                        .shadow(color: budgetItem.count > 0 ? .green : .clear, radius: 20)
                        .overlay {
                            if budgetItem.count == 0 {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.all, 40)
        }
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
