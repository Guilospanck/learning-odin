package raylib_primitives

import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

TILE_SIZE :: 1.0

Unit :: struct {
  position:     rl.Vector3,
  rotation:     rl.Vector3,
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

// process_input :: proc(time_delta: f32, camera: ^rl.Camera3D) {
//   if rl.IsKeyDown(.UP) {
//     camera.x += camera.speed * math.cos(camera.angle) * time_delta
//     camera.y += camera.speed * math.sin(camera.angle) * time_delta
//   }
//   if rl.IsKeyDown(.DOWN) {
//     camera.x -= camera.speed * math.cos(camera.angle) * time_delta
//     camera.y -= camera.speed * math.sin(camera.angle) * time_delta
//   }
//   if rl.IsKeyDown(.LEFT) {
//     camera.angle -= camera.rotspeed * time_delta
//   }
//   if rl.IsKeyDown(.RIGHT) {
//     camera.angle += camera.rotspeed * time_delta
//   }
//   if rl.IsKeyDown(.Q) {
//     camera.height += camera.heightspeed * time_delta
//   }
//   if rl.IsKeyDown(.E) {
//     camera.height -= camera.heightspeed * time_delta
//   }
//   if rl.IsKeyDown(.W) {
//     camera.horizon += camera.horizonspeed * time_delta
//   }
//   if rl.IsKeyDown(.S) {
//     camera.horizon -= camera.horizonspeed * time_delta
//   }
//   if rl.IsKeyDown(.A) {
//     camera.tilt -= camera.tiltspeed * time_delta
//     camera.tilt = camera.tilt < -1 ? -1 : camera.tilt
//   }
//   if rl.IsKeyDown(.D) {
//     camera.tilt += camera.tiltspeed * time_delta
//     camera.tilt = camera.tilt > 1 ? 1 : camera.tilt
//   }
//   if rl.IsKeyDown(.R) {
//     camera.angle = 1.5 * math.PI
//     camera.tilt = 0
//     camera.height = 150
//     camera.horizon = 100
//   }
// }

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
  WIDTH :: 1400
  HEIGHT :: 850

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

  collision := false

  rl.SetTargetFPS(60)

  camera := new_camera()
  view := view_matrix(camera)
  projection := projection_matrix()

  fmt.println(view)
  fmt.println(projection)

  for !rl.WindowShouldClose() {
    // Move player
    if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) do player_unit.position.x += player_unit.speed
    if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) do player_unit.position.x -= player_unit.speed
    if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) do player_unit.position.z += player_unit.speed
    if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) do player_unit.position.z -= player_unit.speed

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

    rl.BeginDrawing()
    rl.ClearBackground(rl.RAYWHITE)

    // camera := my_camera()
    // rl.BeginMode3D(camera)


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

    rl.DrawGrid(10, TILE_SIZE)

    // draw_sphere_on_ray_hit(camera, wall_box)

    // rl.EndMode3D()

    rl.DrawFPS(10, 10)

    // Draw position text
    player_pos_text := rl.TextFormat(
      "player pos:\n\nX = %f\n\nY = %f\n\nZ = %f",
      player_unit.position.x,
      player_unit.position.y,
      player_unit.position.z,
    )
    rl.DrawText(player_pos_text, 30, 30, 30, rl.DARKGRAY)
    rl.EndDrawing()
  }
}

