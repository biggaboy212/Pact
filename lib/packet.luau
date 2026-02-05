--!strict

--// Imports
local Transport = require("./transport")
local Types = require("./types")

--// Types
export type Packet<T> = {
	send: (self: Packet<T>, data: T, target: Player?) -> (),
	listen: (self: Packet<T>, callback: (data: T, sender: Player?) -> ()) -> ()
}

type InternalPacket<T> = {
	_callback: ((T, Player?) -> ())?,
	send: (self: InternalPacket<T>, data: T, target: Player?) -> (),
	listen: (self: InternalPacket<T>, callback: (T, Player?) -> ()) -> ()
}

--// Variables
local handlers = {} :: { [number]: (buffer, number, Player?) -> () }

--// Private Methods
local function route(payload: buffer, sender: Player?)
	local id = buffer.readu8(payload, 0)
	local handler = handlers[id]
	
	if handler then
		handler(payload, 1, sender)
	end
end

Transport.listen("TCP", route)
Transport.listen("UDP", route)

--// Constructor
local PacketModule = {}

function PacketModule.new<T>(def: Types.PacketDef<T>): Packet<T>
	local self = {} :: InternalPacket<T>
	local staticSize = def.schema.staticSize
	
	handlers[def.id] = function(b, offset, sender)
		local data = def.schema.read(b, offset)
		
		if self._callback then
			self._callback(data, sender)
		end
	end

	function self:send(data: T, target: Player?)
		local bodySize
		if staticSize then
			bodySize = staticSize
		else
			bodySize = def.schema.size(data)
		end

		local totalSize = 1 + bodySize
		local b = buffer.create(totalSize)

		buffer.writeu8(b, 0, def.id)
		def.schema.write(b, 1, data)
		Transport.send(def.protocol, b, target)
	end

	function self:listen(callback: (T, Player?) -> ())
		self._callback = callback
	end
	
	return self :: Packet<T>
end

return PacketModule