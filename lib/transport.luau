--// Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Types
export type Protocol = "TCP" | "UDP"

--// Constants
local IS_SERVER = RunService:IsServer()
local SOCKET_DIR = "NetSockets"

--// Variables
local tcpRemote: RemoteEvent
local udpRemote: UnreliableRemoteEvent

--// Private Methods
local function getRemotes()
	if IS_SERVER then
		local folder = Instance.new("Folder")
		folder.Name = SOCKET_DIR
		folder.Parent = ReplicatedStorage

		tcpRemote = Instance.new("RemoteEvent")
		tcpRemote.Name = "TCP"
		tcpRemote.Parent = folder

		udpRemote = Instance.new("UnreliableRemoteEvent")
		udpRemote.Name = "UDP"
		udpRemote.Parent = folder
	else
		local folder = ReplicatedStorage:WaitForChild(SOCKET_DIR)
		tcpRemote = folder:WaitForChild("TCP") :: RemoteEvent
		udpRemote = folder:WaitForChild("UDP") :: UnreliableRemoteEvent
	end
end

--// Public Methods
local Transport = {}

function Transport.init()
	getRemotes()
end

function Transport.send(protocol: Protocol, payload: buffer, recipient: Player?)
	if IS_SERVER then
		if recipient then
			if protocol == "TCP" then
				tcpRemote:FireClient(recipient, payload)
			else
				udpRemote:FireClient(recipient, payload)
			end
		else
			if protocol == "TCP" then
				tcpRemote:FireAllClients(payload)
			else
				udpRemote:FireAllClients(payload)
			end
		end
	else
		if protocol == "TCP" then
			tcpRemote:FireServer(payload)
		else
			udpRemote:FireServer(payload)
		end
	end
end

function Transport.listen(protocol: Protocol, callback: (payload: buffer, sender: Player?) -> ())
	local remote = if protocol == "TCP" then tcpRemote else udpRemote

	if IS_SERVER then
		remote.OnServerEvent:Connect(function(player, payload)
			if typeof(payload) ~= "buffer" then
				return
			end
			callback(payload, player)
		end)
	else
		remote.OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "buffer" then
				return
			end
			callback(payload, nil)
		end)
	end
end

return Transport
