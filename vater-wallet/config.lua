Config = {}

-- Komut ve Tuş Ayarları
Config.Command = 'cuzdan'
Config.OpenKey = 'K' -- Varsayılan tuş (K)
Config.UseItem = true -- Item olarak kullanılabilir mi?
Config.ItemName = 'cuzdan' -- QBCore eşya adı

-- Yakındaki oyuncuya gösterme mesafesi (metre)
Config.ShowDistance = 3.0

-- Varsayılan Kimlik Görseli (San Andreas Eyalet Kimliği)
Config.DefaultAvatar = ''

-- Cüzdanda Görüntülenecek Kartlar
Config.Cards = {
    id_card = {
        enabled = true,
        title = 'KİMLİK KARTI',
        subtitle = 'San Andreas Eyalet Kimliği',
        bgClass = 'card-id',
        requiredLicense = nil, -- Herkeste var
        badge = 'T.C. / S.A.'
    },
    driver_license = {
        enabled = true,
        title = 'SÜRÜCÜ BELGESİ',
        subtitle = 'San Andreas Sürücü Lisansı',
        bgClass = 'card-driver',
        requiredLicense = 'driver',
        badge = 'CLASS C'
    },
    bank_card = {
        enabled = true,
        title = 'FLEET BANK',
        subtitle = 'Visa Platinum Debit Card',
        bgClass = 'card-bank',
        requiredLicense = nil,
        badge = 'DEBIT'
    },
    weapon_license = {
        enabled = true,
        title = 'SİLAH RUHSATI',
        subtitle = 'Ateşli Silah Taşıma İzni',
        bgClass = 'card-weapon',
        requiredLicense = 'weapon',
        badge = 'CCW PERMIT'
    },
    lawyer_license = {
        enabled = true,
        title = 'AVUKAT LİSANSI',
        subtitle = 'Barolar Birliği Avukatlık Belgesi',
        bgClass = 'card-lawyer',
        requiredLicense = 'lawyer',
        badge = 'ATTORNEY'
    },
    vip_card = {
        enabled = true,
        title = 'DIAMOND VIP',
        subtitle = 'The Diamond Casino & Resort VIP',
        bgClass = 'card-vip',
        requiredLicense = 'vip',
        badge = 'GOLD MEMBER'
    }
}

-- Diller / Metinler
Config.Locales = {
    wallet_title = "VATER LEATHER CO.",
    cash_title = "NAKİT PARA",
    bank_title = "BANKA HESABI",
    show_nearby = "Yakındakine Göster",
    inspect = "Kartı İncele",
    flip = "Çevir",
    close = "Kapat",
    gender_male = "Erkek",
    gender_female = "Kadın",
    active = "Aktif / Geçerli",
    inactive = "Mevcut Değil / İptal",
    card_shown = "Kartınızı yakındaki kişiye gösterdiniz.",
    no_player_nearby = "Yakınınızda kart gösterilecek kimse yok!"
}
