extends Area2D

## Projétil disparado por inimigos e chefes (inclui slime_orb e plasma_bolt).

var direction: Vector2 = Vector2.DOWN
var speed: float = 260.0
var damage: int = 25
var proj_color: Color = Color("#FF4500")
var proj_radius: float = 10.0
var spell_sprite_id: String = ""
var spin_speed: float = 0.0
var lifetime: float = 3.0
var sprite: Sprite2D
var hit_processed: bool = false
var _map_bounds: Vector2 = Vector2(2048.0, 1152.0)

func setup(p_dir: Vector2, p_damage: int, p_speed: float = 260.0, p_color: Color = Color("#FF4500"), p_radius: float = 10.0, p_sprite_id: String = "", p_spin: float = 0.0):
	direction = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.DOWN
	damage = p_damage
	speed = p_speed
	proj_color = p_color
	proj_radius = p_radius
	spell_sprite_id = p_sprite_id
	spin_speed = p_spin

func _ready():
	sprite = Sprite2D.new()
	var tex: Texture2D = null
	if spell_sprite_id != "" and not (spell_sprite_id in ["slime_orb", "plasma_bolt"]):
		tex = SpriteFactory.get_spell_texture(spell_sprite_id)

	if spell_sprite_id == "slime_orb":
		var sz = 24
		var half = 12.0
		var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
		for x in range(sz):
			for y in range(sz):
				var p = Vector2(x - half, y - half)
				var wobble = sin(atan2(p.y, p.x) * 3.0) * 1.6
				var d = p.length() + wobble
				if d <= 4.2:
					img.set_pixel(x, y, Color("#F3E8FF"))
				elif d <= 8.6:
					img.set_pixel(x, y, proj_color)
				elif d <= 10.2:
					img.set_pixel(x, y, Color("#4C1D95"))
		# Pequenas gotas de slime ao redor da esfera
		img.set_pixel(4, 17, Color("#C084FC"))
		img.set_pixel(19, 18, Color("#C084FC"))
		sprite.texture = ImageTexture.create_from_image(img)
	elif spell_sprite_id == "plasma_bolt":
		var w = 28
		var h = 16
		var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		for x in range(w):
			for y in range(h):
				var dx = (float(x) - 14.0) / 12.0
				var dy = (float(y) - 8.0) / 5.5
				var ed = sqrt(dx * dx + dy * dy)
				if ed <= 0.45:
					img.set_pixel(x, y, Color.WHITE)
				elif ed <= 0.85:
					img.set_pixel(x, y, proj_color)
				elif ed <= 1.0:
					img.set_pixel(x, y, Color(proj_color.r, proj_color.g, proj_color.b, 0.55))
		sprite.texture = ImageTexture.create_from_image(img)
		sprite.rotation = direction.angle()
	elif tex:
		sprite.texture = tex
		sprite.modulate = proj_color
		sprite.rotation = direction.angle()
	else:
		var sz = int(proj_radius * 2.4)
		var half = sz * 0.5
		var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
		for x in range(sz):
			for y in range(sz):
				var d = Vector2(x - half, y - half).length()
				if d <= proj_radius * 0.55:
					img.set_pixel(x, y, Color.WHITE)
				elif d <= proj_radius:
					img.set_pixel(x, y, proj_color)
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	var trail = CPUParticles2D.new()
	trail.z_index = -1
	trail.amount = 14
	trail.lifetime = 0.25
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 4.0
	trail.direction = -direction
	trail.spread = 30.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 12.0
	trail.initial_velocity_max = 36.0
	trail.scale_amount_min = 2.5
	trail.scale_amount_max = 4.5
	trail.color = proj_color
	add_child(trail)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = proj_radius
	shape.shape = circle
	add_child(shape)

	_map_bounds = GameData.get_map_bounds(get_tree().current_scene)
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if sprite and spin_speed != 0.0:
		sprite.rotation += spin_speed * delta
	global_position += direction * speed * delta
	if global_position.x < 16.0 or global_position.x > _map_bounds.x - 16.0 or global_position.y < 16.0 or global_position.y > _map_bounds.y - 16.0:
		queue_free()

func _on_body_entered(body):
	if hit_processed:
		return
	if body.is_in_group("player") or body is StaticBody2D:
		hit_processed = true
		set_deferred("monitoring", false)
		call_deferred("_resolve_hit", body)

func _resolve_hit(body):
	if is_instance_valid(body) and body.is_in_group("player"):
		GameState.take_damage(damage)
	_spawn_impact_burst()
	queue_free()

func _spawn_impact_burst():
	if not get_parent():
		return
	var burst = CPUParticles2D.new()
	burst.global_position = global_position
	burst.one_shot = true
	burst.explosiveness = 0.90
	burst.amount = 14
	burst.lifetime = 0.30
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 35.0
	burst.initial_velocity_max = 95.0
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 5.0
	burst.color = proj_color
	get_parent().add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
