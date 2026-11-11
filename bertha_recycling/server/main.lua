-- Carrying is visual only; the tire remains in ox_inventory until transferred.
local function hasTyre(src)
    return Bridge.count(src,Config.UsedTyreItem)>0
end
local cargo = {}
local carried = {}
local activeVehicles = {}
local function plateOf(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    return (GetVehicleNumberPlateText(vehicle) or ''):gsub('%s+$','')
end
local function save()
    if Config.PersistCargo then SaveResourceFile(GetCurrentResourceName(), 'cargo.json', json.encode(cargo), -1) end
end
local function sync()
    GlobalState.recyclingCargo = cargo
end
local function near(src, entity, maxdist)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and DoesEntityExist(ped) and entity ~= 0 and DoesEntityExist(entity)
        and #(GetEntityCoords(ped)-GetEntityCoords(entity)) <= maxdist
end
local function vanFull()
    return (tonumber(cargo[Config.VehiclePlate]) or 0) >= Config.MaxTyres
end
local function denyWhenFull(src)
    if not vanFull() then return false end
    TriggerClientEvent('bertha_recycling:notice', src, ('Van full (%d/%d). Unload tires before collecting more.'):format(Config.MaxTyres, Config.MaxTyres), 'error')
    return true
end
local function getJobVan(src, netid)
    local veh = NetworkGetEntityFromNetworkId(tonumber(netid) or 0)
    if not near(src,veh,Config.LoadDistance) or GetEntityType(veh) ~= 2 then return nil end
    local plate = plateOf(veh)
    if not plate or plate ~= Config.VehiclePlate then return nil end
    if GetEntityModel(veh) ~= joaat(Config.VehicleModel) then return nil end
    return veh,plate
end
CreateThread(function()
    local data=LoadResourceFile(GetCurrentResourceName(),'cargo.json')
    if data then
        local ok,parsed=pcall(json.decode,data)
        if ok and type(parsed)=='table' then cargo=parsed end
    end
    cargo[Config.VehiclePlate]=math.max(0,math.min(Config.MaxTyres,tonumber(cargo[Config.VehiclePlate]) or 0))
    sync()
end)
RegisterNetEvent('bertha_recycling:load',function(netid)
    local src=source
    if not Bridge.allowed(src) or not hasTyre(src) then return end
    local _,plate=getJobVan(src,netid)
    if not plate then return end
    local count=tonumber(cargo[plate]) or 0
    if count>=Config.MaxTyres then TriggerClientEvent('bertha_recycling:notice',src,'Van is full','error') return end
    if not Bridge.takeItem(src,Config.UsedTyreItem,1) then return TriggerClientEvent('bertha_recycling:notice',src,'You need a used_tire item.','error') end
    carried[src]=nil
    cargo[plate]=count+1
    save();sync()
    TriggerClientEvent('bertha_recycling:carry',src,false)
end)
RegisterNetEvent('bertha_recycling:unload',function(netid)
    local src=source
    if not Bridge.allowed(src) then return end
    local _,plate=getJobVan(src,netid)
    if not plate then return end
    local count=tonumber(cargo[plate]) or 0
    if count<=0 then return end
    if not Bridge.rewardItem(src,Config.UsedTyreItem,1) then return TriggerClientEvent('bertha_recycling:notice',src,'Not enough inventory space for a tire.','error') end
    cargo[plate]=count-1
    if not carried[src] then carried[src]=true;TriggerClientEvent('bertha_recycling:carry',src,true) end
    save();sync()
end)

-- Shared world pickups: atomic claims, persisted cooldowns, and saved in-game spots.
local spotCooldowns = {}
local customSpots = {}
local function allSpots()
    local result = {}
    for _, v in ipairs(Config.TyreSpots) do result[#result+1] = {coords={x=v.coords.x,y=v.coords.y,z=v.coords.z},heading=v.heading or 0.0} end
    for _, v in ipairs(customSpots) do result[#result+1]=v end
    return result
end
local function syncSpots()
    GlobalState.recyclingSpots = allSpots()
    GlobalState.recyclingSpotCooldowns = spotCooldowns
end
CreateThread(function()
    local raw=LoadResourceFile(GetCurrentResourceName(),'collection.json')
    if raw then
        local ok,data=pcall(json.decode,raw)
        if ok and type(data)=='table' then
            customSpots=type(data.spots)=='table' and data.spots or {}
            spotCooldowns=type(data.cooldowns)=='table' and data.cooldowns or {}
        end
    end
    syncSpots()
end)
local function saveSpots()
    SaveResourceFile(GetCurrentResourceName(),'collection.json',json.encode({spots=customSpots,cooldowns=spotCooldowns}),-1)
    syncSpots()
end
RegisterNetEvent('bertha_recycling:addSpot',function(coords,heading)
    local src=source
    if not Config.DebugCommands then return end
    if type(coords)~='table' or type(coords.x)~='number' or type(coords.y)~='number' or type(coords.z)~='number' then return end
    local ped=GetPlayerPed(src)
    if ped==0 or #(GetEntityCoords(ped)-vector3(coords.x,coords.y,coords.z))>4.0 then return end
    if #customSpots>=100 then return end
    customSpots[#customSpots+1]={coords={x=coords.x,y=coords.y,z=coords.z},heading=tonumber(heading) or 0}
    saveSpots()
    TriggerClientEvent('bertha_recycling:notice',src,('Saved tire location #%d'):format(#Config.TyreSpots+#customSpots),'success')
end)

RegisterNetEvent('bertha_recycling:collect',function(spotIndex)
    local src=source
    if not Bridge.allowed(src) then return end
    if denyWhenFull(src) then return end
    local idx=math.floor(tonumber(spotIndex) or -1)
    local spot=allSpots()[idx]
    if not spot then return end
    local ped=GetPlayerPed(src)
    local c=spot.coords
    if ped==0 or #(GetEntityCoords(ped)-vector3(c.x,c.y,c.z))>5.0 then return end
    local now=os.time()
    if (tonumber(spotCooldowns[tostring(idx)]) or 0)>now then
        TriggerClientEvent('bertha_recycling:notice',src,'This tire has already been collected. Come back later.','error')
        return
    end
    if not Bridge.rewardItem(src,Config.UsedTyreItem,1) then return TriggerClientEvent('bertha_recycling:notice',src,'No inventory space for the tire.','error') end
    spotCooldowns[tostring(idx)]=now+Config.CollectionRespawnSeconds
    carried[src]=true
    saveSpots()
    TriggerClientEvent('bertha_recycling:carry',src,true)
end)
RegisterNetEvent('bertha_recycling:debugCollect',function()
    local src=source
    if not Config.DebugCommands then
        TriggerClientEvent('bertha_recycling:notice', src, 'Tire test command is disabled in config', 'error')
        return
    end
    if Config.DebugRequireAce and not IsPlayerAceAllowed(src, 'recycling.debug') then
        TriggerClientEvent('bertha_recycling:notice', src, 'You need recycling.debug permission for this command', 'error')
        return
    end
    if not Bridge.allowed(src) then
        TriggerClientEvent('bertha_recycling:notice', src, 'You cannot use the recycling job', 'error')
        return
    end
    if carried[src] then
        TriggerClientEvent('bertha_recycling:notice', src, 'You are already carrying a tire', 'error')
        return
    end
    if denyWhenFull(src) then return end
    if not Bridge.rewardItem(src,Config.UsedTyreItem,1) then return TriggerClientEvent('bertha_recycling:notice',src,'No inventory space for a tire.','error') end
    carried[src]=true
    TriggerClientEvent('bertha_recycling:carry',src,true)
end)
RegisterNetEvent('bertha_recycling:cancel',function()
    local src=source
    if carried[src] then carried[src]=nil;TriggerClientEvent('bertha_recycling:carry',src,false) end
end)
-- Bertha can be a CLIENT-LOCAL object from /testshredder. We never ask the
-- server to resolve its network ID. Instead we register the position and
-- validate both proximity and the time spent processing on the server.
local berthaLocations = {}
local processing = {}
local function validPosition(c)
    return type(c)=='table' and type(c.x)=='number' and type(c.y)=='number' and type(c.z)=='number'
        and math.abs(c.x)<10000 and math.abs(c.y)<10000 and math.abs(c.z)<2000
end
local function allowedBerthaPosition(src, coords)
    local ped=GetPlayerPed(src)
    if ped==0 or not DoesEntityExist(ped) then return false end
    local here=GetEntityCoords(ped)
    local registered=Config.BerthaPosition or berthaLocations[src]
    return registered and #(here-registered)<=Config.ShredderServerDistance
        and #(vector3(coords.x,coords.y,coords.z)-registered)<=2.0
end
RegisterNetEvent('bertha_recycling:berthaSeen',function(coords)
    local src=source
    if not validPosition(coords) then return end
    local ped=GetPlayerPed(src)
    if ped==0 or not DoesEntityExist(ped) then return end
    local pos=vector3(coords.x,coords.y,coords.z)
    if #(GetEntityCoords(ped)-pos)>Config.ShredderServerDistance+2.0 then return end
    if not Config.BerthaPosition then berthaLocations[src]=pos end
end)
RegisterNetEvent('bertha_recycling:shredStart',function(coords)
    local src=source
    if not Bridge.allowed(src) or not hasTyre(src) or processing[src] then return end
    if not validPosition(coords) or not allowedBerthaPosition(src,coords) then
        TriggerClientEvent('bertha_recycling:notice',src,'Move closer to Big Bertha','error')
        return
    end
    local token=('%d:%d'):format(src,math.random(100000,999999))
    processing[src]={token=token,started=GetGameTimer(),pos=vector3(coords.x,coords.y,coords.z)}
    TriggerClientEvent('bertha_recycling:shredBegin',src,token)
end)
RegisterNetEvent('bertha_recycling:shredCancel',function(token)
    local src=source
    if processing[src] and processing[src].token==token then processing[src]=nil end
end)
RegisterNetEvent('bertha_recycling:shredFinish',function(token)
    local src=source
    local state=processing[src]
    if not state or state.token~=token then return end
    processing[src]=nil
    if GetGameTimer()-state.started < Config.ShredDurationMs-300 then
        TriggerClientEvent('bertha_recycling:notice',src,'Shredding was interrupted','error')
        return
    end
    local coords={x=state.pos.x,y=state.pos.y,z=state.pos.z}
    if not Bridge.allowed(src) or not hasTyre(src) or not allowedBerthaPosition(src,coords) then
        TriggerClientEvent('bertha_recycling:notice',src,'Stay beside Big Bertha until shredding finishes','error')
        return
    end
    if not Bridge.takeItem(src,Config.UsedTyreItem,1) then return end
    if not Bridge.reward(src,Config.RubberPerTyre) then
        Bridge.rewardItem(src,Config.UsedTyreItem,1)
        TriggerClientEvent('bertha_recycling:notice',src,'Cannot add rubber. Check the rubber item exists and your inventory has space.','error')
        return
    end
    carried[src]=nil
    TriggerClientEvent('bertha_recycling:carry',src,false)
    TriggerClientEvent('bertha_recycling:notice',src,('Big Bertha produced %d rubber!'):format(Config.RubberPerTyre),'success')
end)
AddEventHandler('playerDropped',function() carried[source]=nil;processing[source]=nil;berthaLocations[source]=nil end)


-- Unified, shared Bertha state. All transfers and processing are server authoritative.
local machine = { intake=0, output=0, rolls=0, plasticScraps=0, plasticFlakes=0, plasticPellets=0, glassChunks=0, glassSheets=0, running=false, finishAt=0, batch=0, queue={} }
local function machineSave()
    SaveResourceFile(GetCurrentResourceName(), 'bertha.json', json.encode(machine), -1)
    local snapshot=json.decode(json.encode(machine))
    local reserved={output=0,rolls=0,plasticPellets=0,glassSheets=0}
    local function addReserve(recipe,batch)
        if recipe=='rubberRoll' then reserved.rolls=reserved.rolls+batch
        elseif recipe=='plasticPellets' then reserved.plasticPellets=reserved.plasticPellets+batch*Config.BerthaPlasticPelletsPerCraft
        elseif recipe=='glassSheets' then reserved.glassSheets=reserved.glassSheets+batch
        elseif recipe=='rubber' then reserved.output=reserved.output+batch*Config.RubberPerTyre end
    end
    if machine.running then addReserve(machine.recipe,machine.batch) end
    for _,job in ipairs(machine.queue) do addReserve(job.recipe,job.batch) end
    snapshot.reservedRubber=reserved.output
    snapshot.reservedRolls=reserved.rolls
    snapshot.reservedPellets=reserved.plasticPellets
    snapshot.reservedGlassSheets=reserved.glassSheets
    GlobalState.berthaMachine = snapshot
end
local function machineNearby(src)
    local ped=GetPlayerPed(src)
    return ped~=0 and DoesEntityExist(ped) and #(GetEntityCoords(ped)-Config.BerthaPosition) <= Config.ShredderServerDistance
end
local function machineNotify(src,msg,kind)
    TriggerClientEvent('bertha_recycling:notice',src,msg,kind or 'error')
end
-- FIFO jobs reserve ingredients at submission, preventing duplicate spending.
-- Output space is reserved across the running job and all queued jobs.
local function jobOutput(job)
    if job.recipe=='glassSheets' then return 'glassSheets',job.batch end
    if job.recipe=='rubberRoll' then return 'rolls',job.batch end
    if job.recipe=='plasticPellets' then return 'plasticPellets',job.batch*Config.BerthaPlasticPelletsPerCraft end
    return 'output',job.batch*Config.RubberPerTyre
end
local function jobDuration(job)
    if job.recipe=='glassSheets' then return math.ceil(job.batch*Config.BerthaGlassTimeMs/1000) end
    if job.recipe=='rubberRoll' then return math.ceil(job.batch*Config.BerthaProcessMsPerRoll/1000) end
    if job.recipe=='plasticPellets' then return math.ceil(job.batch*Config.BerthaPlasticPelletsTimeMs/1000) end
    return math.ceil(job.batch*Config.BerthaProcessMsPerTyre/1000)
end
local function machineReservations(field)
    local n=0
    if machine.running then
        local k,v=jobOutput({recipe=machine.recipe,batch=machine.batch})
        if k==field then n=n+v end
    end
    for _,job in ipairs(machine.queue) do
        local k,v=jobOutput(job)
        if k==field then n=n+v end
    end
    return n
end
local function machineStartNext(startAt)
    if machine.running or #machine.queue==0 then return false end
    local job=table.remove(machine.queue,1)
    machine.running=true
    machine.recipe=job.recipe
    machine.batch=job.batch
    machine.finishAt=(startAt or os.time())+jobDuration(job)
    return true
end
local function machineRefresh()
    local changed=false
    local now=os.time()
    -- Catch up after restarts; process queued jobs sequentially by their saved times.
    for _=1,100 do
        if machine.running and now>=machine.finishAt then
            local key,amount=jobOutput({recipe=machine.recipe,batch=machine.batch})
            machine[key]=machine[key]+amount
            local nextAt=machine.finishAt
            machine.running=false;machine.recipe=nil;machine.batch=0;machine.finishAt=0
            changed=true
            machineStartNext(nextAt)
        elseif not machine.running and #machine.queue>0 then
            machineStartNext(now);changed=true
        else break end
    end
    if changed then machineSave() end
end
local function enqueueJob(src,recipe,quantity)
    if #machine.queue >= (Config.BerthaMaxQueue or 20) then return machineNotify(src,'Bertha queue is full.') end
    local job={recipe=recipe,batch=quantity}
    local field,amount=jobOutput(job)
    local cap=field=='glassSheets' and Config.BerthaGlassOutputCapacity or (field=='output' and Config.BerthaOutputCapacity or (field=='rolls' and Config.BerthaRollCapacity or Config.BerthaPlasticOutputCapacity))
    if machine[field]+machineReservations(field)+amount>cap then return machineNotify(src,'Not enough output storage for this queued job. Collect finished products first.') end
    if recipe=='rubber' then
        if machine.intake<quantity then return machineNotify(src,'Not enough tires in intake.') end
        machine.intake=machine.intake-quantity
    elseif recipe=='rubberRoll' then
        local needed=quantity*Config.RubberPerRoll
        if machine.output<needed then return machineNotify(src,('Need %d finished rubber in storage to queue rolls.'):format(needed)) end
        machine.output=machine.output-needed
    elseif recipe=='glassSheets' then
        local needed=quantity*Config.BerthaGlassChunksPerSheet
        if machine.glassChunks<needed then return machineNotify(src,('Need %d glass chunks in intake.'):format(needed)) end
        machine.glassChunks=machine.glassChunks-needed
    elseif recipe=='plasticPellets' then
        local needed=quantity*Config.BerthaPlasticScrapsPerPellet
        if machine.plasticScraps<needed then return machineNotify(src,('Need %d plastic scraps in intake.'):format(needed)) end
        machine.plasticScraps=machine.plasticScraps-needed
    else return end
    table.insert(machine.queue,job)
    machineStartNext(os.time())
    machineSave()
    machineNotify(src,('Added %d x %s to Bertha production.'):format(quantity,recipe),'success')
end
CreateThread(function()
    Wait(1000)
    local raw=LoadResourceFile(GetCurrentResourceName(),'bertha.json')
    if raw then
        local ok,data=pcall(json.decode,raw)
        if ok and type(data)=='table' then
            machine.intake=math.max(0,math.min(Config.BerthaCapacity,tonumber(data.intake) or 0))
            machine.output=math.max(0,math.min(Config.BerthaOutputCapacity,tonumber(data.output) or 0))
            machine.rolls=math.max(0,math.min(Config.BerthaRollCapacity,tonumber(data.rolls) or 0))
            for _,field in ipairs({'plasticScraps','plasticFlakes','plasticPellets'}) do
                machine[field]=math.max(0,math.min(Config.BerthaPlasticCapacity,tonumber(data[field]) or 0))
            end
            -- Upgrade older stored flakes into equivalent raw plastic without losing materials.
            if machine.plasticFlakes > 0 then
                machine.plasticScraps=machine.plasticScraps+machine.plasticFlakes*Config.BerthaPlasticScrapsPerPellet
                machine.plasticFlakes=0
            end
            machine.glassChunks=math.max(0,math.min(Config.BerthaGlassCapacity,tonumber(data.glassChunks) or 0))
            machine.glassSheets=math.max(0,math.min(Config.BerthaGlassOutputCapacity,tonumber(data.glassSheets) or 0))
            machine.recipe=data.recipe
            if machine.recipe=='plasticFlakes' then
                -- A batch already consumed its ingredients; finish it as pellets instead.
                machine.recipe='plasticPellets'
            end
            machine.running=data.running==true
            machine.finishAt=tonumber(data.finishAt) or 0
            machine.batch=math.max(0,tonumber(data.batch) or 0)
            machine.queue={}
            if type(data.queue)=='table' then
                for _,job in ipairs(data.queue) do
                    if type(job)=='table' and (job.recipe=='rubber' or job.recipe=='rubberRoll' or job.recipe=='plasticPellets' or job.recipe=='glassSheets') then
                        local count=math.floor(tonumber(job.batch) or 0)
                        if count>=1 and count<=Config.BerthaPlasticCapacity and #machine.queue<(Config.BerthaMaxQueue or 20) then
                            table.insert(machine.queue,{recipe=job.recipe,batch=count})
                        end
                    end
                end
            end
        end
    end
    machineRefresh();machineSave()
    while true do
        Wait(1000)
        machineRefresh()
    end
end)
-- Tire carry is automatically synchronized from ox_inventory on the client.
RegisterNetEvent('bertha_recycling:carryInventoryTyre',function()
    local src=source
    if not Bridge.allowed(src) or carried[src] then return end
    if not hasTyre(src) then return TriggerClientEvent('bertha_recycling:notice',src,'You have no used tires.','error') end
    carried[src]=true
    TriggerClientEvent('bertha_recycling:carry',src,true)
end)

RegisterNetEvent('bertha_recycling:machineDepositInventoryTyres',function(amount)
    local src=source
    if not Bridge.allowed(src) then return machineNotify(src,'You cannot use this machine.') end
    if not machineNearby(src) then return machineNotify(src,'Move closer to Big Bertha before loading tires.') end
    amount=math.floor(tonumber(amount) or 0)
    if amount<1 or amount>Config.BerthaCapacity then return machineNotify(src,'Choose between 1 and '..Config.BerthaCapacity..' tires.') end
    if machine.intake+amount>Config.BerthaCapacity then return machineNotify(src,'Tire intake is full.') end
    if not Bridge.takeItem(src,Config.UsedTyreItem,amount) then return machineNotify(src,'Not enough used_tyre items in inventory.') end
    machine.intake=machine.intake+amount
    if carried[src] then carried[src]=nil;TriggerClientEvent('bertha_recycling:carry',src,false) end
    machineSave()
    machineNotify(src,('Loaded %d used tires.'):format(amount),'success')
end)

-- Native ox_inventory stashes for searchable industrial skips.
-- The server generates IDs, validates proximity, and seeds loot only when empty.
local skipPlayerCooldowns={}
local skipRestockAt={}
local registeredSkips={}
local function skipKey(c)
    return ('%d:%d:%d'):format(math.floor(c.x/3),math.floor(c.y/3),math.floor(c.z/3))
end
local function skipNear(src,c)
    if type(c)~='table' or type(c.x)~='number' or type(c.y)~='number' or type(c.z)~='number' then return false end
    local ped=GetPlayerPed(src)
    return ped~=0 and DoesEntityExist(ped) and #(GetEntityCoords(ped)-vector3(c.x,c.y,c.z))<=5.0
end
RegisterNetEvent('bertha_recycling:searchSkip',function(coords)
    local src=source
    if not Config.SkipSearchEnabled or not Config.SkipContainerEnabled or not Bridge.allowed(src) or not skipNear(src,coords) then return end
    local key=skipKey(coords)
    local id='bertha_skip_'..key
    local now=os.time()
    if (skipPlayerCooldowns[src] or 0)>now then return end
    skipPlayerCooldowns[src]=now+2
    if not registeredSkips[id] then
        exports.ox_inventory:RegisterStash(id,'Recycling Container',Config.SkipContainerSlots or 8,Config.SkipNativeMaxWeight or 150000,false)
        registeredSkips[id]=true
    end
    local inv=exports.ox_inventory:GetInventory(id,false)
    if not inv then return machineNotify(src,'Could not open recycling container.') end
    local empty=true
    for _,item in pairs(inv.items or {}) do
        if item and (tonumber(item.count) or 0)>0 then empty=false break end
    end
    if empty and now>=(skipRestockAt[key] or 0) then
        skipRestockAt[key]=now+(Config.SkipSearchCooldownSeconds or 600)
        if math.random(100)<=(Config.SkipSearchChance or 65) then
            local glass=math.random(100)<=(Config.SkipGlassRewardChance or 35)
            local name=glass and Config.BerthaGlassChunkItem or Config.UsedTyreItem
            local amount=glass and math.random(Config.SkipGlassMinReward or 1,Config.SkipGlassMaxReward or 4)
                or math.random(Config.SkipSearchMinReward or 1,Config.SkipSearchMaxReward or 3)
            local ok=exports.ox_inventory:AddItem(id,name,amount)
            if not ok then print(('[bertha_recycling] Could not seed %s in %s'):format(name,id)) end
        end
    end
    TriggerClientEvent('bertha_recycling:openSkip',src,id)
end)
AddEventHandler('playerDropped',function() skipPlayerCooldowns[source]=nil end)
RegisterNetEvent('bertha_recycling:machineAction',function(action,quantity)
    local src=source
    if not Bridge.allowed(src) or not machineNearby(src) then return end
    machineRefresh()
    quantity=math.floor(tonumber(quantity) or 1)
    if quantity<1 or quantity>math.max(Config.BerthaPlasticCapacity,Config.BerthaGlassCapacity) then return end
    if action=='deposit' then
        if not hasTyre(src) then return machineNotify(src,'You need a used tire in your pockets.') end
        if machine.intake>=Config.BerthaCapacity then return machineNotify(src,'Bertha intake is full.') end
        if not Bridge.takeItem(src,Config.UsedTyreItem,1) then return machineNotify(src,'No used_tire in inventory.') end
        carried[src]=nil
        machine.intake=machine.intake+1
        TriggerClientEvent('bertha_recycling:carry',src,false)
        machineSave()
    elseif action=='withdraw' then
        if machine.intake<=0 then return end
        if not Bridge.rewardItem(src,Config.UsedTyreItem,1) then return machineNotify(src,'No inventory space for a tire.') end
        machine.intake=machine.intake-1
        carried[src]=true
        TriggerClientEvent('bertha_recycling:carry',src,true)
        machineSave()
    elseif action=='start' then
        enqueueJob(src,'rubber',quantity)
    elseif action=='makeRolls' then
        enqueueJob(src,'rubberRoll',quantity)
    elseif action=='depositRubber' then
        -- Pocket rubber joins the existing rubber stock, which is also the
        -- ingredient source for rubber rolls. Do not exceed finished-goods
        -- capacity, including output reserved by queued tire jobs.
        if quantity>Config.BerthaOutputCapacity then return machineNotify(src,'Invalid rubber quantity.') end
        if machine.output+machineReservations('output')+quantity>Config.BerthaOutputCapacity then
            return machineNotify(src,'Not enough rubber storage space (including queued output).')
        end
        if not Bridge.takeItem(src,Config.RubberItem,quantity) then
            return machineNotify(src,'Not enough rubber in your pockets.')
        end
        machine.output=machine.output+quantity
        machineSave()
        machineNotify(src,('Loaded %d rubber from your pockets.'):format(quantity),'success')
    elseif action=='depositGlass' then
        if machine.glassChunks+quantity>Config.BerthaGlassCapacity then return machineNotify(src,'Glass intake is full.') end
        if not Bridge.takeItem(src,Config.BerthaGlassChunkItem,quantity) then return machineNotify(src,'Not enough glass chunks in your pockets.') end
        machine.glassChunks=machine.glassChunks+quantity;machineSave()
        machineNotify(src,('Loaded %d glass chunks.'):format(quantity),'success')
    elseif action=='withdrawGlass' then
        if quantity>machine.glassChunks then return machineNotify(src,'Not enough glass chunks in intake.') end
        if not Bridge.rewardItem(src,Config.BerthaGlassChunkItem,quantity) then return machineNotify(src,'No inventory space for glass chunks.') end
        machine.glassChunks=machine.glassChunks-quantity;machineSave()
    elseif action=='makeGlass' then
        if quantity>Config.BerthaGlassOutputCapacity then return machineNotify(src,'Too many glass sheets in one batch.') end
        enqueueJob(src,'glassSheets',quantity)
    elseif action=='collectGlass' then
        if machine.glassSheets<=0 then return machineNotify(src,'No glass sheets to collect.') end
        local amount=machine.glassSheets
        if not Bridge.rewardItem(src,Config.BerthaGlassSheetItem,amount) then return machineNotify(src,'Not enough space or glass_sheets item missing.') end
        machine.glassSheets=0;machineSave()
        machineNotify(src,('Collected %d glass sheets.'):format(amount),'success')
    elseif action=='depositPlastic' then
        if machine.plasticScraps+quantity>Config.BerthaPlasticCapacity then return machineNotify(src,'Plastic intake is full.') end
        if not Bridge.takeItem(src,Config.BerthaPlasticScrapItem,quantity) then return machineNotify(src,'Not enough plastic_scraps in inventory.') end
        machine.plasticScraps=machine.plasticScraps+quantity;machineSave();machineNotify(src,('Loaded %d plastic scraps. Intake: %d.'):format(quantity,machine.plasticScraps),'success')
    elseif action=='withdrawPlastic' then
        if quantity>machine.plasticScraps then return machineNotify(src,'Not enough plastic in intake.') end
        if not Bridge.rewardItem(src,Config.BerthaPlasticScrapItem,quantity) then return machineNotify(src,'No inventory space or item undefined.') end
        machine.plasticScraps=machine.plasticScraps-quantity;machineSave();machineNotify(src,('Withdrew %d plastic scraps.'):format(quantity),'success')
    elseif action=='makePellets' then
        enqueueJob(src,'plasticPellets',quantity)
    elseif action=='collectPellets' then
        if machine.plasticPellets<=0 then return machineNotify(src,'No pellets to collect.') end
        local amount=machine.plasticPellets
        if not Bridge.rewardItem(src,Config.BerthaPlasticPelletsItem,amount) then return machineNotify(src,'No space or plastic_pellets item missing.') end
        machine.plasticPellets=0;machineSave();machineNotify(src,('Collected %d plastic pellets.'):format(amount),'success')
    elseif action=='collectRolls' then
        if machine.rolls<=0 then return machineNotify(src,'No rubber rolls to collect.') end
        local amount=machine.rolls
        if not Bridge.rewardItem(src,Config.RubberRollItem,amount) then return machineNotify(src,'No inventory space or rubber_roll item is missing.') end
        machine.rolls=0
        machineSave()
        machineNotify(src,('Collected %d rubber roll(s).'):format(amount),'success')
    elseif action=='collect' then
        if machine.output<=0 then return machineNotify(src,'Output is empty.') end
        local amount=machine.output
        if not Bridge.reward(src,amount) then return machineNotify(src,'Not enough inventory space or rubber item missing.') end
        machine.output=0
        machineSave()
        TriggerClientEvent('bertha_recycling:notice',src,('Collected %d rubber.'):format(amount),'success')
    end
end)
