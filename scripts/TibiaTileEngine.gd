extends Node2D
class_name TibiaTileEngine

## Engine de mapa top-down baseado em cenÃ¡rios Fenaky com malha A* de navegaÃ§Ã£o, obstÃ¡culos e portais.

const TILE_SIZE: int = 32

var cols: int = 64
var rows: int = 36
var map_width: float = 2048.0
var map_height: float = 1152.0

var collision_body: StaticBody2D
var astar: AStarGrid2D

var walkable_grid: Array = []    # rows x cols (bool)
var bridge_cells: Dictionary = {} # Vector2i -> true

var portals: Array = []          # [{ "id", "target_world", "label", "pos", "required_boss", "lock_msg" }]
var arrival_points: Dictionary = {} # from_world -> Vector2
var default_spawn: Vector2 = Vector2(896.0, 512.0)
var hunt_spots: Array = []       # [{ "name", "pos", "monsters", "radius" }]
var prop_positions: Array[Vector2] = []
var minimap_texture: ImageTexture = null

func build_map(world_id: String):
	bridge_cells.clear()
	portals.clear()
	arrival_points.clear()
	hunt_spots.clear()
	prop_positions.clear()

	var fenaky_path := "res://assets/maps/" + world_id + "/fenaky_map.png"
	if not ResourceLoader.exists(fenaky_path):
		push_error("Mapa Fenaky nÃ£o encontrado: " + fenaky_path)
		return
	_build_fenaky_map(world_id, fenaky_path)

func _build_fenaky_map(world_id: String, fenaky_path: String):
	var tex := load(fenaky_path) as Texture2D
	if tex == null:
		return

	cols = 64
	rows = 36
	map_width = float(cols * TILE_SIZE)
	map_height = float(rows * TILE_SIZE)

	var bg := Sprite2D.new()
	bg.texture = tex
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.z_index = -10
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.scale = Vector2(map_width / max(1.0, float(tex.get_width())), map_height / max(1.0, float(tex.get_height())))
	add_child(bg)

	walkable_grid.clear()
	for cy in range(rows):
		var wrow: Array = []
		for _cx in range(cols):
			wrow.append(true)
		walkable_grid.append(wrow)

	collision_body = StaticBody2D.new()
	add_child(collision_body)

	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, cols, rows)
	astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

	match world_id:
		"vila":
			_configure_fenaky_vila()
		"floresta":
			_configure_fenaky_floresta()
		"caverna":
			_configure_fenaky_caverna()
		"castelo":
			_configure_fenaky_castelo()
		"cabana":
			_configure_fenaky_cabana()

	var mini_img := tex.get_image()
	if mini_img:
		mini_img.resize(128, 72, Image.INTERPOLATE_BILINEAR)
		minimap_texture = ImageTexture.create_from_image(mini_img)
	else:
		var fallback := Image.create(64, 36, false, Image.FORMAT_RGBA8)
		fallback.fill(Color("#2B5A28"))
		minimap_texture = ImageTexture.create_from_image(fallback)

func _mark_bridge_rect(x1: int, y1: int, x2: int, y2: int):
	for cy in range(max(0, y1), min(rows, y2 + 1)):
		for cx in range(max(0, x1), min(cols, x2 + 1)):
			var cc := Vector2i(cx, cy)
			bridge_cells[cc] = true
			walkable_grid[cy][cx] = true
			if astar:
				astar.set_point_solid(cc, false)

func _set_solid_cell_rect(x1: int, y1: int, x2: int, y2: int):
	for cy in range(max(0, y1), min(rows, y2 + 1)):
		for cx in range(max(0, x1), min(cols, x2 + 1)):
			if bridge_cells.has(Vector2i(cx, cy)):
				continue
			if not walkable_grid[cy][cx]:
				continue
			walkable_grid[cy][cx] = false
			astar.set_point_solid(Vector2i(cx, cy), true)
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			shape.shape = rect
			shape.position = Vector2(cx * TILE_SIZE + TILE_SIZE * 0.5, cy * TILE_SIZE + TILE_SIZE * 0.5)
			collision_body.add_child(shape)

func _add_circle_obstacle(world_pos: Vector2, radius: float):
	if radius <= 0.0:
		return
	var shape := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = radius
	shape.shape = cs
	shape.position = world_pos
	collision_body.add_child(shape)
	prop_positions.append(world_pos)
	mark_solid_prop(world_pos, radius)

func _add_flame_effect(world_pos: Vector2, flame_color: Color):
	var embers := CPUParticles2D.new()
	embers.position = world_pos
	embers.z_index = -1
	embers.amount = 16
	embers.lifetime = 0.85
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 8.0
	embers.direction = Vector2(0, -1)
	embers.spread = 28.0
	embers.gravity = Vector2.ZERO
	embers.initial_velocity_min = 16.0
	embers.initial_velocity_max = 34.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.5
	embers.color = flame_color
	add_child(embers)

func _configure_fenaky_floresta():
	default_spawn = Vector2(30 * TILE_SIZE, 18.5 * TILE_SIZE)
	arrival_points = {
		"vila": Vector2(7.5 * TILE_SIZE, 18 * TILE_SIZE),
		"caverna": Vector2(56.0 * TILE_SIZE, 18 * TILE_SIZE),
		"default": default_spawn
	}
	portals = [
		{
			"id": "portal_vila",
			"target_world": "vila",
			"label": "Vila BarÃ£o Ragnar",
			"pos": Vector2(5.0 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "",
			"lock_msg": ""
		},
		{
			"id": "portal_caverna",
			"target_world": "caverna",
			"label": "Cavernas e Minas",
			"pos": Vector2(58.5 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "toupeira_serra",
			"lock_msg": "Derrote a Toupeira Serra (Desafiar Chefe) para abrir a passagem Ã s Cavernas!"
		}
	]

	# As 3 pontes de madeira da imagem Fenaky (caminhÃ¡veis sobre o rio)
	_mark_bridge_rect(36, 8, 41, 9)
	_mark_bridge_rect(38, 17, 43, 18)
	_mark_bridge_rect(32, 29, 37, 31)

	# Bordas densas de pinheiros no perÃ­metro (mantendo corredores dos portais livres)
	_set_solid_cell_rect(0, 0, 63, 2)
	_set_solid_cell_rect(0, 33, 63, 35)
	_set_solid_cell_rect(0, 3, 2, 15)
	_set_solid_cell_rect(0, 20, 2, 32)
	_set_solid_cell_rect(61, 3, 63, 15)
	_set_solid_cell_rect(61, 20, 63, 32)

	# Rio azul em S fiel Ã  imagem Fenaky (interrompido exatamente nas 3 pontes)
	_set_solid_cell_rect(39, 0, 41, 3)
	_set_solid_cell_rect(37, 4, 40, 7)
	_set_solid_cell_rect(37, 10, 40, 12)
	_set_solid_cell_rect(38, 13, 41, 15)
	_set_solid_cell_rect(39, 16, 41, 16)
	_set_solid_cell_rect(39, 19, 42, 21)
	_set_solid_cell_rect(37, 22, 40, 25)
	_set_solid_cell_rect(34, 26, 37, 28)
	_set_solid_cell_rect(34, 32, 37, 35)

	# Elementos fÃ­sicos internos (fogueira, troncos, cratera da Toupeira Serra e Ã¡rvore central)
	_add_circle_obstacle(Vector2(960.0, 544.0), 18.0)
	_add_flame_effect(Vector2(960.0, 536.0), Color(1.0, 0.58, 0.16, 0.88))
	_add_circle_obstacle(Vector2(896.0, 544.0), 16.0)
	_add_circle_obstacle(Vector2(986.0, 608.0), 16.0)
	_add_circle_obstacle(Vector2(1720.0, 845.0), 54.0)
	_add_circle_obstacle(Vector2(1018.0, 740.0), 22.0)
	_add_circle_obstacle(Vector2(1070.0, 145.0), 26.0)

	hunt_spots = [
		{"name": "The North-West Spot", "pos": Vector2(14.0 * TILE_SIZE, 9.5 * TILE_SIZE), "label_pos": Vector2(204.0, 145.0), "monsters": ["toupeira"], "radius": 170.0},
		{"name": "South-West Spot", "pos": Vector2(14.0 * TILE_SIZE, 25.0 * TILE_SIZE), "label_pos": Vector2(348.0, 675.0), "monsters": ["zumbi", "esqueleto"], "radius": 170.0},
		{"name": "North-East Spot", "pos": Vector2(53.0 * TILE_SIZE, 9.5 * TILE_SIZE), "label_pos": Vector2(1708.0, 118.0), "monsters": ["esqueleto", "toupeira"], "radius": 170.0},
		{"name": "South-East Spot", "pos": Vector2(51.5 * TILE_SIZE, 25.5 * TILE_SIZE), "label_pos": Vector2(1388.0, 650.0), "monsters": ["toupeira", "zumbi"], "radius": 170.0}
	]

func _configure_fenaky_vila():
	default_spawn = Vector2(32.0 * TILE_SIZE, 18.0 * TILE_SIZE)
	arrival_points = {
		"floresta": Vector2(52.5 * TILE_SIZE, 18.0 * TILE_SIZE),
		"default": default_spawn
	}
	portals = [
		{
			"id": "portal_floresta",
			"target_world": "floresta",
			"label": "Floresta dos Ecos",
			"pos": Vector2(55.0 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "",
			"lock_msg": ""
		}
	]
	_mark_bridge_rect(44, 16, 52, 19)
	_set_solid_cell_rect(0, 0, 63, 1)
	_set_solid_cell_rect(0, 34, 63, 35)
	_set_solid_cell_rect(0, 2, 1, 33)
	_set_solid_cell_rect(62, 2, 63, 33)
	_set_solid_cell_rect(47, 0, 51, 15)
	_set_solid_cell_rect(47, 20, 52, 35)

	# Casas, torres, estÃ¡tua, fonte e fogueira fiÃ©is Ã  imagem Fenaky da Vila
	_add_circle_obstacle(Vector2(620.0, 205.0), 66.0)
	_add_circle_obstacle(Vector2(1310.0, 205.0), 66.0)
	_add_circle_obstacle(Vector2(505.0, 810.0), 66.0)
	_add_circle_obstacle(Vector2(1024.0, 240.0), 34.0)
	_add_circle_obstacle(Vector2(505.0, 560.0), 56.0)
	_add_circle_obstacle(Vector2(325.0, 165.0), 38.0)
	_add_circle_obstacle(Vector2(1845.0, 165.0), 38.0)
	_add_circle_obstacle(Vector2(270.0, 910.0), 38.0)
	_add_circle_obstacle(Vector2(1845.0, 910.0), 38.0)
	_add_circle_obstacle(Vector2(896.0, 915.0), 18.0)
	_add_flame_effect(Vector2(896.0, 900.0), Color(1.0, 0.58, 0.16, 0.88))

func _configure_fenaky_caverna():
	default_spawn = Vector2(28.5 * TILE_SIZE, 20.5 * TILE_SIZE)
	arrival_points = {
		"floresta": Vector2(7.0 * TILE_SIZE, 18.0 * TILE_SIZE),
		"castelo": Vector2(56.5 * TILE_SIZE, 18.0 * TILE_SIZE),
		"default": default_spawn
	}
	portals = [
		{
			"id": "portal_floresta",
			"target_world": "floresta",
			"label": "Floresta dos Ecos",
			"pos": Vector2(4.0 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "",
			"lock_msg": ""
		},
		{
			"id": "portal_castelo",
			"target_world": "castelo",
			"label": "Castelo de LunÃ¡rio",
			"pos": Vector2(60.0 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "robo_aranha",
			"lock_msg": "Derrote o RobÃ´ Aranha GuardiÃ£o (Desafiar Chefe) para abrir os portÃµes do Castelo de LunÃ¡rio!"
		}
	]

	_mark_bridge_rect(36, 8, 43, 10)
	_mark_bridge_rect(36, 17, 43, 19)
	_mark_bridge_rect(36, 28, 43, 30)

	_set_solid_cell_rect(0, 0, 63, 2)
	_set_solid_cell_rect(0, 33, 63, 35)
	_set_solid_cell_rect(0, 3, 1, 32)
	_set_solid_cell_rect(62, 3, 63, 32)

	# Rio turquesa subterrÃ¢neo interrompido exatamente nas 3 pontes
	_set_solid_cell_rect(38, 0, 41, 7)
	_set_solid_cell_rect(38, 11, 41, 16)
	_set_solid_cell_rect(38, 20, 41, 27)
	_set_solid_cell_rect(38, 31, 41, 35)

	# DivisÃ³rias naturais de rocha entre as galerias (mantendo corredores e trilhos livres)
	_set_solid_cell_rect(2, 12, 10, 14)
	_set_solid_cell_rect(14, 13, 25, 15)
	_set_solid_cell_rect(2, 21, 15, 22)
	_set_solid_cell_rect(44, 15, 54, 20)

	_add_circle_obstacle(Vector2(912.0, 560.0), 18.0)
	_add_flame_effect(Vector2(912.0, 546.0), Color(1.0, 0.58, 0.16, 0.88))

	hunt_spots = [
		{"name": "EscavaÃ§Ã£o Goblin (NO)", "pos": Vector2(15.0 * TILE_SIZE, 8.0 * TILE_SIZE), "label_pos": Vector2(360.0, 80.0), "monsters": ["humano_minerador", "toupeira"], "radius": 175.0},
		{"name": "Galeria Inferior (SO)", "pos": Vector2(14.0 * TILE_SIZE, 28.0 * TILE_SIZE), "label_pos": Vector2(380.0, 825.0), "monsters": ["humano_minerador", "robo"], "radius": 175.0},
		{"name": "Gruta dos Cristais (NE)", "pos": Vector2(52.0 * TILE_SIZE, 9.0 * TILE_SIZE), "label_pos": Vector2(1550.0, 80.0), "monsters": ["robo", "humano_minerador"], "radius": 175.0},
		{"name": "Covil da Aranha (SE)", "pos": Vector2(53.0 * TILE_SIZE, 27.0 * TILE_SIZE), "label_pos": Vector2(1540.0, 730.0), "monsters": ["robo", "humano_minerador"], "radius": 175.0}
	]

func _configure_fenaky_castelo():
	default_spawn = Vector2(31.5 * TILE_SIZE, 22.0 * TILE_SIZE)
	arrival_points = {
		"caverna": Vector2(9.0 * TILE_SIZE, 18.0 * TILE_SIZE),
		"cabana": Vector2(54.0 * TILE_SIZE, 18.0 * TILE_SIZE),
		"default": default_spawn
	}
	portals = [
		{
			"id": "portal_caverna",
			"target_world": "caverna",
			"label": "Cavernas e Minas",
			"pos": Vector2(6.5 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "",
			"lock_msg": ""
		},
		{
			"id": "portal_cabana",
			"target_world": "cabana",
			"label": "Cabana Inimiga Distante",
			"pos": Vector2(57.5 * TILE_SIZE, 18.0 * TILE_SIZE),
			"required_boss": "lunario",
			"lock_msg": "Derrote o supremo Deus DragÃ£o LunÃ¡rio para quebrar o selo e revelar a Cabana do seu pai!"
		}
	]

	# As 4 pontes douradas sobre o vazio cÃ³smico
	_mark_bridge_rect(17, 16, 26, 18)
	_mark_bridge_rect(17, 24, 26, 26)
	_mark_bridge_rect(37, 16, 46, 18)
	_mark_bridge_rect(37, 24, 46, 26)

	# Contorno espacial externo + abismos entre as plataformas em H
	_set_solid_cell_rect(0, 0, 4, 35)
	_set_solid_cell_rect(59, 0, 63, 35)
	_set_solid_cell_rect(5, 0, 16, 3)
	_set_solid_cell_rect(5, 31, 16, 35)
	_set_solid_cell_rect(47, 0, 58, 3)
	_set_solid_cell_rect(47, 31, 58, 35)
	_set_solid_cell_rect(27, 0, 36, 2)
	_set_solid_cell_rect(17, 0, 23, 35)
	_set_solid_cell_rect(24, 0, 26, 2)
	_set_solid_cell_rect(24, 11, 26, 35)
	_set_solid_cell_rect(40, 0, 46, 35)
	_set_solid_cell_rect(37, 0, 39, 2)
	_set_solid_cell_rect(37, 11, 39, 35)

	# Muros internos das alas deixando exatamente as escadas abertas
	_set_solid_cell_rect(5, 13, 7, 13)
	_set_solid_cell_rect(10, 13, 11, 13)
	_set_solid_cell_rect(14, 13, 16, 13)
	_set_solid_cell_rect(5, 22, 11, 22)
	_set_solid_cell_rect(14, 22, 16, 22)
	_set_solid_cell_rect(47, 13, 49, 13)
	_set_solid_cell_rect(52, 13, 53, 13)
	_set_solid_cell_rect(56, 13, 58, 13)
	_set_solid_cell_rect(47, 22, 49, 22)
	_set_solid_cell_rect(52, 22, 58, 22)

	# Trono, gÃ¡rgulas e braseiros cÃ³smicos
	_add_circle_obstacle(Vector2(1008.0, 175.0), 34.0)
	_add_circle_obstacle(Vector2(805.0, 240.0), 28.0)
	_add_circle_obstacle(Vector2(1225.0, 240.0), 28.0)
	_add_flame_effect(Vector2(842.0, 136.0), Color(0.75, 0.30, 1.0, 0.85))
	_add_flame_effect(Vector2(1190.0, 136.0), Color(0.75, 0.30, 1.0, 0.85))
	_add_flame_effect(Vector2(875.0, 922.0), Color(0.75, 0.30, 1.0, 0.85))
	_add_flame_effect(Vector2(1156.0, 922.0), Color(0.75, 0.30, 1.0, 0.85))

	hunt_spots = [
		{"name": "Cripta Esqueleto", "pos": Vector2(10.5 * TILE_SIZE, 9.0 * TILE_SIZE), "label_pos": Vector2(215.0, 108.0), "monsters": ["esqueleto", "fantasma", "espectro_slime"], "radius": 165.0},
		{"name": "SalÃ£o dos Ossos", "pos": Vector2(10.5 * TILE_SIZE, 26.5 * TILE_SIZE), "label_pos": Vector2(125.0, 622.0), "monsters": ["esqueleto", "robo"], "radius": 165.0},
		{"name": "SalÃ£o dos GuardiÃµes", "pos": Vector2(52.5 * TILE_SIZE, 9.0 * TILE_SIZE), "label_pos": Vector2(1602.0, 108.0), "monsters": ["fantasma", "robo", "espectro_slime"], "radius": 165.0},
		{"name": "SalÃ£o Lunar", "pos": Vector2(52.5 * TILE_SIZE, 26.5 * TILE_SIZE), "label_pos": Vector2(1720.0, 622.0), "monsters": ["robo", "fantasma", "espectro_slime"], "radius": 165.0}
	]

func _configure_fenaky_cabana():
	default_spawn = Vector2(30.0 * TILE_SIZE, 22.5 * TILE_SIZE)
	arrival_points = {
		"castelo": Vector2(9.0 * TILE_SIZE, 22.0 * TILE_SIZE),
		"default": default_spawn
	}
	portals = [
		{
			"id": "portal_castelo",
			"target_world": "castelo",
			"label": "Castelo de LunÃ¡rio",
			"pos": Vector2(5.5 * TILE_SIZE, 20.5 * TILE_SIZE),
			"required_boss": "",
			"lock_msg": ""
		}
	]

	_mark_bridge_rect(13, 21, 28, 24)
	_set_solid_cell_rect(0, 0, 63, 4)
	_set_solid_cell_rect(0, 31, 63, 35)
	_set_solid_cell_rect(0, 5, 2, 16)
	_set_solid_cell_rect(0, 25, 2, 30)
	_set_solid_cell_rect(58, 5, 63, 30)

	# Rio tranquilo a oeste interrompido na ponte larga
	_set_solid_cell_rect(17, 0, 22, 8)
	_set_solid_cell_rect(15, 9, 22, 20)
	_set_solid_cell_rect(11, 25, 19, 35)

	_add_circle_obstacle(Vector2(1500.0, 440.0), 105.0)
	_add_circle_obstacle(Vector2(1120.0, 512.0), 20.0)
	_add_flame_effect(Vector2(1120.0, 496.0), Color(1.0, 0.65, 0.20, 0.88))

func get_arrival_pos(from_world: String) -> Vector2:
	if arrival_points.has(from_world):
		return arrival_points[from_world]
	return default_spawn

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(world_pos.x / TILE_SIZE), 0, cols - 1),
		clampi(int(world_pos.y / TILE_SIZE), 0, rows - 1)
	)

func is_world_pos_walkable(world_pos: Vector2) -> bool:
	var c := world_to_cell(world_pos)
	return bool(walkable_grid[c.y][c.x])

func mark_solid_prop(world_pos: Vector2, radius: float):
	if astar == null:
		return
	var safe_margin := radius + 10.0
	var r_cells := int(ceil(safe_margin / TILE_SIZE))
	var center := world_to_cell(world_pos)
	for dy in range(-r_cells, r_cells + 1):
		for dx in range(-r_cells, r_cells + 1):
			var cc := Vector2i(center.x + dx, center.y + dy)
			if cc.x >= 0 and cc.x < cols and cc.y >= 0 and cc.y < rows:
				if bridge_cells.has(cc):
					continue
				var cell_center := Vector2(cc.x * TILE_SIZE + 16.0, cc.y * TILE_SIZE + 16.0)
				if cell_center.distance_to(world_pos) <= safe_margin:
					astar.set_point_solid(cc, true)

func find_nearest_walkable_cell(target: Vector2i) -> Vector2i:
	var clamped := Vector2i(clampi(target.x, 0, cols - 1), clampi(target.y, 0, rows - 1))
	if not astar.is_point_solid(clamped) and walkable_grid[clamped.y][clamped.x]:
		return clamped
	for radius in range(1, 14):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cc := Vector2i(clamped.x + dx, clamped.y + dy)
				if cc.x >= 0 and cc.x < cols and cc.y >= 0 and cc.y < rows:
					if not astar.is_point_solid(cc) and walkable_grid[cc.y][cc.x]:
						return cc
	return clamped

func is_reachable(from_pos: Vector2, to_pos: Vector2) -> bool:
	if astar == null:
		return true
	var start_c := find_nearest_walkable_cell(world_to_cell(from_pos))
	var end_c := find_nearest_walkable_cell(world_to_cell(to_pos))
	if start_c == end_c:
		return true
	return not astar.get_id_path(start_c, end_c).is_empty()

func get_path_cost(from_pos: Vector2, to_pos: Vector2) -> float:
	if astar == null:
		return from_pos.distance_to(to_pos)
	var start_c := find_nearest_walkable_cell(world_to_cell(from_pos))
	var end_c := find_nearest_walkable_cell(world_to_cell(to_pos))
	if start_c == end_c:
		return from_pos.distance_to(to_pos)
	var cell_path := astar.get_id_path(start_c, end_c)
	if cell_path.is_empty():
		return INF
	return float(cell_path.size() * TILE_SIZE)

func find_world_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	if astar == null:
		return PackedVector2Array([to_pos])
	var start_c := find_nearest_walkable_cell(world_to_cell(from_pos))
	var end_c := find_nearest_walkable_cell(world_to_cell(to_pos))
	var out := PackedVector2Array()
	if start_c == end_c:
		out.append(Vector2(end_c.x * TILE_SIZE + 16.0, end_c.y * TILE_SIZE + 16.0))
		return out
	var cell_path := astar.get_id_path(start_c, end_c)
	for idx in range(cell_path.size()):
		if idx == 0:
			continue
		var c := cell_path[idx]
		out.append(Vector2(c.x * TILE_SIZE + 16.0, c.y * TILE_SIZE + 16.0))
	return out
