class_name ParallaxCutsceneStage
extends Control

## Reusable 2-layer parallax camera push stage (2340x1080 wide backdrop + 1920x1080 foreground).
const DESIGN := Vector2(1920.0, 1080.0)
const PRESETS := {
	"dusk_corridor": {
		"bg_path": "res://assets/backgrounds/cutscenes/cutscene_pilot_bg.png",
		"fg_path": "res://assets/backgrounds/cutscenes/cutscene_pilot_fg_char.png",
		"duration": 2.4,
		"bg_size": Vector2(2340.0, 1080.0),
		"bg_start": Vector2(-210.0, 0.0),
		"bg_end": Vector2(-286.0, 0.0),
		"bg_pivot_screen": Vector2(960.0, 540.0),
		"bg_scale": Vector2(1.0, 1.04),
		"fg_size": Vector2(1920.0, 1080.0),
		"fg_start": Vector2(0.0, 0.0),
		"fg_end": Vector2(-56.0, 0.0),
		"fg_pivot_screen": Vector2(1180.0, 0.0),
		"fg_scale": Vector2(1.0, 1.09)
	}
}

var preset_id := "dusk_corridor"
var bg_layer: TextureRect
var fg_layer: TextureRect
var _spec: Dictionary = {}
var _tween: Tween
var _progress: float = 0.0
var _edge_material: ShaderMaterial

static func create(id: String = "dusk_corridor", auto_play: bool = true) -> ParallaxCutsceneStage:
	var stage := ParallaxCutsceneStage.new()
	stage.preset_id = id
	stage._auto_play = auto_play
	return stage

var _auto_play: bool = true

func _ready() -> void:
	name = "ParallaxCutsceneStage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = DESIGN
	_build()
	resized.connect(_apply_transforms)
	if _auto_play:
		play(true)

func background_texture() -> Texture2D:
	return bg_layer.texture if is_instance_valid(bg_layer) else null

func configure(id: String = "dusk_corridor", auto_play: bool = true) -> void:
	preset_id = id
	_auto_play = auto_play
	_build()
	if _auto_play:
		play(true)

func play(from_start: bool = true) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if from_start:
		set_progress(0.0)
	if SaveManager.settings.get("reduced_motion", false):
		set_progress(0.0)
		return
	var duration := float(_spec.get("duration", 2.4))
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(set_progress, _progress, 1.0, duration)

func set_progress(t: float) -> void:
	_progress = clampf(t, 0.0, 1.0)
	_apply_transforms()

func _build() -> void:
	_spec = PRESETS.get(preset_id, PRESETS["dusk_corridor"])
	if is_instance_valid(bg_layer):
		bg_layer.queue_free()
	if is_instance_valid(fg_layer):
		fg_layer.queue_free()

	bg_layer = TextureRect.new()
	bg_layer.name = "CutsceneBgLayer"
	bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_layer.stretch_mode = TextureRect.STRETCH_SCALE
	bg_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg_layer.size = _spec["bg_size"]
	if ResourceLoader.exists(str(_spec["bg_path"])):
		bg_layer.texture = load(str(_spec["bg_path"])) as Texture2D
	add_child(bg_layer)

	fg_layer = TextureRect.new()
	fg_layer.name = "CutsceneFgLayer"
	fg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fg_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fg_layer.stretch_mode = TextureRect.STRETCH_SCALE
	fg_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fg_layer.size = _spec["fg_size"]
	if ResourceLoader.exists(str(_spec["fg_path"])):
		fg_layer.texture = load(str(_spec["fg_path"])) as Texture2D
	add_child(fg_layer)

	_apply_transforms()

func _apply_transforms() -> void:
	if _spec.is_empty() or not is_instance_valid(bg_layer) or not is_instance_valid(fg_layer):
		return
	var vp := get_viewport_rect().size
	var aspect := (vp.x / vp.y) if vp.y > 0.0 else (16.0 / 9.0)
	var wide := aspect > 1.82
	var visible_design_w := DESIGN.y * aspect if wide else DESIGN.x
	var bg_size: Vector2 = _spec["bg_size"]
	var bg_start: Vector2 = _spec["bg_start"]
	var bg_end: Vector2 = _spec["bg_end"]
	var bg_pos := bg_start.lerp(bg_end, _progress)
	var bg_pivot_screen: Vector2 = _spec["bg_pivot_screen"]
	var bg_scale_pair: Vector2 = _spec["bg_scale"]
	var bg_s := lerpf(bg_scale_pair.x, bg_scale_pair.y, _progress)
	if wide:
		# Cover ultra-wide viewports (e.g. 20:9) so shifted camera never reveals margins.
		var min_factor := (visible_design_w + 170.0) / bg_size.x
		bg_s *= maxf(1.0, min_factor)
	bg_layer.size = bg_size
	bg_layer.position = bg_pos
	bg_layer.pivot_offset = bg_pivot_screen - bg_start
	bg_layer.scale = Vector2.ONE * bg_s

	var fg_size: Vector2 = _spec["fg_size"]
	var fg_start: Vector2 = _spec["fg_start"]
	var fg_end: Vector2 = _spec["fg_end"]
	var fg_pos := fg_start.lerp(fg_end, _progress)
	var fg_pivot_screen: Vector2 = _spec["fg_pivot_screen"]
	var fg_scale_pair: Vector2 = _spec["fg_scale"]
	var fg_s := lerpf(fg_scale_pair.x, fg_scale_pair.y, _progress)
	fg_layer.size = fg_size
	fg_layer.position = fg_pos
	fg_layer.pivot_offset = fg_pivot_screen - fg_start
	fg_layer.scale = Vector2.ONE * fg_s
	if wide:
		if _edge_material == null:
			_edge_material = ShaderMaterial.new()
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE, UV); float fade = smoothstep(0.0, 0.045, UV.x) * smoothstep(1.0, 0.955, UV.x); COLOR = vec4(c.rgb, c.a * fade); }"
			_edge_material.shader = shader
		fg_layer.material = _edge_material
	else:
		fg_layer.material = null

