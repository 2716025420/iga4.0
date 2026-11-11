class_name ZodiacCatalog
extends RefCounted

## Non-exchangeable story cards; thematic naming remains configurable.
const ORDER := ["hero","everyperson","jester","caregiver","ruler","creator","innocent","rebel","explorer","sage","magician","lover"]
const ENTRIES := {
	"hero": {
		"id": "hero",
		"zodiac": "aries",
		"name": "白羊座",
		"archetype": "英雄",
		"power": "肉体融合",
		"color": "#E87563",
		"motto": "以身体承担力量",
		"ability": "卡牌与使用者肉体融合，身体本身成为卡牌，获得远超常人的体质。",
		"limits": "力量不附带经验与心智成熟度，需训练掌控；普通日常动作也可能伤害他人。",
		"number": 1,
		"interactions": "英雄身体免疫弄臣的身体交换；在反叛者的作用范围内会变得无力。"
	},
	"everyperson": {
		"id": "everyperson",
		"zodiac": "taurus",
		"name": "金牛座",
		"archetype": "凡人",
		"power": "此刻读心",
		"color": "#D9AD64",
		"motto": "与他人站在一起",
		"ability": "读取他人此刻正在思考的内容。",
		"limits": "不读取完整历史记忆，不自动正确解释人格或预测未来行为。",
		"number": 2,
		"interactions": "只涉及对方此刻的想法，不自动正确解释他人的真实意图。"
	},
	"jester": {
		"id": "jester",
		"zodiac": "gemini",
		"name": "双子座",
		"archetype": "弄臣",
		"power": "交换身体",
		"color": "#91ADD7",
		"motto": "另一种生活",
		"ability": "与另一人交换身体，体验对方的生活。",
		"limits": "每名使用者一生最多发动一次；英雄融合后的身体免疫交换。",
		"number": 3,
		"interactions": "可通过身体交换绕过智者、照顾者、统治者的资格限制；如何换回和持续时间待定。"
	},
	"caregiver": {
		"id": "caregiver",
		"zodiac": "cancer",
		"name": "巨蟹座",
		"archetype": "照顾者",
		"power": "身体修复",
		"color": "#89B9AD",
		"motto": "庇护与主观理想",
		"ability": "对另一名仍存活的人进行彻底肉体修复，使身体达到使用者期待的模样。",
		"limits": "每位使用者一生一次；不能复活已死者；理想身体来自使用者的主观期待。",
		"number": 4,
		"interactions": "已经完成的肉体修复和基因改变不会被反叛者回滚。"
	},
	"ruler": {
		"id": "ruler",
		"zodiac": "leo",
		"name": "狮子座",
		"archetype": "统治者",
		"power": "绝对控制",
		"color": "#D9B465",
		"motto": "权力与责任",
		"ability": "对一人施加无法违抗的绝对控制，造成其大脑不可逆改变。",
		"limits": "每名使用者一生只能控制一人；已完成的改变不因能力压制消失。",
		"number": 5,
		"interactions": "受控者认可施控者原来的身体，不追随交换走的意识。"
	},
	"creator": {
		"id": "creator",
		"zodiac": "virgo",
		"name": "处女座",
		"archetype": "创造者",
		"power": "解析复刻",
		"color": "#9FB09C",
		"motto": "不断完善作品",
		"ability": "先解析并记录现实存在的物体，再收集现实分子、替代组合过程复刻同材质物品。",
		"limits": "不能凭空造物，不能复制生命，也不能创造或复制特殊卡牌。",
		"number": 6,
		"interactions": "已制造物品是真实物质，不因反叛者而消失。"
	},
	"innocent": {
		"id": "innocent",
		"zodiac": "libra",
		"name": "天秤座",
		"archetype": "天真者",
		"power": "主观断罪",
		"color": "#A4ACC8",
		"motto": "规则与确信",
		"ability": "判决自己认为邪恶、违规或不好的对象，并使其遭受本人认为对等的处罚。",
		"limits": "最大作用范围为一所学院；善恶和对等来自持卡人，不是客观法律或真理。",
		"number": 7,
		"interactions": "具体判决与处罚演出待主创设计，不补造范围数值、冷却或代价。"
	},
	"rebel": {
		"id": "rebel",
		"zodiac": "scorpio",
		"name": "天蝎座",
		"archetype": "反叛者",
		"power": "能力压制",
		"color": "#A18FB4",
		"motto": "拒绝被规定",
		"ability": "发动时使作用范围内的其他普通卡和特殊卡无法发动。",
		"limits": "不倒转已经造成的现实变化；具体范围值与时长待定；魔法师钥匙例外。",
		"number": 8,
		"interactions": "英雄会无力、爱人分身停下、探索者恢复原年龄；其他未确认交互不推定。"
	},
	"explorer": {
		"id": "explorer",
		"zodiac": "sagittarius",
		"name": "射手座",
		"archetype": "探索者",
		"power": "生理年龄调节",
		"color": "#6FAFB8",
		"motto": "探索仍未结束",
		"ability": "自由调节自身生理年龄，停止生长或衰老，选择适合探索的身体状态。",
		"limits": "不改变心智、记忆或个体极限寿命，不能永生。",
		"number": 9,
		"interactions": "能力被压制时恢复原年龄，达到条件可能触发35岁死亡程序。"
	},
	"sage": {
		"id": "sage",
		"zodiac": "capricorn",
		"name": "摩羯座",
		"archetype": "智者",
		"power": "历史重现",
		"color": "#879EA8",
		"motto": "经验留下的形状",
		"ability": "指定过去发生的事件或时间，以客观画面呈现真实发生之事。",
		"limits": "每名使用者一生一次；不预言，不以问答直接给结论，也不作主观价值判断。",
		"number": 10,
		"interactions": "次数资格与身体个体信息有关，不能统一绑定意识；具体识别机制待定。"
	},
	"magician": {
		"id": "magician",
		"zodiac": "aquarius",
		"name": "水瓶座",
		"archetype": "魔法师",
		"power": "最终许愿钥匙",
		"color": "#7DA8C9",
		"motto": "为改变保留可能",
		"ability": "在其他全部11张卡已收齐时整合卡片，作为前往IGA许愿的钥匙。",
		"limits": "单独持有或未集齐时完全无效；不创造奇迹，不改变成功概率或现实。",
		"number": 11,
		"interactions": "钥匙不受反叛者否决。需收集其他全部11张，单独没有作用。"
	},
	"lover": {
		"id": "lover",
		"zodiac": "pisces",
		"name": "双鱼座",
		"archetype": "爱人",
		"power": "理想伴侣分身",
		"color": "#D3A4B8",
		"motto": "期待与真实自我",
		"ability": "卡本身化作理想伴侣分身，外貌与模拟性格随使用者期待适应。",
		"limits": "分身没有真正独立人格；过往形象与记忆相关故事仍待主创编写。",
		"number": 12,
		"interactions": "分身是卡牌本体；在反叛者范围内会停止行动。"
	}
}

static func definition(id: String) -> Dictionary:
	return ENTRIES.get(id,{}).duplicate(true)

static func known(id: String) -> bool:
	return ENTRIES.has(id)
