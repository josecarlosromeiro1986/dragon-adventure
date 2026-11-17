extends Node2D

## Controlador principal da cena: ciclo de mundos, câmera, modais, cutscenes e chefes.

@onready var world_container = $WorldContainer
@onready var entities_container = $EntitiesContainer
@onready var camera = $Camera2D
@onready var hud = $UI/HUD
@onready var shop_modal = $UI/ShopModal
@onready var map_modal = $UI/HuntsMapModal
@onready var dialogue_box = $UI/DialogueBox
@onready var victory_modal = $UI/VictoryModal
@onready var bestiary_modal = $UI/BestiaryModal
@onready var inventory_modal = $UI/InventoryModal
@onready var confirm_reset_dialog = $UI/ConfirmResetDialog
@onready var cutscene_modal = $UI/CutsceneModal
@onready var settings_modal = $UI/SettingsModal
@onready var ranking_modal = $UI/RankingModal
@onready var title_screen = $UI/TitleScreen

var player: CharacterBody2D
var spawn_timer: float = 0.0
var obstacle_positions: Array[Vector2] = []
var tile_engine: TibiaTileEngine = null
var previous_world_id: String = ""
var arrived_via_portal: bool = false
var hunt_spot_round_robin: int = 0
var touch_controls: TouchControls = null

# Sistema de Screen Shake e Hitstop
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var shake_max_duration: float = 0.1
var hitstop_active: bool = false

var map_width: float = 1792.0
var map_height: float = 1024.0

func _ready():
	get_tree().paused = false
	$UI.process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.world_changed.connect(_on_world_changed)
	GameState.player_died.connect(_on_player_died)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.game_reset.connect(_on_game_reset)
	GameState.screen_shake_requested.connect(_on_screen_shake)
	GameState.hitstop_requested.connect(_on_hitstop)

	hud.open_shop_requested.connect(func(): shop_modal.open())
	hud.open_map_requested.connect(func(): map_modal.open())
	hud.open_bestiary_requested.connect(func(): bestiary_modal.open())
	hud.open_inventory_requested.connect(func(): inventory_modal.open())
	hud.open_settings_requested.connect(func(): settings_modal.open())
	hud.open_ranking_requested.connect(func(): ranking_modal.open())
	hud.toggle_bestiary_requested.connect(_on_toggle_bestiary)
	hud.toggle_inventory_requested.connect(_on_toggle_inventory)
	hud.close_modals_requested.connect(_on_close_modals)
	hud.challenge_boss_requested.connect(_on_challenge_boss)
	hud.reset_game_requested.connect(func(): confirm_reset_dialog.popup_centered(Vector2i(420, 150)))
	settings_modal.rewatch_intro_requested.connect(func():
		title_screen.visible = false
		_sync_modal_pause()
		call_deferred("play_intro_cutscene")
	)
	title_screen.continue_requested.connect(_on_title_continue)
	title_screen.start_new_requested.connect(func(): confirm_reset_dialog.popup_centered(Vector2i(420, 150)))
	title_screen.settings_requested.connect(func(): settings_modal.open())
	title_screen.ranking_requested.connect(func(): ranking_modal.open())
	victory_modal.open_ranking_requested.connect(func(cat: String):
		victory_modal.hide()
		ranking_modal.open(cat)
	)
	confirm_reset_dialog.confirmed.connect(func():
		confirm_reset_dialog.hide()
		title_screen.visible = false
		_sync_modal_pause()
		GameState.reset_save()
	)
	confirm_reset_dialog.canceled.connect(_sync_modal_pause)
	confirm_reset_dialog.theme = MedievalUI.build_medieval_theme()
	MedievalUI.style_button(confirm_reset_dialog.get_ok_button(), "crimson", "", 12, 28)
	MedievalUI.style_button(confirm_reset_dialog.get_cancel_button(), "stone", "", 12, 28)
	_setup_modal_pause_hooks()

	touch_controls = TouchControls.new()
	$UI.add_child(touch_controls)
	$UI.move_child(touch_controls, hud.get_index() + 1)

	# Configura câmera suave com limites do mapa (com margem para HUD direito/superior/inferior)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = -56
	camera.limit_right = int(map_width) + 256
	camera.limit_bottom = int(map_height) + 64

	build_world(GameState.current_world)
	title_screen.refresh_state()
	title_screen.visible = true
	_sync_modal_pause()

func _on_title_continue():
	_sync_modal_pause()
	if not GameState.intro_cutscene_seen:
		call_deferred("play_intro_cutscene")

func _get_all_modals() -> Array:
	return [shop_modal, map_modal, dialogue_box, victory_modal, bestiary_modal, inventory_modal, confirm_reset_dialog, cutscene_modal, settings_modal, ranking_modal, title_screen]

func has_open_modal() -> bool:
	for m in _get_all_modals():
		if is_instance_valid(m) and m.visible:
			return true
	return false

func _setup_modal_pause_hooks():
	for m in _get_all_modals():
		if is_instance_valid(m):
			m.visibility_changed.connect(_sync_modal_pause)
	for m in [shop_modal, map_modal, bestiary_modal, inventory_modal, settings_modal, ranking_modal]:
		if is_instance_valid(m):
			m.window_input.connect(func(ev):
				if ev is InputEventKey and ev.pressed and not ev.echo:
					if ev.keycode == KEY_ESCAPE:
						m.hide()
						m.set_input_as_handled()
					elif ev.keycode == KEY_B and m == bestiary_modal:
						m.hide()
						m.set_input_as_handled()
					elif ev.keycode == KEY_I and m == inventory_modal:
						m.hide()
						m.set_input_as_handled()
			)

func _sync_modal_pause():
	var any_open := has_open_modal()
	if get_tree().paused != any_open:
		get_tree().paused = any_open
		if is_instance_valid(player):
			if any_open and player.has_method("on_modal_opened"):
				player.on_modal_opened()
			elif not any_open and player.has_method("on_modal_closed"):
				player.on_modal_closed()

func _on_toggle_bestiary():
	if bestiary_modal.visible:
		bestiary_modal.hide()
	elif not has_open_modal():
		bestiary_modal.open()

func _on_toggle_inventory():
	if inventory_modal.visible:
		inventory_modal.hide()
	elif not has_open_modal():
		inventory_modal.open()

func _on_close_modals():
	for m in [shop_modal, map_modal, bestiary_modal, inventory_modal, settings_modal, ranking_modal, confirm_reset_dialog]:
		if is_instance_valid(m) and m.visible:
			m.hide()

func _unhandled_input(event):
	if has_open_modal() or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if is_instance_valid(player) and player.has_method("set_click_destination"):
			player.set_click_destination(get_global_mouse_position())

func _process(delta: float):
	# Atualiza a posição da câmera para acompanhar Daniel
	if is_instance_valid(player):
		camera.position = player.position

	# Processa trepidação de câmera (Screen Shake proporcional)
	if shake_timer > 0.0:
		shake_timer -= delta
		var ratio = clamp(shake_timer / max(0.01, shake_max_duration), 0.0, 1.0)
		var cur_mag = shake_intensity * ratio
		camera.offset = Vector2(randf_range(-cur_mag, cur_mag), randf_range(-cur_mag, cur_mag))
	else:
		camera.offset = Vector2.ZERO

	# Spawn contínuo de monstros em zonas de caçada
	var w = GameData.WORLDS.get(GameState.current_world, {})
	if w.get("type", "") == "hunt_zone":
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = 2.0
			var active_monsters = get_tree().get_nodes_in_group("monsters").size()
			if active_monsters < 10:
				_spawn_random_monster(w)

func build_world(world_id: String):
	for c in world_container.get_children():
		c.queue_free()
	for c in entities_container.get_children():
		c.queue_free()

	var w = GameData.WORLDS.get(world_id, GameData.WORLDS["floresta"])
	AudioManager.play_bgm(world_id)

	# Fundo base de segurança + TileMapLayer 32x32 estilo Tibia (PixelLab Map Workshop)
	tile_engine = TibiaTileEngine.new()
	world_container.add_child(tile_engine)
	tile_engine.build_map(world_id)
	map_width = tile_engine.map_width
	map_height = tile_engine.map_height

	camera.limit_left = 0
	camera.limit_top = -56
	camera.limit_right = int(map_width) + 256
	camera.limit_bottom = int(map_height) + 64

	var bg_rect = ColorRect.new()
	bg_rect.color = w.color_bg.darkened(0.45)
	bg_rect.size = Vector2(map_width + 320, map_height + 160)
	bg_rect.position = Vector2(-32, -80)
	bg_rect.z_index = -15
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_container.add_child(bg_rect)

	# Bordas físicas, árvores de contorno, torres, placas de Hunt Spot e portais
	_build_environmental_decorations(world_id)

	# Cria Daniel Ragnar no portal de chegada (ou praça central por viagem rápida)
	var p_script = load("res://scripts/Player.gd")
	player = CharacterBody2D.new()
	player.set_script(p_script)
	if arrived_via_portal:
		player.position = tile_engine.get_arrival_pos(previous_world_id)
		arrived_via_portal = false
	else:
		player.position = tile_engine.default_spawn
	entities_container.add_child(player)
	camera.position = player.position

	match world_id:
		"vila":
			_setup_vila()
		"floresta":
			_setup_floresta()
		"caverna":
			_setup_caverna()
		"castelo":
			_setup_castelo()
		"cabana":
			_setup_cabana()

	# Pré-popula os Hunt Spots para o mapa iniciar vivo imediatamente
	if w.get("type", "") == "hunt_zone":
		for _i in range(6):
			_spawn_random_monster(w)

func _build_environmental_decorations(world_id: String):
	# Paredes/Bordas de colisão física nas 4 extremidades do mapa
	var bounds = StaticBody2D.new()
	
	var top_col = CollisionShape2D.new()
	var top_box = WorldBoundaryShape2D.new()
	top_box.normal = Vector2.DOWN
	top_col.shape = top_box
	top_col.position = Vector2(0, 30)
	bounds.add_child(top_col)

	var bottom_col = CollisionShape2D.new()
	var bot_box = WorldBoundaryShape2D.new()
	bot_box.normal = Vector2.UP
	bottom_col.shape = bot_box
	bottom_col.position = Vector2(0, map_height - 30)
	bounds.add_child(bottom_col)

	var left_col = CollisionShape2D.new()
	var left_box = WorldBoundaryShape2D.new()
	left_box.normal = Vector2.RIGHT
	left_col.shape = left_box
	left_col.position = Vector2(30, 0)
	bounds.add_child(left_col)

	var right_col = CollisionShape2D.new()
	var right_box = WorldBoundaryShape2D.new()
	right_box.normal = Vector2.LEFT
	right_col.shape = right_box
	right_col.position = Vector2(map_width - 30, 0)
	bounds.add_child(right_col)

	world_container.add_child(bounds)

	# Obstáculos e props carregados diretamente do PixelLab Map Workshop no TileEngine
	obstacle_positions.clear()
	hunt_spot_round_robin = 0

	if tile_engine:
		obstacle_positions.append_array(tile_engine.prop_positions)

		# Rótulos de Hunt Spots junto às placas
		for hs in tile_engine.hunt_spots:
			var spot_lbl = Label.new()
			spot_lbl.text = str(hs.get("name", ""))
			spot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			spot_lbl.custom_minimum_size = Vector2(200, 20)
			spot_lbl.position = hs.get("label_pos", hs.get("pos", Vector2.ZERO) + Vector2(-100.0, -78.0))
			spot_lbl.add_theme_font_size_override("font_size", 11)
			spot_lbl.add_theme_color_override("font_color", Color("#FFD76B"))
			spot_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			spot_lbl.add_theme_constant_override("outline_size", 3)
			world_container.add_child(spot_lbl)

		# Portais físicos inter-zonas estilo Tibia
		var zp_script = load("res://scripts/ZonePortal.gd")
		for pdef in tile_engine.portals:
			var portal = Area2D.new()
			portal.set_script(zp_script)
			entities_container.add_child(portal)
			portal.setup(pdef)
			portal.portal_triggered.connect(_on_portal_triggered)

	# Partículas Atmosféricas do Bioma
	var atmo = CPUParticles2D.new()
	atmo.position = Vector2(map_width / 2.0, map_height / 2.0)
	atmo.amount = 65
	atmo.lifetime = 4.5
	atmo.preprocess = 2.0
	atmo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	atmo.emission_rect_extents = Vector2(map_width / 2.0, map_height / 2.0)
	atmo.gravity = Vector2.ZERO
	atmo.initial_velocity_min = 8.0
	atmo.initial_velocity_max = 22.0
	atmo.scale_amount_min = 2.0
	atmo.scale_amount_max = 4.5

	match world_id:
		"vila", "floresta":
			atmo.direction = Vector2(0.5, 1.0)
			atmo.spread = 45.0
			atmo.color = Color(0.85, 1.0, 0.45, 0.45) # Vaga-lumes / Pólen da Floresta
		"caverna":
			atmo.direction = Vector2(0, 1.0)
			atmo.spread = 25.0
			atmo.color = Color(0.55, 0.85, 1.0, 0.40) # Poeira cristalina das minas
		"castelo":
			atmo.direction = Vector2(0, -1.0)
			atmo.spread = 35.0
			atmo.initial_velocity_min = 18.0
			atmo.initial_velocity_max = 42.0
			atmo.color = Color(1.0, 0.35, 0.15, 0.55) # Brasas ascendentes de Lunário
		"cabana":
			atmo.direction = Vector2(0, -1.0)
			atmo.spread = 60.0
			atmo.color = Color(1.0, 0.90, 0.45, 0.50) # Luzes douradas de vitória

	world_container.add_child(atmo)

func _place_prop(obj_name: String, pos: Vector2, collision_radius: float = 26.0, prop_scale: Vector2 = Vector2.ONE, flame_color: Color = Color.TRANSPARENT) -> Node2D:
	var node: Node2D
	if collision_radius > 0.0:
		obstacle_positions.append(pos)
		if tile_engine:
			tile_engine.mark_solid_prop(pos, collision_radius)
		var body = StaticBody2D.new()
		var shape = CollisionShape2D.new()
		var c_shape = CircleShape2D.new()
		c_shape.radius = collision_radius
		shape.shape = c_shape
		body.add_child(shape)
		node = body
	else:
		node = Node2D.new()

	node.position = pos
	var tex = SpriteFactory.get_object_texture(obj_name)
	if tex:
		var sp = Sprite2D.new()
		sp.texture = tex
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.scale = prop_scale
		node.add_child(sp)
	else:
		var fallback = ColorRect.new()
		fallback.color = Color("#3A3530")
		fallback.size = Vector2(44, 44) * prop_scale
		fallback.position = -fallback.size * 0.5
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(fallback)

	if flame_color.a > 0.0:
		var embers = CPUParticles2D.new()
		embers.position = Vector2(0, -10)
		embers.amount = 14
		embers.lifetime = 0.85
		embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		embers.emission_sphere_radius = 6.0
		embers.direction = Vector2(0, -1)
		embers.spread = 28.0
		embers.gravity = Vector2.ZERO
		embers.initial_velocity_min = 16.0
		embers.initial_velocity_max = 32.0
		embers.scale_amount_min = 2.0
		embers.scale_amount_max = 4.0
		embers.color = flame_color
		node.add_child(embers)

	world_container.add_child(node)
	return node

func _setup_vila():
	_place_prop("vila_stall", Vector2(1248.0, 740.0), 28.0, Vector2(1.45, 1.45))

	var aldeao = _create_npc("aldeao", "Aldeão", Vector2(768.0, 576.0), func():
		AudioManager.play_voice("aldeao_intro")
		dialogue_box.show_dialogue("Aldeão da Vila", "Daniel! O Deus Dragão Lunário destruiu as outras vilas... Apenas a Vila Barão Ragnar resistiu, e seu pai sumiu lutando por nós. Vá às caçadas, fique mais forte e traga nosso herói de volta!")
	)
	entities_container.add_child(aldeao)

	var vendedor = _create_npc("vendedor", "Vendedor", Vector2(1248.0, 810.0), func():
		AudioManager.play_voice("vendedor_ola")
		shop_modal.open()
	)
	entities_container.add_child(vendedor)

func _setup_floresta():
	var explorador = _create_npc("explorador", "Explorador", Vector2(1018.0, 536.0), func():
		if not GameState.unlocked_spells.get("fireball", false) or not GameState.defeated_bosses.get("lobisomem", false):
			GameState.unlocked_spells["fireball"] = true
			GameState.stats_changed.emit()
			GameState.save_game()
			AudioManager.play_voice("explorador_floresta_1")
			dialogue_box.show_dialogue("Explorador", "Daniel! As Toupeiras e Zumbis dominam esta floresta. Use sua Bola de Fogo na tecla 1 — ela causa o dobro de dano neles!")
		else:
			AudioManager.play_voice("explorador_floresta_2")
			dialogue_box.show_dialogue("Explorador", "Cuidado com o Lobisomem e a Toupeira Serra! Derrote monstros até o botão Desafiar Chefe brilhar para invocar o líder da área.")
	)
	entities_container.add_child(explorador)

func _setup_caverna():
	var explorador = _create_npc("explorador", "Explorador", Vector2(968.0, 560.0), func():
		if not GameState.unlocked_spells.get("tornado", false) or not GameState.unlocked_spells.get("water_bomb", false):
			GameState.unlocked_spells["tornado"] = true
			GameState.unlocked_spells["water_bomb"] = true
			GameState.stats_changed.emit()
			GameState.save_game()
			AudioManager.play_voice("explorador_caverna_1")
			dialogue_box.show_dialogue("Explorador", "Você desceu às minas! Aqui estão o Tornado na tecla 2 e a Bomba de Água na tecla 3. A água causa curto-circuito com dano em dobro nos Robôs!")
		else:
			AudioManager.play_voice("explorador_caverna_2")
			dialogue_box.show_dialogue("Explorador", "A Robô Toupeira Serra e o temível Robô Aranha guardam este subterrâneo! Use Bomba de Água na tecla 3 para derrubá-los!")
	)
	entities_container.add_child(explorador)

func _setup_castelo():
	var explorador = _create_npc("explorador", "Explorador", Vector2(1008.0, 880.0), func():
		AudioManager.play_voice("explorador_castelo")
		dialogue_box.show_dialogue("Explorador", "Você chegou à fortaleza flutuante! O Dragão Guardião e o supremo Deus Dragão Lunário esperam por você. Vença-os para revelar a cabana onde seu pai está preso!")
	)
	entities_container.add_child(explorador)

func _setup_cabana():
	var barao = _create_npc("barao", "Barão Ragnar (Pai)", Vector2(1344.0, 624.0), func():
		play_ending_cutscene()
	)
	entities_container.add_child(barao)

func _create_npc(id: String, name_str: String, pos: Vector2, on_interact: Callable) -> Area2D:
	var npc_script = load("res://scripts/NPC.gd")
	var npc = Area2D.new()
	npc.set_script(npc_script)
	npc.npc_id = id
	npc.npc_name = name_str
	npc.position = pos
	npc.interacted.connect(func(_id): on_interact.call())
	return npc

func _spawn_random_monster(world_data: Dictionary):
	var m_list: Array = world_data.get("monsters", [])
	if m_list.is_empty():
		return

	var spawn_origin := player.position
	if tile_engine and not tile_engine.hunt_spots.is_empty():
		var spots = tile_engine.hunt_spots
		var spot = spots[hunt_spot_round_robin % spots.size()]
		hunt_spot_round_robin += 1
		# Mantém distância mínima para não surgir em cima do jogador
		if spot.pos.distance_to(player.position) < 170.0 and spots.size() > 1:
			spot = spots[hunt_spot_round_robin % spots.size()]
			hunt_spot_round_robin += 1
		spawn_origin = spot.pos
		var spot_pool: Array = spot.get("monsters", [])
		if not spot_pool.is_empty():
			m_list = spot_pool

	var chosen_id = m_list[randi() % m_list.size()]
	var m_script = load("res://scripts/Monster.gd")
	var m = CharacterBody2D.new()
	m.set_script(m_script)
	m.setup(chosen_id)

	var angle = randf() * TAU
	var dist = randf_range(55.0, 155.0)
	var spawn_pos = spawn_origin + Vector2(cos(angle), sin(angle)) * dist
	m.position = _get_safe_spawn_pos(spawn_pos)
	entities_container.add_child(m)

func _get_safe_spawn_pos(pos: Vector2) -> Vector2:
	var safe = Vector2(clamp(pos.x, 96.0, map_width - 96.0), clamp(pos.y, 96.0, map_height - 96.0))
	if tile_engine:
		var safe_cell = tile_engine.find_nearest_walkable_cell(tile_engine.world_to_cell(safe))
		if not tile_engine.is_world_pos_walkable(safe) or tile_engine.astar.is_point_solid(tile_engine.world_to_cell(safe)):
			safe = Vector2(safe_cell.x * 32.0 + 16.0, safe_cell.y * 32.0 + 16.0)
	for obs_pos in obstacle_positions:
		if safe.distance_to(obs_pos) < 68.0:
			var push = (safe - obs_pos).normalized()
			if push == Vector2.ZERO:
				push = Vector2.RIGHT
			safe = obs_pos + push * 72.0
	safe.x = clamp(safe.x, 96.0, map_width - 96.0)
	safe.y = clamp(safe.y, 96.0, map_height - 96.0)
	return safe

func _on_portal_triggered(portal_data: Dictionary):
	var req_boss: String = str(portal_data.get("required_boss", ""))
	if req_boss != "" and not GameState.defeated_bosses.get(req_boss, false):
		dialogue_box.show_dialogue("Portal Selado", str(portal_data.get("lock_msg", "Este portal ainda está selado!")))
		return
	var target_w: String = str(portal_data.get("target_world", ""))
	if target_w != "" and GameState.unlocked_worlds.get(target_w, false):
		arrived_via_portal = true
		previous_world_id = GameState.current_world
		GameState.set_world(target_w)

const BOSS_CUTSCENE_LINES := {
	"lobisomem": "Grrr... Sinto o cheiro de carne fresca na floresta! Você não escapa do meu uivo, garoto!",
	"toupeira_serra": "Hahaha! Minha serra vai rasgar a terra e cortar você ao meio! Ninguém passa da minha toca!",
	"robo_toupeira_serra": "Alvo detectado! Motores de escavação no máximo. Exterminar o invasor Daniel Ragnar!",
	"robo_aranha": "Minha teia de choque já cercou toda esta caverna, pequeno tolo... Você não sairá vivo daqui!",
	"dragao": "Ousa invadir os domínios do meu mestre?! Minhas chamas vão reduzir você e sua vila a cinzas!",
	"lunario": "Tolo mortal... Eu sou Lunário, o Deus Dragão! Assim como seu pai caiu diante de mim, a luz deste mundo se apagará sob minhas asas!"
}

func _on_challenge_boss():
	for m in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(m) and m.is_boss and m.current_hp > 0:
			return
	var boss_to_spawn := GameState.get_next_world_boss(GameState.current_world)
	if boss_to_spawn == "":
		return

	var m_script = load("res://scripts/Monster.gd")
	var boss = CharacterBody2D.new()
	boss.set_script(m_script)
	boss.setup(boss_to_spawn)
	boss.position = _get_safe_spawn_pos(player.position + Vector2(0, -220))
	entities_container.add_child(boss)
	play_boss_cutscene(boss_to_spawn)

func play_intro_cutscene():
	if not is_instance_valid(cutscene_modal) or has_open_modal():
		return
	GameState.intro_cutscene_seen = true
	GameState.save_game()
	var daniel_tex := SpriteFactory.get_character_texture("daniel_ragnar", "south")
	var aldeao_tex := SpriteFactory.get_character_texture("aldeao", "south")
	var barao_tex := SpriteFactory.get_character_texture("barao", "south")
	var lunario_tex := SpriteFactory.get_character_texture("lunario", "south")
	var slides := [
		{
			"title": "CAPÍTULO I — O ATAQUE DOS DRAGÕES",
			"theme": "crimson",
			"is_evil": false,
			"speaker": "Ancião da Vila",
			"text": "Há tempos sombrios, o Deus Dragão Lunário despertou com seu exército de monstros e destruiu quase todo o reino.",
			"voice": "intro_1_ataque",
			"sfx": "boss_roar",
			"sfx_db": -7.5,
			"sfx_fade": 0.45,
			"shake": 6.0,
			"left_tex": aldeao_tex,
			"left_name": "Ancião da Vila",
			"symbol": "boss",
			"right_tex": lunario_tex,
			"right_name": "Exército de Lunário"
		},
		{
			"title": "CAPÍTULO II — O DESAPARECIMENTO DO BARÃO RAGNAR",
			"theme": "stone",
			"is_evil": false,
			"speaker": "Ancião da Vila",
			"text": "Apenas a Vila Barão Ragnar resistiu, graças ao bravo Barão Ragnar... que desapareceu ao enfrentar o dragão para proteger seu povo.",
			"voice": "intro_2_barao",
			"left_tex": aldeao_tex,
			"left_name": "Ancião da Vila",
			"symbol": "shield",
			"right_tex": barao_tex,
			"right_name": "Barão Ragnar (Pai)"
		},
		{
			"title": "CAPÍTULO III — A PROMESSA DO ÚLTIMO HERÓI",
			"theme": "gold",
			"is_evil": false,
			"speaker": "Daniel Ragnar",
			"text": "Meu pai lutou por todos nós... Agora é a minha vez! Vou vencer cada chefe, derrotar Lunário e trazer meu pai de volta!",
			"voice": "daniel_intro",
			"left_tex": daniel_tex,
			"left_name": "Daniel Ragnar",
			"right_tex": null,
			"finish_label": "Começar Aventura!",
			"finish_icon": "sword"
		}
	]
	cutscene_modal.start_cutscene(slides)

func play_boss_cutscene(boss_id: String):
	if not is_instance_valid(cutscene_modal):
		return
	var b_data: Dictionary = GameData.MONSTERS.get(boss_id, {})
	var b_name := str(b_data.get("name", "Chefe"))
	var b_line := str(BOSS_CUTSCENE_LINES.get(boss_id, "Prepare-se para a batalha!"))
	var boss_tex := SpriteFactory.get_character_texture(boss_id, "south")
	var daniel_tex := SpriteFactory.get_character_texture("daniel_ragnar", "south")
	var slides := [
		{
			"title": "INVOCAÇÃO DE CHEFE — " + b_name.to_upper(),
			"theme": "crimson",
			"is_evil": true,
			"speaker": b_name,
			"text": b_line,
			"voice": "boss_" + boss_id,
			"sfx": "boss_roar",
			"sfx_db": -2.0,
			"sfx_fade": 0.20,
			"shake": 12.0,
			"left_tex": daniel_tex,
			"left_name": "Daniel Ragnar",
			"symbol": "boss",
			"right_tex": boss_tex,
			"right_name": b_name,
			"next_label": "Responder >>"
		},
		{
			"title": "CONFRONTO IMINENTE!",
			"theme": "gold",
			"is_evil": false,
			"speaker": "Daniel Ragnar",
			"text": "Eu não tenho medo de você! Vamos lutar!",
			"voice": "daniel_boss_challenge",
			"left_tex": daniel_tex,
			"left_name": "Daniel Ragnar",
			"symbol": "sword",
			"right_tex": boss_tex,
			"right_name": b_name,
			"finish_label": "Iniciar Batalha!",
			"finish_icon": "sword"
		}
	]
	cutscene_modal.start_cutscene(slides)

func play_ending_cutscene():
	if not is_instance_valid(cutscene_modal):
		return
	GameState.freeze_victory_run()
	var daniel_tex := SpriteFactory.get_character_texture("daniel_ragnar", "south")
	var barao_tex := SpriteFactory.get_character_texture("barao", "south")
	var slides := [
		{
			"title": "EPÍLOGO — O REENCONTRO NA CABANA",
			"theme": "gold",
			"is_evil": false,
			"speaker": "Daniel Ragnar",
			"text": "Pai! Eu consegui! O Deus Dragão Lunário foi derrotado e eu vim buscar o senhor!",
			"voice": "daniel_victory",
			"left_tex": daniel_tex,
			"left_name": "Daniel Ragnar",
			"symbol": "star",
			"right_tex": barao_tex,
			"right_name": "Barão Ragnar (Pai)",
			"next_label": "Ouvir Barão Ragnar >>"
		},
		{
			"title": "O VERDADEIRO ÚLTIMO HERÓI",
			"theme": "gold",
			"is_evil": false,
			"speaker": "Barão Ragnar (Pai)",
			"text": "Daniel... meu filho! Você cruzou todo o reino, derrotou o Deus Dragão Lunário e veio me salvar com sua faixa vermelha! Você é o verdadeiro Último Herói! A Vila Barão Ragnar está a salvo para sempre!",
			"voice": "barao_resgate",
			"left_tex": daniel_tex,
			"left_name": "Daniel Ragnar",
			"symbol": "heart",
			"right_tex": barao_tex,
			"right_name": "Barão Ragnar (Pai)",
			"finish_label": "Concluir Campanha!",
			"finish_icon": "star"
		}
	]
	cutscene_modal.start_cutscene(slides, func():
		GameState.victory_achieved = true
		GameState.save_game()
		victory_modal.open()
	)

func _on_game_reset():
	if is_instance_valid(title_screen):
		title_screen.visible = false
	_sync_modal_pause()
	build_world(GameState.current_world)
	call_deferred("play_intro_cutscene")

func _on_screen_shake(intensity: float, duration: float):
	if intensity >= shake_intensity or shake_timer <= 0.0:
		shake_intensity = intensity
		shake_timer = duration
		shake_max_duration = max(0.01, duration)

func _on_hitstop(duration: float):
	if hitstop_active:
		return
	hitstop_active = true
	Engine.time_scale = 0.08
	get_tree().create_timer(duration, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0
		hitstop_active = false
	)

func _on_world_changed(w_id: String):
	call_deferred("build_world", w_id)

func _on_boss_defeated(b_id: String):
	if b_id == "lobisomem":
		dialogue_box.show_dialogue("MAGIA LIBERADA!", "Você derrotou o Lobisomem! A magia Tornado [Tecla 2] foi desbloqueada — ela atrai e atordoa Esqueletos e Fantasmas (x2 Dano)!")
	elif b_id == "toupeira_serra":
		dialogue_box.show_dialogue("ZONA E MAGIA LIBERADAS!", "Você derrotou a Toupeira Serra! O acesso às Cavernas e Minas foi aberto no Mapa Mundi e as magias Tornado [2] e Bomba de Água [3] estão liberadas!")
	elif b_id == "robo_aranha":
		dialogue_box.show_dialogue("ZONA LIBERADA!", "A Robô Aranha foi destruída! O caminho até o Castelo de Lunário foi aberto no Mapa Mundi [Mapa]!")
	elif b_id == "lunario":
		dialogue_box.show_dialogue("VITÓRIA ÉPICA!", "O Deus Dragão Lunário caiu! O mapa da Cabana Inimiga Distante foi revelado no Mapa Mundi [Mapa] - vá resgatar seu pai, o Barão Ragnar!")

func _on_player_died():
	dialogue_box.show_dialogue("Derrotado!", "Daniel caiu em batalha... Retornando em segurança para a Vila Barão Ragnar para se recuperar.")
	GameState.current_hp = GameState.max_hp
	GameState.set_world("vila")
