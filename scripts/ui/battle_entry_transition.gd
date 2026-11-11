class_name BattleEntryTransition
extends Control

## Alternating ink shutters bridge directly from the encounter into combat.
var exiting := false
var coverage := 0.0:
 set(value):
  coverage = clampf(value,0.0,1.0)
  queue_redraw()

func _ready() -> void:
 name = "BattleEntryTransition"
 mouse_filter = Control.MOUSE_FILTER_STOP
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 resized.connect(queue_redraw)
 hide()

func present(is_exit: bool = false) -> void:
 exiting = is_exit
 coverage = 0.0
 show()

func cover() -> void:
 await _animate(1.0,0.36)

func reveal() -> void:
 await _animate(0.0,0.28)
 hide()

func _animate(value: float, seconds: float) -> void:
 var duration: float = SaveManager.motion_duration(seconds)
 if duration <= 0.0:
  coverage = value
  return
 var tween := create_tween()
 tween.tween_property(self,"coverage",value,duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
 await tween.finished

func _draw() -> void:
 var band_height := size.y/8.0
 for index in 8:
  var amount := clampf((coverage-index*0.022)/0.84,0.0,1.0)
  if amount <= 0.0: continue
  var top := index*band_height-2.0
  var bottom := top+band_height+4.0
  var edge := (size.x+100.0)*amount
  if edge < 0.5: continue
  var slant := minf(80.0,edge*0.8)
  var points: PackedVector2Array
  var leading: PackedVector2Array
  if (index%2 == 0) != exiting:
   points = PackedVector2Array([Vector2(-2,top),Vector2(edge,top),Vector2(edge-slant,bottom),Vector2(-2,bottom)])
   leading = PackedVector2Array([Vector2(edge-4,top),Vector2(edge,top),Vector2(edge-slant,bottom),Vector2(edge-slant-4,bottom)])
  else:
   points = PackedVector2Array([Vector2(size.x+2,top),Vector2(size.x-edge,top),Vector2(size.x-edge+slant,bottom),Vector2(size.x+2,bottom)])
   leading = PackedVector2Array([Vector2(size.x-edge+4,top),Vector2(size.x-edge,top),Vector2(size.x-edge+slant,bottom),Vector2(size.x-edge+slant+4,bottom)])
  draw_colored_polygon(points,Color("#172638") if index%2 == 0 else Color("#1C3048"))
  if amount < 1.0: draw_colored_polygon(leading,Color("#D9BD84"))
