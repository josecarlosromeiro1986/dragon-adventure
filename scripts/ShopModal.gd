extends Window

## Loja da Vila Barão Ragnar para compra de comidas, armas e armaduras com notas.

@onready var items_container = $Margin/VBox/Scroll/ItemsVBox
@onready var notes_lbl = $Margin/VBox/Header/NotesLabel
@onready var close_btn = $Margin/VBox/Header/CloseBtn

func _ready():
	MedievalUI.setup_modal_chrome(self, "stone", 26, 24)
	MedievalUI.style_button(close_btn, "crimson", "", 12, 30)
	close_btn.pressed.connect(func(): hide())
	close_requested.connect(func(): hide())
	_setup_medieval_header()
	GameState.cash_changed.connect(func(_amt):
		if is_instance_valid(notes_lbl):
			notes_lbl.text = "Suas Notas: $ " + str(GameState.cash_notes)
		if visible:
			populate_shop()
	)
	populate_shop()

func _setup_medieval_header():
	var header = $Margin/VBox/Header
	header.add_theme_constant_override("separation", 10)
	$Margin/VBox.add_theme_constant_override("separation", 10)

	var title_lbl = Label.new()
	title_lbl.text = "LOJA DA VILA BARÃO RAGNAR"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)
	header.add_child(title_lbl)
	header.move_child(title_lbl, 0)

	var notes_res := MedievalUI.create_notes_badge(12, 5, Vector2(20, 14), notes_lbl)
	var badge: PanelContainer = notes_res.panel
	var close_idx = close_btn.get_index()
	header.add_child(badge)
	header.move_child(badge, close_idx)

	var vbox = $Margin/VBox
	var greeting_box = PanelContainer.new()
	greeting_box.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 12, 8))
	var greeting_lbl = Label.new()
	greeting_lbl.text = "Vendedor: \"Bem-vindo, jovem guerreiro! Tenho armas, armaduras e comidas prontas para a batalha. O que suas notas podem comprar hoje?\""
	greeting_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(greeting_lbl, Color("#3A2412"), 12, 0)
	greeting_box.add_child(greeting_lbl)
	vbox.add_child(greeting_box)
	vbox.move_child(greeting_box, 1)

func open():
	notes_lbl.text = "Suas Notas: $ " + str(GameState.cash_notes)
	populate_shop()
	MedievalUI.popup_fit(self, Vector2i(680, 520))

func populate_shop():
	for c in items_container.get_children():
		c.queue_free()
	items_container.add_theme_constant_override("separation", 8)

	_add_header("COMIDAS & CURA")
	for f_id in GameData.FOODS.keys():
		var f = GameData.FOODS[f_id]
		var qty = GameState.food_inventory.get(f_id, 0)
		var can_afford = GameState.cash_notes >= f.price
		var btn_var = "gold" if can_afford else "stone"
		_add_shop_item(f.name + " (x" + str(qty) + ")", f.desc, f.price, f_id, 1, "Comprar: $ " + str(f.price), btn_var, not can_afford, func():
			if GameState.spend_cash(f.price):
				GameState.food_inventory[f_id] = GameState.food_inventory.get(f_id, 0) + 1
				_refresh_after_purchase()
				populate_shop()
		)

	_add_header("ESPADAS (RÁPIDAS)")
	for w_id in GameData.WEAPONS.keys():
		var w = GameData.WEAPONS[w_id]
		if w.type == "sword" and w.price > 0:
			var stat_txt = "Dano: %d | Crit: %d%%" % [w.damage, int(w.get("crit_rate", 0.0) * 100)]
			_add_gear_shop_entry(w_id, w, stat_txt, true)

	_add_header("MARTELOS (PESADOS / ATORDOA)")
	for w_id in GameData.WEAPONS.keys():
		var w = GameData.WEAPONS[w_id]
		if w.type == "hammer":
			var stat_txt = "Dano: %d | Atordoar: %d%%" % [w.damage, int(w.get("stun_chance", 0.0) * 100)]
			_add_gear_shop_entry(w_id, w, stat_txt, true)

	_add_header("ARMADURAS")
	for a_id in GameData.ARMORS.keys():
		var a = GameData.ARMORS[a_id]
		if a.price > 0:
			var stat_txt = "Defesa: %d%%" % [int(a.defense_pct * 100)]
			_add_gear_shop_entry(a_id, a, stat_txt, false)

func _add_gear_shop_entry(item_id: String, data: Dictionary, stat_txt: String, is_weapon: bool):
	var rarity = GameData.get_rarity(data.tier)
	var is_equipped = (GameState.equipped_weapon == item_id) if is_weapon else (GameState.equipped_armor == item_id)
	var is_owned = GameState.has_weapon(item_id) if is_weapon else GameState.has_armor(item_id)
	var can_afford = GameState.cash_notes >= data.price
	var tag = " [EQUIPADA]" if is_equipped else (" [NA MOCHILA]" if is_owned else "")
	var btn_txt = "Equipada" if is_equipped else ("Equipar" if is_owned else "Comprar: $ " + str(data.price))
	var btn_var = "stone" if is_equipped else ("green" if is_owned else ("gold" if can_afford else "stone"))
	var btn_disabled = is_equipped or (not is_owned and not can_afford)
	_add_shop_item(
		data.name + " [" + rarity.name + "]" + tag,
		stat_txt + " | " + data.desc,
		data.price,
		item_id,
		data.tier,
		btn_txt,
		btn_var,
		btn_disabled,
		func():
			if is_owned:
				if is_weapon:
					GameState.equip_weapon(item_id)
				else:
					GameState.equip_armor(item_id)
				_refresh_after_purchase()
				populate_shop()
			elif GameState.spend_cash(data.price):
				if is_weapon:
					GameState.unlock_weapon(item_id, true)
				else:
					GameState.unlock_armor(item_id, true)
				_refresh_after_purchase()
				populate_shop()
	)

func _refresh_after_purchase():
	GameState.inventory_changed.emit()
	GameState.save_game()
	notes_lbl.text = "Suas Notas: $ " + str(GameState.cash_notes)

func _add_header(text: String):
	var lbl = Label.new()
	lbl.text = text
	MedievalUI.style_label(lbl, Color("#FFD76B"), 13, 2)
	items_container.add_child(lbl)

func _add_shop_item(item_title: String, desc: String, _price: int, icon_id: String, tier: int, btn_text: String, btn_variant: String, btn_disabled: bool, on_buy: Callable):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 10, 7))
	items_container.add_child(card)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var rarity = GameData.get_rarity(tier)
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 4, 4, rarity.color.lerp(Color.WHITE, 0.35)))
	slot.custom_minimum_size = Vector2(40, 40)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(slot)

	var icon_tex = SpriteFactory.get_item_icon(icon_id)
	if icon_tex:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_tex
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon_rect)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)

	var t_lbl = Label.new()
	t_lbl.text = item_title
	MedievalUI.style_label(t_lbl, Color("#24160A"), 13, 0)
	var d_lbl = Label.new()
	d_lbl.text = desc
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(d_lbl, Color("#5A3B22"), 11, 0)
	vbox.add_child(t_lbl)
	vbox.add_child(d_lbl)

	var btn = Button.new()
	btn.text = btn_text
	btn.disabled = btn_disabled
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MedievalUI.style_button(btn, btn_variant, "", 12, 32)
	if btn_disabled:
		btn.modulate = Color(0.78, 0.78, 0.78, 0.85)
		if _price > 0 and btn_text.begins_with("Comprar:"):
			btn.tooltip_text = "Saldo insuficiente ($ %d / $ %d)" % [GameState.cash_notes, _price]
	btn.pressed.connect(on_buy)

	hbox.add_child(vbox)
	hbox.add_child(btn)
