JunkeeKeyStrip = ZO_Object:Subclass()

function JunkeeKeyStrip:New(name, keybind, callback, alignment)
	local obj = ZO_Object.New(self)
	obj:Init(name, keybind, callback, alignment)
	return obj
end

local function createStripDescriptor(name, keybind, callback, alignment)
	return {{
		alignment = alignment or KEYBIND_STRIP_ALIGN_LEFT,
		name = name,
		keybind = keybind,
		callback = callback
	}}
end

function JunkeeKeyStrip:Init(name, keybind, callback, alignment)
	self.stripDescriptor = createStripDescriptor(name, keybind, callback, alignment)
	self.wasAdded = false
end

function JunkeeKeyStrip:Add(onlyIfBound)
	if (not onlyIfBound or self:IsBound()) then
		KEYBIND_STRIP:AddKeybindButtonGroup(self.stripDescriptor)
		self.wasAdded = true
	end
end

function JunkeeKeyStrip:Remove()
	if (self.wasAdded) then
		KEYBIND_STRIP:RemoveKeybindButtonGroup(self.stripDescriptor)
		self.wasAdded = false
	end
end

function JunkeeKeyStrip:IsBound()
	-- TODO: if this is too expensive, only call once in the construction and register for keybind events
	local layer, category, action = GetActionIndicesFromName(self.stripDescriptor[1]["keybind"])
	for binding = 1, GetMaxBindingsPerAction() do
		local keyCode,_,_,_,_ = GetActionBindingInfo(layer, category, action, binding)
		if (keyCode > 0) then
			return true
		end
	end
	return false
end
