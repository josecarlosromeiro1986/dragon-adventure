extends Control

## Reprodutor de cutscenes em slides com retratos, SFX, screen shake e dublagem ElevenLabs.

signal cutscene_finished

var _slides: Array = []
var _slide_idx: int = 0
var _slide_cooldown: float = 0.0
var _on_complete: Callable = Callable()

var _backdrop: ColorRect
var _card: PanelContainer
var _header_lbl: Label
var _left_slot: PanelContainer
var _left_tex: TextureRect
var _left_name: Label
var _vs_icon: TextureRect
var _right_slot: PanelContainer
var _right_tex: TextureRect
var _right_name: Label
var _speaker_lbl: Label
var _text_lbl: Label
var _progress_lbl: Label
var _skip_btn: Button
var _next_btn: Button
var _bob_time: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 95
	visible = false
	_build_ui()

func _build_ui():
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.03, 0.02, 0.05, 0.86)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	# Tarjas cinematográficas superior e inferior
	var top_bar = ColorRect.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_bottom = 52.0
	top_bar.color = Color(0.02, 0.02, 0.03, 0.96)
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(top_bar)

	var bot_bar = ColorRect.new()
	bot_bar.anchor_top = 1.0
	bot_bar.anchor_right = 1.0
	bot_bar.anchor_bottom = 1.0
	bot_bar.offset_top = -52.0
	bot_bar.color = Color(0.02, 0.02, 0.03, 0.96)
	bot_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bot_bar)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(720, 420)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_theme_stylebox_override("panel", MedievalUI.panel_box("gold", 26, 22))
	center.add_child(_card)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_card.add_child(vbox)

	_header_lbl = Label.new()
	_header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(_header_lbl, Color("#FFD76B"), 18, 3)
	vbox.add_child(_header_lbl)

	# Palco visual dos personagens / chefes
	var stage_panel = PanelContainer.new()
	stage_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 16, 14, Color(0.92, 0.90, 0.96)))
	vbox.add_child(stage_panel)

	var stage_row = HBoxContainer.new()
	stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_row.add_theme_constant_override("separation", 34)
	stage_panel.add_child(stage_row)

	var left_col = VBoxContainer.new()
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	left_col.add_theme_constant_override("separation", 6)
	stage_row.add_child(left_col)

	_left_slot = PanelContainer.new()
	_left_slot.custom_minimum_size = Vector2(108, 108)
	_left_slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 8, 8))
	left_col.add_child(_left_slot)

	_left_tex = TextureRect.new()
	_left_tex.custom_minimum_size = Vector2(88, 88)
	_left_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_left_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_left_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_left_slot.add_child(_left_tex)

	_left_name = Label.new()
	_left_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(_left_name, Color("#F5E6C8"), 12, 2)
	left_col.add_child(_left_name)

	_vs_icon = TextureRect.new()
	_vs_icon.custom_minimum_size = Vector2(44, 44)
	_vs_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vs_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vs_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage_row.add_child(_vs_icon)

	var right_col = VBoxContainer.new()
	right_col.alignment = BoxContainer.ALIGNMENT_CENTER
	right_col.add_theme_constant_override("separation", 6)
	stage_row.add_child(right_col)

	_right_slot = PanelContainer.new()
	_right_slot.custom_minimum_size = Vector2(108, 108)
	_right_slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 8, 8))
	right_col.add_child(_right_slot)

	_right_tex = TextureRect.new()
	_right_tex.custom_minimum_size = Vector2(88, 88)
	_right_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_right_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_right_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_right_slot.add_child(_right_tex)

	_right_name = Label.new()
	_right_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(_right_name, Color("#F5E6C8"), 12, 2)
	right_col.add_child(_right_name)

	# Caixa de Pergaminho com o Texto Exato da Fala
	var speech_box = PanelContainer.new()
	speech_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	speech_box.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 18, 14))
	vbox.add_child(speech_box)

	var speech_vbox = VBoxContainer.new()
	speech_vbox.add_theme_constant_override("separation", 6)
	speech_box.add_child(speech_vbox)

	_speaker_lbl = Label.new()
	MedievalUI.style_label(_speaker_lbl, Color("#7C2D12"), 14, 0)
	speech_vbox.add_child(_speaker_lbl)

	_text_lbl = Label.new()
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.custom_minimum_size = Vector2(630, 68)
	_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(_text_lbl, Color("#24160A"), 15, 0)
	speech_vbox.add_child(_text_lbl)

	# Controles inferiores
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)

	_progress_lbl = Label.new()
	_progress_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(_progress_lbl, Color("#D6C7B2"), 12, 2)
	footer.add_child(_progress_lbl)

	_skip_btn = Button.new()
	_skip_btn.text = "Pular [Esc]"
	MedievalUI.style_button(_skip_btn, "stone", "", 12, 34)
	_skip_btn.pressed.connect(_finish)
	footer.add_child(_skip_btn)

	_next_btn = Button.new()
	_next_btn.text = "Avançar >>"
	MedievalUI.style_button(_next_btn, "gold", "", 13, 34)
	_next_btn.pressed.connect(_advance_slide)
	footer.add_child(_next_btn)

func start_cutscene(slides: Array, on_complete: Callable = Callable()):
	if slides.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return
	_slides = slides
	_slide_idx = 0
	_on_complete = on_complete
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	_show_current_slide()

func _show_current_slide():
	_slide_cooldown = 0.24
	var s: Dictionary = _slides[_slide_idx]

	var theme_name := str(s.get("theme", "gold"))
	_card.add_theme_stylebox_override("panel", MedievalUI.panel_box(theme_name, 26, 22))

	_header_lbl.text = str(s.get("title", "HISTÓRIA"))
	var is_evil := bool(s.get("is_evil", false))
	_header_lbl.add_theme_color_override("font_color", Color("#FF7A7A") if is_evil else Color("#FFD76B"))

	var l_tex: Texture2D = s.get("left_tex", null)
	var r_tex: Texture2D = s.get("right_tex", null)
	var sym := str(s.get("symbol", ""))

	_left_slot.get_parent().visible = (l_tex != null)
	if l_tex:
		_left_tex.texture = l_tex
		_left_name.text = str(s.get("left_name", ""))
	_right_slot.get_parent().visible = (r_tex != null)
	if r_tex:
		_right_tex.texture = r_tex
		_right_name.text = str(s.get("right_name", ""))

	var sym_tex := _resolve_icon_texture(sym)
	_vs_icon.visible = (sym_tex != null and l_tex != null and r_tex != null)
	_vs_icon.texture = sym_tex

	_speaker_lbl.text = str(s.get("speaker", ""))
	_speaker_lbl.add_theme_color_override("font_color", Color("#991B1B") if is_evil else Color("#7C2D12"))
	_text_lbl.text = str(s.get("text", ""))

	var total := _slides.size()
	_progress_lbl.text = "Cena %d / %d  —  [Espaço / Enter] Avançar" % [_slide_idx + 1, total]
	if _slide_idx == total - 1:
		_next_btn.text = str(s.get("finish_label", "Continuar >>"))
		_next_btn.icon = _resolve_icon_texture(str(s.get("finish_icon", "")))
	else:
		_next_btn.text = str(s.get("next_label", "Avançar >>"))
		_next_btn.icon = _resolve_icon_texture(str(s.get("next_icon", "")))
	if _next_btn.icon != null:
		_next_btn.add_theme_constant_override("icon_max_width", 20)

	var sfx_name := str(s.get("sfx", ""))
	if sfx_name != "":
		AudioManager.play_sfx(sfx_name)

	var shake_val := float(s.get("shake", 0.0))
	if shake_val > 0.0:
		GameState.trigger_shake(shake_val, 0.35)

	var voice_name := str(s.get("voice", ""))
	if voice_name != "":
		AudioManager.play_voice(voice_name)
	else:
		AudioManager.stop_voice()

func _advance_slide():
	if not visible:
		return
	if _slide_idx + 1 < _slides.size():
		_slide_idx += 1
		_show_current_slide()
	else:
		_finish()

func _finish():
	if not visible:
		return
	AudioManager.stop_voice()
	visible = false
	var cb := _on_complete
	_on_complete = Callable()
	_slides.clear()
	cutscene_finished.emit()
	if cb.is_valid():
		cb.call()

func _resolve_icon_texture(sym: String) -> Texture2D:
	if sym == "":
		return null
	var path := ""
	match sym:
		"sword", "⚔":
			path = "res://assets/items/weapon_sword.png"
		"shield", "boss", "🛡":
			path = "res://assets/ui/icon_boss_crest.png"
		"star", "★", "✦":
			path = "res://assets/ui/icon_level_crest.png"
		"heart", "❤":
			path = "res://assets/ui/icon_hp_orb.png"
		"book":
			path = "res://assets/ui/icon_bestiary_book.png"
		"scroll":
			path = "res://assets/ui/icon_map_scroll.png"
		_:
			if sym.begins_with("res://"):
				path = sym
			else:
				return MedievalUI.tex(sym)
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _process(delta: float):
	if not visible:
		return
	if _slide_cooldown > 0.0:
		_slide_cooldown = max(0.0, _slide_cooldown - delta)
	_bob_time += delta
	if _left_tex and _left_slot.get_parent().visible:
		_left_tex.position.y = 10.0 + sin(_bob_time * 3.0) * 2.5
	if _right_tex and _right_slot.get_parent().visible:
		_right_tex.position.y = 10.0 + cos(_bob_time * 3.0) * 2.5

func _input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_finish()
			get_viewport().set_input_as_handled()
		elif _slide_cooldown <= 0.0 and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			_advance_slide()
			get_viewport().set_input_as_handled()
