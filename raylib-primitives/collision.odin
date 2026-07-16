package raylib_primitives

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:prof/spall"
import "core:strings"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

TILE_SIZE :: 1.0
GRID_SIZE :: 100

NUMBER_OF_BLOCKS :: 10_000

WIDTH :: 1920
HEIGHT :: 1080

PLAYER_DEFAULT_COLOR :: rl.GREEN

spall_ctx: spall.Context
spall_buffer: spall.Buffer

Unit :: struct {
  position:   rl.Vector3,
  yaw, pitch: f32,
  colour:     rl.Color,
}

Block :: struct {
  position: rl.Vector3,
}

// Basically just cancels unit movement
resolve_collision :: proc(unit: ^Unit, obstacle: rl.Vector3) {
  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "resolve_collision")
  dt := rl.GetFrameTime()

  // Collision resolution logic
  if unit.position.z < obstacle.z - 1 {   // player above
    unit.position.z -= dt * SPEED
  }
  if unit.position.z > obstacle.z + 1 {   // player below
    unit.position.z += dt * SPEED
  }
  if unit.position.x < obstacle.x - 1 {   // player on left
    unit.position.x -= dt * SPEED
  }
  if unit.position.x > obstacle.x + 1 {   // player on right
    unit.position.x += dt * SPEED
  }
}

get_cell_of_block :: proc(position: rl.Vector3) -> rl.Vector3 {
  x := math.floor(position.x / TILE_SIZE)
  y := math.floor(position.y / TILE_SIZE)
  z := math.floor(position.z / TILE_SIZE)

  return rl.Vector3{x, y, z}
}

get_camera_position_based_on_camera_mode :: proc(
  camera_mode: ^CameraMode,
  player_unit: ^Unit,
) -> rl.Vector3 {

  if camera_mode^ == CameraMode.Third_Person {
    CAMERA_Z_DISTANCE_TO_PLAYER_3RD_PERSON_VIEW: f32 : 15.0
    CAMERA_Y_DISTANCE_TO_PLAYER_3RD_PERSON_VIEW: f32 : 2.0

    forward_vector := calculate_forward_vector(player_unit.pitch, player_unit.yaw)

    return(
      player_unit.position +
      forward_vector * CAMERA_Z_DISTANCE_TO_PLAYER_3RD_PERSON_VIEW +
      {0, CAMERA_Y_DISTANCE_TO_PLAYER_3RD_PERSON_VIEW, 0} \
    )
  }

  CAMERA_DISTANCE_TO_PLAYER_1ST_PERSON_VIEW: f32 : 0.5

  return player_unit.position + {0, CAMERA_DISTANCE_TO_PLAYER_1ST_PERSON_VIEW, 0}
}

toggle_camera_mode :: proc(camera_mode: ^CameraMode, camera: ^Camera, player_unit: ^Unit) {
  if camera_mode^ == CameraMode.First_Person {
    camera_mode^ = CameraMode.Third_Person

    camera.yaw = player_unit.yaw
    camera.pitch = math.PI / 4 // 45 deg

  } else {
    camera_mode^ = CameraMode.First_Person

    camera.yaw = player_unit.yaw
    camera.pitch = player_unit.pitch
  }

  camera.position = get_camera_position_based_on_camera_mode(camera_mode, player_unit)
}

process_input :: proc(camera: ^Camera, player_unit: ^Unit, camera_mode: ^CameraMode) {
  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "process_input")

  // change camera mode
  if rl.IsKeyPressed(.Q) {
    toggle_camera_mode(camera_mode, camera, player_unit)
    return
  }

  /******** ROTATION *************/
  yaw, pitch: f32

  // Rotate camera with mouse
  rotate_mouse(&pitch, &yaw)
  // Rotate camera with keyboard
  rotate_with_keyboard(&pitch, &yaw)

  // do not allow pitch on 3rd person view
  if camera_mode^ == CameraMode.Third_Person {
    pitch = 0
  }

  camera.pitch += pitch
  camera.yaw += yaw

  TOLERANCE :: 0.01
  // prevent gimbal lock (-+90deg -+tolerance)
  camera.pitch = rl.Clamp(camera.pitch, -math.PI / 2 + TOLERANCE, math.PI / 2 - TOLERANCE)

  // Set player to the same rotation as camera
  player_unit.pitch = camera.pitch
  player_unit.yaw = camera.yaw

  /******** TRANSLATION *************/
  step_vector := move(camera.yaw, SPEED)
  player_unit.position += step_vector
  camera.position = get_camera_position_based_on_camera_mode(camera_mode, player_unit)
}

draw_sphere_on_ray_hit :: proc(camera: rl.Camera3D, box_collision: rl.BoundingBox) {
  ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
  ray_collision := rl.GetRayCollisionBox(ray, box_collision)
  if ray_collision.hit {
    rl.DrawSphere(ray_collision.point, 0.3, rl.RED)
  }
}

get_random_position :: proc() -> rl.Vector3 {
  x := rand.int32_range(-GRID_SIZE / 2, GRID_SIZE / 2)
  y := rand.int32_range(0, 10)
  z := rand.int32_range(-GRID_SIZE / 2, GRID_SIZE / 2)

  // add 0.5 so cube sits in the cell, not spanning 2 halves of 2 of them
  return rl.Vector3{f32(x) + 0.5, f32(y) + 0.5, f32(z) + 0.5}
}

is_neighbouring_player :: proc(block_position, player_cell: rl.Vector3) -> bool {

  block_cell := get_cell_of_block(block_position)

  dx := math.abs(block_cell.x - player_cell.x)
  dy := math.abs(block_cell.y - player_cell.y)
  dz := math.abs(block_cell.z - player_cell.z)

  return dx <= 1 && dy <= 1 && dz <= 1
}

handle_collision :: proc(
  player_unit: ^Unit,
  camera: ^Camera,
  camera_mode: ^CameraMode,
  player_neighbouring_blocks: []int,
  blocks: []Block,
) {
  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "handle_collision")

  collision := false
  collided_block_pos: rl.Vector3 = rl.Vector3(0)

  // Check collisions player vs block
  player_box := rl.BoundingBox {
    min = {
      player_unit.position.x - TILE_SIZE / 2,
      player_unit.position.y - TILE_SIZE / 2,
      player_unit.position.z - TILE_SIZE / 2,
    },
    max = {
      player_unit.position.x + TILE_SIZE / 2,
      player_unit.position.y + TILE_SIZE / 2,
      player_unit.position.z + TILE_SIZE / 2,
    },
  }

  for b in player_neighbouring_blocks {
    block := blocks[b]

    block_box := rl.BoundingBox {
      min = {
        block.position.x - TILE_SIZE / 2,
        block.position.y - TILE_SIZE / 2,
        block.position.z - TILE_SIZE / 2,
      },
      max = {
        block.position.x + TILE_SIZE / 2,
        block.position.y + TILE_SIZE / 2,
        block.position.z + TILE_SIZE / 2,
      },
    }

    collision = rl.CheckCollisionBoxes(player_box, block_box)
    if collision {
      collided_block_pos = block.position
      break
    }
  }

  if collision {
    player_unit.colour = rl.RED
    resolve_collision(player_unit, collided_block_pos)
    camera^.position = get_camera_position_based_on_camera_mode(camera_mode, player_unit)
  } else {
    player_unit^.colour = PLAYER_DEFAULT_COLOR
  }
}

generate_blocks :: proc(
  blocks: []Block,
  player_neighbouring_blocks: ^[dynamic]int,
  player_cell: rl.Vector3,
) {
  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "generate_blocks")
  placed_block_pos: map[rl.Vector3]bool = {}


  outer: for i in 0 ..< NUMBER_OF_BLOCKS {
    pos: rl.Vector3

    // prevent placing blocks at the same places (limit to 3 attempts)
    block_random_pos_attempts := 0
    for {
      block_random_pos_attempts += 1

      pos = get_random_position()
      if placed_block_pos[pos] {
        if block_random_pos_attempts > 3 do continue outer
        continue
      }

      blocks[i] = Block {
        position = pos,
      }

      placed_block_pos[pos] = true

      break
    }

    if (is_neighbouring_player(pos, player_cell)) {
      append(player_neighbouring_blocks, i)
    }
  }
}

main :: proc() {
  spall_ctx = spall.context_create("trace.spall")
  defer spall.context_destroy(&spall_ctx)

  buffer_backing := make([]u8, 1 << 20) // 1MB
  spall_buffer = spall.buffer_create(buffer_backing)
  defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "main")

  rl.InitWindow(WIDTH, HEIGHT, "quadtree based collision detection")
  defer rl.CloseWindow()

  COLORS: []rl.Color = {rl.DARKPURPLE, rl.PURPLE, rl.DARKBLUE, rl.BLUE}

  player_unit := Unit {
    position = {-4.0, 1.0, -4.0},
    colour   = PLAYER_DEFAULT_COLOR,
  }
  player_cell := get_cell_of_block(player_unit.position)


  // Generate blocks
  player_neighbouring_blocks: [dynamic]int = {}
  defer delete(player_neighbouring_blocks)

  blocks: [NUMBER_OF_BLOCKS]Block = {}
  generate_blocks(
    blocks = blocks[:],
    player_neighbouring_blocks = &player_neighbouring_blocks,
    player_cell = player_cell,
  )

  camera := Camera {
    position = {-4.0, 1.0, -4.0},
    pitch    = 0.0,
    yaw      = 0.0,
    fovy     = math.PI / 4, // 45deg
  }

  camera_mode := CameraMode.First_Person

  projection := projection_matrix(camera.fovy, WIDTH, HEIGHT)

  // These are used for the 2D pass
  default_proj := rlgl.GetMatrixProjection()
  default_view := rlgl.GetMatrixModelview()

  rl.SetTargetFPS(60)

  for !rl.WindowShouldClose() {
    spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "frame")

    process_input(&camera, &player_unit, &camera_mode)

    handle_collision(&player_unit, &camera, &camera_mode, player_neighbouring_blocks[:], blocks[:])

    view := view_matrix(camera)

    rl.BeginDrawing()
    rl.ClearBackground(rl.RAYWHITE)

    /***** 3D pass *****/
    rlgl.EnableDepthTest()

    // set MVP matrix
    rlgl.SetMatrixProjection(projection)
    rlgl.SetMatrixModelview(view)

    // clear player_neighbouring_blocks dynamic array
    clear(&player_neighbouring_blocks)

    player_cell := get_cell_of_block(player_unit.position)

    {
      spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "draw_blocks")
      for b, i in blocks {
        draw_cube(pos = b.position, size = TILE_SIZE, color = COLORS[i % len(COLORS)])
      }
    }

    {
      spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "neighbour_check")
      for b, i in blocks {
        if is_neighbouring_player(b.position, player_cell) {
          append(&player_neighbouring_blocks, i)
        }
      }
    }

    // Draw gizmo
    draw_gizmo()

    // Draw grid
    rl.DrawGrid(GRID_SIZE, TILE_SIZE)

    // TODO: need to find a way now with the custom camera
    // draw_sphere_on_ray_hit(camera, wall_box)

    rlgl.DrawRenderBatchActive() // flush 3D geometry with 3D matrices
    rlgl.DisableDepthTest()

    /***** 2D pass *******/

    // Restore 2D matrices for drawing 2D
    rlgl.SetMatrixProjection(default_proj)
    rlgl.SetMatrixModelview(default_view)

    rl.DrawFPS(10, 10)

    // draw camera angles
    // NOTE: uses a buffer so we prevent flickering
    buf: [256]byte
    s := fmt.bprintf(
      buf[:],
      "Camera angles:\n\nyaw = %.1fdeg\n\npitch = %.1fdeg",
      math.to_degrees_f32(camera.yaw),
      math.to_degrees_f32(camera.pitch),
    )
    camera_angles_text := strings.clone_to_cstring(s, context.temp_allocator)
    draw_ui_text(text = camera_angles_text, margin = 60, position = .Top_Right)

    // Draw position text
    player_pos_text := rl.TextFormat(
      "player pos:\n\nX = %f\n\nY = %f\n\nZ = %f",
      player_unit.position.x,
      player_unit.position.y,
      player_unit.position.z,
    )
    draw_ui_text(text = player_pos_text, margin = 30, position = .Top_Left)

    // draw neighbouring blocks quantity
    neighbouring_blocks_quantity := rl.TextFormat(
      "Neighbouring blocks: %d",
      len(player_neighbouring_blocks),
    )
    draw_ui_text(text = neighbouring_blocks_quantity, margin = 30, position = .Bottom_Left)

    rl.EndDrawing()

    free_all(context.temp_allocator)
  }
}

