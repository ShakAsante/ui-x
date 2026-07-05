local Fusion = require "../../../../Packages/Fusion"

return function(Scope: Fusion.Scope<any>, props: {})
	local UICorner = Scope:New "UICorner" {
		CornerRadius = props.CornerRadius,
		BottomLeftRadius = props.BottomLeftRadius,
		BottomRightRadius = props.BottomRightRadius,
		TopLeftRadius = props.TopLeftRadius,
		TopRightRadius = props.TopRightRadius,
	}

	return UICorner
end
