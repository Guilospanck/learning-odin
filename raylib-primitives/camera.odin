package raylib_primitives

import "core:math"
import rl "vendor:raylib"

Camera :: struct {
  position: rl.Vector3,
  pitch:    f32,
  yaw:      f32,
}


calculate_forward_vector :: proc(pitch, yaw: f32) -> rl.Vector3 {
  assert(
    pitch >= -89 && pitch <= 89,
    "pitch needs to be -89 <= pitch <= 89 to prevent gimbal lock",
  )

  return rl.Vector3 {
    math.cos_f32(pitch) * math.sin_f32(yaw),
    math.sin_f32(pitch),
    math.cos_f32(pitch) * math.cos_f32(yaw),
  }
}

/*
Get the forward vector and zero the y (up) coordinate:

      cos(pitch)*sin(yaw), 0, cos(pitch)*cos(yaw)

 then normalizes it to become unit vector (so our walking speed doesn't change
 based on how downwards we're looking),
 by dividing by cos(pitch), which is the magnitude of this vector. See:

 magnitude^2 = x^2 + y^2 + z^2
 magnitude^2 = cos(pitch)^2 * sin(yaw)^2 + 0^2 + cos(pitch)^2 * cos(yaw)^2
 magnitude^2 = cos(pitch)^2 * (sin(yaw)^2 + cos(yaw)^2)
 magnitude^2 = cos(pitch)^2 * 1
 magnitude^2 = cos(pitch)^2
 magnitude = cos(pitch)

               sin(yaw), 0, cos(yaw)
*/
calculate_walk_vector :: proc(yaw: f32) -> rl.Vector3 {
  return rl.Vector3{math.sin_f32(yaw), 0, math.cos_f32(yaw)}
}

/*

A right vector is our walk vector shifted 90 degrees.

walk vector:
               sin(yaw), 0, cos(yaw)

shift by 90 deg:
               sin(yaw + 90), 0, cos(yaw + 90)
               cos(yaw), 0, -sin(yaw)
*/
calculate_right_vector :: proc(yaw: f32) -> rl.Vector3 {
  return rl.Vector3{math.cos_f32(yaw), 0, -math.sin_f32(yaw)}
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


SPEED :: 2.0

SENSITIVITY_RAD_S :: 0.003

move :: proc(camera: ^Camera, position: rl.Vector3) {
  position := position
  if calculate_vector_magnitude(position) != 0 {
    position = normalize_vector(position)
  }

  dt := rl.GetFrameTime()

  camera.position += position * SPEED * dt
}

rotate :: proc(camera: ^Camera) {
  delta := rl.GetMouseDelta()

  camera.yaw += delta.x * SENSITIVITY_RAD_S
  camera.pitch += delta.y * SENSITIVITY_RAD_S

  TOLERANCE :: 0.01

  // prevent gimbal lock (-+90deg -+tolerance)
  camera.pitch = rl.Clamp(camera.pitch, -math.PI / 2 + TOLERANCE, math.PI / 2 - TOLERANCE)

  // Clamps at [0, 2pi) just so the yaw doesn't grow undefinitely, but not a bug per-se
  camera.yaw = rl.Clamp(camera.yaw, 0, 2 * math.PI - TOLERANCE)
}

@(private)
my_camera :: proc() -> rl.Camera3D {
  camera := rl.Camera3D {
    position   = {0.0, 10.0, 10.0},
    target     = {0.0, 0.0, 0.0},
    up         = {0.0, 1.0, 0.0},
    fovy       = 45.0,
    projection = .PERSPECTIVE,
  }

  return camera
}

