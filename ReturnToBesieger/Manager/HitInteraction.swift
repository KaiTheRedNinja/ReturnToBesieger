//
//  HitInteraction.swift
//  ReturnToBesieger
//
//  Created by Kai Quan Tay on 24/11/26.
//

import SwiftUI

protocol HitInteraction {
    associatedtype HitBox1: HitBox
    associatedtype HitBox2: HitBox

    /// Whether or not two hitboxes intersect each other
    func intersects(hitBox1: HitBox1, hitBox2: HitBox2) -> Bool
    /// The normal unit vector from one hitbox to another. You may assume that `intersects` was
    /// called previously and returned `true`, i.e. the hitboxes for these two values do intersect.
    ///
    /// In this case, it is the first hitbox hitting the second hitbox.
    func normalUnitVector(to hitBox1: HitBox1, from hitBox2: HitBox2) -> CGPoint

    /// Type-erased implementation of `intersects`
    func intersects(hitBox1: any HitBox, hitBox2: any HitBox) throws(HitInteractionError) -> Bool
    /// Type-erased implementation of `normalVector`
    func normalUnitVector(to hitBox1: any HitBox, from hitBox2: any HitBox) throws(HitInteractionError) -> CGPoint
}

enum HitInteractionError: Error {
    case wrongType
}

extension HitInteraction {
    /// Type-erased implementation of `intersects`
    func intersects(hitBox1: any HitBox, hitBox2: any HitBox) throws(HitInteractionError) -> Bool {
        guard let hitBox1 = hitBox1 as? HitBox1,
              let hitBox2 = hitBox2 as? HitBox2
                else { throw .wrongType }
        return intersects(hitBox1: hitBox1, hitBox2: hitBox2)
    }
    /// Type-erased implementation of `normalVector`
    func normalUnitVector(to hitBox1: any HitBox, from hitBox2: any HitBox) throws(HitInteractionError) -> CGPoint {
        guard let hitBox1 = hitBox1 as? HitBox1,
              let hitBox2 = hitBox2 as? HitBox2
                else { throw .wrongType }
        return normalUnitVector(to: hitBox1, from: hitBox2)
    }
}

struct CircleCircleHitInteraction: HitInteraction {
    typealias HitBox1 = CircleHitbox
    typealias HitBox2 = CircleHitbox

    func intersects(hitBox1: CircleHitbox, hitBox2: CircleHitbox) -> Bool {
        // the distance between the two circles must be less than the radius
        // but more than their difference (otherwise they are concentric)
        let centerDistance = (hitBox2.center - hitBox1.center).magnitude
        return abs(hitBox1.radius - hitBox2.radius) < centerDistance && centerDistance < (hitBox1.radius + hitBox2.radius)
    }

    func normalUnitVector(to hitBox1: CircleHitbox, from hitBox2: CircleHitbox) -> CGPoint {
        // its literally just the vector from the center of one to the center of another....
        let offsetVector = hitBox1.center - hitBox2.center
        return offsetVector.unitVec()
    }
}

struct CircleLineHitInteraction: HitInteraction {
    typealias HitBox1 = CircleHitbox
    typealias HitBox2 = LineSegment

    /// Determines the closest point on this line to a ball
    func closestPoint(toCircle circle: CircleHitbox, onLine line: LineSegment) -> CGPoint {
        // if points are equal, its just that point
        guard line.point1 != line.point2 else { return line.point1 }

        // a line can be expressed parametrically as:
        // A + t(B-A)
        // where A and B are vectors corresponding to point 1 and 2, and t ranges from 0 to 1.

        // the closest point can therefore be found via clamping the following to 0 and 1:
        // t = (C - A).(B - A) / |B - A|^2

        let ca = circle.center - line.point1
        let ba = line.point2 - line.point1

        let tRaw = (ca).dot(ba) / pow((ba).magnitude, 2)
        let t = max(0, min(tRaw, 1))

        // return the point
        return line.point1 + t * (ba)
    }

    /// Returns whether a given point is within or on the circle
    func contains(point: CGPoint, inCircle circle: CircleHitbox) -> Bool {
        // definition of a circle
        // (x-c_x)^2 + (y-c_y)^2 = r^2
        // points within the circle are <= r^2 instead
        (point.x - circle.center.x) * (point.x - circle.center.x) +
        (point.y - circle.center.y) * (point.y - circle.center.y) <= circle.radius*circle.radius
    }

    /// Returns whether or not a ball intersects this line
    func intersects(hitBox1: CircleHitbox, hitBox2: LineSegment) -> Bool {
        let closest = closestPoint(toCircle: hitBox1, onLine: hitBox2)
        return contains(point: closest, inCircle: hitBox1)
    }
    /// Returns the normal unit vector of a collision between the ball and the line. This will point from the line to the ball.
    func normalUnitVector(to hitBox1: CircleHitbox, from hitBox2: LineSegment) -> CGPoint {
        let closest = closestPoint(toCircle: hitBox1, onLine: hitBox2)
        return (hitBox1.center - closest).unitVec()
    }
}

struct LineLineHitInteraction: HitInteraction {
    typealias HitBox1 = LineSegment
    typealias HitBox2 = LineSegment

    func intersects(hitBox1: LineSegment, hitBox2: LineSegment) -> Bool {
        /* python code for intersects, found on StackOverflow
         def ccw(A, B, C):
         """
         Determine if three points are listed in a counterclockwise order.

         If the slope of the line AB is less than the slope of the
         line AC, then the three points are listed in a counterclockwise order.
         """
         return (C.y - A.y) * (B.x - A.x) > (B.y - A.y) * (C.x - A.x)

         def intersect(A, B, C, D):
         """Return true if line segments AB and CD intersect."""
         return ccw(A, C, D) != ccw(B, C, D) and ccw(A, B, C) != ccw(A, B, D)
         */

        func ccw(pointA: CGPoint, pointB: CGPoint, pointC: CGPoint) -> Bool {
            (pointC.y - pointA.y) * (pointB.x - pointA.x) > (pointB.y - pointA.y) * (pointC.x - pointA.x)
        }

        // given two lines AB and CD, use the clockwise/anticlockwise equation to determine if they intersect
        return ccw(pointA: hitBox1.point1, pointB: hitBox2.point1, pointC: hitBox2.point2) // A C D
            != ccw(pointA: hitBox1.point2, pointB: hitBox2.point1, pointC: hitBox2.point2) // B C D
            && ccw(pointA: hitBox1.point1, pointB: hitBox1.point2, pointC: hitBox2.point1) // A B C
            != ccw(pointA: hitBox1.point1, pointB: hitBox1.point2, pointC: hitBox2.point2) // A B D
    }

    func normalUnitVector(to hitBox1: LineSegment, from hitBox2: LineSegment) -> CGPoint {
        // determine the normal for the intersection of two lines
        // first we determine the intercept

        // for two lines expressed as:
        // Line 1: A1 + t1 * u1
        // Line 2: A2 + t2 * u2
        // t1 can be found using cramer's rule:
        let a1 = hitBox1.point1
        let u1 = hitBox1.point2 - hitBox1.point1
        let a2 = hitBox2.point1
        let u2 = hitBox2.point2 - hitBox2.point1
        guard u1 != .zero, u2 != .zero else { return .zero } // points cannot intercept lines, nor each other
        let numerator = (a2.x - a1.x)*(-u2.y) - (a2.y - a1.y)*(-u2.x)
        let denominator = (u1.x * -u2.y) - (u1.y * -u2.x)
        guard denominator != .zero else { return .zero } // parallel lines cannot intercept each other.
        let t1 = numerator / denominator
        // t1 must be within bounds
        guard 0 <= t1, t1 <= 1 else { return .zero }
        // calculate the location of the intercept
        let intercept = a1 + t1 * u1
        // using intercept = A2 + t2 * u2, determine t2
        let t2 = (intercept - a2).dot(u2.unitVec()) / u2.magnitude
        // t2 must be within bounds
        guard 0 <= t2, t2 <= 1 else { return .zero }

        // we determine the line with the largest end distance to the intercept
        let line1Dist = min((hitBox1.point1 - intercept).magnitude, (hitBox1.point2 - intercept).magnitude)
        let line2Dist = min((hitBox2.point1 - intercept).magnitude, (hitBox2.point2 - intercept).magnitude)
        // if they have the same distance, its an ambiguous case so we don't render a normal.
        guard line1Dist != line2Dist else { return .zero }

        // get the raw offset, which is just the center of line 2 to the center of line 1
        let rawOffset = hitBox1.center - hitBox2.center

        let lineNormal = if line1Dist > line2Dist {
            // line 1 is larger, we return a vector along line 1's normal, but in the direction of line 2 to line 1
            u1.rotating(acw: .degrees(90)).unitVec()
        } else {
            // line 2 is larger, we return a vector along line 2's normal, but in the direction of line 2 to line 1
            u2.rotating(acw: .degrees(90)).unitVec()
        }

        return (rawOffset.dot(lineNormal) * lineNormal).unitVec()
    }
}
