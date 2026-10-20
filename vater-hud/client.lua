local QBCore = exports['qb-core']:GetCoreObject()

local hudVisible = false
local lastHealth = -1
local lastArmor = -1
local lastKills = 0
local lastDeaths = 0
local killStreak = 0
local firstLoad = true
local lastTime = nil
local lastDate = nil

-- NUI'ye mesaj gonder
local function SendHUD(data)
    SendNUIMessage(data)
end

-- Oyun ici saat & tarih hesapla
local function GetFormattedDateTime()
    local rawHour   = GetClockHours()
    local minute    = GetClockMinutes()
    local day       = GetClockDayOfMonth()
    local month     = GetClockMonth() + 1
    local year      = GetClockYear()

    local period = "AM"
    local hour   = rawHour

    if hour >= 12 then
        period = "PM"
        if hour > 12 then hour = hour - 12 end
    elseif hour == 0 then
        hour = 12
    end

    local timeStr = string.format("%02d:%02d %s", hour, minute, period)
    local dateStr = string.format("%02d/%02d/%04d", month, day, year)
    return timeStr, dateStr
end

-- Kill / Death meta verisini oku
local function GetKDStats()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.metadata then
        return 0, 0
    end
    local kills  = PlayerData.metadata['kills']  or 0
    local deaths = PlayerData.metadata['deaths'] or 0
    return kills, deaths
end

-- HUD'i goster
local function ShowHUD()
    hudVisible = true
    SendHUD({ action = "show" })
    local kills, deaths = GetKDStats()
    lastKills = kills
    lastDeaths = deaths
    SendHUD({ action = "updateStats", kills = kills, deaths = deaths, streak = killStreak })
    
    lastHealth = -1
    lastArmor = -1
    lastTime = nil
    lastDate = nil
end

-- HUD'i gizle
local function HideHUD()
    hudVisible = false
    SendHUD({ action = "hide" })
end

-- ─── Ana Dongu: Saat / Tarih / Can / Zırh ────────────────────────────
CreateThread(function()
    local forceSyncTimer = 0
    while true do
        Wait(250)
        if hudVisible then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                -- Can Hesaplama (0-100)
                local maxHealth = GetEntityMaxHealth(ped)
                local rawHealth = GetEntityHealth(ped)
                local health = 0
                if maxHealth > 100 then
                    health = math.floor(((rawHealth - 100) / (maxHealth - 100)) * 100)
                else
                    health = rawHealth
                end
                health = math.max(0, math.min(100, health))
                
                -- Zırh Hesaplama (0-100)
                local armor = GetPedArmour(ped)
                armor = math.max(0, math.min(100, armor))
                
                forceSyncTimer = forceSyncTimer + 250
                if health ~= lastHealth or armor ~= lastArmor or forceSyncTimer >= 3000 then
                    SendHUD({
                        action = "updateStatus",
                        health = health,
                        armor = armor
                    })
                    lastHealth = health
                    lastArmor = armor
                    forceSyncTimer = 0
                end
            end
        end
    end
end)

-- ─── Harici Scriptlerden Anında HUD Güncelleme ────────────────────────

RegisterNetEvent('vater-hud:forceUpdate', function()
    if hudVisible then
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local maxHealth = GetEntityMaxHealth(ped)
            local rawHealth = GetEntityHealth(ped)
            local health = 0
            if maxHealth > 100 then
                health = math.floor(((rawHealth - 100) / (maxHealth - 100)) * 100)
            else
                health = rawHealth
            end
            health = math.max(0, math.min(100, health))
            local armor = GetPedArmour(ped)
            armor = math.max(0, math.min(100, armor))
            SendHUD({
                action = "updateStatus",
                health = health,
                armor = armor
            })
            lastHealth = health
            lastArmor = armor
        end
    end
end)

-- ─── Saat/Tarih Güncelleme Döngüsü ──────────────────────────────────
CreateThread(function()
    while true do
        Wait(1000)
        if hudVisible then
            local t, d = GetFormattedDateTime()
            if t ~= lastTime or d ~= lastDate then
                SendHUD({ action = "updateDateTime", time = t, date = d })
                lastTime = t
                lastDate = d
            end
        end
    end
end)

-- ─── Stats Dongu: Kill / Death ─────────────────────────────────────
CreateThread(function()
    while true do
        Wait(5000) -- 5 saniyede bir guncelle
        if hudVisible then
            local kills, deaths = GetKDStats()
            local statsChanged = false
            if firstLoad then
                lastKills = kills
                lastDeaths = deaths
                firstLoad = false
            else
                if kills > lastKills then
                    killStreak = killStreak + (kills - lastKills)
                    SendHUD({ action = "notification", message = "DÜŞMAN ELENDİ! 💀", duration = 3000 })
                end
                if deaths > lastDeaths then
                    killStreak = 0
                end
                statsChanged = kills ~= lastKills or deaths ~= lastDeaths
                lastKills = kills
                lastDeaths = deaths
            end
            if statsChanged then
                SendHUD({ action = "updateStats", kills = kills, deaths = deaths, streak = killStreak })
            end
        end
    end
end)

-- ─── QBCore Events ─────────────────────────────────────────────────
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    ShowHUD()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    HideHUD()
end)

-- Harici scriptlerden kill/death guncelleme
RegisterNetEvent('vaterpvp:hud:updateKills', function(kills, deaths)
    if firstLoad then
        lastKills = kills
        lastDeaths = deaths
        firstLoad = false
    else
        if kills > lastKills then
            killStreak = killStreak + (kills - lastKills)
            SendHUD({ action = "notification", message = "DÜŞMAN ELENDİ! 💀", duration = 3000 })
        end
        if deaths > lastDeaths then
            killStreak = 0
        end
        lastKills = kills
        lastDeaths = deaths
    end
    SendHUD({ action = "updateStats", kills = kills, deaths = deaths, streak = killStreak })
end)

-- HUD toggle komutu (debug icin)
RegisterCommand('togglehud', function()
    if hudVisible then
        HideHUD()
    else
        ShowHUD()
    end
end, false)

-- Kaynak basladiginda NUI'yi hazirla
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        Wait(500)
        ShowHUD()
    end
end)
