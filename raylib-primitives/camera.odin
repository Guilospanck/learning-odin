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
  fovy:     f32, // radians
}

CameraMode :: enum {
  First_Person,
  Third_Person,
}

SPEED: f32 : 2.0
SENSITIVITY_RAD_S: f32 : 0.3
SENSITIVITY_MOUSE_RAD_S: f32 : 0.003
NEAR_PLANE: f32 : 0.1
FAR_PLANE: f32 : 100.0

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

/*


When you have a field of view (fovy), you can calculate the constant that goes
into the projection matrix.

Remember:
          / 
        /           |
      /             | screen_height (in world coordinates)
     / ) fovy/2      |
eye o - - - - - - - - - - -> depth (d)
     \ ) fovy/2
      \
       \
        \

        tan(fovy/2) = screen_height / d
        screen_height = tan(fovy/2) * d

>>> but Yndc (normalized device coordinates for y) needs to be [-1, +1], therefore

        Yndc = some_point_height (in world coordinates) / screen_height = +1

>>> And replacing the values:

        Yndc = some_point_height / tan(fovy/2) * d
        Yndc = some_point_height * 1/d * 1/tan(fovy/2)


    where:
    - some_point_height: the "y" coordinate of some vertex that we're gonna multiply for
    - 1/tan(fovy/2): the focal length constant (f). Lives in the projection matrix
    - 1/d: automatically done by the GPU when we equal `w` to `z`

>>> when Yndc > |1|, it lands outside of the screen and therefore it gets clipped

*/
calculate_fovy_focal_length :: proc(fovy: f32) -> f32 {
  return 1.0 / math.tan_f32(fovy / 2)
}

/*

Because the fovy is vertical, when laying it on the y-axis it already works correctly
to fit the [-1, +1] NDC cube.

But, when that happens, we still need to pre-cancel the sggtretch that would happen
with the x-axis, so for that we need the aspect ratio, which would then be used
as f/a when setting the x coordinate for the projection matrix.

      Xndc = some_point_width * 1/d * 1/(a * tan(fovy/2))
           = some_point_width * 1/d * 1/a * 1/tan(fovy/2)
           = some_point_width * 1/d * 1/a * f
           = some_point_width * 1/d * f/a 

*/
calculate_aspect_ratio :: proc(screen_width, screen_height: f32) -> f32 {
  return screen_width / screen_height
}

/*

  As we did with the first (x) and second (y) rows of the projection matrix, we need to also
  do the same for the third row (z) to include them into the NDC cube [-1, +1] (x, y, z).

  So the third row has the responsibility of mapping [near, far] -> [-1, 1]

  The third row can only be [0 0 A B]. Remember that each coordinate gets divided
  by w (or depth if w = z) by the GPU, but we don't want that in the depth (z) coordinate,
  otherwise we would miss the whole depth purpose.

  Therefore we must think of a way that would actually cancel that GPU division:

  [0 0 A B] * | x |
              | y |
              | z |
              | 1 |

  then:

  Zclip = A * z + B

  but after division by depth, this would turn into:

  Zndc = Zclip / w  = (Az + B) / z = A + B/z

  (see how this follows a 1/z curve, which changes quickly when z is small
  and settles when z is bigger, exactly how the near and far planes work)

  At near plane:
        z = near_plane => A + B/near_plane = -1

  At far plane:
        z = far_plane => A + B/far_plane = +1


  You now have two equations. By subtracting one from another and then substituting afterwards,
  you find the values for A and B:

        A = - (near_plane + far_plane) / (near_plane - far_plane)
        B = 2 * near_plane * far_plane / (near_plane - far_plane)


*/
calculate_z_clip_a_and_b :: proc() -> (f32, f32) {
  A := -(NEAR_PLANE + FAR_PLANE) / (NEAR_PLANE - FAR_PLANE)
  B := 2 * NEAR_PLANE * FAR_PLANE / (NEAR_PLANE - FAR_PLANE)

  return A, B
}

/*

 The GPU wants points inside a cube [-1, 1](x, y, z) that's called 
 "Normalized Device Coordinates" (NDC).

 With a perspective projection matrix, we want to solve basically 3 problems:

 - the x and y rows (1st and 2nd): we want to shrink sideways position by depth (perspective) and scale by field of view (fovy), so the visible width maps to [-1, +1].

 - the z row (3rd): it's the depth. It will remap it from [near, far plane] to [-1, +1]


 - the w row (4th): copy depth into `w` so the hardware divides by depth. By having the fourth row, third column as 1.0, it will generate [x, y, z, z] (therefore the w coordinate is z: `w = z`), which the GPU will use to divide everything by w: 

 [x/w, y/w, z/w, w/w] => [x/z, y/z, z/z, z/z] => [x/z, y/z, 1, 1] (divide by depth)

*/
projection_matrix :: proc(fovy, screen_width, screen_height: f32) -> rl.Matrix {

  focal_length := calculate_fovy_focal_length(fovy)
  aspect_ratio := calculate_aspect_ratio(screen_width, screen_height)

  a, b := calculate_z_clip_a_and_b()

  // odinfmt: disable
  return rl.Matrix {
    focal_length/aspect_ratio, 0.0, 0.0, 0.0, // x scale
    0.0, focal_length, 0.0, 0.0, // y scale
    0.0, 0.0, a, b,
    0.0, 0.0, 1.0, 0.0, 
  }
  // odinfmt: enable
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


move_camera :: proc(camera: ^Camera, position: rl.Vector3) {
  position := position
  if calculate_vector_magnitude(position) != 0 {   // prevents divide-by-zero
    position = normalize_vector(position)
  }

  dt := rl.GetFrameTime()

  camera.position += position * SPEED * dt
}

rotate_camera :: proc(camera: ^Camera, apply_tolerance: bool = false) {
  delta := rl.GetMouseDelta()

  camera.yaw += -1 * delta.x * SENSITIVITY_MOUSE_RAD_S
  camera.pitch += delta.y * SENSITIVITY_MOUSE_RAD_S

  if apply_tolerance {
    TOLERANCE :: 0.01

    // prevent gimbal lock (-+90deg -+tolerance)
    camera.pitch = rl.Clamp(camera.pitch, -math.PI / 2 + TOLERANCE, math.PI / 2 - TOLERANCE)

    // Clamps at [-pi, pi) just so the yaw doesn't grow undefinitely, but not a bug per-se
    camera.yaw = rl.Clamp(camera.yaw, -1 * math.PI + TOLERANCE, math.PI - TOLERANCE)
  }
}

