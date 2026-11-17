extends CanvasLayer

## HUD principal do jogador (HP, Mana, Notas, Nível, Hunt Analyzer e barra de magias).

signal open_shop_requested
signal open_map_requested
signal open_bestiary_requested
signal open_inventory_requested
signal open_settings_requested
signal toggle_bestiary_requested
signal toggle_inventory_requested
signal close_modals_requested
signal challenge_boss_requested
signal reset_game_requested

@onready var hp_bar = $TopBar/HBox/VBoxHP/HPBar
@onready var hp_label = $TopBar/HBox/VBoxHP/HPLabel
@onready var mana_bar = $TopBar/HBox/VBoxMana/ManaBar
@onready var mana_label = $TopBar/HBox/VBoxMana/ManaLabel
@onready var cash_label = $TopBar/HBox/CashLabel
@onready var level_label = $TopBar/HBox/LevelLabel
@onready var auto_hunt_btn = $TopBar/HBox/AutoHuntBtn
@onready var boss_btn = $TopBar/HBox/BossBtn
@onready var map_btn = $TopBar/HBox/MapBtn
@onready var shop_btn = $TopBar/HBox/ShopBtn
@onready var bestiary_btn = $TopBar/HBox/BestiaryBtn
@onready var inventory_btn = $TopBar/HBox/InventoryBtn
@onready var reset_btn = $TopBar/HBox/ResetBtn
@onready var music_btn = $TopBar/HBox/MusicBtn
@onready var save_badge = $TopBar/HBox/SaveBadge

@onready var analyzer_panel = $HuntAnalyzer
@onready var analyzer_text = $HuntAnalyzer/Margin/VBox/StatsLabel

@onready var bottom_food_btn = $BottomBar/HBox/FoodBtn
@onready var bottom_weapon_lbl = $BottomBar/HBox/WeaponLabel
@onready var bottom_spell1 = $BottomBar/HBox/Spell1
@onready var bottom_spell2 = $BottomBar/HBox/Spell2
@onready var bottom_spell3 = $BottomBar/HBox/Spell3

var _save_badge_tween: Tween
var _last_save_toast_ms: int = 0
var _xp_bar: ProgressBar
var _weapon_icon_rect: TextureRect
var _armor_icon_rect: TextureRect
var _weapon_slot_panel: PanelContainer
var _armor_slot_panel: PanelContainer
var _spell_slots: Dictionary = {}
var _spell_popup: PanelContainer
var _spell_popup_icon: TextureRect
var _spell_popup_title: Label
var _spell_popup_desc: Label
var _hovered_locked_spell_id: String = ""
var _spell_popup_auto_hide: float = 0.0

const SPELL_UNLOCK_HINTS := {
	"fireball": "Liberada ao iniciar a aventura ou falando com o Explorador [E] na Floresta dos Ecos.",
	"tornado": "Como liberar: derrote o sub-chefe Lobisomem (ou a chefe Toupeira Serra) na Floresta dos Ecos, ou fale com o Explorador [E] nas Cavernas e Minas.",
	"water_bomb": "Como liberar: derrote a chefe Toupeira Serra na Floresta dos Ecos, ou converse com o Explorador [E] nas Cavernas e Minas."
}

func _ready():
	GameState.stats_changed.connect(_update_stats)
	GameState.boss_defeated.connect(func(_b): _update_stats())
	GameState.cash_changed.connect(_update_cash)
	GameState.inventory_changed.connect(_update_inventory)
	GameState.world_changed.connect(_on_world_changed)
	GameState.game_saved.connect(_on_game_saved)
	GameState.game_reset.connect(_on_game_reset)
	GameState.touch_mode_changed.connect(_sync_touch_layout)
	HuntAnalyzerData.analyzer_updated.connect(_update_analyzer)

	auto_hunt_btn.pressed.connect(_on_auto_hunt_toggled)
	boss_btn.pressed.connect(func(): challenge_boss_requested.emit())
	map_btn.pressed.connect(func(): open_map_requested.emit())
	shop_btn.pressed.connect(func(): open_shop_requested.emit())
	bestiary_btn.pressed.connect(func(): open_bestiary_requested.emit())
	inventory_btn.pressed.connect(func(): open_inventory_requested.emit())
	reset_btn.pressed.connect(func(): reset_game_requested.emit())
	music_btn.text = "Config / Som"
	music_btn.pressed.connect(func(): open_settings_requested.emit())
	bottom_food_btn.pressed.connect(func(): GameState.eat_food())

	_apply_medieval_hud()
	_on_world_changed(GameState.current_world)
	_update_stats()
	_update_cash(GameState.cash_notes)
	_update_inventory()
	_update_analyzer()

func _apply_medieval_hud():
	var top_bar = $TopBar
	var top_hbox = $TopBar/HBox
	var bottom_bar = $BottomBar
	var bottom_hbox = $BottomBar/HBox

	top_bar.add_theme_stylebox_override("panel", MedievalUI.panel_box("bar", 16, 12))
	analyzer_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 18, 16))
	bottom_bar.add_theme_stylebox_override("panel", MedievalUI.panel_box("bar", 16, 12))

	# Orbes de Vida e Mana + Barras estilizadas
	_insert_icon_before(top_hbox, $TopBar/HBox/VBoxHP, MedievalUI.tex("icon_hp_orb"), 26)
	_insert_icon_before(top_hbox, $TopBar/HBox/VBoxMana, MedievalUI.tex("icon_mana_orb"), 26)
	MedievalUI.style_label(hp_label, Color("#FFD0D0"), 11, 2)
	MedievalUI.style_label(mana_label, Color("#CFE4FF"), 11, 2)
	MedievalUI.style_progress_bar(hp_bar, Color("#C8232C"), Color("#B58E43"))
	MedievalUI.style_progress_bar(mana_bar, Color("#2563EB"), Color("#9CB3C9"))

	# Placa em pergaminho para Notas e Brasão + Barra de XP para Nível
	_wrap_cash_in_parchment(top_hbox)
	_build_level_crest_group(top_hbox)

	# Botões da barra superior com textura 9-slice e ícones pixel art
	MedievalUI.style_button(auto_hunt_btn, "green" if GameState.auto_hunt_enabled else "stone", "", 11, 28)
	MedievalUI.style_button(boss_btn, "crimson", "icon_boss_crest", 11, 28)
	MedievalUI.style_button(map_btn, "stone", "icon_map_scroll", 11, 28)
	MedievalUI.style_button(shop_btn, "gold", "", 11, 28)
	var shop_icon = SpriteFactory.get_item_icon("maca")
	if shop_icon:
		shop_btn.icon = shop_icon
		shop_btn.add_theme_constant_override("icon_max_width", 16)
	MedievalUI.style_button(bestiary_btn, "stone", "icon_bestiary_book", 11, 28)
	MedievalUI.style_button(inventory_btn, "stone", "", 11, 28)
	var bag_icon = SpriteFactory.get_item_icon("armor_chest")
	if bag_icon:
		inventory_btn.icon = bag_icon
		inventory_btn.add_theme_constant_override("icon_max_width", 16)
	MedievalUI.style_button(reset_btn, "stone", "", 11, 28)
	MedievalUI.style_button(music_btn, "stone", "icon_sound", 11, 28)
	MedievalUI.style_label(save_badge, Color("#7CF088"), 11, 2)

	# Hunt Analyzer
	var analyzer_title = $HuntAnalyzer/Margin/VBox/Title
	MedievalUI.style_label(analyzer_title, Color("#FFD76B"), 12, 2)
	MedievalUI.style_label(analyzer_text, Color("#F5E6C8"), 11, 2)

	# BottomBar: Comida, Slots de Arma/Armadura e Slots Rúnicos de Magias
	MedievalUI.style_button(bottom_food_btn, "gold", "", 12, 32)
	var food_icon = SpriteFactory.get_item_icon("maca")
	if food_icon:
		bottom_food_btn.icon = food_icon
		bottom_food_btn.add_theme_constant_override("icon_max_width", 18)

	_build_gear_slots(bottom_hbox)
	MedievalUI.style_label(bottom_weapon_lbl, Color("#F5E6C8"), 12, 2)

	_wrap_spell_slot(bottom_hbox, bottom_spell1, "fireball")
	_wrap_spell_slot(bottom_hbox, bottom_spell2, "tornado")
	_wrap_spell_slot(bottom_hbox, bottom_spell3, "water_bomb")
	_build_spell_unlock_popup()
	_sync_touch_layout()

func _insert_icon_before(parent: Container, target: Control, tex: Texture2D, sz: int):
	if not tex or not is_instance_valid(target):
		return
	var icon_rect = TextureRect.new()
	icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(sz, sz)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var idx = target.get_index()
	parent.add_child(icon_rect)
	parent.move_child(icon_rect, idx)

func _wrap_cash_in_parchment(top_hbox: HBoxContainer):
	var idx = cash_label.get_index()
	var notes_res := MedievalUI.create_notes_badge(10, 4, Vector2(18, 14), cash_label)
	var badge: PanelContainer = notes_res.panel
	top_hbox.add_child(badge)
	top_hbox.move_child(badge, idx)

func _build_level_crest_group(top_hbox: HBoxContainer):
	var idx = level_label.get_index()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_hbox.add_child(hbox)
	top_hbox.move_child(hbox, idx)

	var crest = MedievalUI.tex("icon_level_crest")
	if crest:
		var icon_r = TextureRect.new()
		icon_r.texture = crest
		icon_r.custom_minimum_size = Vector2(24, 24)
		icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon_r)

	var lv_vbox = VBoxContainer.new()
	lv_vbox.add_theme_constant_override("separation", 2)
	lv_vbox.custom_minimum_size = Vector2(138, 0)
	hbox.add_child(lv_vbox)

	level_label.reparent(lv_vbox)
	MedievalUI.style_label(level_label, Color("#FFE28A"), 11, 2)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(132, 8)
	_xp_bar.show_percentage = false
	MedievalUI.style_progress_bar(_xp_bar, Color("#38BDF8"), Color("#8C6A2E"))
	lv_vbox.add_child(_xp_bar)

func _build_gear_slots(bottom_hbox: HBoxContainer):
	var idx = bottom_weapon_lbl.get_index()
	var gear_hbox = HBoxContainer.new()
	gear_hbox.add_theme_constant_override("separation", 6)
	gear_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom_hbox.add_child(gear_hbox)
	bottom_hbox.move_child(gear_hbox, idx)

	_weapon_icon_rect = _create_icon_slot(gear_hbox, SpriteFactory.get_item_icon(GameState.equipped_weapon), true)
	_armor_icon_rect = _create_icon_slot(gear_hbox, SpriteFactory.get_item_icon(GameState.equipped_armor), false)
	bottom_weapon_lbl.reparent(gear_hbox)

func _create_icon_slot(parent: Control, tex: Texture2D, is_weapon_slot: bool) -> TextureRect:
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 6, 6))
	slot.custom_minimum_size = Vector2(36, 36)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.tooltip_text = "Clique para abrir a Mochila [I]"
	slot.gui_input.connect(func(ev: InputEvent):
		var pressed: bool = (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed)
		if pressed:
			open_inventory_requested.emit()
			slot.accept_event()
	)
	parent.add_child(slot)
	if is_weapon_slot:
		_weapon_slot_panel = slot
	else:
		_armor_slot_panel = slot

	var icon_r = TextureRect.new()
	icon_r.texture = tex
	icon_r.custom_minimum_size = Vector2(22, 22)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon_r)
	return icon_r

func _wrap_spell_slot(bottom_hbox: HBoxContainer, lbl: Label, spell_id: String):
	var idx = lbl.get_index()
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 9, 6))
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom_hbox.add_child(slot)
	bottom_hbox.move_child(slot, idx)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(row)

	var sp_tex = SpriteFactory.get_spell_texture(spell_id)
	if sp_tex:
		var icon_r = TextureRect.new()
		icon_r.texture = sp_tex
		icon_r.custom_minimum_size = Vector2(22, 22)
		icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_r)

	lbl.reparent(row)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MedievalUI.style_label(lbl, Color("#F5E6C8"), 12, 2)
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.mouse_entered.connect(func(): _on_spell_slot_mouse_entered(spell_id))
	slot.mouse_exited.connect(func(): _on_spell_slot_mouse_exited(spell_id))
	slot.gui_input.connect(func(ev): _on_spell_slot_gui_input(spell_id, ev))
	_spell_slots[spell_id] = slot

func _build_spell_unlock_popup():
	_spell_popup = PanelContainer.new()
	_spell_popup.visible = false
	_spell_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_popup.custom_minimum_size = Vector2(300, 0)
	_spell_popup.z_index = 60
	_spell_popup.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 12, 10, Color(1.0, 0.96, 0.90)))
	add_child(_spell_popup)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_popup.add_child(vbox)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	var lock_tex = MedievalUI.tex("icon_padlock")
	if lock_tex:
		var lock_r = TextureRect.new()
		lock_r.texture = lock_tex
		lock_r.custom_minimum_size = Vector2(18, 18)
		lock_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(lock_r)

	_spell_popup_icon = TextureRect.new()
	_spell_popup_icon.custom_minimum_size = Vector2(20, 20)
	_spell_popup_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_spell_popup_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_spell_popup_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_spell_popup_icon)

	_spell_popup_title = Label.new()
	_spell_popup_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(_spell_popup_title, Color("#FFD76B"), 12, 2)
	header.add_child(_spell_popup_title)

	_spell_popup_desc = Label.new()
	_spell_popup_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_spell_popup_desc.custom_minimum_size = Vector2(276, 0)
	_spell_popup_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MedievalUI.style_label(_spell_popup_desc, Color("#F5E6C8"), 11, 2)
	vbox.add_child(_spell_popup_desc)

func _on_spell_slot_mouse_entered(spell_id: String):
	if GameState.unlocked_spells.get(spell_id, false):
		_hide_spell_unlock_popup()
		return
	_hovered_locked_spell_id = spell_id
	var sp_data: Dictionary = GameData.SPELLS.get(spell_id, {})
	var sp_name := str(sp_data.get("name", spell_id))
	var sp_key := str(sp_data.get("key", ""))
	_spell_popup_title.text = sp_name + " [Tecla " + sp_key + "] (Bloqueada)"
	_spell_popup_desc.text = str(SPELL_UNLOCK_HINTS.get(spell_id, "Explore e derrote os chefes para desbloquear esta magia."))
	if _spell_popup_icon:
		_spell_popup_icon.texture = SpriteFactory.get_spell_texture(spell_id)
	_spell_popup.visible = true
	_spell_popup.reset_size()
	call_deferred("_reposition_spell_popup", spell_id)

func _reposition_spell_popup(spell_id: String):
	if not is_instance_valid(_spell_popup) or not _spell_popup.visible:
		return
	if _hovered_locked_spell_id != spell_id or GameState.unlocked_spells.get(spell_id, false):
		_hide_spell_unlock_popup()
		return
	var slot: Control = _spell_slots.get(spell_id)
	if not is_instance_valid(slot):
		return
	_spell_popup.reset_size()
	var slot_rect := slot.get_global_rect()
	var vp_w := get_viewport().get_visible_rect().size.x
	var pop_sz := _spell_popup.size
	var px := clampf(slot_rect.position.x + slot_rect.size.x * 0.5 - pop_sz.x * 0.5, 12.0, maxf(12.0, vp_w - pop_sz.x - 12.0))
	var py := maxf(12.0, slot_rect.position.y - pop_sz.y - 10.0)
	_spell_popup.position = Vector2(px, py)

func _on_spell_slot_mouse_exited(spell_id: String):
	if _hovered_locked_spell_id == spell_id and _spell_popup_auto_hide <= 0.0:
		_hide_spell_unlock_popup()

func _on_spell_slot_gui_input(spell_id: String, ev: InputEvent):
	var tapped: bool = (ev is InputEventScreenTouch and ev.pressed)
	var clicked: bool = (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT)
	if not tapped and not clicked:
		return
	var slot: Control = _spell_slots.get(spell_id)
	if slot:
		slot.accept_event()
	if GameState.unlocked_spells.get(spell_id, false):
		_hide_spell_unlock_popup()
		var scene := get_tree().current_scene
		var p = scene.get("player") if scene else null
		if is_instance_valid(p) and p.has_method("cast_spell_from_ui"):
			p.cast_spell_from_ui(spell_id)
	else:
		show_spell_unlock_hint(spell_id)

## Exibe temporariamente a dica de desbloqueio de uma magia bloqueada (compatível com touch).
func show_spell_unlock_hint(spell_id: String):
	if _spell_popup.visible and _hovered_locked_spell_id == spell_id:
		_hide_spell_unlock_popup()
	else:
		_spell_popup_auto_hide = 3.5
		_on_spell_slot_mouse_entered(spell_id)

func _hide_spell_unlock_popup():
	_hovered_locked_spell_id = ""
	_spell_popup_auto_hide = 0.0
	if is_instance_valid(_spell_popup):
		_spell_popup.visible = false

func _sync_touch_layout():
	var is_touch := GameState.are_touch_controls_active()
	var top_min_h := 34 if is_touch else 28
	for btn in [auto_hunt_btn, map_btn, shop_btn, bestiary_btn, inventory_btn, reset_btn, music_btn]:
		if is_instance_valid(btn):
			btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, float(top_min_h))
	if is_instance_valid(bottom_food_btn):
		bottom_food_btn.custom_minimum_size.y = 38.0 if is_touch else 32.0
	for sp_slot in _spell_slots.values():
		if is_instance_valid(sp_slot):
			sp_slot.custom_minimum_size = Vector2(96.0, 38.0) if is_touch else Vector2.ZERO
	_update_inventory()

func _process(delta: float):
	if _spell_popup_auto_hide > 0.0:
		_spell_popup_auto_hide -= delta
		if _spell_popup_auto_hide <= 0.0:
			_hide_spell_unlock_popup()
	_update_spell_cooldown_labels()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle_bestiary_requested.emit()
		elif event.keycode == KEY_I:
			toggle_inventory_requested.emit()
		elif event.keycode == KEY_ESCAPE:
			close_modals_requested.emit()

func _update_spell_cooldown_labels():
	var specs = [
		[bottom_spell1, "fireball", "[1] Fogo", Color("#FF9E58")],
		[bottom_spell2, "tornado", "[2] Vento", Color("#A5F3FC")],
		[bottom_spell3, "water_bomb", "[3] Agua", Color("#5AC8FA")]
	]
	for sp in specs:
		var lbl: Label = sp[0]
		var sp_id: String = sp[1]
		var label_txt: String = sp[2]
		var ready_col: Color = sp[3]
		var slot: Control = _spell_slots.get(sp_id)
		var cd = GameState.spell_cooldowns.get(sp_id, 0.0)
		if not GameState.unlocked_spells.get(sp_id, false):
			lbl.text = "[X] " + label_txt
			lbl.modulate = Color("#888888")
			if slot:
				slot.modulate = Color(0.55, 0.52, 0.50, 0.85)
				slot.mouse_default_cursor_shape = Control.CURSOR_HELP
		elif cd > 0.0:
			if _hovered_locked_spell_id == sp_id:
				_hide_spell_unlock_popup()
			lbl.text = label_txt.substr(0, 3) + (" %.1fs" % cd)
			lbl.modulate = Color("#CCCCCC")
			if slot:
				slot.modulate = Color(0.75, 0.72, 0.70, 0.95)
				slot.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			if _hovered_locked_spell_id == sp_id:
				_hide_spell_unlock_popup()
			lbl.text = label_txt
			lbl.modulate = ready_col
			if slot:
				slot.modulate = Color.WHITE
				slot.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _update_stats():
	hp_bar.max_value = GameState.max_hp
	var tw_hp = create_tween()
	tw_hp.tween_property(hp_bar, "value", float(GameState.current_hp), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hp_label.text = "HP: " + str(GameState.current_hp) + " / " + str(GameState.max_hp)

	mana_bar.max_value = GameState.max_mana
	var tw_mp = create_tween()
	tw_mp.tween_property(mana_bar, "value", float(GameState.current_mana), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	mana_label.text = "Mana: " + str(GameState.current_mana) + " / " + str(GameState.max_mana)

	level_label.text = "Nv. " + str(GameState.level) + " (" + str(GameState.current_xp) + "/" + str(GameState.xp_to_next_level) + " XP)"
	if _xp_bar:
		_xp_bar.max_value = max(1, GameState.xp_to_next_level)
		_xp_bar.value = GameState.current_xp

	# Verifica progresso e liberação de Chefe
	var w = GameData.WORLDS.get(GameState.current_world, {})
	var kills_req = w.get("kills_to_boss", 0)
	var next_boss = GameState.get_next_world_boss(GameState.current_world)
	if kills_req > 0:
		boss_btn.visible = true
		if next_boss == "":
			boss_btn.disabled = true
			boss_btn.text = "Chefes Vencidos"
			MedievalUI.style_button(boss_btn, "stone", "icon_boss_crest", 11, 28)
			boss_btn.modulate = Color("#889988")
		elif GameState.zone_kills >= kills_req:
			boss_btn.disabled = false
			boss_btn.text = "! Desafiar Chefe"
			MedievalUI.style_button(boss_btn, "crimson", "icon_boss_crest", 11, 28)
			boss_btn.modulate = Color("#FFD76B")
		else:
			boss_btn.disabled = true
			boss_btn.text = "Chefe (" + str(GameState.zone_kills) + "/" + str(kills_req) + ")"
			MedievalUI.style_button(boss_btn, "stone", "icon_boss_crest", 11, 28)
			boss_btn.modulate = Color("#BBBBBB")
	else:
		boss_btn.visible = false

func _update_cash(amount: int):
	cash_label.text = "$ " + str(amount) + " Notas"

func _update_inventory():
	var total_food = GameState.food_inventory.get("apple", 0) + GameState.food_inventory.get("bread", 0) + GameState.food_inventory.get("meat", 0)
	var food_prefix := "Comer (" if GameState.are_touch_controls_active() else "Comer [Q] ("
	bottom_food_btn.text = food_prefix + str(total_food) + ")"

	var w_data = GameData.WEAPONS.get(GameState.equipped_weapon, {})
	var w_name = w_data.get("name", "Espada")
	var a_data = GameData.ARMORS.get(GameState.equipped_armor, {})
	var a_name = a_data.get("name", "Roupas Simples")
	bottom_weapon_lbl.text = w_name + " | " + a_name
	if _weapon_icon_rect:
		_weapon_icon_rect.texture = SpriteFactory.get_item_icon(GameState.equipped_weapon)
	if _armor_icon_rect:
		_armor_icon_rect.texture = SpriteFactory.get_item_icon(GameState.equipped_armor)
	if _weapon_slot_panel:
		var wr = GameData.get_rarity(int(w_data.get("tier", 1)))
		_weapon_slot_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 6, 6, wr.color.lerp(Color.WHITE, 0.35)))
	if _armor_slot_panel:
		var ar = GameData.get_rarity(int(a_data.get("tier", 0)))
		_armor_slot_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 6, 6, ar.color.lerp(Color.WHITE, 0.35)))

func _update_analyzer():
	var s_time = int(HuntAnalyzerData.session_time)
	var mins = s_time / 60
	var secs = s_time % 60
	var time_str = "%02d:%02d" % [mins, secs]

	var txt = "Tempo: " + time_str + "\n"
	txt += "Abates: " + str(HuntAnalyzerData.total_kills) + "\n"
	txt += "XP/h: " + str(HuntAnalyzerData.get_xp_per_hour()) + "\n"
	txt += "Notas: +" + str(HuntAnalyzerData.gross_cash) + "\n"
	txt += "Gasto: -" + str(HuntAnalyzerData.food_waste_cash) + "\n"
	txt += "Lucro Liquido: " + str(HuntAnalyzerData.get_net_profit())
	analyzer_text.text = txt

func _on_auto_hunt_toggled():
	GameState.auto_hunt_enabled = not GameState.auto_hunt_enabled
	auto_hunt_btn.text = "Auto: " + ("ON" if GameState.auto_hunt_enabled else "OFF")
	MedievalUI.style_button(auto_hunt_btn, "green" if GameState.auto_hunt_enabled else "stone", "", 11, 28)
	auto_hunt_btn.modulate = Color.WHITE

func _on_music_toggled():
	open_settings_requested.emit()

func _on_world_changed(w_id: String):
	shop_btn.visible = (w_id == "vila")
	_update_stats()

func _on_game_saved():
	var now_ms = Time.get_ticks_msec()
	if now_ms - _last_save_toast_ms < 2500:
		return
	_last_save_toast_ms = now_ms
	if not is_instance_valid(save_badge):
		return
	if _save_badge_tween and _save_badge_tween.is_valid():
		_save_badge_tween.kill()
	save_badge.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_save_badge_tween = create_tween()
	_save_badge_tween.tween_interval(1.2)
	_save_badge_tween.tween_property(save_badge, "modulate:a", 0.0, 0.8)

func _on_game_reset():
	auto_hunt_btn.text = "Auto: OFF"
	MedievalUI.style_button(auto_hunt_btn, "stone", "", 11, 28)
	auto_hunt_btn.modulate = Color.WHITE
	_update_stats()
	_update_cash(GameState.cash_notes)
	_update_inventory()
	_update_analyzer()
