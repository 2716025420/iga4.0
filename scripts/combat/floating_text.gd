extends Label

enum TextType { DAMAGE, HEAL, SHIELD, MISS, BUFF }

func init_floating(text_str: String, type: TextType, start_pos: Vector2) -> void:
	text = text_str
	global_position = start_pos + Vector2(randf_range(-15, 15), randf_range(-10, 10))
	z_index = 50
	
	# 设置字体颜色与描边
	var font_color = Color.WHITE
	match type:
		TextType.DAMAGE:
			font_color = Color("#ff4757") # 亮红
		TextType.HEAL:
			font_color = Color("#2ed573") # 亮绿
		TextType.SHIELD:
			font_color = Color("#1e90ff") # 亮蓝
		TextType.BUFF:
			font_color = Color("#ffa502") # 亮橙
		TextType.MISS:
			font_color = Color("#a4b0be") # 灰白
	
	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 4)
	add_theme_font_size_override("font_size", 24)
	
	# 向上飘浮并淡出动效
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 45.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.2)
	
	await tween.finished
	queue_free()
