/* =========================================================
   VATER LEATHER CO. - WALLET NUI JAVASCRIPT LOGIC
   ========================================================= */

let walletData = null;
let activeCardType = null;
let isFlipped = false;
let audioCtx = null;

// Kırılmayan Karakter Vesikalık SVG Data URL (2. Görseldeki Şık Portre İllüstrasyonu)
const SVG_CHARACTER_PORTRAIT = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 125' width='100' height='125'><rect width='100' height='125' fill='%230f172a'/><circle cx='50' cy='42' r='22' fill='%2364748b'/><circle cx='50' cy='38' r='14' fill='%23cbd5e1'/><path d='M 20 110 C 20 78, 80 78, 80 110 Z' fill='%2394a3b8'/><rect x='0' y='0' width='100' height='125' fill='none' stroke='%2338bdf8' stroke-width='2'/></svg>";

// Güvenli Metin Atayıcı (Null Error Fix)
function setElementText(id, text) {
    const el = document.getElementById(id);
    if (el) {
        el.innerText = text;
    }
}

// Güvenli Resim Hata Yakalayıcısı
function handleAvatarError(el) {
    if (el) {
        el.onerror = null;
        el.src = SVG_CHARACTER_PORTRAIT;
    }
}

// Audio Context (Dış Asset Olmadan Gerçekçi Ses Üretimi)
function initAudio() {
    if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
}

function playCardSound() {
    try {
        initAudio();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(400, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(150, audioCtx.currentTime + 0.12);
        gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.12);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.12);
    } catch(e) {}
}

function playFlipSound() {
    try {
        initAudio();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(200, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600, audioCtx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.1);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.1);
    } catch(e) {}
}

// NUI Mesaj Dinleyicisi
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openWallet') {
        walletData = data.data;
        renderWallet(walletData);
        const walletApp = document.getElementById('wallet-app');
        if (walletApp) walletApp.classList.remove('hidden');
        playCardSound();
    } else if (data.action === 'closeWallet') {
        closeAllUI();
    } else if (data.action === 'showTargetCard') {
        openTargetCardView(data.cardData, data.ownerName);
    }
});

// Cüzdan Verilerini Arayüze Yansıtma
function renderWallet(data) {
    if (!data) return;

    // Nakit ve Banka Tutarları
    setElementText('cash-amount', '$' + (data.cash || 0).toLocaleString());
    setElementText('bank-amount', '$' + (data.bank || 0).toLocaleString());

    // Karakter Bilgileri (2. Görseldeki San Andreas Kimlik Kartı)
    const info = data.charinfo || {};
    const fullName = (info.firstname || 'Vater') + ' ' + (info.lastname || 'Scripts');
    const citizenid = info.citizenid || 'CGQ39290';
    const dob = info.birthdate || '1999-11-11';
    const gender = info.gender || 'Erkek';

    setElementText('player-fullname', fullName);
    setElementText('player-citizenid', citizenid);
    setElementText('player-dob', dob);
    setElementText('player-gender', gender);
    setElementText('id-card-serial', 'ID-' + citizenid + '-2026');

    // Profil Fotoğrafı / Vesikalık
    const avatarEl = document.getElementById('player-avatar');
    if (avatarEl) {
        if (data && data.avatar && data.avatar !== '' && !data.avatar.includes('imgbb.com') && !data.avatar.includes('image not found')) {
            avatarEl.src = data.avatar;
        } else {
            avatarEl.src = SVG_CHARACTER_PORTRAIT;
        }
    }

    // Kart Önizleme İsimleri & Rozet Durumları
    setElementText('preview-id-name', fullName);
    
    // Banka kartı son 4 hane
    const acc = data.bankAccount || '45328819';
    const last4 = acc.substring(acc.length - 4);
    setElementText('preview-bank-acc', '**** ' + last4);

    // Lisans Badgeleri (Var / Yok)
    const l = data.licenses || {};
    updateBadge('badge-driver', l.driver, 'LİSANSLI', 'YOK');
    updateBadge('badge-weapon', l.weapon, 'GEÇERLİ', 'YOK');
    updateBadge('badge-lawyer', l.lawyer, 'AKTİF', 'YOK');
    updateBadge('badge-vip', l.vip, 'GOLD', 'STANDART');
}

function updateBadge(elementId, hasLicense, activeText, inactiveText) {
    const el = document.getElementById(elementId);
    if (!el) return;
    if (hasLicense) {
        el.innerText = activeText;
        el.style.color = '#4ade80';
    } else {
        el.innerText = inactiveText;
        el.style.color = '#ef4444';
    }
}

// Kart Slotlarına Tıklama Dinleyicisi
document.querySelectorAll('.card-slot-item').forEach(slot => {
    slot.addEventListener('click', function() {
        const cardType = this.getAttribute('data-card');
        openCardModal(cardType);
    });
});

// 3D Kart Modalı Açma
function openCardModal(cardType) {
    activeCardType = cardType;
    isFlipped = false;
    
    const activeCard3D = document.getElementById('active-card-3d');
    if (activeCard3D) activeCard3D.classList.remove('flipped');
    
    renderCardContent(cardType, walletData);

    const modal = document.getElementById('card-modal');
    if (modal) modal.classList.remove('hidden');
    playCardSound();
}

// Başkasının Gösterdiği Kartı Açma Modal (Hedef Modu)
function openTargetCardView(cardData, ownerName) {
    activeCardType = cardData.cardType;
    isFlipped = false;
    
    const activeCard3D = document.getElementById('active-card-3d');
    if (activeCard3D) activeCard3D.classList.remove('flipped');

    const walletApp = document.getElementById('wallet-app');
    if (walletApp) walletApp.classList.remove('hidden');

    const walletWrapper = document.querySelector('.wallet-wrapper');
    if (walletWrapper) walletWrapper.style.display = 'none';

    renderCardContent(cardData.cardType, cardData.data, ownerName);

    const btnShowNearby = document.getElementById('btn-show-nearby');
    if (btnShowNearby) btnShowNearby.style.display = 'none';

    const cardModal = document.getElementById('card-modal');
    if (cardModal) cardModal.classList.remove('hidden');
    playCardSound();
}

// Kart Ön ve Arka Yüzünü Dinamik Oluşturma
function renderCardContent(cardType, data, customOwner) {
    const frontEl = document.getElementById('modal-card-front');
    const backEl = document.getElementById('modal-card-back');
    const titleEl = document.getElementById('modal-card-title');

    if (!frontEl || !backEl || !titleEl) return;

    const info = (data && data.charinfo) || {};
    const fullName = customOwner || ((info.firstname || 'Vater') + ' ' + (info.lastname || 'Scripts'));
    let avatar = (data && data.avatar) || SVG_CHARACTER_PORTRAIT;
    if (!avatar || avatar === '' || avatar.includes('imgbb.com') || avatar.includes('image not found')) {
        avatar = SVG_CHARACTER_PORTRAIT;
    }

    const citizenid = info.citizenid || 'CGQ39290';
    const dob = info.birthdate || '1999-11-11';
    const gender = info.gender || 'Erkek';

    // Kart Sınıflarını Sıfırla
    frontEl.className = 'card-face card-front-face ' + getCardBgClass(cardType);
    backEl.className = 'card-face card-back-face';

    if (cardType === 'id_card') {
        titleEl.innerText = 'SAN ANDREAS EYALET KİMLİĞİ';
        frontEl.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid rgba(255,255,255,0.4); padding-bottom:8px;">
                <div style="font-family:'Cinzel'; font-weight:800; font-size:14px; letter-spacing:1px;">SAN ANDREAS STATE ID</div>
                <div style="font-size:10px; font-weight:700; background:rgba(0,0,0,0.3); padding:2px 8px; border-radius:4px;">USA</div>
            </div>
            <div style="display:flex; gap:16px; align-items:center; margin-top:12px;">
                <img src="${avatar}" onerror="handleAvatarError(this)" style="width:90px; height:110px; object-fit:cover; border-radius:8px; border:2px solid #fff; box-shadow:0 4px 10px rgba(0,0,0,0.5);">
                <div style="display:flex; flex-direction:column; gap:4px; font-size:12px;">
                    <div><span style="opacity:0.7; font-size:9px;">İSİM SOYİSİM:</span> <br><strong>${fullName}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">KİMLİK NO:</span> <br><strong style="color:#fde047;">${citizenid}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">DOĞUM TARİHİ:</span> <br><strong>${dob}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">CİNSİYET:</span> <br><strong>${gender}</strong></div>
                </div>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:auto; font-size:9px; opacity:0.8;">
                <span>VERİLİŞ: STATE OF SA</span>
                <span style="font-family:'OCR A Extended';">ID-${citizenid}-2026</span>
            </div>
        `;

        backEl.innerHTML = `
            <div style="height:40px; background:#000; margin:-20px -20px 15px -20px;"></div>
            <div style="padding:10px; background:rgba(255,255,255,0.1); border-radius:6px; font-size:10px;">
                Bu kart San Andreas Eyalet Hükümeti tarafından resmi kimlik belgesi olarak düzenlenmiştir.
            </div>
            <div style="margin-top:auto; text-align:center;">
                <div style="font-family:'OCR A Extended'; font-size:18px; letter-spacing:4px; opacity:0.8;">|||||| ||| ||||||| ||||</div>
                <div style="font-size:9px; opacity:0.6; margin-top:4px;">OFFICIAL STATE IDENTIFICATION CARD</div>
            </div>
        `;
    } else if (cardType === 'driver_license') {
        const hasDriver = data && data.licenses && data.licenses.driver;
        titleEl.innerText = 'SAN ANDREAS SÜRÜCÜ LİSANSI';
        frontEl.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid rgba(255,255,255,0.4); padding-bottom:8px;">
                <div style="font-family:'Cinzel'; font-weight:800; font-size:14px;">SAN ANDREAS DMV</div>
                <div style="font-size:10px; font-weight:700; background:${hasDriver ? '#16a34a' : '#dc2626'}; padding:2px 8px; border-radius:4px; color:#fff;">
                    ${hasDriver ? 'CLASS C DRIVER' : 'LİSANS YOK'}
                </div>
            </div>
            <div style="display:flex; gap:16px; align-items:center; margin-top:12px;">
                <img src="${avatar}" onerror="handleAvatarError(this)" style="width:90px; height:110px; object-fit:cover; border-radius:8px; border:2px solid #fff;">
                <div style="display:flex; flex-direction:column; gap:4px; font-size:12px;">
                    <div><span style="opacity:0.7; font-size:9px;">SÜRÜCÜ:</span> <br><strong>${fullName}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">LİSANS NO:</span> <br><strong style="color:#fde047;">DL-${citizenid}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">DURUM:</span> <br><strong>${hasDriver ? 'GEÇERLİ SÜRÜCÜ' : 'ASKIYA ALINDI / YOK'}</strong></div>
                </div>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:auto; font-size:9px; opacity:0.8;">
                <span>DEPARTMENT OF MOTOR VEHICLES</span>
                <span>EXP: 12/2030</span>
            </div>
        `;

        backEl.innerHTML = `
            <div style="height:40px; background:#000; margin:-20px -20px 15px -20px;"></div>
            <div style="padding:10px; font-size:10px; line-height:1.4;">
                <strong>KISITLAMALAR:</strong> YOK (NONE)<br>
                <strong>ORGAN DONÖRÜ:</strong> EVET<br>
                Trafik kurallarına uyulmaması durumunda lisans iptal edilebilir.
            </div>
            <div style="margin-top:auto; text-align:center;">
                <div style="font-family:'OCR A Extended'; font-size:18px; letter-spacing:4px;">|||| |||||| ||| ||||</div>
            </div>
        `;
    } else if (cardType === 'bank_card') {
        const bankAcc = (data && data.bankAccount) || '4532 8819 9012 3456';
        titleEl.innerText = 'FLEET BANK VISA PLATINUM';
        frontEl.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center;">
                <div style="font-family:'Orbitron'; font-weight:800; font-size:16px; color:#fbbf24; letter-spacing:1px;">FLEET BANK</div>
                <div style="font-size:12px; font-weight:700; color:#cbd5e1;">VISA PLATINUM</div>
            </div>
            <div style="margin-top:15px; display:flex; align-items:center; gap:10px;">
                <div style="width:42px; height:32px; background:linear-gradient(135deg, #ffd700 0%, #b8860b 100%); border-radius:6px; box-shadow:inset 0 0 4px rgba(0,0,0,0.5);"></div>
                <i class="fa-solid fa-wifi" style="transform:rotate(90deg); color:rgba(255,255,255,0.7); font-size:16px;"></i>
            </div>
            <div style="font-family:'OCR A Extended'; font-size:20px; letter-spacing:3px; color:#ffffff; text-shadow:0 2px 4px rgba(0,0,0,0.8); margin-top:12px;">
                4532 ${bankAcc.substring(0,4)} ${bankAcc.substring(4,8)} 8819
            </div>
            <div style="display:flex; justify-content:space-between; align-items:flex-end; margin-top:auto;">
                <div>
                    <div style="font-size:8px; opacity:0.7;">KART SAHİBİ</div>
                    <div style="font-size:13px; font-weight:700; text-transform:uppercase;">${fullName}</div>
                </div>
                <div style="text-align:right;">
                    <div style="font-size:8px; opacity:0.7;">SON KULLANMA</div>
                    <div style="font-size:12px; font-weight:700;">12/29</div>
                </div>
            </div>
        `;

        backEl.innerHTML = `
            <div style="height:44px; background:#0f172a; margin:-20px -20px 15px -20px; border-bottom:2px solid #000;"></div>
            <div style="display:flex; align-items:center; background:#fff; color:#000; height:34px; padding:0 12px; font-family:'OCR A Extended'; font-weight:bold; justify-content:space-between;">
                <span style="font-style:italic; font-family:serif; font-size:14px;">${fullName}</span>
                <span style="background:#f1f5f9; padding:2px 6px; border:1px solid #94a3b8; color:#000;">492</span>
            </div>
            <div style="font-size:9px; opacity:0.7; margin-top:12px; line-height:1.3;">
                Bu kart Fleet Bank A.Ş. mülkiyetindedir. Bulunduğunda lütfen en yakın şubeye teslim ediniz. Müşteri Hizmetleri: 555-FLEET
            </div>
        `;
    } else if (cardType === 'weapon_license') {
        const hasWeapon = data && data.licenses && data.licenses.weapon;
        titleEl.innerText = 'ATEŞLİ SİLAH TAŞIMA RUHSATI';
        frontEl.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid #ef4444; padding-bottom:8px;">
                <div style="font-family:'Cinzel'; font-weight:800; font-size:13px; color:#fca5a5;">CONCEALED WEAPON PERMIT</div>
                <i class="fa-solid fa-shield-halved" style="color:#ef4444; font-size:18px;"></i>
            </div>
            <div style="display:flex; gap:16px; align-items:center; margin-top:12px;">
                <img src="${avatar}" onerror="handleAvatarError(this)" style="width:90px; height:110px; object-fit:cover; border-radius:8px; border:2px solid #ef4444;">
                <div style="display:flex; flex-direction:column; gap:4px; font-size:12px;">
                    <div><span style="opacity:0.7; font-size:9px;">RUHSAT SAHİBİ:</span> <br><strong>${fullName}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">RUHSAT NO:</span> <br><strong style="color:#ef4444;">CCW-${citizenid}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">SİLAH SINIFI:</span> <br><strong>TABANCA / PISTOL</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">DURUM:</span> <br><strong style="color:${hasWeapon ? '#4ade80' : '#ef4444'};">${hasWeapon ? 'GEÇERLİ TAŞIMA İZNİ' : 'RUHSATSIZ / İPTAL'}</strong></div>
                </div>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:auto; font-size:9px; opacity:0.8;">
                <span>LOS SANTOS POLICE DEPT.</span>
                <span>AUTHORIZED</span>
            </div>
        `;

        backEl.innerHTML = `
            <div style="height:40px; background:#18181b; margin:-20px -20px 15px -20px; border-bottom:2px solid #ef4444;"></div>
            <div style="padding:10px; font-size:10px; line-height:1.4; color:#cbd5e1;">
                <strong>YASAL UYARI:</strong> Bu ruhsat sadece onaylanmış kişisel savunma tabancaları için geçerlidir. Ağır veya otomatik silahları kapsamaz.
            </div>
            <div style="margin-top:auto; text-align:center;">
                <div style="font-family:'OCR A Extended'; font-size:16px; letter-spacing:4px; color:#ef4444;">* CCW APPROVED *</div>
            </div>
        `;
    } else if (cardType === 'lawyer_license') {
        const hasLawyer = data && data.licenses && data.licenses.lawyer;
        titleEl.innerText = 'BAROLAR BİRLİĞİ AVUKAT KARTI';
        frontEl.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid #f472b6; padding-bottom:8px;">
                <div style="font-family:'Cinzel'; font-weight:800; font-size:13px; color:#f472b6;">STATE BAR ASSOCIATION</div>
                <i class="fa-solid fa-scale-balanced" style="color:#f472b6; font-size:18px;"></i>
            </div>
            <div style="display:flex; gap:16px; align-items:center; margin-top:12px;">
                <img src="${avatar}" onerror="handleAvatarError(this)" style="width:90px; height:110px; object-fit:cover; border-radius:8px; border:2px solid #f472b6;">
                <div style="display:flex; flex-direction:column; gap:4px; font-size:12px;">
                    <div><span style="opacity:0.7; font-size:9px;">AVUKAT:</span> <br><strong>${fullName}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">BARO SİCİL NO:</span> <br><strong style="color:#f472b6;">BAR-${citizenid}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">DURUM:</span> <br><strong style="color:${hasLawyer ? '#4ade80' : '#ef4444'};">${hasLawyer ? 'RABBİNİZ VE AVUKATINIZ' : 'AKTİF BARO KAYDI YOK'}</strong></div>
                </div>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:auto; font-size:9px; opacity:0.8;">
                <span>ATTORNEY AT LAW</span>
                <span>STATE LICENSED</span>
            </div>
        `;

        backEl.innerHTML = `
            <div style="height:40px; background:#4c1d95; margin:-20px -20px 15px -20px;"></div>
            <div style="padding:10px; font-size:10px; line-height:1.4;">
                Kart sahibi San Andreas Mahkemelerinde ve Karakollarında müvekkillerini savunma tam yetkisine sahiptir.
            </div>
            <div style="margin-top:auto; text-align:center;">
                <div style="font-family:'Cinzel'; font-size:14px; font-weight:bold; color:#f472b6;">OFFICIAL LEGAL COUNSEL</div>
            </div>
        `;
    } else if (cardType === 'vip_card') {
        const hasVip = data && data.licenses && data.licenses.vip;
        titleEl.innerText = 'THE DIAMOND CASINO VIP MEMBER';
        frontEl.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid #ffd700; padding-bottom:8px;">
                <div style="font-family:'Cinzel'; font-weight:800; font-size:13px; color:#ffd700;">THE DIAMOND CASINO & RESORT</div>
                <i class="fa-solid fa-gem" style="color:#ffd700; font-size:18px;"></i>
            </div>
            <div style="display:flex; gap:16px; align-items:center; margin-top:12px;">
                <img src="${avatar}" onerror="handleAvatarError(this)" style="width:90px; height:110px; object-fit:cover; border-radius:8px; border:2px solid #ffd700;">
                <div style="display:flex; flex-direction:column; gap:4px; font-size:12px;">
                    <div><span style="opacity:0.7; font-size:9px;">VIP ÜYE:</span> <br><strong style="color:#fff;">${fullName}</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">ÜYELİK SEVİYESİ:</span> <br><strong style="color:#ffd700;">DIAMOND GOLD VIP</strong></div>
                    <div><span style="opacity:0.7; font-size:9px;">ÜYE NO:</span> <br><strong>VIP-${citizenid}</strong></div>
                </div>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:auto; font-size:9px; color:#ffd700;">
                <span>HIGH ROLLER LOUNGE</span>
                <span>EXCLUSIVE ACCESS</span>
            </div>
        `;

        backEl.innerHTML = `
            <div style="height:40px; background:#000; margin:-20px -20px 15px -20px; border-bottom:1px solid #ffd700;"></div>
            <div style="padding:10px; font-size:10px; line-height:1.4; color:#ffd700;">
                Bu kart sahibine VIP Penthouse, Helipad ve Yüksek Limitli Casino Masalarına öncelikli erişim hakkı tanır.
            </div>
            <div style="margin-top:auto; text-align:center;">
                <div style="font-family:'Cinzel'; font-size:14px; letter-spacing:2px; color:#ffd700;">VALET & CONCIERGE INCLUDED</div>
            </div>
        `;
    }
}

function getCardBgClass(cardType) {
    switch (cardType) {
        case 'id_card': return 'card-id';
        case 'driver_license': return 'card-driver';
        case 'bank_card': return 'card-bank';
        case 'weapon_license': return 'card-weapon';
        case 'lawyer_license': return 'card-lawyer';
        case 'vip_card': return 'card-vip';
        default: return 'card-id';
    }
}

// Kartı Çevirme Butonu (3D Flip)
const btnFlip = document.getElementById('btn-flip-card');
if (btnFlip) {
    btnFlip.addEventListener('click', function() {
        isFlipped = !isFlipped;
        const cardEl = document.getElementById('active-card-3d');
        if (cardEl) {
            if (isFlipped) {
                cardEl.classList.add('flipped');
            } else {
                cardEl.classList.remove('flipped');
            }
        }
        playFlipSound();
    });
}

// Kart Çevirme (Karta Tıklayınca da Çevrilsin)
const activeCard3DEl = document.getElementById('active-card-3d');
if (activeCard3DEl) {
    activeCard3DEl.addEventListener('click', function() {
        isFlipped = !isFlipped;
        if (isFlipped) {
            this.classList.add('flipped');
        } else {
            this.classList.remove('flipped');
        }
        playFlipSound();
    });
}

// Yakındakine Göster Butonu
const btnShow = document.getElementById('btn-show-nearby');
if (btnShow) {
    btnShow.addEventListener('click', function() {
        if (!activeCardType || !walletData) return;

        fetch(`https://${GetParentResourceName()}/showCardToNearby`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                cardType: activeCardType,
                data: walletData
            })
        }).then(res => res.json()).then(data => {
            closeModalOnly();
        });
    });
}

// Modal Kapatma
const modalCloseBtn = document.getElementById('modal-close-btn');
if (modalCloseBtn) modalCloseBtn.addEventListener('click', closeModalOnly);

const modalBackdrop = document.getElementById('modal-backdrop');
if (modalBackdrop) modalBackdrop.addEventListener('click', closeModalOnly);

function closeModalOnly() {
    const cardModal = document.getElementById('card-modal');
    if (cardModal) cardModal.classList.add('hidden');
    const walletWrapper = document.querySelector('.wallet-wrapper');
    if (walletWrapper && walletWrapper.style.display === 'none') {
        closeAllUI();
    }
}

// Cüzdan Kapatma Butonları
const closeWalletBtn = document.getElementById('close-wallet-btn');
if (closeWalletBtn) closeWalletBtn.addEventListener('click', closeWalletAction);

const walletBackdrop = document.getElementById('wallet-backdrop');
if (walletBackdrop) walletBackdrop.addEventListener('click', closeWalletAction);

function closeWalletAction() {
    fetch(`https://${GetParentResourceName()}/closeWallet`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(() => {
        closeAllUI();
    });
}

function closeAllUI() {
    const walletApp = document.getElementById('wallet-app');
    if (walletApp) walletApp.classList.add('hidden');

    const cardModal = document.getElementById('card-modal');
    if (cardModal) cardModal.classList.add('hidden');

    const walletWrapper = document.querySelector('.wallet-wrapper');
    if (walletWrapper) walletWrapper.style.display = 'flex';

    const btnShowNearby = document.getElementById('btn-show-nearby');
    if (btnShowNearby) btnShowNearby.style.display = 'flex';
}

// Klavyeden ESC Tuşu Basıldığında Kapatma
window.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' || e.code === 'Escape') {
        const modal = document.getElementById('card-modal');
        if (modal && !modal.classList.contains('hidden')) {
            closeModalOnly();
        } else {
            closeWalletAction();
        }
    }
});
