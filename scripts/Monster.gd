extends CharacterBody2D

## Inimigos comuns e chefes com pathfinding A*, animações direcionais e ataques especiais.

signal killed(monster_id)

@export var monster_id: String = "toupeira"

var data: Dictionary
var max_hp: int = 40
var current_hp: int = 40
var speed: float = 60.0
var damage: int = 10
var xp_reward: int = 15
var loot_mult: float = 1.0
var is_boss: bool = false

var sprite_container: Node2D
var sprite: Sprite2D
var hp_bar: ProgressBar
var stun_timer: float = 0.0
var attack_timer: float = 0.0
var current_direction: String = "south"
var knockback_velocity: Vector2 = Vector2.ZERO

# Variáveis para Animação dos Monstros (Frames PixelLab + Fallback Procedural)
var anim_time: float = 0.0
var walk_cycle: float = 0.0
var walk_frame_index: int = 0
var walk_frame_timer: float = 0.0
const WALK_FRAME_DURATION: float = 0.12
var is_striking: bool = false
var strike_timer: float = 0.0

# Habilidades Únicas e Fases de Chefes
var boss_skill_cooldown: float = 2.6
var boss_skill_step: int = 0
var boss_windup_timer: float = 0.0
var boss_queued_skill: String = ""
var boss_aim_dir: Vector2 = Vector2.DOWN
var boss_dash_timer: float = 0.0
var boss_dash_velocity: Vector2 = Vector2.ZERO
var boss_dash_hit_dealt: bool = false
var boss_enraged: bool = false
var telegraph_line: Line2D = null
var boss_label: Label = null
var target_reticle: Node2D = null
var nav_path: PackedVector2Array = PackedVector2Array()
var nav_recalc_timer: float = 0.0
var special_skill_cooldown: float = 1.4
var special_skill_step: int = 0

class TargetReticle extends Node2D:
	var half_size: float = 19.0
	var pulse: float = 0.0
	func _process(delta: float):
		pulse += delta * 6.5
		if visible:
			queue_redraw()
	func _draw():
		var hs = half_size + sin(pulse) * 1.6
		var col = Color(0.95, 0.16, 0.16, 0.95)
		draw_rect(Rect2(Vector2(-hs, -hs), Vector2(hs * 2.0, hs * 2.0)), col, false, 2.2)
		var c = 6.0
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner = Vector2(sx * (hs + 2.0), sy * (hs + 2.0))
				draw_line(corner, corner - Vector2(sx * c, 0), Color("#FF7575"), 2.0)
				draw_line(corner, corner - Vector2(0, sy * c), Color("#FF7575"), 2.0)

func setup(m_id: String):
	monster_id = m_id
	data = GameData.MONSTERS.get(monster_id, GameData.MONSTERS["toupeira"])
	max_hp = data.max_hp
	speed = data.speed
	damage = data.damage
	xp_reward = int(data.xp)
	loot_mult = 1.0
	is_boss = data.is_boss

	# Escalonamento contextual para monstros comuns que reaparecem em zonas avançadas
	if not is_boss:
		if GameState.current_world == "caverna" and m_id == "toupeira":
			max_hp = int(max_hp * 1.55)
			damage = int(damage * 1.45)
			xp_reward = int(xp_reward * 1.8)
			loot_mult = 1.8
		elif GameState.current_world == "castelo" and m_id in ["esqueleto", "robo"]:
			var hp_m := 1.85 if m_id == "esqueleto" else 1.55
			var dmg_m := 1.45 if m_id == "esqueleto" else 1.25
			max_hp = int(max_hp * hp_m)
			damage = int(damage * dmg_m)
			xp_reward = int(xp_reward * 2.0)
			loot_mult = 2.0

	current_hp = max_hp

func _ready():
	add_to_group("monsters")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	if data.is_empty():
		setup(monster_id)

	# Offset aleatório de tempo para os monstros não se moverem sincronizados
	anim_time = randf() * 10.0

	sprite_container = Node2D.new()
	add_child(sprite_container)

	target_reticle = TargetReticle.new()
	target_reticle.half_size = 28.0 if is_boss else 18.0
	target_reticle.z_index = -1
	target_reticle.visible = false
	add_child(target_reticle)

	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = SpriteFactory.get_character_texture(monster_id, "south")
	sprite_container.add_child(sprite)
	if is_boss:
		sprite_container.scale = Vector2(1.65, 1.65)

	input_pickable = true
	input_event.connect(_on_input_event)

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0 if is_boss else 16.0
	col.shape = circle
	add_child(col)

	# Barra de Vida nítida
	hp_bar = ProgressBar.new()
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false
	hp_bar.size = Vector2(40 if not is_boss else 80, 5)
	hp_bar.position = Vector2(-20 if not is_boss else -40, -32 if not is_boss else -45)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#E62E2E")
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_right = 2
	sb.corner_radius_bottom_left = 2
	hp_bar.add_theme_stylebox_override("fill", sb)
	add_child(hp_bar)

	if is_boss:
		boss_label = Label.new()
		boss_label.text = "[CHEFE] " + str(data.get("name", monster_id))
		boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_label.custom_minimum_size = Vector2(220, 20)
		boss_label.position = Vector2(-110, -68)
		boss_label.add_theme_font_size_override("font_size", 12)
		boss_label.add_theme_color_override("font_color", Color("#FFD700"))
		boss_label.add_theme_color_override("font_outline_color", Color.BLACK)
		boss_label.add_theme_constant_override("outline_size", 3)
		add_child(boss_label)

		telegraph_line = Line2D.new()
		telegraph_line.width = 16.0
		telegraph_line.default_color = Color(1.0, 0.25, 0.25, 0.55)
		telegraph_line.visible = false
		telegraph_line.z_index = -1
		add_child(telegraph_line)

func _physics_process(delta: float):
	anim_time += delta

	# Aplica e dissipa o impacto de Knockback
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		var bounds := GameData.get_map_bounds(get_tree().current_scene)
		global_position.x = clamp(global_position.x, 48.0, bounds.x - 48.0)
		global_position.y = clamp(global_position.y, 48.0, bounds.y - 48.0)
		_update_procedural_animation(delta, false)
		return

	if stun_timer > 0.0:
		stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		# Tremor de atordoamento
		sprite_container.position = Vector2(sin(anim_time * 30.0) * 3.0, 0)
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	var is_moving = false
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		var target = players[0]
		if target_reticle:
			target_reticle.visible = ("current_target" in target and target.current_target == self and current_hp > 0)
		var diff = target.global_position - global_position
		var dist = diff.length()
		var dir = diff.normalized()

		# Direção visual principal (exceto durante dash já travado)
		var face_dir = boss_aim_dir if boss_dash_timer > 0.0 else dir
		var new_dir = current_direction
		if abs(face_dir.x) > abs(face_dir.y):
			new_dir = "east" if face_dir.x > 0 else "west"
		else:
			new_dir = "south" if face_dir.y > 0 else "north"
		if new_dir != current_direction:
			current_direction = new_dir
			walk_frame_index = 0
			sprite.texture = SpriteFactory.get_character_texture(monster_id, current_direction)

		# Máquina de Estados de Habilidades Especiais dos Chefes
		if is_boss and _process_boss_combat(delta, target, diff, dist, dir):
			is_moving = boss_dash_timer > 0.0
		elif not is_boss and monster_id == "espectro_slime" and _process_espectro_slime_combat(delta, target, dist):
			is_moving = false
		elif dist > 32.0:
			var move_speed = speed * (1.2 if boss_enraged else 1.0)
			var move_dir = dir
			nav_recalc_timer -= delta
			var main_node = get_tree().current_scene
			if dist > 90.0 and main_node and "tile_engine" in main_node and main_node.tile_engine:
				if nav_path.is_empty() or nav_recalc_timer <= 0.0:
					nav_path = main_node.tile_engine.find_world_path(global_position, target.global_position)
					nav_recalc_timer = 0.45
				while nav_path.size() > 1 and global_position.distance_to(nav_path[0]) < 20.0:
					nav_path.remove_at(0)
				if not nav_path.is_empty():
					var wp_diff = nav_path[0] - global_position
					if wp_diff.length() > 4.0:
						move_dir = wp_diff.normalized()
			var sep: Vector2 = _compute_separation_force()
			var desired_dir: Vector2 = (move_dir + sep * 0.65).normalized()
			if desired_dir != Vector2.ZERO and test_move(global_transform, desired_dir * 12.0):
				for ang_deg in [35.0, -35.0, 70.0, -70.0]:
					var alt: Vector2 = desired_dir.rotated(deg_to_rad(ang_deg))
					if not test_move(global_transform, alt * 14.0):
						desired_dir = alt
						break
			velocity = desired_dir * move_speed
			is_moving = true
		else:
			velocity = _compute_separation_force() * (speed * 0.35)
			if attack_timer <= 0.0:
				attack_timer = 1.0
				is_striking = true
				strike_timer = 0.16
				GameState.take_damage(damage)
				if monster_id in ["toupeira_serra", "robo_toupeira_serra"]:
					AudioManager.play_sfx("sword_slash")
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	var bounds := GameData.get_map_bounds(get_tree().current_scene)
	global_position.x = clamp(global_position.x, 48.0, bounds.x - 48.0)
	global_position.y = clamp(global_position.y, 48.0, bounds.y - 48.0)
	_update_procedural_animation(delta, is_moving)

func _compute_separation_force() -> Vector2:
	var push := Vector2.ZERO
	var min_sep := 42.0 if is_boss else 28.0
	for other in get_tree().get_nodes_in_group("monsters"):
		if other != self and is_instance_valid(other) and other.current_hp > 0:
			var d_vec: Vector2 = global_position - other.global_position
			var d: float = d_vec.length()
			if d > 0.01 and d < min_sep:
				push += (d_vec / d) * ((min_sep - d) / min_sep)
	return push.limit_length(1.2)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]) and "current_target" in players[0]:
			players[0].current_target = self

# ========================================================
# 👾 ANIMAÇÃO DE FRAMES PIXELLAB (COM FALLBACK PROCEDURAL)
# ========================================================
func _update_procedural_animation(delta: float, is_moving: bool):
	if is_striking:
		strike_timer -= delta
		if strike_timer <= 0.0:
			is_striking = false

	var base_scale = Vector2(1.65, 1.65) if is_boss else Vector2(1.0, 1.0)
	var walk_frames = SpriteFactory.get_walk_animation_frames(monster_id, current_direction)

	if is_striking:
		# Ataque: Lunge rápido em direção ao jogador
		sprite_container.scale = base_scale * Vector2(1.18, 0.86)
		sprite_container.rotation = randf_range(-0.08, 0.08)
	elif is_moving and walk_frames.size() > 1:
		# Animação real gerada pelo PixelLab (sem distorcer/girar o sprite)
		sprite_container.position = Vector2.ZERO
		sprite_container.rotation = 0.0
		sprite_container.scale = base_scale
		walk_frame_timer += delta
		var speed_factor = clamp(speed / 70.0, 0.75, 1.5)
		if walk_frame_timer >= (WALK_FRAME_DURATION / speed_factor):
			walk_frame_timer = 0.0
			walk_frame_index = (walk_frame_index + 1) % walk_frames.size()
			sprite.texture = walk_frames[walk_frame_index]
	elif is_moving:
		# Fallback procedural caso ainda não haja frames anim_walk
		match monster_id:
			"zumbi":
				walk_cycle += delta * 6.0
				sprite_container.rotation = sin(walk_cycle) * 0.18
				sprite_container.position = Vector2(0, 1.0 if sin(walk_cycle) > 0 else -3.0)
				sprite_container.scale = base_scale * Vector2(0.95, 1.05)
			"toupeira", "toupeira_serra":
				walk_cycle += delta * 16.0
				sprite_container.rotation = sin(walk_cycle) * 0.15
				sprite_container.position = Vector2(0, abs(sin(walk_cycle)) * -4.0)
				sprite_container.scale = base_scale * Vector2(1.08, 0.92)
			_:
				walk_cycle += delta * 12.0
				sprite_container.rotation = sin(walk_cycle * 0.5) * 0.1
				sprite_container.position = Vector2(0, abs(sin(walk_cycle)) * -4.0)
				sprite_container.scale = base_scale
	else:
		# Parado (Idle): Pose estática limpa + leve respiração sutil
		sprite.texture = SpriteFactory.get_character_texture(monster_id, current_direction)
		walk_frame_index = 0
		walk_frame_timer = 0.0
		var breath = sin(anim_time * 2.5) * 1.0
		sprite_container.position = Vector2(0, breath)
		sprite_container.rotation = 0.0
		sprite_container.scale = base_scale

func take_damage(amount: int, is_crit_or_special: bool = false, from_position: Vector2 = Vector2.ZERO):
	current_hp -= amount
	hp_bar.value = current_hp

	var txt_color = Color("#FFD700") if is_crit_or_special else Color.WHITE
	var prefix = "CRÍTICO! -" if is_crit_or_special else "-"
	_spawn_floating_text(prefix + str(amount), txt_color, is_crit_or_special)

	if from_position != Vector2.ZERO:
		var push_dir = (global_position - from_position).normalized()
		var push_force = 160.0 if not is_boss else 45.0
		knockback_velocity = push_dir * push_force

	var tween = create_tween()
	tween.tween_property(sprite_container, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.06)
	tween.tween_property(sprite_container, "modulate", Color.WHITE, 0.08)

	if is_boss and not boss_enraged and current_hp > 0 and current_hp <= int(max_hp * 0.5):
		_trigger_boss_enrage()

	if current_hp <= 0:
		die()

func apply_stun(duration: float):
	stun_timer = duration
	if sprite_container:
		sprite_container.modulate = Color.WHITE
	if is_boss and (boss_windup_timer > 0.0 or boss_dash_timer > 0.0):
		boss_windup_timer = 0.0
		boss_dash_timer = 0.0
		boss_skill_cooldown = 2.5
		if telegraph_line:
			telegraph_line.visible = false
		_spawn_floating_text("INTERROMPIDO!", Color("#00F0FF"), true)
	else:
		_spawn_floating_text("ATORDÚA!", Color("#FFD700"), true)

# ========================================================
# 👑 HABILIDADES ÚNICAS DE CADA CHEFE E PROJÉTEIS
# ========================================================
func _trigger_boss_enrage():
	boss_enraged = true
	AudioManager.play_sfx("boss_roar")
	GameState.trigger_shake(10.0, 0.30)
	_spawn_floating_text("FÚRIA DE CHEFE!", Color("#FF3355"), true)
	if boss_label:
		boss_label.text = "[FÚRIA] " + str(data.get("name", monster_id))
		boss_label.add_theme_color_override("font_color", Color("#FF5555"))

func _process_boss_combat(delta: float, target: Node2D, diff: Vector2, dist: float, dir: Vector2) -> bool:
	# 1. Executando Investida (Dash) ativa
	if boss_dash_timer > 0.0:
		boss_dash_timer -= delta
		velocity = boss_dash_velocity
		if not boss_dash_hit_dealt and dist <= 44.0:
			boss_dash_hit_dealt = true
			GameState.take_damage(int(damage * 1.25))
			AudioManager.play_sfx("hammer_smash")
			GameState.trigger_shake(9.0, 0.22)
		if boss_dash_timer <= 0.0:
			boss_dash_velocity = Vector2.ZERO
		return true

	# 2. Preparando golpe (Windup com telegrafo visual)
	if boss_windup_timer > 0.0:
		boss_windup_timer -= delta
		velocity = Vector2.ZERO
		var pulse = 1.0 + sin(anim_time * 28.0) * 0.25
		sprite_container.modulate = Color(1.4 * pulse, 0.75, 0.75, 1.0)
		if boss_windup_timer <= 0.0:
			sprite_container.modulate = Color.WHITE
			if telegraph_line:
				telegraph_line.visible = false
			_execute_boss_skill(target)
		return true

	# 3. Contagem regressiva da próxima habilidade especial
	boss_skill_cooldown -= delta
	if boss_skill_cooldown <= 0.0 and dist <= 480.0:
		_start_boss_windup(target, dir)
		return true

	return false

func _start_boss_windup(target: Node2D, dir: Vector2):
	boss_aim_dir = dir if dir != Vector2.ZERO else Vector2.DOWN
	boss_skill_step += 1
	var cd_mult = 0.75 if boss_enraged else 1.0
	boss_skill_cooldown = randf_range(3.2, 4.2) * cd_mult

	match monster_id:
		"lobisomem":
			boss_queued_skill = "dash_bite"
			boss_windup_timer = 0.55
			_show_dash_telegraph(boss_aim_dir * 260.0, Color(1.0, 0.25, 0.25, 0.65))
		"toupeira_serra":
			if boss_skill_step % 2 == 1:
				boss_queued_skill = "saw_dash"
				boss_windup_timer = 0.60
				_show_dash_telegraph(boss_aim_dir * 280.0, Color(1.0, 0.65, 0.15, 0.65))
			else:
				boss_queued_skill = "saw_fan"
				boss_windup_timer = 0.48
		"robo_toupeira_serra":
			boss_queued_skill = "quake_saws" if boss_skill_step % 2 == 1 else "shock_aoe"
			boss_windup_timer = 0.50
		"robo_aranha":
			boss_queued_skill = "spider_lasers" if boss_skill_step % 2 == 1 else "shock_web"
			boss_windup_timer = 0.50
		"dragao":
			boss_queued_skill = "dragon_breath" if boss_skill_step % 2 == 1 else "dragon_meteors"
			boss_windup_timer = 0.55
		"lunario":
			boss_queued_skill = "lunario_nova" if boss_skill_step % 2 == 1 else "lunario_meteors"
			boss_windup_timer = 0.55
		_:
			boss_queued_skill = "shock_aoe"
			boss_windup_timer = 0.50

func _show_dash_telegraph(vec_offset: Vector2, col: Color):
	if not telegraph_line:
		return
	telegraph_line.clear_points()
	telegraph_line.add_point(Vector2.ZERO)
	telegraph_line.add_point(vec_offset)
	telegraph_line.default_color = col
	telegraph_line.visible = true

func _execute_boss_skill(target: Node2D):
	if not is_instance_valid(target):
		return
	var to_player = (target.global_position - global_position).normalized()
	if to_player == Vector2.ZERO:
		to_player = boss_aim_dir

	match boss_queued_skill:
		"dash_bite", "saw_dash":
			boss_dash_timer = 0.38
			boss_dash_velocity = boss_aim_dir * 420.0
			boss_dash_hit_dealt = false
			AudioManager.play_sfx("sword_slash")
		"saw_fan":
			AudioManager.play_sfx("sword_slash")
			_shoot_fan_projectiles(to_player, 3, deg_to_rad(22.0), int(damage * 0.85), 250.0, Color("#D8E6FF"), 11.0, "tornado", 14.0)
		"quake_saws":
			AudioManager.play_sfx("hammer_smash")
			_shoot_radial_projectiles(4 if not boss_enraged else 6, int(damage * 0.80), 230.0, Color("#70D6FF"), 11.0, "tornado", 14.0)
		"shock_aoe":
			_spawn_boss_hazard(target.global_position, 84.0, 0.90, int(damage * 1.15), Color("#46B2FF"), "hammer_smash")
		"spider_lasers":
			AudioManager.play_sfx("magic_water_bomb")
			var count = 5 if boss_enraged else 3
			_shoot_fan_projectiles(to_player, count, deg_to_rad(15.0), int(damage * 0.80), 330.0, Color("#00F0FF"), 9.0, "", 0.0)
		"shock_web":
			_spawn_boss_hazard(target.global_position, 90.0, 0.95, int(damage * 1.15), Color("#00E5FF"), "magic_water_bomb")
			if boss_enraged:
				_spawn_boss_hazard(target.global_position + Vector2(randf_range(-90, 90), randf_range(-90, 90)), 75.0, 1.05, int(damage * 0.95), Color("#00E5FF"), "magic_water_bomb")
		"dragon_breath":
			AudioManager.play_sfx("magic_fireball")
			var count = 5 if boss_enraged else 3
			_shoot_fan_projectiles(to_player, count, deg_to_rad(18.0), int(damage * 0.85), 290.0, Color("#FF5500"), 12.0, "fireball", 0.0)
		"dragon_meteors":
			_spawn_boss_hazard(target.global_position, 86.0, 0.95, int(damage * 1.15), Color("#FF3D00"), "magic_fireball")
			var offset = Vector2(randf_range(-110, 110), randf_range(-110, 110))
			_spawn_boss_hazard(target.global_position + offset, 76.0, 1.15, int(damage * 0.95), Color("#FF6D00"), "magic_fireball")
		"lunario_nova":
			AudioManager.play_sfx("boss_roar")
			if boss_enraged:
				_shoot_radial_projectiles(8, int(damage * 0.85), 275.0, Color("#C77DFF"), 12.0, "fireball", 6.0)
			else:
				_shoot_fan_projectiles(to_player, 5, deg_to_rad(16.0), int(damage * 0.85), 290.0, Color("#C77DFF"), 12.0, "fireball", 6.0)
		"lunario_meteors":
			AudioManager.play_sfx("boss_roar")
			var meteors = 3 if boss_enraged else 2
			for i in range(meteors):
				var pos = target.global_position if i == 0 else target.global_position + Vector2(randf_range(-125, 125), randf_range(-125, 125))
				_spawn_boss_hazard(pos, 96.0, 0.90 + float(i) * 0.25, int(damage * 1.15), Color("#B565FF"), "magic_fireball")

func _shoot_fan_projectiles(center_dir: Vector2, count: int, step_rad: float, dmg: int, p_speed: float, col: Color, rad: float, sp_id: String, spin: float):
	var half = float(count - 1) * 0.5
	for i in range(count):
		var angle = (float(i) - half) * step_rad
		_spawn_enemy_projectile(center_dir.rotated(angle), dmg, p_speed, col, rad, sp_id, spin)

func _shoot_radial_projectiles(count: int, dmg: int, p_speed: float, col: Color, rad: float, sp_id: String, spin: float):
	for i in range(count):
		var angle = TAU * float(i) / float(count)
		_spawn_enemy_projectile(Vector2.RIGHT.rotated(angle), dmg, p_speed, col, rad, sp_id, spin)

func _spawn_enemy_projectile(dir: Vector2, dmg: int, p_speed: float, col: Color, rad: float, sp_id: String, spin: float, origin_pos: Vector2 = Vector2.INF):
	if not get_parent():
		return
	var proj_script = load("res://scripts/EnemyProjectile.gd")
	var proj = Area2D.new()
	proj.set_script(proj_script)
	proj.global_position = (global_position + dir.normalized() * 24.0) if origin_pos == Vector2.INF else origin_pos
	proj.setup(dir, dmg, p_speed, col, rad, sp_id, spin)
	get_parent().add_child(proj)

func _get_espectro_hand_offset(is_slime_hand: bool) -> Vector2:
	# Posição exata das mãos nos sprites direcionais (roxa de slime vs ciano de plasma)
	match current_direction:
		"south":
			return Vector2(20.0, 8.0) if is_slime_hand else Vector2(-20.0, 8.0)
		"north":
			return Vector2(-20.0, 6.0) if is_slime_hand else Vector2(20.0, 6.0)
		"east":
			return Vector2(14.0, 2.0) if is_slime_hand else Vector2(6.0, 12.0)
		"west":
			return Vector2(-6.0, 12.0) if is_slime_hand else Vector2(-16.0, 4.0)
	return Vector2(18.0, 6.0) if is_slime_hand else Vector2(-18.0, 6.0)

func _spawn_hand_cast_fx(world_pos: Vector2, col: Color, is_slime: bool):
	if not get_parent():
		return
	var burst = CPUParticles2D.new()
	burst.global_position = world_pos
	burst.z_index = 6
	burst.one_shot = true
	burst.explosiveness = 0.92
	burst.amount = 14
	burst.lifetime = 0.34 if is_slime else 0.24
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 5.0
	burst.direction = Vector2(0, 1) if is_slime else Vector2.ZERO
	burst.spread = 110.0 if is_slime else 180.0
	burst.gravity = Vector2(0, 110.0) if is_slime else Vector2.ZERO
	burst.initial_velocity_min = 24.0
	burst.initial_velocity_max = 65.0
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 4.5
	burst.color = col
	get_parent().add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)

func _process_espectro_slime_combat(delta: float, target: Node2D, dist: float) -> bool:
	special_skill_cooldown -= delta
	if dist <= 285.0 and special_skill_cooldown <= 0.0:
		var use_slime := (special_skill_step % 2 == 0)
		special_skill_step += 1
		special_skill_cooldown = 1.75
		attack_timer = max(attack_timer, 0.75)
		is_striking = true
		strike_timer = 0.16

		var hand_pos := global_position + _get_espectro_hand_offset(use_slime)
		var shot_dir := (target.global_position - hand_pos).normalized()
		if shot_dir == Vector2.ZERO:
			shot_dir = (target.global_position - global_position).normalized()

		if use_slime:
			# Ataque 1: Orbe viscosa lançada diretamente da mão de slime roxo
			_spawn_hand_cast_fx(hand_pos, Color("#A855F7"), true)
			AudioManager.play_sfx("magic_water_bomb")
			_spawn_enemy_projectile(shot_dir, int(damage * 0.92), 220.0, Color("#A855F7"), 10.5, "slime_orb", 5.5, hand_pos)
		else:
			# Ataque 2: Raio veloz de plasma disparado diretamente da mão espectral de plasma
			_spawn_hand_cast_fx(hand_pos, Color("#38BDF8"), false)
			AudioManager.play_sfx("magic_fireball")
			_spawn_enemy_projectile(shot_dir, int(damage * 1.08), 340.0, Color("#38BDF8"), 9.0, "plasma_bolt", 0.0, hand_pos)
	return false

func _spawn_boss_hazard(pos: Vector2, rad: float, delay: float, dmg: int, col: Color, sfx: String):
	if not get_parent():
		return
	var max_w := 1792.0
	var max_h := 1024.0
	var m_scene = get_tree().current_scene
	if m_scene and "map_width" in m_scene:
		max_w = float(m_scene.map_width)
		max_h = float(m_scene.map_height)
	var hz_script = load("res://scripts/BossHazardZone.gd")
	var hz = Node2D.new()
	hz.set_script(hz_script)
	hz.global_position = Vector2(clamp(pos.x, 70.0, max_w - 70.0), clamp(pos.y, 70.0, max_h - 70.0))
	hz.setup(rad, delay, dmg, col, sfx)
	get_parent().add_child(hz)

func _spawn_floating_text(text: String, col: Color, is_crit: bool):
	FloatingText.spawn(get_parent(), global_position, text, col, is_crit)

func die():
	if is_boss:
		GameState.trigger_shake(15.0, 0.42)
		GameState.trigger_hitstop(0.08)
	else:
		GameState.trigger_shake(3.8, 0.11)

	_spawn_death_particles()

	var count = randi_range(3, 5) if not is_boss else 12
	var cash_total = int(round(float(randi_range(data.cash_min, data.cash_max)) * loot_mult))
	var per_note = max(1, int(cash_total / count))

	var note_script = load("res://scripts/CashNote.gd")
	for i in range(count):
		var note = Area2D.new()
		note.set_script(note_script)
		note.global_position = global_position
		note.value = per_note
		get_parent().call_deferred("add_child", note)

	HuntAnalyzerData.record_kill(monster_id, xp_reward)
	GameState.on_monster_killed(monster_id, xp_reward, is_boss)
	killed.emit(monster_id)

	queue_free()

func _spawn_death_particles():
	if not get_parent():
		return
	var p = CPUParticles2D.new()
	p.global_position = global_position
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = 36 if is_boss else 18
	p.lifetime = 0.55 if is_boss else 0.38
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 45.0
	p.initial_velocity_max = 140.0 if is_boss else 95.0
	p.damping_min = 120.0
	p.damping_max = 180.0
	p.scale_amount_min = 3.5
	p.scale_amount_max = 7.5 if is_boss else 5.5
	p.color = data.get("color", Color("#FF5533")).lightened(0.25)
	get_parent().add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
