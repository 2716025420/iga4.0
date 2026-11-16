class_name CombatVFX
extends RefCounted

const ROOT := "res://assets/ui_core/vfx/"
const SHEETS := {
	"slash": ROOT + "vfx_card_slash_4x2.png",
	"shield": ROOT + "vfx_shield_burst_4x2.png",
	"heal": ROOT + "vfx_heal_breeze_4x2.png",
	"pack": ROOT + "vfx_pack_open_burst_4x2.png",
	"debuff": ROOT + "vfx_debuff_glitch_4x2.png",
	"companion_assist": ROOT + "vfx_companion_assist_4x2.png",
	"overclock_redmoon": ROOT + "vfx_overclock_redmoon_4x2.png",
	"counter_reflect": ROOT + "vfx_counter_reflect_4x2.png",
	"target_reticle": ROOT + "vfx_target_reticle_4x2.png",
	"pack_tear": "res://assets/ui_core/animations/ui_pack_tear_4x2.png",
	"crystal_shimmer": "res://assets/ui_core/animations/anim_crystal_stasis_shimmer_4x2.png"
}
const EFFECT_SPECS := {
	"slash": {"fps": 14.0, "start_idx": 1},
	"shield": {"fps": 14.0, "start_idx": 1},
	"heal": {"fps": 14.0, "start_idx": 1},
	"pack": {"fps": 14.0, "start_idx": 1},
	"debuff": {"fps": 12.0, "start_idx": 0},
	"companion_assist": {"fps": 14.0, "start_idx": 0},
	"overclock_redmoon": {"fps": 14.0, "start_idx": 0},
	"counter_reflect": {"fps": 12.0, "start_idx": 0},
	"target_reticle": {"fps": 10.0, "start_idx": 0},
	"pack_tear": {"fps": 14.0, "start_idx": 0},
	"crystal_shimmer": {"fps": 8.0, "start_idx": 0}
}
const SVG_CORNER_BRACKET := ROOT + "svg_corner_bracket.svg"
const SVG_ARROW_SWEEP := ROOT + "svg_arrow_sweep.svg"
const SVG_DUEL_CREST_VS := ROOT + "svg_duel_crest_vs.svg"
const SVG_RED_MOON_RETICLE := ROOT + "svg_red_moon_reticle.svg"
const COLUMNS := 4
const ROWS := 2
const FPS := 14.0

static var _frames_cache: Dictionary = {}

static func frames_for(key: String) -> Array[AtlasTexture]:
	if _frames_cache.has(key):
		return _frames_cache[key]
	var path: String = str(SHEETS.get(key, ""))
	var list: Array[AtlasTexture] = []
	if path != "" and ResourceLoader.exists(path):
		var sheet := load(path) as Texture2D
		if sheet != null:
			var frame_w := float(sheet.get_width()) / float(COLUMNS)
			var frame_h := float(sheet.get_height()) / float(ROWS)
			for row in ROWS:
				for col in COLUMNS:
					var frame := AtlasTexture.new()
					frame.atlas = sheet
					frame.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
					frame.filter_clip = true
					list.append(frame)
	_frames_cache[key] = list
	return list

static func play_burst(anchor: Control, effect_key: String, global_center: Vector2, extent: Vector2 = Vector2(260, 260), z_layer: int = 45) -> TextureRect:
	if not is_instance_valid(anchor):
		return null
	var frames := frames_for(effect_key)
	if frames.is_empty():
		return null
	var rect := TextureRect.new()
	rect.name = "VFX_" + effect_key
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.z_index = z_layer
	rect.size = extent
	anchor.add_child(rect)
	var local_center := anchor.get_global_transform().affine_inverse() * global_center
	rect.position = local_center - extent * 0.5

	var spec: Dictionary = EFFECT_SPECS.get(effect_key, {"fps": FPS, "start_idx": 1})
	var effect_fps := float(spec.get("fps", FPS))
	var reduced := bool(SaveManager.settings.get("reduced_motion", false))
	if reduced:
		rect.texture = frames[mini(3, frames.size() - 1)]
		rect.modulate = Color(1.0, 1.0, 1.0, 0.78)
		var flash := rect.create_tween()
		flash.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		flash.tween_property(rect, "modulate:a", 0.0, 0.16)
		flash.tween_callback(rect.queue_free)
		return rect

	var start_idx := mini(int(spec.get("start_idx", 1)), maxi(0, frames.size() - 1))
	rect.texture = frames[start_idx]
	var count := frames.size()
	var active_frames := maxi(1, count - start_idx)
	var duration := float(active_frames) / maxf(1.0, effect_fps)
	var tween := rect.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(step: float):
		if is_instance_valid(rect):
			var idx := clampi(int(floorf(step)), start_idx, count - 1)
			rect.texture = frames[idx]
			if idx >= count - 2:
				rect.modulate.a = clampf(1.0 - float(idx - (count - 3)) * 0.35, 0.25, 1.0)
	, float(start_idx), float(count) - 0.01, duration)
	tween.tween_callback(rect.queue_free)
	return rect

static func play_loop(parent: Control, effect_key: String, region: Rect2, alpha: float = 0.85, z_layer: int = 2) -> TextureRect:
	if not is_instance_valid(parent):
		return null
	var frames := frames_for(effect_key)
	if frames.is_empty():
		return null
	var rect := TextureRect.new()
	rect.name = "LoopVFX_" + effect_key
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.z_index = z_layer
	rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	parent.add_child(rect)
	DaylightUI.place(rect, region.position.x, region.position.y, region.size.x, region.size.y)
	var spec: Dictionary = EFFECT_SPECS.get(effect_key, {"fps": 8.0, "start_idx": 0})
	if bool(SaveManager.settings.get("reduced_motion", false)):
		rect.texture = frames[mini(2, frames.size() - 1)]
		return rect
	var start_idx := mini(int(spec.get("start_idx", 0)), maxi(0, frames.size() - 1))
	var count := frames.size()
	var effect_fps := float(spec.get("fps", 8.0))
	var duration := float(maxi(1, count - start_idx)) / maxf(1.0, effect_fps)
	rect.texture = frames[start_idx]
	var tween := rect.create_tween()
	tween.set_loops()
	tween.tween_method(func(step: float):
		if is_instance_valid(rect):
			rect.texture = frames[clampi(int(floorf(step)), start_idx, count - 1)]
	, float(start_idx), float(count) - 0.01, duration)
	return rect
