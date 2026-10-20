// ═══════════════════════════════════════════════════════════════════════
//   VaterPVP Inventory  —  script_v2.js
//   Drag&Drop | Hotbar | Yerdeki Eşyalar | Context Menu | Böl | Miktar
// ═══════════════════════════════════════════════════════════════════════

'use strict';

const resourceName = (typeof window.GetParentResourceName === 'function')
    ? window.GetParentResourceName()
    : 'vater-inventory';
const IMG_BASE = `nui://${resourceName}/ui/icons/`;

// ── DOM Referansları ──────────────────────────────────────────────────
const wrapper      = document.getElementById('inventory-wrapper');
const playerSlots  = document.getElementById('player-slots');
const hotbarSlots  = document.getElementById('hotbar-slots');
const groundSlots  = document.getElementById('ground-slots');
const dropZone     = document.getElementById('drop-zone');
const closeBtn     = document.getElementById('close-btn');
const currentWt    = document.getElementById('current-weight');
const maxWt        = document.getElementById('max-weight');
const weightBarFill = document.getElementById('weight-bar-fill');

const ctxMenu      = document.getElementById('context-menu');
const ctxItemInfo  = document.getElementById('ctx-item-info');
const ctxUse       = document.getElementById('context-use');
const ctxDrop      = document.getElementById('context-drop');
const ctxPickup    = document.getElementById('context-pickup');
const ctxSplit     = document.getElementById('context-split');

const amountModal   = document.getElementById('amount-modal');
const amountTitle   = document.getElementById('amount-title');
const amountInput   = document.getElementById('amount-input');
const amountMinus   = document.getElementById('amount-minus');
const amountPlus    = document.getElementById('amount-plus');
const amountConfirm = document.getElementById('amount-confirm');
const amountCancel  = document.getElementById('amount-cancel');

// ── State ─────────────────────────────────────────────────────────────
let state = {
    maxSlots  : 41,
    hotbar    : 5,
    maxWeight : 1000,
    weight    : 0,
    items     : [],
    groundItems: [],
};

// Drag state
const drag = {
    active      : false,
    sourceSlot  : null,
    sourcePanel : null,
    item        : null,
    ghost       : null,
};

let ctxTarget = null;
let amountCb  = null;

// ── Ghost Element (sürüklenen ikon) ──────────────────────────────────
function createGhost(item) {
    const g = document.createElement('div');
    g.id = 'drag-ghost';
    g.style.cssText = `
        position:fixed; pointer-events:none; z-index:9999;
        width:56px; height:56px; border-radius:8px;
        background:rgba(200,160,60,0.25);
        border:1px solid rgba(200,160,60,0.6);
        display:flex; align-items:center; justify-content:center;
        font-size:22px; opacity:0.85; transform:translate(-50%,-50%);
    `;
    g.textContent = itemEmoji(item.name);
    document.body.appendChild(g);
    return g;
}

function moveGhost(e) {
    if (drag.ghost) {
        drag.ghost.style.left = e.clientX + 'px';
        drag.ghost.style.top  = e.clientY + 'px';
    }
}

function removeGhost() {
    if (drag.ghost) { drag.ghost.remove(); drag.ghost = null; }
}

// ── Emoji / İkon Yardımcı ─────────────────────────────────────────────
function itemEmoji(name) {
    if (!name) return '📦';
    const n = name.toLowerCase();
    if (n.includes('weapon') || n.includes('pistol') || n.includes('rifle') || n.includes('tec')) return '🔫';
    if (n.includes('medkit') || n.includes('bandage')) return '🩹';
    if (n.includes('armor'))  return '🛡️';
    if (n.includes('food') || n.includes('burger')) return '🍔';
    if (n.includes('water') || n.includes('drink')) return '💧';
    if (n.includes('phone'))  return '📱';
    if (n.includes('key'))    return '🔑';
    if (n.includes('drug') || n.includes('cocaine') || n.includes('weed')) return '💊';
    if (n.includes('money') || n.includes('cash'))  return '💵';
    return '📦';
}

// ── Temiz İsim Yardımcı ───────────────────────────────────────────────
function getCleanLabel(item) {
    if (!item) return '';
    const name = item.name.toLowerCase();
    const label = item.label || item.name;
    if (name === 'weapon_combatpistol') return 'Glock 19';
    if (name === 'pistol_ammo') return 'Mermi';
    if (name === 'heavyarmor') return 'Zırh';
    if (name === 'medkit') return 'Medkit';
    if (name === 'radio') return 'Telsiz';
    return label;
}

// ── Slot Oluşturma ────────────────────────────────────────────────────
function makeSlotEl(slot, item, panel) {
    const el = document.createElement('div');
    el.className = 'slot' + (item ? ' slot-filled' : '');
    el.dataset.slot  = slot;
    el.dataset.panel = panel;

    // Slot numarası
    const num = document.createElement('span');
    num.className = 'slot-number';
    num.textContent = slot;
    el.appendChild(num);

    if (item) {
        // Resim / ikon (Bulunamazsa qb-inventory'ye veya emoji'ye geri döner)
        const ico = document.createElement('div');
        ico.className = 'slot-icon';
        
        const img = document.createElement('img');
        img.className = 'item-img';
        img.src = `${IMG_BASE}${item.name.toLowerCase()}.png?v=3`;
        img.alt = '';
        
        let attempts = 0;
        img.onerror = () => {
            attempts++;
            if (attempts === 1) {
                // local resim bulunamadıysa qb-inventory'den yüklemeyi dene
                img.src = `nui://qb-inventory/html/images/${item.name.toLowerCase()}.png?v=3`;
            } else {
                // o da bulunamadıysa resmi gizle ve emoji bas
                img.style.display = 'none';
                ico.textContent = itemEmoji(item.name);
            }
        };
        ico.appendChild(img);
        el.appendChild(ico);

        // İsim
        const lbl = document.createElement('div');
        lbl.className = 'item-label';
        lbl.textContent = getCleanLabel(item);
        el.appendChild(lbl);

        // Miktar
        if (item.amount > 1) {
            const amt = document.createElement('div');
            amt.className = 'item-amount';
            amt.textContent = '×' + item.amount;
            el.appendChild(amt);
        }

        // Ağırlık
        if (item.weight) {
            const wt = document.createElement('div');
            wt.className = 'item-weight';
            wt.textContent = (item.weight * (item.amount || 1) / 1000).toFixed(1) + 'kg';
            el.appendChild(wt);
        }

        // ── Drag başlat ──────────────────────────────────────────────
        el.addEventListener('mousedown', (e) => {
            if (e.button !== 0) return;
            e.preventDefault();
            closeContextMenu();

            drag.active      = true;
            drag.sourceSlot  = slot;
            drag.sourcePanel = panel;
            drag.item        = item;
            drag.ghost       = createGhost(item);
            moveGhost(e);
            el.style.opacity = '0.35';
        });

        // ── Sağ tık — Context menu ───────────────────────────────────
        el.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            showContextMenu(e, item, slot, panel);
        });

        // ── Çift tık — Eşyayı Kullan ─────────────────────────────────────
        el.addEventListener('dblclick', (e) => {
            e.preventDefault();
            if (panel === 'player') {
                useItem(item, slot);
            }
        });
    }

    // ── Drop hedefi ──────────────────────────────────────────────────
    el.addEventListener('mouseup', () => {
        if (drag.active) {
            handleDrop(slot, panel);
            endDrag();
        }
    });

    el.addEventListener('mouseenter', () => {
        if (drag.active && drag.sourceSlot !== slot) {
            el.style.boxShadow = '0 0 0 2px var(--gold)';
        }
    });

    el.addEventListener('mouseleave', () => {
        if (drag.active) {
            el.style.boxShadow = '';
        }
    });

    return el;
}

// ── Drag Bitir ────────────────────────────────────────────────────────
function endDrag() {
    removeGhost();
    // Opaklığı geri al
    document.querySelectorAll('.slot').forEach(el => {
        el.style.opacity   = '';
        el.style.boxShadow = '';
    });
    dropZone.style.borderColor = '';
    dropZone.style.background  = '';
    drag.active      = false;
    drag.sourceSlot  = null;
    drag.sourcePanel = null;
    drag.item        = null;
}

document.addEventListener('mousemove', moveGhost);
document.addEventListener('mouseup', () => {
    if (drag.active) {
        // Hiçbir slota bırakılmadı, iptal
        endDrag();
    }
});

// ── Grid Render ───────────────────────────────────────────────────────
function buildItemMap(items) {
    const map = {};
    (items || []).forEach(it => {
        if (it && it.slot != null) map[it.slot] = it;
    });
    return map;
}

function renderPlayerSlots() {
    playerSlots.innerHTML = '';
    hotbarSlots.innerHTML = '';

    const map     = buildItemMap(state.items);
    const total   = state.maxSlots;
    const hotbar  = state.hotbar;

    // Hotbar slotları (1..5)
    for (let s = 1; s <= hotbar; s++) {
        hotbarSlots.appendChild(makeSlotEl(s, map[s] || null, 'player'));
    }

    // Ana envanter slotları (6..41)
    for (let s = hotbar + 1; s <= total; s++) {
        playerSlots.appendChild(makeSlotEl(s, map[s] || null, 'player'));
    }
}

function renderGroundSlots() {
    groundSlots.innerHTML = '';
    (state.groundItems || []).forEach((item, idx) => {
        groundSlots.appendChild(makeSlotEl(idx, item, 'ground'));
    });
    // En az 6 boş slot
    const existing = (state.groundItems || []).length;
    for (let i = existing; i < 6; i++) {
        groundSlots.appendChild(makeSlotEl(i, null, 'ground'));
    }
}

function renderWeight() {
    const wKg  = (state.weight  / 1000).toFixed(1);
    const mKg  = (state.maxWeight / 1000).toFixed(1);
    currentWt.textContent = wKg;
    maxWt.textContent     = mKg;
    const pct = Math.min(100, (state.weight / state.maxWeight) * 100);
    weightBarFill.style.width = pct + '%';
    weightBarFill.style.background =
        pct > 90 ? 'var(--danger)' :
        pct > 70 ? 'var(--warn,#e6a817)' : 'var(--gold)';
}

function applyState(data) {
    state = Object.assign(state, data);

    // Normalize items to array to prevent crash on sparse data
    if (!state.items) {
        state.items = [];
    } else if (typeof state.items === 'object' && !Array.isArray(state.items)) {
        state.items = Object.values(state.items);
    }

    // Normalize groundItems to array
    if (!state.groundItems) {
        state.groundItems = [];
    } else if (typeof state.groundItems === 'object' && !Array.isArray(state.groundItems)) {
        state.groundItems = Object.values(state.groundItems);
    }

    renderPlayerSlots();
    renderGroundSlots();
    renderWeight();
}

// HUD Hotbar timer reference
let hudHotbarTimer = null;

function showHUDHotbar(items) {
    const container = document.getElementById('hud-hotbar-slots');
    if (!container) return;
    container.innerHTML = '';

    for (let s = 1; s <= 5; s++) {
        const item = items[s] || items[s.toString()] || null;
        
        const el = document.createElement('div');
        el.className = 'slot' + (item ? ' slot-filled' : '');
        
        // Slot number
        const num = document.createElement('span');
        num.className = 'slot-number';
        num.textContent = s;
        el.appendChild(num);

        if (item) {
            // Resim / ikon (Bulunamazsa qb-inventory'ye veya emoji'ye geri döner)
            const ico = document.createElement('div');
            ico.className = 'slot-icon';
            
            const img = document.createElement('img');
            img.className = 'item-img';
            img.src = `${IMG_BASE}${item.name.toLowerCase()}.png?v=3`;
            img.alt = '';
            
            let attempts = 0;
            img.onerror = () => {
                attempts++;
                if (attempts === 1) {
                    // local resim bulunamadıysa qb-inventory'den yüklemeyi dene
                    img.src = `nui://qb-inventory/html/images/${item.name.toLowerCase()}.png?v=3`;
                } else {
                    // o da bulunamadıysa resmi gizle ve emoji bas
                    img.style.display = 'none';
                    ico.textContent = itemEmoji(item.name);
                }
            };
            ico.appendChild(img);
            el.appendChild(ico);

            // Label
            const lbl = document.createElement('div');
            lbl.className = 'item-label';
            lbl.textContent = getCleanLabel(item);
            el.appendChild(lbl);

            // Amount
            if (item.amount > 1) {
                const amt = document.createElement('div');
                amt.className = 'item-amount';
                amt.textContent = '×' + item.amount;
                el.appendChild(amt);
            }
        }
        container.appendChild(el);
    }

    const hudWrapper = document.getElementById('hud-hotbar-wrapper');
    if (hudWrapper) {
        hudWrapper.classList.remove('hud-hotbar-hidden');

        if (hudHotbarTimer) clearTimeout(hudHotbarTimer);
        
        hudHotbarTimer = setTimeout(() => {
            hudWrapper.classList.add('hud-hotbar-hidden');
        }, 5000);
    }
}

// ── Show / Hide ───────────────────────────────────────────────────────
function showInventory() {
    wrapper.classList.remove('hidden');
    const hudWrapper = document.getElementById('hud-hotbar-wrapper');
    if (hudWrapper) hudWrapper.classList.add('hud-hotbar-hidden');
    if (hudHotbarTimer) clearTimeout(hudHotbarTimer);
}

function hideInventory() {
    wrapper.classList.add('hidden');
    closeContextMenu();
    closeAmountModal();
    endDrag();
}

function requestClose() {
    nuiFetch('closeInventory', {});
    hideInventory();
}

// ── NUI Events (FiveM → NUI) ──────────────────────────────────────────
window.addEventListener('message', (ev) => {
    const d = ev.data;
    if (!d || !d.action) return;

    if (d.action === 'openInventory') {
        applyState(d.data || {});
        showInventory();
    } else if (d.action === 'closeInventory') {
        hideInventory();
    } else if (d.action === 'updateInventory') {
        applyState(d.data || {});
    } else if (d.action === 'showHUDHotbar') {
        const hudWrapper = document.getElementById('hud-hotbar-wrapper');
        if (hudWrapper && !hudWrapper.classList.contains('hud-hotbar-hidden')) {
            hudWrapper.classList.add('hud-hotbar-hidden');
            if (hudHotbarTimer) {
                clearTimeout(hudHotbarTimer);
                hudHotbarTimer = null;
            }
        } else {
            showHUDHotbar(d.items || {});
        }
    }
});

// ── Drop Handler ─────────────────────────────────────────────────────
function handleDrop(toSlot, toPanel) {
    if (drag.sourceSlot == null) return;
    const from   = drag.sourceSlot;
    const fItem  = drag.item;
    const fPanel = drag.sourcePanel;

    if (from === toSlot && fPanel === toPanel) return;

    if (fPanel === 'player' && toPanel === 'player') {
        // Envanter içi taşıma / swap
        nuiFetch('moveItem', { from, to: toSlot });

    } else if (fPanel === 'player' && toPanel === 'ground') {
        // Yere bırak
        handleDropToGround();

    } else if (fPanel === 'ground' && toPanel === 'player') {
        // Yerden al
        if (fItem && fItem.amount > 1) {
            openAmountModal(`${fItem.label || fItem.name} al`, fItem.amount, amt => {
                nuiFetch('pickupItem', { groundIndex: fItem.id, toSlot, amount: amt });
            });
        } else {
            nuiFetch('pickupItem', { groundIndex: fItem.id, toSlot, amount: 1 });
        }
    }
}

function handleDropToGround() {
    const fItem = drag.item;
    const from  = drag.sourceSlot;
    if (!fItem) return;
    if (fItem.amount > 1) {
        openAmountModal(`${fItem.label || fItem.name} yere bırak`, fItem.amount, amt => {
            nuiFetch('dropItem', { name: fItem.name, slot: from, amount: amt });
        });
    } else {
        nuiFetch('dropItem', { name: fItem.name, slot: from, amount: 1 });
    }
}

// Drop Zone — sürükleyip zone'a bırak
dropZone.addEventListener('mouseenter', () => {
    if (drag.active && drag.sourcePanel === 'player') {
        dropZone.style.borderColor = 'var(--gold)';
        dropZone.style.background  = 'var(--gold-dim,rgba(200,160,60,0.12))';
    }
});
dropZone.addEventListener('mouseleave', () => {
    dropZone.style.borderColor = '';
    dropZone.style.background  = '';
});
dropZone.addEventListener('mouseup', () => {
    if (drag.active && drag.sourcePanel === 'player') {
        handleDropToGround();
        endDrag();
    }
});

// ── Item Actions ──────────────────────────────────────────────────────
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

// ── Context Menu ──────────────────────────────────────────────────────
function showContextMenu(e, item, slot, panel) {
    ctxTarget = { item, slot, panel };
    ctxItemInfo.textContent = `${item.label || item.name}  ×${item.amount || 1}`;

    ctxUse.style.display    = panel === 'player' ? 'flex' : 'none';
    ctxDrop.style.display   = panel === 'player' ? 'flex' : 'none';
    ctxPickup.style.display = panel === 'ground' ? 'flex' : 'none';
    ctxSplit.style.display  = (panel === 'player' && item.amount > 1) ? 'flex' : 'none';

    ctxMenu.classList.remove('hidden');
    let x = e.clientX + 6, y = e.clientY + 6;
    if (x + 170 > window.innerWidth)  x = e.clientX - 174;
    if (y + 200 > window.innerHeight) y = e.clientY - 204;
    ctxMenu.style.left = x + 'px';
    ctxMenu.style.top  = y + 'px';
}

function closeContextMenu() {
    ctxMenu.classList.add('hidden');
    ctxTarget = null;
}

ctxUse.addEventListener('click',    () => { if (ctxTarget) useItem(ctxTarget.item, ctxTarget.slot); });
ctxDrop.addEventListener('click',   () => { if (ctxTarget) dropItem(ctxTarget.item, ctxTarget.slot); });
ctxPickup.addEventListener('click', () => { if (ctxTarget) pickupItem(ctxTarget.item, ctxTarget.item.id); });
ctxSplit.addEventListener('click',  () => { if (ctxTarget) splitItem(ctxTarget.item, ctxTarget.slot); });

document.addEventListener('click', e => {
    if (!ctxMenu.contains(e.target)) closeContextMenu();
});

// ── Amount Modal ──────────────────────────────────────────────────────
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
    if (e.key === 'Enter')  amountConfirm.click();
    if (e.key === 'Escape') closeAmountModal();
});

// ── Close Button & ESC ────────────────────────────────────────────────
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

// ── NUI Fetch Utility ─────────────────────────────────────────────────
function nuiFetch(endpoint, body) {
    const res = (typeof window.GetParentResourceName === 'function')
        ? window.GetParentResourceName()
        : 'vater-inventory';
    return fetch(`https://${res}/${endpoint}`, {
        method  : 'POST',
        headers : { 'Content-Type': 'application/json' },
        body    : JSON.stringify(body),
    }).catch(() => {});
}

// ── Browser Preview (geliştirme ortamı için) ──────────────────────────
if (!window.invokeNative) {
    document.addEventListener('DOMContentLoaded', () => {
        applyState({
            maxSlots  : 41,
            hotbar    : 5,
            maxWeight : 1000000,
            weight    : 24500,
            items: [
                { slot:1,  name:'weapon_pistol', label:'Pistol',  amount:1,  weight:1500 },
                { slot:2,  name:'weapon_tec9',   label:'Tec-9',   amount:1,  weight:2000 },
                { slot:3,  name:'armor',         label:'Zırh',    amount:2,  weight:3000 },
                { slot:4,  name:'medkit',        label:'Medkit',  amount:5,  weight:500  },
                { slot:5,  name:'bandage',       label:'Bandaj',  amount:10, weight:150  },
                { slot:37, name:'weapon_pistol', label:'Pistol',  amount:1,  weight:1500 },
                { slot:38, name:'medkit',        label:'Medkit',  amount:3,  weight:500  },
            ],
            groundItems: [
                { slot:0, name:'medkit',  label:'Medkit',  amount:2, weight:500  },
                { slot:1, name:'armor',   label:'Zırh',    amount:1, weight:3000 },
                { slot:2, name:'bandage', label:'Bandaj',  amount:5, weight:150  },
            ],
        });
        showInventory();
    });
}
