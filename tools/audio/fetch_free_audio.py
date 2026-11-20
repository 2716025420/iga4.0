"""Download verified open-licensed BGM (PeriTune CC-BY 4.0) and SFX (Kenney CC0) into assets/audio/."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BGM_DIR = ROOT / "assets" / "audio" / "bgm"
SFX_DIR = ROOT / "assets" / "audio" / "sfx"

BGM_TRACKS = [
    {
        "stem": "bgm_title_serene",
        "ext": ".mp3",
        "source_title": "Harbor Morning (467)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/PeriTune_Harbor_Morning.mp3",
        "scene_use": "标题页、加载过渡与设置电台",
    },
    {
        "stem": "bgm_campus_daily",
        "ext": ".mp3",
        "source_title": "Sunlit Café (441)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/Peritune_Sunlit_Cafe.mp3",
        "scene_use": "社团教室 Home、校园地图、图书馆、天台、宿舍、沿海公路、海滩与工坊图鉴",
    },
    {
        "stem": "bgm_shop_breeze",
        "ext": ".mp3",
        "source_title": "Cafe Seaside (401)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/PerituneMaterial_Cafe_Seaside.mp3",
        "scene_use": "校园商店与商店柜台分栏界面",
    },
    {
        "stem": "bgm_dusk_memory",
        "ext": ".mp3",
        "source_title": "Rainwalk (471)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/PeriTune_Rainwalk.mp3",
        "scene_use": "黄昏旧公园约会、黄秋枫结晶独白、红月夜日常、放映档案回忆",
    },
    {
        "stem": "bgm_duel_practice",
        "ext": ".mp3",
        "source_title": "Swift Strike (439)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/Peritune_Swift_Strike.mp3",
        "scene_use": "柳宇龙校门切磋、体育馆模拟训练与阿瑞忒代表选拔赛",
    },
    {
        "stem": "bgm_redmoon_overclock",
        "ext": ".mp3",
        "source_title": "Relentless (469)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/PeriTune_Relentless.mp3",
        "scene_use": "红月门禁封锁、灰区拦截机与猎杀终端 BOSS 超限战",
    },
    {
        "stem": "bgm_victory_stinger",
        "ext": ".mp3",
        "source_title": "Jingle Anime (361)",
        "author": "PeriTune (Sei Muro)",
        "license": "CC-BY 4.0",
        "url": "https://peritune.com/music/PerituneMaterial_Jingle_Anime.mp3",
        "scene_use": "战斗胜利结算与白羊座觉醒短奏（单次播放不循环）",
    },
]

SFX_ITEMS = [
    {
        "stem": "sfx_ui_click",
        "ext": ".wav",
        "source_pack": "Kenney Interface Sounds",
        "source_file": "click_002.wav",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master/addons/kenney_interface_sounds/click_002.wav",
    },
    {
        "stem": "sfx_ui_hover",
        "ext": ".wav",
        "source_pack": "Kenney Interface Sounds",
        "source_file": "tick_001.wav",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master/addons/kenney_interface_sounds/tick_001.wav",
    },
    {
        "stem": "sfx_page_flip",
        "ext": ".ogg",
        "source_pack": "Kenney RPG Audio",
        "source_file": "bookFlip2.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/RPG%20sounds%20(50%20sounds)/bookFlip2.ogg",
    },
    {
        "stem": "sfx_modal_open",
        "ext": ".ogg",
        "source_pack": "Kenney RPG Audio",
        "source_file": "bookOpen.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/RPG%20sounds%20(50%20sounds)/bookOpen.ogg",
    },
    {
        "stem": "sfx_save_chime",
        "ext": ".wav",
        "source_pack": "Kenney Interface Sounds",
        "source_file": "confirmation_002.wav",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master/addons/kenney_interface_sounds/confirmation_002.wav",
    },
    {
        "stem": "sfx_shop_coin",
        "ext": ".ogg",
        "source_pack": "Kenney RPG Audio",
        "source_file": "handleCoins.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/RPG%20sounds%20(50%20sounds)/handleCoins.ogg",
    },
    {
        "stem": "sfx_card_play",
        "ext": ".ogg",
        "source_pack": "Kenney Casino Audio",
        "source_file": "cardShove2.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Casino%20sounds%20(50%20sounds)/cardShove2.ogg",
    },
    {
        "stem": "sfx_shield_up",
        "ext": ".ogg",
        "source_pack": "Kenney Digital Audio",
        "source_file": "powerUp7.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Digital%20sounds%20(60%20sounds)/powerUp7.ogg",
    },
    {
        "stem": "sfx_heal",
        "ext": ".ogg",
        "source_pack": "Kenney Digital Audio",
        "source_file": "powerUp11.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Digital%20sounds%20(60%20sounds)/powerUp11.ogg",
    },
    {
        "stem": "sfx_debuff_glitch",
        "ext": ".wav",
        "source_pack": "Kenney Interface Sounds",
        "source_file": "glitch_002.wav",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master/addons/kenney_interface_sounds/glitch_002.wav",
    },
    {
        "stem": "sfx_counter_reflect",
        "ext": ".wav",
        "source_pack": "Kenney Interface Sounds",
        "source_file": "glass_004.wav",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/Calinou/kenney-interface-sounds/master/addons/kenney_interface_sounds/glass_004.wav",
    },
    {
        "stem": "sfx_hit_normal",
        "ext": ".ogg",
        "source_pack": "Kenney RPG Audio",
        "source_file": "chop.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/RPG%20sounds%20(50%20sounds)/chop.ogg",
    },
    {
        "stem": "sfx_hit_overclock",
        "ext": ".ogg",
        "source_pack": "Kenney Digital Audio",
        "source_file": "laser4.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Digital%20sounds%20(60%20sounds)/laser4.ogg",
    },
    {
        "stem": "sfx_cutin_slash",
        "ext": ".ogg",
        "source_pack": "Kenney RPG Audio",
        "source_file": "knifeSlice2.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/RPG%20sounds%20(50%20sounds)/knifeSlice2.ogg",
    },
    {
        "stem": "sfx_pack_tear",
        "ext": ".ogg",
        "source_pack": "Kenney Casino Audio",
        "source_file": "cardOpenPackage1.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Casino%20sounds%20(50%20sounds)/cardOpenPackage1.ogg",
    },
    {
        "stem": "sfx_zodiac_resonate",
        "ext": ".ogg",
        "source_pack": "Kenney Digital Audio",
        "source_file": "threeTone2.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Digital%20sounds%20(60%20sounds)/threeTone2.ogg",
    },
    {
        "stem": "sfx_victory",
        "ext": ".ogg",
        "source_pack": "Kenney Jingle Audio (Steel)",
        "source_file": "jingles_STEEL10.ogg",
        "license": "CC0 1.0 Public Domain",
        "url": "https://raw.githubusercontent.com/iwenzhou/kenney/master/Audio%20(295%20files)/Jingle%20sounds%20(85%20sounds)/jingles_STEEL/jingles_STEEL10.ogg",
    },
]


def _validate_audio(data: bytes, ext: str) -> tuple[bool, str]:
    if ext == ".mp3":
        if len(data) <= 50_000:
            return False, f"MP3 too small ({len(data)} bytes)"
        if data[:3] == b"ID3":
            return True, "ID3 MP3"
        if len(data) >= 2 and data[0] == 0xFF and data[1] in (0xFB, 0xF3, 0xF2, 0xFA):
            return True, "MPEG frame MP3"
        return False, f"Invalid MP3 header: {data[:12]!r}"
    if ext == ".ogg":
        if len(data) <= 1_000:
            return False, f"OGG too small ({len(data)} bytes)"
        if data[:4] == b"OggS":
            return True, "OggS"
        return False, f"Invalid OGG header: {data[:12]!r}"
    if ext == ".wav":
        if len(data) <= 1_000:
            return False, f"WAV too small ({len(data)} bytes)"
        if data[:4] == b"RIFF" and data[8:12] == b"WAVE":
            return True, "RIFF WAVE"
        return False, f"Invalid WAV header: {data[:12]!r}"
    return False, f"Unsupported ext {ext}"


def _download(url: str, dest: Path, ext: str) -> tuple[bool, str, int]:
    tmp = dest.with_suffix(dest.suffix + ".part")
    if tmp.exists():
        tmp.unlink()
    proc = subprocess.run(
        ["curl.exe", "-sSL", "--fail", "--max-time", "60", "-A", "Mozilla/5.0", "-o", str(tmp), url],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if proc.returncode != 0 or not tmp.exists():
        err = proc.stderr.strip() or f"curl exit {proc.returncode}"
        if tmp.exists():
            tmp.unlink()
        return False, err, 0
    data = tmp.read_bytes()
    ok, reason = _validate_audio(data, ext)
    if not ok:
        tmp.unlink()
        return False, reason, len(data)
    tmp.replace(dest)
    return True, reason, len(data)


def main() -> int:
    BGM_DIR.mkdir(parents=True, exist_ok=True)
    SFX_DIR.mkdir(parents=True, exist_ok=True)

    bgm_results = []
    sfx_results = []
    failed = []

    for item in BGM_TRACKS:
        dest = BGM_DIR / f"{item['stem']}{item['ext']}"
        ok, info, size_b = _download(item["url"], dest, item["ext"])
        row = {"stem": item["stem"], "file": dest.name, "ok": ok, "info": info, "bytes": size_b}
        bgm_results.append(row)
        if not ok:
            failed.append(row)
        print(f"[BGM] {dest.name}: ok={ok} ({size_b} bytes, {info})", flush=True)

    for item in SFX_ITEMS:
        dest = SFX_DIR / f"{item['stem']}{item['ext']}"
        ok, info, size_b = _download(item["url"], dest, item["ext"])
        if ok:
            # Remove older procedural/other-extension duplicate with the same stem
            for old_ext in (".wav", ".ogg", ".mp3"):
                if old_ext == item["ext"]:
                    continue
                old_p = SFX_DIR / f"{item['stem']}{old_ext}"
                if old_p.exists():
                    old_p.unlink()
                old_imp = SFX_DIR / f"{item['stem']}{old_ext}.import"
                if old_imp.exists():
                    old_imp.unlink()
        row = {"stem": item["stem"], "file": dest.name, "ok": ok, "info": info, "bytes": size_b}
        sfx_results.append(row)
        if not ok:
            failed.append(row)
        print(f"[SFX] {dest.name}: ok={ok} ({size_b} bytes, {info})", flush=True)

    summary = {
        "bgm_ok": sum(1 for r in bgm_results if r["ok"]),
        "bgm_total": len(bgm_results),
        "sfx_ok": sum(1 for r in sfx_results if r["ok"]),
        "sfx_total": len(sfx_results),
        "failed": failed,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
