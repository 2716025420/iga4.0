class_name SceneStageLayers
extends Control

## 5-layer modular scene stage + realtime period lighting + optional 2340x1080 blueprint guide overlay.
## Layer 0: Shared Sky (day / dusk / redmoon)
## Layer 1: Clean Cel Midground Architecture & Path
## Layer 2: Dynamic Resident / Story Actors (Slot A + Slot B)
## Layer 3: Foreground Occluders (true alpha PNG or procedural geometry, hiding lower body naturally)
## Layer 4: Managed externally by SceneHUDLayout (dock, top-right bar, minimal NPC bubbles)

const DESIGN := Vector2(1920.0, 1080.0)
const WIDE_RECT := Rect2(-210.0, 0.0, 2340.0, 1080.0)
const WIDE_ORIGIN := Vector2(210.0, 0.0)
const WIDE_EXTEND_PAD := 180.0
const STAGED_ROOT := "res://assets/ui/scene_reset/staged/"
const WIDE_EXTEND_SHADER_CODE := """shader_type canvas_item;
uniform float pad_ratio = 0.06666667;
varying vec4 v_tint;
void vertex() {
	v_tint = COLOR;
}
void fragment() {
	float span = max(0.0001, 1.0 - 2.0 * pad_ratio);
	float mx = (UV.x - pad_ratio) / span;
	if (mx < 0.0) {
		mx = -mx;
	} else if (mx > 1.0) {
		mx = 2.0 - mx;
	}
	mx = clamp(mx, 0.0005, 0.9995);
	COLOR = texture(TEXTURE, vec2(mx, UV.y)) * v_tint;
}
"""
static var _wide_extend_shader: Shader

const SHARED_SKY_PATHS := {
	"day": STAGED_ROOT + "shared/sky_arete_day_wide.png",
	"dusk": STAGED_ROOT + "shared/sky_arete_dusk_wide.png",
	"redmoon": STAGED_ROOT + "shared/sky_arete_redmoon_wide.png"
}

const SCENE_BLUEPRINTS := {
	"dorm": {
		"stage_key": "dorm",
		"title": "学生宿舍",
		"indoor": true,
		"edge_day": "#EAE2D3",
		"edge_dusk": "#DEC7AE",
		"edge_night": "#232F47",
		"slot_a": {
			"mode": "standing",
			"rect": [1040, 299, 151, 559],
			"bubble_anchor": [1114, 299],
			"label": "SLOT A · 叶舟（阅读便签）"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [700, 300, 180, 540],
			"bubble_anchor": [790, 280],
			"label": "SLOT B · 宿舍预留位"
		},
		"occlusion_rects": [
			[1540, 480, 380, 600]
		],
		"occlusion_note": "右侧床铺近景"
	},
	"rooftop": {
		"stage_key": "rooftop",
		"title": "教学楼天台",
		"indoor": false,
		"edge_day": "#98D2F2",
		"edge_dusk": "#E5A577",
		"edge_night": "#1B2846",
		"slot_a": {
			"mode": "standing",
			"rect": [930, 250, 310, 710],
			"bubble_anchor": [1085, 215],
			"label": "SLOT A · 时段轮驻同伴"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [1360, 265, 300, 690],
			"bubble_anchor": [1510, 230],
			"label": "SLOT B · 谈心 / 主线事件位"
		},
		"occlusion_rects": [
			[1380, 770, 510, 310]
		],
		"occlusion_note": "前景原木遮阳桌边沿 + 天台近景花箱"
	},
	"shop": {
		"stage_key": "shop",
		"title": "校园商店",
		"indoor": true,
		"edge_day": "#EAE2D3",
		"edge_dusk": "#DECAB2",
		"edge_night": "#28334A",
		"slot_a": {
			"mode": "counter",
			"rect": [1155, 205, 495, 745],
			"bubble_anchor": [1402, 175],
			"label": "SLOT A · 唐小满（前景柜台遮挡腰部）"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [600, 270, 310, 690],
			"bubble_anchor": [755, 240],
			"label": "SLOT B · 预留来访同学站位"
		},
		"occlusion_rects": [
			[0, 660, 1920, 420]
		],
		"occlusion_note": "全宽前景原木收银柜台 y=660..1080（实时遮挡店员下半身）"
	},
	"gym": {
		"stage_key": "gym",
		"title": "体育馆",
		"indoor": true,
		"edge_day": "#DCE8F2",
		"edge_dusk": "#D7C9BA",
		"edge_night": "#23304A",
		"slot_a": {
			"mode": "standing",
			"rect": [1240, 260, 310, 700],
			"bubble_anchor": [1395, 225],
			"label": "SLOT A · 柳宇龙（木地板地坪线）"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [710, 285, 290, 650],
			"bubble_anchor": [855, 250],
			"label": "SLOT B · 选拔赛裁判 / 挑战对手位"
		},
		"occlusion_rects": [
			[1460, 760, 440, 320],
			[400, 865, 360, 215]
		],
		"occlusion_note": "右下整备长椅与卡匣箱 + 擂台前景低护栏"
	},
	"library": {
		"stage_key": "library",
		"title": "图书馆",
		"indoor": true,
		"edge_day": "#E4DFD4",
		"edge_dusk": "#DAC6B0",
		"edge_night": "#222E47",
		"slot_a": {
			"mode": "counter",
			"rect": [500, 240, 470, 705],
			"bubble_anchor": [735, 205],
			"label": "SLOT A · 林知夏（弧形借书台遮挡下身）"
		},
		"slot_b": {
			"mode": "counter",
			"rect": [1185, 255, 470, 705],
			"bubble_anchor": [1420, 218],
			"label": "SLOT B · 黄秋枫主线窗边书桌位"
		},
		"occlusion_rects": [
			[455, 670, 560, 410],
			[1150, 720, 540, 360]
		],
		"occlusion_note": "左中弧形木借书台 + 右中窗边双人自习桌"
	},
	"arete_coast_test": {
		"stage_key": "coast",
		"title": "阿瑞忒沿海公路",
		"indoor": false,
		"edge_day": "#8FD1F3",
		"edge_dusk": "#E5A073",
		"edge_night": "#1A2644",
		"slot_a": {
			"mode": "standing",
			"rect": [860, 275, 290, 665],
			"bubble_anchor": [1005, 240],
			"label": "SLOT A · 随行同伴散步位"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [1250, 285, 285, 650],
			"bubble_anchor": [1392, 250],
			"label": "SLOT B · 偶遇 / 红月预警位"
		},
		"occlusion_rects": [
			[980, 795, 940, 285]
		],
		"occlusion_note": "右前白色海滨安全护栏 + 石阶栏杆"
	},
	"old_park": {
		"stage_key": "old_park",
		"title": "旧公园",
		"indoor": false,
		"edge_day": "#95D0EF",
		"edge_dusk": "#DF956A",
		"edge_night": "#1B243E",
		"slot_a": {
			"mode": "standing",
			"rect": [590, 280, 290, 660],
			"bubble_anchor": [735, 245],
			"label": "SLOT A · 自由态随行同伴位"
		},
		"slot_b": {
			"mode": "counter",
			"rect": [930, 240, 470, 705],
			"bubble_anchor": [1165, 205],
			"label": "SLOT B · 黄秋枫主线红枫长椅位"
		},
		"occlusion_rects": [
			[870, 725, 520, 355]
		],
		"occlusion_note": "中景红枫长椅靠背/扶手 + 近景红枫垂枝（右后街角设发光汽水贩卖机）"
	},
	"arete_beach_test": {
		"stage_key": "beach",
		"title": "阿瑞忒海滩",
		"indoor": false,
		"edge_day": "#8DD0F2",
		"edge_dusk": "#E59D72",
		"edge_night": "#192440",
		"slot_a": {
			"mode": "standing",
			"rect": [870, 275, 290, 665],
			"bubble_anchor": [1015, 240],
			"label": "SLOT A · 随行同伴栈桥位"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [1310, 285, 285, 650],
			"bubble_anchor": [1452, 250],
			"label": "SLOT B · 主线海滨事件预留位"
		},
		"occlusion_rects": [
			[380, 790, 680, 290]
		],
		"occlusion_note": "前景木栈桥护栏柱与近景沙滩礁石"
	}
}

## Exact pixel-aligned v17 approved variants in 2340x1080 wide stage space (origin offset by WIDE_ORIGIN.x = 210).
const STAGED_VARIANTS := {
	"dorm": {
		"c": {
			"character_id": "ye_zhou",
			"character": "叶舟",
			"hint": "查看",
			"sprite": "dorm/actors/c_sprite.png",
			"sprite_rect": [1250, 299, 151, 559],
			"shadow": "dorm/actors/c_contact_shadow.png",
			"shadow_rect": [1250, 832, 151, 62],
			"head_anchor": [1324, 299]
		}
	},
	"shop": {
		"a": {
			"character_id": "tang_xiao_man",
			"character": "唐小满",
			"hint": "交谈",
			"sprite": "shop/actors/a_sprite.png",
			"sprite_rect": [1127, 286, 223, 390],
			"shadow": "",
			"shadow_rect": [],
			"head_anchor": [1231, 286]
		}
	},
	"rooftop": {
		"a": {
			"character_id": "yang_zi_ying",
			"character": "杨子英",
			"hint": "交谈",
			"sprite": "rooftop/actors/a_sprite.png",
			"sprite_rect": [1302, 357, 176, 523],
			"shadow": "rooftop/actors/a_contact_shadow.png",
			"shadow_rect": [1305, 854, 171, 62],
			"head_anchor": [1376, 357]
		},
		"b": {
			"character_id": "liu_yu_long",
			"character": "柳宇龙",
			"hint": "交谈",
			"sprite": "rooftop/actors/b_sprite.png",
			"sprite_rect": [1360, 329, 180, 555],
			"shadow": "rooftop/actors/b_contact_shadow.png",
			"shadow_rect": [1363, 858, 174, 62],
			"head_anchor": [1436, 329]
		},
		"c": {
			"character_id": "jiang_zi",
			"character": "姜梓",
			"hint": "交谈",
			"sprite": "rooftop/actors/c_sprite.png",
			"sprite_rect": [1273, 344, 175, 550],
			"shadow": "rooftop/actors/c_contact_shadow.png",
			"shadow_rect": [1275, 868, 170, 62],
			"head_anchor": [1351, 344]
		}
	},
	"arete_coast_test": {
		"c": {
			"character_id": "huang_qiufeng",
			"character": "黄秋枫",
			"hint": "交谈",
			"sprite": "coast/actors/c_sprite.png",
			"sprite_rect": [1251, 328, 208, 561],
			"shadow": "coast/actors/c_contact_shadow.png",
			"shadow_rect": [1257, 862, 196, 64],
			"head_anchor": [1345, 328]
		}
	},
	"old_park": {
		"c": {
			"character_id": "huang_qiufeng",
			"character": "黄秋枫",
			"hint": "交谈",
			"sprite": "old_park/actors/c_sprite.png",
			"sprite_rect": [1271, 316, 138, 561],
			"shadow": "old_park/actors/c_contact_shadow.png",
			"shadow_rect": [1270, 851, 141, 62],
			"head_anchor": [1340, 316]
		}
	},
	"arete_beach_test": {
		"a": {
			"character_id": "yang_zi_ying",
			"character": "杨子英",
			"hint": "交谈",
			"sprite": "beach/actors/a_sprite.png",
			"sprite_rect": [1382, 379, 237, 510],
			"shadow": "beach/actors/a_contact_shadow.png",
			"shadow_rect": [1391, 862, 219, 64],
			"head_anchor": [1484, 379]
		},
		"b": {
			"character_id": "liu_yu_long",
			"character": "柳宇龙",
			"hint": "交谈",
			"sprite": "beach/actors/b_sprite.png",
			"sprite_rect": [1475, 352, 270, 540],
			"shadow": "beach/actors/b_contact_shadow.png",
			"shadow_rect": [1488, 865, 245, 64],
			"head_anchor": [1576, 352]
		},
		"c": {
			"character_id": "jiang_zi",
			"character": "姜梓",
			"hint": "交谈",
			"sprite": "beach/actors/c_sprite.png",
			"sprite_rect": [1834, 481, 288, 449],
			"shadow": "beach/actors/c_contact_shadow.png",
			"shadow_rect": [1848, 903, 260, 64],
			"head_anchor": [1992, 481]
		}
	},
	"library": {
		"a": {
			"character_id": "lin_zhi_xia",
			"character": "林知夏",
			"hint": "交谈",
			"sprite": "library/actors/a_sprite.png",
			"sprite_rect": [1456, 321, 169, 570],
			"shadow": "library/actors/a_contact_shadow.png",
			"shadow_rect": [1458, 865, 165, 62],
			"head_anchor": [1537, 321]
		},
		"b": {
			"character_id": "huang_qiufeng",
			"character": "黄秋枫",
			"hint": "交谈",
			"sprite": "library/actors/b_sprite.png",
			"sprite_rect": [1836, 459, 159, 388],
			"shadow": "library/actors/b_contact_shadow.png",
			"shadow_rect": [1837, 821, 157, 62],
			"head_anchor": [1910, 459]
		},
		"c": {
			"character_id": "lin_zhi_xia",
			"character": "林知夏",
			"hint": "交谈",
			"sprite": "library/actors/c_sprite.png",
			"sprite_rect": [1462, 332, 156, 554],
			"shadow": "library/actors/c_contact_shadow.png",
			"shadow_rect": [1463, 860, 155, 62],
			"head_anchor": [1528, 332]
		}
	},
	"gym": {
		"b": {
			"character_id": "liu_yu_long",
			"character": "柳宇龙",
			"hint": "交谈",
			"sprite": "gym/actors/b_sprite.png",
			"sprite_rect": [1272, 280, 316, 523],
			"shadow": "gym/actors/b_contact_shadow.png",
			"shadow_rect": [1290, 776, 293, 64],
			"head_anchor": [1418, 280]
		},
		"c": {
			"character_id": "liu_yu_long",
			"character": "柳宇龙",
			"hint": "交谈",
			"sprite": "gym/actors/c_sprite.png",
			"sprite_rect": [1334, 313, 152, 488],
			"shadow": "gym/actors/c_contact_shadow.png",
			"shadow_rect": [1333, 774, 154, 64],
			"head_anchor": [1408, 313]
		}
	}
}

var location_id := ""
var blueprint: Dictionary = {}
var force_sky_mode := ""

var layer0_sky: Control
var layer1_midground: Control
var layer2_actors: Control
var layer3_foreground: Control

var _sky_tex_rect: TextureRect
var _sky_fallback: ColorRect
var _midground_tex_rect: TextureRect
var _foreground_tex_rect: TextureRect

var _slots: Dictionary = {}


static func has_staged_blueprint(place_id: String) -> bool:
	return SCENE_BLUEPRINTS.has(place_id)


static func blueprint_for(place_id: String) -> Dictionary:
	if SCENE_BLUEPRINTS.has(place_id):
		return SCENE_BLUEPRINTS[place_id]
	return {}


static func staged_variant_spec(place_id: String, variant_id: String) -> Dictionary:
	if not STAGED_VARIANTS.has(place_id):
		return {}
	var scene_map: Dictionary = STAGED_VARIANTS[place_id]
	return scene_map.get(variant_id, {})


func configure(target_location_id: String, _guides_visible: bool = false) -> void:
	location_id = target_location_id
	blueprint = SCENE_BLUEPRINTS.get(location_id, {}).duplicate(true)
	if is_inside_tree():
		_rebuild_layers()


func _ready() -> void:
	size = DESIGN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if blueprint.is_empty() and location_id != "":
		blueprint = SCENE_BLUEPRINTS.get(location_id, {}).duplicate(true)
	_rebuild_layers()


func _rebuild_layers() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_slots.clear()
	if blueprint.is_empty():
		return
	var stage_key := str(blueprint.get("stage_key", location_id))

	# Layer 0: Shared Sky
	layer0_sky = Control.new()
	layer0_sky.name = "Layer0_Sky"
	layer0_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer0_sky)
	DaylightUI.place(layer0_sky, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	_sky_fallback = ColorRect.new()
	_sky_fallback.name = "SkyFallback"
	_sky_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_fallback.color = Color("#8ED7FB")
	layer0_sky.add_child(_sky_fallback)
	DaylightUI.place(_sky_fallback, 0.0, 0.0, WIDE_RECT.size.x, WIDE_RECT.size.y)

	_sky_tex_rect = TextureRect.new()
	_sky_tex_rect.name = "SkyTexture"
	_sky_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_sky_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer0_sky.add_child(_sky_tex_rect)
	_place_wide_texture_rect(_sky_tex_rect)

	# Layer 1: Midground Architecture & Paths
	layer1_midground = Control.new()
	layer1_midground.name = "Layer1_Midground"
	layer1_midground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer1_midground)
	DaylightUI.place(layer1_midground, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	var mid_path := "%s%s/%s_midground_wide.png" % [STAGED_ROOT, stage_key, stage_key]
	if ResourceLoader.exists(mid_path):
		_midground_tex_rect = TextureRect.new()
		_midground_tex_rect.name = "MidgroundTexture"
		_midground_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_midground_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_midground_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_midground_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_midground_tex_rect.texture = load(mid_path) as Texture2D
		layer1_midground.add_child(_midground_tex_rect)
		_place_wide_texture_rect(_midground_tex_rect)

	# Layer 2: Dynamic Resident / Story Actors (Slot A & Slot B)
	layer2_actors = Control.new()
	layer2_actors.name = "Layer2_Actors"
	layer2_actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer2_actors)
	DaylightUI.place(layer2_actors, 0.0, 0.0, DESIGN.x, DESIGN.y)

	# Layer 3: Foreground Occluders (above actors!)
	layer3_foreground = Control.new()
	layer3_foreground.name = "Layer3_Foreground"
	layer3_foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer3_foreground)
	DaylightUI.place(layer3_foreground, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	var fg_path := "%s%s/%s_foreground_wide.png" % [STAGED_ROOT, stage_key, stage_key]
	if ResourceLoader.exists(fg_path):
		_foreground_tex_rect = TextureRect.new()
		_foreground_tex_rect.name = "ForegroundTexture"
		_foreground_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_foreground_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_foreground_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_foreground_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_foreground_tex_rect.texture = load(fg_path) as Texture2D
		layer3_foreground.add_child(_foreground_tex_rect)
		_place_wide_texture_rect(_foreground_tex_rect)

	apply_period_lighting()


func _place_wide_texture_rect(rect_node: TextureRect) -> void:
	if not is_instance_valid(rect_node):
		return
	var total_w := WIDE_RECT.size.x + WIDE_EXTEND_PAD * 2.0
	DaylightUI.place(rect_node, -WIDE_EXTEND_PAD, 0.0, total_w, WIDE_RECT.size.y)
	if _wide_extend_shader == null:
		_wide_extend_shader = Shader.new()
		_wide_extend_shader.code = WIDE_EXTEND_SHADER_CODE
	var mat := rect_node.material as ShaderMaterial
	if mat == null or mat.shader != _wide_extend_shader:
		mat = ShaderMaterial.new()
		mat.shader = _wide_extend_shader
		rect_node.material = mat
	mat.set_shader_parameter("pad_ratio", WIDE_EXTEND_PAD / total_w)


func set_staged_variant(slot_key: String, variant_id: String, tooltip: String = "", callback: Callable = Callable()) -> TextureRect:
	if not is_instance_valid(layer2_actors):
		return null
	clear_slot(slot_key)
	var spec := staged_variant_spec(location_id, variant_id)
	if spec.is_empty():
		return null
	var sprite_path := STAGED_ROOT + str(spec.get("sprite", ""))
	if not ResourceLoader.exists(sprite_path):
		return null
	var srect_arr: Array = spec.get("sprite_rect", [1100, 300, 200, 520])
	var sx := float(srect_arr[0]) - WIDE_ORIGIN.x
	var sy := float(srect_arr[1])
	var sw := float(srect_arr[2])
	var sh := float(srect_arr[3])

	var holder := Control.new()
	holder.name = "ActorHolder_" + slot_key
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer2_actors.add_child(holder)
	DaylightUI.place(holder, 0.0, 0.0, DESIGN.x, DESIGN.y)

	var shadow_rel := str(spec.get("shadow", ""))
	var sh_arr: Array = spec.get("shadow_rect", [])
	if shadow_rel != "" and sh_arr.size() == 4:
		var shadow_path := STAGED_ROOT + shadow_rel
		if ResourceLoader.exists(shadow_path):
			var sh_node := TextureRect.new()
			sh_node.name = "ContactShadow_" + slot_key
			sh_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sh_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sh_node.stretch_mode = TextureRect.STRETCH_SCALE
			sh_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			sh_node.texture = load(shadow_path) as Texture2D
			holder.add_child(sh_node)
			DaylightUI.place(sh_node, float(sh_arr[0]) - WIDE_ORIGIN.x, float(sh_arr[1]), float(sh_arr[2]), float(sh_arr[3]))

	var sprite := TextureRect.new()
	sprite.name = "ActorSprite_" + slot_key
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = load(sprite_path) as Texture2D
	holder.add_child(sprite)
	DaylightUI.place(sprite, sx, sy, sw, sh)
	sprite.pivot_offset = Vector2(sw * 0.5, sh)

	var hit_btn: Button = null
	if callback.is_valid():
		hit_btn = Button.new()
		hit_btn.name = "ActorHit_" + slot_key
		hit_btn.flat = true
		hit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hit_btn.focus_mode = Control.FOCUS_NONE
		if tooltip != "":
			hit_btn.tooltip_text = tooltip
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			hit_btn.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		holder.add_child(hit_btn)
		DaylightUI.place(hit_btn, sx - 16.0, sy - 8.0, sw + 32.0, sh + 16.0)
		hit_btn.pressed.connect(callback)

	_slots[slot_key] = {"holder": holder, "sprite": sprite, "hit": hit_btn, "staged": true, "variant": variant_id}
	return sprite


func is_slot_staged(slot_key: String) -> bool:
	if not _slots.has(slot_key):
		return false
	return bool((_slots[slot_key] as Dictionary).get("staged", false))


func pulse_slot_actor(slot_key: String) -> void:
	if not _slots.has(slot_key) or bool(SaveManager.settings.get("reduced_motion", false)):
		return
	var sprite := (_slots[slot_key] as Dictionary).get("sprite") as TextureRect
	if not is_instance_valid(sprite):
		return
	sprite.pivot_offset = Vector2(sprite.size.x * 0.5, sprite.size.y)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", Vector2(1.03, 1.03), 0.14)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.18)


func set_slot_texture(slot_key: String, texture_path: String) -> void:
	if not _slots.has(slot_key) or texture_path == "" or not ResourceLoader.exists(texture_path):
		return
	var entry: Dictionary = _slots[slot_key]
	if bool(entry.get("staged", false)):
		return
	var sprite := entry.get("sprite") as TextureRect
	if is_instance_valid(sprite):
		sprite.texture = load(texture_path) as Texture2D


func set_slot_hit_enabled(enabled: bool) -> void:
	for entry in _slots.values():
		var hit_btn := (entry as Dictionary).get("hit") as Button
		if is_instance_valid(hit_btn):
			hit_btn.disabled = not enabled
			hit_btn.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func clear_slot(slot_key: String) -> void:
	if not _slots.has(slot_key):
		return
	var entry: Dictionary = _slots[slot_key]
	var holder := entry.get("holder") as Control
	if is_instance_valid(holder):
		if holder.get_parent() != null:
			holder.get_parent().remove_child(holder)
		holder.queue_free()
	_slots.erase(slot_key)


func resolved_sky_mode(period_override: String = "", red_moon: bool = false) -> String:
	if force_sky_mode in ["day", "dusk", "redmoon"]:
		return force_sky_mode
	var p := period_override if period_override != "" else DayCycle.period()
	if red_moon or (p == "night" and _is_redmoon_phase()):
		return "redmoon"
	if p == "night":
		return "redmoon"
	if location_id == "old_park" and not bool(GameState.story_flags.get("chapter_1_completed", false)) and p != "morning":
		return "dusk"
	if p == "afternoon":
		return "dusk" if location_id == "old_park" else "day"
	return "day"


func _is_redmoon_phase() -> bool:
	var next_node: String = GameState.next_phase_two_node()
	if next_node in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss"]:
		return true
	return false


func apply_period_lighting(period_override: String = "", red_moon: bool = false) -> void:
	if blueprint.is_empty():
		return
	var p := period_override if period_override != "" else DayCycle.period()
	var sky_mode := resolved_sky_mode(p, red_moon)
	var stage_key := str(blueprint.get("stage_key", location_id))
	var indoor := bool(blueprint.get("indoor", false))
	var scene_sky_path := "%s%s/%s_sky_wide.png" % [STAGED_ROOT, stage_key, stage_key]
	var has_scene_sky := ResourceLoader.exists(scene_sky_path)
	var sky_path := ""
	var sky_tint := Color.WHITE
	if indoor and has_scene_sky:
		sky_path = scene_sky_path
		if sky_mode == "dusk":
			sky_tint = Color(1.0, 0.86, 0.74)
		elif sky_mode == "redmoon" or p == "night":
			sky_tint = Color(0.68, 0.56, 0.76) if sky_mode == "redmoon" else Color(0.62, 0.68, 0.86)
	elif sky_mode == "day" and has_scene_sky:
		sky_path = scene_sky_path
	elif sky_mode == "dusk" and stage_key == "beach" and has_scene_sky:
		sky_path = scene_sky_path
	else:
		sky_path = str(SHARED_SKY_PATHS.get(sky_mode, ""))
		if sky_path == "" and has_scene_sky:
			sky_path = scene_sky_path
	if is_instance_valid(_sky_tex_rect):
		if sky_path != "" and ResourceLoader.exists(sky_path):
			_sky_tex_rect.texture = load(sky_path) as Texture2D
			_sky_tex_rect.visible = true
			if is_instance_valid(_sky_fallback):
				_sky_fallback.visible = false
		else:
			_sky_tex_rect.visible = false
			if is_instance_valid(_sky_fallback):
				_sky_fallback.visible = true
				_sky_fallback.color = Color("#8ED7FB") if sky_mode == "day" else (Color("#E89278") if sky_mode == "dusk" else Color("#342C52"))
	if is_instance_valid(layer0_sky):
		layer0_sky.modulate = sky_tint
	var tint := Color.WHITE
	if sky_mode == "dusk":
		if stage_key == "beach":
			tint = Color.WHITE
		else:
			tint = Color(1.0, 0.94, 0.87) if indoor else Color(1.0, 0.91, 0.82)
	elif p == "afternoon" and not indoor and stage_key != "beach":
		tint = Color(1.0, 0.97, 0.93)
	elif p == "night" or sky_mode == "redmoon":
		tint = Color(0.84, 0.86, 0.96) if indoor else Color(0.72, 0.74, 0.90)
	for layer in [layer1_midground, layer2_actors, layer3_foreground]:
		if is_instance_valid(layer):
			layer.modulate = tint
	if is_inside_tree() and get_tree().current_scene != null:
		var hud := get_tree().current_scene.find_child("SceneHUD", true, false)
		if is_instance_valid(hud) and hud.has_method("refresh_status"):
			hud.call("refresh_status")


func stage_edge_color() -> Color:
	if blueprint.is_empty():
		return Color("#DCEBF7")
	var p := DayCycle.period()
	if resolved_sky_mode(p) == "dusk":
		return Color(str(blueprint.get("edge_dusk", "#E5A577")))
	if p == "night":
		return Color(str(blueprint.get("edge_night", "#1E2B48")))
	return Color(str(blueprint.get("edge_day", "#A6D9F5")))


func primary_wide_texture() -> Texture2D:
	if is_instance_valid(_midground_tex_rect) and _midground_tex_rect.texture != null:
		return _midground_tex_rect.texture
	return null
