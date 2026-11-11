class_name WorldMap
extends Control

@onready var region_btn_ch1: Button = $MapCanvas/RegionCh1
@onready var region_btn_ch2: Button = $MapCanvas/RegionCh2
@onready var region_btn_ch3: Button = $MapCanvas/RegionCh3

@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_title: Label = $InfoPanel/VBox/TitleLabel
@onready var info_desc: RichTextLabel = $InfoPanel/VBox/DescLabel
@onready var enter_button: Button = $InfoPanel/VBox/EnterButton
@onready var back_button: Button = $TopBar/BackButton

var selected_chapter_id: String = "chapter_1"

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	enter_button.pressed.connect(_on_enter_pressed)
	
	region_btn_ch1.pressed.connect(func(): _select_region("chapter_1"))
	region_btn_ch2.pressed.connect(func(): _select_region("chapter_2"))
	region_btn_ch3.pressed.connect(func(): _select_region("chapter_3"))
	
	_select_region("chapter_1")
	PhaseTwoContent.apply_scene_labels(self)
	DaylightUI.apply(self)

func _select_region(chap_id: String) -> void:
	selected_chapter_id = chap_id
	match chap_id:
		"chapter_1":
			info_title.text = PhaseTwoContent.CHAPTER_TITLE
			var status := "从上学路开始今天的行程。" if GameState.visited_node_ids.is_empty() else "今日行程进行中：已完成 %d 个步骤。" % GameState.visited_node_ids.size()
			if GameState.story_flags.get("chapter_1_completed", false):
				status = "本章已完成。进入后可重新开始。"
			info_desc.text = "[b]校园篇章[/b]\n" + status + "\n\n清晨遇见杨子英，校门前接受柳宇龙的挑战，课间帮助姜梓处理校园事务。\n\n放学黄昏出现异常，依次应对保安、机器人，最后阻止校长。事情平息后，去那条熟悉的路上找杨子英。\n\n[b]行动准备[/b]\n找准空隙 · 书包格挡 · 补充水分 · 连续牵制"
			enter_button.disabled = false
			enter_button.text = "重新开始本章" if GameState.story_flags.get("chapter_1_completed", false) else ("开始今日行程" if GameState.visited_node_ids.is_empty() else "继续今日行程")
		_:
			info_title.text = "后续内容 · 整理中"
			info_desc.text = "目前可以前往第一章校园。\n\n其他行程尚未开放。"
			enter_button.disabled = true
			enter_button.text = "整理中"
	DaylightUI.polish(info_panel)

func _on_enter_pressed() -> void:
	if selected_chapter_id != "chapter_1":
		return
	if GameState.story_flags.get("chapter_1_completed", false):
		GameState.begin_phase_two_chapter()
	GameState.current_chapter_id = selected_chapter_id
	SceneManager.change_scene(SceneManager.TargetScene.EXPLORATION)

func _on_back_pressed() -> void:
	SceneManager.change_scene(SceneManager.TargetScene.HOME)
