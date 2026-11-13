class_name SceneLoadingScreen
extends Control

## A persistent scene between large views, with live resource progress.
const DESIGN := Vector2(1920,1080)
var presentation: Control
var heading: Label
var description: Label
var stage: Label
var percent: Label
var progress: ProgressBar

func _ready() -> void:
 name = "LoadingScene"
 theme = DaylightUI.get_theme().duplicate() as Theme
 mouse_filter = Control.MOUSE_FILTER_STOP
 focus_mode = Control.FOCUS_ALL
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var base := ColorRect.new()
 base.color = Color("#10374C")
 base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(base)
 base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 presentation = Control.new()
 presentation.name = "LoadingPresentation"
 presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
 presentation.size = DESIGN
 add_child(presentation)
 SchoolObjectUI.art(presentation,"DuskCorridor","res://assets/ui/player_experience/loading_after_school.png")
 _text("Chapter","下一段日常",Rect2(120,430,720,60),27,Color("#9CC6C5"))
 heading = _text("Destination","去往校园",Rect2(120,510,820,110),66,Color("#FFF0CE"))
 description = _text("WaitingCopy","稍等片刻，下一段日常正在抵达。",Rect2(124,659,730,110),27,Color("#B9D3CE"))
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stage = _text("LoadingStage","正在读取场景",Rect2(124,842,650,50),25,Color("#C5D9CE"))
 percent = _text("ResourcePercent","0%",Rect2(784,842,100,50),25,Color("#F5D2A0"))
 percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 progress = ProgressBar.new()
 progress.name = "ResourceProgress"
 progress.show_percentage = false
 progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
 progress.max_value = 1.0
 for state in ["background","fill"]:
  var bar := StyleBoxFlat.new()
  bar.bg_color = Color("#355E6C") if state == "background" else Color("#F2BB7E")
  bar.set_corner_radius_all(3)
  progress.add_theme_stylebox_override(state,bar)
 var ambience := GeometricAmbience.new()
 ambience.name = "GeometricAmbience"
 presentation.add_child(ambience)
 DaylightUI.place(ambience,0,0,1920,1080)
 for child in presentation.get_children():
  if child is TextureRect:
   presentation.move_child(ambience,child.get_index() + 1)
   break
 presentation.add_child(progress)
 DaylightUI.place(progress,124,913,760,6)
 _text("GameName","Inorganic General Alien",Rect2(124,993,720,40),22,Color("#83ADB4"))
 resized.connect(_layout)
 _layout()
 hide()

func _text(node_name: String, copy: String, rect: Rect2, font_size: int, color: Color) -> Label:
 var label := SchoolObjectUI.text(presentation,node_name,copy,rect,font_size,color)
 label.add_theme_font_override("font",theme.default_font)
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 return label

func _layout() -> void:
 if not is_instance_valid(presentation): return
 var dusk := presentation.get_node_or_null("DuskCorridor") as TextureRect
 Platform.fit_stage(self,presentation,Color("#10374C"),dusk.texture if dusk != null else null)

class GeometricAmbience extends Control:
 var _elapsed: float = 0.0
 var _particles: Array[Dictionary] = []

 func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  for i in 14:
   var t: float = float(i) / 14.0
   _particles.append({
    "x": lerpf(420.0,1780.0,fposmod(t * 1.37 + 0.11,1.0)),
    "y": lerpf(110.0,880.0,fposmod(t * 2.13 + 0.27,1.0)),
    "size": 3.2 + float(i % 4) * 1.8,
    "speed": 9.0 + float(i % 5) * 3.5,
    "phase": t * TAU,
    "alpha": 0.07 + float(i % 3) * 0.035,
    "warm": (i % 3) != 0,
   })
  set_process(true)

 func _process(delta: float) -> void:
  if not is_visible_in_tree():
   return
  if bool(SaveManager.settings.get("reduced_motion",false)):
   if _elapsed != 0.0:
    _elapsed = 0.0
    queue_redraw()
   return
  _elapsed += delta
  queue_redraw()

 func _draw() -> void:
  if not is_visible_in_tree():
   return
  var reduced: bool = bool(SaveManager.settings.get("reduced_motion",false))
  var drift_t: float = 0.0 if reduced else _elapsed
  var sweep: float = 0.0 if reduced else sin(drift_t * 0.55) * 28.0
  var ray_alpha: float = 0.045 + (0.0 if reduced else 0.015 * sin(drift_t * 0.7))
  draw_colored_polygon(PackedVector2Array([
   Vector2(1060.0 + sweep,0.0),
   Vector2(1310.0 + sweep,0.0),
   Vector2(980.0 + sweep * 0.6,1080.0),
   Vector2(760.0 + sweep * 0.6,1080.0),
  ]),Color(0.98,0.90,0.74,ray_alpha))
  draw_colored_polygon(PackedVector2Array([
   Vector2(1430.0 - sweep * 0.5,0.0),
   Vector2(1590.0 - sweep * 0.5,0.0),
   Vector2(1290.0 - sweep * 0.3,1080.0),
   Vector2(1150.0 - sweep * 0.3,1080.0),
  ]),Color(0.76,0.89,0.92,ray_alpha * 0.75))
  for p in _particles:
   var phase: float = float(p["phase"]) + drift_t * 0.42
   var px: float = float(p["x"]) + drift_t * float(p["speed"]) * 0.65
   px = 360.0 + fposmod(px - 360.0,1480.0)
   var py: float = float(p["y"]) + sin(phase) * 14.0 - drift_t * float(p["speed"]) * 0.25
   py = 80.0 + fposmod(py - 80.0,840.0)
   var s: float = float(p["size"]) * (0.9 + 0.15 * sin(phase * 1.3))
   var col: Color = Color(0.99,0.91,0.72,float(p["alpha"])) if bool(p["warm"]) else Color(0.80,0.92,0.94,float(p["alpha"]) * 0.85)
   var pts := PackedVector2Array([
    Vector2(px,py - s * 1.35),
    Vector2(px + s,py),
    Vector2(px,py + s * 1.35),
    Vector2(px - s,py),
   ])
   draw_colored_polygon(pts,col)


func present(destination: String) -> void:
 heading.text = destination
 description.text = "稍等片刻，下一段日常正在抵达。"
 set_progress(0.0,"正在读取场景")
 modulate.a = 0.0
 show()
 grab_focus()

func set_progress(value: float, copy: String) -> void:
 progress.value = clampf(value,0.0,1.0)
 percent.text = "%d%%" % roundi(progress.value*100.0)
 stage.text = copy

func show_failure(copy: String) -> void:
 heading.text = "暂时没能抵达"
 description.text = copy
 stage.text = "即将返回上一页"
 percent.text = ""
