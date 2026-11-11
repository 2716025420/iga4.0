class_name EnemyData
extends Resource

enum EnemyRank { NORMAL, ELITE, BOSS }

@export var id: String = ""
@export var name: String = "未命名敌人"
@export var title: String = ""
@export var rank: EnemyRank = EnemyRank.NORMAL
@export var max_hp: int = 50
@export var base_atk: int = 10
@export var sprite_texture: Texture2D
@export_multiline var description: String = ""

# 技能池定义: 字典数组 [{"name": "普通重击", "type": "attack", "damage": 12, "desc": "猛力挥击"}]
@export var skills: Array = []

# 行动次数机制 (支持多动怪/首领多段连击)
@export var actions_per_turn: int = 1

# BOSS/精英 阶段机制 (如 HP <= 50% 触发暴走)
@export var has_phase_two: bool = false
@export var phase_two_hp_threshold: float = 0.5
@export var phase_two_skill: Dictionary = {}
