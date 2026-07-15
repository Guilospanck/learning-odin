package raylib_primitives

import rl "vendor:raylib"

draw_gizmo :: proc() {
  radius: f32 = 0.05
  sides: i32 = 8

  rl.DrawCylinderEx(
    rl.Vector3{0.0, 0.0, 0.0},
    rl.Vector3{1.0, 0.0, 0.0},
    radius,
    radius,
    sides,
    rl.RED,
  )
  rl.DrawCylinderEx(
    rl.Vector3{0.0, 0.0, 0.0},
    rl.Vector3{0.0, 1.0, 0.0},
    radius,
    radius,
    sides,
    rl.GREEN,
  )
  rl.DrawCylinderEx(
    rl.Vector3{0.0, 0.0, 0.0},
    rl.Vector3{0.0, 0.0, 1.0},
    radius,
    radius,
    sides,
    rl.BLUE,
  )
}

draw_cube :: proc(
  pos: rl.Vector3,
  size: rl.Vector3,
  color: rl.Color = rl.GRAY,
  draw_wires: bool = true,
) {
  rl.DrawCubeV(pos, size, color)
  if draw_wires {
    rl.DrawCubeWiresV(pos, size, rl.BLACK)
  }
}

