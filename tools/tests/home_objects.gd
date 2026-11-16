extends "res://tools/tests/p5_regions.gd"

func _run() -> void:
 state = get_tree().root.get_node("GameState")
 life = get_tree().root.get_node("CampusLife")
 flow = get_tree().root.get_node("SceneManager")
 saves = get_tree().root.get_node("SaveManager")
 cycle = get_tree().root.get_node("DayCycle")
 cycle.suspended = true
 saves.active_session = false
 saves.settings["reduced_motion"] = true
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--captures="): captures = arg.trim_prefix("--captures=")
 if captures != "": DirAccess.make_dir_recursive_absolute(captures)
 var cases := []
 for slug in ["nomos","agora","techne"]:
  var before := checks
  var failures_before := failures.size()
  await _check_home(slug)
  cases.append({"region":slug,"checks":checks-before,"failures":failures.size()-failures_before})
 print("HOME_OBJECT_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"renderer":DisplayServer.get_name(),"cases":cases}))
 get_tree().quit(0 if failures.is_empty() else 1)

func _check_home(slug: String) -> void:
 check(state.new_game(),"object fixture new game")
 flow.change_scene(flow.TargetScene.HOME)
 await settled()
 state.set_story_flag("region_"+slug+"_unlocked",true)
 check(life.enter_region("university_"+slug),"object Home first entry")
 await settled()
 check(life.complete_first_visit(),"object Home arrival completed")
 await settled()
 var home: CampusScreen = get_tree().current_scene
 var view := home.object_home
 check(is_instance_valid(view) and view.objects.size() == 4,"four independently extracted object buttons")
 var initial: Dictionary = state.export_progress(false)
 await capture(slug+"_normal")
 # Isolate the alpha-mask input check from intentionally clickable caption plates.
 for object in view.objects.values(): object.label_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for id in view.objects:
  var object: HomeObjectButton = view.objects[id]
  var plate := object.label_plate
  var canvas := get_viewport().get_visible_rect()
  check(canvas.encloses(plate.get_global_rect()),"caption stays on canvas: "+slug+"/"+id)
  check(not plate.get_global_rect().intersects(view.clock.get_global_rect()) and not plate.get_global_rect().intersects(view.remaining.get_global_rect()),"date/status do not overlap caption: "+slug+"/"+id)
  var function_text: Label = plate.get_node("Function")
  check(function_text.get_minimum_size().x <= function_text.size.x,"function text fits: "+slug+"/"+id)
  var mask := object.texture_click_mask
  check(mask.get_true_bit_count() > 0 and mask.get_true_bit_count() < mask.get_size().x*mask.get_size().y,"alpha silhouette rather than full rectangle: "+id)
  check(not mask.get_bit(0,mask.get_size().y-1),"transparent object corner excluded: "+id)
  # Mouse clicks inside transparent texture padding must reach the scene behind it.
  var empty := object.get_global_transform()*Vector2(0.1,object.size.y-0.1)
  for down in [true,false]:
   var event := InputEventMouseButton.new()
   event.position = empty
   event.button_index = MOUSE_BUTTON_LEFT
   event.pressed = down
   get_viewport().push_input(event,true)
   await get_tree().process_frame
  check(not is_instance_valid(home._workspace) and not is_instance_valid(home.dialogue) and not flow.is_transitioning,"transparent padding does not activate a function: "+id)
  view.select_object(id)
  check(object.selected and object.material.get_shader_parameter("emphasis") == 1.0,"selected object visibly emphasized: "+id)
  object.hovered = true
  object._refresh()
  check(object.material.get_shader_parameter("emphasis") == 1.0,"selected hover preserves selection appearance: "+id)
  await capture(slug+"_selected_"+id)
  view.select_object()
  object.hovered = false
  object._refresh()
 for object in view.objects.values(): object.label_plate.mouse_filter = Control.MOUSE_FILTER_STOP
 # Actual pointer down/up exercises press feedback and card workspace routing.
 var cards: HomeObjectButton = view.objects["workshop"]
 var point := opaque_point(cards)
 # Clear the real pointer target after the selected-state screenshot fixture.
 # Otherwise no mouse_entered is emitted when that target was already hovered.
 var exit_motion := InputEventMouseMotion.new()
 exit_motion.position = Vector2(930,1050)
 get_viewport().push_input(exit_motion,true)
 await get_tree().process_frame
 var motion := InputEventMouseMotion.new()
 motion.position = point
 get_viewport().push_input(motion,true)
 await get_tree().process_frame
 check(cards.hovered,"pointer hovering furniture is detected")
 await capture(slug+"_hover")
 var press := InputEventMouseButton.new()
 press.position = point
 press.button_index = MOUSE_BUTTON_LEFT
 press.pressed = true
 get_viewport().push_input(press,true)
 await get_tree().process_frame
 check(cards.held,"pointer down has pressed feedback")
 await capture(slug+"_pressed")
 press = InputEventMouseButton.new()
 press.position = point
 press.button_index = MOUSE_BUTTON_LEFT
 press.pressed = false
 get_viewport().push_input(press,true)
 await get_tree().process_frame
 check(is_instance_valid(home._workspace) and cards.selected,"card furniture opens shared workspace and remains selected")
 await key(KEY_ESCAPE)
 await get_tree().process_frame
 check(not is_instance_valid(home._workspace) and view.selected_id == "","closing workspace clears selection")
 check(get_viewport().gui_get_focus_owner() == cards,"workspace returns focus to furniture")
 # Caption and keyboard are alternate entry points to the same object action.
 await click(view.objects["records"].label_plate)
 check(is_instance_valid(home._workspace) and view.selected_id == "records","live caption activates the matching furniture")
 await key(KEY_ESCAPE)
 await get_tree().process_frame
 var partner: HomeObjectButton = view.objects["partner_test"]
 partner.grab_focus()
 await key(KEY_ENTER)
 check(is_instance_valid(home.dialogue) and partner.selected,"keyboard opens partner interaction with persistent selection")
 check(partner.disabled,"modal dialogue blocks object input")
 await key(KEY_ESCAPE)
 await get_tree().process_frame
 check(not is_instance_valid(home.dialogue) and not partner.selected and not partner.disabled,"closing dialogue clears selection and restores object input")
 check(get_viewport().gui_get_focus_owner() == partner,"partner dialogue returns keyboard focus")
 check(state.export_progress(false) == initial,"object interactions preserve time, rewards and save state")
 saves.settings["reduced_motion"] = false
 view.select_object("records")
 check(view.objects["records"].material.get_shader_parameter("emphasis") == 1.0,"static selection feedback also works with full motion setting")
 view.select_object()
 await click(view.refs["map_button"])
 check(flow.current_scene_type == flow.TargetScene.LOCAL_MAP and life.map_region_id == "university_"+slug,"map furniture opens correct region map")
 await key(KEY_ESCAPE)
 await settled()
 check(life.current_location == slug+"_home_test" and get_tree().current_scene.object_home.selected_id == "","map returns to reconstructed Home without stale selection")
 var returned: CampusScreen = get_tree().current_scene
 var day := DayCycle.day_for_date(12,31)
 state.set_game_time(day,20,0,DayCycle.weekday_for_day(day))
 await get_tree().process_frame
 check(returned.object_home.clock.text.contains("12月31日") and returned.object_home.clock.text.contains("夜晚"),"live long date and night label: "+slug)
 check(returned.object_home.clock.get_minimum_size().x <= returned.object_home.clock.size.x,"long date fits: "+slug)
 await capture(slug+"_long_date")

func opaque_point(button: HomeObjectButton) -> Vector2:
 var mask := button.texture_click_mask
 var extent := mask.get_size()
 for y in range(extent.y/3,extent.y*2/3,3):
  for x in range(extent.x/3,extent.x*2/3,3):
   if mask.get_bit(x,y) and mask.get_bit(x-2,y) and mask.get_bit(x+2,y) and mask.get_bit(x,y-2) and mask.get_bit(x,y+2): return button.get_global_transform()*Vector2((float(x)+0.5)/extent.x*button.size.x,(float(y)+0.5)/extent.y*button.size.y)
 return button.get_global_rect().get_center()
