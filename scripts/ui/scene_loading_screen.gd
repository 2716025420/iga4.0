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
 presentation.add_child(progress)
 DaylightUI.place(progress,124,913,760,6)
 _text("GameName","放学以后",Rect2(124,993,720,40),22,Color("#83ADB4"))
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
 var factor := minf(size.x/DESIGN.x,size.y/DESIGN.y)
 presentation.scale = Vector2.ONE*factor
 presentation.position = (size-DESIGN*factor)/2.0

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
