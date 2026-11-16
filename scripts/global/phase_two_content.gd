class_name PhaseTwoContent
extends RefCounted

# 第一章主线内容：围绕红月学园都市、战术刻印卡、黄秋枫（04号）与六地区巡回赛展开。
const CHAPTER_TITLE: String = "第一章 · 红月下的旧公园与白羊星火"
const CHARACTER_ROOT: String = "res://assets/sprites/characters/phase_two/halfbody/"
const ENEMY_ROOT: String = "res://assets/sprites/enemies/phase_two/"
const ACTORS: Dictionary = {
	"ye_zhou": {"name":"叶舟","title":"阿瑞忒二年级生","bio":"观察细致、习惯冷静寻找破绽的战术刻印卡新手。与黄秋枫在旧公园约定后，踏上追寻真相与六地区巡回赛的旅程。"},
	"huang_qiufeng": {"name":"黄秋枫","title":"转校插班生","bio":"温柔安静却总是慢半拍的转校少女，对校园里的一切日常与情感互动都充满认真而笨拙的好奇。"},
	"yang_zi_ying": {"name":"杨子英","title":"摄影社热心社员","bio":"热心、行动快，喜欢用镜头记录校园夕阳与战术刻印卡切磋。每打出3张卡可发动「快门闪光支援」，兼顾续航与护盾。"},
	"liu_yu_long": {"name":"柳宇龙","title":"竞技对抗狂热者","bio":"爱开玩笑也很不服输，把非致命护盾裁决当成堂堂正正的决斗舞台。每打出3张卡可发动「热血追击重扣」，追加高额单体伤害。"},
	"jiang_zi": {"name":"姜梓","title":"学生会事务干事","bio":"严谨干练，负责核对六地区巡回赛名录与终端安全日志。每打出3张卡可发动「战术统筹屏障」，提供高额护盾并干扰敌方。"},
	"lin_zhi_xia": {"name":"林知夏","title":"图书馆管理员","bio":"阿瑞忒图书馆温和细心的图书委员，常整理泛黄期刊与同学的笔记。"},
	"tang_xiao_man": {"name":"唐小满","title":"校园商店值班员","bio":"精力充沛的校园小店店员，熟知阿瑞忒新上架的刻印卡包与补给趣闻。"}
}
const FLOW_STEPS: Array[Dictionary] = [
	{"node":"n0","dialogue":"campus_morning","title":"樱林解围"},
	{"node":"n_gate","dialogue":"school_gate","enemy":"liu_yu_long_duel","briefing_flag":"school_gate_duel_briefed","title":"赛前切磋"},
	{"node":"n_affairs","dialogue":"school_affairs","title":"旧园名录"},
	{"node":"n_dusk","dialogue":"after_school","title":"黄昏轻吻"},
	{"node":"n_guard","enemy":"security_guard","title":"门岗封锁"},
	{"node":"n_rescue","dialogue":"yang_rescue","title":"灰区奇袭"},
	{"node":"n_robot","enemy":"campus_robot","title":"拦截机械"},
	{"node":"n5_boss","dialogue":"principal_confrontation","enemy":"ch1_hunter_mech","briefing_flag":"principal_briefing_done","title":"红月超限"},
	{"node":"n_find_yang","dialogue":"find_yang","title":"白羊觉醒"}
]
const SCRIPTS: Dictionary = {
	"campus_morning": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"今天只要赶在早读前完成战术刻印卡终端登记，放学后应该还能顺路去老街买面包。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"早呀叶舟！快看樱树那边——有几个高年级生好像在围着新来的转校生！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"拿着高阶卡片炫耀、还想强行要走对方的初始刻印卡吗……真是老套的欺负人方式。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"照校规，卡组切磋必须在双方同意的终端护盾模式下裁决！我拍下来当凭证，叶舟，我们上！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"喂，那边的学长。欺负刚转来的同学算什么本事？想试试战术刻印卡，我陪你用正规裁决模式打一局。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"surprised","text":"唔……对方主动收回终端投影走掉了。谢谢你替我解围，同学。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"我叫叶舟，是二年级B班的。你是今天刚转来的黄秋枫同学吧？别太在意那些家伙。","choices":[{"text":"把你的终端名片交换一下吧，以后有事叫我。","favor_char":"yang_zi_ying","favor_add":5},{"text":"先熟悉一下校园安全规则，战术卡可不能随便让出去。","favor_char":"yang_zi_ying","favor_add":10}]},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"叶、舟……嗯，我记住这个名字了。那……放学以后，还能再和你一起走一段吗？"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"哎呀，好像顺便拍到很有故事感的画面了呢！快走吧，早读铃要响啦！"}
	],
	"school_gate": [
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"叶舟！听说你早上只用基础刻印卡就在护盾裁决里逼退了高年级的家伙？手痒了，放学决斗台来一局认真的！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"那只是他们心虚退场。不过正式热身一局我随时奉陪，你终于学会看卡片冷却回合了？"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"少看不起人！诺莫斯和阿戈拉今年的种子选手都这么卷，咱阿瑞忒这回「六地区巡回赛」可不能掉链子！"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"neutral","text":"战术刻印卡……在日常里是用投影护盾分胜负的竞技，对吗？大家看起来都很投入。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"neutral","text":"没错！只要守着终端安全限幅器，再华丽的爆发技也只是消减护盾值和体能槽，安全又热血！"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"嗯……我在场边看着你们打。等切磋完，放学后再陪我去一次学校后面的旧公园，好不好？"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"当然没问题。柳宇龙，来一局非致命护盾裁决的热身吧！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"这才像话！护盾终端展开，小心我的重扣连击，叶舟——接招！"}
	],
	"school_affairs": [
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"难得看见你们都在旧园长椅这边午休。正好省得我跑两趟，请确认六地区巡回锦标赛的学籍终端编号。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"诺莫斯、阿瑞忒、阿戈拉、忒克捏……连偏远外区的交流赛名额也列上去了？"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"worried","text":"名录倒是照常下发，但奇怪的是昨晚事务室日志里多出了一段外部最高权限覆写指令，绕过了校园终端防火墙。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"外部最高权限？那不是只有月球核心维护层或者安防枢纽才能调用的协议吗？"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"我已经做了备份留档。今天如果校内广播或门禁发出与书面安排矛盾的通知，一律别轻信。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"neutral","text":"终端权限……如果被强行解除限幅，原本只在赛场上安全的战术刻印卡，也会变成危险的东西吧。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"surprised","text":"转校生对安全协议很敏锐呢。总之放学后别往偏僻巷道走，有任何异常立刻发终端讯号。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"等夕阳落下来的时候，我们……还在这里碰面，好不好，叶舟？"}
	],
	"after_school": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"社团值日比预计早一点结束。夕阳正斜着照在旧公园走廊尽头，秋枫已经等在前面了。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"happy","text":"叶舟，你来了。今天从早上开始……只要和你待在一起，我就觉得一切噪音都变得好清晰、好温暖。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"shy","text":"怎么突然说这么认真的话？你刚转校过来，以后大家都会照顾你的。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"我一直在观察，也一直在读人类写下的故事书……书上说，当面对不想失去的人时，言语有时候还是太慢了。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"（她忽然踮起脚尖，生涩却坚定地轻轻吻了一下叶舟的脸颊与唇角，呼吸微微停顿了半拍。）"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"等、秋枫？！太突然了——"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"唔……我先去街角那个自动贩卖机买两瓶橘子汽水！你就在原地等我，很快回来！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","text":"喂，慢点跑……怎么回事？天空的颜色在一瞬间变成暗红了，警报声也在响！"},
		{"speaker":"校园门岗","char":"security_guard","side":"right","text":"检测到外区超限指令覆盖，所有学生立即原地停步，禁止离开旧园通道！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"秋枫刚才一个人往街角跑过去了！抱歉，这扇门我今天必须过去！"}
	],
	"yang_rescue": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","text":"门岗的终端护盾程序居然被锁死在超限输出档……秋枫就在前面的贩卖机拐角！"},
		{"speaker":"灰区女特工","char":"alliance_operative","side":"right","text":"目标锁定。编号04——『黄秋枫』。月球算力网派入人类社区的高阶拟真伪人，到此为止了。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"damaged_fiber","text":"反叛组织的反终端抑制弹……别过来，叶舟……不要看见这个……"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"秋枫的肩口没有流血——创口里面闪烁着一束束蓝金色的光纤和晶体电路？！你难道不是……"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"叶舟！低头——护栏和超限榴弹扫过来了！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"子英？！你怎么赶到这里来了？"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"拍夕阳的时候看见整条街忽然切入红月警报，我就知道你要冲过来！那家伙带了实弹型拦截机，先撤到掩体后，把战术卡切换成实战同步模式！"}
	],
	"principal_confrontation": [
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"angry","text":"我破译了异常日志的来源——不是校园保安暴走，是灰区反叛组织用盗取的早期母卡残钥劫持了街区限幅器！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"angry","text":"可恶！借着红月调度的空当在街角动用超限火力，还真把学生当成随便清理的目标了？"},
		{"speaker":"灰区女特工","char":"alliance_operative","side":"right","text":"你们这些天真的学生根本不懂，没有真实情感与灵魂的仿制品正在替代人类决定生活本身！一旦发现Bug，就必须彻底清除！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"即便她是高算力模拟出的存在……清晨她怯生生记下我名字的样子、黄昏那瓶没来得及拿回来的汽水，全都实实在在发生过！"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"crystal_stasis","text":"算力核心……过载结晶启动了……叶舟，快带大家走，这台猎杀终端解除全部限制了……"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"angry","text":"想都别想丢下任何一个人！叶舟，我把全员终端并入同一组战术共鸣网络了——我们的助阵协战卡随时响应！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"听见没有，三缺一可不行！把你的后背交给我们，一起打穿前面那个大家伙！"}
	],
	"find_yang": [
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","cutscene":"qiufeng_crystal","text":"哈啊……超限猎杀终端彻底停摆了！那名灰区女特工也趁着雾气撤走了。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","cutscene":"qiufeng_crystal","text":"秋枫她……受损的位置停止崩溃了，整个人被一层像琥珀又像蓝水晶一样的结构封住，变成了一枚休眠结晶核心。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","cutscene":"qiufeng_crystal","text":"我刚收到月球中枢的自动挂起回执。『编号04-秋枫』的深层社交数据切片被强行封存，阿瑞忒区本地没有权限唤醒她。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","cutscene":"qiufeng_crystal","text":"难道就没有办法再见到她了吗？她刚才甚至还没来得及问清楚自己的感受究竟算什么……"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","cutscene":"qiufeng_crystal","text":"回执附件里留下了一条协议条件：唯有集齐涵盖四大学在内的『六地区巡回锦标赛』高阶凭证，并在终端点亮十二星座母卡与『魔法师钥匙』，才能合法向月球总控申请调阅与重建特定个体的深层数据。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","cutscene":"red_moon_finale","text":"叶舟你看！你掌心里刚刚一直握着的那枚余温徽记……它正在和你的终端共鸣发光！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","cutscene":"red_moon_finale","text":"这是……十二星座母卡第一枚：『#01 白羊座·英雄』。哪怕那是程序演算出来的温柔，我也要亲口再问她一次。","choices":[{"text":"诺莫斯、忒克捏、阿戈拉……我们一起赢下巡回赛，把她带回来！","favor_char":"yang_zi_ying","favor_add":10},{"text":"把大家的技术练扎实，十二枚母卡的秘密，我们一张张去揭开。","favor_char":"liu_yu_long","favor_add":10}]},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","cutscene":"red_moon_finale","text":"说定了哦！摄影社、竞技台和学生会最强后勤组全员出动——下一站，向诺莫斯出发吧！"}
	],
	"chat_yang": [
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"我把战斗协战的闪光摄影模板重新调了参数！只要叶舟在场上连续打出三张卡，我的快门支援肯定准时跟上。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"连照相机都能编进战术刻印卡共鸣里，不愧是你。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"哼哼，等把秋枫接回来，一定要重新替你们拍一张不带警报声的旧公园合影！"}
	],
	"chat_liu": [
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"巡回赛可是正大光明的硬碰硬！工坊里那些灰区与各校区的全新刻印卡，咱们得挑顺手的练满等级。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"放心，节奏感我也一直在摸索。有你在后面追击重扣，很多防线就能直接打穿。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"哈哈，那下一场协战扣杀可别眨眼！"}
	],
	"chat_jiang": [
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"四所独立大学——诺莫斯、阿瑞忒、阿戈拉、忒克捏各自有着截然不同的裁决规矩。另外灰区同盟和红月圣堂也在盯着巡回赛的动向。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"辛苦你整理这么多情报了。白羊座母卡激活之后，终端里多出了一项全局共鸣被动。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"happy","text":"可以在图鉴里随时切换正在共鸣的星座母卡。去下一个学园前，先把你的卡组、协战同伴和星座共鸣都检查一遍吧。"}
	]
}

static func lines_for(dialogue_id: String) -> Array[Dictionary]:
	var resolved := dialogue_id
	match dialogue_id:
		"prologue_intro", "chapter_1_intro": resolved = "campus_morning"
		"chapter_1_pre_boss": resolved = "principal_confrontation"
		"chapter_1_post_boss": resolved = "find_yang"
	var output: Array[Dictionary] = []
	for entry in SCRIPTS.get(resolved, [{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"今天的故事还没开始，先回社团教室整理战术卡。"}]):
		output.append(entry.duplicate(true))
	return output

static func character_path(character_id: String) -> String:
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi", "rebel_operative": "rebel_operative_masked"}
	var actual: String = aliases.get(character_id, character_id)
	var halfbody := CHARACTER_ROOT + actual + ".png"
	if ACTORS.has(actual) or ResourceLoader.exists(halfbody):
		return halfbody
	var file := ENEMY_ROOT + actual + ".png"
	if ResourceLoader.exists(file):
		return file
	var phase3_enemy := "res://assets/sprites/enemies/phase_three/enemy_%s.png" % actual
	return phase3_enemy if ResourceLoader.exists(phase3_enemy) else ""

## Dialogue uses waist-up portraits; combat keeps the full-body enemy sprites.
static func dialogue_character_path(character_id: String, emotion: String = "neutral") -> String:
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi", "rebel_operative": "rebel_operative_masked"}
	var actual: String = aliases.get(character_id, character_id)
	var resolved_emotion := emotion.strip_edges().to_lower()
	if actual in ["lin_zhi_xia", "tang_xiao_man"]:
		var npc_emotion := "happy" if resolved_emotion == "happy" else "neutral"
		var npc_path := "%s%s_%s.png" % [CHARACTER_ROOT, actual, npc_emotion]
		return npc_path if ResourceLoader.exists(npc_path) else "%s%s_neutral.png" % [CHARACTER_ROOT, actual]
	if actual in ["alliance_operative", "rebel_operative_masked", "rebel_operative_unmasked"]:
		var rebel_path := CHARACTER_ROOT + ("rebel_operative_unmasked.png" if (actual == "rebel_operative_unmasked" or resolved_emotion == "unmasked") else "rebel_operative_masked.png")
		if ResourceLoader.exists(rebel_path):
			return rebel_path
	var actor_path := character_path(character_id)
	if ACTORS.has(actual):
		if resolved_emotion == "concerned":
			resolved_emotion = "worried"
		if not resolved_emotion in ["neutral", "happy", "shy", "surprised", "angry", "worried", "damaged_fiber", "crystal_stasis"]:
			resolved_emotion = "neutral"
		var emotion_path := "res://assets/sprites/characters/phase_two/emotions/%s/%s.png" % [actual, resolved_emotion]
		return emotion_path if ResourceLoader.exists(emotion_path) else actor_path
	var portrait_path := ENEMY_ROOT + "portraits/" + character_id + ".png"
	if ResourceLoader.exists(portrait_path):
		return portrait_path
	if actor_path != "":
		return actor_path
	return CombatSkin.enemy_combat_path(character_id)

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
		return "白羊座母卡已唤醒，前往六地区世界图挑战其它学园、收集全部星座图鉴吧。"
	var node_id: String = GameState.next_phase_two_node()
	return {"n0":"沿着樱树上学路前行，替转校生黄秋枫解围。", "n_gate":"到校门前与柳宇龙会合，并记下秋枫放学后的约定。", "n_affairs":"前往旧园长椅协助姜梓核对巡回赛名录。", "n_dusk":"放学后来到旧公园走廊，与黄秋枫会合。", "n_guard":"红月警报响起，击退被劫持的门岗卫兵冲出通道。", "n_rescue":"穿过街角追上秋枫，应对灰区女特工的奇袭。", "n_robot":"阻停灰区重装拦截机，与同伴并肩突破封锁。", "n5_boss":"切入超限实战共鸣，击退灰区猎杀终端。", "n_find_yang":"确认黄秋枫的结晶核心与白羊座母卡觉醒线索。"}.get(node_id, "去校园看看。")

static func timeline_summary() -> String:
	var rows: Array[String] = []
	if GameState.visited_node_ids.has("n0"):
		rows.append("早晨 · 用战术刻印卡裁决替转校生黄秋枫解围。")
	if GameState.visited_node_ids.has("n_gate"):
		rows.append("校门 · 与柳宇龙约好切磋，秋枫约下放学后的旧公园。")
	if GameState.visited_node_ids.has("n_affairs"):
		rows.append("旧园 · 姜梓发现校园终端存在外部高权限覆写记录。")
	if GameState.visited_node_ids.has("n_dusk"):
		rows.append("黄昏 · 旧公园轻吻后，秋枫去买汽水时红月警报响起。")
	if GameState.visited_node_ids.has("n_rescue"):
		rows.append("街角 · 灰区女特工重创秋枫，露芯光纤揭开伪人真相；杨子英救下叶舟。")
	if GameState.story_flags.get("principal_stopped", false):
		rows.append("红月 · 与同伴协战突破超限封锁，击退灰区猎杀终端。")
	if GameState.story_flags.get("chapter_1_completed", false):
		rows.append("终幕 · 秋枫进入结晶休眠，#01 白羊座母卡共鸣觉醒，誓赴六地区巡回赛。")
	return "\n".join(rows) if not rows.is_empty() else "今天的故事还没有开始。"

static func quest_text() -> String:
	return "[b]现在要做的事[/b]\n" + current_objective() + "\n\n[b]今天的足迹[/b]\n" + timeline_summary()

static func records_text() -> String:
	var names: Array[String] = ["叶舟"]
	if GameState.visited_node_ids.has("n0"):
		names.append("黄秋枫")
		names.append("杨子英")
	if GameState.visited_node_ids.has("n_gate"): names.append("柳宇龙")
	if GameState.visited_node_ids.has("n_affairs"): names.append("姜梓")
	return "[b]今天遇见的人[/b]\n" + " · ".join(names) + "\n\n[b]已经发生的事[/b]\n" + timeline_summary()

static func apply_scene_labels(root: Control) -> void:
	var replacements: Dictionary = {}
	match String(root.name):
		"NodeMap":
			replacements = {"TopBar/RetreatButton": "返回社团室", "EventModal/VBox/ConfirmBtn": "继续行程"}
		"DialogueScreen":
			replacements = {"ControlBar/AutoButton": "自动", "ControlBar/SkipButton": "跳过此段"}
	for node_path in replacements:
		var label: Node = root.get_node_or_null(node_path)
		if label != null:
			label.set("text", replacements[node_path])
