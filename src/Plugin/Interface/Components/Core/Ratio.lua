local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return function(Scope: Fusion.Scope<any>, Ratio: number?)
	local AspectRatio = Scope:New "UIAspectRatioConstraint" {
		AspectRatio = Ratio,
	}

	return AspectRatio
end
