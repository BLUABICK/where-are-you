extends Node

var lines_seen := 0

func _ready() -> void:
	get_tree().create_timer(20.0).timeout.connect(func():
		push_error("Dialogic smoke test timed out")
		get_tree().quit(1))
	Dialogic.Text.text_started.connect(_on_text)
	Dialogic.timeline_ended.connect(func():
		if lines_seen == 2:
			print("DIALOGIC_SMOKE_PASS: two text events displayed and timeline completed")
			get_tree().quit(0)
		else:
			push_error("Unexpected text event count: %s" % lines_seen)
			get_tree().quit(1))
	var timeline := DialogicTimeline.new()
	timeline.from_text("Dialogic 2: проверка первой реплики.\nВторая реплика: диалог работает.")
	Dialogic.start(timeline)

func _on_text(_info: Dictionary) -> void:
	lines_seen += 1
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
