class_name SchoolCardCarousel
extends Control

signal offset_changed(value: float)
const DRAG_THRESHOLD := 12.0
var track: Control
var card_step: float = 456.0
var content_width: float = 0.0
var offset: float = 0.0
var _pointer_down := false
var _dragged := false
var _press_local := Vector2.ZERO
var _press_offset := 0.0
var _touch_index := -1
var _ignore_click_until: int = 0
var _motion: Tween

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(func(): set_scroll_offset(offset))

func maximum_offset() -> float:
	return maxf(0.0, content_width - size.x)

func set_scroll_offset(value: float) -> void:
	offset = clampf(value, 0.0, maximum_offset())
	if is_instance_valid(track): track.position.x = -offset
	offset_changed.emit(offset)

func jump_to(value: float, animate: bool = true) -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	var target := clampf(value, 0.0, maximum_offset())
	var duration := SaveManager.motion_duration(0.18) if animate else 0.0
	if not is_inside_tree() or duration == 0.0:
		set_scroll_offset(target)
		return
	_motion = create_tween()
	_motion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.tween_method(set_scroll_offset, offset, target, duration)

func browse(direction: int) -> void:
	_pointer_down = false
	jump_to(offset + direction * card_step)

func reveal_card(index: int, card_width: float) -> void:
	var left := index * card_step
	if left < offset: jump_to(left)
	elif left + card_width > offset + size.x: jump_to(left + card_width - size.x)

func suppress_clicks() -> bool:
	return (_pointer_down and _dragged) or Time.get_ticks_msec() < _ignore_click_until

func _local_point(point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * point

func _inside(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(_local_point(point))

func _start_pointer(point: Vector2) -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	_pointer_down = true
	_dragged = false
	_press_local = _local_point(point)
	_press_offset = offset

func _move_pointer(point: Vector2) -> void:
	if not _pointer_down: return
	var displacement := _local_point(point) - _press_local
	if not _dragged and absf(displacement.x) >= DRAG_THRESHOLD and absf(displacement.x) > absf(displacement.y):
		_dragged = true
		for button in find_children("*", "BaseButton", true, false):
			button.notification(Control.NOTIFICATION_SCROLL_BEGIN)
			button.set_pressed_no_signal(false)
	if _dragged:
		set_scroll_offset(_press_offset - displacement.x)
		get_viewport().set_input_as_handled()

func _end_pointer() -> void:
	if not _pointer_down: return
	_pointer_down = false
	if not _dragged: return
	_ignore_click_until = Time.get_ticks_msec() + 160
	for button in find_children("*", "BaseButton", true, false):
		button.set_pressed_no_signal(false)
		button.notification(Control.NOTIFICATION_SCROLL_END)
	var target := roundf(offset / card_step) * card_step
	# The last partial page is a real stop, so the final card stays fully visible.
	target = clampf(target, 0.0, maximum_offset())
	if absf(maximum_offset() - offset) < absf(target - offset): target = maximum_offset()
	jump_to(target)
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _inside(event.position): _start_pointer(event.position)
			elif not event.pressed: _end_pointer()
		elif event.pressed and _inside(event.position):
			if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
				browse(1)
				get_viewport().set_input_as_handled()
			elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
				browse(-1)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_move_pointer(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _inside(event.position):
			_touch_index = event.index
			_start_pointer(event.position)
		elif not event.pressed and event.index == _touch_index:
			_end_pointer()
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_move_pointer(event.position)
	elif event is InputEventPanGesture and _inside(event.position):
		jump_to(offset + event.delta.x * 50.0, false)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT]:
		browse(-1 if event.keycode == KEY_LEFT else 1)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_pointer_down = false
		_touch_index = -1
		_dragged = false
