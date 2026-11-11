class_name MapNodeData
extends Resource

enum NodeType {
	STORY,      ## 剧情/AVG对话
	BATTLE,     ## 普通遭遇战
	ELITE,      ## 精英战斗
	CHEST,      ## 物资宝箱/新卡牌
	REST,       ## 营地休息/回血
	EVENT,      ## 奇遇文字抉择
	BOSS        ## 区域首领关底战
}

enum NodeState {
	LOCKED,     ## 未解锁
	AVAILABLE,  ## 当前可前往
	VISITED     ## 已完成
}

@export var node_id: String = ""
@export var layer_index: int = 0
@export var node_type: NodeType = NodeType.BATTLE
@export var title: String = "未命名地点"
@export var description: String = ""
@export var connected_next_node_ids: Array = []

# 节点关联的具体资源 ID (如 dialogue_id, enemy_group_id, chest_card_id 等)
@export var content_id: String = ""
@export var state: NodeState = NodeState.LOCKED
