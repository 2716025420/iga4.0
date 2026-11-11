class_name SpecialCardCollection
extends RefCounted

## Permanent, non-exchangeable story badges. No shop/deck/transfer operations exist.
static func empty_state() -> Dictionary:
	return {"collected":[],"events":{}}

static func valid_state(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2 or not value.get("collected") is Array or value["collected"].size() > 12: return false
	var unique := {}
	for id in value["collected"]:
		if not id is String or not ZodiacCatalog.known(id) or unique.has(id): return false
		unique[id] = true
	if not value.get("events") is Dictionary or value["events"].size() > 256: return false
	for event_id in value["events"]:
		if not event_id is String or event_id.strip_edges() == "" or event_id.length() > 120: return false
		var id: Variant = value["events"][event_id]
		if not id is String or not ZodiacCatalog.known(id) or not unique.has(id): return false
	return true

static func snapshot() -> Dictionary:
	return GameState.player_profile.get("zodiac_collection",empty_state()).duplicate(true)

static func collected(id: String) -> bool:
	return snapshot()["collected"].has(id)

static func acquire_from_story(id: String, event_id: String) -> bool:
	if not ZodiacCatalog.known(id) or event_id.strip_edges() == "" or event_id.length() > 120: return false
	var state := snapshot()
	if not valid_state(state) or state["collected"].has(id) or state["events"].has(event_id) or state["events"].size() >= 256: return false
	state["collected"].append(id)
	state["events"][event_id] = id
	GameState.player_profile["zodiac_collection"] = state
	GameState.profile_changed.emit()
	return true

static func key_progress() -> Dictionary:
	var state := snapshot()
	var missing: Array[String] = []
	for id in ZodiacCatalog.ORDER:
		if id != "magician" and not state["collected"].has(id): missing.append(id)
	return {"missing":missing,"other_collected":11-missing.size(),"has_key":state["collected"].has("magician"),"ready":missing.is_empty() and state["collected"].has("magician")}
