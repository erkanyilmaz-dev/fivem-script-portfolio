/* ==========================================================================
   VATERPVP ADVANCED MULTI-STYLE HUD v3 - CORE NUI SCRIPT
   ========================================================================== */

// 20 Status Bar Presets Data
const STATUS_PRESETS = [
    { id: 1, name: "Modern Radial Circles", badge: "Halka Kadran" },
    { id: 2, name: "Minimal Horizontal Bars", badge: "Yatay Bar" },
    { id: 3, name: "Compact Pill Badges", badge: "Kapsül" },
    { id: 4, name: "Vertical Side Stack", badge: "Dikey Stack" },
    { id: 5, name: "Segmented Block Bars", badge: "Arcade Notch" },
    { id: 6, name: "Futuristic Diamond Nodes", badge: "Elmas Görünüm" },
    { id: 7, name: "Hexagonal Neon Grid", badge: "Altıgen Fluid" },
    { id: 8, name: "Cyberpunk Neon Cut", badge: "Cyber Angle" },
    { id: 9, name: "Glassmorphism Floating Cards", badge: "Cam Kart" },
    { id: 10, name: "Curved Semi-Arc Dials", badge: "Kavisli Arc" },
    { id: 11, name: "Retro Pixel Matrix", badge: "8-Bit Retro" },
    { id: 12, name: "Gradient Wave Fill", badge: "Likit Dalga" },
    { id: 13, name: "OLED Minimalist Lines", badge: "İnce Çizgi" },
    { id: 14, name: "Tachometer Dial Minis", badge: "Mini Kadran" },
    { id: 15, name: "Outlined Capsule Rings", badge: "Kalın Kapsül" },
    { id: 16, name: "Concentric Dual Rings", badge: "Çift Halka" },
    { id: 17, name: "Dynamic Percentage Badges", badge: "Floating Badge" },
    { id: 18, name: "Cinematic Bottom Bar", badge: "Alt Orta Bar" },
    { id: 19, name: "Micro Icon Dials", badge: "Mikro İkon" },
    { id: 20, name: "Top Grid Matrix", badge: "Üst Kartlar" }
];

// 15 Speedometer Presets Data
const SPEEDO_PRESETS = [
    { id: 1, name: "Supercar Arc Dial", badge: "Spor Kadran" },
    { id: 2, name: "Modern Minimalist Ring (Image 3)", badge: "Halka Kadran" },
    { id: 3, name: "Minimal Numeric Display", badge: "Minimal Dijital" },
    { id: 4, name: "Drift Compact HUD", badge: "Drift Kadran" },
    { id: 5, name: "Neon Full Radial Ring", badge: "360° Halka" },
    { id: 6, name: "Retro 80s LED Dashboard", badge: "80s LED" },
    { id: 7, name: "Futuristic Hologram HUD", badge: "Sci-Fi Hologram" },
    { id: 8, name: "Porsche GT3 Center Dial", badge: "Porsche Kadran" },
    { id: 9, name: "Hexagon Carbon Gauge", badge: "Karbon Altıgen" },
    { id: 10, name: "AMG Performance Sport Dial", badge: "AMG Spor Kadran" },
    { id: 11, name: "JDM Skyline R34 Legend", badge: "JDM R34 Kadran" },
    { id: 12, name: "MotoGP Telemetry Dash", badge: "MotoGP Yarış Kadran" },
    { id: 13, name: "Modern Minimalist Ring (Image 3)", badge: "Halka Kadran" },
    { id: 14, name: "Ferrari Dual Dial Cluster", badge: "Ferrari Çift Kadran" },
    { id: 15, name: "Linear Segmented Bar", badge: "Lineer Bar" }
];

// State storage
let HUD_CONFIG = {
    statusStyle: 1,
    speedoStyle: 1,
    speedUnit: 'kmh',
    theme: 'cyberpunk',
    scale: 1.0,
    opacity: 1.0,
    colors: {
        health: '#ef4444',
        armor: '#3b82f6',
        hunger: '#f59e0b',
        thirst: '#06b6d4',
        stamina: '#10b981',
        voice: '#a855f7'
    },
    toggles: {
        health: true,
        armor: true,
        hunger: true,
        thirst: true,
        stamina: true,
        voice: true,
        street: true
    },
    positions: {}
};

// Current dynamic values from game tick
let GAME_DATA = {
    health: 100,
    armor: 100,
    hunger: 100,
    thirst: 100,
    stamina: 100,
    isTalking: false,
    voiceLevel: 66,
    voiceLabel: "Normal",
    speedKmh: 0,
    speedMph: 0,
    rpm: 0,
    gear: 1,
    fuel: 100,
    seatbelt: false,
    engineOn: true,
    engineHealth: 100,
    street: "Legion Square",
    zone: "Downtown LS"
};

let isEditorOpen = false;
let isDragMode = false;
let draggedElement = null;
let dragOffset = { x: 0, y: 0 };

// DOM Elements
const statusContainer = document.getElementById('status-hud-container');
const statusWrapper = document.getElementById('status-items-wrapper');
const speedoContainer = document.getElementById('speedo-hud-container');
const speedoWrapper = document.getElementById('speedo-items-wrapper');
const streetContainer = document.getElementById('street-hud-container');
const editorModal = document.getElementById('editor-modal');
const dragOverlay = document.getElementById('drag-overlay');

// Initial Load
document.addEventListener('DOMContentLoaded', () => {
    loadLocalSettings();
    buildStyleGrids();
    setupEventListeners();
    applyThemeAndColors();
    updateHUDComponents();

    // Signal ready to Lua client
    fetch(`https://${GetParentResourceName()}/uiReady`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});
});

// Helper mini preview generator for 20 Status Presets
function getStatusMiniPreview(id) {
    switch (id) {
        case 1:
            return `<div class="mini-preview style-1-prev"><div class="mini-circle c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-circle c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div><div class="mini-circle c-amber-b"><i class="fa-solid fa-utensils c-amber-t"></i></div></div>`;
        case 2:
            return `<div class="mini-preview style-2-prev"><div class="mini-bar-row"><i class="fa-solid fa-heart c-red-t"></i><div class="mini-bar-fill c-red-bg" style="width:75%"></div></div><div class="mini-bar-row"><i class="fa-solid fa-shield-halved c-blue-t"></i><div class="mini-bar-fill c-blue-bg" style="width:50%"></div></div></div>`;
        case 3:
            return `<div class="mini-preview style-3-prev"><div class="mini-pill c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-pill c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 4:
            return `<div class="mini-preview style-4-prev"><div class="mini-sq c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-sq c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 5:
            return `<div class="mini-preview style-5-prev"><div class="mini-blocks"><span class="b-act c-red-bg"></span><span class="b-act c-red-bg"></span><span class="b-inact"></span></div><div class="mini-blocks"><span class="b-act c-blue-bg"></span><span class="b-inact"></span><span class="b-inact"></span></div></div>`;
        case 6:
            return `<div class="mini-preview style-6-prev"><div class="mini-diamond c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-diamond c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 7:
            return `<div class="mini-preview style-7-prev"><div class="mini-hex c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-hex c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 8:
            return `<div class="mini-preview style-8-prev"><div class="mini-cyber c-red-b"><i class="fa-solid fa-heart c-red-t"></i> 100%</div></div>`;
        case 9:
            return `<div class="mini-preview style-9-prev"><div class="mini-card-badge"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-card-badge"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 10:
            return `<div class="mini-preview style-10-prev"><div class="mini-arc c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-arc c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 11:
            return `<div class="mini-preview style-11-prev"><div class="mini-retro"><i class="fa-solid fa-heart c-red-t"></i> [██▒]</div></div>`;
        case 12:
            return `<div class="mini-preview style-12-prev"><div class="mini-wave c-red-bg"><i class="fa-solid fa-heart"></i></div><div class="mini-wave c-blue-bg"><i class="fa-solid fa-shield-halved"></i></div></div>`;
        case 13:
            return `<div class="mini-preview style-13-prev"><span class="mini-line-item"><i class="fa-solid fa-heart c-red-t"></i></span><span class="mini-line-item"><i class="fa-solid fa-shield-halved c-blue-t"></i></span></div>`;
        case 14:
            return `<div class="mini-preview style-14-prev"><div class="mini-tacho c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-tacho c-blue-b"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 15:
            return `<div class="mini-preview style-15-prev"><div class="mini-thick-pill c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div></div>`;
        case 16:
            return `<div class="mini-preview style-16-prev"><div class="mini-dual-ring c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div></div>`;
        case 17:
            return `<div class="mini-preview style-17-prev"><div class="mini-badge-card c-red-b"><i class="fa-solid fa-heart c-red-t"></i></div></div>`;
        case 18:
            return `<div class="mini-preview style-18-prev"><div class="mini-cinematic"><i class="fa-solid fa-heart c-red-t"></i><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        case 19:
            return `<div class="mini-preview style-19-prev"><div class="mini-micro c-red-t"><i class="fa-solid fa-heart"></i></div><div class="mini-micro c-blue-t"><i class="fa-solid fa-shield-halved"></i></div></div>`;
        case 20:
            return `<div class="mini-preview style-20-prev"><div class="mini-grid-box"><i class="fa-solid fa-heart c-red-t"></i></div><div class="mini-grid-box"><i class="fa-solid fa-shield-halved c-blue-t"></i></div></div>`;
        default:
            return `<i class="fa-solid fa-shapes card-icon"></i>`;
    }
}

// Helper mini preview generator for 15 Speedo Presets
function getSpeedoMiniPreview(id) {
    switch (id) {
        case 1:
            // Car Speedometer (ZXL Style - matching user screenshot 1)
            return `<div class="mini-speedo-prev prev-zxl-car">
                <div class="zxl-outer-ring">
                    <div class="zxl-inner-screen">
                        <span class="zxl-unit-tag">MPH</span>
                        <span class="zxl-speed-num">120</span>
                    </div>
                    <div class="zxl-fuel-indicator"><i class="fa-solid fa-gas-pump"></i></div>
                </div>
            </div>`;
        case 2:
            return `<div class="mini-speedo-prev prev-ring"><div class="m-ring-circle"><span class="m-sp">120</span></div></div>`;
        case 3:
            return `<div class="mini-speedo-prev prev-num"><span class="m-sp-lg">120</span></div>`;
        case 4:
            return `<div class="mini-speedo-prev prev-cyber"><span class="m-sp c-cyan-t">120</span><div class="m-cyber-bar"></div></div>`;
        case 5:
            return `<div class="mini-speedo-prev prev-ring"><div class="m-ring-circle"><span class="m-sp">120</span></div></div>`;
        case 6:
            return `<div class="mini-speedo-prev prev-led"><span class="m-led-txt">120 KMH</span></div>`;
        case 7:
            return `<div class="mini-speedo-prev prev-holo"><div class="m-holo-cross"><span class="m-sp c-cyan-t">120</span></div></div>`;
        case 8:
            return `<div class="mini-speedo-prev prev-racing-tacho"><div class="m-tacho-circle"><span class="m-cyan-sp">120</span><span class="m-mt-badge">MT</span><span class="m-gear-big">4</span></div></div>`;
        case 9:
            return `<div class="mini-speedo-prev prev-hex"><div class="m-hex-container"><span class="m-sp c-amber-t">120</span></div></div>`;
        case 10:
            return `<div class="mini-speedo-prev prev-glass"><div class="m-glass-pill"><i class="fa-solid fa-gas-pump c-amber-t"></i><span class="m-sp">120</span></div></div>`;
        case 11:
            return `<div class="mini-speedo-prev prev-wings"><div class="m-wing-box"><span class="m-sp">120</span></div></div>`;
        case 12:
            return `<div class="mini-speedo-prev prev-compact"><span class="m-gear">G4</span><span class="m-sp">120</span></div>`;
        case 13:
            return `<div class="mini-speedo-prev prev-ring"><div class="m-ring-circle"><span class="m-sp">120</span></div></div>`;
        case 14:
            return `<div class="mini-speedo-prev prev-dual"><span class="m-sp">120</span><span class="m-gear">G4</span></div>`;
        case 15:
            return `<div class="mini-speedo-prev prev-linear"><span class="m-sp">120</span><div class="m-seg-ticks"><span class="t-act"></span><span class="t-act"></span><span class="t-act"></span><span class="t-inact"></span></div></div>`;
        default:
            return `<i class="fa-solid fa-gauge-high card-icon"></i>`;
    }
}

// Build 20 Status + 15 Speedo Selection Cards in Editor
function buildStyleGrids() {
    const statusGrid = document.getElementById('status-style-grid');
    statusGrid.innerHTML = '';
    STATUS_PRESETS.forEach(preset => {
        const card = document.createElement('div');
        const isActive = parseInt(HUD_CONFIG.statusStyle) === preset.id;
        card.className = `style-card-option showcase-card ${isActive ? 'active' : ''}`;
        card.dataset.id = preset.id;
        card.innerHTML = `
            <div class="showcase-graphic-area">
                ${getStatusMiniPreview(preset.id)}
            </div>
            <div class="showcase-footer-area">
                <div class="showcase-titles">
                    <span class="showcase-category">STATUS HUD TEMPLATE</span>
                    <span class="showcase-name">#${preset.id} ${preset.name}</span>
                </div>
                <span class="badge">${isActive ? '<i class="fa-solid fa-check"></i> ' : ''}${preset.badge}</span>
            </div>
        `;
        card.addEventListener('click', () => setStatusStyle(preset.id));
        statusGrid.appendChild(card);
    });

    const speedoGrid = document.getElementById('speedo-style-grid');
    speedoGrid.innerHTML = '';
    SPEEDO_PRESETS.forEach(preset => {
        const card = document.createElement('div');
        const isActive = parseInt(HUD_CONFIG.speedoStyle) === preset.id;
        card.className = `style-card-option showcase-card ${isActive ? 'active' : ''}`;
        card.dataset.id = preset.id;
        card.innerHTML = `
            <div class="showcase-graphic-area">
                ${getSpeedoMiniPreview(preset.id)}
            </div>
            <div class="showcase-footer-area">
                <div class="showcase-titles">
                    <span class="showcase-category">SPEEDOMETER TEMPLATE</span>
                    <span class="showcase-name">#${preset.id} ${preset.name}</span>
                </div>
                <span class="badge">${isActive ? '<i class="fa-solid fa-check"></i> ' : ''}${preset.badge}</span>
            </div>
        `;
        card.addEventListener('click', () => setSpeedoStyle(preset.id));
        speedoGrid.appendChild(card);
    });
}

// Set Status Bar Style (1 to 20)
function setStatusStyle(id) {
    HUD_CONFIG.statusStyle = id;
    statusContainer.className = `hud-component style-${id}`;
    statusContainer.dataset.style = id;
    buildStyleGrids();
    updateHUDComponents();
    saveSettings();
}

// Set Speedometer Style (1 to 15)
function setSpeedoStyle(id) {
    HUD_CONFIG.speedoStyle = id;
    speedoContainer.className = `hud-component speedo-style-${id} ${speedoContainer.classList.contains('hidden') ? 'hidden' : ''}`;
    speedoContainer.dataset.speedoStyle = id;
    buildStyleGrids();
    updateSpeedometer();
    saveSettings();
}

// Event Listeners Initialization
function setupEventListeners() {
    // Navigation Tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById(`tab-${tab.dataset.tab}`).classList.add('active');
        });
    });

    // Color Inputs
    ['health', 'armor', 'hunger', 'thirst', 'stamina', 'voice'].forEach(key => {
        const input = document.getElementById(`color-${key}`);
        if (input) {
            input.addEventListener('input', (e) => {
                HUD_CONFIG.colors[key] = e.target.value;
                applyThemeAndColors();
                saveSettings();
            });
        }
    });

    // Theme Presets
    document.querySelectorAll('.theme-card').forEach(card => {
        card.addEventListener('click', () => {
            document.querySelectorAll('.theme-card').forEach(c => c.classList.remove('active'));
            card.classList.add('active');
            const theme = card.dataset.theme;
            HUD_CONFIG.theme = theme;
            applyPresetTheme(theme);
            saveSettings();
        });
    });

    // Sliders
    const scaleInput = document.getElementById('input-scale');
    const opacityInput = document.getElementById('input-opacity');
    
    scaleInput.addEventListener('input', (e) => {
        HUD_CONFIG.scale = parseFloat(e.target.value);
        document.getElementById('val-scale').textContent = `${HUD_CONFIG.scale.toFixed(2)}x`;
        document.documentElement.style.setProperty('--hud-scale', HUD_CONFIG.scale);
        saveSettings();
    });

    opacityInput.addEventListener('input', (e) => {
        HUD_CONFIG.opacity = parseFloat(e.target.value);
        document.getElementById('val-opacity').textContent = `${Math.round(HUD_CONFIG.opacity * 100)}%`;
        document.documentElement.style.setProperty('--hud-opacity', HUD_CONFIG.opacity);
        saveSettings();
    });

    // Unit Toggle
    document.querySelectorAll('.unit-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.unit-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            HUD_CONFIG.speedUnit = btn.dataset.unit;
            updateSpeedometer();
            saveSettings();
        });
    });

    // Element Visibility Toggles
    ['health', 'armor', 'hunger', 'thirst', 'stamina', 'voice', 'street'].forEach(key => {
        const input = document.getElementById(`toggle-${key}`);
        if (input) {
            input.addEventListener('change', (e) => {
                HUD_CONFIG.toggles[key] = e.target.checked;
                updateHUDComponents();
                saveSettings();
            });
        }
    });

    // Buttons
    document.getElementById('btn-close-editor').addEventListener('click', closeEditor);
    document.getElementById('btn-save-close').addEventListener('click', closeEditor);
    document.getElementById('btn-reset-hud').addEventListener('click', resetHUD);
    document.getElementById('btn-drag-mode').addEventListener('click', toggleDragMode);
    document.getElementById('btn-exit-drag').addEventListener('click', exitDragMode);

    // Keydown ESC handler
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (isDragMode) {
                exitDragMode();
            } else if (isEditorOpen) {
                closeEditor();
            }
        }
    });

    // Drag & Drop Handlers
    document.querySelectorAll('.hud-component').forEach(el => {
        el.addEventListener('mousedown', startDragging);
    });
    window.addEventListener('mousemove', handleDragging);
    window.addEventListener('mouseup', stopDragging);
}

// Render Status HUD according to active 20 style templates
function updateHUDComponents() {
    statusWrapper.innerHTML = '';
    const cfg = HUD_CONFIG.toggles;

    const items = [
        { key: 'health', icon: 'fa-heart', val: GAME_DATA.health, show: cfg.health, color: HUD_CONFIG.colors.health },
        { key: 'armor', icon: 'fa-shield-halved', val: GAME_DATA.armor, show: cfg.armor, color: HUD_CONFIG.colors.armor },
        { key: 'hunger', icon: 'fa-utensils', val: GAME_DATA.hunger, show: cfg.hunger, color: HUD_CONFIG.colors.hunger },
        { key: 'thirst', icon: 'fa-droplet', val: GAME_DATA.thirst, show: cfg.thirst, color: HUD_CONFIG.colors.thirst },
        { key: 'stamina', icon: 'fa-bolt', val: GAME_DATA.stamina, show: cfg.stamina, color: HUD_CONFIG.colors.stamina },
        { key: 'voice', icon: 'fa-microphone', val: GAME_DATA.voiceLevel, show: cfg.voice, color: HUD_CONFIG.colors.voice, talking: GAME_DATA.isTalking }
    ];

    // Icon-only preset IDs (no text percentage in socket)
    const iconOnlyStyles = [1, 4, 6, 7, 10, 12, 14, 16, 19];
    const isIconOnly = iconOnlyStyles.includes(parseInt(HUD_CONFIG.statusStyle) || 1);

    items.forEach(item => {
        if (!item.show) return;
        const card = document.createElement('div');
        card.className = `status-card status-${item.key} ${item.talking ? 'talking' : ''}`;
        card.style.setProperty('--val', item.val);
        card.style.setProperty('--fill-color', item.color);

        card.innerHTML = `
            <div class="status-ring"></div>
            <div class="status-bar-bg"></div>
            <i class="fa-solid ${item.icon} status-icon"></i>
            ${isIconOnly ? '' : `<span class="status-val">${item.val}%</span>`}
        `;
        statusWrapper.appendChild(card);
    });

    // Street visibility toggle
    streetContainer.classList.toggle('hidden', !HUD_CONFIG.toggles.street);
}

// Render Speedometer according to active 15 style templates
function updateSpeedometer() {
    if (speedoContainer.classList.contains('hidden')) return;

    speedoWrapper.innerHTML = '';
    const unit = HUD_CONFIG.speedUnit;
    const speed = unit === 'kmh' ? GAME_DATA.speedKmh : GAME_DATA.speedMph;
    const rpmVal = GAME_DATA.rpm || 0; // 0.0 to 1.0
    const rpmPercent = Math.min(Math.max(rpmVal * 100, 0), 100);
    // Needle angle from -135deg to +135deg around circular dial
    const needleAngle = -135 + (rpmVal * 270);
    const gearText = GAME_DATA.gear === 0 ? 'R' : (GAME_DATA.gear || '1');

    const styleId = parseInt(HUD_CONFIG.speedoStyle) || 1;
    const box = document.createElement('div');
    box.className = `speedo-box speedo-preset-${styleId}`;

    // Common detail cluster
    const detailsHtml = `
        <div class="speedo-details">
            <div class="detail-item ${GAME_DATA.fuel < 20 ? 'warning' : 'active'}">
                <i class="fa-solid fa-gas-pump"></i> ${GAME_DATA.fuel}%
            </div>
            <div class="detail-item ${GAME_DATA.seatbelt ? 'active' : 'warning'}">
                <i class="fa-solid ${GAME_DATA.seatbelt ? 'fa-user-check' : 'fa-user-slash'}"></i> ${GAME_DATA.seatbelt ? 'KEMER' : 'KEMERSİZ'}
            </div>
            <div class="detail-item ${GAME_DATA.engineOn ? 'active' : 'warning'}">
                <i class="fa-solid fa-car-battery"></i> ${GAME_DATA.engineHealth}%
            </div>
        </div>
    `;

    if (styleId === 1) {
        // Car Speedometer (ZXL Style)
        box.innerHTML = `
            <div class="zxl-car-hud">
                <div class="zxl-outer-ring">
                    <div class="zxl-inner-screen">
                        <span class="zxl-unit-tag">${unit.toUpperCase()}</span>
                        <span class="zxl-speed-num">${speed}</span>
                    </div>
                    <div class="zxl-fuel-indicator ${GAME_DATA.fuel < 20 ? 'warning' : ''}">
                        <i class="fa-solid fa-gas-pump"></i>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 2) {
        // Modern Minimalist Ring Dial (Image 3)
        // 282 is the circumference of radius 45 circle (2 * Math.PI * 45)
        const dashOffset = 282 - (282 * rpmVal);
        box.innerHTML = `
            <div class="modern-ring-cluster">
                <svg class="ring-svg" viewBox="0 0 100 100">
                    <circle class="ring-bg-circle" cx="50" cy="50" r="45"></circle>
                    <circle class="ring-fill-circle" cx="50" cy="50" r="45" style="stroke-dashoffset: ${dashOffset}"></circle>
                </svg>
                <div class="ring-center-content">
                    <span class="ring-speed-num">${speed}</span>
                    <span class="ring-unit-txt">${unit.toUpperCase()}</span>
                    <div class="ring-sub-info">
                        <span class="ring-gear-badge">${gearText}</span>
                        <div class="ring-status-icons">
                            <i class="fa-solid fa-droplet ${GAME_DATA.fuel < 20 ? 'warning' : ''}"></i>
                            <i class="fa-solid fa-user-shield ${GAME_DATA.seatbelt ? 'active' : ''}"></i>
                        </div>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 3) {
        // Minimalist Numeric (no top bar)
        box.innerHTML = `
            <div class="gear-badge">${gearText}</div>
            <div class="speedo-main">
                <span class="speed-val">${speed}</span>
                <span class="speed-unit">${unit.toUpperCase()}</span>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 6) {
        // Retro 80s LED Dashboard (no top bar)
        box.innerHTML = `
            <div class="gear-badge">${gearText}</div>
            <div class="speedo-main">
                <span class="speed-val">${speed}</span>
                <span class="speed-unit">${unit.toUpperCase()}</span>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 8) {
        // Assetto Corsa Racing Dial (Image 1)
        box.innerHTML = `
            <div class="racing-tacho-cluster">
                <div class="tacho-bezel">
                    <div class="tacho-ticks">
                        <span class="t-num n0">0</span>
                        <span class="t-num n2">2</span>
                        <span class="t-num n3">3</span>
                        <span class="t-num n4">4</span>
                        <span class="t-num n5">5</span>
                        <span class="t-num n6">6</span>
                        <span class="t-num n7">7</span>
                        <span class="t-num n8">8</span>
                        <span class="t-num n9 redline">9</span>
                        <span class="t-num n10 redline">10</span>
                    </div>
                    <div class="tacho-redline-arc"></div>
                    <div class="tacho-needle-indicator" style="transform: rotate(${needleAngle}deg);"></div>
                    <div class="tacho-needle-cap"></div>
                    <div class="tacho-center-screen">
                        <span class="cyan-speed-val">${speed}</span>
                        <span class="speed-unit-lbl">${unit.toLowerCase()}</span>
                        <div class="bottom-gear-row">
                            <span class="trans-mode-badge">${GAME_DATA.gear === 0 ? 'AT' : 'MT'}</span>
                            <span class="big-gear-num">${gearText}</span>
                        </div>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 10) {
        // AMG Performance Sport Dial
        box.innerHTML = `
            <div class="amg-sport-cluster">
                <!-- Left Flank Gauge Arc (Fuel) -->
                <div class="amg-flank-gauge left-flank">
                    <i class="fa-solid fa-gas-pump"></i>
                    <div class="flank-bar-track">
                        <div class="flank-bar-fill" style="height: ${GAME_DATA.fuel}%"></div>
                    </div>
                </div>
                <!-- Central Dial -->
                <div class="amg-center-dial">
                    <div class="amg-ticks">
                        <span>0</span><span>2</span><span>4</span><span>6</span><span class="redline">8</span>
                    </div>
                    <div class="amg-needle" style="transform: rotate(${needleAngle}deg);"></div>
                    <div class="amg-needle-cap"></div>
                    <div class="amg-center-display">
                        <span class="amg-gear">${gearText}</span>
                        <span class="amg-speed">${speed}</span>
                        <span class="amg-unit">${unit.toUpperCase()}</span>
                    </div>
                </div>
                <!-- Right Flank Gauge Arc (Temp) -->
                <div class="amg-flank-gauge right-flank">
                    <i class="fa-solid fa-temperature-half"></i>
                    <div class="flank-bar-track">
                        <div class="flank-bar-fill" style="height: ${GAME_DATA.engineHealth}%"></div>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 11) {
        // Forza Horizon Transparent Dial (Image 2)
        box.innerHTML = `
            <div class="forza-horizon-cluster">
                <div class="forza-bezel">
                    <div class="forza-ticks">
                        <span>0</span><span>1</span><span>2</span><span>3</span><span>4</span><span>5</span><span>6</span><span>7</span><span>8</span><span class="redline">9</span>
                    </div>
                    <div class="forza-needle" style="transform: rotate(${needleAngle}deg);"></div>
                    <div class="forza-needle-cap"></div>
                    
                    <div class="forza-dashboard-bottom">
                        <!-- Left indicators -->
                        <div class="forza-indicators-left">
                            <span class="ind-lbl ${GAME_DATA.seatbelt ? 'active' : ''}">ABS</span>
                            <span class="ind-lbl ${GAME_DATA.handbrake ? 'active' : ''}">HBK</span>
                        </div>
                        
                        <!-- Center gear ring -->
                        <div class="forza-gear-circle">
                            <span class="forza-gear-val">${gearText}</span>
                        </div>
                        
                        <!-- Right speed readout -->
                        <div class="forza-speed-block">
                            <span class="forza-unit-lbl">${unit.toUpperCase()}</span>
                            <span class="forza-speed-val">${speed}</span>
                        </div>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 12) {
        // MotoGP GP-Track Dash
        box.innerHTML = `
            <div class="motogp-track-dash">
                <!-- Shift Lights Bar -->
                <div class="motogp-shift-bar">
                    <span class="shift-led green ${rpmPercent > 30 ? 'lit' : ''}"></span>
                    <span class="shift-led green ${rpmPercent > 50 ? 'lit' : ''}"></span>
                    <span class="shift-led yellow ${rpmPercent > 70 ? 'lit' : ''}"></span>
                    <span class="shift-led yellow ${rpmPercent > 85 ? 'lit' : ''}"></span>
                    <span class="shift-led red ${rpmPercent > 92 ? 'lit' : ''}"></span>
                </div>
                <div class="motogp-layout">
                    <!-- Left LCD display screen -->
                    <div class="motogp-lcd">
                        <div class="lcd-row">
                            <span class="lcd-speed">${speed}</span>
                            <span class="lcd-unit">${unit.toUpperCase()}</span>
                        </div>
                        <div class="telemetry">
                            <span>TEMP: 88°C</span>
                            <span>LAP: 1:24.52</span>
                        </div>
                    </div>
                    <!-- Right Analog Tachometer Circle -->
                    <div class="motogp-tacho">
                        <div class="m-ticks">
                            <span>0</span><span>5</span><span>10</span><span class="red">14</span>
                        </div>
                        <div class="m-needle" style="transform: rotate(${-120 + (rpmVal * 240)}deg);"></div>
                        <div class="m-cap"></div>
                        <span class="m-gear">${gearText}</span>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 4) {
        // Custom Drift Compact HUD (Style 4)
        box.innerHTML = `
            <div class="drift-compact-hud">
                <div class="drift-speed-row">
                    <span class="drift-speed-num">${speed}</span>
                    <span class="drift-unit">${unit.toUpperCase()}</span>
                </div>
                <div class="drift-rpm-bar-container">
                    <div class="drift-rpm-bar-fill" style="width: ${rpmPercent}%"></div>
                </div>
                <div class="drift-gear-row">
                    <span class="drift-gear-val">GEAR ${gearText}</span>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 13) {
        // Modern Minimalist Ring Dial (Image 3)
        const dashOffset = 282 - (282 * rpmVal);
        box.innerHTML = `
            <div class="modern-ring-cluster">
                <svg class="ring-svg" viewBox="0 0 100 100">
                    <circle class="ring-bg-circle" cx="50" cy="50" r="45"></circle>
                    <circle class="ring-fill-circle" cx="50" cy="50" r="45" style="stroke-dashoffset: ${dashOffset}"></circle>
                </svg>
                <div class="ring-center-content">
                    <span class="ring-speed-num">${speed}</span>
                    <span class="ring-unit-txt">${unit.toUpperCase()}</span>
                    <div class="ring-sub-info">
                        <span class="ring-gear-badge">${gearText}</span>
                        <div class="ring-status-icons">
                            <i class="fa-solid fa-droplet ${GAME_DATA.fuel < 20 ? 'warning' : ''}"></i>
                            <i class="fa-solid fa-user-shield ${GAME_DATA.seatbelt ? 'active' : ''}"></i>
                        </div>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 14) {
        // Ferrari Dual Dial Cluster (Style 14)
        const speedNeedleAngle = -135 + (Math.min(speed / 300, 1) * 270);
        box.innerHTML = `
            <div class="dual-cluster-real">
                <!-- Left Dial: RPM -->
                <div class="real-dial rpm-dial">
                    <div class="dial-bezel">
                        <div class="ticks-container">
                            <span>0</span><span>2</span><span>4</span><span>6</span><span class="redline">8</span>
                        </div>
                        <div class="dial-needle" style="transform: rotate(${needleAngle}deg);"></div>
                        <div class="dial-cap"></div>
                        <span class="dial-label">RPM x1000</span>
                    </div>
                </div>
                <!-- Center: Gear Badge -->
                <div class="center-gear-box">
                    <span class="label">GEAR</span>
                    <span class="value">${gearText}</span>
                </div>
                <!-- Right Dial: Speedometer -->
                <div class="real-dial speed-dial">
                    <div class="dial-bezel">
                        <div class="ticks-container">
                            <span>0</span><span>80</span><span>160</span><span>240</span><span>320</span>
                        </div>
                        <div class="dial-needle" style="transform: rotate(${speedNeedleAngle}deg);"></div>
                        <div class="dial-cap"></div>
                        <div class="digital-speed-readout">
                            <span class="speed-num">${speed}</span>
                            <span class="unit-txt">${unit.toUpperCase()}</span>
                        </div>
                    </div>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 15) {
        // Formula 1 Segmented LED Shift Lights
        const totalLeds = 10;
        const activeLeds = Math.round(rpmVal * totalLeds);
        let ledsHtml = '';
        for (let i = 1; i <= totalLeds; i++) {
            let ledColorClass = i <= 5 ? 'led-green' : (i <= 8 ? 'led-yellow' : 'led-red');
            let isLit = i <= activeLeds ? 'lit' : '';
            ledsHtml += `<span class="f1-led ${ledColorClass} ${isLit}"></span>`;
        }
        box.innerHTML = `
            <div class="f1-shift-lights">${ledsHtml}</div>
            <div class="gear-badge">${gearText}</div>
            <div class="speedo-main">
                <span class="speed-val">${speed}</span>
                <span class="speed-unit">${unit.toUpperCase()}</span>
            </div>
            ${detailsHtml}
        `;
    } else if (styleId === 5) {
        // McLaren 360 Radial Ring Gauge
        box.innerHTML = `
            <div class="radial-360-ring" style="background: conic-gradient(var(--accent-glow, rgba(255,255,255,0.4)) ${rpmPercent * 3.6}deg, rgba(255,255,255,0.08) 0deg);">
                <div class="inner-ring-content">
                    <span class="gear-pill">${gearText}</span>
                    <span class="speed-val">${speed}</span>
                    <span class="speed-unit">${unit.toUpperCase()}</span>
                </div>
            </div>
            ${detailsHtml}
        `;
    } else {
        // Standard / Supercar Arc / Cyber / Hexagon / Compact presets
        box.innerHTML = `
            <div class="rpm-progress-bar" style="width: ${rpmPercent}%"></div>
            <div class="gear-badge">${gearText}</div>
            <div class="speedo-main">
                <span class="speed-val">${speed}</span>
                <span class="speed-unit">${unit.toUpperCase()}</span>
            </div>
            ${detailsHtml}
        `;
    }

    speedoWrapper.appendChild(box);
}

// Theme presetter
function applyPresetTheme(theme) {
    const themeColors = {
        glass: { health: '#ffffff', armor: '#e2e8f0', hunger: '#cbd5e1', thirst: '#94a3b8', stamina: '#64748b', voice: '#f8fafc' },
        cyberpunk: { health: '#ef4444', armor: '#3b82f6', hunger: '#f59e0b', thirst: '#06b6d4', stamina: '#10b981', voice: '#a855f7' },
        gold: { health: '#f59e0b', armor: '#d97706', hunger: '#fbbf24', thirst: '#eab308', stamina: '#ca8a04', voice: '#fef08a' },
        emerald: { health: '#10b981', armor: '#059669', hunger: '#34d399', thirst: '#065f46', stamina: '#6ee7b7', voice: '#a7f3d0' },
        sunset: { health: '#f97316', armor: '#ef4444', hunger: '#fb923c', thirst: '#fdba74', stamina: '#dc2626', voice: '#ffedd5' },
        purple: { health: '#8b5cf6', armor: '#ec4899', hunger: '#a855f7', thirst: '#d8b4fe', stamina: '#c084fc', voice: '#f472b6' },
        crimson: { health: '#dc2626', armor: '#991b1b', hunger: '#ef4444', thirst: '#f87171', stamina: '#b91c1c', voice: '#fca5a5' },
        oled: { health: '#e2e8f0', armor: '#94a3b8', hunger: '#cbd5e1', thirst: '#64748b', stamina: '#475569', voice: '#f8fafc' }
    };

    if (themeColors[theme]) {
        HUD_CONFIG.colors = { ...themeColors[theme] };
        applyThemeAndColors();
    }
}

function applyThemeAndColors() {
    const c = HUD_CONFIG.colors;
    document.documentElement.style.setProperty('--health-color', c.health);
    document.documentElement.style.setProperty('--armor-color', c.armor);
    document.documentElement.style.setProperty('--hunger-color', c.hunger);
    document.documentElement.style.setProperty('--thirst-color', c.thirst);
    document.documentElement.style.setProperty('--stamina-color', c.stamina);
    document.documentElement.style.setProperty('--voice-color', c.voice);

    Object.keys(c).forEach(key => {
        const input = document.getElementById(`color-${key}`);
        if (input) input.value = c[key];
    });

    updateHUDComponents();
}

// Drag & Drop handlers
function toggleDragMode() {
    closeEditor(false);
    isDragMode = true;
    dragOverlay.classList.remove('hidden');
    document.querySelectorAll('.hud-component').forEach(el => el.classList.add('drag-active'));
}

function exitDragMode() {
    isDragMode = false;
    dragOverlay.classList.add('hidden');
    document.querySelectorAll('.hud-component').forEach(el => el.classList.remove('drag-active'));
    openEditor();
}

function startDragging(e) {
    if (!isDragMode) return;
    draggedElement = e.currentTarget;
    const rect = draggedElement.getBoundingClientRect();
    dragOffset.x = e.clientX - rect.left;
    dragOffset.y = e.clientY - rect.top;
}

function handleDragging(e) {
    if (!isDragMode || !draggedElement) return;
    const left = e.clientX - dragOffset.x;
    const top = e.clientY - dragOffset.y;

    draggedElement.style.left = `${left}px`;
    draggedElement.style.top = `${top}px`;
    draggedElement.style.bottom = 'auto';
    draggedElement.style.right = 'auto';

    // Store position
    HUD_CONFIG.positions[draggedElement.id] = { left: `${left}px`, top: `${top}px` };
    saveSettings();
}

function stopDragging() {
    draggedElement = null;
}

// Open / Close Editor
function openEditor() {
    isEditorOpen = true;
    editorModal.classList.remove('hidden');
}

function closeEditor(closeNui = true) {
    isEditorOpen = false;
    editorModal.classList.add('hidden');
    if (closeNui) {
        fetch(`https://${GetParentResourceName()}/closeHUD`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {});
    }
}

// Reset HUD to defaults
function resetHUD() {
    HUD_CONFIG.statusStyle = 1;
    HUD_CONFIG.speedoStyle = 1;
    HUD_CONFIG.speedUnit = 'kmh';
    HUD_CONFIG.theme = 'cyberpunk';
    HUD_CONFIG.scale = 1.0;
    HUD_CONFIG.opacity = 1.0;
    HUD_CONFIG.positions = {};
    applyPresetTheme('cyberpunk');
    setStatusStyle(1);
    setSpeedoStyle(1);
    
    // Clear custom positions
    document.querySelectorAll('.hud-component').forEach(el => {
        el.style.left = ''; el.style.top = ''; el.style.bottom = ''; el.style.right = '';
    });
    saveSettings();
}

// NUI Messages from Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    switch (data.action) {
        case 'openEditor':
            openEditor();
            break;
        case 'show':
            document.getElementById('hud-wrapper').style.display = 'block';
            break;
        case 'hide':
            document.getElementById('hud-wrapper').style.display = 'none';
            break;
        case 'updateStatusFast':
            GAME_DATA.health = data.health ?? GAME_DATA.health;
            GAME_DATA.armor = data.armor ?? GAME_DATA.armor;
            GAME_DATA.stamina = data.stamina ?? GAME_DATA.stamina;
            GAME_DATA.isTalking = data.isTalking ?? GAME_DATA.isTalking;
            updateHUDComponents();
            break;
        case 'updateStatusSlow':
            GAME_DATA.hunger = data.hunger ?? GAME_DATA.hunger;
            GAME_DATA.thirst = data.thirst ?? GAME_DATA.thirst;
            updateHUDComponents();
            break;
        case 'updateVoiceMode':
            GAME_DATA.voiceLevel = data.level ?? 66;
            GAME_DATA.voiceLabel = data.label ?? "Normal";
            updateHUDComponents();
            break;
        case 'toggleSpeedo':
            speedoContainer.classList.toggle('hidden', !data.show);
            if (data.show) updateSpeedometer();
            break;
        case 'updateVehicle':
            GAME_DATA.speedKmh = data.kmh ?? 0;
            GAME_DATA.speedMph = data.mph ?? 0;
            GAME_DATA.rpm = data.rpm ?? 0;
            GAME_DATA.gear = data.gear ?? 1;
            GAME_DATA.fuel = data.fuel ?? 100;
            GAME_DATA.seatbelt = data.seatbelt ?? false;
            GAME_DATA.engineOn = data.engineOn ?? true;
            GAME_DATA.engineHealth = data.engineHealth ?? 100;
            GAME_DATA.street = data.street ?? "Legion Square";
            GAME_DATA.zone = data.zone ?? "Downtown LS";

            document.getElementById('street-name').textContent = GAME_DATA.street;
            document.getElementById('zone-name').textContent = GAME_DATA.zone;
            updateSpeedometer();
            break;
        case 'resetHUD':
            resetHUD();
            break;
        case 'loadKvpSettings':
            if (data.settings) {
                HUD_CONFIG = { ...HUD_CONFIG, ...data.settings };
                applyThemeAndColors();
                setStatusStyle(HUD_CONFIG.statusStyle || 1);
                setSpeedoStyle(HUD_CONFIG.speedoStyle || 1);
                applySavedPositions();
            }
            break;
    }
});

// Position restores
function applySavedPositions() {
    if (!HUD_CONFIG.positions) return;
    Object.keys(HUD_CONFIG.positions).forEach(id => {
        const el = document.getElementById(id);
        const pos = HUD_CONFIG.positions[id];
        if (el && pos) {
            el.style.left = pos.left;
            el.style.top = pos.top;
            el.style.bottom = 'auto';
            el.style.right = 'auto';
        }
    });
}

// Local storage & KVP save
function saveSettings() {
    localStorage.setItem('vater_hud_settings_v3', JSON.stringify(HUD_CONFIG));
    fetch(`https://${GetParentResourceName()}/saveKvpSettings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ settings: HUD_CONFIG })
    }).catch(() => {});
}

function loadLocalSettings() {
    const saved = localStorage.getItem('vater_hud_settings_v3');
    if (saved) {
        try {
            HUD_CONFIG = JSON.parse(saved);
        } catch (e) {}
    }
}
