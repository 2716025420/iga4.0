class_name CampusDialogueUI
extends Control

signal closed
var lines: Array = []
var line_index := 0
var body: RichTextLabel
var speaker: Label
var portrait: TextureRect
var _typing := 0.0

func _ready() -> void:
 size = Vector2(1920,1080)
 mouse_filter = Control.MOUSE_FILTER_STOP
 theme = DaylightUI.get_theme()
 var sheet := Panel.new()
 sheet.name = "DialogueSurface"
 sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
 sheet.add_theme_stylebox_override("panel",SceneSkin.style("dialogue_sheet",Vector4.ZERO))
 add_child(sheet)
 DaylightUI.place(sheet,95,726,1730,330)
 speaker = SchoolObjectUI.text(self,"Speaker","",Rect2(145,743,650,47),31,SceneSkin.INK)
 portrait = SchoolObjectUI.art(self,"SpeakerPortrait","",Rect2(0,0,1,1))
 portrait.hide()
 body = RichTextLabel.new()
 body.name = "DialogueText"
 body.mouse_filter = Control.MOUSE_FILTER_PASS
 body.fit_content = false
 body.scroll_active = true
 body.add_theme_font_size_override("normal_font_size",33)
 body.add_theme_constant_override("line_separation",10)
 body.add_theme_color_override("default_color",SceneSkin.INK)
 add_child(body)
 DaylightUI.place(body,145,808,1600,154)
 var next := SceneSurfaceUI.button(self,"NextLine","继续 · Enter / Space",Rect2(1425,980,390,62),26)
 var close := SceneSurfaceUI.button(self,"CloseDialogue","结束交谈 · Esc",Rect2(145,980,290,62),25)
 next.pressed.connect(advance)
 close.pressed.connect(_close)
 next.grab_focus()
 _show_line()

func present(script_lines: Array, face: Texture2D = null) -> void:
 lines = script_lines
 if is_instance_valid(portrait): portrait.texture = face
 if is_inside_tree(): _show_line()

func _show_line() -> void:
 if lines.is_empty() or line_index >= lines.size(): _close(); return
 speaker.text = str(lines[line_index][0])
 if speaker.text in ["我","叶舟"]: portrait.texture = load("res://assets/sprites/characters/phase_two/portraits/ye_zhou.png")
 body.text = str(lines[line_index][1])
 body.scroll_to_line(0)
 _typing = 0.0
 body.visible_characters = -1 if SaveManager.typing_interval() <= 0.0 else 0

func _process(delta: float) -> void:
 if not is_instance_valid(body) or body.visible_characters < 0: return
 var interval: float = SaveManager.typing_interval()
 if interval <= 0.0: body.visible_characters = -1; return
 _typing += delta
 body.visible_characters = mini(body.get_total_character_count(),int(_typing/interval))

func advance() -> void:
 if body.visible_characters >= 0 and body.visible_characters < body.get_total_character_count(): body.visible_characters = -1; return
 line_index += 1
 _show_line()

func _close() -> void:
 closed.emit()
 queue_free()

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode in [KEY_ENTER,KEY_SPACE]: advance(); get_viewport().set_input_as_handled()
  elif event.keycode == KEY_ESCAPE: _close(); get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  advance()
  accept_event()
