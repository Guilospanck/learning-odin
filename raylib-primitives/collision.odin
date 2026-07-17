package raylib_primitives

import "core:fmt"
import "core:math"
import "core:prof/spall"
import "core:strings"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

TILE_SIZE :: 1.0
GRID_SIZE :: 100

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
  blocks_positions: []rl.Vector3,
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
    block_pos := blocks_positions[b]

    block_box := rl.BoundingBox {
      min = {
        block_pos.x - TILE_SIZE / 2,
        block_pos.y - TILE_SIZE / 2,
        block_pos.z - TILE_SIZE / 2,
      },
      max = {
        block_pos.x + TILE_SIZE / 2,
        block_pos.y + TILE_SIZE / 2,
        block_pos.z + TILE_SIZE / 2,
      },
    }

    collision = rl.CheckCollisionBoxes(player_box, block_box)
    if collision {
      collided_block_pos = block_pos
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

main :: proc() {
  spall_ctx = spall.context_create("trace.spall")
  defer spall.context_destroy(&spall_ctx)

  buffer_backing := make([]u8, 1 << 20) // 1MB
  spall_buffer = spall.buffer_create(buffer_backing)
  defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "main")

  rl.InitWindow(WIDTH, HEIGHT, "quadtree based collision detection")
  defer rl.CloseWindow()


  player_unit := Unit {
    position = {-4.0, 1.0, -4.0},
    colour   = PLAYER_DEFAULT_COLOR,
  }
  player_cell := get_cell_of_block(player_unit.position)


  // Generate blocks
  player_neighbouring_blocks: [dynamic]int = {}
  defer delete(player_neighbouring_blocks)

  blocks: Chunk = {
    positions = {},
    colors    = {},
  }
  block_transforms: [NUMBER_OF_BLOCKS]rl.Matrix = {}
  generate_chunk(
    chunk = &blocks,
    block_transforms = block_transforms[:],
    player_neighbouring_blocks = &player_neighbouring_blocks,
    player_cell = player_cell,
  )

  // Set blocks mesh
  blocks_mesh := rl.GenMeshCube(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
  // Shaders
  // NOTE: uniform: for all vertices; attribute: for specific vertex/instance
  shader := rl.LoadShader("./shaders/block.vs", "./shaders/block.fs")
  shader.locs[rl.ShaderLocationIndex.MATRIX_MVP] = rl.GetShaderLocation(shader, "mvp")
  shader.locs[rl.ShaderLocationIndex.MATRIX_MODEL] = rl.GetShaderLocationAttrib(
    shader,
    "instanceTransform", // same name as in the .vs file. rl.DrawMeshInstanced() will pass it as 3rd argument
  )

  // add color per block
  instance_color := rl.GetShaderLocationAttrib(shader, "instanceColor")

  // VAO (Vertex Array Object) is the config that tells what the VBO (Vertex Buffer Object) data is about
  rlgl.EnableVertexArray(blocks_mesh.vaoId)
  vbo := rlgl.LoadVertexBuffer(
    buffer = &blocks.colors[0],
    size = len(blocks.colors) * size_of(rl.Color),
    is_dynamic = false,
  )
  rlgl.EnableVertexAttribute(u32(instance_color))
  rlgl.SetVertexAttribute(
    index = u32(instance_color),
    compSize = size_of(rl.Color),
    type = rlgl.UNSIGNED_BYTE,
    normalized = true, // true = GPU divides by 255 for us (GPU expects to receive 0..1, not 0..255)
    stride = 0,
    offset = 0,
  )
  // divisor = 0 -> different attribute for each vertice;
  // divisor = 1 -> different attribute for each instance
  // divisor = 2-> different attribute every 2 instances;
  // divisor = 3..x -> different attribute every x instances;
  rlgl.SetVertexAttributeDivisor(index = u32(instance_color), divisor = 1)
  rlgl.DisableVertexArray()

  // Materials
  block_material := rl.LoadMaterialDefault()
  block_material.shader = shader


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

    handle_collision(
      player_unit = &player_unit,
      camera = &camera,
      camera_mode = &camera_mode,
      player_neighbouring_blocks = player_neighbouring_blocks[:],
      blocks_positions = blocks.positions[:],
    )

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
      spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "draw_chunk")
      // raylib uplaods block_transforms to the locs[MATRIX_MODEL]
      rl.DrawMeshInstanced(
        blocks_mesh,
        block_material,
        &block_transforms[0],
        len(blocks.positions),
      )
    }

    {

      spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "neighbour_check")
      for b_pos, i in blocks.positions {
        if is_neighbouring_player(b_pos, player_cell) {
          append(&player_neighbouring_blocks, i)
        }
      }
    }

    // Draw player
    draw_cube(
      pos = player_unit.position,
      size = TILE_SIZE,
      color = player_unit.colour,
      draw_wires = false,
    )

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

