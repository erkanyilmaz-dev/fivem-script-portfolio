local Translations = {
    error = {
        not_in_vehicle = "Bu işlemi gerçekleştirmek için bir araçta olmalısınız!",
        must_be_driver = "Aracı modifiye etmek için sürücü koltuğunda olmalısınız!",
        cannot_afford = "Yetersiz bakiye! Bu işlem için %s $ gerekiyor.",
        not_mechanic = "Bu mekanda işlem yapabilmek için yetkili mekanik olmalısınız!",
        vehicle_not_found = "Araç bulunamadı!",
        already_repairing = "Araç şu anda onarılıyor, lütfen bekleyin...",
        not_owner = "Bu araç size ait değil ancak değişiklikler geçici olarak uygulandı.",
        society_cannot_afford = "Mekanik kasasında yeterli para yok!",
    },
    success = {
        installed = "%s başarıyla araca takıldı!",
        purchased = "Tüm modifikasyonlar başarıyla satın alındı ve uygulandı! Toplam: %s $",
        repaired = "Araç başarıyla onarıldı ve temizlendi!",
        cleaned = "Araç pırıl pırıl yıkandı!",
        color_applied = "Boya işlemi başarıyla tamamlandı!",
        saved = "Araç modifikasyonları başarıyla kaydedildi.",
    },
    info = {
        press_e_modify = "[E] - Vater Mechanic Atölyesine Gir",
        mechanic_bay = "Mekanik Garajı",
        duty_off = "Mekanikte şu an görevde değilsiniz!",
        invoice_sent = "Fatura müşteriye gönderildi.",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
