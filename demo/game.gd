extends Node2D
## Demo only: a stand-in for your game. A character paces back and forth and a
## clock counts up, so you can see both freeze when you pause and start over when
## you restart.

const FRAMES: Array[Texture2D] = [
	preload("res://assets/kenney_pixel-platformer/Tiles/Characters/tile_0000.png"),
	preload("res://assets/kenney_pixel-platformer/Tiles/Characters/tile_0001.png"),
]
const SPEED := 70.0

@onready var walker: Sprite2D = $Walker
@onready var clock: Label = $HUD/Clock

var elapsed := 0.0
var _dir := 1.0


func _process(delta: float) -> void:
	elapsed += delta
	clock.text = "Time %.1f" % elapsed
	walker.position.x += _dir * SPEED * delta
	if walker.position.x > 560.0:
		_dir = -1.0
	elif walker.position.x < 80.0:
		_dir = 1.0
	walker.flip_h = _dir > 0.0   # the sprite faces left
	walker.texture = FRAMES[int(elapsed * 8.0) % 2]
