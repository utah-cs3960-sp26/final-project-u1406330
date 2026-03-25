--!strict

local EconomyMath = require(script.Parent.EconomyMath)

local OfflineMath = {}

function OfflineMath.clampElapsedSeconds(elapsedSeconds: number, capSeconds: number)
	return math.clamp(elapsedSeconds, 0, capSeconds)
end

function OfflineMath.collectFinishedGeodeIds(geodeQueue: { any }, nowUnix: number): { string }
	local finished = {}

	for _, entry in ipairs(geodeQueue) do
		if entry.status == "queued" and entry.endsAt <= nowUnix then
			table.insert(finished, entry.id)
		end
	end

	return finished
end

function OfflineMath.buildSummary(lastLogoutUnix: number?, nowUnix: number, passiveRate: number, capSeconds: number)
	if lastLogoutUnix == nil then
		return nil
	end

	local elapsedSeconds = math.max(0, nowUnix - lastLogoutUnix)
	local clampedSeconds = OfflineMath.clampElapsedSeconds(elapsedSeconds, capSeconds)

	return {
		elapsedSeconds = clampedSeconds,
		coins = EconomyMath.getPassiveIncomeForElapsedSeconds(passiveRate, clampedSeconds),
		calculatedAt = nowUnix,
	}
end

return OfflineMath

