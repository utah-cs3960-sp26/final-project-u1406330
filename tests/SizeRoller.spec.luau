--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local SizeRoller = require(Shared.Domain.SizeRoller)
local Sizes = require(Shared.Config.Sizes)

return function()
	-- 1. returns nil for empty pool
	local emptyRoll = SizeRoller.rollSize({}, nil)
	assert(emptyRoll == nil, "rolling on an empty pool should return nil")

	-- 2. returns nil for zero-weight pool
	local zeroPool = {
		{ id = "zero_a", weight = 0 },
		{ id = "zero_b", weight = 0 },
	}
	local zeroRoll = SizeRoller.rollSize(zeroPool, nil)
	assert(zeroRoll == nil, "rolling on a zero-weight pool should return nil")

	-- 3. getTotalWeight sums all positive weights
	local totalWeight = SizeRoller.getTotalWeight(Sizes.order)
	assert(totalWeight == 10000, "total weight of Sizes.order should be 10000, got " .. tostring(totalWeight))

	-- 4. returns a valid size entry from pool
	do
		local result = SizeRoller.rollSize(Sizes.order, nil)
		assert(result ~= nil, "rolling on a valid pool should return an entry")
		assert(type(result.scaleValue) == "number", "rolling on a valid pool should include a numeric scale")
		local found = false
		for _, entry in ipairs(Sizes.order) do
			if entry.id == result.id then
				found = true
				assert(result.scaleValue >= entry.minScale and result.scaleValue <= entry.maxScale, "rolled scale should fit the selected size range")
				break
			end
		end
		assert(found, "rolled size should be a member of the pool")
	end

	-- 5. seeded rng produces deterministic results
	do
		local rngA = Random.new(42)
		local rngB = Random.new(42)
		for i = 1, 100 do
			local a = SizeRoller.rollSize(Sizes.order, rngA)
			local b = SizeRoller.rollSize(Sizes.order, rngB)
			assert(a ~= nil and b ~= nil, "seeded rolls should not be nil")
			assert(a.id == b.id, "seeded rng should produce identical results on roll " .. tostring(i))
			assert(a.scaleValue == b.scaleValue, "seeded rng should produce identical scale values on roll " .. tostring(i))
		end
	end

	-- 6. weighted distribution favors smaller sizes
	do
		local rng = Random.new(1)
		local counts: { [string]: number } = {}
		for _, entry in ipairs(Sizes.order) do
			counts[entry.id] = 0
		end

		for _ = 1, 10000 do
			local result = SizeRoller.rollSize(Sizes.order, rng)
			assert(result ~= nil, "roll should not be nil on a valid pool")
			counts[result.id] += 1
		end

		assert(counts["small"] > counts["medium"], "small should appear more than medium")
		assert(counts["medium"] > counts["large"], "medium should appear more than large")
		assert(counts["large"] > counts["huge"], "large should appear more than huge")
		assert(counts["huge"] > counts["colossal"], "huge should appear more than colossal")
	end

	-- 7. all pool entries can appear
	do
		local rng = Random.new(1)
		local seen: { [string]: boolean } = {}
		for _ = 1, 50000 do
			local result = SizeRoller.rollSize(Sizes.order, rng)
			if result ~= nil then
				seen[result.id] = true
			end
		end

		for _, entry in ipairs(Sizes.order) do
			assert(seen[entry.id], "size '" .. entry.id .. "' should appear at least once in 50000 rolls")
		end
	end

	-- 8. single-entry pool always returns that entry
	do
		local singlePool = { { id = "only_one", weight = 500 } }
		local rng = Random.new(99)
		for _ = 1, 50 do
			local result = SizeRoller.rollSize(singlePool, rng)
			assert(result ~= nil and result.id == "only_one", "single-entry pool should always return that entry")
		end
	end
end
