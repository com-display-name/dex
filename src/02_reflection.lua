Dex.Reflect = {
	Classes = {},
	Enums = {},
	Ready = false,
	Loading = false,
	Failed = false,
	Callbacks = {},
	Source = nil,
	FetchUnavailable = false,
}

local Reflect = Dex.Reflect

local apiCache = nil

local function buildCategoryOrder (ordered)
	local function insertAbove (list, item, aboveItem)
		local from = table.find (list, item)
		if not from then return end
		table.remove (list, from)
		local to = table.find (list, aboveItem)
		if not to then
			table.insert (list, from, item)
			return
		end
		table.insert (list, to, item)
	end

	insertAbove (ordered, "Behavior", "Tuning")
	insertAbove (ordered, "Appearance", "Data")
	insertAbove (ordered, "Attachments", "Axes")
	insertAbove (ordered, "Cylinder", "Slider")
	insertAbove (ordered, "Localization", "Tuning")
	insertAbove (ordered, "Surface", "Motion")
	insertAbove (ordered, "Surface Inputs", "Surface")
	insertAbove (ordered, "Part", "Surface Inputs")
	insertAbove (ordered, "Assembly", "Surface Inputs")
	insertAbove (ordered, "Character", "Controls")
	ordered[#ordered + 1] = "Unscriptable"
	ordered[#ordered + 1] = "Attributes"
	ordered[#ordered + 1] = "Hidden properties"

	local map = {}
	for index, name in ipairs (ordered) do
		if map[name] == nil then map[name] = index end
	end
	return map
end

local FallbackCategoryOrder = buildCategoryOrder ({
	"Appearance",
	"Data",
	"Behavior",
	"State",
	"Transform",
	"Part",
	"Assembly",
	"Surface Inputs",
	"Surface",
	"Color",
	"Lighting",
	"Effects",
	"Emission",
	"Playback",
	"Sound",
	"Emitter",
	"Camera",
	"Controls",
	"Character",
	"Movement",
	"Animation",
	"Attachments",
	"Axes",
	"Slider",
	"Tuning",
	"Localization",
	"Size",
	"Position",
	"Image",
	"Text",
	"Display",
	"Layout",
	"Scrolling",
	"Video",
	"Accessibility",
	"Mapping",
	"Range",
	"Limits",
	"Goals",
	"Motion",
	"Physical",
	"Material Overrides",
	"Tags",
	"Attributes",
	"Other",
})
local CategoryOrder = FallbackCategoryOrder

local function hasFetchFunction ()
	local ok, gameHttpGet = pcall (function ()
		return game.HttpGet
	end)
	if ok and typeof (gameHttpGet) == "function" then return true end

	local request = nil
	if type (syn) == "table" then request = syn.request or syn.HttpRequest end
	request = request or rawget (_G, "http_request") or rawget (_G, "request")
	return type (request) == "function"
end

local function httpGet (url)
	Reflect.FetchUnavailable = not hasFetchFunction ()

	local ok, body = pcall (function ()
		return game:HttpGet (url, true)
	end)
	if ok and type (body) == "string" and #body > 32 then return body end

	local request = nil
	if type (syn) == "table" then request = syn.request or syn.HttpRequest end
	request = request or rawget (_G, "http_request") or rawget (_G, "request")
	if request then
		local requestOk, response = pcall (request, {
			Url = url,
			Method = "GET",
		})
		if requestOk and type (response) == "table" and type (response.Body) == "string" then return response.Body end
	end

	return nil
end

local function decodeJson (body)
	local ok, decoded = pcall (function ()
		return HttpService:JSONDecode (body)
	end)
	return ok and decoded or nil
end

local function getVersionUpload ()
	local ok, version = false, nil
	if Dex.HasCoreAccess then
		ok, version = pcall (function ()
			return Version ()
		end)
	end
	if ok and type (version) == "string" then
		local match = version:match ("(version%-[%w%.]+)")
		if match then return match end
	end

	local body = httpGet ("https://clientsettings.roblox.com/v2/client-version/WindowsPlayer/channel/LIVE")
	if body then
		local json = decodeJson (body)
		if json and type (json.clientVersionUpload) == "string" then return json.clientVersionUpload end
	end

	return nil
end

local function parseApi (raw)
	local api = decodeJson (raw)
	if not api or type (api.Classes) ~= "table" then return nil end

	local classes = {}
	local enums = {}
	local categoryList = {}
	local seenCategory = {}

	for _, class in ipairs (api.Classes) do
		local tags = {}
		for _, tag in ipairs (class.Tags or {}) do
			tags[tag] = true
		end

		local parsedClass = {
			Name = class.Name,
			Superclass = class.Superclass,
			Tags = tags,
			Props = {},
		}

		for _, member in ipairs (class.Members or {}) do
			if member.MemberType == "Property" then
				local memberTags = {}
				for _, tag in ipairs (member.Tags or {}) do
					memberTags[tag] = true
				end

				local security = member.Security
				if type (security) == "table" then
					local write = security.Write
					if
						write == "PluginSecurity"
						or write == "RobloxScriptSecurity"
						or write == "RobloxSecurity"
						or write == "Internal"
					then
						memberTags.ReadOnly = true
					end
				end
				local category = (member.Category or "Data"):match ("^%s*(.-)%s*$")
				if category == "" then category = "Data" end
				if not seenCategory[category] then
					seenCategory[category] = true
					categoryList[#categoryList + 1] = category
				end
				local prop = {
					Name = member.Name,
					Class = class.Name,
					Category = category,
					ValueType = member.ValueType and member.ValueType.Name or "string",
					Tags = memberTags,
				}
				parsedClass.Props[prop.Name] = prop
			end
		end

		classes[class.Name] = parsedClass
	end

	for _, enum in ipairs (api.Enums or {}) do
		local parsedEnum = {
			Name = enum.Name,
			Items = {},
		}
		for _, item in ipairs (enum.Items or {}) do
			local parsedItem = {
				Name = item.Name,
				Value = item.Value,
			}
			parsedEnum.Items[#parsedEnum.Items + 1] = parsedItem
		end
		table.sort (parsedEnum.Items, function (a, b)
			return a.Value < b.Value
		end)
		enums[enum.Name] = parsedEnum
	end

	return {
		Classes = classes,
		Enums = enums,
		CategoryOrder = buildCategoryOrder (categoryList),
	}
end

local function notifyCallbacks (success)
	local callbacks = Reflect.Callbacks
	Reflect.Callbacks = {}
	for _, callback in ipairs (callbacks) do
		task.spawn (callback, success)
	end
end

function Reflect:Wait ()
	while self.Loading and not self.Ready do
		task.wait ()
	end
	return self.Ready and not self.Failed
end

function Reflect:Load (callback)
	if type (callback) == "function" then
		if self.Ready then
			task.spawn (callback, not self.Failed)
			return not self.Failed
		end
		self.Callbacks[#self.Callbacks + 1] = callback
	end

	if self.Ready then return not self.Failed end
	if self.Loading then
		self:Wait ()
		return not self.Failed
	end

	self.Loading = true

	local cache = apiCache
	if type (cache) == "table" and type (cache.Classes) == "table" and next (cache.Classes) then
		self.Classes = cache.Classes
		self.Enums = cache.Enums or {}
		CategoryOrder = type (cache.CategoryOrder) == "table" and cache.CategoryOrder or FallbackCategoryOrder
		self.Ready = true
		self.Failed = false
		self.Source = "cache"
		self.Loading = false
		notifyCallbacks (true)
		return true
	end

	local versionUpload = getVersionUpload ()
	local raw = nil
	local source = nil

	if versionUpload then
		raw = httpGet ("https://setup.rbxcdn.com/" .. versionUpload .. "-API-Dump.json")
		source = "Roblox API"
		if not raw then raw = httpGet ("http://setup.roblox.com/" .. versionUpload .. "-API-Dump.json") end
	end

	if not raw then
		raw = httpGet ("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json")
		source = "Client Tracker"
	end

	local parseOk, parsed = false, nil
	if raw then parseOk, parsed = pcall (parseApi, raw) end
	if parseOk and type (parsed) == "table" and type (parsed.Classes) == "table" and next (parsed.Classes) then
		self.Classes = parsed.Classes
		self.Enums = parsed.Enums
		CategoryOrder = parsed.CategoryOrder or FallbackCategoryOrder
		self.Ready = true
		self.Failed = false
		self.Source = source
		apiCache = parsed
	else
		self.Ready = true
		self.Failed = true
		self.Source = nil
	end

	self.Loading = false
	notifyCallbacks (not self.Failed)
	return not self.Failed
end

function Reflect:GetEnumItems (enumName, valueType)
	local name = valueType or enumName
	local enum = self.Enums[name]
	if not enum then return nil end
	return enum.Items
end

local ExtraProps = {
	Explosion = { "DestroyJointRadius" },
	Player = { "CanLoadCharacter" },
	VideoFrame = { "PlaybackSpeed" },
}

local IgnoredProps = {
	RobloxLocked = true,
	Capabilities = true,
	DataCost = true,
	UniqueId = true,
}

local function categoryRank (category)
	return CategoryOrder[category] or 1000
end

function Reflect:GetProperties (className)
	local result = {}
	local byKey = {}

	local function score (prop)
		if prop.Tags and prop.Tags.Deprecated then return 0 end
		return prop.Name:sub (1, 1):match ("%u") and 2 or 1
	end

	local function add (prop)
		local key = prop.Name:lower ()
		if key == "parent" or key == "classname" or IgnoredProps[prop.Name] then return end
		local existing = byKey[key]
		if not existing then
			byKey[key] = prop
		elseif existing.Name ~= prop.Name and score (prop) > score (existing) then
			byKey[key] = prop
		end
	end

	local class = self.Classes[className]
	local guard = 0
	while class and guard < 40 do
		for _, prop in pairs (class.Props) do
			add (prop)
		end
		class = self.Classes[class.Superclass]
		guard = guard + 1
	end

	for _, name in ipairs (ExtraProps[className] or {}) do
		add ({
			Name = name,
			Class = className,
			Category = "Data",
			ValueType = "string",
			Tags = {},
		})
	end

	for _, prop in pairs (byKey) do
		result[#result + 1] = prop
	end
	return result
end

function Reflect:GetCategoryOrder (category)
	return categoryRank (category)
end
