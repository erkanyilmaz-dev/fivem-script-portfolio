-- =====================================================================
--   VaterPVP Inventory - server.lua  (QB-Core Compatible)
--   v3.0 — Drag&Drop düzeltmesi + Yere bırak/Al/Böl desteği
-- =====================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Yerdeki eşyaları tutmak için basit in-memory tablo
-- Her kayıt: { id, name, label, amount, weight, coords }
local groundItems = {}
local groundIdCounter = 0
local MaxGroundItemDistance = 3.0 -- Yerdeki eşyaları görme ve alma mesafesi (metre)

local function newGroundId()
    groundIdCounter = groundIdCounter + 1
    return groundIdCounter
end

-- Bir oyuncunun yakınındaki yerdeki eşyaları döner
local function GetNearbyGroundItems(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end
    local ped    = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local nearby = {}
    for _, gitem in pairs(groundItems) do
        local dist = #(coords - vector3(gitem.coords.x, gitem.coords.y, gitem.coords.z))
        if dist <= MaxGroundItemDistance then
            nearby[#nearby + 1] = gitem
        end
    end
    return nearby
end

local function RefreshClient(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Save to database immediately
    if GetResourceState('qb-inventory') == 'started' then
        pcall(function() exports['qb-inventory']:SaveInventory(src) end)
    end

    local items  = Player.PlayerData.items or {}
    local weight = 0.0
    for _, item in pairs(items) do
        if item and item.weight and item.amount then
            weight = weight + (item.weight * item.amount)
        end
    end
    local nearby = GetNearbyGroundItems(src)
    TriggerClientEvent('vaterpvp:inventory:refreshClient', src, items, weight, nearby)
end

-- ── Eşyayı Kullan ─────────────────────────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:useItem', function(itemName, slot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    print(('^5[vaterpvp-inventory] useItem called: item=%s slot=%s src=%s^7'):format(tostring(itemName), tostring(slot), tostring(src)))

    -- Eşyayı bul
    local item = nil
    if slot then
        item = Player.Functions.GetItemBySlot(slot)
    end
    if not item or item.name ~= itemName then
        item = Player.Functions.GetItemByName(itemName)
    end

    if not item then
        print(('^1[vaterpvp-inventory] Item NOT found: %s^7'):format(tostring(itemName)))
        TriggerClientEvent('QBCore:Notify', src, 'Bu eşya envanterinde yok.', 'error')
        return
    end

    print(('^2[vaterpvp-inventory] Item found: %s (type=%s)^7'):format(item.name, tostring(item.type)))

    local name = item.name

    -- ── Silah mı? (type == 'weapon' veya isim weapon_ ile başlıyor) ──
    if item.type == 'weapon' or name:sub(1, 7) == 'weapon_' then
        -- item.info tablosunun var ve tam olduğundan emin ol (yoksa qb-weapons çöker)
        if not item.info then item.info = {} end
        if not item.info.ammo then item.info.ammo = 250 end
        if not item.info.serie then item.info.serie = tostring(QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(1) .. QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(4)) end
        if item.info.quality == nil then item.info.quality = 100 end
        if not item.info.attachments then item.info.attachments = {} end

        -- qb-weapons eklentisinin standart silah kuşanma event'ini kullan
        local shootbool = item.info.quality and item.info.quality > 0 or false
        TriggerClientEvent('qb-weapons:client:UseWeapon', src, item, shootbool)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[name], 'use')
        print(('^2[vaterpvp-inventory] Weapon → qb-weapons:client:UseWeapon: %s (ammo=%s)^7'):format(name, tostring(item.info.ammo)))
        return
    end

    -- ── Armor? → vater-zirh eklentisine yönlendir ──
    if name == 'armor' then
        TriggerClientEvent('vater-zirh:client:UseArmor', src)
        print(('^2[vaterpvp-inventory] Armor → vater-zirh:client:UseArmor^7'))
        return
    end

    if name == 'heavyarmor' then
        TriggerClientEvent('vater-zirh:client:UseHeavyArmor', src)
        print(('^2[vaterpvp-inventory] Heavy Armor → vater-zirh:client:UseHeavyArmor^7'))
        return
    end

    -- ── Medkit? → Aşamalı kullan ──
    if name == 'medkit' then
        TriggerClientEvent('vater-inventory:client:UseMedkit', src)
        return
    end

    -- ── Diğer useable eşyalar → QBCore callback zincirini dene ──
    local canUse = QBCore.Functions.CanUseItem(name)
    if canUse then
        print(('^2[vaterpvp-inventory] Using QBCore callback for: %s^7'):format(name))
        if type(canUse) == 'table' and canUse.func then
            canUse.func(src, item)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, (item.label or name) .. ' kullanıldı.', 'success')
    end
end)

-- ── Slot Taşı (Drag & Drop) ───────────────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:moveItem', function(fromSlot, toSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    fromSlot = tonumber(fromSlot)
    toSlot   = tonumber(toSlot)
    if not fromSlot or not toSlot or fromSlot == toSlot then return end

    local items = Player.PlayerData.items
    if not items then return end

    -- Check both string and number keys
    local fromKey = items[fromSlot] and fromSlot or tostring(fromSlot)
    local toKey = items[toSlot] and toSlot or tostring(toSlot)

    local fromItem = items[fromKey]
    local toItem   = items[toKey]

    if not fromItem then return end

    if toItem then
        -- Aynı isimde unique olmayan eşyayı birleştir
        if fromItem.name == toItem.name and not fromItem.unique then
            toItem.amount = toItem.amount + fromItem.amount
            items[fromKey] = nil
        else
            -- Swap
            items[fromKey] = toItem
            items[toKey]   = fromItem
            items[fromKey].slot = tonumber(fromKey)
            items[toKey].slot   = tonumber(toKey)
        end
    else
        -- Boş slota taşı
        items[toKey]   = fromItem
        items[fromKey] = nil
        items[toKey].slot = tonumber(toKey)
    end

    -- qb-inventory SetInventory (Player.Functions olarak eklenmemiş olabilir, doğrudan export kullan)
    local ok, err = pcall(function() exports['qb-inventory']:SetInventory(src, items) end)
    if not ok then
        print(('^1[vaterpvp-inventory] SetInventory failed: %s^7'):format(tostring(err)))
        -- Fallback: doğrudan PlayerData'ya yaz
        Player.PlayerData.items = items
        Player.Functions.SetPlayerData('items', items)
    end
    Wait(100)
    RefreshClient(src)
end)


-- ── Envanter Açıldığında Refresh Et ────────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:openInventory', function()
    local src = source
    RefreshClient(src)
end)

-- ── Eşyayı Yere Bırak ────────────────────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:dropItem', function(itemName, slot, amount)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    amount = tonumber(amount) or 1
    slot   = tonumber(slot)

    local item = Player.Functions.GetItemBySlot(slot)
    if not item or item.name ~= itemName then
        TriggerClientEvent('QBCore:Notify', src, 'Geçersiz eşya.', 'error')
        return
    end

    amount = math.min(amount, item.amount)

    local removed = Player.Functions.RemoveItem(itemName, amount, slot)
    if removed then
        local ped    = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local gid    = newGroundId()
        groundItems[gid] = {
            id     = gid,
            slot   = gid,
            name   = item.name,
            label  = item.label,
            amount = amount,
            weight = item.weight,
            info   = item.info,
            coords = { x = coords.x, y = coords.y, z = coords.z },
        }
        TriggerClientEvent('QBCore:Notify', src, item.label .. ' (' .. amount .. 'x) yere bırakıldı.', 'primary')
        -- Yakındakilere de bildir
        RefreshClient(src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Eşya bırakılamadı.', 'error')
    end
end)

-- ── Yerdeki Eşyayı Al ────────────────────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:pickupItem', function(groundIndex, toSlot, amount)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    groundIndex = tonumber(groundIndex)
    amount      = tonumber(amount) or 1
    local gitem = groundItems[groundIndex]
    if not gitem then
        TriggerClientEvent('QBCore:Notify', src, 'Bu eşya artık yerde yok.', 'error')
        return
    end

    -- Mesafe kontrolü
    local ped    = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local dist   = #(coords - vector3(gitem.coords.x, gitem.coords.y, gitem.coords.z))
    if dist > MaxGroundItemDistance then
        TriggerClientEvent('QBCore:Notify', src, 'Eşyaya çok uzaksın.', 'error')
        return
    end

    amount = math.min(amount, gitem.amount)

    local toSlotNum = toSlot and tonumber(toSlot)
    local items = Player.PlayerData.items
    if toSlotNum then
        local toSlotKey = items[toSlotNum] and toSlotNum or tostring(toSlotNum)
        if items[toSlotKey] then
            if items[toSlotKey].name ~= gitem.name or items[toSlotKey].unique then
                toSlotNum = nil
            end
        end
    end

    local added = Player.Functions.AddItem(gitem.name, amount, toSlotNum, gitem.info)
    if added then
        if amount >= gitem.amount then
            groundItems[groundIndex] = nil
        else
            groundItems[groundIndex].amount = gitem.amount - amount
        end
        TriggerClientEvent('QBCore:Notify', src, gitem.label .. ' (' .. amount .. 'x) alındı.', 'success')
        RefreshClient(src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Envanter dolu.', 'error')
    end
end)

-- ── Eşyayı Böl ───────────────────────────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:splitItem', function(itemName, slot, amount)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    slot   = tonumber(slot)
    amount = tonumber(amount) or 1

    local item = Player.Functions.GetItemBySlot(slot)
    if not item or item.name ~= itemName or item.amount <= 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Eşya bölünemez.', 'error')
        return
    end

    amount = math.min(amount, item.amount - 1)

    -- Orijinal slotu azalt
    Player.Functions.RemoveItem(itemName, amount, slot)
    -- Boş slota ekle (nil = otomatik slot)
    Player.Functions.AddItem(itemName, amount, nil, item.info)

    TriggerClientEvent('QBCore:Notify', src, item.label .. ' bölündü.', 'success')
    RefreshClient(src)
end)

-- ── Server → Client envanter güncelle ────────────────────────────────
RegisterNetEvent('vaterpvp:inventory:refreshClient', function()
    local src = source
    RefreshClient(src)
end)

-- ── QB-Core PlayerData sync ───────────────────────────────────────────
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    Wait(1000)
    RefreshClient(src)
end)

-- ── QB-Core Useable Items ─────────────────────────────────────────────

QBCore.Functions.CreateUseableItem('medkit', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    TriggerClientEvent('vater-inventory:client:UseMedkit', source)
end)

RegisterNetEvent('vater-inventory:server:UseMedkit', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem('medkit', 1) then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['medkit'], 'remove', 1)
        TriggerClientEvent('QBCore:Notify', src, 'Medkit kullandın, can yenilendi.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Medkitiniz yok!', 'error')
    end
end)

--[[
QBCore.Functions.CreateUseableItem('armor', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if Player.Functions.RemoveItem('armor', 1) then
        TriggerClientEvent('vaterpvp:inventory:useEffect', source, 'armor')
        TriggerClientEvent('QBCore:Notify', source, 'Zırh giydin.', 'success')
    end
end)
--]]

QBCore.Functions.CreateUseableItem('weapon_pistol', function(source, item)
    TriggerClientEvent('vaterpvp:inventory:useEffect', source, 'weapon_pistol')
end)

QBCore.Functions.CreateUseableItem('weapon_tec9', function(source, item)
    TriggerClientEvent('vaterpvp:inventory:useEffect', source, 'weapon_tec9')
end)

print('^2[VaterPVP-Inventory] Server v3.0 yüklendi.^7')
