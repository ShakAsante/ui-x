local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local OnEvent = Fusion.OnEvent

local Children = Fusion.Children

return function(Scope: Fusion.Scope<any>, props: {})
	local ButtonScale = Scope:Value(1)

	local UICorner = Scope:New "UICorner" {
		CornerRadius = props.CornerRadius,
		BottomLeftRadius = props.BottomLeftRadius,
		BottomRightRadius = props.BottomRightRadius,
		TopLeftRadius = props.TopLeftRadius,
		TopRightRadius = props.TopRightRadius,
	}

	return UICorner
end
