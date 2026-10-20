-- ============================================================================
-- VATER SCRIPTS - Advanced Gunsmith & Custom Skin Engine
-- ULTRA OPTIMIZED CLIENT ENGINE (0.00 - 0.01 ms Idle Resmon)
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Localized FiveM Core Natives for Maximum Performance
local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityForwardVector = GetEntityForwardVector
local GetCurrentPedWeapon = GetCurrentPedWeapon
local GetPedWeaponTintIndex = GetPedWeaponTintIndex
local SetPedWeaponTintIndex = SetPedWeaponTintIndex
local GiveWeaponComponentToPed = GiveWeaponComponentToPed
local RemoveWeaponComponentFromPed = RemoveWeaponComponentFromPed
local HasPedGotWeaponComponent = HasPedGotWeaponComponent
local SetCurrentPedWeapon = SetCurrentPedWeapon
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local DrawMarker = DrawMarker
local AddTextEntry = AddTextEntry
local DisplayHelpTextThisFrame = DisplayHelpTextThisFrame
local IsControlJustReleased = IsControlJustReleased
local SetEntityRotation = SetEntityRotation
local SetEntityHeading = SetEntityHeading
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityCollision = SetEntityCollision
local SetCamFov = SetCamFov
local GetCamFov = GetCamFov
local SetCamCoord = SetCamCoord
local PointCamAtCoord = PointCamAtCoord
local SetCamActive = SetCamActive
local RenderScriptCams = RenderScriptCams
local DestroyCam = DestroyCam
local CreateCam = CreateCam
local DoesCamExist = DoesCamExist
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local SendNUIMessage = SendNUIMessage
local SetNuiFocus = SetNuiFocus
local ClearPedTasks = ClearPedTasks
local TaskStandStill = TaskStandStill
local AddReplaceTexture = AddReplaceTexture
local RemoveReplaceTexture = RemoveReplaceTexture
local RequestStreamedTextureDict = RequestStreamedTextureDict
local HasStreamedTextureDictLoaded = HasStreamedTextureDictLoaded
local SetStreamedTextureDictAsNoLongerNeeded = SetStreamedTextureDictAsNoLongerNeeded
local CreateRuntimeTxd = CreateRuntimeTxd
local CreateRuntimeTextureFromDuiHandle = CreateRuntimeTextureFromDuiHandle
local CreateDui = CreateDui
local DestroyDui = DestroyDui
local GetDuiHandle = GetDuiHandle
local SendDuiMessage = SendDuiMessage
local GetHashKey = GetHashKey
local math_max = math.max
local math_min = math.min
local table_concat = table.concat

local isUIOpen = false
local isSavingMods = false
local isMenuTransition = false
local cam = nil
local originalWeaponComponents = {}
local originalTintIndex = 0
local selectedTintIndex = 0
local originalSkinId = nil
local selectedSkinId = nil
local currentWeaponHash = nil
local currentWeaponName = nil
local currentInventorySlot = nil
local currentInventorySerial = nil

local equippedInventorySlot = nil
local activeSkinComponentHash = nil
local activeSkinComponentWeaponHash = nil
local appliedSkinId = nil
local appliedSkinWeaponHash = nil
local lastAppearanceKey = nil
local nextAppearanceRetryAt = 0
local appearanceRetryDelay = 2000
local skinRevision = 0
local attachmentRevisions = {}
local syncHeldWeaponAppearance = nil
local clientUnlockedSkins = {}

local dummyWeaponObj = nil
local objHeading = 0.0
local objPitch = 0.0

-- Fast O(1) Pre-Computed Hash Map
local weaponHashToNameMap = {}

local function BuildWeaponHashMap()
    weaponHashToNameMap = {}
    if Config and Config.Weapons then
        for wName in pairs(Config.Weapons) do
            local low = wName:lower()
            weaponHashToNameMap[GetHashKey(wName)] = low
            weaponHashToNameMap[GetHashKey(low)] = low
            weaponHashToNameMap[GetHashKey(wName:upper())] = low
        end
    end
    if QBCore and QBCore.Shared and QBCore.Shared.Weapons then
        for hashKey, weaponInfo in pairs(QBCore.Shared.Weapons) do
            local numHash = type(hashKey) == "number" and hashKey or GetHashKey(tostring(hashKey))
            if weaponInfo and weaponInfo.name then
                weaponHashToNameMap[numHash] = weaponInfo.name:lower()
            end
        end
    end
end

CreateThread(function()
    BuildWeaponHashMap()
    AddTextEntry("SILAH_BENCH_TEXT", "~g~E~w~ - Silah Modifiye Masası")
end)

-- DUI Runtime Texture Engine
local duiObject = nil
local duiHandle = nil
local duiTxdObj = nil
local duiReady = false
local duiPageReady = false
local activeReplaceList = {}

local WeaponTextureMap = {
    ["weapon_pistol"]           = { txd = "w_pi_pistol",         txn = "W_PI_Pistol_Diff" },
    ["weapon_pistol_mk2"]       = { txd = "w_pi_pistolmk2",     txn = "w_pi_pistolmk2_d" },
    ["weapon_combatpistol"]     = { txd = "w_pi_combatpistol",   txn = "W_PI_CombatPistol_Diff" },
    ["weapon_appistol"]         = { txd = "w_pi_appistol",       txn = "W_PI_APPistol_Diff" },
    ["weapon_pistol50"]         = { txd = "w_pi_pistol50",       txn = "W_PI_Pistol50_Diff" },
    ["weapon_smg"]              = { txd = "w_sb_smg",            txn = "W_SB_SMG_Diff" },
    ["weapon_microsmg"]         = { txd = "w_sb_microsmg",       txn = "W_SB_MicroSMG_Diff" },
    ["weapon_assaultrifle"]     = { txd = "w_ar_assaultrifle",   txn = "W_AR_AssaultRifle_Diff" },
    ["weapon_assaultrifle_mk2"] = { txd = "w_ar_assaultriflemk2", txn = "w_ar_assaultriflemk2_d" },
    ["weapon_carbinerifle"]     = { txd = "w_ar_carbinerifle",   txn = "W_AR_CarbineRifle_Diff" },
    ["weapon_specialcarbine"]   = { txd = "w_ar_specialcarbine", txn = "W_AR_SpecialCarbine_Diff" },
    ["weapon_compactrifle"]     = { txd = "w_ar_compactrifle",   txn = "w_ar_compactrifle_d" },
    ["weapon_pumpshotgun"]      = { txd = "w_sg_pumpshotgun",    txn = "W_SG_PumpShotgun_Diff" },
    ["weapon_heavysniper"]      = { txd = "w_sr_heavysniper",    txn = "W_SR_HeavySniper_Diff" },
}

local function normalizeWeaponName(weaponName)
    if type(weaponName) ~= "string" then return nil end
    return weaponName:lower()
end

local function normalizeSkinId(skinId)
    if type(skinId) ~= "string" then return nil end
    local normalized = skinId:match("^%s*(.-)%s*$"):lower()
    if normalized == "" or normalized == "default" then return nil end
    return normalized
end

local function getSkinMode(skin)
    if type(skin) ~= "table" or type(skin.mode) ~= "string" then return "component" end
    return skin.mode:lower()
end

local function getSkinDefinition(skinId, weaponName)
    local normalizedSkinId = normalizeSkinId(skinId)
    local normalizedWeaponName = normalizeWeaponName(weaponName)
    if not normalizedSkinId then return nil end

    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        local configuredWeapon = normalizeWeaponName(skin.weapon)
        if normalizeSkinId(skin.id) == normalizedSkinId
            and (not configuredWeapon or configuredWeapon == normalizedWeaponName) then
            return skin
        end
    end

    return nil
end

local function getAvailableSkins(weaponName)
    local normalizedWeaponName = normalizeWeaponName(weaponName)
    local available = {}

    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        local configuredWeapon = normalizeWeaponName(skin.weapon)
        local skinId = normalizeSkinId(skin.id)
        if skinId and (not configuredWeapon or configuredWeapon == normalizedWeaponName) then
            available[#available + 1] = {
                id = skinId,
                label = skin.label or skin.id,
                description = skin.description,
                preview = skin.preview,
                mode = getSkinMode(skin),
                isLocked = skin.isLocked or false,
                permission = skin.permission,
                requiredItem = skin.requiredItem
            }
        end
    end

    return available
end

local function findInventoryWeapon(weaponName, preferredSlot)
    local playerData = QBCore.Functions.GetPlayerData()
    local items = playerData and playerData.items or {}
    local normalizedWeaponName = normalizeWeaponName(weaponName)

    if preferredSlot and (items[preferredSlot] or items[tostring(preferredSlot)]) then
        local preferredItem = items[preferredSlot] or items[tostring(preferredSlot)]
        if preferredItem and normalizeWeaponName(preferredItem.name) == normalizedWeaponName then
            return preferredItem, preferredSlot
        end
    end

    local foundItem = nil
    local foundSlot = nil
    local matchCount = 0
    for slot, item in pairs(items) do
        if item and normalizeWeaponName(item.name) == normalizedWeaponName then
            matchCount = matchCount + 1
            foundItem = item
            foundSlot = item.slot or slot
        end
    end

    if matchCount == 1 then
        return foundItem, foundSlot
    end

    return nil, nil
end

local function getItemSkinId(item)
    if not item or type(item.info) ~= "table" then return nil end
    return normalizeSkinId(item.info.skin)
end

local function getItemSerial(item)
    if not item or type(item.info) ~= "table" then return nil end
    local serial = item.info.serial or item.info.serie
    if serial == nil or tostring(serial) == "" then return nil end
    return tostring(serial)
end

local function initDui()
    if duiObject and duiReady then
        local readyTimeout = 0
        while not duiPageReady and readyTimeout < 200 do
            Wait(10)
            readyTimeout = readyTimeout + 1
        end
        return duiPageReady
    end
    if duiObject then
        DestroyDui(duiObject)
        duiObject = nil
        duiHandle = nil
        duiTxdObj = nil
        duiReady = false
        duiPageReady = false
    end

    local duiUrl = ("https://cfx-nui-%s/ui/camo_canvas.html"):format(GetCurrentResourceName())
    duiPageReady = false
    duiObject = CreateDui(duiUrl, 512, 512)

    if not duiObject then return false end

    duiHandle = GetDuiHandle(duiObject)
    duiTxdObj = CreateRuntimeTxd("vater_camo_txd")
    local runtimeTex = CreateRuntimeTextureFromDuiHandle(duiTxdObj, "camo_skin", duiHandle)

    if runtimeTex then
        duiReady = true
        local readyTimeout = 0
        while not duiPageReady and readyTimeout < 200 do
            Wait(10)
            readyTimeout = readyTimeout + 1
        end
        return duiPageReady
    end
    return false
end

RegisterNUICallback('camoDuiReady', function(_, cb)
    duiPageReady = true
    cb('ok')
end)

local function clearAllTextureReplacements()
    for _, entry in ipairs(activeReplaceList) do
        RemoveReplaceTexture(entry.txd, entry.txn)
        if entry.streamedTxd then
            SetStreamedTextureDictAsNoLongerNeeded(entry.streamedTxd)
        end
    end
    activeReplaceList = {}
end

local function trackTextureReplacement(sourceTxd, sourceTxn, targetTxd, targetTxn, streamedTxd)
    AddReplaceTexture(sourceTxd, sourceTxn, targetTxd, targetTxn)
    activeReplaceList[#activeReplaceList + 1] = {
        txd = sourceTxd,
        txn = sourceTxn,
        streamedTxd = streamedTxd
    }
end

local function applyCustomCamoToWeapon(patternId, primaryColor, secondaryColor, imgUrl, weaponName, weaponHash, sourceTxd, sourceTxn, expectedRevision)
    weaponName = normalizeWeaponName(weaponName or currentWeaponName)
    weaponHash = weaponHash or currentWeaponHash
    if not weaponName then return false, "Silah adı bulunamadı." end

    if not initDui() or not duiReady then
        return false, "DUI texture motoru hazır değil."
    end
    if expectedRevision and expectedRevision ~= skinRevision then
        return false, nil, true
    end

    clearAllTextureReplacements()

    local playerPed = PlayerPedId()
    if weaponHash then
        SetPedWeaponTintIndex(playerPed, weaponHash, 0)
    end
    if dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
        SetWeaponObjectTintIndex(dummyWeaponObj, 0)
    end

    SendDuiMessage(duiObject, json.encode({
        action = "renderPattern",
        patternId = patternId or "custom_gif",
        primaryColor = primaryColor or "#f97316",
        secondaryColor = secondaryColor or "#7c2d12",
        imgUrl = imgUrl or nil
    }))

    Wait(75)

    if expectedRevision and expectedRevision ~= skinRevision then
        return false, nil, true
    end

    local mapEntry = WeaponTextureMap[weaponName]
    sourceTxd = sourceTxd or (mapEntry and mapEntry.txd)
    sourceTxn = sourceTxn or (mapEntry and mapEntry.txn)
    if not sourceTxd or not sourceTxn then
        return false, ("%s için sourceTxd/sourceTxn tanımlı değil."):format(weaponName)
    end

    trackTextureReplacement(sourceTxd, sourceTxn, "vater_camo_txd", "camo_skin")
    return true
end

local function applyComponentToWeaponObject(weaponObj, componentHash, expectedSkinRevision)
    if not weaponObj or not DoesEntityExist(weaponObj) or not componentHash then return end

    local modelHash = GetWeaponComponentTypeModel(componentHash)
    if not modelHash or modelHash == 0 then
        if componentHash == `COMPONENT_ASSAULTRIFLE_VARMOD_LUXE` or componentHash == GetHashKey("COMPONENT_ASSAULTRIFLE_VARMOD_LUXE") then
            modelHash = `w_ar_assaultrifle_luxe`
        end
    end

    if modelHash and modelHash ~= 0 and not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do
            Wait(10)
            if expectedSkinRevision and expectedSkinRevision ~= skinRevision then
                return false
            end
            timeout = timeout + 1
        end
        SetModelAsNoLongerNeeded(modelHash)
    end

    if expectedSkinRevision and expectedSkinRevision ~= skinRevision then return false end
    if DoesEntityExist(weaponObj) then
        GiveWeaponComponentToWeaponObject(weaponObj, componentHash)
    end
    return true
end

local function getComponentHash(component)
    if type(component) == "number" then return component end
    if type(component) == "string" and component ~= "" then
        return GetHashKey(component)
    end
    return nil
end

local function IsWeaponComponentValid(weaponHash, component)
    local wHash = type(weaponHash) == "number" and weaponHash or (type(weaponHash) == "string" and GetHashKey(weaponHash) or nil)
    local cHash = type(component) == "number" and component or (type(component) == "string" and GetHashKey(component) or nil)
    if not wHash or not cHash then return false end
    return DoesWeaponTakeWeaponComponent(wHash, cHash)
end

local function removeActiveSkinComponent()
    if not activeSkinComponentHash or not activeSkinComponentWeaponHash then return end

    local playerPed = PlayerPedId()
    RemoveWeaponComponentFromPed(playerPed, activeSkinComponentWeaponHash, activeSkinComponentHash)
    if dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
        RemoveWeaponComponentFromWeaponObject(dummyWeaponObj, activeSkinComponentHash)
    end

    activeSkinComponentHash = nil
    activeSkinComponentWeaponHash = nil
end

local function removeConfiguredSkinComponents(weaponName, weaponHash, weaponObj)
    local playerPed = PlayerPedId()
    local normalizedWeaponName = normalizeWeaponName(weaponName)

    for _, skin in ipairs((Config and Config.CustomSkins) or {}) do
        local configuredWeapon = normalizeWeaponName(skin.weapon)
        if getSkinMode(skin) == "component"
            and (not configuredWeapon or configuredWeapon == normalizedWeaponName) then
            local componentHash = getComponentHash(skin.component)
            if componentHash then
                RemoveWeaponComponentFromPed(playerPed, weaponHash, componentHash)
                if weaponObj and DoesEntityExist(weaponObj) then
                    RemoveWeaponComponentFromWeaponObject(weaponObj, componentHash)
                end
            end
        end
    end
end

local function setAppearanceTint(weaponHash, weaponObj, tintIndex)
    local tint = math_max(0, tonumber(tintIndex) or 0)
    local playerPed = PlayerPedId()

    if weaponHash and weaponHash ~= 0 then
        SetPedWeaponTintIndex(playerPed, weaponHash, tint)
    end
    if weaponObj and DoesEntityExist(weaponObj) then
        SetWeaponObjectTintIndex(weaponObj, tint)
    end
end

local function resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
    clearAllTextureReplacements()
    removeActiveSkinComponent()
    removeConfiguredSkinComponents(weaponName, weaponHash, weaponObj)
    setAppearanceTint(weaponHash, weaponObj, tintIndex)

    appliedSkinId = nil
    appliedSkinWeaponHash = weaponHash
end

local function applyConfiguredSkin(skinId, weaponName, weaponHash, tintIndex, weaponObj)
    skinRevision = skinRevision + 1
    local revision = skinRevision
    weaponName = normalizeWeaponName(weaponName)
    skinId = normalizeSkinId(skinId)

    resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
    if not skinId then return true end

    local skin = getSkinDefinition(skinId, weaponName)
    if not skin then
        return false, "Bu skin silah için tanımlı değil. GTA varsayılan görünümü korundu."
    end

    if not isUIOpen and skin.isLocked and not clientUnlockedSkins[skinId] then
        resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
        return false, "🔒 Bu silah kaplaması kilitli olduğu için varsayılan GTA görünümüne sıfırlandı."
    end

    local mode = getSkinMode(skin)
    setAppearanceTint(weaponHash, weaponObj, 0)

    if mode == "component" then
        local componentHash = getComponentHash(skin.component)
        if not componentHash then
            resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
            return false, "Skin component hash'i bulunamadı."
        end

        local playerPed = PlayerPedId()
        GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
        activeSkinComponentHash = componentHash
        activeSkinComponentWeaponHash = weaponHash

        if weaponObj and DoesEntityExist(weaponObj) then
            applyComponentToWeaponObject(weaponObj, componentHash, revision)
        end

        if revision ~= skinRevision then
            return false, nil, true
        end
    elseif mode == "texture" then
        local mapEntry = WeaponTextureMap[weaponName]
        local sourceTxd = skin.sourceTxd or (mapEntry and mapEntry.txd) or "w_ar_assaultrifle"
        local sourceTxn = skin.sourceTxn or (mapEntry and mapEntry.txn) or "W_AR_AssaultRifle_Diff"
        local targetTxd = skin.targetTxd or skin.id
        local targetTxn = skin.targetTxn or sourceTxn

        if not sourceTxd or not targetTxd then
            resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
            return false, "Texture skin TXD/TXN eşlemesi eksik."
        end

        RequestStreamedTextureDict(targetTxd, false)
        local timeout = 0
        while not HasStreamedTextureDictLoaded(targetTxd) and timeout < 100 do
            Wait(10)
            if revision ~= skinRevision then
                SetStreamedTextureDictAsNoLongerNeeded(targetTxd)
                return false, nil, true
            end
            timeout = timeout + 1
        end

        if revision ~= skinRevision then
            SetStreamedTextureDictAsNoLongerNeeded(targetTxd)
            return false, nil, true
        end

        if not HasStreamedTextureDictLoaded(targetTxd) then
            resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
            return false, ("Stream texture dictionary yüklenemedi: %s"):format(targetTxd)
        end

        trackTextureReplacement(sourceTxd, sourceTxn, targetTxd, targetTxn, targetTxd)

        local variations = {
            { src = "W_AR_AssaultRifle_Diff", tgt = "W_AR_AssaultRifle_Diff" },
            { src = "W_AR_AssaultRifle_Diff", tgt = "w_ar_assaultrifle_luxe" },
            { src = "w_ar_assaultrifle", tgt = "W_AR_AssaultRifle_Diff" },
            { src = "w_ar_assaultrifle", tgt = "w_ar_assaultrifle_luxe" },
            { src = "w_ar_assaultrifle", tgt = "w_ar_assaultrifle" },
            { src = "w_ar_assaultrifle_d", tgt = "w_ar_assaultrifle_d" },
            { src = "W_AR_CarbineRifle_Diff", tgt = "W_AR_CarbineRifle_Diff" },
            { src = "W_AR_CarbineRifle_Diff", tgt = "w_ar_carbinerifle" },
            { src = "W_AR_CarbineRifle_Diff", tgt = "w_ar_carbinerifle_d" },
            { src = "w_ar_carbinerifle", tgt = "W_AR_CarbineRifle_Diff" },
            { src = "w_ar_carbinerifle", tgt = "w_ar_carbinerifle" },
            { src = "w_ar_carbinerifle_d", tgt = "w_ar_carbinerifle_d" },
            { src = "W_PI_Pistol_Diff", tgt = "W_PI_Pistol_Diff" },
            { src = "w_pi_pistol", tgt = "W_PI_Pistol_Diff" },
            { src = "w_pi_pistol", tgt = "w_pi_pistol" }
        }
        for _, v in ipairs(variations) do
            if v.src ~= sourceTxn or v.tgt ~= targetTxn then
                trackTextureReplacement(sourceTxd, v.src, targetTxd, v.tgt, nil)
            end
        end
    elseif mode == "runtime" then
        local success, message, superseded = applyCustomCamoToWeapon(
            skin.patternId or skin.id,
            skin.primaryColor,
            skin.secondaryColor,
            skin.image or skin.preview,
            weaponName,
            weaponHash,
            skin.sourceTxd,
            skin.sourceTxn,
            revision
        )
        if superseded or revision ~= skinRevision then return false, nil, true end
        if not success then
            resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
            return false, message
        end
    else
        resetSkinAppearance(weaponName, weaponHash, weaponObj, tintIndex)
        return false, ("Bilinmeyen skin modu: %s"):format(mode)
    end

    appliedSkinId = skinId
    appliedSkinWeaponHash = weaponHash
    return true
end

local function create3DWeaponModel(weaponHash, category)
    clearAllTextureReplacements()

    if dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
        DeleteEntity(dummyWeaponObj)
        dummyWeaponObj = nil
    end

    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    local pedHeading = GetEntityHeading(playerPed)
    local forwardVec = GetEntityForwardVector(playerPed)

    local weaponModel = GetWeapontypeModel(weaponHash)
    if not weaponModel or weaponModel == 0 then return end

    RequestModel(weaponModel)
    local timeout = 0
    while not HasModelLoaded(weaponModel) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    local catSettings = (Config and Config.CategorySettings and category and Config.CategorySettings[category]) or {}
    local camDistance = catSettings.distance or 1.15
    local camFov = catSettings.fov or 40.0

    local spawnX = pedCoords.x + (forwardVec.x * camDistance)
    local spawnY = pedCoords.y + (forwardVec.y * camDistance)
    local spawnZ = pedCoords.z + 0.20

    dummyWeaponObj = CreateWeaponObject(weaponHash, 30, spawnX, spawnY, spawnZ, true, 1.0)

    if not dummyWeaponObj or dummyWeaponObj == 0 or not DoesEntityExist(dummyWeaponObj) then
        dummyWeaponObj = CreateObject(weaponModel, spawnX, spawnY, spawnZ, false, false, false)
    end

    SetModelAsNoLongerNeeded(weaponModel)

    objHeading = pedHeading - 90.0
    objPitch = 0.0

    SetEntityHeading(dummyWeaponObj, objHeading)
    SetEntityRotation(dummyWeaponObj, objPitch, 0.0, objHeading, 2, true)
    FreezeEntityPosition(dummyWeaponObj, true)
    SetEntityCollision(dummyWeaponObj, false, false)

    local configWeapon = Config and Config.Weapons and Config.Weapons[currentWeaponName]
    if configWeapon and configWeapon.attachments then
        for _, attachInfo in pairs(configWeapon.attachments) do
            if attachInfo.component then
                local modelHash = GetWeaponComponentTypeModel(attachInfo.component)
                if modelHash and modelHash ~= 0 and not HasModelLoaded(modelHash) then
                    RequestModel(modelHash)
                end
            end
        end
    end

    Wait(30)

    if configWeapon and configWeapon.attachments then
        for key, attachInfo in pairs(configWeapon.attachments) do
            if originalWeaponComponents[key] then
                applyComponentToWeaponObject(dummyWeaponObj, attachInfo.component)
            end
        end
    end

    if originalTintIndex then
        SetWeaponObjectTintIndex(dummyWeaponObj, originalTintIndex)
    end

    local camX = pedCoords.x + (forwardVec.x * (camDistance * 0.25))
    local camY = pedCoords.y + (forwardVec.y * (camDistance * 0.25))
    local camZ = pedCoords.z + 0.20

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, camX, camY, camZ)
    PointCamAtCoord(cam, spawnX, spawnY, spawnZ)
    SetCamFov(cam, camFov)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)

    SetTimecycleModifier("matrix")
    SetTimecycleModifierStrength(0.7)
end

local function destroy3DWeaponModel(keepTexture)
    ClearTimecycleModifier()
    if not keepTexture then
        clearAllTextureReplacements()
    end

    if dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
        DeleteEntity(dummyWeaponObj)
        dummyWeaponObj = nil
    end

    if cam and DoesCamExist(cam) then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end
end

-- Fast O(1) Cached Weapon Hash Lookup
local function getWeaponNameFromHash(weaponHash)
    if not weaponHash or weaponHash == 0 or weaponHash == `WEAPON_UNARMED` then return nil end
    return weaponHashToNameMap[weaponHash]
end

local function getActiveWeaponData()
    local playerPed = PlayerPedId()
    local _, weaponHash = GetCurrentPedWeapon(playerPed, true)

    if weaponHash == `WEAPON_UNARMED` or weaponHash == 0 then
        return nil
    end

    local matchedWeaponName = weaponHashToNameMap[weaponHash]
    local matchedConfig = matchedWeaponName and Config and Config.Weapons and Config.Weapons[matchedWeaponName]

    if not matchedConfig and QBCore and QBCore.Shared and QBCore.Shared.Weapons then
        for hashKey, wInfo in pairs(QBCore.Shared.Weapons) do
            local currentHash = type(hashKey) == 'number' and hashKey or GetHashKey(tostring(hashKey))
            if currentHash == weaponHash then
                matchedWeaponName = wInfo.name:lower()
                local cat = wInfo.weapontype or "Rifle"
                matchedConfig = {
                    label = wInfo.label or wInfo.name,
                    category = cat,
                    baseStats = { damage = 55, range = 50, accuracy = 65, control = 60, mobility = 70 },
                    attachments = {
                        suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, label = "Taktik Susturucu", category = "Muzzle", node = "suppressor", stats = { range = 15, control = 10 } },
                        flashlight = { component = `COMPONENT_AT_AR_FLSH`, label = "Taktik Fener", category = "Flashlight", node = "flashlight", stats = { accuracy = 10 } },
                        scope = { component = `COMPONENT_AT_SCOPE_MEDIUM`, label = "Taktik Dürbün", category = "Scope", node = "scope", stats = { accuracy = 15 } },
                        grip = { component = `COMPONENT_AT_AR_AFGRIP`, label = "Ön Tutamak", category = "Grip", node = "grip", stats = { control = 15 } }
                    }
                }
                break
            end
        end
    end

    if not matchedWeaponName then
        matchedWeaponName = "weapon_" .. tostring(weaponHash)
        matchedConfig = {
            label = "Ateşli Silah (" .. tostring(weaponHash) .. ")",
            category = "Rifle",
            baseStats = { damage = 50, range = 50, accuracy = 60, control = 60, mobility = 70 },
            attachments = {
                suppressor = { component = `COMPONENT_AT_AR_SUPP_02`, label = "Susturucu", category = "Muzzle", node = "suppressor" },
                flashlight = { component = `COMPONENT_AT_AR_FLSH`, label = "Taktik Fener", category = "Flashlight", node = "flashlight" }
            }
        }
    end

    local activeComponents = {}
    if matchedConfig.attachments then
        for attachKey, attachInfo in pairs(matchedConfig.attachments) do
            activeComponents[attachKey] = HasPedGotWeaponComponent(playerPed, weaponHash, attachInfo.component)
        end
    end

    local activeTint = GetPedWeaponTintIndex(playerPed, weaponHash)
    local inventoryItem, inventorySlot = findInventoryWeapon(matchedWeaponName, equippedInventorySlot)
    local activeSkin = getItemSkinId(inventoryItem)
    if inventoryItem and type(inventoryItem.info) == "table" and inventoryItem.info.tint ~= nil then
        activeTint = tonumber(inventoryItem.info.tint) or activeTint
    end

    if not inventoryItem and not activeSkin and appliedSkinWeaponHash == weaponHash then
        activeSkin = normalizeSkinId(appliedSkinId)
    end

    return {
        hash = weaponHash,
        name = matchedWeaponName,
        label = matchedConfig.label,
        category = matchedConfig.category or "Rifle",
        baseStats = matchedConfig.baseStats,
        attachments = matchedConfig.attachments,
        activeComponents = activeComponents,
        activeTint = activeTint,
        activeSkin = activeSkin,
        inventorySlot = inventorySlot,
        inventorySerial = getItemSerial(inventoryItem)
    }
end

local function closeModificationMenu(restoreOriginals)
    if not isUIOpen then return end
    if restoreOriginals and isSavingMods then
        QBCore.Functions.Notify("Silah modifikasyonu kaydediliyor, lütfen bekleyin.", "primary")
        return
    end
    isUIOpen = false
    isMenuTransition = true
    skinRevision = skinRevision + 1

    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    destroy3DWeaponModel(true)

    if currentWeaponHash then
        SetCurrentPedWeapon(playerPed, currentWeaponHash, true)
    end

    if restoreOriginals and currentWeaponHash then
        SetPedWeaponTintIndex(playerPed, currentWeaponHash, originalTintIndex)
        local configWeapon = Config and Config.Weapons and Config.Weapons[currentWeaponName]
        if configWeapon and configWeapon.attachments then
            for key, attachInfo in pairs(configWeapon.attachments) do
                if originalWeaponComponents[key] then
                    GiveWeaponComponentToPed(playerPed, currentWeaponHash, attachInfo.component)
                else
                    RemoveWeaponComponentFromPed(playerPed, currentWeaponHash, attachInfo.component)
                end
            end
        end
    end

    if currentWeaponHash and currentWeaponName then
        local finalSkinId = restoreOriginals and originalSkinId or selectedSkinId
        local finalTintIndex = restoreOriginals and originalTintIndex or selectedTintIndex
        local success, message = applyConfiguredSkin(
            finalSkinId,
            currentWeaponName,
            currentWeaponHash,
            finalTintIndex,
            nil
        )
        if success then
            lastAppearanceKey = table_concat({
                tostring(currentWeaponHash),
                tostring(normalizeSkinId(finalSkinId) or "default"),
                tostring(currentInventorySlot or "none"),
                tostring(finalTintIndex or 0)
            }, ":")
            nextAppearanceRetryAt = 0
            appearanceRetryDelay = 2000
        else
            lastAppearanceKey = nil
            nextAppearanceRetryAt = GetGameTimer() + appearanceRetryDelay
        end
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeUI" })
    isMenuTransition = false
end

local function openModificationMenu()
    if isUIOpen or isMenuTransition then return end
    isSavingMods = false
    local weaponData = getActiveWeaponData()
    if not weaponData then
        QBCore.Functions.Notify("Lütfen elinize modifiye edilebilen bir silah alın!", "error")
        return
    end
    if not (Config and Config.Weapons and Config.Weapons[normalizeWeaponName(weaponData.name)]) then
        QBCore.Functions.Notify("Bu silah vater-silahci config listesinde desteklenmiyor.", "error")
        return
    end
    if not weaponData.inventorySlot then
        QBCore.Functions.Notify("Aktif silahın envanter slotu belirlenemedi. Aynı silahtan birden fazla varsa birini yeniden kuşanın.", "error")
        return
    end
    isMenuTransition = true

    currentWeaponHash = weaponData.hash
    currentWeaponName = normalizeWeaponName(weaponData.name)
    currentInventorySlot = weaponData.inventorySlot
    currentInventorySerial = weaponData.inventorySerial
    attachmentRevisions = {}
    originalTintIndex = weaponData.activeTint
    selectedTintIndex = originalTintIndex
    originalSkinId = normalizeSkinId(weaponData.activeSkin)
    selectedSkinId = originalSkinId

    originalWeaponComponents = {}
    for key, active in pairs(weaponData.activeComponents) do
        originalWeaponComponents[key] = active
    end

    local playerPed = PlayerPedId()
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
    TaskStandStill(playerPed, -1)
    create3DWeaponModel(currentWeaponHash, weaponData.category)

    local skinApplied, skinError = applyConfiguredSkin(
        originalSkinId,
        currentWeaponName,
        currentWeaponHash,
        originalTintIndex,
        dummyWeaponObj
    )
    if not skinApplied and skinError then
        QBCore.Functions.Notify(skinError, "error")
        originalSkinId = nil
        selectedSkinId = nil
        weaponData.activeSkin = nil
    end

    isUIOpen = true
    isMenuTransition = false
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "openUI",
        weapon = weaponData,
        tints = Config and Config.Tints or {},
        skins = getAvailableSkins(currentWeaponName),
        nodesConfig = Config and Config.AttachmentNodes or {},
        categorySettings = Config and Config.CategorySettings or {},
        prices = Config and Config.Prices or {},
        savedSkins = {},
        unlockedSkins = {}
    })

    QBCore.Functions.TriggerCallback('vater-silahci:server:getUserUnlockedSkins', function(unlockedSkins)
        if isUIOpen and unlockedSkins then
            SendNUIMessage({ action = "updateUnlockedSkins", unlockedSkins = unlockedSkins })
        end
    end)

    QBCore.Functions.TriggerCallback('vater-silahci:server:getPlayerSkins', function(savedSkins)
        if isUIOpen and savedSkins then
            SendNUIMessage({ action = "updateSavedSkins", skins = savedSkins })
        end
    end)
end

RegisterNetEvent('vater-silahci:client:updateUnlockedSkins', function(unlockedSkins)
    clientUnlockedSkins = unlockedSkins or {}
    SendNUIMessage({ action = "updateUnlockedSkins", unlockedSkins = clientUnlockedSkins })
    if syncHeldWeaponAppearance and not isUIOpen then
        syncHeldWeaponAppearance(true)
    end
end)

CreateThread(function()
    Wait(1000)
    QBCore.Functions.TriggerCallback('vater-silahci:server:getUserUnlockedSkins', function(unlockedSkins)
        clientUnlockedSkins = unlockedSkins or {}
        if syncHeldWeaponAppearance and not isUIOpen then
            syncHeldWeaponAppearance(true)
        end
    end)
end)

local cmdName = (Config and Config.Command) or "silahmod"
RegisterCommand(cmdName, function()
    openModificationMenu()
end, false)

RegisterNetEvent('vater-silahci:client:openMenu', function()
    openModificationMenu()
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    closeModificationMenu(data and data.restore)
    cb('ok')
end)

RegisterNUICallback('notifyLocked', function(data, cb)
    local label = (data and data.label) or "Kaplama"
    QBCore.Functions.Notify("🔒 '" .. label .. "' kaplaması kilitlidir! Mağazadan/VIP satın alınmalıdır.", "error")
    cb('ok')
end)

RegisterNUICallback('rotateCamera', function(data, cb)
    if isUIOpen and dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
        if data.deltaX then
            objHeading = objHeading + (data.deltaX * 0.5)
        end
        if data.deltaY then
            objPitch = math_max(-45.0, math_min(45.0, objPitch + (data.deltaY * 0.5)))
        end
        SetEntityRotation(dummyWeaponObj, objPitch, 0.0, objHeading, 2, true)

        if data.zoom and cam then
            local currentFov = GetCamFov(cam)
            local newFov = math_max(20.0, math_min(65.0, currentFov + (data.zoom * 2.5)))
            SetCamFov(cam, newFov)
        end
    end
    cb('ok')
end)

RegisterNUICallback('previewAttachment', function(data, cb)
    if not isUIOpen or type(data) ~= "table" or type(data.key) ~= "string" then
        return cb('error')
    end
    local playerPed = PlayerPedId()
    if not currentWeaponHash or not currentWeaponName then return cb('error') end

    attachmentRevisions[data.key] = (attachmentRevisions[data.key] or 0) + 1
    local attachmentRevision = attachmentRevisions[data.key]

    local weaponConfig = Config and Config.Weapons and Config.Weapons[currentWeaponName]
    if weaponConfig and weaponConfig.attachments and weaponConfig.attachments[data.key] then
        local componentHash = getComponentHash(weaponConfig.attachments[data.key].component)
        if not componentHash or not IsWeaponComponentValid(currentWeaponHash, componentHash) then
            QBCore.Functions.Notify("Bu eklenti seçili silahla uyumlu değil.", "error")
            SendNUIMessage({ action = "setAttachmentState", key = data.key, state = not data.state })
            return cb('invalid_component')
        end

        if data.state then
            local modelHash = GetWeaponComponentTypeModel(componentHash)
            if modelHash and modelHash ~= 0 and not HasModelLoaded(modelHash) then
                RequestModel(modelHash)
                local timeout = 0
                while not HasModelLoaded(modelHash) and timeout < 50 do
                    Wait(10)
                    if not isUIOpen or attachmentRevisions[data.key] ~= attachmentRevision then
                        return cb('superseded')
                    end
                    timeout = timeout + 1
                end
                SetModelAsNoLongerNeeded(modelHash)
            end

            if not isUIOpen or attachmentRevisions[data.key] ~= attachmentRevision then
                return cb('superseded')
            end
            GiveWeaponComponentToPed(playerPed, currentWeaponHash, componentHash)
            if dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
                applyComponentToWeaponObject(dummyWeaponObj, componentHash)
            end
        else
            RemoveWeaponComponentFromPed(playerPed, currentWeaponHash, componentHash)
            if dummyWeaponObj and DoesEntityExist(dummyWeaponObj) then
                RemoveWeaponComponentFromWeaponObject(dummyWeaponObj, componentHash)
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('previewTint', function(data, cb)
    if isUIOpen and currentWeaponHash and data.tintId ~= nil then
        selectedTintIndex = math_max(0, tonumber(data.tintId) or 0)
        selectedSkinId = nil
        applyConfiguredSkin(nil, currentWeaponName, currentWeaponHash, selectedTintIndex, dummyWeaponObj)
    end
    cb('ok')
end)

RegisterNUICallback('updateCustomTextureDui', function(data, cb)
    if isUIOpen and currentWeaponHash and data then
        selectedSkinId = nil
        selectedTintIndex = 0
        skinRevision = skinRevision + 1
        local revision = skinRevision
        resetSkinAppearance(currentWeaponName, currentWeaponHash, dummyWeaponObj, selectedTintIndex)
        CreateThread(function()
            applyCustomCamoToWeapon(
                data.patternId,
                data.primaryColor,
                data.secondaryColor,
                data.imgUrl,
                currentWeaponName,
                currentWeaponHash,
                nil,
                nil,
                revision
            )
        end)
    end
    cb('ok')
end)

RegisterNUICallback('clearWeaponTexture', function(data, cb)
    if not isUIOpen then return cb('error') end
    selectedSkinId = nil
    if currentWeaponHash and currentWeaponName then
        applyConfiguredSkin(nil, currentWeaponName, currentWeaponHash, selectedTintIndex, dummyWeaponObj)
    end
    cb('ok')
end)

RegisterNUICallback('previewCustomSkin', function(data, cb)
    if not isUIOpen or not currentWeaponHash or not currentWeaponName then return cb('error') end

    if data and data.tintId ~= nil then
        selectedTintIndex = math_max(0, tonumber(data.tintId) or 0)
    end
    local requestedSkinId = normalizeSkinId(data and data.skin)
    local success, message, superseded = applyConfiguredSkin(
        requestedSkinId,
        currentWeaponName,
        currentWeaponHash,
        selectedTintIndex,
        dummyWeaponObj
    )

    if superseded then return cb('superseded') end

    if success then
        selectedSkinId = requestedSkinId
    else
        selectedSkinId = nil
        QBCore.Functions.Notify(message or "Skin uygulanamadı.", "error")
        SendNUIMessage({ action = "setSelectedSkin", skin = nil })
    end
    cb('ok')
end)

RegisterNUICallback('saveCustomSkinPattern', function(data, cb)
    QBCore.Functions.TriggerCallback('vater-silahci:server:saveCustomSkinPattern', function(success, savedSkins)
        if success then
            QBCore.Functions.Notify("Özel kaplama deseni şablonu kaydedildi!", "success")
            SendNUIMessage({ action = "updateSavedSkins", skins = savedSkins })
        else
            QBCore.Functions.Notify("Desen kaydı başarısız!", "error")
        end
    end, data)
    cb('ok')
end)

RegisterNUICallback('saveWeaponMods', function(data, cb)
    if not currentWeaponName or not currentWeaponHash then return cb('error') end
    if isSavingMods then return cb('busy') end
    data = type(data) == "table" and data or {}
    isSavingMods = true

    local requestedSkinId = normalizeSkinId(data.customSkin)
    selectedTintIndex = math_max(0, tonumber(data.tint) or selectedTintIndex or 0)

    QBCore.Functions.TriggerCallback('vater-silahci:server:saveWeaponMods', function(success, message, savedSkinId)
        isSavingMods = false
        if success then
            selectedSkinId = normalizeSkinId(savedSkinId)
            originalSkinId = selectedSkinId
            originalTintIndex = selectedTintIndex
            QBCore.Functions.Notify(message or "Silah modifikasyonu başarıyla uygulandı!", "success")
            closeModificationMenu(false)
        else
            QBCore.Functions.Notify(message or "İşlem başarısız veya yetersiz bakiye!", "error")
        end
    end, {
        weaponName = currentWeaponName,
        weaponHash = currentWeaponHash,
        inventorySlot = currentInventorySlot,
        inventorySerial = currentInventorySerial,
        components = data.components,
        tint = data.tint,
        customSkin = requestedSkinId or ""
    })
    cb('ok')
end)

RegisterNetEvent('qb-weapons:client:SetCurrentWeapon', function(weaponData)
    equippedInventorySlot = nil
    if type(weaponData) == "table" then
        equippedInventorySlot = tonumber(weaponData.slot)
    end
    lastAppearanceKey = nil
    CreateThread(function()
        Wait(50)
        if syncHeldWeaponAppearance and not isUIOpen then
            syncHeldWeaponAppearance(true)
        end
    end)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    lastAppearanceKey = nil
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function()
    lastAppearanceKey = nil
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    equippedInventorySlot = nil
    lastAppearanceKey = nil
    clearAllTextureReplacements()
    removeActiveSkinComponent()
end)

syncHeldWeaponAppearance = function(force)
    if isUIOpen or isMenuTransition then return end

    local playerPed = PlayerPedId()
    local _, weaponHash = GetCurrentPedWeapon(playerPed, true)
    if not weaponHash or weaponHash == 0 or weaponHash == `WEAPON_UNARMED` then
        if force or lastAppearanceKey ~= "unarmed" then
            clearAllTextureReplacements()
            removeActiveSkinComponent()
            appliedSkinId = nil
            appliedSkinWeaponHash = nil
            lastAppearanceKey = "unarmed"
            nextAppearanceRetryAt = 0
            appearanceRetryDelay = 2000
        end
        return
    end

    local weaponName = weaponHashToNameMap[weaponHash]
    if not weaponName then
        if force or lastAppearanceKey ~= ("unknown:" .. tostring(weaponHash)) then
            clearAllTextureReplacements()
            removeActiveSkinComponent()
            lastAppearanceKey = "unknown:" .. tostring(weaponHash)
            nextAppearanceRetryAt = 0
            appearanceRetryDelay = 2000
        end
        return
    end

    local inventoryItem, inventorySlot = findInventoryWeapon(weaponName, equippedInventorySlot)
    local skinId = getItemSkinId(inventoryItem)
    local tintIndex = GetPedWeaponTintIndex(playerPed, weaponHash)
    if inventoryItem and type(inventoryItem.info) == "table" and inventoryItem.info.tint ~= nil then
        tintIndex = tonumber(inventoryItem.info.tint) or tintIndex
    end

    local appearanceKey = table_concat({
        tostring(weaponHash),
        tostring(skinId or "default"),
        tostring(inventorySlot or "none"),
        tostring(tintIndex or 0)
    }, ":")

    if force or appearanceKey ~= lastAppearanceKey then
        if not force and GetGameTimer() < nextAppearanceRetryAt then return end

        local success, message, superseded = applyConfiguredSkin(skinId, weaponName, weaponHash, tintIndex, nil)
        if superseded then return end
        if not success and message then
            lastAppearanceKey = nil
            nextAppearanceRetryAt = GetGameTimer() + appearanceRetryDelay
            appearanceRetryDelay = math_min(appearanceRetryDelay * 2, 30000)
            return
        end
        lastAppearanceKey = appearanceKey
        nextAppearanceRetryAt = 0
        appearanceRetryDelay = 2000
    end
end

exports('RefreshWeaponSkin', function()
    lastAppearanceKey = nil
    syncHeldWeaponAppearance(true)
end)

-- Smart Poller: When weapon is steady, sleeps 1000ms; when changing, updates immediately
CreateThread(function()
    Wait(1000)
    while true do
        if not isUIOpen then
            syncHeldWeaponAppearance(false)
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    clearAllTextureReplacements()
    removeActiveSkinComponent()
    destroy3DWeaponModel(false)
    SetNuiFocus(false, false)
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    local _, weaponHash = GetCurrentPedWeapon(playerPed, true)
    local weaponName = weaponHashToNameMap[weaponHash]
    if weaponName then
        local inventoryItem = findInventoryWeapon(weaponName, equippedInventorySlot)
        local tintIndex = 0
        if inventoryItem and type(inventoryItem.info) == "table" then
            tintIndex = tonumber(inventoryItem.info.tint) or 0
        end
        setAppearanceTint(weaponHash, nil, tintIndex)
    end
    if duiObject then
        DestroyDui(duiObject)
        duiObject = nil
        duiHandle = nil
        duiTxdObj = nil
        duiReady = false
        duiPageReady = false
    end
end)

-- Bench / Interaction Markers Loop (Ultra Low Resmon 0.00ms)
CreateThread(function()
    while true do
        local sleep = 1000
        if Config and Config.UseBenchMarker and Config.BenchLocations and not isUIOpen then
            local playerPed = PlayerPedId()
            local pCoords = GetEntityCoords(playerPed)

            for i = 1, #Config.BenchLocations do
                local bench = Config.BenchLocations[i]
                local dx = pCoords.x - bench.coords.x
                local dy = pCoords.y - bench.coords.y
                local dz = pCoords.z - bench.coords.z
                local distSq = (dx * dx) + (dy * dy) + (dz * dz)

                if distSq < 100.0 then -- within 10 meters
                    sleep = 0
                    DrawMarker(2, bench.coords.x, bench.coords.y, bench.coords.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 163, 230, 53, 200, false, true, 2, false, nil, nil, false)
                    if distSq < (bench.radius * bench.radius) then
                        DisplayHelpTextThisFrame("SILAH_BENCH_TEXT", false)
                        if IsControlJustReleased(0, 38) then
                            openModificationMenu()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

