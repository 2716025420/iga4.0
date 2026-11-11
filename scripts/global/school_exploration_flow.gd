class_name SchoolExplorationFlow
extends RefCounted

static func enabled() -> bool:
	return int(GameState.exploration_state.get("layout_version", 0)) == 2

static func migrate_pending() -> void:
	var state: Dictionary = GameState.exploration_state
	if enabled() or state.is_empty() or state.get("status", "") not in ["running", "paused"]: return
	var previous_nodes: Array = state.get("nodes", []).duplicate(true)
	var active_id := str(state.get("current_node_id", ""))
	var depth := 0
	for old in previous_nodes:
		if state.get("visited", []).has(old.get("id", "")):
			depth = maxi(depth, int(old.get("layer", 0)) + 1)
	depth = mini(depth, SchoolExplorationRoutes.NORMAL_DEPTHS)
	var nodes := SchoolExplorationRoutes.generate(str(state["dungeon_id"]), int(state.get("seed", 0)), int(state["run_id"]))
	for old in previous_nodes:
		if str(old.get("id", "")) == active_id:
			var current: Dictionary = old.duplicate(true)
			current["kind"] = SchoolExplorationRoutes.kind_for(current)
			depth = SchoolExplorationRoutes.NORMAL_DEPTHS if current["kind"] == "boss" else clampi(int(current["layer"]), 0, SchoolExplorationRoutes.NORMAL_DEPTHS - 1)
			current["layer"] = depth
			nodes.append(current)
			break
	state["nodes"] = nodes
	state["layout_version"] = 2
	state["depth"] = depth
	state["boss_defeated"] = false
	state["dialogue_line"] = 0
	state["purchases"] = {}
	state["spent_points"] = 0

static func available_nodes() -> Array[String]:
	var ids: Array[String] = []
	var state: Dictionary = GameState.exploration_state
	if not GameState.exploration_active or state.get("status", "") != "running" or state.get("stage", "") != "map": return ids
	var depth := int(state.get("depth", 0))
	if depth > SchoolExplorationRoutes.NORMAL_DEPTHS and not state.get("boss_defeated", false): return ids
	for node in state.get("nodes", []):
		if int(node["layer"]) == depth and str(node["id"]).begins_with("r2_") and not state["settled"].has(node["id"]):
			ids.append(str(node["id"]))
	return ids

static func choose_node(node_id: String) -> bool:
	if SceneManager.is_transitioning or not available_nodes().has(node_id): return false
	var node := GameState.get_exploration_node(node_id)
	var state: Dictionary = GameState.exploration_state
	var kind := SchoolExplorationRoutes.kind_for(node)
	state["current_node_id"] = node_id
	state["stage"] = "combat" if not node.get("enemy_keys", []).is_empty() else ("dialogue" if kind == "story" else ("exit" if kind == "exit" else "encounter"))
	state["dialogue_line"] = 0
	state["hp"] = GameState.player_current_hp
	GameState.exploration_checkpoint.clear()
	GameState.exploration_changed.emit()
	if state["stage"] == "combat": SceneManager.change_scene(SceneManager.TargetScene.COMBAT)
	elif state["stage"] == "dialogue": SceneManager.change_scene(SceneManager.TargetScene.STORY)
	return true

static func checkpoint_dialogue(line: int) -> bool:
	var state: Dictionary = GameState.exploration_state
	if not enabled() or not GameState.exploration_active or state.get("stage", "") != "dialogue": return false
	var node := GameState.get_exploration_node(str(state["current_node_id"]))
	if SchoolExplorationRoutes.kind_for(node) != "story": return false
	state["dialogue_line"] = clampi(line, 0, SchoolExplorationRoutes.dialogue_lines(node).size())
	state["hp"] = GameState.player_current_hp
	GameState.exploration_changed.emit()
	return true

static func _award(reward: Dictionary, healing: int, show_notification: bool = true) -> int:
	var state: Dictionary = GameState.exploration_state
	var earned: Dictionary = state["earned"]
	var points := maxi(0, int(reward.get("scrap_metal", 0)))
	var received := {"practice_points":points}
	GameState.scrap_metal += points
	earned["scrap_metal"] = int(earned.get("scrap_metal", 0)) + points
	for quality in ["common", "fine", "rare"]:
		var amount := maxi(0, int(reward.get("materials", {}).get(quality, 0)))
		GameState.exploration_materials[quality] = int(GameState.exploration_materials.get(quality, 0)) + amount
		earned["materials"][quality] = int(earned["materials"].get(quality, 0)) + amount
		if amount > 0:
			GameState._record_inventory_acquisition("material_" + quality)
			received["material_" + quality] = amount
	var old_hp := GameState.player_current_hp
	if healing > 0: GameState.heal_player(healing)
	state["hp"] = GameState.player_current_hp
	GameState.notify_rewards(received,show_notification)
	return GameState.player_current_hp - old_hp

static func settle(node_id: String, outcome: String = "victory", show_notification: bool = true) -> bool:
	var state: Dictionary = GameState.exploration_state
	if not enabled() or not GameState.exploration_active or state.get("status", "") != "running" or state.get("current_node_id", "") != node_id or state["settled"].has(node_id): return false
	if state.get("stage", "") not in ["combat", "encounter", "event", "dialogue"]: return false
	if outcome in ["defeat", "failed"]: return finish("defeat")
	var node := GameState.get_exploration_node(node_id)
	if node.is_empty(): return false
	var kind := SchoolExplorationRoutes.kind_for(node)
	var reward: Dictionary = node.get("reward", {}).duplicate(true)
	var healing := int(node.get("heal", 0))
	if kind == "story":
		if int(state.get("dialogue_line", 0)) < SchoolExplorationRoutes.dialogue_lines(node).size(): return false
		if outcome != "victory": return false
	elif kind == "npc":
		var chosen: Dictionary = {}
		for choice in node.get("choices", []):
			if str(choice["id"]) == outcome: chosen = choice
		if chosen.is_empty(): return false
		reward = chosen.get("reward", {}).duplicate(true)
		healing = int(chosen.get("heal", 0))
	elif kind == "merchant":
		if outcome not in ["leave", "victory"]: return false
	elif outcome != "victory": return false
	state["settled"][node_id] = {"outcome": outcome, "reward": reward.duplicate(true)}
	state["visited"].append(node_id)
	var restored := _award(reward, healing, show_notification)
	state["last_result"] = {"node_id": node_id, "outcome": outcome, "reward": reward.duplicate(true), "heal": restored, "title": str(node["title"])}
	state["depth"] = int(node["layer"]) + 1
	if kind == "boss":
		state["boss_defeated"] = true
		state["depth"] = SchoolExplorationRoutes.NORMAL_DEPTHS + 1
	state["current_node_id"] = ""
	state["stage"] = "map"
	state["dialogue_line"] = 0
	GameState.exploration_checkpoint.clear()
	GameState.materials_changed.emit()
	GameState.exploration_changed.emit()
	return true

static func finish(outcome: String = "victory") -> bool:
	var state: Dictionary = GameState.exploration_state
	if state.get("status", "") not in ["running", "paused"]: return false
	if outcome == "victory":
		if not GameState.exploration_active or not state.get("boss_defeated", false) or state.get("stage", "") != "exit": return false
		var node := GameState.get_exploration_node(str(state.get("current_node_id", "")))
		if SchoolExplorationRoutes.kind_for(node) != "exit": return false
		state["settled"][node["id"]] = {"outcome": "exit", "reward": {}}
		state["visited"].append(node["id"])
	elif outcome not in ["defeat", "retreated"]: return false
	state["status"] = "completed" if outcome == "victory" else outcome
	state["stage"] = "finished"
	PlayerJourney.record_exploration()
	GameState.exploration_checkpoint.clear()
	GameState._leave_exploration_context()
	GameState.exploration_changed.emit()
	return true
