Config = {}

-- Framework Settings: 'autodetect', 'qb-core', 'esx', or 'standalone'
Config.Framework = 'autodetect'

-- Recording Buffer Settings
Config.BufferDuration = 300    -- Olay yeri canlandırma süresi (5 dakika = 300 saniye)
Config.RecordInterval = 200    -- Milliseconds between record ticks (200ms = 5 frames/sec = 1500 frames total)
Config.ScanRadius = 50.0        -- Distance around player to record peds/vehicles (meters)
Config.MaxIncidentAgeMinutes = 10 -- Maksimum olay inceleme zaman sınırı (10 dakika)

-- Automatic Recording Triggers
Config.RecordOnFatalDeath = true
Config.RecordOnVehicleCrash = true
Config.MinVehicleCrashSpeedDelta = 15.0 -- m/s speed drop required to log crash event

-- Access Control & Items (Sadece Polis / PD Ekipleri)
Config.AllowedJobs = {
    ['police'] = 0,
    ['sheriff'] = 0,
    ['detective'] = 0,
    ['fib'] = 0,
    ['justice'] = 0
}

Config.RequireItem = true
Config.ScannerItem = 'scanner_device'
Config.EnableCommand = true
Config.CommandName = 'olayyeri'
Config.ScannerRadius = 35.0 -- Detection radius for detective scanner tool (meters)

-- Holographic Visual Shader & Marker Settings
Config.Hologram = {
    Alpha = 160,                               -- Entity opacity (0 - 255)
    OutlineColor = { r = 0, g = 229, b = 255 }, -- Glowing outline RGB (Cyan)
    DrawTracers = true,                        -- Render bullet trajectory tracer lines
    TracerColor = { r = 255, g = 50, b = 50, a = 220 },
    DrawMarkers = true,                        -- Draw 3D Event Markers above entities
    MarkerType = 0,                            -- 0 = Cylinder, 2 = Chevron, 28 = Sphere
    MarkerScale = vector3(0.4, 0.4, 0.4),
    MarkerColor = { r = 0, g = 229, b = 255, a = 200 }
}

-- Investigation Scan Minigame Settings (5 Kanıt Noktası Taraması)
Config.Minigame = {
    Enabled = true,
    PointsCount = 5,                     -- Taranması gereken 3D kanıt noktası sayısı (5 adet)
    ScanTimePerPoint = 3000,             -- Her bir nokta için tarama süresi (3000ms = 3 saniye)
    ScannerPropModel = 'scanner_device', -- Özel tarayıcı prop modeli (stream/scanner_device)
    ScannerPropFallback = 'p_digiscanner' -- İkincil yedek GTA V digiscanner modeli
}

-- Notification Titles & Language (Türkçe)
Config.Locale = {
    ['scanner_started'] = 'Alan Tarayıcısı aktifleştirildi. 35m yarıçap taranıyor...',
    ['no_incidents_found'] = 'Bu bölgede son 10 dakika içerisinde kaydedilmiş olay kaydı bulunamadı.',
    ['incident_saved'] = 'Olay yeri kaydı veritabanına başarıyla kaydedildi! ID: ',
    ['playback_started'] = '5 dakikalık holografik olay yeri canlandırması yüklendi.',
    ['playback_ended'] = 'Holografik olay yeri canlandırması sonlandırıldı.',
    ['no_permission'] = 'Olay yeri incelemesi yapmak için Polis/PD yetkiniz bulunmuyor.',
    ['missing_item'] = 'Bu işlemi gerçekleştirmek için Holografik Olay Yeri Tarayıcısı gereklidir.',
    ['incident_expired'] = 'Bu olay yerinin üzerinden 10 dakikadan fazla zaman geçtiği için inceleme süresi dolmuştur!',
    ['minigame_started'] = 'Olay Yeri İncelemesi Başladı! Çevredeki 5 kanıt bölgesini tarayın.',
    ['minigame_point_prompt'] = '~g~[E]~w~ KANIT BÖLGESİNİ TARA (~b~%d/%d~w~)',
    ['minigame_scanning'] = 'Kanıt bölgesi taranıyor...',
    ['minigame_point_complete'] = 'Kanıt bölgesi taranarak kayda işlendi! (%d/%d)',
    ['minigame_completed'] = 'Tüm kanıt bölgeleri başarıyla taranıp çözümlendi! Olay yeri verileri yükleniyor...'
}
