--||--
--This Object implementation was taken from SNKRX (MIT license). Slightly modified, this is a very simple OOP base

local Object = {}
Object.__index = Object
function Object:Init() end

function Object:Extend()
	local cls = {}
	for k, v in pairs(self) do
		if k:find "__" == 1 then
			cls[k] = v
		end
	end
	cls.__index = cls
	cls.super = self
	setmetatable(cls, self)
	return cls
end

function Object:Is(T)
	local mt = getmetatable(self)
	while mt do
		if mt == T then
			return true
		end
		mt = getmetatable(mt)
	end
	return false
end

function Object:__call(...)
	local obj = setmetatable({}, self)
	obj:Init(...)
	return obj
end

return Object
