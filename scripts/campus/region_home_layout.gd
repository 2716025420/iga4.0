class_name RegionHomeLayout
extends RefCounted

## Measured against the 1920x1080 central layer (matching 2340x1080 wide room at x=210..2130).
const HOMES := {
 "techne_home_test":{
  "slug":"techne","title":"忒克捏","native":Vector2(1920,1080),"ink":"#252B37","fill":"#F8F5EC","selected":"#D5DFCA","clock_ink":"#252B37",
  "date_backing":Rect2(126,60,466,292),"clock":Rect2(158,126,402,68),"remaining":Rect2(158,204,402,126),
  "menu":Rect2(1422,60,204,92),"menu_inset":Vector2(0,22),
  "objects":{
   "workshop":{"label":Rect2(516,944,310,60),"inset":Rect2(76,0,226,60),"index":0,"polygon":[[380,710],[410,665],[705,645],[845,745],[845,845],[505,910],[405,840]]},
   "records":{"label":Rect2(1160,956,320,60),"inset":Rect2(80,0,232,60),"index":1,"polygon":[[880,760],[1210,700],[1590,775],[1645,845],[1550,945],[1180,910],[915,845]]},
   "map":{"label":Rect2(928,660,320,62),"inset":Rect2(80,0,232,62),"index":-1,"polygon":[[875,400],[1395,375],[1375,650],[920,645]]},
   "partner_test":{"label":Rect2(1572,734,282,62),"inset":Rect2(68,0,206,62),"index":2,"polygon":[[1490,520],[1820,520],[1850,700],[1520,695]]}
  }
 },
 "nomos_home_test":{
  "slug":"nomos","title":"诺莫斯","native":Vector2(1920,1080),"ink":"#3D2B20","fill":"#EBD0A6","selected":"#CEDDBD","clock_ink":"#263851",
  "date_backing":Rect2(148,64,442,258),"clock":Rect2(174,88,392,68),"remaining":Rect2(174,168,392,132),
  "menu":Rect2(1404,54,292,90),"menu_inset":Vector2(56,0),
  "objects":{
   "workshop":{"label":Rect2(398,872,274,88),"inset":Rect2(34,2,232,82),"index":0,"polygon":[[360,785],[575,705],[890,735],[885,850],[700,930],[405,880]]},
   "records":{"label":Rect2(1152,932,296,94),"inset":Rect2(40,2,248,88),"index":1,"polygon":[[990,775],[1270,740],[1435,775],[1430,885],[1145,935],[1015,880]]},
   "map":{"label":Rect2(936,644,254,86),"inset":Rect2(36,2,210,80),"index":-1,"polygon":[[825,525],[1110,480],[1475,550],[1475,655],[1185,685],[865,625]]},
   "partner_test":{"label":Rect2(1570,766,256,76),"inset":Rect2(34,2,214,72),"index":2,"polygon":[[1510,595],[1670,595],[1690,715],[1620,740],[1530,715]]}
  }
 },
 "agora_home_test":{
  "slug":"agora","title":"阿戈拉","native":Vector2(1920,1080),"ink":"#34423E","fill":"#F2E7CB","selected":"#D5DFBB","clock_ink":"#2F3A36",
  "date_backing":Rect2(130,40,410,276),"clock":Rect2(174,84,344,64),"remaining":Rect2(174,160,340,118),
  "menu":Rect2(1502,36,202,134),"menu_inset":Vector2(0,44),
  "objects":{
   "workshop":{"label":Rect2(456,848,344,84),"inset":Rect2(48,14,284,66),"index":0,"polygon":[[325,730],[580,670],[885,755],[885,845],[620,895],[365,815]]},
   "records":{"label":Rect2(1158,886,358,90),"inset":Rect2(50,14,296,72),"index":1,"polygon":[[990,750],[1360,715],[1565,785],[1555,890],[1150,945],[1025,860]]},
   "map":{"label":Rect2(994,544,302,78),"inset":Rect2(46,12,246,62),"index":-1,"polygon":[[775,580],[1040,560],[1375,595],[1310,695],[935,688],[790,640]]},
   "partner_test":{"label":Rect2(1512,714,306,86),"inset":Rect2(46,14,248,68),"index":2,"polygon":[[1395,595],[1520,565],[1870,565],[1880,675],[1515,702],[1410,688]]}
  }
 }
}
