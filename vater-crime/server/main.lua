-- ====================================================================
-- VATER SCRIPTS - 3D Scene Reconstruction / Holographic Replay System
-- ULTRA OPTIMIZED SERVER ENGINE (Indexed DB Queries & Memory Efficiency)
-- ====================================================================

local QBCore = nil
local ESX = nil

-- Framework Detection & Setup
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

    -- Auto Database Setup via oxmysql
    CreateThread(function()
        while GetResourceState('oxmysql') ~= 'started' do
            Wait(100)
        end

        local sqlQuery = [[
            CREATE TABLE IF NOT EXISTS `crime_scene_reconstructions` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `incident_id` VARCHAR(64) UNIQUE NOT NULL,
                `incident_name` VARCHAR(128) DEFAULT 'Olay Yeri Kaydı',
                `created_at` BIGINT DEFAULT 0,
                `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `location_x` FLOAT NOT NULL,
                `location_y` FLOAT NOT NULL,
                `location_z` FLOAT NOT NULL,
                `trigger_type` VARCHAR(32) NOT NULL,
                `recorded_by` VARCHAR(64) NOT NULL,
                `data` LONGTEXT NOT NULL,
                INDEX `idx_created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]

        MySQL.query(sqlQuery, {}, function()
            MySQL.query("SHOW COLUMNS FROM `crime_scene_reconstructions` LIKE 'created_at'", {}, function(cols)
                if not cols or #cols == 0 then
                    MySQL.query("ALTER TABLE `crime_scene_reconstructions` ADD COLUMN `created_at` BIGINT DEFAULT 0 AFTER `incident_name`", {}, function()
                        print('^2[vater-crime]^7 Veritabanı tablosu `crime_scene_reconstructions` hazırlandı (created_at kolonu eklendi).')
                    end)
                else
                    print('^2[vater-crime]^7 Veritabanı tablosu `crime_scene_reconstructions` doğrulandı/hazırlandı.')
                end
            end)
        end)
    end)
end)

-- Background Routine: Clean old incident logs (> 24 hours) to maintain fast DB queries
CreateThread(function()
    while true do
        Wait(3600000) -- Check every 1 hour
        local expireThreshold = os.time() - 86400
        MySQL.query('DELETE FROM `crime_scene_reconstructions` WHERE `created_at` > 0 AND `created_at` < ?', { expireThreshold })
    end
end)

-- Helper: Check Permission
local function HasPermission(src)
    if IsPlayerAceAllowed(src, 'command.' .. Config.CommandName) then
        return true
    end

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.job then
            local jobName = Player.PlayerData.job.name
            local jobGrade = (Player.PlayerData.job.grade and Player.PlayerData.job.grade.level) or 0
            if Config.AllowedJobs[jobName] and jobGrade >= Config.AllowedJobs[jobName] then
                return true
            end
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            local jobName = xPlayer.job.name
            local jobGrade = xPlayer.job.grade or 0
            if Config.AllowedJobs[jobName] and jobGrade >= Config.AllowedJobs[jobName] then
                return true
            end
        end
    else
        return true
    end

    return false
end

-- Internal Helper to Send Nearby List (Filtered in MySQL with spatial distance)
local function SendNearbyList(src, playerCoords)
    if not playerCoords then return end

    local maxAgeSeconds = (Config.MaxIncidentAgeMinutes or 10) * 60
    local nowUnix = os.time()
    local minCreatedAt = nowUnix - maxAgeSeconds

    local query = [[
        SELECT id, incident_id, incident_name, created_at, timestamp, location_x, location_y, location_z, trigger_type, recorded_by
        FROM crime_scene_reconstructions 
        WHERE (created_at >= ? OR created_at = 0 OR created_at IS NULL)
        ORDER BY id DESC LIMIT 50
    ]]

    MySQL.query(query, { minCreatedAt }, function(results)
        local nearbyList = {}
        if results and type(results) == 'table' then
            local px = tonumber(playerCoords.x) or 0.0
            local py = tonumber(playerCoords.y) or 0.0
            local pz = tonumber(playerCoords.z) or 0.0
            local maxRange = (Config.ScannerRadius or 35.0) + 100.0

            for i = 1, #results do
                local row = results[i]
                local lx = tonumber(row.location_x) or 0.0
                local ly = tonumber(row.location_y) or 0.0
                local lz = tonumber(row.location_z) or 0.0

                local dx = lx - px
                local dy = ly - py
                local dz = lz - pz
                local dist = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))

                if dist <= maxRange then
                    nearbyList[#nearbyList + 1] = {
                        id = row.id,
                        serialId = row.incident_id,
                        name = row.incident_name or 'Olay Yeri Kaydı',
                        timestamp = tostring(row.timestamp),
                        coords = { x = lx, y = ly, z = lz },
                        distance = math.floor(dist),
                        triggerType = row.trigger_type,
                        recordedBy = row.recorded_by
                    }
                end
            end
        end

        TriggerClientEvent('vater-crime:client:receiveNearbyIncidents', src, nearbyList)
    end)
end

-- Save Incident Event
RegisterNetEvent('vater-crime:server:saveIncident', function(incidentData)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
        return
    end

    if not incidentData or not incidentData.coords or not incidentData.buffer then
        TriggerClientEvent('vater-crime:client:notify', src, 'Olay verisi geçersiz veya eksik!', 'error')
        return
    end

    local serialId = 'SN-' .. os.date('%Y%m%d') .. '-' .. string.upper(string.sub(tostring(math.random(100000, 999999)), 1, 6))
    local incidentName = (incidentData.name and incidentData.name ~= '') and incidentData.name or 'Olay Yeri Kaydı'
    local coords = incidentData.coords
    local posX = tonumber(coords.x) or 0.0
    local posY = tonumber(coords.y) or 0.0
    local posZ = tonumber(coords.z) or 0.0
    local triggerType = incidentData.triggerType or 'manual_scan'
    local playerIdentifier = GetPlayerName(src) .. ' (' .. src .. ')'
    local currentUnix = os.time()

    local jsonSuccess, jsonBuffer = pcall(json.encode, incidentData.buffer)
    if not jsonSuccess or not jsonBuffer then
        print('^1[vater-crime] Hata: Olay verileri JSON formatına dönüştürülemedi!^7')
        TriggerClientEvent('vater-crime:client:notify', src, 'Olay verisi kaydedilirken format hatası oluştu!', 'error')
        return
    end

    local query = [[
        INSERT INTO `crime_scene_reconstructions` 
        (`incident_id`, `incident_name`, `created_at`, `location_x`, `location_y`, `location_z`, `trigger_type`, `recorded_by`, `data`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]

    MySQL.insert(query, {
        serialId,
        incidentName,
        currentUnix,
        posX,
        posY,
        posZ,
        triggerType,
        playerIdentifier,
        jsonBuffer
    }, function(insertId)
        if insertId and insertId > 0 then
            TriggerClientEvent('vater-crime:client:notify', src, (Config.Locale['incident_saved'] or 'Olay yeri kaydı oluşturuldu! ID: ') .. serialId, 'success')
            SendNearbyList(src, { x = posX, y = posY, z = posZ })
        else
            TriggerClientEvent('vater-crime:client:notify', src, 'Veritabanına kayıt yapılamadı!', 'error')
        end
    end)
end)

-- Fetch Nearby Incidents RPC
RegisterNetEvent('vater-crime:server:getNearbyIncidents', function(playerCoords)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
        return
    end

    SendNearbyList(src, playerCoords)
end)

-- Delete Incident Event
RegisterNetEvent('vater-crime:server:deleteIncident', function(dbId)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
        return
    end

    local query = [[ DELETE FROM crime_scene_reconstructions WHERE id = ? ]]
    MySQL.update(query, { dbId }, function(affectedRows)
        TriggerClientEvent('vater-crime:client:notify', src, 'Olay yeri kaydı silindi.', 'success')

        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        SendNearbyList(src, { x = coords.x, y = coords.y, z = coords.z })
    end)
end)

-- Load Specific Incident Data
RegisterNetEvent('vater-crime:server:loadIncident', function(dbId)
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
        return
    end

    local query = [[ 
        SELECT incident_id, incident_name, created_at, timestamp, location_x, location_y, location_z, trigger_type, data 
        FROM crime_scene_reconstructions 
        WHERE id = ? 
    ]]
    MySQL.query(query, { dbId }, function(results)
        if results and results[1] then
            local row = results[1]
            local createdAt = tonumber(row.created_at) or 0
            local maxAgeSeconds = (Config.MaxIncidentAgeMinutes or 10) * 60
            local nowUnix = os.time()

            if createdAt > 0 and (nowUnix - createdAt) > maxAgeSeconds then
                TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['incident_expired'] or 'Bu olay yerinin üzerinden 10 dakikadan fazla zaman geçtiği için inceleme süresi dolmuştur!', 'error')
                return
            end

            local success, bufferData = pcall(json.decode, row.data)
            if success and bufferData then
                TriggerClientEvent('vater-crime:client:startPlayback', src, {
                    serialId = row.incident_id,
                    name = row.incident_name or 'Olay Yeri Kaydı',
                    timestamp = tostring(row.timestamp),
                    coords = { x = tonumber(row.location_x), y = tonumber(row.location_y), z = tonumber(row.location_z) },
                    triggerType = row.trigger_type,
                    buffer = bufferData
                })
            else
                print('^1[vater-crime] Hata: Olay verisi decode edilemedi!^7')
                TriggerClientEvent('vater-crime:client:notify', src, 'Olay verisi yüklenirken format hatası oluştu!', 'error')
            end
        end
    end)
end)

-- Usable Item Registration
CreateThread(function()
    if QBCore then
        QBCore.Functions.CreateUseableItem(Config.ScannerItem, function(source, item)
            local src = source
            if HasPermission(src) then
                TriggerClientEvent('vater-crime:client:useScannerTool', src)
            else
                TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
            end
        end)
    elseif ESX then
        ESX.RegisterUsableItem(Config.ScannerItem, function(source)
            local src = source
            if HasPermission(src) then
                TriggerClientEvent('vater-crime:client:useScannerTool', src)
            else
                TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
            end
        end)
    end
end)

-- Command Handler
if Config.EnableCommand then
    RegisterCommand(Config.CommandName, function(source, args, rawCommand)
        local src = source
        if HasPermission(src) then
            TriggerClientEvent('vater-crime:client:useScannerTool', src)
        else
            TriggerClientEvent('vater-crime:client:notify', src, Config.Locale['no_permission'], 'error')
        end
    end, false)
end

