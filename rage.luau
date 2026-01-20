local Shared = _G.NemesisShared
local S = Shared.Settings
local RunService = Shared.Services.RunService
local player = Shared.Player

RunService.Heartbeat:Connect(function()
	if not S.RAGE_ENABLED then return end

	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if not hum or hum.Health <= 0 then return end

end)

print("RAGE LOADED")
