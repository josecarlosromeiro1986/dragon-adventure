extends Node2D
class_name FloatingText

## Texto flutuante animado estilo Tibia / Poke Idle exibido em combate e coleta.

static func spawn(parent: Node, world_pos: Vector2, text: String, color: Color = Color.WHITE, is_crit: bool = false):
	## Instancia e exibe um texto flutuante já anexado à árvore de cena.
	if not is_instance_valid(parent):
		return
	var ft := FloatingText.new()
	ft.global_position = world_pos
	parent.add_child(ft)
	ft.setup(text, color, is_crit)

func setup(text: String, color: Color = Color.WHITE, is_crit: bool = false):
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-50, -25)

	if is_crit:
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 4)
	else:
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 2)

	add_child(lbl)

	# Efeito de salto pop-up estilo Tibia / Poke Idle
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2 if is_crit else 1.0, 1.2 if is_crit else 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", position + Vector2(randf_range(-15, 15), -45), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.2)
	tween.tween_callback(queue_free)
