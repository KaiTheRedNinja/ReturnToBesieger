//
//  PhysicsManager.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

class PhysicsManager {

}

protocol PhysicsObject {
    associatedtype HB: HitBox

    /// The hitbox of the object
    var hitbox: HB { get }
    /// The velocity of the object
    var velocity: CGPoint { get }
}

struct Ball: PhysicsObject {
    var hitbox: CircleHitbox
    var velocity: CGPoint
}

struct Wall: PhysicsObject {
    var hitbox: RotatableRectangleHitbox
    var velocity: CGPoint
}

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
}

struct RotatableRectangleHitbox: HitBox {
    var size: CGSize
    var center: CGPoint
    var angle: Angle

    var frame: CGRect {
        let transform = CGAffineTransform(rotationAngle: angle.radians)
        let centeredRect = CGRectApplyAffineTransform(.init(center: center, size: size), transform)
        return centeredRect
    }

    /// The corners of the rotated rectangle
    var corners: [CGPoint] {
        let naturalRect = CGRect(center: .zero, size: size)
        return naturalRect.corners.map { $0.rotating(acw: angle) }
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

        let t = max(0, min((ca).dot(ba) / pow((ba).magnitude, 2), 1))

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

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width/2, y: center.y - size.height/2, width: size.width, height: size.height)
    }

    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.init(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
    }

    var corners: [CGPoint] {
        [
            .init(x: minX, y: minY),
            .init(x: minX, y: maxY),
            .init(x: maxX, y: maxY),
            .init(x: maxX, y: minY),
        ]
    }
}

/// Vector extensions
extension CGPoint: @retroactive AdditiveArithmetic {
    /// Adds two vectors together
    public static func + (lhs: Self, rhs: Self) -> CGPoint {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    /// Subtracts a vector from another
    public static func - (lhs: Self, rhs: Self) -> CGPoint {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    /// Subtracts a vector from zero
    public static prefix func - (rhs: Self) -> CGPoint {
        .init(x: -rhs.x, y: -rhs.y)
    }
    /// Scales a vector by a scalar
    public static func * (lhs: CGFloat, rhs: Self) -> CGPoint {
        .init(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    /// Performs the dot product operation on this value and another
    public func dot(_ rhs: Self) -> CGFloat {
        self.x * rhs.x + self.y * rhs.y
    }
    /// Obtains the unit vector of this vector
    public func unitVec() -> CGPoint {
        .init(x: x / magnitude, y: y / magnitude)
    }
    /// The magnitude of this vector
    public var magnitude: CGFloat {
        sqrt(x*x + y*y)
    }
    /// The angle of this vector, anticlockwise from the positive x-axis
    public var angle: Angle {
        // calculate base angle, which will be between 0 and 180 degrees
        let base: CGFloat = if x == 0 {
            .pi * 0.5
        } else {
            (atan(y/x) + .pi).truncatingRemainder(dividingBy: .pi)
        }
        // increase by 180 degrees if in 3rd and 4th quadrants (i.e. negative y)
        return .radians(base + (y >= 0 ? 0 : .pi))
    }
    /// Flips a point along the x-axis
    public func vflip() -> CGPoint {
        .init(x: self.x, y: -self.y)
    }
    /// Rotates this vector anticlockwise by the given angle
    public func rotating(acw angle: Angle) -> CGPoint {
        .init(
            x: x * cos(angle.radians) - y * sin(angle.radians),
            y: y * sin(angle.radians) + y * cos(angle.radians)
        )
    }
}

//struct Polar {
//    var magnitude: CGFloat
//    var angle: Angle
//
//    /// The polar coordinate in cartesian
//    var point: CGPoint {
//        .init(x: magnitude * cos(angle.radians), y: magnitude * sin(angle.radians))
//    }
//
//    init(point: CGPoint) {
//        magnitude = point.magnitude
//        angle = point.angle
//    }
//
//    init(magnitude: CGFloat, angle: Angle) {
//        self.magnitude = magnitude
//        self.angle = angle
//    }
//}
