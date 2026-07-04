local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local DefaultProps = require("../DefaultProps")

local Children = Fusion.Children

export type Particle2DProps = {
	Enabled: Fusion.UsedAs<boolean>?,
	Emitter: { Emit: (self: any, count: number?) -> () }?,
	SpawnRate: Fusion.UsedAs<number>?,
	Lifetime: Fusion.UsedAs<number | NumberRange>?,
	Speed: Fusion.UsedAs<number | NumberRange>?,
	Direction: Fusion.UsedAs<Vector2>?,
	Spread: Fusion.UsedAs<number | NumberRange>?,
	Gravity: Fusion.UsedAs<Vector2>?,
	Size: Fusion.UsedAs<{ [number]: number }>?,
	Scale: Fusion.UsedAs<number>?,
	Color: Fusion.UsedAs<Color3 | { [number]: Color3 }>?,
	Transparency: Fusion.UsedAs<number | { [number]: number }>?,
	Texture: Fusion.UsedAs<string>?,
	FlipbookEnabled: Fusion.UsedAs<boolean>?,
	FlipbookLayout: Fusion.UsedAs<Enum.ParticleFlipbookLayout>?,
	FlipbookMode: Fusion.UsedAs<Enum.ParticleFlipbookMode>?,
	FlipbookFramerate: Fusion.UsedAs<NumberRange | number>?,
	FlipbookStartRandom: Fusion.UsedAs<boolean>?,
	FlipbookStartFrame: Fusion.UsedAs<number>?,
	FlipbookEndFrame: Fusion.UsedAs<number>?,
	MaxParticles: Fusion.UsedAs<number>?,
	SpawnAt: Fusion.UsedAs<"Bounds" | "AnchorPoint" | "Center">?,
	Native: { [any]: any }?,
}

type ParticleState = {
	Instance: GuiObject,
	IsImage: boolean,
	IsFlipbook: boolean,
	X: number,
	Y: number,
	VX: number,
	VY: number,
	Lifetime: number,
	Age: number,
	StartSize: number,
	FlipbookStartFrame: number,
	FlipbookFramerate: number,
}

local function RandomRange(MinValue: number, MaxValue: number): number
	if MaxValue <= MinValue then
		return MinValue
	end

	return MinValue + math.random() * (MaxValue - MinValue)
end

local function ResolveProp<T>(Value: any, DefaultValue: T): T
	if Value == nil then
		return DefaultValue
	end

	if type(Value) == "function" then
		local Ok, Result = pcall(Value)

		if Ok and Result ~= nil then
			return Result
		end

		return DefaultValue
	end

	local Ok, Result = pcall(Fusion.peek, Value)

	if Ok and Result ~= nil then
		return Result
	end

	return Value
end

local function NormalizeRange(MinValue: number, MaxValue: number): (number, number)
	if MinValue > MaxValue then
		return MaxValue, MinValue
	end

	return MinValue, MaxValue
end

local function ResolveNumberOrRange(Value: any, Fallback: number): (number, number)
	if typeof(Value) == "NumberRange" then
		return NormalizeRange(Value.Min, Value.Max)
	end

	if type(Value) == "number" then
		return Value, Value
	end

	return Fallback, Fallback
end

local function ResolveSpreadRangeRadians(Value: any, FallbackDegrees: number): (number, number)
	if typeof(Value) == "NumberRange" then
		local MinDeg, MaxDeg = NormalizeRange(Value.Min, Value.Max)
		return math.rad(MinDeg), math.rad(MaxDeg)
	end

	if type(Value) == "number" then
		local HalfAngle = math.rad(Value)
		return -HalfAngle, HalfAngle
	end

	local FallbackRadians = math.rad(FallbackDegrees)
	return -FallbackRadians, FallbackRadians
end

local function ToUnit(Direction: Vector2): Vector2
	if Direction.Magnitude <= 0 then
		return Vector2.new(0, -1)
	end

	return Direction.Unit
end

local function Rotated(Vec: Vector2, Radians: number): Vector2
	local Cosine = math.cos(Radians)
	local Sine = math.sin(Radians)
	return Vector2.new(Vec.X * Cosine - Vec.Y * Sine, Vec.X * Sine + Vec.Y * Cosine)
end

local function MakeParticleInstance(Texture: string?, Color: Color3): GuiObject
	if Texture and Texture ~= "" then
		local Image = Instance.new("ImageLabel")
		Image.BackgroundTransparency = 1
		local Stroke = Instance.new("UIStroke")
		Stroke.Thickness = 1
		Stroke.LineJoinMode = Enum.LineJoinMode.Round
		Stroke.Color = Color3.fromRGB(0, 0, 0)
		Stroke.Parent = Image
		Image.Image = Texture
		Image.ImageColor3 = Color
		Image.AnchorPoint = Vector2.new(0.5, 0.5)
		return Image
	end

	local Dot = Instance.new("Frame")
	Dot.BorderSizePixel = 0
	Dot.BackgroundColor3 = Color
	Dot.AnchorPoint = Vector2.new(0.5, 0.5)

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = Dot

	return Dot
end

local function EvalNumberKeyframes(Keyframes: { [number]: number }, T: number): number
	if type(Keyframes) == "number" then
		return Keyframes
	end

	local Keys = {}
	for Time in pairs(Keyframes) do
		table.insert(Keys, Time)
	end
	table.sort(Keys)

	if #Keys == 0 then
		return 0
	end
	if T <= Keys[1] then
		return Keyframes[Keys[1]]
	end
	if T >= Keys[#Keys] then
		return Keyframes[Keys[#Keys]]
	end

	for i = 1, #Keys - 1 do
		local A, B = Keys[i], Keys[i + 1]
		if T >= A and T <= B then
			local Alpha = (T - A) / (B - A)
			return Keyframes[A] + (Keyframes[B] - Keyframes[A]) * Alpha
		end
	end

	return Keyframes[Keys[#Keys]]
end

local function EvalColorKeyframes(Keyframes: { [number]: Color3 }, T: number): Color3
	if typeof(Keyframes) == "Color3" then
		return Keyframes
	end
	local Keys = {}
	for Time in pairs(Keyframes) do
		table.insert(Keys, Time)
	end
	table.sort(Keys)

	if #Keys == 0 then
		return Color3.new(1, 1, 1)
	end
	if T <= Keys[1] then
		return Keyframes[Keys[1]]
	end
	if T >= Keys[#Keys] then
		return Keyframes[Keys[#Keys]]
	end

	for i = 1, #Keys - 1 do
		local A, B = Keys[i], Keys[i + 1]
		if T >= A and T <= B then
			local Alpha = (T - A) / (B - A)
			return Keyframes[A]:Lerp(Keyframes[B], Alpha)
		end
	end

	return Keyframes[Keys[#Keys]]
end

local GRID_PRESETS: { [any]: number } = {
	[Enum.ParticleFlipbookLayout.Grid2x2] = 2,
	[Enum.ParticleFlipbookLayout.Grid4x4] = 4,
	[Enum.ParticleFlipbookLayout.Grid8x8] = 8,
}

local function SetFlipbookFrame(Image: ImageLabel, FrameIndex: number, GridSize: number)
	local Size = math.max(1, GridSize)
	local Frame = math.max(1, math.floor(FrameIndex))
	local X = (Frame - 1) % Size
	local Y = math.floor((Frame - 1) / Size)

	Image.ImageRectSize = Vector2.new(1024 / Size, 1024 / Size)
	Image.ImageRectOffset = Vector2.new(X * Image.ImageRectSize.X, Y * Image.ImageRectSize.Y)
end

local function ResolveFlipbookLayout(LayoutValue: any): (number, number, Vector2)
	if typeof(LayoutValue) == "EnumItem" and LayoutValue.EnumType == Enum.ParticleFlipbookLayout then
		local GridSize = GRID_PRESETS[LayoutValue]
		if GridSize then
			local FramePx = 1024 / GridSize
			return GridSize, GridSize, Vector2.new(FramePx, FramePx)
		end
	end

	return 1, 1, Vector2.zero
end

local function ResolveFlipbookModeName(ModeValue: any, FallbackLoop: boolean): string
	if typeof(ModeValue) == "EnumItem" and ModeValue.EnumType == Enum.ParticleFlipbookMode then
		local Name = string.lower(ModeValue.Name)
		if Name == "oneshot" or Name == "one_shot" then
			return "OneShot"
		end
		if Name == "pingpong" or Name == "ping_pong" then
			return "PingPong"
		end
		if Name == "random" then
			return "Random"
		end
		return "Loop"
	end

	return if FallbackLoop then "Loop" else "OneShot"
end

local function ResolveFlipbookFramerateRange(FramerateValue: any, FallbackFPS: number): (number, number)
	if typeof(FramerateValue) == "NumberRange" then
		return math.max(0.01, FramerateValue.Min), math.max(0.01, FramerateValue.Max)
	end

	if type(FramerateValue) == "number" then
		local Clamped = math.max(0.01, FramerateValue)
		return Clamped, Clamped
	end

	local SafeFallback = math.max(0.01, FallbackFPS)
	return SafeFallback, SafeFallback
end

local function GetFlipbookFrameFromMode(
	ModeName: string,
	StartFrame: number,
	EndFrame: number,
	Age: number,
	Framerate: number
): number
	local FrameCount = math.max(1, EndFrame - StartFrame + 1)
	local ElapsedFrames = math.floor(Age * Framerate)

	if ModeName == "Random" then
		return StartFrame + math.random(0, FrameCount - 1)
	end

	if ModeName == "OneShot" then
		return StartFrame + math.min(ElapsedFrames, FrameCount - 1)
	end

	if ModeName == "PingPong" then
		if FrameCount <= 1 then
			return StartFrame
		end

		local CycleLength = FrameCount * 2 - 2
		local CycleOffset = ElapsedFrames % CycleLength
		local Offset = if CycleOffset < FrameCount then CycleOffset else CycleLength - CycleOffset
		return StartFrame + Offset
	end

	return StartFrame + (ElapsedFrames % FrameCount)
end

return function(Scope: Fusion.Scope<any>, Props: Particle2DProps?)
	Props = Props or {}

	local Enabled = Props.Enabled
	local DefaultDirection = Vector2.new(0, -1)
	local DefaultGravity = Vector2.new(0, 60)
	local DefaultColor = Color3.fromRGB(255, 255, 255)
	local DefaultSize = {
		[0] = 7,
		[1] = 7,
	}

	local Root = Scope:New("Frame")(DefaultProps({
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		[Children] = {},
	}, Props.Native))

	local Particles: { ParticleState } = {}
	local Pool: { GuiObject } = {}
	local SpawnAccumulator = 0
	local Connection: RBXScriptConnection? = nil
	local SizeChangedConnection: RBXScriptConnection? = nil
	local DestroyingConnection: RBXScriptConnection? = nil
	local RootSizeX = Root.AbsoluteSize.X
	local RootSizeY = Root.AbsoluteSize.Y
	local Texture = ResolveProp(Props.Texture, "")
	local RawColor = ResolveProp(Props.Color, DefaultColor)
	local ColorIsTable = type(RawColor) == "table"
	local StaticColor: Color3 = if ColorIsTable then DefaultColor else RawColor :: Color3
	local UsesImage = Texture ~= ""

	SizeChangedConnection = Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local AbsoluteSize = Root.AbsoluteSize
		RootSizeX = AbsoluteSize.X
		RootSizeY = AbsoluteSize.Y
	end)

	local function AcquireParticleInstance(): GuiObject
		local Instance = table.remove(Pool)

		if Instance then
			return Instance
		end

		return MakeParticleInstance(Texture, StaticColor)
	end

	local function ReleaseParticle(Index: number)
		local Particle = Particles[Index]

		if Particle then
			Particle.Instance.Parent = nil

			local LastIndex = #Particles
			Particles[Index] = Particles[LastIndex]
			Particles[LastIndex] = nil

			table.insert(Pool, Particle.Instance)
		end
	end

	local function SpawnParticle(
		LifetimeMin: number,
		LifetimeMax: number,
		SizeKeyframes: { [number]: number },
		SpeedMin: number,
		SpeedMax: number,
		Direction: Vector2,
		SpreadMin: number,
		SpreadMax: number,
		FlipbookEnabled: boolean,
		FlipbookFrameSize: Vector2,
		FlipbookColumns: number,
		FlipbookStartFrame: number,
		FlipbookEndFrame: number,
		FlipbookStartRandom: boolean,
		FlipbookFramerateMin: number,
		FlipbookFramerateMax: number,
		SpawnAt: string
	)
		if #Particles >= ResolveProp(Props.MaxParticles, 150) then
			return
		end

		if RootSizeX <= 0 or RootSizeY <= 0 then
			return
		end

		local Life = math.max(0.05, RandomRange(LifetimeMin, LifetimeMax))
		local ParticleSize = math.max(1, EvalNumberKeyframes(SizeKeyframes, 0))
		local VelocityMagnitude = math.max(0, RandomRange(SpeedMin, SpeedMax))
		local AngularOffset = RandomRange(SpreadMin, SpreadMax)
		local Velocity = Rotated(Direction, AngularOffset)
		local RootAnchorPoint = Root.AnchorPoint
		local StartX: number
		local StartY: number

		if SpawnAt == "AnchorPoint" then
			StartX = RootSizeX * RootAnchorPoint.X - ParticleSize * RootAnchorPoint.X
			StartY = RootSizeY * RootAnchorPoint.Y - ParticleSize * RootAnchorPoint.Y
		elseif SpawnAt == "Center" then
			-- StartX = (RootSizeX * 0.5) + ParticleSize * 0.5
			-- StartY = (RootSizeY * 0.5) + ParticleSize * 0.5
			StartX = (RootSizeX / 2) - (ParticleSize / 2)
			StartY = (RootSizeY / 2) - (ParticleSize / 2)
		else
			StartX = math.random() * RootSizeX
			StartY = math.random() * RootSizeY
		end

		local VelocityX = Velocity.X * VelocityMagnitude
		local VelocityY = Velocity.Y * VelocityMagnitude
		local ParticleFlipbookStartFrame = FlipbookStartFrame

		if FlipbookStartRandom and FlipbookEndFrame >= FlipbookStartFrame then
			ParticleFlipbookStartFrame = math.random(FlipbookStartFrame, FlipbookEndFrame)
		end

		local ParticleFlipbookFramerate = if FlipbookFramerateMax > FlipbookFramerateMin
			then FlipbookFramerateMin + math.random() * (FlipbookFramerateMax - FlipbookFramerateMin)
			else FlipbookFramerateMin

		local Instance = AcquireParticleInstance()
		Instance.Size = UDim2.fromOffset(ParticleSize, ParticleSize)
		Instance.Position = UDim2.fromOffset(StartX, StartY)

		if UsesImage then
			local ImageInstance = Instance :: ImageLabel
			ImageInstance.ImageTransparency = 0
			if FlipbookEnabled then
				SetFlipbookFrame(ImageInstance, ParticleFlipbookStartFrame, FlipbookColumns)
			else
				ImageInstance.ImageRectSize = Vector2.zero
				ImageInstance.ImageRectOffset = Vector2.zero
			end
		else
			(Instance :: Frame).BackgroundTransparency = 0
		end

		Instance.Parent = Root

		table.insert(Particles, {
			Instance = Instance,
			IsImage = UsesImage,
			IsFlipbook = UsesImage and FlipbookEnabled,
			X = StartX,
			Y = StartY,
			VX = VelocityX,
			VY = VelocityY,
			Lifetime = Life,
			Age = 0,
			StartSize = ParticleSize,
			FlipbookStartFrame = ParticleFlipbookStartFrame,
			FlipbookFramerate = ParticleFlipbookFramerate,
		})
	end

	local function EmitBurst(Count: number)
		local BurstCount = math.max(0, math.floor(Count))
		if BurstCount <= 0 then
			return
		end

		local LifetimeMin, LifetimeMax = ResolveNumberOrRange(ResolveProp(Props.Lifetime, 1.2), 1.2)
		local SpeedMin, SpeedMax = ResolveNumberOrRange(ResolveProp(Props.Speed, 70), 70)
		local SizeKeyframes = ResolveProp(Props.Size, DefaultSize)
		local Direction = ToUnit(ResolveProp(Props.Direction, DefaultDirection))
		local SpreadMin, SpreadMax = ResolveSpreadRangeRadians(ResolveProp(Props.Spread, 30), 30)
		local FlipbookEnabled = UsesImage and ResolveProp(Props.FlipbookEnabled, false)
		local FlipbookColumns, FlipbookRows, FlipbookFrameSize =
			ResolveFlipbookLayout(ResolveProp(Props.FlipbookLayout, nil))
		local FlipbookFramerateMin, FlipbookFramerateMax =
			ResolveFlipbookFramerateRange(ResolveProp(Props.FlipbookFramerate, nil), 12)
		local FlipbookStartFrame = math.max(1, math.floor(ResolveProp(Props.FlipbookStartFrame, 1)))
		local FlipbookEndFrame = math.max(
			FlipbookStartFrame,
			math.floor(ResolveProp(Props.FlipbookEndFrame, FlipbookColumns * FlipbookRows))
		)
		local FlipbookStartRandom = ResolveProp(Props.FlipbookStartRandom, false)

		for _ = 1, BurstCount do
			SpawnParticle(
				LifetimeMin,
				LifetimeMax,
				SizeKeyframes,
				SpeedMin,
				SpeedMax,
				Direction,
				SpreadMin,
				SpreadMax,
				FlipbookEnabled,
				FlipbookFrameSize,
				FlipbookColumns,
				FlipbookStartFrame,
				FlipbookEndFrame,
				FlipbookStartRandom,
				FlipbookFramerateMin,
				FlipbookFramerateMax,
				ResolveProp(Props.SpawnAt, "Bounds")
			)
		end
	end

	-- if type(Props.Emitter) == "table" then
	-- 	function Props.Emitter:Emit(count: number?)
	-- 		EmitBurst(count or 1)
	-- 	end
	-- end

	Connection = RunService.RenderStepped:Connect(function(Dt)
		local IsEnabled = Enabled == nil or ResolveProp(Enabled, true)

		local SpawnRate = ResolveProp(Props.SpawnRate, 16)
		local LifetimeMin, LifetimeMax = ResolveNumberOrRange(ResolveProp(Props.Lifetime, 1.2), 1.2)
		local SpeedMin, SpeedMax = ResolveNumberOrRange(ResolveProp(Props.Speed, 70), 70)
		local SizeKeyframes = ResolveProp(Props.Size, DefaultSize)
		local Direction = ToUnit(ResolveProp(Props.Direction, DefaultDirection))
		local SpreadMin, SpreadMax = ResolveSpreadRangeRadians(ResolveProp(Props.Spread, 30), 30)
		local Gravity = ResolveProp(Props.Gravity, DefaultGravity)
		local RawTransparency = ResolveProp(Props.Transparency, nil)
		local RawColorProp = ResolveProp(Props.Color, nil)
		local FlipbookEnabled = UsesImage and ResolveProp(Props.FlipbookEnabled, false)
		local FlipbookColumns, FlipbookRows, FlipbookFrameSize =
			ResolveFlipbookLayout(ResolveProp(Props.FlipbookLayout, nil))
		local FlipbookFramerateMin, FlipbookFramerateMax =
			ResolveFlipbookFramerateRange(ResolveProp(Props.FlipbookFramerate, nil), 12)
		local FlipbookStartFrame = math.max(1, math.floor(ResolveProp(Props.FlipbookStartFrame, 1)))
		local FlipbookEndFrame = math.max(
			FlipbookStartFrame,
			math.floor(ResolveProp(Props.FlipbookEndFrame, FlipbookColumns * FlipbookRows))
		)
		local FlipbookStartRandom = ResolveProp(Props.FlipbookStartRandom, false)
		local FlipbookModeName = ResolveFlipbookModeName(ResolveProp(Props.FlipbookMode, nil), true)
		local SpawnAt = ResolveProp(Props.SpawnAt, "Bounds")
		local GravityX = Gravity.X
		local GravityY = Gravity.Y

		if IsEnabled then
			SpawnAccumulator += Dt * SpawnRate
		end
		local SpawnCount = math.floor(SpawnAccumulator)
		SpawnAccumulator -= SpawnCount

		for _ = 1, SpawnCount do
			SpawnParticle(
				LifetimeMin,
				LifetimeMax,
				SizeKeyframes,
				SpeedMin,
				SpeedMax,
				Direction,
				SpreadMin,
				SpreadMax,
				FlipbookEnabled,
				FlipbookFrameSize,
				FlipbookColumns,
				FlipbookStartFrame,
				FlipbookEndFrame,
				FlipbookStartRandom,
				FlipbookFramerateMin,
				FlipbookFramerateMax,
				SpawnAt
			)
		end
		for i = #Particles, 1, -1 do
			local Particle = Particles[i]
			Particle.Age += Dt

			if Particle.Age >= Particle.Lifetime then
				ReleaseParticle(i)
				continue
			end

			Particle.VX += GravityX * Dt
			Particle.VY += GravityY * Dt
			Particle.X += Particle.VX * Dt
			Particle.Y += Particle.VY * Dt

			local Alpha = Particle.Age / Particle.Lifetime
			local RawSizeProp = ResolveProp(Props.Size, DefaultSize)
			local ParticleScale = ResolveProp(Props.Scale, 1)
			local CurrentSize = math.max(1, EvalNumberKeyframes(RawSizeProp, Alpha) * ParticleScale)

			Particle.Instance.Size = UDim2.fromOffset(CurrentSize, CurrentSize)
			Particle.Instance.Position = UDim2.fromOffset(Particle.X, Particle.Y)

			local Transparency: number
			if type(RawTransparency) == "table" then
				Transparency = EvalNumberKeyframes(RawTransparency :: { [number]: number }, Alpha)
			elseif type(RawTransparency) == "number" then
				Transparency = RawTransparency :: number
			else
				Transparency = Alpha
			end

			if type(RawColorProp) == "table" then
				local EvaledColor = EvalColorKeyframes(RawColorProp :: { [number]: Color3 }, Alpha)
				if Particle.IsImage then
					(Particle.Instance :: ImageLabel).ImageColor3 = EvaledColor
				else
					(Particle.Instance :: Frame).BackgroundColor3 = EvaledColor
				end
			end

			if Particle.IsImage then
				(Particle.Instance :: ImageLabel).ImageTransparency = Transparency
			else
				(Particle.Instance :: Frame).BackgroundTransparency = Transparency
			end

			if Particle.IsImage and Particle.IsFlipbook then
				local Frame = GetFlipbookFrameFromMode(
					FlipbookModeName,
					Particle.FlipbookStartFrame,
					FlipbookEndFrame,
					Particle.Age,
					Particle.FlipbookFramerate
				)
				SetFlipbookFrame(Particle.Instance :: ImageLabel, Frame, FlipbookColumns)
			end
		end
	end)

	DestroyingConnection = Root.Destroying:Connect(function()
		for i = #Particles, 1, -1 do
			local Particle = Particles[i]
			Particle.Instance:Destroy()
			Particles[i] = nil
		end

		for i = #Pool, 1, -1 do
			Pool[i]:Destroy()
			Pool[i] = nil
		end
	end)

	table.insert(Scope, SizeChangedConnection)
	table.insert(Scope, Connection)
	table.insert(Scope, DestroyingConnection)

	return Root, EmitBurst
end
