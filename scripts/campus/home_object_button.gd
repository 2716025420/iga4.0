class_name HomeObjectButton
extends TextureButton

## A source-registered furniture layer; image, alpha mask and hit area share one transform.
var selected := false
var hovered := false
var held := false
var label_plate: Button
var normal_fill := Color("#F8F5EC")
var selected_fill := Color("#D5DFCA")
static var mask_cache: Dictionary = {}
const FEEDBACK := """shader_type canvas_item;
uniform sampler2D silhouette : filter_nearest;
uniform vec4 source_region = vec4(0.0,0.0,1.0,1.0);
uniform float emphasis = 0.0;
uniform float held = 0.0;
void fragment() {
 vec4 pixel = texture(TEXTURE, UV);
 vec2 local_uv = (UV-source_region.xy)/source_region.zw;
 float shape = texture(silhouette,local_uv).r;
 vec3 lit = mix(pixel.rgb*(1.0+emphasis*0.10),vec3(0.79,0.91,0.77),emphasis*0.10);
 COLOR = vec4(lit*(1.0-held*0.13),pixel.a*shape);
}
"""

func configure_registered(source: Texture2D, polygon: PackedVector2Array, scale_to_design: Vector2) -> void:
 var bounds := Rect2(polygon[0],Vector2.ZERO)
 for point in polygon: bounds = bounds.expand(point)
 var region := Rect2i(bounds.grow(3)).intersection(Rect2i(Vector2i.ZERO,source.get_size()))
 var key := source.resource_path+str(polygon)
 var mask: BitMap
 if mask_cache.has(key): mask = mask_cache[key]
 else:
  mask = BitMap.new()
  mask.create(region.size)
  for y in region.size.y:
   var scan := float(y+region.position.y)+0.5
   var intersections: Array[float] = []
   for i in polygon.size():
    var a := polygon[i]
    var b := polygon[(i+1)%polygon.size()]
    if (a.y <= scan and b.y > scan) or (b.y <= scan and a.y > scan):
     intersections.append(a.x+(scan-a.y)*(b.x-a.x)/(b.y-a.y)-region.position.x)
   intersections.sort()
   for i in range(0,intersections.size()-1,2):
    var left := clampi(int(ceil(intersections[i])),0,region.size.x)
    var right := clampi(int(floor(intersections[i+1])),0,region.size.x-1)
    if right >= left: mask.set_bit_rect(Rect2i(left,y,right-left+1,1),true)
  mask_cache[key] = mask
 var crop := AtlasTexture.new()
 crop.atlas = source
 crop.region = Rect2(region)
 crop.filter_clip = true
 texture_normal = crop
 texture_hover = crop
 texture_pressed = crop
 texture_disabled = crop
 texture_click_mask = mask
 ignore_texture_size = true
 stretch_mode = TextureButton.STRETCH_SCALE
 size = Vector2(region.size)*scale_to_design
 position = Vector2(region.position)*scale_to_design
 set_meta("source_rect",Rect2(region))
 set_meta("source_registered",true)
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 var shader := Shader.new()
 shader.code = FEEDBACK
 var effect := ShaderMaterial.new()
 effect.shader = shader
 effect.set_shader_parameter("silhouette",ImageTexture.create_from_image(mask.convert_to_image()))
 effect.set_shader_parameter("source_region",Vector4(float(region.position.x)/source.get_width(),float(region.position.y)/source.get_height(),float(region.size.x)/source.get_width(),float(region.size.y)/source.get_height()))
 material = effect
 mouse_entered.connect(func(): hovered = true; _refresh())
 mouse_exited.connect(func(): hovered = false; _refresh())
 focus_entered.connect(_refresh)
 focus_exited.connect(_refresh)
 button_down.connect(func(): held = true; _refresh())
 button_up.connect(func(): held = false; _refresh())
 _refresh()

func set_selected(value: bool) -> void:
 selected = value
 if is_instance_valid(label_plate): SchoolObjectUI.set_selected(label_plate,value)
 _refresh()

func _refresh() -> void:
 if material == null: return
 var emphasis := 1.0 if selected else (0.5 if hovered or has_focus() else 0.0)
 material.set_shader_parameter("emphasis",emphasis)
 material.set_shader_parameter("held",1.0 if held else 0.0)
 if is_instance_valid(label_plate):
  var style := label_plate.get_theme_stylebox("normal")
  if style is StyleBoxTexture: style.modulate_color = Color(0.91,0.97,0.86) if selected else Color.WHITE
  elif style is StyleBoxFlat: style.bg_color = selected_fill if selected else normal_fill
  label_plate.queue_redraw()
