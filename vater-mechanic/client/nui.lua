local QBCore = exports['qb-core']:GetCoreObject()

-- NUI: Araç Verilerini Al
RegisterNUICallback("getVehicleData", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then
        cb({ success = false, error = "Araç bulunamadı" })
        return
    end

    local vehData = GetVehicleDiagnosticsAndData(vehicle)
    cb({ success = true, data = vehData })
end)

-- NUI: Parça Önizleme
RegisterNUICallback("previewMod", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 then
        local res = PreviewVehicleMod(vehicle, data.modType, data.value, data.extraData or {})
        cb(res or { success = true })
        return
    end
    cb({ success = false })
end)

-- NUI: Kamera Odak Değiştir
RegisterNUICallback("focusCamera", function(data, cb)
    if data.preset then
        SetCameraPreset(data.preset)
    end
    cb("ok")
end)

-- NUI: Kamera Serbest Döndür
RegisterNUICallback("rotateCamera", function(data, cb)
    RotateCamera(data.deltaX or 0, data.deltaY or 0, data.zoom or 0)
    cb("ok")
end)

-- NUI: Kapı Aç / Kapat
RegisterNUICallback("toggleDoor", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 then
        ToggleVehicleDoor(vehicle, tonumber(data.doorIndex))
    end
    cb("ok")
end)

-- NUI: Tamir Talebi
RegisterNUICallback("repairVehicle", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then
        cb({ success = false, message = Lang:t("error.not_in_vehicle") })
        return
    end

    local currentEngine = GetVehicleEngineHealth(vehicle)
    local currentBody = GetVehicleBodyHealth(vehicle)
    local missingHealth = (1000.0 - currentEngine) + (1000.0 - currentBody)
    local cost = math.max(250, math.min(Config.DefaultFullRepairPrice, math.floor(missingHealth * Config.RepairCostPerHealthPoint)))

    QBCore.Functions.TriggerCallback("vater-mechanic:server:repairVehicle", function(success, message)
        if success then
            RepairAndCleanVehicle(vehicle)
            PlaySoundFrontend(-1, "LOCAL_PLYR_CASH_COUNTER_COMPLETE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
            local vehData = GetVehicleDiagnosticsAndData(vehicle)
            cb({ success = true, message = Lang:t("success.repaired"), data = vehData })
        else
            cb({ success = false, message = message or Lang:t("error.cannot_afford", { cost }) })
        end
    end, cost)
end)

-- NUI: Yıkama Talebi
RegisterNUICallback("cleanVehicle", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then
        cb({ success = false, message = Lang:t("error.not_in_vehicle") })
        return
    end

    local cost = Config.WashPrice or 150

    QBCore.Functions.TriggerCallback("vater-mechanic:server:cleanVehicle", function(success, message)
        if success then
            CleanVehicleOnly(vehicle)
            PlaySoundFrontend(-1, "Spray_Can_Spray", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
            local vehData = GetVehicleDiagnosticsAndData(vehicle)
            cb({ success = true, message = Lang:t("success.cleaned"), data = vehData })
        else
            cb({ success = false, message = message or Lang:t("error.cannot_afford", { cost }) })
        end
    end, cost)
end)

-- NUI: Sepeti Onayla & Satın Al
RegisterNUICallback("checkoutCart", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then
        cb({ success = false, message = Lang:t("error.not_in_vehicle") })
        return
    end

    local cartItems = data.cart or {}
    local totalPrice = tonumber(data.totalPrice) or 0
    local paymentMethod = data.paymentMethod or "cash"

    local currentProperties = QBCore.Functions.GetVehicleProperties(vehicle)

    QBCore.Functions.TriggerCallback("vater-mechanic:server:checkoutCart", function(success, message)
        if success then
            CacheOriginalVehicle(vehicle)
            PlaySoundFrontend(-1, "PURCHASE", "HUD_LIQUOR_STORE_SOUNDSET", true)
            cb({ success = true, message = Lang:t("success.purchased", { totalPrice }) })
        else
            cb({ success = false, message = message or Lang:t("error.cannot_afford", { totalPrice }) })
        end
    end, totalPrice, paymentMethod, currentProperties, cartItems)
end)

-- NUI: Menüyü Kapat
RegisterNUICallback("closeMenu", function(data, cb)
    local shouldRestore = data.restore ~= false
    CloseMechanicWorkshop(shouldRestore)
    cb("ok")
end)
