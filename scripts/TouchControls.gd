extends Control
class_name TouchControls

## Controles táteis virtuais para smartphones e tablets (joystick, ataque, dash e interação contextual).

const SKILL_SPECS := [
	{"id": "fireball", "label": "Fogo", "fill": Color("#7C2D12"), "rim": Color("#FF9E58"), "off": Vector2(-174.0, -75.0)},
	{"id": "tornado", "label": "Vento", "fill": Color("#134E4A"), "rim": Color("#A5F3FC"), "off": Vector2(-146.0, -132.0)},
	{"id": "water_bomb", "label": "Água", "fill": Color("#1E3A8A"), "rim": Color("#5AC8FA"), "off": Vector2(-83.0, -154.0)}
]

var _joystick: TouchThumbstick
var _attack_pad: ActionTouchPad
var _dash_pad: ActionTouchPad
var _skill_pads: Dictionary = {}
var _interact_btn: Button
var _portrait_hint: PanelContainer
var _portrait_hint_dismissed: bool = false
var _interact_target: Node = null
var _interact_kind: String = ""
var _last_vp_size: Vector2 = Vector2.ZERO

class TouchThumbstick extends Control:
	signal vector_changed(vec: Vector2)

	const OUTER_RADIUS := 58.0
	const KNOB_RADIUS := 24.0
	const DEADZONE := 0.14

	var _touch_index: int = -1
	var _knob_offset: Vector2 = Vector2.ZERO

	func _init():
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(156, 148)

	func reset():
		_touch_index = -1
		if _knob_offset != Vector2.ZERO:
			_knob_offset = Vector2.ZERO
			vector_changed.emit(Vector2.ZERO)
			queue_redraw()

	func _gui_input(event: InputEvent):
		var center := size * 0.5
		if event is InputEventScreenTouch:
			if event.pressed and _touch_index == -1:
				_touch_index = event.index
				_update_from_pos(event.position, center)
				accept_event()
			elif not event.pressed and event.index == _touch_index:
				reset()
				accept_event()
			return

		if event is InputEventScreenDrag:
			if event.index == _touch_index:
				_update_from_pos(event.position, center)
				accept_event()
			return

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if _touch_index >= 0:
				accept_event()
				return
			if event.pressed:
				_touch_index = -99
				_update_from_pos(event.position, center)
			elif _touch_index == -99:
				reset()
			accept_event()
			return

		if event is InputEventMouseMotion:
			if _touch_index == -99:
				_update_from_pos(event.position, center)
				accept_event()

	func _update_from_pos(pos: Vector2, center: Vector2):
		var delta := pos - center
		if delta.length() > OUTER_RADIUS:
			delta = delta.normalized() * OUTER_RADIUS
		_knob_offset = delta
		var norm := delta / OUTER_RADIUS
		if norm.length() < DEADZONE:
			vector_changed.emit(Vector2.ZERO)
		else:
			vector_changed.emit(norm)
		queue_redraw()

	func _draw():
		var center := size * 0.5
		draw_circle(center, OUTER_RADIUS, Color(0.08, 0.09, 0.13, 0.56))
		draw_arc(center, OUTER_RADIUS, 0.0, TAU, 36, Color("#D6A84E", 0.85), 2.5)
		draw_arc(center, OUTER_RADIUS - 5.0, 0.0, TAU, 32, Color(0.18, 0.14, 0.08, 0.70), 1.5)

		var knob_pos := center + _knob_offset
		var active := (_touch_index != -1)
		var knob_col := Color("#FFD76B", 0.88) if active else Color("#C8A252", 0.72)
		draw_circle(knob_pos, KNOB_RADIUS, Color(0.14, 0.12, 0.09, 0.88))
		draw_circle(knob_pos, KNOB_RADIUS - 3.0, knob_col)
		draw_arc(knob_pos, KNOB_RADIUS, 0.0, TAU, 24, Color("#FFF3C4", 0.90), 2.0)

class ActionTouchPad extends Control:
	signal pad_pressed
	signal pad_released

	var label_text: String = ""
	var fill_color: Color = Color("#7C2D12")
	var rim_color: Color = Color("#FFD76B")
	var icon_tex: Texture2D = null
	var badge_tex: Texture2D = null
	var cooldown_ratio: float = 0.0
	var dimmed: bool = false

	var _touch_index: int = -1

	func _init():
		mouse_filter = Control.MOUSE_FILTER_STOP

	func release():
		if _touch_index != -1:
			_touch_index = -1
			pad_released.emit()
			queue_redraw()

	func _gui_input(event: InputEvent):
		if event is InputEventScreenTouch:
			if event.pressed and _touch_index == -1:
				_touch_index = event.index
				pad_pressed.emit()
				queue_redraw()
				accept_event()
			elif not event.pressed and event.index == _touch_index:
				release()
				accept_event()
			return

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if _touch_index >= 0:
				accept_event()
				return
			if event.pressed:
				_touch_index = -99
				pad_pressed.emit()
				queue_redraw()
			elif _touch_index == -99:
				release()
			accept_event()

	func _draw():
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 3.0
		var pressed := (_touch_index != -1)
		var is_dim := dimmed or cooldown_ratio > 0.01
		var alpha := 0.48 if is_dim else 0.92
		var bg := fill_color.lightened(0.20) if pressed else fill_color
		bg.a = alpha

		draw_circle(center, radius, Color(0.06, 0.05, 0.04, 0.78))
		draw_circle(center, radius - 3.0, bg)
		draw_arc(center, radius, 0.0, TAU, 32, Color(rim_color.r, rim_color.g, rim_color.b, alpha), 2.5)

		if icon_tex:
			var ic_sz := radius * 0.92
			draw_texture_rect(icon_tex, Rect2(center - Vector2(ic_sz * 0.5, ic_sz * 0.65), Vector2(ic_sz, ic_sz)), false, Color(1, 1, 1, alpha))

		if badge_tex:
			var b_sz := 14.0
			draw_texture_rect(badge_tex, Rect2(Vector2(center.x + radius * 0.25, center.y - radius * 0.72), Vector2(b_sz, b_sz)), false, Color(1, 1, 1, 0.95))

		var font := ThemeDB.fallback_font
		if font and label_text != "":
			var f_sz := 10 if radius < 30.0 else (11 if radius < 36.0 else 12)
			var txt_sz := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz)
			var y_off := radius * 0.54 if icon_tex else txt_sz.y * 0.34
			draw_string(font, Vector2(center.x - txt_sz.x * 0.5, center.y + y_off), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, Color("#FFF8E1", 0.96 if not dimmed else 0.78))

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	_build_controls()
	_layout_controls()
	if get_viewport():
		get_viewport().size_changed.connect(_layout_controls)
	GameState.touch_mode_changed.connect(_sync_visibility)
	GameState.inventory_changed.connect(_refresh_weapon_icon)
	_sync_visibility()

func _layout_controls():
	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280.0, 720.0)
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	_last_vp_size = vp
	position = Vector2.ZERO
	size = vp
	var base_y := vp.y - 76.0

	if is_instance_valid(_joystick):
		_joystick.size = Vector2(156.0, 148.0)
		_joystick.position = Vector2(18.0, base_y - 148.0)

	if is_instance_valid(_attack_pad):
		_attack_pad.size = Vector2(84.0, 84.0)
		_attack_pad.position = Vector2(vp.x - 104.0, base_y - 84.0)

	if is_instance_valid(_dash_pad):
		_dash_pad.size = Vector2(62.0, 62.0)
		_dash_pad.position = Vector2(vp.x - 249.0, base_y - 67.0)

	for sp in SKILL_SPECS:
		var sp_pad: ActionTouchPad = _skill_pads.get(sp.id)
		if is_instance_valid(sp_pad):
			sp_pad.size = Vector2(54.0, 54.0)
			sp_pad.position = Vector2(vp.x + sp.off.x, base_y + sp.off.y)

	if is_instance_valid(_interact_btn):
		_interact_btn.size = Vector2(144.0, 42.0)
		_interact_btn.position = Vector2(vp.x - 404.0, base_y - 50.0)

	if is_instance_valid(_portrait_hint):
		var hint_w := minf(420.0, vp.x - 24.0)
		_portrait_hint.size = Vector2(hint_w, 42.0)
		_portrait_hint.position = Vector2((vp.x - hint_w) * 0.5, 72.0)

func _build_controls():
	_joystick = TouchThumbstick.new()
	_joystick.vector_changed.connect(_on_joystick_changed)
	add_child(_joystick)

	_attack_pad = ActionTouchPad.new()
	_attack_pad.label_text = "ATACAR"
	_attack_pad.fill_color = Color("#991B1B")
	_attack_pad.rim_color = Color("#FFD76B")
	_attack_pad.icon_tex = SpriteFactory.get_item_icon(GameState.equipped_weapon)
	_attack_pad.pad_pressed.connect(func(): _set_attack_held(true))
	_attack_pad.pad_released.connect(func(): _set_attack_held(false))
	add_child(_attack_pad)

	_dash_pad = ActionTouchPad.new()
	_dash_pad.label_text = "DASH"
	_dash_pad.fill_color = Color("#1E3A5F")
	_dash_pad.rim_color = Color("#7DD3FC")
	_dash_pad.pad_pressed.connect(_on_dash_pressed)
	add_child(_dash_pad)

	for sp in SKILL_SPECS:
		var sp_id: String = sp.id
		var sp_pad := ActionTouchPad.new()
		sp_pad.label_text = sp.label
		sp_pad.fill_color = sp.fill
		sp_pad.rim_color = sp.rim
		sp_pad.icon_tex = SpriteFactory.get_spell_texture(sp_id)
		sp_pad.pad_pressed.connect(func(): _on_skill_pressed(sp_id))
		add_child(sp_pad)
		_skill_pads[sp_id] = sp_pad

	_interact_btn = Button.new()
	_interact_btn.visible = false
	_interact_btn.text = "Interagir"
	MedievalUI.style_button(_interact_btn, "gold", "", 13, 44)
	_interact_btn.pressed.connect(_on_interact_pressed)
	add_child(_interact_btn)

	# Dica discreta caso esteja jogando em smartphone na vertical (retrato)
	_portrait_hint = PanelContainer.new()
	_portrait_hint.visible = false
	_portrait_hint.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 12, 6))
	add_child(_portrait_hint)

	var hint_row = HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 8)
	_portrait_hint.add_child(hint_row)

	var hint_lbl = Label.new()
	hint_lbl.text = "Dica: gire o aparelho para Paisagem para melhor visão"
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(hint_lbl, Color("#FFD76B"), 11, 2)
	hint_row.add_child(hint_lbl)

	var ok_hint = Button.new()
	ok_hint.text = "OK"
	MedievalUI.style_button(ok_hint, "stone", "", 11, 28)
	ok_hint.pressed.connect(func():
		_portrait_hint_dismissed = true
		_portrait_hint.visible = false
	)
	hint_row.add_child(ok_hint)

func _refresh_weapon_icon():
	if is_instance_valid(_attack_pad):
		_attack_pad.icon_tex = SpriteFactory.get_item_icon(GameState.equipped_weapon)
		_attack_pad.queue_redraw()

func _get_player() -> Node:
	var scene := get_tree().current_scene
	if scene and "player" in scene and is_instance_valid(scene.player):
		return scene.player
	var plist := get_tree().get_nodes_in_group("player")
	if plist.size() > 0 and is_instance_valid(plist[0]):
		return plist[0]
	return null

func _on_joystick_changed(vec: Vector2):
	var p := _get_player()
	if p and p.has_method("set_virtual_move_input"):
		p.set_virtual_move_input(vec)

func _set_attack_held(held: bool):
	var p := _get_player()
	if p and p.has_method("set_virtual_attack_held"):
		p.set_virtual_attack_held(held)

func _on_dash_pressed():
	var p := _get_player()
	if p and p.has_method("trigger_virtual_dash"):
		p.trigger_virtual_dash()

func _on_skill_pressed(spell_id: String):
	if GameState.unlocked_spells.get(spell_id, false):
		var p := _get_player()
		if p and p.has_method("cast_spell_from_ui"):
			p.cast_spell_from_ui(spell_id)
	else:
		var scene := get_tree().current_scene
		var hud = scene.get("hud") if scene else null
		if is_instance_valid(hud) and hud.has_method("show_spell_unlock_hint"):
			hud.show_spell_unlock_hint(spell_id)

func _on_interact_pressed():
	if not is_instance_valid(_interact_target):
		return
	if _interact_kind == "npc" and _interact_target.has_method("interact"):
		_interact_target.interact()
	elif _interact_kind == "portal":
		_interact_target.portal_triggered.emit(_interact_target.portal_data)

func _sync_visibility():
	var should_show := GameState.are_touch_controls_active() and not get_tree().paused and _get_player() != null
	if visible != should_show:
		visible = should_show
		if should_show:
			_layout_controls()
		else:
			if is_instance_valid(_joystick):
				_joystick.reset()
			if is_instance_valid(_attack_pad):
				_attack_pad.release()
			if is_instance_valid(_dash_pad):
				_dash_pad.release()
			for sp_pad in _skill_pads.values():
				if is_instance_valid(sp_pad):
					sp_pad.release()

func _process(_delta: float):
	_sync_visibility()
	if not visible:
		return

	if get_viewport() and get_viewport().get_visible_rect().size != _last_vp_size:
		_layout_controls()

	var p := _get_player()
	if is_instance_valid(_dash_pad) and p and "dash_cooldown_timer" in p:
		var prev_cd := _dash_pad.cooldown_ratio
		_dash_pad.cooldown_ratio = maxf(0.0, float(p.dash_cooldown_timer))
		if (prev_cd > 0.01) != (_dash_pad.cooldown_ratio > 0.01):
			_dash_pad.queue_redraw()

	_update_skill_pads()
	_update_contextual_interact(p)
	_update_portrait_hint()

func _update_skill_pads():
	var lock_tex := MedievalUI.tex("icon_padlock")
	for sp in SKILL_SPECS:
		var sp_id: String = sp.id
		var sp_pad: ActionTouchPad = _skill_pads.get(sp_id)
		if not is_instance_valid(sp_pad):
			continue
		var unlocked := bool(GameState.unlocked_spells.get(sp_id, false))
		var cd := float(GameState.spell_cooldowns.get(sp_id, 0.0))
		var mana_cost := int(GameData.SPELLS.get(sp_id, {}).get("mana_cost", 0))
		var no_mana := unlocked and GameState.current_mana < mana_cost

		var new_label: String = sp.label
		if not unlocked:
			new_label = "Bloq."
		elif cd > 0.0:
			new_label = "%.1fs" % cd

		var new_cd := maxf(0.0, cd)
		var new_dim := (not unlocked) or no_mana
		var new_badge: Texture2D = null if unlocked else lock_tex

		if sp_pad.label_text != new_label or (sp_pad.cooldown_ratio > 0.01) != (new_cd > 0.01) or sp_pad.dimmed != new_dim or sp_pad.badge_tex != new_badge or new_cd > 0.0:
			sp_pad.label_text = new_label
			sp_pad.cooldown_ratio = new_cd
			sp_pad.dimmed = new_dim
			sp_pad.badge_tex = new_badge
			sp_pad.queue_redraw()

func _update_contextual_interact(p: Node):
	_interact_target = null
	_interact_kind = ""
	if p:
		for npc in get_tree().get_nodes_in_group("npcs"):
			if is_instance_valid(npc) and "player_in_range" in npc and npc.player_in_range:
				_interact_target = npc
				_interact_kind = "npc"
				var npc_id_str := str(npc.npc_id) if "npc_id" in npc else ""
				match npc_id_str:
					"vendedor": _interact_btn.text = "Abrir Loja"
					"explorador": _interact_btn.text = "Ouvir Dica"
					"barao": _interact_btn.text = "Falar" if GameState.victory_achieved else "Resgatar Pai!"
					_: _interact_btn.text = "Conversar"
				break
		if _interact_target == null:
			for portal in get_tree().get_nodes_in_group("portals"):
				if is_instance_valid(portal) and p.global_position.distance_to(portal.global_position) <= 130.0:
					_interact_target = portal
					_interact_kind = "portal"
					_interact_btn.text = "Entrar Portal"
					break
	_interact_btn.visible = (_interact_target != null)

func _update_portrait_hint():
	if _portrait_hint_dismissed or not is_instance_valid(_portrait_hint):
		return
	var win_sz := DisplayServer.window_get_size()
	var is_portrait := win_sz.y > int(float(win_sz.x) * 1.15)
	_portrait_hint.visible = is_portrait
