extends Window

## Modal de configurações de áudio multicanal, guia de controles e replay do prólogo.

signal rewatch_intro_requested

var _channel_rows: Dictionary = {}
var _touch_mode_btn: Button

func _ready():
	title = "Configurações de Áudio & Controles"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	size = Vector2i(620, 490)
	visible = false
	close_requested.connect(func():
		GameState.save_game()
		hide()
	)

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	MedievalUI.setup_modal_chrome(self, "gold", 26, 22)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Cabeçalho
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var ic_sound = MedievalUI.tex("icon_sound")
	if ic_sound:
		var tr = TextureRect.new()
		tr.texture = ic_sound
		tr.custom_minimum_size = Vector2(26, 26)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header.add_child(tr)
	var title_lbl = Label.new()
	title_lbl.text = "MIXER DE ÁUDIO & GUIA DE CONTROLES"
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)
	header.add_child(title_lbl)
	vbox.add_child(header)

	# Painel de Mixer Multicanal
	var audio_panel = PanelContainer.new()
	audio_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 16, 14))
	vbox.add_child(audio_panel)

	var audio_vbox = VBoxContainer.new()
	audio_vbox.add_theme_constant_override("separation", 10)
	audio_panel.add_child(audio_vbox)

	_add_channel_row(audio_vbox, "music", "Música (BGM)", false)
	_add_channel_row(audio_vbox, "sfx", "Efeitos Sonoros (SFX)", true)
	_add_channel_row(audio_vbox, "voice", "Vozes & Dublagens", true)
	_add_touch_mode_row(audio_vbox)

	# Painel de Controles em Pergaminho
	var ctrl_panel = PanelContainer.new()
	ctrl_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ctrl_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 16, 12))
	vbox.add_child(ctrl_panel)

	var ctrl_vbox = VBoxContainer.new()
	ctrl_vbox.add_theme_constant_override("separation", 4)
	ctrl_panel.add_child(ctrl_vbox)

	var ctrl_title = Label.new()
	ctrl_title.text = "GUIA RÁPIDO DO HERÓI"
	MedievalUI.style_label(ctrl_title, Color("#7C2D12"), 13, 0)
	ctrl_vbox.add_child(ctrl_title)

	var ctrl_lines := [
		"• Desktop: WASD / Setas ou Botão Direito para mover; Clique Esquerdo ou Espaço ataca",
		"• Desktop Atalhos: [Shift] Dash, [1]/[2]/[3] Magias, [Q] Comer, [E] Falar, [I]/[B] Menus",
		"• Mobile / Tablet: Joystick esquerdo move; botões Atac/Dash/Interagir + toque nas Magias",
		"• Clique ou toque no Minimapa para caminhar automaticamente e use [Auto: ON] para caçar"
	]
	for ln in ctrl_lines:
		var l = Label.new()
		l.text = ln
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		MedievalUI.style_label(l, Color("#24160A"), 12, 0)
		ctrl_vbox.add_child(l)

	# Rodapé
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)

	var replay_btn = Button.new()
	replay_btn.text = "Rever Prólogo da História"
	MedievalUI.style_button(replay_btn, "gold", "icon_bestiary_book", 12, 32)
	replay_btn.pressed.connect(func():
		GameState.save_game()
		hide()
		rewatch_intro_requested.emit()
	)
	footer.add_child(replay_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var version_lbl = Label.new()
	version_lbl.text = "v%s" % GameData.get_game_version()
	version_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MedievalUI.style_label(version_lbl, Color("#B9A682"), 11, 1)
	footer.add_child(version_lbl)

	var close_btn = Button.new()
	close_btn.text = "Fechar [Esc]"
	MedievalUI.style_button(close_btn, "stone", "", 12, 32)
	close_btn.pressed.connect(func():
		GameState.save_game()
		hide()
	)
	footer.add_child(close_btn)

func _add_channel_row(parent: VBoxContainer, ch_id: String, label_txt: String, with_test: bool):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_txt
	lbl.custom_minimum_size = Vector2(155, 0)
	MedievalUI.style_label(lbl, Color("#F5E6C8"), 12, 2)
	row.add_child(lbl)

	var toggle_btn = Button.new()
	toggle_btn.custom_minimum_size = Vector2(64, 28)
	toggle_btn.pressed.connect(func(): _on_channel_toggled(ch_id))
	row.add_child(toggle_btn)

	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v): _on_channel_slider_changed(ch_id, v))
	row.add_child(slider)

	var pct_lbl = Label.new()
	pct_lbl.custom_minimum_size = Vector2(44, 0)
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	MedievalUI.style_label(pct_lbl, Color("#FFD76B"), 12, 2)
	row.add_child(pct_lbl)

	if with_test:
		var test_btn = Button.new()
		test_btn.text = "Testar"
		MedievalUI.style_button(test_btn, "stone", "", 11, 26)
		test_btn.pressed.connect(func():
			if ch_id == "sfx":
				AudioManager.play_sfx("sword_slash")
			elif ch_id == "voice":
				AudioManager.play_voice("daniel_boss_challenge")
		)
		row.add_child(test_btn)

	_channel_rows[ch_id] = {
		"toggle": toggle_btn,
		"slider": slider,
		"pct": pct_lbl
	}

func _add_touch_mode_row(parent: VBoxContainer):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = "Controles Touch (Mobile)"
	lbl.custom_minimum_size = Vector2(180, 0)
	MedievalUI.style_label(lbl, Color("#F5E6C8"), 12, 2)
	row.add_child(lbl)

	_touch_mode_btn = Button.new()
	_touch_mode_btn.custom_minimum_size = Vector2(160, 28)
	_touch_mode_btn.pressed.connect(_on_touch_mode_cycled)
	row.add_child(_touch_mode_btn)

	var info_lbl = Label.new()
	info_lbl.text = "Smartphone / Tablet"
	info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(info_lbl, Color("#C6B69C"), 11, 1)
	row.add_child(info_lbl)

func _on_touch_mode_cycled():
	var next_mode := "auto"
	match GameState.touch_controls_mode:
		"auto": next_mode = "on"
		"on": next_mode = "off"
		_: next_mode = "auto"
	GameState.set_touch_controls_mode(next_mode)
	_sync_touch_mode_btn()
	GameState.save_game()

func _sync_touch_mode_btn():
	if not is_instance_valid(_touch_mode_btn):
		return
	match GameState.touch_controls_mode:
		"on":
			_touch_mode_btn.text = "Sempre ON"
			MedievalUI.style_button(_touch_mode_btn, "green", "", 11, 28)
		"off":
			_touch_mode_btn.text = "Sempre OFF"
			MedievalUI.style_button(_touch_mode_btn, "crimson", "", 11, 28)
		_:
			var auto_state := "Ativo" if GameState.are_touch_controls_active() else "Desktop"
			_touch_mode_btn.text = "Auto (" + auto_state + ")"
			MedievalUI.style_button(_touch_mode_btn, "gold", "", 11, 28)

func _sync_ui_from_audio():
	var cfg := AudioManager.get_settings()
	_sync_row("music", bool(cfg.get("bgm_enabled", true)), float(cfg.get("music_volume", 0.85)))
	_sync_row("sfx", bool(cfg.get("sfx_enabled", true)), float(cfg.get("sfx_volume", 0.90)))
	_sync_row("voice", bool(cfg.get("voice_enabled", true)), float(cfg.get("voice_volume", 1.0)))

func _sync_row(ch_id: String, enabled: bool, vol: float):
	var r: Dictionary = _channel_rows.get(ch_id, {})
	if r.is_empty():
		return
	var btn: Button = r["toggle"]
	var slider: HSlider = r["slider"]
	var pct: Label = r["pct"]

	btn.text = "ON" if enabled else "OFF"
	MedievalUI.style_button(btn, "green" if enabled else "crimson", "", 11, 26)
	slider.set_value_no_signal(vol)
	pct.text = str(int(round(vol * 100.0))) + "%"

func _on_channel_toggled(ch_id: String):
	var cfg := AudioManager.get_settings()
	match ch_id:
		"music":
			cfg["bgm_enabled"] = not bool(cfg.get("bgm_enabled", true))
		"sfx":
			cfg["sfx_enabled"] = not bool(cfg.get("sfx_enabled", true))
		"voice":
			cfg["voice_enabled"] = not bool(cfg.get("voice_enabled", true))
	AudioManager.apply_settings(cfg)
	_sync_ui_from_audio()
	GameState.save_game()

func _on_channel_slider_changed(ch_id: String, val: float):
	var cfg := AudioManager.get_settings()
	match ch_id:
		"music":
			cfg["music_volume"] = val
		"sfx":
			cfg["sfx_volume"] = val
		"voice":
			cfg["voice_volume"] = val
	AudioManager.apply_settings(cfg)
	_sync_ui_from_audio()

func open():
	_sync_ui_from_audio()
	_sync_touch_mode_btn()
	MedievalUI.popup_fit(self, Vector2i(640, 520))
