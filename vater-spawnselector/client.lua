local QBCore = exports['qb-core']:GetCoreObject()
local choosingSpawn = false
local Houses = {}
local cam = nil
local cam2 = nil

local function SetDisplay(bool)
    choosingSpawn = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = 'showUi',
        status = bool,
        translations = Config.Translations[Config.Lang]
    })
end

RegisterNetEvent('qb-spawn:client:openUI', function(value)
    local ped = PlayerPedId()
    SetEntityVisible(ped, false)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(250)
    Wait(1000)
    DoScreenFadeIn(250)
    
    QBCore.Functions.GetPlayerData(function(PlayerData)
        local pos = PlayerData.position or Config.DefaultSpawn
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z + 200.0, -85.00, 0.00, 0.00, 90.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    end)
    Wait(500)
    SetDisplay(value)
end)

RegisterNetEvent('qb-spawn:client:setupSpawns', function(cData, new, apps)
    local citizenid = cData and cData.citizenid or nil
    if not new then
        if citizenid then
            QBCore.Functions.TriggerCallback('qb-spawn:server:getOwnedHouses', function(houses, playerCounts)
                local myHouses = {}
                if houses ~= nil then
                    for i = 1, #houses do
                        -- Houses logic if needed
                    end
                end
                
                if playerCounts then
                    for k, count in pairs(playerCounts) do
                        if Config.Spawns[k] then
                            if count == 0 then
                                Config.Spawns[k].difficulty = 'Kolay'
                                Config.Spawns[k].players = 'Sakin (0 Oyuncu)'
                            elseif count <= 2 then
                                Config.Spawns[k].difficulty = 'Orta'
                                Config.Spawns[k].players = 'Normal (' .. count .. ' Oyuncu)'
                            elseif count <= 5 then
                                Config.Spawns[k].difficulty = 'Zor'
                                Config.Spawns[k].players = 'Yoğun (' .. count .. ' Oyuncu)'
                            else
                                Config.Spawns[k].difficulty = 'Çok Zor'
                                Config.Spawns[k].players = 'Çok Yoğun (' .. count .. ' Oyuncu)'
                            end
                        end
                    end
                end
                
                Wait(1000) -- Wait for NUI to be ready and displayed
                SendNUIMessage({
                    action = 'setupLocations',
                    locations = Config.Spawns,
                    houses = myHouses,
                    isNew = new
                })
            end, citizenid)
        else
            Wait(1000) -- Wait for NUI to be ready and displayed
            SendNUIMessage({
                action = 'setupLocations',
                locations = Config.Spawns,
                houses = {},
                isNew = new
            })
        end
    else
        Wait(1000) -- Wait for NUI to be ready and displayed
        SendNUIMessage({
            action = 'setupAppartements',
            locations = apps,
            isNew = new
        })
    end
end)

local function SetCam(campos)
    DoScreenFadeOut(200)
    Wait(500)
    DoScreenFadeIn(200)
    
    cam2 = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', campos.x, campos.y, campos.z + 80.0, -75.00, 0.00, campos.w or 0.0, 90.00, false, 0)
    PointCamAtCoord(cam2, campos.x, campos.y, campos.z)
    SetCamActiveWithInterp(cam2, cam, 1000, true, true)
    if DoesCamExist(cam) then
        DestroyCam(cam, true)
    end
    cam = cam2
    SetEntityCoords(PlayerPedId(), campos.x, campos.y, campos.z)
end

RegisterNUICallback('setCam', function(data, cb)
    local location = tostring(data.posname)
    local type = tostring(data.type)
    
    if type == 'current' then
        QBCore.Functions.GetPlayerData(function(PlayerData)
            local pos = PlayerData.position or Config.DefaultSpawn
            SetCam(pos)
        end)
    elseif type == 'normal' then
        SetCam(Config.Spawns[location].coords)
    end
    cb('ok')
end)

RegisterNUICallback('spawnplayer', function(data, cb)
    local location = tostring(data.spawnloc)
    local type = tostring(data.typeLoc)
    local ped = PlayerPedId()
    
    SetDisplay(false)
    DoScreenFadeOut(500)
    Wait(1500)
    
    if type == 'current' then
        QBCore.Functions.GetPlayerData(function(pd)
            ped = PlayerPedId()
            local pos = pd.position or Config.DefaultSpawn
            SetEntityCoords(ped, pos.x, pos.y, pos.z)
            SetEntityHeading(ped, pos.a or 0.0)
        end)
    elseif type == 'normal' then
        local pos = Config.Spawns[location].coords
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        SetEntityHeading(ped, pos.w)
    end
    
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true)
    RenderScriptCams(false, true, 500, true, true)
    
    if DoesCamExist(cam) then DestroyCam(cam, true) end
    if DoesCamExist(cam2) then DestroyCam(cam2, true) end
    cam = nil
    cam2 = nil
    
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerEvent('qb-weathersync:client:EnableSync')
    
    -- Tell multicharacter to close NUI, cams, peds
    TriggerEvent('qb-multicharacter:client:closeNUI')
    
    Wait(500)
    DoScreenFadeIn(250)
    cb('ok')
end)

-- Disable controls while spawning
CreateThread(function()
    while true do
        if choosingSpawn then
            DisableAllControlActions(0)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)
