let isPlaying = true;
let totalFrames = 1;
let currentSpeed = 1.0;
let lastJsToggle = 0;

document.addEventListener('DOMContentLoaded', () => {
    // NUI Message Listener
    window.addEventListener('message', (event) => {
        const item = event.data;
        if (!item || !item.action) return;

        switch (item.action) {
            case 'openScannerList':
                renderScannerList(item.incidents || []);
                hideModal('name-modal');
                hideModal('btn-toggle-focus-mode');
                showModal('scanner-modal');
                break;

            case 'openPlaybackUI':
                setupPlaybackUI(item);
                hideModal('scanner-modal');
                hideModal('name-modal');
                showModal('playback-overlay');
                showModal('btn-toggle-focus-mode');
                break;

            case 'updateModeBadge':
                updateModeBadge(item.isCursorActive);
                break;

            case 'updateTimeline':
                updateSliderPosition(item.currentFrame);
                break;

            case 'closeUI':
                hideModal('scanner-modal');
                hideModal('name-modal');
                hideModal('playback-overlay');
                hideModal('btn-toggle-focus-mode');
                break;
        }
    });

    // Close Buttons
    document.getElementById('btn-close-scanner').addEventListener('click', closeUI);
    document.getElementById('btn-exit-playback').addEventListener('click', closeUI);

    // Cancel / Close Name Input Modal -> Return to Scanner List
    document.getElementById('btn-close-name').addEventListener('click', () => {
        hideModal('name-modal');
        showModal('scanner-modal');
    });

    document.getElementById('btn-cancel-name').addEventListener('click', () => {
        hideModal('name-modal');
        showModal('scanner-modal');
    });

    // Floating Mode Toggle Button Click
    document.getElementById('btn-toggle-focus-mode').addEventListener('click', () => {
        fetchNui('toggleFocusMode');
    });

    // Keyboard Listeners (ESC to Close, ALT / TAB to Toggle Focus Mode)
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeUI();
        } else if (e.key === 'Alt' || e.code === 'AltLeft' || e.code === 'AltRight' || e.key === 'Tab') {
            e.preventDefault();
            const now = Date.now();
            if (now - lastJsToggle > 250) {
                lastJsToggle = now;
                fetchNui('toggleFocusMode');
            }
        }
    });

    // Play / Pause Toggle
    const playPauseBtn = document.getElementById('btn-play-pause');
    playPauseBtn.addEventListener('click', () => {
        isPlaying = !isPlaying;
        playPauseBtn.innerHTML = isPlaying ? '<i class="fa-solid fa-pause"></i>' : '<i class="fa-solid fa-play"></i>';
        fetchNui(isPlaying ? 'play' : 'pause');
    });

    // Speed Control Buttons
    document.querySelectorAll('.btn-speed').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('.btn-speed').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            currentSpeed = parseFloat(e.target.dataset.speed);
            fetchNui('setSpeed', { speed: currentSpeed });
        });
    });

    // Filter Buttons
    document.querySelectorAll('.btn-filter').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.target.classList.toggle('active');
            const filterType = e.target.dataset.filter;
            fetchNui('toggleFilter', { filter: filterType });
        });
    });

    // Timeline Slider Drag / Scrubbing
    const slider = document.getElementById('timeline-slider');
    slider.addEventListener('input', (e) => {
        const targetFrame = parseInt(e.target.value);
        updateTimeDisplay(targetFrame);
        fetchNui('scrubTimeline', { frame: targetFrame });
    });

    // Start Area Scanning Minigame
    const btnScanCurrent = document.getElementById('btn-start-area-scan');
    if (btnScanCurrent) {
        btnScanCurrent.addEventListener('click', () => {
            hideModal('scanner-modal');
            fetchNui('startAreaScan', {});
        });
    }

    // Confirm Save Incident Function
    const handleConfirmSave = () => {
        const nameInput = document.getElementById('incident-name-input').value.trim();
        const finalName = nameInput.length > 0 ? nameInput : 'Olay Yeri Kaydı';
        fetchNui('saveCurrentBuffer', { name: finalName });
        hideModal('name-modal');
        showModal('scanner-modal');
    };

    // Open Save Prompt Modal (Hide scanner modal & show name input)
    document.getElementById('btn-save-manual-prompt').addEventListener('click', () => {
        document.getElementById('incident-name-input').value = '';
        hideModal('scanner-modal');
        showModal('name-modal');
        setTimeout(() => {
            document.getElementById('incident-name-input').focus();
        }, 100);
    });

    // Confirm Save Incident Button
    document.getElementById('btn-confirm-save').addEventListener('click', handleConfirmSave);

    // Enter Key on Name Input to Submit
    document.getElementById('incident-name-input').addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            handleConfirmSave();
        }
    });
});

// Update Mode Toggle Button Visual State
function updateModeBadge(isCursorActive) {
    const btn = document.getElementById('btn-toggle-focus-mode');
    const text = document.getElementById('mode-toggle-text');

    if (isCursorActive) {
        btn.classList.remove('camera-mode');
        text.innerText = 'ARAYÜZ KONTROLÜ';
    } else {
        btn.classList.add('camera-mode');
        text.innerText = 'SERBEST KAMERA';
    }
}

// Render Scanner List
function renderScannerList(incidents) {
    const container = document.getElementById('incident-list');
    container.innerHTML = '';

    if (!incidents || incidents.length === 0) {
        container.innerHTML = `
            <div class="incident-card" style="justify-content: center; padding: 24px; color: var(--text-muted); font-size: 12px; text-align: center;">
                <i class="fa-solid fa-circle-info" style="margin-right: 6px;"></i>
                <span>Bu bölgede yakın zamanda kaydedilmiş olay kaydı bulunamadı.</span>
            </div>
        `;
        return;
    }

    incidents.forEach(inc => {
        const card = document.createElement('div');
        card.className = 'incident-card';
        card.innerHTML = `
            <div class="card-info">
                <div class="card-title-group">
                    <span class="card-serial">${inc.serialId}</span>
                    <span class="card-name">${inc.name || 'Olay Yeri Kaydı'}</span>
                </div>
                <div class="card-details">
                    <span><i class="fa-solid fa-tag"></i> ${inc.triggerType}</span>
                    <span><i class="fa-solid fa-location-arrow"></i> ${inc.distance}m</span>
                    <span><i class="fa-solid fa-clock"></i> ${inc.timestamp}</span>
                </div>
            </div>
            <div class="card-actions">
                <button class="btn-reconstruct" onclick="loadIncident(${inc.id})">
                    <i class="fa-solid fa-play"></i> CANLANDIR
                </button>
                <button class="btn-delete" onclick="deleteIncident(${inc.id})" title="Sil">
                    <i class="fa-solid fa-trash"></i>
                </button>
            </div>
        `;
        container.appendChild(card);
    });
}

// Load Selected Incident
function loadIncident(dbId) {
    fetchNui('loadIncident', { id: dbId });
}

// Delete Selected Incident
function deleteIncident(dbId) {
    fetchNui('deleteIncident', { id: dbId });
}

// Setup Playback HUD Overlay
function setupPlaybackUI(data) {
    document.getElementById('badge-serial-id').innerText = data.serialId || 'SN-2026-000000';
    document.getElementById('badge-incident-name').innerText = data.name || 'Olay Yeri Kaydı';
    document.getElementById('meta-type').innerHTML = `<i class="fa-solid fa-bolt"></i> ${data.triggerType.toUpperCase()}`;
    document.getElementById('meta-time').innerHTML = `<i class="fa-solid fa-clock"></i> ${data.timestamp}`;

    totalFrames = data.totalFrames || 100;
    const slider = document.getElementById('timeline-slider');
    slider.min = 1;
    slider.max = totalFrames;
    slider.value = 1;

    isPlaying = true;
    document.getElementById('btn-play-pause').innerHTML = '<i class="fa-solid fa-pause"></i>';

    const totalSeconds = data.duration || Math.floor((totalFrames * 100) / 1000);
    document.getElementById('total-time').innerText = formatTime(totalSeconds);
    document.getElementById('current-time').innerText = '00:00';

    updateModeBadge(true);
}

// Update Slider Position
function updateSliderPosition(frame) {
    const slider = document.getElementById('timeline-slider');
    slider.value = frame;
    updateTimeDisplay(frame);
}

// Helper: Format Frame to MM:SS Time
function updateTimeDisplay(frame) {
    const seconds = Math.floor((frame * 100) / 1000);
    document.getElementById('current-time').innerText = formatTime(seconds);
}

function formatTime(totalSecs) {
    const mins = Math.floor(totalSecs / 60);
    const secs = totalSecs % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

// Helper UI Toggles
function showModal(id) {
    document.getElementById(id).classList.remove('hidden');
}

function hideModal(id) {
    document.getElementById(id).classList.add('hidden');
}

function closeUI() {
    hideModal('scanner-modal');
    hideModal('name-modal');
    hideModal('playback-overlay');
    hideModal('btn-toggle-focus-mode');
    fetchNui('closeUI');
}

// FiveM NUI Fetch Wrapper
function fetchNui(cbName, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${cbName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).catch(err => console.log('NUI Fetch Error:', err));
}
