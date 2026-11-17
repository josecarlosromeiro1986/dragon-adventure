extends Area2D
class_name ZonePortal

## Portal físico inter-zonas com validação de chefe desbloqueador e suporte a clique.

signal portal_triggered(portal_data: Dictionary)

var portal_data: Dictionary = {}
var is_locked: bool = false
var sprite: Sprite2D
var info_label: Label
var particles: CPUParticles2D
var grace_timer: float = 0.85
var cooldown_timer: float = 0.0

func setup(data: Dictionary):
	add_to_group("portals")
	portal_data = data
	position = data.get("pos", Vector2.ZERO)

	var req_boss: String = str(data.get("required_boss", ""))
	is_locked = req_boss != "" and not GameState.defeated_bosses.get(req_boss, false)

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	col.shape = circle
	add_child(col)

	sprite = Sprite2D.new()
	sprite.texture = SpriteFactory.get_object_texture("portal_gate")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.35, 1.35)
	if is_locked:
		sprite.modulate = Color(0.85, 0.40, 0.40, 0.92)
	add_child(sprite)

	particles = CPUParticles2D.new()
	particles.position = Vector2(0, -6)
	particles.amount = 14
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 18.0
	particles.direction = Vector2(0, -1)
	particles.spread = 35.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 14.0
	particles.initial_velocity_max = 32.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.35, 0.35, 0.75) if is_locked else Color(0.25, 0.92, 1.0, 0.80)
	add_child(particles)

	info_label = Label.new()
	info_label.text = str(data.get("label", "Portal")) + (" [SELADO]" if is_locked else "")
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.custom_minimum_size = Vector2(220, 22)
	info_label.position = Vector2(-110, -66)
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color("#FF7B7B") if is_locked else Color("#66F2FF"))
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 3)
	add_child(info_label)

	body_entered.connect(_on_body_entered)
	input_pickable = true
	input_event.connect(_on_input_event)

func _process(delta: float):
	if grace_timer > 0.0:
		grace_timer -= delta
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	if is_locked:
		var req_boss: String = str(portal_data.get("required_boss", ""))
		if req_boss != "" and GameState.defeated_bosses.get(req_boss, false):
			is_locked = false
			if sprite:
				sprite.modulate = Color.WHITE
			if particles:
				particles.color = Color(0.25, 0.92, 1.0, 0.80)
			if info_label:
				info_label.text = str(portal_data.get("label", "Portal"))
				info_label.add_theme_color_override("font_color", Color("#66F2FF"))

func _on_body_entered(body: Node):
	if grace_timer > 0.0 or cooldown_timer > 0.0:
		return
	if not body.is_in_group("player"):
		return
	# Evita sair acidentalmente da zona enquanto Auto-Hunt persegue monstros na borda
	if GameState.auto_hunt_enabled:
		return
	cooldown_timer = 1.8
	portal_triggered.emit(portal_data)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if get_tree().paused:
		return
	var clicked: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var tapped: bool = (event is InputEventScreenTouch and event.pressed)
	if clicked or tapped:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]):
			if players[0].global_position.distance_to(global_position) <= 130.0:
				portal_triggered.emit(portal_data)
			elif players[0].has_method("set_click_destination"):
				players[0].set_click_destination(global_position)
