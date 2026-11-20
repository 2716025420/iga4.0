/* IGA Story Studio — Zero-Form Stream & Bubble Script Authoring Workspace */
(() => {
  'use strict';

  const STORAGE_KEY = 'iga_story_studio_draft_v1';
  const THEME_KEY = 'iga_story_studio_theme_v1';

  const EMO_TO_CN = {
    neutral: '平静',
    happy: '微笑',
    shy: '害羞',
    surprised: '惊讶',
    angry: '愤怒',
    worried: '担忧',
    concerned: '担忧',
    damaged_fiber: '光纤受损',
    crystal_stasis: '结晶休眠',
    unmasked: '摘面具',
  };
  const CN_TO_EMO = {
    平静: 'neutral',
    默认: 'neutral',
    蒙面: 'neutral',
    微笑: 'happy',
    开心: 'happy',
    害羞: 'shy',
    惊讶: 'surprised',
    愤怒: 'angry',
    生气: 'angry',
    担忧: 'worried',
    担心: 'worried',
    光纤受损: 'damaged_fiber',
    结晶休眠: 'crystal_stasis',
    摘面具: 'unmasked',
  };
  const SIDE_TO_CN = { left: '左', right: '右' };
  const CN_TO_SIDE = { 左: 'left', 右: 'right', left: 'left', right: 'right' };

  const GROUP_META = [
    { key: 'main_active', label: '1. 现行主线（序章 & 第一章）', collapsed: false },
    { key: 'prologue_oral_drafts', label: '2. 主创口述序章原案草稿', collapsed: false },
    { key: 'chapters_2_to_5', label: '3. 第 2–5 章巡回大纲与草稿', collapsed: false },
    { key: 'campus_npcs', label: '4. 校园同伴、NPC 与调查短句', collapsed: false },
    { key: 'notes_and_routes', label: '5. 风物纪要 & 训练留言', collapsed: false },
  ];

  const state = {
    bundle: null,
    serverOnline: false,
    dirty: false,
    activeView: 'scene', // 'scene' | 'cast_world'
    activeCategory: 'main_active',
    activeSceneId: 'campus_morning',
    activeSubTabIdx: 0, // For NPC conditions, library notes, exploration variants, snippets
    editorMode: 'stream', // 'stream' | 'cards'
    autoAlternate: true,
    pairLeft: 'ye_zhou',
    pairRight: 'huang_qiufeng',
    cursorLineIdx: 0, // index in current lines array
    cursorRawRow: 0,  // line index in raw stream text
    showNoteBanner: false,
    playtest: {
      active: false,
      auto: false,
      timer: null,
      typingTimer: null,
      soundOn: true,
      bannerVisible: false,
    },
    collapsedGroups: {},
    searchQuery: '',
  };

  // DOM refs
  const $ = (id) => document.getElementById(id);
  const els = {};

  function cacheDom() {
    els.serverBadge = $('serverBadge');
    els.searchInput = $('searchInput');
    els.sceneTree = $('sceneTree');
    els.editorPane = $('editorPane');
    els.previewMetaTag = $('previewMetaTag');
    els.stageViewportWrap = $('stageViewportWrap');
    els.stageScaler = $('stageScaler');
    els.stageBgStack = $('stageBgStack');
    els.stageCutscene = $('stageCutscene');
    els.cutsceneBgImg = $('cutsceneBgImg');
    els.cutsceneFgImg = $('cutsceneFgImg');
    els.stageCaption = $('stageCaption');
    els.stageLeftActor = $('stageLeftActor');
    els.stageRightActor = $('stageRightActor');
    els.stagePortraitWrap = $('stagePortraitWrap');
    els.stagePortraitImg = $('stagePortraitImg');
    els.stageNameplate = $('stageNameplate');
    els.stageText = $('stageText');
    els.stageContinue = $('stageContinue');
    els.stageChoices = $('stageChoices');
    els.stageChapterBanner = $('stageChapterBanner');
    els.stageBannerTitle = $('stageBannerTitle');
    els.readabilityBar = $('readabilityBar');
    els.btnPlayToggle = $('btnPlayToggle');
    els.btnAutoPlay = $('btnAutoPlay');
    els.btnToggleSound = $('btnToggleSound');
    els.btnToggleBanner = $('btnToggleBanner');
    els.modalBackdrop = $('modalBackdrop');
    els.modalCard = $('modalCard');
    els.toastHost = $('toastHost');
  }

  function toast(msg, kind = '') {
    const div = document.createElement('div');
    div.className = `toast ${kind}`;
    div.textContent = msg;
    els.toastHost.appendChild(div);
    setTimeout(() => div.remove(), 3200);
  }

  function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj));
  }

  function assetUrl(relPath) {
    if (!relPath) return '';
    if (/^(https?:|data:|\/)/i.test(relPath)) return relPath;
    return `../../${relPath.replace(/^\/+/, '')}`;
  }

  function actorLookup() {
    return (state.bundle && state.bundle.actors) || {};
  }

  function findActorIdByName(name) {
    const actors = actorLookup();
    if (actors[name]) return name;
    for (const [cid, spec] of Object.entries(actors)) {
      if (spec.name === name) return cid;
    }
    if (name === '灰区女特工' || name === 'alliance_operative') return 'rebel_operative_masked';
    return '';
  }

  function getActorAvatar(charId, emotion = 'neutral') {
    if (!charId) return { url: '', crop: false };
    const charAssets = state.bundle?.assets?.characters?.[charId];
    if (!charAssets) return { url: '', crop: false };
    const av = charAssets.avatars?.[emotion] || charAssets.avatars?.neutral;
    if (av && av.path) return { url: assetUrl(av.path), crop: !!av.crop };
    const emoPath = charAssets.emotions?.[emotion] || charAssets.emotions?.neutral;
    if (emoPath) return { url: assetUrl(emoPath), crop: true };
    return { url: '', crop: false };
  }

  function getActorSprite(charId, emotion = 'neutral') {
    if (!charId) return '';
    const charAssets = state.bundle?.assets?.characters?.[charId];
    if (!charAssets) return '';
    const p = charAssets.emotions?.[emotion] || charAssets.emotions?.neutral;
    return p ? assetUrl(p) : '';
  }

  function getAvailableEmotions(charId) {
    const charAssets = state.bundle?.assets?.characters?.[charId];
    const base = ['neutral', 'happy', 'shy', 'surprised', 'angry', 'worried'];
    if (!charAssets || !charAssets.emotions) {
      return charId ? base : [];
    }
    const keys = Object.keys(charAssets.emotions);
    if (!keys.length) return [];
    const ordered = ['neutral', 'happy', 'shy', 'surprised', 'angry', 'worried', 'damaged_fiber', 'crystal_stasis', 'unmasked']
      .filter((k) => keys.includes(k));
    return ordered.length ? ordered : keys;
  }

  // ==================== Stream Syntax Parser & Serializer ====================

  function parseStreamText(rawText) {
    const actors = actorLookup();
    const linesOut = [];
    let activeCutscene = '';
    const lastSideByChar = {};
    let lastDialogueIdx = null;
    let activeChoice = null;

    const rawRows = String(rawText || '').split(/\r?\n/);
    for (const raw of rawRows) {
      const trimmed = raw.trim();
      if (!trimmed) continue;
      const indent = raw.length - raw.trimStart().length;

      // Directive: [指令: 参数]
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        const inner = trimmed.slice(1, -1).trim();
        let kind = inner;
        let arg = '';
        const sepIdx = inner.search(/[:：]/);
        if (sepIdx >= 0) {
          kind = inner.slice(0, sepIdx).trim();
          arg = inner.slice(sepIdx + 1).trim();
        }
        if (kind === '过场' || kind === 'cutscene') {
          activeCutscene = ['关闭', '无', 'none', 'off', ''].includes(arg) ? '' : arg;
          continue;
        }
        linesOut.push({ type: 'directive', kind, arg });
        activeChoice = null;
        continue;
      }

      // Choice: ? ... or - "..."
      if (trimmed.startsWith('?') || trimmed.startsWith('- ')) {
        if (trimmed === '? 玩家选择:' || trimmed === '? 玩家选择：') continue;
        let body = trimmed.startsWith('?') ? trimmed.slice(1).trim() : trimmed.slice(2).trim();
        body = body.replace(/^选项[A-Za-z0-9一二三]+\s*[:：]\s*/, '');
        const tags = [...body.matchAll(/\[([^\]]+)\]/g)].map((m) => m[1]);
        const choiceText = body.replace(/\s*\[[^\]]+\]/g, '').trim().replace(/^["“]|["”]$/g, '');
        const choiceObj = { text: choiceText };
        for (const tag of tags) {
          const fm = tag.trim().match(/^(?:好感[:：]\s*|\+)([^+\s]+)\s*\+?\s*(\d+)$/);
          if (fm) {
            const targetName = fm[1].trim();
            choiceObj.favor_char = findActorIdByName(targetName) || targetName;
            choiceObj.favor_add = parseInt(fm[2], 10);
          } else if (tag.trim().startsWith('标志')) {
            choiceObj.flag = tag.split(/[:：]/).slice(1).join(':').trim();
          }
        }
        if (lastDialogueIdx !== null && linesOut[lastDialogueIdx]) {
          if (!linesOut[lastDialogueIdx].choices) linesOut[lastDialogueIdx].choices = [];
          linesOut[lastDialogueIdx].choices.push(choiceObj);
          activeChoice = choiceObj;
        }
        continue;
      }

      // Indented follow-up line under choice
      if (indent >= 2 && activeChoice) {
        const sub = parseSingleDialogueLine(trimmed, actors, lastSideByChar, activeCutscene);
        if (!activeChoice.follow_up) activeChoice.follow_up = [];
        activeChoice.follow_up.push(sub);
        continue;
      }

      activeChoice = null;
      const entry = parseSingleDialogueLine(trimmed, actors, lastSideByChar, activeCutscene);
      linesOut.push(entry);
      lastDialogueIdx = linesOut.length - 1;
    }

    return linesOut;
  }

  function parseSingleDialogueLine(line, actors, lastSideByChar, activeCutscene) {
    const m = line.match(/^([^:：\n(（]{1,24})(?:[(（]([^)）]*)[)）])?\s*[:：]\s*(.*)$/);
    if (!m) {
      const res = { speaker: '旁白', char: '', side: 'left', emotion: 'neutral', text: line };
      if (activeCutscene) res.cutscene = activeCutscene;
      return res;
    }

    let speaker = m[1].trim();
    const metaRaw = (m[2] || '').trim();
    const text = m[3].trim();

    if (speaker === '旁白' || speaker === '叙述') {
      const res = { speaker: '旁白', char: '', side: 'left', emotion: 'neutral', text };
      if (activeCutscene) res.cutscene = activeCutscene;
      return res;
    }

    const charId = findActorIdByName(speaker);
    let emotion = 'neutral';
    let side = '';

    if (metaRaw) {
      const parts = metaRaw.split(/[,，/|]/).map((p) => p.trim()).filter(Boolean);
      for (const p of parts) {
        if (CN_TO_SIDE[p]) {
          side = CN_TO_SIDE[p];
        } else if (p === '内心' || p === '独白') {
          speaker = `${speaker}(内心)`;
        } else if (CN_TO_EMO[p]) {
          emotion = CN_TO_EMO[p];
        } else if (EMO_TO_CN[p]) {
          emotion = p;
        }
      }
    }

    if (!side) {
      if (charId && lastSideByChar[charId]) {
        side = lastSideByChar[charId];
      } else if (charId && actors[charId]) {
        side = actors[charId].default_side || (charId === 'ye_zhou' ? 'left' : 'right');
      } else {
        side = speaker === '叶舟' ? 'left' : 'right';
      }
    }

    if (charId) lastSideByChar[charId] = side;
    const res = { speaker, char: charId, side, emotion, text };
    if (activeCutscene) res.cutscene = activeCutscene;
    return res;
  }

  function linesToStreamText(lines) {
    const actors = actorLookup();
    const out = [];
    let curCutscene = '';

    for (const line of lines || []) {
      if (line.type === 'directive') {
        const kind = line.kind || '备注';
        const arg = line.arg ?? '';
        out.push(arg !== '' ? `[${kind}: ${arg}]` : `[${kind}]`);
        continue;
      }

      const lineCs = line.cutscene || '';
      if (lineCs !== curCutscene) {
        out.push(`[过场: ${lineCs || '关闭'}]`);
        curCutscene = lineCs;
      }

      const speaker = line.speaker || '旁白';
      const charId = line.char || '';
      const emotion = line.emotion || 'neutral';
      const side = line.side || 'left';
      const text = line.text || '';

      if ((speaker === '旁白' || speaker === '叙述') && !charId) {
        out.push(`旁白: ${text}`);
      } else {
        const defSide = actors[charId]?.default_side || (speaker === '叶舟' ? 'left' : 'right');
        const emoCn = EMO_TO_CN[emotion] || emotion;
        const metaParts = [];
        if (emotion && emotion !== 'neutral') metaParts.push(emoCn);
        if (side !== defSide) metaParts.push(SIDE_TO_CN[side] || side);
        const meta = metaParts.length ? `(${metaParts.join(', ')})` : '';
        out.push(`${speaker}${meta}: ${text}`);
      }

      for (const ch of line.choices || []) {
        const tags = [];
        if (ch.favor_char && ch.favor_add != null) {
          const cname = actors[ch.favor_char]?.name || ch.favor_char;
          tags.push(`[好感: ${cname}+${ch.favor_add}]`);
        }
        if (ch.flag) tags.push(`[标志: ${ch.flag}]`);
        const tagStr = tags.length ? ' ' + tags.join(' ') : '';
        out.push(`? ${ch.text || ''}${tagStr}`);
        for (const sub of ch.follow_up || []) {
          const subTxt = linesToStreamText([sub]);
          for (const sl of subTxt.split('\n')) {
            out.push(`    ${sl}`);
          }
        }
      }
    }
    return out.join('\n');
  }

  // Map a raw row index in stream textarea -> index in parsed lines array
  function mapRawRowToLineIdx(rawText, rawRow) {
    const rows = String(rawText || '').split(/\r?\n/);
    let dialogueIdx = -1;
    let activeChoice = false;
    for (let i = 0; i <= Math.min(rawRow, rows.length - 1); i++) {
      const raw = rows[i];
      const t = raw.trim();
      if (!t) continue;
      const indent = raw.length - raw.trimStart().length;
      if (t.startsWith('[') && t.endsWith(']')) {
        const inner = t.slice(1, -1).trim();
        const kind = inner.split(/[:：]/)[0].trim();
        if (kind === '过场' || kind === 'cutscene') continue;
        dialogueIdx++;
        activeChoice = false;
        continue;
      }
      if (t.startsWith('?') || t.startsWith('- ')) {
        activeChoice = true;
        continue;
      }
      if (indent >= 2 && activeChoice) {
        continue;
      }
      activeChoice = false;
      dialogueIdx++;
    }
    return Math.max(0, dialogueIdx);
  }

  // ==================== Scene Helpers ====================

  function getActiveScene() {
    const list = state.bundle?.categories?.[state.activeCategory] || [];
    return list.find((s) => s.id === state.activeSceneId) || list[0] || null;
  }

  // Returns the editable { lines, setLines, label } target for current scene & subtab
  function getActiveLinesContext() {
    const sc = getActiveScene();
    if (!sc) return null;
    if (sc.target_type === 'campus_life_npc') {
      const cond = sc.conditions?.[state.activeSubTabIdx] || sc.conditions?.[0];
      return cond
        ? {
            kind: 'lines',
            label: cond.condition_label || cond.condition_key,
            lines: cond.lines || [],
            setLines: (newLines) => { cond.lines = newLines; },
          }
        : null;
    }
    if (sc.target_type === 'campus_snippets') {
      const sn = sc.snippets?.[state.activeSubTabIdx] || sc.snippets?.[0];
      return sn
        ? {
            kind: 'lines',
            label: sn.id,
            lines: sn.lines || [],
            setLines: (newLines) => { sn.lines = newLines; },
          }
        : null;
    }
    if (sc.target_type === 'exploration_routes') {
      const v = sc.variants?.[state.activeSubTabIdx] || sc.variants?.[0];
      return v
        ? {
            kind: 'lines',
            label: v.title,
            lines: v.lines || [],
            setLines: (newLines) => { v.lines = newLines; },
          }
        : null;
    }
    if (sc.target_type === 'library_notes') {
      return { kind: 'library_notes', articles: sc.articles || [] };
    }
    if (sc.target_type === 'phase_two_battle_only') {
      return { kind: 'battle_only', scene: sc };
    }
    return {
      kind: 'lines',
      label: sc.title,
      lines: sc.lines || [],
      setLines: (newLines) => { sc.lines = newLines; },
    };
  }

  function autoDetectScenePair(lines) {
    const counts = {};
    for (const l of lines || []) {
      if (l.type === 'directive' || !l.char) continue;
      counts[l.char] = (counts[l.char] || 0) + 1;
    }
    const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).map((x) => x[0]);
    if (sorted.includes('ye_zhou')) {
      state.pairLeft = 'ye_zhou';
      state.pairRight = sorted.find((c) => c !== 'ye_zhou') || 'huang_qiufeng';
    } else if (sorted.length >= 2) {
      state.pairLeft = sorted[0];
      state.pairRight = sorted[1];
    } else if (sorted.length === 1) {
      state.pairLeft = 'ye_zhou';
      state.pairRight = sorted[0] === 'ye_zhou' ? 'huang_qiufeng' : sorted[0];
    }
  }

  function markDirty() {
    state.dirty = true;
    updateConnBadge();
    scheduleLocalAutosave();
  }

  let autosaveTimer = null;
  function scheduleLocalAutosave() {
    clearTimeout(autosaveTimer);
    autosaveTimer = setTimeout(() => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify({
          savedAt: Date.now(),
          bundle: state.bundle,
        }));
      } catch (_) {}
    }, 350);
  }

  function updateConnBadge() {
    if (!els.serverBadge) return;
    if (state.serverOnline) {
      els.serverBadge.className = `conn-pill online${state.dirty ? ' dirty' : ''}`;
      els.serverBadge.textContent = '● 本地服务在线 · 可一键写回游戏';
    } else {
      els.serverBadge.className = `conn-pill offline${state.dirty ? ' dirty' : ''}`;
      els.serverBadge.textContent = '○ 离线模式（自动暂存本地 · 支持导出）';
    }
  }

  // ==================== Left Sidebar Rendering ====================

  function renderSidebar() {
    const prevTreeScroll = els.sceneTree.scrollTop;
    const q = state.searchQuery.trim().toLowerCase();
    const actors = actorLookup();
    const parts = [];

    for (const grp of GROUP_META) {
      const items = state.bundle?.categories?.[grp.key] || [];
      const filtered = items.filter((sc) => {
        if (!q) return true;
        const hay = [
          sc.id,
          sc.node,
          sc.title,
          sc.phase,
          sc.note,
          ...(sc.lines || []).map((l) => `${l.speaker || ''} ${l.text || ''}`),
          ...(sc.conditions || []).flatMap((c) => (c.lines || []).map((l) => `${l.speaker || ''} ${l.text || ''}`)),
          ...(sc.articles || []).map((a) => `${a.title} ${a.body}`),
          ...(sc.variants || []).flatMap((v) => (v.lines || []).map((l) => l.text || '')),
        ].join(' ').toLowerCase();
        return hay.includes(q);
      });

      if (q && filtered.length === 0) continue;
      const collapsed = !q && !!state.collapsedGroups[grp.key];
      parts.push(`<div class="tree-group ${collapsed ? 'collapsed' : ''}" data-group="${grp.key}">`);
      parts.push(`
        <div class="tree-group-header" data-toggle-group="${grp.key}">
          <span>${collapsed ? '▸' : '▾'} ${grp.label}</span>
          <span class="tree-count">${filtered.length}</span>
        </div>
      `);
      parts.push('<div class="tree-items">');
      filtered.forEach((sc, idx) => {
        const isActive = state.activeView === 'scene' && state.activeCategory === grp.key && state.activeSceneId === sc.id;
        let countTag = '';
        if (sc.target_type === 'phase_two_battle_only') {
          countTag = `<span class="badge-mini combat">⚔ ${sc.enemy || '战斗'}</span>`;
        } else if (sc.target_type === 'campus_life_npc') {
          countTag = `<span class="badge-mini">${(sc.conditions || []).length} 条件</span>`;
        } else if (sc.target_type === 'library_notes') {
          countTag = `<span class="badge-mini">${(sc.articles || []).length} 篇</span>`;
        } else if (sc.target_type === 'exploration_routes') {
          countTag = `<span class="badge-mini">${(sc.variants || []).length} 组</span>`;
        } else if (sc.target_type === 'campus_snippets') {
          countTag = `<span class="badge-mini">${(sc.snippets || []).length} 处</span>`;
        } else {
          const dlgCount = (sc.lines || []).filter((l) => l.type !== 'directive').length;
          countTag = `<span class="badge-mini">${dlgCount} 句</span>`;
        }

        const canReorder = grp.key === 'main_active' && !q;
        const reorderHtml = canReorder
          ? `<div class="tree-item-actions">
               <button class="mini-icon-btn" data-move-scene="${sc.id}" data-dir="-1" title="上移">↑</button>
               <button class="mini-icon-btn" data-move-scene="${sc.id}" data-dir="1" title="下移">↓</button>
             </div>`
          : '';

        const enemyMini = sc.enemy && sc.target_type !== 'phase_two_battle_only'
          ? `<span class="badge-mini combat">接战斗</span>`
          : '';

        parts.push(`
          <div class="tree-item ${isActive ? 'active' : ''}" data-select-cat="${grp.key}" data-select-id="${sc.id}">
            <div class="tree-item-main">
              <div class="tree-item-title">${escapeHtml(sc.title || sc.id)}</div>
              <div class="tree-item-sub">
                <span>${escapeHtml(sc.phase || sc.id)}</span>
                ${countTag}
                ${enemyMini}
              </div>
            </div>
            ${reorderHtml}
          </div>
        `);
      });
      parts.push('</div></div>');
    }

    els.sceneTree.innerHTML = parts.join('');
    els.sceneTree.scrollTop = prevTreeScroll;
  }

  function escapeHtml(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  // ==================== Center Editor Rendering ====================

  function renderEditor(options = {}) {
    const preserveScroll = options.preserveScroll !== false;
    const focusLineIdx = options.focusLineIdx ?? null;
    const scrollTargetIntoView = !!options.scrollTargetIntoView;
    const prevCardsScroll = preserveScroll ? ($('cardsFlowWrap')?.scrollTop ?? null) : null;
    const prevStreamScroll = preserveScroll ? ($('streamTextarea')?.scrollTop ?? null) : null;

    if (state.activeView === 'cast_world') {
      renderCastAndWorldView();
      return;
    }

    const sc = getActiveScene();
    if (!sc) {
      els.editorPane.innerHTML = '<div class="special-panel">请从左侧选择一幕剧本，或点击「+ 新建剧情幕」。</div>';
      return;
    }

    const bgs = state.bundle.catalogs.backgrounds || [];
    const cutscenes = state.bundle.catalogs.cutscenes || [];
    const bgms = state.bundle.catalogs.bgm || [];
    const enemies = state.bundle.catalogs.enemies || [];

    const bgOptions = bgs.map((b) => `<option value="${b.id}" ${sc.bg === b.id ? 'selected' : ''}>${escapeHtml(b.label)}</option>`).join('');
    const csOptions = cutscenes.map((c) => `<option value="${c.id}" ${(sc.default_cutscene || '') === c.id ? 'selected' : ''}>${escapeHtml(c.label)}</option>`).join('');
    const bgmOptions = bgms.map((m) => `<option value="${m.id}" ${(sc.bgm || 'bgm_campus_daily') === m.id ? 'selected' : ''}>${escapeHtml(m.label)}</option>`).join('');
    const enemyOptions = `<option value="">无后续战斗</option>` + enemies.map((e) => `<option value="${e.id}" ${(sc.enemy || '') === e.id ? 'selected' : ''}>${escapeHtml(e.name)} (${e.id})</option>`).join('');

    const isDraft = state.activeCategory === 'prologue_oral_drafts' || state.activeCategory === 'chapters_2_to_5';
    const promoteBanner = isDraft
      ? `<div class="draft-promote-banner">
           <span>📌 这是工作草稿区，不影响当前游戏存档；写完后可随时一键合入现行主线。</span>
           <button class="btn btn-xs btn-secondary" id="btnPromoteDraft">⤴ 合入 / 替换现行主线节点</button>
         </div>`
      : '';

    const noteVisible = state.showNoteBanner || (isDraft && !!sc.note);
    const noteBanner = noteVisible
      ? `<div class="scene-note-banner">
           <span>📝 幕备注/逻辑约束:</span>
           <input id="sceneNoteInput" type="text" value="${escapeHtml(sc.note || '')}" placeholder="输入导演备注或剧情注意事项…" />
         </div>`
      : '';

    const headerHtml = `
      <div class="scene-header-bar">
        <div class="scene-header-top">
          <span class="scene-phase-pill">${escapeHtml(sc.phase || state.activeCategory)}</span>
          <input id="sceneTitleInput" class="scene-title-input" type="text" value="${escapeHtml(sc.title || '')}" title="点击直接修改幕名" />
          <span class="scene-id-chip">${escapeHtml(sc.id)}</span>
          <button class="btn btn-xs btn-ghost-soft" id="btnToggleNote">${noteVisible ? '收起备注' : '📝 备注'}</button>
        </div>
        <div class="scene-meta-pills">
          <label class="inline-pill">📍 背景
            <select id="selSceneBg">${bgOptions}</select>
          </label>
          <label class="inline-pill">🎬 过场
            <select id="selSceneCutscene">${csOptions}</select>
          </label>
          <label class="inline-pill">🎵 BGM
            <select id="selSceneBgm">${bgmOptions}</select>
          </label>
          ${(state.activeCategory === 'main_active' || isDraft) ? `
            <label class="inline-pill">⚔️ 接战斗
              <select id="selSceneEnemy">${enemyOptions}</select>
            </label>` : ''}
        </div>
        ${noteBanner}
        ${promoteBanner}
      </div>
    `;

    const ctx = getActiveLinesContext();
    if (!ctx) {
      els.editorPane.innerHTML = headerHtml;
      bindHeaderEvents(sc);
      return;
    }

    if (ctx.kind === 'battle_only') {
      const enemyObj = enemies.find((e) => e.id === sc.enemy);
      els.editorPane.innerHTML = `
        ${headerHtml}
        <div class="special-panel">
          <div class="battle-node-box">
            <h3 style="margin:0;">⚔️ 纯战斗节点：${escapeHtml(sc.title)}</h3>
            <p style="margin:0; color:var(--ink-muted); font-size:13px;">
              游戏推进到节点 <code>${escapeHtml(sc.node)}</code> 时会直接进入以下战斗。
            </p>
            <div class="battle-enemy-preview">
              ${enemyObj?.sprite ? `<img src="${assetUrl(enemyObj.sprite)}" alt="" />` : ''}
              <div>
                <div style="font-weight:700; font-size:15px;">${escapeHtml(enemyObj?.name || sc.enemy)}</div>
                <div style="font-size:12px; color:var(--ink-muted); margin-top:3px;">
                  ID: <code>${escapeHtml(sc.enemy)}</code> · HP: ${enemyObj?.max_hp || '?'} · 阶位: ${enemyObj?.rank || 'NORMAL'}
                </div>
              </div>
            </div>
            <button id="btnConvertBattleToDialogue" class="btn btn-primary">✍️ 为这场战斗添加战前对话台词</button>
          </div>
        </div>
      `;
      bindHeaderEvents(sc);
      $('btnConvertBattleToDialogue')?.addEventListener('click', () => {
        sc.target_type = 'phase_two_flow';
        sc.title = sc.title.replace('（战斗节点）', '');
        sc.briefing_flag = `${sc.node}_briefed`;
        sc.lines = [
          { speaker: '叶舟', char: 'ye_zhou', side: 'left', emotion: 'worried', text: '前方的通道被封锁了——小心迎战！' },
        ];
        markDirty();
        renderSidebar();
        renderEditor({ preserveScroll: false });
        renderPreview();
      });
      return;
    }

    if (ctx.kind === 'library_notes') {
      renderLibraryNotesEditor(headerHtml, sc, ctx.articles);
      bindHeaderEvents(sc);
      return;
    }

    // Subtabs bar if NPC conditions, exploration variants, or snippets
    let subTabsHtml = '';
    if (sc.target_type === 'campus_life_npc') {
      subTabsHtml = `<div class="subtabs-bar">` + (sc.conditions || []).map((c, idx) =>
        `<button class="subtab-btn ${idx === state.activeSubTabIdx ? 'active' : ''}" data-subtab="${idx}">${escapeHtml(c.condition_label || c.condition_key)}</button>`
      ).join('') + `</div>`;
    } else if (sc.target_type === 'exploration_routes') {
      subTabsHtml = `<div class="subtabs-bar">` + (sc.variants || []).map((v, idx) =>
        `<button class="subtab-btn ${idx === state.activeSubTabIdx ? 'active' : ''}" data-subtab="${idx}">#${idx} ${escapeHtml(v.title)}</button>`
      ).join('') + `<button class="subtab-btn" id="btnAddRouteVariant">+ 新增留言组</button></div>`;
    } else if (sc.target_type === 'campus_snippets') {
      subTabsHtml = `<div class="subtabs-bar">` + (sc.snippets || []).map((sn, idx) =>
        `<button class="subtab-btn ${idx === state.activeSubTabIdx ? 'active' : ''}" data-subtab="${idx}">${escapeHtml(sn.id)}</button>`
      ).join('') + `<button class="subtab-btn" id="btnAddSnippet">+ 新增热点</button></div>`;
    }

    // Zero-form Cast & Emotion Pill Bar
    const actors = actorLookup();
    const actorEntries = Object.entries(actors);
    const pairOptsLeft = actorEntries.map(([id, a]) => `<option value="${id}" ${state.pairLeft === id ? 'selected' : ''}>${escapeHtml(a.name)}</option>`).join('');
    const pairOptsRight = actorEntries.map(([id, a]) => `<option value="${id}" ${state.pairRight === id ? 'selected' : ''}>${escapeHtml(a.name)}</option>`).join('');

    const curLine = ctx.lines[Math.min(state.cursorLineIdx, Math.max(0, ctx.lines.length - 1))] || null;
    const curChar = curLine?.char || '';
    const curEmo = curLine?.emotion || 'neutral';
    const curSide = curLine?.side || 'left';
    const isNarrator = !curLine || curLine.type === 'directive' || (curLine.speaker === '旁白' && !curChar);

    const quickActors = actorEntries.slice(0, 9);
    const castChipsHtml = [
      `<button class="actor-chip ${isNarrator && curLine?.type !== 'directive' ? 'active' : ''}" data-quick-char="__narrator__" title="Alt+0 切为旁白">
        <span class="narrator-dot">旁</span><span>旁白</span>
      </button>`,
      ...quickActors.map(([cid, spec], idx) => {
        const av = getActorAvatar(cid, 'neutral');
        return `<button class="actor-chip ${curChar === cid ? 'active' : ''}" data-quick-char="${cid}" title="Alt+${idx + 1} 切换为 ${escapeHtml(spec.name)}">
          ${av.url ? `<img src="${av.url}" alt="" />` : `<span class="narrator-dot">${escapeHtml(spec.name.slice(0, 1))}</span>`}
          <span>${escapeHtml(spec.name)}</span>
        </button>`;
      }),
      `<button class="actor-chip" id="btnInlineAddActor" title="新建一个未入库的角色名"><span>+ 角色</span></button>`,
    ].join('');

    const availEmos = curChar ? getAvailableEmotions(curChar) : [];
    const emoPillsHtml = availEmos.length
      ? availEmos.map((emo) => `<button class="emo-pill ${curEmo === emo ? 'active' : ''}" data-set-emo="${emo}">${escapeHtml(EMO_TO_CN[emo] || emo)}</button>`).join('')
      : `<span style="font-size:11.5px; color:var(--ink-muted);">选择角色行后可一键切换表情</span>`;

    const sideToggleHtml = curChar
      ? `<button class="emo-pill" id="btnToggleLineSide" title="切换该句立绘站位">站位: ${curSide === 'left' ? '◀ 左' : '右 ▶'}</button>`
      : '';

    const castToolbarHtml = `
      <div class="cast-toolbar">
        <div class="cast-row">
          <span class="row-tag">同台搭档:</span>
          <label class="pair-box">左 <select id="selPairLeft">${pairOptsLeft}</select></label>
          <span style="color:var(--ink-muted); font-size:11px;">⇄</span>
          <label class="pair-box">右 <select id="selPairRight">${pairOptsRight}</select></label>
          <button id="btnAutoAlt" class="toggle-pill ${state.autoAlternate ? 'active' : ''}" title="开启后敲回车自动带出另一位角色名，像聊天一样写剧本">⏎ 回车自动换人: ${state.autoAlternate ? '开' : '关'}</button>
          <span style="margin-left:auto; font-size:11px; color:var(--ink-muted);">按 Tab 秒切角色</span>
        </div>
        <div class="cast-row">
          <span class="row-tag">点选换人:</span>
          <div class="cast-chips">${castChipsHtml}</div>
        </div>
        <div class="cast-row" id="emotionControlRow">
          <span class="row-tag">当前行:</span>
          ${emoPillsHtml}
          ${sideToggleHtml}
          <span style="margin-left:auto; display:flex; gap:4px; flex-wrap:wrap;">
            <button class="directive-pill" data-insert-dir="choice">+ 选项(?)</button>
            <button class="directive-pill" data-insert-dir="cutscene">+ 视差过场</button>
            <button class="directive-pill" data-insert-dir="sfx">+ SFX音效</button>
            <button class="directive-pill" data-insert-dir="bg">+ 切背景</button>
            <button class="directive-pill" data-insert-dir="note">+ 导演备注</button>
          </span>
        </div>
      </div>
    `;

    const modeBarHtml = `
      <div class="editor-mode-bar">
        <div class="mode-tabs">
          <button class="mode-tab ${state.editorMode === 'stream' ? 'active' : ''}" data-mode="stream">✍️ 流式剧本连写（推荐）</button>
          <button class="mode-tab ${state.editorMode === 'cards' ? 'active' : ''}" data-mode="cards">💬 气泡卡片流</button>
        </div>
        <div id="cursorStatusText" class="cursor-status">
          共 ${ctx.lines.filter((l) => l.type !== 'directive').length} 句对白 · 当前第 ${Math.min(state.cursorLineIdx + 1, Math.max(1, ctx.lines.length))} 行
        </div>
      </div>
    `;

    let bodyHtml = '';
    if (state.editorMode === 'stream') {
      const streamVal = linesToStreamText(ctx.lines);
      const rowCount = Math.max(1, streamVal.split('\n').length);
      const gutterRows = Array.from({ length: rowCount }, (_, i) =>
        `<div class="g-row ${i === state.cursorRawRow ? 'current' : ''}">${i + 1}</div>`
      ).join('');
      bodyHtml = `
        <div class="editor-body">
          <div class="stream-pad-wrap">
            <div class="stream-gutter" id="streamGutter">${gutterRows}</div>
            <textarea id="streamTextarea" class="stream-textarea" spellcheck="false" placeholder="直接按「角色名: 台词」连写，例如：&#10;叶舟: 早安，今天天气真好。&#10;黄秋枫(微笑): 早安，叶舟。">${escapeHtml(streamVal)}</textarea>
          </div>
        </div>
      `;
    } else {
      bodyHtml = `
        <div class="editor-body">
          <div class="cards-flow-wrap" id="cardsFlowWrap">
            ${renderCardsFlow(ctx.lines)}
          </div>
        </div>
      `;
    }

    els.editorPane.innerHTML = headerHtml + subTabsHtml + castToolbarHtml + modeBarHtml + bodyHtml;
    bindHeaderEvents(sc);
    bindSubTabEvents(sc);
    bindToolbarAndEditorEvents(sc, ctx);

    const cardsWrap = $('cardsFlowWrap');
    if (cardsWrap && prevCardsScroll !== null) {
      cardsWrap.scrollTop = prevCardsScroll;
    }
    const streamTa = $('streamTextarea');
    const streamGutter = $('streamGutter');
    if (streamTa && prevStreamScroll !== null) {
      streamTa.scrollTop = prevStreamScroll;
      if (streamGutter) streamGutter.scrollTop = prevStreamScroll;
    }
    if (cardsWrap && scrollTargetIntoView) {
      const targetCard = cardsWrap.querySelector(`[data-card-idx="${state.cursorLineIdx}"]`);
      if (targetCard) targetCard.scrollIntoView({ block: 'nearest' });
    }
    if (focusLineIdx !== null) {
      const targetTa = els.editorPane.querySelector(`[data-card-text="${focusLineIdx}"]`);
      if (targetTa) {
        targetTa.focus({ preventScroll: true });
        targetTa.scrollIntoView({ block: 'nearest' });
      }
    }
  }

  function renderCardsFlow(lines) {
    const actors = actorLookup();
    if (!lines.length) {
      return `<div style="padding:20px; text-align:center; color:var(--ink-muted);">
        本幕暂无台词。<button class="btn btn-sm btn-primary-soft" id="btnAddFirstCardLine">+ 添加第一句</button>
      </div>`;
    }
    return lines.map((line, idx) => {
      const isActive = idx === state.cursorLineIdx;
      if (line.type === 'directive') {
        return `
          <div class="line-card directive-card ${isActive ? 'active' : ''}" data-card-idx="${idx}">
            <div class="line-card-top">
              <span class="badge-mini">🎬 指令: ${escapeHtml(line.kind || '备注')}</span>
              <input class="card-dir-arg" data-card-dir-idx="${idx}" type="text" value="${escapeHtml(line.arg || '')}" style="flex:1; border:1px solid var(--border); background:var(--surface); color:var(--ink); border-radius:6px; padding:3px 8px; font-size:12.5px;" />
              <div class="line-card-tools">
                <button class="mini-icon-btn" data-card-move="${idx}" data-dir="-1">↑</button>
                <button class="mini-icon-btn" data-card-move="${idx}" data-dir="1">↓</button>
                <button class="mini-icon-btn" data-card-del="${idx}">×</button>
              </div>
            </div>
          </div>
        `;
      }

      const av = line.char ? getActorAvatar(line.char, line.emotion || 'neutral') : { url: '' };
      const actorOpts = `<option value="__narrator__" ${!line.char ? 'selected' : ''}>旁白</option>` +
        Object.entries(actors).map(([cid, spec]) =>
          `<option value="${cid}" ${line.char === cid ? 'selected' : ''}>${escapeHtml(spec.name)}</option>`
        ).join('');
      const emoList = line.char ? getAvailableEmotions(line.char) : ['neutral'];
      const emoOpts = emoList.map((e) => `<option value="${e}" ${(line.emotion || 'neutral') === e ? 'selected' : ''}>${escapeHtml(EMO_TO_CN[e] || e)}</option>`).join('');
      const csOpts = (state.bundle.catalogs.cutscenes || []).map((c) =>
        `<option value="${c.id}" ${(line.cutscene || '') === c.id ? 'selected' : ''}>${c.id ? '过场: ' + c.id : '无逐句过场'}</option>`
      ).join('');

      const choicesHtml = (line.choices || []).map((ch, cIdx) => {
        const favorOpts = `<option value="">无好感</option>` + Object.entries(actors)
          .filter(([cid]) => ['yang_zi_ying', 'liu_yu_long', 'jiang_zi', 'huang_qiufeng'].includes(cid) || !actors[cid].builtin)
          .map(([cid, spec]) => `<option value="${cid}" ${ch.favor_char === cid ? 'selected' : ''}>${escapeHtml(spec.name)}</option>`).join('');
        return `
          <div class="choice-row">
            <span style="font-size:11px; font-weight:700; color:var(--teal);">? 选项</span>
            <input type="text" data-choice-text="${idx}:${cIdx}" value="${escapeHtml(ch.text || '')}" placeholder="选项文字…" />
            <select data-choice-char="${idx}:${cIdx}">${favorOpts}</select>
            <input class="num" type="number" data-choice-add="${idx}:${cIdx}" value="${ch.favor_add ?? 5}" title="好感增幅" />
            <button class="mini-icon-btn" data-choice-del="${idx}:${cIdx}">×</button>
          </div>
        `;
      }).join('');

      return `
        <div class="line-card ${isActive ? 'active' : ''}" data-card-idx="${idx}">
          <div class="line-card-top">
            ${av.url ? `<img class="line-avatar" src="${av.url}" alt="" />` : `<span class="narrator-dot" style="width:28px;height:28px;border-radius:50%;display:grid;place-items:center;background:var(--surface-alt);font-size:11px;font-weight:700;">旁</span>`}
            <select class="card-sel" data-card-char="${idx}">${actorOpts}</select>
            ${line.char ? `
              <select class="card-sel" data-card-emo="${idx}">${emoOpts}</select>
              <button class="mini-icon-btn" data-card-side="${idx}">${line.side === 'left' ? '◀ 左' : '右 ▶'}</button>
            ` : ''}
            <select class="card-sel" data-card-cs="${idx}" style="max-width:130px;">${csOpts}</select>
            <div class="line-card-tools">
              <button class="mini-icon-btn" data-card-add-choice="${idx}" title="添加分支选项">+?</button>
              <button class="mini-icon-btn" data-card-insert="${idx}" title="在下方插入新句">+句</button>
              <button class="mini-icon-btn" data-card-move="${idx}" data-dir="-1">↑</button>
              <button class="mini-icon-btn" data-card-move="${idx}" data-dir="1">↓</button>
              <button class="mini-icon-btn" data-card-del="${idx}">×</button>
            </div>
          </div>
          <textarea class="card-text" data-card-text="${idx}" rows="2" placeholder="输入台词（按 Enter 直接新增下一句）…">${escapeHtml(line.text || '')}</textarea>
          ${choicesHtml ? `<div class="choice-sublist">${choicesHtml}</div>` : ''}
        </div>
      `;
    }).join('');
  }

  function renderLibraryNotesEditor(headerHtml, sc, articles) {
    const idx = Math.min(state.activeSubTabIdx, Math.max(0, articles.length - 1));
    const art = articles[idx] || { id: '', title: '', body: '' };
    const listHtml = articles.map((a, i) => `
      <div class="note-list-item ${i === idx ? 'active' : ''}" data-note-idx="${i}">
        <div>${escapeHtml(a.title || a.id)}</div>
        <div style="font-size:11px; color:var(--ink-muted); margin-top:2px;">${escapeHtml(a.id)}</div>
      </div>
    `).join('');

    els.editorPane.innerHTML = `
      ${headerHtml}
      <div class="special-panel">
        <div class="notes-grid">
          <div class="notes-list">
            ${listHtml}
            <button id="btnAddLibraryNote" class="btn btn-sm btn-primary-soft" style="margin-top:6px;">+ 新增风物纪要</button>
          </div>
          <div class="note-editor-card">
            <label style="font-size:12px; font-weight:700;">纪要标题</label>
            <input id="noteTitleInput" type="text" value="${escapeHtml(art.title || '')}" />
            <label style="font-size:12px; font-weight:700;">正文内容（将在图书馆阅读与放映档案室呈现）</label>
            <textarea id="noteBodyInput">${escapeHtml(art.body || '')}</textarea>
            <div style="display:flex; justify-content:space-between; align-items:center; font-size:12px; color:var(--ink-muted);">
              <span>ID: <code>${escapeHtml(art.id)}</code> · 当前字数: ${(art.body || '').length} 字</span>
              ${articles.length > 1 ? `<button id="btnDelLibraryNote" class="btn btn-xs btn-ghost-soft">删除此篇</button>` : ''}
            </div>
          </div>
        </div>
      </div>
    `;

    els.editorPane.querySelectorAll('[data-note-idx]').forEach((el) => {
      el.addEventListener('click', () => {
        state.activeSubTabIdx = Number(el.dataset.noteIdx);
        renderEditor();
        renderPreview();
      });
    });
    $('noteTitleInput')?.addEventListener('input', (e) => {
      art.title = e.target.value;
      markDirty();
      renderPreview();
      const item = els.editorPane.querySelector(`[data-note-idx="${idx}"] div`);
      if (item) item.textContent = art.title || art.id;
    });
    $('noteBodyInput')?.addEventListener('input', (e) => {
      art.body = e.target.value;
      markDirty();
      renderPreview();
    });
    $('btnAddLibraryNote')?.addEventListener('click', () => {
      const nextNum = articles.length + 1;
      articles.push({
        id: `note_custom_${Date.now().toString(36)}`,
        title: `纪要 ${String(nextNum).padStart(2, '0')} · 新风物笔记`,
        body: '在这里填写新的校园或地区风物笔记正文……',
      });
      state.activeSubTabIdx = articles.length - 1;
      markDirty();
      renderSidebar();
      renderEditor();
      renderPreview();
    });
    $('btnDelLibraryNote')?.addEventListener('click', () => {
      articles.splice(idx, 1);
      state.activeSubTabIdx = Math.max(0, idx - 1);
      markDirty();
      renderSidebar();
      renderEditor();
      renderPreview();
    });
  }

  function renderCastAndWorldView() {
    const actors = actorLookup();
    const zodiacs = state.bundle?.world_reference?.zodiac_cards || [];

    const castCards = Object.entries(actors).map(([cid, spec]) => {
      const av = getActorAvatar(cid, 'neutral');
      const emos = getAvailableEmotions(cid).map((e) => EMO_TO_CN[e] || e).join(' / ') || '纯字幕';
      return `
        <div class="cast-card">
          ${av.url ? `<img src="${av.url}" alt="" />` : `<div style="width:48px;height:48px;border-radius:50%;background:var(--surface-alt);display:grid;place-items:center;font-weight:700;">${escapeHtml(spec.name.slice(0, 1))}</div>`}
          <div style="min-width:0; flex:1;">
            <div style="font-weight:700; font-size:14px;">${escapeHtml(spec.name)} <span style="font-size:11px;color:var(--ink-muted);font-weight:400;">(${escapeHtml(cid)})</span></div>
            <div style="font-size:11.5px; color:var(--teal); margin:2px 0;">${escapeHtml(spec.title || '自定义角色')} · 默认${spec.default_side === 'left' ? '左侧' : '右侧'}</div>
            <div style="font-size:11.5px; color:var(--ink-muted); line-height:1.45;">${escapeHtml(spec.bio || '')}</div>
            <div style="font-size:11px; color:var(--ink-muted); margin-top:4px;">可用表情: ${escapeHtml(emos)}</div>
          </div>
        </div>
      `;
    }).join('');

    const zodiacHtml = zodiacs.map((z) => `
      <div class="zodiac-card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
          <strong style="font-size:13.5px;">#${String(z.number).padStart(2, '0')} ${escapeHtml(z.name)} · ${escapeHtml(z.archetype)}</strong>
          <span class="badge-mini">${escapeHtml(z.power)}</span>
        </div>
        <div style="color:var(--ink); margin-bottom:3px;"><strong>能力：</strong>${escapeHtml(z.ability)}</div>
        <div style="color:var(--ink-muted); margin-bottom:3px;"><strong>限制：</strong>${escapeHtml(z.limits)}</div>
        <div style="color:var(--amber);"><strong>规则交互：</strong>${escapeHtml(z.interactions)}</div>
      </div>
    `).join('');

    els.editorPane.innerHTML = `
      <div class="scene-header-bar">
        <div class="scene-header-top">
          <span class="scene-phase-pill">世界观设定速查 & 角色库</span>
          <span style="font-size:16px; font-weight:700; font-family:'IGANotoSerif',serif;">角色立绘与十二星座母卡规则</span>
          <button id="btnAddCustomActor" class="btn btn-sm btn-primary" style="margin-left:auto;">+ 新增自定义角色</button>
        </div>
      </div>
      <div class="special-panel">
        <div>
          <h3 style="margin:0 0 8px;">🎭 已登记角色（写剧本时直接写「角色名: 台词」即可自动匹配）</h3>
          <div class="cast-grid">${castCards}</div>
        </div>
        <div>
          <h3 style="margin:8px 0;">✨ 十二星座母卡设定（写作 2–5 章参考，遵循不私改设定边界）</h3>
          <div class="zodiac-grid">${zodiacHtml}</div>
        </div>
      </div>
    `;

    $('btnAddCustomActor')?.addEventListener('click', openNewActorModal);
  }

  // ==================== Event Binding ====================

  function bindHeaderEvents(sc) {
    $('sceneTitleInput')?.addEventListener('input', (e) => {
      sc.title = e.target.value;
      markDirty();
      renderSidebar();
      renderPreview();
    });
    $('selSceneBg')?.addEventListener('change', (e) => {
      sc.bg = e.target.value;
      markDirty();
      renderPreview();
    });
    $('selSceneCutscene')?.addEventListener('change', (e) => {
      sc.default_cutscene = e.target.value;
      markDirty();
      renderPreview();
    });
    $('selSceneBgm')?.addEventListener('change', (e) => {
      sc.bgm = e.target.value;
      markDirty();
    });
    $('selSceneEnemy')?.addEventListener('change', (e) => {
      sc.enemy = e.target.value;
      markDirty();
      renderSidebar();
    });
    $('btnToggleNote')?.addEventListener('click', () => {
      state.showNoteBanner = !state.showNoteBanner;
      renderEditor();
    });
    $('sceneNoteInput')?.addEventListener('input', (e) => {
      sc.note = e.target.value;
      markDirty();
    });
    $('btnPromoteDraft')?.addEventListener('click', () => openPromoteModal(sc));
  }

  function bindSubTabEvents(sc) {
    els.editorPane.querySelectorAll('[data-subtab]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.activeSubTabIdx = Number(btn.dataset.subtab);
        state.cursorLineIdx = 0;
        state.cursorRawRow = 0;
        renderEditor();
        renderPreview();
      });
    });
    $('btnAddRouteVariant')?.addEventListener('click', () => {
      sc.variants.push({
        index: sc.variants.length,
        title: `随机校园微故事 #${sc.variants.length}`,
        lines: [{ speaker: '叶舟', char: 'ye_zhou', side: 'left', emotion: 'neutral', text: '发现了一张夹在长椅缝里的新便笺。' }],
      });
      state.activeSubTabIdx = sc.variants.length - 1;
      markDirty();
      renderSidebar();
      renderEditor();
      renderPreview();
    });
    $('btnAddSnippet')?.addEventListener('click', () => {
      const sid = window.prompt('请输入新调查热点的英文 ID（如 library_window）：', `hotspot_${Date.now().toString(36)}`);
      if (!sid) return;
      sc.snippets.push({
        id: sid.trim(),
        lines: [{ speaker: '我', char: 'ye_zhou', side: 'left', emotion: 'neutral', text: '这里似乎留着什么有意思的小物件。' }],
      });
      state.activeSubTabIdx = sc.snippets.length - 1;
      markDirty();
      renderSidebar();
      renderEditor();
      renderPreview();
    });
  }

  function bindToolbarAndEditorEvents(sc, ctx) {
    $('selPairLeft')?.addEventListener('change', (e) => { state.pairLeft = e.target.value; });
    $('selPairRight')?.addEventListener('change', (e) => { state.pairRight = e.target.value; });
    $('btnAutoAlt')?.addEventListener('click', () => {
      state.autoAlternate = !state.autoAlternate;
      renderEditor();
    });
    $('btnInlineAddActor')?.addEventListener('click', openNewActorModal);

    els.editorPane.querySelectorAll('[data-mode]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.editorMode = btn.dataset.mode;
        renderEditor();
        renderPreview();
      });
    });

    // Quick speaker chips
    els.editorPane.querySelectorAll('[data-quick-char]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const cid = btn.dataset.quickChar;
        applyQuickSpeaker(ctx, cid === '__narrator__' ? '' : cid);
      });
    });

    // Quick emotion pills
    els.editorPane.querySelectorAll('[data-set-emo]').forEach((btn) => {
      btn.addEventListener('click', () => {
        applyQuickEmotion(ctx, btn.dataset.setEmo);
      });
    });

    $('btnToggleLineSide')?.addEventListener('click', () => toggleCurrentLineSide(ctx));

    // Quick directives
    els.editorPane.querySelectorAll('[data-insert-dir]').forEach((btn) => {
      btn.addEventListener('click', () => openDirectiveQuickInsert(ctx, btn.dataset.insertDir));
    });

    if (state.editorMode === 'stream') {
      const ta = $('streamTextarea');
      const gutter = $('streamGutter');
      if (!ta) return;

      const syncScroll = () => {
        if (gutter) gutter.scrollTop = ta.scrollTop;
      };
      ta.addEventListener('scroll', syncScroll);

      const handleCursorUpdate = () => {
        const pos = ta.selectionStart || 0;
        const before = ta.value.slice(0, pos);
        const row = before.split('\n').length - 1;
        state.cursorRawRow = row;
        state.cursorLineIdx = mapRawRowToLineIdx(ta.value, row);
        updateGutterHighlight(row);
        updateCursorToolbarAndPreview(ctx);
      };

      ta.addEventListener('click', handleCursorUpdate);
      ta.addEventListener('keyup', (e) => {
        if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(e.key)) {
          handleCursorUpdate();
        }
      });

      ta.addEventListener('input', () => {
        const parsed = parseStreamText(ta.value);
        ctx.setLines(parsed);
        markDirty();
        const pos = ta.selectionStart || 0;
        state.cursorRawRow = ta.value.slice(0, pos).split('\n').length - 1;
        state.cursorLineIdx = mapRawRowToLineIdx(ta.value, state.cursorRawRow);
        rebuildGutter(ta.value);
        updateCursorToolbarAndPreview(ctx);
        // Update left tree line count badge smoothly
        const activeCountEl = els.sceneTree.querySelector('.tree-item.active .badge-mini');
        if (activeCountEl && sc.target_type !== 'campus_life_npc' && sc.target_type !== 'exploration_routes' && sc.target_type !== 'campus_snippets') {
          activeCountEl.textContent = `${parsed.filter((l) => l.type !== 'directive').length} 句`;
        }
      });

      ta.addEventListener('keydown', (e) => {
        // Ctrl+Enter -> insert choice
        if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
          e.preventDefault();
          insertAtLineEnd(ta, '\n? 选项文字 [好感: 杨子英+5]', 3, 7);
          ta.dispatchEvent(new Event('input'));
          return;
        }

        // Enter with autoAlternate
        if (e.key === 'Enter' && !e.shiftKey && !e.ctrlKey && !e.altKey && state.autoAlternate) {
          const pos = ta.selectionStart;
          const endPos = ta.selectionEnd;
          if (pos === endPos) {
            const val = ta.value;
            const lineStart = val.lastIndexOf('\n', pos - 1) + 1;
            const lineEndIdx = val.indexOf('\n', pos);
            const lineEnd = lineEndIdx === -1 ? val.length : lineEndIdx;
            const curRow = val.slice(lineStart, lineEnd);
            // Only trigger at end of current row
            if (pos === lineEnd) {
              const actors = actorLookup();
              const leftName = actors[state.pairLeft]?.name || '叶舟';
              const rightName = actors[state.pairRight]?.name || '黄秋枫';
              const trimmed = curRow.trim();

              // If user hit Enter on an empty "角色: " prefix, clear prefix cleanly
              if (/^[^:：]+[:：]\s*$/.test(trimmed)) {
                e.preventDefault();
                ta.value = val.slice(0, lineStart) + val.slice(lineEnd);
                ta.selectionStart = ta.selectionEnd = lineStart;
                ta.dispatchEvent(new Event('input'));
                return;
              }

              const m = trimmed.match(/^([^:：(（]+)(?:[(（][^）)]*[)）])?\s*[:：]\s*(.+)$/);
              if (m) {
                const sp = m[1].trim();
                let nextName = '';
                if (sp === leftName) nextName = rightName;
                else if (sp === rightName) nextName = leftName;
                else if (sp !== '旁白' && sp !== '叙述') nextName = leftName;

                if (nextName) {
                  e.preventDefault();
                  const ins = `\n${nextName}: `;
                  ta.value = val.slice(0, pos) + ins + val.slice(pos);
                  ta.selectionStart = ta.selectionEnd = pos + ins.length;
                  ta.dispatchEvent(new Event('input'));
                  return;
                }
              }
            }
          }
        }

        // Tab -> cycle speaker on current line
        if (e.key === 'Tab') {
          e.preventDefault();
          cycleCurrentRawLineSpeaker(ta, ctx);
          return;
        }

        // Alt+0..9 -> instant speaker switch
        if (e.altKey && /^[0-9]$/.test(e.key)) {
          e.preventDefault();
          const num = parseInt(e.key, 10);
          if (num === 0) {
            applyQuickSpeaker(ctx, '');
          } else {
            const entries = Object.keys(actorLookup());
            if (entries[num - 1]) applyQuickSpeaker(ctx, entries[num - 1]);
          }
        }
      });
    } else {
      bindCardsFlowEvents(ctx);
    }
  }

  function rebuildGutter(rawText) {
    const gutter = $('streamGutter');
    if (!gutter) return;
    const count = Math.max(1, String(rawText || '').split('\n').length);
    gutter.innerHTML = Array.from({ length: count }, (_, i) =>
      `<div class="g-row ${i === state.cursorRawRow ? 'current' : ''}">${i + 1}</div>`
    ).join('');
  }

  function updateGutterHighlight(row) {
    const gutter = $('streamGutter');
    if (!gutter) return;
    gutter.querySelectorAll('.g-row.current').forEach((el) => el.classList.remove('current'));
    const target = gutter.children[row];
    if (target) target.classList.add('current');
  }

  function updateCursorToolbarAndPreview(ctx) {
    const status = $('cursorStatusText');
    const lines = ctx.lines || [];
    const dlgCount = lines.filter((l) => l.type !== 'directive').length;
    if (status) {
      status.textContent = `共 ${dlgCount} 句对白 · 当前第 ${Math.min(state.cursorLineIdx + 1, Math.max(1, lines.length))} 行`;
    }
    const curLine = lines[Math.min(state.cursorLineIdx, Math.max(0, lines.length - 1))];
    // Update quick-char & emotion row without destroying textarea focus/scroll
    const curChar = curLine?.char || '';
    const curEmo = curLine?.emotion || 'neutral';
    const curSide = curLine?.side || 'left';
    const isNarr = !curLine || curLine.type === 'directive' || (curLine.speaker === '旁白' && !curChar);
    els.editorPane.querySelectorAll('[data-quick-char]').forEach((btn) => {
      const target = btn.dataset.quickChar;
      const active = target === '__narrator__' ? (isNarr && curLine?.type !== 'directive') : (curChar === target);
      btn.classList.toggle('active', active);
    });
    const emoRow = $('emotionControlRow');
    if (emoRow) {
      const availEmos = curChar ? getAvailableEmotions(curChar) : [];
      const emoPillsHtml = availEmos.length
        ? availEmos.map((emo) => `<button class="emo-pill ${curEmo === emo ? 'active' : ''}" data-set-emo="${emo}">${escapeHtml(EMO_TO_CN[emo] || emo)}</button>`).join('')
        : `<span style="font-size:11.5px; color:var(--ink-muted);">选择角色行后可一键切换表情</span>`;
      const sideToggleHtml = curChar
        ? `<button class="emo-pill" id="btnToggleLineSide" title="切换该句立绘站位">站位: ${curSide === 'left' ? '◀ 左' : '右 ▶'}</button>`
        : '';
      emoRow.innerHTML = `
        <span class="row-tag">当前行:</span>
        ${emoPillsHtml}
        ${sideToggleHtml}
        <span style="margin-left:auto; display:flex; gap:4px; flex-wrap:wrap;">
          <button class="directive-pill" data-insert-dir="choice">+ 选项(?)</button>
          <button class="directive-pill" data-insert-dir="cutscene">+ 视差过场</button>
          <button class="directive-pill" data-insert-dir="sfx">+ SFX音效</button>
          <button class="directive-pill" data-insert-dir="bg">+ 切背景</button>
          <button class="directive-pill" data-insert-dir="note">+ 导演备注</button>
        </span>
      `;
      emoRow.querySelectorAll('[data-set-emo]').forEach((btn) => {
        btn.addEventListener('click', () => applyQuickEmotion(ctx, btn.dataset.setEmo));
      });
      $('btnToggleLineSide')?.addEventListener('click', () => toggleCurrentLineSide(ctx));
      emoRow.querySelectorAll('[data-insert-dir]').forEach((btn) => {
        btn.addEventListener('click', () => openDirectiveQuickInsert(ctx, btn.dataset.insertDir));
      });
    }
    renderPreview();
  }

  function insertAtLineEnd(ta, text, selectFromOffset = null, selectToOffset = null) {
    const pos = ta.selectionStart || 0;
    const val = ta.value;
    const lineEndIdx = val.indexOf('\n', pos);
    const lineEnd = lineEndIdx === -1 ? val.length : lineEndIdx;
    ta.value = val.slice(0, lineEnd) + text + val.slice(lineEnd);
    if (selectFromOffset !== null) {
      ta.selectionStart = lineEnd + selectFromOffset;
      ta.selectionEnd = lineEnd + selectToOffset;
    } else {
      ta.selectionStart = ta.selectionEnd = lineEnd + text.length;
    }
    ta.focus();
  }

  function replaceCurrentRawLinePrefix(ta, replacerFn) {
    const pos = ta.selectionStart || 0;
    const val = ta.value;
    const lineStart = val.lastIndexOf('\n', pos - 1) + 1;
    const lineEndIdx = val.indexOf('\n', pos);
    const lineEnd = lineEndIdx === -1 ? val.length : lineEndIdx;
    const rawLine = val.slice(lineStart, lineEnd);
    const newLine = replacerFn(rawLine);
    ta.value = val.slice(0, lineStart) + newLine + val.slice(lineEnd);
    ta.selectionStart = ta.selectionEnd = lineStart + newLine.length;
    ta.focus();
    ta.dispatchEvent(new Event('input'));
  }

  function cycleCurrentRawLineSpeaker(ta, ctx) {
    const actors = actorLookup();
    const cycle = [
      actors[state.pairLeft]?.name || '叶舟',
      actors[state.pairRight]?.name || '黄秋枫',
      '旁白',
    ];
    replaceCurrentRawLinePrefix(ta, (rawLine) => {
      const m = rawLine.match(/^([^:：(（]+)(\([^)]*\))?\s*[:：]\s*(.*)$/);
      if (!m) return `${cycle[0]}: ${rawLine.trim()}`;
      const sp = m[1].trim();
      const idx = cycle.indexOf(sp);
      const next = cycle[(idx + 1) % cycle.length];
      if (next === '旁白') return `旁白: ${m[3]}`;
      return `${next}${m[2] || ''}: ${m[3]}`;
    });
  }

  function applyQuickSpeaker(ctx, charId) {
    const actors = actorLookup();
    const nextName = charId ? (actors[charId]?.name || charId) : '旁白';

    if (state.editorMode === 'stream') {
      const ta = $('streamTextarea');
      if (!ta) return;
      replaceCurrentRawLinePrefix(ta, (rawLine) => {
        const t = rawLine.trim();
        if (!t) return `${nextName}: `;
        if (t.startsWith('[') || t.startsWith('?')) return `${rawLine}\n${nextName}: `;
        const m = rawLine.match(/^([^:：(（]+)(?:[(（]([^)）]*)[)）])?\s*[:：]\s*(.*)$/);
        if (!m) return `${nextName}: ${t}`;
        if (!charId) return `旁白: ${m[3]}`;
        return `${nextName}${m[2] ? `(${m[2]})` : ''}: ${m[3]}`;
      });
    } else {
      const line = ctx.lines[state.cursorLineIdx];
      if (!line || line.type === 'directive') return;
      line.char = charId;
      line.speaker = nextName;
      line.side = charId ? (actors[charId]?.default_side || 'right') : 'left';
      markDirty();
      renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
      renderPreview();
    }
  }

  function applyQuickEmotion(ctx, emoId) {
    const emoCn = EMO_TO_CN[emoId] || emoId;
    if (state.editorMode === 'stream') {
      const ta = $('streamTextarea');
      if (!ta) return;
      replaceCurrentRawLinePrefix(ta, (rawLine) => {
        const m = rawLine.match(/^([^:：(（]+)(?:[(（]([^)）]*)[)）])?\s*[:：]\s*(.*)$/);
        if (!m) return rawLine;
        const sp = m[1].trim();
        if (sp === '旁白' || sp === '叙述') return rawLine;
        const sideParts = (m[2] || '').split(/[,，/|]/).map((x) => x.trim()).filter((x) => CN_TO_SIDE[x]);
        const newParts = [];
        if (emoId !== 'neutral') newParts.push(emoCn);
        if (sideParts.length) newParts.push(sideParts[0]);
        const meta = newParts.length ? `(${newParts.join(', ')})` : '';
        return `${sp}${meta}: ${m[3]}`;
      });
    } else {
      const line = ctx.lines[state.cursorLineIdx];
      if (!line || line.type === 'directive') return;
      line.emotion = emoId;
      markDirty();
      renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
      renderPreview();
    }
  }

  function toggleCurrentLineSide(ctx) {
    if (state.editorMode === 'stream') {
      const ta = $('streamTextarea');
      if (!ta) return;
      const line = ctx.lines[state.cursorLineIdx];
      const nextSide = line?.side === 'left' ? '右' : '左';
      replaceCurrentRawLinePrefix(ta, (rawLine) => {
        const m = rawLine.match(/^([^:：(（]+)(?:[(（]([^)）]*)[)）])?\s*[:：]\s*(.*)$/);
        if (!m) return rawLine;
        const parts = (m[2] || '').split(/[,，/|]/).map((x) => x.trim()).filter((x) => x && !CN_TO_SIDE[x]);
        parts.push(nextSide);
        return `${m[1].trim()}(${parts.join(', ')}): ${m[3]}`;
      });
    } else {
      const line = ctx.lines[state.cursorLineIdx];
      if (!line || line.type === 'directive') return;
      line.side = line.side === 'left' ? 'right' : 'left';
      markDirty();
      renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
      renderPreview();
    }
  }

  function bindCardsFlowEvents(ctx) {
    $('btnAddFirstCardLine')?.addEventListener('click', () => {
      const actors = actorLookup();
      ctx.lines.push({ speaker: actors[state.pairLeft]?.name || '叶舟', char: state.pairLeft, side: 'left', emotion: 'neutral', text: '' });
      state.cursorLineIdx = 0;
      markDirty();
      renderEditor();
      renderPreview();
    });

    els.editorPane.querySelectorAll('[data-card-idx]').forEach((card) => {
      card.addEventListener('mousedown', (e) => {
        if (e.target.closest('button, select')) return;
        const idx = Number(card.dataset.cardIdx);
        if (state.cursorLineIdx !== idx) {
          state.cursorLineIdx = idx;
          els.editorPane.querySelectorAll('.line-card.active').forEach((c) => c.classList.remove('active'));
          card.classList.add('active');
          updateCursorToolbarAndPreview(ctx);
        }
      });
    });

    els.editorPane.querySelectorAll('[data-card-char]').forEach((sel) => {
      sel.addEventListener('change', () => {
        const idx = Number(sel.dataset.cardChar);
        const line = ctx.lines[idx];
        const cid = sel.value === '__narrator__' ? '' : sel.value;
        const actors = actorLookup();
        line.char = cid;
        line.speaker = cid ? (actors[cid]?.name || cid) : '旁白';
        line.side = cid ? (actors[cid]?.default_side || 'right') : 'left';
        line.emotion = 'neutral';
        state.cursorLineIdx = idx;
        markDirty();
        renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-emo]').forEach((sel) => {
      sel.addEventListener('change', () => {
        const idx = Number(sel.dataset.cardEmo);
        ctx.lines[idx].emotion = sel.value;
        state.cursorLineIdx = idx;
        markDirty();
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-side]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const idx = Number(btn.dataset.cardSide);
        const line = ctx.lines[idx];
        line.side = line.side === 'left' ? 'right' : 'left';
        state.cursorLineIdx = idx;
        markDirty();
        renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-cs]').forEach((sel) => {
      sel.addEventListener('change', () => {
        const idx = Number(sel.dataset.cardCs);
        if (sel.value) ctx.lines[idx].cutscene = sel.value;
        else delete ctx.lines[idx].cutscene;
        markDirty();
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-text]').forEach((ta) => {
      ta.addEventListener('input', () => {
        const idx = Number(ta.dataset.cardText);
        ctx.lines[idx].text = ta.value;
        markDirty();
        renderPreview();
      });
      ta.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          const idx = Number(ta.dataset.cardText);
          insertCardLineAfter(ctx, idx);
        }
      });
    });

    els.editorPane.querySelectorAll('[data-card-dir-idx]').forEach((inp) => {
      inp.addEventListener('input', () => {
        ctx.lines[Number(inp.dataset.cardDirIdx)].arg = inp.value;
        markDirty();
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-insert]').forEach((btn) => {
      btn.addEventListener('click', () => insertCardLineAfter(ctx, Number(btn.dataset.cardInsert)));
    });

    els.editorPane.querySelectorAll('[data-card-del]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const idx = Number(btn.dataset.cardDel);
        ctx.lines.splice(idx, 1);
        state.cursorLineIdx = Math.max(0, Math.min(idx, ctx.lines.length - 1));
        markDirty();
        renderSidebar();
        renderEditor({ preserveScroll: true });
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-move]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const idx = Number(btn.dataset.cardMove);
        const dir = Number(btn.dataset.dir);
        const target = idx + dir;
        if (target < 0 || target >= ctx.lines.length) return;
        const [item] = ctx.lines.splice(idx, 1);
        ctx.lines.splice(target, 0, item);
        state.cursorLineIdx = target;
        markDirty();
        renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-card-add-choice]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const idx = Number(btn.dataset.cardAddChoice);
        const line = ctx.lines[idx];
        if (!line.choices) line.choices = [];
        line.choices.push({ text: '新分支选项', favor_char: 'yang_zi_ying', favor_add: 5 });
        state.cursorLineIdx = idx;
        markDirty();
        renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-choice-text]').forEach((inp) => {
      inp.addEventListener('input', () => {
        const [li, ci] = inp.dataset.choiceText.split(':').map(Number);
        ctx.lines[li].choices[ci].text = inp.value;
        markDirty();
        renderPreview();
      });
    });

    els.editorPane.querySelectorAll('[data-choice-char]').forEach((sel) => {
      sel.addEventListener('change', () => {
        const [li, ci] = sel.dataset.choiceChar.split(':').map(Number);
        const ch = ctx.lines[li].choices[ci];
        if (sel.value) ch.favor_char = sel.value;
        else delete ch.favor_char;
        markDirty();
      });
    });

    els.editorPane.querySelectorAll('[data-choice-add]').forEach((inp) => {
      inp.addEventListener('input', () => {
        const [li, ci] = inp.dataset.choiceAdd.split(':').map(Number);
        ctx.lines[li].choices[ci].favor_add = parseInt(inp.value || '0', 10);
        markDirty();
      });
    });

    els.editorPane.querySelectorAll('[data-choice-del]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const [li, ci] = btn.dataset.choiceDel.split(':').map(Number);
        ctx.lines[li].choices.splice(ci, 1);
        state.cursorLineIdx = li;
        markDirty();
        renderEditor({ preserveScroll: true });
        renderPreview();
      });
    });
  }

  function insertCardLineAfter(ctx, idx) {
    const actors = actorLookup();
    const cur = ctx.lines[idx];
    let nextChar = state.pairLeft;
    if (state.autoAlternate && cur && cur.char) {
      nextChar = cur.char === state.pairLeft ? state.pairRight : state.pairLeft;
    }
    const spec = actors[nextChar] || { name: '叶舟', default_side: 'left' };
    ctx.lines.splice(idx + 1, 0, {
      speaker: spec.name,
      char: nextChar,
      side: spec.default_side || (nextChar === 'ye_zhou' ? 'left' : 'right'),
      emotion: 'neutral',
      text: '',
    });
    state.cursorLineIdx = idx + 1;
    markDirty();
    renderSidebar();
    renderEditor({ preserveScroll: true, focusLineIdx: idx + 1, scrollTargetIntoView: true });
    renderPreview();
  }

  // ==================== 1920x1080 Live Game Stage Preview ====================

  function layoutStageScale() {
    if (!els.stageViewportWrap || !els.stageScaler) return;
    const w = els.stageViewportWrap.clientWidth;
    if (w > 0) {
      const scale = w / 1920;
      els.stageScaler.style.transform = `scale(${scale})`;
    }
  }

  function renderPreview() {
    layoutStageScale();
    const sc = getActiveScene();
    const ctx = getActiveLinesContext();

    if (state.activeView === 'cast_world' || !sc || !ctx) {
      els.stageBgStack.innerHTML = `<img src="${assetUrl('assets/backgrounds/phase_two/morning_road_wide.png')}" alt="" />`;
      els.stageCutscene.classList.remove('visible', 'animate');
      els.stageLeftActor.classList.remove('visible');
      els.stageRightActor.classList.remove('visible');
      els.stagePortraitWrap.style.display = 'none';
      els.stageNameplate.textContent = 'IGA 创作工作台';
      els.stageText.textContent = '左侧选择任意一幕即可实时预览 1920×1080 游戏演出画面。';
      els.stageChoices.innerHTML = '';
      els.previewMetaTag.textContent = '待机';
      els.readabilityBar.className = 'readability-bar';
      els.readabilityBar.textContent = '随时可以在右侧点击画面或按 Space 交互试玩。';
      return;
    }

    if (ctx.kind === 'library_notes') {
      const art = ctx.articles[Math.min(state.activeSubTabIdx, Math.max(0, ctx.articles.length - 1))] || {};
      const bgLayers = state.bundle.assets.backgrounds.library?.layers || [];
      els.stageBgStack.innerHTML = bgLayers.map((p) => `<img src="${assetUrl(p)}" alt="" />`).join('');
      els.stageCutscene.classList.remove('visible', 'animate');
      els.stageLeftActor.classList.remove('visible');
      els.stageRightActor.className = 'stage-actor actor-right visible speaking';
      els.stageRightActor.src = getActorSprite('lin_zhi_xia', 'happy');
      const av = getActorAvatar('lin_zhi_xia', 'happy');
      els.stagePortraitWrap.style.display = av.url ? 'flex' : 'none';
      els.stagePortraitImg.src = av.url;
      els.stagePortraitImg.className = `stage-portrait ${av.crop ? 'crop-top' : ''}`;
      els.stageCaption.textContent = `风物纪要预览   /   阿瑞忒图书馆`;
      els.stageNameplate.textContent = art.title || '风物纪要';
      els.stageText.textContent = art.body || '';
      els.stageChoices.innerHTML = '';
      els.previewMetaTag.textContent = `${(art.body || '').length} 字`;
      els.readabilityBar.className = 'readability-bar';
      els.readabilityBar.textContent = `当前浏览《${art.title || ''}》 · 字数 ${(art.body || '').length} 字`;
      return;
    }

    if (ctx.kind === 'battle_only') {
      const bgLayers = state.bundle.assets.backgrounds.battle_red_moon_lockdown?.layers || [];
      els.stageBgStack.innerHTML = bgLayers.map((p) => `<img src="${assetUrl(p)}" alt="" />`).join('');
      els.stageCutscene.classList.remove('visible', 'animate');
      els.stageLeftActor.classList.remove('visible');
      els.stageRightActor.classList.remove('visible');
      els.stagePortraitWrap.style.display = 'none';
      els.stageCaption.textContent = `战斗节点   /   ${sc.enemy || ''}`;
      els.stageNameplate.textContent = sc.title || '';
      els.stageText.textContent = `此节点无战前对话，将直接触发与「${sc.enemy}」的战斗。`;
      els.stageChoices.innerHTML = '';
      els.previewMetaTag.textContent = '纯战斗节点';
      els.readabilityBar.className = 'readability-bar';
      els.readabilityBar.textContent = '点击中间「为这场战斗添加战前对话台词」可补充开战前演出。';
      return;
    }

    // Standard dialogue preview: accumulate state from 0..cursorLineIdx
    const lines = ctx.lines || [];
    const targetIdx = Math.max(0, Math.min(state.cursorLineIdx, lines.length - 1));
    let activeBg = sc.bg || 'dusk_road';
    let activeCutscene = sc.default_cutscene || '';
    let leftState = null; // { char, emotion }
    let rightState = null;
    let displayLine = lines[targetIdx] || { speaker: '旁白', char: '', side: 'left', emotion: 'neutral', text: '（开始撰写本幕第一句台词…）' };

    for (let i = 0; i <= targetIdx; i++) {
      const l = lines[i];
      if (!l) continue;
      if (l.type === 'directive') {
        if (l.kind === '背景' || l.kind === 'bg') {
          if (state.bundle.assets.backgrounds[l.arg]) activeBg = l.arg;
        } else if (l.kind === '立绘退场') {
          if (l.arg === '左') leftState = null;
          else if (l.arg === '右') rightState = null;
          else if (l.arg === '全部' || l.arg === 'all') { leftState = null; rightState = null; }
        }
        continue;
      }
      if (l.cutscene) activeCutscene = l.cutscene;
      else if (i > 0 && lines[i - 1]?.cutscene && !l.cutscene) activeCutscene = sc.default_cutscene || '';

      if (l.char && getActorSprite(l.char, l.emotion || 'neutral')) {
        if (l.side === 'left') leftState = { char: l.char, emotion: l.emotion || 'neutral' };
        else rightState = { char: l.char, emotion: l.emotion || 'neutral' };
      }
    }

    // If current index sits on a directive, show nearest preceding dialogue line + directive hint
    let directiveHint = '';
    if (displayLine.type === 'directive') {
      directiveHint = `[${displayLine.kind}${displayLine.arg ? ': ' + displayLine.arg : ''}]`;
      for (let j = targetIdx - 1; j >= 0; j--) {
        if (lines[j].type !== 'directive') {
          displayLine = lines[j];
          break;
        }
      }
      if (displayLine.type === 'directive') {
        displayLine = { speaker: '演出指令', char: '', side: 'left', emotion: 'neutral', text: directiveHint };
      }
    }

    // Background & Cutscene
    const bgInfo = state.bundle.assets.backgrounds[activeBg] || state.bundle.assets.backgrounds.dusk_road;
    els.stageBgStack.innerHTML = (bgInfo?.layers || []).map((p) => `<img src="${assetUrl(p)}" alt="" />`).join('');

    const csSpec = activeCutscene ? state.bundle.assets.cutscenes?.[activeCutscene] : null;
    if (csSpec && csSpec.bg_path) {
      els.stageCutscene.classList.add('visible');
      els.cutsceneBgImg.src = assetUrl(csSpec.bg_path);
      els.cutsceneFgImg.src = csSpec.fg_path ? assetUrl(csSpec.fg_path) : '';
      els.cutsceneFgImg.style.display = csSpec.fg_path ? 'block' : 'none';
      requestAnimationFrame(() => els.stageCutscene.classList.add('animate'));
    } else {
      els.stageCutscene.classList.remove('visible', 'animate');
    }

    // Caption
    const bgLabel = (state.bundle.catalogs.backgrounds || []).find((b) => b.id === activeBg)?.label || sc.title;
    els.stageCaption.textContent = `剧情放映   /   ${bgLabel}`;

    // Left / Right Actors
    const speakingSide = displayLine.char ? displayLine.side : '';
    if (leftState) {
      const src = getActorSprite(leftState.char, leftState.emotion);
      els.stageLeftActor.src = src;
      els.stageLeftActor.className = `stage-actor actor-left visible ${speakingSide === 'left' ? 'speaking' : 'dimmed'}`;
    } else {
      els.stageLeftActor.className = 'stage-actor actor-left';
    }

    if (rightState) {
      const src = getActorSprite(rightState.char, rightState.emotion);
      els.stageRightActor.src = src;
      els.stageRightActor.className = `stage-actor actor-right visible ${speakingSide === 'right' ? 'speaking' : 'dimmed'}`;
    } else {
      els.stageRightActor.className = 'stage-actor actor-right';
    }

    // Avatar & Nameplate
    const av = displayLine.char ? getActorAvatar(displayLine.char, displayLine.emotion || 'neutral') : { url: '' };
    if (av.url) {
      els.stagePortraitWrap.style.display = 'flex';
      els.stagePortraitImg.src = av.url;
      els.stagePortraitImg.className = `stage-portrait ${av.crop ? 'crop-top' : ''}`;
    } else {
      els.stagePortraitWrap.style.display = 'none';
    }

    els.stageNameplate.textContent = displayLine.speaker || '旁白';

    const fullText = displayLine.text || '';
    if (!state.playtest.active) {
      clearInterval(state.playtest.typingTimer);
      els.stageText.textContent = directiveHint ? `${directiveHint}\n${fullText}` : fullText;
    }

    // Choices
    const choices = displayLine.choices || [];
    els.stageChoices.innerHTML = choices.map((ch, ci) =>
      `<button class="stage-choice-btn" data-preview-choice="${ci}"> ▶  ${escapeHtml(ch.text || '')}</button>`
    ).join('');
    els.stageContinue.style.display = choices.length ? 'none' : 'flex';

    // Chapter Banner
    if (state.playtest.bannerVisible) {
      const titleTxt = sc.phase?.includes('序章') ? state.bundle.titles.prologue_title : state.bundle.titles.chapter_title;
      els.stageBannerTitle.textContent = titleTxt;
      els.stageChapterBanner.classList.add('visible');
    } else {
      els.stageChapterBanner.classList.remove('visible');
    }

    // Diagnostics & Readability
    const dlgLines = lines.filter((l) => l.type !== 'directive');
    const len = fullText.length;
    const estSec = Math.max(4, Math.round(dlgLines.reduce((acc, l) => acc + 1.2 + (l.text || '').length * 0.06, 0)));
    els.previewMetaTag.textContent = `第 ${targetIdx + 1} / ${Math.max(1, lines.length)} 行`;

    if (len > 55) {
      els.readabilityBar.className = 'readability-bar warn';
      els.readabilityBar.innerHTML = `<span>⚠ 当前句 ${len} 字（超过 55 字两行舒适区，建议回车拆句）</span><span>预计 ${estSec}s</span>`;
    } else {
      els.readabilityBar.className = 'readability-bar';
      els.readabilityBar.innerHTML = `<span>✓ 当前句 ${len} 字 · 实机双行排版舒适</span><span>本幕共 ${dlgLines.length} 句 · 约 ${estSec}s</span>`;
    }
  }

  // ==================== Playtest & SFX ====================

  function playSfxKey(sfxKey) {
    if (!state.playtest.soundOn || !sfxKey) return;
    const item = (state.bundle.catalogs.sfx || []).find((s) => s.id === sfxKey);
    if (!item) return;
    try {
      const audio = new Audio(assetUrl(item.file));
      audio.volume = 0.45;
      audio.play().catch(() => {});
    } catch (_) {}
  }

  function stepPreview(delta) {
    const ctx = getActiveLinesContext();
    if (!ctx || ctx.kind !== 'lines' || !ctx.lines.length) return;
    const next = Math.max(0, Math.min(ctx.lines.length - 1, state.cursorLineIdx + delta));
    if (next === state.cursorLineIdx && delta > 0 && state.playtest.active) {
      stopPlaytest();
      toast('本幕试玩播映完毕 ✓', 'ok');
      return;
    }
    state.cursorLineIdx = next;
    const line = ctx.lines[next];
    if (line?.type === 'directive' && (line.kind === 'SFX' || line.kind === 'sfx')) {
      playSfxKey(line.arg);
    }
    renderPreview();
    if (state.playtest.active) {
      startTypewriterForLine(line);
    }
  }

  function startTypewriterForLine(line) {
    clearInterval(state.playtest.typingTimer);
    clearTimeout(state.playtest.timer);
    if (!line || line.type === 'directive') {
      if (state.playtest.auto) {
        state.playtest.timer = setTimeout(() => stepPreview(1), 650);
      }
      return;
    }
    const text = line.text || '';
    let pos = 0;
    els.stageText.textContent = '';
    state.playtest.typingTimer = setInterval(() => {
      pos += 2;
      if (pos >= text.length) {
        els.stageText.textContent = text;
        clearInterval(state.playtest.typingTimer);
        if (state.playtest.auto && !(line.choices && line.choices.length)) {
          const waitMs = Math.min(3200, Math.max(1000, 900 + text.length * 45));
          state.playtest.timer = setTimeout(() => stepPreview(1), waitMs);
        }
      } else {
        els.stageText.textContent = text.slice(0, pos);
      }
    }, 28);
  }

  function startPlaytest() {
    const ctx = getActiveLinesContext();
    if (!ctx || ctx.kind !== 'lines' || !ctx.lines.length) return;
    state.playtest.active = true;
    els.btnPlayToggle.textContent = '⏹ 停止试玩';
    playSfxKey('ui_click');
    renderPreview();
    startTypewriterForLine(ctx.lines[state.cursorLineIdx]);
  }

  function stopPlaytest() {
    state.playtest.active = false;
    state.playtest.auto = false;
    clearInterval(state.playtest.typingTimer);
    clearTimeout(state.playtest.timer);
    els.btnPlayToggle.textContent = '▶ 从当前句试玩';
    els.btnAutoPlay.classList.remove('active');
    renderPreview();
  }

  // ==================== Modals & Actions ====================

  function openModal(html) {
    els.modalCard.innerHTML = html;
    els.modalBackdrop.classList.remove('hidden');
  }

  function closeModal() {
    els.modalBackdrop.classList.add('hidden');
    els.modalCard.innerHTML = '';
  }

  function openNewSceneModal() {
    const actors = actorLookup();
    const actorOpts = Object.entries(actors)
      .filter(([id]) => id !== 'ye_zhou')
      .map(([id, spec]) => `<option value="${id}">${escapeHtml(spec.name)}</option>`)
      .join('');
    const bgOpts = (state.bundle.catalogs.backgrounds || []).map((b) =>
      `<option value="${b.id}">${escapeHtml(b.label)}</option>`
    ).join('');

    openModal(`
      <h2>✨ 新建一幕剧情（仅填幕名即可开写）</h2>
      <div class="modal-field">
        <label>幕名（中文即可，ID 自动生成）</label>
        <input id="newSceneTitle" type="text" placeholder="例如：运动会接力赛与第四名的秘密" autofocus />
      </div>
      <div class="modal-field">
        <label>归属分区</label>
        <select id="newSceneCat">
          <option value="prologue_oral_drafts" ${state.activeCategory === 'prologue_oral_drafts' ? 'selected' : ''}>2. 主创口述序章草稿</option>
          <option value="chapters_2_to_5" ${state.activeCategory === 'chapters_2_to_5' ? 'selected' : ''}>3. 第 2–5 章巡回大纲与草稿</option>
          <option value="main_active" ${state.activeCategory === 'main_active' ? 'selected' : ''}>1. 现行主线（序章 & 第一章）</option>
          <option value="campus_npcs" ${state.activeCategory === 'campus_npcs' ? 'selected' : ''}>4. 校园同伴 / 支线对话</option>
        </select>
      </div>
      <div class="modal-field">
        <label>默认背景（可随时在编辑器顶部改）</label>
        <select id="newSceneBg">${bgOpts}</select>
      </div>
      <div class="modal-field">
        <label>本幕主要对手戏角色（用于「回车自动换人」）</label>
        <select id="newScenePartner">${actorOpts}</select>
      </div>
      <div class="modal-actions">
        <button class="btn btn-ghost" id="mCancel">取消</button>
        <button class="btn btn-primary" id="mCreate">创建并立即开写</button>
      </div>
    `);

    $('mCancel').addEventListener('click', closeModal);
    $('mCreate').addEventListener('click', () => {
      const title = ($('newSceneTitle').value || '').trim() || '未命名新剧情幕';
      const cat = $('newSceneCat').value;
      const bg = $('newSceneBg').value;
      const partner = $('newScenePartner').value;
      const slug = `scene_${Date.now().toString(36)}`;
      const partnerName = actors[partner]?.name || '黄秋枫';

      const newObj = {
        id: slug,
        node: cat === 'main_active' ? `n_${slug}` : '',
        category: cat,
        target_type: cat === 'main_active' ? 'phase_two_flow' : (cat === 'campus_npcs' ? 'phase_two_script' : 'draft'),
        phase: cat === 'campus_npcs' ? '支线对话' : (cat === 'chapters_2_to_5' ? '新章节草稿' : '新剧情幕'),
        phase_key: 'act1',
        title,
        location: '',
        bg,
        bgm: 'bgm_campus_daily',
        default_cutscene: '',
        note: '',
        lines: [
          { speaker: '叶舟', char: 'ye_zhou', side: 'left', emotion: 'neutral', text: '' },
          { speaker: partnerName, char: partner, side: 'right', emotion: 'neutral', text: '' },
        ],
      };

      state.bundle.categories[cat].push(newObj);
      state.activeView = 'scene';
      state.activeCategory = cat;
      state.activeSceneId = slug;
      state.pairLeft = 'ye_zhou';
      state.pairRight = partner;
      state.cursorLineIdx = 0;
      markDirty();
      closeModal();
      renderSidebar();
      renderEditor({ preserveScroll: false });
      renderPreview();
      setTimeout(() => $('streamTextarea')?.focus(), 40);
    });
  }

  function openNewActorModal() {
    openModal(`
      <h2>🎭 新增角色</h2>
      <div class="modal-field">
        <label>角色中文名（之后写剧本直接用「角色名: 台词」）</label>
        <input id="actorName" type="text" placeholder="例如：小混混 / 体育生 / 法典裁判官" />
      </div>
      <div class="modal-field">
        <label>引擎英文 ID（可留空自动生成）</label>
        <input id="actorId" type="text" placeholder="例如：track_ace" />
      </div>
      <div class="modal-field">
        <label>身份头衔</label>
        <input id="actorTitle" type="text" placeholder="例如：阿瑞忒田径队主力" />
      </div>
      <div class="modal-field">
        <label>默认站位</label>
        <select id="actorSide">
          <option value="right">右侧 (默认对手/对话对象)</option>
          <option value="left">左侧 (默认主角阵营)</option>
        </select>
      </div>
      <div class="modal-actions">
        <button class="btn btn-ghost" id="mCancel">取消</button>
        <button class="btn btn-primary" id="mSaveActor">添加到角色库</button>
      </div>
    `);
    $('mCancel').addEventListener('click', closeModal);
    $('mSaveActor').addEventListener('click', () => {
      const name = ($('actorName').value || '').trim();
      if (!name) return toast('请输入角色名称', 'err');
      const id = ($('actorId').value || '').trim() || `custom_${Date.now().toString(36)}`;
      state.bundle.actors[id] = {
        id,
        name,
        title: ($('actorTitle').value || '').trim() || '自定义角色',
        bio: '',
        default_side: $('actorSide').value,
        builtin: false,
      };
      markDirty();
      closeModal();
      renderEditor();
      toast(`已添加角色「${name}」，现在可直接写「${name}: 台词」`, 'ok');
    });
  }

  function openDirectiveQuickInsert(ctx, kind) {
    if (kind === 'choice') {
      if (state.editorMode === 'stream') {
        const ta = $('streamTextarea');
        if (ta) {
          insertAtLineEnd(ta, '\n? 选项文字 [好感: 杨子英+5]', 3, 7);
          ta.dispatchEvent(new Event('input'));
        }
      } else if (ctx.lines[state.cursorLineIdx]) {
        const l = ctx.lines[state.cursorLineIdx];
        if (!l.choices) l.choices = [];
        l.choices.push({ text: '新分支选项', favor_char: 'yang_zi_ying', favor_add: 5 });
        markDirty();
        renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
        renderPreview();
      }
      return;
    }

    if (kind === 'cutscene') {
      const opts = (state.bundle.catalogs.cutscenes || [])
        .map((c) => `<option value="${c.id || '关闭'}">${escapeHtml(c.label)}</option>`)
        .join('');
      openModal(`
        <h2>🎬 插入双层视差过场指令</h2>
        <div class="modal-field">
          <label>选择过场动画</label>
          <select id="dirCsSel">${opts}</select>
        </div>
        <div class="modal-actions">
          <button class="btn btn-ghost" id="mCancel">取消</button>
          <button class="btn btn-primary" id="mInsert">插入</button>
        </div>
      `);
      $('mCancel').addEventListener('click', closeModal);
      $('mInsert').addEventListener('click', () => {
        insertRawDirective(ctx, '过场', $('dirCsSel').value);
        closeModal();
      });
      return;
    }

    if (kind === 'sfx') {
      const opts = (state.bundle.catalogs.sfx || [])
        .map((s) => `<option value="${s.id}">${escapeHtml(s.id)}</option>`)
        .join('');
      openModal(`
        <h2>🔊 插入一次性音效 (SFX)</h2>
        <div class="modal-field">
          <label>选择工程内置音效</label>
          <div style="display:flex; gap:8px;">
            <select id="dirSfxSel" style="flex:1;">${opts}</select>
            <button class="btn btn-ghost" id="btnPreviewSfx">▶ 试听</button>
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-ghost" id="mCancel">取消</button>
          <button class="btn btn-primary" id="mInsert">插入</button>
        </div>
      `);
      $('mCancel').addEventListener('click', closeModal);
      $('btnPreviewSfx').addEventListener('click', () => playSfxKey($('dirSfxSel').value));
      $('mInsert').addEventListener('click', () => {
        insertRawDirective(ctx, 'SFX', $('dirSfxSel').value);
        closeModal();
      });
      return;
    }

    if (kind === 'bg') {
      const opts = (state.bundle.catalogs.backgrounds || [])
        .map((b) => `<option value="${b.id}">${escapeHtml(b.label)} (${b.id})</option>`)
        .join('');
      openModal(`
        <h2>🖼️ 插入场景内切换背景指令</h2>
        <div class="modal-field">
          <label>选择切换背景</label>
          <select id="dirBgSel">${opts}</select>
        </div>
        <div class="modal-actions">
          <button class="btn btn-ghost" id="mCancel">取消</button>
          <button class="btn btn-primary" id="mInsert">插入</button>
        </div>
      `);
      $('mCancel').addEventListener('click', closeModal);
      $('mInsert').addEventListener('click', () => {
        insertRawDirective(ctx, '背景', $('dirBgSel').value);
        closeModal();
      });
      return;
    }

    if (kind === 'note') {
      insertRawDirective(ctx, '备注', '这里节奏停顿半拍，突出反差');
    }
  }

  function insertRawDirective(ctx, kind, arg) {
    if (state.editorMode === 'stream') {
      const ta = $('streamTextarea');
      if (ta) {
        insertAtLineEnd(ta, `\n[${kind}: ${arg}]`);
        ta.dispatchEvent(new Event('input'));
      }
    } else {
      ctx.lines.splice(state.cursorLineIdx + 1, 0, { type: 'directive', kind, arg });
      state.cursorLineIdx++;
      markDirty();
      renderEditor({ preserveScroll: true, scrollTargetIntoView: true });
      renderPreview();
    }
  }

  function openPromoteModal(draftScene) {
    const mainList = state.bundle.categories.main_active || [];
    const targetOpts = mainList.map((m) => `<option value="${m.id}">替换现行节点：${escapeHtml(m.title)} (${m.node})</option>`).join('');
    openModal(`
      <h2>⤴ 将草稿合入现行主线</h2>
      <p style="margin:0; font-size:13px; color:var(--ink-muted);">
        当前草稿《${escapeHtml(draftScene.title)}》可直接替换现行主线中的某一幕，或作为新节点追加进主线。
      </p>
      <div class="modal-field">
        <label>选择合入方式</label>
        <select id="promoteTarget">
          ${targetOpts}
          <option value="__append__">+ 作为全新主线幕追加到末尾</option>
        </select>
      </div>
      <div class="modal-actions">
        <button class="btn btn-ghost" id="mCancel">取消</button>
        <button class="btn btn-secondary" id="mConfirmPromote">确认合入主线</button>
      </div>
    `);
    $('mCancel').addEventListener('click', closeModal);
    $('mConfirmPromote').addEventListener('click', () => {
      const targetId = $('promoteTarget').value;
      const clonedLines = deepClone(draftScene.lines || []);
      if (targetId === '__append__') {
        const newId = draftScene.id;
        mainList.push({
          ...deepClone(draftScene),
          id: newId,
          node: `n_${newId}`,
          category: 'main_active',
          target_type: 'phase_two_flow',
          phase_key: 'act1',
        });
        state.activeCategory = 'main_active';
        state.activeSceneId = newId;
      } else {
        const target = mainList.find((m) => m.id === targetId);
        if (target) {
          target.title = draftScene.title.replace('（范本示范稿）', '');
          target.bg = draftScene.bg;
          target.bgm = draftScene.bgm;
          target.default_cutscene = draftScene.default_cutscene;
          target.lines = clonedLines;
          if (target.target_type === 'phase_two_battle_only') target.target_type = 'phase_two_flow';
          state.activeCategory = 'main_active';
          state.activeSceneId = target.id;
        }
      }
      markDirty();
      closeModal();
      renderSidebar();
      renderEditor({ preserveScroll: false });
      renderPreview();
      toast('已合入现行主线列表（点击右上角「同步写回游戏」即可生效）', 'ok');
    });
  }

  function openQuickImportModal() {
    openModal(`
      <h2>📋 智能导入外部文本 / Markdown 剧本</h2>
      <p style="margin:0; font-size:12.5px; color:var(--ink-muted);">
        直接把你在记事本、微信、飞书或 Word 里写的对话粘贴进来！支持 <code>叶舟: 台词</code>、<code>黄秋枫(微笑): 台词</code>、<code>[备注: ...]</code>、<code>? 选项</code> 以及纯旁白段落。
      </p>
      <div class="modal-field">
        <label>粘贴剧情文本</label>
        <textarea id="importRawArea" placeholder="例如：&#10;旁白: 放学后的走廊只剩斜斜的夕阳。&#10;叶舟: 等很久了吗？&#10;黄秋枫(微笑): 没有，我也刚到图书馆门口。"></textarea>
      </div>
      <div class="modal-field">
        <label>导入目标</label>
        <select id="importTargetMode">
          <option value="replace">替换当前幕正文</option>
          <option value="append">追加到当前幕末尾</option>
          <option value="new_draft">新建一幕草稿并导入</option>
        </select>
      </div>
      <div class="modal-actions">
        <button class="btn btn-ghost" id="mCancel">取消</button>
        <button class="btn btn-primary" id="mRunImport">智能识别并导入</button>
      </div>
    `);
    $('mCancel').addEventListener('click', closeModal);
    $('mRunImport').addEventListener('click', () => {
      const raw = $('importRawArea').value.trim();
      if (!raw) return toast('请先粘贴文本内容', 'err');
      // Strip optional YAML header if user pasted full markdown template
      const body = raw.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n*/, '');
      const parsed = parseStreamText(body);
      const mode = $('importTargetMode').value;

      if (mode === 'new_draft') {
        const titleMatch = raw.match(/^幕名\s*[:：]\s*(.+)$/m);
        const slug = `imported_${Date.now().toString(36)}`;
        state.bundle.categories.prologue_oral_drafts.push({
          id: slug,
          node: '',
          category: 'prologue_oral_drafts',
          target_type: 'draft',
          phase: '导入草稿',
          title: titleMatch ? titleMatch[1].trim() : `导入剧本 ${new Date().toLocaleTimeString()}`,
          location: '',
          bg: 'morning_road',
          bgm: 'bgm_campus_daily',
          default_cutscene: '',
          note: '',
          lines: parsed,
        });
        state.activeView = 'scene';
        state.activeCategory = 'prologue_oral_drafts';
        state.activeSceneId = slug;
      } else {
        const ctx = getActiveLinesContext();
        if (!ctx || ctx.kind !== 'lines') return toast('当前页面不支持直接导入对白', 'err');
        ctx.setLines(mode === 'append' ? [...ctx.lines, ...parsed] : parsed);
      }
      state.cursorLineIdx = 0;
      markDirty();
      closeModal();
      renderSidebar();
      renderEditor({ preserveScroll: mode === 'append' });
      renderPreview();
      toast(`成功导入 ${parsed.length} 行内容`, 'ok');
    });
  }

  function downloadFile(filename, content, mime = 'text/plain;charset=utf-8') {
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  function exportCurrentMarkdown() {
    const sc = getActiveScene();
    const ctx = getActiveLinesContext();
    if (!sc || !ctx) return;
    if (ctx.kind === 'lines') {
      const md = [
        `# ${sc.title || sc.id}`,
        '',
        '---',
        `剧情ID: ${sc.id}`,
        `所属阶段: ${sc.phase || ''}`,
        `幕名: ${sc.title || ''}`,
        `默认背景: ${sc.bg || ''}`,
        `默认过场: ${sc.default_cutscene || '无'}`,
        `后续敌人: ${sc.enemy || '无'}`,
        '---',
        '',
        linesToStreamText(ctx.lines),
        '',
      ].join('\n');
      downloadFile(`${sc.id}.md`, md, 'text/markdown;charset=utf-8');
      toast(`已导出 ${sc.id}.md`, 'ok');
    } else if (ctx.kind === 'library_notes') {
      const md = ctx.articles.map((a) => `### ${a.title}\n\n${a.body}\n`).join('\n');
      downloadFile('风物纪要.md', md, 'text/markdown;charset=utf-8');
      toast('已导出 风物纪要.md', 'ok');
    }
  }

  function openExportPackModal() {
    openModal(`
      <h2>📦 导出 / 备份 / 还原工程数据</h2>
      <p style="margin:0; font-size:12.5px; color:var(--ink-muted);">
        在离线模式下，可导出 <code>story_bundle.json</code> 覆盖至 <code>tools/story_studio/story_bundle.json</code> 后运行 <code>python tools/story_studio/sync_story.py --apply</code>。
      </p>
      <div style="display:flex; flex-direction:column; gap:8px;">
        <button class="btn btn-ghost" id="expAllMarkdown">📥 下载全本全分类剧本合集 (IGA_全部剧本合集.md)</button>
        <button class="btn btn-ghost" id="expBundleJson">📥 下载完整工程包 (story_bundle.json)</button>
        <button class="btn btn-ghost" id="expBundleJs">📥 下载离线数据包 (story_data.js)</button>
        <button class="btn btn-ghost" id="expPhaseTwoSnippet">📥 导出主线脚本常量片段 (phase_two_scripts.gd.txt)</button>
        <label class="btn btn-ghost" style="cursor:pointer;">
          📤 从 JSON 工程包恢复导入
          <input id="impBundleJson" type="file" accept=".json" style="display:none;" />
        </label>
        <button class="btn btn-primary-soft" id="btnResetLocalDraft">♻ 丢弃浏览器缓存并重载项目原版剧情</button>
      </div>
      <div class="modal-actions">
        <button class="btn btn-ghost" id="mClose">关闭</button>
      </div>
    `);
    $('mClose').addEventListener('click', closeModal);
    $('expAllMarkdown').addEventListener('click', () => {
      const chunks = ['# IGA 全案剧情合集\n'];
      for (const grp of GROUP_META) {
        chunks.push(`\n# ${grp.label}\n`);
        for (const sc of state.bundle.categories[grp.key] || []) {
          chunks.push(`\n## ${sc.title || sc.id} (${sc.id})\n`);
          if (sc.target_type === 'campus_life_npc') {
            for (const c of sc.conditions || []) {
              chunks.push(`\n### [条件: ${c.condition_label || c.condition_key}]\n${linesToStreamText(c.lines || [])}\n`);
            }
          } else if (sc.target_type === 'library_notes') {
            for (const a of sc.articles || []) {
              chunks.push(`\n### ${a.title}\n${a.body}\n`);
            }
          } else if (sc.target_type === 'exploration_routes') {
            for (const v of sc.variants || []) {
              chunks.push(`\n### ${v.title}\n${linesToStreamText(v.lines || [])}\n`);
            }
          } else if (sc.target_type === 'campus_snippets') {
            for (const sn of sc.snippets || []) {
              chunks.push(`\n### [${sn.id}]\n${linesToStreamText(sn.lines || [])}\n`);
            }
          } else {
            chunks.push(`\n${linesToStreamText(sc.lines || [])}\n`);
          }
        }
      }
      downloadFile('IGA_全部剧本合集.md', chunks.join('\n'), 'text/markdown;charset=utf-8');
      toast('已导出全本剧本合集', 'ok');
    });
    $('expBundleJson').addEventListener('click', () => {
      downloadFile('story_bundle.json', JSON.stringify(state.bundle, null, 2) + '\n', 'application/json;charset=utf-8');
      toast('已导出 story_bundle.json', 'ok');
    });
    $('expBundleJs').addEventListener('click', () => {
      downloadFile('story_data.js', `// Generated by IGA Story Studio\nwindow.IGA_STORY_BUNDLE = ${JSON.stringify(state.bundle, null, 2)};\n`, 'text/javascript;charset=utf-8');
      toast('已导出 story_data.js', 'ok');
    });
    $('expPhaseTwoSnippet').addEventListener('click', () => {
      const scripts = {};
      for (const sc of state.bundle.categories.main_active || []) {
        if (sc.target_type !== 'phase_two_battle_only') {
          scripts[sc.id] = (sc.lines || []).filter((l) => l.type !== 'directive');
        }
      }
      for (const sc of state.bundle.categories.campus_npcs || []) {
        if (sc.target_type === 'phase_two_script') {
          scripts[sc.id] = (sc.lines || []).filter((l) => l.type !== 'directive');
        }
      }
      downloadFile('phase_two_scripts_preview.gd.txt', `const SCRIPTS: Dictionary = ${JSON.stringify(scripts, null, '\t')}\n`);
      toast('已导出 GDScript 剧本片段', 'ok');
    });
    $('impBundleJson').addEventListener('change', (e) => {
      const file = e.target.files?.[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = () => {
        try {
          const parsed = JSON.parse(String(reader.result));
          if (!parsed.categories) throw new Error('无效的 story_bundle.json');
          state.bundle = parsed;
          markDirty();
          closeModal();
          renderSidebar();
          renderEditor();
          renderPreview();
          toast('已成功恢复工程数据包', 'ok');
        } catch (err) {
          toast(`导入失败: ${err.message}`, 'err');
        }
      };
      reader.readAsText(file, 'utf-8');
    });
    $('btnResetLocalDraft').addEventListener('click', async () => {
      localStorage.removeItem(STORAGE_KEY);
      if (state.serverOnline) {
        const res = await fetch('/api/reload_from_gd', { method: 'POST' }).then((r) => r.json());
        if (res.ok && res.bundle) state.bundle = res.bundle;
      } else if (window.IGA_STORY_BUNDLE) {
        state.bundle = deepClone(window.IGA_STORY_BUNDLE);
      }
      state.dirty = false;
      updateConnBadge();
      closeModal();
      renderSidebar();
      renderEditor();
      renderPreview();
      toast('已还原为项目磁盘最新剧情', 'ok');
    });
  }

  // ==================== Save & Apply to Game ====================

  async function saveDraftToServer() {
    scheduleLocalAutosave();
    if (!state.serverOnline) {
      toast('离线模式已保存至浏览器本地（可点击导出 Markdown / JSON）', 'ok');
      state.dirty = false;
      updateConnBadge();
      return;
    }
    try {
      const resp = await fetch('/api/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bundle: state.bundle }),
      });
      const data = await resp.json();
      if (!data.ok) throw new Error(data.error || '保存失败');
      state.dirty = false;
      updateConnBadge();
      toast(`已保存 JSON 与 ${data.markdown_files?.length || 5} 份 Markdown 剧本`, 'ok');
    } catch (err) {
      toast(`保存失败: ${err.message}`, 'err');
    }
  }

  async function applyToGameProject() {
    if (!state.serverOnline) {
      toast('当前为直接双击离线打开。请先下载 story_bundle.json 并运行 根目录/启动剧情工作台.bat 或 sync_story.py --apply', 'err');
      openExportPackModal();
      return;
    }
    try {
      const resp = await fetch('/api/apply_game', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bundle: state.bundle }),
      });
      const data = await resp.json();
      if (!data.ok) throw new Error(data.error || '写回失败');
      state.dirty = false;
      updateConnBadge();
      toast(`🚀 已同步写回 ${(data.updated_files || []).length} 个游戏 .gd 文件与 Markdown 文档！`, 'ok');
    } catch (err) {
      toast(`同步失败: ${err.message}`, 'err');
    }
  }

  // ==================== Boot ====================

  async function init() {
    cacheDom();

    // Restore theme
    if (localStorage.getItem(THEME_KEY) === 'night') {
      document.body.classList.add('theme-night');
    }

    // Load baseline from story_data.js
    if (window.IGA_STORY_BUNDLE) {
      state.bundle = deepClone(window.IGA_STORY_BUNDLE);
    }

    // Probe local sync server when served over HTTP
    if (location.protocol.startsWith('http')) {
      try {
        const st = await fetch('/api/status').then((r) => r.json());
        if (st && st.ok) {
          state.serverOnline = true;
          const bRes = await fetch('/api/bundle').then((r) => r.json());
          if (bRes && bRes.ok && bRes.bundle) {
            state.bundle = bRes.bundle;
          }
        }
      } catch (_) {
        state.serverOnline = false;
      }
    }

    // Restore unsaved offline draft if present and offline
    if (!state.serverOnline) {
      try {
        const cached = localStorage.getItem(STORAGE_KEY);
        if (cached) {
          const parsed = JSON.parse(cached);
          if (parsed?.bundle?.categories) {
            state.bundle = parsed.bundle;
          }
        }
      } catch (_) {}
    }

    updateConnBadge();

    // Bind global topbar & sidebar events
    $('btnThemeToggle').addEventListener('click', () => {
      document.body.classList.toggle('theme-night');
      localStorage.setItem(THEME_KEY, document.body.classList.contains('theme-night') ? 'night' : 'paper');
    });

    $('btnQuickImport').addEventListener('click', openQuickImportModal);
    $('btnExportMd').addEventListener('click', exportCurrentMarkdown);
    $('btnExportPack').addEventListener('click', openExportPackModal);
    $('btnSaveDraft').addEventListener('click', saveDraftToServer);
    $('btnApplyGame').addEventListener('click', applyToGameProject);
    $('btnNewScene').addEventListener('click', openNewSceneModal);
    $('btnCastWorld').addEventListener('click', () => {
      state.activeView = 'cast_world';
      renderSidebar();
      renderEditor();
      renderPreview();
    });

    els.searchInput.addEventListener('input', (e) => {
      state.searchQuery = e.target.value;
      renderSidebar();
    });

    els.sceneTree.addEventListener('click', (e) => {
      const moveBtn = e.target.closest('[data-move-scene]');
      if (moveBtn) {
        e.stopPropagation();
        const sid = moveBtn.dataset.moveScene;
        const dir = Number(moveBtn.dataset.dir);
        const list = state.bundle.categories.main_active;
        const idx = list.findIndex((s) => s.id === sid);
        const target = idx + dir;
        if (idx >= 0 && target >= 0 && target < list.length) {
          const [it] = list.splice(idx, 1);
          list.splice(target, 0, it);
          markDirty();
          renderSidebar();
        }
        return;
      }

      const grpHdr = e.target.closest('[data-toggle-group]');
      if (grpHdr) {
        const gk = grpHdr.dataset.toggleGroup;
        state.collapsedGroups[gk] = !state.collapsedGroups[gk];
        renderSidebar();
        return;
      }

      const item = e.target.closest('[data-select-id]');
      if (item) {
        stopPlaytest();
        state.activeView = 'scene';
        state.activeCategory = item.dataset.selectCat;
        state.activeSceneId = item.dataset.selectId;
        state.activeSubTabIdx = 0;
        state.cursorLineIdx = 0;
        state.cursorRawRow = 0;
        const ctx = getActiveLinesContext();
        if (ctx && ctx.kind === 'lines') autoDetectScenePair(ctx.lines);
        renderSidebar();
        renderEditor({ preserveScroll: false });
        renderPreview();
      }
    });

    // Stage & Playtest controls
    $('btnStepFirst').addEventListener('click', () => {
      state.cursorLineIdx = 0;
      renderPreview();
      if (state.playtest.active) startTypewriterForLine(getActiveLinesContext()?.lines?.[0]);
    });
    $('btnStepPrev').addEventListener('click', () => stepPreview(-1));
    $('btnStepNext').addEventListener('click', () => stepPreview(1));
    $('btnPlayToggle').addEventListener('click', () => {
      if (state.playtest.active) stopPlaytest();
      else startPlaytest();
    });
    $('btnAutoPlay').addEventListener('click', () => {
      state.playtest.auto = !state.playtest.auto;
      els.btnAutoPlay.classList.toggle('active', state.playtest.auto);
      if (state.playtest.auto && !state.playtest.active) startPlaytest();
    });
    els.btnToggleSound.addEventListener('click', () => {
      state.playtest.soundOn = !state.playtest.soundOn;
      els.btnToggleSound.textContent = state.playtest.soundOn ? '🔊 音效开' : '🔇 静音';
    });
    els.btnToggleBanner.addEventListener('click', () => {
      state.playtest.bannerVisible = !state.playtest.bannerVisible;
      renderPreview();
    });

    els.stageViewportWrap.addEventListener('click', (e) => {
      const chBtn = e.target.closest('[data-preview-choice]');
      if (chBtn) {
        playSfxKey('ui_click');
        stepPreview(1);
        return;
      }
      playSfxKey('ui_click');
      stepPreview(1);
    });

    els.modalBackdrop.addEventListener('click', (e) => {
      if (e.target === els.modalBackdrop) closeModal();
    });

    // Global Ctrl+S save shortcut
    window.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
        e.preventDefault();
        saveDraftToServer();
      }
    });

    const ro = new ResizeObserver(() => layoutStageScale());
    ro.observe(els.stageViewportWrap);

    const initCtx = getActiveLinesContext();
    if (initCtx && initCtx.kind === 'lines') autoDetectScenePair(initCtx.lines);
    renderSidebar();
    renderEditor();
    renderPreview();
  }

  document.addEventListener('DOMContentLoaded', init);
})();
