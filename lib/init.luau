--// Imports
local Transport = require("@self/transport")
Transport.init()

local Packet = require("@self/packet")
local Schema = require("@self/schema")

--// Types
export type Packet<T> = Packet.Packet<T>

--// API
local Net = { 
    Packet = Packet, 
    Transport = Transport, 
    Schema = Schema 
}

return Net