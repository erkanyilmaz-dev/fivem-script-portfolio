local QBCore = exports['qb-core']:GetCoreObject()
local activeSpawns = {}
local pendingSpawns = {}

local function getGarage(id)
    return Config.Garages[id]
end

local function isAllowed(Player, garage)
    if not garage then return false end
    if garage.type == 'public' then return true end
    if garage.type == 'job' then return Player.PlayerData.job and Player.PlayerData.job.name == garage.job end
    if garage.type == 'gang' then return Player.PlayerData.gang and Player.PlayerData.gang.name == garage.gang end
    return false
end

local function nearGarage(source, garageId)
    local garage = getGarage(garageId)
    if not garage then return false end
    local ped = GetPlayerPed(source)
    if ped <= 0 then return true end
    return #(GetEntityCoords(ped) - garage.coords) <= Config.StoreRadius
end

local function notify(source, message, kind)
    TriggerClientEvent('QBCore:Notify', source, message, kind or 'primary')
end

local function decodeProps(row)
    local ok, properties = pcall(json.decode, row.mods or '{}')
    row.properties = ok and properties or {}
    row.fuel = tonumber(row.fuel) or row.properties.fuelLevel or 100
    row.engine = tonumber(row.engine) or 1000
    row.body = tonumber(row.body) or 1000
    -- Missing state values from older rows are safest treated as stored, not outside.
    row.state = tonumber(row.state)
    if row.state == nil then row.state = 1 end
    row.favorite = tonumber(row.favorite) == 1
    local sharedVehicle = type(row.vehicle) == 'string' and QBCore.Shared.Vehicles[row.vehicle:lower()] or nil
    row.displayName = sharedVehicle and (sharedVehicle.brand .. ' ' .. sharedVehicle.name) or row.vehicle or 'Unknown Vehicle'
    return row
end

-- Do not persist transient wheel/tyre physics. QBCore reports stock wheel
-- dimensions as 0.0 on this build, and restoring them can corrupt handling.
local function sanitizeStoredProperties(properties)
    if type(properties) ~= 'table' then return {} end
    local transientPhysics = {
        wheelSize = true,
        wheelWidth = true,
        tireHealth = true,
        tireBurstState = true,
        tireBurstCompletely = true,
    }
    local sanitized = {}
    for key, value in pairs(properties) do
        if not transientPhysics[key] then sanitized[key] = value end
    end
    return sanitized
end

QBCore.Functions.CreateCallback('vater-garage:server:getVehicles', function(source, cb, garageId)
    local Player = QBCore.Functions.GetPlayer(source)
    local garage = getGarage(garageId)
    if not Player or not isAllowed(Player, garage) then
        cb({ ok = false, message = Config.Text.noAccess })
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local query = 'SELECT plate, vehicle, hash, mods, garage, state, fuel, engine, body, depotprice, favorite FROM player_vehicles WHERE citizenid = ?'
    local params = { citizenid }
    if garage.type == 'job' then
        query = query .. ' AND job = ?'
        params[#params + 1] = garage.job
    elseif garage.type == 'gang' then
        query = query .. ' AND gang = ?'
        params[#params + 1] = garage.gang
    else
        query = query .. ' AND (job IS NULL OR job = "") AND (gang IS NULL OR gang = "")'
    end

    local rows = MySQL.query.await(query, params) or {}
    for i = 1, #rows do rows[i] = decodeProps(rows[i]) end
    cb({ ok = true, garage = { id = garageId, label = garage.label, type = garage.type }, vehicles = rows })
end)

RegisterNetEvent('vater-garage:server:takeOut', function(plate, garageId)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local garage = getGarage(garageId)
    if not Player or not isAllowed(Player, garage) or not nearGarage(source, garageId) then return end
    if type(plate) ~= 'string' or #plate > 16 then return end

    if pendingSpawns[plate] then
        notify(source, 'Bu araç zaten çıkarılmaya hazırlanıyor.', 'error')
        return
    end

    local row = MySQL.single.await('SELECT plate, vehicle, hash, mods, garage, state, fuel, engine, body, depotprice, favorite FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    if not row then notify(source, Config.Text.notOwner, 'error') return end
    row = decodeProps(row)
    if row.state == 0 then notify(source, 'Bu araç zaten dışarıda.', 'error') return end

    local fee = tonumber(row.depotprice) or 0
    if row.state == 2 and fee > 0 then
        if (Player.PlayerData.money.bank or 0) < fee then
            notify(source, ('Çekici ücreti için $%s banka hesabında olmalı.'):format(fee), 'error')
            return
        end
    end

    -- State is updated only after the client has actually created the vehicle.
    -- This prevents a failed model load from leaving a phantom “outside” vehicle.
    local pending = { source = source, citizenid = Player.PlayerData.citizenid, fee = fee }
    pendingSpawns[plate] = pending
    TriggerClientEvent('vater-garage:client:spawnVehicle', source, row, garage.spawn)
    SetTimeout(15000, function()
        if pendingSpawns[plate] == pending then
            pendingSpawns[plate] = nil
            notify(source, 'Araç çıkarma isteği zaman aşımına uğradı. Araç garajda kaldı.', 'error')
        end
    end)
end)

RegisterNetEvent('vater-garage:server:spawnResult', function(plate, success, netId)
    local source = source
    if type(plate) ~= 'string' then return end
    local pending = pendingSpawns[plate]
    if not pending or pending.source ~= source then return end
    pendingSpawns[plate] = nil

    if success ~= true then
        notify(source, 'Araç oluşturulamadı. Araç garajda tutuldu; model kaydını kontrol et.', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or Player.PlayerData.citizenid ~= pending.citizenid then
        TriggerClientEvent('vater-garage:client:deleteVehicle', source, netId)
        return
    end

    local changed = MySQL.update.await('UPDATE player_vehicles SET state = 0, depotprice = 0 WHERE plate = ? AND citizenid = ? AND state <> 0', { plate, pending.citizenid })
    if not changed or changed < 1 then
        TriggerClientEvent('vater-garage:client:deleteVehicle', source, netId)
        notify(source, 'Araç durumu doğrulanamadı. Araç garajda bırakıldı.', 'error')
        return
    end

    if pending.fee > 0 and not Player.Functions.RemoveMoney('bank', pending.fee, 'vater-garage-impound') then
        MySQL.update.await('UPDATE player_vehicles SET state = 2, depotprice = ? WHERE plate = ? AND citizenid = ?', { pending.fee, plate, pending.citizenid })
        TriggerClientEvent('vater-garage:client:deleteVehicle', source, netId)
        notify(source, 'Çekici ücreti alınamadı. Araç çekicide kaldı.', 'error')
        return
    end

    activeSpawns[plate] = source
end)

RegisterNetEvent('vater-garage:server:storeVehicle', function(payload)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or type(payload) ~= 'table' then return end
    local garage = getGarage(payload.garageId)
    local plate = type(payload.plate) == 'string' and payload.plate:sub(1, 16) or nil
    if not plate or not isAllowed(Player, garage) or not nearGarage(source, payload.garageId) then
        notify(source, Config.Text.tooFar, 'error')
        return
    end

    local owned = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    if not owned then notify(source, Config.Text.notOwner, 'error') return end

    local props = sanitizeStoredProperties(payload.properties)
    local fuel = math.floor(tonumber(payload.fuel) or props.fuelLevel or 100)
    local engine = math.floor(tonumber(payload.engine) or props.engineHealth or 1000)
    local body = math.floor(tonumber(payload.body) or props.bodyHealth or 1000)
    MySQL.update.await('UPDATE player_vehicles SET mods = ?, fuel = ?, engine = ?, body = ?, garage = ?, state = 1, depotprice = 0 WHERE plate = ? AND citizenid = ?', {
        json.encode(props), fuel, engine, body, payload.garageId, plate, Player.PlayerData.citizenid
    })
    activeSpawns[plate] = nil
    TriggerClientEvent('vater-garage:client:deleteVehicle', source, payload.netId)
    notify(source, Config.Text.stored, 'success')
end)

RegisterNetEvent('vater-garage:server:setFavorite', function(plate, favorite)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or type(plate) ~= 'string' then return end
    MySQL.update.await('UPDATE player_vehicles SET favorite = ? WHERE plate = ? AND citizenid = ?', { favorite and 1 or 0, plate, Player.PlayerData.citizenid })
end)

-- Return a missing/stuck vehicle to the garage. If it is the owner's spawned
-- vehicle, ask that client to remove the physical entity first to avoid dupes.
RegisterNetEvent('vater-garage:server:recoverVehicle', function(plate)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or type(plate) ~= 'string' or #plate > 16 then return end
    if activeSpawns[plate] and activeSpawns[plate] ~= source then
        notify(source, 'Araç başka bir oyuncu tarafından kullanılıyor.', 'error')
        return
    end

    TriggerClientEvent('vater-garage:client:recoverVehicleCleanup', source, plate)
    Wait(200)

    local changed = MySQL.update.await('UPDATE player_vehicles SET state = 1, garage = ?, depotprice = 0 WHERE plate = ? AND citizenid = ? AND state = 0', {
        Config.DefaultGarage, plate, Player.PlayerData.citizenid
    })
    if not changed or changed < 1 then
        notify(source, 'Araç kurtarma için uygun değil.', 'error')
        return
    end
    activeSpawns[plate] = nil
    notify(source, Config.Text.recoverQueued, 'success')
end)

RegisterNetEvent('vater-garage:server:transfer', function(plate, targetId)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    targetId = tonumber(targetId)
    if not Player or type(plate) ~= 'string' or not targetId or targetId < 1 or targetId % 1 ~= 0 then return end
    targetId = math.floor(targetId)
    if targetId == source then notify(source, Config.Text.invalidPlayerId, 'error') return end

    -- Server ID is resolved here so Citizen ID is never trusted from the NUI/client.
    local Recipient = QBCore.Functions.GetPlayer(targetId)
    if not Recipient then notify(source, Config.Text.invalidPlayerId, 'error') return end

    local owned = MySQL.single.await('SELECT plate, state FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid })
    if not owned then notify(source, Config.Text.notOwner, 'error') return end
    if tonumber(owned.state) ~= 1 then notify(source, Config.Text.vehicleMustBeStored, 'error') return end
    if Config.TransferFee > 0 and not Player.Functions.RemoveMoney('bank', Config.TransferFee, 'vater-garage-transfer') then
        notify(source, ('Araç devri için $%s gerekli.'):format(Config.TransferFee), 'error')
        return
    end
    MySQL.update.await('UPDATE player_vehicles SET citizenid = ?, state = 1, garage = ?, favorite = 0 WHERE plate = ? AND citizenid = ?', { Recipient.PlayerData.citizenid, Config.DefaultGarage, plate, Player.PlayerData.citizenid })
    activeSpawns[plate] = nil
    notify(source, Config.Text.transferDone, 'success')
    notify(targetId, ('%s plakalı araç sana devredildi.'):format(plate), 'success')
end)

AddEventHandler('playerDropped', function()
    local source = source
    for plate, owner in pairs(activeSpawns) do if owner == source then activeSpawns[plate] = nil end end
    for plate, pending in pairs(pendingSpawns) do if pending.source == source then pendingSpawns[plate] = nil end end
end)
