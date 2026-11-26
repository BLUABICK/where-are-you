extends Control
## Unified visual lab. All dialogue is non-canonical, spoiler-free placeholder text.
const Data = preload("res://tests/sprite_lab_data.gd")
var character_index: int = 0
var pose_index: int = 0
var line_index: int = 0
var background_index: int = 0
var zoom: float = 1.0
var reveal: float = 0.0
var awaiting_choice: bool = false
var branch_text: String = ""
var auto_pose: bool = true
var portrait_bounds := Rect2i(0, 0, 360, 520)
var portrait: TextureRect
var scenery: TextureRect
var solid: ColorRect
var stage: Control
var speaker: Label
var words: RichTextLabel
var line_counter: Label
var pose_title: Label
var status: Label
var choices: HBoxContainer
var next_button: Button
var dialogue_panel: PanelContainer
var dialogue_toggle: Button
var pose_buttons: Array[Button] = []
var character_buttons: Array[Button] = []
var background_picker: OptionButton

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 build_ui()
 set_background(0)
 set_character(0)
 for argument: String in OS.get_cmdline_user_args():
  if argument.begins_with("--character="):
   var index: int = Data.IDS.find(argument.get_slice("=", 1))
   if index >= 0:
    set_character(index)
  elif argument.begins_with("--pose="):
   set_pose(clampi(argument.get_slice("=", 1).to_int() - 1, 0, 11))
  elif argument == "--preview-only":
   toggle_dialogue()
  elif argument.begins_with("--background="):
   set_background(clampi(argument.get_slice("=", 1).to_int(), 0, Data.BACKGROUNDS.size() + 2))
 if "--lab-choice-preview" in OS.get_cmdline_user_args():
  line_index = 2
  show_line()
  words.visible_ratio = 1.0
  advance_dialogue()
 await get_tree().process_frame
 place_portrait()
 if "--lab-verify" in OS.get_cmdline_user_args():
  await verify_lab()
 elif "--lab-capture" in OS.get_cmdline_user_args():
  words.visible_ratio = 1.0
  set_process(false)
  await RenderingServer.frame_post_draw
  await RenderingServer.frame_post_draw
  var capture_path: String = "res://temp/previews/sprite_lab.png"
  for argument: String in OS.get_cmdline_user_args():
   if argument.begins_with("--capture-path="):
    capture_path = argument.trim_prefix("--capture-path=")
  var result: Error = get_viewport().get_texture().get_image().save_png(capture_path)
  print("LAB_CAPTURE: ", capture_path, " result=", result)
  get_tree().quit(result)

func label_for(text: String, font_size: int = 20, color: Color = Color("e5e9ef")) -> Label:
 var label := Label.new()
 label.text = text
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 return label

func box_style(color: Color, border: Color = Color("343b49"), radius: int = 18, padding: int = 20) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.border_color = border
 style.set_border_width_all(1)
 style.set_corner_radius_all(radius)
 style.content_margin_left = padding
 style.content_margin_right = padding
 style.content_margin_top = padding
 style.content_margin_bottom = padding
 return style

func button_for(text: String, action: Callable) -> Button:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size.y = 44
 button.add_theme_font_size_override("font_size", 19)
 button.focus_mode = Control.FOCUS_NONE
 button.pressed.connect(action)
 return button

func build_ui() -> void:
 var theme := Theme.new()
 theme.default_font_size = 20
 theme.set_stylebox("normal", "Button", box_style(Color("222936"), Color("384252"), 10, 10))
 theme.set_stylebox("hover", "Button", box_style(Color("354457"), Color("8bd4c0"), 10, 10))
 theme.set_stylebox("pressed", "Button", box_style(Color("344f4b"), Color("8bd4c0"), 10, 10))
 theme.set_stylebox("normal", "OptionButton", box_style(Color("222936"), Color("384252"), 10, 12))
 theme.set_color("font_color", "Button", Color("edf1f5"))
 self.theme = theme
 var backdrop := ColorRect.new()
 backdrop.color = Color("10151e")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(backdrop)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side: String in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + side, 28)
 add_child(margin)
 var main := VBoxContainer.new()
 main.add_theme_constant_override("separation", 20)
 margin.add_child(main)
 var header := HBoxContainer.new()
 header.add_theme_constant_override("separation", 22)
 main.add_child(header)
 header.add_child(label_for("ВЫ ГДЕ?", 32, Color("f1e5d0")))
 var subtitle := label_for("Лаборатория персонажей", 23)
 subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(subtitle)
 header.add_child(label_for("05 героев  /  60 поз  /  без спойлеров", 18, Color("91a3b8")))
 var body := HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation", 22)
 main.add_child(body)
 var sidebar := PanelContainer.new()
 sidebar.custom_minimum_size.x = 340
 sidebar.add_theme_stylebox_override("panel", box_style(Color("181f2b")))
 body.add_child(sidebar)
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 sidebar.add_child(scroll)
 var controls := VBoxContainer.new()
 controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 controls.add_theme_constant_override("separation", 8)
 scroll.add_child(controls)
 controls.add_child(label_for("ПЕРСОНАЖ", 16, Color("91a3b8")))
 for i: int in Data.IDS.size():
  var button := button_for(Data.NAMES[i], set_character.bind(i))
  button.alignment = HORIZONTAL_ALIGNMENT_LEFT
  button.toggle_mode = true
  character_buttons.append(button)
  controls.add_child(button)
 controls.add_child(HSeparator.new())
 controls.add_child(label_for("ОКРУЖЕНИЕ", 16, Color("91a3b8")))
 background_picker = OptionButton.new()
 background_picker.custom_minimum_size.y = 46
 background_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for title: String in Data.BG_NAMES:
  background_picker.add_item(title)
 for title: String in ["Белая подложка", "Тёмная подложка", "Серая подложка"]:
  background_picker.add_item(title)
 background_picker.item_selected.connect(set_background)
 controls.add_child(background_picker)
 controls.add_child(label_for("ПОЗА", 16, Color("91a3b8")))
 var grid := GridContainer.new()
 grid.columns = 4
 grid.add_theme_constant_override("h_separation", 8)
 grid.add_theme_constant_override("v_separation", 8)
 controls.add_child(grid)
 for i: int in Data.POSES.size():
  var button := button_for("%02d" % (i + 1), set_pose.bind(i))
  button.custom_minimum_size.x = 62
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.toggle_mode = true
  button.tooltip_text = Data.POSE_NAMES[i]
  pose_buttons.append(button)
  grid.add_child(button)
 pose_title = label_for("", 18)
 controls.add_child(pose_title)
 var pose_toggle := CheckButton.new()
 pose_toggle.text = "Жесты по ходу диалога"
 pose_toggle.button_pressed = true
 pose_toggle.toggled.connect(func(enabled: bool): auto_pose = enabled)
 controls.add_child(pose_toggle)
 var zoom_label := label_for("Масштаб персонажа", 16, Color("91a3b8"))
 controls.add_child(zoom_label)
 var slider := HSlider.new()
 slider.min_value = 0.65
 slider.max_value = 1.6
 slider.step = 0.05
 slider.value = 1.0
 slider.custom_minimum_size.y = 26
 slider.value_changed.connect(func(value: float):
  zoom = value
  place_portrait())
 controls.add_child(slider)
 controls.add_child(button_for("Начать диалог заново", restart_dialogue))
 controls.add_child(label_for("← → позы · Space / Enter реплика", 15, Color("91a3b8")))
 stage = Control.new()
 stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
 stage.clip_contents = true
 body.add_child(stage)
 solid = ColorRect.new()
 solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 solid.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(solid)
 scenery = TextureRect.new()
 scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(scenery)
 portrait = TextureRect.new()
 portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(portrait)
 var badge := PanelContainer.new()
 badge.position = Vector2(22, 20)
 badge.add_theme_stylebox_override("panel", box_style(Color(0.06, 0.09, 0.13, 0.85), Color("51606d"), 10, 12))
 badge.add_child(label_for("ПРЕВЬЮ  ·  временные реплики", 16, Color("f1e5d0")))
 stage.add_child(badge)
 dialogue_toggle = button_for("Скрыть диалог", toggle_dialogue)
 dialogue_toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 dialogue_toggle.offset_left = -222
 dialogue_toggle.offset_right = -22
 dialogue_toggle.offset_top = 20
 dialogue_toggle.offset_bottom = 64
 stage.add_child(dialogue_toggle)
 var dialogue := PanelContainer.new()
 dialogue_panel = dialogue
 dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 dialogue.offset_left = 22
 dialogue.offset_right = -22
 dialogue.offset_top = -260
 dialogue.offset_bottom = -22
 dialogue.add_theme_stylebox_override("panel", box_style(Color(0.055, 0.08, 0.115, 0.96), Color("69736f"), 18, 24))
 stage.add_child(dialogue)
 var conversation := VBoxContainer.new()
 conversation.add_theme_constant_override("separation", 10)
 dialogue.add_child(conversation)
 var speaker_row := HBoxContainer.new()
 conversation.add_child(speaker_row)
 speaker = label_for("", 27)
 speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 speaker_row.add_child(speaker)
 line_counter = label_for("", 17, Color("91a3b8"))
 speaker_row.add_child(line_counter)
 words = RichTextLabel.new()
 words.bbcode_enabled = false
 words.custom_minimum_size.y = 72
 words.size_flags_vertical = Control.SIZE_EXPAND_FILL
 words.scroll_active = false
 words.add_theme_font_size_override("normal_font_size", 26)
 words.add_theme_color_override("default_color", Color("eef0eb"))
 words.mouse_filter = Control.MOUSE_FILTER_STOP
 words.gui_input.connect(func(event: InputEvent):
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
   advance_dialogue()
   words.accept_event())
 conversation.add_child(words)
 choices = HBoxContainer.new()
 choices.add_theme_constant_override("separation", 12)
 choices.add_child(button_for("Ещё немного погулять", choose.bind(0)))
 choices.add_child(button_for("Сделать паузу", choose.bind(1)))
 conversation.add_child(choices)
 var footer := HBoxContainer.new()
 conversation.add_child(footer)
 var note := label_for("Диалог-заглушка · не часть сюжета", 16, Color("91a3b8"))
 note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(note)
 next_button = button_for("Далее  →", advance_dialogue)
 next_button.custom_minimum_size.x = 155
 footer.add_child(next_button)
 status = label_for("", 16, Color("91a3b8"))
 main.add_child(status)
 stage.resized.connect(place_portrait)

func set_character(index: int) -> void:
 character_index = index
 for i: int in character_buttons.size():
  character_buttons[i].set_pressed_no_signal(i == index)
 speaker.text = Data.NAMES[index]
 speaker.modulate = Data.COLORS[index]
 restart_dialogue()

func set_background(index: int) -> void:
 background_index = index
 background_picker.select(index)
 scenery.visible = index < Data.BACKGROUNDS.size()
 if scenery.visible:
  scenery.texture = load("res://assets/backgrounds/%s.png" % Data.BACKGROUNDS[index])
 else:
  solid.color = [Color.WHITE, Color("151d29"), Color("808080")][index - Data.BACKGROUNDS.size()]

func set_pose(index: int) -> void:
 pose_index = wrapi(index, 0, Data.POSES.size())
 var id: String = Data.IDS[character_index]
 var path: String = "res://assets/sprites/characters/%s/poses/%s_%02d_%s.png" % [id, id, pose_index + 1, Data.POSES[pose_index]]
 portrait.texture = load(path)
 if portrait.texture != null:
  portrait_bounds = portrait.texture.get_image().get_used_rect()
 pose_title.text = "%02d / 12 · %s" % [pose_index + 1, Data.POSE_NAMES[pose_index]]
 for i: int in pose_buttons.size():
  pose_buttons[i].set_pressed_no_signal(i == pose_index)
 status.text = "%s  ·  %s  ·  360 × 520 RGBA" % [Data.NAMES[character_index], Data.POSE_NAMES[pose_index]]
 place_portrait()

func place_portrait() -> void:
 if portrait == null or stage == null:
  return
 var visible_height: float = stage.size.y * 0.92 * zoom
 var drawing_scale: float = visible_height / maxf(float(portrait_bounds.size.y), 1.0)
 portrait.size = Vector2(360, 520) * drawing_scale
 portrait.position = Vector2((stage.size.x - portrait.size.x) * 0.5, stage.size.y - float(portrait_bounds.end.y + 16) * drawing_scale)

func restart_dialogue() -> void:
 line_index = 0
 branch_text = ""
 show_line()
 # Reset manual pose consistently even if automatic gestures are disabled.
 set_pose(0)

func show_line() -> void:
 awaiting_choice = false
 dialogue_panel.offset_top = -260
 choices.hide()
 next_button.show()
 words.text = branch_text if line_index == 3 and not branch_text.is_empty() else Data.LINES[character_index][line_index]
 words.visible_characters = 0
 reveal = 0.0
 line_counter.text = "%02d / 05" % (line_index + 1)
 next_button.text = "Заново  ↻" if line_index == 4 else "Далее  →"
 if auto_pose:
  set_pose(Data.LINE_POSES[line_index])

func toggle_dialogue() -> void:
 dialogue_panel.visible = not dialogue_panel.visible
 dialogue_toggle.text = "Скрыть диалог" if dialogue_panel.visible else "Показать диалог"

func _process(delta: float) -> void:
 if words == null or words.visible_ratio >= 1.0:
  return
 reveal += delta * 42.0
 words.visible_characters = mini(int(reveal), words.get_total_character_count())

func advance_dialogue() -> void:
 if words.visible_ratio < 1.0:
  words.visible_ratio = 1.0
  return
 if awaiting_choice:
  return
 if line_index == 2:
  awaiting_choice = true
  dialogue_panel.offset_top = -310
  choices.show()
  next_button.hide()
  return
 line_index = (line_index + 1) % 5
 show_line()

func choose(index: int) -> void:
 branch_text = "Хорошо, давайте ещё немного пройдёмся. Сегодня отличный день для прогулки." if index == 0 else "Договорились. Найдём спокойное место и немного отдохнём."
 line_index = 3
 show_line()

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:
  return
 if event.keycode == KEY_RIGHT:
  set_pose(pose_index + 1)
 elif event.keycode == KEY_LEFT:
  set_pose(pose_index - 1)
 elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
  advance_dialogue()
 else:
  return
 get_viewport().set_input_as_handled()

func verify_lab() -> void:
 var failures: Array[String] = []
 for c: int in Data.IDS.size():
  set_character(c)
  for p: int in Data.POSES.size():
   set_pose(p)
   if portrait.texture == null or portrait.texture.get_size() != Vector2(360, 520):
    failures.append("Invalid pose %s %d" % [Data.IDS[c], p + 1])
   else:
    var image: Image = portrait.texture.get_image()
    var used: Rect2i = image.get_used_rect()
    if image.detect_alpha() == Image.ALPHA_NONE or used.position.x <= 0 or used.position.y <= 0 or used.end.x >= 360 or used.end.y >= 520:
     failures.append("Missing transparent padding: %s %d" % [Data.IDS[c], p + 1])
  for option: int in 2:
   restart_dialogue()
   for step: int in 3:
    words.visible_ratio = 1.0
    advance_dialogue()
   if not awaiting_choice or not choices.visible:
    failures.append("Missing dialogue choice: " + Data.IDS[c])
   choose(option)
   if words.text.is_empty() or line_index != 3 or awaiting_choice:
    failures.append("Invalid dialogue branch")
   words.visible_ratio = 1.0
   advance_dialogue()
   words.visible_ratio = 1.0
   advance_dialogue()
   if line_index != 0:
    failures.append("Dialogue restart failed")
 for b: int in Data.BACKGROUNDS.size() + 3:
  set_background(b)
  if b < Data.BACKGROUNDS.size() and scenery.texture == null:
   failures.append("Missing background")
 set_character(0)
 set_background(0)
 await get_tree().process_frame
 if failures.is_empty():
  print("SPRITE_LAB_PASS: 60 pose textures, 12 backgrounds, 3 solid backdrops, 10 dialogue branches and restarts")
  get_tree().quit(0)
 else:
  for failure: String in failures:
   push_error(failure)
  get_tree().quit(1)
