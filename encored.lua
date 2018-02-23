local def = {
    keywords = {name = true, type = true, items = true, index = true, default = true, optional = true},
    types = {number = true, string = true, bool = true, array = true, record = true},
    items = {number = true, string = true, bool = true}
}

local function is_array(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

local function valid_keys(field)
    if not (field.name and field.type) then
        return false
    end
    if field.default and field.optional then
        return false
    end

    for attrKey in pairs(field) do
        if not def.keywords[attrKey] then
            return false
        end
    end
    return true
end

local function valid_type(field)
    return def.types[field.type] or false
end

local function valid_items(field)
    if def.items[field.items] or (type(field.items) == "table" and #field.items ~= 0 and is_array(field.items)) then
        return true
    end
    return false
end

local function valid_default(field)
    if type(field.default) ~= field.type then
        return false
    end

    return true
end

local function is_field_valid(field, state)
    if not valid_keys(field) then
        return false
    end

    if not valid_type(field) then
        return false
    end

    if field.type == "array" or field.type == "record" then
        if not valid_items(field) then
            return false
        end
    elseif field.items then
        return false
    end

    if field.default then
        if not valid_default(field) then
            return false
        end
    end

    return true
end

local function validate_schema(schema)
    local function schema_rec(schema, state)
        for _, field in ipairs(schema) do
            if not is_field_valid(field, state) then
                state = false
            end

            if field.items and type(field.items) == "table" then
                state = schema_rec(field.items, state)
            end
        end

        return state
    end

    return schema_rec(schema, true)
end

local function validate_data(schema, data, dataType)
    -- if not toDataType argument provided autodetect
    if toDataType ~= "table" and toDataType ~= "array" then
        error("dataType '" .. toDataType .. "' is not supported.")
    end

    local function transformer_rec(schema, data, state)
        local dataInKey, dataOutKey = 0, 0
        for fieldIndex, field in ipairs(schema) do
            if toDataType == "array" then
                dataInKey, dataOutKey = field.name, fieldIndex
            else
                dataInKey, dataOutKey = fieldIndex, field.name
            end

            if field.type == "array" and type(field.items) == "table" and data ~= nil and data[dataInKey] ~= nil then
                state[dataOutKey] = {}
                for dataPartIndex, dataPart in ipairs(data[dataInKey]) do
                    state[dataOutKey][dataPartIndex] = {}
                    transformer_rec(field.items, dataPart, state[dataOutKey][dataPartIndex])
                end
            elseif field.type == "record" and type(field.items) == "table" and data ~= nil and data[dataInKey] ~= nil then
                state[dataOutKey] = {}
                transformer_rec(field.items, data[dataInKey], state[dataOutKey])
            else
                field.index = fieldIndex
                fn(field, data, state)
            end
        end

        return state
    end

    return transformer_rec(schema, data, {})
end

-- loop through schema and data while applying fn to individual fields
local function transformer(schema, data, fn, toDataType)
    -- if not toDataType argument provided autodetect
    if toDataType ~= "table" and toDataType ~= "array" then
        error("dataType '" .. toDataType .. "' is not supported.")
    end

    local function transformer_rec(schema, data, state)
        local dataInKey, dataOutKey = 0, 0
        for fieldIndex, field in ipairs(schema) do
            if toDataType == "array" then
                dataInKey, dataOutKey = field.name, fieldIndex
            else
                dataInKey, dataOutKey = fieldIndex, field.name
            end

            if field.type == "array" and type(field.items) == "table" and data ~= nil and data[dataInKey] ~= nil then
                state[dataOutKey] = {}
                for dataPartIndex, dataPart in ipairs(data[dataInKey]) do
                    state[dataOutKey][dataPartIndex] = {}
                    transformer_rec(field.items, dataPart, state[dataOutKey][dataPartIndex])
                end
            elseif field.type == "record" and type(field.items) == "table" and data ~= nil and data[dataInKey] ~= nil then
                state[dataOutKey] = {}
                transformer_rec(field.items, data[dataInKey], state[dataOutKey])
            else
                field.index = fieldIndex
                fn(field, data, state)
            end
        end

        return state
    end

    return transformer_rec(schema, data, {})
end

local function encode(schema, data)
    local function _encode(field, data, state)
        state[field.index] = data[field.name] or field.default
    end

    return transformer(schema, data, _encode, "array")
end

-- _decode(field.items, data[field.index], state[field.name])

local function decode(schema, data)
    local function _decode(field, data, state)
        state[field.name] = data[field.index] or field.default
    end

    return transformer(schema, data, _decode, "table")
end

return {
    transformer = transformer,
    encode = encode,
    decode = decode,
    validate_schema = validate_schema
}
