# 🚀 VaterScripts Loading Screen V2 - Düzenleme Rehberi

Tüm düzenlemeler **tek bir dosya** üzerinden yapılır:  
📁 `vater-loadingscreenv2/html/js/app.js`

---

## 1. 👥 Sunucu Ekibi Ekleme / Silme / Düzenleme

`app.js` dosyasını açıp **`staff`** dizinini bul:

```javascript
staff: [
    { name: "Erkan",   role: "Kurucu",    roleKey: "owner",     initial: "E",  online: true  },
    { name: "Ghost",   role: "Admin",     roleKey: "admin",     initial: "G",  online: true  },
    { name: "Shadow",  role: "Moderatör", roleKey: "moderator", initial: "S",  online: true  },
],
```

### ➕ Yeni Üye Ekleme:
Dizinin en altına virgül koyup yeni satır ekle:
```javascript
{ name: "Ahmet", role: "Destek", roleKey: "support", initial: "A", online: true },
```

### ❌ Üye Silme:
Silmek istediğin kişinin satırını komple silmen yeterlidir.

### 🎨 Rol Renkleri (`roleKey`):
- `"owner"` → Kurucu (**Altın / Sarı**)
- `"admin"` → Admin (**Mavi**)
- `"moderator"` → Moderatör (**Mor**)
- `"developer"` → Yazılımcı (**Yeşil**)
- `"support"` → Destek (**Turuncu**)

---

## 2. 🎵 Şarkı Değiştirme

1. Yeni şarkı `.mp3` dosyanı `vater-loadingscreenv2/html/img/` klasörüne at (Örn: `yeni_sarki.mp3`).
2. `app.js` içerisindeki **`music`** bölümünü güncelle:

```javascript
music: [
    {
        title:  "Çalan Şarkı Adı",    // Ekranın altında görünecek isim
        artist: "Sanatçı veya Bilgi", // Altındaki küçük açıklama
        file:   "img/yeni_sarki.mp3", // Yüklediğin mp3 dosyasının adı
    },
],
```

---

## 3. 🖼️ Arka Plan Videosu / Görseli Değiştirme

1. Yeni arka plan video (`.mp4`) veya resim (`.png`) dosyanı `vater-loadingscreenv2/html/img/` klasörüne at.
2. `app.js` içerisindeki **`background`** bölümünü güncelle:

```javascript
// Video Kullanmak İçin:
background: {
    type:   "video",
    source: "img/yeni_video.mp4",
},

// Görsel (Resim) Kullanmak İçin:
background: {
    type:   "image",
    source: "img/yeni_resim.png",
},
```

---

## 🔗 4. Sosyal Medya Linklerini Değiştirme

`app.js` içerisindeki **`socialLinks`** bölümüne kendi adreslerini yaz:

```javascript
socialLinks: {
    discord: "https://discord.gg/vaterscripts",
    youtube: "https://youtube.com/@vaterscripts",
    tiktok:  "https://tiktok.com/@vaterscripts",
},
```
