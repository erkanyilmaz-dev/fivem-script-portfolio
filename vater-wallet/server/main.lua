local QBCore = exports['qb-core']:GetCoreObject()

-- QBCore Eşya Kullanımı
if Config.UseItem then
    QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
        TriggerClientEvent('vater-wallet:client:openWallet', source)
    end)
end

-- Cüzdan Verilerini Getiren Server Callback
QBCore.Functions.CreateCallback('vater-wallet:server:getWalletData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end

    local pData = Player.PlayerData
    local charinfo = pData.charinfo or {}
    local money = pData.money or {}
    local licenses = pData.metadata['licences'] or {}
    local job = pData.job or {}

    -- Cüzdanda gösterilecek profil fotoğrafı (Varsayılan veya Discord/Custom URL)
    local avatar = pData.metadata['avatar'] or pData.metadata['profile_photo'] or Config.DefaultAvatar

    -- Banka Hesap Numarası
    local bankAccount = charinfo.account or ("US" .. math.random(1000, 9999) .. " " .. math.random(1000, 9999) .. " " .. math.random(1000, 9999))

    local walletPayload = {
        cash = money.cash or 0,
        bank = money.bank or 0,
        charinfo = {
            firstname = charinfo.firstname or "Bilinmiyor",
            lastname = charinfo.lastname or "Bilinmiyor",
            birthdate = charinfo.birthdate or "01/01/1995",
            gender = (charinfo.gender == 0 and Config.Locales.gender_male or Config.Locales.gender_female),
            nationality = charinfo.nationality or "Los Santos",
            citizenid = pData.citizenid or "SA00000",
            phone = charinfo.phone or "555-0100",
            job = job.label or "İşsiz",
            jobGrade = (job.grade and job.grade.name) or "Vatandaş"
        },
        avatar = avatar,
        bankAccount = bankAccount,
        licenses = {
            id_card = true, -- Her zaman var
            driver = licenses.driver or false,
            business = licenses.business or false,
            weapon = licenses.weapon or false,
            lawyer = (licenses.lawyer or job.name == 'lawyer') or false,
            vip = (licenses.vip or pData.metadata['vip']) or false
        }
    }

    cb(walletPayload)
end)

-- Yakındaki Oyuncuya Kart Gösterme Eventi
RegisterNetEvent('vater-wallet:server:showCard', function(cardPayload)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local pData = Player.PlayerData
    local charinfo = pData.charinfo or {}
    local ownerName = charinfo.firstname .. ' ' .. charinfo.lastname
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local targetFound = false
    local players = QBCore.Functions.GetPlayers()

    for _, targetSrc in ipairs(players) do
        if targetSrc ~= src then
            local targetPed = GetPlayerPed(targetSrc)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(coords - targetCoords)

            if dist <= Config.ShowDistance then
                targetFound = true
                TriggerClientEvent('vater-wallet:client:viewTargetCard', targetSrc, cardPayload, ownerName)
            end
        end
    end

    if targetFound then
        TriggerClientEvent('QBCore:Notify', src, Config.Locales.card_shown, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Config.Locales.no_player_nearby, 'error')
    end
end)
