package raylib_primitives

import "core:math"
import rl "vendor:raylib"

/*

From [OpenGL](https://learnopengl.com/Getting-started/Camera)

"To define a camera we need its position in world space, the direction it's looking at, a vector pointing to the right and a vector pointing upwards from the camera"

- to define the direction it is looking at (forward vector), we need `pitch` and `yaw`;
- to define the right vector, we need `yaw`;
- to define the up vector, we need the right vector x forward vector.


Therefore the minimum to define a camera is this struct.

NOTE:  in OpenGL, the positive z (+z) is getting OUT of the camera in direction to us, therefore we need to negate the forward vector coordinates when calculating movements and stuff like that.
*/
Camera :: struct {
  position: rl.Vector3,
  pitch:    f32, // radians
  yaw:      f32, // radians
}

SPEED :: 2.0
SENSITIVITY_RAD_S :: 0.003


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

 then normalize it to become unit vector (so our walking speed doesn't change
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

calculate_up_vector :: proc(right, forward: rl.Vector3) -> rl.Vector3 {
  /*

  x × y =  z
  y × z =  x
  z × x =  y

  if you swap the order:

  y × x = -z
  z × y = -x
  x × z = -y

  */
  return calculate_cross_product(forward, right)
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


move :: proc(camera: ^Camera, position: rl.Vector3) {
  position := position
  if calculate_vector_magnitude(position) != 0 {   // prevents divide-by-zero
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

/*

A matrix that is composed by vectors that are orthogonals (they form
90deg between each other) and are unit vectors (length 1) is called
ORTHONORMAL.

For an orthonormal matrix, its inverse is the same as its transpose:

            A^(-1) = A^t

            right_vector = r (coordinate x)
            up_vector = u (coordinate y)
            forward_vector = f (coordinate Z)
 

            |rx ux fx|
        A = |ry uy fy|
            |rz uz fz|


        A * A^t = I


A VIEW MATRIX is a matrix that brings points from the World Coordinate System
into the Camera's view.

"GPU has no camera, the eye is nailed to the origin, looking down a fixed axis.
So instead of moving the camera into the World, we move the World into the camera"

It's defined by:

          View = R^-1 * T^-1

but because the basis is orthonormal:

          View = R^t * T^t

Where:
          R = the camera's axis (r, u, f)
          T = distance from camera's origin to a point

**** Calculating the distance from camera's origin to a point: ****

point (expressed in World Coordinate System (CS)) = [px, py, pz]
camera's origin  (expressed in World CS)= [cx, cy, cz]

distance = point - camera = [px-cx, py-cy, pz-cz] = p - c

but `p-c` will give the distance from c to p in World coordinates. To make that in Camera coordinates, we need to dot it:

on the camera "r" axis (x, right):   r*(p-c)
on the camera "u" axis (y, up):      u*(p-c)
on the camera "f" axis (z, forward): f*(p-c)


So that would become:

T = [r*(p-c), u*(p-c), f*(p-c)]


but, as we know that we're gonna multiply the view matrix by a point and that point carries w=1 in its fourth coordinate, we can fold in the dot product:

r*(p-c) = r*p - r*c = -r*c
                    = -u*c
                    = -f*c

The idea is that the matrix carries things that don't change in the same frame, but a point does. So T becomes:

T = [-r*c, -u*c, -f*c]

*************************************************************************

Now the view matrix becomes effectively:

                |rx ry rz -(r*c)|
       View   = |ux uy uz -(u*c)|
                |fx fy fz -(f*c)|
                |0  0  0    1   |


  Because we are using raylib/openGL, the z coordinate (f) needs to be flipped:

                |rx ry rz -(r*c)|
       View   = |ux uy uz -(u*c)|
                |-fx -fy -fz f*c|
                |0  0  0    1   |

*/
view_matrix :: proc(camera: Camera) -> rl.Matrix {
  r := calculate_right_vector(camera.yaw)
  f := calculate_forward_vector(camera.pitch, camera.yaw)
  u := calculate_up_vector(r, f)

  c := camera.position

  // odinfmt: disable
  return rl.Matrix {
    r.x, r.y, r.z, -1.0 * calculate_dot_product(r, c),
    u.x, u.y, u.z, -1.0 * calculate_dot_product(u, c),
    -f.x, -f.y, -f.z, calculate_dot_product(f, c),
    0.0, 0.0, 0.0, 1.0,
  }
  // odinfmt: enable
}

projection_matrix :: proc() -> rl.Matrix {
  // odinfmt: disable
  return rl.Matrix {
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
  }
  // odinfmt: enable
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

@(private)
new_camera :: proc() -> Camera {
  // odinfmt: disable
  return Camera {
    position = {0.0, 10.0, 20.0},
    pitch = 0.0,
    yaw = 0.0,
  }
  // odinfmt: enable
}

