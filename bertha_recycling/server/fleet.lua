-- One server-managed shared van for the single configured cargo plate.
local activeVan = 0
local busy = false

local function notify(src, msg, kind)
    TriggerClientEvent('bertha_recycling:notice', src, msg, kind or 'primary')
end

local function nearWorker(src)
    local cfg = Config.SalvageWorker
    local ped = GetPlayerPed(src)
    return cfg and ped ~= 0 and DoesEntityExist(ped)
        and #(GetEntityCoords(ped) - vector3(cfg.coords.x, cfg.coords.y, cfg.coords.z)) <= 5.0
end

local function currentVan()
    if activeVan ~= 0 and DoesEntityExist(activeVan) then return activeVan end
    activeVan = 0
    return 0
end

RegisterNetEvent('bertha_recycling:fleet:request', function()
    local src = source
    local cfg = Config.Fleet
    if not cfg or not cfg.enabled or not nearWorker(src) or busy then return end
    if currentVan() ~= 0 then
        return notify(src, 'The recycling van is already checked out.', 'error')
    end
    busy = true
    local spot = cfg.spawn
    local coords = vector3(spot.x, spot.y, spot.z)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if DoesEntityExist(vehicle) and #(GetEntityCoords(vehicle) - coords) < (cfg.clearRadius or 4.0) then
            busy = false
            return notify(src, 'The van parking bay is blocked. Clear it first.', 'error')
        end
    end
    local hash = joaat(Config.VehicleModel)
    local vehicle = CreateVehicleServerSetter(hash, 'automobile', spot.x, spot.y, spot.z, spot.w)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        busy = false
        return notify(src, 'Could not create the recycling van. Check bertha_boxville.', 'error')
    end
    SetVehicleNumberPlateText(vehicle, Config.VehiclePlate)
    activeVan = vehicle
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    busy = false
    TriggerClientEvent('bertha_recycling:fleet:issued', src, netId)
    notify(src, 'Recycling van ready. Your saved cargo is still tracked.', 'success')
end)

RegisterNetEvent('bertha_recycling:fleet:returnVan', function()
    local src = source
    local cfg = Config.Fleet
    if not cfg or not cfg.enabled or not nearWorker(src) or busy then return end
    local vehicle = currentVan()
    if vehicle == 0 then return notify(src, 'No fleet van is currently checked out.', 'error') end
    local ped = GetPlayerPed(src)
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return notify(src, 'Step out of the vehicle before returning it.', 'error')
    end
    if #(GetEntityCoords(vehicle) - GetEntityCoords(ped)) > 15.0 then
        return notify(src, 'Bring the van back to Box Man to return it.', 'error')
    end
    local cargo = GlobalState.recyclingCargo or {}
    local count = tonumber(cargo[Config.VehiclePlate]) or 0
    if cfg.requireEmptyToReturn and count > 0 then
        return notify(src, ('Unload all %d tires before returning the van.'):format(count), 'error')
    end
    busy = true
    DeleteEntity(vehicle)
    if DoesEntityExist(vehicle) then
        busy = false
        return notify(src, 'Could not return the van. Try again.', 'error')
    end
    activeVan = 0
    busy = false
    notify(src, 'Recycling van returned. Thank you!', 'success')
end)
