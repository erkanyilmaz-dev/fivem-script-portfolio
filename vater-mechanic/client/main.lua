local QBCore = exports['qb-core']:GetCoreObject()
local isInsideBay = false
local currentBayId = nil
local isCustomizing = false
local currentVehicle = nil
local blips = {}

-- 3D Yazı Çizdirme
local function DrawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 240)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Harita Blip'lerini Oluştur
local function CreateBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    blips = {}

    for _, loc in pairs(Config.Locations) do
        if loc.blip then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, loc.blip.sprite or 446)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, loc.blip.scale or 0.75)
            SetBlipColour(blip, loc.blip.color or 5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(loc.blip.name or "Mekanik Garajı")
            EndTextCommandSetBlipName(blip)
            table.insert(blips, blip)
        end
    end
end

-- Atölyeyi Aç
function OpenMechanicWorkshop(bayId)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify(Lang:t("error.not_in_vehicle"), "error")
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        QBCore.Functions.Notify(Lang:t("error.must_be_driver"), "error")
        return
    end

    -- Meslek Kontrolü
    local bay = Config.Locations[bayId]
    if bay and bay.job then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData.job.name ~= bay.job then
            QBCore.Functions.Notify(Lang:t("error.not_mechanic"), "error")
            return
        end
    end

    currentVehicle = vehicle
    isCustomizing = true
    currentBayId = bayId

    -- Aracı dondur ve farları aç
    FreezeEntityPosition(vehicle, true)
    SetVehicleLights(vehicle, 2)
    SetVehicleEngineOn(vehicle, true, true, false)

    -- İlk özellikleri kaydet
    CacheOriginalVehicle(vehicle)

    -- Kamerayı başlat
    CreateMechanicCamera(vehicle)

    -- Verileri al ve NUI'ye gönder
    local vehData = GetVehicleDiagnosticsAndData(vehicle)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        data = vehData,
        currency = Config.Currency,
        currencyPos = Config.CurrencyPosition,
        shopName = bay and bay.name or "Vater Mechanic Atölyesi"
    })
end

-- Atölyeyi Kapat
function CloseMechanicWorkshop(shouldRestore)
    if not isCustomizing then return end

    if shouldRestore then
        RestoreOriginalVehicle()
    end

    if currentVehicle and DoesEntityExist(currentVehicle) then
        FreezeEntityPosition(currentVehicle, false)
    end

    DestroyMechanicCamera()

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })

    isCustomizing = false
    currentVehicle = nil
    currentBayId = nil
end

-- Ana Döngü (Mekanik Noktası Tespiti)
CreateThread(function()
    CreateBlips()

    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if not isCustomizing and IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                local playerCoords = GetEntityCoords(ped)
                local foundBay = nil

                for bayId, loc in pairs(Config.Locations) do
                    local dist = #(playerCoords - loc.coords)
                    if dist <= (loc.radius or 5.0) then
                        sleep = 0
                        foundBay = bayId

                        if loc.drawMarker ~= false then
                            local color = loc.markerColor or { r = 0, g = 229, b = 255, a = 180 }
                            DrawMarker(1, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, loc.radius * 1.8, loc.radius * 1.8, 0.6, color.r, color.g, color.b, color.a, false, false, 2, false, nil, nil, false)
                        end

                        DrawText3D(vector3(loc.coords.x, loc.coords.y, loc.coords.z + 0.6), "[E] ~c~-~s~ ~g~" .. (loc.name or "Mekanik Atölyesi") .. "~s~")

                        if IsControlJustPressed(0, 38) then -- 'E' Tuşu
                            OpenMechanicWorkshop(bayId)
                        end
                        break
                    elseif dist <= 20.0 then
                        sleep = 200
                        if loc.drawMarker ~= false then
                            local color = loc.markerColor or { r = 0, g = 229, b = 255, a = 120 }
                            DrawMarker(1, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, loc.radius * 1.8, loc.radius * 1.8, 0.6, color.r, color.g, color.b, color.a, false, false, 2, false, nil, nil, false)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Kaynak durdurulduğunda temizlik
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if isCustomizing then
        CloseMechanicWorkshop(true)
    end
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
