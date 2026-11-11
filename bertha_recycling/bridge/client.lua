Bridge = {}
function Bridge.notify(msg, kind)
    lib.notify({description=tostring(msg), type=(kind=='primary' or kind=='inform' or kind=='info') and 'inform' or (kind or 'inform')})
end
function Bridge.progress(label, duration)
    return lib.progressBar({duration=duration, label=label, canCancel=true, disable={move=true, car=true, combat=true}})
end
function Bridge.count(item)
    return exports.ox_inventory:Search('count', item) or 0
end
function Bridge.targetEntity(entity, options)
    if GetResourceState('ox_target')~='started' then return false end
    local opts={}
    for _,o in ipairs(options) do
        opts[#opts+1]={name=o.name or ('bertha_'..tostring(entity)..'_'..#opts), label=o.label,icon=o.icon,
            distance=o.distance or 3.0, onSelect=o.onSelect, canInteract=o.canInteract}
    end
    exports.ox_target:addLocalEntity(entity,opts)
    return true
end
