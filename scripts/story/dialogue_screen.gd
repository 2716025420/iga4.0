class_name DialogueScreen
extends Control

signal dialogue_completed(dialogue_id: String)

@onready var bg_texture: TextureRect = $Background
@onready var left_char_sprite: TextureRect = $CharArea/LeftChar
@onready var right_char_sprite: TextureRect = $CharArea/RightChar
@onready var nameplate: Label = $DialogueBox/Margin/VBox/Nameplate
@onready var text_label: RichTextLabel = $DialogueBox/Margin/VBox/TextLabel
@onready var choices_container: VBoxContainer = $ChoicesArea/ChoicesContainer
@onready var choices_panel: PanelContainer = $ChoicesArea
@onready var auto_button: Button = $ControlBar/AutoButton
@onready var skip_button: Button = $ControlBar/SkipButton

var current_dialogue_id: String = ""
var current_lines: Array[Dictionary] = []
var line_index: int = 0

var is_typing: bool = false
var is_auto: bool = false
var full_current_text: String = ""
var tween_typing: Tween

# 角色立绘资源缓存
var character_sprites: Dictionary = {}
var _dialogue_finishing: bool = false
var _line_generation: int = 0
var _last_speaking_key: String = ""
var _char_motion_tween: Tween = null
var pause_button: Button
var record_button: Button
var history_panel: Control
var history_text: RichTextLabel
var history: Array[Dictionary] = []
var _history_keys: Dictionary = {}
var _archive_mode := false
var _exploration_mode := false
var _calendar_mode := false
var _current_cutscene_id := ""
var story_presentation: SchoolDialoguePresentation

func _ready() -> void:
	theme = DaylightUI.get_theme()
	choices_panel.visible = false
	auto_button.toggled.connect(_on_auto_toggled)
	skip_button.pressed.connect(_on_skip_pressed)
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.pressed.connect(_on_pause_pressed)
	add_child(pause_button)
	_build_history()
	story_presentation = SchoolDialoguePresentation.new()
	add_child(story_presentation)
	story_presentation.build(self)
	resized.connect(_layout_story_scene)
	var d_id := GameState.pending_dialogue_id
	load_dialogue(d_id if d_id != "" else "campus_morning")

func _layout_story_scene() -> void:
	if is_instance_valid(story_presentation): story_presentation.update_scene(_current_cutscene_id)

func load_dialogue(dialogue_id: String) -> void:
	_line_generation += 1
	_current_cutscene_id = ""
	if tween_typing and tween_typing.is_valid(): tween_typing.kill()
	_dialogue_finishing = false
	_archive_mode = GameState.archive_dialogue_id != ""
	if _archive_mode: dialogue_id = GameState.archive_dialogue_id
	pause_button.text = "回到记录" if _archive_mode else "暂离"
	_exploration_mode = not _archive_mode and GameState.exploration_active and SchoolExplorationFlow.enabled() and GameState.exploration_state.get("stage", "") == "dialogue"
	_calendar_mode = not _archive_mode and not _exploration_mode and DayCycle.is_event_dialogue(dialogue_id)
	current_dialogue_id = dialogue_id
	left_char_sprite.visible = false
	right_char_sprite.visible = false
	line_index = 0
	if _exploration_mode:
		var node := GameState.get_exploration_node(str(GameState.exploration_state.get("current_node_id", "")))
		current_dialogue_id = "exploration:" + str(node.get("id", ""))
		current_lines = SchoolExplorationRoutes.dialogue_lines(node)
		line_index = clampi(int(GameState.exploration_state.get("dialogue_line", 0)), 0, current_lines.size())
	else:
		current_lines = _get_script_lines(dialogue_id)
		var node_id: String = PhaseTwoContent.node_for_dialogue(dialogue_id)
		var step: Dictionary = PhaseTwoContent.step_for(node_id) if node_id != "" else {}
		var expected_stage := "post_dialogue" if str(step.get("post_dialogue", "")) == dialogue_id else "dialogue"
		if not _archive_mode and node_id != "" and GameState.phase_two_checkpoint.get("node_id", "") == node_id and GameState.phase_two_checkpoint.get("stage", "") == expected_stage:
			line_index = clampi(int(GameState.phase_two_checkpoint.get("line_index", 0)), 0, maxi(0, current_lines.size()-1))
	if _calendar_mode:
		line_index = clampi(int(DayCycle.pending_event().get("line_index",0)),0,maxi(0,current_lines.size()-1))
		pause_button.text = "保存并暂离"
	auto_button.set_pressed_no_signal(is_auto)
	SchoolObjectUI.set_selected(auto_button,is_auto)
	choices_panel.visible = false
	if is_instance_valid(history_panel): history_panel.visible = false
	AudioManager.play_bgm_for_scene(SceneManager.TargetScene.STORY, false, current_dialogue_id)
	_show_next_line()
	if not _archive_mode and line_index == 0 and is_instance_valid(story_presentation):
		if current_dialogue_id in ["campus_morning", "prologue_intro", "chapter_1_intro"]:
			story_presentation.show_chapter_banner(PhaseTwoContent.PROLOGUE_TITLE)
		elif current_dialogue_id in ["school_affairs", "after_school"]:
			story_presentation.show_chapter_banner(PhaseTwoContent.CHAPTER_TITLE)
	DaylightUI.layout(self)

func _get_script_lines(d_id: String) -> Array[Dictionary]:
	return PhaseTwoContent.lines_for(d_id)

func _show_next_line() -> void:
	if _dialogue_finishing:
		return
	if line_index >= current_lines.size():
		_finish_dialogue()
		return
	if line_index > 0 and is_instance_valid(story_presentation):
		story_presentation.hide_chapter_banner()
	_checkpoint_line()
	_line_generation += 1
	var generation := _line_generation
	var data := current_lines[line_index]
	_current_cutscene_id = str(data.get("cutscene", ""))
	if is_instance_valid(story_presentation):
		story_presentation.update_scene(_current_cutscene_id)
	nameplate.text = " " + data.get("speaker", "旁白") + " "
	_refresh_speaker_avatar(data)
	var clear_stage := bool(data.get("clear_stage", false))
	var clear_side := str(data.get("clear_side", "")).strip_edges().to_lower()
	var speaker_char: String = str(data.get("char", ""))
	var speaker_side: String = str(data.get("side", "left"))
	var resolved_emotion := _speaker_emotion(data)
	var sprite_path := PhaseTwoContent.dialogue_character_path(speaker_char, resolved_emotion) if speaker_char != "" else ""
	var speaking_sprite: TextureRect = left_char_sprite if speaker_side == "left" else right_char_sprite
	var other_sprite: TextureRect = right_char_sprite if speaking_sprite == left_char_sprite else left_char_sprite
	for sprite_node: TextureRect in [left_char_sprite, right_char_sprite]:
		var old_shimmer: Node = sprite_node.get_node_or_null("LoopVFX_crystal_shimmer")
		if old_shimmer != null:
			old_shimmer.queue_free()
	if _char_motion_tween != null and is_instance_valid(_char_motion_tween):
		_char_motion_tween.kill()
		_char_motion_tween = null
	if clear_stage or clear_side in ["all", "both", "全部"]:
		left_char_sprite.visible = false
		right_char_sprite.visible = false
		_last_speaking_key = ""
	elif clear_side in ["left", "左"]:
		left_char_sprite.visible = false
		if _last_speaking_key.begins_with("left:"):
			_last_speaking_key = ""
	elif clear_side in ["right", "右"]:
		right_char_sprite.visible = false
		if _last_speaking_key.begins_with("right:"):
			_last_speaking_key = ""
	if speaker_char == "":
		left_char_sprite.visible = false
		right_char_sprite.visible = false
		_last_speaking_key = ""
	else:
		var speaker_key: String = "%s:%s" % [speaker_side, speaker_char] if sprite_path != "" else ""
		var speaker_changed: bool = speaker_key != "" and (speaker_key != _last_speaking_key or not speaking_sprite.visible)
		_last_speaking_key = speaker_key
		other_sprite.scale = Vector2.ONE
		other_sprite.modulate = Color(0.76, 0.74, 0.78)
		speaking_sprite.visible = sprite_path != ""
		if sprite_path != "":
			speaking_sprite.texture = load(sprite_path)
			if speaker_char == "huang_qiufeng" and resolved_emotion == "crystal_stasis":
				CombatVFX.play_loop(speaking_sprite, "crystal_shimmer", Rect2(60.0, 120.0, 600.0, 600.0), 0.72, 2)
			speaking_sprite.pivot_offset = Vector2(speaking_sprite.size.x * 0.5, speaking_sprite.size.y)
			var motion_dur: float = SaveManager.motion_duration(0.18)
			if speaker_changed and motion_dur > 0.0:
				speaking_sprite.scale = Vector2(0.985, 0.985)
				speaking_sprite.modulate = Color(1.0, 1.0, 1.0, 0.78)
				_char_motion_tween = create_tween()
				_char_motion_tween.set_parallel(true)
				_char_motion_tween.tween_property(speaking_sprite, "scale", Vector2.ONE, motion_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_char_motion_tween.tween_property(speaking_sprite, "modulate", Color.WHITE, motion_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			else:
				speaking_sprite.scale = Vector2.ONE
				speaking_sprite.modulate = Color.WHITE
	full_current_text = data.get("text", "")
	text_label.text = full_current_text
	text_label.visible_characters = 0
	is_typing = true
	if is_instance_valid(story_presentation):
		story_presentation.set_continue_cursor_visible(false)
	if tween_typing and tween_typing.is_valid():
		tween_typing.kill()
	tween_typing = create_tween()
	tween_typing.tween_property(text_label, "visible_characters", full_current_text.length(), full_current_text.length() * SaveManager.typing_interval())
	await tween_typing.finished
	if generation == _line_generation and not _dialogue_finishing:
		_reveal_current_line()

func _refresh_speaker_avatar(data: Dictionary) -> void:
	var portrait := nameplate.get_node_or_null("SpeakerPortrait") as TextureRect
	if not portrait:
		portrait = TextureRect.new()
		portrait.name = "SpeakerPortrait"
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		nameplate.add_child(portrait)
		portrait.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		portrait.position = Vector2.ZERO
		portrait.size = Vector2(88, 88)
	portrait.position = Vector2(-155, 68)
	portrait.size = Vector2(136, 170)
	nameplate.custom_minimum_size.y = 0
	var speaker_name := str(data.get("speaker", "旁白")).strip_edges()
	var raw_char := str(data.get("char", ""))
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi", "rebel_operative": "rebel_operative_masked", "alliance_operative": "rebel_operative_masked"}
	var character_id: String = str(aliases.get(raw_char, raw_char))
	var emotion := _speaker_emotion(data)
	if character_id == "rebel_operative_masked" and emotion == "unmasked":
		character_id = "rebel_operative_unmasked"
	var path := ""
	var crop_halfbody := false
	var v7_avatar := "res://assets/sprites/characters/phase_two/avatars/%s_%s.png" % [character_id, emotion]
	var v7_neutral := "res://assets/sprites/characters/phase_two/avatars/%s_neutral.png" % character_id
	var emo_halfbody := "res://assets/sprites/characters/phase_two/emotions/%s/%s.png" % [character_id, emotion]
	if character_id != "":
		if ResourceLoader.exists(v7_avatar):
			path = v7_avatar
		elif emotion != "neutral" and ResourceLoader.exists(emo_halfbody):
			path = emo_halfbody
			crop_halfbody = true
		elif ResourceLoader.exists(v7_neutral):
			path = v7_neutral
		else:
			var portrait_path := "res://assets/sprites/characters/phase_two/portraits/%s.png" % character_id
			if ResourceLoader.exists(portrait_path):
				path = portrait_path
	if path == "" and character_id != "":
		var fallback_path := PhaseTwoContent.dialogue_character_path(character_id, emotion)
		if fallback_path != "" and ResourceLoader.exists(fallback_path):
			path = fallback_path
			crop_halfbody = fallback_path.contains("/halfbody/") or fallback_path.contains("/emotions/") or fallback_path.contains("/combat/")
	if path == "" or not ResourceLoader.exists(path):
		portrait.visible = false
		portrait.texture = null
		nameplate.text = speaker_name
		return
	var tex := load(path) as Texture2D
	if crop_halfbody and tex != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var sz := tex.get_size()
		var crop_w := sz.x * 0.84
		var crop_y := sz.y * 0.01
		atlas.region = Rect2(sz.x * 0.08, crop_y, crop_w, minf(crop_w, sz.y - crop_y))
		atlas.filter_clip = true
		portrait.texture = atlas
	else:
		portrait.texture = tex
	portrait.visible = portrait.texture != null
	nameplate.text = speaker_name

func _speaker_emotion(data: Dictionary) -> String:
	var explicit_emotion := str(data.get("emotion", "")).strip_edges().to_lower()
	if explicit_emotion != "":
		if explicit_emotion == "concerned":
			explicit_emotion = "worried"
		return explicit_emotion if explicit_emotion in ["neutral", "happy", "shy", "surprised", "angry", "worried", "dazed", "rally", "crying", "moved", "damaged_fiber", "crystal_stasis", "unmasked"] else "neutral"
	var copy := str(data.get("text", "")).to_lower()
	for keyword in ["danger", "命令", "受伤", "危险", "异常", "停下", "权限"]:
		if copy.contains(keyword):
			return "worried"
	for keyword in ["笑", "早！", "谢谢", "面包", "借口", "汽水"]:
		if copy.contains(keyword):
			return "happy"
	return "neutral"

func _reveal_current_line() -> void:
	if _dialogue_finishing or line_index >= current_lines.size():
		return
	is_typing = false
	_remember_line(line_index)
	text_label.visible_characters = -1
	var data := current_lines[line_index]
	var has_choices: bool = data.has("choices") and not data["choices"].is_empty()
	if is_instance_valid(story_presentation):
		story_presentation.set_continue_cursor_visible(not has_choices)
	if has_choices:
		_show_choices(data["choices"])
	elif is_auto:
		var generation := _line_generation
		var auto_delay := clampf(0.9 + float(full_current_text.length()) * 0.045, 1.0, 3.2)
		await get_tree().create_timer(auto_delay).timeout
		if generation == _line_generation and is_auto and not is_typing and not choices_panel.visible and not _dialogue_finishing:
			line_index += 1
			_show_next_line()

func _show_choices(choices: Array) -> void:
	for c in choices_container.get_children():
		choices_container.remove_child(c)
		c.queue_free()
	
	choices_panel.visible = true
	var choice_tex_path := "res://assets/ui_core/theme/dialogue_choice_9slice.png"
	var choice_atlas: AtlasTexture = null
	if ResourceLoader.exists(choice_tex_path):
		choice_atlas = AtlasTexture.new()
		choice_atlas.atlas = load(choice_tex_path) as Texture2D
		choice_atlas.region = Rect2(12, 14, 742, 132)
		choice_atlas.filter_clip = true
	for item in choices:
		var btn = Button.new()
		btn.text = " ▶  " + item.get("text", "")
		btn.custom_minimum_size = Vector2(0, 78)
		btn.add_theme_font_size_override("font_size", 26)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if choice_atlas != null:
			for state in ["normal", "hover", "pressed", "hover_pressed"]:
				var style := StyleBoxTexture.new()
				style.texture = choice_atlas
				style.texture_margin_left = 54
				style.texture_margin_right = 26
				style.texture_margin_top = 22
				style.texture_margin_bottom = 22
				style.content_margin_left = 48
				style.content_margin_right = 28
				style.content_margin_top = 14
				style.content_margin_bottom = 14
				style.modulate_color = Color(1.04, 1.03, 0.99) if state == "hover" else (Color(0.91, 0.89, 0.85) if state in ["pressed", "hover_pressed"] else Color.WHITE)
				btn.add_theme_stylebox_override(state, style)
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				btn.add_theme_color_override(state, Color("#303B45"))
			SchoolObjectUI.borderless(btn)
		else:
			var color := Color("#D89A88") if choices_container.get_child_count() % 2 == 0 else Color("#A79AC2")
			for state in ["normal", "hover", "pressed", "focus"]:
				var style := StyleBoxFlat.new()
				style.bg_color = color.lightened(0.12) if state in ["hover", "focus"] else color
				style.border_color = Color("#FFF2DF")
				style.set_border_width_all(1)
				style.set_content_margin_all(15)
				btn.add_theme_stylebox_override(state, style)
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: btn.add_theme_color_override(state, Color("#FFF8ED"))
		btn.pressed.connect(func(): _on_choice_selected(item))
		DaylightUI.bind_button_audio(btn)
		choices_container.add_child(btn)
	if choices_container.get_child_count() > 0: choices_container.get_child(0).grab_focus.call_deferred()

func _on_choice_selected(item: Dictionary) -> void:
	if not choices_panel.visible or _dialogue_finishing:
		return
	choices_panel.visible = false
	history.append({"speaker": "选择", "text": str(item.get("text", ""))})
	if not _archive_mode and not _exploration_mode and item.has("favor_char") and item.has("favor_add"):
		GameState.add_companion_favor(item["favor_char"], item["favor_add"])
	
	line_index += 1
	_show_next_line()

func _finish_dialogue() -> void:
	if _dialogue_finishing or SceneManager.is_transitioning:
		return
	_dialogue_finishing = true
	_line_generation += 1
	if tween_typing and tween_typing.is_valid():
		tween_typing.kill()
	if _archive_mode:
		_return_from_memory()
		return
	if _calendar_mode:
		DayCycle.complete_event()
		return
	if _exploration_mode:
		SchoolExplorationFlow.checkpoint_dialogue(current_lines.size())
		if GameState.complete_exploration_node(str(GameState.exploration_state.get("current_node_id", ""))):
			dialogue_completed.emit(current_dialogue_id)
			SceneManager.change_scene(SceneManager.TargetScene.EXPLORATION)
		else:
			_dialogue_finishing = false
		return
	GameState.pending_dialogue_id = ""
	dialogue_completed.emit(current_dialogue_id)
	match current_dialogue_id:
		"school_gate":
			GameState.set_story_flag("school_gate_duel_briefed", true)
			if GameState.game_day < 2:
				GameState.set_game_time(2, 9, 20, DayCycleService.weekday_for_day(2))
			else:
				GameState.advance_story_time(9, 20)
		"school_gate_after":
			GameState.set_story_flag("school_gate_done", true)
			var club_day: int = maxi(3, GameState.game_day + 1)
			GameState.set_game_time(club_day, 8, 30, DayCycleService.weekday_for_day(club_day))
		"club_welcome":
			GameState.companions["jiang_zi"]["unlocked"] = true
			GameState.set_story_flag("prologue_completed", true)
		"school_affairs":
			GameState.companions["jiang_zi"]["unlocked"] = true
			GameState.set_story_flag("school_affairs_done", true)
			GameState.advance_story_time(16, 20)
		"after_school":
			GameState.advance_story_time(17, 25)
		"yang_rescue":
			GameState.set_story_flag("yang_rescued_player", true)
			GameState.advance_story_time(17, 40)
		"principal_confrontation", "chapter_1_pre_boss":
			GameState.companions["liu_yu_long"]["unlocked"] = true
		"campus_morning", "chapter_1_intro", "prologue_intro":
			GameState.advance_story_time(8, 0)
	if current_dialogue_id.begins_with("chat_"):
		SceneManager.change_scene(SceneManager.TargetScene.HOME)
	elif current_dialogue_id == "school_gate":
		GameState.set_story_flag("school_gate_duel_briefed", true)
		GameState.phase_two_checkpoint = {"node_id":"n_gate","stage":"combat"}
		GameState._open_phase_two_node("n_gate")
	elif current_dialogue_id in ["principal_confrontation", "chapter_1_pre_boss"]:
		GameState.set_story_flag("principal_briefing_done",true)
		GameState.phase_two_checkpoint = {"node_id":"n5_boss","stage":"combat"}
		GameState.advance_story_time(17,55)
		GameState._open_phase_two_node("n5_boss")
	else:
		var node_id: String = PhaseTwoContent.node_for_dialogue(current_dialogue_id)
		if not GameState.complete_phase_two_step(node_id):
			SceneManager.change_scene(SceneManager.TargetScene.HOME)

func _on_pause_pressed() -> void:
	if _dialogue_finishing or SceneManager.is_transitioning:
		return
	if _archive_mode:
		_dialogue_finishing = true
		_line_generation += 1
		if tween_typing and tween_typing.is_valid(): tween_typing.kill()
		_return_from_memory()
		return
	_checkpoint_line()
	if _calendar_mode:
		SaveManager.save_game()
		SceneManager.change_scene(SceneManager.TargetScene.TITLE)
		return
	_dialogue_finishing = true
	_line_generation += 1
	if tween_typing and tween_typing.is_valid(): tween_typing.kill()
	if _exploration_mode: GameState.pause_exploration()
	else: GameState.pause_phase_two_chapter()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(history_panel) and history_panel.visible: history_panel.hide()
		else: _on_pause_pressed()
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not choices_panel.visible:
		_advance()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	if _dialogue_finishing or SceneManager.is_transitioning or choices_panel.visible or (is_instance_valid(history_panel) and history_panel.visible): return
	AudioManager.play_sfx_click()
	if is_typing:
		if tween_typing and tween_typing.is_valid(): tween_typing.kill()
		_reveal_current_line()
	else:
		line_index += 1
		_show_next_line()

func _on_auto_toggled(toggled_on: bool) -> void:
	SchoolObjectUI.set_selected(auto_button,toggled_on)
	if _dialogue_finishing or SceneManager.is_transitioning:
		return
	is_auto = toggled_on
	if is_auto and not is_typing and not choices_panel.visible:
		line_index += 1
		_show_next_line()

func _on_skip_pressed() -> void:
	if _dialogue_finishing or SceneManager.is_transitioning or (is_instance_valid(history_panel) and history_panel.visible): return
	if choices_panel.visible: return
	if tween_typing and tween_typing.is_valid(): tween_typing.kill()
	_line_generation += 1
	while line_index < current_lines.size():
		_remember_line(line_index)
		if not current_lines[line_index].get("choices", []).is_empty():
			_show_next_line()
			if tween_typing and tween_typing.is_valid(): tween_typing.kill()
			_reveal_current_line()
			return
		line_index += 1
	_finish_dialogue()

func _return_from_memory() -> void:
	GameState.archive_dialogue_id = ""
	GameState.archive_return_tab = "journey"
	CampusLife.restore_saved_location()

func _checkpoint_line() -> void:
	if _archive_mode: return
	if _calendar_mode: DayCycle.checkpoint_event(line_index)
	elif _exploration_mode: SchoolExplorationFlow.checkpoint_dialogue(line_index)
	else: GameState.checkpoint_phase_two_dialogue(current_dialogue_id, line_index)

func _remember_line(index: int) -> void:
	if index < 0 or index >= current_lines.size(): return
	var key := current_dialogue_id + ":" + str(index)
	if _history_keys.has(key): return
	_history_keys[key] = true
	history.append({"speaker": str(current_lines[index].get("speaker", "旁白")), "text": str(current_lines[index].get("text", ""))})

func _build_history() -> void:
	record_button = Button.new()
	record_button.name = "RecordButton"
	record_button.text = "记录"
	$ControlBar.add_child(record_button)
	record_button.pressed.connect(_open_history)
	history_panel = Control.new()
	history_panel.name = "HistoryPanel"
	history_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	history_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(history_panel)
	var history_backing := Panel.new()
	history_backing.name = "HistoryBacking"
	history_backing.mouse_filter = Control.MOUSE_FILTER_STOP
	history_backing.add_theme_stylebox_override("panel", CombatSkin.paper(Vector4(24, 24, 24, 24)))
	history_panel.add_child(history_backing)
	DaylightUI.place(history_backing, 230, 145, 1460, 790)
	var history_title := SchoolObjectUI.text(history_panel, "Title", "对话记录", Rect2(295, 177, 800, 70), 44)
	var serif_path := "res://assets/fonts/NotoSerifSC-SemiBold.ttf"
	if ResourceLoader.exists(serif_path):
		history_title.add_theme_font_override("font", load(serif_path))
	history_title.add_theme_color_override("font_color", Color("#303B45"))
	history_text = RichTextLabel.new()
	history_text.name = "HistoryText"
	history_text.bbcode_enabled = false
	history_text.add_theme_color_override("default_color", SchoolObjectUI.INK)
	history_text.add_theme_font_size_override("normal_font_size", 30)
	history_text.add_theme_constant_override("line_separation", 14)
	history_panel.add_child(history_text)
	DaylightUI.place(history_text, 295, 280, 1310, 560)
	var close := SchoolObjectUI.hit(history_panel, "CloseHistory", Rect2(1540, 177, 70, 65), "×", 38)
	SchoolObjectUI.style_close_button(close)
	close.pressed.connect(func(): history_panel.hide(); record_button.grab_focus())
	history_panel.hide()

func _open_history() -> void:
	if _dialogue_finishing or SceneManager.is_transitioning: return
	is_auto = false
	auto_button.set_pressed_no_signal(false)
	SchoolObjectUI.set_selected(auto_button,false)
	var rows: PackedStringArray = []
	for entry in history: rows.append(str(entry["speaker"]) + "\n" + str(entry["text"]))
	history_text.text = "\n\n".join(rows) if not rows.is_empty() else "继续阅读后，这里会留下对话。"
	history_panel.show()
	history_panel.move_to_front()
	history_panel.get_node("CloseHistory").grab_focus()
