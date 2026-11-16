extends Node

## Carregador e cache central de texturas e animações direcionais do PixelLab.

# Cache para texturas base e frames de animação
static var _texture_cache = {}
static var _animation_frames = {}

static func get_character_texture(char_id: String, direction: String = "south") -> Texture2D:
	var cache_key = char_id + "_" + direction
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var local_path = "res://assets/" + char_id + "/" + direction + ".png"
	if ResourceLoader.exists(local_path):
		var tex = load(local_path)
		if tex:
			_texture_cache[cache_key] = tex
			return tex

	# Fallback procedural
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color = Color("#8B5A2B")
	if GameData.MONSTERS.has(char_id):
		color = GameData.MONSTERS[char_id].get("color", Color.WHITE)
	elif char_id == "daniel_ragnar":
		color = Color("#D9CBB8")

	for x in range(12, 36):
		for y in range(16, 40):
			img.set_pixel(x, y, color)

	var tex = ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

# Retorna lista de frames de animação gerada pelo PixelLab (ex: anim_walk / anim_attack)
static func _get_animation_frames(char_id: String, anim_folder: String, direction: String) -> Array[Texture2D]:
	var cache_key = char_id + "_" + anim_folder + "_" + direction
	if _animation_frames.has(cache_key):
		return _animation_frames[cache_key]

	var frames: Array[Texture2D] = []
	for i in range(9):
		var p = "res://assets/" + char_id + "/" + anim_folder + "/" + direction + "/" + str(i) + ".png"
		if ResourceLoader.exists(p):
			var t = load(p)
			if t:
				frames.append(t)

	if frames.size() > 0:
		_animation_frames[cache_key] = frames
		return frames

	# Fallback seguro para pose estática se não houver frames gerados
	var single = get_character_texture(char_id, direction)
	if single:
		frames.append(single)
	_animation_frames[cache_key] = frames
	return frames

static func get_walk_animation_frames(char_id: String, direction: String = "south") -> Array[Texture2D]:
	return _get_animation_frames(char_id, "anim_walk", direction)

static func get_attack_animation_frames(char_id: String, direction: String = "south") -> Array[Texture2D]:
	return _get_animation_frames(char_id, "anim_attack", direction)

static func get_cash_note_texture() -> Texture2D:
	if _texture_cache.has("cash_note"):
		return _texture_cache["cash_note"]
	var local_path = "res://assets/items/cash_note.png"
	if ResourceLoader.exists(local_path):
		var loaded = load(local_path)
		if loaded:
			_texture_cache["cash_note"] = loaded
			return loaded

	var img = Image.create(24, 14, false, Image.FORMAT_RGBA8)
	for x in range(2, 22):
		for y in range(2, 12):
			img.set_pixel(x, y, Color("#85BB65"))
	for x in range(1, 23):
		img.set_pixel(x, 1, Color("#2E5618"))
		img.set_pixel(x, 12, Color("#2E5618"))
	for y in range(1, 13):
		img.set_pixel(1, y, Color("#2E5618"))
		img.set_pixel(22, y, Color("#2E5618"))
	img.set_pixel(11, 6, Color("#1B380E"))
	img.set_pixel(12, 6, Color("#1B380E"))
	img.set_pixel(11, 7, Color("#1B380E"))
	img.set_pixel(12, 7, Color("#1B380E"))

	var tex = ImageTexture.create_from_image(img)
	_texture_cache["cash_note"] = tex
	return tex

static func get_ground_texture(world_id: String) -> Texture2D:
	var key = "ground_" + world_id
	if _texture_cache.has(key):
		return _texture_cache[key]
	var p = "res://assets/tiles/ground_" + world_id + ".png"
	if ResourceLoader.exists(p):
		var t = load(p)
		if t:
			_texture_cache[key] = t
			return t
	return null

static func get_obstacle_texture(world_id: String) -> Texture2D:
	var key = "obs_" + world_id
	if _texture_cache.has(key):
		return _texture_cache[key]
	var p = "res://assets/objects/obs_" + world_id + ".png"
	if ResourceLoader.exists(p):
		var t = load(p)
		if t:
			_texture_cache[key] = t
			return t
	return null

static func get_object_texture(obj_name: String) -> Texture2D:
	var key = "obj_" + obj_name
	if _texture_cache.has(key):
		return _texture_cache[key]
	var p = "res://assets/objects/" + obj_name + ".png"
	if ResourceLoader.exists(p):
		var t = load(p)
		if t:
			_texture_cache[key] = t
			return t
	return null

static func get_spell_texture(spell_id: String) -> Texture2D:
	var key = "spell_" + spell_id
	if _texture_cache.has(key):
		return _texture_cache[key]
	var p = "res://assets/spells/" + spell_id + ".png"
	if ResourceLoader.exists(p):
		var t = load(p)
		if t:
			_texture_cache[key] = t
			return t
	return null

const ITEM_ICON_ALIASES := {
	"apple": "maca",
	"bread": "pao",
	"meat": "carne_assada",
	"feast": "banquete_real",
	"none": "armor_chest"
}

static func get_item_icon(icon_name: String) -> Texture2D:
	var resolved = ITEM_ICON_ALIASES.get(icon_name, icon_name)
	var key = "item_" + resolved
	if _texture_cache.has(key):
		return _texture_cache[key]
	var p = "res://assets/items/" + resolved + ".png"
	if ResourceLoader.exists(p):
		var t = load(p)
		if t:
			_texture_cache[key] = t
			return t
	return null
