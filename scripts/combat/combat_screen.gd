class_name CombatScreen
extends Control

signal combat_finished(victory: bool)

@onready var bg_rect: TextureRect = $Background
@onready var player_sprite: TextureRect = $PlayerArea/ProtagonistSprite
@onready var player_hp_bar: ProgressBar = $PlayerArea/PlayerHPBar
@onready var player_hp_label: Label = $PlayerArea/PlayerHPBar/HPLabel
@onready var player_shield_label: Label = $PlayerArea/PlayerShieldLabel
@onready var player_status_label: Label = $PlayerArea/PlayerStatusLabel

@onready var enemies_container: HBoxContainer = $EnemyArea/EnemiesContainer
@onready var cards_container: HBoxContainer = $HandArea/CardsContainer
@onready var hand_area: Control = $HandArea
@onready var top_info: Control = $TopInfo
@onready var turn_banner: Label = $TopInfo/TurnBanner
@onready var round_label: Label = $TopInfo/RoundLabel
@onready var floating_anchor: Control = $FloatingAnchor

@onready var result_modal: Panel = $ResultModal
@onready var result_title: Label = $ResultModal/VBox/TitleLabel
@onready var result_desc: RichTextLabel = $ResultModal/VBox/DescLabel
@onready var result_button: Button = $ResultModal/VBox/ConfirmButton

var floating_text_scene = preload("res://scripts/combat/floating_text.gd")
var card_ui_scene = preload("res://scenes/combat/combat_card_ui.tscn")
var enemy_ui_scene = preload("res://scenes/combat/enemy_unit_ui.tscn")

var enemy_nodes: Array[EnemyUnitUI] = []
var card_ui_nodes: Array[CombatCardUI] = []
var selected_enemy: EnemyUnitUI = null
var current_round: int = 1
var is_player_turn: bool = true
var is_animating: bool = false
var cards_played_this_turn: int = 0

var player_shield: int = 0
var player_reflect_damage: int = 0
var player_reflect_turns: int = 0
var player_reflect_hits: int = 0

# --- 动态添加的 UI 控件：模态遮罩、结束回合按钮与战报日志 ---
var modal_backdrop: ColorRect
var end_turn_btn: Button
var log_panel: PanelContainer
var log_text: RichTextLabel
var log_toggle_btn: Button
var is_log_expanded: bool = false
var pause_button: Button
var _escaped := false
var _defeat_settled := false
var _result_action_pending: bool = false
var _combat_outcome: String = ""
var _exploration_mode: bool = false
var _qualifier_mode: bool = false
var _qualifier_round: int = 0
var _exploration_node_id: String = ""
var _exploration_run_id: int = -1
var _exploration_data: Dictionary = {}
var _companion_id: String = ""
var _cards_played_total: int = 0
var _active_zodiac_spec: Dictionary = {}
var _history_backdrop: ColorRect
var _history_close_button: Button

func _ready() -> void:
	_exploration_mode = GameState.is_exploration_combat()
	if _exploration_mode:
		_exploration_data = GameState.get_exploration_combat_data()
		_exploration_node_id = str(_exploration_data.get("node_id", ""))
		_exploration_run_id = int(_exploration_data.get("run_id", -1))
	if not _exploration_mode and str(GameState.pending_combat_data.get("mode", "")) == "qualifier":
		_qualifier_mode = true
		_qualifier_round = int(GameState.pending_combat_data.get("qualifier_round", 1))
	result_modal.visible = false
	result_button.pressed.connect(_on_result_button_pressed)
	
	_setup_combat_ui_extensions()
	_setup_combat_from_state()
	_restore_combat_checkpoint()
	_setup_pause_and_hint()
	PhaseTwoContent.apply_scene_labels(self)
	DaylightUI.apply(self)
	AudioManager.play_bgm_for_scene(SceneManager.TargetScene.COMBAT, CombatPresentation.is_overclock_combat(self))

func _setup_combat_ui_extensions() -> void:
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ResultBackdrop"
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(0.20, 0.19, 0.26, 0.48)
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_backdrop.visible = false
	add_child(modal_backdrop)
	end_turn_btn = Button.new()
	end_turn_btn.name = "EndTurnButton"
	end_turn_btn.text = "结束回合"
	CombatSkin.button(end_turn_btn, true)
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	hand_area.add_child(end_turn_btn)
	log_toggle_btn = Button.new()
	log_toggle_btn.name = "CombatHistoryButton"
	log_toggle_btn.text = "回合记录"
	CombatSkin.button(log_toggle_btn)
	log_toggle_btn.pressed.connect(_toggle_log_panel)
	top_info.add_child(log_toggle_btn)
	_history_backdrop = ColorRect.new()
	_history_backdrop.name = "HistoryBackdrop"
	_history_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_history_backdrop.color = Color(0.20, 0.19, 0.26, 0.40)
	_history_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_history_backdrop.visible = false
	_history_backdrop.z_index = 18
	_history_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _close_combat_history()
	)
	add_child(_history_backdrop)
	log_panel = PanelContainer.new()
	log_panel.name = "CombatHistory"
	log_panel.visible = false
	log_panel.z_index = 19
	log_panel.add_theme_stylebox_override("panel", CombatSkin.paper(Vector4(38, 28, 38, 28)))
	add_child(log_panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	log_panel.add_child(body)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "回合记录"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_history_close_button = Button.new()
	_history_close_button.name = "CloseCombatHistory"
	_history_close_button.text = "关闭"
	_history_close_button.custom_minimum_size = Vector2(150, 60)
	_history_close_button.add_theme_font_size_override("font_size", 26)
	CombatSkin.button(_history_close_button)
	_history_close_button.pressed.connect(_close_combat_history)
	header.add_child(_history_close_button)
	body.add_child(header)
	log_text = RichTextLabel.new()
	log_text.name = "HistoryText"
	log_text.bbcode_enabled = true
	log_text.scroll_active = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.custom_minimum_size.y = 470
	log_text.add_theme_font_size_override("normal_font_size", 26)
	log_text.add_theme_font_size_override("bold_font_size", 26)
	log_text.add_theme_color_override("default_color", DaylightUI.INK)
	log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_text.text = "战斗开始，准备行动。\n"
	body.add_child(log_text)
	DaylightUI.layout_combat(self, size)
	move_child(modal_backdrop, -1)
	move_child(result_modal, -1)

func _toggle_log_panel() -> void:
	if result_modal.visible or _combat_outcome != "" or is_animating or not is_player_turn or SceneManager.is_transitioning: return
	_disarm_all_cards()
	if is_log_expanded:
		_close_combat_history()
		return
	is_log_expanded = true
	_history_backdrop.visible = true
	log_panel.visible = true
	move_child(_history_backdrop, -1)
	move_child(log_panel, -1)
	_history_close_button.grab_focus()

func _close_combat_history() -> void:
	is_log_expanded = false
	log_panel.visible = false
	_history_backdrop.visible = false
	if _combat_outcome == "": log_toggle_btn.grab_focus()

func _disarm_all_cards(except: CombatCardUI = null) -> void:
	for card_ui in card_ui_nodes:
		if is_instance_valid(card_ui) and card_ui != except:
			card_ui.disarm_touch()

func _on_card_armed(armed_card: CombatCardUI) -> void:
	_disarm_all_cards(armed_card)

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_disarm_all_cards()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE and is_log_expanded:
		_close_combat_history()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_H and not result_modal.visible and not SceneManager.is_transitioning:
		_toggle_log_panel()
		get_viewport().set_input_as_handled()
		return
	if not is_player_turn or is_animating or result_modal.visible or is_log_expanded or SceneManager.is_transitioning:
		return
	var num_idx := -1
	match event.keycode:
		KEY_1, KEY_KP_1: num_idx = 0
		KEY_2, KEY_KP_2: num_idx = 1
		KEY_3, KEY_KP_3: num_idx = 2
		KEY_4, KEY_KP_4: num_idx = 3
		KEY_5, KEY_KP_5: num_idx = 4
	if num_idx >= 0 and num_idx < card_ui_nodes.size():
		var card_ui := card_ui_nodes[num_idx] as CombatCardUI
		if is_instance_valid(card_ui) and card_ui.is_available:
			_disarm_all_cards()
			_on_card_clicked(card_ui.card_data)
			get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_TAB:
		var living: Array[EnemyUnitUI] = []
		for e in enemy_nodes:
			var enemy_unit := e as EnemyUnitUI
			if is_instance_valid(enemy_unit) and not enemy_unit.is_dead:
				living.append(enemy_unit)
		if living.size() > 1:
			var cur := living.find(selected_enemy)
			_select_enemy(living[(cur + 1) % living.size()])
			AudioManager.play_sfx_hover()
		get_viewport().set_input_as_handled()
		return
	if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		var focus := get_viewport().gui_get_focus_owner()
		if focus == null or focus == end_turn_btn:
			AudioManager.play_sfx_click()
			_on_end_turn_pressed()
			get_viewport().set_input_as_handled()


func _log_combat(line: String) -> void:
	if log_text:
		log_text.append_text(DaylightUI.readable_bbcode(line) + "\n")

func _setup_combat_from_state() -> void:
	# 初始化敌方
	var battle_data: Dictionary = _exploration_data if _exploration_mode else GameState.pending_combat_data
	_companion_id = _resolve_companion_id(battle_data)
	_cards_played_total = 0
	_active_zodiac_spec = PlayerJourney.zodiac_resonance_spec(GameState.get_active_zodiac_id())
	_update_player_ui()
	var raw_enemy_ids: Array = battle_data.get("enemies", ["security_guard"])
	var enemy_ids: Array = raw_enemy_ids.slice(0, 3)
	for child in enemies_container.get_children():
		child.queue_free()
	enemy_nodes.clear()
	
	for eid in enemy_ids:
		var edata: EnemyData = _create_enemy_data(eid)
		if _exploration_mode:
			for spec in _exploration_data.get("enemy_specs", []):
				if spec.get("id", "") == eid:
					edata = _create_exploration_enemy_data(spec)
					break
		var enemy_ui = enemy_ui_scene.instantiate()
		enemies_container.add_child(enemy_ui)
		enemy_ui.setup_enemy(edata)
		enemy_ui.unit_clicked.connect(_on_enemy_clicked)
		enemy_ui.unit_died.connect(_on_enemy_died)
		enemy_nodes.append(enemy_ui)
	
	if enemy_nodes.size() > 0:
		_select_enemy(enemy_nodes[0])
	
	# 初始化卡牌手牌
	for child in cards_container.get_children():
		child.queue_free()
	card_ui_nodes.clear()
	
	var deck: Array[CardData] = []
	if _exploration_mode:
		deck = GameState.get_exploration_cards()
	else:
		for cid in GameState.equipped_card_ids:
			var equipped: CardData = GameState.get_card(cid)
			if equipped: deck.append(equipped)
	for cdata in deck:
		if cdata:
			var card_ui = card_ui_scene.instantiate()
			cards_container.add_child(card_ui)
			card_ui.setup_card(cdata, 0)
			card_ui.card_clicked.connect(_on_card_clicked)
			card_ui.card_armed.connect(_on_card_armed)
			card_ui_nodes.append(card_ui)
	
	if not _has_matching_checkpoint():
		_apply_battle_start_resonance()
	_start_player_turn()

func _create_exploration_enemy_data(spec: Dictionary) -> EnemyData:
	var enemy := EnemyData.new()
	for key in ["id", "name", "title", "rank", "max_hp", "base_atk", "actions_per_turn", "has_phase_two", "phase_two_hp_threshold"]:
		if spec.has(key): enemy.set(key, spec[key])
	enemy.skills = spec.get("skills", []).duplicate(true)
	enemy.phase_two_skill = spec.get("phase_two_skill", {}).duplicate(true)
	var sprite_path: String = str(spec.get("sprite_path", ""))
	if ResourceLoader.exists(sprite_path): enemy.sprite_texture = load(sprite_path)
	return enemy

func _create_enemy_data(eid: String) -> EnemyData:
	var e := EnemyData.new()
	e.id = eid
	var visual_id := eid
	match eid:
		"liu_yu_long_duel":
			visual_id = "liu_yu_long_duel"
			e.name = "柳宇龙（护盾热身）"
			e.max_hp = 60
			e.base_atk = 10
			e.actions_per_turn = 1
			e.skills = [{"name": "直拳试探", "type": "attack", "damage": 10}, {"name": "偏转护盾展开", "type": "defend", "shield": 8}, {"name": "热情连扣", "type": "attack", "damage": 14}]
		"arena_tactician":
			visual_id = "liu_yu_long_duel"
			e.name = "竞技社战术搭档"
			e.max_hp = 110
			e.base_atk = 15
			e.actions_per_turn = 1
			e.skills = [{"name": "快攻牵制", "type": "attack", "damage": 15}, {"name": "联防偏折盾", "type": "defend", "shield": 12}]
		"security_guard", "drone":
			visual_id = "security_guard"
			e.name = "被劫持的门岗卫兵"
			e.max_hp = 95
			e.base_atk = 16
			e.actions_per_turn = 1
			e.skills = [{"name": "超限封锁推击", "type": "attack", "damage": 16}, {"name": "强制截停猛冲", "type": "attack", "damage": 22}, {"name": "过载护盾协议", "type": "defend", "shield": 10}]
		"campus_robot", "preacher":
			visual_id = "campus_robot"
			e.name = "灰区重装拦截机"
			e.max_hp = 135
			e.base_atk = 18
			e.actions_per_turn = 1
			e.skills = [{"name": "超限射线截击", "type": "attack", "damage": 18}, {"name": "高能冲击蓄势", "type": "attack", "damage": 28}, {"name": "脉冲护御力场", "type": "defend", "shield": 14}]
		"ch1_hunter_mech", "principal", "boss_frank":
			visual_id = "ch1_hunter_mech"
			e.name = "灰区超限猎杀机兵"
			e.rank = EnemyData.EnemyRank.BOSS
			e.max_hp = 260
			e.base_atk = 16
			e.actions_per_turn = 2
			e.skills = [{"name": "强制限幅解除", "type": "attack", "damage": 16}, {"name": "红月干扰波", "type": "aoe", "damage": 14}, {"name": "核心护壁重构", "type": "defend", "shield": 12}]
			e.has_phase_two = true
			e.phase_two_hp_threshold = 0.5
			e.phase_two_skill = {"name": "编号抹除协议", "type": "attack", "damage": 28}
		"duel_student_ace":
			e.name = "学园预选代表"
			e.rank = EnemyData.EnemyRank.NORMAL
			e.max_hp = 115
			e.base_atk = 17
			e.actions_per_turn = 1
			e.skills = [{"name": "先手强攻", "type": "attack", "damage": 17}, {"name": "卡组护御", "type": "defend", "shield": 12}]
		"national_finalist":
			e.name = "巡回赛种子代表"
			e.rank = EnemyData.EnemyRank.ELITE
			e.max_hp = 195
			e.base_atk = 20
			e.actions_per_turn = 1
			e.skills = [{"name": "决胜推击", "type": "attack", "damage": 20}, {"name": "舞台威压", "type": "aoe", "damage": 16}, {"name": "反制壁垒", "type": "defend", "shield": 15}]
		"alliance_operative":
			e.name = "灰区反叛者特工"
			e.rank = EnemyData.EnemyRank.ELITE
			e.max_hp = 155
			e.base_atk = 19
			e.actions_per_turn = 1
			e.skills = [{"name": "反刻印狙击", "type": "attack", "damage": 19}, {"name": "光学回路调整", "type": "heal", "heal": 14}]
		"church_guardian":
			e.name = "红月圣堂守卫"
			e.rank = EnemyData.EnemyRank.BOSS
			e.max_hp = 210
			e.base_atk = 18
			e.actions_per_turn = 2
			e.skills = [{"name": "仪轨压制", "type": "attack", "damage": 18}, {"name": "赤月共鸣", "type": "aoe", "damage": 15}, {"name": "庇护结界", "type": "defend", "shield": 14}]
	var sprite_path := CombatSkin.enemy_combat_path(visual_id)
	if sprite_path != "":
		e.sprite_texture = load(sprite_path)
	return e

func _resolve_companion_id(battle_data: Dictionary) -> String:
	var explicit := str(battle_data.get("companion_id", ""))
	if explicit != "":
		return explicit
	if GameState.current_node_id == "n_gate":
		return "yang_zi_ying" if GameState.companions.get("yang_zi_ying", {}).get("unlocked", false) else ""
	var chosen := GameState.get_active_companion_id()
	if chosen != "" and (SaveManager.test_session or GameState.companions.get(chosen, {}).get("unlocked", false)):
		return chosen
	if str(battle_data.get("mode", "")) == "qualifier":
		if chosen != "" and (SaveManager.test_session or GameState.companions.get(chosen, {}).get("unlocked", false)):
			return chosen
		for cid in ["yang_zi_ying", "liu_yu_long", "jiang_zi"]:
			if SaveManager.test_session or GameState.companions.get(cid, {}).get("unlocked", false):
				return cid
		return ""
	var story_assist: bool = GameState.current_node_id in ["n_robot", "n5_boss"] or bool(GameState.story_flags.get("yang_rescued_player", false))
	var has_assist := GameState.equipped_card_ids.has("tag_assist") or GameState.equipped_card_ids.has("focus_lens") or GameState.equipped_card_ids.has("silent_library") or GameState.equipped_card_ids.has("duel_draw")
	if not _exploration_mode and not SaveManager.test_session and not has_assist and not story_assist:
		return ""
	if GameState.equipped_card_ids.has("silent_library") and GameState.companions.get("jiang_zi", {}).get("unlocked", false):
		return "jiang_zi"
	if GameState.equipped_card_ids.has("duel_draw") and GameState.companions.get("liu_yu_long", {}).get("unlocked", false):
		return "liu_yu_long"
	if GameState.companions.get("yang_zi_ying", {}).get("unlocked", false):
		return "yang_zi_ying"
	if GameState.companions.get("liu_yu_long", {}).get("unlocked", false):
		return "liu_yu_long"
	if GameState.companions.get("jiang_zi", {}).get("unlocked", false):
		return "jiang_zi"
	return ""

func _has_matching_checkpoint() -> bool:
	var snapshot: Dictionary = GameState.get_exploration_combat_checkpoint() if _exploration_mode else GameState.phase_two_combat_checkpoint
	var node_id: String = _exploration_node_id if _exploration_mode else GameState.current_node_id
	return not snapshot.is_empty() and snapshot.get("node_id", "") == node_id

func _apply_battle_start_resonance() -> void:
	if _active_zodiac_spec.is_empty():
		return
	var start_shield := int(_active_zodiac_spec.get("start_shield", 0))
	if start_shield > 0:
		player_shield += start_shield
	var start_heal := int(_active_zodiac_spec.get("start_heal", 0))
	if start_heal > 0 and GameState.player_current_hp < GameState.player_max_hp:
		GameState.heal_player(mini(start_heal, GameState.player_max_hp - GameState.player_current_hp))
	var weak_pct := float(_active_zodiac_spec.get("start_enemy_weak", 0.0))
	if weak_pct > 0.0:
		for e in enemy_nodes:
			if not e.is_dead:
				e.apply_debuff(weak_pct, 1)
				if is_instance_valid(floating_anchor):
					CombatVFX.play_burst(floating_anchor, "debuff", _vfx_center(e.sprite), Vector2(220, 220))
	var start_burn := int(_active_zodiac_spec.get("start_enemy_burn", 0))
	if start_burn > 0:
		for e in enemy_nodes:
			if not e.is_dead:
				e.apply_burn(start_burn, 2)
				if is_instance_valid(floating_anchor):
					CombatVFX.play_burst(floating_anchor, "overclock_redmoon", _vfx_center(e.sprite), Vector2(220, 220))
	_log_combat("[color=#8C6A36]✦ 星座共鸣【%s】生效：%s[/color]" % [str(_active_zodiac_spec.get("title", "")), str(_active_zodiac_spec.get("summary", ""))])
	_update_player_ui()

func _update_player_ui() -> void:
	player_hp_bar.max_value = GameState.player_max_hp
	player_hp_bar.value = GameState.player_current_hp
	player_hp_label.text = "%d / %d" % [GameState.player_current_hp, GameState.player_max_hp]
	
	player_shield_label.visible = false
	if player_shield > 0:
		player_shield_label.text = "护盾: %d · 本轮有效" % player_shield
		player_shield_label.add_theme_color_override("font_color", Color("#386485"))
	else:
		player_shield_label.text = "护盾: 0 · 未防备"
		player_shield_label.add_theme_color_override("font_color", Color("#6B6D78"))
	
	var parts: Array[String] = []
	if player_reflect_turns > 0:
		parts.append("掩护反击 %d点(余%d次)" % [player_reflect_damage, player_reflect_hits])
	var incoming := 0
	for enemy in enemy_nodes:
		if not enemy.is_dead: incoming += enemy.predicted_damage()
	var net_incoming := maxi(0, incoming - player_shield)
	parts.append(("预计净受击 %d" % net_incoming) if incoming > 0 else "敌方暂未蓄攻")
	player_status_label.text = "\n".join(parts)
	player_status_label.visible = false
	player_status_label.add_theme_color_override("font_color", Color("#B65B63") if net_incoming > 0 else NotebookUI.INK)
	_refresh_tactical_note()
	CombatPresentation.update_badges(self)

func _select_enemy(enemy: EnemyUnitUI) -> void:
	if selected_enemy and is_instance_valid(selected_enemy):
		selected_enemy.set_selected(false)
	selected_enemy = enemy
	if selected_enemy:
		selected_enemy.set_selected(true)
	_refresh_tactical_note()

func _refresh_tactical_note() -> void:
	var copy := hand_area.get_node_or_null("TargetCopy") as Label
	if copy == null: return
	var target_alive := is_instance_valid(selected_enemy) and not selected_enemy.is_dead
	copy.text = selected_enemy.enemy_data.name if target_alive else "等待选择目标"
	var description := hand_area.get_node_or_null("TargetDescription") as Label
	var portrait := hand_area.get_node_or_null("TargetPortrait") as TextureRect
	if description:
		var incoming := 0
		for enemy in enemy_nodes:
			if not enemy.is_dead: incoming += enemy.predicted_damage()
		var target_intent := ""
		var summary := selected_enemy.intent_summary() if target_alive and selected_enemy.has_method("intent_summary") else (selected_enemy.intent_label.text if target_alive else "")
		if target_alive and not summary.is_empty():
			target_intent = "下轮意图: %s\n" % summary
		description.text = "%s本轮预计受伤 %d\n护盾 %d · 结束时清除" % [target_intent, maxi(0, incoming - player_shield), player_shield]
	if portrait and is_instance_valid(selected_enemy) and selected_enemy.sprite.texture is AtlasTexture:
		var actor := selected_enemy.sprite.texture as AtlasTexture
		var crop := AtlasTexture.new()
		crop.atlas = actor.atlas
		crop.region = Rect2(actor.region.position, Vector2(actor.region.size.x, actor.region.size.y * 0.45))
		crop.filter_clip = true
		portrait.texture = crop
		portrait.flip_h = selected_enemy.sprite.flip_h

func _on_enemy_clicked(enemy: EnemyUnitUI) -> void:
	if not is_player_turn or is_animating or result_modal.visible or is_log_expanded:
		return
	_disarm_all_cards()
	_select_enemy(enemy)

func _on_enemy_died(enemy: EnemyUnitUI) -> void:
	_spawn_floating("击溃!", floating_text_scene.TextType.BUFF, enemy.sprite.global_position + Vector2(30, 30))
	_log_combat("[color=#B65B63][%s][/color] 已被彻底击溃！" % enemy.enemy_data.name)
	if selected_enemy == enemy:
		selected_enemy = null
		for other in enemy_nodes:
			if not other.is_dead:
				_select_enemy(other)
				break
	_check_combat_end()

func _start_player_turn() -> void:
	if result_modal.visible:
		return
	
	is_player_turn = true
	is_animating = false
	cards_played_this_turn = 0
	
	turn_banner.text = "叶舟行动"
	turn_banner.modulate = Color.WHITE
	round_label.text = "第 %d 回合" % current_round
	
	if end_turn_btn:
		end_turn_btn.disabled = false
	hand_area.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_disarm_all_cards()
	_log_combat("[b][color=#9E7051]━━━ 第 %d 回合 · 叶舟回合 ━━━[/color][/b]" % current_round)
	var turn_heal := int(_active_zodiac_spec.get("turn_heal", 0))
	if turn_heal > 0 and GameState.player_current_hp < GameState.player_max_hp:
		var healed := mini(turn_heal, GameState.player_max_hp - GameState.player_current_hp)
		GameState.heal_player(healed)
		if is_instance_valid(player_sprite):
			CombatVFX.play_burst(floating_anchor, "heal", _vfx_center(player_sprite), Vector2(210, 210))
			_spawn_floating("+%d 共鸣" % healed, floating_text_scene.TextType.HEAL, player_sprite.global_position + Vector2(60, 10))
		_log_combat("✦ 星座共鸣【%s】恢复叶舟 [color=#2ed573]%d点[/color] 体力。" % [str(_active_zodiac_spec.get("title", "")), healed])
		_update_player_ui()
	
	# 回合开始，所有卡牌CD减 1
	for card_ui in card_ui_nodes:
		card_ui.reduce_cooldown()
	GameState._request_progress_save()

func _on_card_clicked(card: CardData) -> void:
	if not is_player_turn or is_animating or result_modal.visible or is_log_expanded:
		return
	
	var available := false
	for card_ui in card_ui_nodes:
		if card_ui.card_data == card and card_ui.is_available: available = true
	if not available: return
	if card.heal > 0 and GameState.player_current_hp >= GameState.player_max_hp:
		_log_combat("体力已满，补充水分的次数已保留。")
		return

	# 检查目标
	if card.target_type == CardData.TargetType.SINGLE_ENEMY:
		if not selected_enemy or selected_enemy.is_dead:
			for e in enemy_nodes:
				if not e.is_dead:
					_select_enemy(e)
					break
		if not selected_enemy:
			return
	
	var hint := get_node_or_null("FirstBattleHint")
	if hint: hint.visible = false; GameState.set_story_flag("first_battle_hint_dismissed", true)
	_execute_player_card(card)

func _execute_player_card(card: CardData) -> void:
	is_animating = true
	cards_played_this_turn += 1
	_cards_played_total += 1
	
	# 找到对应的 card_ui 进入冷却
	for card_ui in card_ui_nodes:
		if card_ui.card_data.id == card.id:
			card_ui.put_on_cooldown()
			break
	
	turn_banner.text = "叶舟行动"
	_play_unit_lunge(player_sprite, Vector2(22.0, -4.0))
	AudioManager.play_sfx_card_play()
	var atk_bonus := int(_active_zodiac_spec.get("attack_bonus", 0))
	var shd_bonus := int(_active_zodiac_spec.get("shield_bonus", 0))
	
	# 执行效果并记录战报
	match card.target_type:
		CardData.TargetType.SINGLE_ENEMY:
			if selected_enemy and not selected_enemy.is_dead:
				var dmg = card.get_scaled_damage() + atk_bonus
				var actual_dmg = selected_enemy.take_damage(dmg)
				_play_unit_lunge(selected_enemy.sprite, Vector2(18.0, 0.0))
				CombatVFX.play_burst(floating_anchor, "slash", _vfx_center(selected_enemy.sprite), Vector2(280, 280))
				var is_overclock_hit := card.id in ["overclock_torch", "crimson_pulse", "final_trump"] or card.burn_damage > 0 or CombatPresentation.is_overclock_combat(self)
				AudioManager.play_sfx_hit(is_overclock_hit)
				if card.id in ["overclock_torch", "crimson_pulse", "final_trump"] or card.burn_damage > 0:
					CombatVFX.play_burst(floating_anchor, "overclock_redmoon", _vfx_center(selected_enemy.sprite), Vector2(300, 300), 46)
				_spawn_floating("-%d" % actual_dmg, floating_text_scene.TextType.DAMAGE, selected_enemy.sprite.global_position + Vector2(30, 50))
				
				var burn_str = ""
				if card.burn_damage > 0:
					selected_enemy.apply_burn(card.get_scaled_burn_damage(), card.burn_duration)
					_spawn_floating("压制!", floating_text_scene.TextType.BUFF, selected_enemy.sprite.global_position + Vector2(30, 15))
					burn_str = "，附加 2回合“压制(%d/回合)”" % card.get_scaled_burn_damage()
				
				_log_combat("叶舟打出“%s”：对 [%s] 造成 [color=#ff4757]%d点[/color] 伤害%s" % [card.name, selected_enemy.enemy_data.name, actual_dmg, burn_str])
		
		CardData.TargetType.ALL_ENEMIES:
			if card.attack_down_percent > 0:
				var debuff_val = card.get_scaled_attack_down()
				AudioManager.play_sfx_debuff()
				for e in enemy_nodes:
					if not e.is_dead:
						e.apply_debuff(debuff_val, card.debuff_duration)
						_play_unit_lunge(e.sprite, Vector2(12.0, 0.0))
						CombatVFX.play_burst(floating_anchor, "debuff", _vfx_center(e.sprite), Vector2(240, 240))
						_spawn_floating("虚弱!", floating_text_scene.TextType.BUFF, e.sprite.global_position + Vector2(30, 30))
				_log_combat("叶舟打出“%s”：削弱敌方全体 [color=#ffa502]%d%%[/color] 攻击伤害 (持续2回合)" % [card.name, roundi(debuff_val * 100)])
		
		CardData.TargetType.SELF:
			if card.shield > 0:
				var s = card.get_scaled_shield() + shd_bonus
				player_shield += s
				AudioManager.play_sfx_shield()
				CombatVFX.play_burst(floating_anchor, "shield", _vfx_center(player_sprite), Vector2(260, 260))
				_spawn_floating("+%d 护盾" % s, floating_text_scene.TextType.SHIELD, player_sprite.global_position + Vector2(60, 40))
				_log_combat("叶舟打出“%s”：自身获得 [color=#55aaff]%d点[/color] 护盾" % [card.name, s])
			if card.heal > 0:
				var h = mini(card.get_scaled_heal(), GameState.player_max_hp - GameState.player_current_hp)
				GameState.heal_player(h)
				AudioManager.play_sfx_heal()
				CombatVFX.play_burst(floating_anchor, "heal", _vfx_center(player_sprite), Vector2(260, 260))
				_spawn_floating("+%d 生命" % h, floating_text_scene.TextType.HEAL, player_sprite.global_position + Vector2(60, 20))
				_log_combat("叶舟打出“%s”：恢复叶舟 [color=#2ed573]%d点[/color] 生命值" % [card.name, h])
			if card.reflect_damage > 0:
				var ref = card.get_scaled_reflect_damage()
				player_reflect_damage = ref
				player_reflect_turns = 1
				player_reflect_hits = 2
				AudioManager.play_sfx_shield()
				CombatVFX.play_burst(floating_anchor, "counter_reflect", _vfx_center(player_sprite), Vector2(260, 260))
				_spawn_floating("默契掩护!", floating_text_scene.TextType.BUFF, player_sprite.global_position + Vector2(60, 60))
				_log_combat("叶舟打出“%s”：与同伴默契掩护 (受击反弹 [color=#ff9955]%d点[/color] 伤害)" % [card.name, ref])
	
	if _companion_id != "" and _cards_played_total % 3 == 0:
		_trigger_companion_assist()
	_update_player_ui()
	
	await get_tree().create_timer(0.4).timeout
	if _check_combat_end():
		return
	
	# 叶舟回合保持可操作状态，允许打出其他未在CD的卡牌
	is_animating = false
	GameState._request_progress_save()

func _trigger_companion_assist() -> void:
	var spec := PlayerJourney.companion_assist_spec(_companion_id)
	if spec.is_empty():
		return
	var comp_sprite := get_node_or_null("PlayerArea/CompanionSprite") as Control
	if is_instance_valid(comp_sprite) and comp_sprite.visible:
		_play_unit_lunge(comp_sprite, Vector2(26.0, -6.0))
	var heal_amt := int(spec.get("heal", 0))
	var shield_amt := int(spec.get("shield", 0))
	var dmg_amt := int(spec.get("damage", 0))
	var parts: Array[String] = []
	if heal_amt > 0:
		var actual_heal := mini(heal_amt, GameState.player_max_hp - GameState.player_current_hp)
		if actual_heal > 0:
			GameState.heal_player(actual_heal)
		CombatVFX.play_burst(floating_anchor, "heal", _vfx_center(player_sprite), Vector2(240, 240))
		parts.append("恢复 %d 点体力" % heal_amt)
	if shield_amt > 0:
		player_shield += shield_amt
		CombatVFX.play_burst(floating_anchor, "shield", _vfx_center(player_sprite), Vector2(240, 240))
		parts.append("获得 %d 点护盾" % shield_amt)
	if dmg_amt > 0:
		var target := selected_enemy
		if target == null or not is_instance_valid(target) or target.is_dead:
			target = null
			for e in enemy_nodes:
				if not e.is_dead:
					target = e
					break
		if is_instance_valid(target) and not target.is_dead:
			var actual_dmg := target.take_damage(dmg_amt)
			_play_unit_lunge(target.sprite, Vector2(20.0, 0.0))
			CombatVFX.play_burst(floating_anchor, "slash", _vfx_center(target.sprite), Vector2(260, 260))
			_spawn_floating("协战 -%d" % actual_dmg, floating_text_scene.TextType.DAMAGE, target.sprite.global_position + Vector2(30, 25))
			parts.append("对 [%s] 造成 %d 点协战伤害" % [target.enemy_data.name, actual_dmg])
	var anchor_ctrl: Control = comp_sprite if (is_instance_valid(comp_sprite) and comp_sprite.visible) else player_sprite
	AudioManager.play_sfx_cutin()
	CombatVFX.play_burst(floating_anchor, "companion_assist", _vfx_center(anchor_ctrl), Vector2(290, 290), 46)
	CombatPresentation.play_companion_cutin(self, _companion_id, spec)
	_spawn_floating("★ %s" % str(spec.get("skill", "同伴协战")), floating_text_scene.TextType.BUFF, anchor_ctrl.global_position + Vector2(30, 10))
	_log_combat("[color=#526D87]★ 同伴协战·%s【%s】：%s[/color]" % [str(spec.get("name", "")), str(spec.get("skill", "")), "，".join(parts)])

func _play_unit_lunge(unit_ctrl: Control, offset: Vector2) -> void:
	if not is_instance_valid(unit_ctrl):
		return
	var dur: float = SaveManager.motion_duration(0.11)
	if dur <= 0.0:
		return
	var prev_tween: Tween = unit_ctrl.get_meta("lunge_tween") as Tween if unit_ctrl.has_meta("lunge_tween") else null
	if prev_tween != null and is_instance_valid(prev_tween):
		prev_tween.kill()
	var base_pos: Vector2 = unit_ctrl.get_meta("lunge_base_pos") if unit_ctrl.has_meta("lunge_base_pos") else unit_ctrl.position
	unit_ctrl.set_meta("lunge_base_pos", base_pos)
	unit_ctrl.position = base_pos
	var tw := create_tween()
	unit_ctrl.set_meta("lunge_tween", tw)
	tw.tween_property(unit_ctrl, "position", base_pos + offset, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(unit_ctrl, "position", base_pos, dur * 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_end_turn_pressed() -> void:
	if not is_player_turn or is_animating or result_modal.visible or is_log_expanded:
		return
	
	if cards_played_this_turn == 0:
		_log_combat("[color=#747d8c] 叶舟观察局势，本回合未采取行动。[/color]")
	else:
		_log_combat("[color=#a4b0be]叶舟本回合打出 %d 张卡牌，结束行动。[/color]" % cards_played_this_turn)
	
	is_player_turn = false
	if end_turn_btn:
		end_turn_btn.disabled = true
	_start_enemy_turn()

func _start_enemy_turn() -> void:
	if result_modal.visible:
		return
	
	turn_banner.text = "对方行动"
	turn_banner.modulate = Color.WHITE
	_disarm_all_cards()
	_log_combat("[b][color=#B65B63]━━━ 第 %d 回合 · 敌方行动 ━━━[/color][/b]" % current_round)
	
	await get_tree().create_timer(0.4).timeout
	
	for enemy in enemy_nodes:
		if enemy.is_dead or result_modal.visible:
			continue
		
		if not enemy.begin_enemy_phase():
			_log_combat("[%s] 受到持续压制，停止行动。" % enemy.enemy_data.name)
			if _check_combat_end(): return
			continue

		# 支持特殊怪物/首领每回合多次行动
		var action_total = max(1, enemy.enemy_data.actions_per_turn)
		for act_i in range(action_total):
			if enemy.is_dead or result_modal.visible:
				break
			
			var action = enemy.execute_turn_intent(self)
			var type = action.get("type", "attack")
			
			if type == "burn_death":
				_log_combat("[%s] 受到持续压制，停止行动。" % enemy.enemy_data.name)
				break
			elif type == "skip":
				_log_combat("[%s] 因“特殊状态”无法行动，本回合什么也没有做。" % enemy.enemy_data.name)
			elif type == "attack" or type == "aoe":
				var base_dmg = action.get("damage", 10)
				var calculated_dmg = int(base_dmg * (1.0 - enemy.atk_down_percent))
				var actual_dmg = calculated_dmg
				var shield_absorbed = 0
				
				if player_shield > 0:
					if player_shield >= actual_dmg:
						shield_absorbed = actual_dmg
						player_shield -= actual_dmg
						actual_dmg = 0
					else:
						shield_absorbed = player_shield
						actual_dmg -= player_shield
						player_shield = 0
				
				GameState.damage_player(actual_dmg)
				if actual_dmg > 0:
					AudioManager.play_sfx_hit(type == "aoe" or enemy.is_phase_two or CombatPresentation.is_overclock_combat(self))
				else:
					AudioManager.play_sfx_shield()
				var enemy_fx := ("overclock_redmoon" if type == "aoe" or enemy.is_phase_two else "slash") if actual_dmg > 0 else "shield"
				CombatVFX.play_burst(floating_anchor, enemy_fx, _vfx_center(player_sprite), Vector2(260, 260))
				_spawn_floating("-%d" % actual_dmg, floating_text_scene.TextType.DAMAGE, player_sprite.global_position + Vector2(70, 70))
				
				var absorb_str = (" (护盾吸收 [color=#55aaff]%d点[/color])" % shield_absorbed) if shield_absorbed > 0 else ""
				_log_combat("[%s] 释放“%s”：对叶舟造成 [color=#ff4757]%d点[/color] 伤害%s" % [enemy.enemy_data.name, action.get("name", "攻击"), actual_dmg, absorb_str])
				
				# 触发反伤
				if player_reflect_turns > 0 and player_reflect_hits > 0:
					player_reflect_hits -= 1
					var ref_dmg = enemy.take_damage(player_reflect_damage)
					AudioManager.play_sfx_counter_reflect()
					CombatVFX.play_burst(floating_anchor, "counter_reflect", _vfx_center(player_sprite), Vector2(240, 240))
					CombatVFX.play_burst(floating_anchor, "counter_reflect", _vfx_center(enemy.sprite), Vector2(240, 240), 46)
					_spawn_floating("反弹 -%d" % ref_dmg, floating_text_scene.TextType.DAMAGE, enemy.sprite.global_position + Vector2(30, 40))
					_log_combat("掩护反击生效！反弹 [color=#ff9955]%d点[/color] 伤害给 [%s]！" % [ref_dmg, enemy.enemy_data.name])
			
			elif type == "defend":
				var s = action.get("shield", 15)
				enemy.shield += s
				enemy._update_hp_display()
				CombatVFX.play_burst(floating_anchor, "shield", _vfx_center(enemy.sprite), Vector2(240, 240))
				_spawn_floating("+%d 护盾" % s, floating_text_scene.TextType.SHIELD, enemy.sprite.global_position + Vector2(30, 20))
				_log_combat("[%s] 释放“%s”：自身获得 [color=#55aaff]%d点[/color] 护盾。" % [enemy.enemy_data.name, action.get("name", "防御"), s])
			elif type == "heal":
				var h := mini(int(action.get("heal", 12)), enemy.max_hp - enemy.current_hp)
				enemy.current_hp += h
				enemy._update_hp_display()
				CombatVFX.play_burst(floating_anchor, "heal", _vfx_center(enemy.sprite), Vector2(240, 240))
				_spawn_floating("+%d 恢复" % h, floating_text_scene.TextType.HEAL, enemy.sprite.global_position + Vector2(30, 20))
				_log_combat("[%s] 释放“%s”：自身恢复 [color=#2ed573]%d点[/color] 体力。" % [enemy.enemy_data.name, action.get("name", "调整"), h])
			
			# The remaining locked actions are never rerolled during this phase.
			_update_player_ui()
			await get_tree().create_timer(0.45).timeout
			
			if GameState.player_current_hp <= 0:
				_trigger_defeat()
				return
			
			if _check_combat_end():
				return
	
	if result_modal.visible:
		return
	
	# 回合结束处理
	if player_reflect_turns > 0:
		player_reflect_turns -= 1
		if player_reflect_turns <= 0:
			player_reflect_damage = 0
	
	player_shield = 0
	player_reflect_hits = 0
	for enemy in enemy_nodes:
		if not enemy.is_dead: enemy.finish_enemy_phase()
	_update_player_ui()
	current_round += 1
	_start_player_turn()

func _check_combat_end() -> bool:
	if GameState.player_current_hp <= 0:
		_trigger_defeat()
		return true
	var all_dead = true
	for e in enemy_nodes:
		if not e.is_dead:
			all_dead = false
			break
	
	if all_dead:
		_trigger_victory()
		return true
	return false

func _lock_combat_underlying_ui() -> void:
	_disarm_all_cards()
	_close_combat_history()
	modal_backdrop.z_index = 20
	result_modal.z_index = 21
	move_child(modal_backdrop, -1)
	move_child(result_modal, -1)
	for button in find_children("*", "Button", true, false):
		if not result_modal.is_ancestor_of(button): button.disabled = true
	is_player_turn = false
	is_animating = false
	
	# 1. 激活全屏阻断遮罩
	if modal_backdrop:
		modal_backdrop.visible = true
	
	# 2. 禁用结束回合按钮
	if end_turn_btn:
		end_turn_btn.disabled = true
	
	# 3. 锁定手牌区与战报面板输入
	hand_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if log_panel:
		log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 4. 禁用所有卡牌交互
	for c in card_ui_nodes:
		c.is_available = false
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _trigger_victory() -> void:
	if result_modal.visible or _combat_outcome != "":
		return
	_combat_outcome = "victory"
	AudioManager.play_sfx_victory()
	combat_finished.emit(true)
	_lock_combat_underlying_ui()
	result_modal.visible = true
	if _exploration_mode:
		_show_exploration_result(true)
		return
	if str(GameState.pending_combat_data.get("mode", "")) == "qualifier":
		var round_idx := int(GameState.pending_combat_data.get("qualifier_round", 1))
		var spec := PlayerJourney.qualifier_round_spec(round_idx)
		var flag_key := str(spec.get("flag", "qualifier_r%d_won" % round_idx))
		var first_win := not bool(GameState.story_flags.get(flag_key, false))
		GameState.set_story_flag(flag_key, true)
		if round_idx == 3:
			GameState.set_story_flag("arete_qualifier_completed", true)
		var money_gain := int(spec.get("money", 150)) if first_win else 60
		var pts_gain := int(spec.get("points", 45)) if first_win else 25
		GameState.add_crystals(money_gain)
		GameState.add_scrap(pts_gain, false)
		var item_desc := ""
		if first_win and GameState.grant_inventory_reward("qualifier_reward_r%d" % round_idx, spec.get("items", {}), false):
			for iid in spec.get("items", {}):
				var idef := ItemCatalog.definition(str(iid))
				if not idef.is_empty():
					item_desc += " · %s×%d" % [str(idef["name"]), int(spec["items"][iid])]
		GameState.reset_player_hp()
		_log_combat("选拔赛第 %d 战获胜！零用钱 +%d · 练习点 +%d。" % [round_idx, money_gain, pts_gain])
		if round_idx == 3:
			result_title.text = "★ 阿瑞忒代表选拔赛 · 全胜制霸！"
			result_desc.text = "恭喜赢得「%s」与【阿瑞忒代表通行章】！\n奖励：零用钱 +%d · 练习点 +%d%s。\n\n阿瑞忒篇主线与代表资格已全部达成！第二章「诺莫斯」尚在筹备中，可自由在校园内收集全部16张刻印卡、风物纪要与放映室印章。" % [str(spec.get("title", "最终战")), money_gain, pts_gain, item_desc]
			result_button.text = "回到社团教室"
		else:
			result_title.text = "选拔赛第 %d 战告捷！" % round_idx
			result_desc.text = "成功晋级下一轮校内代表选拔！\n奖励：零用钱 +%d · 练习点 +%d%s。\n\n整理卡匣后即可继续挑战第 %d 战。" % [money_gain, pts_gain, item_desc, round_idx + 1]
			result_button.text = "返回体育馆擂台"
		DaylightUI.polish(result_modal)
		result_button.grab_focus()
		return
	var is_duel_tutorial: bool = GameState.current_node_id == "n_gate"
	result_title.text = "热身切磋结束" if is_duel_tutorial else "暂时安全了"
	var is_boss: bool = GameState.pending_combat_data.get("is_boss", false) or GameState.current_node_id == "n5_boss"
	var points_earned: int = {"n_gate":25, "n_guard":40, "n_robot":50, "n5_boss":80}.get(GameState.current_node_id, 40)
	var materials_earned: int = {"n_gate":2, "n_guard":3, "n_robot":4, "n5_boss":5}.get(GameState.current_node_id, 3)
	if not GameState.grant_inventory_reward("story_combat_materials_" + GameState.current_node_id, {"material_common":materials_earned},false): materials_earned = 0
	GameState.add_scrap(points_earned,false)
	_log_combat("局势平息，获得练习点 +%d。" % points_earned)
	var desc := ("护盾裁决热身完成！\n" if is_duel_tutorial else "找到了继续前进的空隙。\n") + "练习点 +%d" % points_earned
	if materials_earned > 0: desc += " · 普通材料 +%d" % materials_earned
	desc += "。\n"
	if is_boss:
		GameState.set_story_flag("principal_stopped", true)
		GameState.unlock_card("fake_cheque",false)
		desc += "成功击退灰区超限猎杀终端，解锁「扰频假票令」。\n接下来确认黄秋枫与白羊座母卡的状态。"
		result_button.text = "确认情况"
	elif is_duel_tutorial:
		desc += "柳宇龙已加入协战同伴！接下来一起去入驻「社团教室」。"
		result_button.text = "继续行程"
	else:
		desc += "先确认周围安全，再继续今天的行程。"
		result_button.text = "继续行程"
	result_desc.text = desc
	DaylightUI.polish(result_modal)
	result_button.grab_focus()

func _trigger_defeat() -> void:
	if result_modal.visible or _combat_outcome != "":
		return
	_combat_outcome = "defeat"
	combat_finished.emit(false)
	_lock_combat_underlying_ui()
	result_modal.visible = true
	# A defeat is committed immediately, including an escape at positive HP.
	# No checkpoint from this battle may be resumed after leaving or reloading.
	if _exploration_mode:
		_defeat_settled = GameState.complete_exploration_node(_exploration_node_id,"defeat",false)
	else:
		GameState.phase_two_combat_checkpoint.clear()
		GameState.pending_combat_data.clear()
		GameState.reset_player_hp()
		_defeat_settled = true
	SaveManager.request_autosave()
	if _exploration_mode:
		_show_exploration_result(false)
		return
	if _qualifier_mode:
		result_title.text = "逃跑 · 选拔赛判负" if _escaped else "选拔赛惜败"
		result_desc.text = "本场选拔赛按失败结算。\n可回体育馆调整卡匣与刻印卡强化等级后再次登台。" if _escaped else "本场代表选拔赛未能取胜。\n叶舟已恢复体力，回到体育馆整理卡匣与协战同伴后再战吧。"
		result_button.text = "返回体育馆擂台"
	else:
		result_title.text = "逃跑 · 战斗失败" if _escaped else "先休息一下"
		result_desc.text = "已结束本场战斗，按失败结算。\n本场不会获得胜利奖励；已完成的行程会保留。再次挑战将从头开始。" if _escaped else "叶舟暂时体力不支，先回安全的社团教室。\n已完成的行程与练习点会保留，整理行动卡后可以重新挑战。"
		result_button.text = "返回社团教室"
	_log_combat("选择逃跑，本场战斗判负。" if _escaped else "本场战斗失败，先恢复体力。")
	DaylightUI.polish(result_modal)
	result_button.grab_focus()

func _show_exploration_result(victory: bool) -> void:
	if victory:
		var boss: bool = _exploration_data.get("is_boss", false)
		var separate_exit: bool = SchoolExplorationFlow.enabled()
		result_title.text = "出口已开放" if boss and separate_exit else "练习完成"
		var next_step := "回到路线，选择下一站。"
		if boss: next_step = "终点挑战完成，前往出口收好这一趟的收获。" if separate_exit else "路线已走完，回休息室整理收获。"
		result_desc.text = "确认后收集：%s\n%s" % [ExplorationContent.reward_text(_exploration_data.get("reward", {})), next_step]
		result_button.text = ("前往出口" if separate_exit else "收集并返回") if boss else "收集并继续"
	else:
		result_title.text = "逃跑 · 训练失败" if _escaped else "训练失败"
		result_desc.text = "本场战斗按失败结算，本次训练已经结束。\n此前收集的材料与练习点会保留，本场没有胜利奖励。"
		result_button.text = "返回体育馆"
	DaylightUI.polish(result_modal)
	result_button.grab_focus()

func _on_result_button_pressed() -> void:
	if _result_action_pending or not result_modal.visible or SceneManager.is_transitioning:
		return
	if _exploration_mode:
		if _combat_outcome == "defeat" and _defeat_settled:
			_result_action_pending = true
			result_button.disabled = true
			CampusLife.return_from_training()
			return
		if not GameState.is_exploration_combat() or GameState.exploration_state.get("run_id", -2) != _exploration_run_id or GameState.exploration_state.get("current_node_id", "") != _exploration_node_id:
			return
		_result_action_pending = true
		result_button.disabled = true
		if GameState.complete_exploration_node(_exploration_node_id, _combat_outcome,false):
			if GameState.exploration_active: SceneManager.change_scene(SceneManager.TargetScene.EXPLORATION)
			else: CampusLife.return_from_training()
		else:
			_result_action_pending = false
			result_button.disabled = false
		return
	_result_action_pending = true
	result_button.disabled = true
	GameState.phase_two_combat_checkpoint.clear()
	if _qualifier_mode:
		var q_round := _qualifier_round
		var won := (_combat_outcome == "victory")
		GameState.pending_combat_data.clear()
		GameState.current_node_id = ""
		GameState.reset_player_hp()
		CampusLife.travel_to("club" if (won and q_round == 3) else "gym")
		return
	if _combat_outcome == "defeat" or GameState.player_current_hp <= 0:
		GameState.reset_player_hp()
		GameState.pending_combat_data.clear()
		SceneManager.change_scene(SceneManager.TargetScene.HOME)
		return
	if not GameState.complete_phase_two_step(GameState.current_node_id):
		GameState.pending_combat_data.clear()
		SceneManager.change_scene(SceneManager.TargetScene.HOME)

func _setup_pause_and_hint() -> void:
	pause_button = Button.new()
	pause_button.name = "EscapeButton"
	pause_button.text = "逃跑 · 判负"
	pause_button.custom_minimum_size = Vector2(180,48)
	pause_button.position = Vector2(32,24)
	pause_button.pressed.connect(_on_escape_pressed)
	top_info.add_child(pause_button)
	if _exploration_mode or not (GameState.current_node_id in ["n_gate", "n_guard"]) or (GameState.current_node_id == "n_gate" and GameState.story_flags.get("first_battle_hint_dismissed", false)):
		return
	var hint := HBoxContainer.new()
	hint.name = "FirstBattleHint"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var copy := Label.new()
	copy.text = "红月超限警示：安全限幅已解除！请善用护盾与虚弱压制。" if GameState.current_node_id == "n_guard" else "热身教学：先看上方敌方意图；按 1-3 或点击出牌，Tab 切目标，Space 结束回合。"
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	copy.custom_minimum_size = Vector2(424.0, 68.0)
	copy.add_theme_font_size_override("font_size", 17)
	hint.add_child(copy)
	add_child(hint)

func _save_combat_checkpoint() -> void:
	var enemies: Array[Dictionary] = []
	for enemy in enemy_nodes:
		enemies.append({"id":enemy.enemy_data.id,"hp":enemy.current_hp,"shield":enemy.shield,"dead":enemy.is_dead,"burn_damage":enemy.burn_damage_per_turn,"burn_turns":enemy.burn_turns_remaining,"atk_down":enemy.atk_down_percent,"atk_down_turns":enemy.atk_down_turns,"phase_two":enemy.is_phase_two,"intent":enemy.next_intent.duplicate(true),"intent_queue":enemy.intent_queue.duplicate(true)})
	var cooldowns: Dictionary = {}
	var uses: Dictionary = {}
	for card in card_ui_nodes:
		cooldowns[card.card_data.id] = card.current_cooldown
		uses[card.card_data.id] = card.uses_remaining
	var snapshot := {"node_id":GameState.current_node_id,"round":current_round,"player_shield":player_shield,"reflect_damage":player_reflect_damage,"reflect_turns":player_reflect_turns,"reflect_hits":player_reflect_hits,"uses":uses,"played":cards_played_this_turn,"cards_played_total":_cards_played_total,"enemies":enemies,"cooldowns":cooldowns,"selected":enemy_nodes.find(selected_enemy),"log":log_text.get_parsed_text()}
	if _exploration_mode:
		GameState.save_exploration_combat_checkpoint(snapshot)
	else:
		GameState.phase_two_checkpoint = {"node_id":GameState.current_node_id,"stage":"combat"}
		GameState.phase_two_combat_checkpoint = snapshot

func _restore_combat_checkpoint() -> void:
	var snapshot: Dictionary = GameState.get_exploration_combat_checkpoint() if _exploration_mode else GameState.phase_two_combat_checkpoint
	var node_id: String = _exploration_node_id if _exploration_mode else GameState.current_node_id
	if snapshot.is_empty() or snapshot.get("node_id","") != node_id:
		return
	current_round = int(snapshot.get("round",1))
	player_shield = int(snapshot.get("player_shield",0))
	player_reflect_damage = int(snapshot.get("reflect_damage",0))
	player_reflect_turns = int(snapshot.get("reflect_turns",0))
	player_reflect_hits = int(snapshot.get("reflect_hits", 2 if player_reflect_turns > 0 else 0))
	cards_played_this_turn = int(snapshot.get("played",0))
	_cards_played_total = int(snapshot.get("cards_played_total", 0))
	var saved_enemies: Array = snapshot.get("enemies",[])
	for index in mini(saved_enemies.size(),enemy_nodes.size()):
		var enemy: EnemyUnitUI = enemy_nodes[index]
		var saved: Dictionary = saved_enemies[index]
		if saved.get("id","") != enemy.enemy_data.id: continue
		enemy.current_hp = int(saved.get("hp",enemy.max_hp))
		enemy.shield = int(saved.get("shield",0))
		enemy.is_dead = bool(saved.get("dead",false))
		enemy.burn_damage_per_turn = int(saved.get("burn_damage",0))
		enemy.burn_turns_remaining = int(saved.get("burn_turns",0))
		enemy.atk_down_percent = float(saved.get("atk_down",0))
		enemy.atk_down_turns = int(saved.get("atk_down_turns",0))
		enemy.is_phase_two = bool(saved.get("phase_two",false))
		enemy.restore_intents(saved.get("intent_queue",[]), saved.get("intent",{}))
		enemy._update_hp_display()
	var cooldowns: Dictionary = snapshot.get("cooldowns",{})
	for card in card_ui_nodes:
		card.current_cooldown = int(cooldowns.get(card.card_data.id,0))
		card.uses_remaining = int(snapshot.get("uses",{}).get(card.card_data.id,card.card_data.get_battle_use_limit()))
		card._update_display()
	var selected: int = int(snapshot.get("selected",0))
	if selected >= 0 and selected < enemy_nodes.size(): _select_enemy(enemy_nodes[selected])
	log_text.text = snapshot.get("log","")
	round_label.text = "第 %d 回合" % current_round
	_update_player_ui()

func _on_escape_pressed() -> void:
	if not is_player_turn or is_animating or result_modal.visible or is_log_expanded or SceneManager.is_transitioning:
		return
	_escaped = true
	is_player_turn = false
	_trigger_defeat()

func _spawn_floating(text_str: String, type: int, pos: Vector2) -> void:
	var label = Label.new()
	label.set_script(floating_text_scene)
	floating_anchor.add_child(label)
	label.init_floating(text_str, type, pos)

func _vfx_center(target: Control) -> Vector2:
	if not is_instance_valid(target):
		return size * 0.5
	return target.get_global_rect().get_center()
