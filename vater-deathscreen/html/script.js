const deathScreen = document.getElementById('death-screen');
const killerAvatar = document.getElementById('killer-avatar');
const killerText = document.getElementById('killer-text');
const countdownWrapper = document.getElementById('countdown-wrapper');
const countdownTimer = document.getElementById('countdown-timer');
const respawnPrompt = document.getElementById('respawn-prompt');
const progressBarFill = document.getElementById('progress-bar-fill');

window.addEventListener('message', (event) => {
    const action = event.data.action;
    const data = event.data.data;

    if (action === 'openDeathScreen') {
        // Reset elements
        progressBarFill.style.width = '0%';
        countdownWrapper.classList.remove('hidden');
        respawnPrompt.classList.add('hidden');
        
        // Populate Killer Details
        if (data.killerName && data.killerName !== '') {
            killerText.innerHTML = `<span class="highlight-red">${escapeHtml(data.killerName)} (${data.killerServerId})</span> TARAFINDAN ÖLDÜRÜLDÜN`;
        } else {
            killerText.innerHTML = `<span class="highlight-red">ÖLDÜNÜZ</span>`;
        }

        if (data.killerAvatar && data.killerAvatar !== '') {
            killerAvatar.src = data.killerAvatar;
        } else {
            killerAvatar.removeAttribute('src'); // Fallback avatar will show automatically
        }

        // Show UI
        deathScreen.classList.remove('hidden');
        setTimeout(() => {
            deathScreen.classList.add('visible');
        }, 50);

    } else if (action === 'closeDeathScreen') {
        deathScreen.classList.remove('visible');
        setTimeout(() => {
            deathScreen.classList.add('hidden');
        }, 500);

    } else if (action === 'updateCountdown') {
        countdownTimer.textContent = data.seconds;

    } else if (action === 'showRespawnPrompt') {
        countdownWrapper.classList.add('hidden');
        respawnPrompt.classList.remove('hidden');
        progressBarFill.style.width = '0%';

    } else if (action === 'updateEProgress') {
        progressBarFill.style.width = data.progress + '%';

    } else if (action === 'updateKillerAvatar') {
        if (data.killerAvatar && data.killerAvatar !== '') {
            killerAvatar.src = data.killerAvatar;
        } else {
            killerAvatar.removeAttribute('src');
        }
    }
});

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}
