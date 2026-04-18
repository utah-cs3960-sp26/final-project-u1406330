--!strict

-- Shared utility module for Id that supports reusable deterministic helpers.

local HttpService = game:GetService("HttpService")

local Id = {}

function Id.new(prefix: string?)
	local guid = HttpService:GenerateGUID(false)
	if prefix == nil or prefix == "" then
		return guid
	end

	return prefix .. "_" .. guid
end

return Id
