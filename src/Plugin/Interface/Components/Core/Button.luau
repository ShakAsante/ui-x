local Fusion = require "../../../../Packages/Fusion"
local DefaultProps = require "../DefaultProps"

local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local function Button(
	scope: Fusion.Scope<any>,
	props: {
		onClick: (() -> ())?,
		onHoverStart: (() -> ())?,
		onHoverEnd: (() -> ())?,
		native: { [any]: any }?,
	}?
)
	local scale = scope:Value(1)
	local clickSound = scope:New "Sound" {
		SoundId = "rbxassetid://139800881181209",
		Volume = 0.5,
		-- Parent = SoundService,
	}

	local merged = DefaultProps({
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		-- Image = "",
		AutoButtonColor = false,
		[Children] = {
			scope:New "UIScale" {
				Scale = scope:Spring(scale, 20, 0.95),
			},
			clickSound,
		},
	}, props and props.native)

	merged[OnEvent "Activated"] = function()
		clickSound:Play()
		if props and props.onClick then
			props.onClick()
		end
	end

	merged[OnEvent "MouseButton1Down"] = function()
		if props and props.onMouseDown then
			props.onMouseDown()
		end
		scale:set(0.85)
	end

	merged[OnEvent "MouseButton1Up"] = function()
		if props and props.onMouseUp then
			props.onMouseUp()
		end
		scale:set(1)
	end

	merged[OnEvent "MouseEnter"] = function(...)
		scale:set(0.9)
		if props.onHoverStart then
			props.onHoverStart(...)
		end
	end

	merged[OnEvent "MouseLeave"] = function(...)
		scale:set(1)
		if props.onHoverEnd then
			props.onHoverEnd(...)
		end
	end

	return scope:New "ImageButton"(merged)
end

return Button
