# ReturnToBesieger
"Your walls are under siege! Prepare the cannons!!!"
".... what do you mean we have no cannons."

In ReturnToBesieger, your tiny little fortress is under siege, but you have no weapons! The only things you have are builders, lots of rocks, and knowledge of physics. Your job is to build walls around your fortress, reflecting your opponents attacks back at them. You have to destroy them (either by killing their king, or killing all of their attackers) before they destroy you.

## Why?
I want to learn how to make a physics engine. Balls on rectangular walls is one of the simplest ways to do it :P

## Feature plan
Physics sim:
- [x] Balls
- [x] Rectangles
  - [x] Grid-aligned
  - [x] Arbitrary rotation
- [x] Movement using delta-time
- [x] Collisions
  - [x] Ball-rectangle collision detection
  - [x] Ball-ball collision detection
  - [x] Rectangle-rectangle collision detection
  - [ ] Normal vector
  - [ ] Point of collision
  - [x] Perfectly elastic collisions
  - [ ] Collisions with rotation
- [ ] Friction (with the floor)

Game:
- [ ] Render screen
