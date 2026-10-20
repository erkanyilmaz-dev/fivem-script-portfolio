let activeWeapon = null;
let availableTints = [];
let availablePatterns = [];
let customSkins = [];
let savedSkinsList = [];
let unlockedSkinsMap = {};
let nodesConfig = {};
let categorySettings = {};
let prices = { attachment: 500, tint: 250, customSkin: 1500 };

let currentComponents = {};
let selectedTintId = 0;
let selectedCustomSkin = null;
let originalComponents = {};
let originalTintId = 0;
let originalCustomSkin = null;
let activeDrawerTab = 'nodes';

let isDraggingCam = false;
let lastMouseX = 0;
let lastMouseY = 0;

// Current Pattern Generator State
let currentPatternId = "lava_inferno";
let primaryColorVal = "#f97316";
let secondaryColorVal = "#7c2d12";

document.addEventListener('DOMContentLoaded', () => {
    initEventListeners();
    window.addEventListener('resize', drawGunsmithLines);
});

// NUI Message Listener
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === "openUI") {
        activeWeapon = data.weapon;
        availableTints = data.tints || [];
        customSkins = data.skins || (data.streamFolders || []).map(id => ({ id, label: id }));
        availablePatterns = data.patterns || [];
        nodesConfig = data.nodesConfig || {};
        categorySettings = data.categorySettings || {};
        prices = data.prices || prices;
        savedSkinsList = data.savedSkins || [];
        unlockedSkinsMap = data.unlockedSkins || {};

        currentComponents = Object.assign({}, activeWeapon.activeComponents || {});
        selectedTintId = activeWeapon.activeTint || 0;
        selectedCustomSkin = activeWeapon.activeSkin || null;
        originalComponents = Object.assign({}, currentComponents);
        originalTintId = selectedTintId;
        originalCustomSkin = selectedCustomSkin;

        // Populate Header & Info
        document.getElementById('weapon-title').innerHTML = `${activeWeapon.label || activeWeapon.name} <span class="mw-class-badge">${(activeWeapon.category || 'TACTICAL').toUpperCase()}</span>`;
        
        renderFloatingNodes();
        updatePriceSummary();
        updateWeaponStats();
        updateLockedPreviewBanner();

        document.getElementById('app').classList.remove('hidden');
        
        setTimeout(() => {
            drawGunsmithLines();
        }, 80);
    } else if (data.action === "closeUI") {
        document.getElementById('app').classList.add('hidden');
        updateLockedPreviewBanner(true);
    } else if (data.action === "updateUnlockedSkins") {
        unlockedSkinsMap = data.unlockedSkins || {};
        updateLockedPreviewBanner();
        if (activeDrawerTab === 'tints') {
            openDrawer('tints');
        }
    } else if (data.action === "updateSavedSkins") {
        savedSkinsList = data.skins || [];
        if (activeDrawerTab === 'saved-skins') {
            openDrawer('saved-skins');
        }
    } else if (data.action === "setSelectedSkin") {
        selectedCustomSkin = data.skin || null;
        updatePriceSummary();
        updateLockedPreviewBanner();
        if (activeDrawerTab === 'tints') {
            openDrawer('tints');
        }
    } else if (data.action === "setAttachmentState") {
        currentComponents[data.key] = data.state === true;
        updatePriceSummary();
        updateWeaponStats();
        renderFloatingNodes();
        if (activeDrawerTab === data.key) {
            openDrawer(data.key);
        }
    }
});

// Event Listeners Setup
function initEventListeners() {
    // Header Navigation Tabs
    const mwTabs = document.querySelectorAll('.mw-tab');
    mwTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            mwTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            const targetTab = tab.getAttribute('data-tab');
            openDrawer(targetTab);
        });
    });

    // Close Drawer Button
    document.getElementById('btn-close-drawer').addEventListener('click', () => {
        closeDrawer();
    });

    // Action Buttons
    document.getElementById('btn-cancel').addEventListener('click', () => {
        postNUI('closeUI', { restore: true });
    });

    document.getElementById('btn-save').addEventListener('click', () => {
        // KİLİTLİ SKIN UYGULAMA ENGELİ
        if (selectedCustomSkin) {
            const skinDef = customSkins.find(s => (typeof s === 'object' ? s.id : s) === selectedCustomSkin);
            const isLocked = skinDef && skinDef.isLocked && !unlockedSkinsMap[selectedCustomSkin];
            if (isLocked) {
                const label = (skinDef && skinDef.label) || selectedCustomSkin;
                postNUI('notifyLocked', { label: label });
                showToastNotification(`🔒 "${label}" kaplaması kilitlidir! Bu kaplama VIP veya Mağazadan satın alınmalıdır.`);
                return;
            }
        }

        postNUI('saveWeaponMods', {
            components: currentComponents,
            tint: selectedTintId,
            customSkin: selectedCustomSkin
        });
    });

    // ESC Key Listener
    document.addEventListener('keyup', (e) => {
        if (e.key === 'Escape' || e.keyCode === 27) {
            if (!document.getElementById('app').classList.contains('hidden')) {
                postNUI('closeUI', { restore: true });
            }
        }
    });

    // 3D Camera Controls
    document.addEventListener('mousedown', (e) => {
        if (document.getElementById('app').classList.contains('hidden')) return;
        if (e.target.closest('.mw-header') || e.target.closest('.mw-footer') || e.target.closest('.mw-drawer') || e.target.closest('.cod-node-card')) return;
        
        isDraggingCam = true;
        lastMouseX = e.clientX;
        lastMouseY = e.clientY;
    });

    document.addEventListener('mousemove', (e) => {
        if (!isDraggingCam) return;
        const deltaX = e.clientX - lastMouseX;
        const deltaY = e.clientY - lastMouseY;
        lastMouseX = e.clientX;
        lastMouseY = e.clientY;

        postNUI('rotateCamera', { deltaX: deltaX, deltaY: deltaY });
        drawGunsmithLines();
    });

    document.addEventListener('mouseup', () => {
        isDraggingCam = false;
    });

    document.addEventListener('wheel', (e) => {
        if (document.getElementById('app').classList.contains('hidden')) return;
        if (e.target.closest('.mw-drawer')) return;

        const zoom = e.deltaY > 0 ? 1 : -1;
        postNUI('rotateCamera', { zoom: zoom });
    });
}

// Floating Call of Duty Gunsmith Nodes Rendering
function renderFloatingNodes() {
    const container = document.getElementById('nodes-container');
    container.innerHTML = '';

    if (!activeWeapon || !activeWeapon.attachments) return;

    const category = activeWeapon.category || 'Rifle';
    const catData = categorySettings[category] || categorySettings['Rifle'] || {};
    const customNodes = catData.nodes || {};

    const fallbackNodes = {
        suppressor: { left: '10%', top: '38%', targetX: 18, targetY: 44 },
        scope:      { left: '48%', top: '20%', targetX: 52, targetY: 38 },
        flashlight: { left: '26%', top: '64%', targetX: 32, targetY: 47 },
        clip:       { left: '56%', top: '66%', targetX: 56, targetY: 52 },
        grip:       { left: '38%', top: '72%', targetX: 42, targetY: 50 },
        finish:     { left: '76%', top: '32%', targetX: 78, targetY: 42 }
    };

    for (const [key, attachInfo] of Object.entries(activeWeapon.attachments)) {
        const isEquipped = !!currentComponents[key];
        const pos = customNodes[key] || fallbackNodes[key] || { left: '50%', top: '50%', targetX: 50, targetY: 50 };
        const nodeMeta = nodesConfig[key] || { title: attachInfo.category, icon: 'fa-cube' };

        const nodeCard = document.createElement('div');
        nodeCard.className = `cod-node-card ${isEquipped ? 'active-equipped' : ''}`;
        nodeCard.id = `node-card-${key}`;
        nodeCard.style.left = pos.left;
        nodeCard.style.top = pos.top;
        nodeCard.setAttribute('data-target-x', pos.targetX);
        nodeCard.setAttribute('data-target-y', pos.targetY);

        nodeCard.innerHTML = `
            <div class="node-icon-box">
                <i class="fa-solid ${nodeMeta.icon}"></i>
            </div>
            <div class="node-info">
                <span class="node-slot-title">${nodeMeta.title || attachInfo.category}</span>
                <span class="node-slot-sub">${isEquipped ? attachInfo.label : 'SLOT EMPTY'}</span>
            </div>
            <span class="node-status-badge ${isEquipped ? 'equipped' : ''}">${isEquipped ? 'EQUIPPED' : 'EMPTY'}</span>
        `;

        nodeCard.addEventListener('click', () => {
            openDrawer(key);
        });

        container.appendChild(nodeCard);
    }
}

// Draw SVG Connecting Lines
function drawGunsmithLines() {
    const svg = document.getElementById('gunsmith-lines-svg');
    if (!svg || document.getElementById('app').classList.contains('hidden')) return;

    svg.innerHTML = '';

    const nodes = document.querySelectorAll('.cod-node-card');
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    nodes.forEach(node => {
        const rect = node.getBoundingClientRect();
        const startX = rect.left + rect.width / 2;
        const startY = rect.top + rect.height / 2;

        const targetXPercent = parseFloat(node.getAttribute('data-target-x')) || 50;
        const targetYPercent = parseFloat(node.getAttribute('data-target-y')) || 50;

        const endX = (targetXPercent / 100) * viewportWidth;
        const endY = (targetYPercent / 100) * viewportHeight;

        // Create line group
        const g = document.createElementNS('http://www.w3.org/2000/svg', 'g');

        // Path angled line
        const midX = startX + (endX - startX) * 0.5;
        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        const pathData = `M ${startX} ${startY} L ${midX} ${startY} L ${endX} ${endY}`;
        
        const isEquipped = node.classList.contains('active-equipped');
        path.setAttribute('d', pathData);
        path.setAttribute('stroke', isEquipped ? '#ff9d00' : '#38bdf8');
        path.setAttribute('stroke-width', '1.5');
        path.setAttribute('fill', 'none');
        path.setAttribute('stroke-dasharray', '4 2');
        g.appendChild(path);

        // Target Circle at attachment location
        const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        circle.setAttribute('cx', endX);
        circle.setAttribute('cy', endY);
        circle.setAttribute('r', '4.5');
        circle.setAttribute('fill', isEquipped ? '#ff9d00' : '#38bdf8');
        circle.setAttribute('stroke', '#ffffff');
        circle.setAttribute('stroke-width', '1.5');
        g.appendChild(circle);

        svg.appendChild(g);
    });
}

// Slide-Over Drawer Controller
function openDrawer(tabKey) {
    activeDrawerTab = tabKey;
    const drawer = document.getElementById('drawer-panel');
    const title = document.getElementById('drawer-title');
    const body = document.getElementById('drawer-body-content');

    drawer.classList.remove('hidden');
    body.innerHTML = '';
    setTimeout(drawGunsmithLines, 60);

    if (tabKey === 'tints') {
        title.innerHTML = `<i class="fa-solid fa-brush"></i> CAMOS & SKINS`;
        
        // Render Base GTA Tints
        body.innerHTML = `<div style="font-family: 'Share Tech Mono', monospace; font-size:10px; color:var(--lime-primary); letter-spacing:1px; margin:5px 0;">// STANDARD FACTORY TINTS</div>`;
        availableTints.forEach(tint => {
            const isActive = selectedTintId === tint.id && !selectedCustomSkin;
            const tintBadge = isActive
                ? (tint.id === originalTintId ? '[EQUIPPED]' : `$${prices.tint}`)
                : (tint.id === originalTintId ? '[INSTALLED]' : `$${prices.tint}`);
            const card = document.createElement('div');
            card.className = `mw-item-card ${isActive ? 'active' : ''}`;
            card.innerHTML = `
                <div class="mw-item-info" style="display:flex; align-items:center; gap:12px;">
                    <div style="width:26px; height:26px; background:${tint.hex}; border:1px solid var(--border-slate); box-shadow: 0 0 10px ${tint.hex}; flex-shrink:0; clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);"></div>
                    <div>
                        <span class="mw-item-title">${tint.label}</span>
                        <span class="mw-item-desc">${tint.desc || 'Factory Camo Finish'}</span>
                    </div>
                </div>
                <span class="mw-item-badge">${tintBadge}</span>
            `;

            card.addEventListener('click', () => {
                selectedTintId = tint.id;
                selectedCustomSkin = null;
                postNUI('previewTint', { tintId: tint.id });
                updatePriceSummary();
                openDrawer('tints');
            });

            body.appendChild(card);
        });

        // Render configured custom skins header
        const customSkinsHeader = document.createElement('div');
        customSkinsHeader.style.cssText = "font-family: 'Share Tech Mono', monospace; font-size:10px; color:var(--amber-primary); letter-spacing:1px; margin:15px 0 5px 0;";
        customSkinsHeader.textContent = '// CUSTOM WEAPON CAMOS';
        body.appendChild(customSkinsHeader);
        
        // Add Default Factory Skin button
        const isDefaultActive = !selectedCustomSkin && selectedTintId === 0;
        const defaultCard = document.createElement('div');
        defaultCard.className = `mw-item-card ${isDefaultActive ? 'active' : ''}`;
        defaultCard.innerHTML = `
            <div class="mw-item-info" style="display:flex; align-items:center; gap:12px;">
                <i class="fa-solid fa-rotate-left" style="color:var(--lime-primary); font-size:16px;"></i>
                <div>
                    <span class="mw-item-title">FACTORY DEFAULT</span>
                    <span class="mw-item-desc">Original Weapon Finish</span>
                </div>
            </div>
            <span class="mw-item-badge">$0</span>
        `;
        defaultCard.addEventListener('click', () => {
            selectedCustomSkin = null;
            selectedTintId = 0;
            postNUI('previewCustomSkin', { skin: '', tintId: 0 });
            updatePriceSummary();
            updateLockedPreviewBanner();
            openDrawer('tints');
        });
        body.appendChild(defaultCard);

        // Add compatible configured skins
        if (customSkins && customSkins.length > 0) {
            customSkins.forEach(skin => {
                const skinId = typeof skin === 'string' ? skin : skin.id;
                const skinLabel = typeof skin === 'string' ? skin : (skin.label || skin.id);
                const skinDescription = typeof skin === 'string'
                    ? `Skin: ${skin}`
                    : (skin.description || `${(skin.mode || 'component').toUpperCase()} finish`);
                const isLocked = typeof skin === 'object' && skin.isLocked && !unlockedSkinsMap[skinId];
                const isActive = selectedCustomSkin === skinId;
                
                let skinBadge = skinId === originalCustomSkin ? '[EQUIPPED]' : `$${prices.customSkin}`;
                if (isLocked) {
                    skinBadge = `<i class="fa-solid fa-lock" style="color:#ef4444; margin-right:4px;"></i> [🔒 KİLİTLİ]`;
                }

                const folderCard = document.createElement('div');
                folderCard.className = `mw-item-card ${isActive ? 'active' : ''} ${isLocked ? 'locked-skin' : ''}`;
                folderCard.innerHTML = `
                    <div class="mw-item-info">
                        <span class="mw-item-title">${isLocked ? `<i class="fa-solid fa-lock" style="color:#ef4444; font-size:13px; margin-right:6px;"></i>` : ''}${skinLabel}</span>
                        <span class="mw-item-desc">${isLocked ? '<span style="color:#f87171; font-weight:700;">[MAĞAZA / DONATE ÖĞESİ]</span> — ' : ''}${skinDescription}</span>
                    </div>
                    <span class="mw-item-badge ${isLocked ? 'locked-badge' : ''}">${skinBadge}</span>
                `;

                folderCard.addEventListener('click', () => {
                    selectedCustomSkin = skinId;
                    // Kilitli olsa bile 3D model üzerinde ÖNİZLEME yapılmasına izin verilir!
                    postNUI('previewCustomSkin', { skin: skinId, tintId: selectedTintId });
                    updatePriceSummary();
                    updateLockedPreviewBanner();
                    openDrawer('tints');
                });
                body.appendChild(folderCard);
            });
        }

    } else {
        // Specific Node Attachment Slot
        const attachInfo = activeWeapon.attachments[tabKey];
        if (attachInfo) {
            title.innerHTML = `<i class="fa-solid fa-sliders"></i> ${attachInfo.label} SELECTOR`;
            const isEquipped = !!currentComponents[tabKey];
            const wasEquipped = !!originalComponents[tabKey];
            const attachmentBadge = isEquipped
                ? (wasEquipped ? '[EQUIPPED]' : `$${prices.attachment}`)
                : (wasEquipped ? '[REMOVE]' : '$0');

            const card = document.createElement('div');
            card.className = `mw-item-card ${isEquipped ? 'active' : ''}`;
            card.innerHTML = `
                <div class="mw-item-info">
                    <span class="mw-item-title">${attachInfo.label}</span>
                    <span class="mw-item-desc">Category: ${attachInfo.category}</span>
                </div>
                <span class="mw-item-badge">${attachmentBadge}</span>
            `;

            card.addEventListener('click', () => {
                currentComponents[tabKey] = !currentComponents[tabKey];
                postNUI('previewAttachment', { key: tabKey, state: currentComponents[tabKey] });
                updatePriceSummary();
                updateWeaponStats();
                renderFloatingNodes();
                openDrawer(tabKey);
            });

            body.appendChild(card);
        }
    }
}

function closeDrawer() {
    document.getElementById('drawer-panel').classList.add('hidden');
    setTimeout(drawGunsmithLines, 60);
}

// Update Call of Duty Weapon Stats
function updateWeaponStats() {
    if (!activeWeapon || !activeWeapon.baseStats) return;

    const base = activeWeapon.baseStats;
    let stats = {
        damage: base.damage || 50,
        range: base.range || 50,
        accuracy: base.accuracy || 60,
        control: base.control || 55,
        mobility: base.mobility || 70
    };

    // Add attachments stat modifiers
    if (activeWeapon.attachments) {
        for (const [key, isEquipped] of Object.entries(currentComponents)) {
            if (isEquipped && activeWeapon.attachments[key] && activeWeapon.attachments[key].stats) {
                const mod = activeWeapon.attachments[key].stats;
                if (mod.damage) stats.damage += mod.damage;
                if (mod.range) stats.range += mod.range;
                if (mod.accuracy) stats.accuracy += mod.accuracy;
                if (mod.control) stats.control += mod.control;
                if (mod.mobility) stats.mobility += mod.mobility;
            }
        }
    }

    ['damage', 'range', 'accuracy', 'control', 'mobility'].forEach(st => {
        const val = Math.max(5, Math.min(100, stats[st]));
        const bar = document.getElementById(`stat-bar-${st}`);
        const valText = document.getElementById(`stat-val-${st}`);
        if (bar) bar.style.width = `${val}%`;
        if (valText) valText.innerText = val;
    });
}

// Update Price Calculation
function updatePriceSummary() {
    let total = 0;
    for (const [key, active] of Object.entries(currentComponents)) {
        if (active && !originalComponents[key]) total += prices.attachment;
    }
    if (selectedTintId !== originalTintId) total += prices.tint;
    if (selectedCustomSkin && selectedCustomSkin !== originalCustomSkin) total += prices.customSkin;

    document.getElementById('total-price').innerText = `$${total.toLocaleString()}`;
}

// Helper NUI Post
function postNUI(endpoint, data) {
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data || {})
    }).catch(err => console.log('NUI Fetch Error:', err));
}

// Locked Item Preview Banner Update
function updateLockedPreviewBanner(forceHide) {
    const banner = document.getElementById('locked-preview-banner');
    if (!banner) return;

    if (forceHide || !selectedCustomSkin) {
        banner.classList.add('hidden');
        return;
    }

    const skinDef = customSkins.find(s => (typeof s === 'object' ? s.id : s) === selectedCustomSkin);
    const isLocked = skinDef && skinDef.isLocked && !unlockedSkinsMap[selectedCustomSkin];

    if (isLocked) {
        banner.classList.remove('hidden');
    } else {
        banner.classList.add('hidden');
    }
}

// Sleek Call of Duty Modern Toast Notification Generator
function showToastNotification(message) {
    const container = document.getElementById('nui-toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = 'nui-toast';
    toast.innerHTML = `<i class="fa-solid fa-triangle-exclamation"></i> <span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
        toast.classList.add('fade-out');
        setTimeout(() => toast.remove(), 300);
    }, 4500);
}
