extends CharacterBody2D

## Controlador de Daniel Ragnar: combate corpo a corpo, magias, dash, coleta e Auto-Hunt.

signal attack_performed

@export var speed: float = 215.0

# Parâmetros de Física Responsiva, Dash e Input Buffering
const ACCELERATION: float = 2200.0
const FRICTION: float = 1900.0
const DASH_SPEED: float = 540.0
const DASH_DURATION: float = 0.16
const DASH_COOLDOWN: float = 0.85
const INPUT_BUFFER_TIME: float = 0.16

var current_direction: String = "south"
var attack_cooldown_timer: float = 0.0
var attack_buffer_timer: float = 0.0
var buffered_spell: String = ""
var spell_buffer_timer: float = 0.0
var eat_cooldown_timer: float = 0.0
var post_modal_guard_timer: float = 0.0
var _mouse_attack_held: bool = false
var _virtual_move_vec: Vector2 = Vector2.ZERO
var _virtual_attack_held: bool = false

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.DOWN
var ghost_trail_timer: float = 0.0

var sprite_container: Node2D
var sprite: Sprite2D
var weapon_pivot: Node2D
var weapon_glow: Sprite2D
var weapon_sprite: Sprite2D
var weapon_aura_particles: CPUParticles2D
var footstep_particles: CPUParticles2D
var attack_area: Area2D
var attack_slash_visual: Line2D
var attack_slash_inner: Line2D
var attack_sparkles: Node2D
var current_target: Node2D = null

# Variáveis para Animação de Frames do PixelLab + Procedural
var anim_time: float = 0.0
var walk_frame_index: int = 0
var walk_frame_timer: float = 0.0
const FRAME_DURATION: float = 0.11 # Velocidade de troca dos frames do PixelLab (6 frames)
const ATTACK_ANIM_DURATION: float = 0.24

var attack_lunge_offset: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var _weapon_ghost_step: int = 0
var spell_voice_cooldown: float = 0.0

class ShockwaveBurst extends Node2D:
	var progress: float = 0.0
	var duration: float = 0.26
	var max_radius: float = 48.0
	var ring_color: Color = Color.WHITE
	var accent_color: Color = Color.WHITE
	var crystalline: bool = false

	func _process(delta: float):
		progress += delta / max(0.05, duration)
		if progress >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw():
		var t = clamp(progress, 0.0, 1.0)
		var ease_t = 1.0 - pow(1.0 - t, 2.2)
		var r = lerp(10.0, max_radius, ease_t)
		var alpha = 1.0 - t
		var outer = Color(ring_color.r, ring_color.g, ring_color.b, alpha * 0.85)
		var inner = Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.95)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, outer, 3.5 * (1.0 - t * 0.5))
		if crystalline:
			draw_arc(Vector2.ZERO, r * 0.65, 0.0, TAU, 6, inner, 2.0)
		else:
			draw_arc(Vector2.ZERO, r * 0.68, 0.0, TAU, 20, inner, 1.8)

# Navegação Tibia / Idle (Click-to-Walk + Patrulha A* entre Hunt Spots)
var click_destination: Vector2 = Vector2.ZERO
var has_click_destination: bool = false
var nav_path: PackedVector2Array = PackedVector2Array()
var nav_target_cached: Vector2 = Vector2.ZERO
var nav_recalc_timer: float = 0.0
var patrol_spot_index: int = 0
var click_marker: Node2D = null
var _target_reeval_timer: float = 0.0
var _stuck_timer: float = 0.0
var _stuck_anchor_pos: Vector2 = Vector2.ZERO
var _stuck_strikes: int = 0
var _evade_sign: float = 1.0
var _ignored_targets: Dictionary = {}
var _spot_patrol_timer: float = 0.0

class ClickDestMarker extends Node2D:
	var pulse: float = 0.0
	func _process(delta: float):
		pulse += delta * 5.0
		queue_redraw()
	func _draw():
		var r = 13.0 + sin(pulse) * 3.0
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(0.25, 0.95, 0.72, 0.90), 2.2)
		draw_rect(Rect2(Vector2(-10, -10), Vector2(20, 20)), Color(1.0, 0.90, 0.45, 0.55), false, 1.5)
		draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0.25, 0.95, 0.72, 0.85), 1.5)
		draw_line(Vector2(0, -6), Vector2(0, 6), Color(0.25, 0.95, 0.72, 0.85), 1.5)

func _ready():
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 1
	_stuck_anchor_pos = global_position
	
	sprite_container = Node2D.new()
	add_child(sprite_container)

	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	update_direction_sprite("south")
	sprite_container.add_child(sprite)

	weapon_pivot = Node2D.new()
	weapon_pivot.z_index = 2
	sprite_container.add_child(weapon_pivot)

	weapon_aura_particles = CPUParticles2D.new()
	weapon_aura_particles.emitting = false
	weapon_aura_particles.amount = 8
	weapon_aura_particles.lifetime = 0.55
	weapon_aura_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	weapon_aura_particles.emission_sphere_radius = 9.0
	weapon_aura_particles.direction = Vector2(0, -1)
	weapon_aura_particles.spread = 180.0
	weapon_aura_particles.gravity = Vector2(0, -18)
	weapon_aura_particles.initial_velocity_min = 6.0
	weapon_aura_particles.initial_velocity_max = 18.0
	weapon_aura_particles.scale_amount_min = 2.0
	weapon_aura_particles.scale_amount_max = 3.8
	weapon_pivot.add_child(weapon_aura_particles)

	weapon_glow = Sprite2D.new()
	weapon_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_glow.scale = Vector2(1.22, 1.22)
	weapon_glow.visible = false
	weapon_pivot.add_child(weapon_glow)

	weapon_sprite = Sprite2D.new()
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_pivot.add_child(weapon_sprite)
	_refresh_equipped_weapon_visuals()

	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	col.shape = circle
	col.position = Vector2(0, 10)
	add_child(col)

	attack_area = Area2D.new()
	attack_area.collision_mask = 3
	var a_col = CollisionShape2D.new()
	var a_circle = CircleShape2D.new()
	a_circle.radius = 52.0
	a_col.shape = a_circle
	attack_area.add_child(a_col)
	attack_area.position = Vector2(0, 24)
	add_child(attack_area)

	attack_slash_visual = Line2D.new()
	attack_slash_visual.width = 6.0
	attack_slash_visual.joint_mode = Line2D.LINE_JOINT_ROUND
	attack_slash_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	attack_slash_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	attack_slash_visual.visible = false
	add_child(attack_slash_visual)

	attack_slash_inner = Line2D.new()
	attack_slash_inner.width = 2.5
	attack_slash_inner.joint_mode = Line2D.LINE_JOINT_ROUND
	attack_slash_inner.begin_cap_mode = Line2D.LINE_CAP_ROUND
	attack_slash_inner.end_cap_mode = Line2D.LINE_CAP_ROUND
	attack_slash_inner.visible = false
	add_child(attack_slash_inner)

	attack_sparkles = Node2D.new()
	add_child(attack_sparkles)

	# Emissor de Poeira de Passos (Footstep Dust)
	footstep_particles = CPUParticles2D.new()
	footstep_particles.z_index = -1
	footstep_particles.position = Vector2(0, 22)
	footstep_particles.emitting = false
	footstep_particles.amount = 10
	footstep_particles.lifetime = 0.35
	footstep_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	footstep_particles.emission_sphere_radius = 6.0
	footstep_particles.direction = Vector2(0, -1)
	footstep_particles.spread = 65.0
	footstep_particles.gravity = Vector2.ZERO
	footstep_particles.initial_velocity_min = 10.0
	footstep_particles.initial_velocity_max = 26.0
	footstep_particles.scale_amount_min = 2.5
	footstep_particles.scale_amount_max = 4.5
	footstep_particles.color = Color(0.82, 0.76, 0.65, 0.55)
	add_child(footstep_particles)

	GameState.player_damaged.connect(_on_player_damaged)
	GameState.player_healed.connect(_on_player_healed)
	GameState.leveled_up.connect(_on_leveled_up)
	GameState.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed():
	update_direction_sprite(current_direction)
	_refresh_equipped_weapon_visuals()

func _refresh_equipped_weapon_visuals():
	if not is_instance_valid(weapon_sprite):
		return
	var weapon = GameData.WEAPONS.get(GameState.equipped_weapon, GameData.WEAPONS["sword_wood"])
	var rarity = GameData.get_rarity(int(weapon.get("tier", 1)))
	var tex = SpriteFactory.get_item_icon(GameState.equipped_weapon)
	weapon_sprite.texture = tex
	weapon_glow.texture = tex

	# Alinha o cabo da arma exatamente na origem (0,0) do pivot na mão do personagem
	var grip_offset = Vector2(-9, 9) if weapon.type == "sword" else Vector2(-8, -8)
	var base_scale = Vector2(0.76, 0.76) if weapon.type == "sword" else Vector2(0.82, 0.82)
	weapon_sprite.offset = grip_offset
	weapon_sprite.scale = base_scale
	weapon_glow.offset = grip_offset
	weapon_glow.scale = base_scale * 1.24

	var tip_local = Vector2(-14, 14) * base_scale.x if weapon.type == "sword" else Vector2(-11, -11) * base_scale.x
	weapon_aura_particles.position = tip_local

	var aura_amt = int(rarity.get("aura_amount", 0))
	if aura_amt > 0:
		weapon_glow.visible = true
		var glow_alpha = 0.28 if weapon.tier == 2 else (0.45 if weapon.tier == 3 else 0.65)
		weapon_glow.modulate = Color(rarity.color.r, rarity.color.g, rarity.color.b, glow_alpha)
		weapon_aura_particles.amount = aura_amt
		weapon_aura_particles.color = rarity.accent
		weapon_aura_particles.emitting = true
	else:
		weapon_glow.visible = false
		weapon_aura_particles.emitting = false

func _get_sprite_character_id() -> String:
	var armor_id = GameState.equipped_armor
	if armor_id != "" and armor_id != "none":
		return "daniel_" + armor_id
	return "daniel_ragnar"

func _on_leveled_up(new_level: int):
	if not is_inside_tree():
		return
	AudioManager.play_voice("daniel_levelup")
	GameState.trigger_shake(6.0, 0.22)

	var lvl_p = CPUParticles2D.new()
	lvl_p.position = Vector2(0, 6)
	lvl_p.one_shot = true
	lvl_p.explosiveness = 0.90
	lvl_p.amount = 24
	lvl_p.lifetime = 0.70
	lvl_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	lvl_p.emission_sphere_radius = 22.0
	lvl_p.direction = Vector2(0, -1)
	lvl_p.spread = 180.0
	lvl_p.gravity = Vector2(0, -55)
	lvl_p.initial_velocity_min = 35.0
	lvl_p.initial_velocity_max = 80.0
	lvl_p.scale_amount_min = 3.0
	lvl_p.scale_amount_max = 5.5
	lvl_p.color = Color("#FFD700")
	add_child(lvl_p)
	lvl_p.emitting = true
	lvl_p.finished.connect(lvl_p.queue_free)

	FloatingText.spawn(get_parent(), global_position + Vector2(0, -36), "LEVEL UP! Nv. " + str(new_level), Color("#FFD700"), true)

func _on_player_healed(amount: int):
	if not is_inside_tree():
		return
	var heal_p = CPUParticles2D.new()
	heal_p.position = Vector2(0, 8)
	heal_p.one_shot = true
	heal_p.explosiveness = 0.80
	heal_p.amount = 14
	heal_p.lifetime = 0.55
	heal_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	heal_p.emission_sphere_radius = 18.0
	heal_p.direction = Vector2(0, -1)
	heal_p.spread = 35.0
	heal_p.gravity = Vector2(0, -45)
	heal_p.initial_velocity_min = 22.0
	heal_p.initial_velocity_max = 45.0
	heal_p.scale_amount_min = 3.0
	heal_p.scale_amount_max = 5.0
	heal_p.color = Color("#4CFF4C")
	add_child(heal_p)
	heal_p.emitting = true
	heal_p.finished.connect(heal_p.queue_free)

	FloatingText.spawn(get_parent(), global_position + Vector2(0, -28), "+" + str(amount) + " HP", Color("#4CFF4C"), false)

func _on_player_damaged(amount: int):
	if not is_inside_tree():
		return
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2.4, 0.35, 0.35, 1.0), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.10)

	FloatingText.spawn(get_parent(), global_position + Vector2(randf_range(-10, 10), -28), "-" + str(amount) + " HP", Color("#FF3B3B"), false)

func on_modal_opened():
	attack_buffer_timer = 0.0
	spell_buffer_timer = 0.0
	buffered_spell = ""
	_mouse_attack_held = false
	_virtual_attack_held = false
	_virtual_move_vec = Vector2.ZERO
	velocity = Vector2.ZERO
	_reset_stuck_tracker()

func on_modal_closed():
	attack_buffer_timer = 0.0
	spell_buffer_timer = 0.0
	buffered_spell = ""
	_mouse_attack_held = false
	_virtual_attack_held = false
	_virtual_move_vec = Vector2.ZERO
	post_modal_guard_timer = 0.22
	_reset_stuck_tracker()

## Define o vetor do joystick virtual (mobile/tablet).
func set_virtual_move_input(vec: Vector2):
	_virtual_move_vec = vec.limit_length(1.0)

## Controla o estado pressionado do botão virtual de ataque.
func set_virtual_attack_held(held: bool):
	_virtual_attack_held = held
	if held and not _is_modal_blocking() and not GameState.auto_hunt_enabled:
		if is_instance_valid(current_target):
			var aim_dir := current_target.global_position - global_position
			if aim_dir.length() > 4.0:
				_update_direction_from_vector(aim_dir.normalized())
		attack_buffer_timer = INPUT_BUFFER_TIME

## Aciona o dash tático a partir dos controles touch.
func trigger_virtual_dash():
	if _is_modal_blocking() or GameState.auto_hunt_enabled:
		return
	if dash_cooldown_timer <= 0.0:
		_trigger_dash(_virtual_move_vec)

## Conjura uma magia diretamente pela barra de interface (clique/toque).
func cast_spell_from_ui(spell_id: String):
	if _is_modal_blocking():
		return
	if is_instance_valid(current_target):
		var aim_dir := current_target.global_position - global_position
		if aim_dir.length() > 4.0:
			_update_direction_from_vector(aim_dir.normalized())
	buffered_spell = spell_id
	spell_buffer_timer = INPUT_BUFFER_TIME

## Usa comida inteligente a partir dos controles touch/HUD.
func eat_food_from_ui():
	if _is_modal_blocking():
		return
	if eat_cooldown_timer <= 0.0 and GameState.eat_food():
		eat_cooldown_timer = 0.30

func _is_modal_blocking() -> bool:
	if get_tree().paused:
		return true
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("has_open_modal") and main_node.has_open_modal():
		return true
	return false

func _unhandled_input(event):
	if _is_modal_blocking() or post_modal_guard_timer > 0.0:
		_mouse_attack_held = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not GameState.auto_hunt_enabled:
				var aim_dir := get_global_mouse_position() - global_position
				if aim_dir.length() > 4.0:
					_update_direction_from_vector(aim_dir.normalized())
				_mouse_attack_held = true
				attack_buffer_timer = INPUT_BUFFER_TIME
		else:
			_mouse_attack_held = false

func _physics_process(delta: float):
	if post_modal_guard_timer > 0.0:
		post_modal_guard_timer = max(0.0, post_modal_guard_timer - delta)
	if _is_modal_blocking():
		velocity = Vector2.ZERO
		_mouse_attack_held = false
		return
	anim_time += delta

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if attack_buffer_timer > 0.0:
		attack_buffer_timer -= delta
	if spell_buffer_timer > 0.0:
		spell_buffer_timer -= delta
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if eat_cooldown_timer > 0.0:
		eat_cooldown_timer -= delta
	if spell_voice_cooldown > 0.0:
		spell_voice_cooldown -= delta
	if nav_recalc_timer > 0.0:
		nav_recalc_timer -= delta
	if _target_reeval_timer > 0.0:
		_target_reeval_timer -= delta
	_spot_patrol_timer += delta

	# Execução de Dash Tático com Ghost Trail
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		ghost_trail_timer -= delta
		if ghost_trail_timer <= 0.0:
			ghost_trail_timer = 0.04
			_spawn_dash_ghost()
	else:
		if GameState.auto_hunt_enabled:
			_process_auto_hunt(delta)
		else:
			_process_manual_input(delta)

	# Disparo de Ataque via Input Buffering assim que o cooldown zera
	if attack_buffer_timer > 0.0 and attack_cooldown_timer <= 0.0:
		attack_buffer_timer = 0.0
		perform_attack()

	# Disparo de Magia via Input Buffering assim que o cooldown zera
	if spell_buffer_timer > 0.0 and buffered_spell != "":
		if GameState.spell_cooldowns.get(buffered_spell, 0.0) <= 0.0:
			var s_to_cast = buffered_spell
			buffered_spell = ""
			spell_buffer_timer = 0.0
			_cast_spell(s_to_cast)

	move_and_slide()
	var te_bounds = _get_tile_engine()
	var max_w: float = te_bounds.map_width if te_bounds else 2048.0
	var max_h: float = te_bounds.map_height if te_bounds else 1152.0
	global_position.x = clamp(global_position.x, 45.0, max_w - 45.0)
	global_position.y = clamp(global_position.y, 45.0, max_h - 45.0)

	_update_animation(delta)

func _process_manual_input(delta: float):
	var move_input = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_input.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_input.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_input.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_input.y -= 1
	if move_input == Vector2.ZERO and _virtual_move_vec.length() > 0.14:
		move_input = _virtual_move_vec

	if move_input != Vector2.ZERO:
		clear_click_destination()
		move_input = move_input.normalized()
		velocity = velocity.move_toward(move_input * speed, ACCELERATION * delta)
		_update_direction_from_vector(move_input)
	elif has_click_destination:
		if _steer_toward(click_destination, delta, 16.0):
			clear_click_destination()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	# Mantém o alvo Tibia destacado no inimigo mais próximo em alcance de combate
	if not is_instance_valid(current_target) or not current_target.is_in_group("monsters") or global_position.distance_to(current_target.global_position) > 220.0:
		var cand = _find_nearest_monster()
		current_target = cand if (is_instance_valid(cand) and global_position.distance_to(cand.global_position) <= 190.0) else null

	# Dash Tático (Tecla Shift)
	if Input.is_key_pressed(KEY_SHIFT) and dash_cooldown_timer <= 0.0:
		_trigger_dash(move_input)

	# Input Buffering para Ataque Básico (clique esquerdo só conta via _unhandled_input no chão do jogo)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or post_modal_guard_timer > 0.0:
		_mouse_attack_held = false
	if _virtual_attack_held and is_instance_valid(current_target):
		var aim_v := current_target.global_position - global_position
		if aim_v.length() > 4.0:
			_update_direction_from_vector(aim_v.normalized())
	if Input.is_key_pressed(KEY_SPACE) or _mouse_attack_held or _virtual_attack_held:
		attack_buffer_timer = INPUT_BUFFER_TIME

	# Input Buffering para Magias Elementais
	if Input.is_key_pressed(KEY_1):
		buffered_spell = "fireball"
		spell_buffer_timer = INPUT_BUFFER_TIME
	elif Input.is_key_pressed(KEY_2):
		buffered_spell = "tornado"
		spell_buffer_timer = INPUT_BUFFER_TIME
	elif Input.is_key_pressed(KEY_3):
		buffered_spell = "water_bomb"
		spell_buffer_timer = INPUT_BUFFER_TIME

	if Input.is_key_pressed(KEY_Q) and eat_cooldown_timer <= 0.0:
		if GameState.eat_food():
			eat_cooldown_timer = 0.30

func _trigger_dash(input_vec: Vector2):
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	ghost_trail_timer = 0.0
	if input_vec != Vector2.ZERO:
		dash_direction = input_vec.normalized()
	else:
		match current_direction:
			"south": dash_direction = Vector2.DOWN
			"north": dash_direction = Vector2.UP
			"east": dash_direction = Vector2.RIGHT
			"west": dash_direction = Vector2.LEFT

func _spawn_dash_ghost():
	if not get_parent() or not sprite.texture:
		return
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.modulate = Color(0.6, 0.85, 1.0, 0.55)
	get_parent().add_child(ghost)
	var tw = create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.16)
	tw.tween_callback(ghost.queue_free)

func _process_auto_hunt(delta: float):
	if float(GameState.current_hp) / float(GameState.max_hp) < 0.50 and eat_cooldown_timer <= 0.0:
		if GameState.eat_food():
			eat_cooldown_timer = 0.40

	# Defesa oportunista imediata: se um monstro colou ao alcance e há linha limpa, foca nele
	var immediate_threat = _find_nearest_melee_monster(62.0)
	if is_instance_valid(immediate_threat):
		current_target = immediate_threat

	# Se o jogador clicou num ponto de destino (mapa/chão), navega até lá (a menos que um monstro esteja colado)
	if has_click_destination:
		var near_threat = _find_best_hunt_target()
		if not is_instance_valid(near_threat) or global_position.distance_to(near_threat.global_position) > 130.0:
			if _steer_toward(click_destination, delta, 20.0):
				clear_click_destination()
			else:
				_update_stuck_recovery(delta, true, null)
			return
		else:
			clear_click_destination()

	if not is_instance_valid(current_target) or not current_target.is_in_group("monsters") or current_target.current_hp <= 0:
		current_target = _find_best_hunt_target()
		_target_reeval_timer = 0.65
	elif _target_reeval_timer <= 0.0:
		_target_reeval_timer = 0.65
		var better = _find_best_hunt_target()
		if is_instance_valid(better) and better != current_target:
			var cur_d = global_position.distance_to(current_target.global_position)
			var new_d = global_position.distance_to(better.global_position)
			if new_d + 45.0 < cur_d:
				current_target = better

	if is_instance_valid(current_target):
		_spot_patrol_timer = 0.0
		var diff = current_target.global_position - global_position
		var dist = diff.length()
		var dir = diff.normalized() if diff != Vector2.ZERO else Vector2.DOWN
		var has_los = _has_line_of_sight(current_target.global_position)

		if dist <= 54.0 and has_los:
			_update_direction_from_vector(dir)
			_reset_stuck_tracker()
			if dist < 16.0:
				var back_dir = -dir
				if not test_move(global_transform, back_dir * 8.0):
					velocity = velocity.move_toward(back_dir * (speed * 0.45), ACCELERATION * delta)
				else:
					velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			if attack_cooldown_timer <= 0.0:
				perform_attack()
		else:
			if _steer_toward(current_target.global_position, delta, 38.0 if has_los else 14.0):
				_reset_stuck_tracker()
			else:
				_update_stuck_recovery(delta, true, current_target)

		if dist <= 265.0 and has_los:
			_update_direction_from_vector(dir)
			for s in ["fireball", "tornado", "water_bomb"]:
				if GameState.unlocked_spells.get(s, false) and GameState.spell_cooldowns.get(s, 0.0) <= 0.0:
					_cast_spell(s)
					break
		return

	# Sem monstros no alcance imediato: coleta cédulas alcançáveis ou patrulha os Hunt Spots
	var nearest_note: Node2D = _find_nearest_cash_note(260.0)
	if is_instance_valid(nearest_note):
		if _steer_toward(nearest_note.global_position, delta, 14.0):
			_reset_stuck_tracker()
		else:
			_update_stuck_recovery(delta, true, nearest_note)
		return

	var te = _get_tile_engine()
	if te and not te.hunt_spots.is_empty():
		var spots: Array = te.hunt_spots
		var target_spot: Dictionary = spots[patrol_spot_index % spots.size()]
		var spot_pos: Vector2 = target_spot.get("pos", global_position)
		if _steer_toward(spot_pos, delta, 65.0) or _spot_patrol_timer > 12.0:
			patrol_spot_index = (patrol_spot_index + 1) % spots.size()
			_spot_patrol_timer = 0.0
			_reset_stuck_tracker()
		else:
			_update_stuck_recovery(delta, true, null)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		_reset_stuck_tracker()

func _get_tile_engine():
	var main_node = get_tree().current_scene
	if main_node and "tile_engine" in main_node:
		return main_node.tile_engine
	return null

func _get_feet_pos() -> Vector2:
	return global_position + Vector2(0, 8)

func _has_line_of_sight(target_world_pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	if space == null:
		return true
	var params = PhysicsRayQueryParameters2D.create(_get_feet_pos(), target_world_pos, 1, [get_rid()])
	var hit = space.intersect_ray(params)
	return hit.is_empty()

func _reset_stuck_tracker():
	_stuck_timer = 0.0
	_stuck_strikes = 0
	_stuck_anchor_pos = global_position

func _update_stuck_recovery(delta: float, is_trying_to_move: bool, active_node: Node2D):
	if not is_trying_to_move:
		_reset_stuck_tracker()
		return
	_stuck_timer += delta
	if _stuck_timer < 0.45:
		return
	var moved = global_position.distance_to(_stuck_anchor_pos)
	_stuck_anchor_pos = global_position
	_stuck_timer = 0.0
	if moved >= 14.0:
		_stuck_strikes = 0
		return

	_stuck_strikes += 1
	_evade_sign = -_evade_sign
	nav_path = PackedVector2Array()
	nav_recalc_timer = 0.0

	if _stuck_strikes == 1 and dash_cooldown_timer <= 0.0:
		var base_dir = velocity.normalized() if velocity.length() > 5.0 else Vector2.RIGHT
		var dash_dir = _pick_clear_steering_dir(base_dir.rotated(deg_to_rad(55.0 * _evade_sign)))
		if dash_dir != Vector2.ZERO and not test_move(global_transform, dash_dir * 26.0):
			_trigger_dash(dash_dir)
			return

	if _stuck_strikes >= 2:
		if is_instance_valid(active_node):
			_ignored_targets[active_node.get_instance_id()] = anim_time + 4.0
			if active_node == current_target:
				current_target = null
		else:
			var te = _get_tile_engine()
			if te and not te.hunt_spots.is_empty():
				patrol_spot_index = (patrol_spot_index + 1) % te.hunt_spots.size()
				_spot_patrol_timer = 0.0

	if _stuck_strikes >= 3:
		var te = _get_tile_engine()
		if te:
			var safe_c = te.find_nearest_walkable_cell(te.world_to_cell(_get_feet_pos()))
			var safe_p = Vector2(safe_c.x * 32.0 + 16.0, safe_c.y * 32.0 + 16.0)
			var nudge = (safe_p - _get_feet_pos())
			if nudge.length() > 4.0:
				var step = nudge.normalized() * min(18.0, nudge.length())
				if not test_move(global_transform, step):
					global_position += step
		_stuck_strikes = 1

func set_click_destination(world_pos: Vector2):
	var te = _get_tile_engine()
	var max_w: float = te.map_width if te else 2048.0
	var max_h: float = te.map_height if te else 1152.0
	var dest = Vector2(clamp(world_pos.x, 64.0, max_w - 64.0), clamp(world_pos.y, 64.0, max_h - 64.0))
	if te:
		var safe_cell = te.find_nearest_walkable_cell(te.world_to_cell(dest))
		if not te.is_world_pos_walkable(dest) or te.astar.is_point_solid(te.world_to_cell(dest)):
			dest = Vector2(safe_cell.x * 32.0 + 16.0, safe_cell.y * 32.0 + 16.0)
	click_destination = dest
	has_click_destination = true
	nav_path = PackedVector2Array()
	nav_recalc_timer = 0.0
	_reset_stuck_tracker()

	if not is_instance_valid(click_marker) and get_parent():
		click_marker = ClickDestMarker.new()
		click_marker.z_index = -2
		get_parent().add_child(click_marker)
	if is_instance_valid(click_marker):
		click_marker.global_position = dest
		click_marker.visible = true

func clear_click_destination():
	has_click_destination = false
	nav_path = PackedVector2Array()
	if is_instance_valid(click_marker):
		click_marker.visible = false

func _steer_toward(target_pos: Vector2, delta: float, stop_dist: float) -> bool:
	var feet = _get_feet_pos()
	var direct_dist = global_position.distance_to(target_pos)
	if direct_dist <= stop_dist:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		return true

	var te = _get_tile_engine()
	if te:
		if nav_path.is_empty() or nav_recalc_timer <= 0.0 or nav_target_cached.distance_to(target_pos) > 48.0:
			nav_path = te.find_world_path(feet, target_pos)
			nav_target_cached = target_pos
			nav_recalc_timer = 0.25

		while nav_path.size() > 1 and feet.distance_to(nav_path[0]) < 22.0:
			nav_path.remove_at(0)

		# Atalho direto se o próximo waypoint depois do atual estiver livre de paredes/rios
		while nav_path.size() > 1 and _has_line_of_sight(nav_path[1]):
			var shortcut_dir = (nav_path[1] - feet).normalized()
			if not test_move(global_transform, shortcut_dir * 32.0):
				nav_path.remove_at(0)
			else:
				break

	var next_wp = nav_path[0] if not nav_path.is_empty() else target_pos
	var diff = next_wp - feet
	if diff.length() < 6.0:
		if nav_path.size() > 1:
			nav_path.remove_at(0)
			next_wp = nav_path[0]
			diff = next_wp - feet
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			return true

	var raw_dir = diff.normalized()
	var steer_dir = _pick_clear_steering_dir(raw_dir)
	_update_direction_from_vector(steer_dir)
	velocity = velocity.move_toward(steer_dir * speed, ACCELERATION * delta)
	return false

func _pick_clear_steering_dir(desired_dir: Vector2) -> Vector2:
	if desired_dir == Vector2.ZERO:
		return Vector2.ZERO
	if not test_move(global_transform, desired_dir * 16.0):
		return desired_dir
	for deg in [28.0, -28.0, 56.0, -56.0, 84.0, -84.0, 115.0, -115.0]:
		var cand = desired_dir.rotated(deg_to_rad(deg * _evade_sign))
		if not test_move(global_transform, cand * 18.0):
			return cand
	return desired_dir

func _purge_expired_ignores():
	for k in _ignored_targets.keys():
		if float(_ignored_targets[k]) <= anim_time:
			_ignored_targets.erase(k)

func _find_nearest_cash_note(max_dist: float) -> Node2D:
	_purge_expired_ignores()
	var te = _get_tile_engine()
	var feet = _get_feet_pos()
	var best: Node2D = null
	var best_d: float = max_dist
	for note in get_tree().get_nodes_in_group("cash_notes"):
		if is_instance_valid(note) and not _ignored_targets.has(note.get_instance_id()):
			var d = global_position.distance_to(note.global_position)
			if d < best_d:
				if te and not te.is_reachable(feet, note.global_position):
					continue
				best_d = d
				best = note
	return best

func _find_nearest_melee_monster(max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d: float = max_dist
	for m in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(m) and m.current_hp > 0:
			var d = global_position.distance_to(m.global_position)
			if d < best_d and _has_line_of_sight(m.global_position):
				best_d = d
				best = m
	return best

func _find_best_hunt_target() -> Node2D:
	_purge_expired_ignores()
	var te = _get_tile_engine()
	var feet = _get_feet_pos()
	var best: Node2D = null
	var best_score: float = INF

	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.current_hp <= 0:
			continue
		if _ignored_targets.has(m.get_instance_id()):
			continue
		var direct_d = global_position.distance_to(m.global_position)
		if te and not te.is_reachable(feet, m.global_position):
			continue
		var score = direct_d
		if direct_d > 140.0 and te:
			score = te.get_path_cost(feet, m.global_position)
			if score == INF:
				continue
		if direct_d < 85.0:
			score -= 55.0
		if m.max_hp > 0 and float(m.current_hp) / float(m.max_hp) < 0.40:
			score -= 30.0
		if _has_line_of_sight(m.global_position):
			score -= 20.0
		if score < best_score:
			best_score = score
			best = m
	return best

func _find_nearest_monster() -> Node2D:
	var monsters = get_tree().get_nodes_in_group("monsters")
	var nearest = null
	var min_dist = 99999.0
	for m in monsters:
		if is_instance_valid(m) and m.current_hp > 0:
			var d = global_position.distance_to(m.global_position)
			if d < min_dist:
				min_dist = d
				nearest = m
	return nearest

func _update_direction_from_vector(vec: Vector2):
	var new_dir = current_direction
	if abs(vec.x) > abs(vec.y):
		new_dir = "east" if vec.x > 0 else "west"
	else:
		new_dir = "south" if vec.y > 0 else "north"

	if new_dir != current_direction:
		current_direction = new_dir
		walk_frame_index = 0
		update_direction_sprite(current_direction)

func update_direction_sprite(dir: String):
	sprite.texture = SpriteFactory.get_character_texture(_get_sprite_character_id(), dir)
	if attack_area:
		match dir:
			"south": attack_area.position = Vector2(0, 32)
			"north": attack_area.position = Vector2(0, -32)
			"east": attack_area.position = Vector2(32, 0)
			"west": attack_area.position = Vector2(-32, 0)

# ========================================================
# 🎬 ANIMAÇÃO DE FRAMES REAIS DO PIXELLAB
# ========================================================
func _update_animation(delta: float):
	var char_id = _get_sprite_character_id()
	var is_moving = velocity.length() > 15.0
	if footstep_particles:
		footstep_particles.emitting = is_moving
	
	if is_attacking:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0.0:
			is_attacking = false

	# Posição e escala sempre neutras - sem distorções artificiais por código
	sprite_container.position = Vector2.ZERO
	sprite_container.scale = Vector2.ONE
	sprite_container.rotation = 0.0

	if is_attacking:
		var atk_frames = SpriteFactory.get_attack_animation_frames(char_id, current_direction)
		if atk_frames.size() > 1:
			var progress = clamp(1.0 - (attack_anim_timer / ATTACK_ANIM_DURATION), 0.0, 0.999)
			var frame_idx = int(progress * atk_frames.size())
			sprite.texture = atk_frames[frame_idx]
	elif is_moving:
		# Ciclo oficial de frames gerado pelo PixelLab por direção
		walk_frame_timer += delta
		var frames = SpriteFactory.get_walk_animation_frames(char_id, current_direction)
		if frames.size() > 1:
			if walk_frame_timer >= FRAME_DURATION:
				walk_frame_timer = 0.0
				walk_frame_index = (walk_frame_index + 1) % frames.size()
				sprite.texture = frames[walk_frame_index]
	else:
		# Parado (Idle): Usa pose estática da direção gerada pelo PixelLab
		sprite.texture = SpriteFactory.get_character_texture(char_id, current_direction)
		walk_frame_index = 0
		walk_frame_timer = 0.0

	_update_weapon_animation(is_moving)

func _update_weapon_animation(is_moving: bool):
	if not is_instance_valid(weapon_pivot):
		return
	var weapon = GameData.WEAPONS.get(GameState.equipped_weapon, GameData.WEAPONS["sword_wood"])
	var rarity = GameData.get_rarity(int(weapon.get("tier", 1)))

	# Pulso luminoso da aura para armas Incomuns, Raras e Lendárias
	if weapon_glow.visible:
		var base_a = 0.24 if weapon.tier == 2 else (0.42 if weapon.tier == 3 else 0.58)
		var pulse = 0.16 * sin(anim_time * (6.5 if weapon.tier >= 4 else 4.2))
		weapon_glow.modulate.a = clamp(base_a + pulse, 0.12, 0.88)

	var base_pos := Vector2(-13, 8)
	var rest_aim_deg := 125.0
	var face_deg := 90.0
	var rest_z := 2
	match current_direction:
		"south":
			base_pos = Vector2(-13, 8)
			rest_aim_deg = 128.0 if weapon.type == "sword" else 112.0
			face_deg = 90.0
			rest_z = 2
		"east":
			base_pos = Vector2(-2, 7)
			rest_aim_deg = 22.0 if weapon.type == "sword" else -28.0
			face_deg = 0.0
			rest_z = 2
		"west":
			base_pos = Vector2(2, 7)
			rest_aim_deg = 158.0 if weapon.type == "sword" else -152.0
			face_deg = 180.0
			rest_z = 2
		"north":
			base_pos = Vector2(12, 4)
			rest_aim_deg = -58.0
			face_deg = -90.0
			rest_z = -1

	var rot_offset_deg = -135.0 if weapon.type == "sword" else 135.0
	var aim_rad = deg_to_rad(rest_aim_deg)
	var hand_offset = Vector2.ZERO
	var swing_scale = 1.0

	if is_attacking:
		weapon_pivot.z_index = 2
		var p = clamp(1.0 - (attack_anim_timer / ATTACK_ANIM_DURATION), 0.0, 1.0)
		var face_rad = deg_to_rad(face_deg)
		if weapon.type == "sword":
			var eased = 1.0 - pow(1.0 - p, 2.1)
			aim_rad = face_rad + lerp(deg_to_rad(-82.0), deg_to_rad(82.0), eased)
			hand_offset = Vector2.from_angle(face_rad) * (sin(p * PI) * 8.0)
			swing_scale = 1.0 + sin(p * PI) * 0.24
		else:
			# Martelo: recuo rápido até 25% e esmagamento frontal com impacto
			if p < 0.25:
				var wu = p / 0.25
				aim_rad = face_rad + lerp(deg_to_rad(-25.0), deg_to_rad(-105.0), wu)
				hand_offset = Vector2.from_angle(face_rad) * (-3.0 * wu)
			else:
				var sm = clamp((p - 0.25) / 0.55, 0.0, 1.0)
				var sm_ease = 1.0 - pow(1.0 - sm, 2.5)
				aim_rad = face_rad + lerp(deg_to_rad(-105.0), deg_to_rad(32.0), sm_ease)
				hand_offset = Vector2.from_angle(face_rad) * (sin(sm * PI) * 11.0)
				swing_scale = 1.0 + sin(sm * PI) * 0.34

		# Rastro fantasma da arma para raridade Rara (Ouro) e Lendária (Diamante)
		if weapon.tier >= 3:
			var target_steps = 2 if weapon.tier == 3 else 3
			var cur_step = int(p * float(target_steps + 1))
			if cur_step > _weapon_ghost_step and _weapon_ghost_step < target_steps:
				_weapon_ghost_step = cur_step
				_spawn_weapon_afterimage(rarity.color)
	else:
		weapon_pivot.z_index = rest_z
		if is_moving:
			hand_offset.y = sin(anim_time * 18.0) * 1.9
			hand_offset.x = cos(anim_time * 9.0) * 0.9
			aim_rad += sin(anim_time * 9.0) * 0.14
		else:
			hand_offset.y = sin(anim_time * 3.2) * 0.9
			aim_rad += sin(anim_time * 2.4) * 0.04

	weapon_pivot.position = base_pos + hand_offset
	weapon_pivot.rotation = aim_rad + deg_to_rad(rot_offset_deg)
	weapon_pivot.scale = Vector2(swing_scale, swing_scale)

func _spawn_weapon_afterimage(tint: Color):
	if not get_parent() or not weapon_sprite.texture:
		return
	var ghost = Sprite2D.new()
	ghost.texture = weapon_sprite.texture
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.offset = weapon_sprite.offset
	ghost.scale = weapon_sprite.scale * weapon_pivot.scale
	ghost.global_position = weapon_pivot.global_position
	ghost.global_rotation = weapon_pivot.global_rotation
	ghost.z_index = weapon_pivot.z_index - 1
	ghost.modulate = Color(tint.r, tint.g, tint.b, 0.70)
	get_parent().add_child(ghost)
	var tw = create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tw.tween_callback(ghost.queue_free)

func perform_attack():
	var weapon = GameData.WEAPONS.get(GameState.equipped_weapon, GameData.WEAPONS["sword_wood"])
	attack_cooldown_timer = weapon.cooldown

	is_attacking = true
	attack_anim_timer = ATTACK_ANIM_DURATION
	_weapon_ghost_step = 0
	var lunge_dist = 14.0
	match current_direction:
		"south": attack_lunge_offset = Vector2(0, lunge_dist)
		"north": attack_lunge_offset = Vector2(0, -lunge_dist)
		"east": attack_lunge_offset = Vector2(lunge_dist, 0)
		"west": attack_lunge_offset = Vector2(-lunge_dist, 0)

	if weapon.type == "hammer":
		AudioManager.play_sfx("hammer_smash")
	else:
		AudioManager.play_sfx("sword_slash")

	_play_slash_effect(weapon)

	var bodies = attack_area.get_overlapping_bodies()
	var hit_any = false
	var hit_heavy = false
	for b in bodies:
		if b.is_in_group("monsters") and b != self:
			hit_any = true
			var is_crit = randf() < weapon.get("crit_rate", 0.0)
			if is_crit or weapon.type == "hammer":
				hit_heavy = true
			var dmg = weapon.damage * (2 if is_crit else 1)
			b.take_damage(dmg, is_crit, global_position)
			_spawn_hit_sparks(b.global_position, weapon.tier)
			if weapon.type == "hammer" and randf() < weapon.get("stun_chance", 0.0):
				b.apply_stun(1.2)

	if hit_heavy:
		GameState.trigger_shake(7.5, 0.18)
		GameState.trigger_hitstop(0.045)
	elif hit_any:
		GameState.trigger_shake(3.2, 0.10)

func _play_slash_effect(weapon: Dictionary):
	var rarity = GameData.get_rarity(int(weapon.get("tier", 1)))
	attack_slash_visual.clear_points()
	attack_slash_inner.clear_points()
	var base_pos = attack_area.position

	var points = PackedVector2Array()
	match current_direction:
		"south":
			points.append(base_pos + Vector2(-36, -8))
			points.append(base_pos + Vector2(-16, 18))
			points.append(base_pos + Vector2(16, 18))
			points.append(base_pos + Vector2(36, -8))
		"north":
			points.append(base_pos + Vector2(-36, 8))
			points.append(base_pos + Vector2(-16, -18))
			points.append(base_pos + Vector2(16, -18))
			points.append(base_pos + Vector2(36, 8))
		"east":
			points.append(base_pos + Vector2(-8, -36))
			points.append(base_pos + Vector2(18, -16))
			points.append(base_pos + Vector2(18, 16))
			points.append(base_pos + Vector2(-8, 36))
		"west":
			points.append(base_pos + Vector2(8, -36))
			points.append(base_pos + Vector2(-18, -16))
			points.append(base_pos + Vector2(-18, 16))
			points.append(base_pos + Vector2(8, 36))

	attack_slash_visual.points = points
	attack_slash_visual.default_color = rarity.color
	attack_slash_visual.width = float(rarity.slash_width) + (2.0 if weapon.type == "hammer" else 0.0)
	attack_slash_visual.visible = true
	attack_slash_visual.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(attack_slash_visual, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): attack_slash_visual.visible = false)

	if weapon.tier >= 2:
		attack_slash_inner.points = points
		attack_slash_inner.default_color = rarity.accent
		attack_slash_inner.width = max(2.2, float(rarity.slash_width) * 0.42)
		attack_slash_inner.visible = true
		attack_slash_inner.modulate.a = 1.0
		var tw_in = create_tween()
		tw_in.tween_property(attack_slash_inner, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_in.tween_callback(func(): attack_slash_inner.visible = false)

	_spawn_rarity_attack_burst(weapon, rarity, base_pos)

func _spawn_rarity_attack_burst(weapon: Dictionary, rarity: Dictionary, local_impact_pos: Vector2):
	var tier = int(weapon.get("tier", 1))
	# Partículas de corte por raridade (Incomum / Raro / Lendário)
	if tier >= 2 and get_parent():
		var burst = CPUParticles2D.new()
		burst.global_position = global_position + local_impact_pos
		burst.one_shot = true
		burst.explosiveness = 0.92
		burst.amount = 6 if tier == 2 else (12 if tier == 3 else 18)
		burst.lifetime = 0.28 if tier == 2 else (0.36 if tier == 3 else 0.44)
		burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		burst.emission_sphere_radius = 18.0
		burst.spread = 180.0
		burst.gravity = Vector2.ZERO
		burst.initial_velocity_min = 35.0
		burst.initial_velocity_max = 90.0 if tier < 4 else 135.0
		burst.scale_amount_min = 2.2
		burst.scale_amount_max = 4.0 if tier < 4 else 5.5
		burst.color = rarity.accent
		get_parent().add_child(burst)
		burst.emitting = true
		burst.finished.connect(burst.queue_free)

	# Onda de impacto para Martelos e para armas Raras/Lendárias
	if (weapon.type == "hammer" or tier >= 3) and get_parent():
		var wave = ShockwaveBurst.new()
		wave.global_position = global_position + local_impact_pos
		wave.max_radius = 36.0 + float(tier) * 9.0 + (10.0 if weapon.type == "hammer" else 0.0)
		wave.duration = 0.22 if tier < 4 else 0.30
		wave.ring_color = rarity.color
		wave.accent_color = rarity.accent
		wave.crystalline = (tier >= 4)
		get_parent().add_child(wave)

func _spawn_hit_sparks(hit_pos: Vector2, tier: int):
	var rarity = GameData.get_rarity(tier)
	var count = int(rarity.get("spark_count", 4))
	for i in range(count):
		var spark = Line2D.new()
		spark.width = 2.0 if tier < 3 else 2.8
		spark.default_color = rarity.accent if (i % 2 == 0 and tier >= 3) else rarity.color
		var ang = randf() * TAU
		var sp_dist = randf_range(10, 22 + tier * 4)
		spark.add_point(to_local(hit_pos))
		spark.add_point(to_local(hit_pos + Vector2(cos(ang), sin(ang)) * sp_dist))
		attack_sparkles.add_child(spark)

		var tw = create_tween()
		tw.tween_property(spark, "modulate:a", 0.0, 0.18)
		tw.tween_callback(spark.queue_free)

func _cast_spell(spell_id: String):
	if GameState.cast_spell(spell_id):
		AudioManager.play_spell_voice("daniel_" + spell_id)
		var proj_script = load("res://scripts/SpellProjectile.gd")
		var proj = Area2D.new()
		proj.set_script(proj_script)
		proj.global_position = global_position
		var dir = Vector2.DOWN
		match current_direction:
			"north": dir = Vector2.UP
			"south": dir = Vector2.DOWN
			"east": dir = Vector2.RIGHT
			"west": dir = Vector2.LEFT
		proj.setup(spell_id, dir)
		get_parent().add_child(proj)
