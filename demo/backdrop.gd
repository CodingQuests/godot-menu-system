@tool
extends Control
## Demo only: fills this control with a sky, a band of clouds and ground tiles
## along the bottom, drawn from the Kenney Pixel Platformer art at 2x. Swap it for
## your own background.

const TILES := preload("res://assets/kenney_pixel-platformer/Tilemap/tilemap_packed.png")
const SKY := preload("res://assets/kenney_pixel-platformer/Tilemap/tilemap-backgrounds_packed.png")
const PIXEL := 2.0
const SKY_COLOR := Color(0.875, 0.965, 0.961)
const HAZE_COLOR := Color(0.761, 0.89, 0.91)

## Height of the cloud band's top edge, as a share of this control's height.
@export_range(0.0, 1.0) var clouds_at := 0.3:
	set(value):
		clouds_at = value
		queue_redraw()
## Rows of ground tiles along the bottom.
@export_range(0, 4) var ground_rows := 2:
	set(value):
		ground_rows = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SKY_COLOR)
	# The background strip is four tiles wide: sky, then clouds, then haze.
	var strip := Vector2(96, 72) * PIXEL
	var y := size.y * clouds_at
	var x := 0.0
	while x < size.x:
		draw_texture_rect_region(SKY, Rect2(Vector2(x, y), strip), Rect2(0, 0, 96, 72))
		x += strip.x
	draw_rect(Rect2(0, y + strip.y, size.x, size.y), HAZE_COLOR)
	# Grass on top, dirt below: atlas row 0 and row 6, middle column.
	var tile := 18.0 * PIXEL
	for row in ground_rows:
		var gy := size.y - (ground_rows - row) * tile
		var src := Rect2(Vector2(2, 0 if row == 0 else 6) * 18.0, Vector2(18, 18))
		var gx := 0.0
		while gx < size.x:
			draw_texture_rect_region(TILES, Rect2(Vector2(gx, gy), Vector2(tile, tile)), src)
			gx += tile
