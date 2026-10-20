local cam = nil
local activePreset = "default"
local currentVehicle = nil
local camCoords = vector3(0, 0, 0)
local camPointCoords = vector3(0, 0, 0)
local camDistance = 4.8
local camAngleX = 0.0
local camAngleY = 15.0

-- Camera Presets Framed for Split Left/Right UI (Vehicle Dead-Center in Open Space)
local PRESETS = {
    ["default"] = { offset = vector3(-3.2, 3.8, 1.1), target = vector3(0.0, 0.0, 0.1), fov = 46.0 },
    ["front"] = { offset = vector3(0.0, 3.2, 0.6), target = vector3(0.0, 1.4, 0.1), fov = 40.0 },
    ["hood"] = { offset = vector3(0.0, 2.5, 1.2), target = vector3(0.0, 1.1, 0.1), fov = 38.0 },
    ["engine"] = { offset = vector3(0.0, 2.1, 1.4), target = vector3(0.0, 1.1, 0.0), fov = 36.0 },
    ["rear"] = { offset = vector3(0.0, -3.4, 0.8), target = vector3(0.0, -1.4, 0.1), fov = 42.0 },
    ["spoiler"] = { offset = vector3(-1.4, -2.8, 1.2), target = vector3(0.0, -1.6, 0.4), fov = 38.0 },
    ["exhaust"] = { offset = vector3(0.8, -2.5, 0.2), target = vector3(0.0, -1.8, -0.2), fov = 35.0 },
    ["side"] = { offset = vector3(-3.6, 0.0, 0.5), target = vector3(0.0, 0.0, 0.0), fov = 42.0 },
    ["wheel_front"] = { offset = vector3(-1.8, 1.2, 0.0), target = vector3(-0.9, 1.2, -0.2), fov = 36.0 },
    ["wheel_rear"] = { offset = vector3(-1.8, -1.2, 0.0), target = vector3(-0.9, -1.2, -0.2), fov = 36.0 },
    ["interior"] = { offset = vector3(-0.2, 0.2, 0.7), target = vector3(0.0, 0.8, 0.2), fov = 52.0 },
    ["roof"] = { offset = vector3(0.0, 0.4, 3.5), target = vector3(0.0, 0.0, 0.2), fov = 45.0 },
    ["underglow"] = { offset = vector3(-2.6, -1.0, -0.3), target = vector3(0.0, 0.0, -0.4), fov = 46.0 },
    ["plate"] = { offset = vector3(0.0, -2.5, 0.3), target = vector3(0.0, -1.8, 0.1), fov = 34.0 },
    ["xenon"] = { offset = vector3(0.0, 3.0, 0.4), target = vector3(0.0, 1.5, 0.1), fov = 38.0 }
}

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function LerpVector3(a, b, t)
    return vector3(
        Lerp(a.x, b.x, t),
        Lerp(a.y, b.y, t),
        Lerp(a.z, b.z, t)
    )
end

function CreateMechanicCamera(vehicle)
    if cam and DoesCamExist(cam) then
        DestroyCam(cam, false)
    end

    currentVehicle = vehicle
    activePreset = "default"

    local preset = PRESETS["default"]
    local targetPos = GetOffsetFromEntityInWorldCoords(vehicle, preset.target.x, preset.target.y, preset.target.z)
    local cameraPos = GetOffsetFromEntityInWorldCoords(vehicle, preset.offset.x, preset.offset.y, preset.offset.z)

    camCoords = cameraPos
    camPointCoords = targetPos

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, cameraPos.x, cameraPos.y, cameraPos.z)
    PointCamAtCoord(cam, targetPos.x, targetPos.y, targetPos.z)
    SetCamFov(cam, preset.fov or 46.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, true)
end

function SetCameraPreset(presetName)
    if not cam or not DoesCamExist(cam) or not currentVehicle then return end
    local preset = PRESETS[presetName] or PRESETS["default"]
    activePreset = presetName

    CreateThread(function()
        local startTime = GetGameTimer()
        local duration = 550
        local startCamPos = GetCamCoord(cam)
        local startFov = GetCamFov(cam)
        local targetOffset = preset.offset
        local targetFocus = preset.target

        while GetGameTimer() - startTime < duration and cam and DoesCamExist(cam) do
            local progress = (GetGameTimer() - startTime) / duration
            local easeProgress = progress * progress * (3 - 2 * progress)

            local curTargetWorld = GetOffsetFromEntityInWorldCoords(currentVehicle, targetFocus.x, targetFocus.y, targetFocus.z)
            local curCamWorld = GetOffsetFromEntityInWorldCoords(currentVehicle, targetOffset.x, targetOffset.y, targetOffset.z)

            local interpolatedPos = LerpVector3(startCamPos, curCamWorld, easeProgress)
            local interpolatedFov = Lerp(startFov, preset.fov or 46.0, easeProgress)

            SetCamCoord(cam, interpolatedPos.x, interpolatedPos.y, interpolatedPos.z)
            PointCamAtCoord(cam, curTargetWorld.x, curTargetWorld.y, curTargetWorld.z)
            SetCamFov(cam, interpolatedFov)
            Wait(0)
        end

        if cam and DoesCamExist(cam) and currentVehicle then
            local finalTarget = GetOffsetFromEntityInWorldCoords(currentVehicle, targetFocus.x, targetFocus.y, targetFocus.z)
            local finalCam = GetOffsetFromEntityInWorldCoords(currentVehicle, targetOffset.x, targetOffset.y, targetOffset.z)
            SetCamCoord(cam, finalCam.x, finalCam.y, finalCam.z)
            PointCamAtCoord(cam, finalTarget.x, finalTarget.y, finalTarget.z)
            SetCamFov(cam, preset.fov or 46.0)
        end
    end)
end

function RotateCamera(deltaX, deltaY, zoomDelta)
    if not cam or not DoesCamExist(cam) or not currentVehicle then return end

    camAngleX = (camAngleX + deltaX * 0.4) % 360.0
    camAngleY = math.max(-35.0, math.min(70.0, camAngleY - deltaY * 0.3))

    if zoomDelta then
        camDistance = math.max(1.8, math.min(7.5, camDistance - zoomDelta * 0.3))
    end

    local radX = math.rad(camAngleX)
    local radY = math.rad(camAngleY)

    local offsetX = camDistance * math.cos(radY) * math.sin(radX)
    local offsetY = camDistance * math.cos(radY) * math.cos(radX)
    local offsetZ = camDistance * math.sin(radY)

    local vehCoords = GetEntityCoords(currentVehicle)
    local targetPos = vector3(vehCoords.x, vehCoords.y, vehCoords.z + 0.2)
    local newCamPos = vector3(vehCoords.x + offsetX, vehCoords.y + offsetY, vehCoords.z + offsetZ)

    SetCamCoord(cam, newCamPos.x, newCamPos.y, newCamPos.z)
    PointCamAtCoord(cam, targetPos.x, targetPos.y, targetPos.z)
end

function DestroyMechanicCamera()
    if cam and DoesCamExist(cam) then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
    currentVehicle = nil
end
