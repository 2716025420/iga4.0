class_name MapPageUI
extends RefCounted

static func plate(parent: Control, node_name: String, rect: Rect2, color: Color) -> Panel:
 var p := SchoolObjectUI.slab(parent,node_name,rect,color)
 var style := p.get_theme_stylebox("panel") as StyleBoxFlat
 style.set_border_width_all(0)
 style.set_corner_radius_all(8)
 return p

static func button(parent: Control, node_name: String, copy: String, rect: Rect2, ink: Color, fill: Color = Color.TRANSPARENT, font_size: int = 25) -> Button:
 var b := SchoolObjectUI.hit(parent,node_name,rect,copy,font_size)
 for state in ["normal","hover","pressed","hover_pressed"]:
  var style := StyleBoxFlat.new()
  style.bg_color = fill
  if state == "hover": style.bg_color = fill.blend(Color(ink,0.10))
  elif state in ["pressed","hover_pressed"]: style.bg_color = fill.blend(Color(ink,0.18))
  style.set_corner_radius_all(8)
  b.add_theme_stylebox_override(state,style)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: b.add_theme_color_override(state,ink)
 SchoolObjectUI.borderless(b)
 return b
