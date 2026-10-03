extends CanvasLayer
## The in-game pause menu. Press the "pause" action (Esc, P or a gamepad's Start)
## to freeze the game and show Resume, Restart, Options and Quit to Title. Drop
## one into any scene that should be pausable.
##
## It runs with process_mode ALWAYS, so it keeps working while the tree is paused.
## Everything else in your scene uses the default (Inherit), so it freezes.

## The scene "Quit to Title" opens.
@export_file("*.tscn") var title_scene := "res://menus/main_menu.tscn"
## Pause on its own when the game window loses focus (alt-tab).
@export var pause_on_focus_loss := true
## The look of the menu. The scene sets it to menus/menu_theme.tres.
@export var menu_theme: Theme

@onready var options_menu = $OptionsMenu

var _root: Control
var _resume_button: Button
var _options_button: Button


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false
	options_menu.closed.connect(func() -> void: _options_button.grab_focus())


func _build() -> void:
	_root = Control.new()
	_root.theme = menu_theme
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	move_child(_root, 0)   # under the options overlay

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.theme_type_variation = &"HeadingLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_resume_button = _button("Resume", resume)
	vbox.add_child(_resume_button)
	vbox.add_child(_button("Restart", restart))
	_options_button = _button("Options", func() -> void: options_menu.open())
	vbox.add_child(_options_button)
	vbox.add_child(_button("Quit to Title", quit_to_title))


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 0)
	b.pressed.connect(action)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused():
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and pause_on_focus_loss:
		pause()


func is_paused() -> bool:
	return _root.visible


func pause() -> void:
	if _root == null or is_paused() or Transition.is_busy():
		return
	get_tree().paused = true
	_root.visible = true
	_resume_button.grab_focus()


func resume() -> void:
	options_menu.close()
	_root.visible = false
	get_tree().paused = false


func restart() -> void:
	_root.visible = false
	Transition.reload()   # unpauses once the screen is covered


func quit_to_title() -> void:
	_root.visible = false
	Transition.change_scene(title_scene)
