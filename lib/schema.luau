--!strict

--// Imports
local Types = require("./types")

--// Types
type Schema<T> = Types.Schema<T>

--// Variables
local Schema = {}

--// Private Methods
local function primitive(bytes: number, writeFn: (b: buffer, o: number, v: number) -> (), readFn: (b: buffer, o: number) -> number): Schema<number>
    return {
        staticSize = bytes,
        size = function() return bytes end,
        write = function(b, o, v) 
            writeFn(b, o, v) 
            return o + bytes 
        end,
        read = function(b, o) 
            return readFn(b, o), o + bytes 
        end,
    }
end

--// Primitives
function Schema.u8() return primitive(1, buffer.writeu8, buffer.readu8) end
function Schema.u16() return primitive(2, buffer.writeu16, buffer.readu16) end
function Schema.u32() return primitive(4, buffer.writeu32, buffer.readu32) end
function Schema.i8() return primitive(1, buffer.writei8, buffer.readi8) end
function Schema.i16() return primitive(2, buffer.writei16, buffer.readi16) end
function Schema.i32() return primitive(4, buffer.writei32, buffer.readi32) end
function Schema.f32() return primitive(4, buffer.writef32, buffer.readf32) end
function Schema.f64() return primitive(8, buffer.writef64, buffer.readf64) end

function Schema.boolean(): Schema<boolean>
    return {
        staticSize = 1,
        size = function() return 1 end,
        write = function(b, o, v) buffer.writeu8(b, o, v and 1 or 0); return o + 1 end,
        read = function(b, o) return buffer.readu8(b, o) == 1, o + 1 end,
    }
end

function Schema.string(): Schema<string>
    return {
        size = function(v) return 4 + #v end,
        write = function(b, o, v)
            local len = #v
            buffer.writeu32(b, o, len)
            buffer.writestring(b, o + 4, v)
            return o + 4 + len
        end,
        read = function(b, o)
            local len = buffer.readu32(b, o)
            local str = buffer.readstring(b, o + 4, len)
            return str, o + 4 + len
        end,
    }
end

function Schema.vector3(): Schema<Vector3>
    return {
        staticSize = 12,
        size = function() return 12 end,
        write = function(b, o, v)
            buffer.writef32(b, o, v.X)
            buffer.writef32(b, o + 4, v.Y)
            buffer.writef32(b, o + 8, v.Z)
            return o + 12
        end,
        read = function(b, o)
            local x = buffer.readf32(b, o)
            local y = buffer.readf32(b, o + 4)
            local z = buffer.readf32(b, o + 8)
            return Vector3.new(x, y, z), o + 12
        end,
    }
end

function Schema.struct<T>(definition: { [string]: Schema<any> }): Schema<T>
    local keys = {}
    local staticSize = 0
    local isStatic = true

    for k, subSchema in definition do
        table.insert(keys, k)
        
        if isStatic and subSchema.staticSize then
            staticSize += subSchema.staticSize
        else
            isStatic = false 
        end
    end
    table.sort(keys)

    return {
        staticSize = if isStatic then staticSize else nil,
        
        size = if isStatic then 
            function() return staticSize end 
        else 
            function(data: any)
                local total = 0
                for _, k in keys do
                    total += definition[k].size(data[k])
                end
                return total
            end,

        write = function(b, o, data: any)
            for _, k in keys do
                o = definition[k].write(b, o, data[k])
            end
            return o
        end,

        read = function(b, o)
            local data = {}
            for _, k in keys do
                local val, newOffset = definition[k].read(b, o)
                data[k] = val
                o = newOffset
            end
            return data :: T, o
        end,
    }
end

return Schema