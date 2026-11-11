class_name HomePortraitActor
extends TextureRect

## A dependency-free portrait rig: continuous local UV deformation, a registered
## blink texture and damped gaze. The seat, legs and foreground remain stationary.
@export_range(0.0, 1.5) var motion_strength := 1.0
@export var playback_enabled := true
var _elapsed := 0.0
var _gaze := Vector2.ZERO
var _blink_weight := 0.0
var _blink_elapsed := -1.0
var _next_blink := 3.5
var _random := RandomNumberGenerator.new()
var _portrait_material: ShaderMaterial

func _ready() -> void:
 _random.randomize()
 _next_blink = _random.randf_range(2.8,5.2)
 _portrait_material = ShaderMaterial.new()
 _portrait_material.shader = load("res://assets/ui/player_experience/home_motion/portrait_motion.gdshader")
 _portrait_material.set_shader_parameter("blink_texture",load("res://assets/ui/player_experience/home_motion/jiang_zi_blink.png"))
 material = _portrait_material
 set_meta("animation_method","native_uv_portrait")

func _process(delta: float) -> void:
 if not is_instance_valid(_portrait_material): return
 if bool(SaveManager.settings.get("reduced_motion",false)):
  _portrait_material.set_shader_parameter("strength",0.0)
  _portrait_material.set_shader_parameter("blink",0.0)
  return
 _portrait_material.set_shader_parameter("strength",motion_strength)
 if not playback_enabled or not is_visible_in_tree(): return
 var home := get_tree().current_scene
 if home is HomeScreen:
  if home.get_meta("campus_dialogue_open",false) or home.get_meta("campus_map_open",false) or home.modals_layer.visible or (is_instance_valid(home.system_menu) and home.system_menu.visible): return
 _elapsed += minf(delta,0.05)
 var target := (get_local_mouse_position()/size-Vector2(0.33,0.24))*Vector2(1.0,0.6)
 target = target.limit_length(0.65)
 _gaze = _gaze.lerp(target,1.0-exp(-delta*2.5))
 _next_blink -= delta
 if _next_blink <= 0.0 and _blink_elapsed < 0.0: trigger_blink()
 if _blink_elapsed >= 0.0:
  _blink_elapsed += delta
  # Close rapidly, hold briefly, and reopen more gently.
  if _blink_elapsed < 0.065: _blink_weight = smoothstep(0.0,0.065,_blink_elapsed)
  elif _blink_elapsed < 0.115: _blink_weight = 1.0
  elif _blink_elapsed < 0.255: _blink_weight = 1.0-smoothstep(0.115,0.255,_blink_elapsed)
  else:
   _blink_weight = 0.0
   _blink_elapsed = -1.0
   _next_blink = _random.randf_range(3.2,6.4)
 _portrait_material.set_shader_parameter("elapsed",_elapsed)
 _portrait_material.set_shader_parameter("gaze",_gaze)
 _portrait_material.set_shader_parameter("blink",_blink_weight)

func trigger_blink() -> void:
 _blink_elapsed = 0.0
