# 三学院 Home · 家具分层与分辨率校验

> 历史阶段记录。2026-10-25已替换旧家具层并清理历史截图/一次性脚本；6张概念原图与原验收数据原样保留。当前实现、检查与恢复清单见[场景重置](../../2026-10-25/SCENE_RESET.md)。下文旧验收数字只代表该阶段。

主创先认可忒克捏高视角并要求扣出家具做可点击按钮，随后明确“继续完成其它的两个场景和分辨率校验，直接先实装”，并补充“记着保留原始概念图”。本轮诺莫斯、阿戈拉也已实际接入游戏。

**原图原样保留：**第一版与后续视角版共6张概念PNG均位于 [concepts](concepts/)，没有覆盖、裁剪或重命名。已和`d86f6e9`中的原始字节逐一比较；[ORIGINALS.json](concepts/ORIGINALS.json)记录完整路径、尺寸和SHA256。新图层在`assets/ui/region_homes/{nomos,agora,techne}/`，实机截图另存于本交付目录。

| 场景 | 卡牌整理物品 | 记录物品 | 地图物品 | 伙伴交流物品 |
| --- | --- | --- | --- | --- |
| 诺莫斯巨树酒馆 | 随行木匣 | 议事簿 | 门边导览图 | 围桌席 |
| 阿戈拉集中营宿舍 | 床边布包 | 共用记事本 | 墙上路线图 | 床沿坐席 |
| 忒克捏研究制造室 | 工作台卡架 | 研究手记 | 墙上索引图 | 协作台 |

每个场景有独立清理背景＋4个真实RGBA物品层，保留各自透视与位置。运行中物品轮廓和实时文字标签都能点击；悬浮/焦点提亮、按下变暗，选中物品与标签保持强调，关闭面板清除选择并恢复焦点。透明空白不触发；减少动态下保留静态反馈，不加描边。伙伴交流仍为TEST内容，不消耗活动、不推进时间或发收益。

实现共用`RegionHomeView`、`RegionHomeLayout`、`HomeObjectButton`，沿用`CampusScreen`和原整理/记录/地图服务；`TechneHomeView`保留为兼容子类。布局与标签材料分别配置，操作文案从原地区地点配置读取，没有复制三个状态管理器。旧地区ID、Home地点ID和存档键未更改。

每个资源目录的`manifest.json`记录源图、SHA256、真实输出尺寸和透明区域。源概念图是1672×941；独立生成层尺寸各异，均按真实值记录，运行按1920×1080逻辑画布配准，没有冒称原生1920母图。生成提取含重绘，纹理、细节和大小仍有与母图的差异，后续可继续精修。三个新场景当前各有一套光照背景；“夜晚长日期”校验的是文字布局，独立夜景/三时段背景尚未制作。正式人物/对白仍待主创编写。

复现：

```bash
bash tools/cloud/check.sh
bash tools/cloud/test_p5.sh
P5_TEST_SCENE=res://tools/tests/home_objects.tscn bash tools/cloud/test_p5.sh
DISPLAY=:97 P5_TEST_SCENE=res://tools/tests/home_objects.tscn P5_CAPTURE_DIR=/tmp/homes-1920 P5_RESOLUTION=1920x1080 bash tools/cloud/test_p5.sh
DISPLAY=:97 P5_TEST_SCENE=res://tools/tests/home_objects.tscn P5_CAPTURE_DIR=/tmp/homes-1600 P5_RESOLUTION=1600x900 bash tools/cloud/test_p5.sh
```

最终结果：云端导入/启动通过；六地区核心**539项**；三场景物品专项headless **174项**（每景58）；1920×1080和1600×900 **各198项**（每景66），全部0失败。覆盖鼠标/键盘、alpha透明误点、家具与标签入口、持续选中及关闭恢复、地图回程、时间/收益隔离、日期更新、标签不越界/不遮挡日期、功能文字适配及12月31日夜晚长文本。

[1920×1080截图](https://github.com/2716025420/just-life/tree/b74cbdd/docs/2026-10-24/p5-delivery/object-feedback/1920x1080/) / [1600×900截图](https://github.com/2716025420/just-life/tree/b74cbdd/docs/2026-10-24/p5-delivery/object-feedback/1600x900/)各24张，共48张。每景8张：正常、悬浮、按下、四物品分别选中、长日期。`selected_*`是直接呈现选择状态供视觉核对；实际打开面板、保持选择及关闭清除另有输入断言。已逐场核对实际渲染，修正酒馆木匣/议事簿及宿舍记事本的承托配准。这是自动化图形及交互校验，完整人工P6仍为后续任务。
