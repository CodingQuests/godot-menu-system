extends Node
## Demo only: gives the volume sliders something to control without shipping any
## audio files. It builds a short music loop and a click in code, plays the music
## on the Music bus, and clicks on the SFX bus when any button is pressed or a
## slider is let go. In your game, play your own music and sounds on those buses.

const RATE := 22050

var _music := AudioStreamPlayer.new()
var _click := AudioStreamPlayer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music.stream = _make_music()
	_music.bus = &"Music"
	add_child(_music)
	_music.play()
	_click.stream = _make_click()
	_click.bus = &"SFX"
	add_child(_click)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(_click.play):
		node.pressed.connect(_click.play)
	elif node is Slider:
		node.drag_ended.connect(func(_changed: bool) -> void: _click.play())


# A short square-wave blip.
func _make_click() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(RATE * 0.05)
	for i in count:
		var t := float(i) / RATE
		var square := 1.0 if fmod(t * 660.0, 1.0) < 0.5 else -1.0
		samples.append(square * 0.2 * (1.0 - float(i) / count))
	return _to_wav(samples, false)


# Four chords (A minor, F, C, G), each played as a soft eight-note arpeggio over
# a quiet bass note. About eight seconds, looped.
func _make_music() -> AudioStreamWAV:
	var chords := [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
	var pattern := [0, 1, 2, 1, 0, 1, 2, 1]
	var note_len := 0.25
	var note_samples := int(RATE * note_len)
	var samples := PackedFloat32Array()
	for chord in chords:
		var bass_freq := _midi_to_hz(chord[0] - 12)
		for step in pattern.size():
			var freq := _midi_to_hz(chord[pattern[step]] + 12)
			for i in note_samples:
				var t := float(i) / RATE
				var envelope := exp(-t * 6.0)
				var note := _triangle(t * freq) * envelope * 0.12
				var bass := sin(TAU * bass_freq * (t + step * note_len)) * 0.06
				samples.append(note + bass)
	return _to_wav(samples, true)


func _triangle(phase: float) -> float:
	return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0


func _midi_to_hz(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
