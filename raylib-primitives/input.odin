package raylib_primitives

import rl "vendor:raylib"

rotate_mouse :: proc(pitch, yaw: ^f32) {
  delta := rl.GetMouseDelta()

  yaw^ = -1 * delta.x * SENSITIVITY_MOUSE_RAD_S
  pitch^ = delta.y * SENSITIVITY_MOUSE_RAD_S
}

rotate_with_keyboard :: proc(pitch, yaw: ^f32) {
  dt := rl.GetFrameTime()

  if rl.IsKeyDown(.UP) do pitch^ -= SENSITIVITY_RAD_S * dt
  if rl.IsKeyDown(.DOWN) do pitch^ += SENSITIVITY_RAD_S * dt
  if rl.IsKeyDown(.LEFT) do yaw^ += SENSITIVITY_RAD_S * dt
  if rl.IsKeyDown(.RIGHT) do yaw^ -= SENSITIVITY_RAD_S * dt
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


move :: proc(yaw: f32, speed: f32 = SPEED) -> rl.Vector3 {

  walk_vector := calculate_walk_vector(yaw)
  right_vector := calculate_right_vector(yaw)

  move_vector: rl.Vector3

  // Move player and camera (W/S flipped because Z convention)
  if rl.IsKeyDown(.W) do move_vector -= walk_vector
  if rl.IsKeyDown(.S) do move_vector += walk_vector
  if rl.IsKeyDown(.D) do move_vector += right_vector
  if rl.IsKeyDown(.A) do move_vector -= right_vector

  if calculate_vector_magnitude(move_vector) != 0 {   // prevents divide-by-zero
    move_vector = normalize_vector(move_vector)
  }

  dt := rl.GetFrameTime()

  return move_vector * SPEED * dt
}

