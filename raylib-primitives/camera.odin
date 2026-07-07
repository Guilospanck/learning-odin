package raylib_primitives

import rl "vendor:raylib"

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

