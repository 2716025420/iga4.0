class_name EnemyUnitUI
extends Control

signal unit_clicked(unit: EnemyUnitUI)
signal unit_died(unit: EnemyUnitUI)

var enemy_data: EnemyData
var current_hp: int = 50
var max_hp: int = 50
var shield: int = 0
var burn_damage_per_turn: int = 0
var burn_turns_remaining: int = 0
var atk_down_percent: float = 0.0
var atk_down_turns: int = 0
var is_dead: bool = false
var is_selected: bool = false
var is_phase_two: bool = false

# 下一回合将要执行的技能
var next_intent: Dictionary = {}
var intent_queue: Array[Dictionary] = []

@onready var sprite: TextureRect = $VBox/SpriteContainer/EnemySprite
@onready var name_label: Label = $VBox/NameLabel
@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var hp_label: Label = $VBox/HPBar/HPLabel
@onready var intent_badge: PanelContainer = $VBox/IntentBadge
@onready var intent_label: Label = $VBox/IntentBadge/IntentLabel
@onready var status_label: Label = $VBox/StatusLabel
@onready var select_indicator: Panel = $SelectIndicator

func setup_enemy(data: EnemyData) -> void:
	enemy_data = data
	max_hp = data.max_hp
	current_hp = max_hp
	
	name_label.text = data.name
	if data.rank == EnemyData.EnemyRank.BOSS:
		name_label.text = data.name + " · 首领"
		name_label.add_theme_color_override("font_color", Color("#ff4757"))
	elif data.rank == EnemyData.EnemyRank.ELITE:
		name_label.text = data.name + " · 强敌"
		name_label.add_theme_color_override("font_color", Color("#ffa502"))
	
	# Mirror only this combat TextureRect; shared PNGs and dialogue portraits stay unchanged.
	sprite.flip_h = true
	if data.sprite_texture:
		sprite.texture = CombatSkin.actor_texture(data.sprite_texture.resource_path)
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	_update_hp_display()
	decide_next_intent()
	custom_minimum_size = Vector2(520, 530)
	sprite.custom_minimum_size = Vector2(250, 424)
	var selection_style := StyleBoxFlat.new()
	selection_style.draw_center = false
	selection_style.border_color = SceneSkin.ACCENT
	selection_style.border_width_bottom = 0
	select_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	select_indicator.offset_top = -48
	select_indicator.add_theme_stylebox_override("panel", selection_style)
	DaylightUI.polish(self)
	intent_badge.visible = true
	select_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_badge.add_theme_stylebox_override("panel", CombatSkin.flat(Color("#FFF9F0"), Vector4(12, 4, 12, 4)))
	intent_badge.modulate = Color.WHITE
	intent_label.add_theme_color_override("font_color", DaylightUI.INK)
	intent_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hp_bar.custom_minimum_size.y = 26
	hp_bar.add_theme_stylebox_override("background", CombatSkin.flat(Color("#ECEAE2"), Vector4.ZERO))
	hp_bar.add_theme_stylebox_override("fill", CombatSkin.flat(Color("#99B3A0"), Vector4.ZERO))
	hp_label.add_theme_color_override("font_color", Color("#303A59"))
	status_label.add_theme_color_override("font_color", DaylightUI.MUTED)
	layout_stage(Vector2(520, 530))

func layout_stage(frame: Vector2) -> void:
	# Keep every existing child path; only remove the container's forced vertical stacking.
	var stage := get_node("VBox") as Control
	if stage is VBoxContainer:
		var old_box := stage
		var index := old_box.get_index()
		old_box.name = "LegacyVBox"
		stage = Control.new()
		stage.name = "VBox"
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stage)
		move_child(stage, index)
		for child in old_box.get_children():
			child.reparent(stage, false)
		remove_child(old_box)
		old_box.queue_free()
	custom_minimum_size = frame
	DaylightUI.place(stage, 0, 0, frame.x, frame.y + 26)
	intent_badge.visible = not is_dead
	intent_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_font_size_override("font_size", 27)
	hp_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_font_size_override("font_size", 20)
	var wide := frame.x > 550
	var badge_width := minf(278, frame.x - 16)
	var badge_x := frame.x - badge_width - 20 if wide else (frame.x - badge_width) / 2.0
	var badge := stage.get_node_or_null("IdentityPaper") as TextureRect
	if not badge:
		badge = TextureRect.new()
		badge.name = "IdentityPaper"
		badge.texture = CombatSkin.actor_texture("res://assets/ui/combat_notebook/status_note.png")
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(badge)
		stage.move_child(badge, 0)
	DaylightUI.place(badge, badge_x - 10, 18, badge_width + 30, 142)
	DaylightUI.place(name_label, badge_x + 48, 45, badge_width - 54, 40)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var portrait_frame := stage.get_node("SpriteContainer") as CenterContainer
	var portrait_height := frame.y - 14 if wide else frame.y - 250
	DaylightUI.place(portrait_frame, frame.x * 0.42 - 170 if wide else 0.0, 0 if wide else 250, 340 if wide else frame.x, portrait_height)
	sprite.custom_minimum_size = Vector2(310 if wide else frame.x - 16, portrait_height)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.flip_h = true
	DaylightUI.place(hp_bar, badge_x + 54, 94, badge_width - 72, 18)
	DaylightUI.place(hp_label, 0, 21, badge_width - 72, 30)
	DaylightUI.place(intent_badge, badge_x - 10, 165 if wide else 142, badge_width + 30, 48)
	DaylightUI.place(status_label, badge_x + 2, 220 if wide else 194, badge_width + 10, 58)
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	select_indicator.visible = false
	set_selected(is_selected)

func _update_hp_display() -> void:
	hp_bar.value = current_hp
	if shield > 0:
		hp_label.text = "%d / %d (护盾: %d)" % [current_hp, max_hp, shield]
	else:
		hp_label.text = "%d / %d" % [current_hp, max_hp]
	
	var status_text = ""
	if burn_turns_remaining > 0:
		status_text += "压制(%d) " % burn_turns_remaining
	if atk_down_turns > 0:
		status_text += "虚弱(-%d%%) " % roundi(atk_down_percent * 100)
	status_label.text = status_text

func decide_next_intent() -> void:
	# Only called once while preparing the next complete enemy phase.
	intent_queue.clear()
	if is_dead:
		intent_badge.hide()
		return
	var phase_change := enemy_data.has_phase_two and not is_phase_two and float(current_hp) / float(max_hp) <= enemy_data.phase_two_hp_threshold
	for index in maxi(1, enemy_data.actions_per_turn):
		var action: Dictionary
		if phase_change and index == 0:
			is_phase_two = true
			action = enemy_data.phase_two_skill.duplicate(true)
		elif not enemy_data.skills.is_empty():
			action = enemy_data.skills.pick_random().duplicate(true)
		else:
			action = {"type":"attack", "damage":enemy_data.base_atk, "name":"普通攻击"}
		intent_queue.append(action)
	_sync_intent()

func _sync_intent() -> void:
	next_intent = intent_queue[0].duplicate(true) if not intent_queue.is_empty() else {}
	refresh_intent_display()

func refresh_intent_display() -> void:
	var parts: Array[String] = []
	for action in intent_queue:
		if action.get("type", "attack") == "defend": parts.append("防御%d" % int(action.get("shield", 0)))
		else: parts.append("攻击%d" % int(int(action.get("damage", enemy_data.base_atk)) * (1.0 - atk_down_percent)))
	intent_label.text = " → ".join(parts)
	intent_badge.visible = not is_dead and not parts.is_empty()

func predicted_damage() -> int:
	var total := 0
	for action in intent_queue:
		if action.get("type", "attack") in ["attack", "aoe"]:
			total += int(int(action.get("damage", enemy_data.base_atk)) * (1.0 - atk_down_percent))
	return total

func restore_intents(saved: Array, legacy: Dictionary = {}) -> void:
	intent_queue.clear()
	for action in saved:
		if action is Dictionary: intent_queue.append(action.duplicate(true))
	if intent_queue.is_empty() and not legacy.is_empty():
		# Older checkpoints stored only one preview: retain it for the whole phase.
		for index in maxi(1, enemy_data.actions_per_turn): intent_queue.append(legacy.duplicate(true))
	if intent_queue.is_empty() and not is_dead: decide_next_intent()
	else: _sync_intent()

func begin_enemy_phase() -> bool:
	if is_dead: return false
	# Enemy guard lasts through the preceding player phase only.
	shield = 0
	if burn_turns_remaining > 0:
		burn_turns_remaining -= 1
		take_damage(burn_damage_per_turn, false)
	_update_hp_display()
	return not is_dead

func finish_enemy_phase() -> void:
	if atk_down_turns > 0:
		atk_down_turns -= 1
		if atk_down_turns == 0: atk_down_percent = 0.0
	_update_hp_display()
	decide_next_intent()

func execute_turn_intent(_player_ref: Node = null) -> Dictionary:
	if is_dead or intent_queue.is_empty(): return {"type":"skip"}
	var result: Dictionary = intent_queue.pop_front()
	_sync_intent()
	if not bool(SaveManager.settings["reduced_motion"]):
		var base_x := position.x
		var tween := create_tween()
		tween.tween_property(self, "position:x", base_x - 24.0, 0.10)
		tween.tween_property(self, "position:x", base_x, 0.12)
	return result

func take_damage(amount: int, trigger_anim: bool = true) -> int:
	if is_dead:
		return 0
	
	var actual_dmg = amount
	if shield > 0:
		if shield >= actual_dmg:
			shield -= actual_dmg
			actual_dmg = 0
		else:
			actual_dmg -= shield
			shield = 0
	
	current_hp = max(0, current_hp - actual_dmg)
	_update_hp_display()
	
	if trigger_anim and not bool(SaveManager.settings["reduced_motion"]):
		# 受击闪白 + 剧烈晃动
		var orig_pos = position
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		for i in range(3):
			tween.tween_property(self, "position", orig_pos + Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.03)
		tween.tween_property(self, "position", orig_pos, 0.03)
	
	if current_hp <= 0:
		die()
	
	return actual_dmg

func apply_burn(dmg: int, duration: int) -> void:
	burn_damage_per_turn = dmg
	burn_turns_remaining = duration
	_update_hp_display()

func apply_debuff(down_pct: float, duration: int) -> void:
	atk_down_percent = down_pct
	atk_down_turns = duration
	_update_hp_display()
	refresh_intent_display()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	intent_badge.visible = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, SaveManager.motion_duration(0.4))
	if not bool(SaveManager.settings["reduced_motion"]): tween.tween_property(self, "position:y", position.y + 30.0, 0.4)
	await tween.finished
	unit_died.emit(self)
	visible = false

func set_selected(val: bool) -> void:
	is_selected = val
	select_indicator.visible = false
	name_label.text = ("◇ " if val else "") + enemy_data.name + (" · 首领" if enemy_data.rank == EnemyData.EnemyRank.BOSS else "")
	name_label.add_theme_color_override("font_color", NotebookUI.PLUM if val else NotebookUI.INK)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_dead:
			unit_clicked.emit(self)
