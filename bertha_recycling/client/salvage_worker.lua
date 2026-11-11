local worker
local busy = false

local function exchange(max)
    if busy then return end
    local count = 1
    if max then count = -1 else
        AddTextEntry('BERTHA_BOX_AMOUNT', 'How many recycling boxes?')
        DisplayOnscreenKeyboard(1, 'BERTHA_BOX_AMOUNT', '', '1', '', '', '', 3)
        while UpdateOnscreenKeyboard() == 0 do Wait(0) end
        if UpdateOnscreenKeyboard() ~= 1 then return end
        count = math.floor(tonumber(GetOnscreenKeyboardResult()) or 0)
        if count < 1 then return Bridge.notify('Enter a positive number of boxes.', 'error') end
    end
    busy = true
    local ok=Bridge.progress('Breaking down recycling boxes...',3000)
    busy=false
    if ok then TriggerServerEvent('bertha_recycling:salvageBoxes',count) end
end
CreateThread(function()
    local cfg=Config.SalvageWorker
    if not cfg or not cfg.enabled then return end
    local hash=joaat(cfg.model)
    RequestModel(hash)
    local deadline=GetGameTimer()+8000
    while not HasModelLoaded(hash) and GetGameTimer()<deadline do Wait(50) end
    if not HasModelLoaded(hash) then
        print('[bertha_recycling] Box Man ped model failed to load: '..tostring(cfg.model))
        return
    end
    local c=cfg.coords
    local z = c.z + (tonumber(cfg.zOffset) or 0.0)
    -- Fixed position: never use GTA ground probes, which can select the lumber pile.
    worker = CreatePed(4, hash, c.x, c.y, z, c.w, false, true)
    if worker == 0 or not DoesEntityExist(worker) then
        print('[bertha_recycling] Box Man ped could not be created')
        return
    end
    SetEntityAsMissionEntity(worker, true, true)
    -- CreatePed may adjust the Z origin; explicitly restore the floor-level Z.
    SetEntityCoordsNoOffset(worker, c.x, c.y, z, false, false, false)
    SetEntityHeading(worker, c.w)
    SetEntityInvincible(worker, true)
    SetBlockingOfNonTemporaryEvents(worker, true)
    FreezeEntityPosition(worker, true)
    ClearPedTasksImmediately(worker)
    local actual = GetEntityCoords(worker)
    print(('[bertha_recycling] Box Man requested Z %.3f; actual Z %.3f'):format(z, actual.z))
    Bridge.targetEntity(worker,{
        {icon='fas fa-box-open',label='Break down recycling boxes',onSelect=function()exchange(false)end},
        {icon='fas fa-boxes-stacked',label='Break down MAX boxes',onSelect=function()exchange(true)end},
        {icon='fas fa-truck',label='Collect Recycling Van',onSelect=function()
            TriggerServerEvent('bertha_recycling:fleet:request')
        end, canInteract=function() return Config.Fleet and Config.Fleet.enabled end},
        {icon='fas fa-warehouse',label='Return Recycling Van',onSelect=function()
            TriggerServerEvent('bertha_recycling:fleet:returnVan')
        end, canInteract=function() return Config.Fleet and Config.Fleet.enabled end},
        {icon='fas fa-clipboard-list',label='Check Van Cargo',onSelect=function()
            local cargo = GlobalState.recyclingCargo or {}
            local amount = tonumber(cargo[Config.VehiclePlate]) or 0
            Bridge.notify(('Recycling van: %d/%d tires'):format(amount, Config.MaxTyres), 'primary')
        end, canInteract=function() return Config.Fleet and Config.Fleet.enabled end},
    })
    SetModelAsNoLongerNeeded(hash)
end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then
        if worker and DoesEntityExist(worker) then
            exports.ox_target:removeLocalEntity(worker)
            DeleteEntity(worker)
        end
    end
end)

-- The server creates the single shared fleet vehicle; keys are assigned to the requesting player.
RegisterNetEvent('bertha_recycling:fleet:issued', function(netId)
    local vehicle = NetToVeh(netId)
    local deadline = GetGameTimer() + 5000
    while (vehicle == 0 or not DoesEntityExist(vehicle)) and GetGameTimer() < deadline do
        Wait(100)
        vehicle = NetToVeh(netId)
    end
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        -- GTA vehicle liveries are zero-based: 0 is the first selectable livery.
        local desired = (Config.Fleet and Config.Fleet.livery) or 0
        SetVehicleModKit(vehicle, 0)
        if GetVehicleLiveryCount(vehicle) > 0 then SetVehicleLivery(vehicle, desired) end
        if GetNumVehicleMods(vehicle, 48) > 0 then SetVehicleMod(vehicle, 48, desired, false) end
        local plate = GetVehicleNumberPlateText(vehicle)
        if Config.VehicleKeys == 'qb-vehiclekeys' and GetResourceState('qb-vehiclekeys') == 'started' then
            TriggerEvent('vehiclekeys:client:SetOwner', plate)
            TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
        end
    end
end)

-- Enforce the fleet livery for everyone who streams the van in, not only its borrower.
CreateThread(function()
    while true do
        Wait(2500)
        if Config.Fleet and Config.Fleet.enabled then
            local model = joaat(Config.VehicleModel)
            local plate = (Config.VehiclePlate or ''):gsub('%s+$','')
            for _, vehicle in ipairs(GetGamePool('CVehicle')) do
                if GetEntityModel(vehicle) == model and GetVehicleNumberPlateText(vehicle):gsub('%s+$','') == plate then
                    local desired = Config.Fleet.livery or 0
                    SetVehicleModKit(vehicle, 0)
                    if GetVehicleLiveryCount(vehicle) > 0 and GetVehicleLivery(vehicle) ~= desired then
                        SetVehicleLivery(vehicle, desired)
                    end
                    if GetNumVehicleMods(vehicle, 48) > 0 and GetVehicleMod(vehicle, 48) ~= desired then
                        SetVehicleMod(vehicle, 48, desired, false)
                    end
                end
            end
        end
    end
end)
