local Shared = _G.NemesisShared
local Fatality = Shared.Fatality
local S = Shared.Settings
local UI = Shared.UI

local Window = Fatality.new({ Name = "Nemesis", Expire = "never" })

local Rage = Window:AddMenu({ Name = "RAGE", Icon = "skull" })
local Visual = Window:AddMenu({ Name = "VISUAL", Icon = "eye" })

S.RAGE_ENABLED = false
S.TRACER_ENABLED = false
S.OFFSCREEN_ENABLED = false

UI.RageToggle = Rage:AddToggle({
	Name = "Aimbot",
	Callback = function(v)
		S.RAGE_ENABLED = v
	end
})

UI.TracerToggle = Visual:AddToggle({
	Name = "Tracers",
	Callback = function(v)
		S.TRACER_ENABLED = v
	end
})

UI.ArrowToggle = Visual:AddToggle({
	Name = "Arrows",
	Callback = function(v)
		S.OFFSCREEN_ENABLED = v
	end
})

print("UI LOADED")
