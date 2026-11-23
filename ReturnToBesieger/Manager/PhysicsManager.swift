//
//  PhysicsManager.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

class PhysicsManager {

}

struct Ball {
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

struct Line {
    var point1: CGPoint
    var point2: CGPoint

    var frame: CGRect {
        .init(
            minX: min(point1.x, point2.x),
            minY: min(point1.y, point2.y),
            maxX: max(point1.x, point2.x),
            maxY: max(point1.y, point2.y)
        )
    }

    /// Determines the closest point on this line to a ball
    func closestPoint(toBall ball: Ball) -> CGPoint {
        // if points are equal, its just that point
        guard point1 != point2 else { return point1 }

        // a line can be expressed parametrically as:
        // A + t(B-A)
        // where A and B are vectors corresponding to point 1 and 2, and t ranges from 0 to 1.

        // the closest point can therefore be found via clamping the following to 0 and 1:
        // t = (C - A).(B - A) / |B - A|^2

        let ca = ball.center - point1
        let ba = point2 - point1

        let t = max(0, min((ca).dot(ba) / pow((ba).magnitude, 2), 1))

        // return the point
        return point1 + t * (ba)
    }

    /// Returns whether or not a ball intersects this line
    func intersects(ball: Ball) -> Bool {
        let closest = closestPoint(toBall: ball)
        return ball.contains(point: closest)
    }

    /// Returns the normal unit vector of a collision between the ball and the line. This will point from the line to the ball.
    func normalUnitVector(ball: Ball) -> CGPoint {
        let closest = closestPoint(toBall: ball)
        return (ball.center - closest).unitVec()
    }
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width/2, y: center.y - size.height/2, width: size.width, height: size.height)
    }

    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.init(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
    }
}

/// Vector extensions
extension CGPoint {
    /// Adds two vectors together
    static func + (lhs: Self, rhs: Self) -> CGPoint {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    /// Subtracts a vector from another
    static func - (lhs: Self, rhs: Self) -> CGPoint {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    /// Subtracts a vector from zero
    static prefix func - (rhs: Self) -> CGPoint {
        .init(x: -rhs.x, y: -rhs.y)
    }
    /// Scales a vector by a scalar
    static func * (lhs: CGFloat, rhs: Self) -> CGPoint {
        .init(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    /// Performs the dot product operation on this value and another
    func dot(_ rhs: Self) -> CGFloat {
        self.x * rhs.x + self.y * rhs.y
    }
    /// Obtains the unit vector of this vector
    func unitVec() -> CGPoint {
        .init(x: x / magnitude, y: y / magnitude)
    }
    /// The magnitude of this vector
    var magnitude: CGFloat {
        sqrt(x*x + y*y)
    }
}
