local Object = require "../Object"

local Behaviour = Object:extend()

function Behaviour:Init()
	self.viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local cam = workspace.CurrentCamera

		if cam then
			self.viewport = cam.ViewportSize
		end
	end)
end

function Behaviour:GetViewport()
	local camera = workspace.CurrentCamera
	self.viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	return self.viewport
end

function Behaviour:PositionToScale(instance: UIBase)
	local viewport = self:GetViewport()
	local pos = instance.Position

	return UDim2.fromScale(pos.X.Scale + (pos.X.Offset / viewport.X), pos.Y.Scale + (pos.Y.Offset / viewport.Y))
end

function Behaviour:PositionToOffset(instance: UIBase)
	local viewport = self:GetViewport()
	local pos = instance.Position

	return UDim2.fromOffset((pos.X.Scale * viewport.X) + pos.X.Offset, (pos.Y.Scale * viewport.Y) + pos.Y.Offset)
end

function Behaviour:SizeToScale(instance: UIBase)
	local viewport = self:GetViewport()
	local size = instance.Size

	return UDim2.fromScale(size.X.Scale + (size.X.Offset / viewport.X), size.Y.Scale + (size.Y.Offset / viewport.Y))
end

function Behaviour:SizeToOffset(instance: UIBase)
	local viewport = self:GetViewport()
	local size = instance.Size

	return UDim2.fromOffset((size.X.Scale * viewport.X) + size.X.Offset, (size.Y.Scale * viewport.Y) + size.Y.Offset)
end

return Behaviour
