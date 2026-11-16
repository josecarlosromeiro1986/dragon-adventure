extends Node2D

## Zona de perigo telegrafada em área usada por ataques especiais dos chefes.

var radius: float = 84.0
var delay: float = 0.95
var elapsed: float = 0.0
var damage: int = 40
var hazard_color: Color = Color("#FF4500")
var sfx_name: String = "magic_fireball"
var detonated: bool = false

func setup(p_radius: float, p_delay: float, p_damage: int, p_color: Color = Color("#FF4500"), p_sfx: String = "magic_fireball"):
	radius = p_radius
	delay = max(0.25, p_delay)
	damage = p_damage
	hazard_color = p_color
	sfx_name = p_sfx
	z_index = -1

func _process(delta: float):
	if detonated:
		return
	elapsed += delta
	queue_redraw()
	if elapsed >= delay:
		_detonate()

func _draw():
	var progress = clamp(elapsed / delay, 0.0, 1.0)
	var fill_col = Color(hazard_color.r, hazard_color.g, hazard_color.b, 0.16 + progress * 0.24)
	var ring_col = Color(hazard_color.r, hazard_color.g, hazard_color.b, 0.92)
	draw_circle(Vector2.ZERO, radius, fill_col)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring_col, 3.0, true)
	draw_circle(Vector2.ZERO, radius * progress, Color(hazard_color.r, hazard_color.g, hazard_color.b, 0.28))

func _detonate():
	detonated = true
	AudioManager.play_sfx(sfx_name)
	GameState.trigger_shake(7.5, 0.20)

	# Verifica se Daniel ainda está dentro da área no momento da explosão
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= radius + 10.0:
			GameState.take_damage(damage)

	if get_parent():
		var burst = CPUParticles2D.new()
		burst.global_position = global_position
		burst.one_shot = true
		burst.explosiveness = 0.92
		burst.amount = 28
		burst.lifetime = 0.45
		burst.spread = 180.0
		burst.gravity = Vector2.ZERO
		burst.initial_velocity_min = 60.0
		burst.initial_velocity_max = 165.0
		burst.scale_amount_min = 4.0
		burst.scale_amount_max = 8.0
		burst.color = hazard_color.lightened(0.2)
		get_parent().add_child(burst)
		burst.emitting = true
		burst.finished.connect(burst.queue_free)

	queue_free()
