//
//  PhysicsManualMoveTarget.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 26/11/26.
//

import SwiftUI

struct PhysicsManualMoveTarget<Content: View>: View {
    var object: any PhysicsObject
    var manager: PhysicsManager
    var enabled: Bool
    var content: Content

    @State private var preservedPosition: CGPoint?
    @State private var preservedAngle: Angle?

    @State private var lastDragTime: Date?
    @State private var throwVelocity: CGPoint?

    init(object: any PhysicsObject, manager: PhysicsManager, enabled: Bool = true, @ViewBuilder content: () -> Content) {
        self.object = object
        self.manager = manager
        self.enabled = enabled
        self.content = content()
    }

    var body: some View {
        if enabled {
            gestureOn
        } else {
            ZStack {
                content
            }
        }
    }

    var gestureOn: some View {
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
