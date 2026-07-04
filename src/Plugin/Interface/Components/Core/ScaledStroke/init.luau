local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Viewport = require "@self/Viewport"

local REFERENCE_HEIGHT = 1080

return function(scope: Fusion.Scope<any>, props)
	return scope:New "UIStroke" {
		Thickness = scope:Computed(function(use)
			local viewport = use(Viewport)

			local scale = math.clamp(viewport.Y / REFERENCE_HEIGHT, 0.75, 1.5)

			return (props.thickness or 2) * scale
		end),

		Color = props.color or Color3.new(0, 0, 0),
		Transparency = props.transparency or 0,
		Enabled = props.enabled ~= false,
		ApplyStrokeMode = props.context or Enum.ApplyStrokeMode.Border,
		LineJoinMode = props.mode or Enum.LineJoinMode.Miter,
	}
end
