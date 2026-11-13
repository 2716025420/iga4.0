class_name CardData
extends Resource

enum CardType { ATTACK, DEFENSE, RECOVERY, DEBUFF, SPECIAL }
enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SELF }

@export var id: String = ""
@export var name: String = "新卡牌"
@export_multiline var description: String = ""
@export_multiline var flavor_text: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var icon_texture: Texture2D

@export_group("Stats")
@export var base_cooldown: int = 1       ## 初始冷却回合数 (0表示每回合可用)
@export var damage: int = 0              ## 基础伤害
@export var shield: int = 0              ## 获得护盾
@export var heal: int = 0                ## 生命恢复
@export var burn_damage: int = 0         ## 压制持续伤害
@export var burn_duration: int = 0       ## 压制回合数
@export var attack_down_percent: float = 0.0 ## 降低攻击百分比 (0.3 = 30%)
@export var debuff_duration: int = 0     ## 减益持续回合
@export var reflect_damage: int = 0      ## 反伤数值
@export var level: int = 1               ## 当前强化等级
@export var max_level: int = 3           ## 最大强化等级

func get_current_cooldown(_target_lvl: int = -1) -> int:
	return maxi(1, base_cooldown)

func get_battle_use_limit() -> int:
	return 2 if card_type == CardType.RECOVERY else -1

func _growth_step(target_lvl: int) -> int:
	return clampi(level if target_lvl < 0 else target_lvl, 1, max_level) - 1

func get_scaled_damage(target_lvl: int = -1) -> int:
	return roundi(damage * (1.0 + _growth_step(target_lvl) * 0.12))

func get_scaled_shield(target_lvl: int = -1) -> int:
	return shield + 2 * _growth_step(target_lvl) if shield > 0 else 0

func get_scaled_heal(target_lvl: int = -1) -> int:
	return heal + 3 * _growth_step(target_lvl) if heal > 0 else 0

func get_scaled_burn_damage(target_lvl: int = -1) -> int:
	return burn_damage + _growth_step(target_lvl) if burn_damage > 0 else 0

func get_scaled_attack_down(target_lvl: int = -1) -> float:
	return roundf(minf(0.70, attack_down_percent + _growth_step(target_lvl) * 0.025) * 100.0) / 100.0 if attack_down_percent > 0.0 else 0.0

func get_scaled_reflect_damage(target_lvl: int = -1) -> int:
	return reflect_damage + 2 * _growth_step(target_lvl) if reflect_damage > 0 else 0

func get_dynamic_description(target_lvl: int = -1, use_bbcode: bool = false) -> String:
	var lvl = level if target_lvl < 0 else target_lvl
	var cur_dmg = get_scaled_damage(lvl)
	var cur_shield = get_scaled_shield(lvl)
	var cur_heal = get_scaled_heal(lvl)
	var cur_burn = get_scaled_burn_damage(lvl)
	var cur_atk_down = roundi(get_scaled_attack_down(lvl) * 100)
	var cur_reflect = get_scaled_reflect_damage(lvl)
	
	match id:
		"wrench_smash":
			if use_bbcode:
				return "对单个敌人造成 [color=#C9514B]%d点[/color] 伤害。" % cur_dmg
			return "对单个敌人造成 %d点 伤害。" % cur_dmg
		"scrap_armor", "scrap_shield":
			if use_bbcode:
				return "自身获得 [color=#5B8DD6]%d点[/color] 护盾，持续至本次敌方行动结束。" % cur_shield
			return "自身获得 %d点 护盾，持续至本次敌方行动结束。" % cur_shield
		"icy_soda":
			if use_bbcode:
				return "调整呼吸，恢复叶舟 [color=#6FD3C4]%d点[/color] 体力；每场战斗最多使用2次。" % cur_heal
			return "调整呼吸，恢复叶舟 %d点 体力；每场战斗最多使用2次。" % cur_heal
		"overclock_torch":
			if use_bbcode:
				return "造成 [color=#C9514B]%d点[/color] 伤害，并附加 2 回合“压制”(每回合%d点)。" % [cur_dmg, cur_burn]
			return "造成 %d点 伤害，并附加 2 回合“压制”(每回合%d点)。" % [cur_dmg, cur_burn]
		"fake_cheque":
			if use_bbcode:
				return "转移敌方全体注意，使其造成的伤害降低 [color=#E8833A]%d%%[/color]，持续 2 回合。" % cur_atk_down
			return "转移敌方全体注意，使其造成的伤害降低 %d%%，持续 2 回合。" % cur_atk_down
		"steel_barricade":
			if use_bbcode:
				return "获得 [color=#5B8DD6]%d点[/color] 护盾，本次敌方行动中受击反弹 [color=#E8833A]%d点[/color] 伤害，最多2次。" % [cur_shield, cur_reflect]
			return "获得 %d点 护盾，本次敌方行动中受击反弹 %d点 伤害，最多2次。" % [cur_shield, cur_reflect]
	
	if description != "":
		return description
	return "无特殊效果"

func get_combat_summary() -> String:
	match card_type:
		CardType.ATTACK:
			var hit_text := "全体伤害 %d" if target_type == TargetType.ALL_ENEMIES else "伤害 %d"
			if burn_damage > 0 and burn_duration > 0:
				return (hit_text % get_scaled_damage()) + " · 压制%d×%d回" % [get_scaled_burn_damage(), burn_duration]
			return hit_text % get_scaled_damage()
		CardType.DEFENSE:
			return "护盾 %d" % get_scaled_shield()
		CardType.RECOVERY:
			return "恢复 %d · 限2次" % get_scaled_heal()
		CardType.DEBUFF:
			var target_text := "敌全体伤害 -%d%%" if target_type == TargetType.ALL_ENEMIES else "伤害 -%d%%"
			return (target_text % roundi(get_scaled_attack_down() * 100)) + " · %d回" % debuff_duration
		CardType.SPECIAL:
			return "护盾 %d · 反击 %d×2" % [get_scaled_shield(), get_scaled_reflect_damage()]
	return "无特殊效果"

func get_plain_description() -> String:
	return get_dynamic_description(level, false)

func get_upgrade_preview_text() -> String:
	if level >= max_level:
		return "已达最高等级 %d · 威力已达上限" % max_level
	
	var next_lvl = level + 1
	var diff_texts: Array[String] = []
	
	if damage > 0:
		diff_texts.append("伤害: %d -> %d" % [get_scaled_damage(level), get_scaled_damage(next_lvl)])
	if shield > 0:
		diff_texts.append("护盾: %d -> %d" % [get_scaled_shield(level), get_scaled_shield(next_lvl)])
	if heal > 0:
		diff_texts.append("恢复: %d -> %d" % [get_scaled_heal(level), get_scaled_heal(next_lvl)])
	if burn_damage > 0:
		diff_texts.append("压制: %d -> %d/回合" % [get_scaled_burn_damage(level), get_scaled_burn_damage(next_lvl)])
	if attack_down_percent > 0:
		diff_texts.append("减攻: %d%% -> %d%%" % [roundi(get_scaled_attack_down(level) * 100), roundi(get_scaled_attack_down(next_lvl) * 100)])
	if reflect_damage > 0:
		diff_texts.append("反伤: %d -> %d" % [get_scaled_reflect_damage(level), get_scaled_reflect_damage(next_lvl)])
	
	var cd_curr = get_current_cooldown(level)
	var cd_next = get_current_cooldown(next_lvl)
	if cd_next < cd_curr:
		diff_texts.append("冷却: %d -> %d回合" % [cd_curr, cd_next])
	
	return "练习效果：%s" % " | ".join(diff_texts)
