local function deepclone(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[orig_key] = deepclone(orig_value, copies)
            end
            local mt = deepclone(getmetatable(orig), copies)
            setmetatable(copy, mt)
        end
    else
        copy = orig
    end
    return copy
end

Lib47.DeepClone = deepclone