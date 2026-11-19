extends Node

const OUTPUT_DIR := "res://.godot/v13_staging/03_Wireframe_Blueprints"
const SPECS := [
	{
		"place": "rooftop",
		"file": "BP_01_rooftop_2340x1080.png",
		"sky": "day",
		"slot_a": "res://assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png",
		"slot_b": ""
	},
	{
		"place": "shop",
		"file": "BP_02_shop_2340x1080.png",
		"sky": "day",
		"slot_a": "res://assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png",
		"slot_b": ""
	},
	{
		"place": "gym",
		"file": "BP_03_gym_2340x1080.png",
		"sky": "day",
		"slot_a": "res://assets/sprites/characters/phase_two/fullbody/liu_yu_long.png",
		"slot_b": ""
	},
	{
		"place": "library",
		"file": "BP_04_library_2340x1080.png",
		"sky": "day",
		"slot_a": "res://assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_neutral.png",
		"slot_b": "res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png"
	},
	{
		"place": "arete_coast_test",
		"file": "BP_05_coast_2340x1080.png",
		"sky": "day",
		"slot_a": "res://assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png",
		"slot_b": ""
	},
	{
		"place": "old_park",
		"file": "BP_06_old_park_2340x1080.png",
		"sky": "dusk",
		"slot_a": "",
		"slot_b": "res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png"
	},
	{
		"place": "arete_beach_test",
		"file": "BP_07_beach_2340x1080.png",
		"sky": "day",
		"slot_a": "res://assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png",
		"slot_b": ""
	}
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var abs_out := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_out)
	var vp := SubViewport.new()
	vp.name = "BlueprintViewport"
	vp.size = Vector2i(2340, 1080)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var exported := 0
	var errors: Array[String] = []
	for raw_spec in SPECS:
		var spec: Dictionary = raw_spec
		for child in vp.get_children():
			vp.remove_child(child)
			child.queue_free()
		var stage := SceneStageLayers.new()
		stage.force_sky_mode = str(spec["sky"])
		stage.configure(str(spec["place"]), true)
		vp.add_child(stage)
		DaylightUI.place(stage, 210.0, 0.0, 1920.0, 1080.0)
		var slot_a_path := str(spec.get("slot_a", ""))
		if slot_a_path != "":
			stage.set_slot_actor("slot_a", slot_a_path)
		var slot_b_path := str(spec.get("slot_b", ""))
		if slot_b_path != "":
			stage.set_slot_actor("slot_b", slot_b_path)
		stage.apply_period_lighting("afternoon" if str(spec["sky"]) == "dusk" else "morning")

		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

		var img := vp.get_texture().get_image()
		var out_path := abs_out.path_join(str(spec["file"]))
		if img == null or img.get_width() != 2340 or img.get_height() != 1080:
			errors.append("invalid size for " + str(spec["file"]))
			continue
		if img.save_png(out_path) != OK:
			errors.append("failed save " + str(spec["file"]))
			continue
		exported += 1

	print("BLUEPRINT_EXPORT_RESULT " + JSON.stringify({"exported": exported, "errors": errors, "output": abs_out}))
	get_tree().quit(0 if errors.is_empty() else 1)
