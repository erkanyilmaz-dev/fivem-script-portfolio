'use strict';

/* ═══════════════════════════════════════════════════════════
   VaterPVP Inventory — script.js
   Özellikler:
     ✓ Drag & Drop (player ↔ player, player → ground, ground → player)
     ✓ Drop Zone (sağ panelin altı)
     ✓ Yerdeki eşyalar paneli (sağ taraf)
     ✓ Context Menu (Kullan / Yere Bırak / Al / Böl)
     ✓ Amount Modal (böl / miktar seç)
     ✓ Hotbar tab / Envanter tab
═══════════════════════════════════════════════════════════ */

// ── QB-Core item görselleri
const IMG_BASE = 'nui://qb-inventory/html/images/';

// ── State
const state = {
    items       : [],
    groundItems : [],
    weight      : 0,
    maxWeight   : 1000,
    maxSlots    : 41,
    hotbar      : 5,
};

// ── Drag state
let dragSource     = null;   // { slot, panel }  panel: 'player' | 'ground'
let dragItem       = null;   // item object

// ── Context state
let ctxTarget = null;  // { item, slot, panel }

// ── Amount modal callback
let amountCb = null;

// ── DOM refs
const wrapper       = document.getElementById('inventory-wrapper');
const playerGrid    = document.getElementById('player-slots');
const hotbarGrid    = document.getElementById('hotbar-slots');
const groundGrid    = document.getElementById('ground-slots');
const weightFill    = document.getElementById('weight-bar-fill');
const curWeightEl   = document.getElementById('current-weight');
const maxWeightEl   = document.getElementById('max-weight');
const ctxMenu       = document.getElementById('context-menu');
const ctxItemInfo   = document.getElementById('ctx-item-info');
const ctxUse        = document.getElementById('context-use');
const ctxDrop       = document.getElementById('context-drop');
const ctxPickup     = document.getElementById('context-pickup');
const ctxSplit      = document.getElementById('context-split');
const dropZone      = document.getElementById('drop-zone');
const amountModal   = document.getElementById('amount-modal');
const amountInput   = document.getElementById('amount-input');
const amountTitle   = document.getElementById('amount-title');
const amountConfirm = document.getElementById('amount-confirm');
const amountCancel  = document.getElementById('amount-cancel');
const amountMinus   = document.getElementById('amount-minus');
const amountPlus    = document.getElementById('amount-plus');
const closeBtn      = document.getElementById('close-btn');

// ── NUI Messages ──────────────────────────────────────────
window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'openInventory':
            if (data.data) applyState(data.data);
            showInventory();
            break;
        case 'closeInventory':
            hideInventory();
            break;
        case 'updateInventory':
            if (data.data) applyState(data.data);
            renderAll();
            break;
        case 'updateGround':
            state.groundItems = data.items || [];
            renderGround();
            break;
    }
});

function applyState(d) {
    state.items       = d.items       || [];
    state.groundItems = d.groundItems || [];
    state.weight      = d.weight      || 0;
    state.maxWeight   = d.maxWeight   || 1000;
    state.maxSlots    = d.maxSlots    || 41;
    state.hotbar      = d.hotbar      || 5;
}

// ── Open / Close ──────────────────────────────────────────
function showInventory() {
    wrapper.classList.remove('hidden');
    renderAll();
}

function hideInventory() {
    wrapper.classList.add('hidden');
    closeContextMenu();
    closeAmountModal();
}

function requestClose() {
    nuiFetch('closeInventory', {});
    hideInventory();
}

// ── Render ────────────────────────────────────────────────
function renderAll() {
    updateWeight();
    renderPlayer();
    renderGround();
}

function buildSlotMap(items) {
    const map = {};
    const list = Array.isArray(items) ? items : Object.values(items || {});
    for (const item of list) {
        if (item && item.slot != null) map[item.slot] = item;
    }
    return map;
}

function renderPlayer() {
    const slotMap      = buildSlotMap(state.items);
    const hotbar       = state.hotbar || 5;

    // Hotbar slotları (1..5)
    hotbarGrid.innerHTML = '';
    for (let i = 1; i <= hotbar; i++) {
        const slot = makeSlot(i, slotMap[i] || null, 'player', true);
        const badge = document.createElement('div');
        badge.className = 'hotbar-badge';
        badge.textContent = i;
        slot.appendChild(badge);
        hotbarGrid.appendChild(slot);
    }

    // Envanter slotları (6..total)
    playerGrid.innerHTML = '';
    for (let i = hotbar + 1; i <= state.maxSlots; i++) {
        playerGrid.appendChild(makeSlot(i, slotMap[i] || null, 'player', false));
    }
}

function renderGround() {
    groundGrid.innerHTML = '';
    const list = Array.isArray(state.groundItems)
        ? state.groundItems
        : Object.values(state.groundItems || {});

    if (list.length === 0) {
        const empty = document.createElement('div');
        empty.style.cssText = 'grid-column:1/-1;text-align:center;color:rgba(200,180,130,0.3);font-size:12px;padding:20px 0;';
        empty.textContent = 'Yakında hiç eşya yok.';
        groundGrid.appendChild(empty);
        return;
    }

    list.forEach((item, idx) => {
        groundGrid.appendChild(makeSlot(idx, item, 'ground', false));
    });
}

// ── Slot Factory ──────────────────────────────────────────
function makeSlot(slotIndex, item, panel, isHotbar) {
    const el = document.createElement('div');
    el.className = panel === 'ground' ? 'slot ground-slot' : 'slot';
    el.dataset.slot  = slotIndex;
    el.dataset.panel = panel;

    if (item && item.name) {
        el.classList.add('has-item');

        const img = document.createElement('img');
        img.className = 'item-img';
        img.src = `${IMG_BASE}${item.name}.png`;
        img.alt = item.label || item.name;
        img.draggable = false;
        img.onerror = () => { img.style.display = 'none'; appendEmoji(el, item); };
        el.appendChild(img);

        const label = document.createElement('div');
        label.className = 'item-label';
        label.textContent = item.label || item.name;
        el.appendChild(label);

        const amount = document.createElement('div');
        amount.className = 'item-amount';
        amount.textContent = (item.amount || 1) + 'x';
        el.appendChild(amount);

        // Drag
        el.draggable = true;
        el.addEventListener('dragstart', e => onDragStart(e, slotIndex, item, panel));
        el.addEventListener('dragend',   e => onDragEnd(e));

        // Çift tıkla kullan (sadece oyuncu)
        if (panel === 'player') {
            el.addEventListener('dblclick', () => useItem(item, slotIndex));
        }

        // Sağ tık
        el.addEventListener('contextmenu', e => {
            e.preventDefault();
            showContextMenu(e, item, slotIndex, panel);
        });
    } else {
        const num = document.createElement('div');
        num.className = 'slot-number';
        num.textContent = slotIndex;
        el.appendChild(num);
    }

    // Drop target
    el.addEventListener('dragover',  e => { e.preventDefault(); el.classList.add('drag-over'); });
    el.addEventListener('dragleave', ()  => el.classList.remove('drag-over'));
    el.addEventListener('drop',      e  => { e.preventDefault(); el.classList.remove('drag-over'); onDrop(slotIndex, panel); });

    return el;
}

function appendEmoji(el, item) {
    const EMOJI = { weapon_pistol:'🔫', weapon_tec9:'🔫', armor:'🛡️', medkit:'🩺', bandage:'🩹' };
    const em = document.createElement('div');
    em.className = 'item-emoji';
    em.textContent = EMOJI[item.name] || '📦';
    el.insertBefore(em, el.firstChild);
}

// ── Weight Bar ────────────────────────────────────────────
function updateWeight() {
    const cw  = parseFloat(state.weight)    || 0;
    const mw  = parseFloat(state.maxWeight) || 1000;
    const pct = Math.min((cw / mw) * 100, 100);
    curWeightEl.textContent = cw.toFixed(1);
    maxWeightEl.textContent = mw;
    weightFill.style.width  = pct + '%';
}

// ── Drag & Drop ───────────────────────────────────────────
function onDragStart(e, slotIndex, item, panel) {
    dragSource = { slot: slotIndex, panel };
    dragItem   = item;
    e.currentTarget.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', ''); // WebKit/CEF drag-drop uyumluluğu
    // Drop zone vurgula
    dropZone.classList.add('drag-active');
}

function onDragEnd(e) {
    e.currentTarget.classList.remove('dragging');
    dragSource = null;
    dragItem   = null;
    dropZone.classList.remove('drag-active');
    document.querySelectorAll('.drag-over').forEach(el => el.classList.remove('drag-over'));
}

function onDrop(toSlot, toPanel) {
    if (!dragSource) return;
    const from  = dragSource;
    const fItem = dragItem;

    // Aynı slot, hiçbir şey yapma
    if (from.slot === toSlot && from.panel === toPanel) return;

    if (from.panel === 'player' && toPanel === 'player') {
        // Oyuncu → Oyuncu (taşı)
        nuiFetch('moveItem', { from: from.slot, to: toSlot });

    } else if (from.panel === 'player' && toPanel === 'ground') {
        // Oyuncu → Yer (bırak)
        if (fItem && fItem.amount > 1) {
            openAmountModal(`${fItem.label || fItem.name} bırak`, fItem.amount, amt => {
                nuiFetch('dropItem', { name: fItem.name, slot: from.slot, amount: amt });
            });
        } else {
            nuiFetch('dropItem', { name: fItem.name, slot: from.slot, amount: 1 });
        }

    } else if (from.panel === 'ground' && toPanel === 'player') {
        // Yer → Oyuncu (al)
        if (fItem && fItem.amount > 1) {
            openAmountModal(`${fItem.label || fItem.name} al`, fItem.amount, amt => {
                nuiFetch('pickupItem', { groundIndex: from.slot, toSlot, amount: amt });
            });
        } else {
            nuiFetch('pickupItem', { groundIndex: from.slot, toSlot, amount: 1 });
        }
    }
}

// ── Drop Zone (sağ panel alt) ─────────────────────────────
dropZone.addEventListener('dragover', e => {
    e.preventDefault();
    dropZone.classList.add('drag-active');
});
dropZone.addEventListener('dragleave', () => {
    dropZone.classList.remove('drag-active');
});
dropZone.addEventListener('drop', e => {
    e.preventDefault();
    dropZone.classList.remove('drag-active');
    if (!dragSource || dragSource.panel !== 'player' || !dragItem) return;
    const item = dragItem;
    if (item.amount > 1) {
        openAmountModal(`${item.label || item.name} yere bırak`, item.amount, amt => {
            nuiFetch('dropItem', { name: item.name, slot: dragSource.slot, amount: amt });
        });
    } else {
        nuiFetch('dropItem', { name: item.name, slot: dragSource.slot, amount: 1 });
    }
});

// ── Item Actions ──────────────────────────────────────────
function useItem(item, slot) {
    if (!item) return;
    nuiFetch('useItem', { name: item.name, slot });
    closeContextMenu();
}

function dropItem(item, slot) {
    if (!item) return;
    if (item.amount > 1) {
        openAmountModal(`${item.label || item.name} yere bırak`, item.amount, amt => {
            nuiFetch('dropItem', { name: item.name, slot, amount: amt });
        });
    } else {
        nuiFetch('dropItem', { name: item.name, slot, amount: 1 });
    }
    closeContextMenu();
}

function pickupItem(item, groundIndex) {
    if (!item) return;
    if (item.amount > 1) {
        openAmountModal(`${item.label || item.name} al`, item.amount, amt => {
            nuiFetch('pickupItem', { groundIndex, amount: amt });
        });
    } else {
        nuiFetch('pickupItem', { groundIndex, amount: 1 });
    }
    closeContextMenu();
}

function splitItem(item, slot) {
    if (!item || item.amount < 2) return;
    openAmountModal(`${item.label || item.name} böl`, item.amount - 1, amt => {
        nuiFetch('splitItem', { name: item.name, slot, amount: amt });
    });
    closeContextMenu();
}

// ── Context Menu ──────────────────────────────────────────
function showContextMenu(e, item, slot, panel) {
    ctxTarget = { item, slot, panel };
    ctxItemInfo.textContent = `${item.label || item.name}  ×${item.amount || 1}`;

    // Hangi seçenekleri göster?
    ctxUse.style.display     = panel === 'player' ? 'flex' : 'none';
    ctxDrop.style.display    = panel === 'player' ? 'flex' : 'none';
    ctxPickup.style.display  = panel === 'ground' ? 'flex' : 'none';
    ctxSplit.style.display   = (panel === 'player' && item.amount > 1) ? 'flex' : 'none';

    ctxMenu.classList.remove('hidden');
    let x = e.clientX + 6, y = e.clientY + 6;
    if (x + 170 > window.innerWidth)  x = e.clientX - 174;
    if (y + 180 > window.innerHeight) y = e.clientY - 184;
    ctxMenu.style.left = x + 'px';
    ctxMenu.style.top  = y + 'px';
}

function closeContextMenu() {
    ctxMenu.classList.add('hidden');
    ctxTarget = null;
}

ctxUse.addEventListener('click', () => {
    if (ctxTarget) useItem(ctxTarget.item, ctxTarget.slot);
});
ctxDrop.addEventListener('click', () => {
    if (ctxTarget) dropItem(ctxTarget.item, ctxTarget.slot);
});
ctxPickup.addEventListener('click', () => {
    if (ctxTarget) pickupItem(ctxTarget.item, ctxTarget.slot);
});
ctxSplit.addEventListener('click', () => {
    if (ctxTarget) splitItem(ctxTarget.item, ctxTarget.slot);
});

document.addEventListener('click', e => {
    if (!ctxMenu.contains(e.target)) closeContextMenu();
});

// ── Amount Modal ──────────────────────────────────────────
function openAmountModal(title, max, cb) {
    amountTitle.textContent = title;
    amountInput.value = 1;
    amountInput.max   = max;
    amountCb = cb;
    amountModal.classList.remove('hidden');
    amountInput.focus();
}

function closeAmountModal() {
    amountModal.classList.add('hidden');
    amountCb = null;
}

amountMinus.addEventListener('click', () => {
    const v = parseInt(amountInput.value) || 1;
    if (v > 1) amountInput.value = v - 1;
});
amountPlus.addEventListener('click', () => {
    const v = parseInt(amountInput.value) || 1;
    const m = parseInt(amountInput.max)   || 9999;
    if (v < m) amountInput.value = v + 1;
});
amountConfirm.addEventListener('click', () => {
    const amt = parseInt(amountInput.value) || 1;
    if (amountCb) amountCb(amt);
    closeAmountModal();
});
amountCancel.addEventListener('click', closeAmountModal);
amountInput.addEventListener('keydown', e => {
    if (e.key === 'Enter') amountConfirm.click();
    if (e.key === 'Escape') closeAmountModal();
});

// ── Close Button & ESC ────────────────────────────────────
closeBtn.addEventListener('click', requestClose);
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (!amountModal.classList.contains('hidden')) {
            closeAmountModal();
        } else {
            requestClose();
        }
    }
});

// ── NUI Fetch Utility ─────────────────────────────────────
function nuiFetch(endpoint, body) {
    const res = (typeof window.GetParentResourceName === 'function')
        ? window.GetParentResourceName()
        : 'vater-inventory';
    return fetch(`https://${res}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    }).catch(() => {});
}

// ── Browser Preview ───────────────────────────────────────
if (!window.invokeNative) {
    document.addEventListener('DOMContentLoaded', () => {
        applyState({
            maxSlots  : 41,
            hotbar    : 5,
            maxWeight : 1000,
            weight    : 24.5,
            items: [
                { slot:1,  name:'weapon_pistol', label:'Pistol',  amount:1,  weight:150 },
                { slot:2,  name:'weapon_tec9',   label:'Tec-9',   amount:1,  weight:200 },
                { slot:3,  name:'armor',         label:'Zırh',    amount:2,  weight:300 },
                { slot:4,  name:'medkit',        label:'Medkit',  amount:5,  weight:50  },
                { slot:5,  name:'bandage',       label:'Bandaj',  amount:10, weight:15  },
                { slot:37, name:'weapon_pistol', label:'Pistol',  amount:1,  weight:150 },
                { slot:38, name:'medkit',        label:'Medkit',  amount:3,  weight:50  },
            ],
            groundItems: [
                { slot:0, name:'medkit',  label:'Medkit',  amount:2, weight:50  },
                { slot:1, name:'armor',   label:'Zırh',    amount:1, weight:300 },
                { slot:2, name:'bandage', label:'Bandaj',  amount:5, weight:15  },
            ],
        });
        showInventory();
    });
}
