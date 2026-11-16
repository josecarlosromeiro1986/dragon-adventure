extends Window

## Janela de Mochila & Equipamentos com prévia de Daniel, slots equipados e filtros.

var _notes_lbl: Label
var _hero_preview_rect: TextureRect
var _hero_weapon_badge: TextureRect
var _hero_stats_lbl: Label
var _equipped_weapon_box: VBoxContainer
var _equipped_armor_box: VBoxContainer
var _backpack_vbox: VBoxContainer
var _filter_mode: String = "all"
var _tab_buttons: Dictionary = {}

const RARITY_FX_DESC := {
	0: "Sem aura elemental.",
	1: "Golpe físico básico.",
	2: "Brilho metálico e lascas de pedra.",
	3: "Aura dourada e corte luminoso duplo.",
	4: "Aura prismática contínua, pós-imagem e estilhaços de cristal!"
}

func _ready():
	title = "Mochila & Equipamentos — Dragon Adventure"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	size = Vector2i(860, 540)
	visible = false
	close_requested.connect(func(): hide())

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	MedievalUI.setup_modal_chrome(self, "stone", 26, 24)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	# Cabeçalho
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header)

	var armor_icon = SpriteFactory.get_item_icon("armor_wood")
	if armor_icon:
		var hr = TextureRect.new()
		hr.texture = armor_icon
		hr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hr.custom_minimum_size = Vector2(28, 28)
		hr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header.add_child(hr)

	var title_lbl = Label.new()
	title_lbl.text = "MOCHILA & EQUIPAMENTOS"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)
	header.add_child(title_lbl)

	var notes_res := MedievalUI.create_notes_badge(12, 5, Vector2(20, 14))
	_notes_lbl = notes_res.label
	header.add_child(notes_res.panel)

	var close_btn = Button.new()
	close_btn.text = "Fechar [I]"
	MedievalUI.style_button(close_btn, "crimson", "", 12, 30)
	close_btn.pressed.connect(func(): hide())
	header.add_child(close_btn)

	# Corpo principal em 2 colunas
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(body_hbox)

	# Coluna Esquerda: Personagem & Slots Equipados
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(305, 0)
	left_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 12, 10))
	body_hbox.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 10)
	left_panel.add_child(left_vbox)

	var eq_title = Label.new()
	eq_title.text = "EQUIPAMENTO DO HERÓI"
	eq_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(eq_title, Color("#4E2B10"), 13, 0)
	left_vbox.add_child(eq_title)

	# Preview vivo de Daniel Ragnar com Armadura + Arma
	var preview_card = PanelContainer.new()
	preview_card.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 8, 8))
	left_vbox.add_child(preview_card)

	var preview_hbox = HBoxContainer.new()
	preview_hbox.add_theme_constant_override("separation", 10)
	preview_card.add_child(preview_hbox)

	var avatar_holder = Control.new()
	avatar_holder.custom_minimum_size = Vector2(72, 72)
	preview_hbox.add_child(avatar_holder)

	_hero_preview_rect = TextureRect.new()
	_hero_preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hero_preview_rect.position = Vector2(0, 0)
	_hero_preview_rect.size = Vector2(72, 72)
	_hero_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_holder.add_child(_hero_preview_rect)

	_hero_weapon_badge = TextureRect.new()
	_hero_weapon_badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hero_weapon_badge.position = Vector2(44, 42)
	_hero_weapon_badge.size = Vector2(26, 26)
	_hero_weapon_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_weapon_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_holder.add_child(_hero_weapon_badge)

	_hero_stats_lbl = Label.new()
	_hero_stats_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_stats_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MedievalUI.style_label(_hero_stats_lbl, Color("#FFF4D6"), 12, 2)
	preview_hbox.add_child(_hero_stats_lbl)

	_equipped_weapon_box = VBoxContainer.new()
	_equipped_weapon_box.add_theme_constant_override("separation", 4)
	left_vbox.add_child(_equipped_weapon_box)

	_equipped_armor_box = VBoxContainer.new()
	_equipped_armor_box.add_theme_constant_override("separation", 4)
	left_vbox.add_child(_equipped_armor_box)

	# Coluna Direita: Abas + Lista da Mochila
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 8)
	body_hbox.add_child(right_vbox)

	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 6)
	right_vbox.add_child(tabs_hbox)

	var tab_defs = [
		["all", "Tudo"],
		["weapons", "Armas"],
		["armors", "Armaduras"],
		["foods", "Comidas"]
	]
	for td in tab_defs:
		var t_id: String = td[0]
		var btn = Button.new()
		btn.text = td[1]
		btn.pressed.connect(func():
			_filter_mode = t_id
			_update_tab_styles()
			populate_inventory()
		)
		tabs_hbox.add_child(btn)
		_tab_buttons[t_id] = btn
	_update_tab_styles()

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vbox.add_child(scroll)

	_backpack_vbox = VBoxContainer.new()
	_backpack_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_backpack_vbox.add_theme_constant_override("separation", 7)
	scroll.add_child(_backpack_vbox)

	GameState.inventory_changed.connect(_on_state_updated)
	GameState.stats_changed.connect(_on_state_updated)
	GameState.cash_changed.connect(func(_c): _on_state_updated())

func _on_state_updated():
	if visible:
		populate_inventory()

func _update_tab_styles():
	for k in _tab_buttons.keys():
		var b: Button = _tab_buttons[k]
		var active = (k == _filter_mode)
		MedievalUI.style_button(b, "gold" if active else "stone", "", 11, 28)

func open():
	populate_inventory()
	MedievalUI.popup_fit(self, Vector2i(860, 540))

func populate_inventory():
	_notes_lbl.text = "Notas: $ " + str(GameState.cash_notes)
	_refresh_equipped_panel()

	for c in _backpack_vbox.get_children():
		c.queue_free()

	if _filter_mode == "all" or _filter_mode == "weapons":
		_add_section_header("ARMAS NA MOCHILA (%d / %d)" % [GameState.owned_weapons.size(), GameData.WEAPONS.size()])
		for w_id in GameData.WEAPONS.keys():
			if GameState.has_weapon(w_id):
				_add_weapon_row(w_id)

	if _filter_mode == "all" or _filter_mode == "armors":
		_add_section_header("ARMADURAS NA MOCHILA (%d / %d)" % [GameState.owned_armors.size(), GameData.ARMORS.size()])
		for a_id in GameData.ARMORS.keys():
			if GameState.has_armor(a_id):
				_add_armor_row(a_id)

	if _filter_mode == "all" or _filter_mode == "foods":
		_add_section_header("COMIDAS & SUPRIMENTOS")
		for f_id in GameData.FOODS.keys():
			_add_food_row(f_id)

func _refresh_equipped_panel():
	var armor_id = GameState.equipped_armor
	var char_id = ("daniel_" + armor_id) if (armor_id != "" and armor_id != "none") else "daniel_ragnar"
	_hero_preview_rect.texture = SpriteFactory.get_character_texture(char_id, "south")
	_hero_weapon_badge.texture = SpriteFactory.get_item_icon(GameState.equipped_weapon)

	var weapon = GameData.WEAPONS.get(GameState.equipped_weapon, GameData.WEAPONS["sword_wood"])
	var armor = GameData.ARMORS.get(armor_id, GameData.ARMORS["none"])
	var dps = float(weapon.damage) / max(0.05, float(weapon.cooldown))
	_hero_stats_lbl.text = "Daniel Ragnar (Nv. %d)\nHP: %d/%d | Mana: %d/%d\nDPS Base: %.1f | Def: %d%%" % [
		GameState.level,
		GameState.current_hp, GameState.max_hp,
		GameState.current_mana, GameState.max_mana,
		dps,
		int(armor.get("defense_pct", 0.0) * 100)
	]

	for c in _equipped_weapon_box.get_children():
		c.queue_free()
	var w_rarity = GameData.get_rarity(weapon.tier)
	var w_lines = [
		weapon.name + " [" + w_rarity.name + "]",
		"Dano: %d | Recarga: %.2fs | Crit: %d%%" % [weapon.damage, weapon.cooldown, int(weapon.get("crit_rate", 0.0) * 100)],
		RARITY_FX_DESC.get(weapon.tier, "")
	]
	if weapon.get("stun_chance", 0.0) > 0.0:
		w_lines[1] += " | Stun: %d%%" % int(weapon.stun_chance * 100)
	_build_equipped_slot_card(_equipped_weapon_box, "ARMA EQUIPADA", GameState.equipped_weapon, w_rarity, w_lines)

	for c in _equipped_armor_box.get_children():
		c.queue_free()
	var a_rarity = GameData.get_rarity(armor.tier)
	var a_lines = [
		armor.name + " [" + a_rarity.name + "]",
		"Redução de Dano: %d%%" % int(armor.get("defense_pct", 0.0) * 100),
		armor.desc
	]
	_build_equipped_slot_card(_equipped_armor_box, "ARMADURA EQUIPADA", armor_id, a_rarity, a_lines)

func _build_equipped_slot_card(parent: Control, heading: String, icon_id: String, rarity: Dictionary, lines: Array):
	var h_lbl = Label.new()
	h_lbl.text = heading
	MedievalUI.style_label(h_lbl, Color("#4E2B10"), 11, 0)
	parent.add_child(h_lbl)

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 8, 7, rarity.color.lerp(Color.WHITE, 0.45)))
	parent.add_child(card)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var icon_r = TextureRect.new()
	icon_r.texture = SpriteFactory.get_item_icon(icon_id)
	icon_r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_r.custom_minimum_size = Vector2(36, 36)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_r)

	var text_col = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)

	var t_lbl = Label.new()
	t_lbl.text = str(lines[0])
	MedievalUI.style_label(t_lbl, rarity.accent, 12, 2)
	text_col.add_child(t_lbl)

	var s_lbl = Label.new()
	s_lbl.text = str(lines[1])
	s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(s_lbl, Color("#F5E6C8"), 11, 1)
	text_col.add_child(s_lbl)

	var fx_lbl = Label.new()
	fx_lbl.text = str(lines[2])
	fx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(fx_lbl, Color("#D6C7AE"), 10, 1)
	text_col.add_child(fx_lbl)

func _add_section_header(text: String):
	var lbl = Label.new()
	lbl.text = text
	MedievalUI.style_label(lbl, Color("#FFD76B"), 12, 2)
	_backpack_vbox.add_child(lbl)

func _add_weapon_row(w_id: String):
	var w = GameData.WEAPONS[w_id]
	var rarity = GameData.get_rarity(w.tier)
	var is_eq = (GameState.equipped_weapon == w_id)
	var tipo = "Espada" if w.type == "sword" else "Martelo"
	var sub = "%s | Dano: %d | Crit: %d%%" % [tipo, w.damage, int(w.get("crit_rate", 0.0) * 100)]
	if w.get("stun_chance", 0.0) > 0.0:
		sub += " | Atordoar: %d%%" % int(w.stun_chance * 100)
	_add_backpack_card(
		w.name + " [" + rarity.name + "]",
		sub,
		w_id,
		rarity,
		"EQUIPADA" if is_eq else "Equipar",
		"stone" if is_eq else "green",
		is_eq,
		func(): GameState.equip_weapon(w_id)
	)

func _add_armor_row(a_id: String):
	var a = GameData.ARMORS[a_id]
	var rarity = GameData.get_rarity(a.tier)
	var is_eq = (GameState.equipped_armor == a_id)
	var sub = "Defesa: %d%% | %s" % [int(a.get("defense_pct", 0.0) * 100), a.desc]
	_add_backpack_card(
		a.name + " [" + rarity.name + "]",
		sub,
		a_id,
		rarity,
		"EQUIPADA" if is_eq else "Equipar",
		"stone" if is_eq else "green",
		is_eq,
		func(): GameState.equip_armor(a_id)
	)

func _add_food_row(f_id: String):
	var f = GameData.FOODS[f_id]
	var qty = GameState.food_inventory.get(f_id, 0)
	var rarity = GameData.get_rarity(1)
	var can_eat = qty > 0 and GameState.current_hp < GameState.max_hp
	_add_backpack_card(
		"%s (x%d)" % [f.name, qty],
		"Cura +%d HP | %s" % [f.heal, f.desc],
		f_id,
		rarity,
		"Comer (+%d)" % f.heal if qty > 0 else "Vazio",
		"gold" if can_eat else "stone",
		not can_eat,
		func(): GameState.eat_food(f_id)
	)

func _add_backpack_card(title_txt: String, desc_txt: String, icon_id: String, rarity: Dictionary, btn_txt: String, btn_variant: String, btn_disabled: bool, on_action: Callable):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 10, 7))
	_backpack_vbox.add_child(card)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 4, 4, rarity.color.lerp(Color.WHITE, 0.35)))
	slot.custom_minimum_size = Vector2(40, 40)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(slot)

	var icon_r = TextureRect.new()
	icon_r.texture = SpriteFactory.get_item_icon(icon_id)
	icon_r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_r.custom_minimum_size = Vector2(28, 28)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon_r)

	var text_v = VBoxContainer.new()
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_v.add_theme_constant_override("separation", 2)
	hbox.add_child(text_v)

	var t_lbl = Label.new()
	t_lbl.text = title_txt
	MedievalUI.style_label(t_lbl, Color("#24160A"), 12, 0)
	text_v.add_child(t_lbl)

	var d_lbl = Label.new()
	d_lbl.text = desc_txt
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(d_lbl, Color("#5A3B22"), 11, 0)
	text_v.add_child(d_lbl)

	var btn = Button.new()
	btn.text = btn_txt
	btn.disabled = btn_disabled
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MedievalUI.style_button(btn, btn_variant, "", 11, 30)
	btn.pressed.connect(on_action)
	hbox.add_child(btn)
