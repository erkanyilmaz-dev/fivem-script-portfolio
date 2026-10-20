Config = {}
Config.Locale = 'tr' -- 'tr' veya 'en'
Config.Currency = '$'
Config.CurrencyPosition = 'right' -- 'left' ($100) or 'right' (100 $)

-- Genel Ayarlar
Config.AllowFreePreview = true -- Menü açıkken ücretsiz parça önizleme (Satın al veya Çıkışta eski haline döner)
Config.SaveToDatabase = true -- Değişiklikleri player_vehicles tablosuna oxmysql ile kaydet
Config.RepairCostPerHealthPoint = 2.5 -- Her eksik can puanı için onarım ücreti çarpanı
Config.WashPrice = 150 -- Yıkama ücreti
Config.DefaultFullRepairPrice = 2500 -- Tam tamir maksimum taban ücreti

-- Mekanik Lokasyonları
Config.Locations = {
    ["bennys_original"] = {
        name = "Benny's Original Motorworks",
        coords = vector3(-211.55, -1324.55, 30.89),
        heading = 320.0,
        radius = 5.0,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - Benny's"
        },
        job = nil, -- nil = Herkese açık, 'mechanic' / 'bennys' = Sadece meslek sahiplerine
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    },
    ["ls_customs_burton"] = {
        name = "Los Santos Customs - Burton",
        coords = vector3(-338.28, -136.71, 39.01),
        heading = 75.0,
        radius = 4.5,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - LS Customs (Burton)"
        },
        job = nil,
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    },
    ["ls_customs_airport"] = {
        name = "Los Santos Customs - Havalimanı",
        coords = vector3(-1155.53, -2005.47, 13.18),
        heading = 135.0,
        radius = 5.0,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - Havalimanı"
        },
        job = nil,
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    },
    ["hayes_autos"] = {
        name = "Hayes Autos",
        coords = vector3(-1423.86, -449.62, 35.91),
        heading = 300.0,
        radius = 5.0,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - Hayes Autos"
        },
        job = nil,
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    },
    ["harmony_repairs"] = {
        name = "Harmony Repairs & Tuning",
        coords = vector3(1177.89, 2640.16, 37.75),
        heading = 180.0,
        radius = 5.0,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - Harmony"
        },
        job = nil,
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    },
    ["paleto_bay"] = {
        name = "Beeker's Garage - Paleto Bay",
        coords = vector3(110.98, 6626.38, 31.79),
        heading = 45.0,
        radius = 5.0,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - Paleto Bay"
        },
        job = nil,
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    },
    ["tuner_shop"] = {
        name = "Los Santos Tuners",
        coords = vector3(140.71, -3030.38, 7.04),
        heading = 0.0,
        radius = 5.0,
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.75,
            name = "Vater Mechanic - Tuners"
        },
        job = nil,
        society = "society_mechanic",
        drawMarker = true,
        markerColor = { r = 0, g = 229, b = 255, a = 180 }
    }
}

-- Fiyatlandırma Tablosu (Örnek taban fiyatlar ve seviye katsayıları)
Config.Prices = {
    -- Performans Yükseltmeleri (Seviye başına fiyat)
    performance = {
        engine = { 2500, 5000, 10000, 18000, 26000 },
        brakes = { 1500, 3500, 7000, 12000 },
        transmission = { 2000, 4500, 9000, 15000 },
        suspension = { 1000, 2500, 5000, 8500, 12000 },
        armor = { 3000, 6000, 12000, 20000, 35000 },
        turbo = 15000
    },

    -- Dış Gövde & Kozmetik Parçalar
    cosmetics = {
        spoilers = 1800,
        frontBumper = 1600,
        rearBumper = 1600,
        sideSkirt = 1200,
        exhaust = 1400,
        frame = 1800,
        grille = 950,
        hood = 2200,
        fender = 1100,
        rightFender = 1100,
        roof = 2000,
        archCover = 1200,
        aerials = 500,
        trimA = 900,
        trimB = 900,
        tank = 1500,
        windows = 800,
        plateHolder = 400,
        vanityPlate = 500,
        livery = 3500,
        liveryRoof = 2500,
        extras = 450
    },

    -- İç Mekan
    interior = {
        dashboard = 1200,
        dial = 800,
        doorSpeaker = 650,
        seats = 1600,
        steeringWheel = 1100,
        shifterLeavers = 750,
        aPlate = 500,
        speakers = 1300,
        trunk = 1400,
        hydrolic = 8000,
        engineBlock = 2500,
        airFilter = 1100,
        struts = 1800,
        ornaments = 400
    },

    -- Boya & Kaplama
    paint = {
        primary = 1200,
        secondary = 900,
        pearlescent = 1500,
        interior = 850,
        dashboard = 850,
        wheel = 650,
        customRGB = 2200,
        chameleon = 4500
    },

    -- Işıklandırma
    lighting = {
        xenon = 2500,
        xenonColor = 1200,
        neonSet = 3500, -- 4 taraf komple kit
        neonColor = 800
    },

    -- Jantlar ve Lastikler
    wheels = {
        type = 2000,
        customTires = 1200,
        driftTires = 3000,
        bulletproofTires = 8500,
        tireSmoke = 1500
    },

    -- Cam Filmi, Korna & Plaka
    miscellaneous = {
        windowTint = 950,
        horns = 600,
        plateIndex = 750
    }
}

-- GTA Boya Tipleri ve Paletleri
Config.PaintTypes = {
    { id = 0, name = "Normal / Standart" },
    { id = 1, name = "Metalik (Metallic)" },
    { id = 2, name = "İnci / Sedef (Pearl)" },
    { id = 3, name = "Mat (Matte)" },
    { id = 4, name = "Krom (Chrome)" },
    { id = 5, name = "Bukalemun (Chameleon)" }
}

-- Kategorize Edilmiş Renk Listesi
Config.Colors = {
    ["Siyah & Koyu"] = {
        { name = "Siyah", index = 0 },
        { name = "Karbon Siyah", index = 147 },
        { name = "Grafit Siyah", index = 1 },
        { name = "An Trasit Siyah", index = 11 },
        { name = "Mat Siyah", index = 12 },
        { name = "Koyu Çelik", index = 2 },
        { name = "Gümüş Grisi", index = 4 },
        { name = "Çelik Grisi", index = 5 }
    },
    ["Beyaz & Açık"] = {
        { name = "Saf Kar Beyazı", index = 111 },
        { name = "Buz Beyazı", index = 112 },
        { name = "Krem Beyazı", index = 107 },
        { name = "Mat Beyaz", index = 131 },
        { name = "Sedef Beyaz", index = 134 }
    },
    ["Kırmızı & Bordo"] = {
        { name = "Torino Kırmızısı", index = 27 },
        { name = "Formula Kırmızısı", index = 28 },
        { name = "Lav Kırmızısı", index = 29 },
        { name = "Şarap Bordosu", index = 33 },
        { name = "Koyu Bordo", index = 34 },
        { name = "Garnet Kırmızısı", index = 35 },
        { name = "Mat Kırmızı", index = 39 },
        { name = "Mat Koyu Kırmızı", index = 40 }
    },
    ["Mavi & Turkuaz"] = {
        { name = "Ultra Mavi", index = 70 },
        { name = "Yarış Mavisi", index = 73 },
        { name = "Kraliyet Mavisi", index = 64 },
        { name = "Gece Mavisi", index = 61 },
        { name = "Liman Mavisi", index = 67 },
        { name = "Elmas Mavisi", index = 68 },
        { name = "Sörf Mavisi", index = 69 },
        { name = "Elektrik Mavisi", index = 74 },
        { name = "Mat Koyu Mavi", index = 83 },
        { name = "Mat Gece Yarısı", index = 84 }
    },
    ["Yeşil & Haki"] = {
        { name = "Yarış Yeşili", index = 50 },
        { name = "Deniz Yeşili", index = 51 },
        { name = "Zeytin Yeşili", index = 52 },
        { name = "Parlak Yeşil", index = 53 },
        { name = "Benzin Yeşili", index = 54 },
        { name = "Limon Yeşili", index = 92 },
        { name = "Mat Yeşil", index = 55 },
        { name = "Mat Askeri Yeşil", index = 128 }
    },
    ["Sarı & Altın"] = {
        { name = "Yarış Sarısı", index = 88 },
        { name = "Taksi Sarısı", index = 89 },
        { name = "Altın Sarısı", index = 91 },
        { name = "Mat Sarı", index = 42 },
        { name = "Şampanya Sarısı", index = 99 }
    },
    ["Turuncu & Bakır"] = {
        { name = "Gün Batımı Turuncusu", index = 38 },
        { name = "Parlak Turuncu", index = 138 },
        { name = "Bakır Turuncu", index = 41 },
        { name = "Mat Turuncu", index = 123 },
        { name = "Lava Turuncusu", index = 124 }
    },
    ["Mor & Pembe"] = {
        { name = "Gece Moru", index = 71 },
        { name = "Neon Mor", index = 72 },
        { name = "Miliard Pembe", index = 135 },
        { name = "Gül Pembesi", index = 137 },
        { name = "Mat Mor", index = 148 },
        { name = "Mat Koyu Mor", index = 149 }
    },
    ["Krom & Özel"] = {
        { name = "Saf Krom (Chrome)", index = 120 },
        { name = "Fırçalanmış Çelik", index = 117 },
        { name = "Fırçalanmış Siyah Çelik", index = 118 },
        { name = "Fırçalanmış Alüminyum", index = 119 },
        { name = "Saf Altın Kaplama", index = 158 },
        { name = "Fırçalanmış Altın", index = 159 }
    }
}

-- Xenon Far Renkleri
Config.XenonColors = {
    { id = -1, name = "Standart Halojen / Beyaz" },
    { id = 0, name = "Buz Beyazı (Ice White)" },
    { id = 1, name = "Elektrik Mavisi (Electric Blue)" },
    { id = 2, name = "Açık Mavi (Mint Blue)" },
    { id = 3, name = "Kireç Yeşili (Lime Green)" },
    { id = 4, name = "Zümrüt Yeşili (Emerald)" },
    { id = 5, name = "Güneş Sarısı (Golden Yellow)" },
    { id = 6, name = "Altın Sarısı (Pure Gold)" },
    { id = 7, name = "Turuncu (Amber Orange)" },
    { id = 8, name = "Kırmızı (Blaze Red)" },
    { id = 9, name = "Pony Pembe (Soft Pink)" },
    { id = 10, name = "Sıcak Pembe (Hot Pink)" },
    { id = 11, name = "Mor (Royal Purple)" },
    { id = 12, name = "Ultraviyole (Blacklight)" }
}

-- Cam Filmi Çeşitleri
Config.WindowTints = {
    { id = 0, name = "Yok / Fabrika Çıkışı (Stock)" },
    { id = 3, name = "Açık Duman (Light Smoke)" },
    { id = 2, name = "Koyu Duman (Dark Smoke)" },
    { id = 1, name = "Saf Siyah (Limo / Pure Black)" },
    { id = 4, name = "Yeşil / Özel (Green)" },
    { id = 5, name = "Altın / Bronz (Gold)" }
}

-- Plaka Stilleri
Config.PlateTypes = {
    { id = 0, name = "Mavi Üzerine Beyaz (Blue / White)" },
    { id = 1, name = "Sarı Üzerine Siyah (Yellow / Black)" },
    { id = 2, name = "Mavi Üzerine Sarı (Yellow / Blue)" },
    { id = 3, name = "Mavi / Beyaz 2 (Blue / White 2)" },
    { id = 4, name = "Mavi / Beyaz 3 (Blue / White 3)" },
    { id = 5, name = "Yankton Özel Plaka (North Yankton)" }
}

-- Jant Kategorileri
Config.WheelCategories = {
    { id = 0, name = "Spor (Sport)" },
    { id = 1, name = "Kaslı (Muscle)" },
    { id = 2, name = "Lowrider" },
    { id = 3, name = "SUV / Arazi" },
    { id = 4, name = "Off-Road" },
    { id = 5, name = "Tuner / Sokak" },
    { id = 6, name = "Motosiklet (Bikes)" },
    { id = 7, name = "High End / Lüks" },
    { id = 8, name = "Benny's Özel (Bespoke)" },
    { id = 9, name = "Benny's Klasik (Original)" },
    { id = 10, name = "Açık Teker (Open Wheel)" },
    { id = 11, name = "Sokak (Street)" },
    { id = 12, name = "Pist / Yarış (Track)" }
}

-- Korna Listesi
Config.Horns = {
    { id = -1, name = "Standart Korna" },
    { id = 0, name = "Kamyon Kornası" },
    { id = 1, name = "Polis Kornası" },
    { id = 2, name = "Palyaço Kornası" },
    { id = 3, name = "Müzikal Korna 1" },
    { id = 4, name = "Müzikal Korna 2" },
    { id = 5, name = "Müzikal Korna 3" },
    { id = 6, name = "Müzikal Korna 4" },
    { id = 7, name = "Müzikal Korna 5" },
    { id = 8, name = "Cucaracha 1" },
    { id = 9, name = "Cucaracha 2" },
    { id = 10, name = "Cucaracha 3" },
    { id = 11, name = "Cucaracha 4" },
    { id = 12, name = "Klasik Trompet" },
    { id = 13, name = "Dixie Korna" },
    { id = 14, name = "Hüzün Trompeti" },
    { id = 15, name = "Caz Korna" }
}
