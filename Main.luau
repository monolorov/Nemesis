if _G.NemesisLoaded then return end
_G.NemesisLoaded = true

local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/Monolorov/FatalInterface/main/src.luau"))()
local Notification = Fatality:CreateNotifier()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")

Fatality:Loader({ Name = "NEMESIS", Duration = 3 })
task.wait(3)

Notification:Notify({
	Title = "NEMESIS",
	Content = "Hello, "..player.DisplayName,
	Duration = 4
})

_G.NemesisShared = {
	Player = player,
	GuiParent = guiParent,
	Fatality = Fatality,
	Notification = Notification,
	Services = {
		Players = Players,
		TweenService = TweenService,
		UserInputService = UserInputService,
		RunService = RunService,
		ReplicatedStorage = ReplicatedStorage,
		Workspace = Workspace,
		Lighting = Lighting,
		HttpService = HttpService,
		SoundService = SoundService,
		Debris = Debris
	},
	Settings = {},
	UI = {},
	Connections = {}
}

local BASE = "https://raw.githubusercontent.com/YourUsername/Nemesis/main/modules/"

loadstring(game:HttpGet(BASE.."config.lua"))()
loadstring(game:HttpGet(BASE.."ui.lua"))()
loadstring(game:HttpGet(BASE.."visuals.lua"))()
loadstring(game:HttpGet(BASE.."misc.lua"))()
loadstring(game:HttpGet(BASE.."rage.lua"))()

print("NEMESIS LOADED")
