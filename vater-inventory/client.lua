-- =====================================================================
--   VaterPVP Inventory - client.lua  (QB-Core Compatible)
--   v3.0 — Drag&Drop, Ground Panel, Böl desteği
-- =====================================================================

local QBCore = exports['qb-core']:GetCoreObject()

local isOpen        = false
local playerItems   = {}
local groundItems   = {}
local playerWeight  = 0.0
local maxWeight     = 1000000.0
local maxSlots      = 41
local hotbarSlots   = 5

-- ── Payload ───────────────────────────────────────────────────────────
local function BuildPayload()
    return {
        items       = playerItems,
        groundItems = groundItems,
        weight      = playerWeight,
        maxWeight   = maxWeight,
        maxSlots    = maxSlots,
        hotbar      = hotbarSlots,
    }
end

-- ── UI Aç / Kapat ─────────────────────────────────────────────────────
local function SendOpen()
    SendNUIMessage({ action = 'openInventory', data = BuildPayload() })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    DisplayRadar(false)
    isOpen = true
end

local function SendClose()
    SendNUIMessage({ action = 'closeInventory' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
    isOpen = false

    -- ESC girdisinin oyuna gecip pause menüsünü acmasını engellemek icin kısa sureli thread
    CreateThread(function()
        local start = GetGameTimer()
        while GetGameTimer() - start < 300 do
            Wait(0)
            DisableControlAction(0, 200, true) -- ESC (Pause Menu)
            DisableControlAction(0, 199, true) -- ESC (Pause Menu Alt)
        end
    end)
end

-- ── Envanteri QB-Core'dan Yükle ──────────────────────────────────────
local function LoadInventory()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return end

    playerItems  = PlayerData.items or {}
    playerWeight = 0.0

    for _, item in pairs(playerItems) do
        if item and item.weight and item.amount then
            playerWeight = playerWeight + (item.weight * item.amount)
        end
    end
end

-- ── Key Binding (F2 & TAB) ────────────────────────────────────────────
RegisterKeyMapping('vater_inventory_open', 'WraithPVP - Envanter Aç', 'keyboard', 'F2')

RegisterCommand('vater_inventory_open', function()
    if isOpen then
        SendClose()
    else
        LoadInventory()
        SendOpen()
        TriggerServerEvent('vaterpvp:inventory:openInventory')
    end
end, false)

RegisterKeyMapping('vater_inventory_hotbar', 'WraithPVP - Hotbar Göster', 'keyboard', 'TAB')

RegisterCommand('vater_inventory_hotbar', function()
    if isOpen then return end
    if IsPauseMenuActive() then return end
    LoadInventory()
    
    local hotbarItems = {}
    for _, item in pairs(playerItems) do
        local slotNum = tonumber(item.slot)
        if item and slotNum and slotNum >= 1 and slotNum <= 5 then
            hotbarItems[tostring(slotNum)] = item
        end
    end

    SendNUIMessage({
        action = 'showHUDHotbar',
        items = hotbarItems
    })
end, false)

-- ── NUI Callbacks ─────────────────────────────────────────────────────

RegisterNUICallback('closeInventory', function(_, cb)
    SendClose()
    cb('ok')
end)

-- Eşyayı Kullan
RegisterNUICallback('useItem', function(data, cb)
    if not data.name then cb('err') return end
    local name = data.name
    -- Silah veya zırh kullanıldığında envanteri kapat (focus sorunu önlenir)
    if name:sub(1, 7) == 'weapon_' or name == 'armor' or name == 'heavyarmor' then
        SendClose()
    end
    TriggerServerEvent('vaterpvp:inventory:useItem', name, data.slot)
    cb('ok')
end)

-- Eşyayı Yere Bırak
RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('vaterpvp:inventory:dropItem', data.name, data.slot, data.amount or 1)
    cb('ok')
end)

-- Slot Taşı (Drag & Drop)
RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('vaterpvp:inventory:moveItem', data.from, data.to)
    cb('ok')
end)

-- Yerdeki Eşyayı Al
RegisterNUICallback('pickupItem', function(data, cb)
    TriggerServerEvent('vaterpvp:inventory:pickupItem', data.groundIndex, data.toSlot, data.amount or 1)
    cb('ok')
end)

-- Eşyayı Böl
RegisterNUICallback('splitItem', function(data, cb)
    TriggerServerEvent('vaterpvp:inventory:splitItem', data.name, data.slot, data.amount or 1)
    cb('ok')
end)

-- ── Server Events ─────────────────────────────────────────────────────

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    LoadInventory()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if val and val.items then
        playerItems  = val.items
        playerWeight = 0.0
        for _, item in pairs(playerItems) do
            if item and item.weight and item.amount then
                playerWeight = playerWeight + (item.weight * item.amount)
            end
        end
        if isOpen then
            SendNUIMessage({ action = 'updateInventory', data = BuildPayload() })
        end
    end
end)

-- Sunucudan envanter + yerdeki eşya güncelleme
RegisterNetEvent('vaterpvp:inventory:refreshClient', function(items, weight, nearby)
    playerItems  = items   or playerItems
    playerWeight = weight  or playerWeight
    groundItems  = nearby  or {}
    if isOpen then
        SendNUIMessage({ action = 'updateInventory', data = BuildPayload() })
    end
end)

-- Use efektleri
RegisterNetEvent('vaterpvp:inventory:useEffect', function(itemName)
    local ped = PlayerPedId()

    if itemName == 'medkit' then
        local maxHealth = GetEntityMaxHealth(ped)
        if maxHealth < 200 then maxHealth = 200 end
        SetEntityMaxHealth(ped, maxHealth)
        SetEntityHealth(ped, maxHealth)
        QBCore.Functions.Notify('Can yenilendi.', 'success')
        Wait(100)
        TriggerEvent('vater-hud:forceUpdate')

    elseif itemName == 'armor' then
        SetPedArmour(ped, 100)
        QBCore.Functions.Notify('Zırh takıldı.', 'success')
        Wait(100)
        TriggerEvent('vater-hud:forceUpdate')

    elseif itemName:sub(1, 7) == 'weapon_' then
        -- Tüm silahlar için dinamik kuşanma
        local hash = GetHashKey(itemName:upper())
        if hash == 0 then
            hash = GetHashKey(itemName)
        end
        RequestWeaponAsset(hash, 31, 0)
        local timeout = 0
        while not HasWeaponAssetLoaded(hash) and timeout < 500 do
            Wait(0)
            timeout = timeout + 1
        end
        GiveWeaponToPed(ped, hash, 250, false, true)
        local itemInfo = QBCore.Shared.Items[itemName]
        local label = (itemInfo and itemInfo.label) or itemName
        QBCore.Functions.Notify(label .. ' kuşanıldı.', 'success')
    end
end)

-- ── Başlangıç ─────────────────────────────────────────────────────────
AddEventHandler('onClientResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    SendNUIMessage({ action = 'closeInventory' })
    SetNuiFocus(false, false)
end)

-- ── 1-5 Sıcak Tuş Atamaları (Fallback) ─────────────────────────────────
if GetResourceState('qb-inventory') ~= 'started' then
    for i = 1, 5 do
        RegisterCommand('vaterpvp_slot_' .. i, function()
            if isOpen then return end
            if IsPauseMenuActive() then return end
            LoadInventory()
            local item = playerItems[i] or playerItems[tostring(i)]
            if item and item.name then
                TriggerServerEvent('vaterpvp:inventory:useItem', item.name, i)
            end
        end, false)
        RegisterKeyMapping('vaterpvp_slot_' .. i, 'VaterPVP Envanter Slot ' .. i, 'keyboard', tostring(i))
    end
end

-- ── Silah Çarkını Devre Dışı Bırak & Envanter Açıkken Kontrolleri Kısıtla ──
CreateThread(function()
    while true do
        Wait(0)
        -- Her zaman silah çarkını (TAB) ve araç içi silah değiştirmeyi (TAB) engelle
        DisableControlAction(0, 37, true)
        DisableControlAction(0, 99, true) -- Araç içi silah değiştirme (TAB)
        DisableControlAction(0, 115, true) -- Uçak/Helikopter içi silah değiştirme (TAB)

        -- Envanter açıkken hareket (WASD) hariç aksiyonları engelle
        if isOpen then
            DisablePlayerFiring(PlayerPedId(), true) -- Ateş etmeyi engelle
            DisableControlAction(0, 24, true) -- Sol tık (Saldırı)
            DisableControlAction(0, 25, true) -- Sağ tık (Nişan)
            DisableControlAction(0, 140, true) -- Melee vuruş
            DisableControlAction(0, 141, true) -- Melee vuruş
            DisableControlAction(0, 142, true) -- Melee vuruş
            DisableControlAction(0, 257, true) -- Melee
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true) -- Melee
            DisableControlAction(0, 22, true) -- Zıplama (Space)
            DisableControlAction(0, 44, true) -- Siper alma (Q)

            -- Kameranın dönmesini (mouse ile bakış) engelle
            DisableControlAction(0, 1, true) -- Look Left/Right
            DisableControlAction(0, 2, true) -- Look Up/Down
            DisableControlAction(0, 16, true) -- Look Up
            DisableControlAction(0, 17, true) -- Look Down
            DisableControlAction(0, 18, true) -- Look Left
            DisableControlAction(0, 19, true) -- Look Right

            -- ESC tuşuna basıldığında pause menüsünün açılmasını engelle
            DisableControlAction(0, 200, true) -- ESC (Pause Menu)
        end
    end
end)

RegisterNetEvent('vater-inventory:client:UseMedkit', function()
    local ped = PlayerPedId()
    if GetEntityHealth(ped) >= GetEntityMaxHealth(ped) then
        QBCore.Functions.Notify('Canınız zaten dolu!', 'error')
        return
    end

    QBCore.Functions.Progressbar('use_medkit', 'Medkit kullanılıyor...', 4000, false, false, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'amb@medic@standing@tendtodead@idle_a',
        anim = 'idle_a',
        flags = 49,
    }, {}, {}, function() -- Done
        local maxHealth = GetEntityMaxHealth(ped)
        if maxHealth < 200 then maxHealth = 200 end
        SetEntityMaxHealth(ped, maxHealth)
        SetEntityHealth(ped, maxHealth)
        TriggerServerEvent('vater-inventory:server:UseMedkit')
        -- HUD'u anında güncelle
        Wait(100)
        TriggerEvent('vater-hud:forceUpdate')
    end)
end)
