class_name EnemyUnitUI
extends Control

signal unit_clicked(unit: EnemyUnitUI)
signal unit_died(unit: EnemyUnitUI)

const PLAQUE_PATH := "res://assets/combat/status_plaque.png"
const FALLBACK_PLAQUE_PATH := "res://assets/ui/combat_notebook/status_note.png"
const ICON_ATK_SINGLE := "res://assets/ui_core/icons/combat/atk_single.svg"
const ICON_ATK_AOE := "res://assets/ui_core/icons/combat/atk_aoe.svg"
const ICON_SHIELD := "res://assets/ui_core/icons/combat/shield.svg"
const ICON_DEBUFF := "res://assets/ui_core/icons/combat/debuff.svg"
const ICON_BURN := "res://assets/ui_core/icons/combat/burn_suppress.svg"
const ICON_HEAL := "res://assets/ui_core/icons/combat/heal.svg"
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
var _status_icon: TextureRect
var _status_row: HBoxContainer
var _phase_tick: ColorRect
var _target_reticle: TextureRect
var _ground_shadow: TextureRect
var _intent_summary: String = ""

func setup_enemy(data: EnemyData) -> void:
	enemy_data = data
	max_hp = data.max_hp
	current_hp = max_hp
	
	_apply_rank_title()
	
	# Mirror only right-facing enemy sprites; left-facing art stays unflipped.
	sprite.flip_h = CombatSkin.enemy_needs_flip_h(data.id)
	if data.sprite_texture:
		sprite.texture = CombatSkin.actor_texture(data.sprite_texture.resource_path)
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	custom_minimum_size = CombatPresentation.ENEMY_SLOT_SIZE
	sprite.custom_minimum_size = Vector2(290, 400)
	select_indicator.visible = false
	select_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DaylightUI.polish(self)
	intent_badge.visible = true
	intent_badge.add_theme_stylebox_override("panel", CombatPresentation.status_chip_style("intent_atk"))
	intent_badge.modulate = Color.WHITE
	intent_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	intent_label.add_theme_color_override("font_color", NotebookUI.INK)
	intent_label.add_theme_constant_override("outline_size", 0)
	intent_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	intent_label.clip_text = false
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	name_label.add_theme_constant_override("outline_size", 0)
	hp_bar.clip_contents = false
	hp_bar.custom_minimum_size.y = 13
	hp_bar.add_theme_stylebox_override("background", CombatSkin.flat(Color("#E2DACB"), Vector4.ZERO))
	hp_bar.add_theme_stylebox_override("fill", CombatSkin.flat(Color("#B86A5B"), Vector4.ZERO))
	hp_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	hp_label.add_theme_color_override("font_color", Color("#232C36"))
	hp_label.add_theme_constant_override("outline_size", 0)
	status_label.visible = false
	layout_stage(CombatPresentation.ENEMY_SLOT_SIZE)
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
		row.add_theme_constant_override("separation", 4)
		intent_badge.add_child(row)
		_intent_icon = TextureRect.new()
		_intent_icon.name = "IntentIcon"
		_intent_icon.custom_minimum_size = Vector2(18, 18)
		_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_intent_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(_intent_icon)
		intent_label.reparent(row, false)
		intent_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		intent_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		intent_label.clip_text = false

	_status_row = stage.get_node_or_null("EnemyStatusIcons") as HBoxContainer
	if _status_row == null:
		_status_row = HBoxContainer.new()
		_status_row.name = "EnemyStatusIcons"
		_status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_status_row.add_theme_constant_override("separation", 6)
		stage.add_child(_status_row)
	if intent_badge.get_parent() != _status_row:
		intent_badge.reparent(_status_row, false)
	_status_row.move_child(intent_badge, 0)
	intent_badge.custom_minimum_size = Vector2(0, 28)

	custom_minimum_size = frame
	DaylightUI.place(stage, 0, 0, frame.x, frame.y)
	intent_badge.visible = not is_dead and not intent_queue.is_empty()
	intent_label.add_theme_font_size_override("font_size", 17)
	var name_len := name_label.text.length()
	var name_size := 21 if name_len <= 8 else (18 if name_len <= 12 else 16)
	name_label.add_theme_font_size_override("font_size", name_size)
	hp_label.add_theme_font_size_override("font_size", 18)
	status_label.visible = false

	var badge_w := clampf(frame.x - 16.0, 280.0, 312.0)
	var badge_h := 84.0
	var badge_x := (frame.x - badge_w) * 0.5
	var badge_y := 2.0
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
		DaylightUI.place(_target_clip, badge_x + badge_w * 0.5 - 14.0, badge_y - 10.0, 28.0, 30.0)

	var inner_x := badge_x + badge_w * 0.178
	var inner_w := badge_w * 0.72
	DaylightUI.place(name_label, inner_x, badge_y + 9.0, inner_w, 27.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DaylightUI.place(hp_bar, inner_x, badge_y + 39.0, inner_w, 13.0)
	DaylightUI.place(hp_label, 0, 14, inner_w, 22)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if enemy_data != null and enemy_data.has_phase_two:
		if not is_instance_valid(_phase_tick):
			_phase_tick = ColorRect.new()
			_phase_tick.name = "PhaseThresholdTick"
			_phase_tick.color = Color("#D6A048")
			_phase_tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hp_bar.add_child(_phase_tick)
		DaylightUI.place(_phase_tick, inner_w * enemy_data.phase_two_hp_threshold - 1.0, -2.0, 3.0, 17.0)
		_phase_tick.visible = true
	elif is_instance_valid(_phase_tick):
		_phase_tick.visible = false

	# Dedicated status strip directly beneath IdentityPaper and clear above enemy head.
	DaylightUI.place(_status_row, 2.0, 90.0, frame.x - 4.0, 32.0)
	if is_instance_valid(_status_pill):
		_status_pill.visible = false

	# Unified battle platform baseline (local y = 554 -> screen y = 634), fixed sprite box across 1..3 enemies.
	var foot_y := 554.0
	var max_w := minf(frame.x - 24.0, 290.0)
	var max_h := 400.0
	var draw_size := Vector2(max_w, max_h)
	if sprite.texture != null:
		var tsize := sprite.texture.get_size()
		if tsize.x > 0.0 and tsize.y > 0.0:
			var sc := minf(max_w / tsize.x, max_h / tsize.y)
			draw_size = tsize * sc
	var center_x := frame.x * 0.5
	var portrait_frame := stage.get_node("SpriteContainer") as CenterContainer
	DaylightUI.place(portrait_frame, center_x - draw_size.x * 0.5, foot_y - draw_size.y, draw_size.x, draw_size.y)
	sprite.custom_minimum_size = draw_size
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if enemy_data != null:
		sprite.flip_h = CombatSkin.enemy_needs_flip_h(enemy_data.id)
	if not is_instance_valid(_ground_shadow):
		_ground_shadow = DaylightUI.soft_ground_shadow(stage, "GroundShadow", Vector2.ZERO, Vector2(220, 34))
		stage.move_child(_ground_shadow, portrait_frame.get_index())
	var shadow_w := clampf(draw_size.x * 0.78, 168.0, 260.0)
	DaylightUI.place(_ground_shadow, center_x - shadow_w * 0.5, foot_y - 16.0, shadow_w, 30.0)
	var reticle_size := Vector2(clampf(draw_size.x * 0.92, 220.0, 280.0), 190.0)
	var reticle_rect := Rect2(center_x - reticle_size.x * 0.5, foot_y - reticle_size.y * 0.56, reticle_size.x, reticle_size.y)
	if not is_instance_valid(_target_reticle):
		_target_reticle = CombatVFX.play_loop(stage, "target_reticle", reticle_rect, 0.92, 0)
		if is_instance_valid(_target_reticle):
			stage.move_child(_target_reticle, portrait_frame.get_index())
	else:
		DaylightUI.place(_target_reticle, reticle_rect.position.x, reticle_rect.position.y, reticle_rect.size.x, reticle_rect.size.y)
	select_indicator.visible = false
	set_selected(is_selected)
	refresh_intent_display()
	_refresh_status_chips()

func _update_hp_display() -> void:
	hp_bar.value = current_hp
	hp_label.text = "%d / %d" % [current_hp, max_hp]
	
	var status_text = ""
	if burn_turns_remaining > 0:
		status_text += "压制(%d) " % burn_turns_remaining
	if atk_down_turns > 0:
		status_text += "虚弱(-%d%%) " % roundi(atk_down_percent * 100)
	status_label.text = status_text.strip_edges()
	status_label.visible = false
	if is_instance_valid(_status_pill):
		_status_pill.visible = false
	_refresh_status_chips()

func _refresh_status_chips() -> void:
	if not is_instance_valid(_status_row):
		return
	if is_dead:
		_status_row.visible = false
		return
	_status_row.visible = true
	var shield_chip := CombatPresentation.sync_status_chip(_status_row, "EnemyShieldChip", ICON_SHIELD, str(shield), "shield")
	shield_chip.visible = shield > 0

	# Ensure StatusIcon stays on whichever debuff chip is active without node-name collisions.
	var old_weak := _status_row.get_node_or_null("EnemyWeakChip/ChipRow")
	if old_weak != null:
		for child in old_weak.get_children():
			if child is TextureRect:
				(child as Node).name = "_WeakIconTmp"
	var burn_icon_name := "StatusIcon" if burn_turns_remaining > 0 else "BurnIcon"
	var weak_icon_name := "StatusIcon" if (burn_turns_remaining <= 0 and atk_down_turns > 0) else "WeakIcon"
	var burn_chip := CombatPresentation.sync_status_chip(
		_status_row,
		"EnemyBurnChip",
		ICON_BURN,
		"%d×%d" % [burn_damage_per_turn, burn_turns_remaining],
		"burn",
		burn_icon_name
	)
	burn_chip.visible = burn_turns_remaining > 0
	var weak_chip := CombatPresentation.sync_status_chip(
		_status_row,
		"EnemyWeakChip",
		ICON_DEBUFF,
		"-%d%%×%d" % [roundi(atk_down_percent * 100), atk_down_turns],
		"weak",
		weak_icon_name
	)
	weak_chip.visible = atk_down_turns > 0
	if burn_turns_remaining > 0:
		_status_icon = burn_chip.find_child("StatusIcon", true, false) as TextureRect
	elif atk_down_turns > 0:
		_status_icon = weak_chip.find_child("StatusIcon", true, false) as TextureRect

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

func intent_summary() -> String:
	return _intent_summary

func refresh_intent_display() -> void:
	var summary_parts: Array[String] = []
	var compact_parts: Array[String] = []
	var has_aoe := false
	var has_attack := false
	var has_defend := false
	var has_heal := false
	var has_debuff := false
	for action in intent_queue:
		var t: String = str(action.get("type", "attack"))
		if t == "defend":
			has_defend = true
			var sh := int(action.get("shield", 0))
			summary_parts.append("防御%d" % sh)
			compact_parts.append(str(sh))
		elif t == "heal":
			has_heal = true
			var hl := int(action.get("heal", 12))
			summary_parts.append("回复%d" % hl)
			compact_parts.append("+%d" % hl)
		elif t == "debuff":
			has_debuff = true
			summary_parts.append("干扰")
			compact_parts.append("干扰")
		else:
			if t == "aoe": has_aoe = true
			has_attack = true
			var dmg := int(int(action.get("damage", enemy_data.base_atk)) * (1.0 - atk_down_percent))
			summary_parts.append("攻击%d" % dmg)
			compact_parts.append(str(dmg))
	_intent_summary = " → ".join(summary_parts)
	var mixed_kinds := (int(has_attack) + int(has_defend) + int(has_heal) + int(has_debuff)) > 1
	if mixed_kinds:
		intent_label.text = " → ".join(summary_parts)
	else:
		intent_label.text = "→".join(compact_parts)
	var pal_key := "intent_mix" if mixed_kinds else ("intent_atk" if has_attack else ("intent_heal" if has_heal else ("intent_debuff" if has_debuff else "intent_def")))
	var pal: Dictionary = CombatPresentation.CHIP_PALETTES.get(pal_key, CombatPresentation.CHIP_PALETTES["intent_mix"])
	intent_badge.add_theme_stylebox_override("panel", CombatPresentation.status_chip_style(pal_key))
	intent_label.add_theme_color_override("font_color", pal.get("ink", NotebookUI.INK))
	if is_instance_valid(_intent_icon):
		var icon_path := ICON_ATK_AOE if has_aoe else (ICON_ATK_SINGLE if has_attack else (ICON_HEAL if has_heal else (ICON_DEBUFF if has_debuff else ICON_SHIELD)))
		if ResourceLoader.exists(icon_path):
			_intent_icon.texture = load(icon_path) as Texture2D
			_intent_icon.visible = not compact_parts.is_empty()
		else:
			_intent_icon.visible = false
	intent_badge.visible = not is_dead and not compact_parts.is_empty()

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
	if is_instance_valid(_status_row): _status_row.visible = false
	if is_instance_valid(_target_clip): _target_clip.visible = false
	if is_instance_valid(_target_reticle): _target_reticle.visible = false
	if is_instance_valid(_ground_shadow): _ground_shadow.visible = false
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
	if is_instance_valid(_target_reticle):
		_target_reticle.visible = val and not is_dead
	var badge := get_node_or_null("VBox/IdentityPaper") as CanvasItem
	if is_instance_valid(badge):
		badge.modulate = Color(1.04, 1.02, 0.96) if val else Color(0.95, 0.94, 0.92)

func _gui_input(event: InputEvent) -> void:
	if is_dead:
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		unit_clicked.emit(self)
