-- NEMESIS by monolorov
-- GitHub: https://github.com/monolorov/Nemesis

local GITHUB_BASE = "https://raw.githubusercontent.com/monolorov/Nemesis/main/"

-- ============================================
-- Services
-- ============================================
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

-- ============================================
-- Load Fatality UI
-- ============================================
local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/Monolorov/FatalInterface/main/src.luau"))()
local Notification = Fatality:CreateNotifier()

-- ============================================
-- Loader
-- ============================================
Fatality:Loader({
	Name = "NEMESIS",
	Duration = 3
})
task.wait(3)
Notification:Notify({
	Title = "NEMESIS",
	Content = "Hello, "..player.DisplayName..' Welcome back!',
	Icon = "clipboard",
	Duration = 5
})

-- ============================================
-- Shared Global
-- ============================================
_G.NemesisShared = {
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
	Player = player,
	GuiParent = guiParent,
	Fatality = Fatality,
	Notification = Notification,
	UI = {},
	Settings = {},
	Functions = {}
}

-- ============================================
-- Load Modules
-- ============================================
print("⏳ Loading Config System...")
loadstring(game:HttpGet(GITHUB_BASE .. "config.luau"))()

print("⏳ Loading Rage Module...")
loadstring(game:HttpGet(GITHUB_BASE .. "rage.luau"))()

print("⏳ Loading Visuals Module...")
loadstring(game:HttpGet(GITHUB_BASE .. "visuals.luau"))()

print("⏳ Loading Misc Module...")
loadstring(game:HttpGet(GITHUB_BASE .. "misc.luau"))()

print("⏳ Loading UI Module...")
loadstring(game:HttpGet(GITHUB_BASE .. "ui.luau"))()

print("✅ Nemesis Loaded Successfully!")
