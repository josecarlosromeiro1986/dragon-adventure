extends Node

## Gerenciador de áudio em 3 canais (BGM com crossfade, SFX sintético/ElevenLabs e dublagens).
const WORLD_BGM_DB := {
	"vila": -13.0,
	"floresta": -13.5,
	"caverna": -12.5,
	"castelo": -11.5,
	"cabana": -13.0
}
const BGM_CROSSFADE_SEC := 1.1
const VOICE_DUCK_OFFSET_DB := -5.0
const SFX_BASE_DB := -3.0
const SFX_DB_OFFSET := {
	"boss_roar": -8.5
}

var _audio_players = []
var _voice_player: AudioStreamPlayer
var _spell_voice_player: AudioStreamPlayer
var _bgm_players: Array[AudioStreamPlayer] = []
var _active_bgm_idx: int = 0
var _bgm_tween: Tween = null
var _duck_tween: Tween = null
var _voice_duck_db: float = 0.0
var _stream_cache = {}
var bgm_enabled: bool = true
var sfx_enabled: bool = true
var voice_enabled: bool = true
var music_volume: float = 0.85
var sfx_volume: float = 0.90
var voice_volume: float = 1.00
var current_bgm_world: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(8):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_audio_players.append(p)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.finished.connect(func():
		_set_voice_duck(false)
	)
	add_child(_voice_player)

	_spell_voice_player = AudioStreamPlayer.new()
	add_child(_spell_voice_player)

	for idx in range(2):
		var bp = AudioStreamPlayer.new()
		bp.volume_db = -40.0
		bp.finished.connect(func():
			if idx == _active_bgm_idx and bgm_enabled and current_bgm_world != "" and bp.stream:
				bp.play()
		)
		add_child(bp)
		_bgm_players.append(bp)

	_apply_channel_volumes()

func _vol_to_db(vol: float, base_db: float) -> float:
	if vol <= 0.005:
		return -80.0
	return base_db + linear_to_db(clamp(vol, 0.005, 1.5))

func _apply_channel_volumes():
	for p in _audio_players:
		if is_instance_valid(p):
			var offset_db := float(p.get_meta("sfx_offset_db", 0.0))
			p.volume_db = _vol_to_db(sfx_volume, SFX_BASE_DB + offset_db) if sfx_enabled else -80.0
	var v_db := _vol_to_db(voice_volume, 2.0) if voice_enabled else -80.0
	if is_instance_valid(_voice_player):
		_voice_player.volume_db = v_db
	if is_instance_valid(_spell_voice_player):
		_spell_voice_player.volume_db = v_db
	var active_bp := _get_active_bgm_player()
	if active_bp and active_bp.playing and bgm_enabled:
		active_bp.volume_db = _get_target_bgm_db()

func apply_settings(cfg: Dictionary):
	bgm_enabled = bool(cfg.get("bgm_enabled", bgm_enabled))
	sfx_enabled = bool(cfg.get("sfx_enabled", sfx_enabled))
	voice_enabled = bool(cfg.get("voice_enabled", voice_enabled))
	music_volume = clampf(float(cfg.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	voice_volume = clampf(float(cfg.get("voice_volume", voice_volume)), 0.0, 1.0)
	_apply_channel_volumes()
	if not bgm_enabled:
		if _bgm_tween and _bgm_tween.is_valid():
			_bgm_tween.kill()
		for bp in _bgm_players:
			if is_instance_valid(bp):
				bp.stop()
	elif current_bgm_world != "":
		var active_bp := _get_active_bgm_player()
		if not active_bp or not active_bp.playing:
			var target = current_bgm_world
			current_bgm_world = ""
			play_bgm(target)
	if not voice_enabled:
		stop_voice()

func get_settings() -> Dictionary:
	return {
		"bgm_enabled": bgm_enabled,
		"sfx_enabled": sfx_enabled,
		"voice_enabled": voice_enabled,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume
	}

func _get_active_bgm_player() -> AudioStreamPlayer:
	if _bgm_players.is_empty():
		return null
	return _bgm_players[_active_bgm_idx]

func _get_target_bgm_db(world_id: String = "") -> float:
	if not bgm_enabled:
		return -80.0
	var w_id := world_id if world_id != "" else current_bgm_world
	return _vol_to_db(music_volume, float(WORLD_BGM_DB.get(w_id, -13.0)) + _voice_duck_db)

func _set_voice_duck(ducked: bool):
	var target_offset := VOICE_DUCK_OFFSET_DB if ducked else 0.0
	if is_equal_approx(_voice_duck_db, target_offset):
		return
	_voice_duck_db = target_offset
	var active_bp := _get_active_bgm_player()
	if not active_bp or not active_bp.playing:
		return
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_duck_tween.tween_property(active_bp, "volume_db", _get_target_bgm_db(), 0.25 if ducked else 0.45)

func _input(event):
	# Desbloqueia autoplay da trilha sonora no primeiro clique/tecla no Chrome
	var active_bp := _get_active_bgm_player()
	if bgm_enabled and current_bgm_world != "" and active_bp and active_bp.stream and not active_bp.playing:
		if event is InputEventKey or event is InputEventMouseButton:
			if event.pressed:
				active_bp.volume_db = _get_target_bgm_db()
				active_bp.play()

func play_bgm(world_id: String):
	var active_bp := _get_active_bgm_player()
	if world_id == current_bgm_world and active_bp and active_bp.playing:
		return
	current_bgm_world = world_id
	if not bgm_enabled:
		return

	var path = "res://assets/audio/bgm/bgm_" + world_id + ".mp3"
	var stream = null
	if _stream_cache.has(path):
		stream = _stream_cache[path]
	elif ResourceLoader.exists(path):
		stream = load(path)
		if stream:
			if stream is AudioStreamMP3:
				stream.loop = true
			_stream_cache[path] = stream

	if stream:
		var old_bp := _get_active_bgm_player()
		var next_idx := 1 - _active_bgm_idx if old_bp and old_bp.playing else _active_bgm_idx
		_active_bgm_idx = next_idx
		var new_bp := _bgm_players[next_idx]
		var target_db := _get_target_bgm_db(world_id)

		if _bgm_tween and _bgm_tween.is_valid():
			_bgm_tween.kill()
		if _duck_tween and _duck_tween.is_valid():
			_duck_tween.kill()

		new_bp.stop()
		new_bp.stream = stream

		if old_bp and old_bp != new_bp and old_bp.playing:
			new_bp.volume_db = -36.0
			new_bp.play()
			_bgm_tween = create_tween()
			_bgm_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_bgm_tween.set_parallel(true)
			_bgm_tween.tween_property(new_bp, "volume_db", target_db, BGM_CROSSFADE_SEC)
			_bgm_tween.tween_property(old_bp, "volume_db", -42.0, BGM_CROSSFADE_SEC)
			_bgm_tween.chain().tween_callback(func():
				if is_instance_valid(old_bp) and _bgm_players[_active_bgm_idx] != old_bp:
					old_bp.stop()
			)
		else:
			new_bp.volume_db = target_db
			new_bp.play()

func toggle_bgm() -> bool:
	bgm_enabled = not bgm_enabled
	if not bgm_enabled:
		if _bgm_tween and _bgm_tween.is_valid():
			_bgm_tween.kill()
		for bp in _bgm_players:
			bp.stop()
	else:
		var target = current_bgm_world
		current_bgm_world = ""
		if target != "":
			play_bgm(target)
	return bgm_enabled

func play_sfx(sfx_name: String, db_offset: float = 0.0, fade_in_sec: float = 0.0):
	if not sfx_enabled or sfx_volume <= 0.005:
		return
	var total_offset_db := float(SFX_DB_OFFSET.get(sfx_name, 0.0)) + db_offset
	var path = "res://assets/audio/sfx/" + sfx_name + ".mp3"
	if _stream_cache.has(path):
		_play_stream(_stream_cache[path], total_offset_db, fade_in_sec)
		return
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			_stream_cache[path] = stream
			_play_stream(stream, total_offset_db, fade_in_sec)
			return
	# Fallback sintético procedural para WebGL
	_play_procedural_beep(sfx_name)

func _load_voice_stream(voice_name: String) -> AudioStream:
	var path = "res://assets/audio/voices/" + voice_name + ".mp3"
	if _stream_cache.has(path):
		return _stream_cache[path]
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			_stream_cache[path] = stream
			return stream
	return null

func play_voice(voice_name: String, pitch: float = 1.0):
	if not voice_enabled or voice_volume <= 0.005:
		return
	var stream := _load_voice_stream(voice_name)
	if stream and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.volume_db = _vol_to_db(voice_volume, 2.0)
		_voice_player.pitch_scale = pitch if pitch > 0.0 else 1.0
		_voice_player.stream = stream
		_set_voice_duck(true)
		_voice_player.play()

func play_spell_voice(voice_name: String):
	if not voice_enabled or voice_volume <= 0.005:
		return
	var stream := _load_voice_stream(voice_name)
	if stream and is_instance_valid(_spell_voice_player):
		_spell_voice_player.stop()
		_spell_voice_player.volume_db = _vol_to_db(voice_volume, 2.0)
		_spell_voice_player.pitch_scale = 1.0
		_spell_voice_player.stream = stream
		_spell_voice_player.play()

func stop_voice():
	if is_instance_valid(_voice_player) and _voice_player.playing:
		_voice_player.stop()
	if is_instance_valid(_spell_voice_player) and _spell_voice_player.playing:
		_spell_voice_player.stop()
	_set_voice_duck(false)

func _play_stream(stream: AudioStream, db_offset: float = 0.0, fade_in_sec: float = 0.0):
	var target_db := _vol_to_db(sfx_volume, SFX_BASE_DB + db_offset) if sfx_enabled else -80.0
	for p in _audio_players:
		if not p.playing:
			p.set_meta("sfx_offset_db", db_offset)
			p.stream = stream
			if fade_in_sec > 0.0 and sfx_enabled:
				p.volume_db = maxf(target_db - 22.0, -45.0)
				p.play()
				var tw = create_tween()
				tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(p, "volume_db", target_db, fade_in_sec)
			else:
				p.volume_db = target_db
				p.play()
			return

func _play_procedural_beep(type: String):
	# Cria um som de feedback leve em tempo real
	var sample_rate = 22050
	var duration = 0.1
	var freq = 440.0
	match type:
		"sword_slash":
			freq = 600.0
			duration = 0.08
		"hammer_smash":
			freq = 180.0
			duration = 0.2
		"cash_pickup":
			freq = 980.0
			duration = 0.12
		"magic_fireball":
			freq = 520.0
			duration = 0.15
		"magic_tornado":
			freq = 380.0
			duration = 0.2
		"water_bomb":
			freq = 280.0
			duration = 0.18
		"eat_food":
			freq = 740.0
			duration = 0.1

	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var wave = sin(2.0 * PI * freq * t)
		var val = int(wave * 127.0 * (1.0 - float(i)/num_samples))
		data.append(val + 128)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	_play_stream(stream)
