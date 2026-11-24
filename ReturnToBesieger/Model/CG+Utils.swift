//
//  CG+Utils.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 23/11/26.
//

import SwiftUI

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
    /// Performs the cross product operation on this value and another. Returns the resultant magnitude, as CGPoint is only 2D.
    public func crossMagnitude(rhs: Self) -> CGFloat {
        // c = a x b = | i  j  k | = i | a2 0 | - j | a1 0 | + k | a1 a2 | = k ( a1 * b2 - a2 * b1 )
        //             | a1 a2 0 |     | b2 0 |     | b1 0 |     | b1 b2 |
        //             | b1 b2 0 |
        return self.x * rhs.y - self.y * rhs.x
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
    /// Rotates this vector anticlockwise by the given angle around the origin
    public func rotating(acw angle: Angle) -> CGPoint {
        .init(
            x: x * cos(-angle.radians) - y * sin(-angle.radians),
            y: x * sin(-angle.radians) + y * cos(-angle.radians)
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

