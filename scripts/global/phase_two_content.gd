class_name PhaseTwoContent
extends RefCounted

# 序章与第一章内容：围绕红月学园都市、战术刻印卡匣、黄秋枫（04号）与阿瑞忒巡回选拔赛展开。
const PROLOGUE_TITLE: String = "序章 · 樱道初遇与第四名的呼吸"
const CHAPTER_TITLE: String = "第一章 · 红月下的旧公园与白羊星火"
const CHARACTER_ROOT: String = "res://assets/sprites/characters/phase_two/halfbody/"
const ENEMY_ROOT: String = "res://assets/sprites/enemies/phase_two/"
const ACTORS: Dictionary = {
	"ye_zhou": {"name":"叶舟","title":"阿瑞忒二年级生","bio":"观察细致、习惯冷静寻找破绽的战术刻印卡新手。与黄秋枫在旧公园约定后，踏上追寻真相与六地区巡回赛的旅程。"},
	"huang_qiufeng": {"name":"黄秋枫","title":"转校插班生","bio":"温柔安静却总是慢半拍的转校少女，对校园里的日常与人类情感都充满笨拙而认真的好奇。"},
	"yang_zi_ying": {"name":"杨子英","title":"摄影社热心社员","bio":"热心、行动快，喜欢用镜头记录校园夕阳与战术刻印卡切磋。每打出3张卡可发动「快门闪光支援」，兼顾续航与护盾。"},
	"liu_yu_long": {"name":"柳宇龙","title":"竞技对抗狂热者","bio":"爱开玩笑也很不服输，把非致命护盾裁决当成堂堂正正的决斗舞台。每打出3张卡可发动「热血追击重扣」，追加高额单体伤害。"},
	"jiang_zi": {"name":"姜梓","title":"学生会事务干事","bio":"严谨干练，负责核对六地区巡回赛名录与校内安防日志。每打出3张卡可发动「战术统筹屏障」，提供高额护盾并干扰敌方。"},
	"lin_zhi_xia": {"name":"林知夏","title":"图书馆管理员","bio":"阿瑞忒图书馆温和细心的图书委员，常整理校史期刊与同学们留下的卡片批注。"},
	"tang_xiao_man": {"name":"唐小满","title":"校园商店值班员","bio":"精力充沛的校园小店店员，熟知阿瑞忒新上架的刻印卡组与补给趣闻。"}
}
const FLOW_STEPS: Array[Dictionary] = [
	{"node":"n0","dialogue":"campus_morning","title":"樱林解围","phase":"prologue"},
	{"node":"n_gate","dialogue":"school_gate","enemy":"liu_yu_long_duel","briefing_flag":"school_gate_duel_briefed","title":"运动会与初战","phase":"prologue"},
	{"node":"n_club_intro","dialogue":"club_welcome","title":"入驻社团室","phase":"prologue"},
	{"node":"n_affairs","dialogue":"school_affairs","title":"书页与旧园之约","phase":"act1","location":"library"},
	{"node":"n_dusk","dialogue":"after_school","title":"黄昏轻吻","phase":"climax","location":"old_park"},
	{"node":"n_guard","enemy":"security_guard","title":"门岗封锁","phase":"climax"},
	{"node":"n_rescue","dialogue":"yang_rescue","title":"灰区奇袭","phase":"climax"},
	{"node":"n_robot","enemy":"campus_robot","title":"拦截机械","phase":"climax"},
	{"node":"n5_boss","dialogue":"principal_confrontation","enemy":"ch1_hunter_mech","briefing_flag":"principal_briefing_done","title":"红月超限","phase":"climax"},
	{"node":"n_find_yang","dialogue":"find_yang","title":"白羊觉醒","phase":"climax"}
]
const SCRIPTS: Dictionary = {
	"campus_morning": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"只要在早读前把随身卡匣的年度登记交上去，放学后还能顺路去老街买面包。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"早呀叶舟！快看樱树那边——有几个高年级生好像在围着新来的转校生！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"拿着高阶刻印卡炫耀、还想强行拿走别人的基础卡组吗……真是老套的欺负人方式。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"照校规，卡组切磋必须在双方同意的「学园护盾裁决」下进行！我拍下来当凭证，叶舟，我们上！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"喂，那边的学长。欺负刚转来的同学算什么本事？想比划两张刻印卡，我用护盾裁决陪你们打一局。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"surprised","text":"唔……看到你的相机和护盾卡，那些人收起卡匣走掉了。谢谢你替我解围，同学。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"我叫叶舟，二年级B班的。你是今天刚转来的黄秋枫同学吧？别太在意那些家伙。","choices":[{"text":"把卡片登记编号互相记一下吧，以后有事随时找我。","favor_char":"yang_zi_ying","favor_add":5},{"text":"先熟悉下校园的护盾裁决规矩，自己的初始卡可不能随便让出去。","favor_char":"yang_zi_ying","favor_add":10}]},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"叶、舟……嗯，我记住这个名字了。那……明天校园运动会结束后，还能再说说话吗？"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"早读铃响啦！先去教室点名，明天运动会再把社团钥匙交给你！"}
	],
	"school_gate": [
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"第二天清晨的田径场可真热闹！不过叶舟，你刚注意到黄秋枫跑完四百米接力的样子了吗？"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"看到了……明明冲到了第四名，下场的时候却一滴汗都没有，呼吸稳得像根本没参加过比赛一样。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"neutral","text":"嗯？名次停在第四名左右，呼吸频率也不超过常人平均线，应该是最不容易引起注意的标准表现吧……叶舟同学怎么这样看着我？"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"哈哈！先别发呆了叶舟！听说你昨天早上只靠三张基础刻印卡就逼退了高年级的家伙？正巧比赛间隙，来决斗台切磋一局！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"只是他们心虚走开而已。不过既然你手痒，热身一局我随时奉陪，希望你今天记得看清敌方意图再出牌。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"少看不起人！诺莫斯和阿戈拉今年的新生都卷得厉害，咱阿瑞忒这回「六地区巡回赛」可不能掉链子！展开学园护盾裁决，叶舟——接招！"}
	],
	"club_welcome": [
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"运动会热身辛苦了，叶舟。从今天下午开始，这间「阿瑞忒社团教室」就正式归我们活动组使用了。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"桌上那只旧铁盒我已经收拾成「卡牌整理台」啦！墙边还挂好了手绘校园地图，隔壁放映小间改成了咱们的「放映档案室」——达成委托还能去那里盖章领零用钱和材料呢！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"体育馆的模拟训练路线、校园商店的新上架卡组，还有图书馆里的藏书，阿瑞忒可好玩着呢！先把社团里的第 4 张储备卡装进卡匣试试手感吧！"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"大家看起来都很期待接下来的校园生活……我下午想去「图书馆」窗边借几本讲人类故事的书。等叶舟你在校园里逛一逛、熟悉了之后，能来图书馆找我吗？"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"正好，我也去核对一下校内限幅器日志。去卡牌工坊整备好卡匣、到放映室领完入部补给，就可以放心出发了。"}
	],
	"school_affairs": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"推开图书馆窗边的阅读区，阳光正好落在一摞摊开的旧小说上。秋枫果然还坐在这里。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"happy","text":"叶舟，你来找我了。前天早上的事……还有运动会那天我没反应过来的话，本来应该早点好好谢谢你的。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"shy","text":"谢什么，路见不平顺手搭把手而已。话说，你一直在读这些描写恋爱与日常的小说吗？"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"嗯……书上写着，如果一直想再见到一个人，想确认他对自己的感觉究竟是什么，那或许就是所谓的“喜欢”。叶舟……我也想试着站在人类这一侧，和你多待一会儿。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"worried","text":"抱歉打断一下你们的午后谈话——叶舟、秋枫，刚才学生会收到了紧急日志告警：校外偏僻街区的安全限幅器出现了外部高权限覆写。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","text":"安全限幅器被覆写？意思是……原本只用于校园护盾裁决的街区防御设施，在特定状态下可能会切入超限实战模式？"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"我已经留下备份存档。在问题查清前，去校外街区前务必把卡匣整备妥当——最好编满 5 张行动卡或将常用卡强化到 Lv.2。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"那……等傍晚日落的时候，我先在学校后面的「旧公园」长椅等你。记住一定要准备好再过来哦，叶舟。"}
	],
	"after_school": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"社团的值日与整备已经全部完成了。夕阳把旧公园的红枫和梧桐大道染成金色，秋枫果然站在走廊尽头的长椅边。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"happy","text":"叶舟，你按约过来了。今天只要待在你身边，周围原本喧闹的各种数值和杂音，好像全都一下子变得安静又清晰。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"shy","text":"怎么突然说得这么认真……刚转校过来，习惯这里本来就是应该的。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"我一直在观察，也把图书馆借来的故事一页页读完了。书上说，当面对不想失去的人时，单纯的语言有时候太慢——"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"（她忽然踮起脚尖，生涩却坚定地轻轻吻了一下叶舟的脸颊与唇角，呼吸仿佛停顿了半拍。）"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"等、秋枫？！太突然了——"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"shy","text":"唔……我先去街角那个自动贩卖机买两瓶橘子汽水！你就在这里等我，很快回来！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","text":"喂，慢点跑……怎么回事？天空的颜色在一瞬间变成暗红了，警报声也在响！"},
		{"speaker":"校园门岗","char":"security_guard","side":"right","text":"检测到外区超限指令覆盖，所有学生立即原地停步，禁止离开旧公园通道！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"秋枫刚才一个人往街角跑过去了！抱歉，这扇门我今天必须过去！"}
	],
	"yang_rescue": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","text":"门岗的护盾程序居然被锁死在超限输出档……秋枫就在前面的贩卖机拐角！"},
		{"speaker":"灰区女特工","char":"alliance_operative","side":"right","text":"目标锁定。编号04——『黄秋枫』。月球算力网派入人类社区的高阶拟真伪人，到此为止了。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"damaged_fiber","text":"抑制实弹……别过来，叶舟……不要看见这副样子……"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"秋枫的肩口没有流血——创口里面闪烁着一束束蓝金色的光纤和晶体电路？！你难道不是……"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"叶舟！低头——护栏和超限榴弹扫过来了！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"子英？！你怎么赶到这里来了？"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"拍夕阳的时候看见整条街忽然切入红月警报，我就知道你要冲过来！那家伙带了实弹型拦截机，先撤到掩体后，把卡匣切入实战共鸣模式！"}
	],
	"principal_confrontation": [
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"angry","text":"我破译了异常日志的来源——不是校园保安暴走，是灰区反叛组织用盗取的早期母卡残钥劫持了街区限幅器！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"angry","text":"可恶！借着红月调度的空当在街角动用超限火力，还真把学生当成随便清理的目标了？"},
		{"speaker":"灰区女特工","char":"alliance_operative","side":"right","text":"你们这些天真的学生根本不懂，没有真实情感与灵魂的仿制品正在替代人类决定生活本身！一旦发现Bug，就必须彻底清除！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"即便她是以高算力模拟出的存在……清晨她记下我名字的样子、刚才去买的两瓶汽水，全都实实在在发生过！"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"crystal_stasis","text":"算力核心……过载结晶启动了……叶舟，快带大家走，这台猎杀机兵解除全部限制了……"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"angry","text":"想都别想丢下任何一个人！叶舟，我把全员卡匣并入同一组战术共鸣网络了——我们的助阵协战卡随时响应！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"听见没有，三缺一可不行！把你的后背交给我们，一起打穿前面那个大家伙！"}
	],
	"find_yang": [
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","cutscene":"qiufeng_crystal","text":"哈啊……超限猎杀机兵彻底停摆了！那名灰区女特工也趁着雾气撤走了。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","cutscene":"qiufeng_crystal","text":"秋枫她……受损的位置停止崩溃了，整个人被一层像琥珀又像蓝水晶一样的结构封住，变成了一枚休眠结晶核心。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","cutscene":"qiufeng_crystal","text":"我刚收到月球中枢的自动挂起回执。『编号04-秋枫』的深层社交数据切片被强行封存，阿瑞忒区本地没有权限唤醒她。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","cutscene":"qiufeng_crystal","text":"难道就没有办法再见到她了吗？她刚才甚至还没来得及问清楚自己的感受究竟算什么……"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","cutscene":"qiufeng_crystal","text":"回执附件里留下了一条协议条件：唯有集齐涵盖四大学在内的『六地区巡回锦标赛』高阶凭证，点亮十二星座母卡与『魔法师钥匙』，才能合法向月球总控申请调阅与重建特定个体的深层数据。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","cutscene":"red_moon_finale","text":"叶舟你看！你掌心里刚刚一直握着的那枚余温徽记……它正在和你的卡匣共鸣发光！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","cutscene":"red_moon_finale","text":"这是……十二星座母卡第一枚：『#01 白羊座·英雄』。哪怕那是程序演算出来的温柔，我也要亲口再问她一次。","choices":[{"text":"赢下阿瑞忒代表选拔赛，然后一起去诺莫斯与其余学园把她带回来！","favor_char":"yang_zi_ying","favor_add":10},{"text":"先在体育馆拿到阿瑞忒代表资格，十二枚母卡的秘密我们一张张去揭开。","favor_char":"liu_yu_long","favor_add":10}]},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"happy","cutscene":"red_moon_finale","text":"好——明早先回社团教室把「#01 白羊座·英雄」录入图鉴，再去体育馆赢下 3 轮《阿瑞忒代表选拔赛》，取得正式巡回代表通行章，我们就能向诺莫斯出发了！"}
	],
	"chat_yang": [
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"我把快门闪光的协战模板重新调了曝光参数！只要叶舟在场上连续打出三张卡，我的摄影支援肯定准时跟上。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"连照相机都能编进战术刻印卡共鸣里，不愧是你。熟悉度越高，我们的同步威力也会跟着提升呢。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"哼哼，等把秋枫接回来，一定要重新替你们拍一张不带警报声的旧公园合影！"}
	],
	"chat_liu": [
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"巡回赛可是正大光明的硬碰硬！商店里会随主线进货全新刻印卡，工坊强化卡级还不占白天活动次数，记得勤加整备！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"放心，节奏感我也一直在摸索。有你在后面追击重扣，很多防线都能直接打穿。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"right","emotion":"happy","text":"哈哈，那下一场选拔赛协战扣杀可别眨眼！"}
	],
	"chat_jiang": [
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"四所独立大学——诺莫斯、阿瑞忒、阿戈拉、忒克捏各自有着截然不同的裁决规矩。记得常来「放映档案室」核对委托并加盖巡回印章。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"辛苦你整理这么多情报了。白羊座母卡点亮之后，在星座图鉴里还能切换战斗共鸣被动。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"happy","text":"去下一所学院前，先把你的卡匣、协战同伴和星座共鸣都检查一遍，赢下体育馆选拔赛的代表席位吧。"}
	]
}

static func lines_for(dialogue_id: String) -> Array[Dictionary]:
	var resolved := dialogue_id
	match dialogue_id:
		"prologue_intro", "chapter_1_intro": resolved = "campus_morning"
		"chapter_1_pre_boss": resolved = "principal_confrontation"
		"chapter_1_post_boss": resolved = "find_yang"
	var output: Array[Dictionary] = []
	for entry in SCRIPTS.get(resolved, [{"speaker":"叶舟","char":"ye_zhou","side":"left","text":"今天的故事还没开始，先回社团教室整理战术卡匣。"}]):
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
		"club_welcome", "school_affairs", "chat_jiang", "chat_liu", "chat_yang": return "school_room"
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
	if bool(GameState.story_flags.get("arete_qualifier_completed", false)):
		return "已赢得阿瑞忒代表通行章！第二章「诺莫斯」筹备中，可自由探索校园与收集刻印卡。"
	if bool(GameState.story_flags.get("chapter_1_completed", false)):
		return "白羊座母卡已唤醒，前往「体育馆」参加 3 轮《阿瑞忒代表选拔赛》，赢取巡回代表资格。"
	var node_id: String = GameState.next_phase_two_node()
	if node_id == "n_affairs":
		if PlayerJourney.act1_story_ready():
			return "完成校园初探！前往「图书馆」寻找正在读人类故事书的黄秋枫。"
		return "先打开「校园地图」体验日常活动（打工/图书馆研习/训练），随后前往「图书馆」找黄秋枫。"
	if node_id == "n_dusk":
		if PlayerJourney.act2_combat_ready():
			return "卡匣已整备就绪！前往校外「旧公园」长椅赴黄秋枫的黄昏之约。"
		return "街区限幅器出现异常。赴约前先在「卡牌整理」编满 5 张卡或将任意卡强化至 Lv.2。"
	return {
		"n0": "序章 · 沿着樱树上学路前行，替转校生黄秋枫解围。",
		"n_gate": "序章 · 次日运动会后与柳宇龙进行 3 卡护盾热身切磋。",
		"n_club_intro": "序章 · 跟姜梓与杨子英前往并入驻「社团教室」。",
		"n_guard": "红月警报响起，击退被劫持的门岗卫兵冲出旧公园通道。",
		"n_rescue": "穿过街角追上秋枫，应对灰区女特工的奇袭。",
		"n_robot": "阻停灰区重装拦截机，与同伴并肩突破封锁。",
		"n5_boss": "切入超限实战共鸣，击退灰区猎杀机兵。",
		"n_find_yang": "确认黄秋枫的结晶核心与白羊座母卡觉醒线索。"
	}.get(node_id, "去阿瑞忒校园走走，推进今日活动。")

static func timeline_summary() -> String:
	var rows: Array[String] = []
	if GameState.visited_node_ids.has("n0"):
		rows.append("序章 · 樱林用学园护盾裁决替转校生黄秋枫解围。")
	if GameState.visited_node_ids.has("n_gate"):
		rows.append("运动会 · 秋枫冲刺第四名却呼吸平稳；与柳宇龙完成切磋热身。")
	if GameState.visited_node_ids.has("n_club_intro"):
		rows.append("社团室 · 正式接手阿瑞忒社团教室，姜梓、子英、宇龙集结。")
	if GameState.visited_node_ids.has("n_affairs"):
		rows.append("图书馆 · 秋枫坦露想试着站在人类一侧的心意；约定黄昏前往旧公园。")
	if GameState.visited_node_ids.has("n_dusk"):
		rows.append("黄昏 · 旧公园轻吻后，秋枫去买汽水时红月警报骤然封锁街区。")
	if GameState.visited_node_ids.has("n_rescue"):
		rows.append("街角 · 灰区女特工重创秋枫，露芯光纤揭开伪人真相；杨子英救下叶舟。")
	if GameState.story_flags.get("principal_stopped", false):
		rows.append("红月 · 与同伴协战突破超限封锁，击退灰区猎杀机兵。")
	if GameState.story_flags.get("chapter_1_completed", false):
		rows.append("终幕 · 秋枫进入结晶休眠，#01 白羊座母卡觉醒，誓夺巡回代表席位。")
	if GameState.story_flags.get("arete_qualifier_completed", false):
		rows.append("选拔赛 · 全胜通关体育馆 3 轮代表战，赢得「阿瑞忒代表通行章」。")
	return "\n".join(rows) if not rows.is_empty() else "今天的故事还没有开始。"

static func quest_text() -> String:
	return "[b]现在要做的事[/b]\n" + current_objective() + "\n\n[b]校园与旅途足迹[/b]\n" + timeline_summary()

static func records_text() -> String:
	var names: Array[String] = ["叶舟"]
	if GameState.visited_node_ids.has("n0"):
		names.append("黄秋枫")
		names.append("杨子英")
	if GameState.visited_node_ids.has("n_gate"): names.append("柳宇龙")
	if GameState.visited_node_ids.has("n_club_intro") or GameState.visited_node_ids.has("n_affairs"): names.append("姜梓")
	return "[b]已认识的同学[/b]\n" + " · ".join(names) + "\n\n[b]已经发生的事[/b]\n" + timeline_summary()

static func apply_scene_labels(root: Control) -> void:
	var replacements: Dictionary = {}
	match String(root.name):
		"NodeMap":
			replacements = {"TopBar/RetreatButton": "返回体育馆", "EventModal/VBox/ConfirmBtn": "继续行程"}
		"DialogueScreen":
			replacements = {"ControlBar/AutoButton": "自动", "ControlBar/SkipButton": "跳过此段"}
	for node_path in replacements:
		var label: Node = root.get_node_or_null(node_path)
		if label != null:
			label.set("text", replacements[node_path])
