class_name NodeMap
extends Control

@onready var nodes_container: Control = $ScrollContainer/MapCanvas/NodesContainer
@onready var lines_canvas: Control = $ScrollContainer/MapCanvas/LinesCanvas
@onready var hp_label: Label = $TopBar/PlayerInfo/HPLabel
@onready var scrap_label: Label = $TopBar/PlayerInfo/ScrapLabel
@onready var chapter_title: Label = $TopBar/ChapterTitle
@onready var retreat_button: Button = $TopBar/RetreatButton
@onready var event_modal: Panel = $EventModal
@onready var event_title: Label = $EventModal/VBox/Title
@onready var event_desc: RichTextLabel = $EventModal/VBox/Desc
@onready var event_confirm: Button = $EventModal/VBox/ConfirmBtn

var reset_route_btn: Button
var node_data_map: Dictionary = {}
var current_active_node_id: String = ""
var node_buttons: Dictionary = {}

# The existing story route remains the default; material runs opt into this branch.
var material_exploration_mode: bool = false
var refs: Dictionary = {}
var pause_button: Button
var event_choice_buttons: Dictionary = {}
var _material_surface: Panel
var _material_backdrop: ColorRect
var _material_choices: HBoxContainer
var _material_totals: Label
var _material_progress: Label
var _material_feedback: Label
var _material_refresh_pending: bool = false

func _ready() -> void:
	if GameState.exploration_active and not GameState.exploration_state.is_empty():
		material_exploration_mode = true
		_ready_material_exploration()
		return
	event_modal.visible = false
	event_confirm.pressed.connect(func():
		event_modal.visible = false
		_update_ui()
		_refresh_node_states()
	)
	retreat_button.pressed.connect(_on_retreat_pressed)
	
	# 添加「重新规划路线」按钮，方便随时体验其他分支
	reset_route_btn = Button.new()
	reset_route_btn.text = "重新开始"
	reset_route_btn.custom_minimum_size = Vector2(110, 36)
	reset_route_btn.position = Vector2(retreat_button.position.x - 125, retreat_button.position.y)
	reset_route_btn.pressed.connect(_on_reset_route_pressed)
	$TopBar.add_child(reset_route_btn)
	
	_update_ui()
	_generate_chapter_1_nodes()
	PhaseTwoContent.apply_scene_labels(self)
	DaylightUI.apply(self)

func _update_ui() -> void:
	hp_label.text = "体力 %d / %d" % [GameState.player_current_hp, GameState.player_max_hp]
	scrap_label.text = "练习点 %d" % GameState.scrap_metal
	chapter_title.text = PhaseTwoContent.CHAPTER_TITLE

func _generate_chapter_1_nodes() -> void:
	node_data_map.clear()
	# 临时校园章节采用线性顺序，保证四位角色、援手与敌人顺序完整。
	_add_node_def("n0", 0, MapNodeData.NodeType.STORY, "樱林解围", "在樱林上学路遇见杨子英、黄秋枫与堵路小混混。", ["n_gate"], "campus_morning", Vector2(120, 150))
	_add_node_def("n_gate", 1, MapNodeData.NodeType.BATTLE, "海选赛与初战", "操场海选赛与杨子英组队迎战柳宇龙与姜梓。", ["n_affairs"], "school_gate", Vector2(250, 370))
	_add_node_def("n_affairs", 2, MapNodeData.NodeType.STORY, "旧园名录", "协助姜梓核对巡回赛名录并察觉终端异常。", ["n_dusk"], "school_affairs", Vector2(380, 150))
	_add_node_def("n_dusk", 3, MapNodeData.NodeType.STORY, "黄昏轻吻", "旧公园黄昏轻吻后，红月警报忽然封锁校门。", ["n_guard"], "after_school", Vector2(510, 370))
	_add_node_def("n_guard", 4, MapNodeData.NodeType.BATTLE, "门岗封锁", "冲破被外部权限劫持的超限卫兵封锁。", ["n_rescue"], "security_guard", Vector2(640, 150))
	_add_node_def("n_rescue", 5, MapNodeData.NodeType.STORY, "灰区奇袭", "灰区女特工重创秋枫，杨子英拉着叶舟突围。", ["n_robot"], "yang_rescue", Vector2(770, 370))
	_add_node_def("n_robot", 6, MapNodeData.NodeType.BATTLE, "拦截机械", "阻停灰区重装巡逻拦截机。", ["n5_boss"], "campus_robot", Vector2(900, 150))
	_add_node_def("n5_boss", 7, MapNodeData.NodeType.BOSS, "红月超限", "击退解除限幅的灰区猎杀终端。", ["n_find_yang"], "principal_confrontation", Vector2(1030, 370))
	_add_node_def("n_find_yang", 8, MapNodeData.NodeType.STORY, "白羊觉醒", "确认秋枫的结晶休眠，唤醒 #01 白羊座母卡。", [], "find_yang", Vector2(1160, 150))
	_refresh_node_states()

func _refresh_node_states() -> void:
	# 1. 默认将所有节点设为锁定 LOCKED
	for nid in node_data_map:
		node_data_map[nid]["data"].state = MapNodeData.NodeState.LOCKED
	
	# 2. 将历史已访问节点标记为 VISITED
	for vid in GameState.visited_node_ids:
		if node_data_map.has(vid):
			node_data_map[vid]["data"].state = MapNodeData.NodeState.VISITED
	
	# 3. 严格依据当前行进节点解锁下游分支（互斥机制：所有未选择的同层/平行分支路线彻底锁定）
	if GameState.visited_node_ids.is_empty():
		current_active_node_id = "n0"
		if node_data_map.has("n0"):
			node_data_map["n0"]["data"].state = MapNodeData.NodeState.AVAILABLE
	else:
		var last_id = GameState.visited_node_ids[-1]
		current_active_node_id = last_id
		if node_data_map.has(last_id):
			var next_ids = node_data_map[last_id]["data"].connected_next_node_ids
			for nxt in next_ids:
				if node_data_map.has(nxt) and not GameState.visited_node_ids.has(nxt):
					node_data_map[nxt]["data"].state = MapNodeData.NodeState.AVAILABLE
	
	_render_nodes_and_lines()

func _add_node_def(nid: String, layer: int, type: MapNodeData.NodeType, title_str: String, desc: String, nxt_ids: Array[String], content_id: String, pos: Vector2) -> void:
	var n = MapNodeData.new()
	n.node_id = nid
	n.layer_index = layer
	n.node_type = type
	n.title = title_str
	n.description = desc
	n.connected_next_node_ids = nxt_ids
	n.content_id = content_id
	n.state = MapNodeData.NodeState.LOCKED
	node_data_map[nid] = {"data": n, "pos": pos, "base_pos": pos}

func _render_nodes_and_lines() -> void:
	var canvas_size: Vector2 = nodes_container.get_parent().size
	for entry in node_data_map.values():
		var base: Vector2 = entry["base_pos"]
		entry["pos"] = Vector2(160 + (base.x - 120) * (canvas_size.x - 320) / 1040, 140 + (base.y - 150) * (canvas_size.y - 280) / 220)
	for child in nodes_container.get_children():
		child.queue_free()
	node_buttons.clear()
	
	# 绘制连线
	lines_canvas.set_map_data(node_data_map)
	
	# 创建节点按钮
	for nid in node_data_map:
		var item = node_data_map[nid]
		var ndata: MapNodeData = item["data"]
		var pos: Vector2 = item["pos"]
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(190, 100)
		btn.position = pos - Vector2(95, 50)
		btn.clip_text = true
		
		var icon_str = ""
		match ndata.node_type:
			MapNodeData.NodeType.STORY:
				icon_str = ""
			MapNodeData.NodeType.BATTLE:
				icon_str = ""
			MapNodeData.NodeType.ELITE:
				icon_str = ""
			MapNodeData.NodeType.CHEST:
				icon_str = ""
			MapNodeData.NodeType.REST:
				icon_str = ""
			MapNodeData.NodeType.EVENT:
				icon_str = ""
			MapNodeData.NodeType.BOSS:
				icon_str = ""
		
		btn.add_theme_font_size_override("font_size", 18)
		
		if ndata.state == MapNodeData.NodeState.AVAILABLE:
			btn.disabled = false
			btn.text = "%s%s\n▶ 点击探索" % [icon_str, ndata.title]
			btn.modulate = Color.WHITE
			btn.theme_type_variation = &"PrimaryButton"
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.add_theme_color_override("font_color", DaylightUI.INK)
		elif ndata.state == MapNodeData.NodeState.VISITED:
			btn.disabled = true
			btn.text = "%s%s\n(已通关)" % [icon_str, ndata.title]
			btn.modulate = Color.WHITE
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_theme_color_override("font_color", Color("#a4b0be"))
		else:
			btn.disabled = true
			btn.text = "%s%s\n(锁定)" % [icon_str, ndata.title]
			btn.modulate = Color(1, 1, 1, 0.90)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_theme_color_override("font_color", Color("#747d8c"))
		
		btn.pressed.connect(func(): _on_node_clicked(nid))
		nodes_container.add_child(btn)
		node_buttons[nid] = btn

func _on_node_clicked(nid: String) -> void:
	if event_modal.visible or not node_data_map.has(nid):
		return
	var ndata: MapNodeData = node_data_map[nid]["data"]
	if ndata.state != MapNodeData.NodeState.AVAILABLE:
		return
	GameState.current_node_id = nid
	match ndata.node_type:
		MapNodeData.NodeType.BATTLE, MapNodeData.NodeType.ELITE:
			GameState.pending_dialogue_id = ""
			GameState.pending_combat_data = {"enemies": [ndata.content_id], "is_boss": false}
			SceneManager.change_scene(SceneManager.TargetScene.COMBAT)
		MapNodeData.NodeType.BOSS, MapNodeData.NodeType.STORY:
			GameState.pending_dialogue_id = ndata.content_id
			SceneManager.change_scene(SceneManager.TargetScene.STORY)
		_:
			_show_event_modal("校园补给", "在休息区整理了一下书包。\n体力已恢复，继续今天的行程吧。")
			GameState.reset_player_hp()
			GameState.mark_node_visited(nid)

func _show_event_modal(title_str: String, desc_str: String) -> void:
	event_title.text = title_str
	event_desc.text = desc_str
	event_modal.visible = true
	DaylightUI.polish(event_modal)
	event_confirm.grab_focus()

func _on_reset_route_pressed() -> void:
	GameState.begin_phase_two_chapter()
	_refresh_node_states()
	_update_ui()

func _on_retreat_pressed() -> void:
	SceneManager.change_scene(SceneManager.TargetScene.HOME)


func _ready_material_exploration() -> void:
	theme = DaylightUI.get_theme()
	event_modal.visible = false
	event_confirm.pressed.connect(_on_material_event_confirmed)
	retreat_button.text = "稍后继续"
	retreat_button.pressed.connect(_on_material_pause)
	pause_button = retreat_button
	reset_route_btn = Button.new()
	reset_route_btn.name = "WithdrawExploration"
	reset_route_btn.text = "撤离路线"
	reset_route_btn.pressed.connect(_on_material_retreat)
	$TopBar.add_child(reset_route_btn)
	var background := $Background as TextureRect
	var background_path: String = "res://assets/backgrounds/phase_three/exploration_campus_wide.png"
	if not ResourceLoader.exists(background_path):
		background_path = "res://assets/backgrounds/phase_three/exploration_campus.png"
	if ResourceLoader.exists(background_path): background.texture = load(background_path) as Texture2D
	var canvas := $ScrollContainer/MapCanvas as Control
	_material_surface = Panel.new()
	_material_surface.name = "MaterialRouteBoard"
	_material_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material_surface.add_theme_stylebox_override("panel", SceneSkin.style("route_board", Vector4(64, 64, 64, 64)))
	canvas.add_child(_material_surface)
	canvas.move_child(_material_surface, 0)
	for layer in range(6):
		var label := _material_label(canvas, "Station%d" % layer, "终点" if layer == 5 else "第 %d 站" % (layer + 1), 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_material_totals = _material_label(canvas, "MaterialTotals", "", 26)
	_material_progress = _material_label(canvas, "MaterialProgress", "", 28)
	_material_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_material_feedback = _material_label(self, "MaterialFeedback", "选好方向，再从容出发。", 28)
	_material_backdrop = ColorRect.new()
	_material_backdrop.name = "MaterialEventBackdrop"
	_material_backdrop.color = Color(0.23, 0.23, 0.28, 0.44)
	_material_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_material_backdrop.visible = false
	add_child(_material_backdrop)
	move_child(_material_backdrop, event_modal.get_index())
	_material_choices = HBoxContainer.new()
	_material_choices.name = "MaterialEventChoices"
	_material_choices.add_theme_constant_override("separation", 40)
	$EventModal/VBox.add_child(_material_choices)
	$EventModal/VBox.move_child(_material_choices, event_confirm.get_index())
	var close := Button.new()
	close.name = "CloseMaterialEvent"
	close.text = "×"
	close.add_theme_font_size_override("font_size", 32)
	close.pressed.connect(_hide_material_event)
	event_modal.add_child(close)
	DaylightUI.bind_button_feedback(close)
	DaylightUI.bind_button_feedback(retreat_button)
	DaylightUI.bind_button_feedback(reset_route_btn)
	DaylightUI.bind_button_feedback(event_confirm)
	refs = {"route_board": _material_surface, "lines": lines_canvas, "pause_button": pause_button, "retreat_button": reset_route_btn, "event_confirm": event_confirm, "event_choice_buttons": event_choice_buttons, "node_buttons": node_buttons, "event_close": close}
	GameState.exploration_changed.connect(_schedule_material_refresh)
	GameState.player_stats_changed.connect(_update_material_ui)
	GameState.materials_changed.connect(_update_material_ui)
	DaylightUI.apply(self)
	event_title.add_theme_font_size_override("font_size", 48)
	event_title.custom_minimum_size.y = 64
	event_desc.add_theme_font_size_override("normal_font_size", 28)
	event_desc.add_theme_font_size_override("bold_font_size", 28)
	event_desc.custom_minimum_size.y = 112
	event_desc.scroll_active = false
	event_confirm.custom_minimum_size.y = 88
	event_confirm.add_theme_font_size_override("font_size", 28)
	_update_material_ui()
	layout_exploration_map()
	_refresh_material_nodes()
	if GameState.exploration_state.get("stage", "") == "event": _show_material_event()

func layout_exploration_map() -> void:
	if not material_exploration_mode or not is_instance_valid(_material_surface): return
	var extent: Vector2 = size
	DaylightUI.place($TopBar, 140, 24, extent.x - 280, 110)
	$TopBar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	DaylightUI.place(chapter_title, 20, 0, extent.x - 840, 70)
	chapter_title.add_theme_font_size_override("font_size", 48)
	DaylightUI.place($TopBar/PlayerInfo, 28, 72, 800, 40)
	hp_label.add_theme_font_size_override("font_size", 28)
	scrap_label.add_theme_font_size_override("font_size", 28)
	DaylightUI.place(retreat_button, extent.x - 730, 22, 190, 72)
	DaylightUI.place(reset_route_btn, extent.x - 520, 22, 210, 72)
	for button in [retreat_button, reset_route_btn]: button.add_theme_font_size_override("font_size", 28)
	var scroll := $ScrollContainer as ScrollContainer
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DaylightUI.place(scroll, 160, 150, 1600, 800)
	var canvas := $ScrollContainer/MapCanvas as Control
	canvas.custom_minimum_size = Vector2(1600, 800)
	canvas.size = Vector2(1600, 800)
	DaylightUI.place(_material_surface, 0, 0, 1600, 800)
	for layer in range(6): DaylightUI.place(canvas.get_node("Station%d" % layer), 46 + layer * 272, 44, 148, 48)
	DaylightUI.place(_material_totals, 64, 706, 1090, 44)
	DaylightUI.place(_material_progress, 1160, 706, 370, 44)
	DaylightUI.place(_material_feedback, 180, 970, 1540, 54)
	DaylightUI.place(_material_backdrop, 0, 0, extent.x, extent.y)
	DaylightUI.place(event_modal, (extent.x - 1000) / 2.0, (extent.y - 480) / 2.0, 1000, 480)
	event_modal.add_theme_stylebox_override("panel", SceneSkin.style("exploration_panel", Vector4(64, 64, 64, 64)))
	DaylightUI.place($EventModal/VBox, 80, 58, 840, 370)
	$EventModal/VBox.add_theme_constant_override("separation", 22)
	DaylightUI.place(event_modal.get_node("CloseMaterialEvent"), 910, 26, 64, 64)

func _schedule_material_refresh() -> void:
	if _material_refresh_pending: return
	_material_refresh_pending = true
	_refresh_material_view.call_deferred()

func _refresh_material_view() -> void:
	_material_refresh_pending = false
	_update_material_ui()
	_refresh_material_nodes()

func _update_material_ui() -> void:
	if not material_exploration_mode: return
	var state: Dictionary = GameState.exploration_state
	var dungeon: Dictionary = ExplorationContent.dungeon_definition(str(state.get("dungeon_id", "")))
	chapter_title.text = "%s · %s" % [dungeon.get("title", "校园探索"), dungeon.get("difficulty", "")]
	hp_label.text = "体力 %d / %d" % [GameState.player_current_hp, GameState.player_max_hp]
	scrap_label.text = "练习点 %d" % GameState.scrap_metal
	var materials: Dictionary = GameState.exploration_materials
	_material_totals.text = "普通材料 %d    精良材料 %d    稀有材料 %d" % [materials.get("common", 0), materials.get("fine", 0), materials.get("rare", 0)]
	_material_progress.text = "已走过 %d / 6 站" % state.get("visited", []).size()
	var result: Dictionary = state.get("last_result", {})
	_material_feedback.text = "选好方向，再从容出发。" if result.is_empty() else ExplorationContent.reward_text(result.get("reward", {}))
	if int(result.get("heal", 0)) > 0: _material_feedback.text += " · 恢复 %d 体力" % int(result["heal"])

func _refresh_material_nodes() -> void:
	node_data_map.clear()
	var state: Dictionary = GameState.exploration_state
	var visited: Array = state.get("visited", [])
	var available: Array[String] = GameState.get_exploration_available_nodes()
	current_active_node_id = str(state.get("current_node_id", ""))
	for definition in state.get("nodes", []):
		var node := MapNodeData.new()
		node.node_id = str(definition["id"])
		node.layer_index = int(definition["layer"])
		node.node_type = int(definition["type"]) as MapNodeData.NodeType
		node.title = str(definition["title"])
		node.description = str(definition["description"])
		node.connected_next_node_ids = definition.get("next", []).duplicate()
		node.state = MapNodeData.NodeState.VISITED if visited.has(node.node_id) else (MapNodeData.NodeState.AVAILABLE if available.has(node.node_id) else MapNodeData.NodeState.LOCKED)
		var point := Vector2(120 + node.layer_index * 272, 410 if node.layer_index == 5 else (260 if int(definition["branch"]) == 0 else 550))
		node_data_map[node.node_id] = {"data": node, "pos": point, "definition": definition, "line_half_extent": Vector2(70, 62)}
	for child in nodes_container.get_children():
		nodes_container.remove_child(child)
		child.queue_free()
	node_buttons.clear()
	lines_canvas.call("set_map_data", node_data_map)
	for node_id in node_data_map:
		var entry: Dictionary = node_data_map[node_id]
		var node: MapNodeData = entry["data"]
		var button := Button.new()
		button.name = "MaterialNode_" + str(node_id)
		button.custom_minimum_size = Vector2(128, 112)
		button.focus_mode = Control.FOCUS_ALL
		button.set_meta("node_id", node_id)
		var tile_key: String = "node_battle"
		match node.node_type:
			MapNodeData.NodeType.ELITE, MapNodeData.NodeType.BOSS: tile_key = "node_elite"
			MapNodeData.NodeType.CHEST, MapNodeData.NodeType.EVENT: tile_key = "node_cache"
			MapNodeData.NodeType.REST: tile_key = "node_rest"
		for style_state in ["normal", "hover", "pressed", "disabled"]:
			var tint: Color = Color(1.02, 1.01, 1.04) if style_state == "hover" else (Color(0.94, 0.96, 0.97) if style_state == "pressed" else Color.WHITE)
			button.add_theme_stylebox_override(style_state, SceneSkin.style(tile_key, Vector4.ZERO, tint))
		var selected: bool = GameState.exploration_active and state.get("current_node_id", "") == node_id and state.get("stage", "") in ["event", "combat"]
		button.disabled = node.state != MapNodeData.NodeState.AVAILABLE and not selected
		button.modulate = Color.WHITE if not button.disabled else Color(1, 1, 1, 0.62 if node.state == MapNodeData.NodeState.VISITED else 0.30)
		nodes_container.add_child(button)
		var point: Vector2 = entry["pos"] - Vector2(64, 56)
		DaylightUI.place(button, point.x, point.y, 128, 112)
		var label := _material_label(nodes_container, "Title_" + str(node_id), node.title, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", DaylightUI.MUTED if button.disabled else DaylightUI.INK)
		DaylightUI.place(label, point.x - 30, point.y + 118, 188, 36)
		var caption: String = "继续" if selected else ("可前往" if node.state == MapNodeData.NodeState.AVAILABLE else ("已完成" if node.state == MapNodeData.NodeState.VISITED else ""))
		var status := _material_label(nodes_container, "Status_" + str(node_id), caption, 24)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		DaylightUI.place(status, point.x - 16, point.y + 156, 160, 36)
		button.pressed.connect(_on_material_node_clicked.bind(str(node_id)))
		DaylightUI.bind_button_feedback(button)
		node_buttons[node_id] = button

func _on_material_node_clicked(node_id: String) -> void:
	if event_modal.visible or not node_buttons.has(node_id) or node_buttons[node_id].disabled: return
	if GameState.exploration_state.get("current_node_id", "") == node_id:
		if GameState.exploration_state.get("stage", "") == "event": _show_material_event()
		elif GameState.is_exploration_combat(): GameState.start_exploration(str(GameState.exploration_state["dungeon_id"]))
		return
	if GameState.choose_exploration_node(node_id) and GameState.exploration_state.get("stage", "") == "event": _show_material_event()

func _show_material_event() -> void:
	var node: Dictionary = GameState.get_exploration_node(str(GameState.exploration_state.get("current_node_id", "")))
	if node.is_empty() or GameState.exploration_state.get("stage", "") != "event": return
	event_title.text = str(node["title"])
	event_desc.text = str(node["description"])
	if int(node.get("heal", 0)) > 0: event_desc.text += "\n恢复 %d 体力。" % int(node["heal"])
	if int(node["type"]) != MapNodeData.NodeType.EVENT: event_desc.text += "\n" + ExplorationContent.reward_text(node.get("reward", {}))
	for child in _material_choices.get_children(): child.queue_free()
	event_choice_buttons.clear()
	var choices: Array = node.get("choices", [])
	_material_choices.visible = not choices.is_empty()
	event_confirm.visible = choices.is_empty()
	for choice in choices:
		var choice_id: String = str(choice["id"])
		var button := Button.new()
		button.name = "Choice_" + choice_id
		button.text = str(choice["title"])
		button.custom_minimum_size = Vector2(400, 96)
		button.theme_type_variation = &"PrimaryButton" if choice_id == "organize" else &"SecondaryButton"
		button.add_theme_font_size_override("font_size", 28)
		button.focus_mode = Control.FOCUS_ALL
		_material_choices.add_child(button)
		button.pressed.connect(_on_material_choice.bind(choice_id))
		DaylightUI.bind_button_feedback(button)
		event_choice_buttons[choice_id] = button
	_material_backdrop.visible = true
	event_modal.visible = true
	if choices.is_empty(): event_confirm.grab_focus()
	elif event_choice_buttons.has("organize"): event_choice_buttons["organize"].grab_focus()

func _on_material_event_confirmed() -> void:
	_on_material_choice("victory")

func _on_material_choice(choice_id: String) -> void:
	if not event_modal.visible: return
	if not GameState.complete_exploration_node(str(GameState.exploration_state.get("current_node_id", "")), choice_id): return
	_hide_material_event()
	_refresh_material_view()
	for node_id in GameState.get_exploration_available_nodes():
		if node_buttons.has(node_id): node_buttons[node_id].grab_focus(); break

func _hide_material_event() -> void:
	event_modal.visible = false
	_material_backdrop.visible = false
	var node_id: String = str(GameState.exploration_state.get("current_node_id", ""))
	if node_buttons.has(node_id) and not node_buttons[node_id].disabled: node_buttons[node_id].grab_focus()

func _on_material_pause() -> void:
	GameState.pause_exploration()

func _on_material_retreat() -> void:
	if not event_modal.visible: GameState.retreat_exploration()

func _input(event: InputEvent) -> void:
	if not material_exploration_mode: return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if event_modal.visible: _hide_material_event()
		else: _on_material_pause()
		get_viewport().set_input_as_handled()

func _material_label(parent: Control, node_name: String, copy: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", DaylightUI.body_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", DaylightUI.INK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label
