extends Node

## Telemetria em tempo real da sessão de caça (estilo Poke Idle League / Tibia).
signal analyzer_updated

var session_time: float = 0.0
var total_kills: int = 0
var kills_by_monster: Dictionary = {}
var session_xp: int = 0
var gross_cash: int = 0
var food_waste_cash: int = 0
var is_active: bool = true
var _emit_accum: float = 0.0

func _process(delta: float):
	if is_active and GameState.current_world != "vila" and GameState.current_world != "cabana":
		session_time += delta
		_emit_accum += delta
		if _emit_accum >= 0.5:
			_emit_accum = 0.0
			analyzer_updated.emit()

func record_kill(monster_id: String, xp_earned: int):
	total_kills += 1
	kills_by_monster[monster_id] = kills_by_monster.get(monster_id, 0) + 1
	session_xp += xp_earned
	analyzer_updated.emit()

func record_cash_collected(amount: int):
	gross_cash += amount
	analyzer_updated.emit()

func record_food_consumed(food_id: String):
	if GameData.FOODS.has(food_id):
		food_waste_cash += GameData.FOODS[food_id].price
		analyzer_updated.emit()

func get_net_profit() -> int:
	return gross_cash - food_waste_cash

func get_xp_per_hour() -> int:
	if session_time <= 5.0:
		return 0
	var hours = session_time / 3600.0
	return int(session_xp / hours)

func get_cash_per_hour() -> int:
	if session_time <= 5.0:
		return 0
	var hours = session_time / 3600.0
	return int(get_net_profit() / hours)

func reset_session():
	session_time = 0.0
	total_kills = 0
	kills_by_monster.clear()
	session_xp = 0
	gross_cash = 0
	food_waste_cash = 0
	_emit_accum = 0.0
	analyzer_updated.emit()
