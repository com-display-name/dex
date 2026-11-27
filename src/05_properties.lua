local U = Dex.Utils
local UIS = UserInputService

local Properties = {
	Objects = {},
	RowMetas = {},
	RowsByName = {},
	Collapsed = {},
	CategoryFilter = nil,
	FilterText = "",
	SelectedName = nil,
	Editing = nil,
	_FilterToken = 0,
	ExpandedProps = {},
	Frozen = false,
}

Dex.Properties = Properties

local Inaccessible = {}

local EnumByProperty = {
	Material = "Material",
	Shape = "PartType",
	TopSurface = "SurfaceType",
	BottomSurface = "SurfaceType",
	FrontSurface = "SurfaceType",
	BackSurface = "SurfaceType",
	LeftSurface = "SurfaceType",
	RightSurface = "SurfaceType",
	TextXAlignment = "TextXAlignment",
	TextYAlignment = "TextYAlignment",
	TextTruncate = "TextTruncate",
	Font = "Font",
	ScaleType = "ScaleType",
	BorderMode = "BorderMode",
	ScrollingDirection = "ScrollingDirection",
	CameraType = "CameraType",
	StreamOutBehavior = "StreamOutBehavior",
	MeshType = "MeshType",
	ResetEnum = "ResetEnum",
	EasingStyle = "EasingStyle",
	EasingDirection = "EasingDirection",
	ApplyShadowMode = "ApplyShadowMode",
	AudioRollOffMaxDistance = "RollOffMaxDistance",
	FillDirection = "FillDirection",
	SortOrder = "SortOrder",
	HorizontalAlignment = "HorizontalAlignment",
	VerticalAlignment = "VerticalAlignment",
	ZIndexBehavior = "ZIndexBehavior",
	SizeConstraint = "SizeConstraint",
	LineJoin = "LineJoin",
	TextInputType = "TextInputType",
	ThumbnailSize = "ThumbnailSize",
}


local function valuesEqual (a, b)
	if a == b then return true end
	local typeA = typeof (a)
	local typeB = typeof (b)
	if typeA ~= typeB then return false end
	if typeA == "Color3" then
		return a.R == b.R and a.G == b.G and a.B == b.B
	elseif typeA == "BrickColor" then
		return a.Number == b.Number
	elseif
		typeA == "Vector2"
		or typeA == "Vector3"
		or typeA == "UDim"
		or typeA == "UDim2"
		or typeA == "CFrame"
		or typeA == "Rect"
		or typeA == "NumberRange"
		or typeA == "NumberSequence"
		or typeA == "ColorSequence"
		or typeA == "Font"
		or typeA == "Content"
		or typeA == "Ray"
		or typeA == "PhysicalProperties"
	then
		local okA, textA = pcall (tostring, a)
		local okB, textB = pcall (tostring, b)
		return okA and okB and textA == textB
	end
	return false
end

local function splitNumbers (text)
	local values = {}
	local cleaned = tostring (text):gsub ("Vector%d?%.new", "")
	for value in cleaned:gmatch ("[-+]?%d*%.?%d+") do
		local number = tonumber (value)
		if number then values[#values + 1] = number end
	end
	return values
end

local function propertyReadOnly (prop)
	return prop.Tags and (prop.Tags.ReadOnly or prop.Tags.NotScriptable) or false
end

function Properties:GetObjects ()
	local list = {}
	for _, object in ipairs (Dex.Selection.List) do
		if typeof (object) == "Instance" then list[#list + 1] = object end
	end
	return list
end

function Properties:GetTitle ()
	local objects = self.Objects
	if #objects == 0 then
		return "Properties"
	elseif #objects == 1 then
		local object = objects[1]
		local ok, name = pcall (function ()
			return object.Name
		end)
		local className = object.ClassName
		return string.format ("Properties - %s \"%s\"", className, ok and name or "?")
	end
	return string.format ("Properties - %d objects", #objects)
end

function Properties:UpdateTitle ()
	if self.Window then self.Window:SetTitle (self:GetTitle ()) end
end

local function hasHiddenPropertyApi ()
	return type (gethiddenproperties) == "function" and type (gethiddenproperty) == "function"
end

function Properties:ReadProperty (object, prop)
	if prop.Kind == "attribute" then
		local ok, value = pcall (function ()
			return object:GetAttribute (prop.Name)
		end)
		return ok, value
	end
	if prop.Kind == "hidden" then
		local ok, value = pcall (function ()
			return (gethiddenproperty (object, prop.Name))
		end)
		if not ok then return false, nil end
		return true, value
	end
	if prop.Kind == "tags" then
		if not CollectionService then return false, nil end
		local ok, tags = pcall (function ()
			return CollectionService:GetTags (object)
		end)
		return ok, tags
	end

	local ok, value = pcall (function ()
		return object[prop.Name]
	end)
	if not ok then return true, Inaccessible end
	return true, value
end

function Properties:GetValues (prop)
	local values = {}
	for _, object in ipairs (self.Objects) do
		local ok, value = self:ReadProperty (object, prop)
		if ok then values[#values + 1] = value end
	end
	return values
end

function Properties:GetCommonValue (prop)
	local values = self:GetValues (prop)
	if #values == 0 then return nil, true, values end
	local first = values[1]
	local mixed = #values < #self.Objects
	for index = 2, #values do
		if not valuesEqual (first, values[index]) then
			mixed = true
			break
		end
	end
	return first, mixed, values
end

function Properties:FormatValue (prop, value, mixed)
	if mixed then return "Multiple values" end
	if prop.Kind == "tags" then
		if type (value) ~= "table" or #value == 0 then return "—" end
		return table.concat (value, ", ")
	end
	if typeof (value) == "string" then
		return value
	elseif typeof (value) == "nil" then
		return "nil"
	elseif typeof (value) == "EnumItem" then
		return value.Name
	elseif typeof (value) == "Color3" then
		return "#" .. U.ColorHex (value)
	elseif typeof (value) == "Instance" then
		local ok, fullName = pcall (function ()
			return value:GetFullName ()
		end)
		return ok and fullName or value.Name
	end
	return U.Pretty (value)
end

local function parseAttributeValue (typeName, text)
	if typeName == "string" then
		return true, tostring (text)
	elseif typeName == "number" then
		local number = tonumber (text)
		if not number then return false, "Enter a valid number" end
		return true, number
	elseif typeName == "boolean" then
		local lower = tostring (text):lower ()
		if lower ~= "true" and lower ~= "false" then return false, "Enter true or false" end
		return true, lower == "true"
	elseif typeName == "Color3" then
		local raw = tostring (text):gsub ("#", ""):gsub ("%s", "")
		if raw:match ("^%x%x%x%x%x%x$") then
			local number = tonumber (raw, 16)
			return true,
				Color3.fromRGB (math.floor (number / 65536) % 256, math.floor (number / 256) % 256, number % 256)
		end
		local numbers = splitNumbers (text)
		if #numbers == 3 then
			return true,
				Color3.new (math.clamp (numbers[1], 0, 1), math.clamp (numbers[2], 0, 1), math.clamp (numbers[3], 0, 1))
		end
		return false, "Enter a hex color or R, G, B"
	elseif typeName == "Vector3" then
		local numbers = splitNumbers (text)
		if #numbers ~= 3 then return false, "Vector3 needs 3 numbers" end
		return true, Vector3.new (numbers[1], numbers[2], numbers[3])
	elseif typeName == "Vector2" then
		local numbers = splitNumbers (text)
		if #numbers ~= 2 then return false, "Vector2 needs 2 numbers" end
		return true, Vector2.new (numbers[1], numbers[2])
	elseif typeName == "BrickColor" then
		local ok, color = pcall (function ()
			return BrickColor.new (text)
		end)
		if not ok then return false, "Unknown BrickColor" end
		return true, color
	end
	return false, "Unsupported attribute type"
end

local function getBrickColors ()
	local colors = {}
	local seen = {}
	for index = 0, 127 do
		local ok, color = pcall (function ()
			return BrickColor.palette (index)
		end)
		if ok and typeof (color) == "BrickColor" and not seen[color.Name] then
			seen[color.Name] = true
			colors[#colors + 1] = color
		end
	end
	if #colors == 0 then
		for number = 0, 255 do
			local valid, color = pcall (function ()
				return BrickColor.new (number)
			end)
			if valid and typeof (color) == "BrickColor" and not seen[color.Name] then
				seen[color.Name] = true
				colors[#colors + 1] = color
			end
		end
	end
	table.sort (colors, function (a, b)
		return a.Name:lower () < b.Name:lower ()
	end)
	return colors
end

function Properties:ApplyProperty (prop, value, quiet)
	if #self.Objects == 0 then return false end
	if prop.Name == "ClassName" or prop.Kind == "hidden" or prop.Kind == "message" then return false end

	local failures = 0
	for _, object in ipairs (self.Objects) do
		local ok
		if prop.Kind == "attribute" then
			ok = pcall (function ()
				object:SetAttribute (prop.Name, value)
			end)
		elseif prop.Kind == "tags" then
			ok = pcall (function ()
				local tags = type (value) == "table" and value or {}
				local desired = {}
				for _, tag in ipairs (tags) do
					desired[tag] = true
				end
				local current = CollectionService:GetTags (object)
				for _, tag in ipairs (current) do
					if not desired[tag] then CollectionService:RemoveTag (object, tag) end
				end
				for tag in pairs (desired) do
					CollectionService:AddTag (object, tag)
				end
			end)
		else
			ok = pcall (function ()
				object[prop.Name] = value
			end)
		end
		if not ok then failures = failures + 1 end
	end

	if failures > 0 and not quiet then
		Dex:Notify ("Could not set " .. prop.Name .. " on " .. tostring (failures) .. " object(s)", "error")
	end

	self:RefreshValueDisplays ()
	self:UpdateTitle ()
	return failures == 0
end

function Properties:RefreshValueDisplays ()
	for propName, meta in pairs (self.RowsByName) do
		if not self.Editing or self.Editing.PropName ~= propName then
			if meta.Component then
				self:UpdateComponentValue (meta)
			else
				self:UpdateRowValue (meta)
			end
		end
	end
	if self.EmptyLabel and #self.Objects == 0 then self.EmptyLabel.Visible = true end
end

function Properties:RepaintRow (meta)
	if not meta or not meta.Row or not meta.Row.Parent then return end

	local selected = self.SelectedName == meta.Prop.Name
	local background
	if selected then
		background = Dex.Theme.Properties.RowSelected
	elseif meta.Hovered then
		background = Dex.Theme.Properties.RowHover
	else
		background = meta.Alternate and Dex.Theme.Properties.RowAlt or Dex.Theme.Properties.Row
	end
	meta.Row.BackgroundColor3 = background

	local muted = propertyReadOnly (meta.Prop) or meta.Inaccessible == true
	if meta.NameLabel then
		meta.NameLabel.TextColor3 = muted and Dex.Theme.Properties.ValueMuted or Dex.Theme.Properties.Name
	end
	if meta.ValueLabel then
		if meta.MixedValue or meta.Inaccessible then
			meta.ValueLabel.TextColor3 = Dex.Theme.Properties.ValueMuted
		else
			meta.ValueLabel.TextColor3 = muted and Dex.Theme.Properties.ValueMuted or Dex.Theme.Properties.Value
		end
	end
end

function Properties:SelectProperty (propName)
	if self.SelectedName == propName then return end
	local previous = self.SelectedName
	self.SelectedName = propName
	if previous and self.RowsByName[previous] then self:RepaintRow (self.RowsByName[previous]) end
	if self.RowsByName[propName] then self:RepaintRow (self.RowsByName[propName]) end
end

function Properties:GetEnumType (prop, value)
	if typeof (value) == "EnumItem" then
		local ok, name = pcall (function ()
			return tostring (value.EnumType)
		end)
		if ok and name then
			local valid, enum = pcall (function ()
				return Enum[name]
			end)
			if valid and enum then return name end
		end
	end
	if prop.ValueType and Dex.Reflect.Enums[prop.ValueType] then return prop.ValueType end
	local mapped = EnumByProperty[prop.Name]
	if mapped and typeof (mapped) == "string" then
		local ok, enum = pcall (function ()
			return Enum[mapped]
		end)
		if ok and enum then return mapped end
	end
	return nil
end

function Properties:GetEnumItems (enumType)
	if not enumType then return {} end

	local result = {}
	local ok, values = pcall (function ()
		return Enum[enumType]:GetEnumItems ()
	end)
	if ok and type (values) == "table" then
		for _, item in ipairs (values) do
			result[#result + 1] = {
				Name = item.Name,
				Value = item.Value,
			}
		end
		if #result > 0 then return result end
	end
	return Dex.Reflect:GetEnumItems (enumType) or result
end

function Properties:OpenEnumPicker (meta)
	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	local enumType = self:GetEnumType (prop, value)
	if not enumType then
		Dex:Notify ("This property does not expose an enum type", "info")
		return
	end

	local items = self:GetEnumItems (enumType)
	if #items == 0 then
		Dex:Notify ("No enum values available", "error")
		return
	end

	local pickerItems = {}
	for _, item in ipairs (items) do
		pickerItems[#pickerItems + 1] = {
			Text = item.Name,
			Value = item.Name,
			Selected = not mixed and typeof (value) == "EnumItem" and value.Name == item.Name,
		}
	end

	Dex:ShowPicker ({
		Anchor = meta.ValueCell,
		Items = pickerItems,
		Width = math.max (220, meta.ValueCell.AbsoluteSize.X),
		MaxHeight = 340,
		Search = true,
		SearchPlaceholder = prop.Name,
		AutoFocus = true,
		OnSelect = function (itemName)
			local ok, item = pcall (function ()
				return Enum[enumType][itemName]
			end)
			if not ok or not item then
				Dex:Notify ("Unable to set " .. prop.Name, "error")
				return
			end
			self:ApplyProperty (prop, item)
			self:RefreshValueDisplays ()
		end,
	})
end

function Properties:OpenBrickColorPicker (meta)
	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	local colors = getBrickColors ()

	local items = {}
	for _, color in ipairs (colors) do
		items[#items + 1] = {
			Text = color.Name,
			Value = color.Name,
			Selected = not mixed and typeof (value) == "BrickColor" and value.Name == color.Name,
		}
	end

	Dex:ShowPicker ({
		Anchor = meta.ValueCell,
		Items = items,
		Width = math.max (240, meta.ValueCell.AbsoluteSize.X),
		MaxHeight = 360,
		Search = true,
		SearchPlaceholder = "BrickColor...",
		AutoFocus = true,
		OnSelect = function (name)
			local valid, color = pcall (function ()
				return BrickColor.new (name)
			end)
			if valid then
				self:ApplyProperty (prop, color)
			else
				Dex:Notify ("Invalid BrickColor", "error")
			end
		end,
	})
end

function Properties:OpenColorPicker (meta)
	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	local startColor = (not mixed and typeof (value) == "Color3") and value or Color3.new (1, 1, 1)
	local position = Vector2.new (
		meta.ValueCell.AbsolutePosition.X,
		meta.ValueCell.AbsolutePosition.Y + meta.ValueCell.AbsoluteSize.Y + 2
	)

	Dex:ShowColorPicker (startColor, position, function (color)
		if not self:ApplyProperty (prop, color) then return end
		if meta.Swatch then meta.Swatch.BackgroundColor3 = color end
		if meta.ValueLabel then
			meta.ValueLabel.Text = "#" .. U.ColorHex (color)
			meta.ValueLabel.TextColor3 = Dex.Theme.Properties.Value
		end
	end)
end

function Properties:StartValueEdit (meta)
	if self.Editing then self:FinishValueEdit (true) end
	local prop = meta.Prop
	if propertyReadOnly (prop) then return end

	local value, mixed = self:GetCommonValue (prop)
	local initial
	if meta.Component then
		local ok, componentValue = pcall (function ()
			return meta.Component.Get (value)
		end)
		initial = ok and tostring (componentValue) or ""
	elseif prop.Kind == "tags" then
		initial = type (value) == "table" and table.concat (value, ", ") or ""
	elseif mixed then
		initial = ""
	elseif typeof (value) == "string" then
		initial = value
	elseif typeof (value) == "CFrame" then
		initial = tostring (value)
	elseif typeof (value) == "EnumItem" then
		initial = value.Name
	elseif typeof (value) == "nil" then
		initial = ""
	elseif typeof (value) == "Instance" then
		initial = value:GetFullName ()
	else
		initial = U.Pretty (value)
	end

	if meta.ValueLabel then meta.ValueLabel.Visible = false end

	local isText = meta.IsTextValue == true or typeof (value) == "string"
	local box = U.Textbox (meta.ValueCell, {
		Name = "Editor",
		BackgroundColor3 = Dex.Theme.Properties.InputBackground,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (4, 1),
		Size = UDim2.new (1, -8, 1, -2),
		Font = Dex.Fonts.UI,
		Text = initial,
		TextColor3 = Dex.Theme.Properties.Value,
		TextSize = 13,
		TextWrapped = isText,
		TextYAlignment = isText and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
		MultiLine = isText,
		ZIndex = (meta.Row.ZIndex or 2) + 6,
	})
	U.Corner (box, 2)
	U.Stroke (box, Dex.Theme.Properties.InputBorder, 1, 0)
	self.Editing = {
		PropName = meta.Component and (prop.Name .. "." .. meta.Component.Name) or prop.Name,
		Box = box,
		Meta = meta,
		Finished = false,
	}

	meta.ValueCell.Active = false
	box.FocusLost:Connect (function ()
		self:FinishValueEdit (true)
	end)
	task.defer (function ()
		if box and box.Parent then
			box:CaptureFocus ()
			box.SelectionStart = 1
			box.CursorPosition = #box.Text + 1
		end
	end)
end

function Properties:ParseAndSet (meta, text)
	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	local typeName = typeof (value)
	local valueType = prop.ValueType
	if prop.Kind == "attribute" and typeName == "nil" and valueType then typeName = valueType end

	if meta.Component then
		local number = tonumber (text)
		if not number then
			Dex:Notify ("Enter a number", "error")
			return false
		end
		local ok, newValue = pcall (function ()
			return meta.Component.Set (value, number)
		end)
		if not ok then
			Dex:Notify ("Invalid value", "error")
			return false
		end
		return self:ApplyProperty (prop, newValue)
	end

	if prop.Kind == "tags" then
		local tags = {}
		for tag in text:gmatch ("[^,%s]+") do
			tags[#tags + 1] = tag
		end
		self:ApplyProperty (prop, tags)
		return true
	end

	if typeName == "number" then
		local number = tonumber (text)
		if not number then
			Dex:Notify ("Enter a valid number", "error")
			return false
		end
		return self:ApplyProperty (prop, number)
	elseif typeName == "boolean" then
		local lower = text:lower ()
		if lower ~= "true" and lower ~= "false" then
			Dex:Notify ("Enter true or false", "error")
			return false
		end
		return self:ApplyProperty (prop, lower == "true")
	elseif typeName == "string" or typeof (value) == "nil" and (valueType == "string" or valueType == "Content") then
		return self:ApplyProperty (prop, text)
	elseif typeName == "Color3" then
		local raw = text:gsub ("#", ""):gsub ("%s", "")
		if raw:match ("^%x%x%x%x%x%x$") then
			local number = tonumber (raw, 16)
			local color =
				Color3.fromRGB (math.floor (number / 65536) % 256, math.floor (number / 256) % 256, number % 256)
			return self:ApplyProperty (prop, color)
		end
		local numbers = splitNumbers (text)
		if #numbers == 3 then
			local r, g, b = numbers[1], numbers[2], numbers[3]
			if r > 1 or g > 1 or b > 1 then
				return self:ApplyProperty (
					prop,
					Color3.fromRGB (math.clamp (r, 0, 255), math.clamp (g, 0, 255), math.clamp (b, 0, 255))
				)
			end
			return self:ApplyProperty (
				prop,
				Color3.new (math.clamp (r, 0, 1), math.clamp (g, 0, 1), math.clamp (b, 0, 1))
			)
		end
		Dex:Notify ("Enter a hex color like #ff00aa or R, G, B", "error")
		return false
	elseif typeName == "Vector2" then
		local numbers = splitNumbers (text)
		if #numbers ~= 2 then
			Dex:Notify ("Vector2 needs 2 numbers", "error")
			return false
		end
		return self:ApplyProperty (prop, Vector2.new (numbers[1], numbers[2]))
	elseif typeName == "Vector3" or valueType == "Vector3" then
		local numbers = splitNumbers (text)
		if #numbers < 3 then
			Dex:Notify ("Vector3 needs 3 numbers (X, Y, Z)", "error")
			return false
		end
		return self:ApplyProperty (prop, Vector3.new (numbers[1], numbers[2], numbers[3]))
	elseif typeName == "UDim" then
		local numbers = splitNumbers (text)
		if #numbers == 1 then
			return self:ApplyProperty (prop, UDim.new (0, numbers[1]))
		elseif #numbers == 2 then
			return self:ApplyProperty (prop, UDim.new (numbers[1], numbers[2]))
		end
		Dex:Notify ("UDim needs scale and offset", "error")
		return false
	elseif typeName == "UDim2" then
		local numbers = splitNumbers (text)
		if #numbers ~= 4 then
			Dex:Notify ("UDim2 needs 4 numbers", "error")
			return false
		end
		return self:ApplyProperty (prop, UDim2.new (numbers[1], numbers[2], numbers[3], numbers[4]))
	elseif typeName == "Rect" then
		local numbers = splitNumbers (text)
		if #numbers ~= 4 then
			Dex:Notify ("Rect needs 4 numbers", "error")
			return false
		end
		return self:ApplyProperty (prop, Rect.new (numbers[1], numbers[2], numbers[3], numbers[4]))
	elseif typeName == "CFrame" then
		local numbers = splitNumbers (text)
		if #numbers == 3 then
			return self:ApplyProperty (prop, CFrame.new (numbers[1], numbers[2], numbers[3]))
		elseif #numbers == 9 or #numbers == 12 then
			local ok, frame = pcall (function ()
				return CFrame.new (table.unpack (numbers))
			end)
			if ok then return self:ApplyProperty (prop, frame) end
		end
		Dex:Notify ("CFrame needs 3, 9 or 12 numbers", "error")
		return false
	elseif typeName == "NumberRange" then
		local numbers = splitNumbers (text)
		if #numbers == 1 then
			return self:ApplyProperty (prop, NumberRange.new (numbers[1]))
		elseif #numbers == 2 then
			return self:ApplyProperty (prop, NumberRange.new (numbers[1], numbers[2]))
		end
		Dex:Notify ("NumberRange needs 1 or 2 numbers", "error")
		return false
	elseif typeName == "EnumItem" then
		local enumType = self:GetEnumType (prop, value)
		if enumType then
			local ok, item = pcall (function ()
				return Enum[enumType][text]
			end)
			if ok and item then return self:ApplyProperty (prop, item) end
		end
		Dex:Notify ("Unknown enum value", "error")
		return false
	elseif typeName == "BrickColor" then
		local ok, color = pcall (function ()
			return BrickColor.new (text)
		end)
		if ok then return self:ApplyProperty (prop, color) end
		Dex:Notify ("Unknown BrickColor", "error")
		return false
	elseif typeof (value) == "nil" and valueType == "Instance" then
		Dex:Notify ("Instance values are edited by selecting the object", "info")
		return false
	end

	return self:ApplyProperty (prop, text)
end

function Properties:FinishValueEdit (commit)
	local editing = self.Editing
	if not editing or editing.Finished then return end
	editing.Finished = true
	self.Editing = nil
	local box = editing.Box
	local meta = editing.Meta
	local text = box and box.Text or ""

	if box then box:Destroy () end
	if meta.ValueCell then meta.ValueCell.Active = true end
	if meta.ValueLabel then meta.ValueLabel.Visible = true end

	if commit then
		local ok, result = pcall (function ()
			return self:ParseAndSet (meta, text)
		end)
		if not ok then Dex:Notify (tostring (result), "error") end
	end
	self:RefreshValueDisplays ()
end

function Properties:CancelEdit ()
	if not self.Editing then return end
	local editing = self.Editing
	if editing.Finished then return end
	editing.Finished = true
	self.Editing = nil
	if editing.Box then editing.Box:Destroy () end
	if editing.Meta and editing.Meta.ValueCell then editing.Meta.ValueCell.Active = true end
	if editing.Meta and editing.Meta.ValueLabel then editing.Meta.ValueLabel.Visible = true end
	self:RefreshValueDisplays ()
end

function Properties:ToggleBoolean (meta)
	if propertyReadOnly (meta.Prop) then return end
	local value, mixed = self:GetCommonValue (meta.Prop)
	local nextValue = mixed and true or not (value == true)
	self:ApplyProperty (meta.Prop, nextValue)
end

function Properties:HandleValueClick (meta)
	self:SelectProperty (meta.Prop.Name)
	if propertyReadOnly (meta.Prop) or meta.Inaccessible then return end

	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	local typeName = typeof (value)

	local enumTypeForProp = self:GetEnumType (prop, value)
	if typeof (value) == "EnumItem" or enumTypeForProp then
		self:OpenEnumPicker (meta)
	elseif typeName == "Color3" then
		self:OpenColorPicker (meta)
	elseif typeName == "BrickColor" then
		self:OpenBrickColorPicker (meta)
	elseif typeName == "boolean" then
		self:ToggleBoolean (meta)
	elseif typeName == "Instance" then
		if value then
			local isPlayer = false
			pcall (function ()
				isPlayer = value:IsA ("Player")
			end)
			if isPlayer then
				Dex:ShowMenu ({
					{
						Text = "Select Player",
						Callback = function ()
							Dex:SetSelection ({ value }, value)
						end,
					},
					{
						Text = "Select Character",
						Callback = function ()
							local character = value.Character
							if character then
								Dex:SetSelection ({ character }, character)
							else
								Dex:Notify ("That player has no character", "info")
							end
						end,
					},
				}, U.MousePoint ())
			else
				Dex:SetSelection ({ value }, value)
			end
		end
	elseif typeName == "nil" and prop.ValueType == "Instance" then
		Dex:Notify (prop.Name .. " has no Instance value", "info")
	elseif
		typeName == "CFrame"
		or typeName == "Vector3"
		or typeName == "Vector2"
		or typeName == "UDim"
		or typeName == "UDim2"
		or typeName == "Rect"
		or typeName == "NumberRange"
		or typeName == "string"
		or typeName == "number"
		or prop.Kind == "tags"
	then
		self:StartValueEdit (meta)
	elseif typeof (value) == "nil" and (prop.ValueType == "string" or prop.ValueType == "Content") then
		self:StartValueEdit (meta)
	end
end

function Properties:ShowPropertyMenu (meta, position)
	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	local primary = self.Objects[1]

	local valueIsPlayer = false
	pcall (function ()
		valueIsPlayer = typeof (value) == "Instance" and value:IsA ("Player")
	end)
	if valueIsPlayer then
		Dex:ShowMenu ({
			{
				Text = "Select Character",
				Callback = function ()
					local character = value.Character
					if character then
						Dex:SetSelection ({ character }, character)
					else
						Dex:Notify ("That player has no character", "info")
					end
				end,
			},
			{ Separator = true },
			{
				Text = "Select Player",
				Callback = function ()
					Dex:SetSelection ({ value }, value)
				end,
			},
		}, position or U.MousePoint ())
		return
	end

	local menuItems = {
		{
			Text = "Copy Value",
			Callback = function ()
				local text
				if mixed then
					text = "Multiple values"
				elseif prop.Kind == "tags" and type (value) == "table" then
					text = table.concat (value, ", ")
				elseif typeof (value) == "string" then
					text = value
				else
					text = U.Pretty (value)
				end
				Dex:CopyText (text)
			end,
		},
		{
			Text = "Copy Property Name",
			Callback = function ()
				Dex:CopyText (prop.Name)
			end,
		},
		{ Separator = true },
		{
			Text = "Reset to Default",
			Enabled = primary ~= nil and prop.Kind == nil and not propertyReadOnly (prop),
			Callback = function ()
				if not primary then return end
				local ok = pcall (function ()
					primary:ResetPropertyToDefault (prop.Name)
				end)
				if ok then
					self:RefreshValues ()
				else
					Dex:Notify ("This property cannot be reset to its default", "error")
				end
			end,
		},
		{
			Text = "Refresh Properties",
			Callback = function ()
				self:Refresh ()
			end,
		},
	}
	if prop.Kind == "attribute" then
		table.insert (menuItems, 3, { Separator = true })
		table.insert (menuItems, 4, {
			Text = "Remove Attribute",
			Callback = function ()
				for _, object in ipairs (self.Objects) do
					pcall (function ()
						object:SetAttribute (prop.Name, nil)
					end)
				end
				self:Refresh (true)
			end,
		})
	end
	Dex:ShowMenu (menuItems, position or U.MousePoint ())
end

function Properties:ResizeRow (meta)
	if not meta or not meta.Row or not meta.Row.Parent then return end

	local height = 22
	local wrapped = false
	if meta.IsTextValue and meta.ValueLabel and meta.ValueLabel.Visible then
		local width = meta.ValueCell and meta.ValueCell.AbsoluteSize.X or 0
		if width <= 0 then width = (self.List and self.List.AbsoluteSize.X or 400) * 0.5 - 16 end
		width = math.max (80, width - 8)
		local text = meta.ValueLabel.Text
		local ok, size = pcall (function ()
			return Dex.Services.TextService:GetTextSize (
				text,
				meta.ValueLabel.TextSize,
				meta.ValueLabel.Font,
				Vector2.new (width, math.huge)
			)
		end)
		if ok and size then
			local needed = math.ceil (size.Y) + 10
			if needed > 22 then
				height = math.min (160, needed)
				wrapped = true
			end
		end
	end

	meta.Row.Size = UDim2.new (1, 0, 0, height)
	if meta.ValueCell then meta.ValueCell.Size = UDim2.new (0.5, 0, 1, 0) end
	if meta.ValueLabel then
		meta.ValueLabel.TextWrapped = wrapped
		meta.ValueLabel.TextTruncate = wrapped and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
		meta.ValueLabel.TextYAlignment = wrapped and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
		local hasPrefix = (meta.Swatch and meta.Swatch.Visible) or (meta.Checkbox and meta.Checkbox.Visible)
		if wrapped then
			meta.ValueLabel.Position = UDim2.fromOffset (8, 3)
			meta.ValueLabel.Size = UDim2.new (1, -16, 1, -6)
		elseif not hasPrefix then
			meta.ValueLabel.Position = UDim2.fromOffset (8, 0)
			meta.ValueLabel.Size = UDim2.new (1, -16, 1, 0)
		end
	end
end

function Properties:UpdateRowValue (meta)
	if not meta or not meta.Row or not meta.Row.Parent then return end
	local prop = meta.Prop
	local value, mixed = self:GetCommonValue (prop)
	meta.MixedValue = mixed
	meta.Inaccessible = value == Inaccessible
	meta.IsTextValue = false
	meta.ValueLabel.Visible = true
	meta.ValueLabel.Position = UDim2.fromOffset (8, 0)
	meta.ValueLabel.Size = UDim2.new (1, -16, 1, 0)
	meta.Swatch.Visible = false
	meta.Checkbox.Visible = false
	meta.MixedMark.Visible = false
	meta.EnumArrow.Visible = false

	if meta.Inaccessible then
		meta.ValueLabel.Text = "<inaccessible>"
	elseif prop.Kind == "tags" then
		meta.ValueLabel.Text = self:FormatValue (prop, value, mixed)
	elseif typeof (value) == "EnumItem" then
		meta.ValueLabel.Text = mixed and "Multiple values" or value.Name
		meta.EnumArrow.Visible = not propertyReadOnly (prop)
	elseif typeof (value) == "Color3" then
		meta.Swatch.Visible = not mixed
		if not mixed then meta.Swatch.BackgroundColor3 = value end
		meta.ValueLabel.Text = mixed and "Multiple values" or ("#" .. U.ColorHex (value))
		meta.ValueLabel.Position = UDim2.fromOffset (28, 0)
		meta.ValueLabel.Size = UDim2.new (1, -36, 1, 0)
	elseif typeof (value) == "BrickColor" then
		meta.Swatch.Visible = not mixed
		if not mixed then meta.Swatch.BackgroundColor3 = value.Color end
		meta.ValueLabel.Text = mixed and "Multiple values" or value.Name
		meta.ValueLabel.Position = UDim2.fromOffset (28, 0)
		meta.ValueLabel.Size = UDim2.new (1, -36, 1, 0)
	elseif typeof (value) == "boolean" then
		meta.Checkbox.Visible = true
		meta.Checkbox.Image = (not mixed and value == true) and "rbxassetid://114553310323578" or "rbxassetid://86355492202291"
		meta.MixedMark.Visible = mixed
		meta.ValueLabel.Visible = false
	else
		local formatted = self:FormatValue (prop, value, mixed)
		if typeof (value) == "string" and not mixed then
			meta.IsTextValue = true
			if #formatted > 2000 then formatted = formatted:sub (1, 2000) .. "…" end
		end
		meta.ValueLabel.Text = formatted
		if prop.ValueType and Dex.Reflect.Enums[prop.ValueType] then
			meta.EnumArrow.Visible = not propertyReadOnly (prop)
		end
	end
	self:ResizeRow (meta)
	self:RepaintRow (meta)
end

local CompositeTypes = {
	Vector2 = true,
	Vector3 = true,
	UDim = true,
	UDim2 = true,
	CFrame = true,
	Color3 = true,
}

function Properties:GetComponents (prop, value)
	local kind = typeof (value)
	if not CompositeTypes[kind] then return nil end

	if kind == "Vector2" then
		return {
			{
				Name = "X",
				Get = function (v)
					return v.X
				end,
				Set = function (v, n)
					return Vector2.new (n, v.Y)
				end,
			},
			{
				Name = "Y",
				Get = function (v)
					return v.Y
				end,
				Set = function (v, n)
					return Vector2.new (v.X, n)
				end,
			},
		}
	elseif kind == "Vector3" then
		return {
			{
				Name = "X",
				Get = function (v)
					return v.X
				end,
				Set = function (v, n)
					return Vector3.new (n, v.Y, v.Z)
				end,
			},
			{
				Name = "Y",
				Get = function (v)
					return v.Y
				end,
				Set = function (v, n)
					return Vector3.new (v.X, n, v.Z)
				end,
			},
			{
				Name = "Z",
				Get = function (v)
					return v.Z
				end,
				Set = function (v, n)
					return Vector3.new (v.X, v.Y, n)
				end,
			},
		}
	elseif kind == "UDim" then
		return {
			{
				Name = "Scale",
				Get = function (v)
					return v.Scale
				end,
				Set = function (v, n)
					return UDim.new (n, v.Offset)
				end,
			},
			{
				Name = "Offset",
				Get = function (v)
					return v.Offset
				end,
				Set = function (v, n)
					return UDim.new (v.Scale, n)
				end,
			},
		}
	elseif kind == "UDim2" then
		return {
			{
				Name = "X Scale",
				Get = function (v)
					return v.X.Scale
				end,
				Set = function (v, n)
					return UDim2.new (n, v.X.Offset, v.Y.Scale, v.Y.Offset)
				end,
			},
			{
				Name = "X Offset",
				Get = function (v)
					return v.X.Offset
				end,
				Set = function (v, n)
					return UDim2.new (v.X.Scale, n, v.Y.Scale, v.Y.Offset)
				end,
			},
			{
				Name = "Y Scale",
				Get = function (v)
					return v.Y.Scale
				end,
				Set = function (v, n)
					return UDim2.new (v.X.Scale, v.X.Offset, n, v.Y.Offset)
				end,
			},
			{
				Name = "Y Offset",
				Get = function (v)
					return v.Y.Offset
				end,
				Set = function (v, n)
					return UDim2.new (v.X.Scale, v.X.Offset, v.Y.Scale, n)
				end,
			},
		}
	elseif kind == "CFrame" then
		local function angles (v)
			local x, y, z = v:ToEulerAnglesXYZ ()
			return math.deg (x), math.deg (y), math.deg (z)
		end
		local function withPos (v, x, y, z)
			return CFrame.new (x, y, z) * CFrame.fromEulerAnglesXYZ (v:ToEulerAnglesXYZ ())
		end
		local function withRot (v, rx, ry, rz)
			return CFrame.new (v.Position) * CFrame.fromEulerAnglesXYZ (math.rad (rx), math.rad (ry), math.rad (rz))
		end
		return {
			{
				Name = "X",
				Get = function (v)
					return v.X
				end,
				Set = function (v, n)
					return withPos (v, n, v.Y, v.Z)
				end,
			},
			{
				Name = "Y",
				Get = function (v)
					return v.Y
				end,
				Set = function (v, n)
					return withPos (v, v.X, n, v.Z)
				end,
			},
			{
				Name = "Z",
				Get = function (v)
					return v.Z
				end,
				Set = function (v, n)
					return withPos (v, v.X, v.Y, n)
				end,
			},
			{
				Name = "RX",
				Get = function (v)
					return (angles (v))
				end,
				Set = function (v, n)
					local _, y, z = angles (v)
					return withRot (v, n, y, z)
				end,
			},
			{
				Name = "RY",
				Get = function (v)
					local _, y = angles (v)
					return y
				end,
				Set = function (v, n)
					local x, _, z = angles (v)
					return withRot (v, x, n, z)
				end,
			},
			{
				Name = "RZ",
				Get = function (v)
					local _, _, z = angles (v)
					return z
				end,
				Set = function (v, n)
					local x, y = angles (v)
					return withRot (v, x, y, n)
				end,
			},
		}
	elseif kind == "Color3" then
		local function to255 (v)
			return math.floor (v * 255 + 0.5)
		end
		local function from255 (r, g, b)
			return Color3.fromRGB (math.clamp (r, 0, 255), math.clamp (g, 0, 255), math.clamp (b, 0, 255))
		end
		return {
			{
				Name = "R",
				Get = function (v)
					return to255 (v.R)
				end,
				Set = function (v, n)
					return from255 (n, to255 (v.G), to255 (v.B))
				end,
			},
			{
				Name = "G",
				Get = function (v)
					return to255 (v.G)
				end,
				Set = function (v, n)
					return from255 (to255 (v.R), n, to255 (v.B))
				end,
			},
			{
				Name = "B",
				Get = function (v)
					return to255 (v.B)
				end,
				Set = function (v, n)
					return from255 (to255 (v.R), to255 (v.G), n)
				end,
			},
		}
	end
	return nil
end

function Properties:CreateCategory (category, index)
	local row = U.Button (self.List, {
		Name = "Category" .. category,
		BackgroundColor3 = Dex.Theme.Properties.CategoryBackground,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 24),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 2,
	})
	local collapsed = self.Collapsed[category] == true
	local caret = U.Label (row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (9, 0),
		Size = UDim2.fromOffset (12, 24),
		Font = Dex.Fonts.UIBold,
		Text = collapsed and "▶" or "▼",
		TextColor3 = Dex.Theme.Properties.CategoryText,
		TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})
	caret.Active = false
	local label = U.Label (row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (27, 0),
		Size = UDim2.new (1, -36, 1, 0),
		Font = Dex.Fonts.UIBold,
		Text = category,
		TextColor3 = Dex.Theme.Properties.CategoryText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})
	label.Active = false

	row.MouseEnter:Connect (function ()
		row.BackgroundColor3 = Dex.Theme.Properties.RowHover
	end)
	row.MouseLeave:Connect (function ()
		row.BackgroundColor3 = Dex.Theme.Properties.CategoryBackground
	end)
	row.MouseButton1Click:Connect (function ()
		self.Collapsed[category] = not collapsed
		self:Refresh ()
	end)
	return row
end

function Properties:CreateMessageRow (text, index)
	local row = U.Frame (self.List, {
		Name = "PropertyMessage",
		BackgroundTransparency = 1,
		Size = UDim2.new (1, 0, 0, 22),
		LayoutOrder = index,
		ZIndex = 2,
	})
	local label = U.Label (row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (9, 0),
		Size = UDim2.new (1, -18, 1, 0),
		Font = Dex.Fonts.UI,
		Text = text,
		TextColor3 = Dex.Theme.Properties.ValueMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})
	label.Active = false
	return row
end

function Properties:CreatePropertyRow (prop, index, alternate, topDivider)
	local row = U.Button (self.List, {
		Name = "Property" .. prop.Name,
		BackgroundColor3 = alternate and Dex.Theme.Properties.RowAlt or Dex.Theme.Properties.Row,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 22),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 2,
	})

	local valueX = math.floor (self.List.AbsoluteSize.X * 0.5)
	if valueX < 110 then valueX = 110 end

	local nameLabel = U.Label (row, {
		Name = "PropertyName",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (9, 0),
		Size = UDim2.new (0, math.max (30, valueX - 15), 1, 0),
		Font = Dex.Fonts.UI,
		Text = prop.Name,
		TextColor3 = propertyReadOnly (prop) and Dex.Theme.Properties.ValueMuted or Dex.Theme.Properties.Name,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})
	nameLabel.Active = false

	local valueForType = self:GetCommonValue (prop)
	local components = self:GetComponents (prop, valueForType)
	if components then
		local caret = U.Button (row, {
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Position = UDim2.fromOffset (1, 0),
			Size = UDim2.fromOffset (10, 22),
			Font = Dex.Fonts.UIBold,
			Text = self.ExpandedProps[prop.Name] and "▼" or "▶",
			TextColor3 = Dex.Theme.Properties.ValueMuted,
			TextSize = 8,
			ZIndex = 4,
		})
		caret.Active = true
		caret.MouseButton1Click:Connect (function ()
			self.ExpandedProps[prop.Name] = not self.ExpandedProps[prop.Name]
			self:Refresh (false)
		end)
	end

	U.Frame (row, {
		BackgroundColor3 = Dex.Theme.Properties.Separator,
		BorderSizePixel = 0,
		Position = UDim2.new (0.5, 0, 0, 3),
		Size = UDim2.new (0, 1, 1, -6),
		ZIndex = 3,
		Active = false,
	})

	local valueCell = U.Button (row, {
		Name = "ValueCell",
		BackgroundTransparency = 1,
		Position = UDim2.new (0.5, 0, 0, 0),
		Size = UDim2.new (0.5, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})

	local valueLabel = U.Label (valueCell, {
		Name = "Value",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (8, 0),
		Size = UDim2.new (1, -16, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "",
		TextColor3 = propertyReadOnly (prop) and Dex.Theme.Properties.ValueMuted or Dex.Theme.Properties.Value,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
	})
	valueLabel.Active = false

	local swatch = U.Frame (valueCell, {
		Name = "Swatch",
		BackgroundColor3 = Dex.Theme.Properties.Value,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (8, 4),
		Size = UDim2.fromOffset (14, 14),
		Visible = false,
		ZIndex = 4,
		Active = false,
	})
	U.Corner (swatch, 2)
	U.Stroke (swatch, Dex.Theme.Properties.Separator, 1, 0.2)

	local checkbox = U.Create ("ImageLabel", {
		Name = "Checkbox",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (9, 4),
		Size = UDim2.fromOffset (14, 14),
		Image = "rbxassetid://86355492202291",
		ImageColor3 = Color3.new (1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
		Visible = false,
		ZIndex = 4,
		Active = false,
	})
	checkbox.Parent = valueCell
	local mixedMark = U.Frame (checkbox, {
		Name = "Mixed",
		BackgroundColor3 = Dex.Theme.Properties.ValueMuted,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Position = UDim2.fromScale (0.5, 0.5),
		Size = UDim2.fromOffset (7, 1),
		Visible = false,
		ZIndex = 5,
	})

	local enumArrow = U.Label (valueCell, {
		Name = "Arrow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0.5),
		Position = UDim2.new (1, -8, 0.5, 0),
		Size = UDim2.fromOffset (10, 14),
		Font = Dex.Fonts.UI,
		Text = "▾",
		TextColor3 = Dex.Theme.Properties.ValueMuted,
		TextSize = 11,
		Visible = false,
		ZIndex = 4,
	})
	enumArrow.Active = false

	local meta = {
		Prop = prop,
		Row = row,
		NameLabel = nameLabel,
		ValueCell = valueCell,
		ValueLabel = valueLabel,
		Swatch = swatch,
		Checkbox = checkbox,
		MixedMark = mixedMark,
		EnumArrow = enumArrow,
		Alternate = alternate,
		Hovered = false,
		MixedValue = false,
	}
	self.RowMetas[#self.RowMetas + 1] = meta
	self.RowsByName[prop.Name] = meta

	row.MouseEnter:Connect (function ()
		meta.Hovered = true
		self:RepaintRow (meta)
	end)
	row.MouseLeave:Connect (function ()
		meta.Hovered = false
		self:RepaintRow (meta)
	end)
	row.MouseButton1Click:Connect (function ()
		self.Window:Focus ()
		self:SelectProperty (prop.Name)
	end)
	valueCell.MouseButton1Click:Connect (function ()
		self.Window:Focus ()
		if self.Editing and self.Editing.PropName ~= prop.Name then self:FinishValueEdit (true) end
		self:HandleValueClick (meta)
	end)
	row.MouseButton2Click:Connect (function ()
		self.Window:Focus ()
		self:SelectProperty (prop.Name)
		self:ShowPropertyMenu (meta, U.MousePoint ())
	end)
	valueCell.MouseButton2Click:Connect (function ()
		self.Window:Focus ()
		self:SelectProperty (prop.Name)
		self:ShowPropertyMenu (meta, U.MousePoint ())
	end)

	if topDivider then
		U.Frame (row, {
			Name = "Divider",
			BackgroundColor3 = Dex.Theme.Properties.Separator,
			BorderSizePixel = 0,
			Position = UDim2.new (0, 0, 0, 0),
			Size = UDim2.new (1, 0, 0, 1),
			ZIndex = 3,
			Active = false,
		})
	end

	self:UpdateRowValue (meta)
	return row
end

function Properties:GetPropertiesForPrimary ()
	local object = self.Objects[1]
	if not object then return {} end

	local className = object.ClassName
	local result = {}
	local byKey = {}
	local function rank (prop)
		if prop.Tags and prop.Tags.Deprecated then return 0 end
		return prop.Name:sub (1, 1):match ("%u") and 2 or 1
	end
	local function add (prop)
		local key = prop.Name:lower ()
		if key == "parent" then return end
		local existing = byKey[key]
		if not existing or rank (prop) > rank (existing) then byKey[key] = prop end
	end

	for _, prop in ipairs (Dex.Reflect:GetProperties (className)) do
		add (prop)
	end
	add ({ Name = "Name", Class = className, Category = "Data", ValueType = "string", Tags = {} })
	add ({
		Name = "ClassName",
		Class = className,
		Category = "Data",
		ValueType = "string",
		Tags = { ReadOnly = true, NotScriptable = true },
	})
	if CollectionService then
		add ({ Name = "Tags", Class = className, Category = "Tags", ValueType = "Tags", Tags = {}, Kind = "tags" })
	end

	do
		local attrNames = {}
		local attrSet = {}
		local sampleValues = {}
		for _, object in ipairs (self.Objects) do
			local ok, attrs = pcall (function ()
				return object:GetAttributes ()
			end)
			if ok and type (attrs) == "table" then
				for name, value in pairs (attrs) do
					if type (name) == "string" and not attrSet[name] then
						attrSet[name] = true
						attrNames[#attrNames + 1] = name
						sampleValues[name] = value
					end
				end
			end
		end
		table.sort (attrNames, function (a, b)
			return a:lower () < b:lower ()
		end)
		for _, name in ipairs (attrNames) do
			if not byKey[name:lower ()] then
				local valueType = typeof (sampleValues[name])
				if valueType == "nil" then valueType = "string" end
				add ({
					Name = name,
					Class = className,
					Category = "Attributes",
					ValueType = valueType,
					Tags = {},
					Kind = "attribute",
				})
			end
		end
	end

	if hasHiddenPropertyApi () then
		local ok, names = pcall (function ()
			return gethiddenproperties (object)
		end)
		if ok and type (names) == "table" then
			for _, name in ipairs (names) do
				if type (name) == "string" then
					add ({
						Name = name,
						Class = className,
						Category = "Hidden properties",
						ValueType = "string",
						Tags = { ReadOnly = true },
						Kind = "hidden",
					})
				end
			end
		end
	else
		add ({
			Name = "Unavailable due to missing functions",
			Class = className,
			Category = "Hidden properties",
			ValueType = "string",
			Tags = { ReadOnly = true },
			Kind = "message",
		})
	end

	for _, prop in pairs (byKey) do
		prop.Unmapped = Dex.Reflect:GetCategoryOrder (prop.Category) >= 1000
		result[#result + 1] = prop
	end

	table.sort (result, function (a, b)
		if a.Unmapped ~= b.Unmapped then return a.Unmapped end
		local rankA = a.Unmapped and -1 or Dex.Reflect:GetCategoryOrder (a.Category)
		local rankB = b.Unmapped and -1 or Dex.Reflect:GetCategoryOrder (b.Category)
		if rankA ~= rankB then return rankA < rankB end
		if a.Category ~= b.Category then return a.Category < b.Category end
		return a.Name:lower () < b.Name:lower ()
	end)
	return result
end

function Properties:CreateComponentRow (parentProp, component, index, alternate)
	local row = U.Button (self.List, {
		Name = "Component" .. parentProp.Name .. "_" .. component.Name,
		BackgroundColor3 = alternate and Dex.Theme.Properties.RowAlt or Dex.Theme.Properties.Row,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 22),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 2,
	})
	local nameLabel = U.Label (row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (28, 0),
		Size = UDim2.new (0.5, -36, 1, 0),
		Font = Dex.Fonts.UI,
		Text = component.Name,
		TextColor3 = Dex.Theme.Properties.ValueMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	nameLabel.Active = false
	local valueCell = U.Button (row, {
		Name = "ValueCell",
		BackgroundTransparency = 1,
		Position = UDim2.new (0.5, 0, 0, 0),
		Size = UDim2.new (0.5, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	local valueLabel = U.Label (valueCell, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (8, 0),
		Size = UDim2.new (1, -16, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "",
		TextColor3 = Dex.Theme.Properties.Value,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})
	valueLabel.Active = false
	local meta = {
		Prop = parentProp,
		Component = component,
		Row = row,
		NameLabel = nameLabel,
		ValueCell = valueCell,
		ValueLabel = valueLabel,
		Alternate = alternate,
		Hovered = false,
	}
	self.RowMetas[#self.RowMetas + 1] = meta
	self.RowsByName[parentProp.Name .. "." .. component.Name] = meta
	valueCell.MouseButton1Click:Connect (function ()
		self.Window:Focus ()
		if self.Editing and self.Editing.PropName ~= parentProp.Name .. "." .. component.Name then
			self:FinishValueEdit (true)
		end
		self:StartValueEdit (meta)
	end)
	self:UpdateComponentValue (meta)
	return row
end

function Properties:UpdateComponentValue (meta)
	if not meta or not meta.ValueLabel then return end
	local value = self:GetCommonValue (meta.Prop)
	local ok, componentValue = pcall (function ()
		return meta.Component.Get (value)
	end)
	meta.ValueLabel.Text = ok and tostring (componentValue) or "?"
end

function Properties:ShowAddAttribute ()
	local window = self.AddAttributeWindow
	if not window or window.Destroyed then
		window = Dex:CreateWindow ({
			Name = "AddAttribute",
			Title = "Add Attribute",
			Size = UDim2.fromOffset (300, 220),
			Position = UDim2.fromOffset (420, 220),
			MinSize = Vector2.new (260, 200),
			ContentColor = Dex.Theme.Properties.Background,
			TitleBarColor3 = Dex.Theme.Properties.TitleBar,
			BorderColor3 = Dex.Theme.Properties.Border,
			TitleTextColor3 = Dex.Theme.Properties.TitleText,
			AccentTransparency = 1,
			ContentBuilder = function (content, win)
				local state = {
					Type = "string",
					ValueText = "",
					BoolValue = false,
					ColorValue = Color3.new (1, 1, 1),
					BrickValue = BrickColor.new ("White"),
				}
				win.AttributeState = state

				local function field (labelText, y, isButton)
					local label = U.Label (content, {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset (12, y),
						Size = UDim2.new (0, 70, 0, 22),
						Font = Dex.Fonts.UI,
						Text = labelText,
						TextColor3 = Dex.Theme.Properties.Name,
						TextSize = 12,
						ZIndex = 2,
					})
					label.Active = false
					local control
					if isButton then
						control = U.Button (content, {
							BackgroundColor3 = Dex.Theme.Properties.InputBackground,
							BorderSizePixel = 0,
							Position = UDim2.fromOffset (88, y),
							Size = UDim2.new (1, -100, 0, 24),
							Font = Dex.Fonts.UI,
							Text = state.Type,
							TextColor3 = Dex.Theme.Properties.Value,
							TextSize = 12,
							ZIndex = 2,
						})
					else
						control = U.Textbox (content, {
							BackgroundColor3 = Dex.Theme.Properties.InputBackground,
							BorderSizePixel = 0,
							Position = UDim2.fromOffset (88, y),
							Size = UDim2.new (1, -100, 0, 24),
							Font = Dex.Fonts.UI,
							Text = "",
							TextColor3 = Dex.Theme.Properties.Value,
							TextSize = 12,
							ClearTextOnFocus = false,
							ZIndex = 2,
						})
					end
					U.Corner (control, 3)
					U.Stroke (control, Dex.Theme.Properties.InputBorder, 1, 0)
					return control
				end

				local nameBox = field ("Name", 12, false)
				local typeButton = field ("Type", 44, true)
				win.AttributeNameBox = nameBox

				local valueLabel = U.Label (content, {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset (12, 76),
					Size = UDim2.new (0, 70, 0, 22),
					Font = Dex.Fonts.UI,
					Text = "Value",
					TextColor3 = Dex.Theme.Properties.Name,
					TextSize = 12,
					ZIndex = 2,
				})
				valueLabel.Active = false
				local valueHolder = U.Frame (content, {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset (88, 76),
					Size = UDim2.new (1, -100, 0, 24),
					ZIndex = 2,
				})
				win.AttributeValueHolder = valueHolder

				local function makeBox (placeholder)
					local box = U.Textbox (valueHolder, {
						BackgroundColor3 = Dex.Theme.Properties.InputBackground,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset (0, 0),
						Size = UDim2.new (1, 0, 1, 0),
						Font = Dex.Fonts.UI,
						Text = "",
						PlaceholderText = placeholder or "",
						PlaceholderColor3 = Dex.Theme.Properties.Placeholder,
						TextColor3 = Dex.Theme.Properties.Value,
						TextSize = 12,
						ClearTextOnFocus = false,
						ZIndex = 2,
					})
					U.Corner (box, 3)
					U.Stroke (box, Dex.Theme.Properties.InputBorder, 1, 0)
					box:GetPropertyChangedSignal ("Text"):Connect (function ()
						state.ValueText = box.Text
					end)
					return box
				end

				local function rebuildValueEditor ()
					for _, child in ipairs (valueHolder:GetChildren ()) do
						child:Destroy ()
					end
					if state.Type == "boolean" then
						local button = U.Button (valueHolder, {
							BackgroundColor3 = Dex.Theme.Properties.InputBackground,
							BorderSizePixel = 0,
							Position = UDim2.fromOffset (0, 0),
							Size = UDim2.new (1, 0, 1, 0),
							Font = Dex.Fonts.UIMedium,
							Text = state.BoolValue and "true" or "false",
							TextColor3 = state.BoolValue and Dex.Theme.Common.Success
								or Dex.Theme.Properties.ValueMuted,
							TextSize = 12,
							ZIndex = 2,
						})
						U.Corner (button, 3)
						U.Stroke (button, Dex.Theme.Properties.InputBorder, 1, 0)
						button.MouseButton1Click:Connect (function ()
							state.BoolValue = not state.BoolValue
							button.Text = state.BoolValue and "true" or "false"
							button.TextColor3 = state.BoolValue and Dex.Theme.Common.Success
								or Dex.Theme.Properties.ValueMuted
						end)
					elseif state.Type == "Color3" then
						local swatch = U.Button (valueHolder, {
							BackgroundColor3 = state.ColorValue,
							BorderSizePixel = 0,
							Position = UDim2.fromOffset (0, 0),
							Size = UDim2.fromOffset (28, 24),
							Text = "",
							ZIndex = 2,
						})
						U.Corner (swatch, 3)
						U.Stroke (swatch, Dex.Theme.Properties.InputBorder, 1, 0)
						local hexLabel = U.Label (valueHolder, {
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset (36, 0),
							Size = UDim2.new (1, -36, 1, 0),
							Font = Dex.Fonts.Mono,
							Text = "#" .. U.ColorHex (state.ColorValue),
							TextColor3 = Dex.Theme.Properties.Value,
							TextSize = 12,
							ZIndex = 2,
						})
						hexLabel.Active = false
						swatch.MouseButton1Click:Connect (function ()
							Dex:ShowColorPicker (state.ColorValue, U.MousePoint (), function (color)
								state.ColorValue = color
								swatch.BackgroundColor3 = color
								hexLabel.Text = "#" .. U.ColorHex (color)
							end)
						end)
					elseif state.Type == "BrickColor" then
						local button = U.Button (valueHolder, {
							BackgroundColor3 = state.BrickValue and state.BrickValue.Color
								or Dex.Theme.Properties.InputBackground,
							BorderSizePixel = 0,
							Position = UDim2.fromOffset (0, 0),
							Size = UDim2.new (1, 0, 1, 0),
							Font = Dex.Fonts.UI,
							Text = state.BrickValue and state.BrickValue.Name or "Select BrickColor...",
							TextColor3 = Dex.Theme.Common.White,
							TextSize = 12,
							ZIndex = 2,
						})
						U.Corner (button, 3)
						U.Stroke (button, Dex.Theme.Properties.InputBorder, 1, 0)
						button.MouseButton1Click:Connect (function ()
							local items = {}
							local colors = getBrickColors ()
							for _, color in ipairs (colors) do
								items[#items + 1] = {
									Text = color.Name,
									Value = color.Name,
									Selected = state.BrickValue and state.BrickValue.Name == color.Name,
									Callback = function ()
										state.BrickValue = color
										button.Text = color.Name
										button.BackgroundColor3 = color.Color
									end,
								}
							end
							Dex:ShowPicker ({
								Anchor = button,
								Items = items,
								Width = 240,
								MaxHeight = 360,
								Search = true,
								SearchPlaceholder = "BrickColor...",
								AutoFocus = true,
								OnSelect = function (name)
									local color = BrickColor.new (name)
									state.BrickValue = color
									button.Text = color.Name
									button.BackgroundColor3 = color.Color
								end,
							})
						end)
					else
						local placeholder = "Text"
						if state.Type == "number" then
							placeholder = "0"
						elseif state.Type == "Vector3" then
							placeholder = "X, Y, Z"
						elseif state.Type == "Vector2" then
							placeholder = "X, Y"
						end
						makeBox (placeholder)
					end
				end

				local function setType (typeName)
					state.Type = typeName
					typeButton.Text = typeName
					state.ValueText = ""
					rebuildValueEditor ()
				end

				local types = { "string", "number", "boolean", "Color3", "Vector3", "Vector2", "BrickColor" }
				typeButton.MouseButton1Click:Connect (function ()
					local items = {}
					for _, typeName in ipairs (types) do
						items[#items + 1] = {
							Text = typeName,
							Checked = state.Type == typeName,
							Callback = function ()
								setType (typeName)
							end,
						}
					end
					Dex:ShowMenu (items, U.MousePoint ())
				end)

				rebuildValueEditor ()

				local addButton = U.Button (content, {
					BackgroundColor3 = Dex.Theme.Common.Accent,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new (1, 1),
					Position = UDim2.new (1, -12, 1, -12),
					Size = UDim2.fromOffset (96, 28),
					Font = Dex.Fonts.UIMedium,
					Text = "Add",
					TextColor3 = Dex.Theme.Common.White,
					TextSize = 12,
					ZIndex = 2,
				})
				U.Corner (addButton, 3)
				addButton.MouseButton1Click:Connect (function ()
					local name = tostring (nameBox.Text or "")
					name = name:gsub ("^%s+", ""):gsub ("%s+$", "")
					if name == "" then
						Dex:Notify ("Enter an attribute name", "error")
						return
					end
					local value
					if state.Type == "boolean" then
						value = state.BoolValue
					elseif state.Type == "Color3" then
						value = state.ColorValue
					elseif state.Type == "BrickColor" then
						if not state.BrickValue then
							Dex:Notify ("Choose a BrickColor", "error")
							return
						end
						value = state.BrickValue
					else
						local ok, parsed = parseAttributeValue (state.Type, state.ValueText)
						if not ok then
							Dex:Notify (tostring (parsed), "error")
							return
						end
						value = parsed
					end
					local failures = 0
					for _, object in ipairs (self.Objects) do
						local applied, err = pcall (function ()
							object:SetAttribute (name, value)
						end)
						if not applied then failures = failures + 1 end
					end
					if failures > 0 then
						Dex:Notify ("Could not set " .. name .. " on " .. failures .. " object(s)", "error")
					else
						Dex:Notify ("Added attribute " .. name, "success")
						win:Hide ()
						self:Refresh (true)
					end
				end)
			end,
		})
		self.AddAttributeWindow = window
	end
	window:Show ()
	window:Focus ()
	return window
end

function Properties:CreateAddAttributeRow (index)
	local row = U.Button (self.List, {
		Name = "AddAttributeRow",
		BackgroundColor3 = Dex.Theme.Properties.Row,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 22),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 2,
	})
	local label = U.Label (row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (10, 0),
		Size = UDim2.new (1, -20, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "+  Add Attribute...",
		TextColor3 = Dex.Theme.Properties.ValueMuted,
		TextSize = 12,
		ZIndex = 3,
	})
	label.Active = false
	row.MouseEnter:Connect (function ()
		label.TextColor3 = Dex.Theme.Properties.Value
	end)
	row.MouseLeave:Connect (function ()
		label.TextColor3 = Dex.Theme.Properties.ValueMuted
	end)
	row.MouseButton1Click:Connect (function ()
		self.Window:Focus ()
		self:ShowAddAttribute ()
	end)
	return row
end

function Properties:Refresh (scrollTop)
	if not self.List or not self.List.Parent then return end
	if not self.Window or not self.Window.GUI or not self.Window.GUI.Parent then return end
	self:UpdateTitle ()

	if self.Editing then self:CancelEdit () end

	for _, child in ipairs (self.List:GetChildren ()) do
		if child:IsA ("GuiObject") then child:Destroy () end
	end
	self.RowMetas = {}
	self.RowsByName = {}

	if #self.Objects == 0 then
		self.EmptyLabel.Visible = true
		self.EmptyLabel.Text = "Select an object in the Explorer"
		self.FilterBar.Visible = false
		return
	end

	self.FilterBar.Visible = true
	local allProperties = self:GetPropertiesForPrimary ()
	local query = self.FilterText:lower ()
	local categoryFilter = self.CategoryFilter
	local filtered = {}

	for _, prop in ipairs (allProperties) do
		local categoryMatch = categoryFilter == nil or prop.Category == categoryFilter
		local nameMatch = query == "" or prop.Name:lower ():find (query, 1, true) ~= nil
		if categoryMatch and nameMatch then filtered[#filtered + 1] = prop end
	end

	if categoryFilter == nil or categoryFilter == "Attributes" then
		local addRow = {
			Name = "Add Attribute",
			Class = "",
			Category = "Attributes",
			ValueType = "AddAttribute",
			Tags = {},
			Kind = "addAttribute",
		}
		local lastAttribute = nil
		for index, prop in ipairs (filtered) do
			if prop.Category == "Attributes" then lastAttribute = index end
		end
		if lastAttribute then
			table.insert (filtered, lastAttribute + 1, addRow)
		else
			filtered[#filtered + 1] = addRow
		end
	end

	if #filtered == 0 then
		self.EmptyLabel.Visible = true
		self.EmptyLabel.Text = query ~= "" and "No matching properties" or "No properties available"
		return
	end

	self.EmptyLabel.Visible = false
	self.AllCategories = {}
	local categorySet = {}
	for _, prop in ipairs (allProperties) do
		if not categorySet[prop.Category] then
			categorySet[prop.Category] = true
			self.AllCategories[#self.AllCategories + 1] = prop.Category
		end
	end
	if not categorySet["Attributes"] then
		categorySet["Attributes"] = true
		self.AllCategories[#self.AllCategories + 1] = "Attributes"
	end
	table.sort (self.AllCategories, function (a, b)
		local rankA = Dex.Reflect:GetCategoryOrder (a)
		local rankB = Dex.Reflect:GetCategoryOrder (b)
		if rankA ~= rankB then return rankA < rankB end
		return a < b
	end)

	local layoutOrder = 1
	local currentCategory = nil
	local alternate = false
	local firstPropertyInCategory = true
	for _, prop in ipairs (filtered) do
		if prop.Category and prop.Category ~= currentCategory then
			currentCategory = prop.Category
			alternate = false
			firstPropertyInCategory = true
			self:CreateCategory (currentCategory, layoutOrder)
			layoutOrder = layoutOrder + 1
		end
		if not self.Collapsed[currentCategory] then
			if prop.Kind == "addAttribute" then
				self:CreateAddAttributeRow (layoutOrder)
				layoutOrder = layoutOrder + 1
				firstPropertyInCategory = false
			elseif prop.Kind == "message" then
				self:CreateMessageRow (prop.Name, layoutOrder)
				layoutOrder = layoutOrder + 1
				firstPropertyInCategory = false
			else
				self:CreatePropertyRow (prop, layoutOrder, alternate, not firstPropertyInCategory)
				layoutOrder = layoutOrder + 1
				alternate = not alternate
				firstPropertyInCategory = false

				local currentValue = self:GetCommonValue (prop)
				local components = self:GetComponents (prop, currentValue)
				if components and self.ExpandedProps[prop.Name] then
					for _, component in ipairs (components) do
						self:CreateComponentRow (prop, component, layoutOrder, alternate)
						layoutOrder = layoutOrder + 1
						alternate = not alternate
					end
				end
			end
		end
	end

	if scrollTop ~= false then
		task.defer (function ()
			if self.List then self.List.CanvasPosition = Vector2.new (0, 0) end
		end)
	end
	self:RefreshValueDisplays ()
	task.defer (function ()
		for _, meta in ipairs (self.RowMetas or {}) do
			self:ResizeRow (meta)
		end
	end)
end

function Properties:RefreshValues ()
	if #self.Objects == 0 or not self.Window or not self.Window.Visible then return end
	self:UpdateTitle ()
	self:RefreshValueDisplays ()
end

function Properties:OnSelectionChanged ()
	local objects = self:GetObjects ()
	self.Objects = objects
	self.SelectedName = nil
	self.ExpandedProps = {}
	self:Refresh (true)
end

function Properties:FocusFilter ()
	if self.FilterBox then
		self.Window:Focus ()
		self.FilterBox:CaptureFocus ()
	end
end

function Properties:ShowCategoryMenu ()
	local items = {
		{
			Text = "All Categories",
			Checked = self.CategoryFilter == nil,
			Callback = function ()
				self.CategoryFilter = nil
				self:Refresh (true)
			end,
		},
	}
	for _, category in ipairs (self.AllCategories or {}) do
		local captured = category
		items[#items + 1] = {
			Text = category,
			Checked = self.CategoryFilter == category,
			Callback = function ()
				self.CategoryFilter = captured
				self:Refresh (true)
			end,
		}
	end
	items[#items + 1] = { Separator = true }
	items[#items + 1] = {
		Text = "Freeze Properties",
		Checked = function ()
			return self.Frozen == true
		end,
		Callback = function ()
			self.Frozen = not self.Frozen
			if not self.Frozen then self:RefreshValues () end
		end,
	}
	items[#items + 1] = {
		Text = "Expand All Categories",
		Callback = function ()
			self.Collapsed = {}
			self:Refresh (false)
		end,
	}
	items[#items + 1] = {
		Text = "Collapse All Categories",
		Callback = function ()
			for _, category in ipairs (self.AllCategories or {}) do
				self.Collapsed[category] = true
			end
			self:Refresh (false)
		end,
	}
	items[#items + 1] = {
		Text = "Refresh Properties",
		Callback = function ()
			self:Refresh (false)
		end,
	}
	Dex:ShowMenu (items, U.MousePoint ())
end

function Properties:Build (content)
	self.Content = content

	local filterBar = U.Frame (content, {
		Name = "FilterBar",
		BackgroundColor3 = Dex.Theme.Properties.CategoryBackground,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (0, 0),
		Size = UDim2.new (1, 0, 0, 31),
		Visible = false,
		ZIndex = 2,
	})
	self.FilterBar = filterBar
	U.Frame (filterBar, {
		BackgroundColor3 = Dex.Theme.Properties.Border,
		BorderSizePixel = 0,
		Position = UDim2.new (0, 0, 1, -1),
		Size = UDim2.new (1, 0, 0, 1),
		ZIndex = 3,
	})

	local filterBox = U.Textbox (filterBar, {
		Name = "Filter",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (10, 0),
		Size = UDim2.new (1, -54, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "",
		PlaceholderText = "Filter Properties (Shift+Ctrl+P)",
		PlaceholderColor3 = Dex.Theme.Properties.Placeholder,
		TextColor3 = Dex.Theme.Properties.SearchText,
		TextSize = 13,
		ClearTextOnFocus = false,
		ZIndex = 3,
	})
	self.FilterBox = filterBox

	local buttonHolder = U.Frame (filterBar, {
		Name = "FilterButtons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -2, 0, 0),
		Size = UDim2.new (0, 46, 1, 0),
		ZIndex = 3,
	})
	local buttonLayout = U.List (buttonHolder, 2, true)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	self.FilterButtonsHolder = buttonHolder

	local clear = U.Button (buttonHolder, {
		Name = "ClearFilter",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (18, 18),
		LayoutOrder = 1,
		Text = "",
		Visible = false,
		ZIndex = 3,
	})
	U.DrawX (clear, 7, Dex.Theme.Properties.Placeholder)
	self.ClearFilterButton = clear
	function self:SetClearFilterButtonVisible (visible)
		if not self.ClearFilterButton then return end
		self.ClearFilterButton.Visible = visible == true
		self.ClearFilterButton.Parent = visible and self.FilterButtonsHolder or nil
	end
	clear.MouseEnter:Connect (function ()
		clear.BackgroundTransparency = 0
		clear.BackgroundColor3 = Dex.Theme.Properties.RowHover
	end)
	clear.MouseLeave:Connect (function ()
		clear.BackgroundTransparency = 1
	end)
	clear.MouseButton1Click:Connect (function ()
		self._SettingFilter = true
		filterBox.Text = ""
		self._SettingFilter = false
		self.FilterText = ""
		self:SetClearFilterButtonVisible (false)
		self:Refresh (true)
		filterBox:CaptureFocus ()
	end)

	local categoryButton = U.Button (buttonHolder, {
		Name = "Categories",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (22, 22),
		LayoutOrder = 2,
		Font = Dex.Fonts.UI,
		Text = "▾",
		TextColor3 = Dex.Theme.Properties.Placeholder,
		TextSize = 13,
		ZIndex = 3,
	})
	U.Corner (categoryButton, 3)
	categoryButton.MouseEnter:Connect (function ()
		categoryButton.BackgroundTransparency = 0
		categoryButton.BackgroundColor3 = Dex.Theme.Properties.RowHover
		categoryButton.TextColor3 = Dex.Theme.Properties.CategoryText
	end)
	categoryButton.MouseLeave:Connect (function ()
		categoryButton.BackgroundTransparency = 1
		categoryButton.TextColor3 = Dex.Theme.Properties.Placeholder
	end)
	categoryButton.MouseButton1Click:Connect (function ()
		self:ShowCategoryMenu ()
	end)
	Dex:AttachTooltip (categoryButton, "Filter by category")

	filterBox.Focused:Connect (function ()
		self.Window:Focus ()
	end)
	filterBox:GetPropertyChangedSignal ("Text"):Connect (function ()
		if self._SettingFilter then return end
		self.FilterText = filterBox.Text
		self:SetClearFilterButtonVisible (filterBox.Text ~= "")
		self._FilterToken = self._FilterToken + 1
		local token = self._FilterToken
		task.delay (0.10, function ()
			if token == self._FilterToken then self:Refresh (true) end
		end)
	end)

	local list = U.Scroll (content, {
		Name = "PropertyList",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (0, 31),
		Size = UDim2.new (1, 0, 1, -31),
		CanvasSize = UDim2.new (0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Dex.Theme.Properties.ScrollBar,
		ScrollBarImageTransparency = 0.15,
		ZIndex = 2,
	})
	self.List = list
	local layout = U.Create ("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new (0, 0),
		Parent = list,
	})
	local pad = U.Create ("UIPadding", {
		PaddingBottom = UDim.new (0, 8),
		Parent = list,
	})

	local empty = U.Label (content, {
		Name = "Empty",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (0, 31),
		Size = UDim2.new (1, 0, 1, -31),
		Font = Dex.Fonts.UI,
		Text = "Select an object in the Explorer",
		TextColor3 = Dex.Theme.Properties.Empty,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = true,
		ZIndex = 3,
		Active = false,
	})
	self.EmptyLabel = empty

	self.Window:OnShow (function ()
		self:Refresh (false)
	end)
	self.Window:OnResize (function ()
		task.defer (function ()
			self:Refresh (false)
		end)
	end)

	self.Objects = self:GetObjects ()
	self:Refresh (true)

	Dex:Track (Dex.SelectionChanged:Connect (function ()
		self:OnSelectionChanged ()
	end))

	Dex.Reflect:Load (function ()
		if self.Window and self.Window.GUI and self.Window.GUI.Parent and self.List and self.List.Parent then
			self:Refresh (false)
		end
	end)

	Dex:Track (Dex.ThemeChanged:Connect (function ()
		if self.Window and self.Window.Visible then self:Refresh (false) end
	end))
	Dex:Track (RunService.Heartbeat:Connect (function ()
		self._ValueRefreshAccumulator = (self._ValueRefreshAccumulator or 0) + 1
		if self._ValueRefreshAccumulator < (Dex.PerformanceMode and 90 or 24) then return end
		self._ValueRefreshAccumulator = 0
		if
			not self.Window
			or not self.Window.Visible
			or self.Editing
			or Dex._menuState
			or Dex._picker
			or self.Frozen
		then
			return
		end
		self:RefreshValues ()
	end))

	Dex:Track (UIS.InputBegan:Connect (function (input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local ctrl = UIS:IsKeyDown (Enum.KeyCode.LeftControl) or UIS:IsKeyDown (Enum.KeyCode.RightControl)
		local shift = UIS:IsKeyDown (Enum.KeyCode.LeftShift) or UIS:IsKeyDown (Enum.KeyCode.RightShift)

		if ctrl and shift and input.KeyCode == Enum.KeyCode.P then
			if self.Window and self.Window.Visible then self:FocusFilter () end
			return
		end
		if Dex.ActiveWindow ~= self.Window or not self.Window.Visible then return end
		if UIS:GetFocusedTextBox () then return end
		if input.KeyCode == Enum.KeyCode.Escape and self.Editing then self:CancelEdit () end
	end))
end

function Properties:Create ()
	local window = Dex:CreateWindow ({
		Name = "Properties",
		Title = "Properties",
		Size = UDim2.fromOffset (340, 560),
		Position = UDim2.fromOffset (900, 60),
		MinSize = Vector2.new (260, 200),
		ContentColor = Dex.Theme.Properties.Background,
		TitleBarColor3 = Dex.Theme.Properties.TitleBar,
		BorderColor3 = Dex.Theme.Properties.Border,
		TitleTextColor3 = Dex.Theme.Properties.TitleText,
		AccentTransparency = 1,
		ContentBuilder = function (content, window)
			self.Window = window
			self:Build (content)
		end,
	})
	self.Window = window
	return window
end
