--!strict

-- Client bootstrap module that wires controllers, UI, remotes, and shared state for the local player.

local ClientBootstrap = {}

function ClientBootstrap.start()
	local AppController = require(script.Parent.Parent.Controllers.AppController)
	local app = AppController.new()
	app:start()

	print("[GemFactory] Client bootstrap started")
	return app
end

return ClientBootstrap

