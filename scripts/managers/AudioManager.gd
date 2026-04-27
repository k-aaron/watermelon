extends Node

enum SoundType {
	DROP,
	MERGE,
	BOUNCE,
	GAME_OVER,
	BUTTON
}

var master_volume: float = 1.0
var bgm_volume: float = 0.5
var sfx_volume: float = 0.8

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sfx_streams: Dictionary = {}

const SAMPLE_RATE = 44100

func _ready():
	_bgm_player = AudioStreamPlayer.new()
	_sfx_player = AudioStreamPlayer.new()
	add_child(_bgm_player)
	add_child(_sfx_player)

	_sfx_streams[SoundType.DROP] = _make_drop_sound()
	_sfx_streams[SoundType.MERGE] = _make_merge_sound()
	_sfx_streams[SoundType.BOUNCE] = _make_bounce_sound()
	_sfx_streams[SoundType.GAME_OVER] = _make_game_over_sound()
	_sfx_streams[SoundType.BUTTON] = _make_button_sound()

	_bgm_player.stream = _make_bgm()
	_bgm_player.volume_db = linear_to_db(master_volume * bgm_volume)
	_bgm_player.finished.connect(_on_bgm_finished)
	_bgm_player.play()

func play_sfx(sound_type: SoundType):
	if not _sfx_streams.has(sound_type):
		return
	_sfx_player.stream = _sfx_streams[sound_type]
	_sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)
	_sfx_player.play()

func _on_bgm_finished():
	_bgm_player.play()

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(master_volume * bgm_volume)

func set_bgm_volume(volume: float):
	bgm_volume = clamp(volume, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(master_volume * bgm_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

# ── 파형 합성 헬퍼 ─────────────────────────────────────────────

func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE

	var data = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v = int(clamp(samples[i], -1.0, 1.0) * 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	stream.data = data
	return stream

func _sine(freq: float, t: float) -> float:
	return sin(TAU * freq * t)

func _envelope(t: float, duration: float, attack: float = 0.01, release: float = 0.08) -> float:
	if t < attack:
		return t / attack
	elif t > duration - release:
		return (duration - t) / release
	return 1.0

# ── 효과음 합성 ───────────────────────────────────────────────

func _make_drop_sound() -> AudioStreamWAV:
	var dur := 0.12
	var n := int(SAMPLE_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		# 주파수가 내려가는 짧은 타격음
		var freq := lerp(220.0, 100.0, t / dur)
		s[i] = _sine(freq, t) * _envelope(t, dur, 0.002, 0.06) * 0.6
	return _make_wav(s)

func _make_merge_sound() -> AudioStreamWAV:
	var dur := 0.25
	var n := int(SAMPLE_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		# 주파수가 올라가는 상승음 (화음)
		var freq := lerp(300.0, 600.0, t / dur)
		var env := _envelope(t, dur, 0.005, 0.12)
		s[i] = (_sine(freq, t) * 0.5 + _sine(freq * 1.5, t) * 0.3) * env
	return _make_wav(s)

func _make_bounce_sound() -> AudioStreamWAV:
	var dur := 0.06
	var n := int(SAMPLE_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		s[i] = _sine(400.0, t) * _envelope(t, dur, 0.001, 0.04) * 0.3
	return _make_wav(s)

func _make_game_over_sound() -> AudioStreamWAV:
	var dur := 0.8
	var n := int(SAMPLE_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		# 내려가는 3음 시퀀스
		var progress := t / dur
		var freq: float
		if progress < 0.33:
			freq = 523.0  # C5
		elif progress < 0.66:
			freq = 392.0  # G4
		else:
			freq = 262.0  # C4
		s[i] = _sine(freq, t) * _envelope(t, dur, 0.01, 0.15) * 0.7
	return _make_wav(s)

func _make_button_sound() -> AudioStreamWAV:
	var dur := 0.08
	var n := int(SAMPLE_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		s[i] = _sine(500.0, t) * _envelope(t, dur, 0.002, 0.04) * 0.4
	return _make_wav(s)

# ── BGM: 간단한 멜로디 루프 ────────────────────────────────────

func _make_bgm() -> AudioStreamWAV:
	# C장조 8마디 반복 루프 (BPM 110)
	var bpm := 110.0
	var beat := 60.0 / bpm
	var notes := [
		[262, 1], [294, 1], [330, 1], [349, 1],  # C D E F
		[392, 2], [330, 1], [294, 1],              # G G E D
		[262, 2], [0, 1], [330, 1],               # C . E
		[392, 1], [349, 1], [330, 2],              # G F E
		[294, 1], [330, 1], [349, 1], [330, 1],   # D E F E
		[294, 2], [262, 2],                        # D C
		[330, 1], [349, 1], [392, 2],              # E F G
		[262, 4],                                  # C (long)
	]

	var total_beats: float = 0.0
	for note in notes:
		total_beats += note[1]
	var dur := total_beats * beat

	var n := int(SAMPLE_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)

	var cursor := 0.0
	for note in notes:
		var freq: float = note[0]
		var note_beats: float = note[1]
		var note_dur := note_beats * beat
		var note_start := int(cursor * SAMPLE_RATE)
		var note_n := int(note_dur * SAMPLE_RATE)

		if freq > 0:
			for j in range(note_n):
				var idx := note_start + j
				if idx >= n:
					break
				var t := float(j) / SAMPLE_RATE
				var env := _envelope(t, note_dur, 0.01, note_dur * 0.3)
				s[idx] += _sine(freq, t) * env * 0.25
				s[idx] += _sine(freq * 2.0, t) * env * 0.08  # 2배음
		cursor += note_dur

	return _make_wav(s)
