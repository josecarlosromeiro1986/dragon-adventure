extends Window

## Janela do Ranking Global de Speedrun separada por categoria (Sem Auto-Hunt vs Com Auto-Hunt).

var _manual_tab_btn: Button
var _auto_tab_btn: Button
var _global_scope_btn: Button
var _mine_scope_btn: Button
var _refresh_btn: Button
var _close_btn: Button
var _status_lbl: Label
var _footer_lbl: Label
var _rows_vbox: VBoxContainer

var _active_category: String = "manual"
var _only_mine: bool = false
var _is_loading: bool = false
var _last_from_network: Dictionary = {}
var _last_error: Dictionary = {}

func _ready():
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	MedievalUI.setup_modal_chrome(self, "stone", 26, 24)
	_build_ui(margin)
	close_requested.connect(hide)
	LeaderboardService.rankings_loaded.connect(_on_rankings_loaded)
	LeaderboardService.submission_finished.connect(_on_submission_finished)

func _build_ui(margin: MarginContainer):
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Cabeçalho padrão (estilo Bestiário / Loja)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var crest_tex := MedievalUI.tex("icon_boss_crest")
	if crest_tex:
		var crest := TextureRect.new()
		crest.texture = crest_tex
		crest.custom_minimum_size = Vector2(28, 28)
		crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(crest)

	var title_lbl := Label.new()
	title_lbl.text = "RANKING GLOBAL — SPEEDRUN"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)
	header.add_child(title_lbl)

	_refresh_btn = Button.new()
	_refresh_btn.text = "Atualizar"
	MedievalUI.style_button(_refresh_btn, "gold", "", 12, 30)
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	header.add_child(_refresh_btn)

	_close_btn = Button.new()
	_close_btn.text = "Fechar"
	MedievalUI.style_button(_close_btn, "crimson", "", 12, 30)
	_close_btn.pressed.connect(hide)
	header.add_child(_close_btn)

	# Linha de abas de categoria e filtro global/local
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs_row)

	_manual_tab_btn = Button.new()
	_manual_tab_btn.text = "Sem Auto-Hunt (Manual)"
	_manual_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_manual_tab_btn.pressed.connect(func(): _select_category("manual"))
	tabs_row.add_child(_manual_tab_btn)

	_auto_tab_btn = Button.new()
	_auto_tab_btn.text = "Com Auto-Hunt"
	_auto_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_tab_btn.pressed.connect(func(): _select_category("auto_hunt"))
	tabs_row.add_child(_auto_tab_btn)

	_global_scope_btn = Button.new()
	_global_scope_btn.text = "Top Global"
	_global_scope_btn.pressed.connect(func(): _set_scope(false))
	tabs_row.add_child(_global_scope_btn)

	_mine_scope_btn = Button.new()
	_mine_scope_btn.text = "Meus Recordes"
	_mine_scope_btn.pressed.connect(func(): _set_scope(true))
	tabs_row.add_child(_mine_scope_btn)

	# Faixa de status (StyleBoxFlat nítido, sem borda 9-slice sobrepondo o texto)
	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", MedievalUI.notes_pill_box(14, 7))
	vbox.add_child(status_panel)

	_status_lbl = Label.new()
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(_status_lbl, Color("#E5E7EB"), 12, 2)
	status_panel.add_child(_status_lbl)

	# Livro em Pergaminho contendo o cabeçalho da tabela e a lista rolável (padrão Bestiário)
	var ledger_page := PanelContainer.new()
	ledger_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ledger_page.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 16, 14, Color("#FFFDF7")))
	vbox.add_child(ledger_page)

	var ledger_vbox := VBoxContainer.new()
	ledger_vbox.add_theme_constant_override("separation", 8)
	ledger_page.add_child(ledger_vbox)

	var col_hdr := PanelContainer.new()
	col_hdr.add_theme_stylebox_override("panel", _make_header_bar_style())
	ledger_vbox.add_child(col_hdr)
	col_hdr.add_child(_build_table_header_row())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ledger_vbox.add_child(scroll)

	_rows_vbox = VBoxContainer.new()
	_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows_vbox)

	# Rodapé da run atual
	var footer_panel := PanelContainer.new()
	footer_panel.add_theme_stylebox_override("panel", MedievalUI.notes_pill_box(14, 7))
	vbox.add_child(footer_panel)

	_footer_lbl = Label.new()
	_footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(_footer_lbl, Color("#FFE28A"), 12, 2)
	footer_panel.add_child(_footer_lbl)

func _make_header_bar_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#3F2612")
	sb.border_color = Color("#9C7338")
	sb.set_border_width_all(1)
	sb.border_width_bottom = 2
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb

func _make_row_card_style(rank: int, is_mine: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if is_mine:
		sb.bg_color = Color(0.84, 0.95, 0.84, 0.92)
		sb.border_color = Color("#2E7D32")
		sb.set_border_width_all(2)
	elif rank == 1:
		sb.bg_color = Color(0.98, 0.91, 0.68, 0.95)
		sb.border_color = Color("#B8860B")
		sb.set_border_width_all(2)
	elif rank == 2:
		sb.bg_color = Color(0.92, 0.93, 0.95, 0.92)
		sb.border_color = Color("#708090")
		sb.set_border_width_all(1)
	elif rank == 3:
		sb.bg_color = Color(0.95, 0.88, 0.78, 0.92)
		sb.border_color = Color("#A0522D")
		sb.set_border_width_all(1)
	else:
		sb.bg_color = Color(0.96, 0.91, 0.80, 0.82) if (rank % 2 == 0) else Color(0.93, 0.87, 0.74, 0.82)
		sb.border_color = Color(0.45, 0.30, 0.16, 0.38)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _build_table_header_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var specs := [
		["#", 48.0, HORIZONTAL_ALIGNMENT_CENTER, false],
		["Jogador", 0.0, HORIZONTAL_ALIGNMENT_LEFT, true],
		["Tempo", 104.0, HORIZONTAL_ALIGNMENT_RIGHT, false],
		["Nível", 52.0, HORIZONTAL_ALIGNMENT_CENTER, false],
		["Versão", 76.0, HORIZONTAL_ALIGNMENT_CENTER, false],
		["Data", 84.0, HORIZONTAL_ALIGNMENT_CENTER, false]
	]
	for sp in specs:
		var lbl := Label.new()
		lbl.text = str(sp[0])
		lbl.horizontal_alignment = sp[2]
		if bool(sp[3]):
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			lbl.custom_minimum_size.x = float(sp[1])
		MedievalUI.style_label(lbl, Color("#FFD76B"), 13, 2)
		row.add_child(lbl)
	return row

func open(default_category: String = ""):
	if default_category == "manual" or default_category == "auto_hunt":
		_active_category = default_category
	else:
		_active_category = GameState.get_run_category()
	_only_mine = false
	_update_tab_styles()
	_update_footer()
	_render_rows()
	MedievalUI.popup_fit(self, Vector2i(820, 540))
	_request_refresh()

func _select_category(cat: String):
	_active_category = LeaderboardService.normalize_category(cat)
	_update_tab_styles()
	_render_rows()
	if not _only_mine:
		_request_refresh()

func _set_scope(only_mine: bool):
	_only_mine = only_mine
	_update_tab_styles()
	_render_rows()

func _on_refresh_pressed():
	_request_refresh()

func _request_refresh():
	_is_loading = true
	_update_status_label()
	if is_instance_valid(_refresh_btn):
		_refresh_btn.disabled = true
	LeaderboardService.fetch_global_rankings(_active_category, 50)

func _on_rankings_loaded(category: String, _entries: Array, from_network: bool, error_msg: String):
	_last_from_network[category] = from_network
	_last_error[category] = error_msg
	if category == _active_category:
		_is_loading = false
		if is_instance_valid(_refresh_btn):
			_refresh_btn.disabled = false
		_render_rows()

func _on_submission_finished(success: bool, entry: Dictionary, _error_msg: String):
	if not visible:
		return
	var submitted_cat := str(entry.get("category", _active_category))
	if success and submitted_cat == _active_category:
		_render_rows()
		_request_refresh()
	else:
		_render_rows()

func _update_tab_styles():
	var is_manual := (_active_category == "manual")
	MedievalUI.style_button(_manual_tab_btn, "gold" if is_manual else "stone", "", 12, 32)
	MedievalUI.style_button(_auto_tab_btn, "green" if not is_manual else "stone", "", 12, 32)
	MedievalUI.style_button(_global_scope_btn, "gold" if not _only_mine else "stone", "", 12, 32)
	MedievalUI.style_button(_mine_scope_btn, "gold" if _only_mine else "stone", "", 12, 32)

func _update_footer():
	if not is_instance_valid(_footer_lbl):
		return
	var t_str := LeaderboardService.format_exact_time(GameState.play_time_seconds)
	var cat_lbl := LeaderboardService.format_category_name(GameState.get_run_category())
	var state_tag := "Campanha Concluída" if GameState.victory_achieved else "Run em Andamento"
	_footer_lbl.text = "%s  •  Tempo: %s  •  Categoria: %s" % [state_tag, t_str, cat_lbl]

func _update_status_label():
	if not is_instance_valid(_status_lbl):
		return
	var pb := LeaderboardService.get_personal_best(_active_category)
	var pb_txt := LeaderboardService.format_exact_time(pb) if pb > 0.0 else "--:--"
	if _only_mine:
		var local_cnt := LeaderboardService.get_local_records(_active_category).size()
		_status_lbl.text = "Meus Recordes (%s)  •  Total salvo: %d  •  Melhor tempo pessoal: %s" % [
			LeaderboardService.format_category_name(_active_category),
			local_cnt,
			pb_txt
		]
		MedievalUI.style_label(_status_lbl, Color("#FFE28A"), 12, 2)
		return
	if _is_loading:
		_status_lbl.text = "Consultando Rank Global (%s)...  •  Seu recorde pessoal: %s" % [
			LeaderboardService.format_category_name(_active_category),
			pb_txt
		]
		MedievalUI.style_label(_status_lbl, Color("#93C5FD"), 12, 2)
		return
	var from_net := bool(_last_from_network.get(_active_category, false))
	var err_msg := str(_last_error.get(_active_category, ""))
	if from_net:
		var cnt := LeaderboardService.get_cached_global_records(_active_category).size()
		_status_lbl.text = "Rank Global Online conectado  •  %d registro(s)  •  Seu recorde pessoal: %s" % [cnt, pb_txt]
		MedievalUI.style_label(_status_lbl, Color("#86EFAC"), 12, 2)
	else:
		var reason := err_msg if err_msg != "" else "exibindo recordes locais salvos"
		_status_lbl.text = "Offline / Fallback local (%s)  •  Seu recorde pessoal: %s" % [reason, pb_txt]
		MedievalUI.style_label(_status_lbl, Color("#FDE68A"), 12, 2)

func _render_rows():
	if not is_instance_valid(_rows_vbox):
		return
	for ch in _rows_vbox.get_children():
		ch.queue_free()

	_update_status_label()
	_update_footer()

	var entries: Array = LeaderboardService.get_local_records(_active_category) if _only_mine else LeaderboardService.get_cached_global_records(_active_category)
	if entries.is_empty():
		var empty_panel := PanelContainer.new()
		empty_panel.add_theme_stylebox_override("panel", _make_row_card_style(4, false))
		_rows_vbox.add_child(empty_panel)
		var empty_lbl := Label.new()
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _only_mine:
			empty_lbl.text = "Você ainda não concluiu nenhuma campanha na categoria %s.\nDerrote Lunário, resgate o Barão Ragnar e registre seu primeiro recorde!" % LeaderboardService.format_category_name(_active_category)
		else:
			empty_lbl.text = "Nenhum tempo registrado ainda em %s.\nSeja o primeiro herói a cravar o recorde mundial!" % LeaderboardService.format_category_name(_active_category)
		MedievalUI.style_label(empty_lbl, Color("#3B2310"), 13, 0)
		empty_panel.add_child(empty_lbl)
		return

	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		_rows_vbox.add_child(_create_entry_row(i + 1, entry))

func _create_entry_row(rank: int, entry: Dictionary) -> Control:
	var is_mine := bool(entry.get("is_local", false))
	var is_synced := bool(entry.get("synced", true))

	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 36
	panel.add_theme_stylebox_override("panel", _make_row_card_style(rank, is_mine))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var rank_col := Color("#3B2310")
	match rank:
		1: rank_col = Color("#8C5200")
		2: rank_col = Color("#334155")
		3: rank_col = Color("#7C2D12")

	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.custom_minimum_size.x = 48.0
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(rank_lbl, rank_col, 13, 0)
	row.add_child(rank_lbl)

	var name_str := str(entry.get("player_name", "Herói"))
	if is_mine and not is_synced:
		name_str += " (local)"
	elif is_mine:
		name_str += " (você)"

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	MedievalUI.style_label(name_lbl, Color("#14532D") if is_mine else Color("#24160A"), 13, 0)
	row.add_child(name_lbl)

	var time_lbl := Label.new()
	time_lbl.text = LeaderboardService.format_exact_time(float(entry.get("time_seconds", 0.0)))
	time_lbl.custom_minimum_size.x = 104.0
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	MedievalUI.style_label(time_lbl, Color("#15803D") if rank == 1 else Color("#6B2D0F"), 13, 0)
	row.add_child(time_lbl)

	var lvl_lbl := Label.new()
	lvl_lbl.text = str(int(entry.get("level", 1)))
	lvl_lbl.custom_minimum_size.x = 52.0
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(lvl_lbl, Color("#422B18"), 12, 0)
	row.add_child(lvl_lbl)

	var ver_lbl := Label.new()
	ver_lbl.text = "v" + str(entry.get("game_version", GameData.get_game_version()))
	ver_lbl.custom_minimum_size.x = 76.0
	ver_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(ver_lbl, Color("#1D4E6B"), 12, 0)
	row.add_child(ver_lbl)

	var date_lbl := Label.new()
	date_lbl.text = LeaderboardService.format_date_short(str(entry.get("created_at", "")))
	date_lbl.custom_minimum_size.x = 84.0
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MedievalUI.style_label(date_lbl, Color("#5A3B22"), 12, 0)
	row.add_child(date_lbl)

	return panel
