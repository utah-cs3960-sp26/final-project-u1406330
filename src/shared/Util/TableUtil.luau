--!strict

-- Shared utility module for Table Util that supports reusable deterministic helpers.

local TableUtil = {}

function TableUtil.shallowCopy<T>(input: T): T
	local copy = {} :: any
	for key, value in pairs(input :: any) do
		copy[key] = value
	end
	return copy
end

function TableUtil.deepCopy<T>(input: T): T
	if type(input) ~= "table" then
		return input
	end

	local copy = {}
	for key, value in pairs(input :: any) do
		copy[TableUtil.deepCopy(key)] = TableUtil.deepCopy(value)
	end
	return copy :: any
end

function TableUtil.reconcile<T>(template: T, value: any): T
	if type(template) ~= "table" then
		if value == nil then
			return template
		end

		return value
	end

	local resolved = {}
	local source = if type(value) == "table" then value else {}

	for key, templateValue in pairs(template :: any) do
		resolved[key] = TableUtil.reconcile(templateValue, source[key])
	end

	for key, sourceValue in pairs(source :: any) do
		if resolved[key] == nil then
			resolved[key] = TableUtil.deepCopy(sourceValue)
		end
	end

	return resolved :: any
end

function TableUtil.merge<T>(base: T, override: T): T
	local result = TableUtil.deepCopy(base)
	for key, value in pairs(override :: any) do
		result[key] = value
	end
	return result
end

return TableUtil
