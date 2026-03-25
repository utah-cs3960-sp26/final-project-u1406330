--!strict

local Time = {}

function Time.nowUnix()
	return DateTime.now().UnixTimestamp
end

function Time.elapsedSeconds(startUnix: number, endUnix: number?)
	local currentUnix = endUnix or Time.nowUnix()
	return math.max(0, currentUnix - startUnix)
end

function Time.clampSeconds(seconds: number, capSeconds: number)
	return math.clamp(seconds, 0, capSeconds)
end

return Time
