package raylib_primitives

import "core:math"
import rl "vendor:raylib"

// magnitude^2 = x^2 + y^2 + z^2
// NOTE: you can also just use raylib's `rl.Vector3Length(v)`
calculate_vector_magnitude :: proc(v: rl.Vector3) -> f32 {
  return math.sqrt_f32(math.pow_f32(v.x, 2) + math.pow_f32(v.y, 2) + math.pow_f32(v.z, 2))
}

/*

A dot product is defined by:

    a * b
    = b * a                         (it's symmetric)
    = a.x*b.x + a.y*b.y + a.z*b.z
    = |a| * |b| * cos(theta)        (theta is the angle between the vectors)

Therefore, when one of the vectors is a unit vector (let's say vector b),
we have |b| = 1, then:

    a * b = |a| * cos(theta)

    which means "the shadow that vector a casts on the axis of (same direction of) vector b"

// NOTE: you could also use `rl.Vector3DotProduct(a, b)`
*/
calculate_dot_product :: proc(a, b: rl.Vector3) -> f32 {
  /*

  OR

  array programming

  c := a*b
  return c.x + c.y + c.z

  */
  return a.x * b.x + a.y * b.y + a.z * b.z
}

/*

a * b = |a| * |b| * cos(theta)

- a and b are vectors
- where theta is the angle between vectors a and b
- |a| and |b| are the length of the vectors a and b respectively. 
  For a unit vector, the length is always 1.

for two vectors to be perpendicular, their cos(theta) needs to be 0 (cos(90) = cos(-90) = 0)

Then:

a * b == 0

*/
are_vectors_perpendicular :: proc(a, b: rl.Vector3) -> bool {
  dot := calculate_dot_product(a, b)
  return dot == 0
}

/*
Normalization is a process by which you turn a vector into a unit vector (one
with magnitude equal to 1).

             normalized = v.x/|v|, v.y/|v|, v.z/|v|

You generally use it when you care only about the direction and not the length
of the vector.

For example, in a game if you were to calculate the direction of a player based
on an enemy, you could get something like this:

direction = enemy_pos - player_pos
direction = (30, 40)

then, if you were to move the player by that direction:

player_pos += direction

the player would jump 50 positions (hip^2 = cat_oppo^2 + cat_adj^2).

by normalizing the direction vector, you only care about that - the direction.
the distance would always be whatever you defined in your game.

direction = normalize(enemy_position - player_position)
player += direction * speed * delta_time

now the player will move at a constant speed, no matter where the enemy is.


NOTE: this is here like this only so it's easier for me to remember what those things are.
In a real application, use `rl.Vector3Normalize(v)`

Other raylib helpers:

rl.Vector3Length(v)
rl.Vector3DotProduct(a, b)
rl.Vector3CrossProduct(a, b)

*/
normalize_vector :: proc(v: rl.Vector3) -> rl.Vector3 {
  length := calculate_vector_magnitude(v)
  assert(length != 0, "length is zero, cannot normalize vector")

  return rl.Vector3{v.x / length, v.y / length, v.z / length}
}


// A cross-product is an operation on two vectors that produce a new vector
// that is perpendicular to both.
calculate_cross_product :: proc(v1, v2: rl.Vector3) -> rl.Vector3 {
  return rl.Vector3CrossProduct(v1, v2)
}

rotate :: proc(apply_tolerance: bool = false) -> (pitch, yaw: f32) {
  delta := rl.GetMouseDelta()

  yaw = -1 * delta.x * SENSITIVITY_MOUSE_RAD_S
  pitch = delta.y * SENSITIVITY_MOUSE_RAD_S

  if apply_tolerance {
    TOLERANCE :: 0.01

    // prevent gimbal lock (-+90deg -+tolerance)
    pitch = rl.Clamp(pitch, -math.PI / 2 + TOLERANCE, math.PI / 2 - TOLERANCE)

    // Clamps at [-pi, pi) just so the yaw doesn't grow undefinitely, but not a bug per-se
    yaw = rl.Clamp(yaw, -1 * math.PI + TOLERANCE, math.PI - TOLERANCE)
  }

  return pitch, yaw
}

/*

FUN FACT: 

There's something called "diagonal strafing" or "strafe-running" in which
running diagonally makes one run faster. This bug was shipped in many games,
including Quake.

If you think about it, pressing W and D at the same time (forward and right).

forward is (0, 0, 1) and right is (1, 0, 0).
This direction length of the resulting vector (forward + right) is:

resulting vector : (0, 0, 1) + (1, 0, 0) = (1, 0, 1)
length: sqrt(resulting^2) = sqrt(2) ~ 1.41

which makes you run ~41% faster when diagonally.

-> Therefore, we should always normalize the vector before moving the unit
and before scaling by speed.

if linalg.length(move) > 0 { // prevents division by zero
    move = linalg.normalize(move)
}
cam.position += move * speed * dt


CAVEAT

what if you would press W and SPACE (go up) at the same time?

SPACE moves you up in the y-axis (0, 1, 0).

therefore the length of W + SPACE would be:

sqrt([(0, 0, 1) + (0, 1, 0)]^2) 
=> sqrt((0, 1, 1) ^2)
=> sqrt(2)

the same as W + D before, but here you could think about it:

- do I want to normalize the up vector as well for that?
- maybe you just want to normalize the ground direction (WASD), but
leave the y-axis direction (SPACE, LEFT-SHIFT) as normal.

*/


move :: proc(position: rl.Vector3, speed: f32 = SPEED) -> rl.Vector3 {
  position := position
  if calculate_vector_magnitude(position) != 0 {   // prevents divide-by-zero
    position = normalize_vector(position)
  }

  dt := rl.GetFrameTime()

  return position * SPEED * dt
}

