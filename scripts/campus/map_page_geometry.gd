class_name MapPageGeometry
extends Control

var map_level := "local"
var region_id := "campus"
var hovered := ""

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size = Vector2(1920,1080)

func _draw() -> void:
 if map_level == "world": _world(); return
 if region_id != "campus": return
 draw_rect(Rect2(0,0,1920,1080),Color("#F2E7D6"))
 # Shared masses establish adjacency, scale and the campus circulation loop.
 _shape([Vector2(120,240),Vector2(580,160),Vector2(1060,390),Vector2(790,680),Vector2(230,540)],Color("#D5D9CA"))
 _shape([Vector2(1010,160),Vector2(1600,155),Vector2(1710,415),Vector2(1200,560),Vector2(940,360)],Color("#CCDAD7"))
 _shape([Vector2(1230,515),Vector2(1810,480),Vector2(1835,885),Vector2(1350,955),Vector2(1110,760)],Color("#E4C2A6"))
 _shape([Vector2(125,640),Vector2(715,600),Vector2(1250,830),Vector2(1120,1005),Vector2(160,1005)],Color("#E2D5B8"))
 var path := PackedVector2Array([Vector2(340,820),Vector2(630,685),Vector2(740,485),Vector2(1030,435),Vector2(1350,320),Vector2(1600,620),Vector2(1500,815),Vector2(1000,855),Vector2(660,910),Vector2(340,820)])
 draw_polyline(path,Color("#F7F0E2"),48,true)
 draw_polyline(path,Color(0.60,0.43,0.32,0.20),2,true)
 draw_line(Vector2(365,300),Vector2(705,485),Color("#F7F0E2"),30,true)
 for id in RegionCatalog.REGIONS["campus"]["places"]: _landmark(str(id),RegionCatalog.MAP_RECTS[id])

func _shape(points: Array, color: Color) -> void:
 draw_colored_polygon(PackedVector2Array(points),color)

func _landmark(id: String, rect: Rect2) -> void:
 var c := rect.get_center()-Vector2(0,30)
 var ink := Color("#3C5C62")
 var warm := Color("#BB7352")
 match id:
  "club":
   draw_rect(Rect2(c-Vector2(160,75),Vector2(320,125)),ink)
   _shape([c+Vector2(-175,-75),c+Vector2(65,-125),c+Vector2(190,-65),c+Vector2(-55,-10)],warm)
   draw_rect(Rect2(c-Vector2(125,30),Vector2(210,60)),Color("#F1DEC0"))
  "rooftop":
   _shape([c+Vector2(-100,0),c+Vector2(30,-65),c+Vector2(125,-5),c+Vector2(-20,65)],ink)
   draw_line(c+Vector2(-80,-15),c+Vector2(30,-70),warm,9,true)
   draw_line(c+Vector2(-25,15),c+Vector2(55,-20),Color("#F1DEC0"),16,true)
  "library":
   _shape([c+Vector2(-130,-55),c+Vector2(-15,-95),c+Vector2(0,70),c+Vector2(-125,20)],ink)
   _shape([c+Vector2(0,70),c+Vector2(25,-95),c+Vector2(135,-50),c+Vector2(125,25)],warm)
  "gym":
   draw_arc(c+Vector2(0,20),120,PI,TAU,24,ink,50,true)
   draw_rect(Rect2(c-Vector2(120,0),Vector2(240,80)),ink)
   draw_rect(Rect2(c-Vector2(70,20),Vector2(140,95)),Color("#D8C7A5"))
   draw_arc(c+Vector2(0,45),25,0,TAU,24,warm,4,true)
  "dorm":
   draw_rect(Rect2(c-Vector2(105,75),Vector2(210,145)),ink)
   draw_rect(Rect2(c-Vector2(130,85),Vector2(260,22)),warm)
   for i in 3: draw_rect(Rect2(c+Vector2(-75+i*65,-40),Vector2(38,70)),Color("#F0D8AF"))
  "shop":
   draw_rect(Rect2(c-Vector2(95,35),Vector2(190,95)),ink)
   _shape([c+Vector2(-115,-35),c+Vector2(-70,-80),c+Vector2(90,-80),c+Vector2(115,-35)],warm)
   draw_rect(Rect2(c-Vector2(55,15),Vector2(110,65)),Color("#F0D8AF"))

func _world() -> void:
 draw_rect(Rect2(0,0,1920,1080),Color("#193D46"))
 for i in 5: draw_arc(Vector2(980,540),400+i*65,-0.5,3.7,80,Color(0.68,0.79,0.77,0.065),2,true)
 for id in RegionCatalog.LEGACY_REGIONS:
  var unlocked := RegionCatalog.is_unlocked(str(id))
  var color: Color = {"campus":Color("#BBCDB6"),"resistance":Color("#D2AC87"),"sanctuary":Color("#D4CCAF")}[id] if unlocked else Color("#6B7D7D")
  if hovered == id and unlocked: color = color.lightened(0.08)
  var poly := RegionCatalog.territory(str(id))
  draw_colored_polygon(poly,color)
  var border := poly.duplicate()
  border.append(poly[0])
  draw_polyline(border,Color("#193D46"),7,true)
  if not unlocked:
   var center: Vector2 = RegionCatalog.ATLAS_LABELS[id].get_center()
   draw_arc(center+Vector2(0,-122),17,PI,TAU,20,Color("#D8DFD7"),4,true)
   draw_rect(Rect2(center+Vector2(-21,-122),Vector2(42,31)),Color("#D8DFD7"))
