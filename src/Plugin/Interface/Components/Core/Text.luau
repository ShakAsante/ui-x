local Fusion = require "../../../../Packages/Fusion"
local DefaultProps = require "../DefaultProps"

return function(Scope: Fusion.Scope<any>, Props: { Text: string, Font: Enum.Font, Native: { [any]: any } }?)
	local Text = Scope:New "TextLabel"(DefaultProps({
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = Props.text,
		Font = Props.font,
		TextScaled = Props.scaled,
		TextColor3 = Props.color,
	}, Props.native))

	return Text
end
