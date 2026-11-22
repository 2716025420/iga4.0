"""IGA Story Studio exporter, Markdown script generator, and GDScript two-way syncer."""
from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
import re
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
STUDIO_DIR = Path(__file__).resolve().parent
SCRIPTS_DOC_DIR = ROOT / "docs" / "story" / "scripts"

PHASE_TWO_GD = ROOT / "scripts" / "global" / "phase_two_content.gd"
CAMPUS_PLACES_GD = ROOT / "scripts" / "campus" / "campus_places.gd"
CAMPUS_LIFE_GD = ROOT / "scripts" / "campus" / "campus_life.gd"
EXPLORATION_ROUTES_GD = ROOT / "scripts" / "global" / "school_exploration_routes.gd"
ZODIAC_CATALOG_GD = ROOT / "scripts" / "data_models" / "zodiac_catalog.gd"
PARALLAX_CUTSCENE_GD = ROOT / "scripts" / "ui" / "parallax_cutscene_stage.gd"
AUDIO_MANAGER_GD = ROOT / "scripts" / "global" / "audio_manager.gd"
COMBAT_SCREEN_GD = ROOT / "scripts" / "combat" / "combat_screen.gd"

BUNDLE_JSON = STUDIO_DIR / "story_bundle.json"
BUNDLE_JS = STUDIO_DIR / "story_data.js"

EMOTION_TO_CN = {
    "neutral": "平静",
    "happy": "微笑",
    "shy": "害羞",
    "surprised": "惊讶",
    "angry": "愤怒",
    "worried": "担忧",
    "concerned": "担忧",
    "damaged_fiber": "光纤受损",
    "crystal_stasis": "结晶休眠",
    "unmasked": "摘面具",
}
CN_TO_EMOTION = {v: k for k, v in EMOTION_TO_CN.items()}
CN_TO_EMOTION["蒙面"] = "neutral"
CN_TO_EMOTION["默认"] = "neutral"

SIDE_TO_CN = {"left": "左", "right": "右"}
CN_TO_SIDE = {"左": "left", "右": "right", "left": "left", "right": "right"}

BG_CHOICES = [
    {"id": "prologue_sakura_road", "label": "序章 · 樱林上学路", "phase2_key": "prologue_sakura_road"},
    {"id": "prologue_sports_field", "label": "序章 · 操场海选赛", "phase2_key": "prologue_sports_field"},
    {"id": "battle_sports_field", "label": "序章 · 操场 2v2 对决战台", "phase2_key": "battle_sports_field"},
    {"id": "prologue_club_meeting", "label": "序章 · 决斗社团首次会议", "phase2_key": "prologue_club_meeting"},
    {"id": "morning_road", "label": "上学樱道（旧版底图）", "phase2_key": "morning_road"},
    {"id": "school_gate", "label": "运动会 / 校门（旧版底图）", "phase2_key": "school_gate"},
    {"id": "school_room", "label": "社团教室（白）", "phase2_key": "school_room"},
    {"id": "club", "label": "社团教室 Home（午后）", "phase2_key": "school_room"},
    {"id": "club_morning", "label": "社团教室 Home（清晨）", "phase2_key": "school_room"},
    {"id": "club_night", "label": "社团教室 Home（夜晚）", "phase2_key": "school_room"},
    {"id": "library", "label": "阿瑞忒图书馆", "phase2_key": "school_room"},
    {"id": "shop", "label": "校园商店", "phase2_key": "school_room"},
    {"id": "gym", "label": "体育馆", "phase2_key": "school_room"},
    {"id": "rooftop", "label": "教学楼天台", "phase2_key": "school_room"},
    {"id": "dorm", "label": "学生宿舍", "phase2_key": "school_room"},
    {"id": "coast", "label": "沿海公路", "phase2_key": "dusk_road"},
    {"id": "beach", "label": "阿瑞忒海滩", "phase2_key": "dusk_road"},
    {"id": "old_park", "label": "旧公园（黄昏分层）", "phase2_key": "dusk_road"},
    {"id": "dusk_road", "label": "黄昏街道", "phase2_key": "dusk_road"},
    {"id": "battle_campus", "label": "校园对决舞台", "phase2_key": "battle_campus"},
    {"id": "battle_red_moon_lockdown", "label": "红月封锁夜战", "phase2_key": "battle_red_moon_lockdown"},
    {"id": "nomos_home", "label": "诺莫斯 · 巨树酒馆", "phase2_key": "school_room"},
    {"id": "techne_home", "label": "忒克捏 · 黑白研究室", "phase2_key": "school_room"},
    {"id": "agora_home", "label": "阿戈拉 · 强劳宿舍", "phase2_key": "dusk_road"},
]

BGM_CHOICES = [
    {"id": "bgm_title_serene", "label": "清晨舒缓 (bgm_title_serene)"},
    {"id": "bgm_campus_daily", "label": "校园日常 (bgm_campus_daily)"},
    {"id": "bgm_shop_breeze", "label": "海风商店 (bgm_shop_breeze)"},
    {"id": "bgm_dusk_memory", "label": "黄昏回忆 (bgm_dusk_memory)"},
    {"id": "bgm_duel_practice", "label": "阳光切磋 (bgm_duel_practice)"},
    {"id": "bgm_redmoon_overclock", "label": "红月超限 (bgm_redmoon_overclock)"},
    {"id": "bgm_victory_stinger", "label": "胜利觉醒 (bgm_victory_stinger)"},
]

CUTSCENE_LABELS = {
    "": "无视差过场",
    "dusk_corridor": "黄昏走廊 (dusk_corridor)",
    "old_park_dusk": "旧公园长椅黄昏 (old_park_dusk)",
    "rebel_warning": "废街反叛者奇袭 (rebel_warning)",
    "red_moon_street": "红月封锁街区 (red_moon_street)",
    "qiufeng_crystal": "秋枫结晶封印 (qiufeng_crystal)",
    "red_moon_finale": "红月夜誓言 (red_moon_finale)",
    "arena_spotlight": "选拔赛舞台聚光灯 (arena_spotlight)",
}

PHASE_2_VALID_BGS = {
    "prologue_sakura_road",
    "prologue_sports_field",
    "battle_sports_field",
    "prologue_club_meeting",
    "morning_road",
    "school_gate",
    "school_room",
    "dusk_road",
    "battle_campus",
    "battle_red_moon_lockdown",
}


def _extract_balanced(text: str, start_idx: int) -> tuple[str, int]:
    """Extract a balanced {...} or [...] block while respecting quoted strings."""
    open_ch = text[start_idx]
    close_ch = "}" if open_ch == "{" else "]"
    depth = 0
    in_str = False
    escape = False
    i = start_idx
    while i < len(text):
        ch = text[i]
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
        else:
            if ch == '"':
                in_str = True
            elif ch == open_ch:
                depth += 1
            elif ch == close_ch:
                depth -= 1
                if depth == 0:
                    return text[start_idx : i + 1], i + 1
        i += 1
    raise ValueError(f"Unbalanced block starting at {start_idx}")


def _extract_gd_const(text: str, name: str) -> Any:
    """Parse a GDScript const literal (Dictionary or Array) into Python."""
    m = re.search(rf"^const\s+{re.escape(name)}(?:\s*:\s*[^=]*)?\s*=\s*([{{\[])", text, re.MULTILINE)
    if not m:
        raise ValueError(f"Could not locate const {name}")
    block, _ = _extract_balanced(text, m.start(1))
    # Strip GDScript comments outside strings and trailing commas if any
    cleaned = re.sub(r",(\s*[}\]])", r"\1", block)
    return json.loads(cleaned)


def _extract_gd_string_const(text: str, name: str) -> str:
    m = re.search(rf'^const\s+{re.escape(name)}(?:\s*:\s*String)?\s*=\s*"((?:[^"\\]|\\.)*)"', text, re.MULTILINE)
    if not m:
        return ""
    return json.loads(f'"{m.group(1)}"')


def _parse_cutscene_presets(text: str) -> dict[str, dict[str, Any]]:
    presets: dict[str, dict[str, Any]] = {}
    m = re.search(r"const\s+PRESETS\s*:?=\s*\{", text)
    if not m:
        return presets
    block, _ = _extract_balanced(text, m.end() - 1)
    # Replace Vector2(a, b) with [a, b]
    json_like = re.sub(r"Vector2\(\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*\)", r"[\1, \2]", block)
    json_like = re.sub(r",(\s*[}\]])", r"\1", json_like)
    try:
        raw = json.loads(json_like)
        for pid, spec in raw.items():
            presets[pid] = {
                "id": pid,
                "label": CUTSCENE_LABELS.get(pid, pid),
                "status": spec.get("status", ""),
                "bg_path": str(spec.get("bg_path", "")).replace("res://", ""),
                "fg_path": str(spec.get("fg_path", "")).replace("res://", ""),
                "duration": spec.get("duration", 3.4),
                "bg_start": spec.get("bg_start", [-210, 0]),
                "bg_end": spec.get("bg_end", [-210, 0]),
                "bg_scale": spec.get("bg_scale", [1.0, 1.04]),
                "fg_start": spec.get("fg_start", [0, 0]),
                "fg_end": spec.get("fg_end", [0, 0]),
                "fg_scale": spec.get("fg_scale", [1.0, 1.08]),
            }
    except json.JSONDecodeError:
        pass
    return presets


def _parse_sfx_keys(text: str) -> list[dict[str, str]]:
    try:
        raw = _extract_gd_const(text, "SFX_KEYS")
        sfx_dir = ROOT / "assets" / "audio" / "sfx"
        out: list[dict[str, str]] = []
        for k, v in raw.items():
            chosen = f"assets/audio/sfx/{v}.wav"
            for ext in (".ogg", ".wav", ".mp3"):
                if (sfx_dir / f"{v}{ext}").is_file():
                    chosen = f"assets/audio/sfx/{v}{ext}"
                    break
            out.append({"id": k, "file": chosen})
        return out
    except Exception:
        return []


def _parse_enemies(text: str) -> list[dict[str, Any]]:
    enemies: list[dict[str, Any]] = []
    block_m = re.search(r"func _create_enemy_data\(eid: String\) -> EnemyData:\n(.*?)\n\tvar sprite_path", text, re.DOTALL)
    if not block_m:
        return enemies
    body = block_m.group(1)
    current_ids: list[str] = []
    cur_name = ""
    cur_hp = 0
    cur_rank = "NORMAL"

    def flush() -> None:
        if current_ids and cur_name:
            eid = current_ids[0]
            vis = "liu_yu_long_duel" if eid == "liu_yu_long_duel" else (
                "ch1_hunter_mech" if eid in ["ch1_hunter_mech", "principal", "boss_frank"] else eid
            )
            sprite_p = ROOT / "assets" / "sprites" / "enemies" / "phase_three" / f"enemy_{vis}.png"
            if eid == "liu_yu_long_duel":
                sprite_rel = "assets/sprites/characters/phase_three/combat/combat_liu_yu_long_idle.png"
            elif sprite_p.exists():
                sprite_rel = f"assets/sprites/enemies/phase_three/enemy_{vis}.png"
            else:
                sprite_rel = ""
            enemies.append({
                "id": eid,
                "aliases": current_ids[1:],
                "name": cur_name,
                "max_hp": cur_hp,
                "rank": cur_rank,
                "sprite": sprite_rel,
            })

    for line in body.splitlines():
        case_m = re.match(r"^\t\t(.+):\s*$", line)
        if case_m:
            flush()
            current_ids = re.findall(r'"([^"]+)"', case_m.group(1))
            cur_name, cur_hp, cur_rank = "", 0, "NORMAL"
            continue
        name_m = re.search(r'e\.name\s*=\s*"([^"]+)"', line)
        if name_m:
            cur_name = name_m.group(1)
        hp_m = re.search(r"e\.max_hp\s*=\s*(\d+)", line)
        if hp_m:
            cur_hp = int(hp_m.group(1))
        rank_m = re.search(r"e\.rank\s*=\s*EnemyData\.EnemyRank\.(\w+)", line)
        if rank_m:
            cur_rank = rank_m.group(1)
    flush()
    return enemies


def _parse_exploration_variants(text: str) -> list[list[dict[str, Any]]]:
    m = re.search(r"static func dialogue_lines\(.*?\).*?\n\tvar variants:\s*Array\[Array\]\s*=\s*(\[)", text, re.DOTALL)
    if not m:
        raise ValueError("Could not locate SchoolExplorationRoutes.dialogue_lines variants")
    block, _ = _extract_balanced(text, m.start(1))
    cleaned = re.sub(r",(\s*[}\]])", r"\1", block)
    return json.loads(cleaned)


def _parse_campus_npc_lines(text: str) -> list[dict[str, Any]]:
    """Parse CampusLife.npc_lines into editable conditioned scenes."""
    m = re.search(r"func npc_lines\(npc_id: String\) -> Array:\n(.*?)\nfunc _record_activity", text, re.DOTALL)
    if not m:
        return []
    body = m.group(1)

    def _convert_pairs(pairs: list[list[str]], npc_char: str) -> list[dict[str, Any]]:
        lines: list[dict[str, Any]] = []
        for sp, txt in pairs:
            cid = npc_char if sp != "我" else "ye_zhou"
            side = "left" if sp == "我" else "right"
            lines.append({"speaker": sp, "char": cid, "side": side, "emotion": "neutral", "text": txt})
        return lines

    # Extract each npc branch cleanly
    npc_meta = {
        "lin_zhi_xia": {"title": "图书馆 · 林知夏日常对话", "bg": "library", "location": "library"},
        "tang_xiao_man": {"title": "校园商店 · 唐小满日常对话", "bg": "shop", "location": "shop"},
        "liu_yu_long": {"title": "天台 / 体育馆 · 柳宇龙日常对话", "bg": "gym", "location": "gym"},
        "yang_zi_ying": {"title": "天台 · 杨子英日常对话", "bg": "rooftop", "location": "rooftop"},
        "jiang_zi": {"title": "社团教室 / 天台 · 姜梓日常对话", "bg": "club", "location": "club"},
    }
    scenes: list[dict[str, Any]] = []
    branches = re.split(r'\n  "([a-z_]+)":\n', body)
    # branches: [prefix, npc_id1, block1, npc_id2, block2, ...]
    for i in range(1, len(branches), 2):
        npc_id = branches[i]
        block = branches[i + 1]
        meta = npc_meta.get(npc_id, {"title": npc_id, "bg": "school_room", "location": ""})
        blocks_out: list[dict[str, Any]] = []
        if "if count == 0:" in block:
            ret_arrays = re.findall(r"return\s+(\[\[.*?\]\])", block)
            if len(ret_arrays) >= 2:
                blocks_out.append({
                    "condition_key": "first_talk",
                    "condition_label": "首次交谈 (count == 0)",
                    "lines": _convert_pairs(json.loads(ret_arrays[0]), npc_id),
                })
                blocks_out.append({
                    "condition_key": "repeat_talk",
                    "condition_label": "日常重复交谈",
                    "lines": _convert_pairs(json.loads(ret_arrays[1]), npc_id),
                })
        elif 'arete_qualifier_completed' in block:
            ret_arrays = re.findall(r"return\s+(\[\[.*?\]\])", block)
            if len(ret_arrays) >= 2:
                blocks_out.append({
                    "condition_key": "post_qualifier",
                    "condition_label": "选拔赛全胜通关后 (arete_qualifier_completed)",
                    "lines": _convert_pairs(json.loads(ret_arrays[0]), npc_id),
                })
                blocks_out.append({
                    "condition_key": "default",
                    "condition_label": "常规对话",
                    "lines": _convert_pairs(json.loads(ret_arrays[1]), npc_id),
                })
        else:
            ret_arrays = re.findall(r"return\s+(\[\[.*?\]\])", block)
            if ret_arrays:
                blocks_out.append({
                    "condition_key": "default",
                    "condition_label": "常规对话",
                    "lines": _convert_pairs(json.loads(ret_arrays[0]), npc_id),
                })
        scenes.append({
            "id": f"npc_{npc_id}",
            "npc_id": npc_id,
            "target_type": "campus_life_npc",
            "category": "campus_npcs",
            "phase": "日常驻场",
            "title": meta["title"],
            "location": meta["location"],
            "bg": meta["bg"],
            "bgm": "bgm_campus_daily",
            "default_cutscene": "",
            "note": "对应 scripts/campus/campus_life.gd 中 npc_lines()，支持首次/重复/通关条件分块。",
            "conditions": blocks_out,
        })
    return scenes


def _build_assets_manifest(actors: dict[str, Any], enemies: list[dict[str, Any]], presets: dict[str, Any]) -> dict[str, Any]:
    """Scan assets/ to produce verified relative asset paths for Story Studio preview."""
    char_assets: dict[str, dict[str, Any]] = {}
    char_root = ROOT / "assets" / "sprites" / "characters" / "phase_two"

    all_char_ids = list(actors.keys()) + [
        "thug_grunt",
        "thug_boss",
        "rebel_operative_masked",
        "rebel_operative_unmasked",
        "alliance_operative",
        "agora_broker",
        "nomos_arbiter",
        "techne_researcher",
        "security_guard",
        "campus_robot",
        "ch1_hunter_mech",
    ]
    seen_ids: set[str] = set()
    for raw_id in all_char_ids:
        if raw_id in seen_ids:
            continue
        seen_ids.add(raw_id)
        emotions: dict[str, str] = {}
        avatars: dict[str, dict[str, Any]] = {}

        actual_id = "rebel_operative_masked" if raw_id == "alliance_operative" else raw_id
        emo_dir = char_root / "emotions" / actual_id
        if emo_dir.is_dir():
            for png in sorted(emo_dir.glob("*.png")):
                emotions[png.stem] = f"assets/sprites/characters/phase_two/emotions/{actual_id}/{png.name}"

        # Halfbody variants
        halfbody_plain = char_root / "halfbody" / f"{actual_id}.png"
        if halfbody_plain.exists() and "neutral" not in emotions:
            emotions["neutral"] = f"assets/sprites/characters/phase_two/halfbody/{actual_id}.png"

        for npc_emo in ["neutral", "happy"]:
            hp = char_root / "halfbody" / f"{actual_id}_{npc_emo}.png"
            if hp.exists():
                emotions[npc_emo] = f"assets/sprites/characters/phase_two/halfbody/{actual_id}_{npc_emo}.png"

        if raw_id in ["rebel_operative_masked", "alliance_operative"]:
            masked = char_root / "halfbody" / "rebel_operative_masked.png"
            unmasked = char_root / "halfbody" / "rebel_operative_unmasked.png"
            if masked.exists():
                emotions["neutral"] = "assets/sprites/characters/phase_two/halfbody/rebel_operative_masked.png"
            if unmasked.exists():
                emotions["unmasked"] = "assets/sprites/characters/phase_two/halfbody/rebel_operative_unmasked.png"

        # Enemy portrait / combat sprite fallback
        enemy_portrait = ROOT / "assets" / "sprites" / "enemies" / "phase_two" / "portraits" / f"{raw_id}.png"
        enemy_p3 = ROOT / "assets" / "sprites" / "enemies" / "phase_three" / f"enemy_{raw_id}.png"
        if not emotions and enemy_portrait.exists():
            emotions["neutral"] = f"assets/sprites/enemies/phase_two/portraits/{raw_id}.png"
        elif not emotions and enemy_p3.exists():
            emotions["neutral"] = f"assets/sprites/enemies/phase_three/enemy_{raw_id}.png"

        # Avatars matching DialogueScreen._refresh_speaker_avatar()
        for emo_key in ["neutral", "happy", "shy", "surprised", "angry", "worried", "damaged_fiber", "crystal_stasis", "unmasked"]:
            av_key = "rebel_operative_unmasked" if (raw_id in ["rebel_operative_masked", "alliance_operative"] and emo_key == "unmasked") else actual_id
            v7_av = char_root / "avatars" / f"{av_key}_{emo_key}.png"
            v7_neu = char_root / "avatars" / f"{av_key}_neutral.png"
            por_p = char_root / "portraits" / f"{av_key}.png"
            if v7_av.exists():
                avatars[emo_key] = {"path": f"assets/sprites/characters/phase_two/avatars/{av_key}_{emo_key}.png", "crop": False}
            elif v7_neu.exists():
                avatars[emo_key] = {"path": f"assets/sprites/characters/phase_two/avatars/{av_key}_neutral.png", "crop": False}
            elif por_p.exists():
                avatars[emo_key] = {"path": f"assets/sprites/characters/phase_two/portraits/{av_key}.png", "crop": False}
            elif emo_key in emotions:
                avatars[emo_key] = {"path": emotions[emo_key], "crop": True}
            elif "neutral" in emotions:
                avatars[emo_key] = {"path": emotions["neutral"], "crop": True}

        char_assets[raw_id] = {"emotions": emotions, "avatars": avatars}

    # Backgrounds map
    bg_assets: dict[str, dict[str, Any]] = {}
    phase2_bg_dir = ROOT / "assets" / "backgrounds" / "phase_two"
    for name in [
        "prologue_sakura_road",
        "prologue_sports_field",
        "battle_sports_field",
        "prologue_club_meeting",
        "morning_road",
        "school_gate",
        "school_room",
        "dusk_road",
        "battle_campus",
        "battle_red_moon_lockdown",
    ]:
        wide = phase2_bg_dir / f"{name}_wide.png"
        std = phase2_bg_dir / f"{name}.png"
        p = wide if wide.exists() else std
        if p.exists():
            layers = [f"assets/backgrounds/phase_two/{p.name}"]
            if name == "prologue_sports_field":
                ov_wide = phase2_bg_dir / "overlays" / "prologue_sports_field_duel_crowd_wide.png"
                ov_std = phase2_bg_dir / "overlays" / "prologue_sports_field_duel_crowd.png"
                ov = ov_wide if ov_wide.exists() else ov_std
                if ov.exists():
                    layers.append(f"assets/backgrounds/phase_two/overlays/{ov.name}")
            bg_assets[name] = {"layers": layers}

    fallback_bgs = {
        "prologue_sakura_road": "assets/backgrounds/phase_two/morning_road_wide.png",
        "prologue_sports_field": "assets/backgrounds/phase_two/school_gate_wide.png",
        "battle_sports_field": "assets/backgrounds/phase_two/battle_campus_wide.png",
        "prologue_club_meeting": "assets/backgrounds/phase_two/school_room_wide.png",
    }
    for key, rel in fallback_bgs.items():
        if key not in bg_assets and (ROOT / rel).exists():
            bg_assets[key] = {"layers": [rel]}

    bg_assets["club"] = {"layers": ["assets/ui/player_experience/home_room_v3.png"]}
    bg_assets["club_morning"] = {"layers": ["assets/ui/player_experience/home_room_morning_v1.png"]}
    bg_assets["club_night"] = {"layers": ["assets/ui/player_experience/home_room_night_v1.png"]}
    bg_assets["dorm"] = {"layers": ["assets/ui/campus_life/dorm_bg_wide.png"]}

    for place_id in ["library", "shop", "gym", "rooftop", "coast", "beach"]:
        place_wide = ROOT / "assets" / "ui" / "scene_reset" / "places" / f"{place_id}_wide.png"
        if place_wide.exists():
            bg_assets[place_id] = {"layers": [f"assets/ui/scene_reset/places/{place_id}_wide.png"]}

    bg_assets["old_park"] = {
        "layers": [
            "assets/ui/scene_reset/staged/shared/sky_arete_dusk_wide.png",
            "assets/ui/scene_reset/staged/old_park/old_park_midground_wide.png",
            "assets/ui/scene_reset/staged/old_park/old_park_foreground_wide.png",
        ]
    }
    bg_assets["nomos_home"] = {"layers": ["assets/ui/scene_reset/homes/nomos_clean_wide.png"]}
    bg_assets["agora_home"] = {"layers": ["assets/ui/scene_reset/homes/agora_clean_wide.png"]}
    bg_assets["techne_home"] = {"layers": ["assets/ui/scene_reset/homes/techne_clean_wide.png"]}

    return {
        "characters": char_assets,
        "backgrounds": bg_assets,
        "cutscenes": presets,
        "ui": {
            "story_chrome": "assets/ui/school_objects/story_chrome.png",
            "choice_9slice": "assets/ui_core/theme/dialogue_choice_9slice.png",
            "chapter_banner": "assets/ui_core/animations/ui_chapter_banner.png",
            "paper_modal": "assets/ui_core/theme/paper_modal_9slice.png",
        },
        "enemies": enemies,
    }


def _parse_oral_prologue_demo1() -> dict[str, Any]:
    """Extract Demo 1 from docs/story/IGA_正式剧本编写范本.md as structured lines."""
    doc_path = ROOT / "docs" / "story" / "IGA_正式剧本编写范本.md"
    lines: list[dict[str, Any]] = []
    if doc_path.exists():
        content = doc_path.read_text(encoding="utf-8")
        m = re.search(r"### 示范 1：主线剧情幕.*?\n```markdown\n(.*?)\n```", content, re.DOTALL)
        if m:
            raw_md = m.group(1)
            # Strip YAML frontmatter
            raw_body = re.sub(r"^---\n.*?\n---\n+", "", raw_md, flags=re.DOTALL)
            lines = parse_stream_text(raw_body, default_actors_lookup())
    return {
        "id": "prologue_01_alley_rescue",
        "node": "n_oral_01",
        "category": "prologue_oral_drafts",
        "target_type": "draft",
        "phase": "口述序章 · A",
        "title": "街角解围与退缩（范本示范稿）",
        "location": "morning_road",
        "bg": "morning_road",
        "bgm": "bgm_campus_daily",
        "default_cutscene": "",
        "next_action": "推进至次日运动会 (prologue_02_sports_day)",
        "unlock_flags": ["prologue_rescue_done"],
        "note": "源自 IGA_正式剧本编写范本.md（严格按 2026-10-28 口述 A 编写：叶舟未主动出头仅啧了一声被拽衣帽，黄秋枫叫停，小混混威胁叶舟附和，叶舟羞耻逃跑）。",
        "lines": lines,
    }


def default_actors_lookup() -> dict[str, dict[str, Any]]:
    text = PHASE_TWO_GD.read_text(encoding="utf-8")
    actors = _extract_gd_const(text, "ACTORS")
    # Augment with non-ACTORS built-in speakers
    extra = {
        "rebel_operative_masked": {"name": "灰区女特工", "title": "灰区反叛组织特工", "bio": "早期核心研究者决裂后的极端清除派行动人员。", "default_side": "right"},
        "security_guard": {"name": "校园门岗", "title": "受控门岗卫兵", "bio": "安全限幅器遭劫持的校外通道守卫。", "default_side": "right"},
    }
    merged: dict[str, Any] = {}
    for cid, spec in actors.items():
        merged[cid] = {
            "id": cid,
            "name": spec.get("name", cid),
            "title": spec.get("title", ""),
            "bio": spec.get("bio", ""),
            "default_side": "left" if cid == "ye_zhou" else "right",
            "builtin": True,
        }
    for cid, spec in extra.items():
        merged[cid] = {"id": cid, **spec, "builtin": True}
    return merged


def parse_stream_text(raw_text: str, actors: dict[str, Any]) -> list[dict[str, Any]]:
    """Parse stream script markdown lines into structured dialogue/directive objects."""
    name_to_id: dict[str, str] = {}
    for cid, spec in actors.items():
        name_to_id[spec["name"]] = cid
        name_to_id[cid] = cid
    name_to_id["灰区女特工"] = "rebel_operative_masked"
    name_to_id["alliance_operative"] = "rebel_operative_masked"

    lines_out: list[dict[str, Any]] = []
    active_cutscene = ""
    last_side_by_char: dict[str, str] = {}
    stage_slots: dict[str, str] = {"left": "", "right": ""}
    last_dialogue_idx: int | None = None
    active_choice: dict[str, Any] | None = None

    for raw in raw_text.splitlines():
        stripped = raw.strip()
        if not stripped:
            continue
        indent = len(raw) - len(raw.lstrip(" \t"))

        # Directive line: [指令: 参数]
        if stripped.startswith("[") and stripped.endswith("]"):
            inner = stripped[1:-1].strip()
            if ":" in inner or "：" in inner:
                sep = ":" if ":" in inner else "："
                kind, arg = [p.strip() for p in inner.split(sep, 1)]
            else:
                kind, arg = inner, ""
            if kind in ["过场", "cutscene"]:
                active_cutscene = "" if arg in ["关闭", "无", "none", "off", ""] else arg
                continue
            if kind in ["清场", "退场", "立绘退场", "clear", "exit"]:
                if arg in ["左", "left"]:
                    old_left = stage_slots.get("left", "")
                    stage_slots["left"] = ""
                    if old_left:
                        last_side_by_char.pop(old_left, None)
                elif arg in ["右", "right"]:
                    old_right = stage_slots.get("right", "")
                    stage_slots["right"] = ""
                    if old_right:
                        last_side_by_char.pop(old_right, None)
                elif arg and arg not in ["全部", "all", "both"]:
                    target_cid = name_to_id.get(arg, arg)
                    if stage_slots.get("left") in [target_cid, arg]:
                        stage_slots["left"] = ""
                    if stage_slots.get("right") in [target_cid, arg]:
                        stage_slots["right"] = ""
                    last_side_by_char.pop(target_cid, None)
                    last_side_by_char.pop(arg, None)
                else:
                    stage_slots["left"] = ""
                    stage_slots["right"] = ""
                    last_side_by_char.clear()
            lines_out.append({"type": "directive", "kind": kind, "arg": arg})
            active_choice = None
            continue

        # Choice line: ? ... or - "..." [...]
        if stripped.startswith("?") or stripped.startswith("- "):
            if stripped == "? 玩家选择:" or stripped == "? 玩家选择：":
                continue
            body = stripped[1:].strip() if stripped.startswith("?") else stripped[2:].strip()
            # Remove optional 选项A: prefix
            body = re.sub(r"^选项[A-Za-z0-9一二三]+\s*[:：]\s*", "", body)
            tags = re.findall(r"\[([^\]]+)\]", body)
            choice_text = re.sub(r"\s*\[[^\]]+\]", "", body).strip().strip('"').strip("“”")
            choice_obj: dict[str, Any] = {"text": choice_text}
            for tag in tags:
                favor_m = re.match(r"^(?:好感[:：]\s*|\+)([^+\s]+)\s*\+?\s*(\d+)$", tag.strip())
                if favor_m:
                    target_name = favor_m.group(1).strip()
                    choice_obj["favor_char"] = name_to_id.get(target_name, target_name)
                    choice_obj["favor_add"] = int(favor_m.group(2))
                elif tag.strip().startswith("标志"):
                    choice_obj["flag"] = tag.split(":", 1)[-1].split("：", 1)[-1].strip()
            if last_dialogue_idx is not None and 0 <= last_dialogue_idx < len(lines_out):
                target = lines_out[last_dialogue_idx]
                target.setdefault("choices", []).append(choice_obj)
                active_choice = choice_obj
            continue

        # Indented follow-up line under a choice
        if indent >= 2 and active_choice is not None:
            parsed = _parse_dialogue_line(stripped, name_to_id, actors, last_side_by_char, stage_slots, active_cutscene)
            active_choice.setdefault("follow_up", []).append(parsed)
            continue

        active_choice = None
        parsed = _parse_dialogue_line(stripped, name_to_id, actors, last_side_by_char, stage_slots, active_cutscene)
        lines_out.append(parsed)
        last_dialogue_idx = len(lines_out) - 1

    return lines_out


def _auto_assign_stage_side(
    char_key: str,
    last_side_by_char: dict[str, str],
    stage_slots: dict[str, str],
) -> str:
    if char_key and char_key in last_side_by_char:
        return last_side_by_char[char_key]
    if not stage_slots.get("left") and not stage_slots.get("right"):
        return "left"
    if stage_slots.get("left") and not stage_slots.get("right"):
        return "right"
    if not stage_slots.get("left") and stage_slots.get("right"):
        return "left"
    return "left" if char_key in ["ye_zhou", "叶舟"] else "right"


def _parse_dialogue_line(
    line: str,
    name_to_id: dict[str, str],
    actors: dict[str, Any],
    last_side_by_char: dict[str, str],
    stage_slots: dict[str, str],
    active_cutscene: str,
) -> dict[str, Any]:
    # Match Speaker(emo, side): text  OR  Speaker: text
    m = re.match(r"^([^:：\n(（]{1,24})(?:[(（]([^)）]*)[)）])?\s*[:：]\s*(.*)$", line)
    if not m:
        last_side_by_char.clear()
        stage_slots["left"] = ""
        stage_slots["right"] = ""
        entry: dict[str, Any] = {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "clear_stage": True, "text": line}
        if active_cutscene:
            entry["cutscene"] = active_cutscene
        return entry

    speaker = m.group(1).strip()
    meta_raw = (m.group(2) or "").strip()
    text = m.group(3).strip()

    if speaker in ["旁白", "叙述"]:
        last_side_by_char.clear()
        stage_slots["left"] = ""
        stage_slots["right"] = ""
        entry = {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "clear_stage": True, "text": text}
        if active_cutscene:
            entry["cutscene"] = active_cutscene
        return entry

    char_id = name_to_id.get(speaker, "")
    char_key = char_id or speaker
    emotion = "neutral"
    side = ""
    clear_stage = False
    clear_side = ""
    if meta_raw:
        parts = [p.strip() for p in re.split(r"[,，/|]", meta_raw) if p.strip()]
        for p in parts:
            if p in CN_TO_SIDE:
                side = CN_TO_SIDE[p]
            elif p in ["清场", "退场"]:
                clear_stage = True
            elif p in ["退左", "清左"]:
                clear_side = "left"
            elif p in ["退右", "清右"]:
                clear_side = "right"
            elif p in ["内心", "独白"]:
                speaker = f"{speaker}(内心)"
            elif p in CN_TO_EMOTION:
                emotion = CN_TO_EMOTION[p]
            elif p in EMOTION_TO_CN:
                emotion = p

    if clear_stage:
        last_side_by_char.clear()
        stage_slots["left"] = ""
        stage_slots["right"] = ""
    elif clear_side in ["left", "right"]:
        old_key = stage_slots.get(clear_side, "")
        stage_slots[clear_side] = ""
        if old_key:
            last_side_by_char.pop(old_key, None)

    if not side:
        side = _auto_assign_stage_side(char_key, last_side_by_char, stage_slots)

    prev_occupant = stage_slots.get(side, "")
    if prev_occupant and prev_occupant != char_key:
        last_side_by_char.pop(prev_occupant, None)
    stage_slots[side] = char_key
    if char_key:
        last_side_by_char[char_key] = side

    entry = {"speaker": speaker, "char": char_id, "side": side, "emotion": emotion, "text": text}
    if clear_stage:
        entry["clear_stage"] = True
    if clear_side:
        entry["clear_side"] = clear_side
    if active_cutscene:
        entry["cutscene"] = active_cutscene
    return entry


def lines_to_stream_text(lines: list[dict[str, Any]], actors: dict[str, Any]) -> str:
    """Serialize structured lines back into compact, human-friendly stream syntax."""
    out: list[str] = []
    cur_cutscene = ""
    last_side_by_char: dict[str, str] = {}
    stage_slots: dict[str, str] = {"left": "", "right": ""}
    for line in lines:
        if line.get("type") == "directive":
            kind = line.get("kind", "备注")
            arg = line.get("arg", "")
            if kind in ["清场", "退场", "立绘退场", "clear", "exit"]:
                if arg in ["左", "left"]:
                    old_left = stage_slots.get("left", "")
                    stage_slots["left"] = ""
                    if old_left:
                        last_side_by_char.pop(old_left, None)
                elif arg in ["右", "right"]:
                    old_right = stage_slots.get("right", "")
                    stage_slots["right"] = ""
                    if old_right:
                        last_side_by_char.pop(old_right, None)
                elif arg and arg not in ["全部", "all", "both"]:
                    last_side_by_char.pop(arg, None)
                    for s_key in ["left", "right"]:
                        if stage_slots.get(s_key) == arg:
                            stage_slots[s_key] = ""
                else:
                    stage_slots["left"] = ""
                    stage_slots["right"] = ""
                    last_side_by_char.clear()
            out.append(f"[{kind}: {arg}]" if arg != "" else f"[{kind}]")
            continue

        line_cs = str(line.get("cutscene", ""))
        if line_cs != cur_cutscene:
            out.append(f"[过场: {line_cs if line_cs else '关闭'}]")
            cur_cutscene = line_cs

        speaker = str(line.get("speaker", "旁白"))
        char_id = str(line.get("char", ""))
        emotion = str(line.get("emotion", "neutral") or "neutral")
        side = str(line.get("side", "left") or "left")
        text = str(line.get("text", ""))

        if speaker in ["旁白", "叙述"] and not char_id:
            last_side_by_char.clear()
            stage_slots["left"] = ""
            stage_slots["right"] = ""
            out.append(f"旁白: {text}")
        else:
            char_key = char_id or speaker.replace("(内心)", "")
            if line.get("clear_stage"):
                last_side_by_char.clear()
                stage_slots["left"] = ""
                stage_slots["right"] = ""
            elif line.get("clear_side") in ["left", "right"]:
                c_side = str(line["clear_side"])
                old_k = stage_slots.get(c_side, "")
                stage_slots[c_side] = ""
                if old_k:
                    last_side_by_char.pop(old_k, None)
            expected_side = _auto_assign_stage_side(char_key, last_side_by_char, stage_slots)
            emo_cn = EMOTION_TO_CN.get(emotion, emotion)
            meta_parts: list[str] = []
            if line.get("clear_stage"):
                meta_parts.append("清场")
            elif line.get("clear_side") == "left":
                meta_parts.append("退左")
            elif line.get("clear_side") == "right":
                meta_parts.append("退右")
            if emotion != "neutral":
                meta_parts.append(emo_cn)
            if side != expected_side:
                meta_parts.append(SIDE_TO_CN.get(side, side))
            prev_occ = stage_slots.get(side, "")
            if prev_occ and prev_occ != char_key:
                last_side_by_char.pop(prev_occ, None)
            stage_slots[side] = char_key
            if char_key:
                last_side_by_char[char_key] = side
            meta = f"({', '.join(meta_parts)})" if meta_parts else ""
            out.append(f"{speaker}{meta}: {text}")

        for choice in line.get("choices", []) or []:
            tags: list[str] = []
            if choice.get("favor_char") and choice.get("favor_add"):
                cname = actors.get(choice["favor_char"], {}).get("name", choice["favor_char"])
                tags.append(f"[好感: {cname}+{choice['favor_add']}]")
            if choice.get("flag"):
                tags.append(f"[标志: {choice['flag']}]")
            tag_str = (" " + " ".join(tags)) if tags else ""
            out.append(f"? {choice.get('text', '')}{tag_str}")
            for sub in choice.get("follow_up", []) or []:
                sub_txt = lines_to_stream_text([sub], actors)
                for sub_line in sub_txt.splitlines():
                    out.append(f"    {sub_line}")
    return "\n".join(out)


def _seed_oral_drafts(demo1: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        demo1,
        {
            "id": "prologue_02_sports_day",
            "node": "n_oral_02",
            "category": "prologue_oral_drafts",
            "target_type": "draft",
            "phase": "口述序章 · B",
            "title": "次日运动会与第四名的呼吸",
            "location": "school_gate",
            "bg": "school_gate",
            "bgm": "bgm_campus_daily",
            "default_cutscene": "",
            "next_action": "推进至道歉与亲近 (prologue_03_apology_confession)",
            "unlock_flags": [],
            "note": "口述 B 要点：1) 霸凌解围后的第二天举行运动会，叶舟从此开始主动注意黄秋枫；2) 独立视角切换至专业体育生——后程加速却怎么也甩不开身后的黄秋枫，直到冲线夺冠才发现她只拿第4名、却神色平稳一滴汗都没流；3) 体育生视角与主角本人所知信息保持分离。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "次日校园运动会，先写体育生视角径赛暗线，再切回叶舟在看台注意黄秋枫"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "霸凌事件发生后的第二天，阿瑞忒学院迎来了秋季运动会。"},
                {"speaker": "体育生", "char": "", "side": "right", "emotion": "neutral", "text": "（内心）最后一百米冲刺——怎么回事，无论怎么拉大步幅，那个转校生的脚步声都稳稳贴在身后半步？"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "他咬牙撞线夺冠后回头，才惊觉第四名冲线的黄秋枫连呼吸都没有乱。"},
            ],
        },
        {
            "id": "prologue_03_apology_confession",
            "node": "n_oral_03",
            "category": "prologue_oral_drafts",
            "target_type": "draft",
            "phase": "口述序章 · C1",
            "title": "道歉、相处与未答复的表白",
            "location": "club",
            "bg": "club",
            "bgm": "bgm_campus_daily",
            "default_cutscene": "",
            "next_action": "推进至旧公园约会 (prologue_04_old_park_kiss)",
            "unlock_flags": [],
            "note": "口述 C1 要点：1) 运动会后叶舟主动找黄秋枫道歉（为昨天逃跑的事）；2) 两人逐步亲近一起玩；3) 主角鼓起勇气表白，黄秋枫表示感谢并称「需要考虑一下」。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "补齐叶舟为逃跑道歉、一起相处以及表白后秋枫说『需要考虑一下』"},
                {"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "shy", "text": "那个……黄秋枫同学，前天在樱花路忽然跑掉的事，实在对不起。"},
                {"speaker": "黄秋枫", "char": "huang_qiufeng", "side": "right", "emotion": "happy", "text": "没关系的，叶舟同学。能再来和我说话，我就已经很开心了。"},
            ],
        },
        {
            "id": "prologue_04_old_park_kiss",
            "node": "n_oral_04",
            "category": "prologue_oral_drafts",
            "target_type": "draft",
            "phase": "口述序章 · C2",
            "title": "旧公园黄昏、突然亲吻与买水离场",
            "location": "old_park",
            "bg": "old_park",
            "bgm": "bgm_dusk_memory",
            "default_cutscene": "old_park_dusk",
            "next_action": "推进至买水返回目击袭击 (prologue_05_ambush_water_rescue)",
            "unlock_flags": [],
            "note": "口述 C2 要点（极重要）：1) 黄秋枫不想让人议论而约在几乎无人的旧公园；2) 叶舟自我贬低时，她突然极快地亲吻主角并鼓励肯定他（注意：不是正式接受表白，她没有主观爱意）；3) 提到表白答复时她改口说口渴疲倦请叶舟去买水（『毕竟你是男孩子，体能比我好』），不擅自写成预见袭击或刻意支开。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "主角自我贬低 -> 秋枫极快亲吻并鼓励 -> 刚要回表白又改口请主角去买水"},
                {"speaker": "黄秋枫", "char": "huang_qiufeng", "side": "right", "emotion": "neutral", "text": "因为不想给叶舟带来多余的麻烦，所以选了这个几乎不会有人来的旧公园。"},
                {"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "worried", "text": "其实我这种人……既胆小又没什么特别的长处，你根本没必要这么照顾我。"},
                {"speaker": "黄秋枫", "char": "huang_qiufeng", "side": "right", "emotion": "shy", "text": "不对哦。叶舟很好——比你自己以为的还要好。"},
            ],
        },
        {
            "id": "prologue_05_ambush_water_rescue",
            "node": "n_oral_05",
            "category": "prologue_oral_drafts",
            "target_type": "draft",
            "phase": "口述序章 · D/E",
            "title": "半小时后返回、泼水砸瓶与救人失败",
            "location": "old_park",
            "bg": "dusk_road",
            "bgm": "bgm_redmoon_overclock",
            "default_cutscene": "rebel_warning",
            "next_action": "推进至威胁与带走 (prologue_06_threat_abduction)",
            "unlock_flags": [],
            "note": "口述 D/E 要点（极重要）：1) 主角约半小时买水回来，仅目睹重武女性袭击者的最后一击（不可写成目睹全程）；2) 主角瞬间冷静：拧开一瓶水泼向对方眼睛 + 用手提塑料袋像投石一样把另一瓶水甩向眼睛 + 低头俯身铲抱起秋枫狼狈奔跑；3) 非正面战斗也非成功逃脱，不可借触感立即识破机械构造或赋予超人体能。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "拧水泼眼 -> 甩塑料袋投石掷第二瓶 -> 俯身铲抱秋枫踉跄逃跑"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "大约半小时后拎着两瓶水跑回旧公园时，林荫尽头落下了夸张重武器的最后一击。"},
                {"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "angry", "text": "……！（拧开右手水瓶盖，算准最短直线冲过去泼向那名女袭击者的眼睛）"},
            ],
        },
        {
            "id": "prologue_06_threat_abduction",
            "node": "n_oral_06",
            "category": "prologue_oral_drafts",
            "target_type": "draft",
            "phase": "口述序章 · F",
            "title": "二选一威胁与被敲晕带走",
            "location": "dusk_road",
            "bg": "dusk_road",
            "bgm": "bgm_dusk_memory",
            "default_cutscene": "red_moon_street",
            "next_action": "序章收束",
            "unlock_flags": [],
            "note": "口述 F 要点：主角最终跑不掉。女袭击者因目击现场给出二选一『跟她走，或者死』（目前只是威胁，不可认定必然杀害），最终叶舟被打晕带走；后续下落待定。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "未定：袭击者姓名/职务、为何不杀叶舟、醒来后安排均留白"},
                {"speaker": "灰区女特工", "char": "rebel_operative_masked", "side": "right", "emotion": "neutral", "text": "目击现场的普通学生……我给你两个选择：跟我走，或者现在死在这里。"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "后颈传来沉闷的一击，视野里的红月和旧公园一起沉入黑暗。"},
            ],
        },
    ]


def _seed_chapters_2_to_5() -> list[dict[str, Any]]:
    return [
        {
            "id": "ch2_nomos_draft",
            "node": "ch2_nomos",
            "category": "chapters_2_to_5",
            "target_type": "outline",
            "phase": "第二章 · 诺莫斯",
            "title": "巨树酒馆与主观天平（大纲与起稿区）",
            "location": "nomos_home_test",
            "bg": "nomos_home",
            "bgm": "bgm_campus_daily",
            "default_cutscene": "",
            "next_action": "待定",
            "unlock_flags": [],
            "note": "世界观总纲：诺莫斯法典学园（巨树内部中性木质小酒馆 Home / 法典庭院）。天秤座『天真者』持卡人（法典首席裁判官）将同情或越级挑战者统一定性为违纪并当场施罚，揭示规则只是持卡人偏见的投影。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "待主创正式撰写第二章台词；不擅自补全未知持卡人姓名与外观"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "穿过包裹着诺莫斯议事厅的巨大古树根系，木质小酒馆暖黄的灯光正映出法典庭院的轮廓。"},
                {"speaker": "姜梓", "char": "jiang_zi", "side": "right", "emotion": "neutral", "text": "诺莫斯的法典裁决以『主观确信』为尺——在庭院里发言和出牌，最好先摸清裁判官划下的边界。"},
            ],
        },
        {
            "id": "ch3_techne_draft",
            "node": "ch3_techne",
            "category": "chapters_2_to_5",
            "target_type": "outline",
            "phase": "第三章 · 忒克捏",
            "title": "黑白工坊与造物主的记忆切片（大纲与起稿区）",
            "location": "techne_home_test",
            "bg": "techne_home",
            "bgm": "bgm_dusk_memory",
            "default_cutscene": "",
            "next_action": "待定",
            "unlock_flags": [],
            "note": "世界观总纲：忒克捏极简黑白研究室（Home / 分子重构车间）。探索反叛组织特工绕过终端护盾的武器来源，涉及处女座『创造者』、摩羯座『智者』与巨蟹座『照顾者』的研发团队分裂往事。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "待主创正式撰写第三章台词；保留早期研究者分裂因果的悬念边界"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "黑白强对比的忒克捏制造室里只有极少量的红绿标识灯在跳动，像一张尚未显影完的工程蓝图。"},
            ],
        },
        {
            "id": "ch4_agora_draft",
            "node": "ch4_agora",
            "category": "chapters_2_to_5",
            "target_type": "outline",
            "phase": "第四章 · 阿戈拉",
            "title": "不夜城、空头支票与强劳宿舍（大纲与起稿区）",
            "location": "agora_home_test",
            "bg": "agora_home",
            "bgm": "bgm_dusk_memory",
            "default_cutscene": "",
            "next_action": "待定",
            "unlock_flags": [],
            "note": "世界观总纲：阿戈拉商业街与强制劳动集中营集体宿舍（Home）。涉及不对称契约与双子/凡人卡牌对抗破局，注意AGENTS约束：不实现劳动、博彩或自造未确认经济规则。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "待主创正式撰写第四章台词；遵守不自造未确认博彩/福利经济规则约束"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "阿戈拉的霓虹耀金招牌彻夜不熄，而一墙之隔的集体宿舍却只剩下冰冷的床沿与未签署完的契约单。"},
            ],
        },
        {
            "id": "ch5_finale_draft",
            "node": "ch5_finale",
            "category": "chapters_2_to_5",
            "target_type": "outline",
            "phase": "第五章 · 灰区与红月圣堂",
            "title": "伪人、人类与心之证明（终局大纲区）",
            "location": "region_failed_alliance_gateway_test",
            "bg": "battle_red_moon_lockdown",
            "bgm": "bgm_redmoon_overclock",
            "default_cutscene": "red_moon_finale",
            "next_action": "全案终局",
            "unlock_flags": [],
            "note": "世界观总纲：失败者同盟前线与 IGA 信仰教团（无 Home，多难度剧情探索区）。携集齐的 11 枚母卡与水瓶座『魔法师钥匙』向月球总控发起交互请求。结局逻辑保留由主创亲笔定夺。",
            "lines": [
                {"type": "directive", "kind": "备注", "arg": "终局保留全部未定抉择与结局走向，交由主创亲笔书写"},
                {"speaker": "旁白", "char": "", "side": "left", "emotion": "neutral", "text": "十一枚星座母卡在掌心次第亮起，水瓶座的魔法师钥匙正指向夜空中央那轮无声运转的红月。"},
            ],
        },
    ]


def build_bundle(preserve_existing: bool = True) -> dict[str, Any]:
    """Read live GDScript & docs/story files to assemble the unified Story Studio bundle."""
    p2_text = PHASE_TWO_GD.read_text(encoding="utf-8")
    places_text = CAMPUS_PLACES_GD.read_text(encoding="utf-8")
    life_text = CAMPUS_LIFE_GD.read_text(encoding="utf-8")
    routes_text = EXPLORATION_ROUTES_GD.read_text(encoding="utf-8")
    zodiac_text = ZODIAC_CATALOG_GD.read_text(encoding="utf-8")
    cutscene_text = PARALLAX_CUTSCENE_GD.read_text(encoding="utf-8")
    audio_text = AUDIO_MANAGER_GD.read_text(encoding="utf-8")
    combat_text = COMBAT_SCREEN_GD.read_text(encoding="utf-8")

    prologue_title = _extract_gd_string_const(p2_text, "PROLOGUE_TITLE")
    chapter_title = _extract_gd_string_const(p2_text, "CHAPTER_TITLE")
    actors = default_actors_lookup()
    flow_steps = _extract_gd_const(p2_text, "FLOW_STEPS")
    scripts = _extract_gd_const(p2_text, "SCRIPTS")

    # Background key mappings parsed from PhaseTwoContent.background_key
    bg_map: dict[str, str] = {
        "school_gate": "prologue_sports_field",
        "school_gate_after": "prologue_sports_field",
        "club_welcome": "prologue_club_meeting",
        "school_affairs": "library",
        "chat_jiang": "club",
        "chat_liu": "school_room",
        "chat_yang": "school_room",
        "campus_morning": "prologue_sakura_road",
        "after_school": "old_park",
        "yang_rescue": "dusk_road",
        "principal_confrontation": "battle_red_moon_lockdown",
        "find_yang": "dusk_road",
    }
    default_cutscene_map = {
        "after_school": "dusk_corridor",
        "yang_rescue": "rebel_warning",
        "principal_confrontation": "red_moon_street",
        "find_yang": "arena_spotlight",
    }
    default_bgm_map = {
        "after_school": "bgm_dusk_memory",
        "yang_rescue": "bgm_redmoon_overclock",
        "principal_confrontation": "bgm_redmoon_overclock",
        "find_yang": "bgm_dusk_memory",
    }

    main_scenes: list[dict[str, Any]] = []
    used_script_ids: set[str] = set()
    for step in flow_steps:
        node_id = str(step.get("node", ""))
        dlg_id = str(step.get("dialogue", ""))
        post_dlg_id = str(step.get("post_dialogue", ""))
        enemy_id = str(step.get("enemy", ""))
        enemies_list = step.get("enemies", [])
        scripted_defeat = str(step.get("scripted_defeat", ""))
        combat_done_flag = str(step.get("combat_done_flag", ""))
        title = str(step.get("title", node_id))
        phase = str(step.get("phase", "act1"))
        location = str(step.get("location", ""))
        briefing_flag = str(step.get("briefing_flag", ""))
        if dlg_id:
            used_script_ids.add(dlg_id)
            raw_lines = scripts.get(dlg_id, [])
            # Normalize side/emotion
            norm_lines = []
            for entry in raw_lines:
                d = dict(entry)
                if "emotion" not in d or not d["emotion"]:
                    d["emotion"] = "neutral"
                norm_lines.append(d)
            scene_obj: dict[str, Any] = {
                "id": dlg_id,
                "node": node_id,
                "category": "main_active",
                "target_type": "phase_two_flow",
                "phase": {"prologue": "序章", "act1": "第一章 · 日常与伏笔", "climax": "第一章 · 红月高潮"}.get(phase, phase),
                "phase_key": phase,
                "title": title,
                "location": location,
                "enemy": enemy_id,
                "briefing_flag": briefing_flag,
                "bg": bg_map.get(dlg_id, "dusk_road"),
                "bgm": default_bgm_map.get(dlg_id, "bgm_campus_daily"),
                "default_cutscene": default_cutscene_map.get(dlg_id, ""),
                "note": f"主线节点 {node_id}" + (f" · 完成后接战斗 {enemy_id}" if enemy_id else ""),
                "lines": norm_lines,
            }
            if post_dlg_id:
                scene_obj["post_dialogue"] = post_dlg_id
            if enemies_list:
                scene_obj["enemies"] = enemies_list
            if scripted_defeat:
                scene_obj["scripted_defeat"] = scripted_defeat
            if combat_done_flag:
                scene_obj["combat_done_flag"] = combat_done_flag
            main_scenes.append(scene_obj)
            if post_dlg_id:
                used_script_ids.add(post_dlg_id)
                post_raw = scripts.get(post_dlg_id, [])
                post_norm = []
                for entry in post_raw:
                    d = dict(entry)
                    if "emotion" not in d or not d["emotion"]:
                        d["emotion"] = "neutral"
                    post_norm.append(d)
                main_scenes.append({
                    "id": post_dlg_id,
                    "node": node_id,
                    "category": "main_active",
                    "target_type": "phase_two_post_dialogue",
                    "phase": {"prologue": "序章", "act1": "第一章 · 日常与伏笔", "climax": "第一章 · 红月高潮"}.get(phase, phase),
                    "phase_key": phase,
                    "title": f"{title} · 战后",
                    "location": location,
                    "enemy": "",
                    "briefing_flag": "",
                    "bg": bg_map.get(post_dlg_id, bg_map.get(dlg_id, "dusk_road")),
                    "bgm": default_bgm_map.get(post_dlg_id, "bgm_campus_daily"),
                    "default_cutscene": "",
                    "note": f"主线节点 {node_id} 战后剧情",
                    "lines": post_norm,
                })
        else:
            main_scenes.append({
                "id": node_id,
                "node": node_id,
                "category": "main_active",
                "target_type": "phase_two_battle_only",
                "phase": {"prologue": "序章", "act1": "第一章 · 日常与伏笔", "climax": "第一章 · 红月高潮"}.get(phase, phase),
                "phase_key": phase,
                "title": f"{title}（战斗节点）",
                "location": location,
                "enemy": enemy_id,
                "briefing_flag": briefing_flag,
                "bg": "battle_red_moon_lockdown",
                "bgm": "bgm_redmoon_overclock",
                "default_cutscene": "",
                "note": f"纯战斗节点 {node_id}（敌人: {enemy_id}）。若需增加战前剧情台词，可直接转为「战前对话+战斗」。",
                "lines": [],
            })

    # Campus NPCs & Chats
    npc_scenes: list[dict[str, Any]] = []
    chat_meta = {
        "chat_yang": ("社团闲聊 · 杨子英", "club", "club"),
        "chat_liu": ("社团闲聊 · 柳宇龙", "club", "club"),
        "chat_jiang": ("社团闲聊 · 姜梓", "club", "club"),
    }
    for sid, lines in scripts.items():
        if sid in used_script_ids:
            continue
        title, loc, bg = chat_meta.get(sid, (f"支线/额外剧情 · {sid}", "club", "school_room"))
        norm_lines = []
        for entry in lines:
            d = dict(entry)
            if not d.get("emotion"):
                d["emotion"] = "neutral"
            norm_lines.append(d)
        npc_scenes.append({
            "id": sid,
            "node": "",
            "category": "campus_npcs",
            "target_type": "phase_two_script",
            "phase": "社团闲聊",
            "title": title,
            "location": loc,
            "bg": bg,
            "bgm": "bgm_campus_daily",
            "default_cutscene": "",
            "note": "社团教室点击同伴「同学交流」触发（0 活动点消耗）。",
            "lines": norm_lines,
        })

    npc_scenes.extend(_parse_campus_npc_lines(life_text))

    snippets_raw = _extract_gd_const(places_text, "SNIPPETS")
    snippet_items = []
    for key, pairs in snippets_raw.items():
        snippet_items.append({
            "id": key,
            "lines": [
                {
                    "speaker": p[0],
                    "char": "tang_xiao_man" if p[0] == "唐小满" else ("ye_zhou" if p[0] == "我" else ""),
                    "side": "right" if p[0] == "唐小满" else "left",
                    "emotion": "neutral",
                    "text": p[1],
                }
                for p in pairs
            ],
        })
    npc_scenes.append({
        "id": "campus_snippets",
        "target_type": "campus_snippets",
        "category": "campus_npcs",
        "phase": "场景调查",
        "title": "各场景物件调查短句 (11处)",
        "location": "campus",
        "bg": "library",
        "bgm": "bgm_campus_daily",
        "default_cutscene": "",
        "note": "对应 CampusPlaces.SNIPPETS，玩家点击便笺、自动贩卖机、纸箱、海面等热点时弹出。",
        "snippets": snippet_items,
    })

    # Notes & Exploration Routes
    library_notes = _extract_gd_const(places_text, "LIBRARY_NOTES")
    route_variants = _parse_exploration_variants(routes_text)
    notes_and_routes = [
        {
            "id": "library_notes",
            "target_type": "library_notes",
            "category": "notes_and_routes",
            "phase": "图书馆收集",
            "title": "《阿瑞忒与红月风物纪要》(8篇)",
            "location": "library",
            "bg": "library",
            "bgm": "bgm_campus_daily",
            "note": "图书馆研习逐篇解锁，并在《放映档案室》可重读。",
            "articles": library_notes,
        },
        {
            "id": "exploration_notes",
            "target_type": "exploration_routes",
            "category": "notes_and_routes",
            "phase": "体育馆训练",
            "title": "模拟训练「拾到的留言」微故事 (8组)",
            "location": "gym",
            "bg": "gym",
            "bgm": "bgm_campus_daily",
            "note": "第 0 层固定为第 1 组路牌指引，第 1 层起随机轮换其余 7 组校园微故事。",
            "variants": [
                {
                    "index": idx,
                    "title": "第 0 层固定指引" if idx == 0 else f"随机校园微故事 #{idx}",
                    "lines": [
                        {
                            "speaker": l.get("speaker", "叶舟"),
                            "char": l.get("char", "ye_zhou"),
                            "side": l.get("side", "left"),
                            "emotion": l.get("emotion", "neutral"),
                            "text": l.get("text", ""),
                        }
                        for l in variant
                    ],
                }
                for idx, variant in enumerate(route_variants)
            ],
        },
    ]

    # Drafts and outlines (preserve existing user drafts if bundle already exists)
    oral_drafts = _seed_oral_drafts(_parse_oral_prologue_demo1())
    chapters_2_5 = _seed_chapters_2_to_5()
    custom_actors: dict[str, Any] = {}

    if preserve_existing and BUNDLE_JSON.exists():
        try:
            prev = json.loads(BUNDLE_JSON.read_text(encoding="utf-8"))
            if prev.get("categories", {}).get("prologue_oral_drafts"):
                oral_drafts = prev["categories"]["prologue_oral_drafts"]
            if prev.get("categories", {}).get("chapters_2_to_5"):
                chapters_2_5 = prev["categories"]["chapters_2_to_5"]
            for cid, spec in prev.get("actors", {}).items():
                if not spec.get("builtin"):
                    custom_actors[cid] = spec
            # Preserve director remarks/non-engine directives on main_active if scene lines match
            prev_main = {s["id"]: s for s in prev.get("categories", {}).get("main_active", [])}
            for sc in main_scenes:
                prev_sc = prev_main.get(sc["id"])
                if prev_sc:
                    if prev_sc.get("bg"):
                        sc["bg"] = prev_sc["bg"]
                    if prev_sc.get("bgm"):
                        sc["bgm"] = prev_sc["bgm"]
                    if prev_sc.get("note"):
                        sc["note"] = prev_sc["note"]
        except Exception:
            pass

    all_actors = {**actors, **custom_actors}
    presets = _parse_cutscene_presets(cutscene_text)
    sfx_list = _parse_sfx_keys(audio_text)
    enemies = _parse_enemies(combat_text)
    zodiac_order = _extract_gd_const(zodiac_text, "ORDER")
    zodiac_entries = _extract_gd_const(zodiac_text, "ENTRIES")
    zodiac_cards = [zodiac_entries[zid] for zid in zodiac_order if zid in zodiac_entries]

    bundle = {
        "version": 1,
        "exported_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "project": "IGA (Inorganic General Alien)",
        "titles": {
            "prologue_title": prologue_title,
            "chapter_title": chapter_title,
        },
        "actors": all_actors,
        "categories": {
            "main_active": main_scenes,
            "prologue_oral_drafts": oral_drafts,
            "chapters_2_to_5": chapters_2_5,
            "campus_npcs": npc_scenes,
            "notes_and_routes": notes_and_routes,
        },
        "world_reference": {
            "zodiac_cards": zodiac_cards,
        },
        "catalogs": {
            "backgrounds": BG_CHOICES,
            "bgm": BGM_CHOICES,
            "sfx": sfx_list,
            "cutscenes": [{"id": k, "label": v} for k, v in CUTSCENE_LABELS.items()],
            "enemies": enemies,
            "emotions": [{"id": k, "label": v} for k, v in EMOTION_TO_CN.items() if k != "concerned"],
        },
        "assets": _build_assets_manifest(all_actors, enemies, presets),
    }
    return bundle


def export_web_data(bundle: dict[str, Any]) -> None:
    """Write story_bundle.json and story_data.js (for offline file:// access)."""
    STUDIO_DIR.mkdir(parents=True, exist_ok=True)
    json_str = json.dumps(bundle, ensure_ascii=False, indent=2)
    BUNDLE_JSON.write_text(json_str + "\n", encoding="utf-8")
    BUNDLE_JS.write_text(
        "// Auto-generated by tools/story_studio/sync_story.py\n"
        f"window.IGA_STORY_BUNDLE = {json_str};\n",
        encoding="utf-8",
    )


def _scene_markdown_block(scene: dict[str, Any], actors: dict[str, Any]) -> str:
    header = [
        "---",
        f"剧情ID: {scene['id']}",
        f"类型: {scene.get('target_type', 'scene')}",
        f"所属阶段: {scene.get('phase', '')}",
        f"幕名: {scene.get('title', '')}",
        f"触发地点: {scene.get('location', '') or '自动推进'}",
        f"默认背景: {scene.get('bg', '')}",
        f"默认BGM: {scene.get('bgm', '')}",
        f"默认过场: {scene.get('default_cutscene', '') or '无'}",
        f"后续敌人: {scene.get('enemy', '') or '无'}",
        f"说明备注: {scene.get('note', '')}",
        "---",
    ]
    body = lines_to_stream_text(scene.get("lines", []), actors)
    return "\n".join(header) + "\n\n" + (body + "\n" if body else "_（本幕暂无台词）_\n")


def export_markdown_scripts(bundle: dict[str, Any], out_dir: Path = SCRIPTS_DOC_DIR) -> list[Path]:
    """Export all story categories into human-readable stream Markdown files under docs/story/scripts/."""
    out_dir.mkdir(parents=True, exist_ok=True)
    actors = bundle["actors"]
    written: list[Path] = []

    # 1. Main active
    p1 = out_dir / "01_现行主线_序章与第一章.md"
    parts1 = [
        "# 01 · 现行游戏实装主线（序章与第一章）",
        "",
        f"> **序章标题**：{bundle['titles']['prologue_title']}",
        f"> **第一章标题**：{bundle['titles']['chapter_title']}",
        f"> **同步时间**：{bundle['exported_at']}",
        "",
    ]
    for sc in bundle["categories"]["main_active"]:
        parts1.append(f"## {sc.get('phase', '')} ｜ {sc.get('title', sc['id'])}")
        parts1.append("")
        parts1.append(_scene_markdown_block(sc, actors))
    p1.write_text("\n".join(parts1), encoding="utf-8")
    written.append(p1)

    # 2. Oral prologue drafts
    p2 = out_dir / "02_主创口述序章原案草稿.md"
    parts2 = [
        "# 02 · 主创口述序章原案与重写草稿区（2026-10-28 基准）",
        "",
        "> 本文件对应工作台「口述序章草稿」分区，写完可在工作台一键替换/合入现行主线。",
        "",
    ]
    for sc in bundle["categories"]["prologue_oral_drafts"]:
        parts2.append(f"## {sc.get('phase', '')} ｜ {sc.get('title', sc['id'])}")
        parts2.append("")
        parts2.append(_scene_markdown_block(sc, actors))
    p2.write_text("\n".join(parts2), encoding="utf-8")
    written.append(p2)

    # 3. Chapters 2 to 5
    p3 = out_dir / "03_第二至五章巡回大纲与草稿.md"
    parts3 = [
        "# 03 · 第二至五章六地区巡回大纲与草稿槽",
        "",
        "> 遵循 2026-11-14 全案世界观重构设计书，第 2–5 章保留待定创作边界。",
        "",
    ]
    for sc in bundle["categories"]["chapters_2_to_5"]:
        parts3.append(f"## {sc.get('phase', '')} ｜ {sc.get('title', sc['id'])}")
        parts3.append("")
        parts3.append(_scene_markdown_block(sc, actors))
    p3.write_text("\n".join(parts3), encoding="utf-8")
    written.append(p3)

    # 4. Campus NPCs & snippets
    p4 = out_dir / "04_校园驻场NPC与场景互动.md"
    parts4 = ["# 04 · 社团同伴闲聊、校园驻场 NPC 对白与场景热点", ""]
    for sc in bundle["categories"]["campus_npcs"]:
        parts4.append(f"## {sc.get('title', sc['id'])}")
        parts4.append("")
        if sc.get("target_type") == "campus_life_npc":
            for cond in sc.get("conditions", []):
                parts4.append(f"### [条件: {cond.get('condition_label', cond.get('condition_key', ''))}]")
                parts4.append(lines_to_stream_text(cond.get("lines", []), actors))
                parts4.append("")
        elif sc.get("target_type") == "campus_snippets":
            for sn in sc.get("snippets", []):
                parts4.append(f"### [{sn['id']}]")
                parts4.append(lines_to_stream_text(sn.get("lines", []), actors))
                parts4.append("")
        else:
            parts4.append(_scene_markdown_block(sc, actors))
    p4.write_text("\n".join(parts4), encoding="utf-8")
    written.append(p4)

    # 5. Library notes & exploration routes
    p5 = out_dir / "05_风物纪要与训练路线留言.md"
    parts5 = ["# 05 · 《阿瑞忒风物纪要》与体育馆模拟训练「拾到的留言」", ""]
    for item in bundle["categories"]["notes_and_routes"]:
        if item.get("target_type") == "library_notes":
            parts5.append("## 《阿瑞忒与红月风物纪要》")
            parts5.append("")
            for art in item.get("articles", []):
                parts5.append(f"### {art['title']} (`{art['id']}`)")
                parts5.append(art["body"])
                parts5.append("")
        elif item.get("target_type") == "exploration_routes":
            parts5.append("## 体育馆训练路线「拾到的留言」")
            parts5.append("")
            for var in item.get("variants", []):
                parts5.append(f"### {var['title']}")
                parts5.append(lines_to_stream_text(var.get("lines", []), actors))
                parts5.append("")
    p5.write_text("\n".join(parts5), encoding="utf-8")
    written.append(p5)

    return written


def _gd_line_dict(line: dict[str, Any]) -> str:
    """Format a dialogue line into compact single-line GDScript dictionary literal."""
    ordered: dict[str, Any] = {
        "speaker": str(line.get("speaker", "旁白")),
        "char": str(line.get("char", "")),
        "side": str(line.get("side", "left")),
    }
    emo = str(line.get("emotion", "neutral") or "neutral")
    if emo != "neutral" or ordered["char"] in ["ye_zhou", "huang_qiufeng", "yang_zi_ying", "liu_yu_long", "jiang_zi", "lin_zhi_xia", "tang_xiao_man", "thug_grunt", "thug_boss"]:
        ordered["emotion"] = emo
    if line.get("clear_stage") or ordered["char"] == "":
        ordered["clear_stage"] = True
    elif line.get("clear_side") in ["left", "right"]:
        ordered["clear_side"] = str(line["clear_side"])
    if line.get("cutscene"):
        ordered["cutscene"] = str(line["cutscene"])
    ordered["text"] = str(line.get("text", ""))
    if line.get("choices"):
        clean_choices = []
        for ch in line["choices"]:
            c_dict: dict[str, Any] = {"text": str(ch.get("text", ""))}
            if ch.get("favor_char"):
                c_dict["favor_char"] = str(ch["favor_char"])
            if ch.get("favor_add") is not None:
                c_dict["favor_add"] = int(ch["favor_add"])
            clean_choices.append(c_dict)
        ordered["choices"] = clean_choices
    return json.dumps(ordered, ensure_ascii=False, separators=(",", ":"))


def _flatten_engine_dialogue(lines: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Filter out non-engine remark directives and flatten follow-up choices safely."""
    out: list[dict[str, Any]] = []
    pending_clear_stage = False
    pending_clear_side = ""
    for line in lines:
        if line.get("type") == "directive":
            kind = str(line.get("kind", "")).strip()
            arg = str(line.get("arg", "")).strip()
            if kind in ["清场", "退场", "立绘退场", "clear", "exit"]:
                if arg in ["左", "left"]:
                    pending_clear_side = "left"
                elif arg in ["右", "right"]:
                    pending_clear_side = "right"
                else:
                    pending_clear_stage = True
                    pending_clear_side = ""
            continue
        copy_line = {k: v for k, v in line.items() if k != "type"}
        if pending_clear_stage:
            copy_line["clear_stage"] = True
            pending_clear_stage = False
            pending_clear_side = ""
        elif pending_clear_side:
            copy_line["clear_side"] = pending_clear_side
            pending_clear_side = ""
        follow_ups: list[dict[str, Any]] = []
        if copy_line.get("choices"):
            clean_choices = []
            for ch in copy_line["choices"]:
                c_clean = {k: v for k, v in ch.items() if k != "follow_up"}
                clean_choices.append(c_clean)
                for fu in ch.get("follow_up", []) or []:
                    if fu.get("type") != "directive":
                        follow_ups.append(fu)
            copy_line["choices"] = clean_choices
        out.append(copy_line)
        # Preserve optional follow-up response lines only if authored
        out.extend(follow_ups)
    return out


def _replace_const_block(text: str, const_name: str, replacement_block: str) -> str:
    m = re.search(rf"^const\s+{re.escape(const_name)}(?:\s*:\s*[^=]*)?\s*=\s*([{{\[])", text, re.MULTILINE)
    if not m:
        raise ValueError(f"Const {const_name} not found")
    _, end_idx = _extract_balanced(text, m.start(1))
    return text[: m.start(1)] + replacement_block + text[end_idx:]


def _write_preserving_newlines(path: Path, text: str, had_crlf: bool) -> None:
    normalized = text.replace("\r\n", "\n")
    if had_crlf:
        normalized = normalized.replace("\n", "\r\n")
    path.write_bytes(normalized.encode("utf-8"))


def apply_bundle_to_gdscript(bundle: dict[str, Any]) -> dict[str, Any]:
    """Write edited story bundle cleanly back into Godot .gd source files."""
    summary: dict[str, Any] = {"updated_files": []}

    # 1. scripts/global/phase_two_content.gd (STRICT TAB INDENTATION)
    p2_raw = PHASE_TWO_GD.read_bytes()
    p2_crlf = b"\r\n" in p2_raw
    p2_text = p2_raw.decode("utf-8").replace("\r\n", "\n")
    p2_text = re.sub(
        r'^const\s+PROLOGUE_TITLE:\s*String\s*=\s*".*"$',
        f'const PROLOGUE_TITLE: String = {json.dumps(bundle["titles"]["prologue_title"], ensure_ascii=False)}',
        p2_text,
        flags=re.MULTILINE,
    )
    p2_text = re.sub(
        r'^const\s+CHAPTER_TITLE:\s*String\s*=\s*".*"$',
        f'const CHAPTER_TITLE: String = {json.dumps(bundle["titles"]["chapter_title"], ensure_ascii=False)}',
        p2_text,
        flags=re.MULTILINE,
    )

    # Rebuild ACTORS (preserve core fields name/title/bio)
    actors_lines = ["{"]
    actor_items = [
        (cid, spec)
        for cid, spec in bundle["actors"].items()
        if cid not in ["rebel_operative_masked", "security_guard"]
    ]
    for idx, (cid, spec) in enumerate(actor_items):
        comma = "," if idx < len(actor_items) - 1 else ""
        obj = {"name": spec.get("name", cid), "title": spec.get("title", ""), "bio": spec.get("bio", "")}
        actors_lines.append(f'\t{json.dumps(cid, ensure_ascii=False)}: {json.dumps(obj, ensure_ascii=False, separators=(",", ":"))}{comma}')
    actors_lines.append("}")
    p2_text = _replace_const_block(p2_text, "ACTORS", "\n".join(actors_lines))

    # Rebuild FLOW_STEPS & SCRIPTS
    main_scenes = bundle["categories"]["main_active"]
    scripts_dict: dict[str, list[dict[str, Any]]] = {}
    bg_to_phase2 = {item["id"]: item["phase2_key"] for item in BG_CHOICES}
    bg_groups: dict[str, list[str]] = {
        "prologue_sakura_road": ["prologue_intro", "chapter_1_intro"],
        "prologue_sports_field": [],
        "battle_sports_field": [],
        "prologue_club_meeting": [],
        "morning_road": [],
        "school_gate": [],
        "school_room": [],
        "dusk_road": [],
        "battle_campus": [],
        "battle_red_moon_lockdown": [],
    }

    flow_items: list[dict[str, Any]] = []
    for sc in main_scenes:
        if sc.get("target_type") == "phase_two_post_dialogue":
            scripts_dict[sc["id"]] = _flatten_engine_dialogue(sc.get("lines", []))
            bg_key = bg_to_phase2.get(sc.get("bg", "dusk_road"), "dusk_road")
            if bg_key != "dusk_road" and sc["id"] not in bg_groups.get(bg_key, []):
                bg_groups.setdefault(bg_key, []).append(sc["id"])
            continue
        step_obj: dict[str, Any] = {"node": sc.get("node") or sc["id"]}
        if sc.get("target_type") != "phase_two_battle_only":
            step_obj["dialogue"] = sc["id"]
            scripts_dict[sc["id"]] = _flatten_engine_dialogue(sc.get("lines", []))
            bg_key = bg_to_phase2.get(sc.get("bg", "dusk_road"), "dusk_road")
            if bg_key != "dusk_road" and sc["id"] not in bg_groups.get(bg_key, []):
                bg_groups.setdefault(bg_key, []).append(sc["id"])
        if sc.get("post_dialogue"):
            step_obj["post_dialogue"] = sc["post_dialogue"]
        if sc.get("enemy"):
            step_obj["enemy"] = sc["enemy"]
        if sc.get("enemies"):
            step_obj["enemies"] = sc["enemies"]
        if sc.get("scripted_defeat"):
            step_obj["scripted_defeat"] = sc["scripted_defeat"]
        if sc.get("briefing_flag"):
            step_obj["briefing_flag"] = sc["briefing_flag"]
        if sc.get("combat_done_flag"):
            step_obj["combat_done_flag"] = sc["combat_done_flag"]
        step_obj["title"] = sc.get("title", "").replace("（战斗节点）", "")
        step_obj["phase"] = sc.get("phase_key", "act1")
        if sc.get("location"):
            step_obj["location"] = sc["location"]
        flow_items.append(step_obj)

    flow_lines = ["["]
    for idx, step_obj in enumerate(flow_items):
        comma = "," if idx < len(flow_items) - 1 else ""
        flow_lines.append(f'\t{json.dumps(step_obj, ensure_ascii=False, separators=(",", ":"))}{comma}')
    flow_lines.append("]")
    p2_text = _replace_const_block(p2_text, "FLOW_STEPS", "\n".join(flow_lines))

    # Add phase_two_script scenes (like chat_yang, chat_liu, chat_jiang, and any user-added side scripts)
    for sc in bundle["categories"]["campus_npcs"]:
        if sc.get("target_type") == "phase_two_script":
            scripts_dict[sc["id"]] = _flatten_engine_dialogue(sc.get("lines", []))
            bg_key = bg_to_phase2.get(sc.get("bg", "school_room"), "school_room")
            if bg_key != "dusk_road" and sc["id"] not in bg_groups.get(bg_key, []):
                bg_groups.setdefault(bg_key, []).append(sc["id"])

    script_lines = ["{"]
    script_keys = list(scripts_dict.keys())
    for s_idx, sid in enumerate(script_keys):
        s_comma = "," if s_idx < len(script_keys) - 1 else ""
        script_lines.append(f'\t{json.dumps(sid, ensure_ascii=False)}: [')
        dlg_rows = scripts_dict[sid]
        for l_idx, row in enumerate(dlg_rows):
            l_comma = "," if l_idx < len(dlg_rows) - 1 else ""
            script_lines.append(f"\t\t{_gd_line_dict(row)}{l_comma}")
        script_lines.append(f"\t]{s_comma}")
    script_lines.append("}")
    p2_text = _replace_const_block(p2_text, "SCRIPTS", "\n".join(script_lines))

    # Update background_key(dialogue_id) cleanly with Tab indent
    bg_fn_lines = ["static func background_key(dialogue_id: String) -> String:", "\tmatch dialogue_id:"]
    for bg_key in ["prologue_sakura_road", "prologue_sports_field", "battle_sports_field", "prologue_club_meeting", "school_gate", "school_room", "morning_road", "battle_campus", "battle_red_moon_lockdown"]:
        ids = bg_groups.get(bg_key, [])
        if ids:
            joined = ", ".join(json.dumps(x, ensure_ascii=False) for x in ids)
            bg_fn_lines.append(f'\t\t{joined}: return "{bg_key}"')
    bg_fn_lines.append('\treturn "dusk_road"')
    p2_text = re.sub(
        r"static func background_key\(dialogue_id: String\) -> String:.*?\n\treturn \"dusk_road\"",
        "\n".join(bg_fn_lines),
        p2_text,
        flags=re.DOTALL,
    )
    _write_preserving_newlines(PHASE_TWO_GD, p2_text, p2_crlf)
    summary["updated_files"].append("scripts/global/phase_two_content.gd")

    # 2. scripts/campus/campus_places.gd (STRICT SINGLE-SPACE INDENTATION)
    places_raw = CAMPUS_PLACES_GD.read_bytes()
    places_crlf = b"\r\n" in places_raw
    places_text = places_raw.decode("utf-8").replace("\r\n", "\n")
    notes_item = next((x for x in bundle["categories"]["notes_and_routes"] if x.get("id") == "library_notes"), None)
    if notes_item is not None:
        lib_lines = ["["]
        articles = notes_item.get("articles", [])
        for idx, art in enumerate(articles):
            comma = "," if idx < len(articles) - 1 else ""
            obj = {"id": art["id"], "title": art["title"], "body": art["body"]}
            lib_lines.append(f' {json.dumps(obj, ensure_ascii=False, separators=(",", ":"))}{comma}')
        lib_lines.append("]")
        places_text = _replace_const_block(places_text, "LIBRARY_NOTES", "\n".join(lib_lines))

    snippets_item = next((x for x in bundle["categories"]["campus_npcs"] if x.get("id") == "campus_snippets"), None)
    if snippets_item is not None:
        sn_lines = ["{"]
        sn_list = snippets_item.get("snippets", [])
        for idx, sn in enumerate(sn_list):
            comma = "," if idx < len(sn_list) - 1 else ""
            pairs = [[l.get("speaker", "我"), l.get("text", "")] for l in sn.get("lines", []) if l.get("type") != "directive"]
            sn_lines.append(f' {json.dumps(sn["id"], ensure_ascii=False)}:{json.dumps(pairs, ensure_ascii=False, separators=(",", ":"))}{comma}')
        sn_lines.append("}")
        places_text = _replace_const_block(places_text, "SNIPPETS", "\n".join(sn_lines))

    _write_preserving_newlines(CAMPUS_PLACES_GD, places_text, places_crlf)
    summary["updated_files"].append("scripts/campus/campus_places.gd")

    # 3. scripts/global/school_exploration_routes.gd (STRICT TAB INDENTATION)
    routes_raw = EXPLORATION_ROUTES_GD.read_bytes()
    routes_crlf = b"\r\n" in routes_raw
    routes_text = routes_raw.decode("utf-8").replace("\r\n", "\n")
    exp_item = next((x for x in bundle["categories"]["notes_and_routes"] if x.get("id") == "exploration_notes"), None)
    if exp_item is not None:
        m = re.search(r"(static func dialogue_lines\(.*?\).*?\n\tvar variants:\s*Array\[Array\]\s*=\s*)(\[)", routes_text, re.DOTALL)
        if m:
            _, end_idx = _extract_balanced(routes_text, m.start(2))
            v_lines = ["["]
            variants = exp_item.get("variants", [])
            for v_idx, var in enumerate(variants):
                v_comma = "," if v_idx < len(variants) - 1 else ""
                v_lines.append("\t\t[")
                v_rows = [l for l in var.get("lines", []) if l.get("type") != "directive"]
                for l_idx, row in enumerate(v_rows):
                    l_comma = "," if l_idx < len(v_rows) - 1 else ""
                    v_lines.append(f"\t\t\t{_gd_line_dict(row)}{l_comma}")
                v_lines.append(f"\t\t]{v_comma}")
            v_lines.append("\t]")
            routes_text = routes_text[: m.start(2)] + "\n".join(v_lines) + routes_text[end_idx:]
            _write_preserving_newlines(EXPLORATION_ROUTES_GD, routes_text, routes_crlf)
            summary["updated_files"].append("scripts/global/school_exploration_routes.gd")

    # 4. scripts/campus/campus_life.gd npc_lines (STRICT SINGLE-SPACE INDENTATION)
    npc_life_scenes = [x for x in bundle["categories"]["campus_npcs"] if x.get("target_type") == "campus_life_npc"]
    if npc_life_scenes:
        life_raw = CAMPUS_LIFE_GD.read_bytes()
        life_crlf = b"\r\n" in life_raw
        life_text = life_raw.decode("utf-8").replace("\r\n", "\n")
        m_npc = re.search(r"func npc_lines\(npc_id: String\) -> Array:.*?\nfunc _record_activity", life_text, re.DOTALL)
        if m_npc:
            def to_pairs_json(lines: list[dict[str, Any]]) -> str:
                pairs = [[l.get("speaker", "我"), l.get("text", "")] for l in lines if l.get("type") != "directive"]
                return json.dumps(pairs, ensure_ascii=False, separators=(",", ":"))

            fn_lines = [
                "func npc_lines(npc_id: String) -> Array:",
                ' if not CampusPlaces.NPCS.has(npc_id): return []',
                ' if not DayCycle.pending_event().is_empty(): return [["我",DayCycle.block_reason()]]',
                " var data := snapshot()",
                ' var count := int(data["npc_talks"].get(npc_id,0))',
                ' data["npc_talks"][npc_id] = mini(9999,count+1)',
                " _commit(data)",
                " match npc_id:",
            ]
            for nsc in npc_life_scenes:
                nid = nsc["npc_id"]
                conds = nsc.get("conditions", [])
                fn_lines.append(f'  "{nid}":')
                if len(conds) >= 2 and conds[0].get("condition_key") == "first_talk":
                    fn_lines.append("   if count == 0:")
                    fn_lines.append(f"    return {to_pairs_json(conds[0]['lines'])}")
                    fn_lines.append(f"   return {to_pairs_json(conds[1]['lines'])}")
                elif len(conds) >= 2 and conds[0].get("condition_key") == "post_qualifier":
                    fn_lines.append('   if bool(GameState.story_flags.get("arete_qualifier_completed", false)):')
                    fn_lines.append(f"    return {to_pairs_json(conds[0]['lines'])}")
                    fn_lines.append(f"   return {to_pairs_json(conds[1]['lines'])}")
                elif conds:
                    fn_lines.append(f"   return {to_pairs_json(conds[0]['lines'])}")
                else:
                    fn_lines.append("   return []")
            fn_lines.append(" return []")
            fn_lines.append("")
            fn_lines.append("func _record_activity")
            life_text = life_text[: m_npc.start()] + "\n".join(fn_lines) + life_text[m_npc.end() :]
            _write_preserving_newlines(CAMPUS_LIFE_GD, life_text, life_crlf)
            summary["updated_files"].append("scripts/campus/campus_life.gd")

    return summary


def verify_gd_indentation() -> list[str]:
    """Same indentation preflight check used by tools/run_godot_tests.py."""
    errors: list[str] = []
    for folder in ["scripts", "tools/tests"]:
        for file in (ROOT / folder).rglob("*.gd"):
            styles: set[str] = set()
            multiline = None
            for line_no, line in enumerate(file.read_text(encoding="utf-8-sig").splitlines(), 1):
                if multiline:
                    if line.count(multiline) % 2:
                        multiline = None
                    continue
                stripped = line.lstrip()
                prefix = line[: len(line) - len(stripped)]
                if stripped and not stripped.startswith("#") and prefix:
                    styles.add("tabs" if prefix.startswith("\t") else "spaces")
                    if "\t" in prefix and " " in prefix:
                        errors.append(f"{file.relative_to(ROOT)}:{line_no}: mixed tab/space indentation")
                for delimiter in ['"""', "'''"]:
                    if line.count(delimiter) % 2:
                        multiline = delimiter
                        break
            if len(styles) > 1:
                errors.append(f"{file.relative_to(ROOT)}: indentation style changes within the file")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--export", action="store_true", help="Export project story into JSON/JS/Markdown")
    parser.add_argument("--fresh", action="store_true", help="Ignore existing story_bundle.json drafts and rebuild fresh")
    parser.add_argument("--apply", action="store_true", help="Apply story_bundle.json back into .gd files and .md docs")
    parser.add_argument("--verify", action="store_true", help="Verify GDScript indentation and bundle integrity")
    args = parser.parse_args()

    if not args.export and not args.apply and not args.verify:
        args.export = True

    if args.export:
        bundle = build_bundle(preserve_existing=not args.fresh)
        export_web_data(bundle)
        md_files = export_markdown_scripts(bundle)
        print(json.dumps({
            "action": "export",
            "main_active_count": len(bundle["categories"]["main_active"]),
            "oral_drafts_count": len(bundle["categories"]["prologue_oral_drafts"]),
            "chapters_2_5_count": len(bundle["categories"]["chapters_2_to_5"]),
            "campus_npcs_count": len(bundle["categories"]["campus_npcs"]),
            "markdown_files": [str(p.relative_to(ROOT)) for p in md_files],
        }, ensure_ascii=False))

    if args.apply:
        if not BUNDLE_JSON.exists():
            bundle = build_bundle(preserve_existing=False)
        else:
            bundle = json.loads(BUNDLE_JSON.read_text(encoding="utf-8"))
        bundle["exported_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        export_web_data(bundle)
        export_markdown_scripts(bundle)
        summary = apply_bundle_to_gdscript(bundle)
        print(json.dumps({"action": "apply", **summary}, ensure_ascii=False))

    if args.verify:
        indent_errors = verify_gd_indentation()
        if indent_errors:
            print(json.dumps({"verify": False, "indentation_errors": indent_errors}, ensure_ascii=False))
            return 1
        print(json.dumps({"verify": True, "indentation_errors": []}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
