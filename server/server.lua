local ESX = nil
local QBCore = nil

local trackerPairItemName = 'cw_tracking_pair'
local receiverItemName = 'cw_receiver'
local trackerItemName = 'cw_tracker'

local useDebug = Config.Debug
local installedTrackers = {}

if Config.Core == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
else
    print('^1UNSUPPORTED CORE')
end

local function notify(src, text, type)
    if Config.UseOxLib then
        TriggerClientEvent('ox_lib:notify', src, {
            title = text,
            type = type,
        })

    else
        TriggerClientEvent('QBCore:Notify', src, text, type)
    end
end

local function vehicleExists(netid)
    local entity = NetworkGetEntityFromNetworkId(netid)
    if useDebug then print('Vehicle entity for netid', netid, entity) end
    if entity == 0 then -- vehicle has been removed
        return false
    end
    return true
end

local function updatePingForUser(src, trackerId)
    local tracker = installedTrackers[trackerId]
    if not tracker then
        notify(src, 'The tracker has gone dark', 'error')
    end
    if not vehicleExists(tracker.netid) then -- vehicle has been removed
        notify(src, 'The tracker has gone dark', 'error')
        installedTrackers[trackerId] = nil
    else
        local entity = NetworkGetEntityFromNetworkId(tracker.netid)
        local location = GetEntityCoords(entity)
        TriggerClientEvent('cw-vehicletrackers:client:updateBlip', src, trackerId, location)
    end
end

local function generateUUID()
    local template ='xxxx-xx-xxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function addItemBridge(src, item, info)
    if Config.Inventory == 'qb' then
    	local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddItem(item, 1, nil, info)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
    elseif Config.Inventory == 'ox' then
        exports.ox_inventory:AddItem(src, item, 1, info)
    else
        print('^1You fucked up the inventory config you dofus')
    end
end

local function removeItemBridge(src, itemName, info)
    if Config.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.RemoveItem(itemName, 1, nil)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
        return true
    elseif Config.Inventory == 'ox' then
        return exports.ox_inventory:RemoveItem(src, itemName, 1, info, nil)
    else
        print('^1You fucked up the inventory config you dofus')
    end
end

local function createTrackerPair(src) -- give the combo item
    local trackerId = generateUUID()
    addItemBridge(src, trackerPairItemName, { trackerId = trackerId })
end exports('createTrackerPair', createTrackerPair)

local function swapTrackerPair(src, trackerId) -- remove combo item
    if removeItemBridge(src, trackerPairItemName, { trackerId = trackerId }) then
        addItemBridge(src, receiverItemName, { trackerId = trackerId })
    else
        print('^1Lacking tracker pair item')
    end
end

local function useTrackerPair(src, metadata)
    if metadata and metadata.trackerId then
        if useDebug then print('Using tracking pair item with tracker id: ', metadata.trackerId) end
        TriggerClientEvent('cw-vehicletrackers:client:attemptToApplyTracker', src, metadata.trackerId)
    else
        if useDebug then print('^1This item is broken as the developer is to lazy to read readmes.', json.encode(metadata, {indent=true})) end
    end
end

local function useTracker(src, metadata)
    if metadata and metadata.trackerId then
        if useDebug then print('Using tracking pair item with tracker id: ', metadata.trackerId) end
        TriggerClientEvent('cw-vehicletrackers:client:attemptToApplyTracker', src, metadata.trackerId, true)
    else
        if useDebug then print('^1This item is broken as the developer is to lazy to read readmes.', json.encode(metadata, {indent=true})) end
    end
end

local function useReceiver(src, metadata)
    if installedTrackers[metadata.trackerId] == nil then notify(src, 'Can not find tracker', 'error') return end
    if metadata and metadata.trackerId then
        if useDebug then print('Using tracking receiver with tracker id: ', metadata.trackerId) end
        updatePingForUser(src, metadata.trackerId)
    else
        if useDebug then print('^1This item is broken as the developer is to lazy to read readmes.', json.encode(metadata, {indent=true})) end
    end
end

RegisterNetEvent('cw-vehicletrackers:server:addToList', function(netid, trackerId, usingTracker)
    if installedTrackers[trackerId] then if useDebug then print('^2Tracker already exists') end return end
    if useDebug then print('^2Adding vehicle to tracker list', netid, trackerId) end
    
    if vehicleExists(netid) then
        local tracker = { trackerId = trackerId, netid = netid, receiverSource = receiverSource }
        if useDebug then print(json.encode(tracker, {indent=true})) end
        installedTrackers[trackerId] = { trackerId = trackerId, netid = netid, receiverSource = receiverSource }
        local entity = NetworkGetEntityFromNetworkId(netid)
        Entity(entity).state.tracker = tracker
        if usingTracker then
            removeItemBridge(source, trackerItemName, {trackerId = trackerId})
        else
            swapTrackerPair(source, trackerId)
        end
    else
        if useDebug then print('^1Could not find vehicle') end
    end
end)

RegisterNetEvent('cw-vehicletrackers:server:removeFromList', function(netid, trackerId)
    if useDebug then print('^1Removing vehicle from list', netid, trackerId) end
    installedTrackers[trackerId] = nil
    if vehicleExists(netid) then
        local entity = NetworkGetEntityFromNetworkId(netid)
        Entity(entity).state.tracker = nil
        addItemBridge(source, trackerItemName, {trackerId = trackerId})
    end
end)

RegisterNetEvent('cw-vehicletrackers:server:createTrackerPair', function()
    createTrackerPair(source)
end)

if Config.Inventory == 'qb' then
    print('^7CW-VEHICLETRACKERS INVENTORY IS SET TO QB')
    print('If you encounter issues that are inventory related then please debug yourself. Support for qb-inventory is limited as we only use ox. Instead of just reporting issues consider reporting with a fix.')
    QBCore.Functions.CreateUseableItem(trackerPairItemName, function(source, item)
        useTrackerPair(source, item.info)
    end)
    QBCore.Functions.CreateUseableItem(trackerItemName, function(source, item)
        useTrackerPair(source, item.info)
    end)
    QBCore.Functions.CreateUseableItem(receiverItemName, function(source, item)
        useReceiver(source, item.info)
    end)
elseif Config.Inventory == 'ox' then
    print('^7CW-VEHICLETRACKERS INVENTORY IS SET TO OX')
    AddEventHandler('ox_inventory:usedItem', function(src, name, slotId, metadata)
        if name == trackerPairItemName then
            useTrackerPair(src, metadata)
        elseif name == receiverItemName then
            useReceiver(src, metadata)
        elseif name == trackerItemName then
            useTracker(src, metadata)
        end
    end)
else
    print('^1You fucked up the inventory config you dofus')
end


RegisterCommand("createtracker", function(source)
    if source > 0 then
        createTrackerPair(source)
    else
        print("^1This is console! no source to add to")
    end
end, true)


RegisterCommand("checkfortracker", function(source)
    if source > 0 then
        TriggerClientEvent('cw-vehicletrackers:client:checkForTracker', source)
    else
        print("^1This is console! no source to add to")
    end
end, true)


