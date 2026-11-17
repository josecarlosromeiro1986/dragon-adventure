class_name MedievalUI
extends RefCounted

## Utilitários de tema medieval 9-slice, botões, rótulos e badges padronizados da UI.

static var _tex_cache: Dictionary = {}
static var _style_cache: Dictionary = {}
static var _shared_theme: Theme = null

static func tex(asset_name: String) -> Texture2D:
	if _tex_cache.has(asset_name):
		return _tex_cache[asset_name]
	var path = "res://assets/ui/" + asset_name + ".png"
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded:
			_tex_cache[asset_name] = loaded
			return loaded
	return null

static func panel_box(variant: String = "stone", pad_x: int = 14, pad_y: int = 10, tint: Color = Color.WHITE) -> StyleBox:
	var key = "panel_%s_%d_%d_%s" % [variant, pad_x, pad_y, tint.to_html()]
	if _style_cache.has(key):
		return _style_cache[key]

	var tex_name = "panel_" + variant
	if variant == "bar":
		tex_name = "panel_stone"
	var t = tex(tex_name)
	var sb: StyleBox
	if t:
		var st = StyleBoxTexture.new()
		st.texture = t
		var m_x := 22
		var m_y := 22
		match variant:
			"parchment":
				m_x = 18
				m_y = 18
			"slot":
				m_x = 12
				m_y = 12
			"gold":
				m_x = 28
				m_y = 28
			"bar":
				m_x = 22
				m_y = 16
			_:
				m_x = 22
				m_y = 22
		st.texture_margin_left = m_x
		st.texture_margin_right = m_x
		st.texture_margin_top = m_y
		st.texture_margin_bottom = m_y
		st.content_margin_left = pad_x
		st.content_margin_right = pad_x
		st.content_margin_top = pad_y
		st.content_margin_bottom = pad_y
		st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		st.modulate_color = tint
		sb = st
	else:
		var sf = StyleBoxFlat.new()
		sf.bg_color = Color("#1B1F27") if variant != "parchment" else Color("#E3D2AC")
		sf.border_color = Color("#9B7A3B")
		sf.set_border_width_all(2)
		sf.set_corner_radius_all(6)
		sf.content_margin_left = pad_x
		sf.content_margin_right = pad_x
		sf.content_margin_top = pad_y
		sf.content_margin_bottom = pad_y
		sb = sf

	_style_cache[key] = sb
	return sb

static func notes_pill_box(pad_x: int = 12, pad_y: int = 5) -> StyleBox:
	var key = "notes_pill_%d_%d" % [pad_x, pad_y]
	if _style_cache.has(key):
		return _style_cache[key]
	var sf = StyleBoxFlat.new()
	sf.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	sf.border_color = Color("#B58E43")
	sf.set_border_width_all(2)
	sf.set_corner_radius_all(4)
	sf.content_margin_left = pad_x
	sf.content_margin_right = pad_x
	sf.content_margin_top = pad_y
	sf.content_margin_bottom = pad_y
	_style_cache[key] = sf
	return sf

## Cria um badge padronizado com o ícone da cédula de dinheiro e rótulo estilizado.
static func create_notes_badge(pad_x: int = 12, pad_y: int = 5, icon_size: Vector2 = Vector2(20, 14), existing_label: Label = null) -> Dictionary:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", notes_pill_box(pad_x, pad_y))
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	badge.add_child(row)

	var note_tex := SpriteFactory.get_cash_note_texture()
	if note_tex:
		var nr := TextureRect.new()
		nr.texture = note_tex
		nr.custom_minimum_size = icon_size
		nr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		nr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		nr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(nr)

	var lbl: Label = existing_label if is_instance_valid(existing_label) else Label.new()
	if lbl.get_parent() != null:
		lbl.reparent(row)
	else:
		row.add_child(lbl)
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	style_label(lbl, Color("#98EC7E"), 12, 2)
	return {"panel": badge, "label": lbl}

static func parchment_pill_box(pad_x: int = 8, pad_y: int = 3) -> StyleBox:
	var key = "pill_%d_%d" % [pad_x, pad_y]
	if _style_cache.has(key):
		return _style_cache[key]
	var pt = tex("panel_parchment")
	var sb: StyleBox
	if pt:
		var st = StyleBoxTexture.new()
		st.texture = pt
		st.texture_margin_left = 12
		st.texture_margin_right = 12
		st.texture_margin_top = 10
		st.texture_margin_bottom = 10
		st.content_margin_left = pad_x + 4
		st.content_margin_right = pad_x + 4
		st.content_margin_top = pad_y + 3
		st.content_margin_bottom = pad_y + 3
		st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sb = st
	else:
		var sf = StyleBoxFlat.new()
		sf.bg_color = Color("#E8D8B5")
		sf.border_color = Color("#6B4423")
		sf.set_border_width_all(2)
		sf.set_corner_radius_all(4)
		sf.content_margin_left = pad_x
		sf.content_margin_right = pad_x
		sf.content_margin_top = pad_y
		sf.content_margin_bottom = pad_y
		sb = sf
	_style_cache[key] = sb
	return sb

static func button_box(variant: String = "stone", state: String = "normal") -> StyleBox:
	var key = "btn_%s_%s" % [variant, state]
	if _style_cache.has(key):
		return _style_cache[key]

	var state_tex = tex("btn_%s_%s" % [variant, state]) if state != "normal" else null
	var t = state_tex if state_tex else tex("btn_" + variant)
	var sb: StyleBox
	if t:
		var st = StyleBoxTexture.new()
		st.texture = t
		st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		if state_tex and state == "hover":
			# Estado hover do PixelLab inclui 4px de brilho dourado externo em cada borda
			st.texture_margin_left = 16
			st.texture_margin_right = 16
			st.texture_margin_top = 13
			st.texture_margin_bottom = 13
			st.expand_margin_left = 4
			st.expand_margin_right = 4
			st.expand_margin_top = 4
			st.expand_margin_bottom = 4
		else:
			st.texture_margin_left = 12
			st.texture_margin_right = 12
			st.texture_margin_top = 9
			st.texture_margin_bottom = 9

		st.content_margin_left = 12
		st.content_margin_right = 12
		if state == "pressed":
			st.content_margin_top = 6
			st.content_margin_bottom = 4
		else:
			st.content_margin_top = 5
			st.content_margin_bottom = 5

		if state_tex:
			st.modulate_color = Color(1, 1, 1, 0.90) if state == "disabled" else Color.WHITE
		else:
			match state:
				"hover":
					st.modulate_color = Color(1.18, 1.14, 1.06, 1.0)
				"pressed":
					st.modulate_color = Color(0.76, 0.72, 0.68, 1.0)
				"disabled":
					st.modulate_color = Color(0.50, 0.48, 0.46, 0.78)
				_:
					st.modulate_color = Color.WHITE
		sb = st
	else:
		var sf = StyleBoxFlat.new()
		sf.bg_color = Color("#2C323E")
		sf.border_color = Color("#B58E43")
		sf.set_border_width_all(2)
		sf.set_corner_radius_all(4)
		sf.content_margin_left = 10
		sf.content_margin_right = 10
		sf.content_margin_top = 4
		sf.content_margin_bottom = 4
		sb = sf

	_style_cache[key] = sb
	return sb

static func style_button(btn: Button, variant: String = "stone", icon_name: String = "", font_sz: int = 12, min_h: int = 30):
	if not is_instance_valid(btn):
		return
	btn.add_theme_stylebox_override("normal", button_box(variant, "normal"))
	btn.add_theme_stylebox_override("hover", button_box(variant, "hover"))
	btn.add_theme_stylebox_override("pressed", button_box(variant, "pressed"))
	btn.add_theme_stylebox_override("disabled", button_box(variant, "disabled"))
	btn.add_theme_stylebox_override("focus", button_box(variant, "hover"))

	var text_col = Color("#FFF4D2")
	var hover_col = Color("#FFFFFF")
	var disabled_col = Color("#9B958C")
	if variant == "gold":
		text_col = Color("#FFF9E6")
	elif variant == "green":
		text_col = Color("#EEFFEE")

	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", hover_col)
	btn.add_theme_color_override("font_pressed_color", Color("#E8D8B0"))
	btn.add_theme_color_override("font_disabled_color", disabled_col)
	btn.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.01, 0.96))
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if btn.disabled else Control.CURSOR_POINTING_HAND
	if min_h > 0:
		btn.custom_minimum_size.y = max(btn.custom_minimum_size.y, float(min_h))

	if icon_name != "":
		var ic = tex(icon_name)
		if ic:
			btn.icon = ic
			btn.add_theme_constant_override("icon_max_width", 18)

static func style_label(lbl: Label, col: Color = Color("#F5E6C8"), font_sz: int = 12, outline_sz: int = 2):
	if not is_instance_valid(lbl):
		return
	lbl.add_theme_color_override("font_color", col)
	if font_sz > 0:
		lbl.add_theme_font_size_override("font_size", font_sz)
	if outline_sz > 0:
		lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.01, 0.95))
		lbl.add_theme_constant_override("outline_size", outline_sz)
	else:
		lbl.add_theme_constant_override("outline_size", 0)

static func style_progress_bar(bar: ProgressBar, fill_col: Color, rim_col: Color = Color("#B58E43")):
	if not is_instance_valid(bar):
		return
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	bg.border_color = rim_col
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_col
	fill.border_color = fill_col.lightened(0.32)
	fill.border_width_top = 1
	fill.border_width_bottom = 1
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

static func build_medieval_theme() -> Theme:
	if _shared_theme:
		return _shared_theme
	var th = Theme.new()

	var empty_sb = StyleBoxEmpty.new()
	th.set_stylebox("embedded_border", "Window", empty_sb)
	th.set_stylebox("embedded_unfocused_border", "Window", empty_sb)

	# Scrollbar medieval em pedra e latão
	var scroll_track = StyleBoxFlat.new()
	scroll_track.bg_color = Color(0.10, 0.09, 0.08, 0.88)
	scroll_track.border_color = Color("#5A4528")
	scroll_track.set_border_width_all(1)
	scroll_track.set_corner_radius_all(3)
	scroll_track.content_margin_left = 4
	scroll_track.content_margin_right = 4

	var grabber = StyleBoxFlat.new()
	grabber.bg_color = Color("#A88442")
	grabber.border_color = Color("#E8C472")
	grabber.set_border_width_all(1)
	grabber.set_corner_radius_all(3)

	var grabber_hi = StyleBoxFlat.new()
	grabber_hi.bg_color = Color("#C9A255")
	grabber_hi.border_color = Color("#FFF0A6")
	grabber_hi.set_border_width_all(1)
	grabber_hi.set_corner_radius_all(3)

	th.set_stylebox("scroll", "VScrollBar", scroll_track)
	th.set_stylebox("grabber", "VScrollBar", grabber)
	th.set_stylebox("grabber_highlight", "VScrollBar", grabber_hi)
	th.set_stylebox("grabber_pressed", "VScrollBar", grabber_hi)

	# Labels padrão com sombra/contorno legível
	th.set_color("font_color", "Label", Color("#F5E6C8"))
	th.set_color("font_outline_color", "Label", Color(0.05, 0.03, 0.01, 0.92))
	th.set_constant("outline_size", "Label", 2)

	# ConfirmationDialog medieval
	th.set_stylebox("panel", "AcceptDialog", panel_box("stone", 22, 20))
	th.set_stylebox("panel", "ConfirmationDialog", panel_box("stone", 22, 20))

	_shared_theme = th
	return th

static func setup_modal_chrome(win: Window, panel_variant: String = "stone", pad_x: int = 28, pad_y: int = 26) -> Panel:
	if not is_instance_valid(win):
		return null
	win.borderless = true
	win.unresizable = true
	win.transparent = true
	win.transparent_bg = true
	win.theme = build_medieval_theme()

	var frame = win.get_node_or_null("MedievalFrame")
	if not frame:
		frame = Panel.new()
		frame.name = "MedievalFrame"
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win.add_child(frame)
		win.move_child(frame, 0)
	frame.add_theme_stylebox_override("panel", panel_box(panel_variant, 8, 8))

	var margin = win.get_node_or_null("Margin")
	if margin is MarginContainer:
		margin.add_theme_constant_override("margin_left", pad_x)
		margin.add_theme_constant_override("margin_right", pad_x)
		margin.add_theme_constant_override("margin_top", pad_y)
		margin.add_theme_constant_override("margin_bottom", pad_y)
	return frame

## Centraliza uma janela modal ajustando o tamanho para caber em telas desktop, tablet ou mobile.
static func popup_fit(win: Window, desired_size: Vector2i):
	if not is_instance_valid(win):
		return
	var vp := Vector2(1280.0, 720.0)
	if win.get_tree() and win.get_tree().root:
		vp = win.get_tree().root.get_visible_rect().size
	var max_w := maxi(320, int(vp.x) - 24)
	var max_h := maxi(240, int(vp.y) - 24)
	var fitted := Vector2i(mini(desired_size.x, max_w), mini(desired_size.y, max_h))
	win.popup_centered(fitted)
