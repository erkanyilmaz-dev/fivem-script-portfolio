local QBCore = exports['qb-core']:GetCoreObject()

local function normalizeWeaponName(weaponName)
    if type(weaponName) ~= "string" then return nil end
    return weaponName:lower()
end

local function normalizeSkinId(skinId)
    if type(skinId) ~= "string" then return nil end
    local normalized = skinId:match("^%s*(.-)%s*$"):lower()
    if normalized == "" or normalized == "default" then return nil end
    return normalized
end

local function getSkinMode(skin)
    if type(skin) ~= "table" or type(skin.mode) ~= "string" then return "component" end
    return skin.mode:lower()
end

local function getSkinDefinition(skinId, weaponName)
    local normalizedSkinId = normalizeSkinId(skinId)
    local normalizedWeaponName = normalizeWeaponName(weaponName)
    if not normalizedSkinId then return nil end

    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        local configuredWeapon = normalizeWeaponName(skin.weapon)
        if normalizeSkinId(skin.id) == normalizedSkinId
            and (not configuredWeapon or configuredWeapon == normalizedWeaponName) then
            return skin
        end
    end

    return nil
end


local function resolveComponentHash(component)
    if type(component) == "number" then return component end
    if type(component) == "string" and component ~= "" then
        return GetHashKey(component)
    end
    return nil
end


local function componentKey(component)
    local resolved = resolveComponentHash(component)
    return resolved and tostring(resolved) or nil
end


local function findWeaponItem(Player, weaponName, requestedSlot)
    local items = Player.PlayerData.items or {}
    local normalizedWeaponName = normalizeWeaponName(weaponName)
    local slot = tonumber(requestedSlot)

    if slot then
        local itemKey = items[slot] and slot or tostring(slot)
        local item = items[itemKey]
        if not item or normalizeWeaponName(item.name) ~= normalizedWeaponName then
            return nil, nil
        end
        return item, itemKey
    end

    local foundItem = nil
    local foundSlot = nil
    local matchCount = 0
    for itemSlot, item in pairs(items) do
        if item and normalizeWeaponName(item.name) == normalizedWeaponName then
            matchCount = matchCount + 1
            foundItem = item
            foundSlot = itemSlot
        end
    end

    if matchCount == 1 then
        return foundItem, foundSlot
    end

    return nil, nil
end


local function hasAttachment(attachments, component)
    local wantedKey = componentKey(component)
    if not wantedKey then return false end

    for _, attachment in ipairs(attachments or {}) do
        if componentKey(attachment.component) == wantedKey then
            return true
        end
    end
    return false
end


local function removeAttachment(attachments, component)
    local wantedKey = componentKey(component)
    if not wantedKey then return end

    for index = #attachments, 1, -1 do
        if componentKey(attachments[index].component) == wantedKey then
            table.remove(attachments, index)
        end
    end
end


local function removeManagedSkinAttachments(attachments, weaponName)
    local managedComponentKeys = {}
    local normalizedWeaponName = normalizeWeaponName(weaponName)
    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        local configuredWeapon = normalizeWeaponName(skin.weapon)
        if getSkinMode(skin) == "component"
            and (not configuredWeapon or configuredWeapon == normalizedWeaponName) then
            local key = componentKey(skin.component)
            if key then managedComponentKeys[key] = true end
        end
    end

    for index = #attachments, 1, -1 do
        local attachment = attachments[index]
        if type(attachment) == "table" then
            local isManagedSkin = attachment.type == "weapon_skin" or attachment.skin ~= nil
            local isLegacyManagedFinish = attachment.type == "finish"
                and managedComponentKeys[componentKey(attachment.component) or ""] == true
            if isManagedSkin or isLegacyManagedFinish then
                table.remove(attachments, index)
            end
        end
    end
end


local function copyWeaponInfo(originalInfo)
    local copiedInfo = {}
    if type(originalInfo) == "table" then
        for key, value in pairs(originalInfo) do
            copiedInfo[key] = value
        end
    end

    copiedInfo.attachments = {}
    local originalAttachments = type(originalInfo) == "table" and originalInfo.attachments or nil
    for index, attachment in ipairs(type(originalAttachments) == "table" and originalAttachments or {}) do
        copiedInfo.attachments[index] = attachment
    end

    return copiedInfo
end


-- v1.2.0 component hash'lerini sayı olarak kaydediyordu. qb-weapons yeniden
-- kuşanırken joaat(attachment.component) çağırdığı için burada bunları tekrar
-- kanonik component adına çeviriyoruz.
local function migratePlayerWeaponComponents(Player)
    if not Player or type(Player.PlayerData) ~= "table" then return false end

    local items = Player.PlayerData.items or {}
    local changed = false

    for _, item in pairs(items) do
        local weaponName = item and normalizeWeaponName(item.name)
        local weaponConfig = weaponName and Config.Weapons[weaponName]
        local info = item and type(item.info) == "table" and item.info or nil
        local attachments = info and type(info.attachments) == "table" and info.attachments or nil

        if weaponConfig and attachments then
            local canonicalNames = {}
            for _, definition in pairs(weaponConfig.attachments or {}) do
                local key = componentKey(definition.component)
                if key and definition.componentName then
                    canonicalNames[key] = definition.componentName
                end
            end
            for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
                local configuredWeapon = normalizeWeaponName(skin.weapon)
                if getSkinMode(skin) == "component"
                    and (not configuredWeapon or configuredWeapon == weaponName)
                    and type(skin.component) == "string" then
                    local key = componentKey(skin.component)
                    if key then canonicalNames[key] = skin.component end
                end
            end

            for _, attachment in ipairs(attachments) do
                if type(attachment) == "table" and type(attachment.component) == "number" then
                    local componentName = canonicalNames[componentKey(attachment.component) or ""]
                    if componentName then
                        attachment.component = componentName
                        changed = true
                    end
                end
            end
        end
    end

    if changed then
        Player.Functions.SetPlayerData("items", items)
    end
    return changed
end


AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    migratePlayerWeaponComponents(Player)
end)


CreateThread(function()
    Wait(1000)
    for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
        migratePlayerWeaponComponents(Player)
    end
end)

-- Veritabanı Tablolarını Otomatik Oluşturma ve Kolon Ekleme
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_weapon_skins` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `pattern_id` VARCHAR(50) NOT NULL,
            `primary_color` VARCHAR(20) NOT NULL,
            `secondary_color` VARCHAR(20) NOT NULL,
            `img_url` TEXT DEFAULT NULL,
            `scale` FLOAT DEFAULT 1.0,
            `opacity` FLOAT DEFAULT 1.0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_unlocked_skins` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `skin_id` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `citizenid_skin` (`citizenid`, `skin_id`)
        );
    ]])
    
    -- img_url kolonu yoksa otomatik ekle
    MySQL.query("ALTER TABLE `player_weapon_skins` ADD COLUMN IF NOT EXISTS `img_url` TEXT DEFAULT NULL;")
end)

-- Oyuncunun Steam Hex ID'sini al
local function getPlayerSteamHex(source)
    local src = tonumber(source)
    if not src then return nil end
    local steam = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'steam')
    if steam then return steam:lower() end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 6) == "steam:" then
            return id:lower()
        end
    end
    return nil
end

-- Oyuncunun Rockstar License ID'sini al
local function getPlayerLicense(source)
    local src = tonumber(source)
    if not src then return nil end
    local license = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license')
    if license then return license:lower() end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == "license:" then
            return id:lower()
        end
    end
    return nil
end

-- Oyuncunun bir skin kilidini açıp açmadığını doğrulayan sunucu kontrolü (SteamHex & CitizenID)
local function isSkinUnlockedForPlayer(source, skinId)
    local normalizedSkinId = normalizeSkinId(skinId)
    if not normalizedSkinId then return true end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local skinDef = getSkinDefinition(normalizedSkinId)
    if not skinDef or not skinDef.isLocked then
        return true -- Varsayılan kilitli değilse her oyuncuya açıktır
    end

    local citizenid = (Player.PlayerData and Player.PlayerData.citizenid or ""):lower()
    local steamHex = (getPlayerSteamHex(source) or ""):lower()
    local rawSteam = steamHex ~= "" and steamHex:gsub("steam:", "") or ""
    local license = (getPlayerLicense(source) or ""):lower()

    -- DB'de Steam Hex ID, raw Steam Hex, CitizenID veya License var mı? (İndeks dostu IN sorgusu)
    local result = MySQL.scalar.await([[
        SELECT COUNT(*) FROM player_unlocked_skins 
        WHERE skin_id = ? AND citizenid IN (?, ?, ?, ?)
    ]], {
        normalizedSkinId,
        citizenid,
        steamHex,
        rawSteam,
        license
    })

    if result and result > 0 then
        return true
    end

    -- Opsiyonel eşya kontrolü (skin.requiredItem)
    if skinDef.requiredItem then
        local item = Player.Functions.GetItemByName(skinDef.requiredItem)
        if item and item.amount > 0 then
            return true
        end
    end

    return false
end

-- Oyuncunun kilit açtığı skinleri liste olarak çeken yardımcı fonksiyon
local function fetchPlayerUnlockedSkins(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local citizenid = (Player.PlayerData and Player.PlayerData.citizenid or ""):lower()
    local steamHex = (getPlayerSteamHex(source) or ""):lower()
    local rawSteam = steamHex ~= "" and steamHex:gsub("steam:", "") or ""
    local license = (getPlayerLicense(source) or ""):lower()

    local unlockedMap = {}

    local rows = MySQL.query.await([[
        SELECT skin_id FROM player_unlocked_skins 
        WHERE citizenid IN (?, ?, ?, ?)
    ]], { citizenid, steamHex, rawSteam, license })

    if rows then
        for _, row in ipairs(rows) do
            unlockedMap[row.skin_id] = true
        end
    end

    -- Config'deki eşya (requiredItem) kontrolleri
    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        local skinId = normalizeSkinId(skin.id)
        if skinId and skin.isLocked then
            if skin.requiredItem then
                local item = Player.Functions.GetItemByName(skin.requiredItem)
                if item and item.amount > 0 then
                    unlockedMap[skinId] = true
                end
            end
        end
    end

    return unlockedMap
end

-- Oyuncunun Kilitli Açtığı Skin Listesini Getiren Callback
QBCore.Functions.CreateCallback('vater-silahci:server:getUserUnlockedSkins', function(source, cb)
    cb(fetchPlayerUnlockedSkins(source))
end)

-- Oyuncunun Kayıtlı Desenlerini Getirme Callback'i
QBCore.Functions.CreateCallback('vater-silahci:server:getPlayerSkins', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    MySQL.query('SELECT * FROM player_weapon_skins WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(result)
        if result and #result > 0 then
            local skins = {}
            for _, row in ipairs(result) do
                table.insert(skins, {
                    id = row.id,
                    name = row.name,
                    patternId = row.pattern_id,
                    primaryColor = row.primary_color,
                    secondaryColor = row.secondary_color,
                    imgUrl = row.img_url,
                    scale = row.scale or 1.0,
                    opacity = row.opacity or 1.0
                })
            end
            cb(skins)
        else
            cb({})
        end
    end)
end)

-- Özel GIF / Desen Kaydetme Callback'i
QBCore.Functions.CreateCallback('vater-silahci:server:saveCustomSkinPattern', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not data then return cb(false) end

    local citizenid = Player.PlayerData.citizenid
    local skinName = data.name or "Özel GIF Kaplama"
    local patternId = data.patternId or "custom_gif"
    local primaryColor = data.primaryColor or "#eab308"
    local secondaryColor = data.secondaryColor or "#111111"
    local imgUrl = data.imgUrl or nil
    local scale = tonumber(data.scale) or 1.0
    local opacity = tonumber(data.opacity) or 1.0

    MySQL.insert('INSERT INTO player_weapon_skins (citizenid, name, pattern_id, primary_color, secondary_color, img_url, scale, opacity) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    { citizenid, skinName, patternId, primaryColor, secondaryColor, imgUrl, scale, opacity }, function(id)
        if id then
            -- Güncellenmiş listeyi geri döndür
            MySQL.query('SELECT * FROM player_weapon_skins WHERE citizenid = ?', { citizenid }, function(result)
                local skins = {}
                if result then
                    for _, row in ipairs(result) do
                        table.insert(skins, {
                            id = row.id,
                            name = row.name,
                            patternId = row.pattern_id,
                            primaryColor = row.primary_color,
                            secondaryColor = row.secondary_color,
                            imgUrl = row.img_url,
                            scale = row.scale or 1.0,
                            opacity = row.opacity or 1.0
                        })
                    end
                end
                cb(true, skins)
            end)
        else
            cb(false)
        end
    end)
end)

-- Silah Modifikasyonu Kaydetme ve Envanter Metadasını Güncelleme Callback'i
QBCore.Functions.CreateCallback('vater-silahci:server:saveWeaponMods', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or type(data) ~= "table" then return cb(false, "Geçersiz veri!") end

    local weaponName = normalizeWeaponName(data.weaponName)
    local weaponConfig = weaponName and Config.Weapons[weaponName]
    if not weaponName or not weaponConfig then
        return cb(false, "Bu silah modifiye listesinde bulunmuyor.")
    end

    local weaponItem, itemSlot = findWeaponItem(Player, weaponName, data.inventorySlot)
    if not weaponItem or not itemSlot then
        return cb(false, "Aktif silah slotu bulunamadı veya aynı silahtan birden fazla var; ödeme alınmadı.")
    end
    local itemInfo = type(weaponItem.info) == "table" and weaponItem.info or {}
    local actualSerial = itemInfo.serial or itemInfo.serie
    local requestedSerial = data.inventorySerial
    if actualSerial ~= nil then
        if requestedSerial == nil or tostring(requestedSerial) ~= tostring(actualSerial) then
            return cb(false, "Silah seri numarası/slot eşleşmesi değişti; ödeme alınmadı.")
        end
    elseif requestedSerial ~= nil and tostring(requestedSerial) ~= "" then
        return cb(false, "Silah seri numarası doğrulanamadı; ödeme alınmadı.")
    end

    local requestedSkinId = normalizeSkinId(data.customSkin)
    local requestedSkin = requestedSkinId and getSkinDefinition(requestedSkinId, weaponName) or nil
    if requestedSkinId and not requestedSkin then
        return cb(false, "Geçersiz veya bu silahla uyumsuz skin seçildi.")
    end

    -- KİLİTLİ / PAID SKIN SUNUCU KONTROLÜ
    if requestedSkinId and requestedSkin and requestedSkin.isLocked then
        if not isSkinUnlockedForPlayer(source, requestedSkinId) then
            return cb(false, "🔒 '" .. (requestedSkin.label or requestedSkinId) .. "' kaplaması kilitlidir! Kullanabilmek için Mağazadan/VIP satın almalısınız.")
        end
    end
    local requestedSkinMode = requestedSkin and getSkinMode(requestedSkin) or nil
    if requestedSkinMode
        and requestedSkinMode ~= "component"
        and requestedSkinMode ~= "texture"
        and requestedSkinMode ~= "runtime" then
        return cb(false, "Skin modu geçersiz; ödeme alınmadı.")
    end
    local requestedSkinComponent = nil
    if requestedSkinMode == "component" then
        requestedSkinComponent = resolveComponentHash(requestedSkin.component)
        if not requestedSkinComponent then
            return cb(false, "Skin component tanımı geçersiz; ödeme alınmadı.")
        end
    end

    local requestedTint = tonumber(data.tint)
    if requestedTint == nil then requestedTint = 0 end
    requestedTint = math.floor(requestedTint)
    if requestedTint < 0 or requestedTint > 7 then
        return cb(false, "Geçersiz silah rengi seçildi.")
    end

    local info = copyWeaponInfo(itemInfo)
    removeManagedSkinAttachments(info.attachments, weaponName)
    local currentSkinId = normalizeSkinId(info.skin)
    local currentTint = tonumber(info.tint) or 0
    local totalPrice = 0

    -- Yalnızca yeni takılan eklentiler ücretlendirilir; mevcut parçalar tekrar sayılmaz.
    if type(data.components) ~= "table" then
        return cb(false, "Eklenti listesi eksik; mevcut parçalar korunarak işlem iptal edildi.")
    end
    local requestedComponents = data.components
    for attachmentKey in pairs(weaponConfig.attachments or {}) do
        if type(requestedComponents[attachmentKey]) ~= "boolean" then
            return cb(false, ("Eklenti durumu eksik: %s"):format(attachmentKey))
        end
    end
    for attachmentKey, attachment in pairs(weaponConfig.attachments or {}) do
        local wantsAttachment = requestedComponents[attachmentKey] == true
        local alreadyHasAttachment = hasAttachment(info.attachments, attachment.component)

        if wantsAttachment and not alreadyHasAttachment then
            totalPrice = totalPrice + (tonumber(Config.Prices.attachment) or 0)
        end
    end

    if requestedTint ~= currentTint then
        totalPrice = totalPrice + (tonumber(Config.Prices.tint) or 0)
    end
    if requestedSkinId and requestedSkinId ~= currentSkinId then
        totalPrice = totalPrice + (tonumber(Config.Prices.customSkin) or 0)
    end

    local paymentAccount = nil
    if totalPrice > 0 then
        local cash = tonumber(Player.PlayerData.money.cash) or 0
        local bank = tonumber(Player.PlayerData.money.bank) or 0
        local paymentResult = nil
        if cash >= totalPrice then
            paymentAccount = "cash"
            paymentResult = Player.Functions.RemoveMoney('cash', totalPrice, "silah-modifiye")
        elseif bank >= totalPrice then
            paymentAccount = "bank"
            paymentResult = Player.Functions.RemoveMoney('bank', totalPrice, "silah-modifiye")
        else
            return cb(false, "Yetersiz bakiye! Gereken: $" .. totalPrice)
        end
        if paymentResult == false then
            return cb(false, "Ödeme alınamadı; silah değiştirilmedi.")
        end
    end

    -- Whitelist dışındaki component anahtarları yok sayılır.
    for attachmentKey, attachment in pairs(weaponConfig.attachments or {}) do
        if requestedComponents[attachmentKey] == true then
            if not hasAttachment(info.attachments, attachment.component) then
                info.attachments[#info.attachments + 1] = {
                    component = attachment.componentName or attachment.component,
                    label = attachment.label,
                    type = attachmentKey
                }
            end
        else
            removeAttachment(info.attachments, attachment.component)
        end
    end

    -- Yönetilen skin component'lerinden yalnızca seçilen skin kalır.
    if requestedSkinComponent then
        info.attachments[#info.attachments + 1] = {
            component = type(requestedSkin.component) == "string"
                and requestedSkin.component or requestedSkinComponent,
            label = requestedSkin.label or requestedSkin.id,
            type = "weapon_skin",
            skin = requestedSkinId
        }
    end

    info.tint = requestedTint
    info.skin = requestedSkinId -- nil olduğunda eski skin metadata'sı gerçekten temizlenir.

    local originalInfo = weaponItem.info
    local commitOk, commitError = pcall(function()
        Player.PlayerData.items[itemSlot].info = info
        Player.Functions.SetPlayerData("items", Player.PlayerData.items)
    end)
    if not commitOk then
        if Player.PlayerData.items[itemSlot] then
            Player.PlayerData.items[itemSlot].info = originalInfo
        end
        if paymentAccount and totalPrice > 0 then
            Player.Functions.AddMoney(paymentAccount, totalPrice, "silah-modifiye-iade")
        end
        print(("[vater-silahci] Envanter kaydı başarısız (%s): %s"):format(source, tostring(commitError)))
        return cb(false, "Envanter kaydı başarısız oldu; alınan ücret iade edildi.")
    end

    cb(true, "Silah modifikasyonu uygulandı! Ücret: $" .. totalPrice, requestedSkinId or "")
end)

-- Eski UI sürümleri için geriye dönük callback. Dosya sistemi taranmaz; config whitelist'i döner.
QBCore.Functions.CreateCallback('vater-silahci:server:getStreamFolders', function(source, cb)
    local skinIds = {}
    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        if skin.id then
            skinIds[#skinIds + 1] = skin.id
        end
    end
    cb(skinIds)
end)

-- ============================================================================
-- ADMİN KOMUTLARI & SERVER EXPORTLARI (GERÇEK PARA / STEAMHEX ENTEGRASYONU)
-- ============================================================================

-- Oyuncunun SteamHex, Oyuncu ID veya CitizenID'sine özel silah kaplamasının kilidini açma komutu
QBCore.Commands.Add('unlockskin', 'Oyuncuya SteamHex / ID / CitizenID ile kilitli silah kaplamasını açar', {
    { name = 'target', help = 'Oyuncu ID (ör: 1), SteamHex (ör: steam:11000...) veya CitizenID' },
    { name = 'skin', help = 'Kaplama ID (ör. galaxym4, diamondak)' }
}, true, function(source, args)
    local targetInput = args[1]
    local skinId = normalizeSkinId(args[2])

    if not targetInput or not skinId then
        TriggerClientEvent('QBCore:Notify', source, 'Kullanım: /unlockskin [ID / SteamHex / CitizenID] [skin_id]', 'error')
        return
    end

    local skinDef = getSkinDefinition(skinId)
    local skinLabel = (skinDef and skinDef.label) or skinId
    local targetIdentifier = targetInput:lower()
    local targetSource = nil
    local targetCitizenId = nil

    -- 1. Oyuncu ID (online) ile deneme
    local targetPlayer = tonumber(targetInput) and QBCore.Functions.GetPlayer(tonumber(targetInput))
    if targetPlayer then
        targetSource = targetPlayer.PlayerData.source
        targetCitizenId = targetPlayer.PlayerData.citizenid
        targetIdentifier = getPlayerSteamHex(targetSource) or targetCitizenId or targetInput:lower()
    else
        -- 2. CitizenID ile online oyuncu kontrolü
        local onlinePlayer = QBCore.Functions.GetPlayerByCitizenId(targetInput)
        if onlinePlayer then
            targetSource = onlinePlayer.PlayerData.source
            targetCitizenId = onlinePlayer.PlayerData.citizenid
            targetIdentifier = getPlayerSteamHex(targetSource) or targetCitizenId
        end
    end

    MySQL.insert('INSERT INTO player_unlocked_skins (citizenid, skin_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin_id = skin_id', {
        targetIdentifier, skinId
    }, function(id)
        if targetCitizenId and targetCitizenId ~= targetIdentifier then
            MySQL.insert('INSERT INTO player_unlocked_skins (citizenid, skin_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin_id = skin_id', {
                targetCitizenId, skinId
            })
        end

        if targetSource then
            local updatedUnlockedMap = fetchPlayerUnlockedSkins(targetSource)
            TriggerClientEvent('vater-silahci:client:updateUnlockedSkins', targetSource, updatedUnlockedMap)
            TriggerClientEvent('QBCore:Notify', targetSource, "🔒 '" .. skinLabel .. "' silah kaplamasının kilidi açıldı!", "success")
        end
        TriggerClientEvent('QBCore:Notify', source, ("%s için '%s' kilidi başarıyla açıldı."):format(targetIdentifier, skinLabel), "success")
    end)
end, 'admin')

-- Oyuncunun silah kaplaması kilidini kaldırma / yeniden kilitleme komutu
QBCore.Commands.Add('lockskin', 'Oyuncudan kilitli silah kaplaması kilidini kaldırır', {
    { name = 'target', help = 'Oyuncu ID, SteamHex veya CitizenID' },
    { name = 'skin', help = 'Kaplama ID' }
}, true, function(source, args)
    local targetInput = args[1]
    local skinId = normalizeSkinId(args[2])

    if not targetInput or not skinId then
        TriggerClientEvent('QBCore:Notify', source, 'Kullanım: /lockskin [ID / SteamHex / CitizenID] [skin_id]', 'error')
        return
    end

    local skinDef = getSkinDefinition(skinId)
    local skinLabel = (skinDef and skinDef.label) or skinId

    local targetPlayer = tonumber(targetInput) and QBCore.Functions.GetPlayer(tonumber(targetInput))
    local targetIdentifier = targetInput:lower()
    local targetSource = nil
    local targetCitizenId = nil

    if targetPlayer then
        targetSource = targetPlayer.PlayerData.source
        targetCitizenId = targetPlayer.PlayerData.citizenid
        targetIdentifier = getPlayerSteamHex(targetSource) or targetCitizenId
    else
        local onlinePlayer = QBCore.Functions.GetPlayerByCitizenId(targetInput)
        if onlinePlayer then
            targetSource = onlinePlayer.PlayerData.source
            targetCitizenId = onlinePlayer.PlayerData.citizenid
        end
    end

    local steamHex = targetSource and getPlayerSteamHex(targetSource) or nil
    local rawSteam = steamHex and steamHex:gsub("steam:", "") or nil

    MySQL.query([[
        DELETE FROM player_unlocked_skins 
        WHERE skin_id = ? AND (
            LOWER(citizenid) = LOWER(?) OR 
            LOWER(citizenid) = LOWER(?) OR 
            LOWER(citizenid) = LOWER(?) OR 
            LOWER(citizenid) = LOWER(?)
        )
    ]], {
        skinId,
        targetInput:lower(),
        targetCitizenId or "",
        steamHex or "",
        rawSteam or ""
    }, function()
        if targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.items then
            local items = targetPlayer.PlayerData.items
            local updated = false
            for itemSlot, item in pairs(items) do
                if item and type(item.info) == "table" and item.info.skin then
                    if normalizeSkinId(item.info.skin) == skinId then
                        item.info.skin = nil
                        updated = true
                    end
                end
            end
            if updated then
                targetPlayer.Functions.SetPlayerData("items", items)
            end
        end

        if targetSource then
            local updatedUnlockedMap = fetchPlayerUnlockedSkins(targetSource)
            TriggerClientEvent('vater-silahci:client:updateUnlockedSkins', targetSource, updatedUnlockedMap)
            TriggerClientEvent('QBCore:Notify', targetSource, "🔒 '" .. skinLabel .. "' kaplamanız yeniden kilitlendi ve silahtan kaldırıldı.", "error")
        end
        TriggerClientEvent('QBCore:Notify', source, ("%s için '%s' kaplaması başarıyla kilitlendi."):format(targetInput, skinLabel), "primary")
    end)
end, 'admin')

-- Dış Kaynak / Tebex Exportları
exports('UnlockSkin', function(identifier, skinId)
    local normalized = normalizeSkinId(skinId)
    if not identifier or not normalized then return false end
    MySQL.insert('INSERT INTO player_unlocked_skins (citizenid, skin_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin_id = skin_id', { identifier:lower(), normalized })
    return true
end)

exports('LockSkin', function(identifier, skinId)
    local normalized = normalizeSkinId(skinId)
    if not identifier or not normalized then return false end
    MySQL.query('DELETE FROM player_unlocked_skins WHERE LOWER(citizenid) = LOWER(?) AND skin_id = ?', { identifier:lower(), normalized })
    return true
end)

exports('HasUnlockedSkin', function(source, skinId)
    return isSkinUnlockedForPlayer(source, skinId)
end)
