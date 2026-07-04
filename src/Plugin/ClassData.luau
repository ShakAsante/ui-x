--[=[
	Roblox UI Classes Reference
	https://create.roblox.com/docs/reference/engine/classes
]=]

local DEFAULT_UDIM2 = UDim2.new(0, 0, 0, 0)
local DEFAULT_UDIM = UDim.new(0, 0)
local DEFAULT_COLOR = Color3.new(1, 1, 1)

local DEFAULT_NUMBER = 0
local DEFAULT_BOOL = true

-- shared GuiObject properties
local GuiObjectProps = {
	Position = DEFAULT_UDIM2,
	Size = DEFAULT_UDIM2,
	Rotation = DEFAULT_NUMBER,
	ZIndex = DEFAULT_NUMBER,

	Visible = DEFAULT_BOOL,
	Active = DEFAULT_BOOL,

	BackgroundColor3 = DEFAULT_COLOR,
	BackgroundTransparency = DEFAULT_NUMBER,
	BorderSizePixel = DEFAULT_NUMBER,
}

local Classes = {

	Frame = {
		className = "Frame",
		props = GuiObjectProps,
	},

	TextLabel = {
		className = "TextLabel",
		props = {
			Position = DEFAULT_UDIM2,
			Size = DEFAULT_UDIM2,

			BackgroundColor3 = DEFAULT_COLOR,
			BackgroundTransparency = DEFAULT_NUMBER,
			BorderSizePixel = DEFAULT_NUMBER,

			Text = "",
			TextColor3 = DEFAULT_COLOR,
			TextSize = 14,
			TextScaled = false,
			TextWrapped = false,

			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		},
	},

	TextButton = {
		className = "TextButton",
		props = {
			Position = DEFAULT_UDIM2,
			Size = DEFAULT_UDIM2,

			BackgroundColor3 = DEFAULT_COLOR,
			BackgroundTransparency = DEFAULT_NUMBER,

			Text = "Button",
			TextColor3 = DEFAULT_COLOR,
			TextSize = 14,

			Font = Enum.Font.SourceSans,

			AutoButtonColor = DEFAULT_BOOL,
			Active = DEFAULT_BOOL,
		},
	},

	TextBox = {
		className = "TextBox",
		props = {
			Position = DEFAULT_UDIM2,
			Size = DEFAULT_UDIM2,

			Text = "",
			PlaceholderText = "",
			ClearTextOnFocus = false,

			TextColor3 = DEFAULT_COLOR,
			BackgroundColor3 = DEFAULT_COLOR,
		},
	},

	ImageLabel = {
		className = "ImageLabel",
		props = {
			Position = DEFAULT_UDIM2,
			Size = DEFAULT_UDIM2,

			Image = "",
			ImageColor3 = DEFAULT_COLOR,
			ImageTransparency = DEFAULT_NUMBER,

			BackgroundColor3 = DEFAULT_COLOR,
			BackgroundTransparency = DEFAULT_NUMBER,
		},
	},

	ImageButton = {
		className = "ImageButton",
		props = {
			Position = DEFAULT_UDIM2,
			Size = DEFAULT_UDIM2,

			Image = "",
			ImageColor3 = DEFAULT_COLOR,

			BackgroundTransparency = DEFAULT_NUMBER,
			AutoButtonColor = DEFAULT_BOOL,
		},
	},

	ScrollingFrame = {
		className = "ScrollingFrame",
		props = {
			Position = DEFAULT_UDIM2,
			Size = DEFAULT_UDIM2,

			CanvasSize = DEFAULT_UDIM2,
			ScrollBarThickness = 6,
			ScrollingEnabled = true,

			BackgroundColor3 = DEFAULT_COLOR,
			BackgroundTransparency = DEFAULT_NUMBER,
		},
	},

	UIListLayout = {
		className = "UIListLayout",
		props = {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = DEFAULT_UDIM,
		},
	},

	UIPadding = {
		className = "UIPadding",
		props = {
			PaddingTop = DEFAULT_UDIM,
			PaddingBottom = DEFAULT_UDIM,
			PaddingLeft = DEFAULT_UDIM,
			PaddingRight = DEFAULT_UDIM,
		},
	},

	UICorner = {
		className = "UICorner",
		props = {
			CornerRadius = UDim.new(0, 8),
		},
	},

	UIStroke = {
		className = "UIStroke",
		props = {
			Color = DEFAULT_COLOR,
			Thickness = 1,
			Transparency = 0,
		},
	},
}

return Classes
