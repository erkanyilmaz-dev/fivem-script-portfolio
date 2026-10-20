/**
 * VaterPVP HUD — script.js
 * NUI mesajlarını dinler, DOM'u günceller, durum yönetimini ve
 * tarayıcı önizleme test panelini kontrol eder.
 */

'use strict';

// ── DOM Referansları ──────────────────────────────────────────────
const hudWrapper     = document.getElementById('hud-wrapper');
const rankCard       = document.getElementById('rank-card');
const statusCard     = document.getElementById('status-card');
const notificationFeed = document.getElementById('notification-feed');

const timeEl         = document.getElementById('hud-time');
const dateEl         = document.getElementById('hud-date');

const killsEl        = document.getElementById('hud-kills');
const deathsEl       = document.getElementById('hud-deaths');
const streakEl       = document.getElementById('hud-streak');
const streakContainer = document.getElementById('streak-container');

const rankNameEl     = document.getElementById('rank-name');
const rankLvlEl      = document.getElementById('rank-lvl');
const xpBarFill      = document.getElementById('xp-bar-fill');
const xpTextEl       = document.getElementById('xp-text');

const healthBarFill  = document.getElementById('health-bar-fill');
const healthValEl    = document.getElementById('health-val');
const armorBarFill   = document.getElementById('armor-bar-fill');
const armorValEl     = document.getElementById('armor-val');

// Test Paneli Referansları
const previewTestPanel = document.getElementById('preview-test-panel');
const togglePanelBtn = document.getElementById('toggle-panel-btn');
const openPanelBtn = document.getElementById('open-panel-btn');

// ── Durum Yönetimi (State) ─────────────────────────────────────────
const State = {
  kills: 0,
  deaths: 0,
  streak: 0,
  level: 1,
  xp: 0,
  xpToNextLevel: 100,
  health: 100,
  armor: 50,
};

const RankTitles = {
  1: "BRONZE I",
  2: "BRONZE II",
  3: "SILVER I",
  4: "SILVER II",
  5: "GOLD I",
  6: "GOLD II",
  7: "DIAMOND",
  8: "GIGACHAD",
};

// ── Yardımcı: Sayı Değişim Efekti ──────────────────────────────────
function animateValueChange(el, newValue) {
  const current = el.textContent;
  const next = String(newValue);
  if (current === next) return;

  el.textContent = next;
  el.classList.remove('updated');
  void el.offsetWidth; // Reflow tetikle
  el.classList.add('updated');

  setTimeout(() => el.classList.remove('updated'), 500);
}

// ── Yardımcı: Seviye İsmi Belirle ──────────────────────────────────
function getRankTitle(level) {
  if (level >= 8) return RankTitles[8];
  return RankTitles[level] || "RECRUIT";
}

// ── XP & Seviye Mantığı ───────────────────────────────────────────
function updateRankUI() {
  rankNameEl.textContent = getRankTitle(State.level);
  rankLvlEl.textContent = `LVL ${State.level}`;
  
  const xpPercent = Math.max(0, Math.min(100, (State.xp / State.xpToNextLevel) * 100));
  xpBarFill.style.width = `${xpPercent}%`;
  xpTextEl.textContent = `${State.xp} / ${State.xpToNextLevel}`;
}

function addXP(amount) {
  State.xp += amount;
  
  if (State.xp >= State.xpToNextLevel) {
    State.xp -= State.xpToNextLevel;
    State.level++;
    
    // Level Up Flaş Efekti
    rankCard.classList.remove('level-up-animate');
    void rankCard.offsetWidth; // Reflow
    rankCard.classList.add('level-up-animate');
    
    spawnNotification("TEBRİKLER! YENİ PVP RÜTBESİNE ULAŞTINIZ! 🎉", 4500);
    
    setTimeout(() => {
      rankCard.classList.remove('level-up-animate');
    }, 1200);
  }
  updateRankUI();
}

// ── Can & Zırh Güncelleme ─────────────────────────────────────────
function updateStatusUI() {
  // Can güncelleme
  healthBarFill.style.width = `${State.health}%`;
  healthValEl.textContent = State.health;

  // Zırh güncelleme
  armorBarFill.style.width = `${State.armor}%`;
  armorValEl.textContent = State.armor;

  // Kritik can uyarısı (< 25%)
  if (State.health <= 25) {
    statusCard.classList.add('critical-alert');
  } else {
    statusCard.classList.remove('critical-alert');
  }
}

// ── Dinamik Bildirim Gönderme (Notification Feed) ─────────────────
function spawnNotification(message, duration = 3500) {
  const notif = document.createElement('div');
  notif.className = 'hud-notification';
  
  // Eğer bildirim öldürme veya pvp ile ilgiliyse farklı renk sınıfı ekle
  if (message.includes('ELENDİ') || message.includes('KILLED') || message.includes('KILL')) {
    notif.classList.add('kill-event');
  }

  const textNode = document.createElement('span');
  textNode.className = 'notif-text';
  textNode.innerHTML = message;
  
  notif.appendChild(textNode);
  notificationFeed.appendChild(notif);

  // Belirli süre sonra sil
  setTimeout(() => {
    notif.classList.add('fade-out');
    notif.addEventListener('animationend', () => {
      notif.remove();
    });
  }, duration);
}

// ── NUI Actions ──────────────────────────────────────────────────
const actions = {
  // HUD Göster / Gizle
  show() {
    hudWrapper.classList.add('visible');
    rankCard.style.display = 'flex';
    statusCard.style.display = 'flex';
  },

  hide() {
    hudWrapper.classList.remove('visible');
    rankCard.style.display = 'none';
    statusCard.style.display = 'none';
  },

  // Saat & Tarih güncelleme
  updateDateTime({ time, date }) {
    if (time) timeEl.textContent = time;
    if (date) dateEl.textContent = date;
  },

  // Can & Zırh güncelleme
  updateStatus({ health, armor }) {
    if (health !== undefined) State.health = health;
    if (armor !== undefined) State.armor = armor;
    updateStatusUI();
  },

  // İstatistikleri güncelleme
  updateStats({ kills, deaths, streak }) {
    if (kills !== undefined) {
      animateValueChange(killsEl, kills);
      // Eğer kill arttıysa XP ekle
      if (kills > State.kills) {
        const diff = kills - State.kills;
        addXP(diff * 20); // Her kill için 20 XP
      }
      State.kills = kills;
    }

    if (deaths !== undefined) {
      animateValueChange(deathsEl, deaths);
      State.deaths = deaths;
    }

    if (streak !== undefined) {
      animateValueChange(streakEl, streak);
      State.streak = streak;

      // Streak sıfırdan büyükse göstergeyi aç
      if (streak > 0) {
        streakContainer.style.display = 'flex';
      } else {
        streakContainer.style.display = 'none';
      }
    }
  },

  // Özel NUI bildirimi tetikleme
  notification({ message, duration }) {
    spawnNotification(message, duration);
  }
};

// ── NUI Mesaj Dinleyicisi ─────────────────────────────────────────
window.addEventListener('message', (event) => {
  const data = event.data;
  const action = data?.action;

  if (action && actions[action]) {
    actions[action](data);
  }
});

// ─────────────────────────────────────────────────────────────────
// TARAYICI ÖNİZLEME MODU (BROWSER PREVIEW)
// FiveM dışında (doğrudan tarayıcıda açıldığında) önizlemeyi aktif et.
// ─────────────────────────────────────────────────────────────────
(function initBrowserPreview() {
  // FiveM ortamında window.invokeNative tanımlıdır.
  if (typeof window.invokeNative !== 'undefined') return;

  // HUD elemanlarını görünür kıl
  hudWrapper.classList.add('visible');
  rankCard.style.display = 'flex';
  statusCard.style.display = 'flex';

  // Test paneli butonlarını aktif et
  openPanelBtn.style.display = 'flex';
  previewTestPanel.style.display = 'flex';

  // Buton Tıklama Olayları
  togglePanelBtn.addEventListener('click', () => {
    previewTestPanel.style.display = 'none';
  });

  openPanelBtn.addEventListener('click', () => {
    previewTestPanel.style.display = 'flex';
  });

  // +1 Kill Ekle
  document.getElementById('btn-add-kill').addEventListener('click', () => {
    State.kills++;
    State.streak++;
    
    actions.updateStats({ 
      kills: State.kills, 
      deaths: State.deaths, 
      streak: State.streak 
    });

    spawnNotification("DÜŞMAN ETKİSİZ HALE GETİRİLDİ! ☠️", 3000);
  });

  // +20 XP Ekle
  document.getElementById('btn-add-xp').addEventListener('click', () => {
    addXP(20);
  });

  // Hasar Al
  document.getElementById('btn-damage').addEventListener('click', () => {
    State.health = Math.max(10, State.health - 20);
    State.armor = Math.max(0, State.armor - 15);
    updateStatusUI();
    
    spawnNotification("⚠️ HASAR ALDINIZ! CAN KRİTİK!", 2500);
  });

  // Canlandır
  document.getElementById('btn-heal').addEventListener('click', () => {
    State.health = 100;
    State.armor = 100;
    updateStatusUI();
    
    spawnNotification("❤️ CAN VE ZIRH YENİLENDİ!", 2500);
  });

  // Rastgele Bildirim
  const sampleNotifications = [
    "Headshot! 🎯 +10 Bonus XP",
    "Double Kill! 🔥 Sunucu Sallanıyor!",
    "Öldürme Serisi Yakaladın! 💀",
    "Düşman intikam almak için geri döndü! 🧾",
    "PVP Arenasında Yeni Lider: WRAITHPVP! 👑"
  ];

  document.getElementById('btn-trigger-notif').addEventListener('click', () => {
    const randomMsg = sampleNotifications[Math.floor(Math.random() * sampleNotifications.length)];
    spawnNotification(randomMsg, 3500);
  });

  // Saat simülasyonu
  function updateRealClock() {
    const now = new Date();
    let hour = now.getHours();
    const minute = String(now.getMinutes()).padStart(2, '0');
    const period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    else if (hour === 0) hour = 12;

    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const year = now.getFullYear();

    timeEl.textContent = `${String(hour).padStart(2, '0')}:${minute} ${period}`;
    dateEl.textContent = `${month}/${day}/${year}`;
  }

  updateRealClock();
  setInterval(updateRealClock, 1000);
  updateRankUI();
  updateStatusUI();
})();
