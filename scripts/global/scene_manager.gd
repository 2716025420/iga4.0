class_name ProjectSceneFlow
extends CanvasLayer

signal scene_transition_started
signal scene_transition_completed
signal scene_transition_failed(message: String)

enum TargetScene { HOME, EXPLORATION, COMBAT, STORY, TITLE, CAMPUS_LIFE, LOCAL_MAP, REGION_ATLAS }
const SCENE_PATHS: Dictionary = {
 TargetScene.HOME:"res://scenes/home/home_screen.tscn",
 TargetScene.EXPLORATION:"res://scenes/exploration/node_map.tscn",
 TargetScene.COMBAT:"res://scenes/combat/combat_screen.tscn",
 TargetScene.STORY:"res://scenes/story/dialogue_screen.tscn",
 TargetScene.TITLE:"res://scenes/title/title_screen.tscn",
 TargetScene.CAMPUS_LIFE:"res://scenes/campus/campus_screen.tscn",
 TargetScene.LOCAL_MAP:"res://scenes/campus/local_map_screen.tscn",
 TargetScene.REGION_ATLAS:"res://scenes/campus/region_atlas_screen.tscn"
}
const DESTINATIONS := {TargetScene.HOME:"回到教室",TargetScene.EXPLORATION:"进入训练路线",TargetScene.COMBAT:"准备练习",TargetScene.STORY:"翻开下一段故事",TargetScene.TITLE:"回到放学以后",TargetScene.CAMPUS_LIFE:"去往下一处地点",TargetScene.LOCAL_MAP:"展开地区地图",TargetScene.REGION_ATLAS:"展开地区总图"}
const MIN_LOADING_SECONDS := 0.75
const LOAD_TIMEOUT_SECONDS := 30.0
var current_scene_type: TargetScene = TargetScene.HOME
var is_transitioning: bool = false
var last_error: String = ""
var last_transition: Dictionary = {}
var _loading: SceneLoadingScreen
var _dialogue_fade: ColorRect
var _battle_entry: BattleEntryTransition
var _previous_focus: Control

func _ready() -> void:
 layer = 100
 process_mode = Node.PROCESS_MODE_ALWAYS
 _loading = SceneLoadingScreen.new()
 add_child(_loading)
 _dialogue_fade = ColorRect.new()
 _dialogue_fade.name = "DialogueTransition"
 _dialogue_fade.color = Color("#173447")
 _dialogue_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _dialogue_fade.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(_dialogue_fade)
 _dialogue_fade.hide()
 _battle_entry = BattleEntryTransition.new()
 add_child(_battle_entry)
 var reward_cards: Node = load("res://scripts/ui/reward_card_popup.gd").new()
 add_child(reward_cards)

func _input(_event: InputEvent) -> void:
 if is_transitioning: get_viewport().set_input_as_handled()

func change_scene(target: TargetScene, _params: Dictionary = {}) -> void:
 if is_transitioning: return
 is_transitioning = true
 last_error = ""
 _previous_focus = get_viewport().gui_get_focus_owner()
 var current := get_tree().current_scene
 var battle_exit := current_scene_type == TargetScene.COMBAT and target != TargetScene.COMBAT
 var battle_entry := target == TargetScene.COMBAT or battle_exit
 var reuse_dialogue := target == TargetScene.STORY and is_instance_valid(current) and current.has_method("load_dialogue")
 last_transition = {"target":target,"mode":("battle_exit" if battle_exit else "battle_wipe") if battle_entry else ("dialogue" if reuse_dialogue else "loading"),"success":false,"started_msec":Time.get_ticks_msec(),"resource_progress":0.0}
 scene_transition_started.emit()
 if reuse_dialogue:
  # Same reading view: a short dusk fade keeps consecutive dialogue lightweight.
  _dialogue_fade.modulate.a = 0.0
  _dialogue_fade.show()
  await _fade(_dialogue_fade,1.0,SaveManager.motion_duration(0.12))
  current.call("load_dialogue",GameState.pending_dialogue_id)
  current_scene_type = target
  await get_tree().process_frame
  await _fade(_dialogue_fade,0.0,SaveManager.motion_duration(0.12))
  _dialogue_fade.hide()
  _complete_transition()
  return
 if battle_entry:
  if target == TargetScene.COMBAT:
   AudioManager.play_sfx_cutin()
  _battle_entry.present(battle_exit)
 else:
  if target in [TargetScene.STORY, TargetScene.EXPLORATION, TargetScene.LOCAL_MAP, TargetScene.REGION_ATLAS]:
   AudioManager.play_sfx_page_flip()
  _loading.present(DESTINATIONS.get(target,"去往下一站"),SceneLoadingScreen.theme_for_context(target,CampusLife.current_region,CampusLife.current_location))
  await _fade(_loading,1.0,SaveManager.motion_duration(0.18))
 # Render the transition before requesting or instantiating a heavy scene.
 await get_tree().process_frame
 await get_tree().process_frame
 var path: String = SCENE_PATHS.get(target,"")
 if target == TargetScene.EXPLORATION and GameState.exploration_active and SchoolExplorationFlow.enabled():
  path = "res://scenes/exploration/school_route_screen.tscn"
 last_transition["path"] = path
 if path.is_empty() or not ResourceLoader.exists(path,"PackedScene"):
  await _fail_transition("场景暂时不可用，请稍后再试。")
  return
 var request_error := ResourceLoader.load_threaded_request(path,"PackedScene",false)
 if request_error != OK:
  await _fail_transition("没能开始读取场景，请稍后再试。")
  return
 if battle_entry: await _battle_entry.cover()
 var load_started := Time.get_ticks_msec()
 var packed: PackedScene
 while true:
  var resource_progress: Array = []
  var state := ResourceLoader.load_threaded_get_status(path,resource_progress)
  if not resource_progress.is_empty():
   last_transition["resource_progress"] = float(resource_progress[0])
   _loading.set_progress(float(resource_progress[0]),"正在读取场景")
  if state == ResourceLoader.THREAD_LOAD_LOADED:
   packed = ResourceLoader.load_threaded_get(path) as PackedScene
   break
  if state in [ResourceLoader.THREAD_LOAD_FAILED,ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
   await _fail_transition("这次读取没有完成，请稍后再试。")
   return
  if (Time.get_ticks_msec()-load_started)/1000.0 > LOAD_TIMEOUT_SECONDS:
   await _fail_transition("读取时间有些长，请稍后再试。")
   return
  await get_tree().process_frame
 if packed == null:
  await _fail_transition("场景内容暂时不可用，请稍后再试。")
  return
 last_transition["resource_progress"] = 1.0
 _loading.set_progress(1.0,"场景资源已就绪")
 var visible_seconds := 0.0 if battle_entry else (0.45 if bool(SaveManager.settings["reduced_motion"]) else MIN_LOADING_SECONDS)
 while (Time.get_ticks_msec()-int(last_transition["started_msec"]))/1000.0 < visible_seconds:
  await get_tree().process_frame
 _loading.set_progress(1.0,"正在进入下一幕")
 var change_error := get_tree().change_scene_to_packed(packed)
 if change_error != OK:
  await _fail_transition("没能进入场景，请稍后再试。")
  return
 await get_tree().scene_changed
 current_scene_type = target
 if target != TargetScene.COMBAT:
  AudioManager.play_bgm_for_scene(target,false,GameState.pending_dialogue_id)
 # The new scene has run _ready; give deferred layouts and its first frame time to settle.
 await get_tree().process_frame
 await get_tree().process_frame
 _loading.set_progress(1.0,"准备好了")
 if battle_entry: await _battle_entry.reveal()
 else:
  await _fade(_loading,0.0,SaveManager.motion_duration(0.22))
  _loading.hide()
 _complete_transition()

func _fade(control: Control, opacity: float, duration: float) -> void:
 if duration <= 0.0:
  control.modulate.a = opacity
  return
 var tween := create_tween()
 tween.tween_property(control,"modulate:a",opacity,duration).set_trans(Tween.TRANS_SINE)
 await tween.finished

func _fail_transition(message: String) -> void:
 last_error = message
 last_transition["error"] = message
 scene_transition_failed.emit(message)
 if last_transition.get("mode","") in ["battle_wipe","battle_exit"]:
  await _battle_entry.reveal()
  _finish_transition()
  return
 _loading.show_failure(message)
 await get_tree().create_timer(1.25).timeout
 await _fade(_loading,0.0,SaveManager.motion_duration(0.18))
 _loading.hide()
 _finish_transition()

func _complete_transition() -> void:
 last_transition["success"] = true
 _finish_transition()

func _finish_transition() -> void:
 last_transition["elapsed_msec"] = Time.get_ticks_msec()-int(last_transition["started_msec"])
 is_transitioning = false
 if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
  _previous_focus.grab_focus()
 _previous_focus = null
 scene_transition_completed.emit()
