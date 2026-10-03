extends Control
## The title screen: your game's name, Play, Options and Quit. The buttons are
## built in code, so there are no node paths to break. Set the title and the
## scene Play opens in the Inspector, and put your art under the Background node.

## The game's name, shown at the top.
@export var title := "MY GAME"
## The scene the Play button opens.
@export_file("*.tscn") var play_scene := "res://demo/game.tscn"

@onready var options_menu = $OptionsMenu

var _first_button: Button
var _options_button: Button


func _ready() -> void:
	get_tree().paused = false   # in case we came back from a paused game
	_build()
	options_menu.closed.connect(func() -> void: _options_button.grab_focus())
	# Focus Play so Enter, arrow keys and a gamepad work right away.
	_first_button.grab_focus()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	var label := Label.new()
	label.text = title
	label.theme_type_variation = &"TitleLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_first_button = _button("Play", func() -> void: Transition.change_scene(play_scene))
	vbox.add_child(_first_button)
	_options_button = _button("Options", func() -> void: options_menu.open())
	vbox.add_child(_options_button)
	# A desktop game needs Quit; a web build does not.
	if not OS.has_feature("web"):
		vbox.add_child(_button("Quit", Transition.quit))

	# Keep the options overlay drawn on top of the buttons.
	move_child(options_menu, get_child_count() - 1)


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 0)
	b.pressed.connect(action)
	return b
