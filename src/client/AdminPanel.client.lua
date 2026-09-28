local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if player:GetAttribute("IsGameAdmin") == nil then
	player:GetAttributeChangedSignal("IsGameAdmin"):Wait()
end
if player:GetAttribute("IsGameAdmin") ~= true then
	return
end

local Modules = script.Parent:WaitForChild("AdminModules")
local UI = require(Modules.UI)
local Flight = require(Modules.Flight)
local Diagnostics = require(Modules.Diagnostics)
local BoundaryVisualizer = require(Modules.BoundaryVisualizer)

BoundaryVisualizer.create(Workspace)
local controls = UI.create(player)
Diagnostics.bind(player, controls, RunService)
Flight.bind(player, controls, {
	RunService = RunService,
	UserInputService = UserInputService,
	Workspace = Workspace,
})
