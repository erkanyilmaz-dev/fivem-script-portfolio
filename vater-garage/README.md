# Vater Garage — WraithPVP

QBCore ve oxmysql için hazırlanmış, modern NUI arayüzlü garaj kaynağı.

## İçerik

- Kişisel, iş ve çete garaj altyapısı
- Araç çıkartma, hasar/yakıt/modifikasyonlarını kaydederek geri koyma
- Araç durumu, çekici ücreti, favori araçlar ve güvenli Citizen ID devri
- `qb-target` varsa hedef etkileşimi, yoksa E tuşu desteği
- Sunucu tarafında sahiplik, mesafe ve garaj yetkisi doğrulaması
- Mobil ekranlara uyumlu modern NUI

## Kurulum

1. `vater-garage` klasörünü sunucunuzun `resources` dizinine taşıyın.
2. [sql/vater-garage.sql](sql/vater-garage.sql) dosyasını veritabanınızda bir kez çalıştırın. Mevcut QBCore `player_vehicles` şemanızda alanlar varsa komutlar onları atlar.
3. `server.cfg` içine `ensure oxmysql`, `ensure qb-core` satırlarından sonra `ensure vater-garage` ekleyin.
4. Garaj yerlerini, ücretleri ve meslek garajlarını `config.lua` üzerinden WraithPVP’ye göre düzenleyin.

## Gereksinimler

- qb-core
- oxmysql
- qb-target (isteğe bağlı)

Kişisel araçlar standart `player_vehicles` tablosundan okunur. İş/çete araçlarını desteklemek için ilgili kayıtların `job` veya `gang` sütununda uygun değer bulunmalıdır.
