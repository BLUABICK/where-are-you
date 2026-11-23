extends Control
## Visual test room. All artwork is loaded from project resources.

const POSES: Array[String] = ["neutral", "clasped", "hand_on_hip", "arms_crossed", "thoughtful", "relaxed", "explaining", "hands_behind", "holding_wrist", "neck_touch", "hand_on_stomach", "open_palms"]
const TITLES: Array[String] = ["Спокойный", "Руки вместе", "Рука на поясе", "Руки скрещены", "Задумался", "Расслаблен", "Объясняет", "Руки за спиной", "Держит запястье", "Рука у шеи", "Рука на животе", "Открытые ладони"]
const BACKGROUNDS: Array[String] = ["lower_lake", "plaza_interior", "sea_muted"]
const BG_TITLES: Array[String] = ["Нижнее озеро", "Торговый центр", "Балтийское море"]
var pose_index := 0
var background: TextureRect
var portrait: TextureRect
var pose_label: Label
var pose_buttons: Array[Button] = []
var caption: PanelContainer
var character_index := 1
var name_label: Label
var dialogue_text: Label
const CHARACTER_IDS: Array[String] = ["artem", "alyona"]
const CHARACTER_NAMES: Array[String] = ["АРТЁМ", "АЛЁНА"]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	set_background(0)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.anchor_left = 0.5
	portrait.anchor_right = 0.5
	portrait.anchor_bottom = 1.0
	portrait.anchor_top = 1.0
	portrait.offset_left = -330
	portrait.offset_right = 330
	portrait.offset_top = -990
	portrait.offset_bottom = -37
	add_child(portrait)
	var controls := make_panel(Vector2(32, 32), Vector2(345, 640))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	controls.add_child(box)
	var heading := Label.new()
	heading.text = "ТЕСТ ПЕРСОНАЖЕЙ"
	heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	var character_picker := OptionButton.new()
	character_picker.add_item("Артём")
	character_picker.add_item("Алёна")
	character_picker.select(character_index)
	character_picker.item_selected.connect(set_character)
	box.add_child(character_picker)
	var bg_picker := OptionButton.new()
	for title in BG_TITLES:
		bg_picker.add_item(title)
	bg_picker.item_selected.connect(set_background)
	box.add_child(bg_picker)
	pose_label = Label.new()
	box.add_child(pose_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for i in POSES.size():
		var button := Button.new()
		button.text = "%02d. %s" % [i+1, TITLES[i]]
		button.custom_minimum_size = Vector2(145, 44)
		button.add_theme_font_size_override("font_size", 14)
		button.toggle_mode = true
		button.pressed.connect(set_pose.bind(i))
		grid.add_child(button)
		pose_buttons.append(button)
	var hint := Label.new()
	hint.text = "← →  сменить позу\nКнопки 1–9 — позы 1–9\nPNG • прозрачность • nearest"
	hint.add_theme_font_size_override("font_size", 16)
	box.add_child(hint)
	var dialog_button := Button.new()
	dialog_button.text = "Проверить диалог Dialogic 2"
	dialog_button.pressed.connect(start_dialogue)
	box.add_child(dialog_button)
	caption = make_panel(Vector2.ZERO, Vector2.ZERO)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_left = 410
	caption.offset_right = -48
	caption.offset_top = -180
	caption.offset_bottom = -32
	var words := VBoxContainer.new()
	caption.add_child(words)
	name_label = Label.new()
	name_label.text = "АРТЁМ"
	name_label.modulate = Color("82d9ce")
	name_label.add_theme_font_size_override("font_size", 26)
	words.add_child(name_label)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 25)
	words.add_child(dialogue_text)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	set_pose(0)
	set_character(character_index)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--character="):
			var requested := CHARACTER_IDS.find(argument.get_slice("=", 1))
			if requested >= 0:
				set_character(requested)
				character_picker.select(requested)
		if argument.begins_with("--artem-pose="):
			set_pose(argument.get_slice("=", 1).to_int()-1)
	print("ARTEM_TEST_READY: 12 poses, 3 backgrounds, Dialogic button")
	if "--artem-verify" in OS.get_cmdline_user_args():
		verify_resources()
	if "--artem-dialogue-check" in OS.get_cmdline_user_args():
		get_tree().create_timer(20.0).timeout.connect(func(): get_tree().quit(1))
		Dialogic.Text.text_started.connect(_advance_test_dialogue)
		Dialogic.timeline_ended.connect(func():
			print("ARTEM_DIALOGUE_PASS: test timeline completed")
			get_tree().quit())
		start_dialogue()
	if "--artem-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://temp/previews/artem_test.png")
		get_tree().quit()

func make_panel(pos: Vector2, dimensions: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = dimensions
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.09, 0.94)
	style.border_color = Color(0.24, 0.55, 0.54, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func set_pose(index: int) -> void:
	pose_index = wrapi(index, 0, POSES.size())
	var character_id := CHARACTER_IDS[character_index]
	var path := "res://assets/sprites/characters/%s/poses/%s_%02d_%s.png" % [character_id, character_id, pose_index+1, POSES[pose_index]]
	portrait.texture = load(path)
	pose_label.text = "Поза %02d / 12 — %s" % [pose_index+1, TITLES[pose_index]]
	for i in pose_buttons.size():
		pose_buttons[i].set_pressed_no_signal(i == pose_index)

func set_background(index: int) -> void:
	background.texture = load("res://assets/backgrounds/%s.png" % BACKGROUNDS[index])

func set_character(index: int) -> void:
	if Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	character_index = index
	name_label.text = CHARACTER_NAMES[index]
	name_label.modulate = Color("82d9ce") if index == 0 else Color("d7b4f0")
	dialogue_text.text = "Ну что, прогуляемся? Я знаю тут одно классное место." if index == 0 else "Подожди, тут такой красивый свет! Давай я вас сфотографирую."
	caption.show()
	set_pose(pose_index)

func start_dialogue() -> void:
	if Dialogic.current_timeline != null:
		return
	caption.hide()
	Dialogic.start("res://dialogue/timelines/prologue/%s_test.dtl" % CHARACTER_IDS[character_index])

func _on_dialogue_ended() -> void:
	caption.show()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or Dialogic.current_timeline != null:
		return
	if event.keycode == KEY_RIGHT:
		set_pose(pose_index+1)
	elif event.keycode == KEY_LEFT:
		set_pose(pose_index-1)
	elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
		set_pose(event.keycode-KEY_1)

func verify_resources() -> void:
	for c in CHARACTER_IDS.size():
		set_character(c)
		for i in POSES.size():
			set_pose(i)
			assert(portrait.texture != null, "Missing pose %s %d" % [CHARACTER_IDS[c], i])
			assert(portrait.texture.get_size() == Vector2(360, 520), "Pose canvas mismatch")
	for i in BACKGROUNDS.size():
		set_background(i)
		assert(background.texture != null, "Missing background")
	set_pose(0)
	set_background(0)
	print("CHARACTER_RESOURCES_PASS: all 24 pose textures and 3 backgrounds loaded")
	get_tree().quit()

func _advance_test_dialogue(_info: Dictionary) -> void:
	await get_tree().create_timer(0.5).timeout
	Dialogic.Text.skip_text_reveal()
	await get_tree().process_frame
	var event := InputEventAction.new()
	event.action = "dialogic_default_action"
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = "dialogic_default_action"
	event.pressed = false
	Input.parse_input_event(event)
