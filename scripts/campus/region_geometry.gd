class_name RegionGeometry
extends Control

## Geometric layouts are engine primitives, deliberately free of concept art.
var region_id := "resistance"
var place_id := ""

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size = Vector2(1920,1080)

func _draw() -> void:
 var spec: Dictionary = RegionCatalog.REGIONS[region_id]
 var ink := Color(spec["ink"])
 var accent := Color(spec["accent"])
 var paper := Color(spec["paper"])
 draw_rect(Rect2(0,0,1920,1080),paper)
 var grid := Color(ink,0.055)
 for x in range(480,1920,48): draw_line(Vector2(x,120),Vector2(x,1000),grid,1.0)
 for y in range(136,1000,48): draw_line(Vector2(480,y),Vector2(1890,y),grid,1.0)
 if place_id != "":
  _room(accent,ink)
  return
 for link in RegionCatalog.links(region_id):
  var from: Vector2 = RegionCatalog.MAP_RECTS[link[0]].get_center()
  var to: Vector2 = RegionCatalog.MAP_RECTS[link[1]].get_center()
  draw_line(from,to,Color(accent,0.35),12.0,true)
  draw_line(from,to,Color(ink,0.20),2.0,true)
 if region_id == "sanctuary":
  draw_arc(Vector2(1190,560),360,0,TAU,80,Color(accent,0.18),2.0,true)
 for id in spec["places"]:
  var rect: Rect2 = RegionCatalog.MAP_RECTS[id]
  var body := rect.grow(-20)
  body.size.y -= 75
  draw_rect(body,Color(ink,0.07))
  draw_rect(body,Color(accent,0.60),false,2.0)
  if region_id == "resistance":
   var top := PackedVector2Array([body.position+Vector2(0,28),body.position+Vector2(28,0),body.position+Vector2(body.size.x,0),body.position+Vector2(body.size.x,28)])
   draw_colored_polygon(top,Color(accent,0.30))
   for i in 3: draw_rect(Rect2(body.position+Vector2(28+i*75,55),Vector2(48,35)),Color(ink,0.16))
  else:
   draw_colored_polygon(PackedVector2Array([body.position+Vector2(0,35),body.position+Vector2(body.size.x/2,-22),body.position+Vector2(body.size.x,35)]),Color(accent,0.25))
   for i in 3:
    var center := body.position+Vector2(45+i*(body.size.x-90)/2,67)
    draw_circle(center,16,Color(accent,0.25))
    draw_rect(Rect2(center-Vector2(16,0),Vector2(32,maxf(12,body.size.y-80))),Color(accent,0.25))

func _room(accent: Color, ink: Color) -> void:
 var floor := PackedVector2Array([Vector2(340,730),Vector2(1130,340),Vector2(1780,590),Vector2(1010,930)])
 draw_colored_polygon(floor,Color(accent,0.15))
 draw_polyline(PackedVector2Array([floor[0],floor[1],floor[2],floor[3],floor[0]]),Color(accent,0.70),3.0,true)
 draw_colored_polygon(PackedVector2Array([floor[0],floor[1],Vector2(1130,220),Vector2(340,610)]),Color(ink,0.08))
 draw_colored_polygon(PackedVector2Array([floor[1],floor[2],Vector2(1780,470),Vector2(1130,220)]),Color(ink,0.13))
 if place_id in ["gym","alliance_drill"]:
  var court := PackedVector2Array([Vector2(620,670),Vector2(1130,420),Vector2(1510,570),Vector2(1000,810),Vector2(620,670)])
  draw_polyline(court,Color(ink,0.55),3.0,true)
  draw_line(Vector2(870,545),Vector2(1260,695),Color(ink,0.5),3.0,true)
  draw_arc(Vector2(1065,620),58,0,TAU,48,Color(ink,0.5),3.0,true)
 elif place_id == "sanctuary_garden":
  draw_circle(Vector2(1065,620),145,Color(accent,0.15))
  draw_arc(Vector2(1065,620),145,0,TAU,64,Color(accent,0.7),3.0,true)
  draw_circle(Vector2(1065,620),95,Color("#83A6A1"))
  for i in 4: draw_circle(Vector2(760+i*200,450+(i%2)*330),30,Color(accent,0.45))
 elif place_id == "sanctuary_cathedral":
  draw_colored_polygon(PackedVector2Array([Vector2(830,760),Vector2(1170,400),Vector2(1320,470),Vector2(1000,830)]),Color(accent,0.28))
  for i in 4:
   draw_circle(Vector2(760+i*105,700-i*75),22,Color(ink,0.28))
   draw_circle(Vector2(1120+i*105,810-i*75),22,Color(ink,0.28))
  draw_rect(Rect2(1110,388,170,65),Color(accent,0.55))
 elif place_id in ["alliance_supply","sanctuary_archive"]:
  for row in 2:
   for i in 4:
    var shelf := Rect2(650+i*175+row*125,490+row*175,115,75)
    draw_rect(shelf,Color(accent,0.32))
    draw_rect(shelf,Color(ink,0.4),false,2.0)
 elif place_id in ["alliance_quarters","sanctuary_lodging"]:
  for i in 4:
   var bed := Rect2(620+i*220,570+(i%2)*70,155,90)
   draw_rect(bed,Color(accent,0.32))
   draw_rect(Rect2(bed.position+Vector2(8,8),Vector2(37,74)),Color(ink,0.18))
 elif place_id == "alliance_intel":
  draw_rect(Rect2(920,360,470,145),Color(accent,0.34))
  for i in 4: draw_rect(Rect2(950+i*105,383,78,80),Color(ink,0.16))
  draw_rect(Rect2(680,650,260,115),Color(accent,0.25))
 else:
  for i in 3:
   var r := Rect2(600+i*310,570+(i%2)*80,210,95)
   draw_rect(r,Color(accent,0.25))
   draw_rect(r,Color(accent,0.7),false,2.0)
