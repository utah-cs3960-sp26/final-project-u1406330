--!strict

-- Shared utility module for Signal that supports reusable deterministic helpers.

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: () -> (),
}

function Signal.new()
	return setmetatable({
		_listeners = {},
	}, Signal)
end

function Signal:Connect(callback: (...any) -> ())
	local listeners = self._listeners
	local connection = {
		Disconnect = function()
			local index = table.find(listeners, callback)
			if index ~= nil then
				table.remove(listeners, index)
			end
		end,
	}

	table.insert(listeners, callback)
	return connection :: Connection
end

function Signal:Fire(...)
	for _, callback in ipairs(self._listeners) do
		callback(...)
	end
end

function Signal:Destroy()
	table.clear(self._listeners)
end

return Signal
