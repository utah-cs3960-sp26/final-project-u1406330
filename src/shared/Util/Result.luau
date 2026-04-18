--!strict

-- Shared utility module for Result that supports reusable deterministic helpers.

export type Result<T, E> = {
	ok: true,
	value: T,
} | {
	ok: false,
	error: E,
}

local Result = {}

function Result.ok<T, E>(value: T): Result<T, E>
	return {
		ok = true,
		value = value,
	}
end

function Result.err<T, E>(errorValue: E): Result<T, E>
	return {
		ok = false,
		error = errorValue,
	}
end

function Result.isOk<T, E>(result: Result<T, E>): boolean
	return result.ok
end

return Result
