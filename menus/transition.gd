extends CanvasLayer
## A full-screen fade for scene changes, so the game never hard-cuts. Registered
## as the `Transition` autoload. It draws above everything and keeps animating
## while the game is paused or slowed down, so the pause menu can use it too.

## Emitted when a transition has faded back in and the new scene is showing.
signal finished

## The color the screen fades to.
@export var color := Color(0.05, 0.06, 0.1)
## Seconds for each half of the fade (out, then in).
@export var duration := 0.35

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 128                              # above every other CanvasLayer
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep fading while paused
	_rect = ColorRect.new()
	_rect.color = Color(color, 1.0)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	# Fade in from the color when the game launches.
	_fade(0.0)


## True while a fade is running. Calls made during a fade are ignored.
func is_busy() -> bool:
	return _busy


## Fade out, switch to the scene at `path`, fade back in.
func change_scene(path: String) -> void:
	if _busy:
		return
	_begin()
	await _fade(1.0).finished
	# A scene change from the pause menu or a slow-motion moment should not carry
	# the pause or the time scale into the next scene.
	Engine.time_scale = 1.0
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Transition: could not open %s (error %d)" % [path, err])
	else:
		await get_tree().scene_changed
	await _fade(0.0).finished
	_end()
	finished.emit()


## Fade out, restart the current scene, fade back in.
func reload() -> void:
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != "":
		change_scene(scene.scene_file_path)


## Fade out, then close the game.
func quit() -> void:
	if _busy:
		return
	_begin()
	await _fade(1.0).finished
	get_tree().quit()


func _begin() -> void:
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # no clicks mid-fade


func _end() -> void:
	_busy = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade(alpha: float) -> Tween:
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(_rect, "color:a", alpha, duration).set_trans(Tween.TRANS_SINE)
	return tween
