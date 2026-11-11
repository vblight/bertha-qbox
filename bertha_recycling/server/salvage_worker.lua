local processing={}
local function notify(src,msg,kind) TriggerClientEvent('bertha_recycling:notice',src,msg,kind or 'error') end
local function chooseReward(cfg)
    local total=0
    for _,v in ipairs(cfg.rewards) do total=total+v.weight end
    if total<=0 then return end
    local roll=math.random(total)
    for _,v in ipairs(cfg.rewards) do
        roll=roll-v.weight
        if roll<=0 then return v end
    end
end
RegisterNetEvent('bertha_recycling:salvageBoxes',function(requested)
    local src=source
    local cfg=Config.SalvageWorker
    if not cfg or not cfg.enabled or processing[src] then return end
    local ped=GetPlayerPed(src)
    if ped==0 or #(GetEntityCoords(ped)-vector3(cfg.coords.x,cfg.coords.y,cfg.coords.z))>4.0 then return end
    local available=Bridge.count(src,cfg.boxItem)
    local count=tonumber(requested)
    if count==-1 then count=math.min(available,cfg.maxPerExchange) end
    if not count or count~=math.floor(count) or count<1 or count>cfg.maxPerExchange then return notify(src,'Invalid box quantity.') end
    if available<count then return notify(src,'You do not have that many recycling boxes.') end
    processing[src]=true
    local rewards={}
    for _=1,count do
        local entry=chooseReward(cfg)
        if not entry then processing[src]=nil;return notify(src,'Worker rewards are not configured.') end
        local amount=math.random(entry.min,entry.max)
        rewards[entry.item]=(rewards[entry.item] or 0)+amount
    end
    if not Bridge.takeItem(src,cfg.boxItem,count) then processing[src]=nil;return notify(src,'Could not remove recycling boxes.') end
    local granted={}
    local ok=true
    for item,amount in pairs(rewards) do
        if Bridge.rewardItem(src,item,amount) then granted[item]=amount else ok=false;break end
    end
    if not ok then
        for item,amount in pairs(granted) do Bridge.takeItem(src,item,amount) end
        if not Bridge.rewardItem(src,cfg.boxItem,count) then
            print(('[bertha_recycling] CRITICAL: failed to refund %d boxes to %s'):format(count,src))
            notify(src,'Exchange failed. Contact staff: box refund failed.')
        else notify(src,'Not enough inventory space for materials; boxes refunded.') end
    else
        local parts={}
        for item,amount in pairs(rewards) do parts[#parts+1]=amount..' '..item end
        notify(src,'Recycled '..count..' box(es): '..table.concat(parts,', '),'success')
    end
    processing[src]=nil
end)
AddEventHandler('playerDropped',function() processing[source]=nil end)
