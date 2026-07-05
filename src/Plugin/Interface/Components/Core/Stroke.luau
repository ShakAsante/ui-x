local Fusion = require "../../../../Packages/Fusion"

local DefaultProps = require "../DefaultProps"

return function(scope: Fusion.Scope<any>, props: {})
	local Stroke = scope:New "UIStroke"(DefaultProps({
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = props.thickness,
		Transparency = props.transparency,
		LineJoinMode = props.mode or Enum.LineJoinMode.Miter,
		ApplyStrokeMode = props.context,
		StrokeSizingMode = props.sizing or Enum.StrokeSizingMode.FixedSize,
	}, props.native))
	return Stroke
end
