extends Window

## Modal de epílogo exibido após o resgate do Barão Ragnar na Cabana Inimiga.

signal open_ranking_requested(category: String)

@onready var daniel_portrait = $Margin/VBox/PortraitsRow/DanielPortrait
@onready var barao_portrait = $Margin/VBox/PortraitsRow/BaraoPortrait
@onready var quote_lbl = $Margin/VBox/QuoteLabel
@onready var stats_lbl = $Margin/VBox/StatsPanel/StatsMargin/StatsLabel
@onready var continue_btn = $Margin/VBox/ButtonsRow/ContinueBtn
@onready var new_game_btn = $Margin/VBox/ButtonsRow/NewGameBtn

var _record_badge_panel: PanelContainer
var _record_badge_lbl: Label
var _name_input: LineEdit
var _submit_btn: Button
var _rank_btn: Button
var _submit_status_lbl: Label

func _ready():
	MedievalUI.setup_modal_chrome(self, "gold", 24, 20)
	_apply_medieval_victory_layout()
	close_requested.connect(func(): _close())
	continue_btn.pressed.connect(func(): _close())
	new_game_btn.pressed.connect(_on_new_game_pressed)
	LeaderboardService.submission_finished.connect(_on_submission_finished)

func _apply_medieval_victory_layout():
	var banner_lbl = $Margin/VBox/BannerTitle
	MedievalUI.style_label(banner_lbl, Color("#FFD76B"), 20, 3)

	_wrap_portrait_slot(daniel_portrait)
	_wrap_portrait_slot(barao_portrait)

	var heart_lbl = $Margin/VBox/PortraitsRow/HeartLabel
	MedievalUI.style_label(heart_lbl, Color("#FFD76B"), 22, 2)

	var vbox = $Margin/VBox
	var quote_idx = quote_lbl.get_index()
	var q_panel = PanelContainer.new()
	q_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 14, 10))
	vbox.add_child(q_panel)
	vbox.move_child(q_panel, quote_idx)
	quote_lbl.reparent(q_panel)
	MedievalUI.style_label(quote_lbl, Color("#24160A"), 12, 0)

	var stats_panel = $Margin/VBox/StatsPanel
	stats_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 12, 8))
	MedievalUI.style_label(stats_lbl, Color("#F5E6C8"), 12, 2)

	# Badge de Recorde Pessoal / Top Global + Envio ao Ranking Online
	var buttons_row = $Margin/VBox/ButtonsRow
	var btn_idx = buttons_row.get_index()

	_record_badge_panel = PanelContainer.new()
	_record_badge_panel.add_theme_stylebox_override("panel", MedievalUI.notes_pill_box(12, 6))
	vbox.add_child(_record_badge_panel)
	vbox.move_child(_record_badge_panel, btn_idx)

	_record_badge_lbl = Label.new()
	_record_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_badge_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(_record_badge_lbl, Color("#FFD76B"), 12, 2)
	_record_badge_panel.add_child(_record_badge_lbl)

	var rank_box := PanelContainer.new()
	rank_box.add_theme_stylebox_override("panel", MedievalUI.notes_pill_box(14, 10))
	vbox.add_child(rank_box)
	vbox.move_child(rank_box, btn_idx + 1)

	var rank_vbox := VBoxContainer.new()
	rank_vbox.add_theme_constant_override("separation", 6)
	rank_box.add_child(rank_vbox)

	var submit_row := HBoxContainer.new()
	submit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	submit_row.add_theme_constant_override("separation", 8)
	rank_vbox.add_child(submit_row)

	var nick_lbl := Label.new()
	nick_lbl.text = "Seu Apelido:"
	MedievalUI.style_label(nick_lbl, Color("#FFE28A"), 12, 2)
	submit_row.add_child(nick_lbl)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Ex: DanielHeroi"
	_name_input.max_length = 20
	_name_input.custom_minimum_size = Vector2(170, 32)
	var line_sb := StyleBoxFlat.new()
	line_sb.bg_color = Color(0.08, 0.08, 0.11, 0.95)
	line_sb.border_color = Color("#B58E43")
	line_sb.set_border_width_all(2)
	line_sb.set_corner_radius_all(4)
	line_sb.content_margin_left = 8
	line_sb.content_margin_right = 8
	_name_input.add_theme_stylebox_override("normal", line_sb)
	_name_input.add_theme_stylebox_override("focus", line_sb)
	_name_input.add_theme_color_override("font_color", Color("#F5E6C8"))
	_name_input.add_theme_font_size_override("font_size", 12)
	submit_row.add_child(_name_input)

	_submit_btn = Button.new()
	_submit_btn.text = "Enviar ao Rank Global"
	MedievalUI.style_button(_submit_btn, "green", "", 12, 32)
	_submit_btn.pressed.connect(_on_submit_pressed)
	submit_row.add_child(_submit_btn)

	_submit_status_lbl = Label.new()
	_submit_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_submit_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MedievalUI.style_label(_submit_status_lbl, Color("#CBD5E1"), 11, 2)
	rank_vbox.add_child(_submit_status_lbl)

	_rank_btn = Button.new()
	_rank_btn.text = "Ver Ranking Global"
	MedievalUI.style_button(_rank_btn, "gold", "", 12, 34)
	_rank_btn.pressed.connect(func():
		open_ranking_requested.emit(GameState.get_run_category())
	)
	buttons_row.add_child(_rank_btn)
	buttons_row.move_child(_rank_btn, 0)

	MedievalUI.style_button(continue_btn, "stone", "", 12, 34)
	MedievalUI.style_button(new_game_btn, "crimson", "", 12, 34)

func _wrap_portrait_slot(tex_r: TextureRect):
	if not is_instance_valid(tex_r):
		return
	var parent = tex_r.get_parent()
	var idx = tex_r.get_index()
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 8, 8))
	parent.add_child(slot)
	parent.move_child(slot, idx)
	tex_r.reparent(slot)

func open():
	if daniel_portrait:
		daniel_portrait.texture = SpriteFactory.get_character_texture("daniel_ragnar", "south")
	if barao_portrait:
		barao_portrait.texture = SpriteFactory.get_character_texture("barao", "south")

	var uid := GameState.ensure_run_uid()
	var cat := GameState.get_run_category()
	var cat_label := LeaderboardService.format_category_name(cat)
	var time_str := LeaderboardService.format_exact_time(GameState.play_time_seconds)
	var is_pb := LeaderboardService.is_personal_best(cat, GameState.play_time_seconds, uid)

	# Registra a corrida localmente de forma idempotente (independe do save da campanha)
	var default_nick := LeaderboardService.last_player_name
	if default_nick.length() < 2:
		default_nick = "Daniel Ragnar"
	if is_instance_valid(_name_input):
		_name_input.text = default_nick
	LeaderboardService.record_local_run(default_nick)

	var w_name = GameData.WEAPONS.get(GameState.equipped_weapon, {}).get("name", "Espada")
	var a_name = GameData.ARMORS.get(GameState.equipped_armor, {}).get("name", "Roupas Simples")
	var bosses_done = GameState.get_defeated_boss_count()

	quote_lbl.text = "\"Daniel... meu filho! Você cruzou todo o reino, derrotou o Deus Dragão Lunário e veio me salvar com sua faixa vermelha! Você é o verdadeiro Último Herói! A Vila Barão Ragnar está a salvo para sempre!\""

	stats_lbl.text = (
		"Tempo Oficial: %s   |   Categoria: %s\n" % [time_str, cat_label] +
		"Nível Alcançado: %d   |   Chefes: %d / 6   |   Abates: %d\n" % [GameState.level, bosses_done, GameState.total_kills_all_time] +
		"Notas no Bolso: %d   |   Equipamento: %s + %s" % [GameState.cash_notes, w_name, a_name]
	)

	var global_cached := LeaderboardService.get_cached_global_records(cat)
	var qualifies_top10 := global_cached.size() < 10 or GameState.play_time_seconds < float(global_cached[mini(9, global_cached.size() - 1)].get("time_seconds", 999999.0))
	if is_pb and qualifies_top10:
		_record_badge_lbl.text = "NOVO RECORDE PESSOAL + POTENCIAL TOP 10 GLOBAL (%s)!" % cat_label
		MedievalUI.style_label(_record_badge_lbl, Color("#FFD76B"), 12, 2)
	elif is_pb:
		_record_badge_lbl.text = "NOVO RECORDE PESSOAL na categoria %s!" % cat_label
		MedievalUI.style_label(_record_badge_lbl, Color("#86EFAC"), 12, 2)
	else:
		var pb := LeaderboardService.get_personal_best(cat)
		_record_badge_lbl.text = "Categoria %s  •  Seu melhor tempo: %s" % [cat_label, LeaderboardService.format_exact_time(pb)]
		MedievalUI.style_label(_record_badge_lbl, Color("#CFE4FF"), 12, 2)

	if LeaderboardService.is_run_synced(uid):
		_submit_btn.text = "Enviado ao Rank!"
		_submit_btn.disabled = true
		_name_input.editable = false
		_submit_status_lbl.text = "Esta corrida já foi registrada no Ranking Global."
		MedievalUI.style_label(_submit_status_lbl, Color("#86EFAC"), 11, 2)
	else:
		_submit_btn.text = "Enviar ao Rank Global"
		_submit_btn.disabled = false
		_name_input.editable = true
		_submit_status_lbl.text = "Tempo salvo localmente. Informe seu apelido e envie para competir no Ranking Global!"
		MedievalUI.style_label(_submit_status_lbl, Color("#CBD5E1"), 11, 2)

	LeaderboardService.fetch_global_rankings(cat, 50)
	MedievalUI.popup_fit(self, Vector2i(700, 560))

func _on_submit_pressed():
	if not is_instance_valid(_name_input):
		return
	var err_txt := LeaderboardService.validate_player_name(_name_input.text)
	if err_txt != "":
		_submit_status_lbl.text = err_txt
		MedievalUI.style_label(_submit_status_lbl, Color("#FCA5A5"), 11, 2)
		return
	_submit_btn.disabled = true
	_submit_btn.text = "Enviando..."
	_submit_status_lbl.text = "Enviando tempo para o Ranking Global..."
	MedievalUI.style_label(_submit_status_lbl, Color("#93C5FD"), 11, 2)
	LeaderboardService.submit_current_run(_name_input.text)

func _on_submission_finished(success: bool, entry: Dictionary, error_msg: String):
	if not visible:
		return
	var current_uid := GameState.ensure_run_uid()
	if not entry.is_empty() and str(entry.get("run_uid", "")) != current_uid:
		return
	if success:
		_submit_btn.text = "Enviado ao Rank!"
		_submit_btn.disabled = true
		_name_input.editable = false
		_submit_status_lbl.text = "Tempo publicado com sucesso no Ranking Global (%s)!" % LeaderboardService.format_category_name(str(entry.get("category", "manual")))
		MedievalUI.style_label(_submit_status_lbl, Color("#86EFAC"), 11, 2)
	else:
		_submit_btn.text = "Tentar Novamente"
		_submit_btn.disabled = false
		_name_input.editable = true
		_submit_status_lbl.text = error_msg if error_msg != "" else "Não foi possível enviar agora."
		MedievalUI.style_label(_submit_status_lbl, Color("#FDE68A"), 11, 2)

func _close():
	AudioManager.stop_voice()
	hide()

func _on_new_game_pressed():
	AudioManager.stop_voice()
	hide()
	GameState.reset_save()
