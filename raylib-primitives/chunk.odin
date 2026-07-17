package raylib_primitives

import "core:prof/spall"
import rl "vendor:raylib"

NUMBER_OF_BLOCKS :: 10_000
BLOCK_SIZE :: 1.0
BLOCK_COLORS: []rl.Color = {rl.DARKPURPLE, rl.PURPLE, rl.DARKBLUE, rl.BLUE}

MAX_RAND_NUMBER_ATTEMPTS :: 3

Block_Kind :: enum {
  Air,
  Sand,
  Stone,
  Water,
}

Chunk :: struct {
  positions: [NUMBER_OF_BLOCKS]rl.Vector3,
  colors:    [NUMBER_OF_BLOCKS]rl.Color,
}

generate_chunk_and_fill_in_neighbouring_blocks :: proc(
  chunk: ^Chunk,
  block_transforms: []rl.Matrix,
  player_neighbouring_blocks: ^[dynamic]int,
  player_cell: rl.Vector3,
) {
  spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, "generate_chunk")
  placed_block_pos: map[rl.Vector3]bool = {}


  outer: for i in 0 ..< NUMBER_OF_BLOCKS {
    pos: rl.Vector3

    // prevent placing blocks at the same places (limit to MAX_RAND_NUMBER_ATTEMPTS)
    block_random_pos_attempts := 0
    for {
      block_random_pos_attempts += 1

      pos = get_random_position()
      if placed_block_pos[pos] {
        if block_random_pos_attempts > MAX_RAND_NUMBER_ATTEMPTS do continue outer
        continue
      }

      color := BLOCK_COLORS[i % len(BLOCK_COLORS)]

      chunk.positions[i] = pos
      chunk.colors[i] = color

      block_transforms[i] = rl.MatrixTranslate(pos.x, pos.y, pos.z)

      placed_block_pos[pos] = true

      break
    }

    // Fill in the neighbouring player dynamic array
    if (is_neighbouring_player(pos, player_cell)) {
      append(player_neighbouring_blocks, i)
    }
  }
}

