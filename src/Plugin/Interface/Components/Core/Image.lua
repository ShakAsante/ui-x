local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local DefaultProps = require "../DefaultProps"

return function(Scope: Fusion.Scope<any>, Props: {})
	local Image = Scope:New "ImageLabel"(DefaultProps({
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageTransparency = Props.transparency,
		Image = Props.texture,
	}, Props.native))
	return Image
end
