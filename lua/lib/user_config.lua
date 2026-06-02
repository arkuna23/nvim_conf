local defaults = {
	editor_lang = nil,
	avante = {},
}

local function deep_copy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for k, v in pairs(value) do
		copy[deep_copy(k)] = deep_copy(v)
	end
	return copy
end

local function merge_defaults(user_config, default_config)
	if type(user_config) ~= "table" then
		return deep_copy(default_config)
	end

	local merged = deep_copy(user_config)
	for key, default_value in pairs(default_config) do
		if merged[key] == nil then
			merged[key] = deep_copy(default_value)
		elseif type(merged[key]) == "table" and type(default_value) == "table" then
			merged[key] = merge_defaults(merged[key], default_value)
		end
	end
	return merged
end

local ok, user_config = pcall(require, "user_config")

return merge_defaults(ok and user_config or {}, defaults)
