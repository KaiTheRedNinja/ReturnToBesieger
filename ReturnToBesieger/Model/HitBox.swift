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

    /// Returns whether a given point is within or on the circle
    func contains(point: CGPoint) -> Bool {
        // definition of a circle
        // (x-c_x)^2 + (y-c_y)^2 = r^2
        // points within the circle are <= r^2 instead
        (point.x - center.x) * (point.x - center.x) + (point.y - center.y) * (point.y - center.y) <= radius*radius
    }

    /// Determines if two circles intersect
    func intersects(circle: CircleHitbox) -> Bool {
        // the distance between the two circles must be less than the radius
        // but more than their difference (otherwise they are concentric)
        let centerDistance = (circle.center - self.center).magnitude
        return abs(circle.radius - self.radius) < centerDistance && centerDistance < (circle.radius + self.radius)
    }

    /// Determines the normal vector of a collision with another circle. This will point from self to the other circle.
    func normalUnitVector(circle: CircleHitbox) -> CGPoint {
        // its literally just the vector from the center of one to the center of another....
        let offsetVector = circle.center - self.center
        return offsetVector.unitVec()
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

    /// Determines the closest point on this line to a ball
    func closestPoint(toCircle circle: CircleHitbox) -> CGPoint {
        // if points are equal, its just that point
        guard point1 != point2 else { return point1 }

        // a line can be expressed parametrically as:
        // A + t(B-A)
        // where A and B are vectors corresponding to point 1 and 2, and t ranges from 0 to 1.

        // the closest point can therefore be found via clamping the following to 0 and 1:
        // t = (C - A).(B - A) / |B - A|^2

        let ca = circle.center - point1
        let ba = point2 - point1

        let tRaw = (ca).dot(ba) / pow((ba).magnitude, 2)
        let t = max(0, min(tRaw, 1))

        // return the point
        return point1 + t * (ba)
    }

    /// Returns whether or not a ball intersects this line
    func intersects(circle: CircleHitbox) -> Bool {
        let closest = closestPoint(toCircle: circle)
        return circle.contains(point: closest)
    }

    /// Returns the normal unit vector of a collision between the ball and the line. This will point from the line to the ball.
    func normalUnitVector(circle: CircleHitbox) -> CGPoint {
        let closest = closestPoint(toCircle: circle)
        return (circle.center - closest).unitVec()
    }
}
