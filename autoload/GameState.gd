extends Node

## Gerencia estado persistente do jogador, inventário, progressão, áudio e Save/Load.

# Sinais globais para atualização da HUD e eventos
signal stats_changed
signal cash_changed(new_amount)
signal inventory_changed
signal world_changed(world_id)
signal boss_defeated(boss_id)
signal player_died
signal player_damaged(amount)
signal player_healed(amount)
signal screen_shake_requested(intensity, duration)
signal hitstop_requested(duration)
signal game_saved
signal game_reset
signal leveled_up(new_level)

const SAVE_PATH = "user://savegame.json"

# Atributos vitais de Daniel Ragnar
var player_name: String = "Daniel Ragnar"
var current_hp: int = 100
var max_hp: int = 100
var current_mana: int = 50
var max_mana: int = 50
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 50

# Economia e Equipamentos
var cash_notes: int = 0
var equipped_weapon: String = "sword_wood"
var equipped_armor: String = "none"
var owned_weapons: Array[String] = ["sword_wood"]
var owned_armors: Array[String] = ["none"]

# Inventário de Comidas: id -> quantidade
var food_inventory = {
	"apple": 5,
	"bread": 2,
	"meat": 0
}

# Magias desbloqueadas
var unlocked_spells = {
	"fireball": true,    # Começa com a Bola de Fogo dada na floresta
	"tornado": false,
	"water_bomb": false
}

# Cooldowns ativos de magias
var spell_cooldowns = {
	"fireball": 0.0,
	"tornado": 0.0,
	"water_bomb": 0.0
}

# Progresso do Mundo
var current_world: String = "floresta"
var unlocked_worlds = {
	"vila": true,
	"floresta": true,
	"caverna": false,
	"castelo": false,
	"cabana": false
}

var defeated_bosses = {
	"lobisomem": false,
	"toupeira_serra": false,
	"robo_toupeira_serra": false,
	"robo_aranha": false,
	"dragao": false,
	"lunario": false
}

# Abates na sessão atual da zona para liberar o botão de Chefe
var zone_kills: int = 0
var total_kills_all_time: int = 0
var bestiary_kills: Dictionary = {}
var play_time_seconds: float = 0.0
var victory_achieved: bool = false
var intro_cutscene_seen: bool = false

# Modo Auxiliar (Auto-Hunt)
var auto_hunt_enabled: bool = false
var mana_regen_accum: float = 0.0
var _autosave_accum: float = 0.0

func _ready():
	load_game()

func _process(delta: float):
	play_time_seconds += delta

	# Salvamento automático periódico em segundo plano (a cada 15s)
	_autosave_accum += delta
	if _autosave_accum >= 15.0:
		_autosave_accum = 0.0
		save_game()

	# Redução de cooldowns de magias
	for s in spell_cooldowns.keys():
		if spell_cooldowns[s] > 0.0:
			spell_cooldowns[s] = max(0.0, spell_cooldowns[s] - delta)

	# Regeneração passiva de Mana (3 por segundo com acumulador de ponto flutuante)
	if current_mana < max_mana:
		mana_regen_accum += delta * 3.0
		if mana_regen_accum >= 1.0:
			var gain = int(mana_regen_accum)
			mana_regen_accum -= gain
			current_mana = min(max_mana, current_mana + gain)
			stats_changed.emit()

func add_cash(amount: int):
	if amount <= 0:
		return
	cash_notes += amount
	cash_changed.emit(cash_notes)
	save_game()

func spend_cash(amount: int) -> bool:
	if amount <= 0:
		return false
	if cash_notes >= amount:
		cash_notes -= amount
		cash_changed.emit(cash_notes)
		save_game()
		return true
	return false

func add_xp(amount: int):
	if amount <= 0:
		return
	current_xp += amount
	var did_level_up = false
	xp_to_next_level = maxi(50, xp_to_next_level)
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		max_hp += 20
		current_hp = max_hp
		max_mana += 10
		current_mana = max_mana
		xp_to_next_level = maxi(50, int(xp_to_next_level * 1.5))
		did_level_up = true
	stats_changed.emit()
	if did_level_up:
		leveled_up.emit(level)
	save_game()

func take_damage(amount: int) -> int:
	var armor_data = GameData.ARMORS.get(equipped_armor, GameData.ARMORS["none"])
	var reduction = armor_data.get("defense_pct", 0.0)
	var final_damage = max(1, int(amount * (1.0 - reduction)))
	current_hp = max(0, current_hp - final_damage)
	stats_changed.emit()
	player_damaged.emit(final_damage)
	trigger_shake(5.5, 0.16)
	if current_hp <= 0:
		player_died.emit()
	return final_damage

func trigger_shake(intensity: float, duration: float = 0.15):
	screen_shake_requested.emit(intensity, duration)

func trigger_hitstop(duration: float = 0.045):
	hitstop_requested.emit(duration)

func heal(amount: int):
	if amount <= 0:
		return
	current_hp = min(max_hp, current_hp + amount)
	stats_changed.emit()
	player_healed.emit(amount)

func eat_food(food_id: String = "") -> bool:
	if current_hp >= max_hp:
		return false
	if food_id == "":
		var missing := max_hp - current_hp
		var order: Array[String] = ["apple", "bread", "meat"]
		if missing >= 130:
			order = ["meat", "bread", "apple"]
		elif missing >= 55:
			order = ["bread", "meat", "apple"]
		for f in order:
			if food_inventory.get(f, 0) > 0:
				food_id = f
				break
	if food_id != "" and food_inventory.get(food_id, 0) > 0:
		food_inventory[food_id] -= 1
		var f_data = GameData.FOODS[food_id]
		heal(f_data.heal)
		inventory_changed.emit()
		save_game()
		return true
	return false

func has_weapon(w_id: String) -> bool:
	return w_id in owned_weapons

func has_armor(a_id: String) -> bool:
	return a_id in owned_armors

func unlock_weapon(w_id: String, auto_equip: bool = true):
	if not GameData.WEAPONS.has(w_id):
		return
	if not (w_id in owned_weapons):
		owned_weapons.append(w_id)
	if auto_equip:
		equipped_weapon = w_id
	inventory_changed.emit()
	save_game()

func equip_weapon(w_id: String) -> bool:
	if not GameData.WEAPONS.has(w_id) or not (w_id in owned_weapons):
		return false
	equipped_weapon = w_id
	inventory_changed.emit()
	save_game()
	return true

func unlock_armor(a_id: String, auto_equip: bool = true):
	if not GameData.ARMORS.has(a_id):
		return
	if not (a_id in owned_armors):
		owned_armors.append(a_id)
	if auto_equip:
		equipped_armor = a_id
	inventory_changed.emit()
	save_game()

func equip_armor(a_id: String) -> bool:
	if not GameData.ARMORS.has(a_id) or not (a_id in owned_armors):
		return false
	equipped_armor = a_id
	inventory_changed.emit()
	save_game()
	return true

func cast_spell(spell_id: String) -> bool:
	if not unlocked_spells.get(spell_id, false):
		return false
	if spell_cooldowns.get(spell_id, 0.0) > 0.0:
		return false
	var s_data = GameData.SPELLS[spell_id]
	if current_mana < s_data.mana_cost:
		return false
	current_mana -= s_data.mana_cost
	spell_cooldowns[spell_id] = s_data.cooldown
	stats_changed.emit()
	return true

func set_world(new_world: String):
	if GameData.WORLDS.has(new_world) and unlocked_worlds.get(new_world, false):
		current_world = new_world
		zone_kills = 0
		world_changed.emit(new_world)
		save_game()

func on_monster_killed(m_id: String, xp_val: int, is_boss: bool):
	total_kills_all_time += 1
	bestiary_kills[m_id] = int(bestiary_kills.get(m_id, 0)) + 1
	add_xp(xp_val)
	if is_boss:
		defeated_bosses[m_id] = true
		boss_defeated.emit(m_id)
		check_world_unlocks()
		check_spell_unlocks()
		stats_changed.emit()
	else:
		zone_kills += 1
	save_game()

func get_next_world_boss(world_id: String = "") -> String:
	var target_w := world_id if world_id != "" else current_world
	var w: Dictionary = GameData.WORLDS.get(target_w, {})
	var sub_b := str(w.get("sub_boss", ""))
	if sub_b != "" and not defeated_bosses.get(sub_b, false):
		return sub_b
	var main_b := str(w.get("boss", ""))
	if main_b != "" and not defeated_bosses.get(main_b, false):
		return main_b
	return ""

func get_defeated_boss_count() -> int:
	var count = 0
	for k in defeated_bosses.keys():
		if defeated_bosses[k]:
			count += 1
	return count

func check_world_unlocks():
	if defeated_bosses.get("toupeira_serra", false):
		unlocked_worlds["caverna"] = true
	if defeated_bosses.get("robo_aranha", false):
		unlocked_worlds["castelo"] = true
	if defeated_bosses.get("lunario", false):
		unlocked_worlds["cabana"] = true

func check_spell_unlocks() -> bool:
	var changed := false
	var any_late_boss := bool(
		defeated_bosses.get("toupeira_serra", false)
		or defeated_bosses.get("robo_toupeira_serra", false)
		or defeated_bosses.get("robo_aranha", false)
		or defeated_bosses.get("dragao", false)
		or defeated_bosses.get("lunario", false)
		or unlocked_worlds.get("caverna", false)
		or unlocked_worlds.get("castelo", false)
		or unlocked_worlds.get("cabana", false)
	)
	if not unlocked_spells.get("tornado", false):
		if defeated_bosses.get("lobisomem", false) or any_late_boss:
			unlocked_spells["tornado"] = true
			changed = true
	if not unlocked_spells.get("water_bomb", false):
		if any_late_boss:
			unlocked_spells["water_bomb"] = true
			changed = true
	return changed

func has_saved_progress() -> bool:
	return intro_cutscene_seen or total_kills_all_time > 0 or level > 1 or cash_notes > 0 or get_defeated_boss_count() > 0

func save_game():
	var save_dict = {
		"current_hp": current_hp,
		"max_hp": max_hp,
		"current_mana": current_mana,
		"max_mana": max_mana,
		"level": level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level,
		"cash_notes": cash_notes,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"owned_weapons": owned_weapons,
		"owned_armors": owned_armors,
		"food_inventory": food_inventory,
		"unlocked_spells": unlocked_spells,
		"unlocked_worlds": unlocked_worlds,
		"defeated_bosses": defeated_bosses,
		"current_world": current_world,
		"zone_kills": zone_kills,
		"total_kills_all_time": total_kills_all_time,
		"bestiary_kills": bestiary_kills,
		"play_time_seconds": play_time_seconds,
		"victory_achieved": victory_achieved,
		"intro_cutscene_seen": intro_cutscene_seen,
		"audio_settings": AudioManager.get_settings()
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()
		game_saved.emit()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_res = json.parse(text)
		if parse_res == OK and json.data is Dictionary:
			var d = json.data
			max_hp = maxi(20, int(d.get("max_hp", max_hp)))
			current_hp = clampi(int(d.get("current_hp", current_hp)), 1, max_hp)
			max_mana = maxi(10, int(d.get("max_mana", max_mana)))
			current_mana = clampi(int(d.get("current_mana", current_mana)), 0, max_mana)
			level = clampi(int(d.get("level", level)), 1, 999)
			xp_to_next_level = maxi(50, int(d.get("xp_to_next_level", xp_to_next_level)))
			current_xp = clampi(int(d.get("current_xp", current_xp)), 0, 10000000)
			cash_notes = maxi(0, int(d.get("cash_notes", cash_notes)))
			equipped_weapon = str(d.get("equipped_weapon", equipped_weapon))
			if not GameData.WEAPONS.has(equipped_weapon):
				equipped_weapon = "sword_wood"
			equipped_armor = str(d.get("equipped_armor", equipped_armor))
			if not GameData.ARMORS.has(equipped_armor):
				equipped_armor = "none"
			owned_weapons = ["sword_wood"]
			if d.has("owned_weapons") and d["owned_weapons"] is Array:
				for w in d["owned_weapons"]:
					var ws = str(w)
					if GameData.WEAPONS.has(ws) and not (ws in owned_weapons):
						owned_weapons.append(ws)
			if not (equipped_weapon in owned_weapons):
				owned_weapons.append(equipped_weapon)

			owned_armors = ["none"]
			if d.has("owned_armors") and d["owned_armors"] is Array:
				for a in d["owned_armors"]:
					var as_id = str(a)
					if GameData.ARMORS.has(as_id) and not (as_id in owned_armors):
						owned_armors.append(as_id)
			if not (equipped_armor in owned_armors):
				owned_armors.append(equipped_armor)
			zone_kills = maxi(0, int(d.get("zone_kills", zone_kills)))
			total_kills_all_time = maxi(0, int(d.get("total_kills_all_time", total_kills_all_time)))
			play_time_seconds = maxf(0.0, float(d.get("play_time_seconds", play_time_seconds)))
			victory_achieved = bool(d.get("victory_achieved", victory_achieved))
			intro_cutscene_seen = bool(d.get("intro_cutscene_seen", false))
			if d.has("audio_settings") and d["audio_settings"] is Dictionary:
				AudioManager.apply_settings(d["audio_settings"])

			if d.has("bestiary_kills") and d["bestiary_kills"] is Dictionary:
				bestiary_kills.clear()
				for k in d["bestiary_kills"].keys():
					var m_key := str(k)
					if GameData.MONSTERS.has(m_key):
						bestiary_kills[m_key] = maxi(0, int(d["bestiary_kills"][k]))
			if d.has("food_inventory") and d["food_inventory"] is Dictionary:
				for k in food_inventory.keys():
					if d["food_inventory"].has(k):
						food_inventory[k] = clampi(int(d["food_inventory"][k]), 0, 9999)
			if d.has("unlocked_spells") and d["unlocked_spells"] is Dictionary:
				for k in unlocked_spells.keys():
					if d["unlocked_spells"].has(k):
						unlocked_spells[k] = bool(d["unlocked_spells"][k])
			if d.has("unlocked_worlds") and d["unlocked_worlds"] is Dictionary:
				for k in unlocked_worlds.keys():
					if d["unlocked_worlds"].has(k):
						unlocked_worlds[k] = bool(d["unlocked_worlds"][k])
			if d.has("defeated_bosses") and d["defeated_bosses"] is Dictionary:
				for k in defeated_bosses.keys():
					if d["defeated_bosses"].has(k):
						defeated_bosses[k] = bool(d["defeated_bosses"][k])

			var saved_world = str(d.get("current_world", current_world))
			if GameData.WORLDS.has(saved_world) and unlocked_worlds.get(saved_world, false):
				current_world = saved_world
			check_world_unlocks()
			if check_spell_unlocks():
				save_game()

func reset_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	current_hp = 100
	max_hp = 100
	current_mana = 50
	max_mana = 50
	level = 1
	current_xp = 0
	xp_to_next_level = 50
	cash_notes = 0
	equipped_weapon = "sword_wood"
	equipped_armor = "none"
	owned_weapons = ["sword_wood"]
	owned_armors = ["none"]
	food_inventory = {
		"apple": 5,
		"bread": 2,
		"meat": 0
	}
	unlocked_spells = {
		"fireball": true,
		"tornado": false,
		"water_bomb": false
	}
	spell_cooldowns = {
		"fireball": 0.0,
		"tornado": 0.0,
		"water_bomb": 0.0
	}
	unlocked_worlds = {
		"vila": true,
		"floresta": true,
		"caverna": false,
		"castelo": false,
		"cabana": false
	}
	defeated_bosses = {
		"lobisomem": false,
		"toupeira_serra": false,
		"robo_toupeira_serra": false,
		"robo_aranha": false,
		"dragao": false,
		"lunario": false
	}
	zone_kills = 0
	total_kills_all_time = 0
	bestiary_kills.clear()
	play_time_seconds = 0.0
	victory_achieved = false
	intro_cutscene_seen = false
	auto_hunt_enabled = false
	mana_regen_accum = 0.0

	HuntAnalyzerData.reset_session()
	current_world = "floresta"
	save_game()
	stats_changed.emit()
	cash_changed.emit(cash_notes)
	inventory_changed.emit()
	game_reset.emit()
	world_changed.emit(current_world)
