local Shared = _G.NemesisShared
local HttpService = Shared.Services.HttpService
local Notification = Shared.Notification

local CONFIG_FOLDER = "NEMESIS"
local CONFIG_EXTENSION = ".json"

local function hasFileSystem()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"	
		and type(makefolder) == "function"
		and type(isfolder) == "function"
		and type(listfiles) == "function"
		and type(delfile) == "function"
end

local function ensureConfigFolder()
	if not hasFileSystem() then return false end
	if not isfolder(CONFIG_FOLDER) then
		makefolder(CONFIG_FOLDER)
	end
	return true
end

local function getConfigList()
	if not hasFileSystem() then return {"No configs"} end
	ensureConfigFolder()

	local configs = {}
	local ok, files = pcall(function()
		return listfiles(CONFIG_FOLDER)
	end)
	if not ok or type(files) ~= "table" then
		ok, files = pcall(function()
			return listfiles(CONFIG_FOLDER .. "/")
		end)
	end

	if ok and type(files) == "table" then
		for _, file in ipairs(files) do
			local name = tostring(file):match("([^/\\]+)$")
			if name and name:sub(-5) == ".json" then
				table.insert(configs, name:sub(1, #name - 5))
			end
		end
	end

	table.sort(configs)
	if #configs == 0 then
		configs[1] = "No configs"
	end
	return configs
end

local function getAllSettings()
	local function colorToTable(c)
		return {math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)}
	end

	return {
		RAGE_ENABLED = Shared.Settings.RAGE_ENABLED,
		RAGE_HITPART = Shared.Settings.RAGE_HITPART,
		RAGE_HITCHANCE = Shared.Settings.RAGE_HITCHANCE,
		RAGE_HITCHANCE_ENABLED = Shared.Settings.RAGE_HITCHANCE_ENABLED,
		RAGE_AUTOSHOOT = Shared.Settings.RAGE_AUTOSHOOT,
		RAGE_NOSPREAD = Shared.Settings.RAGE_NOSPREAD,
		AUTO_EQUIP_SSG = Shared.Settings.AUTO_EQUIP_SSG,
		MAX_DISTANCE = Shared.Settings.MAX_DISTANCE,
		PREDICTION_ENABLED = Shared.Settings.PREDICTION_ENABLED,
		PREDICTION_STRENGTH = Shared.Settings.PREDICTION_STRENGTH,
		MIN_DAMAGE_ENABLED = Shared.Settings.MIN_DAMAGE_ENABLED,
		MIN_DAMAGE_VALUE = Shared.Settings.MIN_DAMAGE_VALUE,
		
		HITLOG_ENABLED = Shared.Settings.HITLOG_ENABLED,
		KEYBIND_LIST_VISIBLE = Shared.Settings.KEYBIND_LIST_VISIBLE,
		HITSOUND_ENABLED = Shared.Settings.HITSOUND_ENABLED,
		HITSOUND_PRESET = Shared.Settings.HITSOUND_PRESET,
		HITSOUND_VOLUME = Shared.Settings.HITSOUND_VOLUME,
		INDICATOR_ENABLED = Shared.Settings.INDICATOR_ENABLED,
		OFFSCREEN_ENABLED = Shared.Settings.OFFSCREEN_ENABLED,
		OFFSCREEN_COLOR = colorToTable(Shared.Settings.OFFSCREEN_COLOR),
		
		WALLBANG_ENABLED = Shared.Settings.WALLBANG_ENABLED,
		WALLBANG_ENTRY_COLOR = colorToTable(Shared.Settings.WALLBANG_ENTRY_COLOR),
		WALLBANG_EXIT_COLOR = colorToTable(Shared.Settings.WALLBANG_EXIT_COLOR),
		WALLBANG_MARKER_SIZE = Shared.Settings.WALLBANG_MARKER_SIZE,
		WALLBANG_LIFETIME = Shared.Settings.WALLBANG_LIFETIME,
		
		KILLFX_ENABLED = Shared.Settings.KILLFX_ENABLED,
		KILLFX_TYPE = Shared.Settings.KILLFX_TYPE,
		KILLFX_COLOR = colorToTable(Shared.Settings.KILLFX_COLOR),
		KILLFX_LIGHT_COLOR = colorToTable(Shared.Settings.KILLFX_LIGHT_COLOR),
		KILLFX_CUSTOM_DURATION = Shared.Settings.KILLFX_CUSTOM_DURATION,
		KILLFX_LIGHT_RANGE = Shared.Settings.KILLFX_LIGHT_RANGE,
		KILLIMAGE_ENABLED = Shared.Settings.KILLIMAGE_ENABLED,
		KILLIMAGE_COLOR = colorToTable(Shared.Settings.KILLIMAGE_COLOR),
		KILLIMAGE_MAX_ALPHA = Shared.Settings.KILLIMAGE_MAX_ALPHA,
		BACKTRACK_GHOST_ENABLED = Shared.Settings.BACKTRACK_GHOST_ENABLED,
		BACKTRACK_GHOST_COLOR = colorToTable(Shared.Settings.BACKTRACK_GHOST_COLOR),
		BACKTRACK_GHOST_DURATION = Shared.Settings.BACKTRACK_GHOST_DURATION,
		
		TRACER_ENABLED = Shared.Settings.TRACER_ENABLED,
		TRACER_COLOR = colorToTable(Shared.Settings.TRACER_COLOR),
		TRACER_LIFETIME = Shared.Settings.TRACER_LIFETIME,
		TRACER_WIDTH = Shared.Settings.TRACER_WIDTH,
		
		ATMOSPHERE_ENABLED = Shared.Settings.ATMOSPHERE_ENABLED,
		ATMOSPHERE_DENSITY = Shared.Settings.ATMOSPHERE_DENSITY,
		ATMOSPHERE_OFFSET = Shared.Settings.ATMOSPHERE_OFFSET,
		ATMOSPHERE_COLOR = colorToTable(Shared.Settings.ATMOSPHERE_COLOR),
		ATMOSPHERE_DECAY = colorToTable(Shared.Settings.ATMOSPHERE_DECAY),
		ATMOSPHERE_GLARE = Shared.Settings.ATMOSPHERE_GLARE,
		ATMOSPHERE_HAZE = Shared.Settings.ATMOSPHERE_HAZE,
		
		BLOOM_ENABLED = Shared.Settings.BLOOM_ENABLED,
		BLOOM_INTENSITY = Shared.Settings.BLOOM_INTENSITY,
		BLOOM_SIZE = Shared.Settings.BLOOM_SIZE,
		BLOOM_THRESHOLD = Shared.Settings.BLOOM_THRESHOLD,
		
		COLOR_CORRECTION_ENABLED = Shared.Settings.COLOR_CORRECTION_ENABLED,
		COLOR_CORRECTION_BRIGHTNESS = Shared.Settings.COLOR_CORRECTION_BRIGHTNESS,
		COLOR_CORRECTION_CONTRAST = Shared.Settings.COLOR_CORRECTION_CONTRAST,
		COLOR_CORRECTION_SATURATION = Shared.Settings.COLOR_CORRECTION_SATURATION,
		COLOR_CORRECTION_TINT = colorToTable(Shared.Settings.COLOR_CORRECTION_TINT),
		
		LIGHTING_EDIT_ENABLED = Shared.Settings.LIGHTING_EDIT_ENABLED,
		CUSTOM_BRIGHTNESS = Shared.Settings.CUSTOM_BRIGHTNESS,
		CUSTOM_AMBIENT = colorToTable(Shared.Settings.CUSTOM_AMBIENT),
		CUSTOM_OUTDOOR_AMBIENT = colorToTable(Shared.Settings.CUSTOM_OUTDOOR_AMBIENT),
		
		WORLD_TIME_ENABLED = Shared.Settings.WORLD_TIME_ENABLED,
		CUSTOM_CLOCKTIME = Shared.Settings.CUSTOM_CLOCKTIME,
		TIME_PRESET = Shared.Settings.TIME_PRESET,
		
		CUSTOM_SKY_ENABLED = Shared.Settings.CUSTOM_SKY_ENABLED,
		CUSTOM_SKY_PRESET = Shared.Settings.CUSTOM_SKY_PRESET,
	}
end

local function saveConfig(configName)
	if not ensureConfigFolder() then
		Notification:Notify({
			Title = "Config Error",
			Content = "File system not available",
			Icon = "alert-triangle",
			Duration = 3
		})
		return false
	end

	local settings = getAllSettings()
	local json = HttpService:JSONEncode(settings)
	local path = CONFIG_FOLDER .. "/" .. configName .. CONFIG_EXTENSION

	local success = pcall(function()
		writefile(path, json)
	end)

	if success then
		Notification:Notify({
			Title = "Config Saved",
			Content = "Saved: " .. configName,
			Icon = "check",
			Duration = 3
		})
		return true
	else
		Notification:Notify({
			Title = "Config Error",
			Content = "Failed to save",
			Icon = "alert-triangle",
			Duration = 3
		})
		return false
	end
end

local function loadConfig(configName)
	if not hasFileSystem() then
		Notification:Notify({
			Title = "Config Error",
			Content = "File system not available",
			Icon = "alert-triangle",
			Duration = 3
		})
		return false
	end
	
	local path = CONFIG_FOLDER .. "/" .. configName .. CONFIG_EXTENSION
	if not isfile(path) then
		Notification:Notify({
			Title = "Config Error",
			Content = "Config not found: " .. configName,
			Icon = "alert-triangle",
			Duration = 3
		})
		return false
	end
	
	local success, result = pcall(function()
		local json = readfile(path)
		return HttpService:JSONDecode(json)
	end)
	
	if success and result then
		if Shared.Functions.applySettings then
			Shared.Functions.applySettings(result)
		end
		Notification:Notify({
			Title = "Config Loaded",
			Content = "Loaded: " .. configName,
			Icon = "check",
			Duration = 3
		})
		return true
	else
		Notification:Notify({
			Title = "Config Error",
			Content = "Failed to load",
			Icon = "alert-triangle",
			Duration = 3
		})
		return false
	end
end

local function deleteConfig(configName)
	if not hasFileSystem() then return false end
	local path = CONFIG_FOLDER .. "/" .. configName .. CONFIG_EXTENSION
	if isfile(path) then
		delfile(path)
		Notification:Notify({
			Title = "Config Deleted",
			Content = "Deleted: " .. configName,
			Icon = "trash",
			Duration = 3
		})
		return true
	end
	return false
end

Shared.Functions.saveConfig = saveConfig
Shared.Functions.loadConfig = loadConfig
Shared.Functions.deleteConfig = deleteConfig
Shared.Functions.getConfigList = getConfigList

print("✅ Config Module Loaded")
