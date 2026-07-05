local Fusion = require "../../../../Packages/Fusion"

return function(Scope: Fusion.Scope<any>, Ratio: number?)
	local AspectRatio = Scope:New "UIAspectRatioConstraint" {
		AspectRatio = Ratio,
	}

	return AspectRatio
end
