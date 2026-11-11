class_name PhaseTwoContent
extends RefCounted

# 二阶段临时内容。它只验证校园章节结构，后续正式剧本可整体替换。
const CHAPTER_TITLE: String = "第一章 · 放学后的那条路"
const CHARACTER_ROOT: String = "res://assets/sprites/characters/phase_two/halfbody/"
const ENEMY_ROOT: String = "res://assets/sprites/enemies/phase_two/"
const ACTORS: Dictionary = {
	"ye_zhou": {"name":"叶舟","title":"想平静放学的学生","bio":"观察细致，习惯先想办法再行动。眼下最大的愿望是按时回家，顺路买到喜欢的面包。"},
	"yang_zi_ying": {"name":"杨子英","title":"总有新计划的同学","bio":"热心、行动快，喜欢摄影和橘子汽水。想拍下上学路最漂亮的夕阳，也不愿把朋友留在危险里。"},
	"liu_yu_long": {"name":"柳宇龙","title":"不服输的同班同学","bio":"爱开玩笑，也很在意别人是否认真看待自己。一次光明正大的胜利，比嘴上占便宜更重要。"},
	"jiang_zi": {"name":"姜梓","title":"认真负责的校园事务员","bio":"负责整理校园事务与值日表。嘴上嫌麻烦，遇到问题总会先把信息核对清楚，让大家少走弯路。"}
}
const FLOW_STEPS: Array[Dictionary] = [
	{"node":"n0","dialogue":"campus_morning","title":"上学路"},
	{"node":"n_gate","dialogue":"school_gate","title":"校门前"},
	{"node":"n_affairs","dialogue":"school_affairs","title":"课间事务"},
	{"node":"n_dusk","dialogue":"after_school","title":"放学黄昏"},
	{"node":"n_guard","enemy":"security_guard","title":"保安拦路"},
	{"node":"n_rescue","dialogue":"yang_rescue","title":"路上的援手"},
	{"node":"n_robot","enemy":"campus_robot","title":"巡逻机器人"},
	{"node":"n5_boss","dialogue":"principal_confrontation","enemy":"principal","title":"校长现身"},
	{"node":"n_find_yang","dialogue":"find_yang","title":"归途"}
]
const SCRIPTS: Dictionary = {
	"campus_morning": [{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"今天只要不迟到，放学后应该能赶上面包店最后一炉。计划非常严谨。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"叶舟，早！你走这么快，是为了学习，还是为了那家面包店？"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"两者并不冲突。只是面包凉了比较难补救。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"那放学记得还走这条路。黄昏的光很好，我想给摄影社补一张照片。","choices":[{"text":"好，到时候帮你拿反光板。","favor_char":"yang_zi_ying","favor_add":10},{"text":"可以，报酬是一瓶橘子汽水。","favor_char":"yang_zi_ying","favor_add":5}]},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"先说好，如果上课铃响了，我们都得跑。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"那就现在跑！我可不想让班主任把照片标题改成《迟到的两个人》。"}],
	"school_gate": [{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"叶舟，今天放学来一局？上次你赢得太安静，我还没来得及找借口。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"所以这次你提前准备好了？"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"我准备了实力。还有三个备用借口，但那不重要。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"先把校服领子整理好，实力选手。值日生已经看你半天了。"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"行。放学见，我想赢一次认真的。你可别偷偷溜去买面包。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"看来我的日程已经公开得很彻底了。"}],
	"school_affairs": [{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"你们三位，课间借我五分钟。校园活动的登记表和出入记录对不上。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"五分钟可以。需要我们做什么？"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"核对社团名单。杨子英交照片，柳宇龙把比赛时间写清楚，叶舟检查重复条目。"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"我在这里的职责就这么普通？"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"你也可以负责把字写得能看懂。这项任务的难度比较高。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"别笑啦。姜梓想今天交完，我们帮她早点放学。"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"谢谢。还有一件事：新安防系统的人工命令会覆盖普通通知。如果广播不对劲，先看纸质疏散图。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"我记住了。希望今天用不上。"}],
	"after_school": [{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"夕阳倒是准时到了。校门怎么还关着？"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"公告说正常放学，广播却要求所有人留校。两份命令的时间戳只差一分钟。"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"挑战延期。现在我更想赢过这扇门。"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"门禁被最高管理权限改写了。我留在办公室核对日志，柳宇龙去通知后面的同学走侧门。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"我先去侧门看看。杨子英应该还在早上的那条路上拍照。"},{"speaker":"校园保安","char":"security_guard","side":"right","text":"收到留校指令。把证件和手机交出来，不许再往外走。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"这条指令没有说明理由。请让后面的同学先离开。"},{"speaker":"校园保安","char":"security_guard","side":"right","text":"我得执行命令。你退后！"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"没法好好解释了。先挡住他，别让人挤到关闭的门边。"}],
	"yang_rescue": [{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"保安终于停手了。他说命令直接来自校长，可平时的校长根本不会这样。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"叶舟！别往前——！"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"欸？"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"抓紧我！隔离栏正在落下，刚才差一点就把你压在里面了。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"多亏你。早上约的拍照，怎么变成救命了？"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"说明我的课外活动范围很广。先别站起来，机器人还在路口。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"你先去树后面。我停下它，再去找你。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"说定了。还有，刚才的报酬改一下：你欠我一瓶橘子汽水。"}],
	"principal_confrontation": [{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"日志核对完了。封路、扣留学生、机器人强制拦截，全部是校长本人签发的。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"不是系统误报？"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"不是。每一步都绕开了安全限制，执行顺序也很清楚。"},{"speaker":"校长","char":"principal","side":"right","text":"你们终于学会查记录了。可惜，权限在我手上。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"你知道这些命令会伤到学生。为什么还要继续？"},{"speaker":"校长","char":"principal","side":"right","text":"我当然知道。我定下的规矩、维护的名声、你们相信的安全——今天，我要亲手把它们一件件毁掉。"},{"speaker":"校长","char":"principal","side":"right","text":"我没有糊涂。哪一扇门先锁，谁会去救谁，我都算过。我的身份，正好让你们来不及怀疑。"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"日志已经发出去了。你的权限不会一直有效。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"原因以后查。现在先停下他，让所有人离开。"}],
	"find_yang": [{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"校长的控制权限已经切断。校外的应急人员正在接手，同学们可以安全离开了。"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"我把人都带出来了。今天的比赛算平局，谁也不许说我逃赛。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"没人这么说。杨子英还在路口等我，我得去找她。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"我在这儿！你看起来比早上狼狈了一点。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"计划出了点意外。面包没赶上，汽水应该还来得及。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"你回来就好。照片下次再拍，今天先把这条路安全走完。"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"发生了什么还需要调查，不能把它当成普通的情绪失控。我把记录留好了。"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"那我也留个记录：某人欠两场比赛和一份面包。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"怎么连面包都欠上了？"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"走吧，叶舟。至少夕阳没有迟到。"}],
	"chat_yang": [{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"下一张照片想拍得简单一点：天空、树影，还有刚好路过的人。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"我可以路过，但别把迟到也拍进去。"},{"speaker":"杨子英","char":"yang_zi_ying","side":"right","text":"放心，这次我们慢慢走。"}],
	"chat_liu": [{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"下次比赛我想认真赢你一次。赢了之后再考虑说什么。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"我会认真应战。借口先留在书包里。"},{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","text":"你怎么知道我还有备用的？"}],
	"chat_jiang": [{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"登记表终于核对完了。今天的记录，我想按实际发生的事写。"},{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"需要帮忙的话叫我。"},{"speaker":"姜梓","char":"jiang_zi","side":"right","text":"有。先把这杯已经放凉的茶换掉。"}]
}

static func lines_for(dialogue_id: String) -> Array[Dictionary]:
	var resolved := dialogue_id
	match dialogue_id:
		"prologue_intro", "chapter_1_intro": resolved = "campus_morning"
		"chapter_1_pre_boss": resolved = "principal_confrontation"
		"chapter_1_post_boss": resolved = "find_yang"
	var output: Array[Dictionary] = []
	for entry in SCRIPTS.get(resolved, [{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"今天的故事还没开始，先回休息室。"}]):
		output.append(entry.duplicate(true))
	return output

static func character_path(character_id: String) -> String:
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi"}
	var actual: String = aliases.get(character_id, character_id)
	var file := CHARACTER_ROOT + actual + ".png" if ACTORS.has(actual) else ENEMY_ROOT + actual + ".png"
	return file if ResourceLoader.exists(file) else ""

## Dialogue uses waist-up portraits; combat keeps the full-body enemy sprites.
static func dialogue_character_path(character_id: String, emotion: String = "neutral") -> String:
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi"}
	var actual: String = aliases.get(character_id, character_id)
	var actor_path := character_path(character_id)
	if ACTORS.has(actual):
		var resolved_emotion := emotion.strip_edges().to_lower()
		if resolved_emotion == "concerned":
			resolved_emotion = "worried"
		if not resolved_emotion in ["neutral", "happy", "shy", "surprised", "angry", "worried"]:
			resolved_emotion = "neutral"
		var emotion_path := "res://assets/sprites/characters/phase_two/emotions/%s/%s.png" % [actual, resolved_emotion]
		return emotion_path if ResourceLoader.exists(emotion_path) else actor_path
	var portrait_path := ENEMY_ROOT + "portraits/" + character_id + ".png"
	return portrait_path if ResourceLoader.exists(portrait_path) else actor_path

static func background_key(dialogue_id: String) -> String:
	match dialogue_id:
		"school_gate": return "school_gate"
		"school_affairs", "chat_jiang", "chat_liu", "chat_yang": return "school_room"
		"campus_morning", "prologue_intro", "chapter_1_intro": return "morning_road"
	return "dusk_road"

static func step_for(node_id: String) -> Dictionary:
	for step in FLOW_STEPS:
		if step["node"] == node_id:
			return step.duplicate(true)
	return {}

static func node_for_dialogue(dialogue_id: String) -> String:
	var resolved: String = {"prologue_intro":"campus_morning", "chapter_1_intro":"campus_morning", "chapter_1_pre_boss":"principal_confrontation", "chapter_1_post_boss":"find_yang"}.get(dialogue_id, dialogue_id)
	for step in FLOW_STEPS:
		if step.get("dialogue", "") == resolved:
			return step["node"]
	return ""

static func current_objective() -> String:
	if GameState.story_flags.get("chapter_1_completed", false):
		return "今天的行程已经结束。慢慢休息，下一次再一起出发。"
	var node_id: String = GameState.next_phase_two_node()
	return {"n0":"沿着熟悉的上学路，去学校。", "n_gate":"到校门前，和同学打个招呼。", "n_affairs":"课间去事务室，帮忙核对登记表。", "n_dusk":"放学了，确认出口后离开校园。", "n_guard":"先保护身后的同学，找到离校的空隙。", "n_rescue":"回到熟悉的路上，确认周围安全。", "n_robot":"停止路口的异常拦截。", "n5_boss":"和姜梓核对日志，阻止眼前的危险。", "n_find_yang":"去路口找杨子英，一起走完归途。"}.get(node_id, "去学校看看。")

static func timeline_summary() -> String:
	var rows: Array[String] = []
	if GameState.visited_node_ids.has("n0"):
		rows.append("上学 · 在路上遇见杨子英。")
	if GameState.visited_node_ids.has("n_gate"):
		rows.append("校门 · 柳宇龙约了一场放学后的比赛。")
	if GameState.visited_node_ids.has("n_affairs"):
		rows.append("课间 · 和姜梓一起核对登记表。")
	if GameState.visited_node_ids.has("n_dusk"):
		rows.append("放学 · 校门关闭，广播与公告出现矛盾。")
	if GameState.visited_node_ids.has("n_rescue"):
		rows.append("归途 · 杨子英在隔离栏落下前拉住了叶舟。")
	if GameState.story_flags.get("principal_stopped", false):
		rows.append("黄昏 · 异常管理权限已被切断，应急人员接手。")
	if GameState.story_flags.get("chapter_1_completed", false):
		rows.append("归途 · 找到杨子英，大家安全离校。")
	return "\n".join(rows) if not rows.is_empty() else "今天的故事还没有开始。"

static func quest_text() -> String:
	return "[b]现在要做的事[/b]\n" + current_objective() + "\n\n[b]今天的足迹[/b]\n" + timeline_summary()

static func records_text() -> String:
	var names: Array[String] = ["叶舟"]
	if GameState.visited_node_ids.has("n0"): names.append("杨子英")
	if GameState.visited_node_ids.has("n_gate"): names.append("柳宇龙")
	if GameState.visited_node_ids.has("n_affairs"): names.append("姜梓")
	return "[b]今天遇见的人[/b]\n" + " · ".join(names) + "\n\n[b]已经发生的事[/b]\n" + timeline_summary()

static func apply_scene_labels(root: Control) -> void:
	var replacements: Dictionary = {}
	match String(root.name):
		"WorldMap":
			replacements = {"TopBar/Title": "校园篇章", "TopBar/BackButton": "返回休息室", "MapCanvas/RegionCh1": "第一章\n放学后的那条路", "MapCanvas/RegionCh2": "后续篇章\n整理中", "MapCanvas/RegionCh3": "自由活动\n整理中"}
		"NodeMap":
			replacements = {"TopBar/RetreatButton": "返回休息室", "EventModal/VBox/ConfirmBtn": "继续行程"}
		"DialogueScreen":
			replacements = {"ControlBar/AutoButton": "自动", "ControlBar/SkipButton": "跳过此段"}
	for node_path in replacements:
		var label: Node = root.get_node_or_null(node_path)
		if label != null:
			label.set("text", replacements[node_path])
