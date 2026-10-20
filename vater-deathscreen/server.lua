local QBCore = exports['qb-core']:GetCoreObject()

local function GetDiscordAvatar(src, cb)
    local discordId = nil
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.match(id, "discord:") then
            discordId = string.gsub(id, "discord:", "")
            break
        end
    end

    if not discordId then
        cb(nil)
        return
    end

    PerformHttpRequest("https://discordlookup.mesavanc.co/v1/user/" .. discordId, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local data = json.decode(response)
            if data and data.avatar and data.avatar.link then
                cb(data.avatar.link)
                return
            end
        end
        cb(nil)
    end, "GET")
end

RegisterNetEvent('vater-deathscreen:server:onDeath', function(killerServerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Mark player as dead in QBCore metadata
    Player.Functions.SetMetaData('isdead', true)
    Player.Functions.SetMetaData('inlaststand', false)

    local killerName = ""
    local killerId = -1

    if killerServerId and killerServerId ~= -1 and killerServerId ~= src then
        local nickname = GetPlayerName(killerServerId)
        if nickname and nickname ~= "" then
            killerName = nickname
        else
            local KillerPlayer = QBCore.Functions.GetPlayer(killerServerId)
            if KillerPlayer then
                killerName = KillerPlayer.PlayerData.charinfo.firstname .. " " .. KillerPlayer.PlayerData.charinfo.lastname
            else
                killerName = "Bilinmeyen Katil"
            end
        end
        killerId = killerServerId

        -- Send initial screen with placeholder avatar instantly
        TriggerClientEvent('vater-deathscreen:client:showDeathScreen', src, killerName, killerId, "")

        -- Fetch avatar asynchronously
        GetDiscordAvatar(killerServerId, function(avatarUrl)
            if avatarUrl then
                TriggerClientEvent('vater-deathscreen:client:updateKillerAvatar', src, avatarUrl)
            end
        end)
        return
    end

    -- Default if suicide / NPC / self-kill
    TriggerClientEvent('vater-deathscreen:client:showDeathScreen', src, "", -1, "")
end)

RegisterNetEvent('vater-deathscreen:server:respawnPlayer', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Reset QBCore death metadata
    Player.Functions.SetMetaData('isdead', false)
    Player.Functions.SetMetaData('inlaststand', false)

    -- Wipe all inventory items
    exports['qb-inventory']:ClearInventory(src)

    -- Trigger client-side revive and teleport
    TriggerClientEvent('vater-deathscreen:client:reviveAndRespawn', src)
end)

-- Admin commands/events support for Revive
RegisterNetEvent('hospital:client:Revive', function()
    -- Forward to deathscreen client side
    local src = source
    TriggerClientEvent('vater-deathscreen:client:reviveSilent', src)
end)
