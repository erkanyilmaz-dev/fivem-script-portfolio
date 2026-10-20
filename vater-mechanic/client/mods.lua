local QBCore = exports['qb-core']:GetCoreObject()
local originalProperties = nil
local originalStance = { camber = 0.0, width = 0.0, size = 0.0 }
local cachedVehicle = nil
local currentSelectedWheelType = 0

-- Mod Tipleri Haritası
local MOD_CATEGORIES = {
    [0] = { name = "Spoiler", focus = "spoiler", priceKey = "spoilers" },
    [1] = { name = "Ön Tampon", focus = "front", priceKey = "frontBumper" },
    [2] = { name = "Arka Tampon", focus = "rear", priceKey = "rearBumper" },
    [3] = { name = "Yan Etekler", focus = "side", priceKey = "sideSkirt" },
    [4] = { name = "Egzoz", focus = "exhaust", priceKey = "exhaust" },
    [5] = { name = "Gövde İskeleti / Kafes", focus = "interior", priceKey = "frame" },
    [6] = { name = "Ön Izgara", focus = "front", priceKey = "grille" },
    [7] = { name = "Kaput", focus = "hood", priceKey = "hood" },
    [8] = { name = "Sol Çamurluk", focus = "side", priceKey = "fender" },
    [9] = { name = "Sağ Çamurluk", focus = "side", priceKey = "rightFender" },
    [10] = { name = "Tavan", focus = "roof", priceKey = "roof" },
    [11] = { name = "Motor Yükseltmesi", focus = "engine", priceKey = "engine", performance = true },
    [12] = { name = "Fren Sistemi", focus = "wheel_front", priceKey = "brakes", performance = true },
    [13] = { name = "Şanzıman", focus = "engine", priceKey = "transmission", performance = true },
    [14] = { name = "Korna", focus = "default", priceKey = "horns" },
    [15] = { name = "Süspansiyon", focus = "side", priceKey = "suspension", performance = true },
    [16] = { name = "Zırh", focus = "default", priceKey = "armor", performance = true },
    [25] = { name = "Plaka Tutucu", focus = "plate", priceKey = "plateHolder" },
    [26] = { name = "Özel Plaka", focus = "plate", priceKey = "vanityPlate" },
    [27] = { name = "İç Döşeme A", focus = "interior", priceKey = "trimA" },
    [28] = { name = "Süsler / Kokuluk", focus = "interior", priceKey = "ornaments" },
    [29] = { name = "Gösterge Paneli", focus = "interior", priceKey = "dashboard" },
    [30] = { name = "Kadranlar", focus = "interior", priceKey = "dial" },
    [31] = { name = "Kapı Hoparlörleri", focus = "interior", priceKey = "doorSpeaker" },
    [32] = { name = "Koltuklar", focus = "interior", priceKey = "seats" },
    [33] = { name = "Direksiyon", focus = "interior", priceKey = "steeringWheel" },
    [34] = { name = "Vites Kolu", focus = "interior", priceKey = "shifterLeavers" },
    [35] = { name = "İç Plaket", focus = "interior", priceKey = "aPlate" },
    [36] = { name = "Hoparlör Sistemi", focus = "interior", priceKey = "speakers" },
    [37] = { name = "Bagaj Tasarımı", focus = "rear", priceKey = "trunk" },
    [38] = { name = "Hidrolik", focus = "underglow", priceKey = "hydrolic" },
    [39] = { name = "Motor Bloğu", focus = "engine", priceKey = "engineBlock" },
    [40] = { name = "Hava Filtresi", focus = "engine", priceKey = "airFilter" },
    [41] = { name = "Kule Gergisi", focus = "engine", priceKey = "struts" },
    [42] = { name = "Çamurluk Koruma", focus = "side", priceKey = "archCover" },
    [43] = { name = "Antenler", focus = "roof", priceKey = "aerials" },
    [44] = { name = "İç Döşeme B", focus = "interior", priceKey = "trimB" },
    [45] = { name = "Yakıt Tankı", focus = "rear", priceKey = "tank" },
    [46] = { name = "Cam Kaplamaları", focus = "side", priceKey = "windows" },
    [48] = { name = "Gövde Kaplaması (Livery)", focus = "default", priceKey = "livery" }
}

-- Araç Özelliklerini Önbelleğe Al
function CacheOriginalVehicle(vehicle)
    cachedVehicle = vehicle
    originalProperties = QBCore.Functions.GetVehicleProperties(vehicle)
    currentSelectedWheelType = GetVehicleWheelType(vehicle)
    originalStance = {
        wheelWidth = GetVehicleWheelWidth(vehicle) or 1.0,
        wheelSize = GetVehicleWheelSize(vehicle) or 1.0
    }
end

-- Araç Eski Haline Döndür
function RestoreOriginalVehicle()
    if not cachedVehicle or not DoesEntityExist(cachedVehicle) or not originalProperties then return end
    QBCore.Functions.SetVehicleProperties(cachedVehicle, originalProperties)
    
    if originalStance.wheelWidth and originalStance.wheelWidth > 0 then
        SetVehicleWheelWidth(cachedVehicle, originalStance.wheelWidth)
    end
    if originalStance.wheelSize and originalStance.wheelSize > 0 then
        SetVehicleWheelSize(cachedVehicle, originalStance.wheelSize)
    end
end

-- Detaylı Araç Bilgisini Getir
function GetVehicleDiagnosticsAndData(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    SetVehicleModKit(vehicle, 0)

    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    local brandName = GetMakeNameFromVehicleModel(model)
    local label = GetLabelText(displayName)
    if label == "NULL" then label = displayName end

    local plate = QBCore.Functions.GetPlate(vehicle)

    -- Canlı İstatistikler
    local engineHealth = math.floor(GetVehicleEngineHealth(vehicle) + 0.5)
    local bodyHealth = math.floor(GetVehicleBodyHealth(vehicle) + 0.5)
    local tankHealth = math.floor(GetVehiclePetrolTankHealth(vehicle) + 0.5)
    local dirtLevel = math.floor(GetVehicleDirtLevel(vehicle) * 10) / 10
    local maxSpeed = math.floor(GetVehicleEstimatedMaxSpeed(vehicle) * 3.6)
    local acceleration = math.floor(GetVehicleAcceleration(vehicle) * 100)
    local maxBraking = math.floor(GetVehicleMaxBraking(vehicle) * 100)
    local maxTraction = math.floor(GetVehicleMaxTraction(vehicle) * 100)

    -- Mevcut Modlar & Seçenekler Listesi
    local availableMods = {}

    for modType, info in pairs(MOD_CATEGORIES) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count > 0 then
            local currentVal = GetVehicleMod(vehicle, modType)
            local items = {}
            
            table.insert(items, {
                index = -1,
                name = "Standart (Stock)",
                price = 0,
                installed = (currentVal == -1)
            })

            for i = 0, count - 1 do
                local modLabel = GetModTextLabel(vehicle, modType, i)
                local itemName = GetLabelText(modLabel)
                if itemName == "NULL" or not itemName or itemName == "" then
                    itemName = info.name .. " " .. (i + 1)
                end

                local price = 0
                if info.performance then
                    local pList = Config.Prices.performance[info.priceKey] or {}
                    price = pList[i + 1] or (1000 * (i + 1))
                else
                    price = Config.Prices.cosmetics[info.priceKey] or Config.Prices.interior[info.priceKey] or 1500
                end

                table.insert(items, {
                    index = i,
                    name = itemName,
                    price = price,
                    installed = (currentVal == i)
                })
            end

            availableMods[tostring(modType)] = {
                category = info.name,
                focus = info.focus,
                current = currentVal,
                isPerformance = info.performance or false,
                items = items
            }
        end
    end

    -- Turbo
    local hasTurbo = IsToggleModOn(vehicle, 18)
    local turboMod = {
        category = "Turbo",
        focus = "engine",
        current = hasTurbo and 1 or 0,
        items = {
            { index = 0, name = "Yok (Standart)", price = 0, installed = not hasTurbo },
            { index = 1, name = "Yarış Turbo Şarj Kiti", price = Config.Prices.performance.turbo or 15000, installed = hasTurbo }
        }
    }

    -- Ekstralar (1 - 12)
    local extrasList = {}
    for extraId = 0, 12 do
        if DoesExtraExist(vehicle, extraId) then
            local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
            table.insert(extrasList, {
                id = extraId,
                name = "Ekstra Parça #" .. extraId,
                enabled = state,
                price = Config.Prices.cosmetics.extras or 450
            })
        end
    end

    -- Xenon Farlar
    local xenonEnabled = IsToggleModOn(vehicle, 22)
    local xenonColor = GetVehicleXenonLightsColor(vehicle)
    local xenonList = {}
    for _, xColor in ipairs(Config.XenonColors) do
        table.insert(xenonList, {
            id = xColor.id,
            name = xColor.name,
            price = xColor.id == -1 and (Config.Prices.lighting.xenon or 2500) or (Config.Prices.lighting.xenonColor or 1200),
            installed = (xenonEnabled and xenonColor == xColor.id) or (not xenonEnabled and xColor.id == -1)
        })
    end

    -- Neon Alt Işıklandırma
    local neonEnabled = {
        left = IsVehicleNeonLightEnabled(vehicle, 0),
        right = IsVehicleNeonLightEnabled(vehicle, 1),
        front = IsVehicleNeonLightEnabled(vehicle, 2),
        back = IsVehicleNeonLightEnabled(vehicle, 3)
    }
    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local neonColor = { r = nr, g = ng, b = nb }

    -- Renkler & Boyalar
    local primaryColor, secondaryColor = GetVehicleColours(vehicle)
    local pearlColor, wheelColor = GetVehicleExtraColours(vehicle)
    local customPrimary = nil
    if GetIsVehiclePrimaryColourCustom(vehicle) then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
        customPrimary = { r = r, g = g, b = b }
    end

    local customSecondary = nil
    if GetIsVehicleSecondaryColourCustom(vehicle) then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
        customSecondary = { r = r, g = g, b = b }
    end

    -- Jantlar
    local wheelType = GetVehicleWheelType(vehicle)
    currentSelectedWheelType = wheelType
    local currentFrontWheel = GetVehicleMod(vehicle, 23)
    local hasCustomTires = GetVehicleModVariation(vehicle, 23)
    local tireSmokeR, tireSmokeG, tireSmokeB = GetVehicleTyreSmokeColor(vehicle)
    local hasDriftTires = GetDriftTyresEnabled and GetDriftTyresEnabled(vehicle) or false

    -- Cam Filmi
    local currentTint = GetVehicleWindowTint(vehicle)

    -- Plaka Stili
    local currentPlateIndex = GetVehicleNumberPlateTextIndex(vehicle)

    return {
        vehicle = {
            model = model,
            label = label,
            brand = brandName,
            plate = plate,
            stats = {
                engine = engineHealth,
                body = bodyHealth,
                tank = tankHealth,
                dirt = dirtLevel,
                maxSpeed = maxSpeed,
                acceleration = acceleration,
                braking = maxBraking,
                traction = maxTraction
            }
        },
        mods = availableMods,
        turbo = turboMod,
        extras = extrasList,
        xenon = {
            enabled = xenonEnabled,
            color = xenonColor,
            list = xenonList
        },
        neons = {
            enabled = neonEnabled,
            color = neonColor,
            price = Config.Prices.lighting.neonSet or 3500
        },
        paint = {
            primary = primaryColor,
            secondary = secondaryColor,
            pearlescent = pearlColor,
            dashboard = GetVehicleDashboardColour(vehicle),
            interior = GetVehicleInteriorColour(vehicle),
            wheelColor = wheelColor,
            customPrimary = customPrimary,
            customSecondary = customSecondary,
            colors = Config.Colors,
            types = Config.PaintTypes
        },
        wheels = {
            currentType = wheelType,
            currentMod = currentFrontWheel,
            customTires = hasCustomTires,
            driftTires = hasDriftTires,
            tireSmokeColor = { r = tireSmokeR, g = tireSmokeG, b = tireSmokeB },
            categories = Config.WheelCategories,
            wheelCount = GetNumVehicleMods(vehicle, 23)
        },
        tints = {
            current = currentTint,
            list = Config.WindowTints
        },
        plates = {
            current = currentPlateIndex,
            list = Config.PlateTypes
        },
        horns = {
            current = GetVehicleMod(vehicle, 14),
            list = Config.Horns
        },
        prices = Config.Prices
    }
end

-- Parça Önizleme (Canlı Uygulama)
function PreviewVehicleMod(vehicle, modType, value, extraData)
    if not DoesEntityExist(vehicle) then return { success = false } end
    SetVehicleModKit(vehicle, 0)

    if modType == "mod" then
        local id = tonumber(extraData.id)
        if id then
            SetVehicleMod(vehicle, id, tonumber(value), false)
        end
    elseif modType == "turbo" then
        ToggleVehicleMod(vehicle, 18, value == 1 or value == true)
    elseif modType == "extra" then
        local extraId = tonumber(extraData.id)
        local state = (value == 1 or value == true)
        SetVehicleExtra(vehicle, extraId, state and 0 or 1)
    elseif modType == "xenon" then
        local colorId = tonumber(value)
        if colorId == -1 then
            ToggleVehicleMod(vehicle, 22, false)
        else
            ToggleVehicleMod(vehicle, 22, true)
            SetVehicleXenonLightsColor(vehicle, colorId)
        end
    elseif modType == "neon_toggle" then
        local side = tonumber(extraData.side)
        local state = (value == 1 or value == true)
        SetVehicleNeonLightEnabled(vehicle, side, state)
    elseif modType == "neon_color" then
        local r, g, b = tonumber(value.r), tonumber(value.g), tonumber(value.b)
        SetVehicleNeonLightsColour(vehicle, r, g, b)
    elseif modType == "paint_classic" then
        local pType = extraData.paintType
        local colorIdx = tonumber(value)
        if pType == "primary" then
            local _, sec = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, colorIdx, sec)
            ClearVehicleCustomPrimaryColour(vehicle)
        elseif pType == "secondary" then
            local pri, _ = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, pri, colorIdx)
            ClearVehicleCustomSecondaryColour(vehicle)
        elseif pType == "pearlescent" then
            local _, wheel = GetVehicleExtraColours(vehicle)
            SetVehicleExtraColours(vehicle, colorIdx, wheel)
        elseif pType == "wheel" then
            local pearl, _ = GetVehicleExtraColours(vehicle)
            SetVehicleExtraColours(vehicle, pearl, colorIdx)
        elseif pType == "dashboard" then
            SetVehicleDashboardColour(vehicle, colorIdx)
        elseif pType == "interior" then
            SetVehicleInteriorColour(vehicle, colorIdx)
        end
    elseif modType == "paint_rgb" then
        local pType = extraData.paintType
        local r, g, b = tonumber(value.r), tonumber(value.g), tonumber(value.b)
        if pType == "primary" then
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        elseif pType == "secondary" then
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        elseif pType == "smoke" then
            ToggleVehicleMod(vehicle, 20, true)
            SetVehicleTyreSmokeColor(vehicle, r, g, b)
        end
    elseif modType == "wheel_type" then
        SetVehicleModKit(vehicle, 0)
        local wType = tonumber(value) or 0
        currentSelectedWheelType = wType
        SetVehicleWheelType(vehicle, wType)
        local count = GetNumVehicleMods(vehicle, 23)
        return { success = true, wheelCount = count }
    elseif modType == "wheel_mod" then
        SetVehicleModKit(vehicle, 0)
        local wType = (extraData and extraData.wheelType and tonumber(extraData.wheelType)) or currentSelectedWheelType or GetVehicleWheelType(vehicle) or 0
        currentSelectedWheelType = wType
        SetVehicleWheelType(vehicle, wType)
        local wMod = tonumber(value)
        local customTires = (extraData and (extraData.customTires == true or extraData.customTires == 1)) or false
        SetVehicleMod(vehicle, 23, wMod, customTires)
        if GetVehicleClass(vehicle) == 8 then
            SetVehicleMod(vehicle, 24, wMod, customTires)
        end
        return { success = true }
    elseif modType == "custom_tires" then
        SetVehicleModKit(vehicle, 0)
        local state = (value == 1 or value == true)
        local currentWheel = GetVehicleMod(vehicle, 23)
        SetVehicleMod(vehicle, 23, currentWheel, state)
        if GetVehicleClass(vehicle) == 8 then
            SetVehicleMod(vehicle, 24, currentWheel, state)
        end
    elseif modType == "drift_tires" then
        if SetDriftTyresEnabled then
            SetDriftTyresEnabled(vehicle, value == 1 or value == true)
        end
    elseif modType == "bulletproof_tires" then
        SetVehicleTyresCanBurst(vehicle, not (value == 1 or value == true))
    elseif modType == "window_tint" then
        SetVehicleWindowTint(vehicle, tonumber(value))
    elseif modType == "plate_index" then
        SetVehicleNumberPlateTextIndex(vehicle, tonumber(value))
    elseif modType == "horn" then
        SetVehicleMod(vehicle, 14, tonumber(value), false)
    elseif modType == "stance" then
        if extraData.camber and SetVehicleWheelCamber then
            SetVehicleWheelCamber(vehicle, 0, tonumber(extraData.camber) / 100)
            SetVehicleWheelCamber(vehicle, 1, tonumber(extraData.camber) / 100)
        end
        if extraData.width and SetVehicleWheelWidth then
            SetVehicleWheelWidth(vehicle, tonumber(extraData.width) / 100)
        end
        if extraData.size and SetVehicleWheelSize then
            SetVehicleWheelSize(vehicle, tonumber(extraData.size) / 100)
        end
    end
    return { success = true }
end

-- Tamir ve Yıkama
function RepairAndCleanVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    
    for i = 0, 7 do
        FixVehicleWindow(vehicle, i)
    end
    for i = 0, 5 do
        SetVehicleDoorShut(vehicle, i, false)
    end
    for i = 0, 5 do
        SetVehicleTyreFixed(vehicle, i)
    end
end

function CleanVehicleOnly(vehicle)
    if not DoesEntityExist(vehicle) then return end
    SetVehicleDirtLevel(vehicle, 0.0)
end

-- Kapı Açma / Kapama Kontrolü
function ToggleVehicleDoor(vehicle, doorIndex)
    if not DoesEntityExist(vehicle) then return end
    if GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.0 then
        SetVehicleDoorShut(vehicle, doorIndex, false)
    else
        SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    end
end
