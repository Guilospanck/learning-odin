package raylib_primitives

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

get_random_position :: proc() -> rl.Vector3 {
  x := rand.int32_range(-GRID_SIZE / 2, GRID_SIZE / 2)
  y := rand.int32_range(0, 10)
  z := rand.int32_range(-GRID_SIZE / 2, GRID_SIZE / 2)

  // add 0.5 so cube sits in the cell, not spanning 2 halves of 2 of them
  return rl.Vector3{f32(x) + 0.5, f32(y) + 0.5, f32(z) + 0.5}
}

get_cell_of_block :: proc(position: rl.Vector3) -> rl.Vector3 {
  x := math.floor(position.x / TILE_SIZE)
  y := math.floor(position.y / TILE_SIZE)
  z := math.floor(position.z / TILE_SIZE)

  return rl.Vector3{x, y, z}
}

