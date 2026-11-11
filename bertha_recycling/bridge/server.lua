Bridge = {}
function Bridge.allowed(src)
    if not Config.RequireJob then return true end
    local player=exports.qbx_core:GetPlayer(src)
    local job=player and player.PlayerData and player.PlayerData.job
    return job and Config.AllowedJobs[job.name] == true or false
end
function Bridge.count(src,item)
    return exports.ox_inventory:GetItemCount(src,item) or 0
end
function Bridge.rewardItem(src,item,amount)
    if not amount or amount<1 then return false end
    if not exports.ox_inventory:CanCarryItem(src,item,amount) then return false end
    return exports.ox_inventory:AddItem(src,item,amount) == true
end
function Bridge.reward(src,amount) return Bridge.rewardItem(src,Config.RubberItem,amount) end
function Bridge.takeItem(src,item,amount)
    if not amount or amount<1 or Bridge.count(src,item)<amount then return false end
    return exports.ox_inventory:RemoveItem(src,item,amount) == true
end
