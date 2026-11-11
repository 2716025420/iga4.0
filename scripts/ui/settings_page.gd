class_name GameSettingsPage
extends Control

signal close_requested
const ART_ROOT := "res://assets/ui/player_experience/"
const ART_SCALE := Vector2(1920.0/1672.0,1080.0/941.0)
const INK := Color("#173C51")
const TEAL := Color("#328C92")
const CREAM := Color("#FFF2D6")
var draft: Dictionary = {}
var original: Dictionary = {}
var sliders: Dictionary = {}
var fullscreen_toggle: CheckButton
var motion_toggle: CheckButton
var speed_option: OptionButton
var status: Label
var preview: RichTextLabel
var _preview_elapsed: float = 0.0
var _discard_prompt: Panel
var _locked_controls: Array[Dictionary] = []

func _ready() -> void:
 name = "SettingsPage"
 mouse_filter = Control.MOUSE_FILTER_STOP
 theme = DaylightUI.get_theme().duplicate() as Theme
 original = SaveManager.settings.duplicate(true)
 draft = original.duplicate(true)
 DaylightUI.place(self,0,0,1920,1080)
 SchoolObjectUI.art(self,"BroadcastRoom",ART_ROOT+"settings_broadcast_room.png")
 var console := SchoolObjectUI.art(self,"BroadcastConsole",ART_ROOT+"settings_console.png")
 console.stretch_mode = TextureRect.STRETCH_SCALE
 _place(console,Rect2(135,87,1438,885))
 _label(self,"Title","游戏设置",Rect2(150,20,520,128),88,CREAM)
 _label(self,"Subtitle","调到自己的频率。",Rect2(235,151,480,49),29,CREAM)
 _button(self,"BackButton","‹  返回",Rect2(1488,44,153,60),28,true).pressed.connect(request_close)
 _label(self,"OnAir","ON AIR",Rect2(402,273,145,39),30,CREAM,true)
 _label(self,"Frequency","放学以后 · FM 104",Rect2(939,248,320,30),16,Color("#A5C8CB"),true)
 _label(self,"SoundHeading","♪  声音",Rect2(256,369,590,54),32)
 _label(self,"ComfortHeading","显示与阅读",Rect2(926,369,500,54),32)
 _rule(Rect2(332,421,514,1))
 _rule(Rect2(925,421,523,1))
 var audio_keys := ["master_volume","music_volume","sfx_volume"]
 var audio_names := ["总音量","背景音乐","音效"]
 for index in audio_keys.size():
  var key: String = audio_keys[index]
  var y := 451.0+index*100.0
  _label(self,key+"Label",audio_names[index],Rect2(278,y,140,52),27)
  var value_label := _label(self,key+"Value","",Rect2(790,y,75,52),27)
  var slider := HSlider.new()
  slider.name = key+"Slider"
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 1
  slider.value = float(draft[key])*100
  slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  for state in ["slider","grabber_area","grabber_area_highlight"]:
   var track := StyleBoxFlat.new()
   track.bg_color = Color("#C9C5B2") if state == "slider" else TEAL
   track.border_color = Color("#8C9D9B")
   track.set_border_width_all(1)
   track.set_content_margin_all(6)
   track.set_corner_radius_all(7)
   slider.add_theme_stylebox_override(state,track)
  for state in ["grabber","grabber_highlight","grabber_disabled"]:
   slider.add_theme_icon_override(state,load(ART_ROOT+"settings_knob.svg"))
  add_child(slider)
  _place(slider,Rect2(426,y+2,344,48))
  value_label.text = "%d%%" % int(slider.value)
  slider.value_changed.connect(func(value: float): draft[key] = value/100.0; value_label.text = "%d%%" % int(value))
  sliders[key] = slider
  if index < 2: _rule(Rect2(258,y+81,590,1))
 fullscreen_toggle = _toggle("FullscreenToggle","全屏显示",Rect2(925,436,485,50),bool(draft["fullscreen"]))
 fullscreen_toggle.toggled.connect(func(value: bool): draft["fullscreen"] = value)
 motion_toggle = _toggle("ReducedMotionToggle","减少动态效果",Rect2(925,496,485,50),bool(draft["reduced_motion"]))
 motion_toggle.toggled.connect(func(value: bool): draft["reduced_motion"] = value)
 _label(self,"TextSpeedLabel","文本速度",Rect2(925,562,240,48),27)
 speed_option = OptionButton.new()
 speed_option.name = "TextSpeedOption"
 for copy in ["舒缓","标准","快速","即时显示"]: speed_option.add_item(copy)
 speed_option.selected = int(draft["text_speed"])
 speed_option.add_theme_font_size_override("font_size",29)
 _field(speed_option)
 add_child(speed_option)
 _place(speed_option,Rect2(1190,561,280,44))
 speed_option.item_selected.connect(func(index: int): draft["text_speed"] = index; _preview_elapsed = 0.0)
 _label(self,"PreviewSymbol","♪",Rect2(942,645,50,60),40,Color("#53ACB9"),true)
 preview = RichTextLabel.new()
 preview.name = "ReadingPreview"
 preview.text = "放学的铃声响了。收好书包，慢慢出发吧。"
 preview.scroll_active = false
 preview.add_theme_font_size_override("normal_font_size",28)
 preview.add_theme_color_override("default_color",CREAM)
 preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(preview)
 _place(preview,Rect2(1004,637,443,83))
 status = _label(self,"SettingsStatus","设置在所有存档之间共用 · 保存后生效。",Rect2(434,754,700,32),20,CREAM,true)
 _button(self,"ResetDefaults","↶  恢复默认",Rect2(330,794,300,76),29).pressed.connect(_reset_defaults)
 _button(self,"CancelSettings","×  取消修改",Rect2(651,794,340,76),29).pressed.connect(request_close)
 _button(self,"SaveSettings","保存设置",Rect2(1012,794,332,76),31,false,true).pressed.connect(_save)
 get_node("BackButton").grab_focus()

func _place(node: Control, rect: Rect2) -> void:
 node.position = rect.position*ART_SCALE
 node.size = rect.size*ART_SCALE

func _label(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 27, color: Color = INK, centered: bool = false) -> Label:
 var label := Label.new()
 label.name = node_name
 label.text = copy
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
 label.add_theme_font_size_override("font_size",roundi(font_size*ART_SCALE.x))
 label.add_theme_color_override("font_color",color)
 if node_name == "Title": label.add_theme_font_override("font",load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
 parent.add_child(label)
 _place(label,rect)
 return label

func _rule(rect: Rect2) -> void:
 var line := ColorRect.new()
 line.color = Color(0.16,0.36,0.40,0.25)
 line.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(line)
 _place(line,rect)

func _button(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 29, solid: bool = false, light: bool = false) -> Button:
 var button := Button.new()
 button.name = node_name
 button.text = copy
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 button.add_theme_font_size_override("font_size",roundi(font_size*ART_SCALE.x))
 for state in ["normal","hover","pressed","disabled","focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color = CREAM if solid else Color.TRANSPARENT
  if state == "hover": style.bg_color = Color("#F4DFC0") if solid else Color(0.12,0.42,0.48,0.13)
  if state == "pressed": style.bg_color = Color("#D8C5A7") if solid else Color(0.12,0.42,0.48,0.25)
  if state == "focus":
   style.bg_color = Color.TRANSPARENT
   style.border_color = Color("#EAB264")
   style.set_border_width_all(3)
  style.set_corner_radius_all(18)
  button.add_theme_stylebox_override(state,style)
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  button.add_theme_color_override(key,CREAM if light else INK)
 parent.add_child(button)
 _place(button,rect)
 if node_name in ["ResetDefaults","CancelSettings","SaveSettings"]:
  var shear := -16.0 if node_name == "ResetDefaults" else (-4.0 if node_name == "CancelSettings" else 12.0)
  SchoolObjectUI.fit_surface(button,0,shear*ART_SCALE.x)
 SchoolObjectUI.borderless(button)
 return button

func _toggle(node_name: String, copy: String, rect: Rect2, value: bool) -> CheckButton:
 var toggle := CheckButton.new()
 toggle.name = node_name
 toggle.text = copy
 toggle.button_pressed = value
 toggle.add_theme_font_size_override("font_size",30)
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  toggle.add_theme_color_override(key,INK)
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color = Color(0.16,0.45,0.47,0.07) if state in ["hover","hover_pressed"] else Color.TRANSPARENT
  style.set_corner_radius_all(6)
  if state == "focus":
   style.border_color = TEAL
   style.set_border_width_all(2)
  toggle.add_theme_stylebox_override(state,style)
 for key in ["checked","checked_disabled"]: toggle.add_theme_icon_override(key,load(ART_ROOT+"settings_switch_on.svg"))
 for key in ["unchecked","unchecked_disabled"]: toggle.add_theme_icon_override(key,load(ART_ROOT+"settings_switch_off.svg"))
 add_child(toggle)
 _place(toggle,rect)
 SchoolObjectUI.borderless(toggle)
 var state_label := _label(self,node_name+"State","开" if value else "关",Rect2(1420,rect.position.y,50,rect.size.y),24)
 SchoolObjectUI.set_selected(toggle,value)
 toggle.toggled.connect(func(enabled: bool):
  state_label.text = "开" if enabled else "关"
  SchoolObjectUI.set_selected(toggle,enabled)
 )
 return toggle

func _field(option: OptionButton) -> void:
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color = CREAM if state != "hover" else Color("#F4DFC0")
  style.border_color = TEAL if state == "focus" else INK
  style.set_border_width_all(2)
  style.set_corner_radius_all(7)
  style.set_content_margin_all(8)
  option.add_theme_stylebox_override(state,style)
 option.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: option.add_theme_color_override(key,INK)
 var popup := option.get_popup()
 var plate := StyleBoxFlat.new()
 plate.bg_color = CREAM
 plate.border_color = INK
 plate.set_border_width_all(2)
 plate.set_content_margin_all(10)
 popup.add_theme_stylebox_override("panel",plate)
 var selected := StyleBoxFlat.new()
 selected.bg_color = Color("#D4E4D7")
 popup.add_theme_stylebox_override("hover",selected)
 popup.add_theme_color_override("font_color",INK)
 popup.add_theme_color_override("font_hover_color",INK)
 popup.add_theme_font_size_override("font_size",29)

func _process(delta: float) -> void:
 if not is_instance_valid(preview): return
 _preview_elapsed += delta
 var interval: float = [0.045,0.025,0.012,0.0][int(draft["text_speed"])]
 preview.visible_characters = -1 if interval <= 0.0 else int(_preview_elapsed/interval)
 if _preview_elapsed > 4.0: _preview_elapsed = 0.0

func _reset_defaults() -> void:
 for key in sliders: sliders[key].value = float(SaveManager.DEFAULT_SETTINGS[key])*100
 fullscreen_toggle.button_pressed = bool(SaveManager.DEFAULT_SETTINGS["fullscreen"])
 motion_toggle.button_pressed = bool(SaveManager.DEFAULT_SETTINGS["reduced_motion"])
 speed_option.select(int(SaveManager.DEFAULT_SETTINGS["text_speed"]))
 draft["text_speed"] = int(SaveManager.DEFAULT_SETTINGS["text_speed"])
 _preview_elapsed = 0.0
 status.text = "已恢复默认值，保存后生效。"

func _save() -> void:
 if SaveManager.update_settings(draft):
  original = draft.duplicate(true)
  close_requested.emit()
 else: status.text = SaveManager.last_error

func request_close() -> void:
 if is_instance_valid(_discard_prompt):
  for entry in _locked_controls:
   if is_instance_valid(entry["control"]): entry["control"].focus_mode = entry["mode"]
  _locked_controls.clear()
  _discard_prompt.queue_free()
  _discard_prompt = null
  get_node("BackButton").grab_focus()
  return
 if draft == original:
  close_requested.emit()
  return
 for node in find_children("*","Control",true,false):
  if node.focus_mode != Control.FOCUS_NONE:
   _locked_controls.append({"control":node,"mode":node.focus_mode})
   node.focus_mode = Control.FOCUS_NONE
 _discard_prompt = Panel.new()
 _discard_prompt.name = "DiscardChanges"
 _discard_prompt.add_theme_stylebox_override("panel",CombatSkin.flat(Color(0.04,0.13,0.19,0.75)))
 add_child(_discard_prompt)
 DaylightUI.place(_discard_prompt,0,0,1920,1080)
 var dialog := SchoolObjectUI.slab(_discard_prompt,"Dialog",Rect2(520,350,880,360),CREAM)
 var plate := dialog.get_theme_stylebox("panel") as StyleBoxFlat
 plate.border_color = TEAL
 plate.set_border_width_all(3)
 _label(_discard_prompt,"Question","放弃未保存的设置？",Rect2(495,330,690,70),34)
 _label(_discard_prompt,"Copy","已保存的设置会继续使用。",Rect2(495,413,690,55),24)
 _button(_discard_prompt,"Discard","放弃修改",Rect2(865,520,290,62),28,true).pressed.connect(func(): close_requested.emit())
 var cancel := _button(_discard_prompt,"KeepEditing","继续调整",Rect2(495,520,290,62),28,true)
 cancel.pressed.connect(request_close)
 cancel.grab_focus()
