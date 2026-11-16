class_name CombatSkin
extends RefCounted

const PAPER_PATH := "res://assets/ui_core/theme/paper_modal_9slice.png"
const FALLBACK_PAPER_PATH := "res://assets/ui/phase_three/battle_paper.png"
const CARD_BACK_DUEL_PATH := "res://assets/combat/card_back_duel.png"
static var _paper: Texture2D
static var _paper_is_modal_slice: bool = false
static var _actors: Dictionary = {}

static func character_combat_path(actor_id: String) -> String:
	var actual := str({"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi"}.get(actor_id, actor_id))
	if actual == "ye_zhou":
		return "res://assets/sprites/characters/phase_three/combat/ye_zhou_idle.png"
	var p := "res://assets/sprites/characters/phase_three/combat/combat_%s_idle.png" % actual
	return p if ResourceLoader.exists(p) else ""

static func character_cutin_path(actor_id: String) -> String:
	var actual := str({"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi"}.get(actor_id, actor_id))
	var p := "res://assets/sprites/characters/phase_three/cutin/%s_cutin.png" % actual
	return p if ResourceLoader.exists(p) else character_combat_path(actual)

static func enemy_combat_path(enemy_id: String) -> String:
	if enemy_id == "liu_yu_long_duel":
		return character_combat_path("liu_yu_long")
	var target_id := "ch1_hunter_mech" if enemy_id in ["principal", "boss_frank", "ch1_hunter_mech"] else enemy_id
	var p := "res://assets/sprites/enemies/phase_three/enemy_%s.png" % target_id
	if ResourceLoader.exists(p):
		return p
	if target_id == "ch1_hunter_mech":
		var fallback := "res://assets/sprites/enemies/phase_three/enemy_alliance_operative.png"
		if ResourceLoader.exists(fallback):
			return fallback
	return PhaseTwoContent.character_path(target_id)

static func enemy_needs_flip_h(enemy_id: String) -> bool:
	return enemy_id in ["drone", "preacher", "liu_yu_long_duel"]

static func platform_texture(overclock: bool) -> Texture2D:
	var key := "redmoon" if overclock else "day"
	var p := "res://assets/ui_core/theme/combat_stage_platform_%s.png" % key
	return load(p) as Texture2D if ResourceLoader.exists(p) else null

static func card_back_texture() -> Texture2D:
	return load(CARD_BACK_DUEL_PATH) as Texture2D if ResourceLoader.exists(CARD_BACK_DUEL_PATH) else null

static func actor_texture(path: String) -> Texture2D:
	if _actors.has(path): return _actors[path]
	var source := load(path) as Texture2D
	if source == null: return null
	var image := source.get_image()
	if image.is_compressed(): image.decompress()
	var used := image.get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = used
	atlas.filter_clip = true
	_actors[path] = atlas
	return atlas

static func paper(inset: Vector4 = Vector4(18, 16, 18, 16), tint: Color = Color.WHITE) -> StyleBox:
	if _paper == null:
		if ResourceLoader.exists(PAPER_PATH):
			_paper = load(PAPER_PATH) as Texture2D
			_paper_is_modal_slice = _paper != null
		elif ResourceLoader.exists(FALLBACK_PAPER_PATH):
			_paper = load(FALLBACK_PAPER_PATH) as Texture2D
			_paper_is_modal_slice = false
	if _paper:
		var box := StyleBoxTexture.new()
		box.texture = _paper
		box.modulate_color = tint
		if _paper_is_modal_slice:
			box.set_texture_margin(SIDE_LEFT, 72)
			box.set_texture_margin(SIDE_TOP, 72)
			box.set_texture_margin(SIDE_RIGHT, 48)
			box.set_texture_margin(SIDE_BOTTOM, 48)
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				box.set_expand_margin(side, 6)
		else:
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				box.set_texture_margin(side, 48)
				box.set_expand_margin(side, 8)
		box.content_margin_left = inset.x
		box.content_margin_top = inset.y
		box.content_margin_right = inset.z
		box.content_margin_bottom = inset.w
		return box
	return flat(Color("#FFF9F0"), inset)

static func flat(fill: Color, inset: Vector4 = Vector4(16, 10, 16, 10)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color("#C8BCA9")
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = inset.x
	box.content_margin_top = inset.y
	box.content_margin_right = inset.z
	box.content_margin_bottom = inset.w
	return box

static func button(button_node: Button, primary: bool = false) -> void:
	var base := Color("#D66B5A") if primary else Color("#EFE6D5")
	var border := Color("#B95343") if primary else Color("#C8BCA9")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := flat(base, Vector4(16, 10, 16, 10))
		style.border_color = border
		if state == "hover":
			style.bg_color = base.lightened(0.06) if primary else base.darkened(0.05)
		elif state in ["pressed", "hover_pressed"]:
			style.bg_color = base.darkened(0.10)
		elif state == "disabled":
			style.bg_color = Color("#DCD5C7")
			style.border_color = Color("#C4BCAD")
		button_node.add_theme_stylebox_override(state, style)
	button_node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := Color("#FFFDF8") if primary else Color("#303A67")
	for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button_node.add_theme_color_override(color_key, ink)
	button_node.add_theme_color_override("font_disabled_color", Color("#6C7280"))
	SchoolObjectUI.borderless(button_node)
	DaylightUI.bind_button_feedback(button_node)
