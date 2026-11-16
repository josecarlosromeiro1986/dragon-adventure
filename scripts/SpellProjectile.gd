extends Area2D

## Projétil elemental conjurado por Daniel (Bola de Fogo, Tornado e Bomba de Água).

var spell_id: String = "fireball"
var direction: Vector2 = Vector2.DOWN
var speed: float = 380.0
var damage: int = 45
var element: String = "fire"
var lifetime: float = 2.2
var sprite: Sprite2D
var hit_processed: bool = false
var _map_bounds: Vector2 = Vector2(2048.0, 1152.0)

func setup(s_id: String, dir: Vector2):
	spell_id = s_id
	direction = dir.normalized()
	var s_data = GameData.SPELLS[spell_id]
	damage = s_data.damage
	element = s_data.element

func _ready():
	collision_mask = 3
	sprite = Sprite2D.new()
	var col = Color("#FF4500")
	if element == "wind":
		col = Color("#E0FFFF")
	elif element == "water":
		col = Color("#00BFFF")

	var spell_tex = SpriteFactory.get_spell_texture(spell_id)
	if spell_tex:
		sprite.texture = spell_tex
	else:
		var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
		for x in range(20):
			for y in range(20):
				if Vector2(x-10, y-10).length() <= 8:
					img.set_pixel(x, y, col)
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	# Rastro Elemental Contínuo da Magia
	var trail = CPUParticles2D.new()
	trail.z_index = -1
	trail.amount = 16
	trail.lifetime = 0.25
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 5.0
	trail.direction = -direction
	trail.spread = 35.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 15.0
	trail.initial_velocity_max = 45.0
	trail.scale_amount_min = 2.5
	trail.scale_amount_max = 5.0
	trail.color = col
	add_child(trail)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)

	_map_bounds = GameData.get_map_bounds(get_tree().current_scene)
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx("magic_" + spell_id)

func _process(delta: float):
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if sprite and spell_id == "tornado":
		sprite.rotation += 12.0 * delta
	global_position += direction * speed * delta
	if global_position.x < 10.0 or global_position.x > _map_bounds.x - 10.0 or global_position.y < 10.0 or global_position.y > _map_bounds.y - 10.0:
		queue_free()

func _on_body_entered(body):
	if hit_processed:
		return
	if body.is_in_group("monsters") or body is StaticBody2D:
		hit_processed = true
		set_deferred("monitoring", false)
		call_deferred("_resolve_hit", body)

func _resolve_hit(body):
	if not is_instance_valid(body):
		queue_free()
		return
	if body.is_in_group("monsters"):
		var mult = GameData.get_elemental_multiplier(element, body.monster_id)
		var final_dmg = int(damage * mult)
		body.take_damage(final_dmg, mult > 1.0, global_position)
		_spawn_impact_burst()
		if mult > 1.0:
			GameState.trigger_shake(8.5, 0.20)
			GameState.trigger_hitstop(0.045)
		else:
			GameState.trigger_shake(4.2, 0.12)
		queue_free()
	elif body is StaticBody2D:
		_spawn_impact_burst()
		queue_free()

func _spawn_impact_burst():
	if not get_parent():
		return
	var col = Color("#FF4500")
	if element == "wind":
		col = Color("#E0FFFF")
	elif element == "water":
		col = Color("#00BFFF")
	var burst = CPUParticles2D.new()
	burst.global_position = global_position
	burst.one_shot = true
	burst.explosiveness = 0.90
	burst.amount = 20
	burst.lifetime = 0.35
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 110.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 6.0
	burst.color = col
	get_parent().add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
