local Shared = _G.NemesisShared
local HttpService = Shared.Services.HttpService

local S = Shared.Settings
S.ConfigName = "default"

local FOLDER = "NEMESIS"

local function fs()
	return writefile and readfile and isfile and makefolder and listfiles
end

if fs() and not isfolder(FOLDER) then
	makefolder(FOLDER)
end

function S.SaveConfig(name)
	if not fs() then return end
	local path = FOLDER.."/"..name..".json"
	writefile(path, HttpService:JSONEncode(S))
end

function S.LoadConfig(name)
	if not fs() then return end
	local path = FOLDER.."/"..name..".json"
	if not isfile(path) then return end
	local data = HttpService:JSONDecode(readfile(path))
	for k,v in pairs(data) do
		S[k] = v
	end
end

function S.GetConfigs()
	if not fs() then return {} end
	local t = {}
	for _,f in ipairs(listfiles(FOLDER)) do
		local n = f:match("([^/]+)%.json$")
		if n then table.insert(t,n) end
	end
	return t
end
