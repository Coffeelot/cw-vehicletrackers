local QBCore = nil

if not Config.UseOxLib then
    print("vehicletrackers: ^2Using QB")
    QBCore = exports['qb-core']:GetCoreObject()
else
    print("vehicletrackers: ^2Using OX")
end

local trackerCooldown = false

local useDebug = Config.Debug
local activeBlips = {}
local blipTimers = {}

if Config.Inventory == 'ox' then
    AddEventHandler('playerSpawned', function() -- Triggered when a player is spawned
        exports.ox_inventory:displayMetadata({
            trackerId = 'Tracker Id'
        })
    end)
end

local function notify(text, type)
    if Config.UseOxLib then
        lib.notify({
            title = text,
            type = type,
        })
    else
        QBCore.Functions.Notify(text, type)
    end
end

local function applyMinigame(cb)
    if Config.ApplyMinigame then
        if Config.ApplyMinigameLib == 'ox' then
            if lib.skillCheckActive() then lib.cancelSkillCheck() end
            local res = lib.skillCheck({'easy', 'easy'}, {'w', 'a', 's', 'd'})
            cb(res) return
        elseif Config.MinigameLib == 'ps' then
            exports['ps-ui']:Circle(function(success)
                    cb(success) return
            end, math.random(3,5), math.random(10,15))
            return
        else
            -- ADD APPLY MINGAME HERE
            -- MAKE SURE IT HAS A "cb(<result of minigame>) return" at the end. See above for examples
            -- IF YOU GOT ISSUES IMPLEMENTING THIS THEN DONT COME TO US TO ASK FOR HELP

            print('^1Not implemented. REQUIRES YOUR OWN EFFORT PLEASE READ CONFIG AND CLIENT.LUA')
        end        
    else
        cb(true)
    end
end

local function removeMinigame(cb)
    if Config.RemoveMinigame then
        if Config.RemoveMinigameLib == 'ox' then
            if lib.skillCheckActive() then lib.cancelSkillCheck() end
            local res = lib.skillCheck({'easy', 'easy'}, {'w', 'a', 's', 'd'})
            cb(res) return
        elseif Config.MinigameLib == 'ps' then
            exports['ps-ui']:Circle(function(success)
                    cb(success) return
            end, math.random(1,4), math.random(10,15))
            return
        else
            -- ADD REMOVE MINGAME HERE
            -- MAKE SURE IT HAS A "cb(<result of minigame>) return" at the end. See above for examples
            -- IF YOU GOT ISSUES IMPLEMENTING THIS THEN DONT COME TO US TO ASK FOR HELP
            print('^1Not implemented. REQUIRES YOUR OWN EFFORT PLEASE READ CONFIG AND CLIENT.LUA')
        end        
    else
        cb(true)
    end
end

local function removeFromList(vehicle)
    local tracker = Entity(vehicle).state.tracker
    local netid = NetworkGetNetworkIdFromEntity(vehicle)

    if useDebug then print('^1Removing from list', netid) end
    TriggerServerEvent('cw-vehicletrackers:server:removeFromList', netid, tracker.trackerId)
    Entity(vehicle).state:set('trackerIsKnown', false, false)
end exports('removeFromList', removeFromList)

local function removeBlip(trackingId)
    if activeBlips[trackingId] then
        if useDebug then print('^3Removing blip') end
        RemoveBlip(activeBlips[trackingId])
        activeBlips[trackingId] = nil
        blipTimers[trackingId] = nil
    else
        if useDebug then print('^1Could NOT remove blip') end
    end
end

local function offsetRadiusCenter(location)
    local xOffset = math.random(-1*Config.RadiusSize+5, Config.RadiusSize-5)
    local yOffset = math.random(-1*Config.RadiusSize+5, Config.RadiusSize-5)
    return vector3(location.x + xOffset, location.y + yOffset, location.z)
end

local function createBlip(trackerId, location)
    local offsetCenter = offsetRadiusCenter(location)
    local blipId = AddBlipForRadius(offsetCenter.x, offsetCenter.y, offsetCenter.z, Config.RadiusSize)
    SetBlipColour(blipId, Config.Blips.color)
    SetBlipAlpha(blipId, 128)
    activeBlips[trackerId] = blipId
    blipTimers[trackerId] = GetGameTimer()
end

local function moveBlip(trackerId, location)
    local offsetCenter = offsetRadiusCenter(location)
    SetBlipCoords(activeBlips[trackerId], offsetCenter.x, offsetCenter.y, offsetCenter.z)
    blipTimers[trackerId] = GetGameTimer()
end

local function checkIfVehicleHasATracker(vehicle)
    if Entity(vehicle).state.tracker then
        if useDebug then print('vehicle has a tracker') end
        Entity(vehicle).state:set('trackerIsKnown', true, false)
        return true
    else
        if useDebug then print('vehicle has no tracker') end
        return false
    end
end

local function applyAnimate(vehicle)
    TaskTurnPedToFaceEntity(PlayerPedId(), vehicle, 100)
    Citizen.SetTimeout(1000, function()
        TriggerEvent('animations:client:EmoteCommandStart', {'mechanic4'})
    end)
end

local function cancelAnimation()
    TriggerEvent('animations:client:EmoteCommandStart', {'c'})
end

local function progressBar(label, time, cb)
    if Config.UseOxLib then
        if lib.progressBar({
            label = label,
            duration = time,
            useWhileDead = false,
            canCancel = true,
            disable = { car = true }
        }) then
            cancelAnimation()
            cb()
        else
            cancelAnimation()
        end
    else
        QBCore.Functions.Progressbar("vehicle_tracker_progress", label, time, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
        }, {}, {}, function() -- Done
            cancelAnimation()
            cb()
        end, function() -- Cancel
            cancelAnimation()
        end)
    end
end

local function addToList(vehicle, trackerId, usingTracker)
    if NetworkGetNetworkIdFromEntity(vehicle) == 0 then
        if useDebug then print("Vehicle dont exist on server") end
    else
        local netid = NetworkGetNetworkIdFromEntity(vehicle)
        if useDebug then print('^2Adding vehicle to list', netid, trackerId) end
        TriggerServerEvent('cw-vehicletrackers:server:addToList', netid, trackerId, usingTracker)
    end
end exports('addToList', addToList)

RegisterNetEvent('cw-vehicletrackers:client:updateBlip', function(trackerId, location)
    if trackerCooldown then notify('Receiver is on cooldown') return end
    if activeBlips[trackerId] then
        moveBlip(trackerId, location)
    else
        createBlip(trackerId, location)
    end
    notify('Updated tracker', 'success')
    trackerCooldown = true
    SetTimeout(Config.TrackerCooldown, function()
        trackerCooldown = false
    end)
end)

RegisterNetEvent('cw-vehicletrackers:client:attemptToApplyTracker', function(trackerId, usingTracker)
    local nearestVehicle =  GetClosestVehicle(GetEntityCoords(PlayerPedId()), 3.000, 0, 70)
    if nearestVehicle == 0 then
        notify('No unoccupied vehicles close by', 'error')
        return
    else
        applyAnimate(nearestVehicle)
        applyMinigame(function(result)
            if result then
                if checkIfVehicleHasATracker(nearestVehicle) then
                    notify('You need to remove the current tracker first', 'error')
                    cancelAnimation()
                    return
                end
                progressBar('Mounting tracker', Config.AddTime or 5000, function() addToList(nearestVehicle, trackerId, usingTracker) end )
            else
                notify('You failed to apply the tracker', 'error')
                cancelAnimation()
            end
        end)
        
    end
end)

RegisterNetEvent('cw-vehicletrackers:client:checkForTracker', function()
    local nearestVehicle =  GetClosestVehicle(GetEntityCoords(PlayerPedId()), 3.000, 0, 70)
    if nearestVehicle == 0 then
        notify('No vehicles close by', 'error')
        return
    else
        checkIfVehicleHasATracker(nearestVehicle)
    end
end)

local function validateTimers()
    for trackingId, modified in pairs(blipTimers) do
        if GetTimeDifference(GetGameTimer(), modified) > Config.TimeUntilRemove then
            removeBlip(trackingId)
        end
    end
end

local function removeTracker()
    local nearestVehicle =  GetClosestVehicle(GetEntityCoords(PlayerPedId()), 3.000, 0, 70)
    if nearestVehicle == 0 then
        notify('No vehicles close by', 'error')
        return
    else
        applyAnimate(nearestVehicle)
        removeMinigame(function(result)
            if result then
                progressBar('Removing gps tracker', Config.AddTime or 5000, function() removeFromList(nearestVehicle) end)
            else
                notify('You failed to remove the tracker', 'error')
                cancelAnimation()
            end
        end)
    end
end

CreateThread(function()
    while true do
        validateTimers()
        Wait(1000)
    end
end)

local function scanNearestVehicle()
    local nearestVehicle =  GetClosestVehicle(GetEntityCoords(PlayerPedId()), 3.000, 0, 70)
    applyAnimate(nearestVehicle)
    progressBar('Checking vehicle for trackers', Config.TrackerCheckTime or 5000, function() 
        if nearestVehicle == 0 then
            notify('No vehicles close by', 'error')
            return
        else
            if checkIfVehicleHasATracker(nearestVehicle) then
                notify('You found a tracker!', 'success')
            else
                notify('You found no trackers', 'success')
            end
        end
    end)
end

if Config.OxTarget then
    exports.ox_target:addGlobalVehicle({
        {
            name = 'cw-vehicletrackers:check',
            icon = 'fa-solid fa-search',
            label = "Check for tracker",
            canInteract = function(entity, distance, coords, name, boneId)
                if lib.progressActive() then return false end
                if not Entity(entity).state.trackerIsKnown then return true end
                return false
            end,
            onSelect = function(data)
                scanNearestVehicle()
            end
        }
    })
    exports.ox_target:addGlobalVehicle({
        {
            name = 'cw-vehicletrackers:remove',
            icon = 'fa-solid fa-trash',
            label = "Remove tracker",
            canInteract = function(entity, distance, coords, name, boneId)
                if lib.progressActive() then return false end
                if Entity(entity).state.tracker and Entity(entity).state.trackerIsKnown then return true end
                return false
            end,
            onSelect = function(data)
                removeTracker()
            end
        }
    })
else
    exports['qb-target']:AddGlobalVehicle({
        options = {
            {
                name = 'cw-vehicletrackers:check',
                icon = 'fa-solid fa-search',
                label = "Check for tracker",
                canInteract = function(entity, distance, coords, name, boneId)
                    if not Entity(entity).state.trackerIsKnown then return true end
                    return false
                end,
                action = function(data)
                    scanNearestVehicle()
                end
            }
        },
        distance = 3
    })
    exports['qb-target']:AddGlobalVehicle({
        options = {
            {
                name = 'cw-vehicletrackers:remove',
                icon = 'fa-solid fa-trash',
                label = "Remove tracker",
                canInteract = function(entity, distance, coords, name, boneId)
                    if Entity(entity).state.tracker and Entity(entity).state.trackerIsKnown then return true end
                    return false
                end,
                action = function(data)
                    removeTracker()
                end
            }
        },
        distance = 3
    })
end