extends Control

var node_data_map: Dictionary = {}

func set_map_data(data: Dictionary) -> void:
	node_data_map = data
	queue_redraw()

func _draw() -> void:
	for nid in node_data_map:
		var item = node_data_map[nid]
		var from_pos: Vector2 = item["pos"]
		var ndata: MapNodeData = item["data"]
		
		for next_id in ndata.connected_next_node_ids:
			if node_data_map.has(next_id):
				var to_pos: Vector2 = node_data_map[next_id]["pos"]
				var to_data: MapNodeData = node_data_map[next_id]["data"]
				
				var line_color = Color(0.35, 0.4, 0.5, 0.5)
				var width = 2.5
				
				if ndata.state == MapNodeData.NodeState.VISITED and to_data.state == MapNodeData.NodeState.VISITED:
					line_color = ThemePalette.MINT # 已通过路径
					width = 4.0
				elif ndata.state == MapNodeData.NodeState.VISITED and to_data.state == MapNodeData.NodeState.AVAILABLE:
					line_color = ThemePalette.GOLD # 当前可前进路径
					width = 4.0
				elif ndata.state == MapNodeData.NodeState.AVAILABLE and to_data.state == MapNodeData.NodeState.LOCKED:
					line_color = Color(0.45, 0.55, 0.7, 0.7)
					width = 3.0
				
				var start := from_pos
				var end := to_pos
				if item.has("line_half_extent"):
					var delta: Vector2 = to_pos - from_pos
					var half: Vector2 = item["line_half_extent"]
					var ratio: float = maxf(absf(delta.x) / half.x, absf(delta.y) / half.y)
					if ratio > 0.0: start += delta / ratio
					var target_half: Vector2 = node_data_map[next_id].get("line_half_extent", half)
					var target_ratio: float = maxf(absf(delta.x) / target_half.x, absf(delta.y) / target_half.y)
					if target_ratio > 0.0: end -= delta / target_ratio
				draw_line(start, end, line_color, width, true)
