local Fusion = require "../../../../Packages/Fusion"

type CurveName = "Linear" | "EaseIn" | "EaseOut" | "EaseInOut"
type CurveFn = (t: number) -> number

type ColorData = { [number]: Color3 }
type NumberData = { [number]: number }

export type GradientProps = {
	Curve: CurveName?,
	Samples: number?,
	Rotation: number?,
	Offset: Vector2?,
	Color: ColorData?,
	Transparency: NumberData?,
}

type Point<T> = { time: number, value: T }

local Curves: { [CurveName]: CurveFn } = {
	Linear = function(t: number): number
		return t
	end,

	EaseIn = function(t: number): number
		return t * t
	end,

	EaseOut = function(t: number): number
		return 1 - (1 - t) * (1 - t)
	end,

	EaseInOut = function(t: number): number
		return t < 0.5 and 2 * t * t or 1 - ((-2 * t + 2) ^ 2) / 2
	end,
}

local function Interpolate(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function InterpolateColor(a: Color3, b: Color3, t: number): Color3
	return Color3.new(Interpolate(a.R, b.R, t), Interpolate(a.G, b.G, t), Interpolate(a.B, b.B, t))
end

local function BuildSequence(
	data: ColorData | NumberData | nil,
	samples: number,
	curveFn: CurveFn,
	isColor: boolean
): ColorSequence | NumberSequence | nil
	if not data then
		return nil
	end

	local points: { Point<any> } = {}
	for time, value in pairs(data) do
		table.insert(points, { time = time, value = value })
	end

	table.sort(points, function(a: Point<any>, b: Point<any>): boolean
		return a.time < b.time
	end)

	local keypoints: { any } = {}

	for i = 1, #points - 1 do
		local a: Point<any> = points[i]
		local b: Point<any> = points[i + 1]

		for s = 0, samples do
			local t = s / samples
			local curved = curveFn(t)

			local time = Interpolate(a.time, b.time, t)

			if isColor then
				local col = InterpolateColor(a.value, b.value, curved)
				table.insert(keypoints, ColorSequenceKeypoint.new(time, col))
			else
				local val = Interpolate(a.value, b.value, curved)
				table.insert(keypoints, NumberSequenceKeypoint.new(time, val))
			end
		end
	end

	if isColor then
		return ColorSequence.new(keypoints)
	else
		return NumberSequence.new(keypoints)
	end
end

return function(Scope: Fusion.Scope<any>, Props: GradientProps): UIGradient
	local curveFn = Curves[Props.Curve or "Linear"]
	local samples = Props.Samples or 8

	local Gradient = Scope:New "UIGradient" {
		Rotation = Props.rotation,
		Offset = Props.Offset or Vector2.new(0, 0),
		Color = BuildSequence(Props.color, samples, curveFn, true),
		Transparency = BuildSequence(Props.transparency, samples, curveFn, false),
	}

	return Gradient
end
