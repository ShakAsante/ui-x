local Object = require "../Object"

--[=[
	@class Behaviour

	Provides viewport-relative helpers for converting `UDim2` values between
	scale and offset space.
]=]
local Behaviour = Object:extend()

--[=[
	Initializes the cached viewport size and keeps it in sync whenever the
	workspace's `CurrentCamera` is replaced.
]=]
function Behaviour:Init(): ()
	self.viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local cam = workspace.CurrentCamera

		if cam then
			self.viewport = cam.ViewportSize
		end
	end)
end

--[=[
	Returns the current viewport size, refreshing it from `workspace.CurrentCamera`.

	@return Vector2
]=]
function Behaviour:GetViewport(): Vector2
	local camera = workspace.CurrentCamera
	self.viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	return self.viewport
end

--[=[
	Converts a `UIBase` instance's `Position` to pure scale, folding any
	offset component into scale using the current viewport size.

	@param instance UIBase
	@return UDim2
]=]
function Behaviour:PositionToScale(instance: UIBase): UDim2
	local viewport = self:GetViewport()
	local pos = instance.Position

	return UDim2.fromScale(pos.X.Scale + (pos.X.Offset / viewport.X), pos.Y.Scale + (pos.Y.Offset / viewport.Y))
end

--[=[
	Converts a `UIBase` instance's `Position` to pure offset, expanding any
	scale component into pixels using the current viewport size.

	@param instance UIBase
	@return UDim2
]=]
function Behaviour:PositionToOffset(instance: UIBase): UDim2
	local viewport = self:GetViewport()
	local pos = instance.Position

	return UDim2.fromOffset((pos.X.Scale * viewport.X) + pos.X.Offset, (pos.Y.Scale * viewport.Y) + pos.Y.Offset)
end

--[=[
	Converts a `UIBase` instance's `Size` to pure scale, folding any offset
	component into scale using the current viewport size.

	@param instance UIBase
	@return UDim2
]=]
function Behaviour:SizeToScale(instance: UIBase): UDim2
	local viewport = self:GetViewport()
	local size = instance.Size

	return UDim2.fromScale(size.X.Scale + (size.X.Offset / viewport.X), size.Y.Scale + (size.Y.Offset / viewport.Y))
end

--[=[
	Converts a `UIBase` instance's `Size` to pure offset, expanding any scale
	component into pixels using the current viewport size.

	@param instance UIBase
	@return UDim2
]=]
function Behaviour:SizeToOffset(instance: UIBase): UDim2
	local viewport = self:GetViewport()
	local size = instance.Size

	return UDim2.fromOffset((size.X.Scale * viewport.X) + size.X.Offset, (size.Y.Scale * viewport.Y) + size.Y.Offset)
end

return Behaviour
