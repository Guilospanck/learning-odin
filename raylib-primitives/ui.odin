package raylib_primitives

import rl "vendor:raylib"

FONT_SIZE: i32 : 30

Anchor :: enum {
  Top_Left,
  Top_Right,
  Bottom_Left,
  Bottom_Right,
  Center,
}

draw_ui_text :: proc(
  text: cstring,
  position: Anchor = Anchor.Top_Left,
  font_size: i32 = FONT_SIZE,
  margin: i32 = 0,
  color: rl.Color = rl.DARKGRAY,
) {
  text_width := rl.MeasureText(text, font_size)

  screen_width := rl.GetScreenWidth()
  screen_height := rl.GetScreenHeight()

  x, y: i32
  switch position {
  case .Top_Left:
    x = margin; y = margin
  case .Top_Right:
    x = screen_width - text_width - margin; y = margin
  case .Bottom_Left:
    x = margin; y = screen_height - font_size - margin
  case .Bottom_Right:
    x = screen_width - text_width - margin; y = screen_height - font_size - margin
  case .Center:
    x = screen_width / 2 - text_width; y = screen_height / 2 - font_size
  }
  rl.DrawText(text, x, y, font_size, color)
}

