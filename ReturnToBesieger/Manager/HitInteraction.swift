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
