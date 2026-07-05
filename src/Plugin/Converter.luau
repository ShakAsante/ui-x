local ReplicatedStorage = game:GetService "ReplicatedStorage"
local EnumList = "@self/Packages"
local ClassData = require "@self/ClassData"
local Object = require "../Object"

--[=[
	@class Converter

	Serializes a Roblox `Instance` tree into a plain data table, then emits
	that data as generated source code for a target UI framework (Fusion,
	Roact, Vide, or native `Instance.new` calls).
]=]
local Converter = Object:extend()

type AcceptedTypes = string | boolean | number | Color3 | UDim2 | UDim | Vector2 | Vector3

type SerializedObject = {
	Name: string,
	ClassName: string,
	Children: { SerializedObject },
}

type Framework = EnumItem

type VideComponent = string
type NativeComponent = string
type FusionComponent = string
type RoactComponent = string

local Frameworks = EnumList.new("Frameworks", {
	"Vide",
	"Fusion",
	"Roact",
	"Native",
})

--[=[
	Sets the default target framework to Fusion and exposes the `Frameworks` enum.
]=]
function Converter:Init(): ()
	self.framework = Frameworks.Fusion
	self.frameworks = Frameworks
end

--[=[
	Formats a single value as a Luau source-code literal.

	@param value AcceptedTypes
	@return string
	@error "Unhandled type: <type>" -- thrown if `value`'s type has no formatter
]=]
function Converter:FormatValue(value: AcceptedTypes): string?
	local type = typeof(value)

	local formats = {
		["string"] = function()
			return string.format("%q", value)
		end,

		["boolean"] = function()
			return tostring(value)
		end,

		["number"] = function()
			return tostring(value)
		end,

		["Color3"] = function()
			return ("Color3.fromRGB(%d, %d, %d)"):format(
				math.floor(value.R * 255),
				math.floor(value.G * 255),
				math.floor(value.B * 255)
			)
		end,

		["UDim2"] = function()
			return ("UDim2.new(%s, %s, %s, %s)"):format(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
		end,
	}

	local format = formats[type]

	if format then
		return format()
	end

	error("Unhandled type: " .. type)
end

--[=[
	Returns `level` tab characters, used to indent generated source lines.

	@param level number
	@return string
]=]
function Converter:Indent(level: number): string
	return string.rep("\t", level)
end

--[=[
	Binds `self` to `callback` so it can be invoked without an explicit method call.

	@param callback (self: Converter, ...any) -> ...any
	@return (...any) -> ...any
]=]
function Converter:Wrap(callback: (self: any, ...any) -> ...any): (...any) -> ...any
	return function(...)
		return callback(self, ...)
	end
end

--[=[
	Reads the properties listed in `ClassData` off `instance` into a plain table.

	@param instance Instance
	@return { [string]: any }
]=]
function Converter:Serialize(instance: Instance): { [string]: any }
	local props = self:GetPropsOfClass(instance.ClassName)

	local tbl = {}

	for prop, _ in pairs(props) do
		tbl[prop] = instance[prop]
	end

	tbl["Name"] = instance.Name
	tbl["ClassName"] = instance.ClassName

	return tbl
end

--[=[
	Recursively serializes `instance` and its descendants into a `SerializedObject` tree.

	@param instance Instance
	@return SerializedObject
]=]
function Converter:ConvertInstance(instance: Instance): SerializedObject
	local serial = self:Serialize(instance)

	serial.Children = {}

	for _, child in ipairs(instance:GetChildren()) do
		table.insert(serial.Children, self:ConvertInstance(child))
		task.wait()
	end

	return serial
end

--[=[
	Generates Fusion component source code from a `SerializedObject` tree.

	@param data SerializedObject
	@return FusionComponent -- generated source text
]=]
function Converter:MakeFusionComponent(data: SerializedObject): FusionComponent
	local function Read(node: SerializedObject, offset: number?): string
		offset = offset or 1
		local ignoredProps = { "ClassName", "className", "Children" }

		local indent = self:Indent(offset)

		local lines = {}

		table.insert(lines, `{indent}scope:New("{node.ClassName}")` .. " {")

		for prop, value in pairs(node) do
			if table.find(ignoredProps, prop) then
				continue
			end
			table.insert(lines, `{self:Indent(offset + 1)}{prop} = {self:FormatValue(value)},`)
		end

		if #node.Children > 0 then
			table.insert(lines, indent .. "\t[Children] = {")

			for _, child in ipairs(node.Children) do
				table.insert(lines, Read(child, offset + 2) .. ",")
			end

			table.insert(lines, indent .. "\t},")
		end

		table.insert(lines, indent .. "}")

		return table.concat(lines, "\n")
	end

	return table.concat({
		"local Fusion = require(...)",
		"",
		"local Children = Fusion.Children",
		"",
		"return function(scope: Fusion.Scope<typeof(Fusion)>)",
		"\treturn " .. Read(data),
		"end",
	}, "\n")
end

--[=[
	Generates native `Instance.new` construction source code from a `SerializedObject` tree.

	@param data SerializedObject
	@return NativeComponent -- generated source text
]=]
function Converter:MakeNativeComponent(data: SerializedObject): NativeComponent
	local function Read(node: SerializedObject, offset: number?): string
		offset = offset or 1
		local indent = self:Indent(offset)

		local lines = {}

		table.insert(lines, indent .. `local node = Instance.new("{node.ClassName}")`)

		for prop, value in pairs(node) do
			if prop == "ClassName" or prop == "Children" then
				continue
			end

			table.insert(lines, indent .. `node.{prop} = {self:FormatValue(value)}`)
		end

		if node.Children and #node.Children > 0 then
			for _, child in ipairs(node.Children) do
				table.insert(lines, Read(child, offset))
				table.insert(lines, indent .. "child.Parent = node")
			end
		end

		table.insert(lines, indent .. "return node")

		return table.concat(lines, "\n")
	end

	return table.concat({
		"-- Native Roblox Instance Tree",
		"local function build()",
		self:Indent(1) .. "local root = nil",
		self:Indent(1) .. Read(data),
		self:Indent(1) .. "return node",
		"end",
	}, "\n")
end

--[=[
	Generates Vide component source code from a `SerializedObject` tree.

	@param data SerializedObject
	@return VideComponent -- generated source text
]=]
function Converter:MakeVideComponent(data: SerializedObject): VideComponent
	local function Quote(str: string): string
		return string.format("%q", str)
	end

	local function Read(node: SerializedObject, offset: number?): string
		offset = offset or 1
		local indent = self:Indent(offset)

		local lines = {}

		table.insert(lines, indent .. "vide.create(" .. Quote(node.ClassName) .. ", {")

		for prop, value in pairs(node) do
			if prop == "ClassName" or prop == "Children" then
				continue
			end

			table.insert(lines, indent .. "\t" .. prop .. " = " .. self:FormatValue(value) .. ",")
		end

		if node.Children and #node.Children > 0 then
			table.insert(lines, indent .. "\tchildren = {")

			for _, child in ipairs(node.Children) do
				table.insert(lines, self:Indent(offset + 1) .. Read(child, offset + 1) .. ",")
			end

			table.insert(lines, indent .. "\t}")
		end

		table.insert(lines, indent .. "})")

		return table.concat(lines, "\n")
	end

	return table.concat({
		"-- Vide Component Tree",
		"local vide = require(...)",
		"",
		"return function()",
		self:Indent(1) .. "return " .. Read(data, 1),
		"end",
	}, "\n")
end

--[=[
	Generates Roact component source code from a `SerializedObject` tree.

	@param data SerializedObject
	@return RoactComponent -- generated source text
]=]
function Converter:MakeRoactComponent(data: SerializedObject): RoactComponent
	local function Quote(str: string): string
		return string.format("%q", str)
	end

	local function Read(node: SerializedObject, offset: number?): string
		offset = offset or 1
		local indent = self:Indent(offset)

		local props = {}
		local children = {}

		for prop, value in pairs(node) do
			if prop == "ClassName" or prop == "Children" then
				continue
			end

			table.insert(props, indent .. "\t" .. prop .. " = " .. self:FormatValue(value) .. ",")
		end

		if node.Children and #node.Children > 0 then
			for _, child in ipairs(node.Children) do
				local childName = child.Name or child.ClassName

				table.insert(children, indent .. "\t[" .. Quote(childName) .. "] = " .. Read(child, offset + 1) .. ",")
			end
		end

		local propsBlock = table.concat(props, "\n")
		local childrenBlock = table.concat(children, "\n")

		local result = {}

		table.insert(result, indent .. "Roact.createElement(" .. Quote(node.ClassName) .. ", {")

		if propsBlock ~= "" then
			table.insert(result, propsBlock)
		end

		table.insert(result, indent .. "}, {")

		if childrenBlock ~= "" then
			table.insert(result, childrenBlock)
		end

		table.insert(result, indent .. "})")

		return table.concat(result, "\n")
	end

	return table.concat({
		"-- Roact Component Tree",
		"local Roact = require(...)",
		"",
		"return function()",
		self:Indent(1) .. "return " .. Read(data, 1),
		"end",
	}, "\n")
end

--[=[
	Dispatches to the generator matching `framework` and returns its generated source.

	@param data SerializedObject
	@param framework Framework
]=]
function Converter:MakeComponent(data: SerializedObject, framework: Framework): ()
	local refs = {
		[Frameworks.Roact] = self.MakeRoactComponent,
		[Frameworks.Fusion] = self.MakeFusionComponent,
		[Frameworks.Vide] = self.MakeVideComponent,
		[Frameworks.Native] = self.MakeNativeComponent,
	}

	refs[framework](self, data)
end

--[=[
	Asserts that `enum` is a supported framework and that its library is present
	under `ReplicatedStorage`.

	@param enum Framework?
	@error "Unsupported framework" -- thrown if `enum` isn't Roact, Fusion, or Vide
	@error "<name> library not found" -- thrown if the library can't be located
]=]
function Converter:AssertFramework(enum: Framework?): ()
	local refs = {
		[Frameworks.Roact] = "Roact",
		[Frameworks.Fusion] = "Fusion",
		[Frameworks.Vide] = "Vide",
	}

	assert(refs[enum], "Unsupported framework")
	local path = self:GetPathOfLibrary(refs[enum], ReplicatedStorage)
	assert(path, refs[enum] .. " library not found")
end

function Converter:GetDefaultComponents(): ()
	-- self:AssertPackages()
end

--[=[
	Searches upward from `parent` (defaulting to this script) for a descendant
	named `libraryName`, checking each ancestor in turn.

	@param libraryName string
	@param parent Instance? -- defaults to this script
	@return string? -- the full path of the found instance, if any
]=]
function Converter:GetPathOfLibrary(libraryName: string, parent: Instance?): string?
	parent = parent or script

	local current = parent

	local found = nil

	while current do
		found = current:FindFirstChild(libraryName, true)

		if found then
			break
		end

		current = current.Parent
	end

	return found and found:GetFullName() or nil
end

--[=[
	Looks up the serializable property list for `className` from `ClassData`.

	@param className string
	@return { [string]: boolean }
]=]
function Converter:GetPropsOfClass(className: string): { [string]: boolean }
	return ClassData[className] and ClassData[className].props or {}
end

return Converter
