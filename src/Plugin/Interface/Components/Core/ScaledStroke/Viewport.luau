local Workspace = game:GetService "Workspace"
local Fusion = require "../../../../../Packages/Fusion"

local outerScope = Fusion.scoped(Fusion)

local camera = Workspace.CurrentCamera
local Viewport = outerScope:Value(camera.ViewportSize)

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	Viewport:set(camera.ViewportSize)
end)

return Viewport
