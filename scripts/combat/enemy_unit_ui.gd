class_name EnemyUnitUI
extends Control

signal unit_clicked(unit: EnemyUnitUI)
signal unit_died(unit: EnemyUnitUI)

const PLAQUE_PATH := "res://assets/combat/status_plaque.png"
const FALLBACK_PLAQUE_PATH := "res://assets/ui/combat_notebook/status_note.png"
const ICON_ATK_SINGLE := "res://assets/ui_core/icons/combat/atk_single.svg"
const ICON_ATK_AOE := "res://assets/ui_core/icons/combat/atk_aoe.svg"
const ICON_SHIELD := "res://assets/ui_core/icons/combat/shield.svg"
const ICON_TARGET_CLIP := "res://assets/ui_core/icons/combat/target_clip.svg"

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
var _intent_icon: TextureRect
var _target_clip: TextureRect
var _status_pill: Panel
var _phase_tick: ColorRect

func setup_enemy(data: EnemyData) -> void:
	enemy_data = data
	max_hp = data.max_hp
	current_hp = max_hp
	
	_apply_rank_title()
	
	# Mirror only this combat TextureRect; shared PNGs and dialogue portraits stay unchanged.
	sprite.flip_h = true
	if data.sprite_texture:
		sprite.texture = CombatSkin.actor_texture(data.sprite_texture.resource_path)
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	custom_minimum_size = Vector2(520, 530)
	sprite.custom_minimum_size = Vector2(250, 424)
	select_indicator.visible = false
	select_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DaylightUI.polish(self)
	intent_badge.visible = true
	var badge_box := CombatSkin.flat(Color("#FFF8EC"), Vector4(12, 4, 12, 4))
	badge_box.border_color = Color("#C8BCA9")
	badge_box.set_corner_radius_all(10)
	intent_badge.add_theme_stylebox_override("panel", badge_box)
	intent_badge.modulate = Color.WHITE
	intent_label.add_theme_color_override("font_color", NotebookUI.INK)
	intent_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	intent_label.clip_text = false
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	hp_bar.custom_minimum_size.y = 18
	hp_bar.add_theme_stylebox_override("background", CombatSkin.flat(Color("#E2DACB"), Vector4.ZERO))
	hp_bar.add_theme_stylebox_override("fill", CombatSkin.flat(Color("#B86A5B"), Vector4.ZERO))
	hp_label.add_theme_color_override("font_color", NotebookUI.INK)
	status_label.add_theme_color_override("font_color", Color("#5B3E5E"))
	layout_stage(Vector2(520, 530))
	decide_next_intent()
	_update_hp_display()

func _apply_rank_title() -> void:
	if enemy_data == null:
		return
	if enemy_data.rank == EnemyData.EnemyRank.BOSS:
		name_label.text = enemy_data.name + " · 首领"
		name_label.add_theme_color_override("font_color", Color("#A83B40"))
	elif enemy_data.rank == EnemyData.EnemyRank.ELITE:
		name_label.text = enemy_data.name + " · 强敌"
		name_label.add_theme_color_override("font_color", Color("#A66320"))
	else:
		name_label.text = enemy_data.name
		name_label.add_theme_color_override("font_color", NotebookUI.INK)

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
	if intent_badge.get_node_or_null("IntentRow") == null:
		var row := HBoxContainer.new()
		row.name = "IntentRow"
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		intent_badge.add_child(row)
		_intent_icon = TextureRect.new()
		_intent_icon.name = "IntentIcon"
		_intent_icon.custom_minimum_size = Vector2(22, 22)
		_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(_intent_icon)
		intent_label.reparent(row, false)
		intent_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		intent_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		intent_label.clip_text = false

	custom_minimum_size = frame
	DaylightUI.place(stage, 0, 0, frame.x, frame.y)
	intent_badge.visible = not is_dead and not intent_queue.is_empty()
	var wide := frame.x > 520.0
	intent_label.add_theme_font_size_override("font_size", 22 if wide else 20)
	name_label.add_theme_font_size_override("font_size", 25 if wide else 22)
	hp_label.add_theme_font_size_override("font_size", 22 if wide else 20)
	status_label.add_theme_font_size_override("font_size", 20)

	var badge_w := 352.0 if wide else clampf(frame.x - 8.0, 252.0, 336.0)
	var badge_h := roundf(badge_w / 2.60)
	var badge_x := frame.x - badge_w - 16.0 if wide else (frame.x - badge_w) * 0.5
	var badge_y := 22.0 if wide else 18.0
	var badge := stage.get_node_or_null("IdentityPaper") as TextureRect
	if not badge:
		badge = TextureRect.new()
		badge.name = "IdentityPaper"
		var p_path := PLAQUE_PATH if ResourceLoader.exists(PLAQUE_PATH) else FALLBACK_PLAQUE_PATH
		badge.texture = load(p_path) as Texture2D
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_SCALE
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(badge)
		stage.move_child(badge, 0)
	DaylightUI.place(badge, badge_x, badge_y, badge_w, badge_h)

	if not is_instance_valid(_target_clip) and ResourceLoader.exists(ICON_TARGET_CLIP):
		_target_clip = TextureRect.new()
		_target_clip.name = "TargetClipIcon"
		_target_clip.texture = load(ICON_TARGET_CLIP) as Texture2D
		_target_clip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_target_clip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_target_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(_target_clip)
	if is_instance_valid(_target_clip):
		DaylightUI.place(_target_clip, badge_x + badge_w * 0.5 - 16.0, badge_y - 24.0, 32.0, 36.0)

	var inner_x := badge_x + badge_w * 0.17
	var inner_w := badge_w * 0.76
	DaylightUI.place(name_label, inner_x, badge_y + badge_h * 0.13, inner_w, 34)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DaylightUI.place(hp_bar, inner_x, badge_y + badge_h * 0.44, inner_w, 16)
	DaylightUI.place(hp_label, 0, 19, inner_w, 26)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	if enemy_data != null and enemy_data.has_phase_two:
		if not is_instance_valid(_phase_tick):
			_phase_tick = ColorRect.new()
			_phase_tick.name = "PhaseThresholdTick"
			_phase_tick.color = Color("#D6A048")
			_phase_tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hp_bar.add_child(_phase_tick)
		DaylightUI.place(_phase_tick, inner_w * enemy_data.phase_two_hp_threshold - 1.0, -2.0, 3.0, 20.0)
		_phase_tick.visible = true
	elif is_instance_valid(_phase_tick):
		_phase_tick.visible = false

	var pill_x := badge_x + badge_w * 0.06
	var pill_w := badge_w * 0.88
	DaylightUI.place(intent_badge, pill_x, badge_y + badge_h + 4.0, pill_w, 42)

	if not is_instance_valid(_status_pill):
		_status_pill = Panel.new()
		_status_pill.name = "StatusPill"
		_status_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var status_box := CombatSkin.flat(Color(0.99, 0.96, 0.91, 0.93), Vector4.ZERO)
		status_box.border_color = Color("#C8BCA9")
		status_box.set_corner_radius_all(8)
		_status_pill.add_theme_stylebox_override("panel", status_box)
		stage.add_child(_status_pill)
		stage.move_child(_status_pill, status_label.get_index())
	DaylightUI.place(_status_pill, pill_x, badge_y + badge_h + 50.0, pill_w, 42)
	DaylightUI.place(status_label, pill_x + 8.0, badge_y + badge_h + 50.0, pill_w - 16.0, 42)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_pill.visible = not is_dead and status_label.text != ""

	var portrait_frame := stage.get_node("SpriteContainer") as CenterContainer
	var top_reserved := badge_y + badge_h + 98.0
	var portrait_height := frame.y - 16.0 if wide else maxf(160.0, frame.y - top_reserved - 8.0)
	DaylightUI.place(portrait_frame, frame.x * 0.36 - 170.0 if wide else 0.0, 8.0 if wide else top_reserved, 340.0 if wide else frame.x, portrait_height)
	sprite.custom_minimum_size = Vector2(310.0 if wide else minf(frame.x - 16.0, 310.0), portrait_height)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.flip_h = true
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
	status_label.text = status_text.strip_edges()
	if is_instance_valid(_status_pill):
		_status_pill.visible = not is_dead and status_label.text != ""

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
	var has_aoe := false
	var has_attack := false
	for action in intent_queue:
		var t: String = str(action.get("type", "attack"))
		if t == "defend": parts.append("防御%d" % int(action.get("shield", 0)))
		else:
			if t == "aoe": has_aoe = true
			has_attack = true
			parts.append("攻击%d" % int(int(action.get("damage", enemy_data.base_atk)) * (1.0 - atk_down_percent)))
	intent_label.text = " → ".join(parts)
	if is_instance_valid(_intent_icon):
		var icon_path := ICON_ATK_AOE if has_aoe else (ICON_ATK_SINGLE if has_attack else ICON_SHIELD)
		if ResourceLoader.exists(icon_path):
			_intent_icon.texture = load(icon_path) as Texture2D
			_intent_icon.visible = not parts.is_empty()
		else:
			_intent_icon.visible = false
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
	if is_instance_valid(_target_clip): _target_clip.visible = false
	if is_instance_valid(_status_pill): _status_pill.visible = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, SaveManager.motion_duration(0.4))
	if not bool(SaveManager.settings["reduced_motion"]): tween.tween_property(self, "position:y", position.y + 30.0, 0.4)
	await tween.finished
	unit_died.emit(self)
	visible = false

func set_selected(val: bool) -> void:
	is_selected = val
	select_indicator.visible = false
	_apply_rank_title()
	if is_instance_valid(_target_clip):
		_target_clip.visible = val and not is_dead
	var badge := get_node_or_null("VBox/IdentityPaper") as CanvasItem
	if is_instance_valid(badge):
		badge.modulate = Color(1.04, 1.02, 0.96) if val else Color(0.95, 0.94, 0.92)

func _gui_input(event: InputEvent) -> void:
	if is_dead:
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		unit_clicked.emit(self)
