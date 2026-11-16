extends Window

## Mapa-múndi interativo para viagem rápida entre zonas desbloqueadas.

@onready var container = $Margin/VBox/Scroll/WorldsVBox
@onready var close_btn = $Margin/VBox/Header/CloseBtn
@onready var title_lbl = $Margin/VBox/Header/Title

const WORLD_ICON_PROPS := {
	"vila": "vila_house",
	"floresta": "floresta_campfire",
	"caverna": "caverna_crystal",
	"castelo": "castelo_throne",
	"cabana": "cabana_fence"
}

func _ready():
	MedievalUI.setup_modal_chrome(self, "stone", 26, 24)
	$Margin/VBox.add_theme_constant_override("separation", 10)
	title_lbl.text = "SELECIONE SEU DESTINO"
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)
	MedievalUI.style_button(close_btn, "crimson", "", 12, 30)
	close_btn.pressed.connect(func(): hide())
	close_requested.connect(func(): hide())
	populate_worlds()

func open():
	populate_worlds()
	popup_centered(Vector2i(620, 480))

func populate_worlds():
	for c in container.get_children():
		c.queue_free()
	container.add_theme_constant_override("separation", 8)

	for w_id in GameData.WORLDS.keys():
		var w = GameData.WORLDS[w_id]
		var is_unlocked = GameState.unlocked_worlds.get(w_id, false)
		var is_current = (GameState.current_world == w_id)

		var card = PanelContainer.new()
		var variant = "parchment" if is_unlocked else "stone"
		var tint = Color(1.06, 1.03, 0.96) if is_current else (Color.WHITE if is_unlocked else Color(0.75, 0.72, 0.72, 0.95))
		card.add_theme_stylebox_override("panel", MedievalUI.panel_box(variant, 10, 8, tint))
		container.add_child(card)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		var slot = PanelContainer.new()
		slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 4, 4))
		slot.custom_minimum_size = Vector2(44, 44)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(slot)

		var icon_tex: Texture2D = null
		if is_unlocked:
			var obj_name = WORLD_ICON_PROPS.get(w_id, "")
			if obj_name != "":
				icon_tex = SpriteFactory.get_object_texture(obj_name)
			if not icon_tex:
				icon_tex = SpriteFactory.get_obstacle_texture(w_id)
		else:
			icon_tex = MedievalUI.tex("icon_padlock")

		if icon_tex:
			var icon_r = TextureRect.new()
			icon_r.texture = icon_tex
			icon_r.custom_minimum_size = Vector2(32, 32)
			icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot.add_child(icon_r)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)

		var name_lbl = Label.new()
		name_lbl.text = w.name + (" [ATUAL]" if is_current else "")
		if is_unlocked:
			MedievalUI.style_label(name_lbl, Color("#6B3F0A") if is_current else Color("#24160A"), 14, 0)
		else:
			MedievalUI.style_label(name_lbl, Color("#B0A8A0"), 14, 2)

		var desc_lbl = Label.new()
		desc_lbl.text = w.desc if is_unlocked else "[BLOQUEADO] Derrote o Chefe anterior para liberar"
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_unlocked:
			MedievalUI.style_label(desc_lbl, Color("#5A3B22"), 11, 0)
		else:
			MedievalUI.style_label(desc_lbl, Color("#998888"), 11, 2)

		vbox.add_child(name_lbl)
		vbox.add_child(desc_lbl)

		var btn = Button.new()
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if is_current:
			btn.text = "Aqui"
			btn.disabled = true
			MedievalUI.style_button(btn, "gold", "", 12, 32)
		elif is_unlocked:
			btn.text = "Viajar >>"
			MedievalUI.style_button(btn, "green", "", 12, 32)
			btn.pressed.connect(func():
				GameState.set_world(w_id)
				hide()
			)
		else:
			btn.text = "Bloqueado"
			btn.disabled = true
			MedievalUI.style_button(btn, "stone", "icon_padlock", 11, 32)

		hbox.add_child(vbox)
		hbox.add_child(btn)
