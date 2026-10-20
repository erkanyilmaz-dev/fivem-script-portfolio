-- ====================================================================
-- VATER SCRIPTS - 3D Scene Reconstruction / Holographic Replay System
-- ULTRA OPTIMIZED CLIENT ENGINE (0.00 - 0.01 ms Idle Resmon)
-- ====================================================================

-- Localized Core Natives for Maximum Lua Execution Speed
local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local PlayerId = PlayerId
local GetEntityCoords = GetEntityCoords
local GetEntityVelocity = GetEntityVelocity
local GetEntitySpeed = GetEntitySpeed
local GetEntityModel = GetEntityModel
local GetEntityRotation = GetEntityRotation
local GetEntityHeading = GetEntityHeading
local GetEntityHealth = GetEntityHealth
local GetPedArmour = GetPedArmour
local GetSelectedPedWeapon = GetSelectedPedWeapon
local IsPedShooting = IsPedShooting
local IsPedDeadOrDying = IsPedDeadOrDying
local IsEntityDead = IsEntityDead
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsPedInVehicle = IsPedInVehicle
local IsPlayerFreeAiming = IsPlayerFreeAiming
local IsPedAimingFromCover = IsPedAimingFromCover
local IsPedAPlayer = IsPedAPlayer
local GetGamePool = GetGamePool
local DoesEntityExist = DoesEntityExist
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityHeading = SetEntityHeading
local SetEntityRotation = SetEntityRotation
local SetEntityVisible = SetEntityVisible
local SetEntityCollision = SetEntityCollision
local SetEntityAlpha = SetEntityAlpha
local SetEntityDrawOutline = SetEntityDrawOutline
local SetEntityDrawOutlineColor = SetEntityDrawOutlineColor
local SetEntityNoCollisionEntity = SetEntityNoCollisionEntity
local SetEntityInvincible = SetEntityInvincible
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local DeleteEntity = DeleteEntity
local CreatePed = CreatePed
local CreateVehicle = CreateVehicle
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local DrawMarker = DrawMarker
local DrawLine = DrawLine
local SetNuiFocus = SetNuiFocus
local SetNuiFocusKeepInput = SetNuiFocusKeepInput
local SendNUIMessage = SendNUIMessage
local TriggerServerEvent = TriggerServerEvent
local TriggerEvent = TriggerEvent
local DisableControlAction = DisableControlAction
local IsControlJustPressed = IsControlJustPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local World3dToScreen2d = World3dToScreen2d
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextProportional = SetTextProportional
local SetTextColour = SetTextColour
local SetTextDropshadow = SetTextDropshadow
local SetTextEdge = SetTextEdge
local SetTextDropShadow = SetTextDropShadow
local SetTextOutline = SetTextOutline
local SetTextEntry = SetTextEntry
local AddTextComponentString = AddTextComponentString
local DrawText = DrawText
local GiveWeaponToPed = GiveWeaponToPed
local SetCurrentPedWeapon = SetCurrentPedWeapon
local SetPedUsingActionMode = SetPedUsingActionMode
local SetPedToRagdoll = SetPedToRagdoll
local IsPedRagdoll = IsPedRagdoll
local TaskShootAtCoord = TaskShootAtCoord
local TaskAimGunAtCoord = TaskAimGunAtCoord
local ClearPedTasks = ClearPedTasks
local GetEntityForwardVector = GetEntityForwardVector
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove

local QBCore = nil
local ESX = nil

-- Framework Init
CreateThread(function()
    if Config.Framework == 'autodetect' or Config.Framework == 'qb-core' then
        if GetResourceState('qb-core') == 'started' then
            QBCore = exports['qb-core']:GetCoreObject()
        end
    end

    if not QBCore and (Config.Framework == 'autodetect' or Config.Framework == 'esx') then
        if GetResourceState('es_extended') == 'started' then
            ESX = exports['es_extended']:getSharedObject()
        end
    end
end)

-- Math Helpers
local function Clamp(val, lower, upper)
    if val < lower then return lower end
    if val > upper then return upper end
    return val
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function LerpVec3(v1, v2, t)
    return vector3(
        v1.x + (v2.x - v1.x) * t,
        v1.y + (v2.y - v1.y) * t,
        v1.z + (v2.z - v1.z) * t
    )
end

local function LerpAngle(a, b, t)
    local diff = (b - a) % 360.0
    if diff > 180.0 then diff = diff - 360.0 end
    if diff < -180.0 then diff = diff + 360.0 end
    return (a + diff * t) % 360.0
end

local function GetDistanceSq(c1, c2)
    local dx = c1.x - c2.x
    local dy = c1.y - c2.y
    local dz = c1.z - c2.z
    return (dx * dx) + (dy * dy) + (dz * dz)
end

-- State Variables
local ringBuffer = {}
local maxFrames = math_floor(((Config.BufferDuration or 180) * 1000) / (Config.RecordInterval or 200))
local isRecording = true
local isScanning = false
local isPlaybackActive = false
local isCursorActive = true

-- Playback Engine States
local playbackData = nil
local currentFrame = 1
local isPlaying = false
local playbackSpeed = 1.0
local localClones = { peds = {}, vehicles = {} }
local cloneStates = { peds = {}, vehicles = {} }
local showPeds = true
local showVehicles = true
local showEvents = true

-- Appearance Cache (Prevents heavy clothing loops on every 200ms tick)
local pedAppearanceCache = {}
local lastCacheClean = 0

local function GetCachedPedAppearance(ped, model)
    local now = GetGameTimer()
    local cached = pedAppearanceCache[ped]
    if cached and cached.model == model and (now - cached.time < 15000) then
        return cached.app
    end

    local components = {}
    for i = 0, 11 do
        components[#components + 1] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i)
        }
    end

    local props = {}
    for i = 0, 3 do
        props[#props + 1] = {
            index = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i)
        }
    end

    local app = { components = components, props = props }
    pedAppearanceCache[ped] = { model = model, time = now, app = app }
    return app
end

-- Helper: Set Ped Appearance
local function ApplyPedAppearance(ped, appearance)
    if not appearance then return end
    if appearance.components then
        for i, comp in ipairs(appearance.components) do
            SetPedComponentVariation(ped, i - 1, comp.drawable, comp.texture, comp.palette)
        end
    end
    if appearance.props then
        for i, prop in ipairs(appearance.props) do
            if prop.index ~= -1 then
                SetPedPropIndex(ped, i - 1, prop.index, prop.texture, true)
            else
                ClearPedProp(ped, i - 1)
            end
        end
    end
end

-- Utility: Notifications
RegisterNetEvent('vater-crime:client:notify', function(msg, msgType)
    if QBCore then
        QBCore.Functions.Notify(msg, msgType or 'primary')
    elseif ESX then
        ESX.ShowNotification(msg)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, false)
    end
end)

-- Focus Mode Controller
local lastFocusToggleTime = 0
local function UpdateFocusMode(cursorEnabled)
    local now = GetGameTimer()
    if now - lastFocusToggleTime < 250 then return end
    lastFocusToggleTime = now

    isCursorActive = cursorEnabled
    SetNuiFocus(isCursorActive, isCursorActive)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'updateModeBadge',
        isCursorActive = isCursorActive
    })
end

RegisterKeyMapping('toggleHoloFocus', 'Hologram Kamera/Arayüz Değiştir', 'keyboard', 'LMENU')
RegisterCommand('toggleHoloFocus', function()
    if isPlaybackActive then
        UpdateFocusMode(not isCursorActive)
    end
end, false)

-- Helper: Convert Vector3 / Table to pure serializable numeric table
local function VecToTable(v)
    if not v then return { x = 0.0, y = 0.0, z = 0.0 } end
    return {
        x = math_floor(((v.x or 0.0) * 100) + 0.5) / 100,
        y = math_floor(((v.y or 0.0) * 100) + 0.5) / 100,
        z = math_floor(((v.z or 0.0) * 100) + 0.5) / 100
    }
end

-- Lightweight Buffer Sanitizer (No FPS stutters on death or save)
local function SanitizeBuffer(rawBuffer)
    local cleanBuffer = {}
    if not rawBuffer then return cleanBuffer end

    for bIdx = 1, #rawBuffer do
        local frame = rawBuffer[bIdx]
        local cleanPeds = {}
        if frame.peds then
            for pIdx = 1, #frame.peds do
                local p = frame.peds[pIdx]
                cleanPeds[#cleanPeds + 1] = {
                    key = p.key,
                    model = p.model,
                    coords = VecToTable(p.coords),
                    heading = math_floor(((p.heading or 0.0) * 100) + 0.5) / 100,
                    health = p.health,
                    armor = p.armor,
                    weapon = p.weapon,
                    isShooting = p.isShooting,
                    isAiming = p.isAiming,
                    isDead = p.isDead,
                    speed = p.speed,
                    inVehicle = p.inVehicle,
                    appearance = p.appearance,
                    isPlayer = p.isPlayer
                }
            end
        end

        local cleanVehs = {}
        if frame.vehicles then
            for vIdx = 1, #frame.vehicles do
                local v = frame.vehicles[vIdx]
                cleanVehs[#cleanVehs + 1] = {
                    key = v.key,
                    model = v.model,
                    coords = VecToTable(v.coords),
                    rotation = VecToTable(v.rotation),
                    velocity = VecToTable(v.velocity),
                    engineHealth = v.engineHealth,
                    bodyHealth = v.bodyHealth,
                    primaryColor = v.primaryColor,
                    secondaryColor = v.secondaryColor,
                    extraPrimary = v.extraPrimary,
                    extraSecondary = v.extraSecondary,
                    customPrimary = v.customPrimary,
                    customSecondary = v.customSecondary,
                    livery = v.livery
                }
            end
        end

        local cleanEvents = {}
        if frame.events then
            for eIdx = 1, #frame.events do
                local e = frame.events[eIdx]
                cleanEvents[#cleanEvents + 1] = {
                    type = e.type,
                    coords = VecToTable(e.coords),
                    label = e.label
                }
            end
        end

        cleanBuffer[#cleanBuffer + 1] = {
            timestamp = frame.timestamp,
            peds = cleanPeds,
            vehicles = cleanVehs,
            events = cleanEvents
        }
    end
    return cleanBuffer
end

-- ====================================================================
-- 1. ROLLING RECORDING ENGINE (Optimized 200ms Worker)
-- ====================================================================
CreateThread(function()
    local lastVehicleSpeed = 0.0
    local scanRadiusSq = (Config.ScanRadius or 50.0) * (Config.ScanRadius or 50.0)
    local interval = Config.RecordInterval or 200

    while true do
        Wait(interval)

        if isRecording and not isPlaybackActive then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local now = GetGameTimer()

            -- Periodic GC cleanup of appearance cache
            if now - lastCacheClean > 30000 then
                pedAppearanceCache = {}
                lastCacheClean = now
            end

            local framePeds = {}
            local frameVehicles = {}
            local frameEvents = {}
            local pedInAnyVeh = IsPedInAnyVehicle(playerPed, false)

            -- 1. Scan Nearby Vehicles (Only if vehicles exist in pool)
            local vehicles = GetGamePool('CVehicle')
            for vIdx = 1, #vehicles do
                local veh = vehicles[vIdx]
                if DoesEntityExist(veh) then
                    local vehCoords = GetEntityCoords(veh)
                    if GetDistanceSq(vehCoords, playerCoords) <= scanRadiusSq then
                        local vehVel = GetEntityVelocity(veh)
                        local currentSpeed = GetEntitySpeed(veh)
                        local pedInVeh = pedInAnyVeh and IsPedInVehicle(playerPed, veh, false)

                        -- Crash Trigger
                        if pedInVeh and Config.RecordOnVehicleCrash then
                            local speedDelta = math_abs(currentSpeed - lastVehicleSpeed)
                            if speedDelta >= (Config.MinVehicleCrashSpeedDelta or 15.0) then
                                frameEvents[#frameEvents + 1] = {
                                    type = 'crash',
                                    coords = vehCoords,
                                    label = 'Araç Çarpışması'
                                }
                            end
                            lastVehicleSpeed = currentSpeed
                        end

                        local pColor, sColor = GetVehicleColours(veh)
                        local extraP, extraS = GetVehicleExtraColours(veh)
                        local customP, customS = nil, nil

                        if GetIsVehiclePrimaryColourCustom and GetIsVehiclePrimaryColourCustom(veh) then
                            local r, g, b = GetVehicleCustomPrimaryColour(veh)
                            customP = { r = r, g = g, b = b }
                        end
                        if GetIsVehicleSecondaryColourCustom and GetIsVehicleSecondaryColourCustom(veh) then
                            local r, g, b = GetVehicleCustomSecondaryColour(veh)
                            customS = { r = r, g = g, b = b }
                        end

                        frameVehicles[#frameVehicles + 1] = {
                            key = 'veh_' .. vIdx,
                            id = veh,
                            model = GetEntityModel(veh),
                            coords = vehCoords,
                            rotation = GetEntityRotation(veh, 2),
                            velocity = vehVel,
                            engineHealth = GetVehicleEngineHealth(veh),
                            bodyHealth = GetVehicleBodyHealth(veh),
                            primaryColor = pColor,
                            secondaryColor = sColor,
                            extraPrimary = extraP,
                            extraSecondary = extraS,
                            customPrimary = customP,
                            customSecondary = customS,
                            livery = GetVehicleLivery(veh)
                        }
                    end
                end
            end

            -- 2. Scan Nearby Peds
            local peds = GetGamePool('CPed')
            for pIdx = 1, #peds do
                local ped = peds[pIdx]
                if DoesEntityExist(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    if GetDistanceSq(pedCoords, playerCoords) <= scanRadiusSq then
                        local isShooting = IsPedShooting(ped)
                        local isDead = IsPedDeadOrDying(ped, true) or IsEntityDead(ped)
                        local weaponHash = GetSelectedPedWeapon(ped)
                        local speed = GetEntitySpeed(ped)
                        local inVehicle = IsPedInAnyVehicle(ped, false)
                        local isAiming = false

                        if not inVehicle then
                            isAiming = (ped == playerPed and IsPlayerFreeAiming(PlayerId())) or IsPedAimingFromCover(ped)
                        end

                        if isShooting then
                            frameEvents[#frameEvents + 1] = {
                                type = 'shooting',
                                coords = pedCoords,
                                label = 'Ateşli Silah Kullanımı'
                            }
                        end

                        if isDead then
                            frameEvents[#frameEvents + 1] = {
                                type = 'casualty',
                                coords = pedCoords,
                                label = 'Olay Yeri Yaralısı'
                            }
                        end

                        local modelHash = GetEntityModel(ped)
                        framePeds[#framePeds + 1] = {
                            key = 'ped_' .. pIdx,
                            id = ped,
                            model = modelHash,
                            coords = pedCoords,
                            heading = GetEntityHeading(ped),
                            health = GetEntityHealth(ped),
                            armor = GetPedArmour(ped),
                            weapon = weaponHash,
                            isShooting = isShooting,
                            isAiming = isAiming,
                            isDead = isDead,
                            speed = speed,
                            inVehicle = inVehicle,
                            appearance = GetCachedPedAppearance(ped, modelHash),
                            isPlayer = IsPedAPlayer(ped)
                        }
                    end
                end
            end

            -- Store snapshot
            ringBuffer[#ringBuffer + 1] = {
                timestamp = now,
                peds = framePeds,
                vehicles = frameVehicles,
                events = frameEvents
            }

            -- Trim buffer
            if #ringBuffer > maxFrames then
                table_remove(ringBuffer, 1)
            end

            -- Fatal Death Auto-Save Trigger (Max 200 frames to stay safely under FiveM 64KB net event limit)
            if Config.RecordOnFatalDeath and IsPedDeadOrDying(playerPed, true) then
                if #ringBuffer >= 10 then
                    local requiredFrames = math_min(200, math_floor(((Config.BufferDuration or 40) * 1000) / interval))
                    local incidentSlice = {}
                    local startIdx = math_max(1, #ringBuffer - requiredFrames + 1)
                    for i = startIdx, #ringBuffer do
                        incidentSlice[#incidentSlice + 1] = ringBuffer[i]
                    end

                    local cleanSlice = SanitizeBuffer(incidentSlice)
                    TriggerServerEvent('vater-crime:server:saveIncident', {
                        name = 'Otomatik Kayıt (Ölümcül Vaka)',
                        coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z },
                        triggerType = 'fatal_death',
                        buffer = cleanSlice
                    })
                    Wait(6000)
                end
            end
        end
    end
end)

-- Helper: 3D Text Rendering
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(0, 229, 255, 235)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Helper: Check Job Permission on Client
local function HasClientJobPermission()
    if not Config.AllowedJobs then return true end

    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
        local pData = QBCore.Functions.GetPlayerData()
        if pData and pData.job then
            local jobName = pData.job.name
            local jobGrade = (pData.job.grade and pData.job.grade.level) or 0
            if Config.AllowedJobs[jobName] and jobGrade >= Config.AllowedJobs[jobName] then
                return true
            end
        end
    elseif ESX and ESX.GetPlayerData then
        local pData = ESX.GetPlayerData()
        if pData and pData.job then
            local jobName = pData.job.name
            local jobGrade = pData.job.grade or 0
            if Config.AllowedJobs[jobName] and jobGrade >= Config.AllowedJobs[jobName] then
                return true
            end
        end
    else
        return true
    end

    return false
end

-- ====================================================================
-- 2. INVESTIGATION MINIGAME (Optimized Distance Poller)
-- ====================================================================
local isMinigameActive = false
local scannerPropEntity = nil

local function RemoveMinigameScannerProp()
    if scannerPropEntity and DoesEntityExist(scannerPropEntity) then
        DeleteEntity(scannerPropEntity)
        scannerPropEntity = nil
    end

    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local checkModels = { `scanner_device`, `p_digiscanner`, `w_me_knife_01`, `prop_tracker_01` }
    for i = 1, #checkModels do
        local obj = GetClosestObjectOfType(pCoords.x, pCoords.y, pCoords.z, 5.0, checkModels[i], false, false, false)
        if DoesEntityExist(obj) and IsEntityAttachedToEntity(obj, playerPed) then
            DeleteEntity(obj)
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveMinigameScannerProp()
        if isPlaybackActive then
            for _, ped in pairs(localClones.peds) do
                if DoesEntityExist(ped) then DeleteEntity(ped) end
            end
            for _, veh in pairs(localClones.vehicles) do
                if DoesEntityExist(veh) then DeleteEntity(veh) end
            end
        end
    end
end)

local function StartInvestigationMinigame(centerCoords)
    if isMinigameActive then return end
    isMinigameActive = true

    local playerPed = PlayerPedId()
    TriggerEvent('vater-crime:client:notify', Config.Locale['minigame_started'], 'primary')
    RemoveMinigameScannerProp()

    local pointsCount = (Config.Minigame and Config.Minigame.PointsCount) or 5
    local scanTimeMs = (Config.Minigame and Config.Minigame.ScanTimePerPoint) or 3000
    local scanPoints = {}

    for i = 1, pointsCount do
        local angle = (i * (360.0 / pointsCount)) * (math.pi / 180.0)
        local distRadius = 6.0 + (math.random(0, 80) / 10.0)
        local ptX = centerCoords.x + (math.cos(angle) * distRadius)
        local ptY = centerCoords.y + (math.sin(angle) * distRadius)
        local foundGround, ptZ = GetGroundZFor_3dCoord(ptX, ptY, centerCoords.z + 10.0, false)
        if not foundGround or ptZ == 0.0 then ptZ = centerCoords.z end

        local blip = AddBlipForCoord(ptX, ptY, ptZ)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 38)
        SetBlipScale(blip, 0.85)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(('Kanıt Bölgesi #%d'):format(i))
        EndTextCommandSetBlipName(blip)

        scanPoints[#scanPoints + 1] = {
            id = i,
            x = ptX,
            y = ptY,
            z = ptZ,
            coords = vector3(ptX, ptY, ptZ),
            blip = blip,
            completed = false
        }
    end

    CreateThread(function()
        local completedCount = 0
        local isPointScanning = false

        while isMinigameActive and completedCount < pointsCount do
            local pPed = PlayerPedId()
            local pCoords = GetEntityCoords(pPed)
            local closestDistSq = 999999.0
            local closestPoint = nil

            for idx = 1, #scanPoints do
                local pt = scanPoints[idx]
                if not pt.completed then
                    local dSq = GetDistanceSq(pCoords, pt.coords)
                    if dSq < closestDistSq then
                        closestDistSq = dSq
                        closestPoint = pt
                    end
                end
            end

            -- Dynamic Sleep: When player is far from points, sleep 250ms; when nearby, draw markers at 0ms
            if closestDistSq > 900.0 then -- > 30 meters
                Wait(250)
            else
                Wait(0)
                for idx = 1, #scanPoints do
                    local pt = scanPoints[idx]
                    if not pt.completed then
                        local dSq = GetDistanceSq(pCoords, pt.coords)
                        if dSq <= 900.0 then
                            DrawMarker(22, pt.x, pt.y, pt.z + 1.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.6, 0.6, 0.6, 0, 229, 255, 220, true, true, 2, false, nil, nil, false)
                            DrawMarker(1, pt.x, pt.y, pt.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.8, 1.8, 0.4, 0, 229, 255, 150, false, false, 2, false, nil, nil, false)

                            if dSq <= 4.0 and not isPointScanning then
                                DrawText3D(pt.x, pt.y, pt.z + 0.5, (Config.Locale['minigame_point_prompt']):format(completedCount, pointsCount))

                                if IsControlJustPressed(0, 38) then
                                    isPointScanning = true
                                    TriggerEvent('vater-crime:client:notify', Config.Locale['minigame_scanning'], 'primary')
                                    PlaySoundFrontend(-1, "SCANNER_BEEP", "HUD_MINIGAME_SOUNDSET", true)

                                    RequestAnimDict("amb@medic@standing@tendtodead@idle_a")
                                    local timeout = 0
                                    while not HasAnimDictLoaded("amb@medic@standing@tendtodead@idle_a") and timeout < 50 do
                                        Wait(10)
                                        timeout = timeout + 1
                                    end
                                    if HasAnimDictLoaded("amb@medic@standing@tendtodead@idle_a") then
                                        TaskPlayAnim(pPed, "amb@medic@standing@tendtodead@idle_a", "idle_a", 8.0, -8.0, scanTimeMs, 1, 0.0, false, false, false)
                                    else
                                        TaskStartScenarioInPlace(pPed, "CODE3_SECURITY_GUARD", 0, true)
                                    end

                                    local elapsed = 0
                                    while elapsed < scanTimeMs do
                                        Wait(0)
                                        elapsed = elapsed + 15
                                        local pulseRadius = (elapsed / scanTimeMs) * 2.5
                                        DrawMarker(1, pt.x, pt.y, pt.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, pulseRadius * 2.0, pulseRadius * 2.0, 0.5, 0, 229, 255, 200, false, false, 2, false, nil, nil, false)
                                    end

                                    ClearPedTasks(pPed)
                                    pt.completed = true
                                    completedCount = completedCount + 1
                                    isPointScanning = false

                                    if DoesBlipExist(pt.blip) then RemoveBlip(pt.blip) end
                                    PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", true)
                                    TriggerEvent('vater-crime:client:notify', (Config.Locale['minigame_point_complete']):format(completedCount, pointsCount), 'success')
                                end
                            end
                        end
                    end
                end
            end
        end

        for idx = 1, #scanPoints do
            local pt = scanPoints[idx]
            if DoesBlipExist(pt.blip) then RemoveBlip(pt.blip) end
        end

        RemoveMinigameScannerProp()
        isMinigameActive = false

        if completedCount >= pointsCount then
            TriggerEvent('vater-crime:client:notify', Config.Locale['minigame_completed'], 'success')
            Wait(1000)
            TriggerServerEvent('vater-crime:server:getNearbyIncidents', { x = centerCoords.x, y = centerCoords.y, z = centerCoords.z })
        end
    end)
end

RegisterNetEvent('vater-crime:client:useScannerTool', function()
    if not HasClientJobPermission() then
        TriggerEvent('vater-crime:client:notify', Config.Locale['no_permission'], 'error')
        return
    end

    if isScanning or isPlaybackActive or isMinigameActive then return end

    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    TriggerServerEvent('vater-crime:server:getNearbyIncidents', { x = pCoords.x, y = pCoords.y, z = pCoords.z })
end)

RegisterNetEvent('vater-crime:client:receiveNearbyIncidents', function(incidents)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openScannerList',
        incidents = incidents
    })
end)

-- ====================================================================
-- 3. HOLOGRAPHIC PLAYBACK SYSTEM (Zero-Thrash Clone Management)
-- ====================================================================
local function CleanLocalClones()
    for _, ped in pairs(localClones.peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, veh in pairs(localClones.vehicles) do
        if DoesEntityExist(veh) then DeleteEntity(veh) end
    end
    localClones = { peds = {}, vehicles = {} }
    cloneStates = { peds = {}, vehicles = {} }
end

local function UpdatePedClone(key, pedA, pedB, factor)
    local clone = localClones.peds[key]
    local state = cloneStates.peds[key]

    if pedA.inVehicle then
        if clone and DoesEntityExist(clone) then
            SetEntityVisible(clone, false, false)
        end
        return
    end

    local lerpCoords = LerpVec3(pedA.coords, pedB.coords, factor)
    local lerpHeading = LerpAngle(pedA.heading, pedB.heading, factor)

    if not clone or not DoesEntityExist(clone) then
        RequestModel(pedA.model)
        while not HasModelLoaded(pedA.model) do Wait(0) end

        clone = CreatePed(4, pedA.model, lerpCoords.x, lerpCoords.y, lerpCoords.z, lerpHeading, false, false)
        SetModelAsNoLongerNeeded(pedA.model)

        SetEntityAlpha(clone, Config.Hologram.Alpha or 160, false)
        SetEntityDrawOutline(clone, true)
        SetEntityDrawOutlineColor(Config.Hologram.OutlineColor.r, Config.Hologram.OutlineColor.g, Config.Hologram.OutlineColor.b, 255)
        SetEntityNoCollisionEntity(clone, PlayerPedId(), false)
        SetEntityCollision(clone, false, false)
        SetEntityInvincible(clone, true)
        SetBlockingOfNonTemporaryEvents(clone, true)

        ApplyPedAppearance(clone, pedA.appearance)

        localClones.peds[key] = clone
        cloneStates.peds[key] = { weapon = 0, action = 'none', isDead = false }
        state = cloneStates.peds[key]
    end

    SetEntityVisible(clone, showPeds, false)
    SetEntityCoordsNoOffset(clone, lerpCoords.x, lerpCoords.y, lerpCoords.z, false, false, false)
    SetEntityHeading(clone, lerpHeading)

    -- Weapon Syncing (State Checked - Only triggers on change)
    if pedA.weapon and pedA.weapon ~= 0 then
        if state.weapon ~= pedA.weapon then
            GiveWeaponToPed(clone, pedA.weapon, 999, true, true)
            SetCurrentPedWeapon(clone, pedA.weapon, true)
            SetPedUsingActionMode(clone, true, -1, 0)
            state.weapon = pedA.weapon
        end
    else
        if state.weapon ~= `WEAPON_UNARMED` and state.weapon ~= 0 then
            SetCurrentPedWeapon(clone, `WEAPON_UNARMED`, true)
            SetPedUsingActionMode(clone, false, -1, 0)
            state.weapon = `WEAPON_UNARMED`
        end
    end

    -- Upper Body Combat Actions (State Checked - Prevents Task spamming every frame!)
    if pedA.isDead then
        if not state.isDead then
            SetPedToRagdoll(clone, 5000, 5000, 0, false, false, false)
            state.isDead = true
            state.action = 'dead'
        end
    elseif pedA.isShooting then
        state.isDead = false
        if state.action ~= 'shooting' then
            local fwd = GetEntityForwardVector(clone)
            local aimTarget = lerpCoords + (fwd * 20.0)
            TaskShootAtCoord(clone, aimTarget.x, aimTarget.y, aimTarget.z, 300, `FIRING_PATTERN_FULL_AUTO`)
            state.action = 'shooting'
        end
    elseif pedA.isAiming then
        state.isDead = false
        if state.action ~= 'aiming' then
            local fwd = GetEntityForwardVector(clone)
            local aimTarget = lerpCoords + (fwd * 20.0)
            TaskAimGunAtCoord(clone, aimTarget.x, aimTarget.y, aimTarget.z, 300, false, false)
            state.action = 'aiming'
        end
    else
        state.isDead = false
        if state.action ~= 'idle' then
            ClearPedTasks(clone)
            state.action = 'idle'
        end
    end
end

local function UpdateVehicleClone(key, vehA, vehB, factor)
    local lerpCoords = LerpVec3(vehA.coords, vehB.coords, factor)
    local lerpRot = vector3(
        LerpAngle(vehA.rotation.x, vehB.rotation.x, factor),
        LerpAngle(vehA.rotation.y, vehB.rotation.y, factor),
        LerpAngle(vehA.rotation.z, vehB.rotation.z, factor)
    )

    local clone = localClones.vehicles[key]
    if not clone or not DoesEntityExist(clone) then
        RequestModel(vehA.model)
        while not HasModelLoaded(vehA.model) do Wait(0) end

        clone = CreateVehicle(vehA.model, lerpCoords.x, lerpCoords.y, lerpCoords.z, lerpRot.z, false, false)
        SetModelAsNoLongerNeeded(vehA.model)

        SetEntityRotation(clone, lerpRot.x, lerpRot.y, lerpRot.z, 2, true)
        SetEntityAlpha(clone, Config.Hologram.Alpha or 160, false)
        SetEntityDrawOutline(clone, true)
        SetEntityDrawOutlineColor(Config.Hologram.OutlineColor.r, Config.Hologram.OutlineColor.g, Config.Hologram.OutlineColor.b, 255)

        SetEntityCollision(clone, false, false)
        SetEntityNoCollisionEntity(clone, PlayerPedId(), false)
        SetEntityInvincible(clone, true)
        SetVehicleEngineOn(clone, false, false, true)
        SetVehicleDoorsLocked(clone, 2)
        FreezeEntityPosition(clone, true)

        if vehA.primaryColor and vehA.secondaryColor then
            SetVehicleColours(clone, vehA.primaryColor, vehA.secondaryColor)
        end
        if vehA.extraPrimary and vehA.extraSecondary then
            SetVehicleExtraColours(clone, vehA.extraPrimary, vehA.extraSecondary)
        end
        if vehA.customPrimary then
            SetVehicleCustomPrimaryColour(clone, vehA.customPrimary.r, vehA.customPrimary.g, vehA.customPrimary.b)
        end
        if vehA.customSecondary then
            SetVehicleCustomSecondaryColour(clone, vehA.customSecondary.r, vehA.customSecondary.g, vehA.customSecondary.b)
        end
        if vehA.livery and vehA.livery ~= -1 then
            SetVehicleLivery(clone, vehA.livery)
        end

        localClones.vehicles[key] = clone
    end

    SetEntityCoordsNoOffset(clone, lerpCoords.x, lerpCoords.y, lerpCoords.z, false, false, false)
    SetEntityRotation(clone, lerpRot.x, lerpRot.y, lerpRot.z, 2, true)
    SetEntityVisible(clone, showVehicles, false)
end

-- Playback Master Thread (60+ FPS Smooth Interpolation)
RegisterNetEvent('vater-crime:client:startPlayback', function(data)
    if not data or not data.buffer or #data.buffer == 0 then return end

    CleanLocalClones()
    playbackData = data.buffer
    currentFrame = 1
    isPlaying = true
    isPlaybackActive = true

    UpdateFocusMode(true)

    SendNUIMessage({
        action = 'openPlaybackUI',
        serialId = data.serialId,
        name = data.name or 'Olay Yeri Kaydı',
        timestamp = data.timestamp,
        triggerType = data.triggerType,
        totalFrames = #playbackData,
        duration = math_floor((#playbackData * (Config.RecordInterval or 200)) / 1000)
    })

    TriggerEvent('vater-crime:client:notify', Config.Locale['playback_started'], 'success')

    CreateThread(function()
        local frameStartTime = GetGameTimer()
        local interval = Config.RecordInterval or 200

        while isPlaybackActive do
            Wait(0)

            -- Key listeners for focus mode toggle
            DisableControlAction(0, 19, true)
            DisableControlAction(0, 37, true)
            if IsDisabledControlJustPressed(0, 19) or IsControlJustPressed(0, 19) or IsDisabledControlJustPressed(0, 37) or IsControlJustPressed(0, 37) then
                UpdateFocusMode(not isCursorActive)
            end

            local totalLen = #playbackData
            local nextFrame = math_min(totalLen, currentFrame + 1)
            local frameDuration = interval / playbackSpeed

            if isPlaying and playbackData then
                local now = GetGameTimer()
                local elapsed = now - frameStartTime

                if elapsed >= frameDuration then
                    currentFrame = currentFrame + 1
                    if currentFrame >= totalLen then
                        currentFrame = 1
                    end
                    frameStartTime = now

                    SendNUIMessage({
                        action = 'updateTimeline',
                        currentFrame = currentFrame
                    })
                end
            end

            local factor = 0.0
            if isPlaying then
                factor = Clamp((GetGameTimer() - frameStartTime) / frameDuration, 0.0, 1.0)
            end

            local frameA = playbackData[currentFrame]
            local frameB = playbackData[nextFrame] or frameA

            if frameA and frameB then
                -- Render Vehicles
                if frameA.vehicles then
                    for idx = 1, #frameA.vehicles do
                        local vDataA = frameA.vehicles[idx]
                        local vDataB = (frameB.vehicles and frameB.vehicles[idx]) or vDataA
                        local vKey = vDataA.key or ('veh_' .. idx)
                        UpdateVehicleClone(vKey, vDataA, vDataB, factor)
                    end
                end

                -- Render Peds
                if frameA.peds then
                    for idx = 1, #frameA.peds do
                        local pDataA = frameA.peds[idx]
                        local pDataB = (frameB.peds and frameB.peds[idx]) or pDataA
                        local pKey = pDataA.key or ('ped_' .. idx)
                        UpdatePedClone(pKey, pDataA, pDataB, factor)

                        -- Bullet tracer visual line
                        if showEvents and pDataA.isShooting and not pDataA.inVehicle then
                            local clonePed = localClones.peds[pKey]
                            if clonePed and DoesEntityExist(clonePed) and showPeds then
                                local fwd = GetEntityForwardVector(clonePed)
                                local muzzle = GetEntityCoords(clonePed) + vector3(0.0, 0.0, 0.6)
                                local target = muzzle + (fwd * 25.0)
                                DrawLine(muzzle.x, muzzle.y, muzzle.z, target.x, target.y, target.z,
                                    Config.Hologram.TracerColor.r, Config.Hologram.TracerColor.g, Config.Hologram.TracerColor.b, Config.Hologram.TracerColor.a)
                            end
                        end
                    end
                end

                -- Render 3D Event Overlay Markers
                if showEvents and frameA.events then
                    for eIdx = 1, #frameA.events do
                        local ev = frameA.events[eIdx]
                        DrawMarker(Config.Hologram.MarkerType, ev.coords.x, ev.coords.y, ev.coords.z + 1.2,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            Config.Hologram.MarkerScale.x, Config.Hologram.MarkerScale.y, Config.Hologram.MarkerScale.z,
                            Config.Hologram.MarkerColor.r, Config.Hologram.MarkerColor.g, Config.Hologram.MarkerColor.b, Config.Hologram.MarkerColor.a,
                            true, true, 2, false, nil, nil, false)
                        DrawText3D(ev.coords.x, ev.coords.y, ev.coords.z + 1.5, '[ ' .. string.upper(ev.label) .. ' ]')
                    end
                end
            end
        end

        CleanLocalClones()
    end)
end)

local function StopPlayback()
    isPlaybackActive = false
    isPlaying = false
    CleanLocalClones()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'closeUI' })
    TriggerEvent('vater-crime:client:notify', Config.Locale['playback_ended'], 'primary')
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    StopPlayback()
    cb('ok')
end)

RegisterNUICallback('startAreaScan', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    StartInvestigationMinigame(pCoords)
end)

RegisterNUICallback('toggleFocusMode', function(data, cb)
    UpdateFocusMode(not isCursorActive)
    cb('ok')
end)

RegisterNUICallback('play', function(data, cb)
    isPlaying = true
    cb('ok')
end)

RegisterNUICallback('pause', function(data, cb)
    isPlaying = false
    cb('ok')
end)

RegisterNUICallback('scrubTimeline', function(data, cb)
    if data.frame and playbackData then
        currentFrame = Clamp(tonumber(data.frame) or 1, 1, #playbackData)
    end
    cb('ok')
end)

RegisterNUICallback('setSpeed', function(data, cb)
    if data.speed then
        playbackSpeed = tonumber(data.speed) or 1.0
    end
    cb('ok')
end)

RegisterNUICallback('toggleFilter', function(data, cb)
    if data.filter == 'peds' then
        showPeds = not showPeds
    elseif data.filter == 'vehicles' then
        showVehicles = not showVehicles
    elseif data.filter == 'events' then
        showEvents = not showEvents
    end
    cb('ok')
end)

RegisterNUICallback('loadIncident', function(data, cb)
    if data.id then
        TriggerServerEvent('vater-crime:server:loadIncident', data.id)
    end
    cb('ok')
end)

RegisterNUICallback('deleteIncident', function(data, cb)
    if data.id then
        TriggerServerEvent('vater-crime:server:deleteIncident', data.id)
    end
    cb('ok')
end)

RegisterNUICallback('saveCurrentBuffer', function(data, cb)
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)

    local targetBuffer = {}
    if #ringBuffer > 0 then
        -- Cap to last 200 frames (~40s) so packet stays safely around 25KB (well under 64KB net event limit)
        local maxSaveFrames = 200
        local startIdx = math_max(1, #ringBuffer - maxSaveFrames + 1)
        for i = startIdx, #ringBuffer do
            targetBuffer[#targetBuffer + 1] = ringBuffer[i]
        end
    else
        local scanRadiusSq = (Config.ScanRadius or 50.0) * (Config.ScanRadius or 50.0)
        local peds = GetGamePool('CPed')
        local framePeds = {}
        for pIdx = 1, #peds do
            local ped = peds[pIdx]
            if DoesEntityExist(ped) and GetDistanceSq(GetEntityCoords(ped), pCoords) <= scanRadiusSq then
                local modelHash = GetEntityModel(ped)
                framePeds[#framePeds + 1] = {
                    key = 'ped_' .. pIdx,
                    model = modelHash,
                    coords = GetEntityCoords(ped),
                    heading = GetEntityHeading(ped),
                    health = GetEntityHealth(ped),
                    armor = GetPedArmour(ped),
                    weapon = GetSelectedPedWeapon(ped),
                    speed = GetEntitySpeed(ped),
                    inVehicle = IsPedInAnyVehicle(ped, false),
                    appearance = GetCachedPedAppearance(ped, modelHash)
                }
            end
        end

        local vehicles = GetGamePool('CVehicle')
        local frameVehicles = {}
        for vIdx = 1, #vehicles do
            local veh = vehicles[vIdx]
            if DoesEntityExist(veh) and GetDistanceSq(GetEntityCoords(veh), pCoords) <= scanRadiusSq then
                local pColor, sColor = GetVehicleColours(veh)
                frameVehicles[#frameVehicles + 1] = {
                    key = 'veh_' .. vIdx,
                    model = GetEntityModel(veh),
                    coords = GetEntityCoords(veh),
                    rotation = GetEntityRotation(veh, 2),
                    velocity = GetEntityVelocity(veh),
                    primaryColor = pColor,
                    secondaryColor = sColor
                }
            end
        end

        targetBuffer[#targetBuffer + 1] = {
            timestamp = GetGameTimer(),
            peds = framePeds,
            vehicles = frameVehicles,
            events = {}
        }
    end

    local cleanBuffer = SanitizeBuffer(targetBuffer)

    TriggerEvent('vater-crime:client:notify', 'Olay yeri veritabanına kaydediliyor...', 'primary')

    TriggerServerEvent('vater-crime:server:saveIncident', {
        name = data.name or 'Olay Yeri Kaydı',
        coords = { x = pCoords.x, y = pCoords.y, z = pCoords.z },
        triggerType = 'manual_scan',
        buffer = cleanBuffer
    })
    cb('ok')
end)
