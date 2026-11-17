extends Window

## Bestiário Ilustrado exibindo monstros comuns, chefes, fraquezas e contagem de abates.

var summary_lbl: Label
var common_vbox: VBoxContainer
var boss_vbox: VBoxContainer

const BOSS_SKILLS_DESC = {
	"lobisomem": "Investida Feroz telegrafada",
	"toupeira_serra": "Investida + Leque de 3 Serras",
	"robo_toupeira_serra": "Serras Radiais + Choque Sísmico AoE",
	"robo_aranha": "Salva de Lasers + Teia Elétrica AoE",
	"dragao": "Baforada de Fogo + Meteoros AoE",
	"lunario": "Rajada Cósmica (360° Fúria) + Tempestade Estelar"
}

func _ready():
	title = "Bestiário Ilustrado de Dragon Adventure"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	size = Vector2i(860, 520)
	visible = false
	close_requested.connect(func(): hide())

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	MedievalUI.setup_modal_chrome(self, "stone", 26, 24)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	var book_tex = MedievalUI.tex("icon_bestiary_book")
	if book_tex:
		var br = TextureRect.new()
		br.texture = book_tex
		br.custom_minimum_size = Vector2(28, 28)
		br.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		br.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		br.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(br)

	var title_lbl = Label.new()
	title_lbl.text = "BESTIÁRIO ILUSTRADO"
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)
	header.add_child(title_lbl)

	var sum_badge = PanelContainer.new()
	sum_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sum_badge.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 10, 4))
	header.add_child(sum_badge)

	summary_lbl = Label.new()
	summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(summary_lbl, Color("#24160A"), 12, 0)
	sum_badge.add_child(summary_lbl)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	MedievalUI.style_button(close_btn, "crimson", "", 12, 30)
	close_btn.pressed.connect(func(): hide())
	header.add_child(close_btn)
	vbox.add_child(header)

	# Páginas abertas lado a lado: Monstros à esquerda, Chefes à direita
	var pages_hbox = HBoxContainer.new()
	pages_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(pages_hbox)

	common_vbox = _create_book_page(pages_hbox, "MONSTROS DAS ZONAS DE CAÇADA", Color("#3B2310"), Color("#FFFDF7"))
	boss_vbox = _create_book_page(pages_hbox, "CHEFES LENDÁRIOS", Color("#7C2D12"), Color(1.0, 0.96, 0.88))

func _create_book_page(parent: HBoxContainer, heading: String, title_col: Color, page_tint: Color) -> VBoxContainer:
	var page = PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 14, 12, page_tint))
	parent.add_child(page)

	var p_vbox = VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 8)
	page.add_child(p_vbox)

	var h_lbl = Label.new()
	h_lbl.text = heading
	h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(h_lbl, title_col, 13, 0)
	p_vbox.add_child(h_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p_vbox.add_child(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 7)
	scroll.add_child(list_vbox)
	return list_vbox

func open():
	populate_bestiary()
	MedievalUI.popup_fit(self, Vector2i(860, 520))

func populate_bestiary():
	for c in common_vbox.get_children():
		c.queue_free()
	for c in boss_vbox.get_children():
		c.queue_free()

	var common_ids: Array[String] = []
	var boss_ids: Array[String] = []
	var discovered_count = 0

	for m_id in GameData.MONSTERS.keys():
		var m_data = GameData.MONSTERS[m_id]
		var kills = int(GameState.bestiary_kills.get(m_id, 0))
		if kills > 0 or GameState.defeated_bosses.get(m_id, false):
			discovered_count += 1
		if m_data.get("is_boss", false):
			boss_ids.append(m_id)
		else:
			common_ids.append(m_id)

	var defeated_bosses_cnt = GameState.get_defeated_boss_count()
	summary_lbl.text = "Catalogados: %d/%d   |   Chefes: %d/%d   |   Abates: %d" % [
		discovered_count, GameData.MONSTERS.size(),
		defeated_bosses_cnt, boss_ids.size(),
		GameState.total_kills_all_time
	]

	for m_id in common_ids:
		_add_monster_card(common_vbox, m_id, GameData.MONSTERS[m_id])
	for m_id in boss_ids:
		_add_monster_card(boss_vbox, m_id, GameData.MONSTERS[m_id])

func _add_monster_card(target_vbox: VBoxContainer, m_id: String, m_data: Dictionary):
	var is_boss = bool(m_data.get("is_boss", false))
	var kills = int(GameState.bestiary_kills.get(m_id, 0))
	var is_defeated_boss = is_boss and GameState.defeated_bosses.get(m_id, false)
	var discovered = kills > 0 or is_defeated_boss

	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.89, 0.74, 0.82) if not is_boss else Color(0.92, 0.83, 0.65, 0.90)
	sb.border_color = Color("#B45309") if is_defeated_boss else (Color("#7C2D12") if is_boss else Color("#8B6D43"))
	sb.set_border_width_all(2 if is_boss else 1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	target_vbox.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	# Retrato PixelLab em moldura de slot
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 4, 4))
	slot.custom_minimum_size = Vector2(54, 54)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(slot)

	var tex_rect = TextureRect.new()
	tex_rect.texture = SpriteFactory.get_character_texture(m_id, "south")
	tex_rect.custom_minimum_size = Vector2(44, 44)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not discovered:
		tex_rect.modulate = Color(0.18, 0.16, 0.22, 0.92)
	slot.add_child(tex_rect)

	# Informações centrais em tinta escura sobre o pergaminho
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var status_tag = "DERROTADO" if is_defeated_boss else ("Descoberto" if discovered else "Não encontrado")
	var title_lbl = Label.new()
	title_lbl.text = ("[CHEFE] " if is_boss else "") + str(m_data.name) + " [" + status_tag + "]"
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var title_col = Color("#8C1D18") if is_defeated_boss else (Color("#6B2D0F") if is_boss else Color("#24160A"))
	MedievalUI.style_label(title_lbl, title_col, 13, 0)
	info_vbox.add_child(title_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "HP: %d | Dano: %d | Vel: %d | XP: %d | Notas: %d-%d" % [
		m_data.max_hp, m_data.damage, int(m_data.speed), m_data.xp, m_data.cash_min, m_data.cash_max
	]
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(stats_lbl, Color("#422B18"), 11, 0)
	info_vbox.add_child(stats_lbl)

	var weak_lbl = Label.new()
	var weak_str = _get_weakness_label(m_id)
	if is_boss and BOSS_SKILLS_DESC.has(m_id):
		weak_str += "\nHabilidade: " + BOSS_SKILLS_DESC[m_id]
	weak_lbl.text = weak_str
	weak_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(weak_lbl, Color("#1D4E6B"), 10, 0)
	info_vbox.add_child(weak_lbl)

	# Contador de abates à direita
	var kills_lbl = Label.new()
	kills_lbl.text = "%d\nabate(s)" % kills
	kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kills_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MedievalUI.style_label(kills_lbl, Color("#1E5A22") if kills > 0 else Color("#7A6A58"), 11, 0)
	hbox.add_child(kills_lbl)

func _get_weakness_label(m_id: String) -> String:
	var tags: Array[String] = []
	if GameData.get_elemental_multiplier("fire", m_id) > 1.0:
		tags.append("Fogo (x2)")
	if GameData.get_elemental_multiplier("wind", m_id) > 1.0:
		tags.append("Vento (x2)")
	if GameData.get_elemental_multiplier("water", m_id) > 1.0:
		tags.append("Água (x2)")
	if tags.is_empty():
		return "Fraqueza: Físico / Neutro (x1)"
	return "Fraqueza: " + ", ".join(tags)
