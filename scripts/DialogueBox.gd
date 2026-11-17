extends Window

## Caixa de diálogo medieval para interações com NPCs e avisos do mundo.

@onready var title_lbl = $Margin/VBox/Title
@onready var text_lbl = $Margin/VBox/Text
@onready var ok_btn = $Margin/VBox/OkBtn

var open_cooldown: float = 0.0
var e_was_down: bool = false
var portrait_rect: TextureRect

func _ready():
	add_to_group("dialogue_box")
	MedievalUI.setup_modal_chrome(self, "stone", 26, 24)
	_build_medieval_layout()

	ok_btn.pressed.connect(_close)
	close_requested.connect(_close)
	window_input.connect(_on_window_input)

func _close():
	AudioManager.stop_voice()
	hide()

func _on_window_input(event: InputEvent):
	if visible and open_cooldown <= 0.0 and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_E, KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_close()
			set_input_as_handled()

func _build_medieval_layout():
	var vbox = $Margin/VBox
	vbox.add_theme_constant_override("separation", 10)
	MedievalUI.style_label(title_lbl, Color("#FFD76B"), 16, 2)

	var scroll_panel = PanelContainer.new()
	scroll_panel.add_theme_stylebox_override("panel", MedievalUI.panel_box("parchment", 12, 10))
	scroll_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll_panel)
	vbox.move_child(scroll_panel, 1)

	var body_hbox = HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 12)
	scroll_panel.add_child(body_hbox)

	var p_slot = PanelContainer.new()
	p_slot.add_theme_stylebox_override("panel", MedievalUI.panel_box("slot", 6, 6))
	p_slot.custom_minimum_size = Vector2(68, 68)
	p_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body_hbox.add_child(p_slot)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(54, 54)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_slot.add_child(portrait_rect)

	text_lbl.reparent(body_hbox)
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MedievalUI.style_label(text_lbl, Color("#24160A"), 13, 0)

	MedievalUI.style_button(ok_btn, "gold", "", 13, 40)

func _resolve_speaker_portrait(speaker: String) -> Texture2D:
	var s = speaker.to_lower()
	if s.contains("alde"):
		return SpriteFactory.get_character_texture("aldeao", "south")
	if s.contains("explorador"):
		return SpriteFactory.get_character_texture("explorador", "south")
	if s.contains("barão") or s.contains("barao") or s.contains("vitória"):
		return SpriteFactory.get_character_texture("barao", "south")
	if s.contains("chefe"):
		return MedievalUI.tex("icon_boss_crest")
	if s.contains("zona"):
		return MedievalUI.tex("icon_map_scroll")
	return SpriteFactory.get_character_texture("daniel_ragnar", "south")

func _process(delta: float):
	if open_cooldown > 0.0:
		open_cooldown -= delta

	var e_down = Input.is_key_pressed(KEY_E)
	if visible and open_cooldown <= 0.0 and e_down and not e_was_down:
		_close()
	e_was_down = e_down

func show_dialogue(speaker: String, text: String):
	title_lbl.text = speaker
	text_lbl.text = text
	if portrait_rect:
		portrait_rect.texture = _resolve_speaker_portrait(speaker)
	open_cooldown = 0.22
	e_was_down = true
	ok_btn.text = "Entendido" if GameState.are_touch_controls_active() else "Entendido [E]"
	MedievalUI.popup_fit(self, Vector2i(580, 265))
