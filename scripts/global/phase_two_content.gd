class_name PhaseTwoContent
extends RefCounted

# 序章与第一章内容：围绕红月学园都市、战术刻印卡匣、黄秋枫（04号）与阿瑞忒巡回选拔赛展开。
const PROLOGUE_TITLE: String = "序章 · 樱林解围与决斗社团"
const CHAPTER_TITLE: String = "第一章 · 红月下的旧公园与白羊星火"
const CHARACTER_ROOT: String = "res://assets/sprites/characters/phase_two/halfbody/"
const ENEMY_ROOT: String = "res://assets/sprites/enemies/phase_two/"
const ACTORS: Dictionary = {
	"ye_zhou": {"name":"叶舟","title":"阿瑞忒二年级生","bio":"立志赢得 IGA 世界大赛拯救世界的中二英雄少年，战术直觉敏锐。与黄秋枫相识后，与伙伴们一同踏上六地区巡回赛的旅程。"},
	"huang_qiufeng": {"name":"黄秋枫","title":"神秘高阶学生","bio":"语调轻柔带『喔』尾音的少女，自称没有稀有卡牌却在海选赛第一时间集齐三张参赛券登顶榜首。"},
	"yang_zi_ying": {"name":"杨子英","title":"叶舟挚友 · 社团主力","bio":"嘴硬心软、总帮叶舟收拾麻烦的摄影社伙伴。每打出3张卡可发动「快门闪光支援」，兼顾续航与护盾。"},
	"liu_yu_long": {"name":"柳宇龙","title":"校长之子 · 天才决斗师","bio":"本届学院所有挑战中未尝一败的强手，以维护学院名声为己任，认可叶舟的战术直觉并约定正赛一战。每打出3张卡可发动「热血追击重扣」，追加高额单体伤害。"},
	"jiang_zi": {"name":"姜梓","title":"决斗社社长 · 俯瞰的天眼","bio":"入学文化理论成绩榜首，观察力过人，为夺取星座卡与红月代理人资格创立最强决斗社团。每打出3张卡可发动「战术统筹屏障」，提供高额护盾并干扰敌方。"},
	"lin_zhi_xia": {"name":"林知夏","title":"图书馆管理员","bio":"阿瑞忒图书馆温和细心的图书委员，常整理校史期刊与同学们留下的卡片批注。"},
	"tang_xiao_man": {"name":"唐小满","title":"校园商店值班员","bio":"精力充沛的校园小店店员，熟知阿瑞忒新上架的刻印卡组与补给趣闻。"},
	"thug_grunt": {"name":"小混混","title":"樱林堵路跟班","bio":"擅长替老大吹捧助威、嘴上讲规矩却专挑软柿子下手的校园跟班，见对方人多立刻脚底抹油。"},
	"thug_boss": {"name":"小混混老大","title":"有原则的樱林混混头目","bio":"口头禅『欧啦』、把欺软怕硬与大胆撤退奉为信条的校园小混混头目。"}
}
const FLOW_STEPS: Array[Dictionary] = [
	{"node":"n0","dialogue":"campus_morning","title":"樱林解围","phase":"prologue"},
	{"node":"n_gate","dialogue":"school_gate","post_dialogue":"school_gate_after","enemy":"liu_yu_long_duel","enemies":["liu_yu_long_duel","jiang_zi_duel"],"scripted_defeat":"liu_yu_long_duel","briefing_flag":"school_gate_duel_briefed","combat_done_flag":"school_gate_combat_done","title":"海选赛与初战","phase":"prologue"},
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
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"我是这个游戏的主角，在很久很久以前，这个世界的月亮变成红色，并且出现了\"卡牌\"，一切都是IGA掌控人类的手段，而我将会赢得IGA世界大赛，拯救这个世界。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"早呀叶舟！你又在对着空气说话吗？这样连我都会被当作奇怪的人的，拜托为了还在你身边的朋友，在公共场合控制一下吧。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"shy","text":"早。。早啊，我才没有被当作奇怪的人，我只是在认真践行自己的英雄准备。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"唉呀呀。。虽然说大家都会想要成为英雄，但是在没有危机的日常中展示英雄的主张，只会被当作把空气当敌人，所以你会格格不入啦。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"我很格格不入吗？唔呣呣。。。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"英雄都是孤独的，难以被他人理解，果然我也。。。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"right","emotion":"worried","text":"啊！不要啊！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"有人遇到危险，敌人出现了！","choices":[{"text":"这宿命的呼喊！喂，放开那个女孩！","favor_char":"yang_zi_ying","favor_add":10},{"text":"杨子英，危机出现了，一起上吧！","favor_char":"yang_zi_ying","favor_add":20}]},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"neutral","text":"唉~，（这个笨蛋啊，不管的话会惹一堆麻烦吧），等一下。"},
		{"speaker":"小混混","char":"thug_grunt","side":"right","emotion":"happy","text":"只是决斗一下，输了我们也会给你卡牌的，很清楚的规则哦~"},
		{"speaker":"小混混老大","char":"thug_boss","side":"right","emotion":"neutral","text":"只是你要和我们每个人进行决斗哈哈哈"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"surprised","text":"怎么这样，我并没有什么强力卡牌，一点也不稀有喔，所以可以放我走嘛。。。"},
		{"speaker":"小混混","char":"thug_grunt","side":"right","emotion":"happy","text":"哈哈哈，老大，你果然预判的准，一眼看出她容易战胜，这下又有收获了。"},
		{"speaker":"小混混老大","char":"thug_boss","side":"right","emotion":"neutral","text":"哼哼，就是因为这样才不能放你走欧啦，谁？什么声音。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"恶徒们，你们的恶行我已经通过双眼确定，现在你们就是我的敌人！"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"surprised","text":"啊呀，果然惹上麻烦了，不过也算是做好事了，这种毫无顾忌的按自己想法行事还真分不清是帅气还是无耻。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"祈祷没有更多人看见啦。"},
		{"speaker":"小混混","char":"thug_grunt","side":"left","emotion":"surprised","text":"老大，有神经病，不过现在是他们人多了。"},
		{"speaker":"小混混老大","char":"thug_boss","side":"right","emotion":"happy","text":"这个时候大胆撤退才是小混混的风格欧啦，不是欺软怕硬的战斗我们不干的欧啦，我们可是有原则的欧啦。"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","clear_stage":true,"text":"小混混迅速逃走了"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"surprised","text":"哇哦，那个。。。谢谢你们。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"angry","text":"可恶，好不容易出现的敌人，如果是我一个人的话说不定就。。。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"worried","text":"（应该是个好人喔？但是怪怪的喔）你好我叫黄秋枫，也是这个学校的学生，可以请问你的名字吗？我想找机会感谢你。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"又在叽里咕噜自言自语了，别当着其他人面露出奇怪行为啦。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"neutral","text":"你好呀，我叫杨子英，他是叶舟，虽然有点怪怪笨笨的，却意外是个好人啦。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"shy","text":"唔姆，也不是什么大不了的事情，和我们一起走吧，这样他们应该不敢再回来了。"},
		{"speaker":"黄秋枫","char":"huang_qiufeng","side":"left","emotion":"happy","text":"好呀，一起走吧（这样算交到朋友了喔？）"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","text":"三人一起去了学校"}
	],
	"school_gate": [
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","clear_stage":true,"text":"第二天，操场上，学生自由决斗海选赛。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"neutral","text":"已经开始匹配预选赛对手了吗，自由寻找同学当对手，开始每个人拥有一张参赛券，结束时拥有3张即可通过预选赛选拔，对我而言轻轻松松，但是我记得黄秋枫同学说过——"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"surprised","text":"快看，预选赛入选名额，已经有超多同学拥有3张了，再自言自语的话就没有对手可以让你打败了啦。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"明明一直说什么期待敌人，结果可以挑战的时候却在发呆什么的，简直又怪又迟钝啦。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"shy","text":"我没有怪怪的，一开始就冲出去的话不是显得我很想抢弱小的对手的参赛券吗？"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"我在等那些强者出现，英雄正在等待抢夺弱小同学的恶徒出现。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"worried","text":"（比赛需要两人组队，该不会没人理他吧，啊啊我就知道会这样啦）"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"我也在等待那个。。。高手，你现在还是一个人吧，我们组队吧，现在已经有好几个3票以上的选手名字出现了，他们一定是欺负弱小的恶徒，赶快去干掉拿到参赛券啦~"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"居然。。。黄秋枫的名字在第一个嘛，怪不得一直没看到她，原来一开始就晋级了。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"喂喂喂？我在这边啦，看着我说话啦，组队啦！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"唔姆，组队，要和我组队吗？"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"面对需要帮助的人的请求，英雄没有拒绝的选择，现在的我已经没有顾虑，火力全开！"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"你这家伙，早知道丢你在这一个人发呆到世界末日啦。"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","clear_stage":true,"text":"杨子英加入队伍。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"neutral","text":"都是些只会乱窜的蟑螂，让这种水平的选手参加比赛，就是在侮辱这座学校的名声，连同在这所学校的我一起都会受影响。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"这是要战斗到最后一刻的宣言吗？看来今天不免会出许多汗。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"neutral","text":"你要是累的话一边休息就可以，我一个人就可以堵住这些盲目的羊群。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"shy","text":"还请收回这种发言，我并没有要求这种照顾。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"neutral","text":"那是我失言了，你的参赛券早就足够了，因为我的私人原因而在这没有意义的战斗一天，我以为对你来说只是为难。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"angry","text":"这同样是我的名声！"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"happy","text":"哈哈哈，有趣，是我狭隘了，当然是这样，会被老鼠影响的是每一个强大优秀的学生。"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","clear_stage":true,"text":"两人继续追逐逃跑的倒霉同学决斗，一次又一次的淘汰其它选手，仿佛绿茵场上的除草机。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"那边两个恶徒，你们的所作所为到此为止了！"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"shy","text":"（别看我，别看我）"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","text":"四人正对而立。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"surprised","text":"哦？不但不逃跑还向我走来嘛！"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"surprised","text":"（这人分明此前一直一个人坐在观众席傻笑自言自语，居然参赛了）"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"happy","text":"啊哈，重复这种清理害虫的动作让我都开始乏味了，刚好调味料自己送上门。"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","text":"决斗宣言      战斗即将开始"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"happy","text":"收集上百张参赛券却不满足，而是游戏般的淘汰满怀斗志的同学，将赛场弄得一塌糊涂，简直是电视里出来的反派敌人，叶舟，将在此向你发起决斗。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"shy","text":"杨子英发。。发起决斗啦~"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"neutral","text":"柳宇龙，为守护我父亲学院的名声，应战！"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"neutral","text":"姜梓，为了创建最强决斗社团，应战！"}
	],
	"school_gate_after": [
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"worried","text":"还是差了一步吗？可恶，要是在这里倒下的话，就无法保护身后的同学们了。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"shy","text":"（在我们战斗时大家都打完了，已经没人了）参赛券交给你们，我们就先回去吧，已经完蛋了。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"worried","text":"（虽然人看起来怪怪的，但是战术直觉非常不错，但是卡牌太新手了吧）"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"happy","text":"你们的实力我认可了，参赛券你们留下，去好好装备完整的卡牌，正赛上再公平的一决胜负吧"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"shy","text":"我最近在组建一个可以代表我们学院的决斗社团，你们如果参加的话，就能达到最低三人人数要求，这张可以还给你们。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"angry","text":"我是不会与恶。。。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"neutral","text":"（捂住叶舟嘴巴，往后推）"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"我们愿意加入，早就听说两位的名声了，校长之子柳宇龙，学院本届的天才决斗师，所有挑战中未尝一败，入学文化理论成绩榜首姜梓，被称为俯瞰的天眼，不遗漏任何获胜的可能。"},
		{"speaker":"柳宇龙","char":"liu_yu_long","side":"left","emotion":"shy","text":"校长之子什么的不重要，我也只是这个学院的学生中一个，自觉维护学院名声。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"right","emotion":"happy","text":"非常明智的选择，明天一起去社团教室吧！"}
	],
	"club_welcome": [
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"happy","text":"社团教室成功申请下来了，那么第一次社团会议，开始。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"neutral","text":"首先人员报数，一，姜梓。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"surprised","text":"（超认真的感觉是怎么回事啦，不得了的感觉啦。）二，杨子英！"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"angry","text":"三，叶舟，就算是加入了社团，我也不会与恶为伍，欺负弱小！"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"worried","text":"暂且不管误解了哪点，不过还是希望你把我当作可以信任的伙伴。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"happy","text":"（拍拍）这个笨蛋的胡话不用在意啦，他其实是个英雄爱好者，说话有点怪但是也能好好沟通的。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"worried","text":"我没有很怪。。。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"surprised","text":"结合昨天的情况这不难理解，对于特殊人群给予的照顾余裕我还是具备的。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"happy","text":"接下来指明我们社团的目标——参加校园赛选拔，赢得星座卡，代表阿瑞忒参加世界赛，集齐全部12张星座卡牌，获得红月代理人资格。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"surprised","text":"红月代理人资格，这可是能够改变世界的权力，超厉害啦。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"happy","text":"不错，我很久很久之前就在为这一刻准备了，拯救世界的使命就交给我吧。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"neutral","text":"但是我们还缺少一个伙伴，校队代表必须是四人一组，两个主战，两个替补。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"shy","text":"剩下一人，我有一个推荐，就是不知道本人意见如何。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"happy","text":"是柳宇龙吧，他是我们学校最强的决斗师，我一开始就邀请了，得到的回复是必须先打败他，而这正是我们当前的目标。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"angry","text":"那种恶徒我会击败，亲自报仇。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"shy","text":"不过我指的是黄秋枫，也就是一开始就获得三张参赛券，早早退场的女孩，绝对是隐藏的强者，队伍有神秘高手很酷吧。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"surprised","text":"啊，真是始料未及，既然出现了分歧，那就投票决定吧。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"happy","text":"即便明知你们是熟识的伙伴，我也不会用社长的身份进行一言堂，率先表达信任是我身为社长的责任。"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"我选择柳宇龙。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"left","emotion":"surprised","text":"为什么，那是欺负学生的恶徒吧，难道你被催眠了，还是被诱惑了？"},
		{"speaker":"杨子英","char":"yang_zi_ying","side":"right","emotion":"angry","text":"被诱惑的人是你吧。"},
		{"speaker":"旁白","char":"","side":"left","emotion":"neutral","text":"空气安静了下来。"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"happy","text":"真是意外，不过确实是经过理性思考容易做出的决定，那就决定了，打败柳宇龙让他成为最后一位队友，夺取星座卡。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"worried","text":"等下！"},
		{"speaker":"姜梓","char":"jiang_zi","side":"left","emotion":"happy","text":"我们学院第一张星座卡是白羊座——英雄卡，打败柳宇龙后即可获得，归你所有。"},
		{"speaker":"叶舟","char":"ye_zhou","side":"right","emotion":"neutral","text":"没有意见！"}
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
	if actual == "":
		return ""
	var halfbody := CHARACTER_ROOT + actual + ".png"
	if ResourceLoader.exists(halfbody):
		return halfbody
	var halfbody_neutral := "%s%s_neutral.png" % [CHARACTER_ROOT, actual]
	if ResourceLoader.exists(halfbody_neutral):
		return halfbody_neutral
	var phase3_enemy := "res://assets/sprites/enemies/phase_three/enemy_%s.png" % actual
	return phase3_enemy if ResourceLoader.exists(phase3_enemy) else ""

## Dialogue uses waist-up portraits; combat keeps the full-body enemy sprites.
static func dialogue_character_path(character_id: String, emotion: String = "neutral") -> String:
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi", "rebel_operative": "rebel_operative_masked"}
	var actual: String = aliases.get(character_id, character_id)
	if actual == "":
		return ""
	var resolved_emotion := emotion.strip_edges().to_lower()
	if resolved_emotion == "concerned":
		resolved_emotion = "worried"
	if actual in ["lin_zhi_xia", "tang_xiao_man"]:
		var npc_emotion := "happy" if resolved_emotion == "happy" else "neutral"
		var npc_path := "%s%s_%s.png" % [CHARACTER_ROOT, actual, npc_emotion]
		if ResourceLoader.exists(npc_path):
			return npc_path
		var npc_neutral := "%s%s_neutral.png" % [CHARACTER_ROOT, actual]
		return npc_neutral if ResourceLoader.exists(npc_neutral) else ""
	if actual in ["alliance_operative", "rebel_operative_masked", "rebel_operative_unmasked"]:
		var rebel_path := CHARACTER_ROOT + ("rebel_operative_unmasked.png" if (actual == "rebel_operative_unmasked" or resolved_emotion == "unmasked") else "rebel_operative_masked.png")
		if ResourceLoader.exists(rebel_path):
			return rebel_path
	if resolved_emotion == "" or not resolved_emotion in ["neutral", "happy", "shy", "surprised", "angry", "worried", "damaged_fiber", "crystal_stasis"]:
		resolved_emotion = "neutral"
	var emotion_path := "res://assets/sprites/characters/phase_two/emotions/%s/%s.png" % [actual, resolved_emotion]
	if ResourceLoader.exists(emotion_path):
		return emotion_path
	var neutral_emotion_path := "res://assets/sprites/characters/phase_two/emotions/%s/neutral.png" % actual
	if ResourceLoader.exists(neutral_emotion_path):
		return neutral_emotion_path
	var halfbody_emotion := "%s%s_%s.png" % [CHARACTER_ROOT, actual, resolved_emotion]
	if ResourceLoader.exists(halfbody_emotion):
		return halfbody_emotion
	var actor_path := character_path(character_id)
	if actor_path != "":
		return actor_path
	var portrait_path := ENEMY_ROOT + "portraits/" + actual + ".png"
	if ResourceLoader.exists(portrait_path):
		return portrait_path
	return CombatSkin.enemy_combat_path(character_id)

static func background_key(dialogue_id: String) -> String:
	match dialogue_id:
		"school_gate", "school_gate_after": return "prologue_sports_field"
		"club_welcome": return "prologue_club_meeting"
		"school_affairs", "chat_yang", "chat_liu", "chat_jiang": return "school_room"
		"prologue_intro", "chapter_1_intro", "campus_morning": return "prologue_sakura_road"
		"principal_confrontation": return "battle_red_moon_lockdown"
	return "dusk_road"

static func resolve_background_path(key: String, prefer_wide: bool = true) -> String:
	var candidates: Array[String] = []
	var bg_dir := "res://assets/backgrounds/phase_two/"
	match key:
		"prologue_sakura_road":
			if prefer_wide:
				candidates.append(bg_dir + "prologue_sakura_road_wide.png")
			candidates.append(bg_dir + "prologue_sakura_road.png")
			if prefer_wide:
				candidates.append(bg_dir + "morning_road_wide.png")
			candidates.append(bg_dir + "morning_road.png")
		"prologue_sports_field":
			if prefer_wide:
				candidates.append(bg_dir + "prologue_sports_field_wide.png")
			candidates.append(bg_dir + "prologue_sports_field.png")
			if prefer_wide:
				candidates.append(bg_dir + "school_gate_wide.png")
			candidates.append(bg_dir + "school_gate.png")
		"battle_sports_field":
			if prefer_wide:
				candidates.append(bg_dir + "battle_sports_field_wide.png")
			candidates.append(bg_dir + "battle_sports_field.png")
			if prefer_wide:
				candidates.append(bg_dir + "battle_campus_wide.png")
			candidates.append(bg_dir + "battle_campus.png")
		"prologue_club_meeting":
			if prefer_wide:
				candidates.append(bg_dir + "prologue_club_meeting_wide.png")
			candidates.append(bg_dir + "prologue_club_meeting.png")
			if prefer_wide:
				candidates.append(bg_dir + "school_room_wide.png")
			candidates.append(bg_dir + "school_room.png")
			candidates.append("res://assets/ui/player_experience/home_room_morning_v1.png")
		_:
			if prefer_wide:
				candidates.append("%s%s_wide.png" % [bg_dir, key])
			candidates.append("%s%s.png" % [bg_dir, key])
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

static func resolve_background_overlay_path(dialogue_id: String, key: String, prefer_wide: bool = true) -> String:
	if key != "prologue_sports_field" or dialogue_id != "school_gate":
		return ""
	var overlay_dir := "res://assets/backgrounds/phase_two/overlays/"
	var candidates: Array[String] = []
	if prefer_wide:
		candidates.append(overlay_dir + "prologue_sports_field_duel_crowd_wide.png")
	candidates.append(overlay_dir + "prologue_sports_field_duel_crowd.png")
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

static func step_for(node_id: String) -> Dictionary:
	for step in FLOW_STEPS:
		if step["node"] == node_id:
			return step.duplicate(true)
	return {}

static func node_for_dialogue(dialogue_id: String) -> String:
	var resolved: String = {"prologue_intro":"campus_morning", "chapter_1_intro":"campus_morning", "chapter_1_pre_boss":"principal_confrontation", "chapter_1_post_boss":"find_yang"}.get(dialogue_id, dialogue_id)
	for step in FLOW_STEPS:
		if step.get("dialogue", "") == resolved or step.get("post_dialogue", "") == resolved:
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
		"n0": "序章 · 在樱林上学路替黄秋枫解围，赶走堵路的小混混。",
		"n_gate": "序章 · 次日操场海选赛与杨子英组队，直面柳宇龙与姜梓。",
		"n_club_intro": "序章 · 接受姜梓邀请，出席决斗社团第一次会议。",
		"n_guard": "红月警报响起，击退被劫持的门岗卫兵冲出旧公园通道。",
		"n_rescue": "穿过街角追上秋枫，应对灰区女特工的奇袭。",
		"n_robot": "阻停灰区重装拦截机，与同伴并肩突破封锁。",
		"n5_boss": "切入超限实战共鸣，击退灰区猎杀机兵。",
		"n_find_yang": "确认黄秋枫的结晶核心与白羊座母卡觉醒线索。"
	}.get(node_id, "去阿瑞忒校园走走，推进今日活动。")

static func timeline_summary() -> String:
	var rows: Array[String] = []
	if GameState.visited_node_ids.has("n0"):
		rows.append("序章 · 在樱林上学路替黄秋枫解围，吓跑堵路的小混混并与她结伴去学校。")
	if GameState.visited_node_ids.has("n_gate"):
		rows.append("海选赛 · 与杨子英组队迎战柳宇龙与姜梓，虽遭锁血反杀仍获认可并受邀入社。")
	if GameState.visited_node_ids.has("n_club_intro"):
		rows.append("社团室 · 姜梓、杨子英、叶舟召开首次社团会议，定下击败柳宇龙夺取白羊座的目标。")
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
