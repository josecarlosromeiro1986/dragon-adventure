extends Control

## Tela inicial de Dragon Adventure com vitrine heroica, resumo do progresso e atalhos.

signal continue_requested
signal start_new_requested
signal settings_requested

var _summary_lbl: Label
var _primary_btn: Button
var _new_btn: Button
var _bob_t: float = 0.0
var _hero_tex: TextureRect
var _boss_tex: TextureRect

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	_build_ui()
	refresh_state()

func _build_ui():
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.05, 0.80)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(660, 440)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", MedievalUI.panel_box("gold", 30, 26))
	center.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "DRAGON ADVENTURE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 30, 4)
	vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "O Último Herói da Vila Barão Ragnar"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(sub_lbl, Color("#F5E6C8"), 15, 2)
	vbox.add_child(sub_lbl)

	# Vitrine Heroi vs Deus Dragao
	var showcase = PanelContainer.new()
	showcase.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 16, 12))
	vbox.add_child(showcase)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	showcase.add_child(row)

	_hero_tex = TextureRect.new()
	_hero_tex.texture = SpriteFactory.get_character_texture("daniel_ragnar", "south")
	_hero_tex.custom_minimum_size = Vector2(82, 82)
	_hero_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_hero_tex)

	var crest = TextureRect.new()
	var crest_tex = SpriteFactory.get_item_icon("weapon_sword")
	crest.texture = crest_tex if crest_tex else MedievalUI.tex("icon_boss_crest")
	crest.custom_minimum_size = Vector2(44, 44)
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(crest)

	_boss_tex = TextureRect.new()
	_boss_tex.texture = SpriteFactory.get_character_texture("lunario", "south")
	_boss_tex.custom_minimum_size = Vector2(82, 82)
	_boss_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boss_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_boss_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_boss_tex)

	# Cartão de Resumo / Lore
	var info_panel = PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 16, 10))
	vbox.add_child(info_panel)

	_summary_lbl = Label.new()
	_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(_summary_lbl, Color("#24160A"), 13, 0)
	info_panel.add_child(_summary_lbl)

	# Botões principais
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_box)

	_primary_btn = Button.new()
	_primary_btn.custom_minimum_size = Vector2(320, 40)
	_primary_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MedievalUI.style_button(_primary_btn, "gold", "", 15, 40)
	var sword_icon = SpriteFactory.get_item_icon("weapon_sword")
	if sword_icon:
		_primary_btn.icon = sword_icon
		_primary_btn.add_theme_constant_override("icon_max_width", 22)
	_primary_btn.pressed.connect(func():
		visible = false
		continue_requested.emit()
	)
	btn_box.add_child(_primary_btn)

	var secondary_row = HBoxContainer.new()
	secondary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary_row.add_theme_constant_override("separation", 12)
	btn_box.add_child(secondary_row)

	_new_btn = Button.new()
	_new_btn.text = "Nova Aventura"
	MedievalUI.style_button(_new_btn, "crimson", "", 12, 34)
	_new_btn.pressed.connect(func():
		start_new_requested.emit()
	)
	secondary_row.add_child(_new_btn)

	var cfg_btn = Button.new()
	cfg_btn.text = "Configurações & Som"
	MedievalUI.style_button(cfg_btn, "stone", "icon_sound", 12, 34)
	cfg_btn.pressed.connect(func():
		settings_requested.emit()
	)
	secondary_row.add_child(cfg_btn)

	var version_lbl = Label.new()
	version_lbl.text = "Versão v%s  •  Godot WebGL" % GameData.get_game_version()
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(version_lbl, Color("#B9A682"), 11, 1)
	vbox.add_child(version_lbl)

func refresh_state():
	if not is_instance_valid(_summary_lbl):
		return
	if GameState.has_saved_progress():
		var w_name := str(GameData.WORLDS.get(GameState.current_world, {}).get("name", GameState.current_world))
		var bosses_done := GameState.get_defeated_boss_count()
		_summary_lbl.text = "Progresso Salvo: Nível %d  •  $ %d Notas  •  Chefes: %d / 6\nZona Atual: %s" % [GameState.level, GameState.cash_notes, bosses_done, w_name]
		_primary_btn.text = "Continuar Aventura"
		_new_btn.visible = true
	else:
		_summary_lbl.text = "Ajude Daniel Ragnar a enfrentar as hordas de monstros, derrotar os 6 chefes do reino e resgatar seu pai aprisionado pelo Deus Dragão Lunário!"
		_primary_btn.text = "Iniciar Aventura"
		_new_btn.visible = false

func _process(delta: float):
	if not visible:
		return
	_bob_t += delta
	if _hero_tex:
		_hero_tex.position.y = sin(_bob_t * 2.8) * 2.5
	if _boss_tex:
		_boss_tex.position.y = cos(_bob_t * 2.8) * 2.5
