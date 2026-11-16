extends Area2D

## NPC interativo do mundo com patrulha segura e gatilho de diálogo por tecla [E] ou clique.

signal interacted(npc_id)

@export var npc_id: String = "aldeao"
@export var npc_name: String = "Aldeão"

var is_wandering: bool = false
var wander_dir: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var player_in_range: bool = false
var interact_cooldown: float = 0.0
var e_was_down: bool = false
var prompt_lbl: Label
var sprite: Sprite2D
var indicator_node: Node2D
var current_direction: String = "south"

class NPCIndicator extends Node2D:
	var symbol_char: String = "!"
	var bg_col: Color = Color("#D97706")
	var rim_col: Color = Color("#FFE28A")
	var text_col: Color = Color("#FFF8E1")
	var bob_t: float = 0.0

	func _process(delta: float):
		bob_t += delta * 4.2
		position.y = -52.0 + sin(bob_t) * 3.5
		queue_redraw()

	func _draw():
		# Medalhão losango medieval desenhado em pixel/vetor limpo
		var r := 10.0
		var pts := PackedVector2Array([
			Vector2(0, -r),
			Vector2(r, 0),
			Vector2(0, r),
			Vector2(-r, 0)
		])
		draw_colored_polygon(pts, bg_col)
		var rim_pts := PackedVector2Array([
			Vector2(0, -r),
			Vector2(r, 0),
			Vector2(0, r),
			Vector2(-r, 0),
			Vector2(0, -r)
		])
		draw_polyline(rim_pts, Color(0.08, 0.05, 0.02, 0.95), 2.5)
		draw_polyline(PackedVector2Array([
			Vector2(0, -(r - 1.8)),
			Vector2(r - 1.8, 0),
			Vector2(0, r - 1.8),
			Vector2(-(r - 1.8), 0),
			Vector2(0, -(r - 1.8))
		]), rim_col, 1.4)
		var font := ThemeDB.fallback_font
		if font:
			var f_sz := 12
			var sz := font.get_string_size(symbol_char, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz)
			draw_string(font, Vector2(-sz.x * 0.5, sz.y * 0.34), symbol_char, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, text_col)

func _ready():
	add_to_group("npcs")
	sprite = Sprite2D.new()
	sprite.texture = SpriteFactory.get_character_texture(npc_id, current_direction)
	add_child(sprite)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 48.0
	shape.shape = circle
	add_child(shape)

	indicator_node = NPCIndicator.new()
	indicator_node.z_index = 4
	match npc_id:
		"vendedor":
			indicator_node.symbol_char = "$"
			indicator_node.bg_col = Color("#15803D")
			indicator_node.rim_col = Color("#FFD76B")
		"explorador":
			indicator_node.symbol_char = "?"
			indicator_node.bg_col = Color("#0369A1")
			indicator_node.rim_col = Color("#7DD3FC")
		"barao":
			indicator_node.symbol_char = "!"
			indicator_node.bg_col = Color("#B45309")
			indicator_node.rim_col = Color("#FFF0A5")
		_:
			indicator_node.symbol_char = "!"
			indicator_node.bg_col = Color("#B91C1C")
			indicator_node.rim_col = Color("#FDE68A")
	add_child(indicator_node)

	var lbl = Label.new()
	lbl.text = npc_name
	lbl.position = Vector2(-75, -38)
	lbl.size = Vector2(150, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(lbl, Color("#F5E6C8"), 12, 2)
	add_child(lbl)

	prompt_lbl = Label.new()
	prompt_lbl.text = _get_prompt_text()
	prompt_lbl.position = Vector2(-85, -78)
	prompt_lbl.size = Vector2(170, 20)
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(prompt_lbl, Color("#FFD76B"), 11, 3)
	prompt_lbl.visible = false
	add_child(prompt_lbl)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_pickable = true
	input_event.connect(_on_input_event)

	if npc_id == "explorador":
		is_wandering = true

func _get_prompt_text() -> String:
	match npc_id:
		"vendedor":
			return "[E] Abrir Loja"
		"explorador":
			return "[E] Ouvir Dica"
		"barao":
			return "[E] Conversar" if GameState.victory_achieved else "[E] Resgatar Pai!"
		_:
			return "[E] Conversar"

func _process(delta: float):
	if interact_cooldown > 0.0:
		interact_cooldown -= delta

	if is_wandering:
		wander_timer -= delta
		if wander_timer <= 0.0:
			wander_timer = randf_range(2.0, 4.0)
			wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			_update_wander_facing()
		var next_pos := position + wander_dir * 30.0 * delta
		if _can_walk_to(next_pos):
			position = next_pos
		else:
			wander_dir = -wander_dir
			wander_timer = randf_range(0.6, 1.5)
			_update_wander_facing()

	var e_down = Input.is_key_pressed(KEY_E)
	if not get_tree().paused and player_in_range and e_down and not e_was_down and interact_cooldown <= 0.0:
		var d_boxes = get_tree().get_nodes_in_group("dialogue_box")
		var is_dlg_open = d_boxes.size() > 0 and d_boxes[0].visible
		if not is_dlg_open:
			interact()
	e_was_down = e_down

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		prompt_lbl.text = _get_prompt_text()
		prompt_lbl.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		prompt_lbl.visible = false

func interact():
	interact_cooldown = 0.25
	interacted.emit(npc_id)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if get_tree().paused or interact_cooldown > 0.0:
		return
	var clicked: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var tapped: bool = (event is InputEventScreenTouch and event.pressed)
	if clicked or tapped:
		if player_in_range:
			interact()
		else:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0 and is_instance_valid(players[0]) and players[0].has_method("set_click_destination"):
				players[0].set_click_destination(global_position)

func _update_wander_facing():
	if abs(wander_dir.x) > abs(wander_dir.y):
		current_direction = "east" if wander_dir.x > 0 else "west"
	else:
		current_direction = "south" if wander_dir.y > 0 else "north"
	if sprite:
		sprite.texture = SpriteFactory.get_character_texture(npc_id, current_direction)

func _can_walk_to(target_pos: Vector2) -> bool:
	var scene := get_tree().current_scene
	var te = scene.get("tile_engine") if scene else null
	var bounds := GameData.get_map_bounds(scene)
	if te == null:
		return target_pos.x >= 96.0 and target_pos.x <= bounds.x - 96.0 and target_pos.y >= 96.0 and target_pos.y <= bounds.y - 96.0
	if target_pos.x < 96.0 or target_pos.x > te.map_width - 96.0 or target_pos.y < 96.0 or target_pos.y > te.map_height - 96.0:
		return false
	for offset in [Vector2.ZERO, Vector2(12, 0), Vector2(-12, 0), Vector2(0, 12), Vector2(0, -12)]:
		var p: Vector2 = target_pos + offset
		if not te.is_world_pos_walkable(p):
			return false
		if te.astar and te.astar.is_point_solid(te.world_to_cell(p)):
			return false
	return true
