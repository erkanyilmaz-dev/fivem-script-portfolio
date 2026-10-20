local Framework = nil
local isQBX = false

-- Framework Auto-Detector (QB-Core / QBX-Core)
CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        isQBX = true
        Framework = exports['qbx_core']
    elseif GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
    end
end)

local function GetQBCore()
    if not Framework and GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
    end
    return Framework
end

local hudVisible = false
local editModeActive = false
local isSeatbeltOn = false
local inVehicle = false

-- Cache variables for diff updates
local lastHealth = -1
local lastArmor = -1
local lastStamina = -1
local lastHunger = -1
local lastThirst = -1
local lastVoiceSpeaking = false
local lastVoiceMode = 2

-- Voice modes mapping
local voiceLevels = {
    [1] = { level = 33, label = "Fısıltı" },
    [2] = { level = 66, label = "Normal" },
    [3] = { level = 100, label = "Bağırma" }
}

local function SendHUD(data)
    SendNUIMessage(data)
end

-- Safely get Hunger and Thirst for QB-Core and QBX-Core
local function GetNeeds()
    if isQBX and exports['qbx_core'] and exports['qbx_core']:GetPlayerData() then
        local pData = exports['qbx_core']:GetPlayerData()
        if pData and pData.metadata then
            local hunger = pData.metadata['hunger'] or 100
            local thirst = pData.metadata['thirst'] or 100
            return hunger, thirst
        end
    end

    local qb = GetQBCore()
    if qb and qb.Functions then
        local PlayerData = qb.Functions.GetPlayerData()
        if PlayerData and PlayerData.metadata then
            local hunger = PlayerData.metadata['hunger'] or 100
            local thirst = PlayerData.metadata['thirst'] or 100
            return hunger, thirst
        end
    end

    return 100, 100
end

local function IsPlayerLoggedIn()
    if isQBX and exports['qbx_core'] then
        return LocalPlayer.state.isLoggedIn or false
    end
    local qb = GetQBCore()
    if qb and qb.Functions then
        local PlayerData = qb.Functions.GetPlayerData()
        return PlayerData ~= nil and PlayerData.citizenid ~= nil
    end
    return LocalPlayer.state.isLoggedIn or false
end

-- Safely get Vehicle Fuel
local function GetVehicleFuel(veh)
    if not DoesEntityExist(veh) then return 100 end
    if GetResourceState('LegacyFuel') == 'started' then
        return exports['LegacyFuel']:GetFuel(veh)
    elseif GetResourceState('qb-fuel') == 'started' then
        return exports['qb-fuel']:GetFuel(veh)
    elseif GetResourceState('cdn-fuel') == 'started' then
        return exports['cdn-fuel']:GetFuel(veh)
    end
    return GetVehicleFuelLevel(veh)
end

-- Show HUD
local function ShowHUD()
    if not hudVisible then
        hudVisible = true
        SendHUD({ action = "show" })
        lastHealth = -1
        lastArmor = -1
        lastStamina = -1
        lastHunger = -1
        lastThirst = -1
        lastVoiceSpeaking = false
    end
end

-- Hide HUD
local function HideHUD()
    if hudVisible then
        hudVisible = false
        SendHUD({ action = "hide" })
    end
end

-- Fast status tick (Health, Armor, Stamina, Voice)
CreateThread(function()
    while true do
        if hudVisible and not IsPauseMenuActive() then
            Wait(200)
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                -- Health
                local maxHealth = GetEntityMaxHealth(ped)
                local rawHealth = GetEntityHealth(ped)
                local health = 0
                if maxHealth > 100 then
                    health = math.floor(((rawHealth - 100) / (maxHealth - 100)) * 100)
                else
                    health = rawHealth
                end
                health = math.max(0, math.min(100, health))

                -- Armor
                local armor = GetPedArmour(ped)
                armor = math.max(0, math.min(100, armor))

                -- Stamina
                local stamina = 100 - math.floor(GetPlayerSprintStaminaRemaining(PlayerId()))
                stamina = math.max(0, math.min(100, stamina))

                -- Voice talking state
                local isTalking = MumbleIsPlayerTalking(PlayerId()) or NetworkIsPlayerTalking(PlayerId()) or false

                if health ~= lastHealth or armor ~= lastArmor or stamina ~= lastStamina or isTalking ~= lastVoiceSpeaking then
                    SendHUD({
                        action = "updateStatusFast",
                        health = health,
                        armor = armor,
                        stamina = stamina,
                        isTalking = isTalking
                    })
                    lastHealth = health
                    lastArmor = armor
                    lastStamina = stamina
                    lastVoiceSpeaking = isTalking
                end
            end
        elseif IsPauseMenuActive() and hudVisible then
            SendHUD({ action = "hide" })
            hudVisible = false
        elseif not IsPauseMenuActive() and not hudVisible and IsPlayerLoggedIn() then
            ShowHUD()
        else
            Wait(1000)
        end
    end
end)

-- Slow status tick (Hunger, Thirst)
CreateThread(function()
    while true do
        Wait(1000)
        if hudVisible and not IsPauseMenuActive() then
            local hunger, thirst = GetNeeds()
            hunger = math.max(0, math.min(100, math.floor(hunger)))
            thirst = math.max(0, math.min(100, math.floor(thirst)))

            if hunger ~= lastHunger or thirst ~= lastThirst then
                SendHUD({
                    action = "updateStatusSlow",
                    hunger = hunger,
                    thirst = thirst
                })
                lastHunger = hunger
                lastThirst = thirst
            end
        end
    end
end)

-- Vehicle & Speedometer Tick
CreateThread(function()
    while true do
        Wait(100)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and not IsPauseMenuActive() then
            local veh = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(veh) and GetPedInVehicleSeat(veh, -1) == ped then
                if not inVehicle then
                    inVehicle = true
                    SendHUD({ action = "toggleSpeedo", show = true })
                end

                local speedMs = GetEntitySpeed(veh)
                local speedKmh = math.floor(speedMs * 3.6)
                local speedMph = math.floor(speedMs * 2.236936)
                local rpm = GetVehicleCurrentRpm(veh) or 0.0
                local gear = GetVehicleCurrentGear(veh) or 1
                local fuel = math.floor(GetVehicleFuel(veh))
                local engineHealth = GetVehicleEngineHealth(veh)
                local engineOn = GetIsVehicleEngineRunning(veh)

                -- Street & Area location
                local coords = GetEntityCoords(ped)
                local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                local streetName = GetStreetNameFromHashKey(streetHash)
                local crossingName = GetStreetNameFromHashKey(crossingHash)
                local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
                local zoneLabel = GetLabelText(zoneName)

                local locationText = streetName
                if crossingName ~= nil and crossingName ~= "" then
                    locationText = locationText .. " / " .. crossingName
                end

                SendHUD({
                    action = "updateVehicle",
                    kmh = speedKmh,
                    mph = speedMph,
                    rpm = rpm,
                    gear = gear,
                    fuel = fuel,
                    seatbelt = isSeatbeltOn,
                    engineOn = engineOn,
                    engineHealth = math.floor(engineHealth / 10),
                    street = locationText,
                    zone = zoneLabel
                })
            else
                if inVehicle then
                    inVehicle = false
                    SendHUD({ action = "toggleSpeedo", show = false })
                end
            end
        else
            if inVehicle then
                inVehicle = false
                SendHUD({ action = "toggleSpeedo", show = false })
            end
            Wait(500)
        end
    end
end)

-- Event Handlers
RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    if hudVisible then
        local hunger = math.max(0, math.min(100, math.floor(newHunger)))
        local thirst = math.max(0, math.min(100, math.floor(newThirst)))
        SendHUD({
            action = "updateStatusSlow",
            hunger = hunger,
            thirst = thirst
        })
        lastHunger = hunger
        lastThirst = thirst
    end
end)

RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
    lastVoiceMode = mode
    local levelData = voiceLevels[mode] or { level = 66, label = "Normal" }
    SendHUD({
        action = "updateVoiceMode",
        level = levelData.level,
        label = levelData.label
    })
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function(state)
    if state ~= nil then
        isSeatbeltOn = state
    else
        isSeatbeltOn = not isSeatbeltOn
    end
end)

-- QB-Core events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    ShowHUD()
    local currentProximity = 2
    if LocalPlayer.state.proximity and LocalPlayer.state.proximity.mode then
        currentProximity = LocalPlayer.state.proximity.mode
    end
    local levelData = voiceLevels[currentProximity] or { level = 66, label = "Normal" }
    SendHUD({
        action = "updateVoiceMode",
        level = levelData.level,
        label = levelData.label
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    HideHUD()
end)

-- QBX-Core events
RegisterNetEvent('qbx_core:client:playerLoaded', function()
    Wait(1000)
    ShowHUD()
    local currentProximity = 2
    if LocalPlayer.state.proximity and LocalPlayer.state.proximity.mode then
        currentProximity = LocalPlayer.state.proximity.mode
    end
    local levelData = voiceLevels[currentProximity] or { level = 66, label = "Normal" }
    SendHUD({
        action = "updateVoiceMode",
        level = levelData.level,
        label = levelData.label
    })
end)

RegisterNetEvent('qbx_core:client:playerUnloaded', function()
    HideHUD()
end)

-- Command & NUI Handlers
local function OpenHUDMenu()
    if not IsPlayerLoggedIn() and not isQBX then
        -- Allow opening if logged in or for initial setup preview
    end
    editModeActive = true
    SetNuiFocus(true, true)
    SendHUD({ action = "openEditor" })
end

RegisterCommand('hud', function()
    OpenHUDMenu()
end, false)

RegisterCommand('hudedit', function()
    OpenHUDMenu()
end, false)

RegisterCommand('hudreset', function()
    SendHUD({ action = "resetHUD" })
    local qb = GetQBCore()
    if qb and qb.Functions then
        qb.Functions.Notify("HUD varsayılan ayarlara sıfırlandı.", "success")
    end
end, false)

RegisterKeyMapping('hud', 'HUD Düzenleme Menüsünü Aç', 'keyboard', 'I')

-- NUI Callbacks
RegisterNUICallback('closeHUD', function(data, cb)
    SetNuiFocus(false, false)
    editModeActive = false
    cb('ok')
end)

RegisterNUICallback('saveKvpSettings', function(data, cb)
    if data and data.settings then
        SetResourceKvp('vater_hud_settings_v3', json.encode(data.settings))
    end
    cb('ok')
end)

RegisterNUICallback('uiReady', function(data, cb)
    local kvpData = GetResourceKvpString('vater_hud_settings_v3')
    if kvpData then
        SendHUD({ action = "loadKvpSettings", settings = json.decode(kvpData) })
    end

    if IsPlayerLoggedIn() then
        ShowHUD()
        local currentProximity = 2
        if LocalPlayer.state.proximity and LocalPlayer.state.proximity.mode then
            currentProximity = LocalPlayer.state.proximity.mode
        end
        local levelData = voiceLevels[currentProximity] or { level = 66, label = "Normal" }
        SendHUD({
            action = "updateVoiceMode",
            level = levelData.level,
            label = levelData.label
        })
    else
        -- Force show HUD for testing / setup preview
        ShowHUD()
    end
    cb('ok')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        Wait(500)
        ShowHUD()
    end
end)
