local QBCore = exports['qb-core']:GetCoreObject()

local function GetPlayersInSpawnPoints()
    local counts = {}
    -- Initialize counts to 0
    for k, v in pairs(Config.Spawns) do
        counts[k] = 0
    end
    
    local activePlayers = QBCore.Functions.GetPlayers()
    for i = 1, #activePlayers do
        local src = activePlayers[i]
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local coords = GetEntityCoords(ped)
            for k, v in pairs(Config.Spawns) do
                local spawnCoords = vector3(v.coords.x, v.coords.y, v.coords.z)
                local dist = #(coords - spawnCoords)
                if dist < 200.0 then
                    counts[k] = counts[k] + 1
                end
            end
        end
    end
    return counts
end

-- Callback to get player owned houses for spawn selector
QBCore.Functions.CreateCallback('qb-spawn:server:getOwnedHouses', function(source, cb, cid)
    local playerCounts = GetPlayersInSpawnPoints()
    if cid ~= nil then
        local success, result = pcall(function()
            return MySQL.query.await('SELECT * FROM player_houses WHERE citizenid = ?', { cid })
        end)
        if success and result and result[1] ~= nil then
            cb(result, playerCounts)
        else
            cb({}, playerCounts)
        end
    else
        cb({}, playerCounts)
    end
end)
