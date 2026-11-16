class_name SceneDesignCatalog
extends RefCounted

## Reversible visual proposals. This catalog never changes stable place/region IDs.
const NATIVE := Vector2(1672,941)
const DESIGN := Vector2(1920,1080)
const ROOT := "res://assets/ui/scene_reset/"
const PLACES := {
 "rooftop": {
  "image": "rooftop",
  "title": "教学楼天台",
  "objects": [
   {
    "id": "talk",
    "label": "聊聊天",
    "polygon": [
     [
      969,
      422
     ],
     [
      1327,
      453
     ],
     [
      1308,
      663
     ],
     [
      1030,
      682
     ],
     [
      962,
      599
     ]
    ],
    "tag": [
     1227,
     444,
     170,
     60
    ]
   },
   {
    "id": "rooftop_note",
    "label": "看看纸条",
    "polygon": [
     [
      818,
      548
     ],
     [
      903,
      540
     ],
     [
      944,
      561
     ],
     [
      905,
      586
     ],
     [
      822,
      575
     ]
    ],
    "tag": [
     688,
     528,
     190,
     60
    ]
   }
  ]
 },
 "library": {
  "image": "library",
  "title": "图书馆",
  "objects": [
   {
    "id": "read",
    "label": "翻阅书页",
    "polygon": [
     [
      251,
      679
     ],
     [
      555,
      626
     ],
     [
      807,
      641
     ],
     [
      980,
      785
     ],
     [
      597,
      857
     ],
     [
      225,
      891
     ]
    ],
    "tag": [
     800,
     623,
     198,
     64
    ]
   },
   {
    "id": "talk",
    "label": "和同学聊聊",
    "polygon": [
     [
      1280,
      443
     ],
     [
      1667,
      449
     ],
     [
      1668,
      647
     ],
     [
      1325,
      597
     ]
    ],
    "tag": [
     1218,
     367,
     210,
     64
    ]
   }
  ]
 },
 "gym": {
  "image": "gym",
  "title": "体育馆",
  "objects": [
   {
    "id": "training",
    "label": "模拟训练",
    "polygon": [
     [
      1084,
      371
     ],
     [
      1240,
      369
     ],
     [
      1250,
      504
     ],
     [
      1230,
      581
     ],
     [
      1076,
      587
     ]
    ],
    "tag": [
     1260,
     352,
     210,
     64
    ]
   },
   {
    "id": "workshop",
    "label": "整理行动卡",
    "polygon": [
     [
      228,
      581
     ],
     [
      361,
      563
     ],
     [
      395,
      591
     ],
     [
      395,
      659
     ],
     [
      251,
      665
     ],
     [
      221,
      637
     ]
    ],
    "tag": [
     449,
     567,
     220,
     64
    ]
   }
  ]
 },
 "shop": {
  "image": "shop",
  "title": "校园商店",
  "objects": [
   {
    "id": "shop",
    "label": "查看商品",
    "polygon": [
     [
      1179,
      374
     ],
     [
      1350,
      360
     ],
     [
      1454,
      422
     ],
     [
      1432,
      532
     ],
     [
      1188,
      483
     ]
    ],
    "tag": [
     1185,
     367,
     226,
     64
    ]
   },
   {
    "id": "delivery",
    "label": "看看送货单",
    "polygon": [
     [
      569,
      551
     ],
     [
      642,
      536
     ],
     [
      701,
      597
     ],
     [
      617,
      611
     ]
    ],
    "tag": [
     595,
     466,
     220,
     64
    ]
   }
  ]
 },
 "arete_coast_test": {
  "image": "coast",
  "title": "沿海道路 · TEST",
  "objects": [
   {
    "id": "coast_observe",
    "label": "看看海风",
    "polygon": [
     [
      156,
      546
     ],
     [
      321,
      507
     ],
     [
      372,
      622
     ],
     [
      287,
      741
     ],
     [
      194,
      724
     ]
    ],
    "tag": [
     289,
     510,
     210,
     64
    ]
   },
   {
    "id": "go",
    "label": "走向海滩",
    "target": "arete_beach_test",
    "polygon": [
     [
      1020,
      605
     ],
     [
      1265,
      649
     ],
     [
      1495,
      808
     ],
     [
      1360,
      902
     ],
     [
      1026,
      723
     ]
    ],
    "tag": [
     1270,
     599,
     220,
     64
    ]
   }
  ]
 },
 "arete_beach_test": {
  "image": "beach",
  "title": "阿瑞忒海滩 · TEST",
  "objects": [
   {
    "id": "coast_observe",
    "label": "看看海面",
    "polygon": [
     [
      120,
      440
     ],
     [
      1050,
      420
     ],
     [
      1060,
      740
     ],
     [
      140,
      760
     ]
    ],
    "tag": [
     440,
     560,
     220,
     64
    ]
   },
   {
    "id": "go",
    "label": "返回沿海道路",
    "target": "arete_coast_test",
    "polygon": [
     [
      1060,
      470
     ],
     [
      1560,
      470
     ],
     [
      1580,
      780
     ],
     [
      1050,
      780
     ]
    ],
    "tag": [
     1190,
     790,
     260,
     64
    ]
   }
  ]
 }
}
const MAPS := {
 "university_nomos": {
  "image": "map_nomos",
  "locations": {
   "nomos_home_test": {
    "label": "巨树酒馆",
    "polygon": [
     [
      451,
      220
     ],
     [
      790,
      175
     ],
     [
      899,
      380
     ],
     [
      838,
      591
     ],
     [
      572,
      631
     ],
     [
      424,
      493
     ]
    ],
    "tag": [
     812,
     480,
     230,
     68
    ]
   },
   "nomos_shop_test": {
    "label": "社区商店",
    "polygon": [
     [
      1330,
      460
     ],
     [
      1470,
      440
     ],
     [
      1535,
      520
     ],
     [
      1500,
      610
     ],
     [
      1340,
      600
     ]
    ],
    "tag": [
     1280,
     622,
     230,
     64
    ]
   }
  }
 },
 "university_agora": {
  "image": "map_agora",
  "locations": {
   "agora_home_test": {
    "label": "集体宿舍",
    "polygon": [
     [
      959,
      501
     ],
     [
      1406,
      522
     ],
     [
      1584,
      648
     ],
     [
      1436,
      833
     ],
     [
      1001,
      733
     ]
    ],
    "tag": [
     1232,
     486,
     220,
     68
    ]
   },
   "agora_shop_test": {
    "label": "地区商店",
    "polygon": [
     [
      420,
      330
     ],
     [
      625,
      310
     ],
     [
      710,
      420
     ],
     [
      600,
      475
     ],
     [
      432,
      430
     ]
    ],
    "tag": [
     510,
     467,
     230,
     64
    ]
   }
  }
 },
 "university_techne": {
  "image": "map_techne",
  "locations": {
   "techne_home_test": {
    "label": "研究制造室",
    "polygon": [
     [
      609,
      276
     ],
     [
      940,
      249
     ],
     [
      1178,
      361
     ],
     [
      1137,
      539
     ],
     [
      803,
      562
     ],
     [
      582,
      436
     ]
    ],
    "tag": [
     875,
     310,
     260,
     68
    ]
   },
   "techne_shop_test": {
    "label": "工坊用品店",
    "polygon": [
     [
      90,
      410
     ],
     [
      300,
      390
     ],
     [
      370,
      485
     ],
     [
      280,
      558
     ],
     [
      90,
      520
     ]
    ],
    "tag": [
     165,
     568,
     230,
     64
    ]
   }
  }
 },
 "region_failed_alliance": {
  "image": "map_failed",
  "locations": {
   "region_failed_alliance_gateway_test": {
    "label": "剧情入口",
    "polygon": [
     [
      634,
      387
     ],
     [
      852,
      358
     ],
     [
      1020,
      481
     ],
     [
      877,
      636
     ],
     [
      650,
      551
     ]
    ],
    "tag": [
     780,
     300,
     220,
     68
    ]
   },
   "region_failed_alliance_dungeon_test": {
    "label": "副本入口",
    "polygon": [
     [
      1245,
      204
     ],
     [
      1569,
      205
     ],
     [
      1659,
      305
     ],
     [
      1443,
      393
     ],
     [
      1257,
      326
     ]
    ],
    "tag": [
     1400,
     178,
     220,
     68
    ]
   },
   "region_failed_alliance_shop_test": {
    "label": "商店",
    "polygon": [
     [
      1151,
      515
     ],
     [
      1371,
      492
     ],
     [
      1519,
      553
     ],
     [
      1515,
      709
     ],
     [
      1190,
      714
     ]
    ],
    "tag": [
     1406,
     476,
     170,
     68
    ]
   },
   "region_failed_alliance_feature_test": {
    "label": "特殊功能",
    "polygon": [
     [
      156,
      516
     ],
     [
      341,
      504
     ],
     [
      444,
      605
     ],
     [
      359,
      748
     ],
     [
      150,
      694
     ]
    ],
    "tag": [
     275,
     579,
     230,
     68
    ]
   }
  }
 },
 "region_iga_church": {
  "image": "map_church",
  "locations": {
   "region_iga_church_gateway_test": {
    "label": "剧情入口",
    "polygon": [
     [
      676,
      498
     ],
     [
      933,
      484
     ],
     [
      1113,
      613
     ],
     [
      962,
      723
     ],
     [
      717,
      688
     ]
    ],
    "tag": [
     803,
     576,
     220,
     68
    ]
   },
   "region_iga_church_dungeon_test": {
    "label": "副本入口",
    "polygon": [
     [
      794,
      152
     ],
     [
      1093,
      145
     ],
     [
      1193,
      293
     ],
     [
      1123,
      404
     ],
     [
      856,
      399
     ],
     [
      755,
      284
     ]
    ],
    "tag": [
     818,
     204,
     220,
     68
    ]
   },
   "region_iga_church_shop_test": {
    "label": "商店",
    "polygon": [
     [
      232,
      555
     ],
     [
      425,
      545
     ],
     [
      548,
      666
     ],
     [
      455,
      757
     ],
     [
      237,
      704
     ]
    ],
    "tag": [
     422,
     659,
     170,
     68
    ]
   },
   "region_iga_church_feature_test": {
    "label": "特殊功能",
    "polygon": [
     [
      1341,
      408
     ],
     [
      1520,
      400
     ],
     [
      1624,
      519
     ],
     [
      1570,
      642
     ],
     [
      1367,
      613
     ]
    ],
    "tag": [
     1290,
     576,
     230,
     68
    ]
   }
  }
 },
 "resistance": {
  "image": "map_legacy_alliance",
  "locations": {
   "alliance_hq": {
    "label": "指挥所",
    "polygon": [
     [
      638,
      279
     ],
     [
      930,
      276
     ],
     [
      1106,
      409
     ],
     [
      1047,
      551
     ],
     [
      737,
      548
     ],
     [
      614,
      415
     ]
    ],
    "tag": [
     747,
     430,
     200,
     68
    ]
   },
   "alliance_intel": {
    "label": "情报站",
    "polygon": [
     [
      242,
      178
     ],
     [
      496,
      137
     ],
     [
      581,
      242
     ],
     [
      521,
      340
     ],
     [
      283,
      354
     ],
     [
      218,
      275
     ]
    ],
    "tag": [
     494,
     194,
     210,
     68
    ]
   },
   "alliance_drill": {
    "label": "演练场",
    "polygon": [
     [
      1165,
      152
     ],
     [
      1463,
      144
     ],
     [
      1631,
      255
     ],
     [
      1519,
      382
     ],
     [
      1202,
      364
     ]
    ],
    "tag": [
     1250,
     248,
     210,
     68
    ]
   },
   "alliance_supply": {
    "label": "补给处",
    "polygon": [
     [
      118,
      507
     ],
     [
      341,
      490
     ],
     [
      542,
      586
     ],
     [
      458,
      711
     ],
     [
      170,
      679
     ]
    ],
    "tag": [
     337,
     630,
     210,
     68
    ]
   },
   "alliance_quarters": {
    "label": "休整区",
    "polygon": [
     [
      1133,
      506
     ],
     [
      1464,
      465
     ],
     [
      1628,
      567
     ],
     [
      1528,
      721
     ],
     [
      1181,
      706
     ]
    ],
    "tag": [
     1425,
     657,
     210,
     68
    ]
   }
  }
 },
 "sanctuary": {
  "image": "map_legacy_sanctuary",
  "locations": {
   "sanctuary_hall": {
    "label": "会所",
    "polygon": [
     [
      707,
      466
     ],
     [
      1069,
      441
     ],
     [
      1233,
      557
     ],
     [
      1146,
      748
     ],
     [
      782,
      748
     ],
     [
      655,
      610
     ]
    ],
    "tag": [
     912,
     465,
     180,
     68
    ]
   },
   "sanctuary_cathedral": {
    "label": "圣堂",
    "polygon": [
     [
      719,
      118
     ],
     [
      1067,
      99
     ],
     [
      1157,
      209
     ],
     [
      1090,
      330
     ],
     [
      767,
      322
     ],
     [
      691,
      217
     ]
    ],
    "tag": [
     1004,
     128,
     190,
     68
    ]
   },
   "sanctuary_archive": {
    "label": "文献馆",
    "polygon": [
     [
      270,
      302
     ],
     [
      475,
      270
     ],
     [
      672,
      341
     ],
     [
      642,
      449
     ],
     [
      344,
      489
     ],
     [
      236,
      396
     ]
    ],
    "tag": [
     540,
     295,
     210,
     68
    ]
   },
   "sanctuary_garden": {
    "label": "庭院",
    "polygon": [
     [
      1239,
      318
     ],
     [
      1455,
      299
     ],
     [
      1621,
      417
     ],
     [
      1549,
      503
     ],
     [
      1302,
      473
     ]
    ],
    "tag": [
     1402,
     288,
     190,
     68
    ]
   },
   "sanctuary_lodging": {
    "label": "旅舍",
    "polygon": [
     [
      169,
      579
     ],
     [
      389,
      553
     ],
     [
      541,
      622
     ],
     [
      475,
      742
     ],
     [
      223,
      726
     ]
    ],
    "tag": [
     388,
     552,
     190,
     68
    ]
   }
  }
 }
}
const WORLD := {
 "university_nomos": {
  "polygon": [
   [
    100,
    143
   ],
   [
    489,
    100
   ],
   [
    610,
    252
   ],
   [
    599,
    382
   ],
   [
    252,
    450
   ],
   [
    78,
    326
   ]
  ],
  "tag": [
   355,
   335,
   245,
   66
  ]
 },
 "university_arete": {
  "polygon": [
   [
    70,
    438
   ],
   [
    424,
    435
   ],
   [
    604,
    562
   ],
   [
    562,
    748
   ],
   [
    230,
    794
   ],
   [
    78,
    668
   ]
  ],
  "tag": [
   304,
   662,
   245,
   66
  ]
 },
 "university_techne": {
  "polygon": [
   [
    665,
    126
   ],
   [
    976,
    96
   ],
   [
    1121,
    252
   ],
   [
    1111,
    426
   ],
   [
    836,
    433
   ],
   [
    630,
    307
   ]
  ],
  "tag": [
   896,
   310,
   245,
   66
  ]
 },
 "university_agora": {
  "polygon": [
   [
    1189,
    153
   ],
   [
    1516,
    114
   ],
   [
    1657,
    247
   ],
   [
    1655,
    432
   ],
   [
    1351,
    450
   ],
   [
    1169,
    335
   ]
  ],
  "tag": [
   1385,
   329,
   247,
   66
  ]
 },
 "region_failed_alliance": {
  "polygon": [
   [
    683,
    499
   ],
   [
    924,
    437
   ],
   [
    1163,
    554
   ],
   [
    1187,
    727
   ],
   [
    891,
    824
   ],
   [
    667,
    703
   ]
  ],
  "tag": [
   917,
   684,
   260,
   66
  ]
 },
 "region_iga_church": {
  "polygon": [
   [
    1242,
    508
   ],
   [
    1518,
    457
   ],
   [
    1658,
    579
   ],
   [
    1630,
    762
   ],
   [
    1373,
    816
   ],
   [
    1196,
    698
   ]
  ],
  "tag": [
   1360,
   650,
   280,
   66
  ]
 }
}

static func rect(values: Array) -> Rect2:
 return Rect2(values[0],values[1],values[2],values[3])

static func polygon(points: Array, source_size: Vector2 = NATIVE) -> PackedVector2Array:
 var result := PackedVector2Array()
 for point in points: result.append(Vector2(point[0],point[1])*source_size/NATIVE)
 return result

static func map_path(region_id: String) -> String:
 return ROOT+"maps/"+str(MAPS[region_id]["image"])+".png" if MAPS.has(region_id) else ""

static func place_config(id: String) -> Dictionary:
 if id in ["club","dorm"]: return {}
 if PLACES.has(id): return PLACES[id].duplicate(true)
 if id in ["study","stockroom"]:
  var base: Dictionary = PLACES["library" if id == "study" else "shop"].duplicate(true)
  base["title"] = str(CampusPlaces.PLACES[id]["title"])
  base["objects"] = []
  return base
 for region_id in WorldRegionContent.REGIONS:
  var spec: Dictionary = WorldRegionContent.REGIONS[region_id]
  if id == spec["first_entry_id"] or id in spec["places"]:
   var image := "world" if region_id == "university_arete" else str(MAPS[region_id]["image"])
   return {"image":image,"map_image":true,"title":str(CampusPlaces.PLACES[id]["title"]),"objects":[],"region":region_id}
 for region_id in ["resistance","sanctuary"]:
  if id in RegionCatalog.LEGACY_REGIONS[region_id]["places"]:
   return {"image":MAPS[region_id]["image"],"map_image":true,"title":str(CampusPlaces.PLACES[id]["title"]),"objects":[],"region":region_id}
 return {}

static func place_path(id: String) -> String:
 var config := place_config(id)
 if config.is_empty(): return ""
 return ROOT+("maps/" if config.get("map_image",false) else "places/")+str(config["image"])+".png"
