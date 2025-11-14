-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- EventBus.lua
-- EventBus owns all event names internally. Initialize() builds them automatically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventBus = {}
EventBus.__index = EventBus

-- All events defined here:
EventBus.EventNames = {
	"PlotLoaded",
	"ItemPurchased",
	"Notification",
	"PurchaseFromShop",  -- Client → Server: Purchase request
	"CurrencyUpdated",   -- Server → Client: Currency changed
	-- Add more events here!
}

local EVENTS_FOLDER_NAME = "Events"

-- Stores RemoteEvent references
local RegisteredEvents = {}

--//////////////////////////////////////////////////////////
-- Initialization
--//////////////////////////////////////////////////////////

function EventBus.Initialize()
	-- Create/Find Events folder
	local EventsFolder = ReplicatedStorage:FindFirstChild(EVENTS_FOLDER_NAME)
	if not EventsFolder then
		EventsFolder = Instance.new("Folder")
		EventsFolder.Name = EVENTS_FOLDER_NAME
		EventsFolder.Parent = ReplicatedStorage
	end

	-- Loop through internal event list
	for _, eventName in ipairs(EventBus.EventNames) do
		local event = EventsFolder:FindFirstChild(eventName)

		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = eventName
			event.Parent = EventsFolder
		end

		RegisteredEvents[eventName] = event
	end
end

--//////////////////////////////////////////////////////////
-- SERVER API
--//////////////////////////////////////////////////////////

function EventBus.Fire(eventName, player, data)
	local event = RegisteredEvents[eventName]
	if event then
		event:FireClient(player, data)
	end
end

function EventBus.FireAll(eventName, data)
	local event = RegisteredEvents[eventName]
	if event then
		event:FireAllClients(data)
	end
end

--//////////////////////////////////////////////////////////
-- CLIENT API
--//////////////////////////////////////////////////////////

function EventBus.On(eventName, callback)
	local event = RegisteredEvents[eventName]
	if event then
		return event.OnClientEvent:Connect(callback)
	end
end

function EventBus.FireServer(eventName, data)
	local event = RegisteredEvents[eventName]
	if event then
		event:FireServer(data)
	end
end

--//////////////////////////////////////////////////////////
-- SERVER-SIDE LISTENING API
--//////////////////////////////////////////////////////////

function EventBus.OnServerEvent(eventName, callback)
	local event = RegisteredEvents[eventName]
	if event then
		return event.OnServerEvent:Connect(callback)
	end
end

return EventBus
