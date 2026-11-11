class_name CombatSkin
extends RefCounted

const PAPER_PATH := "res://assets/ui/phase_three/battle_paper.png"
static var _paper: Texture2D
static var _actors: Dictionary = {}

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
	if _paper == null and ResourceLoader.exists(PAPER_PATH): _paper = load(PAPER_PATH) as Texture2D
	if _paper:
		var box := StyleBoxTexture.new()
		box.texture = _paper
		box.modulate_color = tint
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
	box.border_color = Color("#CEC8DA")
	box.set_border_width_all(1)
	box.set_corner_radius_all(16)
	box.content_margin_left = inset.x
	box.content_margin_top = inset.y
	box.content_margin_right = inset.z
	box.content_margin_bottom = inset.w
	return box

static func button(button_node: Button, primary: bool = false) -> void:
	var fill := Color("#DFD6EE") if primary else Color("#FFF9F0")
	button_node.add_theme_stylebox_override("normal", flat(fill))
	button_node.add_theme_stylebox_override("hover", flat(fill.lightened(0.07)))
	button_node.add_theme_stylebox_override("pressed", flat(fill.darkened(0.05)))
	button_node.add_theme_stylebox_override("disabled", flat(Color("#E8E5E2")))
	button_node.add_theme_color_override("font_disabled_color", DaylightUI.MUTED)
	DaylightUI.bind_button_feedback(button_node)
