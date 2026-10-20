local QBCore = exports['qb-core']:GetCoreObject()

local isDead = false
local timer = 30
local timerFinished = false
local holdStartTime = nil

-- Death detection from baseevents
RegisterNetEvent('baseevents:onPlayerKilled', function(killerServerId, data)
    if isDead then return end
    StartDeathSequence(killerServerId)
end)

RegisterNetEvent('baseevents:onPlayerDied', function(killertype, data)
    if isDead then return end
    StartDeathSequence(-1)
end)

-- Safety check thread to ensure death is caught
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsEntityDead(ped) and not isDead then
            Wait(1000)
            if not isDead then
                StartDeathSequence(-1)
            end
        end
    end
end)

function StartDeathSequence(killerServerId)
    isDead = true
    timer = 30
    timerFinished = false
    holdStartTime = nil

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Eject from vehicle if in one
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, veh, 16)
        Wait(500)
    end

    -- Resurrect ped but keep them in dead state
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    SetEntityHealth(ped, 100)
    SetEntityInvincible(ped, true)
    
    -- Request and play dead animation
    RequestAnimDict("dead")
    while not HasAnimDictLoaded("dead") do Wait(0) end
    TaskPlayAnim(ped, "dead", "dead_a", 8.0, 8.0, -1, 33, 0, false, false, false)

    -- Trigger server-side death registration
    TriggerServerEvent('vater-deathscreen:server:onDeath', killerServerId)
end

RegisterNetEvent('vater-deathscreen:client:showDeathScreen', function(killerName, killerServerId, killerAvatar)
    SendNUIMessage({
        action = 'openDeathScreen',
        data = {
            killerName = killerName,
            killerServerId = killerServerId,
            killerAvatar = killerAvatar
        }
    })

    -- Start countdown thread
    CreateThread(function()
        while isDead and timer > 0 do
            Wait(1000)
            if isDead then
                timer = timer - 1
                SendNUIMessage({
                    action = 'updateCountdown',
                    data = { seconds = timer }
                })
            end
        end

        if isDead then
            timerFinished = true
            SendNUIMessage({
                action = 'showRespawnPrompt'
            })
        end
    end)
end)

RegisterNetEvent('vater-deathscreen:client:updateKillerAvatar', function(avatarUrl)
    if isDead then
        SendNUIMessage({
            action = 'updateKillerAvatar',
            data = {
                killerAvatar = avatarUrl
            }
        })
    end
end)

-- Loop to disable controls and handle E key holding
CreateThread(function()
    while true do
        if isDead then
            local ped = PlayerPedId()
            
            -- Keep dead animation playing if interrupted
            if not IsEntityPlayingAnim(ped, "dead", "dead_a", 3) then
                RequestAnimDict("dead")
                while not HasAnimDictLoaded("dead") do Wait(0) end
                TaskPlayAnim(ped, "dead", "dead_a", 8.0, 8.0, -1, 33, 0, false, false, false)
            end

            -- Disable controls
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Look Left/Right
            EnableControlAction(0, 2, true) -- Look Up/Down

            -- Handle E hold
            if timerFinished then
                if IsDisabledControlPressed(0, 38) then -- E key
                    if not holdStartTime then
                        holdStartTime = GetGameTimer()
                    end
                    
                    local heldDuration = GetGameTimer() - holdStartTime
                    local progress = math.min((heldDuration / 5000) * 100, 100)
                    
                    SendNUIMessage({
                        action = 'updateEProgress',
                        data = { progress = progress }
                    })
                    
                    if heldDuration >= 5000 then
                        TriggerServerEvent('vater-deathscreen:server:respawnPlayer')
                        holdStartTime = nil
                        Wait(1000)
                    end
                else
                    if holdStartTime then
                        holdStartTime = nil
                        SendNUIMessage({
                            action = 'updateEProgress',
                            data = { progress = 0 }
                        })
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Respawn at hospital and revive
RegisterNetEvent('vater-deathscreen:client:reviveAndRespawn', function()
    isDead = false
    timerFinished = false
    holdStartTime = nil

    DoScreenFadeOut(500)
    Wait(600)

    SendNUIMessage({ action = 'closeDeathScreen' })

    local ped = PlayerPedId()
    
    -- Teleport to Pillbox Hill Hospital
    SetEntityCoords(ped, 298.02, -584.43, 43.26, false, false, false, false)
    SetEntityHeading(ped, 72.84)

    -- Revive player status
    SetEntityInvincible(ped, false)
    local maxHealth = GetEntityMaxHealth(ped)
    if maxHealth < 200 then maxHealth = 200 end
    SetEntityMaxHealth(ped, maxHealth)
    SetEntityHealth(ped, maxHealth)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)

    Wait(500)
    DoScreenFadeIn(1000)

    QBCore.Functions.Notify('Hastanede uyandınız, envanteriniz temizlendi.', 'success')
    TriggerEvent('vater-hud:forceUpdate')
end)

-- Silent revive (e.g. from admin command)
RegisterNetEvent('vater-deathscreen:client:reviveSilent', function()
    if isDead then
        isDead = false
        timerFinished = false
        holdStartTime = nil

        SendNUIMessage({ action = 'closeDeathScreen' })

        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        local maxHealth = GetEntityMaxHealth(ped)
        if maxHealth < 200 then maxHealth = 200 end
        SetEntityMaxHealth(ped, maxHealth)
        SetEntityHealth(ped, maxHealth)
        ClearPedBloodDamage(ped)
        ClearPedTasksImmediately(ped)
        TriggerEvent('vater-hud:forceUpdate')
    end
end)

-- Compatibility net events
RegisterNetEvent('hospital:client:Revive', function()
    TriggerEvent('vater-deathscreen:client:reviveSilent')
end)

RegisterNetEvent('hospital:client:KillPlayer', function()
    SetEntityHealth(PlayerPedId(), 0)
end)
