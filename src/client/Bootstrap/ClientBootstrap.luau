--!strict

local ClientBootstrap = {}

function ClientBootstrap.start()
	local AppController = require(script.Parent.Parent.Controllers.AppController)
	local app = AppController.new()
	app:start()

	print("[GemFactory] Client bootstrap started")
	return app
end

return ClientBootstrap

