package raylib_primitives

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

TILE_SIZE :: 1.0
WIDTH :: 1920
HEIGHT :: 1080

Unit :: struct {
  position:     rl.Vector3,
  yaw, pitch:   f32,
  size:         rl.Vector3,
  velocity:     rl.Vector3,
  speed:        f32,
  max_speed:    f32,
  health:       int,
  max_health:   int,
  damage:       int,
  is_active:    bool,
  cooldown:     int,
  can_attack:   bool,
  attack_timer: int,
  colour:       rl.Color,
}

Wall :: struct {
  position:  rl.Vector3,
  size:      rl.Vector3,
  health:    int,
  is_active: bool,
  colour:    rl.Color,
}

// Basically just cancels unit movement
resolve_collision :: proc(unit: ^Unit, obstacle: rl.Vector3) {
  // Collision resolution logic
  if unit.position.z < obstacle.z - 1 {   // player above
    unit.position.z -= unit.speed
  }
  if unit.position.z > obstacle.z + 1 {   // player below
    unit.position.z += unit.speed
  }
  if unit.position.x < obstacle.x - 1 {   // player on left
    unit.position.x -= unit.speed
  }
  if unit.position.x > obstacle.x + 1 {   // player on right
    unit.position.x += unit.speed
  }
}

get_camera_position_based_on_players :: proc(
  camera_mode: ^CameraMode,
  player_unit: ^Unit,
) -> rl.Vector3 {

  if camera_mode^ == CameraMode.Third_Person {
    forward_vector := calculate_forward_vector(player_unit.pitch, player_unit.yaw)

    return(
      player_unit.position +
      forward_vector * CAMERA_DISTANCE_TO_PLAYER_3RD_PERSON_VIEW +
      {0, CAMERA_DISTANCE_TO_PLAYER_3RD_PERSON_VIEW, 0} \
    )
  }

  return player_unit.position
}

process_input :: proc(camera: ^Camera, player_unit: ^Unit, camera_mode: ^CameraMode) {

  dt := rl.GetFrameTime()

  // Rotate camera with mouse
  pitch, yaw := rotate()

  // Rotate camera with keyboard
  if rl.IsKeyDown(.UP) do pitch -= SENSITIVITY_RAD_S * dt
  if rl.IsKeyDown(.DOWN) do pitch += SENSITIVITY_RAD_S * dt
  if rl.IsKeyDown(.LEFT) do yaw += SENSITIVITY_RAD_S * dt
  if rl.IsKeyDown(.RIGHT) do yaw -= SENSITIVITY_RAD_S * dt

  // do not allow pitch on 3rd person view
  if camera_mode^ != CameraMode.Third_Person {
    camera.pitch += pitch
    player_unit.pitch += pitch
  }

  camera.yaw += yaw
  player_unit.yaw += yaw

  // change camera mode
  if rl.IsKeyPressed(.Q) {
    if camera_mode^ == CameraMode.First_Person {
      camera_mode^ = CameraMode.Third_Person
      camera.yaw = 0.0
      camera.pitch = math.PI / 4 // 45 deg
    } else {
      camera_mode^ = CameraMode.First_Person
      camera.yaw = player_unit.yaw
      camera.pitch = player_unit.pitch
    }
  }


  walk_vector := calculate_walk_vector(camera.yaw)
  right_vector := calculate_right_vector(camera.yaw)

  move_vector: rl.Vector3

  // Move player and camera (W/S flipped because Z convention)
  if rl.IsKeyDown(.W) do move_vector -= walk_vector
  if rl.IsKeyDown(.S) do move_vector += walk_vector
  if rl.IsKeyDown(.D) do move_vector += right_vector
  if rl.IsKeyDown(.A) do move_vector -= right_vector

  step := move(move_vector, SPEED)
  player_unit.position += step

  camera.position = get_camera_position_based_on_players(camera_mode, player_unit)
}

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

draw_sphere_on_ray_hit :: proc(camera: rl.Camera3D, box_collision: rl.BoundingBox) {
  ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
  ray_collision := rl.GetRayCollisionBox(ray, box_collision)
  if ray_collision.hit {
    rl.DrawSphere(ray_collision.point, 0.3, rl.RED)
  }
}

main :: proc() {

  rl.InitWindow(WIDTH, HEIGHT, "quadtree based collision detection")
  defer rl.CloseWindow()


  player_unit := Unit {
    position   = {-4.0, 1.0, -4.0},
    size       = {1.0, 2.0, 1.0},
    speed      = 0.1,
    max_speed  = 0.5,
    health     = 40,
    max_health = 40,
    damage     = 6,
    colour     = rl.RED,
  }

  wall := Wall {
    position = {0.0, 1.0, 0.0},
    size     = rl.Vector3(2.0),
    health   = 20,
    colour   = rl.GRAY,
  }

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

  collision := false

  rl.SetTargetFPS(60)


  for !rl.WindowShouldClose() {
    collision = false

    // Check collisions player vs wall
    player_box := rl.BoundingBox {
      min = {
        player_unit.position.x - player_unit.size.x / 2,
        player_unit.position.y - player_unit.size.y / 2,
        player_unit.position.z - player_unit.size.z / 2,
      },
      max = {
        player_unit.position.x + player_unit.size.x / 2,
        player_unit.position.y + player_unit.size.y / 2,
        player_unit.position.z + player_unit.size.z / 2,
      },
    }

    wall_box := rl.BoundingBox {
      min = {
        wall.position.x - wall.size.x / 2,
        wall.position.y - wall.size.y / 2,
        wall.position.z - wall.size.z / 2,
      },
      max = {
        wall.position.x + wall.size.x / 2,
        wall.position.y + wall.size.y / 2,
        wall.position.z + wall.size.z / 2,
      },
    }

    collision = rl.CheckCollisionBoxes(player_box, wall_box)

    if collision {
      player_unit.colour = rl.RED
      resolve_collision(&player_unit, wall.position)
    } else {
      player_unit.colour = rl.GREEN
    }

    process_input(&camera, &player_unit, &camera_mode)

    view := view_matrix(camera)

    rl.BeginDrawing()
    rl.ClearBackground(rl.RAYWHITE)

    /***** 3D pass *****/

    // set MVP matrix
    rlgl.SetMatrixProjection(projection)
    rlgl.SetMatrixModelview(view)

    // Draw wall
    // rl.DrawCubeV(wall.position, wall.size, rl.GRAY)
    rl.DrawCubeWiresV(wall.position, wall.size, rl.BLACK)

    // Draw player
    rl.DrawCubeV(player_unit.position, player_unit.size, player_unit.colour)
    rl.DrawCubeWiresV(player_unit.position, player_unit.size, rl.BLACK)

    draw_gizmo()
    rl.DrawGrid(100, TILE_SIZE)
    // draw_sphere_on_ray_hit(camera, wall_box)

    rlgl.DrawRenderBatchActive() // flush 3D geometry with 3D matrices

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
    rl.EndDrawing()

    free_all(context.temp_allocator)
  }
}

