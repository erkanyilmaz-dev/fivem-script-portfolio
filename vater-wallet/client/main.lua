local QBCore = exports['qb-core']:GetCoreObject()
local isWalletOpen = false

-- Cüzdanı Açma Fonksiyonu
local function OpenWallet()
    if isWalletOpen then return end

    QBCore.Functions.TriggerCallback('vater-wallet:server:getWalletData', function(data)
        if not data then return end

        isWalletOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openWallet',
            data = data,
            config = Config
        })
    end)
end

-- Cüzdan Kapatma Fonksiyonu
local function CloseWallet()
    if not isWalletOpen then return end
    isWalletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeWallet'
    })
end

-- Komut ve Tuş Ataması
RegisterCommand(Config.Command, function()
    if isWalletOpen then
        CloseWallet()
    else
        OpenWallet()
    end
end, false)

RegisterKeyMapping(Config.Command, 'Cüzdanı Aç / Kapat', 'keyboard', Config.OpenKey)

-- Item Kullanımı veya Event İle Açma
RegisterNetEvent('vater-wallet:client:openWallet', function()
    OpenWallet()
end)

-- NUI Callbacks
RegisterNUICallback('closeWallet', function(data, cb)
    CloseWallet()
    cb('ok')
end)

RegisterNUICallback('showCardToNearby', function(data, cb)
    if not data or not data.cardType then 
        cb('error')
        return 
    end
    
    TriggerServerEvent('vater-wallet:server:showCard', data)
    cb('ok')
end)

-- Başkasının Gösterdiği Kartı Görüntüleme Eventi
RegisterNetEvent('vater-wallet:client:viewTargetCard', function(cardData, ownerName)
    QBCore.Functions.Notify(ownerName .. ' size bir kart gösterdi.', 'info', 5000)
    
    SendNUIMessage({
        action = 'showTargetCard',
        cardData = cardData,
        ownerName = ownerName,
        config = Config
    })
end)

-- NUI Kapatma tuşu (ESC) dinleyici için güvenlik ekleme
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if isWalletOpen then
        SetNuiFocus(false, false)
    end
end)
