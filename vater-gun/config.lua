Config = Config or {}

-- Modifiye Komutu ve Genel Ayarlar
Config.Command = "silahmod"
Config.UseBenchMarker = true

-- Modifiye Masaları / İletişim Noktaları
Config.BenchLocations = {
    { coords = vec3(18.57, -1107.53, 29.8), radius = 2.0, label = "Silah Modifiye Masası (Ammunation Center)" },
    { coords = vec3(810.25, -2157.6, 29.62), radius = 2.0, label = "Silah Modifiye Masası (Docks)" },
    { coords = vec3(1693.44, 3759.5, 34.7), radius = 2.0, label = "Silah Modifiye Masası (Sandy Shores)" },
    { coords = vec3(-324.26, 6045.38, 31.48), radius = 2.0, label = "Silah Modifiye Masası (Paleto Bay)" },
}

-- İşlem Ücretleri
Config.Prices = {
    attachment = 500,    -- Eklenti takma ücreti ($)
    tint = 250,          -- Renk/Kaplama değiştirme ücreti ($)
    customSkin = 1500    -- Özel desen tasarlama/uygulama ücreti ($)
}

-- GTA V Resmi Silah Renk & Kamuflaj Tonları (0-7 Engine Tints)
Config.Tints = {
    { id = 0, label = "Varsayılan (Fabrika Siyahı)", hex = "#2b2b2b", desc = "Standart Fabrika Üretimi Siyah" },
    { id = 1, label = "Taktik Askeri Yeşil", hex = "#4b5320", desc = "Kamuflaj Ordu Mat Yeşil" },
    { id = 2, label = "24K Lüks Altın Kaplama", hex = "#d4af37", desc = "Parlak 24 Ayar Altın Metal" },
    { id = 3, label = "Siber Pembe Metalik", hex = "#ff69b4", desc = "Neon Siber Metalik Pembe" },
    { id = 4, label = "Ordu Taktik Kamuflaj", hex = "#556b2f", desc = "Ordu Taktik Çöl/Orman Mat" },
    { id = 5, label = "LSPD Derin Mavi", hex = "#1e90ff", desc = "Polis Özel Harekat Mavi" },
    { id = 6, label = "Taktik Turuncu", hex = "#f97316", desc = "Taktik Sinyal Turuncusu" },
    { id = 7, label = "Platin Gümüş Parlak", hex = "#e5e4e2", desc = "Cilalı Platin Gümüş Metal" }
}

-- Özel silah görünümleri
--
-- ÖNEMLİ:
-- Vanilla silahla aynı isimdeki bir .ydr/.ytd dosyasını (ör. w_ar_assaultrifle.ytd)
-- stream klasörüne koymayın. FiveM bu dosyayı resource başlarken global olarak yükler
-- ve silah, skin seçilmeden önce de değişmiş görünür.
--
-- Desteklenen modlar:
--   runtime   : NUI'deki PNG/JPG/GIF görselini seçildiğinde silah dokusuna uygular.
--   texture   : Benzersiz isimli streamed YTD içindeki dokuyu seçildiğinde uygular.
--   component : Ayrı bir weapon component/VARMOD takar. Tam model için önerilen moddur.
--
-- "texture" örneği:
-- {
--     id = "diamondak_stream", label = "Diamond AK Stream", weapon = "weapon_assaultrifle",
--     mode = "texture", sourceTxd = "w_ar_assaultrifle",
--     sourceTxn = "W_AR_AssaultRifle_Diff", targetTxd = "diamondak",
--     targetTxn = "diamondak_diff", preview = "assets/camos/diamondak.png"
-- }
--
-- "component" örneği (component ve meta dosyaları asset paketinizle aynı olmalı):
-- {
--     id = "diamondak_model", label = "Diamond AK Full Model",
--     weapon = "weapon_assaultrifle", mode = "component",
--     component = "COMPONENT_ASSAULTRIFLE_VARMOD_DIAMONDAK",
--     preview = "assets/camos/diamondak.png"
-- }
--
-- Gerçek parayla satılan / Kilitli (Locked) kaplama örneği:
-- {
--     id = "dragonak", label = "Dragon AK-47 [VIP / DONATE]",
--     description = "Varsayılan kilitli VIP kaplaması. Sadece satın alanlar kuşanabilir.",
--     weapon = "weapon_assaultrifle", mode = "texture",
--     sourceTxd = "w_ar_assaultrifle", sourceTxn = "W_AR_AssaultRifle_Diff",
--     targetTxd = "diamondak", targetTxn = "W_AR_AssaultRifle_Diff",
--     isLocked = true,               -- Varsayılan olarak kilitli (Gerçek parayla satılan skin)
--     permission = "vip",            -- Opsiyonel: QBCore yetkisi olanların kilidi otomatik açılır
--     requiredItem = "vip_skin_pass" -- Opsiyonel: Envanterinde bu eşya olanların kilidi otomatik açılır
-- }
Config.CustomSkins = {
    {
        id = "diamondak",
        label = "Diamond AK [VIP / DONATE]",
        description = "Gerçek parayla satılan varsayılan kilitli Elmas kaplama deseni.",
        weapon = "weapon_assaultrifle",
        mode = "texture",
        sourceTxd = "w_ar_assaultrifle",
        sourceTxn = "W_AR_AssaultRifle_Diff",
        targetTxd = "diamondak",
        targetTxn = "W_AR_AssaultRifle_Diff",
        preview = "assets/camos/diamondak.png",
        isLocked = true
    },
    {
        id = "galaxyak",
        label = "Galaksi AK-47",
        description = "Özel Galaksi desenli streamed silah kaplaması.",
        weapon = "weapon_assaultrifle",
        mode = "texture",
        sourceTxd = "w_ar_assaultrifle",
        sourceTxn = "W_AR_AssaultRifle_Diff",
        targetTxd = "galaxyak",
        targetTxn = "W_AR_AssaultRifle_Diff",
        preview = "assets/camos/galaxyak.png",
        isLocked = false
    },
    {
        id = "mormaviak",
        label = "Mor Mavi AK-47 [DONATE]",
        description = "Özel Mor Mavi desenli VIP kilitli kaplama.",
        weapon = "weapon_assaultrifle",
        mode = "texture",
        sourceTxd = "w_ar_assaultrifle",
        sourceTxn = "W_AR_AssaultRifle_Diff",
        targetTxd = "mormaviak",
        targetTxn = "W_AR_AssaultRifle_Diff",
        preview = "assets/camos/mormaviak.png",
        isLocked = true
    },
    {
        id = "zebraak",
        label = "Zebra AK-47",
        description = "Özel Zebra desenli streamed silah kaplaması.",
        weapon = "weapon_assaultrifle",
        mode = "texture",
        sourceTxd = "w_ar_assaultrifle",
        sourceTxn = "W_AR_AssaultRifle_Diff",
        targetTxd = "zebraak",
        targetTxn = "W_AR_AssaultRifle_Diff",
        preview = "assets/camos/zebraak.png",
        isLocked = false
    },
    {
        id = "custompistol",
        label = "Özel Taktik Pistol",
        description = "Pistol için özel kaplamalı desen.",
        weapon = "weapon_pistol",
        mode = "texture",
        sourceTxd = "w_pi_pistol",
        sourceTxn = "W_PI_Pistol_Diff",
        targetTxd = "custompistol",
        targetTxn = "W_PI_Pistol_Diff",
        isLocked = false
    },
    {
        id = "galaxym4",
        label = "Galaksi M4A1 [VIP / DONATE]",
        description = "M4A1 (Carbine Rifle) için kilitli Galaksi desenli özel kaplama.",
        weapon = "weapon_carbinerifle",
        mode = "texture",
        sourceTxd = "w_ar_carbinerifle",
        sourceTxn = "W_AR_CarbineRifle_Diff",
        targetTxd = "galaxym4",
        targetTxn = "W_AR_CarbineRifle_Diff",
        preview = "assets/camos/galaxyak.png",
        isLocked = true
    }
}

-- Eski entegrasyonlar için geriye dönük isim.
Config.SkinPatterns = Config.CustomSkins

-- Silah Kategorilerine Göre Otomatik Kamera Ölçeği & İdeal Yükseklik Hizalama Haritası
Config.CategorySettings = {
    Pistol = {
        distance = 0.65,
        fov = 34.0,
        nodes = {
            suppressor = { left = '18%', top = '38%', targetX = 35, targetY = 48 },
            scope      = { left = '40%', top = '22%', targetX = 48, targetY = 40 },
            flashlight = { left = '26%', top = '64%', targetX = 42, targetY = 52 },
            clip       = { left = '52%', top = '66%', targetX = 52, targetY = 56 },
            finish     = { left = '70%', top = '34%', targetX = 60, targetY = 44 }
        }
    },
    SMG = {
        distance = 0.85,
        fov = 38.0,
        nodes = {
            suppressor = { left = '12%', top = '38%', targetX = 26, targetY = 46 },
            scope      = { left = '42%', top = '20%', targetX = 48, targetY = 38 },
            flashlight = { left = '24%', top = '62%', targetX = 36, targetY = 50 },
            grip       = { left = '36%', top = '70%', targetX = 44, targetY = 52 },
            clip       = { left = '55%', top = '68%', targetX = 54, targetY = 56 },
            finish     = { left = '72%', top = '32%', targetX = 64, targetY = 44 }
        }
    },
    Rifle = {
        distance = 1.15,
        fov = 40.0,
        nodes = {
            suppressor = { left = '10%', top = '38%', targetX = 18, targetY = 46 },
            scope      = { left = '46%', top = '18%', targetX = 52, targetY = 38 },
            flashlight = { left = '24%', top = '62%', targetX = 32, targetY = 50 },
            grip       = { left = '38%', top = '70%', targetX = 42, targetY = 53 },
            clip       = { left = '58%', top = '68%', targetX = 58, targetY = 58 },
            finish     = { left = '78%', top = '32%', targetX = 76, targetY = 42 }
        }
    },
    Sniper = {
        distance = 1.40,
        fov = 44.0,
        nodes = {
            suppressor = { left = '8%',  top = '38%', targetX = 14, targetY = 46 },
            scope      = { left = '46%', top = '16%', targetX = 50, targetY = 36 },
            flashlight = { left = '24%', top = '62%', targetX = 30, targetY = 50 },
            grip       = { left = '36%', top = '70%', targetX = 40, targetY = 52 },
            clip       = { left = '58%', top = '68%', targetX = 56, targetY = 56 },
            finish     = { left = '80%', top = '34%', targetX = 80, targetY = 42 }
        }
    },
    Shotgun = {
        distance = 1.10,
        fov = 40.0,
        nodes = {
            suppressor = { left = '10%', top = '38%', targetX = 20, targetY = 46 },
            flashlight = { left = '26%', top = '62%', targetX = 34, targetY = 50 },
            finish     = { left = '74%', top = '34%', targetX = 72, targetY = 44 }
        }
    }
}

-- COD Gunsmith Bağlantı Noktaları Varsayılan İsim ve İkonlar
Config.AttachmentNodes = {
    suppressor = { title = "NAMLU ÇIKIŞI", icon = "fa-bullseye" },
    scope      = { title = "NİŞANGAH / DÜRBÜN", icon = "fa-crosshair" },
    flashlight = { title = "TAKTİK FENER / LAZER", icon = "fa-lightbulb" },
    clip       = { title = "ŞARJÖR", icon = "fa-box-archive" },
    grip       = { title = "ÖN TUTAMAK", icon = "fa-hand-back-fist" },
    finish     = { title = "KAPLAMA BİLEŞENİ", icon = "fa-paintbrush" }
}

-- Desteklenen Tüm Silahlar ve Eklenti Tanımları
Config.Weapons = {
    ['weapon_pistol'] = {
        label = "Pistol 9mm",
        category = "Pistol",
        baseStats = { damage = 42, range = 35, accuracy = 60, control = 65, firerate = 50, mobility = 85 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_PI_SUPP_02`, componentName = "COMPONENT_AT_PI_SUPP_02", label = "Taktik Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15, control = 10, mobility = -5 } },
            flashlight = { component = `COMPONENT_AT_PI_FLSH`, componentName = "COMPONENT_AT_PI_FLSH", label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            clip = { component = `COMPONENT_PISTOL_CLIP_02`, componentName = "COMPONENT_PISTOL_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -5, mobility = -5 } },
            finish = { component = `COMPONENT_PISTOL_VARMOD_LUXE`, componentName = "COMPONENT_PISTOL_VARMOD_LUXE", label = "Lüks Ahşap Oymalı", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_pistol_mk2'] = {
        label = "Pistol Mk2",
        category = "Pistol",
        baseStats = { damage = 45, range = 38, accuracy = 65, control = 68, firerate = 55, mobility = 85 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_PI_SUPP_02`, componentName = "COMPONENT_AT_PI_SUPP_02", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15, control = 10 } },
            flashlight = { component = `COMPONENT_AT_PI_FLSH`, componentName = "COMPONENT_AT_PI_FLSH", label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10 } },
            scope = { component = `COMPONENT_AT_PI_RAIL`, componentName = "COMPONENT_AT_PI_RAIL", label = "Mikro Nişangah", category = "Scope", node = "scope", stats = { accuracy = 12 } },
            clip = { component = `COMPONENT_PISTOL_MK2_CLIP_02`, componentName = "COMPONENT_PISTOL_MK2_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -4 } }
        }
    },
    ['weapon_combatpistol'] = {
        label = "Combat Pistol (Glock 19)",
        category = "Pistol",
        baseStats = { damage = 48, range = 40, accuracy = 65, control = 70, firerate = 55, mobility = 82 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_PI_SUPP`, componentName = "COMPONENT_AT_PI_SUPP", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 12, control = 8, mobility = -4 } },
            flashlight = { component = `COMPONENT_AT_PI_FLSH`, componentName = "COMPONENT_AT_PI_FLSH", label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            clip = { component = `COMPONENT_COMBATPISTOL_CLIP_02`, componentName = "COMPONENT_COMBATPISTOL_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -4, mobility = -5 } },
            finish = { component = `COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER`, componentName = "COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER", label = "Lowrider Oymalı", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_appistol'] = {
        label = "AP Pistol",
        category = "Pistol",
        baseStats = { damage = 38, range = 38, accuracy = 55, control = 50, firerate = 85, mobility = 88 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_PI_SUPP`, componentName = "COMPONENT_AT_PI_SUPP", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 10, control = 12, mobility = -5 } },
            flashlight = { component = `COMPONENT_AT_PI_FLSH`, componentName = "COMPONENT_AT_PI_FLSH", label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 8, mobility = -2 } },
            clip = { component = `COMPONENT_APPISTOL_CLIP_02`, componentName = "COMPONENT_APPISTOL_CLIP_02", label = "Tambur Şarjör", category = "Magazine", node = "clip", stats = { control = -8, mobility = -8 } },
            finish = { component = `COMPONENT_APPISTOL_VARMOD_LUXE`, componentName = "COMPONENT_APPISTOL_VARMOD_LUXE", label = "Lüks Altın Kaplama", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_pistol50'] = {
        label = "Pistol .50",
        category = "Pistol",
        baseStats = { damage = 75, range = 50, accuracy = 70, control = 45, firerate = 35, mobility = 75 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, componentName = "COMPONENT_AT_AR_SUPP_02", label = "Ağır Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 18, control = 15, mobility = -8 } },
            flashlight = { component = `COMPONENT_AT_PI_FLSH`, componentName = "COMPONENT_AT_PI_FLSH", label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            clip = { component = `COMPONENT_PISTOL50_CLIP_02`, componentName = "COMPONENT_PISTOL50_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -6, mobility = -6 } },
            finish = { component = `COMPONENT_PISTOL50_VARMOD_LUXE`, componentName = "COMPONENT_PISTOL50_VARMOD_LUXE", label = "Lüks İşleme", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_smg'] = {
        label = "SMG MP5",
        category = "SMG",
        baseStats = { damage = 45, range = 45, accuracy = 68, control = 72, firerate = 75, mobility = 78 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_PI_SUPP`, componentName = "COMPONENT_AT_PI_SUPP", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 12, control = 10, mobility = -5 } },
            flashlight = { component = `COMPONENT_AT_AR_FLSH`, componentName = "COMPONENT_AT_AR_FLSH", label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            scope = { component = `COMPONENT_AT_SCOPE_MACRO_02`, componentName = "COMPONENT_AT_SCOPE_MACRO_02", label = "Kırmızı Nokta Dürbün", category = "Scope", node = "scope", stats = { accuracy = 15, range = 8, mobility = -4 } },
            clip = { component = `COMPONENT_SMG_CLIP_02`, componentName = "COMPONENT_SMG_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -5, mobility = -6 } },
            finish = { component = `COMPONENT_SMG_VARMOD_LUXE`, componentName = "COMPONENT_SMG_VARMOD_LUXE", label = "Lüks Kaplama", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_microsmg'] = {
        label = "Micro SMG",
        category = "SMG",
        baseStats = { damage = 40, range = 38, accuracy = 58, control = 60, firerate = 82, mobility = 85 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, componentName = "COMPONENT_AT_AR_SUPP_02", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 10 } },
            flashlight = { component = `COMPONENT_AT_PI_FLSH`, componentName = "COMPONENT_AT_PI_FLSH", label = "Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 8 } },
            scope = { component = `COMPONENT_AT_SCOPE_MACRO`, componentName = "COMPONENT_AT_SCOPE_MACRO", label = "Dürbün", category = "Scope", node = "scope", stats = { accuracy = 12 } },
            clip = { component = `COMPONENT_MICROSMG_CLIP_02`, componentName = "COMPONENT_MICROSMG_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -5 } },
            finish = { component = `COMPONENT_MICROSMG_VARMOD_LUXE`, componentName = "COMPONENT_MICROSMG_VARMOD_LUXE", label = "Lüks Altın", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_assaultrifle'] = {
        label = "Assault Rifle (AK-47)",
        category = "Rifle",
        baseStats = { damage = 62, range = 65, accuracy = 60, control = 58, firerate = 62, mobility = 65 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, componentName = "COMPONENT_AT_AR_SUPP_02", label = "Taktik Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15, control = 12, mobility = -6 } },
            flashlight = { component = `COMPONENT_AT_AR_FLSH`, componentName = "COMPONENT_AT_AR_FLSH", label = "Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            scope = { component = `COMPONENT_AT_SCOPE_MACRO`, componentName = "COMPONENT_AT_SCOPE_MACRO", label = "Nişangah Dürbün", category = "Scope", node = "scope", stats = { accuracy = 18, range = 10, mobility = -5 } },
            grip = { component = `COMPONENT_AT_AR_AFGRIP`, componentName = "COMPONENT_AT_AR_AFGRIP", label = "Ön Tutamak", category = "Grip", node = "grip", stats = { control = 18, accuracy = 10, mobility = -4 } },
            clip = { component = `COMPONENT_ASSAULTRIFLE_CLIP_02`, componentName = "COMPONENT_ASSAULTRIFLE_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -6, mobility = -8 } }
        }
    },
    ['weapon_assaultrifle_mk2'] = {
        label = "Assault Rifle Mk2 (AK Mk2)",
        category = "Rifle",
        baseStats = { damage = 65, range = 68, accuracy = 64, control = 62, firerate = 65, mobility = 65 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, componentName = "COMPONENT_AT_AR_SUPP_02", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15, control = 12 } },
            flashlight = { component = `COMPONENT_AT_AR_FLSH`, componentName = "COMPONENT_AT_AR_FLSH", label = "Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10 } },
            scope = { component = `COMPONENT_AT_SCOPE_MACRO_MK2`, componentName = "COMPONENT_AT_SCOPE_MACRO_MK2", label = "Dürbün", category = "Scope", node = "scope", stats = { accuracy = 18 } },
            grip = { component = `COMPONENT_AT_AR_AFGRIP_02`, componentName = "COMPONENT_AT_AR_AFGRIP_02", label = "Ön Tutamak", category = "Grip", node = "grip", stats = { control = 18 } },
            clip = { component = `COMPONENT_ASSAULTRIFLE_MK2_CLIP_02`, componentName = "COMPONENT_ASSAULTRIFLE_MK2_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -6 } }
        }
    },
    ['weapon_carbinerifle'] = {
        label = "Carbine Rifle (M4A1)",
        category = "Rifle",
        baseStats = { damage = 58, range = 70, accuracy = 75, control = 70, firerate = 68, mobility = 68 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_AR_SUPP`, componentName = "COMPONENT_AT_AR_SUPP", label = "Taktik Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15, control = 12, mobility = -6 } },
            flashlight = { component = `COMPONENT_AT_AR_FLSH`, componentName = "COMPONENT_AT_AR_FLSH", label = "Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            scope = { component = `COMPONENT_AT_SCOPE_MEDIUM`, componentName = "COMPONENT_AT_SCOPE_MEDIUM", label = "Orta Menzil Dürbün", category = "Scope", node = "scope", stats = { accuracy = 20, range = 12, mobility = -6 } },
            grip = { component = `COMPONENT_AT_AR_AFGRIP`, componentName = "COMPONENT_AT_AR_AFGRIP", label = "Ön Tutamak", category = "Grip", node = "grip", stats = { control = 20, accuracy = 8, mobility = -4 } },
            clip = { component = `COMPONENT_CARBINERIFLE_CLIP_02`, componentName = "COMPONENT_CARBINERIFLE_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -6, mobility = -7 } },
            finish = { component = `COMPONENT_CARBINERIFLE_VARMOD_LUXE`, componentName = "COMPONENT_CARBINERIFLE_VARMOD_LUXE", label = "Lüks Metalik Kaplama", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_specialcarbine'] = {
        label = "Special Carbine (G36C)",
        category = "Rifle",
        baseStats = { damage = 60, range = 68, accuracy = 72, control = 75, firerate = 70, mobility = 70 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, componentName = "COMPONENT_AT_AR_SUPP_02", label = "Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 14, control = 10, mobility = -5 } },
            flashlight = { component = `COMPONENT_AT_AR_FLSH`, componentName = "COMPONENT_AT_AR_FLSH", label = "Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10, mobility = -2 } },
            scope = { component = `COMPONENT_AT_SCOPE_MEDIUM`, componentName = "COMPONENT_AT_SCOPE_MEDIUM", label = "Dürbün", category = "Scope", node = "scope", stats = { accuracy = 18, range = 10, mobility = -5 } },
            grip = { component = `COMPONENT_AT_AR_AFGRIP`, componentName = "COMPONENT_AT_AR_AFGRIP", label = "Ön Tutamak", category = "Grip", node = "grip", stats = { control = 18, mobility = -3 } },
            clip = { component = `COMPONENT_SPECIALCARBINE_CLIP_02`, componentName = "COMPONENT_SPECIALCARBINE_CLIP_02", label = "Uzatılmış Şarjör", category = "Magazine", node = "clip", stats = { control = -5, mobility = -7 } }
        }
    },
    ['weapon_compactrifle'] = {
        label = "Compact Rifle",
        category = "Rifle",
        baseStats = { damage = 55, range = 50, accuracy = 60, control = 60, firerate = 65, mobility = 70 },
        attachments = {
            scope = { component = `COMPONENT_AT_SCOPE_MEDIUM`, componentName = "COMPONENT_AT_SCOPE_MEDIUM", label = "Taktik Dürbün", category = "Scope", node = "scope", stats = { accuracy = 15 } },
            clip = { component = `COMPONENT_COMPACTRIFLE_CLIP_02`, componentName = "COMPONENT_COMPACTRIFLE_CLIP_02", label = "Tambur Şarjör", category = "Magazine", node = "clip", stats = { control = -8 } }
        }
    },
    ['weapon_pumpshotgun'] = {
        label = "Pump Shotgun",
        category = "Shotgun",
        baseStats = { damage = 85, range = 25, accuracy = 45, control = 50, firerate = 30, mobility = 70 },
        attachments = {
            suppressor = { component = `COMPONENT_AT_SR_SUPP`, componentName = "COMPONENT_AT_SR_SUPP", label = "Shotgun Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15 } },
            flashlight = { component = `COMPONENT_AT_AR_FLSH`, componentName = "COMPONENT_AT_AR_FLSH", label = "Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10 } },
            finish = { component = `COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER`, componentName = "COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER", label = "Lowrider Oymalı", category = "Finish", node = "finish", stats = { accuracy = 5 } }
        }
    },
    ['weapon_heavysniper'] = {
        label = "Heavy Sniper .50",
        category = "Sniper",
        baseStats = { damage = 98, range = 95, accuracy = 90, control = 35, firerate = 20, mobility = 40 },
        attachments = {
            scope = { component = `COMPONENT_HEAVYSNIPER_SCOPE_LARGE3`, componentName = "COMPONENT_HEAVYSNIPER_SCOPE_LARGE3", label = "Gelişmiş Dürbün", category = "Scope", node = "scope", stats = { accuracy = 10 } }
        }
    }
}
