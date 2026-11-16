extends Area2D

## Cédula de dinheiro dropada por monstros e coletada por atração magnética.

var value: int = 10
var target = null
var current_velocity: Vector2 = Vector2.ZERO
var max_speed: float = 550.0
var acceleration: float = 1200.0
var lifetime: float = 0.0
var sprite: Sprite2D
var collected: bool = false

func _ready():
	add_to_group("cash_notes")
	sprite = Sprite2D.new()
	sprite.texture = SpriteFactory.get_cash_note_texture()
	add_child(sprite)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 28.0 # Raio de coleta maior e mais responsivo
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)

	# Efeito de expulsão / salto da cédula ao surgir do monstro
	var jump_angle = randf() * TAU
	var jump_dist = randf_range(30, 60)
	var target_pos = position + Vector2(cos(jump_angle), sin(jump_angle)) * jump_dist
	
	scale = Vector2(0.2, 0.2)
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta: float):
	lifetime += delta
	if not target:
		sprite.rotation = sin(lifetime * 4.0) * 0.15
		# Atração magnética automática se Daniel estiver a menos de 140px
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and is_instance_valid(players[0]):
			if global_position.distance_to(players[0].global_position) < 140.0:
				target = players[0]
	else:
		if not is_instance_valid(target):
			target = null
			current_velocity = Vector2.ZERO
			return
		# Atração magnética curvada suave e veloz
		var diff = target.global_position - global_position
		var dist = diff.length()
		var desired_vel = diff.normalized() * max_speed
		current_velocity = current_velocity.move_toward(desired_vel, acceleration * delta)
		global_position += current_velocity * delta

		# Efeito de rotação acompanhando o arco de atração
		sprite.rotation = current_velocity.angle()
		# Encolhe levemente ao entrar na mochila
		if dist < 50.0:
			scale = Vector2(dist / 50.0, dist / 50.0)

		if dist < 22.0 and not collected:
			collected = true
			set_deferred("monitoring", false)
			call_deferred("collect")

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		target = body

func collect():
	GameState.add_cash(value)
	HuntAnalyzerData.record_cash_collected(value)
	AudioManager.play_sfx("cash_pickup")
	
	# Mini texto flutuante verde "+X Notas"
	FloatingText.spawn(get_parent(), global_position, "+" + str(value) + " Notas", Color("#85BB65"), false)
	queue_free()
