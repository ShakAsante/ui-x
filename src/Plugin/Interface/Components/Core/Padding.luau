local Fusion = require "../../../../Packages/Fusion"

local DefaultProps = require("../DefaultProps")

return function(Scope: Fusion.Scope<any>, Props: Fusion.PropertyTable)
	return Scope:New("UIPadding")(DefaultProps({
		PaddingTop = Props.PaddingTop,
		PaddingBottom = Props.PaddingBottom,
		PaddingLeft = Props.PaddingLeft,
		PaddingRight = Props.PaddingRight,
	}, Props))
end
