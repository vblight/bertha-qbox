local carrying=false
local refreshInventoryCarry
local carryProp=nil
local cargoProps={}
local targetedVehicles={}
local spawnedTyres={}
local function loadModel(name)
    local hash=joaat(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local untilTime=GetGameTimer()+5000
    while not HasModelLoaded(hash) and GetGameTimer()<untilTime do Wait(50) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end
local function removeCarry()
    if carryProp and DoesEntityExist(carryProp) then DeleteEntity(carryProp) end
    carryProp=nil
    ClearPedSecondaryTask(PlayerPedId())
end
local function startCarry()
    removeCarry()
    local ped=PlayerPedId()
    local hash=loadModel(Config.CarryProp)
    if not hash then Bridge.notify('Tire prop unavailable', 'error');return end
    carryProp=CreateObject(hash,GetEntityCoords(ped),false,false,false)
    SetEntityCollision(carryProp,false,false)
    local o=Config.CarryOffset
    AttachEntityToEntity(carryProp,ped,GetPedBoneIndex(ped,57005),o.x,o.y,o.z,o.rx,o.ry,o.rz,false,false,false,false,2,true)
    RequestAnimDict(Config.CarryAnim.dict)
    local deadline=GetGameTimer()+3000
    while not HasAnimDictLoaded(Config.CarryAnim.dict) and GetGameTimer()<deadline do Wait(50) end
    if HasAnimDictLoaded(Config.CarryAnim.dict) then
        TaskPlayAnim(ped,Config.CarryAnim.dict,Config.CarryAnim.clip,8.0,-8.0,-1,49,0.0,false,false,false)
    end
end
RegisterNetEvent('bertha_recycling:carry',function()
    SetTimeout(300,function() if refreshInventoryCarry then refreshInventoryCarry() end end)
end)
-- Carry is a visual reflection of inventory, not a separate inventory state.
refreshInventoryCarry=function()
    local wanted=Bridge.count(Config.UsedTyreItem)>0
    if wanted~=carrying then
        carrying=wanted
        if wanted then startCarry() else removeCarry() end
    end
end
AddEventHandler('ox_inventory:updateInventory',function() refreshInventoryCarry() end)
RegisterNetEvent('qbx_core:client:playerLoaded',function() Wait(500);refreshInventoryCarry() end)
CreateThread(function() Wait(2000);while true do Wait(1500);refreshInventoryCarry() end end)
RegisterCommand('carrytyre',function() refreshInventoryCarry() end,false)

-- Search world industrial skips through ox_target. A local progress bar is cosmetic;
-- the server generates shared container contents and validates transfers.
CreateThread(function()
    if not Config.SkipSearchEnabled then return end
    while GetResourceState('ox_target')~='started' do Wait(1000) end
    exports.ox_target:addModel(Config.SkipSearchModels,{{name='bertha_search_skip',icon='fas fa-search',label='Search Recycling Container',distance=2.5,onSelect=function(data)
        local entity=data.entity
        if not DoesEntityExist(entity) then return end
        local c=GetEntityCoords(entity)
        local ped=PlayerPedId()
        local dict='amb@prop_human_bum_bin@base'
        RequestAnimDict(dict)
        local timeout=GetGameTimer()+2500
        while not HasAnimDictLoaded(dict) and GetGameTimer()<timeout do Wait(25) end
        if HasAnimDictLoaded(dict) then TaskPlayAnim(ped,dict,'base',8.0,-8.0,Config.SkipSearchSeconds*1000,1,0,false,false,false) end
        local ok=Bridge.progress('Searching industrial skip...',Config.SkipSearchSeconds*1000)
        ClearPedTasks(ped)
        if ok then TriggerServerEvent('bertha_recycling:searchSkip',{x=c.x,y=c.y,z=c.z}) end
    end}})
end)
RegisterNetEvent('bertha_recycling:notice',function(msg,kind) Bridge.notify(msg,kind) end)
local function getCargoCount(plate)
    local data=GlobalState.recyclingCargo or {}
    return tonumber(data[(plate or ''):gsub('%s+$','')]) or 0
end
local function isVanFull()
    return getCargoCount(Config.VehiclePlate) >= Config.MaxTyres
end
local function clearCargo(key)
    local entry=cargoProps[key]
    if entry then
        for _,obj in ipairs(entry.objects) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
    end
    cargoProps[key]=nil
end
local function updateCargo(veh)
    local plate=(GetVehicleNumberPlateText(veh) or ''):gsub('%s+$','')
    if plate~=Config.VehiclePlate or GetEntityModel(veh)~=joaat(Config.VehicleModel) then return end
    local key=VehToNet(veh)
    if key==0 then return end
    local count=math.min(Config.MaxTyres,getCargoCount(plate))
    if cargoProps[key] and cargoProps[key].count==count and cargoProps[key].vehicle==veh then return end
    clearCargo(key)
    local hash=loadModel(Config.CargoProp)
    if not hash then return end
    local objects={}
    for i=1,count do
        local slot=Config.CargoSlots[i]
        if slot then
            local obj=CreateObject(hash,GetEntityCoords(veh),false,false,false)
            SetEntityCollision(obj,false,false)
            AttachEntityToEntity(obj,veh,0,slot.x,slot.y,slot.z,slot.rx,slot.ry,slot.rz,false,false,false,false,2,true)
            objects[#objects+1]=obj
        end
    end
    cargoProps[key]={vehicle=veh,count=count,objects=objects}
end
local function attachVanTarget(veh)
    if targetedVehicles[veh] then return end
    local registered = Bridge.targetEntity(veh,{
        {name='recycling_load',label='Load carried tire',icon='fa-solid fa-truck-ramp-box',distance=3.0,
          canInteract=function() return getCargoCount(GetVehicleNumberPlateText(veh))<Config.MaxTyres end,
          onSelect=function() TriggerServerEvent('bertha_recycling:load',VehToNet(veh)) end},
        {name='recycling_unload',label='Unload a tire',icon='fa-solid fa-dolly',distance=3.0,
          canInteract=function() return getCargoCount(GetVehicleNumberPlateText(veh))>0 end,
          onSelect=function() TriggerServerEvent('bertha_recycling:unload',VehToNet(veh)) end}
    })
    if registered then targetedVehicles[veh]=true end
end
CreateThread(function()
    while true do
        Wait(1600)
        local ped=PlayerPedId()
        local pos=GetEntityCoords(ped)
        for _,veh in ipairs(GetGamePool('CVehicle')) do
            if DoesEntityExist(veh) and #(GetEntityCoords(veh)-pos)<100.0 then
                if GetEntityModel(veh)==joaat(Config.VehicleModel) and (GetVehicleNumberPlateText(veh) or ''):gsub('%s+$','')==Config.VehiclePlate then
                    attachVanTarget(veh)
                    updateCargo(veh)
                end
            end
        end
        for key,entry in pairs(cargoProps) do
            if not DoesEntityExist(entry.vehicle) or #(GetEntityCoords(entry.vehicle)-pos)>130.0 then clearCargo(key) end
        end
        for veh in pairs(targetedVehicles) do if not DoesEntityExist(veh) then targetedVehicles[veh]=nil end end
    end
end)
-- Rear-door convenience: only operate the designated recycling van while parked.
-- Track doors we opened so walking away doesn't close doors opened manually.
local openedRearDoors = {}
CreateThread(function()
    while true do
        Wait(400)
        local cfg = Config.RearDoors
        if cfg and cfg.enabled then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local seen = {}
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(veh)
                    and GetEntityModel(veh) == joaat(Config.VehicleModel)
                    and (GetVehicleNumberPlateText(veh) or ''):gsub('%s+$', '') == Config.VehiclePlate
                    and #(GetEntityCoords(veh) - pos) < 16.0 then
                    seen[veh] = true
                    local rear = GetOffsetFromEntityInWorldCoords(veh, 0.0, cfg.rearOffsetY or -3.0, 0.0)
                    local distance = #(pos - rear)
                    local speed = GetEntitySpeed(veh)
                    local stopped = speed <= (cfg.maxSpeed or 0.8)
                    if not openedRearDoors[veh] and not inVehicle
                        and stopped and distance <= (cfg.openDistance or 3.5) then
                        -- Never change a remote vehicle without network control.
                        if NetworkHasControlOfEntity(veh) then
                            local opened = false
                            for _, door in ipairs(cfg.indices or {2, 3}) do
                                if GetVehicleDoorAngleRatio(veh, door) < 0.1
                                    and not IsVehicleDoorDamaged(veh, door) then
                                    SetVehicleDoorOpen(veh, door, false, false)
                                    opened = true
                                end
                            end
                            if opened then openedRearDoors[veh] = true end
                        else
                            NetworkRequestControlOfEntity(veh)
                        end
                    elseif openedRearDoors[veh] and
                        (distance >= (cfg.closeDistance or 5.0) or not stopped) then
                        if NetworkHasControlOfEntity(veh) then
                            for _, door in ipairs(cfg.indices or {2, 3}) do
                                if not IsVehicleDoorDamaged(veh, door) then
                                    SetVehicleDoorShut(veh, door, false)
                                end
                            end
                            openedRearDoors[veh] = nil
                        else
                            NetworkRequestControlOfEntity(veh)
                        end
                    end
                end
            end
            for veh in pairs(openedRearDoors) do
                if not DoesEntityExist(veh) then
                    openedRearDoors[veh] = nil
                elseif not seen[veh] and NetworkHasControlOfEntity(veh) then
                    for _, door in ipairs(cfg.indices or {2, 3}) do
                        if not IsVehicleDoorDamaged(veh, door) then
                            SetVehicleDoorShut(veh, door, false)
                        end
                    end
                    openedRearDoors[veh] = nil
                end
            end
        end
    end
end)
CreateThread(function()
    while true do
        if carrying then
            Wait(0)
            DisableControlAction(0,21,true) -- sprint
            DisableControlAction(0,22,true) -- jump
            DisableControlAction(0,23,true) -- enter vehicle
            DisableControlAction(0,24,true) -- attack
            if IsPedInAnyVehicle(PlayerPedId(),false) or IsEntityDead(PlayerPedId()) then
                TriggerServerEvent('bertha_recycling:cancel')
            elseif not IsEntityPlayingAnim(PlayerPedId(),Config.CarryAnim.dict,Config.CarryAnim.clip,3) then
                TaskPlayAnim(PlayerPedId(),Config.CarryAnim.dict,Config.CarryAnim.clip,8.0,-8.0,-1,49,0.0,false,false,false)
            end
        else Wait(500) end
    end
end)
RegisterCommand('droptyre',function()
    if carrying then TriggerServerEvent('bertha_recycling:cancel') end
end,false)
RegisterCommand('recycletyre',function()
    if Config.DebugCommands then
        if isVanFull() then
            Bridge.notify(('Van full (%d/%d). Unload tires first.'):format(Config.MaxTyres, Config.MaxTyres), 'error')
            return
        end
        TriggerServerEvent('bertha_recycling:debugCollect')
    else
        Bridge.notify('Tire test command is disabled in config', 'error')
    end
end,false)
RegisterCommand('recyclevan',function()
    if Config.Fleet and Config.Fleet.enabled then Bridge.notify('Collect the recycling van from Box Man.', 'primary'); return end
    if not Config.DebugCommands then Bridge.notify('Van test command is disabled in config', 'error'); return end
    local ped=PlayerPedId()
    local hash=loadModel(Config.VehicleModel)
    if not hash then Bridge.notify('rboxville is not streamed; ensure bertha_boxville starts before bertha_recycling','error');return end
    local coords=GetOffsetFromEntityInWorldCoords(ped,0.0,6.0,0.0)
    local veh=CreateVehicle(hash,coords.x,coords.y,coords.z,GetEntityHeading(ped),true,true)
    SetVehicleNumberPlateText(veh,Config.VehiclePlate)
    SetEntityAsMissionEntity(veh,true,true)
    -- Give the player keys immediately, so the cargo can be road-tested.
    if Config.VehicleKeys == 'qb-vehiclekeys' then
        if GetResourceState('qb-vehiclekeys') == 'started' then
            TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
            TriggerEvent('qb-vehiclekeys:client:AddKeys', GetVehicleNumberPlateText(veh))
        else
            Bridge.notify('qb-vehiclekeys is not running; van spawned without keys', 'error')
        end
    end
    Bridge.notify('Job van spawned. Saved cargo will reappear on this plate.','success')
end,false)
-- Stream world tyres only near the player; shared cooldown prevents duplicate claims.
local spotObjects = {}
local function clearSpot(i)
    if spotObjects[i] and DoesEntityExist(spotObjects[i]) then DeleteEntity(spotObjects[i]) end
    spotObjects[i]=nil
end
RegisterCommand('recycleaddspot',function()
    if not Config.DebugCommands then Bridge.notify('Spot editor disabled','error');return end
    local ped=PlayerPedId()
    local c=GetEntityCoords(ped)
    TriggerServerEvent('bertha_recycling:addSpot',{x=c.x,y=c.y,z=c.z},GetEntityHeading(ped))
end,false)
CreateThread(function()
    while true do
        Wait(2000)
        local spots=GlobalState.recyclingSpots or {}
        local cooldowns=GlobalState.recyclingSpotCooldowns or {}
        local pos=GetEntityCoords(PlayerPedId())
        local now=GetCloudTimeAsInt()
        for i,spot in ipairs(spots) do
            local c=spot.coords
            local dist=#(pos-vector3(c.x,c.y,c.z))
            local available=(tonumber(cooldowns[tostring(i)]) or 0)<=now
            if dist<Config.CollectionStreamDistance and available then
                if not spotObjects[i] or not DoesEntityExist(spotObjects[i]) then
                    local hash=loadModel(Config.CarryProp)
                    if hash then
                        local z=c.z
                        local found,ground=GetGroundZFor_3dCoord(c.x,c.y,c.z+25.0,false)
                        if found and math.abs(ground-c.z)<8.0 then z=ground end
                        local obj=CreateObject(hash,c.x,c.y,z+0.08,false,false,false)
                        SetEntityHeading(obj,spot.heading or 0.0)
                        PlaceObjectOnGroundProperly(obj)
                        FreezeEntityPosition(obj,true)
                        spotObjects[i]=obj
                        local index=i
                        Bridge.targetEntity(obj,{{name='recycling_pickup_'..i,label='Pick up used tire',icon='fa-solid fa-hand',distance=2.0,
                            canInteract=function()
                                local t=GlobalState.recyclingSpotCooldowns or {}
                                return not isVanFull() and (tonumber(t[tostring(index)]) or 0)<=GetCloudTimeAsInt()
                            end,
                            onSelect=function() TriggerServerEvent('bertha_recycling:collect',index) end}})
                    end
                end
            else clearSpot(i) end
        end
        for i in pairs(spotObjects) do if i>#spots then clearSpot(i) end end
    end
end)

-- Unified local static machine. Only one visible instance per client.
local berthaObject=nil
local berthaTargets={}
local panelOpen=false
local berthaZOffset = Config.BerthaZOffset or 0.0
local stopBerthaSmoke = function() end
local function spawnBertha()
    stopBerthaSmoke()
    if berthaObject and DoesEntityExist(berthaObject) then DeleteEntity(berthaObject) end
    berthaObject=nil
    local hash=loadModel(Config.ShredderModel)
    if not hash then Bridge.notify('Bertha model could not load','error');return end
    local p=Config.BerthaPosition
    berthaObject=CreateObjectNoOffset(hash,p.x,p.y,p.z + berthaZOffset,false,false,false)
    if berthaObject==0 then Bridge.notify('Bertha spawn failed','error');return end
    SetEntityHeading(berthaObject,Config.BerthaHeading)
    SetEntityCollision(berthaObject,true,true)
    FreezeEntityPosition(berthaObject,true)
    SetModelAsNoLongerNeeded(hash)
end
local function closePanel()
    panelOpen=false
    SetNuiFocus(false,false)
    SendNUIMessage({type='close'})
end
local function plasticInventoryCount() return Bridge.count(Config.BerthaPlasticScrapItem) end
local function tyreInventoryCount() return Bridge.count(Config.UsedTyreItem) end
local function glassInventoryCount() return Bridge.count(Config.BerthaGlassChunkItem) end
local function rubberInventoryCount() return Bridge.count(Config.RubberItem) end
local function openPanel()
    if panelOpen then return end
    panelOpen=true
    SetNuiFocus(true,true)
    SendNUIMessage({type='open',capacity=Config.BerthaCapacity,outputCapacity=Config.BerthaOutputCapacity,perTyre=Config.RubberPerTyre,perRoll=Config.RubberPerRoll,rollCapacity=Config.BerthaRollCapacity,plasticCapacity=Config.BerthaPlasticCapacity,plasticOutputCapacity=Config.BerthaPlasticOutputCapacity,plasticPerPellet=Config.BerthaPlasticScrapsPerPellet,glassCapacity=Config.BerthaGlassCapacity,glassOutputCapacity=Config.BerthaGlassOutputCapacity,glassPerSheet=Config.BerthaGlassChunksPerSheet,inventoryPlastic=plasticInventoryCount(),inventoryTyres=tyreInventoryCount(),inventoryRubber=rubberInventoryCount(),inventoryGlass=glassInventoryCount(),times={rubber=Config.BerthaProcessMsPerTyre,roll=Config.BerthaProcessMsPerRoll,pellets=Config.BerthaPlasticPelletsTimeMs,glass=Config.BerthaGlassTimeMs},carrying=carrying,state=GlobalState.berthaMachine or {}})
end
RegisterNUICallback('close',function(_,cb) closePanel();cb({ok=true}) end)
RegisterNUICallback('action',function(data,cb)
    if type(data)=='table' and ({deposit=true,withdraw=true,start=true,collect=true,makeRolls=true,collectRolls=true,depositPlastic=true,depositRubber=true,withdrawPlastic=true,makePellets=true,collectPellets=true,depositGlass=true,withdrawGlass=true,makeGlass=true,collectGlass=true})[data.action] then
        TriggerServerEvent('bertha_recycling:machineAction',data.action,tonumber(data.quantity) or 1)
    end
    cb({ok=true})
end)
RegisterNUICallback('depositInventoryTyres',function(data,cb)
    TriggerServerEvent('bertha_recycling:machineDepositInventoryTyres',tonumber(data and data.quantity) or 1)
    cb({ok=true})
end)
CreateThread(function()
    Wait(2000)
    if Config.BerthaAutoSpawn then spawnBertha() end
    while true do
        Wait(1000)
        if berthaObject and DoesEntityExist(berthaObject) and not berthaTargets[berthaObject] then
            local obj=berthaObject
            if Bridge.targetEntity(obj,{{name='recycling_bertha_panel',label='Open Big Bertha control panel',icon='fa-solid fa-gears',distance=Config.ShredderInteractionDistance,onSelect=openPanel}}) then
                berthaTargets[obj]=true
            end
        end
        if panelOpen then
            local pos=GetEntityCoords(PlayerPedId())
            if #(pos-Config.BerthaPosition)>Config.ShredderServerDistance+1.0 then closePanel()
            else SendNUIMessage({type='state',state=GlobalState.berthaMachine or {},carrying=carrying,inventoryPlastic=plasticInventoryCount(),inventoryTyres=tyreInventoryCount(),inventoryRubber=rubberInventoryCount(),inventoryGlass=glassInventoryCount()}) end
        end
    end
end)
-- Client-side smoke is tied to the server-authoritative machine running state.
local berthaSmokeHandle=nil
local smokeDictionary='core'
local smokeEffect='ent_amb_smoke_factory'
stopBerthaSmoke = function()
    if berthaSmokeHandle then
        StopParticleFxLooped(berthaSmokeHandle,false)
        berthaSmokeHandle=nil
    end
end
CreateThread(function()
    while true do
        Wait(650)
        local running=(GlobalState.berthaMachine or {}).running == true
        local exists=berthaObject and DoesEntityExist(berthaObject)
        local nearby=false
        local distance=999.0
        if exists then
            distance=#(GetEntityCoords(PlayerPedId())-GetEntityCoords(berthaObject))
            nearby=distance<35.0
        end
        if Config.BerthaSmoke and running and nearby then
            if not berthaSmokeHandle then
                RequestNamedPtfxAsset(smokeDictionary)
                local deadline=GetGameTimer()+2500
                while not HasNamedPtfxAssetLoaded(smokeDictionary) and GetGameTimer()<deadline do Wait(50) end
                if HasNamedPtfxAssetLoaded(smokeDictionary) and exists then
                    UseParticleFxAssetNextCall(smokeDictionary)
                    local offset=Config.BerthaSmokeOffset or vector3(0.0,0.0,1.5)
                    berthaSmokeHandle=StartParticleFxLoopedOnEntity(smokeEffect,berthaObject,offset.x,offset.y,offset.z,0.0,0.0,0.0,Config.BerthaSmokeScale or 0.85,false,false,false)
                    if berthaSmokeHandle==0 then berthaSmokeHandle=nil end
                end
            end
        else stopBerthaSmoke() end
        -- The UI runs the motor synth even when closed, once audio has been unlocked.
        if Config.BerthaSound then
            local level=(running and nearby) and math.max(0.0,1.0-distance/(Config.BerthaSoundRange or 22.0)) or 0.0
            SendNUIMessage({type='machineAudio',running=running and nearby,level=level,volume=Config.BerthaSoundVolume or 0.20})
        end
    end
end)
RegisterCommand('resetbertha',function() closePanel();spawnBertha() end,false)
-- Development tuning: /berthaz -0.2 lowers Bertha 20cm, /berthaz 0.2 raises her.
RegisterCommand('berthaz',function(_,args)
    local delta=tonumber(args[1])
    if not delta or math.abs(delta)>2.0 then
        Bridge.notify('Use /berthaz -0.2 to lower or /berthaz 0.2 to raise (metres)','primary')
        return
    end
    berthaZOffset=berthaZOffset+delta
    if berthaObject and DoesEntityExist(berthaObject) then
        local p=Config.BerthaPosition
        SetEntityCoordsNoOffset(berthaObject,p.x,p.y,p.z+berthaZOffset,false,false,false)
        FreezeEntityPosition(berthaObject,true)
    end
    Bridge.notify(('Bertha Z offset: %.2f m. Set Config.BerthaZOffset to keep it after restart.'):format(berthaZOffset),'success')
end,false)
AddEventHandler('onResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    closePanel()
    stopBerthaSmoke()
    if berthaObject and DoesEntityExist(berthaObject) then DeleteEntity(berthaObject) end
    removeCarry()
    for key in pairs(cargoProps) do clearCargo(key) end
    for i in pairs(spotObjects) do clearSpot(i) end
end)

RegisterNetEvent('bertha_recycling:openSkip',function(id)
    exports.ox_inventory:openInventory('stash',id)
end)
