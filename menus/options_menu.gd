extends Control
## The options overlay: a volume slider for each bus in `Settings.BUSES`,
## fullscreen and vsync toggles, and Back. It reads and writes the `Settings`
## autoload, so the same scene works on the title screen and in the pause menu.
## Built in code, so there are no node paths to break.

## Emitted when the overlay closes (Back or Esc), after the settings are saved.
signal closed

var _sliders := {}
var _fullscreen: CheckButton
var _vsync: CheckButton
var _back: Button


func _ready() -> void:
	# Keep working while the game is paused, for when the pause menu opens it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(300, 0)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "OPTIONS"
	title.theme_type_variation = &"HeadingLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for bus in Settings.BUSES:
		vbox.add_child(_volume_row(bus))

	_fullscreen = _toggle("Fullscreen", Settings.set_fullscreen)
	vbox.add_child(_fullscreen)
	_vsync = _toggle("VSync", Settings.set_vsync)
	vbox.add_child(_vsync)

	_back = Button.new()
	_back.text = "Back"
	_back.pressed.connect(close)
	vbox.add_child(_back)


func _volume_row(bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = bus
	label.custom_minimum_size = Vector2(90, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value = Settings.get_volume(bus)
	slider.value_changed.connect(func(v: float) -> void: Settings.set_volume(bus, v))
	row.add_child(slider)

	_sliders[bus] = slider
	return row


func _toggle(text: String, setter: Callable) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.toggled.connect(func(on: bool) -> void: setter.call(on))
	return toggle


## Show the overlay with the controls synced to the current settings.
func open() -> void:
	for bus in _sliders:
		_sliders[bus].set_value_no_signal(Settings.get_volume(bus))
	_fullscreen.set_pressed_no_signal(Settings.is_fullscreen())
	_vsync.set_pressed_no_signal(Settings.is_vsync())
	visible = true
	# Focus the first control so the menu works with arrow keys or a gamepad.
	if not _sliders.is_empty():
		_sliders[Settings.BUSES[0]].grab_focus()
	else:
		_back.grab_focus()


## Hide the overlay and save the settings.
func close() -> void:
	if not visible:
		return
	visible = false
	Settings.save_settings()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
