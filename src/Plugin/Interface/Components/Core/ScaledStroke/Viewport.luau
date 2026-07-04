local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Workspace = game:GetService "Workspace"
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local outerScope = Fusion.scoped(Fusion)

local camera = Workspace.CurrentCamera
local Viewport = outerScope:Value(camera.ViewportSize)

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	Viewport:set(camera.ViewportSize)
end)

return Viewport
