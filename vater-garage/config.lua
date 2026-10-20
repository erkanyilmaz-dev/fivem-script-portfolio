Config = {}

Config.Debug = false
Config.Command = 'garaj'
Config.DrawDistance = 18.0
Config.InteractionDistance = 2.0
-- Garaj menüsü hedef sistemiyle değil, görevli NPC'ye E basılarak açılır.
Config.UseTarget = false
Config.PedModel = 's_m_y_xmech_02'
Config.PedScenario = 'WORLD_HUMAN_CLIPBOARD'
Config.ParkingMarker = {
    type = 1,
    scale = vector3(4.0, 4.0, 0.35),
    colour = { r = 40, g = 214, b = 166, a = 135 }
}
Config.StoreRadius = 22.0
Config.TakeOutCooldown = 2000
Config.DefaultGarage = 'legion'
Config.ImpoundFee = 2500
Config.TransferFee = 500
Config.AllowedVehicleClasses = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true, [19] = true, [20] = true }

Config.Garages = {
    legion = {
        label = 'Legion Square', type = 'public', icon = 'P',
        coords = vector3(215.84, -810.12, 30.73),
        -- Kulübe objesi üzerinden hesaplanır; mapping değişse de NPC kapının önünde kalır.
        ped = vector4(214.60, -807.75, 30.73, 160.0),
        booth = {
            models = { 'dt1_21_parkinghut', 'prop_parking_hut_2', 'prop_parking_hut_2b' },
            frontOffset = vector3(0.0, 2.25, 0.0)
        },
        store = vector3(215.84, -810.12, 30.73),
        spawn = vector4(229.49, -800.33, 30.57, 157.11),
        blip = { sprite = 357, colour = 3, scale = 0.72 }
    },
    pinkcage = {
        label = 'Pink Cage', type = 'public', icon = 'P',
        coords = vector3(273.21, -343.88, 44.92),
        ped = vector4(270.93, -343.14, 44.92, 247.0),
        store = vector3(273.21, -343.88, 44.92),
        spawn = vector4(285.04, -342.59, 44.92, 249.25),
        blip = { sprite = 357, colour = 3, scale = 0.72 }
    },
    pillbox = {
        label = 'Pillbox Hill', type = 'public', icon = 'P',
        coords = vector3(294.22, -611.22, 43.29),
        ped = vector4(292.62, -613.07, 43.29, 340.0),
        store = vector3(294.22, -611.22, 43.29),
        spawn = vector4(286.90, -603.42, 43.34, 68.11),
        blip = { sprite = 357, colour = 3, scale = 0.72 }
    },
    sandy = {
        label = 'Sandy Shores', type = 'public', icon = 'P',
        coords = vector3(1737.54, 3710.13, 34.14),
        ped = vector4(1735.53, 3709.07, 34.14, 21.0),
        store = vector3(1737.54, 3710.13, 34.14),
        spawn = vector4(1730.51, 3711.48, 34.11, 20.0),
        blip = { sprite = 357, colour = 3, scale = 0.72 }
    },
    paleto = {
        label = 'Paleto Bay', type = 'public', icon = 'P',
        coords = vector3(105.04, 6613.88, 31.98),
        ped = vector4(103.04, 6612.93, 31.98, 224.0),
        store = vector3(105.04, 6613.88, 31.98),
        spawn = vector4(113.19, 6611.19, 31.85, 221.0),
        blip = { sprite = 357, colour = 3, scale = 0.72 }
    },
    police = {
        label = 'LSPD Motor Pool', type = 'job', job = 'police', icon = 'S',
        coords = vector3(454.58, -1017.33, 28.45),
        ped = vector4(452.39, -1018.42, 28.45, 90.0),
        store = vector3(454.58, -1017.33, 28.45),
        spawn = vector4(438.67, -1018.31, 28.70, 91.0),
        blip = { sprite = 56, colour = 38, scale = 0.72 }
    }
}

Config.Text = {
    open = '[E] Garajı Aç',
    store = '[E] Aracı Garaja Koy',
    noVehicles = 'Bu garajda gösterilecek araç yok.',
    noAccess = 'Bu garaja erişimin yok.',
    spawnBlocked = 'Araç çıkış noktası dolu.',
    tooFar = 'Garaj alanına yeterince yakın değilsin.',
    notOwner = 'Bu araç sana ait değil.',
    stored = 'Araç güvenli şekilde garaja kaldırıldı.',
    retrieved = 'Araç hazır. Güvenli sürüşler!',
    impounded = 'Araç çekildi. Çıkarmak için ödeme gerekiyor.',
    transferDone = 'Araç devri tamamlandı.',
    invalidPlayerId = 'Bu oyuncu ID ile çevrimiçi bir oyuncu bulunamadı.',
    vehicleMustBeStored = 'Araç devredilmeden önce garaja park edilmelidir.',
    recoverQueued = 'Araç garaja geri alındı. Garajı kapatıp tekrar açarak çıkarabilirsin.'
}
