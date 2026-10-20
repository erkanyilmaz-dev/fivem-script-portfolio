local QBCore = exports['qb-core']:GetCoreObject()

-- Araç Tamiri Ödeme Doğrulaması
QBCore.Functions.CreateCallback("vater-mechanic:server:repairVehicle", function(source, cb, cost)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(false, Lang:t("error.cannot_afford", { cost })) return end

    cost = tonumber(cost) or 0

    if cost <= 0 then
        cb(true)
        return
    end

    if Player.Functions.GetMoney("cash") >= cost then
        Player.Functions.RemoveMoney("cash", cost, "vater-mechanic-repair")
        TriggerClientEvent("QBCore:Notify", src, Lang:t("success.repaired") .. " (-" .. cost .. " $)", "success")
        cb(true)
    elseif Player.Functions.GetMoney("bank") >= cost then
        Player.Functions.RemoveMoney("bank", cost, "vater-mechanic-repair")
        TriggerClientEvent("QBCore:Notify", src, Lang:t("success.repaired") .. " (-" .. cost .. " $)", "success")
        cb(true)
    else
        cb(false, Lang:t("error.cannot_afford", { cost }))
    end
end)

-- Araç Yıkama Ödeme Doğrulaması
QBCore.Functions.CreateCallback("vater-mechanic:server:cleanVehicle", function(source, cb, cost)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(false) return end

    cost = tonumber(cost) or Config.WashPrice or 150

    if Player.Functions.GetMoney("cash") >= cost then
        Player.Functions.RemoveMoney("cash", cost, "vater-mechanic-wash")
        TriggerClientEvent("QBCore:Notify", src, Lang:t("success.cleaned") .. " (-" .. cost .. " $)", "success")
        cb(true)
    elseif Player.Functions.GetMoney("bank") >= cost then
        Player.Functions.RemoveMoney("bank", cost, "vater-mechanic-wash")
        TriggerClientEvent("QBCore:Notify", src, Lang:t("success.cleaned") .. " (-" .. cost .. " $)", "success")
        cb(true)
    else
        cb(false, Lang:t("error.cannot_afford", { cost }))
    end
end)

-- Sepet Ödeme & Veritabanına Kaydetme
QBCore.Functions.CreateCallback("vater-mechanic:server:checkoutCart", function(source, cb, totalPrice, paymentMethod, vehicleProps, cartItems)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(false, "Oyuncu bulunamadı") return end

    totalPrice = tonumber(totalPrice) or 0
    paymentMethod = paymentMethod or "cash"

    -- Ücretsiz ise direkt kaydet
    if totalPrice <= 0 then
        if Config.SaveToDatabase and vehicleProps and vehicleProps.plate then
            local plate = string.gsub(vehicleProps.plate, "^%s*(.-)%s*$", "%1")
            MySQL.update("UPDATE player_vehicles SET mods = ? WHERE plate = ?", {
                json.encode(vehicleProps),
                plate
            })
        end
        cb(true)
        return
    end

    -- Bakiye Kontrolü
    local hasMoney = false
    if paymentMethod == "bank" then
        if Player.Functions.GetMoney("bank") >= totalPrice then
            Player.Functions.RemoveMoney("bank", totalPrice, "vater-mechanic-customs")
            hasMoney = true
        end
    else
        if Player.Functions.GetMoney("cash") >= totalPrice then
            Player.Functions.RemoveMoney("cash", totalPrice, "vater-mechanic-customs")
            hasMoney = true
        elseif Player.Functions.GetMoney("bank") >= totalPrice then
            Player.Functions.RemoveMoney("bank", totalPrice, "vater-mechanic-customs")
            hasMoney = true
        end
    end

    if not hasMoney then
        cb(false, Lang:t("error.cannot_afford", { totalPrice }))
        return
    end

    -- Veritabanına Kaydet
    if Config.SaveToDatabase and vehicleProps and vehicleProps.plate then
        local plate = string.gsub(vehicleProps.plate, "^%s*(.-)%s*$", "%1")
        MySQL.update("UPDATE player_vehicles SET mods = ? WHERE plate = ?", {
            json.encode(vehicleProps),
            plate
        })
    end

    TriggerClientEvent("QBCore:Notify", src, Lang:t("success.purchased", { totalPrice }), "success")
    cb(true)
end)

-- Araç Özelliklerini Tüm Oyunculara Senkronize Et
RegisterNetEvent("vater-mechanic:server:syncVehicleMods", function(netId, props)
    TriggerClientEvent("vater-mechanic:client:syncVehicleMods", -1, netId, props)
end)
