/* ================================================
   VATER SCRIPTS - LOADING SCREEN V2
   JavaScript Application Logic & Configuration
   ================================================ */

'use strict';

/* ╔══════════════════════════════════════════════════════════════════════════╗
   ║                           ⚙️  KOLAY AYAR PANELİ                           ║
   ╠══════════════════════════════════════════════════════════════════════════╣
   ║  Düzenlemen gereken TEK DOSYA: html/js/app.js                            ║
   ║  Aşağıdaki CONFIG objesi üzerinden tüm içeriği değiştirebilirsin.       ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */
const CONFIG = {

    // ────────────────────────────────────────────────────────────────────────
    //  1. 🖼️ ARKAPLAN AYARI (Video veya Resim)
    // ────────────────────────────────────────────────────────────────────────
    //  • Video kullanmak için : type: "video", source: "img/bg.mp4"
    //  • Resim kullanmak için : type: "image", source: "img/bg.png"
    //
    //  NASIL DEĞİŞTİRİLİR?
    //  Yeni video veya resim dosyanı "html/img/" klasörü içine atıp
    //  aşağıdaki "source" kısmına dosya adını yazman yeterlidir.
    // ────────────────────────────────────────────────────────────────────────
    background: {
        type:   "video",       // "video" veya "image"
        source: "img/bg.mp4",  // html/img/ içindeki dosya yolu (Örn: img/bg.mp4 veya img/bg.png)
    },

    // ────────────────────────────────────────────────────────────────────────
    //  2. 🎵 MÜZİK AYARLARI (Şarkı Ekleme / Değiştirme)
    // ────────────────────────────────────────────────────────────────────────
    //  NASIL ŞARKI DEĞİŞTİRİLİR?
    //  1. Yeni .mp3 dosyanı "html/img/" klasörüne at (Örn: sarki.mp3).
    //  2. Aşağıdaki "file" kısmına "img/sarki.mp3" yaz.
    //  3. "title" kısmına şarkı adını, "artist" kısmına alt yazıyı yaz.
    // ────────────────────────────────────────────────────────────────────────
    music: [
        {
            title:  "Vater Scripts",   // Ekranın altındaki müzik çalarda görünen Başlık
            artist: "Sunucu Müziği",   // Altındaki Açıklama
            file:   "img/music.mp3",   // html/img/ içindeki .mp3 dosyasının yolu
        },
        // Birden fazla şarkı eklemek istersen virgül koyup yeni satır ekle:
        // { title: "İkinci Şarkı", artist: "Sanatçı Adı", file: "img/sarki2.mp3" },
    ],
    musicVolume: 50,   // Başlangıç ses seviyesi (0 ile 100 arasında)
    autoPlay:    true, // Oyuncu girince müzik otomatik başlasın mı? (true / false)

    // ────────────────────────────────────────────────────────────────────────
    //  3. 👥 SUNUCU EKİBİ (Ekip Üyesi Ekleme / Silme / Düzenleme)
    // ────────────────────────────────────────────────────────────────────────
    //  YENİ EKİP ÜYESİ EKLEMEK İÇİN:
    //  En alta yeni bir satır ekle:
    //  { name: "İsim", role: "Unvan", roleKey: "owner", initial: "Harf", online: true },
    //
    //  EKİP ÜYESİ SİLMEK İÇİN:
    //  Silmek istediğin kişinin satırını komple sil.
    //
    //  ROL ANHTARLARI (roleKey):
    //  • "owner"     → Kurucu (Altın / Sarı renk)
    //  • "admin"     → Admin (Mavi renk)
    //  • "moderator" → Moderatör (Mor renk)
    //  • "developer" → Yazılımcı (Yeşil renk)
    //  • "support"   → Destek (Turuncu renk)
    // ────────────────────────────────────────────────────────────────────────
    staff: [
        { name: "Vater",   role: "Kurucu",    roleKey: "owner",     initial: "E",  online: true  },
        
    ],

    // ────────────────────────────────────────────────────────────────────────
    //  4. 📢 SON GÜNCELLEMELER
    // ────────────────────────────────────────────────────────────────────────
    updates: [
        { date: "Ağu 8, 2026",  title: "Büyük Sunucu Güncellemesi!", desc: "Yeni araç paketi, performans iyileştirmeleri ve hata düzeltmeleri canlıya alındı." },
        { date: "Ağu 5, 2026",  title: "Yeni MLO Lokasyonlar Eklendi", desc: "Premium lokasyonlar sunucuya eklendi. Tüm sahneleri keşfet!" },
        { date: "Tem 28, 2026", title: "Staff Başvuruları Açık", desc: "Sunucumuza katılmak isteyen adaylar Discord üzerinden başvurabilir." },
    ],

    // ────────────────────────────────────────────────────────────────────────
    //  5. 💡 LOADING İPUÇLARI (Ekranda Sırayla Dönen İpuçları)
    // ────────────────────────────────────────────────────────────────────────
    hints: [
        "Şehirde sosyalleşmek için Otel, Hastane, LS Customs ve diğer işletmeleri ziyaret edebilirsin.",
        "F6 tuşuna basarak radyal menüyü açabilir ve tüm iş seçeneklerine ulaşabilirsin.",
        "Karakter geçmişini oluşturmak için karakter oluşturma ekranında dikkatli seçimler yap.",
        "Diğer oyuncularla iletişim kurmak için /me, /do ve /try komutlarını kullanabilirsin.",
        "Emniyet kemeri tak, trafik kurallarına uy! Trafik cezaları gerçektir.",
        "Discord sunucumuza katılarak etkinlikler ve duyurulardan haberdar ol.",
        "İlk kez katılıyorsan /yardım komutunu kullanarak tüm komutlara ulaşabilirsin.",
    ],

    // ────────────────────────────────────────────────────────────────────────
    //  6. 🔗 SOSYAL MEDYA LİNKLERİ (Sağ Üstteki Butonlar)
    // ────────────────────────────────────────────────────────────────────────
    socialLinks: {
        discord: "https://discord.gg/vaterscripts",
        youtube: "https://youtube.com/@vaterscripts",
        tiktok:  "https://tiktok.com/@vaterscripts",
    },
    discordLink: "https://discord.gg/vaterscripts",
    youtubeLink: "https://youtube.com/@vaterscripts",
    tiktokLink:  "https://tiktok.com/@vaterscripts",

    // ────────────────────────────────────────────────────────────────────────
    //  7. 📋 SUNUCU KURALLARI (Üst Menüdeki Kurallar Sekmesi)
    // ────────────────────────────────────────────────────────────────────────
    rules: [
        { title: "1. Roleplay Kuralları",  desc: "Karakterini gerçekçi oyna. OOC bilgini IC'de kullanma. Powergaming ve Metagaming yasaktır." },
        { title: "2. RDM/VDM Yasağı",     desc: "Sebepsiz yere oyuncu öldürmek veya araç çarpmak kesinlikle yasaktır." },
        { title: "3. Combat Logging",      desc: "Roleplay sırasında sunucudan ayrılmak yasaktır. Ceza uygulanır." },
        { title: "4. Fail RP",            desc: "Karakterinin korku duymadığı durumlar Fail RP sayılır." },
        { title: "5. Saygılı Ol",         desc: "Tüm oyunculara ve yetkililere saygılı davranılması zorunludur." },
        { title: "6. Reklam Yasağı",      desc: "Başka sunucu veya platformların reklamı kesinlikle yasaktır." },
    ],
};

/* ══════════════════════════════════════════════════════════════════════════╗
   ║                        AŞAĞIDAKİ KODLARI DÜZENLEMEYİN                      ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */

let currentProgress  = 0;
let loadingFinished  = false;
let currentSongIndex = 0;
let isPlaying        = false;
let currentHintIndex = 0;

const loadingMessages = [
    "Sunucuya Bağlanılıyor...",
    "Harita Yükleniyor...",
    "Modlar Başlatılıyor...",
    "Araçlar Hazırlanıyor...",
    "Karakterler Yükleniyor...",
    "Dünya İnşa Ediliyor...",
    "Son Dokunuşlar...",
    "Neredeyse Hazır...",
    "Hoş Geldin, VaterScripts!",
];

// ─── Initialize ───────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    initBackground();
    renderStaff();
    renderUpdates();
    startClock();
    startHintRotation();
    startLoadingSimulation();
    initNavigation();
    updateSocialLinks();
    initMusic();
    animateEntrance();
});

// ─── Background ───────────────────────────────────────
function initBackground() {
    const bgImage   = document.getElementById('bgImage');
    const bgVideo   = document.getElementById('bgVideo');
    const bgYoutube = document.getElementById('bgYoutube');

    if (bgImage)   bgImage.style.display   = 'none';
    if (bgYoutube) bgYoutube.style.display = 'none';

    if (bgVideo) {
        bgVideo.style.display = 'block';
        bgVideo.muted = true;
        bgVideo.currentTime = 0;
        bgVideo.play().catch(() => {
            if (bgImage) {
                bgImage.style.backgroundImage = "url('img/bg.png')";
                bgImage.style.display = 'block';
            }
        });
    }
}

// ─── Music ────────────────────────────────────────────
function initMusic() {
    const song = CONFIG.music[currentSongIndex];
    if (!song) return;

    updateMusicUI(song.title, song.artist);

    const slider = document.getElementById('volumeSlider');
    if (slider) slider.value = CONFIG.musicVolume;

    const audio = document.getElementById('bgMusic');
    if (audio && song.file) {
        audio.src = song.file;
        audio.volume = CONFIG.musicVolume / 100;
        if (CONFIG.autoPlay) {
            playAudio();
        }
    }

    document.body.addEventListener('click', function autoPlayOnClick() {
        if (!isPlaying) {
            playAudio();
        }
        document.body.removeEventListener('click', autoPlayOnClick);
    }, { once: true });
}

function playAudio() {
    const audio = document.getElementById('bgMusic');
    if (!audio) return;
    audio.play().then(() => {
        isPlaying = true;
        setPlayPauseIcon(true);
    }).catch(err => {
        console.log('Ses başlatılamadı:', err);
    });
}

function pauseAudio() {
    const audio = document.getElementById('bgMusic');
    if (!audio) return;
    audio.pause();
    isPlaying = false;
    setPlayPauseIcon(false);
}

function toggleMusic() {
    if (isPlaying) {
        pauseAudio();
    } else {
        playAudio();
    }
}

function nextSong() {
    const songs = CONFIG.music;
    if (!songs || songs.length <= 1) return;
    currentSongIndex = (currentSongIndex + 1) % songs.length;
    loadSong(currentSongIndex);
}

function prevSong() {
    const songs = CONFIG.music;
    if (!songs || songs.length <= 1) return;
    currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
    loadSong(currentSongIndex);
}

function loadSong(index) {
    const song = CONFIG.music[index];
    if (!song) return;
    updateMusicUI(song.title, song.artist);
    if (isPlaying) {
        playAudio();
    }
}

function setVolume(val) {
    const audio = document.getElementById('bgMusic');
    if (audio) audio.volume = val / 100;
}

function updateMusicUI(title, artist) {
    const titleEl  = document.getElementById('musicTitle');
    const artistEl = document.querySelector('.music-artist');
    if (titleEl)  titleEl.textContent  = title;
    if (artistEl) artistEl.textContent = artist;
}

function setPlayPauseIcon(playing) {
    const playIcon  = document.getElementById('playIcon');
    const pauseIcon = document.getElementById('pauseIcon');
    if (playIcon)  playIcon.style.display  = playing ? 'none' : '';
    if (pauseIcon) pauseIcon.style.display = playing ? '' : 'none';
}

// ─── Staff ────────────────────────────────────────────
function renderStaff() {
    const container = document.getElementById('staffList');
    if (!container) return;
    container.innerHTML = CONFIG.staff.map(m => `
        <div class="staff-item">
            <div class="staff-avatar avatar-${m.roleKey} ${m.online ? '' : 'offline'}">${m.initial}</div>
            <div class="staff-info">
                <span class="staff-name">${m.name}</span>
                <span class="staff-role role-${m.roleKey}">${m.role}</span>
            </div>
        </div>
    `).join('');
}

// ─── Updates ──────────────────────────────────────────
function renderUpdates() {
    const container = document.getElementById('updatesList');
    if (!container) return;
    container.innerHTML = CONFIG.updates.map(u => `
        <div class="update-item">
            <div class="update-date">${u.date}</div>
            <div class="update-title">${u.title}</div>
            <div class="update-desc">${u.desc}</div>
        </div>
    `).join('');
}

// ─── Clock ────────────────────────────────────────────
function startClock() {
    const update = () => {
        const now = new Date();
        const el = document.getElementById('serverTime');
        if (el) el.textContent = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
    };
    update();
    setInterval(update, 1000);
}

// ─── Hints ────────────────────────────────────────────
function startHintRotation() {
    const el = document.getElementById('hintText');
    if (!el) return;
    el.textContent = CONFIG.hints[0];
    setInterval(() => {
        currentHintIndex = (currentHintIndex + 1) % CONFIG.hints.length;
        el.style.cssText += 'opacity:0;transform:translateY(4px);transition:opacity 0.3s,transform 0.3s;';
        setTimeout(() => {
            el.textContent = CONFIG.hints[currentHintIndex];
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }, 320);
    }, 6000);
}

// ─── Loading Bar ──────────────────────────────────────
function startLoadingSimulation() {
    const steps = [
        { target: 15,  delay: 400  },
        { target: 35,  delay: 900  },
        { target: 55,  delay: 1100 },
        { target: 70,  delay: 700  },
        { target: 85,  delay: 1000 },
        { target: 100, delay: 1600 },
    ];
    let i = 0;
    const advance = () => {
        if (i >= steps.length) return;
        const step = steps[i++];
        setTimeout(() => {
            animateProgress(step.target);
            const el = document.getElementById('loadingText');
            if (el) el.textContent = loadingMessages[Math.min(i, loadingMessages.length - 1)];
            advance();
        }, step.delay);
    };
    advance();
}

function animateProgress(target) {
    const bar  = document.getElementById('progressBar');
    const pct  = document.getElementById('progressPercent');
    const start = currentProgress;
    const diff  = target - start;
    const t0    = performance.now();
    const tick  = (now) => {
        const t = Math.min((now - t0) / 600, 1);
        const e = 1 - Math.pow(1 - t, 3);
        currentProgress = start + diff * e;
        if (bar) bar.style.width = currentProgress + '%';
        if (pct) pct.textContent = Math.round(currentProgress) + '%';
        if (t < 1) requestAnimationFrame(tick);
        else {
            currentProgress = target;
            if (target >= 100) onLoadingComplete();
        }
    };
    requestAnimationFrame(tick);
}

function onLoadingComplete() {
    if (loadingFinished) return;
    loadingFinished = true;
    const el = document.getElementById('loadingText');
    if (el) el.textContent = '✓ Hazır! Bağlantı Kuruldu.';
    setTimeout(() => {
        if (window.invokeNative) window.invokeNative('loadingScreenEnd', '');
    }, 1200);
}

// ─── Navigation ───────────────────────────────────────
function initNavigation() {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
            item.classList.add('active');
            const tab = item.dataset.tab;
            if (['staff', 'updates', 'rules'].includes(tab)) openTab(tab);
            else closeTab();
        });
    });
}

function openTab(type) {
    const overlay = document.getElementById('tabOverlay');
    const content = document.getElementById('tabContent');
    if (!overlay || !content) return;
    let html = '';
    if (type === 'staff') {
        html = `<h2 style="font-family:Outfit,sans-serif;font-size:16px;font-weight:700;color:rgba(255,255,255,0.9);margin-bottom:16px;letter-spacing:2px;text-transform:uppercase;">Sunucu Ekibi</h2>
            <div style="display:flex;flex-direction:column;gap:6px;">
                ${CONFIG.staff.map(m => `
                    <div style="display:flex;align-items:center;gap:12px;padding:12px 14px;background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.1);border-radius:8px;">
                        <div class="staff-avatar avatar-${m.roleKey}" style="width:38px;height:38px;font-size:13px;">${m.initial}</div>
                        <div>
                            <div style="font-family:Outfit,sans-serif;font-weight:600;font-size:14px;color:rgba(255,255,255,0.85);">${m.name}</div>
                            <div class="staff-role role-${m.roleKey}" style="font-size:11px;">${m.role}</div>
                        </div>
                        <div style="margin-left:auto;font-size:10px;font-weight:500;color:${m.online ? '#4ade80' : '#555'};letter-spacing:1px;">${m.online ? '● ONLINE' : '● OFFLINE'}</div>
                    </div>`).join('')}
            </div>`;
    } else if (type === 'updates') {
        html = `<h2 style="font-family:Outfit,sans-serif;font-size:16px;font-weight:700;color:rgba(255,255,255,0.9);margin-bottom:16px;letter-spacing:2px;text-transform:uppercase;">Son Güncellemeler</h2>
            <div style="display:flex;flex-direction:column;gap:8px;">
                ${CONFIG.updates.map(u => `
                    <div style="padding:14px;background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.1);border-left:2px solid rgba(232,201,126,0.5);border-radius:8px;">
                        <div style="font-size:10px;color:rgba(255,255,255,0.25);margin-bottom:4px;letter-spacing:0.5px;text-transform:uppercase;">${u.date}</div>
                        <div style="font-family:Outfit,sans-serif;font-size:14px;font-weight:600;color:rgba(255,255,255,0.85);margin-bottom:6px;">${u.title}</div>
                        <div style="font-size:12px;color:rgba(255,255,255,0.45);line-height:1.6;">${u.desc}</div>
                    </div>`).join('')}
            </div>`;
    } else if (type === 'rules') {
        html = `<h2 style="font-family:Outfit,sans-serif;font-size:16px;font-weight:700;color:rgba(255,255,255,0.9);margin-bottom:16px;letter-spacing:2px;text-transform:uppercase;">Sunucu Kuralları</h2>
            <ul class="rules-list">
                ${CONFIG.rules.map(r => `<li><strong>${r.title}</strong>${r.desc}</li>`).join('')}
            </ul>`;
    }
    content.innerHTML = html;
    overlay.style.display = 'flex';
}

function closeTab() {
    const overlay = document.getElementById('tabOverlay');
    if (overlay) overlay.style.display = 'none';
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.querySelector('.nav-item[data-tab="main"]')?.classList.add('active');
}

// ─── Social Links ─────────────────────────────────────
function updateSocialLinks() {
    const d = document.querySelector('.social-btn.discord');
    const y = document.querySelector('.social-btn.youtube');
    const t = document.querySelector('.social-btn.tiktok');

    const discordUrl = (CONFIG.socialLinks && CONFIG.socialLinks.discord) || CONFIG.discordLink;
    const youtubeUrl = (CONFIG.socialLinks && CONFIG.socialLinks.youtube) || CONFIG.youtubeLink;
    const tiktokUrl  = (CONFIG.socialLinks && CONFIG.socialLinks.tiktok)  || CONFIG.tiktokLink;

    if (d) d.onclick = () => window.open(discordUrl, '_blank');
    if (y) y.onclick = () => window.open(youtubeUrl, '_blank');
    if (t) t.onclick = () => window.open(tiktokUrl, '_blank');
}

// ─── Entrance Animation ───────────────────────────────
function animateEntrance() {
    const els = [
        document.querySelector('.welcome-badge'),
        document.querySelector('.welcome-title'),
        document.querySelector('.welcome-subtitle'),
        document.querySelector('.welcome-desc'),
        document.querySelector('.hint-box'),
    ].filter(Boolean);
    els.forEach((el, i) => {
        el.style.opacity   = '0';
        el.style.transform = 'translateY(16px)';
        el.style.transition = `opacity 0.55s ease ${i * 0.1}s, transform 0.55s ease ${i * 0.1}s`;
        setTimeout(() => { el.style.opacity = '1'; el.style.transform = 'translateY(0)'; }, 80 + i * 100);
    });
}

// ─── FiveM NUI Events ─────────────────────────────────
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.eventName) return;
    if (data.eventName === 'loadProgress' && data.loadFraction !== undefined)
        animateProgress(Math.round(data.loadFraction * 100));
    if (data.eventName === 'loadingScreenEnd')
        animateProgress(100);
    if (data.eventName === 'onPlayerList' && data.players) {
        const el = document.getElementById('playerCount');
        if (el) el.textContent = `${data.players} / 128`;
    }
});

window.addEventListener('load', () => {
    if (window.invokeNative) window.invokeNative('loadingScreenCall', JSON.stringify({ ready: true }));
});
