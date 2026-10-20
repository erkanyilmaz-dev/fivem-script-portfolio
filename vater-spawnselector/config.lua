Config = Config or {}

Config.DefaultSpawn = vector4(195.17, -933.77, 29.7, 144.5)

Config.Spawns = {
    legion = {
        coords = vector4(195.17, -933.77, 29.7, 144.5),
        location = 'legion',
        label = 'Legion Square',
        description = 'Şehir merkezi, en sıcak çatışmaların yaşandığı pvp alanı.',
        difficulty = 'Zor',
        players = 'Çok Yoğun'
    },
    paleto = {
        coords = vector4(80.35, 6424.12, 31.67, 45.5),
        location = 'paleto',
        label = 'Paleto Bay',
        description = 'Kuzey bölgesi kasaba merkezi, uzak mesafe silahlı mücadeleler.',
        difficulty = 'Zor',
        players = 'Sakin'
    },
    policedp = {
        coords = vector4(428.23, -984.28, 29.76, 3.5),
        location = 'policedp',
        label = 'Polis Departmanı',
        description = 'Merkez Polis Karakolu önü, korunaklı ve geniş siper alanları.',
        difficulty = 'Orta',
        players = 'Normal'
    },
    hospital = {
        coords = vector4(298.02, -584.43, 43.26, 72.84),
        location = 'hospital',
        label = 'Hastane',
        description = 'Pillbox Hill Hastanesi önü, pvp sırası canlanma noktası.',
        difficulty = 'Kolay',
        players = 'Yoğun'
    },
    motel = {
        coords = vector4(327.56, -205.08, 53.08, 163.5),
        location = 'motel',
        label = 'Pink Motel',
        description = 'Pembe Motel ve çevresi, yakın mesafe siper alma ve çatışma.',
        difficulty = 'Zor',
        players = 'Yoğun'
    },
}

Config.Lang = 'tr'

Config.Translations = {
    ['tr'] = {
        title = 'SPAWN NOKTASI SEÇİN',
        subtitle = 'VATERPVP - BABALARIN MEKANI',
        spawn_btn = 'SPAWN OL',
        last_location = 'Son Konum',
        last_loc_desc = 'En son oyundan çıktığınız koordinatlarda doğun.',
        difficulty_label = 'ZORLUK',
        density_label = 'PVP YOĞUNLUK',
        select_spawn = 'Haritadan veya listeden bir konum seçin.',
    },
    ['en'] = {
        title = 'CHOOSE SPAWN POINT',
        subtitle = 'VATERPVP - HOME OF THE BOSSES',
        spawn_btn = 'SPAWN',
        last_location = 'Last Location',
        last_loc_desc = 'Spawn at the coordinates where you last logged out.',
        difficulty_label = 'DIFFICULTY',
        density_label = 'PVP DENSITY',
        select_spawn = 'Select a location from the map or list.',
    }
}
