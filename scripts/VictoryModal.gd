extends Window

## Modal de epílogo exibido após o resgate do Barão Ragnar na Cabana Inimiga.

@onready var daniel_portrait = $Margin/VBox/PortraitsRow/DanielPortrait
@onready var barao_portrait = $Margin/VBox/PortraitsRow/BaraoPortrait
@onready var quote_lbl = $Margin/VBox/QuoteLabel
@onready var stats_lbl = $Margin/VBox/StatsPanel/StatsMargin/StatsLabel
@onready var continue_btn = $Margin/VBox/ButtonsRow/ContinueBtn
@onready var new_game_btn = $Margin/VBox/ButtonsRow/NewGameBtn

func _ready():
	MedievalUI.setup_modal_chrome(self, "gold", 28, 24)
	_apply_medieval_victory_layout()
	close_requested.connect(func(): _close())
	continue_btn.pressed.connect(func(): _close())
	new_game_btn.pressed.connect(_on_new_game_pressed)

func _apply_medieval_victory_layout():
	var banner_lbl = $Margin/VBox/BannerTitle
	MedievalUI.style_label(banner_lbl, Color("#FFD76B"), 20, 3)

	# Moldura de slot ao redor dos retratos de Daniel e Barão Ragnar
	_wrap_portrait_slot(daniel_portrait)
	_wrap_portrait_slot(barao_portrait)

	var heart_lbl = $Margin/VBox/PortraitsRow/HeartLabel
	MedievalUI.style_label(heart_lbl, Color("#FFD76B"), 22, 2)

	# Citação dentro de pergaminho real
	var vbox = $Margin/VBox
	var quote_idx = quote_lbl.get_index()
	var q_panel = PanelContainer.new()
	q_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 14, 10))
	vbox.add_child(q_panel)
	vbox.move_child(q_panel, quote_idx)
	quote_lbl.reparent(q_panel)
	MedievalUI.style_label(quote_lbl, Color("#24160A"), 13, 0)

	# Placa de pedra para estatísticas finais
	var stats_panel = $Margin/VBox/StatsPanel
	stats_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("stone", 12, 8))
	MedievalUI.style_label(stats_lbl, Color("#F5E6C8"), 13, 2)

	MedievalUI.style_button(continue_btn, "gold", "", 13, 34)
	MedievalUI.style_button(new_game_btn, "crimson", "", 13, 34)

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

	var total_sec = int(GameState.play_time_seconds)
	var mins = total_sec / 60
	var secs = total_sec % 60
	var time_str = "%02d:%02d" % [mins, secs]

	var w_name = GameData.WEAPONS.get(GameState.equipped_weapon, {}).get("name", "Espada")
	var a_name = GameData.ARMORS.get(GameState.equipped_armor, {}).get("name", "Roupas Simples")
	var bosses_done = GameState.get_defeated_boss_count()

	quote_lbl.text = "\"Daniel... meu filho! Você cruzou todo o reino, derrotou o Deus Dragão Lunário e veio me salvar com sua faixa vermelha! Você é o verdadeiro Último Herói! A Vila Barão Ragnar está a salvo para sempre!\""

	stats_lbl.text = (
		"Nível Alcançado: %d   |   Tempo de Jornada: %s\n" % [GameState.level, time_str] +
		"Chefes Derrotados: %d / 6   |   Abates Totais: %d\n" % [bosses_done, GameState.total_kills_all_time] +
		"Notas no Bolso: %d   |   Equipamento: %s + %s" % [GameState.cash_notes, w_name, a_name]
	)

	MedievalUI.popup_fit(self, Vector2i(660, 480))

func _close():
	AudioManager.stop_voice()
	hide()

func _on_new_game_pressed():
	AudioManager.stop_voice()
	hide()
	GameState.reset_save()
