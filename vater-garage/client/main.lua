local QBCore = exports['qb-core']:GetCoreObject()
local uiOpen, currentGarage, lastSpawn = false, nil, 0
local blips = {}
local garagePeds = {}
local garagePedCoords = {}
local spawnedVehicle, driveGuardUntil, lastDriveValidation = nil, 0, 0

local function notify(message, kind)
    QBCore.Functions.Notify(message, kind or 'primary')
end

local function drawText(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextFont(4); SetTextScale(0.31, 0.31); SetTextColour(240, 244, 255, 230); SetTextCentre(true)
    SetTextOutline(); BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function getGaragePedCoords(garage)
    if garage.booth and type(garage.booth.models) == 'table' then
        local offset = garage.booth.frontOffset or vector3(0.0, 2.0, 0.0)
        for _, modelName in ipairs(garage.booth.models) do
            local booth = GetClosestObjectOfType(garage.coords.x, garage.coords.y, garage.coords.z, 14.0, joaat(modelName), false, false, false)
            if booth ~= 0 and DoesEntityExist(booth) then
                local position = GetOffsetFromEntityInWorldCoords(booth, offset.x, offset.y, offset.z)
                return vector4(position.x, position.y, position.z, GetEntityHeading(booth))
            end
        end
    end
    return garage.ped or vector4(garage.coords.x + 1.8, garage.coords.y, garage.coords.z, 0.0)
end

local function createGaragePed(garage, coords)
    coords = coords or getGaragePedCoords(garage)
    local model = joaat(garage.pedModel or Config.PedModel)
    if not IsModelInCdimage(model) or not IsModelValid(model) then return nil end

    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(model) then return nil end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, garage.pedScenario or Config.PedScenario, 0, true)
    SetModelAsNoLongerNeeded(model)
    return ped
end

local function closeGarage()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openGarage(garageId)
    local garage = Config.Garages[garageId]
    if not garage then return end
    QBCore.Functions.TriggerCallback('vater-garage:server:getVehicles', function(response)
        if not response.ok then notify(response.message, 'error') return end
        currentGarage = garageId
        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', payload = response })
    end, garageId)
end

local function storeCurrentVehicle(garageId)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify('Garaja koymak için bir aracın sürücü koltuğunda olmalısın.', 'error')
        return
    end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        notify('Aracı yalnızca sürücü saklayabilir.', 'error')
        return
    end
    local props = QBCore.Functions.GetVehicleProperties(vehicle)
    TriggerServerEvent('vater-garage:server:storeVehicle', {
        garageId = garageId, plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle)), properties = props,
        fuel = GetVehicleFuelLevel(vehicle), engine = GetVehicleEngineHealth(vehicle), body = GetVehicleBodyHealth(vehicle), netId = VehToNet(vehicle)
    })
end

local function getNearestGarage()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestId, closestDistance = nil, Config.StoreRadius
    for id, garage in pairs(Config.Garages) do
        local distance = #(playerCoords - garage.coords)
        if distance <= closestDistance then
            closestId, closestDistance = id, distance
        end
    end
    return closestId
end

-- The radial menu ships with these two events. Keeping the handlers here
-- prevents it from silently calling missing garage actions.
RegisterNetEvent('vater-garage:client:openGarage', function()
    local garageId = getNearestGarage()
    if not garageId then
        notify('Garaj alanÄ±nda deÄŸilsin.', 'error')
        return
    end
    openGarage(garageId)
end)

RegisterNetEvent('vater-garage:client:parkVehicle', function()
    local garageId = getNearestGarage()
    if not garageId then
        notify(Config.Text.tooFar, 'error')
        return
    end
    storeCurrentVehicle(garageId)
end)

local function isSpawnClear(spawn)
    local vehicle = GetClosestVehicle(spawn.x, spawn.y, spawn.z, 3.0, 0, 71)
    return vehicle == 0
end

-- Some saved property sets preserve a handbrake/undriveable state. A spawned
-- garage vehicle must always be released into a normal, controllable state.
local function resetDriveState(vehicle)
    FreezeEntityPosition(vehicle, false)
    SetEntityDynamic(vehicle, true)
    SetEntityCollision(vehicle, true, true)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleHandbrake(vehicle, false)
    SetVehicleBrakeLights(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleEngineOn(vehicle, true, true, false)
end

local function resetDriverState()
    local ped = PlayerPedId()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetPlayerControl(PlayerId(), true, 0)
end

local function requestVehicleControl(vehicle)
    local timeout = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(vehicle)
        Wait(0)
    end
    return NetworkHasControlOfEntity(vehicle)
end

-- A garage vehicle is never accepted as spawned until its physical state is
-- known to be drivable. This deliberately avoids applying saved handling or
-- wheel-size data: those values can turn a valid GTA vehicle into a static
-- entity even when its engine health looks normal.
local function prepareVehicleForDriving(vehicle)
    requestVehicleControl(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleTyresCanBurst(vehicle, true)
    for wheel = 0, 7 do
        SetVehicleTyreFixed(vehicle, wheel)
    end
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    resetDriveState(vehicle)
    return IsVehicleDriveable(vehicle, false) and not IsEntityPositionFrozen(vehicle)
end

-- Briefly protect a newly spawned garage vehicle from another UI/script that
-- may leave the accelerator, brake or handbrake controls disabled that frame.
local function startDriveGuard(vehicle)
    spawnedVehicle = vehicle
    driveGuardUntil = GetGameTimer() + 10000
    lastDriveValidation = 0
end

local function requestModel(vehicleData)
    local candidates, seen = {}, {}
    local function addCandidate(value)
        if value == nil or value == '' then return end
        local hash = type(value) == 'number' and value or tonumber(value) or joaat(value)
        if hash ~= 0 and not seen[hash] then
            seen[hash] = true
            candidates[#candidates + 1] = hash
        end
    end

    -- The vehicle spawn code is authoritative; old database hashes can point to
    -- a different (but still valid) vehicle model after a server migration.
    addCandidate(vehicleData.vehicle)
    if type(vehicleData.vehicle) == 'string' then
        local shared = QBCore.Shared.Vehicles[vehicleData.vehicle] or QBCore.Shared.Vehicles[vehicleData.vehicle:lower()]
        if shared then addCandidate(shared.hash) end
    end
    addCandidate(vehicleData.hash)

    for _, hash in ipairs(candidates) do
        if IsModelInCdimage(hash) and IsModelAVehicle(hash) then
            RequestModel(hash)
            local timeout = GetGameTimer() + 10000
            while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
            if HasModelLoaded(hash) then return hash end
        end
    end
    return nil
end

RegisterNetEvent('vater-garage:client:spawnVehicle', function(vehicleData, spawn)
    if not isSpawnClear(spawn) then
        notify(Config.Text.spawnBlocked, 'error')
        TriggerServerEvent('vater-garage:server:spawnResult', vehicleData.plate, false)
        return
    end
    local model = requestModel(vehicleData)
    if not model then
        TriggerServerEvent('vater-garage:server:spawnResult', vehicleData.plate, false)
        return
    end
    -- Use the same creation path as QBCore's working vehicle spawner. It
    -- establishes a migratable network entity before the player enters it.
    local vehicle = nil
    -- Use an explicit vector4 so the garage heading is preserved end-to-end.
    local spawnCoords = vector4(spawn.x, spawn.y, spawn.z, spawn.w)
    QBCore.Functions.SpawnVehicle(model, function(createdVehicle)
        vehicle = createdVehicle
    end, spawnCoords, true, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(model)
        TriggerServerEvent('vater-garage:server:spawnResult', vehicleData.plate, false)
        return
    end
    if not prepareVehicleForDriving(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        SetModelAsNoLongerNeeded(model)
        notify('Araç sürüş için hazırlanamadı; garajda bırakıldı.', 'error')
        TriggerServerEvent('vater-garage:server:spawnResult', vehicleData.plate, false)
        return
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, true)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    -- Do not apply legacy `mods` here. These records include physics fields
    -- which have already produced undriveable vehicles. The clean native model
    -- is guaranteed to retain its normal handling and input response.
    SetVehicleFuelLevel(vehicle, math.max(tonumber(vehicleData.fuel) or 100.0, 10.0))
    resetDriveState(vehicle)
    SetVehRadioStation(vehicle, 'OFF')
    SetModelAsNoLongerNeeded(model)
    resetDriverState()
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    Wait(250)
    if GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        Wait(100)
    end
    resetDriverState()
    if not prepareVehicleForDriving(vehicle) or GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        notify('Araç sürüş için doğrulanamadı; garajda bırakıldı.', 'error')
        TriggerServerEvent('vater-garage:server:spawnResult', vehicleData.plate, false)
        return
    end
    TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle)))
    startDriveGuard(vehicle)
    TriggerServerEvent('vater-garage:server:spawnResult', vehicleData.plate, true, VehToNet(vehicle))
    notify(Config.Text.retrieved, 'success')
end)

RegisterNetEvent('vater-garage:client:deleteVehicle', function(netId)
    local vehicle = netId and NetToVeh(netId) or GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local timeout = GetGameTimer() + 1500
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do Wait(0); NetworkRequestControlOfEntity(vehicle) end
        DeleteVehicle(vehicle)
    end
end)

RegisterNetEvent('vater-garage:client:recoverVehicleCleanup', function(plate)
    if type(plate) ~= 'string' then return end
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle)) == plate then
            NetworkRequestControlOfEntity(vehicle)
            local timeout = GetGameTimer() + 1500
            while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
                Wait(0)
                NetworkRequestControlOfEntity(vehicle)
            end
            if NetworkHasControlOfEntity(vehicle) then
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteVehicle(vehicle)
            end
        end
    end
end)

RegisterNUICallback('close', function(_, cb) closeGarage(); cb(true) end)
RegisterNUICallback('takeOut', function(data, cb)
    if GetGameTimer() - lastSpawn < Config.TakeOutCooldown then cb(false) return end
    lastSpawn = GetGameTimer()
    closeGarage(); TriggerServerEvent('vater-garage:server:takeOut', data.plate, currentGarage); cb(true)
end)
RegisterNUICallback('favorite', function(data, cb) TriggerServerEvent('vater-garage:server:setFavorite', data.plate, data.favorite); cb(true) end)
RegisterNUICallback('transfer', function(data, cb) TriggerServerEvent('vater-garage:server:transfer', data.plate, data.targetId); cb(true) end)
RegisterNUICallback('recover', function(data, cb) TriggerServerEvent('vater-garage:server:recoverVehicle', data.plate); cb(true) end)

CreateThread(function()
    local controls = { 59, 60, 61, 62, 63, 64, 71, 72, 75, 76 }
    while true do
        if spawnedVehicle and GetGameTimer() < driveGuardUntil and DoesEntityExist(spawnedVehicle) then
            local ped = PlayerPedId()
            if GetPedInVehicleSeat(spawnedVehicle, -1) == ped then
                for group = 0, 2 do
                    for _, control in ipairs(controls) do EnableControlAction(group, control, true) end
                end

                -- Never alter speed, RPM, torque or gravity here. A control
                -- guard must only re-enable input; changing physics while W
                -- is held can itself keep a newly spawned vehicle stationary.
                if IsControlPressed(0, 71) and GetGameTimer() - lastDriveValidation > 500 then
                    if not GetIsVehicleEngineRunning(spawnedVehicle) then
                        SetVehicleEngineOn(spawnedVehicle, true, true, false)
                    end
                    if not IsVehicleDriveable(spawnedVehicle, false) then
                        prepareVehicleForDriving(spawnedVehicle)
                    end
                    lastDriveValidation = GetGameTimer()
                end
            end
            Wait(0)
        else
            spawnedVehicle = nil
            Wait(500)
        end
    end
end)

CreateThread(function()
    for id, garage in pairs(Config.Garages) do
        local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
        SetBlipSprite(blip, garage.blip.sprite); SetBlipDisplay(blip, 4); SetBlipScale(blip, garage.blip.scale); SetBlipColour(blip, garage.blip.colour)
        SetBlipAsShortRange(blip, true); BeginTextCommandSetBlipName('STRING'); AddTextComponentString('Vater Garage | ' .. garage.label); EndTextCommandSetBlipName(blip)
        blips[id] = blip
        garagePedCoords[id] = getGaragePedCoords(garage)
        garagePeds[id] = createGaragePed(garage, garagePedCoords[id])
        if Config.UseTarget then
            exports['qb-target']:AddBoxZone('vater_garage_' .. id, garage.coords, 2.4, 2.4, { name = 'vater_garage_' .. id, heading = 0, debugPoly = Config.Debug, minZ = garage.coords.z - 1.0, maxZ = garage.coords.z + 1.5 }, {
                options = {
                    { icon = 'fas fa-warehouse', label = garage.label .. ' Garajı', action = function() openGarage(id) end, canInteract = function() return not IsPedInAnyVehicle(PlayerPedId(), false) end },
                    { icon = 'fas fa-square-parking', label = 'Aracı Garaja Koy', action = function() storeCurrentVehicle(id) end, canInteract = function() return IsPedInAnyVehicle(PlayerPedId(), false) and GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId() end }
                }, distance = 2.0
            })
        end
    end
    RegisterCommand(Config.Command, function() openGarage(Config.DefaultGarage) end, false)
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if not uiOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            local inVehicle = vehicle ~= 0
            for id, garage in pairs(Config.Garages) do
                if not inVehicle then
                    local npcCoords = garagePedCoords[id] or getGaragePedCoords(garage)
                    local distance = #(coords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))
                    if distance < Config.DrawDistance then
                        sleep = 200
                        if distance < Config.InteractionDistance then
                            sleep = 0
                            drawText(vector3(npcCoords.x, npcCoords.y, npcCoords.z + 1.08), Config.Text.open)
                            if IsControlJustReleased(0, 38) then openGarage(id) end
                        end
                    end
                elseif GetPedInVehicleSeat(vehicle, -1) == ped then
                    local store = garage.store or garage.coords
                    local distance = #(coords - store)
                    if distance < Config.DrawDistance then
                        sleep = 0
                        local marker = Config.ParkingMarker
                        DrawMarker(marker.type, store.x, store.y, store.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, marker.scale.x, marker.scale.y, marker.scale.z, marker.colour.r, marker.colour.g, marker.colour.b, marker.colour.a, false, false, 2, false, nil, nil, false)
                        if distance < Config.InteractionDistance + 1.0 then
                            drawText(vector3(store.x, store.y, store.z + 0.45), Config.Text.store)
                            if IsControlJustReleased(0, 38) then storeCurrentVehicle(id) end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, ped in pairs(garagePeds) do
        if ped and DoesEntityExist(ped) then DeletePed(ped) end
    end
end)

CreateThread(function()
    while true do
        if uiOpen then
            if IsControlJustReleased(0, 200) then closeGarage() end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
