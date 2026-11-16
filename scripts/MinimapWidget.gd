extends PanelContainer

## Minimapa tático interativo estilo Tibia com clique para navegar pelo mundo.

const FALLBACK_WORLD_WIDTH: float = 2048.0
const FALLBACK_WORLD_HEIGHT: float = 1152.0
const CANVAS_SIZE := Vector2(186.0, 124.0)

var title_lbl: Label
var map_canvas: Control
var pulse_time: float = 0.0

class MinimapCanvas extends Control:
	var widget_ref

	func _get_world_size() -> Vector2:
		var main_node = get_tree().current_scene
		if main_node and "tile_engine" in main_node and main_node.tile_engine:
			return Vector2(max(1.0, main_node.tile_engine.map_width), max(1.0, main_node.tile_engine.map_height))
		return Vector2(FALLBACK_WORLD_WIDTH, FALLBACK_WORLD_HEIGHT)

	func _gui_input(event: InputEvent):
		if get_tree().paused:
			return
		if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			var ws := _get_world_size()
			var wx = clamp((event.position.x / max(1.0, size.x)) * ws.x, 48.0, ws.x - 48.0)
			var wy = clamp((event.position.y / max(1.0, size.y)) * ws.y, 48.0, ws.y - 48.0)
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0 and is_instance_valid(players[0]) and players[0].has_method("set_click_destination"):
				players[0].set_click_destination(Vector2(wx, wy))
			accept_event()

	func _draw():
		var w_id = GameState.current_world
		var w_data = GameData.WORLDS.get(w_id, {})
		var bg_col: Color = w_data.get("color_bg", Color("#1C2B1C")).lightened(0.06)

		draw_rect(Rect2(Vector2.ZERO, size), bg_col)

		var main_node = get_tree().current_scene
		if main_node and "tile_engine" in main_node and main_node.tile_engine and main_node.tile_engine.minimap_texture:
			draw_texture_rect(main_node.tile_engine.minimap_texture, Rect2(Vector2.ZERO, size), false)

		# Grade tática sutil
		for gx in range(1, 4):
			var x_pos = size.x * float(gx) / 4.0
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), Color(1, 1, 1, 0.06), 1.0)
		for gy in range(1, 4):
			var y_pos = size.y * float(gy) / 4.0
			draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), Color(1, 1, 1, 0.06), 1.0)

		var ws := _get_world_size()
		var sx = size.x / ws.x
		var sy = size.y / ws.y

		# Hunt Spots e Portais do TileEngine
		if main_node and "tile_engine" in main_node and main_node.tile_engine:
			for hs in main_node.tile_engine.hunt_spots:
				var hp = Vector2(hs.pos.x * sx, hs.pos.y * sy)
				draw_circle(hp, 3.0, Color(1.0, 0.78, 0.25, 0.32))
				draw_line(hp + Vector2(-2.2, 0), hp + Vector2(2.2, 0), Color("#FFD76B"), 1.0)
				draw_line(hp + Vector2(0, -2.2), hp + Vector2(0, 2.2), Color("#FFD76B"), 1.0)
			for pdef in main_node.tile_engine.portals:
				var pp = Vector2(pdef.pos.x * sx, pdef.pos.y * sy)
				draw_arc(pp, 4.0, 0.0, TAU, 16, Color("#3BF0FF"), 1.4)

		# Obstáculos / Landmarks do mapa atual
		if main_node and "obstacle_positions" in main_node:
			for obs_pos in main_node.obstacle_positions:
				var p = Vector2(obs_pos.x * sx, obs_pos.y * sy)
				draw_rect(Rect2(p - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color(0.06, 0.08, 0.06, 0.72))

		# Cédulas caídas no chão
		for note in get_tree().get_nodes_in_group("cash_notes"):
			if is_instance_valid(note):
				var np = Vector2(note.global_position.x * sx, note.global_position.y * sy)
				draw_circle(np, 1.5, Color("#85BB65"))

		# NPCs da área
		for npc in get_tree().get_nodes_in_group("npcs"):
			if is_instance_valid(npc):
				var npp = Vector2(npc.global_position.x * sx, npc.global_position.y * sy)
				draw_rect(Rect2(npp - Vector2(2.5, 2.5), Vector2(5, 5)), Color("#00E5FF"))

		# Monstros e Chefes
		var pulse = 0.0
		if widget_ref:
			pulse = sin(widget_ref.pulse_time * 6.0)
		for m in get_tree().get_nodes_in_group("monsters"):
			if is_instance_valid(m) and m.current_hp > 0:
				var mp = Vector2(m.global_position.x * sx, m.global_position.y * sy)
				if m.is_boss:
					draw_circle(mp, 5.2 + pulse * 1.1, Color(1.0, 0.15, 0.45, 0.45))
					draw_circle(mp, 3.6, Color("#FFD700"))
				else:
					draw_circle(mp, 2.2, Color("#FF4444"))

		# Daniel Ragnar + Destino Ativo + retângulo aproximado da câmera (1280x720)
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]):
			var pl = players[0]
			var pp = Vector2(pl.global_position.x * sx, pl.global_position.y * sy)
			if "has_click_destination" in pl and pl.has_click_destination:
				var dp = Vector2(pl.click_destination.x * sx, pl.click_destination.y * sy)
				draw_line(pp, dp, Color(0.25, 0.95, 0.72, 0.70), 1.2)
				draw_circle(dp, 2.8, Color(0.25, 0.95, 0.72, 0.95))
			var cam_w = 1280.0 * sx
			var cam_h = 720.0 * sy
			var cam_rect = Rect2(pp - Vector2(cam_w * 0.5, cam_h * 0.5), Vector2(cam_w, cam_h))
			draw_rect(cam_rect, Color(1, 1, 1, 0.25), false, 1.0)
			draw_circle(pp, 3.8, Color("#E62E2E"))
			draw_circle(pp, 2.4, Color.WHITE)

		draw_rect(Rect2(Vector2.ZERO, size), Color("#4A3512"), false, 3.0)
		draw_rect(Rect2(Vector2(1.5, 1.5), size - Vector2(3.0, 3.0)), Color("#C99D44"), false, 1.5)

func _ready():
	add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 22, 20))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_bottom", 0)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	title_lbl = Label.new()
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 11, 2)
	vbox.add_child(title_lbl)

	map_canvas = MinimapCanvas.new()
	map_canvas.widget_ref = self
	map_canvas.custom_minimum_size = CANVAS_SIZE
	map_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	map_canvas.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	map_canvas.tooltip_text = "Clique para andar no mapa (ou botão direito no chão)"
	vbox.add_child(map_canvas)

	var legend_row = HBoxContainer.new()
	legend_row.alignment = BoxContainer.ALIGNMENT_CENTER
	legend_row.add_theme_constant_override("separation", 6)
	vbox.add_child(legend_row)

	for item in [
		[Color.WHITE, "Voce"],
		[Color("#00E5FF"), "NPC"],
		[Color("#FF4444"), "Inim."],
		[Color("#FFD700"), "Chefe"]
	]:
		var dot = ColorRect.new()
		dot.color = item[0]
		dot.custom_minimum_size = Vector2(7, 7)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		legend_row.add_child(dot)

		var lbl = Label.new()
		lbl.text = item[1]
		MedievalUI.style_label(lbl, Color("#E8D8B8"), 9, 2)
		legend_row.add_child(lbl)

	GameState.world_changed.connect(_update_world_title)
	_update_world_title(GameState.current_world)

func _update_world_title(w_id: String):
	var w_name = GameData.WORLDS.get(w_id, {}).get("name", w_id.capitalize())
	if title_lbl:
		title_lbl.text = "Mapa: " + w_name

func _process(delta: float):
	pulse_time += delta
	if map_canvas:
		map_canvas.queue_redraw()
