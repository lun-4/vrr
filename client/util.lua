local mod = {}
function mod.table_concat(...)
    local res = {}
    for k, v in pairs(...) do
        for k, v in pairs(v) do
            table.insert(res, v)
        end
    end
    return res
end
return mod
