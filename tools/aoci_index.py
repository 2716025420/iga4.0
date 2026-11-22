"""AOCI (AI-Oriented Code Indexing) local-first cognition volume generator and drift verifier for IGA."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
AOCI_MANIFEST = ROOT / "aoci.txt"
AOCI_META = ROOT / "aoci.meta.txt"
AOCI_CODE = ROOT / "aoci.code.txt"

MANAGED_ROOT_FILES = ["project.godot", "AGENTS.md", "HANDOFF.md"]
MANAGED_DIRS = [
    ("scripts", {".gd"}),
    ("scenes", {".tscn"}),
    ("tools", {".py", ".gd", ".tscn", ".js", ".html", ".css", ".mjs", ".sh", ".md"}),
]
EXCLUDED_NAMES = {"story_bundle.json", "story_data.js"}

# Curated FRAS (Function, Read-with, API/Callers, Safety/Constraints) specifications.
FRAS_CATALOG: dict[str, dict[str, str]] = {
    "project.godot": {
        "F": "Godot 4.7.2 project config, 1920x1080 canvas_items stretch, 6 autoload singletons (SaveManager, SceneManager, GameState, DayCycle, CampusLife, AudioManager)",
        "R": "scripts/global/game_state.gd,scripts/global/scene_manager.gd",
        "A": "Entry scene res://scenes/title/title_screen.tscn",
        "S": "Keep gl_compatibility renderer and autoload registration order intact.",
    },
    "AGENTS.md": {
        "F": "Top-level AI agent rules, 2026-11-14 worldbuilding baseline, 1920x1080 Stage-1->Stage-2 art pipeline, and AOCI index workflow",
        "R": "aoci.txt,aoci.code.txt,HANDOFF.md,docs/CURRENT_DESIGN.md",
        "A": "All coding agents & subagents",
        "S": "Highest-priority engineering & canon constraints; never violate.",
    },
    "HANDOFF.md": {
        "F": "Chronological round-by-round engineering handoff log and verification summary",
        "R": "AGENTS.md,aoci.code.txt",
        "A": "Developers & AI agents",
        "S": "Update concisely at the end of every completed task round.",
    },
    # --- scripts/campus ---
    "scripts/campus/campus_dialogue_ui.gd": {
        "F": "In-scene NPC dialogue overlay using StoryChrome notebook frame, portrait crop, and choice buttons",
        "R": "scripts/campus/campus_screen.gd,scripts/story/school_dialogue_presentation.gd",
        "A": "CampusDialogueUI; mounted by CampusScreen",
        "S": "Pure-Tab indent; uses unified StoryChrome frame without legacy speech bubbles.",
    },
    "scripts/campus/campus_life.gd": {
        "F": "CampusLife autoload: daily AP/meal/rest rules, 16-card shop transactions, NPC condition dialogues, and automatic day/night map concept resolution",
        "R": "scripts/campus/campus_places.gd,scripts/campus/region_map_view.gd,tools/story_studio/sync_story.py",
        "A": "CampusLife(Autoload) / CampusLifeService: map_concept(), npc_dialogue_lines(), buy_shop_item()",
        "S": "1-space indent; map_concept() auto-switches vermilion/indigo by DayCycle.period(); NPC lines synced by sync_story.py.",
    },
    "scripts/campus/campus_places.gd": {
        "F": "Campus location registry (club_room, library, gym, shop, dorm, rooftop, old_park, coast, beach) and hotspot snippet dialogues",
        "R": "scripts/campus/campus_life.gd,scripts/campus/scene_design_catalog.gd,tools/story_studio/sync_story.py",
        "A": "CampusPlaces: place_spec(), object_dialogue_lines()",
        "S": "1-space indent; hotspot dialogue snippets are managed by sync_story.py.",
    },
    "scripts/campus/campus_screen.gd": {
        "F": "Main controller for 8 playable campus/district places, NPC talks, Gym Set-C QualifierModal, and place transitions",
        "R": "scripts/campus/scene_object_view.gd,scripts/campus/campus_shop_panel.gd,scripts/ui/dynamic_ui.gd",
        "A": "CampusScreen (scenes/campus/campus_screen.tscn): _open_qualifier_modal(), open_shop()",
        "S": "Pure-Tab indent; QualifierModal uses v18 Set-C 9-slice textures and borderless buttons.",
    },
    "scripts/campus/campus_shop_panel.gd": {
        "F": "v18 Set-B wooden corkboard & sticky-note physical campus shop UI with card/item tabs, quantity stepper, and clerk speech bubble",
        "R": "scripts/campus/campus_screen.gd,scripts/data_models/campus_shop_catalog.gd,scripts/ui/dynamic_ui.gd",
        "A": "CampusShopPanel: setup(), refresh()",
        "S": "Pure-Tab indent; opening/closing shop counter must keep stage background fixed at x=150.",
    },
    "scripts/campus/home_object_button.gd": {
        "F": "Interactive hotspot button widget for Home & campus scene props with subtle hover/press feedback and reduced_motion support",
        "R": "scripts/home/home_screen.gd,scripts/ui/school_object_ui.gd",
        "A": "HomeObjectButton",
        "S": "1-space indent; never add focus outline or extra selection border.",
    },
    "scripts/campus/map_page_geometry.gd": {
        "F": "Normalized 1920x1080 coordinate and pin rect calculator for campus and region maps",
        "R": "scripts/campus/region_map_view.gd,scripts/campus/region_geometry.gd",
        "A": "MapPageGeometry",
        "S": "1-space indent.",
    },
    "scripts/campus/map_page_ui.gd": {
        "F": "Shared UI helper for map header/footer badges and pin labels",
        "R": "scripts/campus/map_screen.gd,scripts/campus/region_map_view.gd",
        "A": "MapPageUI",
        "S": "1-space indent.",
    },
    "scripts/campus/map_screen.gd": {
        "F": "Local campus map scene wrapper mounting RegionMapView for Arete Academy",
        "R": "scripts/campus/region_map_view.gd,scenes/campus/local_map_screen.tscn",
        "A": "MapScreen",
        "S": "1-space indent.",
    },
    "scripts/campus/region_atlas_view.gd": {
        "F": "Six-region world tour atlas screen showing 4 academies + 2 story factions, chapter route progress, and travel entry",
        "R": "scripts/campus/world_region_content.gd,scripts/campus/region_catalog.gd",
        "A": "RegionAtlasView (scenes/campus/region_atlas_screen.tscn)",
        "S": "Pure-Tab indent; Losers Alliance and IGA Cult have no Home, only 4 universities have Home.",
    },
    "scripts/campus/region_catalog.gd": {
        "F": "Metadata catalog for the 6 regions (Arete, Nomos, Agora, Techne, Losers Alliance, IGA Cult) and place nodes",
        "R": "scripts/campus/world_region_content.gd,scripts/campus/region_atlas_view.gd",
        "A": "RegionCatalog",
        "S": "1-space indent; keep Chapters 2-5 unconfirmed story details open.",
    },
    "scripts/campus/region_geometry.gd": {
        "F": "Pin positions and route line coordinates for regional map boards",
        "R": "scripts/campus/region_map_view.gd,scripts/campus/map_page_geometry.gd",
        "A": "RegionGeometry",
        "S": "1-space indent.",
    },
    "scripts/campus/region_home_layout.gd": {
        "F": "Furniture & hotspot layout descriptors for the 4 university Home clubrooms",
        "R": "scripts/campus/region_home_view.gd,scripts/home/home_screen.gd",
        "A": "RegionHomeLayout",
        "S": "1-space indent.",
    },
    "scripts/campus/region_home_view.gd": {
        "F": "Regional Home room background & prop renderer for university bases",
        "R": "scripts/campus/region_home_layout.gd,scripts/home/home_screen.gd",
        "A": "RegionHomeView",
        "S": "1-space indent.",
    },
    "scripts/campus/region_map_view.gd": {
        "F": "Interactive Arete & regional map board with automatic day/night art crossfade, 3 top-right utility buttons, and location cards",
        "R": "scripts/campus/campus_life.gd,scripts/global/day_cycle.gd,scripts/campus/region_geometry.gd",
        "A": "RegionMapView: _build_ui(), _refresh_map_concept()",
        "S": "Pure-Tab indent; no manual ToggleMapStyle button (auto day/night by DayCycle); keep night disabled button text high-contrast.",
    },
    "scripts/campus/scene_design_catalog.gd": {
        "F": "v17 8-scene layered stage catalog (sky, midground, foreground, actor sprites, contact shadows, hotspot rects)",
        "R": "scripts/campus/scene_stage_layers.gd,scripts/campus/scene_object_view.gd",
        "A": "SceneDesignCatalog: scene_spec(), actor_placements()",
        "S": "1-space indent; coordinates calibrated to 1920x1080/2340x1080 v17 production assets.",
    },
    "scripts/campus/scene_hud_layout.gd": {
        "F": "Unified v17 Set-A 56px single-row top bar, left action dock, and bottom bar for Home and 8 campus scenes",
        "R": "scripts/campus/scene_object_view.gd,scripts/home/home_screen.gd",
        "A": "SceneHUDLayout: build_top_bar(), build_left_dock()",
        "S": "Pure-Tab indent; top bar height strictly 56px across Home and all 8 campus scenes.",
    },
    "scripts/campus/scene_object_view.gd": {
        "F": "Unified v17 layered scene container combining SceneStageLayers and SceneHUDLayout for all 8 campus places",
        "R": "scripts/campus/scene_stage_layers.gd,scripts/campus/scene_hud_layout.gd,scripts/campus/campus_screen.gd",
        "A": "SceneObjectView: setup_place(), set_shop_split_mode()",
        "S": "Pure-Tab indent; shop stage_layers.position.x stays fixed at SHOP_STAGE_OFFSET_X = 150.0.",
    },
    "scripts/campus/scene_stage_layers.gd": {
        "F": "Multi-plane parallax stage renderer (sky/window, midground, foreground, positioned NPC sprites + contact shadows)",
        "R": "scripts/campus/scene_design_catalog.gd,scripts/campus/scene_object_view.gd",
        "A": "SceneStageLayers",
        "S": "Pure-Tab indent; no floating overhead speech icons on NPCs.",
    },
    "scripts/campus/world_region_content.gd": {
        "F": "Lore, academy philosophies, and regional rules for the 4 universities and 2 factions",
        "R": "scripts/campus/region_catalog.gd,docs/story/2026-10-24-四大学院与六地区最新设定.md",
        "A": "WorldRegionContent",
        "S": "1-space indent.",
    },
    # --- scripts/combat ---
    "scripts/combat/combat_card_ui.gd": {
        "F": "Tactical imprint card widget in combat hand with cost badge, custom art, hover lift, and target drag/click",
        "R": "scripts/combat/combat_screen.gd,scripts/combat/combat_presentation.gd,scripts/data_models/card_data.gd",
        "A": "CombatCardUI (scenes/combat/combat_card_ui.tscn)",
        "S": "Pure-Tab indent; borderless card frame with hover lift feedback.",
    },
    "scripts/combat/combat_presentation.gd": {
        "F": "1920x1080 combat arena layout: x=960 center-symmetric teams (500 vs 1420), overhead CompactIdentityBox HP plaques, animated TacticalResonanceSeal, and y=67 CardsContainer",
        "R": "scripts/combat/combat_screen.gd,scripts/combat/enemy_unit_ui.gd,scripts/combat/combat_vfx.gd",
        "A": "CombatPresentation: apply_layout(), pulse_resonance_seal(), is_sports_field_arena(), is_mirrored_2v2()",
        "S": "Pure-Tab indent; TEAM_CENTER_OFFSET=460 (Left=500, Right=1420); CardsContainer at (200,67,1246,340) flush on purple border; no legacy DuelDeckBack.",
    },
    "scripts/combat/combat_screen.gd": {
        "F": "Turn-based tactical card combat engine: shield vs Overclock HP rules, companion 3-card assist, Zodiac passives, and Liu Yulong 1-HP lock scripted counter",
        "R": "scripts/combat/combat_presentation.gd,scripts/combat/enemy_unit_ui.gd,scripts/global/game_state.gd",
        "A": "CombatScreen (scenes/combat/combat_screen.tscn)",
        "S": "Pure-Tab indent; calls pulse_resonance_seal() on card play and routes post_dialogue after scripted/boss fights.",
    },
    "scripts/combat/combat_vfx.gd": {
        "F": "Frame-sheet and procedural VFX player (slash, shield, overclock_redmoon, companion_assist, crystal_shimmer)",
        "R": "scripts/combat/combat_screen.gd,scripts/combat/combat_presentation.gd,scripts/story/dialogue_screen.gd",
        "A": "CombatVFX: play_once(), play_loop()",
        "S": "Pure-Tab indent; respects SaveManager.reduced_motion.",
    },
    "scripts/combat/enemy_unit_ui.gd": {
        "F": "Enemy fighter unit UI with full-body sprite, intent pill, target paperclip, and overhead CompactIdentityBox HP/shield plaque",
        "R": "scripts/combat/combat_presentation.gd,scripts/combat/combat_screen.gd,scripts/data_models/enemy_data.gd",
        "A": "EnemyUnitUI (scenes/combat/enemy_unit_ui.tscn): apply_compact_plaque_layout()",
        "S": "Pure-Tab indent; solo plaque 224x76, duo plaque 168x76 (352px pair) centered directly above enemy head.",
    },
    "scripts/combat/floating_text.gd": {
        "F": "Floating damage/shield/heal number popup animation in combat",
        "R": "scripts/combat/combat_screen.gd",
        "A": "FloatingText",
        "S": "Pure-Tab indent.",
    },
    # --- scripts/data_models ---
    "scripts/data_models/campus_shop_catalog.gd": {
        "F": "16 Tactical Imprint Cards + campus consumables catalog sold in physical campus shops",
        "R": "scripts/campus/campus_shop_panel.gd,scripts/campus/campus_life.gd",
        "A": "CampusShopCatalog",
        "S": "Pure-Tab indent; 12 Zodiac Mother Cards must NEVER appear in shop or gacha.",
    },
    "scripts/data_models/card_data.gd": {
        "F": "CardData resource model defining cost, damage, block, draw, upgrade Lv.2 deltas, and companion/zodiac tags",
        "R": "scripts/global/game_state.gd,scripts/combat/combat_card_ui.gd",
        "A": "CardData",
        "S": "Pure-Tab indent.",
    },
    "scripts/data_models/enemy_data.gd": {
        "F": "EnemyData resource model for single and multi-enemy encounters (HP, intents, hp_lock_min, companion visual)",
        "R": "scripts/global/game_state.gd,scripts/combat/enemy_unit_ui.gd",
        "A": "EnemyData",
        "S": "Pure-Tab indent.",
    },
    "scripts/data_models/item_catalog.gd": {
        "F": "Inventory item definitions for gifts, snacks, and tactical supplies",
        "R": "scripts/global/game_state.gd,scripts/campus/campus_life.gd",
        "A": "ItemCatalog",
        "S": "Pure-Tab indent.",
    },
    "scripts/data_models/map_node_data.gd": {
        "F": "Data structure for exploration and story node map entries",
        "R": "scripts/exploration/node_map.gd,scripts/global/game_state.gd",
        "A": "MapNodeData",
        "S": "Pure-Tab indent.",
    },
    "scripts/data_models/zodiac_catalog.gd": {
        "F": "12 Zodiac Mother Cards catalog, lore, resonance passive specs, and story acquisition chapters",
        "R": "scripts/home/zodiac_album_panel.gd,scripts/global/game_state.gd,docs/story/2026-10-25-星座卡与学生智能终端.md",
        "A": "ZodiacCatalog",
        "S": "Pure-Tab indent; keep unknown holder identities in Chapters 2-5 unset per canon.",
    },
    # --- scripts/exploration ---
    "scripts/exploration/lines_canvas.gd": {
        "F": "Custom Control drawing connecting lines between nodes on NodeMap",
        "R": "scripts/exploration/node_map.gd",
        "A": "LinesCanvas",
        "S": "Pure-Tab indent.",
    },
    "scripts/exploration/node_map.gd": {
        "F": "Chapter story & exploration node map UI with node badges, route lines, and next-objective entry",
        "R": "scripts/global/game_state.gd,scripts/exploration/lines_canvas.gd",
        "A": "NodeMap (scenes/exploration/node_map.tscn)",
        "S": "Pure-Tab indent.",
    },
    "scripts/exploration/school_route_screen.gd": {
        "F": "Campus route exploration & practice patrol screen with found notes and tactical encounters",
        "R": "scripts/global/school_exploration_flow.gd,scripts/global/school_exploration_routes.gd",
        "A": "SchoolRouteScreen (scenes/exploration/school_route_screen.tscn)",
        "S": "Pure-Tab indent.",
    },
    # --- scripts/global ---
    "scripts/global/audio_manager.gd": {
        "F": "AudioManager autoload: 7 CC-BY BGM tracks (auto-loop except victory stinger) and 17 CC0 SFX with scene routing",
        "R": "scripts/global/save_manager.gd,docs/design/2026-11-20-背景音乐与音效推荐及实装清单.md",
        "A": "AudioManager(Autoload): play_bgm(), play_sfx()",
        "S": "Pure-Tab indent; supports .ogg/.wav/.mp3 lookup.",
    },
    "scripts/global/calendar_content.gd": {
        "F": "Calendar weekday/period labels for campus schedule HUD",
        "R": "scripts/global/day_cycle.gd",
        "A": "CalendarContent",
        "S": "Pure-Tab indent.",
    },
    "scripts/global/combat_skin.gd": {
        "F": "Combat sprite & arena background path resolver for protagonist, companions, and enemies",
        "R": "scripts/combat/combat_presentation.gd,scripts/global/phase_two_content.gd",
        "A": "CombatSkin: enemy_combat_path(), arena_background_path()",
        "S": "Pure-Tab indent.",
    },
    "scripts/global/day_cycle.gd": {
        "F": "DayCycle autoload tracking day number, time period (morning/noon/afternoon/dusk/night), and Red-Moon phase",
        "R": "scripts/campus/campus_life.gd,scripts/campus/region_map_view.gd",
        "A": "DayCycle(Autoload) / DayCycleService: period(), advance_period()",
        "S": "Pure-Tab indent.",
    },
    "scripts/global/daylight_ui.gd": {
        "F": "Shared daylight paper/ink UI builders, centered FirstBattleHint banner, and combat/story badges",
        "R": "scripts/combat/combat_screen.gd,scripts/ui/school_object_ui.gd",
        "A": "DaylightUI",
        "S": "Pure-Tab indent; FirstBattleHint centered at x=960.",
    },
    "scripts/global/exploration_content.gd": {
        "F": "Library lore articles (《阿瑞忒与红月风物纪要》) and exploration event text",
        "R": "scripts/campus/campus_screen.gd,tools/story_studio/sync_story.py",
        "A": "ExplorationContent: LIBRARY_NOTES",
        "S": "Pure-Tab indent; LIBRARY_NOTES synced by sync_story.py.",
    },
    "scripts/global/game_state.gd": {
        "F": "GameState autoload: master story flow (Prologue n0 -> n_gate 2v2 -> n_club_intro -> Chapter 1), deck/workshop upgrades, companions, and enemy definitions",
        "R": "scripts/global/phase_two_content.gd,scripts/global/save_manager.gd,scripts/combat/combat_screen.gd",
        "A": "GameState(Autoload): new_game(), start_story_from_home(), complete_combat(), get_enemy_group()",
        "S": "Pure-Tab indent; supports post_dialogue 3-stage node flow (pre-dialogue -> combat -> post-dialogue).",
    },
    "scripts/global/phase_two_content.gd": {
        "F": "Master story script repository (ACTORS, SCRIPTS for Prologue & Chapter 1), waist-up emotion sprite resolver, and background/overlay paths",
        "R": "scripts/story/dialogue_screen.gd,tools/story_studio/sync_story.py,docs/story/user_write/序章.md",
        "A": "PhaseTwoContent: lines_for(), dialogue_character_path(), resolve_background_path(), resolve_background_overlay_path()",
        "S": "Pure-Tab indent; auto-updated by sync_story.py --apply; do not break const block headers.",
    },
    "scripts/global/platform_service.gd": {
        "F": "OS/window/DPI adaptation and fullscreen/resolution helper service",
        "R": "scripts/ui/settings_page.gd",
        "A": "PlatformService",
        "S": "Pure-Tab indent.",
    },
    "scripts/global/player_journey.gd": {
        "F": "Player objective tracker, chapter milestone descriptions, and next-destination guidance for Home & Terminal",
        "R": "scripts/global/game_state.gd,scripts/home/player_workspace.gd,scripts/home/home_panels.gd",
        "A": "PlayerJourney: current_objective(), milestone_entries()",
        "S": "1-space indent.",
    },
    "scripts/global/save_manager.gd": {
        "F": "SaveManager autoload: multi-slot JSON persistence, backward-compatible field migration, typing speed, and reduced_motion settings",
        "R": "scripts/global/game_state.gd,scripts/ui/settings_page.gd",
        "A": "SaveManager(Autoload) / SaveService: save_game(), load_game(), motion_duration()",
        "S": "Pure-Tab indent; preserve legacy save field compatibility.",
    },
    "scripts/global/scene_manager.gd": {
        "F": "SceneManager autoload handling transitions between Title, Home, Campus, Map, Dialogue, and Combat scenes",
        "R": "scripts/ui/scene_loading_screen.gd,scripts/ui/battle_entry_transition.gd",
        "A": "SceneManager(Autoload) / ProjectSceneFlow: change_scene()",
        "S": "1-space indent.",
    },
    "scripts/global/scene_skin.gd": {
        "F": "Visual theme and background path lookup for campus places and UI skins",
        "R": "scripts/campus/scene_design_catalog.gd",
        "A": "SceneSkin",
        "S": "1-space indent.",
    },
    "scripts/global/school_exploration_flow.gd": {
        "F": "State machine for gym simulated patrol routes and random note encounters",
        "R": "scripts/exploration/school_route_screen.gd,scripts/global/school_exploration_routes.gd",
        "A": "SchoolExplorationFlow",
        "S": "Pure-Tab indent.",
    },
    "scripts/global/school_exploration_routes.gd": {
        "F": "Found-note micro-story variants (拾到的留言) during gym/campus exploration routes",
        "R": "scripts/global/school_exploration_flow.gd,tools/story_studio/sync_story.py",
        "A": "SchoolExplorationRoutes: ROUTE_NOTE_VARIANTS",
        "S": "Pure-Tab indent; ROUTE_NOTE_VARIANTS synced by sync_story.py.",
    },
    "scripts/global/special_card_collection.gd": {
        "F": "Helper registry for special/signature cards and Zodiac Mother Card unlock states",
        "R": "scripts/data_models/zodiac_catalog.gd,scripts/global/game_state.gd",
        "A": "SpecialCardCollection",
        "S": "Pure-Tab indent.",
    },
    "scripts/global/theme_palette.gd": {
        "F": "Color palette constants for daylight paper UI and Red-Moon overclock accents",
        "R": "scripts/global/daylight_ui.gd",
        "A": "ThemePalette",
        "S": "Pure-Tab indent.",
    },
    # --- scripts/home ---
    "scripts/home/campus_guide_panel.gd": {
        "F": "Academy handbook and tactical rules guide panel inside Home / StudentTerminal",
        "R": "scripts/home/player_workspace.gd",
        "A": "CampusGuidePanel",
        "S": "Pure-Tab indent.",
    },
    "scripts/home/home_panels.gd": {
        "F": "RefCounted data provider for Home story archive filmstrip records and companion profiles",
        "R": "scripts/home/home_screen.gd,scripts/home/player_workspace.gd",
        "A": "HomePanels: known_records()",
        "S": "Pure-Tab indent.",
    },
    "scripts/home/home_portrait_actor.gd": {
        "F": "Companion portrait display widget inside the Home clubroom stage",
        "R": "scripts/home/home_screen.gd",
        "A": "HomePortraitActor",
        "S": "1-space indent.",
    },
    "scripts/home/home_screen.gd": {
        "F": "Arete Duel Clubroom Home screen with v17 56px top bar, left dock, 3D room hotspots, and StudentTerminal workspace host",
        "R": "scripts/home/player_workspace.gd,scripts/campus/scene_hud_layout.gd,scripts/global/game_state.gd",
        "A": "HomeScreen (scenes/home/home_screen.tscn)",
        "S": "Pure-Tab indent; top bar matches 8 campus scenes at 56px height.",
    },
    "scripts/home/player_workspace.gd": {
        "F": "6-page StudentTerminal workspace (Overview, Deck/Workshop, Companions, Zodiac Album, Story Archive, World Atlas) sharing TerminalProjection",
        "R": "scripts/home/home_screen.gd,scripts/home/zodiac_album_panel.gd,docs/story/2026-10-25-星座卡与学生智能终端.md",
        "A": "PlayerWorkspace: open_tab()",
        "S": "1-space indent; terminal has NO shop/gacha; all 6 pages share TerminalProjection chassis baseline.",
    },
    "scripts/home/school_object_panels.gd": {
        "F": "Pop-up inspection panels for clubroom physical objects (blackboard, bookshelf, workbench)",
        "R": "scripts/home/home_screen.gd",
        "A": "SchoolObjectPanels",
        "S": "Pure-Tab indent.",
    },
    "scripts/home/zodiac_album_panel.gd": {
        "F": "12 Zodiac Mother Cards collection album UI with constellation wheel, resonance passive viewer, and equip slot",
        "R": "scripts/data_models/zodiac_catalog.gd,scripts/home/player_workspace.gd",
        "A": "ZodiacAlbumPanel",
        "S": "Pure-Tab indent; Zodiac cards are permanent story collectibles only.",
    },
    # --- scripts/story ---
    "scripts/story/dialogue_screen.gd": {
        "F": "Main visual novel story playback screen: left/right waist-up emotion sprites, auto stage-clear on narrator lines, expression avatar crop, and branching choices",
        "R": "scripts/story/school_dialogue_presentation.gd,scripts/global/phase_two_content.gd,scripts/global/game_state.gd",
        "A": "DialogueScreen (scenes/story/dialogue_screen.tscn): _show_next_line(), _refresh_speaker_avatar()",
        "S": "Pure-Tab indent; any narrator line (speaker_char=='') or clear_stage/clear_side hides stage portraits so the next speakers start fresh Left -> Right.",
    },
    "scripts/story/school_dialogue_presentation.gd": {
        "F": "1920x1080 StoryChrome visual novel stage builder with background, BackdropOverlay (duel crowd), ParallaxCutsceneStage, and top control pills",
        "R": "scripts/story/dialogue_screen.gd,scripts/global/phase_two_content.gd,scripts/ui/parallax_cutscene_stage.gd",
        "A": "SchoolDialoguePresentation: configure_stage(), update_scene()",
        "S": "Pure-Tab indent; BackdropOverlay renders prologue_sports_field_duel_crowd only during school_gate.",
    },
    # --- scripts/title ---
    "scripts/title/title_screen.gd": {
        "F": "Title screen with New Game, Continue, Story Archive, Settings, and BGM launch",
        "R": "scripts/global/game_state.gd,scripts/global/save_manager.gd,scenes/title/title_screen.tscn",
        "A": "TitleScreen",
        "S": "Pure-Tab indent.",
    },
    # --- scripts/ui ---
    "scripts/ui/battle_entry_transition.gd": {
        "F": "Screen transition overlay when entering combat encounters",
        "R": "scripts/global/scene_manager.gd",
        "A": "BattleEntryTransition",
        "S": "1-space indent.",
    },
    "scripts/ui/dynamic_ui.gd": {
        "F": "9-slice StyleBoxTexture builder including v17 Set-A HUD helpers and v18 Shop Set-B / Gym Set-C window skin helpers",
        "R": "scripts/campus/campus_shop_panel.gd,scripts/campus/campus_screen.gd,scripts/ui/school_object_ui.gd",
        "A": "DynamicUI: v18_box(), apply_v18_panel(), apply_v18_button()",
        "S": "Pure-Tab indent; preserve 9-slice corner margins without stretching rivets/tape/tails.",
    },
    "scripts/ui/game_menu.gd": {
        "F": "In-game pause/system menu modal (Save, Load, Settings, Return to Title)",
        "R": "scripts/global/save_manager.gd,scripts/ui/settings_page.gd",
        "A": "GameMenu",
        "S": "Pure-Tab indent.",
    },
    "scripts/ui/notebook_ui.gd": {
        "F": "Shared notebook paper surface styling helper",
        "R": "scripts/ui/school_paper_surface.gd",
        "A": "NotebookUI",
        "S": "Pure-Tab indent.",
    },
    "scripts/ui/parallax_cutscene_stage.gd": {
        "F": "Two-layer parallax cutscene renderer (bg + fg pan/zoom) inside story dialogue playback",
        "R": "scripts/story/school_dialogue_presentation.gd",
        "A": "ParallaxCutsceneStage",
        "S": "Pure-Tab indent; respects reduced_motion.",
    },
    "scripts/ui/reward_card_popup.gd": {
        "F": "Post-combat / story card acquisition reward modal",
        "R": "scripts/combat/combat_screen.gd,scripts/data_models/card_data.gd",
        "A": "RewardCardPopup",
        "S": "1-space indent.",
    },
    "scripts/ui/scene_loading_screen.gd": {
        "F": "Async scene transition loading overlay",
        "R": "scripts/global/scene_manager.gd",
        "A": "SceneLoadingScreen",
        "S": "1-space indent.",
    },
    "scripts/ui/scene_surface_ui.gd": {
        "F": " translucent surface panel helper avoiding double dark borders",
        "R": "scripts/ui/school_object_ui.gd",
        "A": "SceneSurfaceUI",
        "S": "1-space indent; only modulate alpha on overlays.",
    },
    "scripts/ui/school_card_carousel.gd": {
        "F": "Horizontal card carousel component for deck and collection browsing",
        "R": "scripts/home/player_workspace.gd",
        "A": "SchoolCardCarousel",
        "S": "Pure-Tab indent.",
    },
    "scripts/ui/school_object_ui.gd": {
        "F": "Core borderless button/panel factory enforcing SchoolObjectUI.borderless() and hover/press micro-motions",
        "R": "scripts/ui/dynamic_ui.gd,scripts/campus/scene_hud_layout.gd",
        "A": "SchoolObjectUI: borderless()",
        "S": "Pure-Tab indent; runtime controls must never add focus rings or selection outlines.",
    },
    "scripts/ui/school_paper_surface.gd": {
        "F": "Warm paper card/panel StyleBox builder",
        "R": "scripts/ui/school_object_ui.gd",
        "A": "SchoolPaperSurface",
        "S": "Pure-Tab indent.",
    },
    "scripts/ui/settings_page.gd": {
        "F": "Settings panel for audio volume, typing speed, resolution, and reduced_motion toggle",
        "R": "scripts/global/save_manager.gd,scripts/global/audio_manager.gd",
        "A": "GameSettingsPage",
        "S": "Pure-Tab indent.",
    },
    # --- scenes ---
    "scenes/campus/campus_screen.tscn": {
        "F": "Scene root for playable campus & district places",
        "R": "scripts/campus/campus_screen.gd",
        "A": "res://scenes/campus/campus_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/campus/local_map_screen.tscn": {
        "F": "Scene root for Arete Academy campus map",
        "R": "scripts/campus/map_screen.gd,scripts/campus/region_map_view.gd",
        "A": "res://scenes/campus/local_map_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/campus/region_atlas_screen.tscn": {
        "F": "Scene root for 6-region world tour atlas",
        "R": "scripts/campus/region_atlas_view.gd",
        "A": "res://scenes/campus/region_atlas_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/combat/combat_card_ui.tscn": {
        "F": "PackedScene for hand cards in CombatScreen",
        "R": "scripts/combat/combat_card_ui.gd",
        "A": "res://scenes/combat/combat_card_ui.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/combat/combat_screen.tscn": {
        "F": "Scene root for turn-based tactical card combat",
        "R": "scripts/combat/combat_screen.gd,scripts/combat/combat_presentation.gd",
        "A": "res://scenes/combat/combat_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/combat/enemy_unit_ui.tscn": {
        "F": "PackedScene for enemy fighter units in CombatScreen",
        "R": "scripts/combat/enemy_unit_ui.gd",
        "A": "res://scenes/combat/enemy_unit_ui.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/exploration/node_map.tscn": {
        "F": "Scene root for story/chapter node map",
        "R": "scripts/exploration/node_map.gd",
        "A": "res://scenes/exploration/node_map.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/exploration/school_route_screen.tscn": {
        "F": "Scene root for campus patrol route exploration",
        "R": "scripts/exploration/school_route_screen.gd",
        "A": "res://scenes/exploration/school_route_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/home/home_screen.tscn": {
        "F": "Scene root for Arete Duel Clubroom Home",
        "R": "scripts/home/home_screen.gd",
        "A": "res://scenes/home/home_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/story/dialogue_screen.tscn": {
        "F": "Scene root for visual novel story dialogue playback",
        "R": "scripts/story/dialogue_screen.gd",
        "A": "res://scenes/story/dialogue_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "scenes/title/title_screen.tscn": {
        "F": "Main entry title screen scene",
        "R": "scripts/title/title_screen.gd",
        "A": "res://scenes/title/title_screen.tscn",
        "S": "Pure-Tab .tscn.",
    },
    # --- tools ---
    "tools/aoci_index.py": {
        "F": "AOCI local-first cognition index builder, drift detector (--verify), incremental updater (--update), and module query CLI (--query)",
        "R": "aoci.txt,aoci.meta.txt,aoci.code.txt,tools/run_godot_tests.py",
        "A": "CLI: python tools/aoci_index.py [--verify|--update|--query <kw>]",
        "S": "Run --update whenever managed files are added, edited, or removed.",
    },
    "tools/audio/fetch_free_audio.py": {
        "F": "Downloader and verifier for 7 CC-BY PeriTune BGM tracks and 17 CC0 Kenney SFX files",
        "R": "scripts/global/audio_manager.gd,assets/audio/CREDITS.txt",
        "A": "CLI: python tools/audio/fetch_free_audio.py",
        "S": "Preserves attribution in assets/audio/CREDITS.txt.",
    },
    "tools/audio/generate_sfx.py": {
        "F": "Procedural fallback WAV sound effect generator",
        "R": "tools/audio/fetch_free_audio.py",
        "A": "CLI: python tools/audio/generate_sfx.py",
        "S": "Fallback utility only.",
    },
    "tools/build_v17_scene_char_ui_combo_pack.py": {
        "F": "Asset brief packager for v17 8-scene layered backgrounds, character sprites, and UI Set-A",
        "R": "docs/design/2026-11-20-场景人物立绘与UI三套组合需求方案_v17.md",
        "A": "CLI packager -> archive/",
        "S": "Outputs to ignored archive/ directory.",
    },
    "tools/build_v18_shop_gym_modal_pack.py": {
        "F": "Asset brief packager for v18 Shop Set-B and Gym Qualifier Set-C 9-slice window layers",
        "R": "docs/design/2026-11-20-商店柜台商品窗口与体育馆大赛窗口三套概念需求方案_v18.md",
        "A": "CLI packager -> archive/",
        "S": "Outputs to ignored archive/ directory.",
    },
    "tools/build_v19_prologue_asset_pack.py": {
        "F": "Asset brief packager for v19 Prologue characters (thug_grunt, thug_boss) and scenes",
        "R": "docs/design/2026-11-21-新序章人物与场景素材需求方案_v19.md",
        "A": "CLI packager -> archive/",
        "S": "Outputs to ignored archive/ directory.",
    },
    "tools/build_v20_library_encounter_asset_pack.py": {
        "F": "Asset brief packager for v20 Ch1 Library Encounter (school_affairs.md): empty-handed thug emotions, passerby silhouettes, and ch1_library_path scenes",
        "R": "docs/design/2026-11-22-图书馆偶遇人物与场景素材需求方案_v20.md,docs/story/user_write/school_affairs.md",
        "A": "CLI packager -> archive/",
        "S": "Outputs to ignored archive/ directory.",
    },
    "tools/cloud/check.sh": {
        "F": "Linux cloud headless import & startup sanity script",
        "R": "tools/cloud/setup.sh,docs/CLOUD_DEVELOPMENT.md",
        "A": "CLI: bash tools/cloud/check.sh",
        "S": "Uses isolated XDG temp directories.",
    },
    "tools/cloud/setup.sh": {
        "F": "Linux cloud Godot 4.7.2 binary provisioning script",
        "R": "tools/cloud/check.sh,docs/CLOUD_DEVELOPMENT.md",
        "A": "CLI: bash tools/cloud/setup.sh",
        "S": "Installs into .godot/cloud-tools/.",
    },
    "tools/cloud/test_p5.sh": {
        "F": "Linux cloud headless smoke test wrapper",
        "R": "tools/run_godot_tests.py,tools/cloud/check.sh",
        "A": "CLI: bash tools/cloud/test_p5.sh",
        "S": "Delegates to tools/run_godot_tests.py.",
    },
    "tools/run_godot_tests.py": {
        "F": "Isolated Godot regression runner with GDScript indentation preflight, AOCI drift check, headless smoke suite, and OpenGL screenshot size verification",
        "R": "tools/tests/core_smoke.gd,tools/tests/capture_scenes.gd,tools/aoci_index.py",
        "A": "CLI: python tools/run_godot_tests.py --godot <BIN> --suite [smoke|captures|all]",
        "S": "Fails closed on any mixed/inconsistent GDScript indentation or SCRIPT ERROR.",
    },
    "tools/story_studio/app.js": {
        "F": "Story Studio web frontend: stream script parser/serializer, auto stage-clear on narrator with Left->Right speaker reset, explicit stage-clear directive buttons, and 1920x1080 live preview",
        "R": "tools/story_studio/index.html,tools/story_studio/sync_story.py,scripts/story/dialogue_screen.gd",
        "A": "Browser app for tools/story_studio/index.html",
        "S": "Keep stream syntax round-trip lossless with sync_story.py; validate via node --check.",
    },
    "tools/story_studio/index.html": {
        "F": "Story Studio 3-pane workspace HTML shell (navigator, stream/card editor, 1920x1080 stage preview & shortcuts)",
        "R": "tools/story_studio/app.js,tools/story_studio/style.css",
        "A": "Story Studio UI entry",
        "S": "Loads story_data.js for zero-server offline use or connects to server.py.",
    },
    "tools/story_studio/server.py": {
        "F": "Local HTTP server for Story Studio enabling 1-click save/apply directly back to Godot .gd files",
        "R": "tools/story_studio/sync_story.py,tools/story_studio/app.js",
        "A": "CLI: python tools/story_studio/server.py",
        "S": "Delegates export/apply/verify to sync_story.py.",
    },
    "tools/story_studio/style.css": {
        "F": "Warm paper & dark theme stylesheet and 1920x1080 scaled stage replica rules for Story Studio",
        "R": "tools/story_studio/index.html",
        "A": "Story Studio CSS",
        "S": "Keep stage actor/chrome proportions aligned with SchoolDialoguePresentation.",
    },
    "tools/story_studio/sync_story.py": {
        "F": "Bi-directional story synchronizer between Godot .gd scripts, story_bundle.json, story_data.js, and docs/story/scripts/*.md",
        "R": "scripts/global/phase_two_content.gd,scripts/campus/campus_life.gd,tools/story_studio/app.js",
        "A": "CLI: python tools/story_studio/sync_story.py [--export|--apply|--verify]",
        "S": "Preserves per-target file indentation (Tabs for phase_two_content.gd, 1-space for campus_life.gd & campus_places.gd).",
    },
    "tools/tests/capture_scenes.gd": {
        "F": "Automated OpenGL visual regression capture runner producing 28 deterministic screenshots across Title, Home, 6 Terminal tabs, Map day/night, 8 Campus places, Prologue, and Combat",
        "R": "tools/run_godot_tests.py,tools/tests/core_smoke.gd",
        "A": "res://tools/tests/capture_scenes.tscn",
        "S": "Pure-Tab indent; verify at both 1600x900 and 1600x720.",
    },
    "tools/tests/capture_scenes.tscn": {
        "F": "Scene wrapper for capture_scenes.gd visual capture suite",
        "R": "tools/tests/capture_scenes.gd",
        "A": "res://tools/tests/capture_scenes.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "tools/tests/core_smoke.gd": {
        "F": "Comprehensive automated smoke suite (1889+ checks) covering story flow, narrator stage-clear, 2v2/1v1 combat symmetry, animated seal, auto day/night map, shops, audio, and saves",
        "R": "tools/run_godot_tests.py,scripts/global/game_state.gd",
        "A": "res://tools/tests/core_smoke.tscn",
        "S": "Pure-Tab indent; all checks must pass with 0 failures.",
    },
    "tools/tests/core_smoke.tscn": {
        "F": "Scene wrapper for core_smoke.gd regression suite",
        "R": "tools/tests/core_smoke.gd",
        "A": "res://tools/tests/core_smoke.tscn",
        "S": "Pure-Tab .tscn.",
    },
    "tools/visual_review/README.md": {
        "F": "Usage guide for live Godot MCP visual inspection scripts",
        "R": "tools/visual_review/school_mcp.mjs",
        "A": "Documentation",
        "S": "Keep concise.",
    },
    "tools/visual_review/mcp_client.mjs": {
        "F": "Minimal Node.js JSON-RPC client for Godot runtime MCP server",
        "R": "tools/visual_review/school_mcp.mjs",
        "A": "Node ESM module",
        "S": "Connects to localhost 6570-6585.",
    },
    "tools/visual_review/school_mcp.mjs": {
        "F": "Live scene tree and screenshot inspector via Godot MCP runtime",
        "R": "tools/visual_review/mcp_client.mjs",
        "A": "CLI: node tools/visual_review/school_mcp.mjs",
        "S": "Read-only inspection tool.",
    },
}


def discover_managed_files() -> list[Path]:
    found: list[Path] = []
    for rel in MANAGED_ROOT_FILES:
        p = ROOT / rel
        if p.is_file():
            found.append(p)
    for folder, exts in MANAGED_DIRS:
        base = ROOT / folder
        if not base.exists():
            continue
        for p in sorted(base.rglob("*")):
            if not p.is_file():
                continue
            if "__pycache__" in p.parts:
                continue
            if p.name in EXCLUDED_NAMES or p.name.endswith(".uid") or p.name.endswith(".import"):
                continue
            if p.suffix.lower() in exts:
                found.append(p)
    return found


def compute_file_fingerprint(path: Path) -> tuple[str, int, str]:
    raw = path.read_bytes()
    normalized = raw.replace(b"\r\n", b"\n")
    digest = hashlib.sha1(normalized).hexdigest()[:4].upper()
    text = normalized.decode("utf-8", errors="replace")
    lines = text.splitlines()
    indent_tag = "txt"
    if path.suffix in {".gd", ".tscn", ".py", ".js", ".css", ".html", ".mjs", ".sh"}:
        indent_tag = "tab"
        for line in lines:
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if line.startswith("\t"):
                indent_tag = "tab"
                break
            if line.startswith(" ") and not line.startswith("  "):
                indent_tag = "1sp"
                break
            if line.startswith("  "):
                indent_tag = "sp"
                break
    return digest, len(lines), indent_tag


def infer_default_fras(rel_path: str, path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    cn_match = re.search(r"^class_name\s+(\w+)", text, re.MULTILINE)
    class_label = cn_match.group(1) if cn_match else Path(rel_path).stem
    _, _, indent_tag = compute_file_fingerprint(path)
    return {
        "F": f"Module {rel_path} ({class_label})",
        "R": "project.godot",
        "A": class_label,
        "S": f"Maintain file indentation style ({indent_tag}).",
    }


def parse_existing_code_volume() -> dict[str, dict[str, Any]]:
    entries: dict[str, dict[str, Any]] = {}
    if not AOCI_CODE.is_file():
        return entries
    line_re = re.compile(
        r"^([^\[\s]+)\[([0-9A-F]{4})\|L(\d+)\|([^\]]+)\]:\s*F:(.*?)\s*\|\s*R:(.*?)\s*\|\s*A:(.*?)\s*\|\s*S:(.*)$"
    )
    for raw_line in AOCI_CODE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        m = line_re.match(line)
        if not m:
            continue
        rel_path, digest, line_count, indent_tag, f_val, r_val, a_val, s_val = m.groups()
        entries[rel_path] = {
            "hash": digest,
            "lines": int(line_count),
            "indent": indent_tag,
            "F": f_val.strip(),
            "R": r_val.strip(),
            "A": a_val.strip(),
            "S": s_val.strip(),
        }
    return entries


def build_code_volume_text(existing: dict[str, dict[str, Any]] | None = None) -> str:
    existing = existing or {}
    managed = discover_managed_files()
    out_lines = [
        "#AOCI-CODE-VOLUME: 1 ===res://===",
        "#Format: object-fras-v2 (<path>[<sha1_4>|L<lines>|<indent>]: F:<responsibility> | R:<read-with> | A:<api/callers> | S:<safety/constraints>)",
        "#Note: Read this single file at session start to locate target modules, dependencies, APIs, and indentation rules without blind full-repo scans.",
    ]
    current_group = ""
    for path in managed:
        rel = path.relative_to(ROOT).as_posix()
        top_group = rel.split("/")[0] if "/" in rel else "root"
        if top_group != current_group:
            current_group = top_group
            out_lines.append(f"# --- {current_group} ---")
        digest, line_count, indent_tag = compute_file_fingerprint(path)
        fras = FRAS_CATALOG.get(rel) or existing.get(rel) or infer_default_fras(rel, path)
        f_str = fras["F"].replace("\n", " ").strip()
        r_str = fras["R"].replace("\n", " ").strip()
        a_str = fras["A"].replace("\n", " ").strip()
        s_str = fras["S"].replace("\n", " ").strip()
        out_lines.append(
            f"{rel}[{digest}|L{line_count}|{indent_tag}]: F:{f_str} | R:{r_str} | A:{a_str} | S:{s_str}"
        )
    return "\n".join(out_lines) + "\n"


def verify_index() -> dict[str, Any]:
    missing_volumes = [p.name for p in [AOCI_MANIFEST, AOCI_META, AOCI_CODE] if not p.is_file()]
    if missing_volumes:
        return {
            "aoci_verified": False,
            "missing_volumes": missing_volumes,
            "unbaselined": [],
            "orphans": [],
            "stale": [],
        }
    indexed = parse_existing_code_volume()
    managed = {p.relative_to(ROOT).as_posix(): p for p in discover_managed_files()}
    unbaselined: list[str] = []
    orphans: list[str] = []
    stale: list[str] = []

    for rel, path in managed.items():
        if rel not in indexed:
            unbaselined.append(rel)
            continue
        digest, line_count, indent_tag = compute_file_fingerprint(path)
        entry = indexed[rel]
        if entry["hash"] != digest or entry["lines"] != line_count or entry["indent"] != indent_tag:
            stale.append(rel)

    for rel in indexed:
        if rel not in managed:
            orphans.append(rel)

    ok = not (unbaselined or orphans or stale)
    return {
        "aoci_verified": ok,
        "total_indexed": len(indexed),
        "total_managed": len(managed),
        "unbaselined": unbaselined,
        "orphans": orphans,
        "stale": stale,
    }


def query_index(keyword: str) -> list[str]:
    kw = keyword.lower().strip()
    if not AOCI_CODE.is_file():
        return []
    matches: list[str] = []
    for line in AOCI_CODE.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        if kw in line.lower():
            matches.append(line)
    return matches


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--update", action="store_true", help="Rebuild/refresh aoci.code.txt fingerprints from current repository state")
    parser.add_argument("--verify", action="store_true", help="Check for Missing/Orphan/Stale/Unbaselined drift in aoci.code.txt")
    parser.add_argument("--query", help="Filter aoci.code.txt FRAS lines by keyword")
    args = parser.parse_args()

    if args.update or (not args.verify and not args.query):
        existing = parse_existing_code_volume()
        content = build_code_volume_text(existing)
        AOCI_CODE.write_text(content, encoding="utf-8")

    if args.query:
        results = query_index(args.query)
        for r in results:
            print(r)
        print(json.dumps({"query": args.query, "matches": len(results)}, ensure_ascii=False))
        return 0

    report = verify_index()
    print(json.dumps(report, ensure_ascii=False))
    return 0 if report["aoci_verified"] else 1


if __name__ == "__main__":
    sys.exit(main())
