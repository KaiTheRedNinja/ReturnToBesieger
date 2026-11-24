//
//  HitBox.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

protocol HitBox {
    /// The center of the object. This may be manipulated externally for movement.
    var center: CGPoint { get set }
    /// The frame of the object, that contains the whole of the object
    var frame: CGRect { get }
}

struct CircleHitbox: HitBox {
    var radius: CGFloat
    var center: CGPoint

    var frame: CGRect {
        .init(center: center, size: .init(width: radius*2, height: radius*2))
    }
}

struct RotatableRectangleHitbox: HitBox {
    var size: CGSize
    var center: CGPoint
    var angle: Angle

    var frame: CGRect {
        let transform = CGAffineTransform(rotationAngle: angle.radians)
        let centeredRect = CGRectApplyAffineTransform(.init(center: .zero, size: size), transform)
        return .init(center: center, size: centeredRect.size)
    }

    /// The corners of the rotated rectangle
    var corners: [CGPoint] {
        let naturalRect = CGRect(center: .zero, size: size)
        return naturalRect.corners.map { $0.rotating(acw: angle) + center }
    }

    /// The edges of the rotated rectangle
    var edges: [LineSegment] {
        var corners = corners
        corners.append(corners[0]) // wrap
        return (0..<4).map { index in
            .init(point1: corners[index], point2: corners[index+1])
        }
    }
}

struct LineSegment: HitBox {
    var point1: CGPoint
    var point2: CGPoint

    var center: CGPoint {
        get {
            0.5 * (point1 + point2)
        }
        set {
            // simple linear offset both points
            let offset = newValue - (0.5 * (point1 + point2))
            point1 += offset
            point2 += offset
        }
    }

    var frame: CGRect {
        .init(
            minX: min(point1.x, point2.x),
            minY: min(point1.y, point2.y),
            maxX: max(point1.x, point2.x),
            maxY: max(point1.y, point2.y)
        )
    }
}
