extends Node
## Player settings: a volume per audio bus, fullscreen and vsync. Loaded from
## disk at startup, applied to the game, and saved by the options menu.
## Registered as the `Settings` autoload, so any script can read or change them.

## Emitted after any setting changes.
signal changed

const PATH := "user://settings.cfg"

## The audio buses that get a volume setting (and a slider in the options menu).
## Add a bus in the Audio tab at the bottom of the editor, then list it here.
const BUSES: Array[String] = ["Master", "Music", "SFX"]

## Used for anything the settings file does not have yet, like on first launch.
const DEFAULT_VOLUME := {"Master": 1.0, "Music": 0.6, "SFX": 0.8}
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true

var _config := ConfigFile.new()


func _ready() -> void:
	load_settings()


## Reads the settings file and applies every setting. A missing file is fine:
## the defaults fill in, and the next save writes every setting out.
func load_settings() -> void:
	_config = ConfigFile.new()
	_config.load(PATH)
	for bus in BUSES:
		_config.set_value("audio", bus, get_volume(bus))
		_apply_volume(bus, get_volume(bus))
	_config.set_value("video", "fullscreen", is_fullscreen())
	_config.set_value("video", "vsync", is_vsync())
	_apply_fullscreen(is_fullscreen())
	_apply_vsync(is_vsync())


## Writes the current settings to disk. Returns OK or an error code.
func save_settings() -> Error:
	var err := _config.save(PATH)
	if err != OK:
		push_warning("Settings: could not save %s (error %d)" % [PATH, err])
	return err


## Volume of a bus, from 0.0 (silent) to 1.0 (full).
func get_volume(bus: String) -> float:
	return _config.get_value("audio", bus, DEFAULT_VOLUME.get(bus, 1.0))


func set_volume(bus: String, linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	_config.set_value("audio", bus, linear)
	_apply_volume(bus, linear)
	changed.emit()


func is_fullscreen() -> bool:
	return _config.get_value("video", "fullscreen", DEFAULT_FULLSCREEN)


func set_fullscreen(on: bool) -> void:
	_config.set_value("video", "fullscreen", on)
	_apply_fullscreen(on)
	changed.emit()


func is_vsync() -> bool:
	return _config.get_value("video", "vsync", DEFAULT_VSYNC)


func set_vsync(on: bool) -> void:
	_config.set_value("video", "vsync", on)
	_apply_vsync(on)
	changed.emit()


func _apply_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		push_warning("Settings: there is no audio bus named %s" % bus)
		return
	# Sliders are linear, but the mixer works in decibels.
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.0)


func _apply_fullscreen(on: bool) -> void:
	var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if on == is_full:
		return
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_vsync(on: bool) -> void:
	if on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
