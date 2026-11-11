class_name SceneSurfaceUI
extends RefCounted

## Small painted UI surfaces extracted from the new complete library concept.
static func paper_texture() -> Texture2D:
 return SceneSkin.texture_for("button_plain")

static func style(tint: Color = Color.WHITE) -> StyleBox:
 var texture := paper_texture()
 if texture == null: return SceneSkin.style("button_plain",Vector4(14,6,14,6),tint)
 var box := StyleBoxTexture.new()
 box.texture = texture
 box.modulate_color = tint
 box.texture_margin_left = 14
 box.texture_margin_right = 14
 box.texture_margin_top = 14
 box.texture_margin_bottom = 14
 box.content_margin_left = 18
 box.content_margin_right = 18
 return box

static func button(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 28) -> Button:
 var control := SchoolObjectUI.hit(parent,node_name,rect,copy,font_size)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var tint := Color.WHITE
  if state == "hover": tint = Color(1.035,1.04,1.015)
  elif state in ["pressed","hover_pressed"]: tint = Color(0.86,0.91,0.85)
  elif state == "disabled": tint = Color(0.75,0.78,0.75,0.8)
  control.add_theme_stylebox_override(state,style(tint))
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  control.add_theme_color_override(state,SceneSkin.INK)
 SchoolObjectUI.borderless(control)
 return control

static func heading(parent: Control, title: String) -> void:
 var width := clampf(title.length()*42.0+70.0,340.0,1110.0)
 var backing := Panel.new()
 backing.name = "HeadingSurface"
 backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
 backing.add_theme_stylebox_override("panel",style())
 parent.add_child(backing)
 DaylightUI.place(backing,48,27,width,86)
 SchoolObjectUI.text(parent,"LocationTitle",title,Rect2(72,37,width-45,64),41,SceneSkin.INK)
 var date_back := Panel.new()
 date_back.name = "DateSurface"
 date_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
 date_back.add_theme_stylebox_override("panel",style(Color(1,1,1,0.94)))
 parent.add_child(date_back)
 DaylightUI.place(date_back,54,113,525,55)
 SchoolObjectUI.text(parent,"DayTime",GameState.get_detailed_time_string(),Rect2(75,120,490,39),24,SceneSkin.INK)

static func landmark(parent: Control, node_name: String, source: Texture2D, points: Array, tag: Array, copy: String, activate: Callable) -> Dictionary:
 var image := HomeObjectButton.new()
 image.name = "Landmark_"+node_name
 parent.add_child(image)
 image.configure_registered(source,SceneDesignCatalog.polygon(points,source.get_size()),SceneDesignCatalog.DESIGN/source.get_size())
 image.focus_mode = Control.FOCUS_NONE
 image.set_meta("display_label",copy)
 var native_rect := SceneDesignCatalog.rect(tag)
 var label := button(parent,node_name,copy,Rect2(native_rect.position*SceneDesignCatalog.DESIGN/SceneDesignCatalog.NATIVE,native_rect.size*SceneDesignCatalog.DESIGN/SceneDesignCatalog.NATIVE),27)
 image.label_plate = label
 image.pressed.connect(activate)
 label.pressed.connect(activate)
 label.mouse_entered.connect(func(): image.hovered = true; image._refresh())
 label.mouse_exited.connect(func(): image.hovered = false; image._refresh())
 label.focus_entered.connect(func(): image.hovered = true; image._refresh())
 label.focus_exited.connect(func(): image.hovered = false; image._refresh())
 return {"image":image,"label":label}

static func finish_layering(parent: Control, background: TextureRect) -> void:
 background.z_index = -2
 for child in parent.get_children():
  if child is HomeObjectButton: child.z_index = -1
 # Render and input order both keep captions, dates and navigation above objects.
 for child in parent.get_children():
  if child != background and not child is HomeObjectButton:
   parent.move_child(child,parent.get_child_count()-1)
