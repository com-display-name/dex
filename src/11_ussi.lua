local function loadUniversalSaveInstance ()
	local U = Dex.Utils

	local function StringFind (s, pattern, init)
		return string.find (s, pattern, init, true)
	end

	local function ArrayToDict (t, hydridMode, valueOverride, typeStrict)
		local tmp = {}

		if hydridMode then
			for any1, any2 in t do
				if type (any1) == "number" then
					tmp[any2] = valueOverride or true
				elseif type (any2) == "table" then
					tmp[any1] = ArrayToDict (any2, hydridMode, valueOverride, typeStrict)
				else
					tmp[any1] = any2
				end
			end
		else
			for _, key in t do
				if not typeStrict or typeStrict and type (key) == typeStrict then tmp[key] = true end
			end
		end

		return tmp
	end

	local GlobalContainer = {
		gethiddenproperty = gethiddenproperty,
		getnilinstances = getnilinstances,
		getscriptbytecode = getscriptbytecode,
		protectgui = (type (syn) == "table" and syn.protect_gui) or protect_gui,
		base64encode = (type (crypt) == "table" and crypt.base64encode) or base64encode,
	}
	do
		local ok, finder, container = pcall (function ()
			local filename = "UniversalMethodFinder"
			local loaded = loadstring (
				game:HttpGet ("https://raw.githubusercontent.com/luau/SomeHub/main/" .. filename .. ".luau", true),
				filename
			)
			if not loaded then return nil end
			return loaded ()
		end)
		if ok and type (finder) == "function" then
			if type (container) == "table" then
				for key, value in pairs (GlobalContainer) do
					if container[key] == nil then container[key] = value end
				end
				GlobalContainer = container
			end
			pcall (finder, {
				base64encode = "local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,\"encode\")and(c(b,\"base64\")or c(string.lower(tostring(a[2])),\"base64\"))",
				gethiddenproperty = "string.find(...,\"get\",nil,true) and string.find(...,\"h\",nil,true) and string.find(...,\"prop\",nil,true) and string.sub(...,#...) ~= \"s\"",
				gethui = "string.find(...,\"get\",nil,true) and string.find(...,\"h\",nil,true) and string.find(...,\"ui\",nil,true)",
				getnilinstances = "string.find(...,\"nil\",nil,true) and string.find(...,\"get\",nil,true) and string.sub(...,#...) == \"s\"",
				getscriptbytecode = "string.find(...,\"get\",nil,true) and string.find(...,\"script\",nil,true) and string.find(...,\"bytecode\",nil,true)",
				protectgui = "string.find(...,\"protect\",nil,true) and string.find(...,\"ui\",nil,true) and not string.find(...,\"un\",nil,true)",
			}, true, 10)
		end
	end

	local IdentifyExecutor = identifyexecutor or getexecutorname or whatexecutor

	local ExecutorName = IdentifyExecutor and IdentifyExecutor () or ""

	local gethiddenproperty = GlobalContainer.gethiddenproperty

	local appendfile = appendfile
	local isfile = isfile
	local readfile = readfile
	local writefile = writefile

	local getscriptbytecode = GlobalContainer.getscriptbytecode
	local base64encode = GlobalContainer.base64encode

	local service = setmetatable ({}, {
		__index = function (self, serviceName)
			local o, s = pcall (U.Create, serviceName)
			local Service = o and s
				or game:GetService (serviceName)
				or settings ():GetService (serviceName)
				or UserSettings ():GetService (serviceName)

			if Service then self[serviceName] = Service end
			return Service
		end,
	})

	local SharedStringIdentifier = 1e15
	local SharedStrings = setmetatable ({}, {
		__index = function (self, str)
			local identifier = base64encode (tostring (SharedStringIdentifier))
			SharedStringIdentifier += 1

			self[str] = identifier
			return identifier
		end,
	})

	local InheritedProperties = {}
	local DefaultInstances = {}
	local referents, RefSize = {}, 0

	local function GetRef (instance)
		local ref = referents[instance]
		if not ref then
			ref = RefSize
			referents[instance] = ref
			RefSize += 1
		end
		return ref
	end

	local function index (self, IndexName)
		return self[IndexName]
	end

	local FullVersion

	if not pcall (function ()
		FullVersion = version ()
	end) then
		if not pcall (function ()
			FullVersion = settings ():GetService ("DebugSettings").RobloxVersion
		end) then
			if not pcall (function ()
				FullVersion = service.RunService:GetRobloxVersion ()
			end) then
				FullVersion = "UNKNOWN"
			end
		end
	end

	local ClientVersion = tonumber (string.match (FullVersion, "%d+%.(%d+)")) or 9e9

	local CframeRotationIds = {
		["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x02,
		["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x03,
		["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x05,
		["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x06,
		["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x07,
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x09,
		["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x0a,
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x0c,
		["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0d,
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0e,
		["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x10,
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = 0x11,
		["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x14,
		["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = 0x15,
		["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x17,
		["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = 0x18,
		["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x19,
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x1b,
		["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x1c,
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x1e,
		["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x1f,
		["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x20,
		["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x22,
		["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = 0x23,
	}
	local rotationBuffer = buffer.create (36)

	local AttrTypeIds = {
		string = 0x02,
		boolean = 0x03,
		int32 = 0x04,

		number = 0x06,

		UDim = 0x09,
		UDim2 = 0x0A,
		Ray = 0x0B,
		Faces = 0x0C,
		Axes = 0x0D,
		BrickColor = 0x0E,
		Color3 = 0x0F,
		Vector2 = 0x10,
		Vector3 = 0x11,
		Vector2int16 = 0x12,
		Vector3int16 = 0x13,
		CFrame = 0x14,
		EnumItem = 0x15,

		NumberSequence = 0x17,
		NumberSequenceKeypoint = 0x18,
		ColorSequence = 0x19,
		ColorSequenceKeypoint = 0x1A,
		NumberRange = 0x1B,
		Rect = 0x1C,
		PhysicalProperties = 0x1D,

		Region3 = 0x1F,
		Region3int16 = 0x20,
		Font = 0x21,
		SecurityCapabilities = 0x22,
		Path2DControlPoint = 0x23,
		TweenInfo = 0x24,
	}

	local BaseCapabilities
	pcall (function ()
		BaseCapabilities = SecurityCapabilities.new ()
	end)
	local CapabilityBits = {
		Plugin = 2 ^ 0,
		LocalUser = 2 ^ 1,
		WritePlayer = 2 ^ 2,
		RobloxScript = 2 ^ 3,
		RobloxEngine = 2 ^ 4,
		NotAccessible = 2 ^ 5,

		RunClientScript = 2 ^ 8,
		RunServerScript = 2 ^ 9,
		Unknown = 2 ^ 10,
		AccessOutsideWrite = 2 ^ 11,

		Unassigned = 2 ^ 15,
		LoadUnownedAsset = 2 ^ 16,
		LoadString = 2 ^ 17,
		ScriptGlobals = 2 ^ 18,
		CreateInstances = 2 ^ 19,
		Basic = 2 ^ 20,
		Audio = 2 ^ 21,
		DataStore = 2 ^ 22,
		Network = 2 ^ 23,
		Physics = 2 ^ 24,
		UI = 2 ^ 25,
		CSG = 2 ^ 26,
		Chat = 2 ^ 27,
		Animation = 2 ^ 28,
		AvatarAppearance = 2 ^ 29,
		Input = 2 ^ 30,
		Environment = 2 ^ 31,
		RemoteEvent = 2 ^ 32,
		LegacySound = 2 ^ 33,
		Players = 2 ^ 34,
		CapabilityControl = 2 ^ 35,
		AssetRead = 2 ^ 36,
		AssetManagement = 2 ^ 37,
		DynamicGeneration = 2 ^ 38,
		PlatformAvatarEditing = 2 ^ 39,
		AssetCreateUpdate = 2 ^ 40,
		Capture = 2 ^ 41,
		SensitiveInput = 2 ^ 42,
		Monetization = 2 ^ 43,
		LoadOwnedAsset = 2 ^ 44,
		Social = 2 ^ 45,
		ServerCommunication = 2 ^ 46,
		Logging = 2 ^ 47,
		PromptExternalPurchase = 2 ^ 48,
		Groups = 2 ^ 49,
		Teleport = 2 ^ 50,
		Consequences = 2 ^ 51,
		Material = 2 ^ 52,
		AvatarBehavior = 2 ^ 53,

		RemoteCommand = 2 ^ 59,
		InternalTest = 2 ^ 60,
		PluginOrOpenCloud = 2 ^ 61,
		Assistant = 2 ^ 62,
		Restricted = 2 ^ 63,
	}

	local function CountCapabilityBits (raw)
		local result = 0
		for _, flag in string.split (tostring (raw), " | ") do
			local bit = CapabilityBits[flag]
			if bit then
				result += bit
			end
		end
		return result
	end

	local function CountBits (...)
		local Value = 0

		for i, bit in { ... } do
			if bit then
				Value += 2 ^ (i - 1)
			end
		end

		return Value
	end

	local BinaryDescriptors
	BinaryDescriptors = {
		PackMultiple = function (descriptor, value1, value2, value3)
			local buf1, size1 = descriptor (value1)
			local buf2, size2 = descriptor (value2)

			local len = size1 + size2
			local buf3, size3

			if value3 ~= nil then
				buf3, size3 = descriptor (value3)
				len += size3
			end

			local b = buffer.create (len)

			buffer.copy (b, 0, buf1)
			buffer.copy (b, size1, buf2)

			if value3 ~= nil then buffer.copy (b, size1 + size2, buf3) end

			return b, len
		end,
		ConstructSequence = function (KeypointHandler, keypointSize)
			return function (raw)
				local Keypoints = raw.Keypoints
				local KeypointsN = #Keypoints

				local len = 4 + keypointSize * KeypointsN
				local b = buffer.create (len)

				buffer.writeu32 (b, 0, KeypointsN)

				local offset = 4
				for _, keypoint in Keypoints do
					KeypointHandler (keypoint, b, offset)
					offset += keypointSize
				end

				return b, len
			end
		end,
		WriteI64Le = function (b, offset, raw)
			local low = bit32.band (raw, 0xFFFFFFFF)
			local high = (raw - low) / 0x100000000

			buffer.writei32 (b, offset, low)
			buffer.writei32 (b, offset + 4, high)
		end,
		PackF32 = nil,
		PackI16 = nil,
		ConstructPacker = function (float)
			local writeFunc = float and buffer.writef32 or buffer.writei16
			local elementSize = float and 4 or 2

			return function (X, Y, Z)
				local len = Z and (elementSize * 3) or (elementSize * 2)
				local b = buffer.create (len)

				writeFunc (b, 0, X)
				writeFunc (b, elementSize, Y)
				if Z then writeFunc (b, elementSize * 2, Z) end

				return b, len
			end
		end,

		["string"] = function (raw)
			local RawLen = #raw
			local len = 4 + RawLen

			local b = buffer.create (len)

			buffer.writeu32 (b, 0, RawLen)
			buffer.writestring (b, 4, raw)

			return b, len
		end,
		["boolean"] = function (raw)
			local b = buffer.create (1)

			buffer.writeu8 (b, 0, raw and 1 or 0)

			return b, 1
		end,
		["number"] = function (raw)
			local b = buffer.create (8)

			buffer.writef64 (b, 0, raw)

			return b, 8
		end,
		["UDim"] = function (raw)
			local b = buffer.create (8)

			buffer.writef32 (b, 0, raw.Scale)
			buffer.writei32 (b, 4, raw.Offset)

			return b, 8
		end,
		["UDim2"] = function (raw)
			return BinaryDescriptors.PackMultiple (BinaryDescriptors["UDim"], raw.X, raw.Y)
		end,
		["Ray"] = function (raw)
			return BinaryDescriptors.PackMultiple (BinaryDescriptors["Vector3"], raw.Origin, raw.Direction)
		end,
		["Faces"] = function (raw)
			local b = buffer.create (4)

			buffer.writeu32 (b, 0, CountBits (raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front))

			return b, 4
		end,
		["Axes"] = function (raw)
			local b = buffer.create (4)

			buffer.writeu32 (b, 0, CountBits (raw.X, raw.Y, raw.Z))

			return b, 4
		end,
		["BrickColor"] = function (raw)
			local b = buffer.create (4)

			buffer.writeu32 (b, 0, raw.Number)

			return b, 4
		end,
		["Color3"] = function (raw)
			return BinaryDescriptors.PackF32 (raw.R, raw.G, raw.B)
		end,
		["Vector2"] = function (raw)
			return BinaryDescriptors.PackF32 (raw.X, raw.Y)
		end,
		["Vector3"] = function (raw)
			return BinaryDescriptors.PackF32 (raw.X, raw.Y, raw.Z)
		end,
		["Vector2int16"] = function (raw)
			return BinaryDescriptors.PackI16 (raw.X, raw.Y)
		end,
		["Vector3int16"] = function (raw)
			return BinaryDescriptors.PackI16 (raw.X, raw.Y, raw.Z)
		end,
		["CFrame"] = function (raw)
			local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents ()

			buffer.writef32 (rotationBuffer, 0, R00)
			buffer.writef32 (rotationBuffer, 4, R01)
			buffer.writef32 (rotationBuffer, 8, R02)
			buffer.writef32 (rotationBuffer, 12, R10)
			buffer.writef32 (rotationBuffer, 16, R11)
			buffer.writef32 (rotationBuffer, 20, R12)
			buffer.writef32 (rotationBuffer, 24, R20)
			buffer.writef32 (rotationBuffer, 28, R21)
			buffer.writef32 (rotationBuffer, 32, R22)

			local RotationID = CframeRotationIds[buffer.tostring (rotationBuffer)]

			local len = RotationID and 13 or 49
			local b = buffer.create (len)

			local PackF32 = BinaryDescriptors.PackF32
			local position = PackF32 (X, Y, Z)
			buffer.copy (b, 0, position)

			if RotationID then
				buffer.writeu8 (b, 12, RotationID)
			else
				buffer.writeu8 (b, 12, 0x0)

				local xBasis = PackF32 (R00, R01, R02)
				buffer.copy (b, 13, xBasis)
				local yBasis = PackF32 (R10, R11, R12)
				buffer.copy (b, 13 + 12, yBasis)
				local zBasis = PackF32 (R20, R21, R22)
				buffer.copy (b, 13 + 24, zBasis)
			end

			return b, len
		end,
		["EnumItem"] = function (raw)
			local b_Name, Name_size = BinaryDescriptors["string"] (tostring (raw.EnumType))

			local len = Name_size + 4
			local b = buffer.create (len)

			buffer.copy (b, 0, b_Name)
			buffer.writeu32 (b, Name_size, raw.Value)

			return b, len
		end,
		["NumberSequence"] = nil,
		["NumberSequenceKeypoint"] = function (keypoint, b, offset)
			if not b then return BinaryDescriptors.PackF32 (keypoint.Envelope, keypoint.Time, keypoint.Value) end

			buffer.writef32 (b, offset, keypoint.Envelope)
			offset += 4
			buffer.writef32 (b, offset, keypoint.Time)
			offset += 4
			buffer.writef32 (b, offset, keypoint.Value)
		end,
		["ColorSequence"] = nil,
		["ColorSequenceKeypoint"] = function (keypoint, b, offset)
			local Value = BinaryDescriptors["Color3"] (keypoint.Value)

			if not b then
				b = buffer.create (20)
				offset = 0
			end

			buffer.writef32 (b, offset, 0)
			offset += 4
			buffer.writef32 (b, offset, keypoint.Time)
			offset += 4
			buffer.copy (b, offset, Value)

			return b, 20
		end,
		["NumberRange"] = function (raw)
			return BinaryDescriptors.PackF32 (raw.Min, raw.Max)
		end,
		["Rect"] = function (raw)
			return BinaryDescriptors.PackMultiple (BinaryDescriptors["Vector2"], raw.Min, raw.Max)
		end,
		["PhysicalProperties"] = function (raw)
			local len = 1
			if raw then
				len += 24
			end
			local b = buffer.create (len)

			buffer.writeu8 (b, 0, raw and 3 or 0)

			if raw then
				buffer.writef32 (b, 1, raw.Density)
				buffer.writef32 (b, 5, raw.Friction)
				buffer.writef32 (b, 9, raw.Elasticity)
				buffer.writef32 (b, 13, raw.FrictionWeight)
				buffer.writef32 (b, 17, raw.ElasticityWeight)
				buffer.writef32 (b, 21, raw.AcousticAbsorption)
			end

			return b, len
		end,
		["Region3"] = function (raw)
			local Translation = raw.CFrame.Position
			local HalfSize = raw.Size * 0.5

			return BinaryDescriptors.PackMultiple (
				BinaryDescriptors["Vector3"],
				Translation - HalfSize,
				Translation + HalfSize
			)
		end,
		["Region3int16"] = function (raw)
			return BinaryDescriptors.PackMultiple (BinaryDescriptors["Vector3int16"], raw.Min, raw.Max)
		end,
		["Font"] = function (raw)
			local StringDescriptor = BinaryDescriptors["string"]

			local b_Family, Family_size = StringDescriptor (raw.Family)
			local b_CachedFaceId, CachedFaceId_size = StringDescriptor ("")

			local len = 3 + Family_size + CachedFaceId_size
			local b = buffer.create (len)

			local OkW, weight = pcall (index, raw, "Weight")
			local OkS, style = pcall (index, raw, "Style")

			buffer.writeu16 (b, 0, OkW and weight.Value or 0)
			buffer.writeu8 (b, 2, OkS and style.Value or 0)

			buffer.copy (b, 3, b_Family)
			buffer.copy (b, 3 + Family_size, b_CachedFaceId)

			return b, len
		end,
		["SecurityCapabilities"] = function (raw)
			local b = buffer.create (8)

			if raw == BaseCapabilities then return b, 8 end

			BinaryDescriptors.WriteI64Le (b, 0, CountCapabilityBits (raw))

			return b, 8
		end,
		["Path2DControlPoint"] = function (raw)
			return BinaryDescriptors.PackMultiple (
				BinaryDescriptors["UDim2"],
				raw.Position,
				raw.LeftTangent,
				raw.RightTangent
			)
		end,
		["TweenInfo"] = function (raw)
			local b = buffer.create (21)

			buffer.writef32 (b, 0, raw.Time)
			buffer.writef32 (b, 4, raw.DelayTime)
			buffer.writei32 (b, 8, raw.RepeatCount)
			buffer.writeu32 (b, 12, raw.EasingStyle.Value)
			buffer.writeu32 (b, 16, raw.EasingDirection.Value)
			buffer.writeu8 (b, 20, raw.Reverses and 1 or 0)

			return b, 21
		end,
	}

	do
		BinaryDescriptors["NumberSequence"] =
			BinaryDescriptors.ConstructSequence (BinaryDescriptors["NumberSequenceKeypoint"], 12)

		BinaryDescriptors["ColorSequence"] =
			BinaryDescriptors.ConstructSequence (BinaryDescriptors["ColorSequenceKeypoint"], 20)
	end

	do
		BinaryDescriptors.PackF32 = BinaryDescriptors.ConstructPacker (true)

		BinaryDescriptors.PackI16 = BinaryDescriptors.ConstructPacker ()
	end


	local Escapes = {
		["&"] = "&amp;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		["\""] = "&#34;",
		["'"] = "&#39;",
		["\0"] = "",
	}

	for rangeStart, rangeEnd in string.gmatch ("[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]", "(.)%-(.)") do
		for charCode = string.byte (rangeStart), string.byte (rangeEnd) do
			Escapes[string.char (charCode)] = "&#" .. charCode .. ";"
		end
	end

	local XmlDescriptors
	XmlDescriptors = {
		__CDATA = function (raw)
			return "<![CDATA[" .. raw .. "]]>"
		end,
		NormalizeNumber = function (raw)
			if raw ~= raw then
				return "NAN"
			elseif raw == math.huge then
				return "INF"
			elseif raw == -math.huge then
				return "-INF"
			end

			return raw
		end,
		NormalizeRange = function (raw)
			return raw ~= raw and "0" or raw
		end,
		__MINMAX = function (min, max, descriptor)
			return "<min>" .. descriptor (min) .. "</min><max>" .. descriptor (max) .. "</max>"
		end,
		__PROTECTEDSTRING = function (raw)
			return StringFind (raw, "]]>") and string.gsub (raw, "[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]", Escapes)
				or XmlDescriptors.__CDATA (raw)
		end,
		ConstructSequence = function (KeypointHandler)
			return function (raw)
				local sequence = ""

				for _, keypoint in raw.Keypoints do
					sequence ..= KeypointHandler (keypoint)
				end

				return sequence
			end
		end,
		__VECTOR = function (X, Y, Z)
			local Value = "<X>" .. X .. "</X><Y>" .. Y .. "</Y>"

			if Z then
				Value ..= "<Z>" .. Z .. "</Z>"
			end

			return Value
		end,

		Axes = function (raw)
			return "<axes>" .. CountBits (raw.X, raw.Y, raw.Z) .. "</axes>"
		end,

		BinaryString = function (raw)
			return raw == "" and "" or base64encode (raw)
		end,

		BrickColor = function (raw)
			return raw.Number
		end,
		CFrame = function (raw)
			local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents ()
			return XmlDescriptors.__VECTOR (X, Y, Z)
				.. "<R00>"
				.. R00
				.. "</R00><R01>"
				.. R01
				.. "</R01><R02>"
				.. R02
				.. "</R02><R10>"
				.. R10
				.. "</R10><R11>"
				.. R11
				.. "</R11><R12>"
				.. R12
				.. "</R12><R20>"
				.. R20
				.. "</R20><R21>"
				.. R21
				.. "</R21><R22>"
				.. R22
				.. "</R22>",
				"CoordinateFrame"
		end,

		Color3 = function (raw)
			local ok, r, g, b = pcall (function ()
				return raw.R, raw.G, raw.B
			end)
			if not ok or type (raw) == "table" then
				local source = type (raw) == "table" and raw or {}
				r, g, b = source.R, source.G, source.B
			end
			r, g, b = tonumber (r) or 0, tonumber (g) or 0, tonumber (b) or 0
			return "<R>" .. r .. "</R><G>" .. g .. "</G><B>" .. b .. "</B>"
		end,
		Color3uint8 = function (raw)
			if type (raw) ~= "userdata" then
				local source = type (raw) == "table" and raw or {}
				raw = {
					R = tonumber (source.R) or 0,
					G = tonumber (source.G) or tonumber (source.R) or 0,
					B = tonumber (source.B) or 0,
				}
			end

			local ok, r, g, b = pcall (function ()
				return raw.R, raw.G, raw.B
			end)
			if not ok then
				r, g, b = 0, 0, 0
			end
			r, g, b = tonumber (r) or 0, tonumber (g) or 0, tonumber (b) or 0

			return 0xFF000000 + (math.floor (r * 255) * 0x10000) + (math.floor (g * 255) * 0x100) + math.floor (b * 255)
		end,
		ColorSequence = nil,
		ColorSequenceKeypoint = function (keypoint)
			local NormalizeRange = XmlDescriptors.NormalizeRange

			local color3 = keypoint.Value

			return NormalizeRange (keypoint.Time)
				.. " "
				.. NormalizeRange (color3.R)
				.. " "
				.. NormalizeRange (color3.G)
				.. " "
				.. NormalizeRange (color3.B)
				.. " 0 "
		end,
		Content = function (raw)
			local SourceType = raw.SourceType
			return SourceType == Enum.ContentSourceType.None and "<null></null>"
				or SourceType == Enum.ContentSourceType.Uri and "<uri>" .. XmlDescriptors.string (raw.Uri) .. "</uri>"
				or SourceType == Enum.ContentSourceType.Object and "<Ref>" .. GetRef (raw.Object) .. "</Ref>"
				or SourceType == Enum.ContentSourceType.Opaque and "<Ref>" .. GetRef (raw.Opaque) .. "</Ref>"
		end,
		ContentId = function (raw)
			return raw == "" and "<null></null>" or "<url>" .. XmlDescriptors.string (raw) .. "</url>", "Content"
		end,
		CoordinateFrame = function (raw)
			return "<CFrame>" .. XmlDescriptors.CFrame (raw) .. "</CFrame>"
		end,

		EnumItem = function (raw)
			return raw.Value, "token"
		end,
		Faces = function (raw)
			return "<faces>"
				.. CountBits (raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front)
				.. "</faces>"
		end,
		Font = function (raw)
			local OkW, weight = pcall (index, raw, "Weight")
			local OkS, style = pcall (index, raw, "Style")

			return "<Family>"
				.. XmlDescriptors.ContentId (raw.Family)
				.. "</Family><Weight>"
				.. (OkW and XmlDescriptors.EnumItem (weight) or "")
				.. "</Weight><Style>"
				.. (OkS and style.Name or "")
				.. "</Style>"
		end,
		NetAssetRef = nil,
		NumberRange = function (raw)
			local NormalizeRange = XmlDescriptors.NormalizeRange

			return NormalizeRange (raw.Min) .. " " .. NormalizeRange (raw.Max)
		end,
		NumberSequence = nil,
		NumberSequenceKeypoint = function (keypoint)
			local NormalizeRange = XmlDescriptors.NormalizeRange

			return NormalizeRange (keypoint.Time)
				.. " "
				.. NormalizeRange (keypoint.Value)
				.. " "
				.. NormalizeRange (keypoint.Envelope)
				.. " "
		end,

		PhysicalProperties = function (raw)
			local CustomPhysics = "<CustomPhysics>"
				.. XmlDescriptors.bool (raw and true or false)
				.. "</CustomPhysics>"

			return raw
					and CustomPhysics .. "<Density>" .. raw.Density .. "</Density><Friction>" .. raw.Friction .. "</Friction><Elasticity>" .. raw.Elasticity .. "</Elasticity><FrictionWeight>" .. raw.FrictionWeight .. "</FrictionWeight><ElasticityWeight>" .. raw.ElasticityWeight .. "</ElasticityWeight><AcousticAbsorption>" .. raw.AcousticAbsorption .. "</AcousticAbsorption>"
				or CustomPhysics
		end,

		Ray = function (raw)
			local vector3 = XmlDescriptors.Vector3

			return "<origin>"
				.. vector3 (raw.Origin)
				.. "</origin><direction>"
				.. vector3 (raw.Direction)
				.. "</direction>"
		end,
		Rect = function (raw)
			return XmlDescriptors.__MINMAX (raw.Min, raw.Max, XmlDescriptors.Vector2), "Rect2D"
		end,
		Region3 = function (raw)
			local Translation = raw.CFrame.Position
			local HalfSize = raw.Size * 0.5

			return XmlDescriptors.__MINMAX (Translation - HalfSize, Translation + HalfSize, XmlDescriptors.Vector3)
		end,
		Region3int16 = function (raw)
			return XmlDescriptors.__MINMAX (raw.Min, raw.Max, XmlDescriptors.Vector3int16)
		end,

		SharedString = function (raw)
			return SharedStrings[XmlDescriptors.BinaryString (raw)]
		end,
		SecurityCapabilities = function (raw)
			if raw == BaseCapabilities then return 0 end

			return CountCapabilityBits (raw)
		end,

		UDim = function (raw)
			return "<S>" .. raw.Scale .. "</S><O>" .. raw.Offset .. "</O>"
		end,
		UDim2 = function (raw)
			local X, Y = raw.X, raw.Y

			return "<XS>"
				.. X.Scale
				.. "</XS><XO>"
				.. X.Offset
				.. "</XO><YS>"
				.. Y.Scale
				.. "</YS><YO>"
				.. Y.Offset
				.. "</YO>"
		end,

		UniqueId = function (raw)
			return string.gsub (raw, "-", "")
		end,

		Vector2 = function (raw)
			return XmlDescriptors.__VECTOR (raw.X, raw.Y)
		end,
		Vector2int16 = nil,

		Vector3 = function (raw)
			return XmlDescriptors.__VECTOR (raw.X, raw.Y, raw.Z)
		end,
		Vector3int16 = nil,

		bool = function (raw)
			return raw and "true" or "false"
		end,
		double = nil,
		float = nil,
		int = nil,
		int64 = nil,
		string = function (raw)
			return (raw == nil or raw == "") and ""
				or StringFind (raw, "]]>") and string.gsub (raw, "[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]", Escapes)
				or XmlDescriptors.__CDATA (string.gsub (raw, "\0", ""))
		end,
	}

	do
		XmlDescriptors.NumberSequence = XmlDescriptors.ConstructSequence (XmlDescriptors.NumberSequenceKeypoint)

		XmlDescriptors.ColorSequence = XmlDescriptors.ConstructSequence (XmlDescriptors.ColorSequenceKeypoint)
	end

	for descriptorName, redirectName in
		{
			NetAssetRef = "SharedString",
			Vector2int16 = "Vector2",
			Vector3int16 = "Vector3",
			double = "NormalizeNumber",
			float = "NormalizeNumber",
			int = "NormalizeNumber",
			int64 = "NormalizeNumber",
		}
	do
		XmlDescriptors[descriptorName] = XmlDescriptors[redirectName]
	end

	local ClassList, FetchAPI

	do
		local ClassPropertyExceptions = ArrayToDict ({
			Whitelist = {
				MeshPart = { "CollisionFidelity" },
				PartOperation = { "CollisionFidelity" },
				TriangleMeshPart = { "CollisionFidelity" },
			},
			Blacklist = {
				LuaSourceContainer = { "ScriptGuid" },
				Instance = { "UniqueId", "HistoryId" },
			},
		}, true)

		local function AttributesSerialize (attrs, HeaderBytes)
			local AttrsN = 0
			local BufferSize = 4
			local AttrsSorted = {}
			local AttrsFormatted = table.clone (attrs)

			if HeaderBytes then
				BufferSize += #HeaderBytes
			end

			for attr, val in attrs do
				AttrsN += 1
				AttrsSorted[AttrsN] = attr

				local Type = typeof (val)

				local Descriptor = BinaryDescriptors[Type]
				local AttrSize

				AttrsFormatted[attr], AttrSize = Descriptor (val)

				BufferSize += 5 + #attr + AttrSize
			end

			table.sort (AttrsSorted)

			local b = buffer.create (BufferSize)

			local offset = 0

			if HeaderBytes then
				for _, HeaderByte in HeaderBytes do
					buffer.writeu8 (b, offset, HeaderByte)
					offset += 1
				end
			end

			buffer.writeu32 (b, offset, AttrsN)
			offset += 4

			local StringDescriptor = BinaryDescriptors["string"]
			for _, attr in AttrsSorted do
				local b_Name, Name_size = StringDescriptor (attr)

				buffer.copy (b, offset, b_Name)
				offset += Name_size

				buffer.writeu8 (b, offset, AttrTypeIds[typeof (attrs[attr])])
				offset += 1

				local bb = AttrsFormatted[attr]

				buffer.copy (b, offset, bb)
				offset += buffer.len (bb)
			end

			return buffer.tostring (b)
		end

		local function AttenuationSerialize (attenuations)
			if not next (attenuations) then return "\0" end

			local AttenuationsN = 0

			local AttenuationsSorted = {}

			for key in attenuations do
				AttenuationsN += 1
				AttenuationsSorted[AttenuationsN] = key
			end

			table.sort (AttenuationsSorted)

			local b = buffer.create (1 + AttenuationsN * 8)

			local offset = 1
			for _, key in AttenuationsSorted do
				buffer.writef32 (b, offset, key)
				offset += 4
				buffer.writef32 (b, offset, attenuations[key])
				offset += 4
			end

			return buffer.tostring (b)
		end

		local function TransformsSerialize (transforms)
			local TransformsN = #transforms

			if TransformsN == 0 then return "\1\0\0\0\0\0\0\0" end

			local b = buffer.create (8 + TransformsN * 48)

			buffer.writeu32 (b, 0, 1)
			buffer.writeu32 (b, 4, TransformsN)

			local PackF32 = BinaryDescriptors.PackF32

			local offset = 8
			for _, transform in transforms do
				local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = transform:GetComponents ()

				local xBasis = PackF32 (R00, R01, R02)
				buffer.copy (b, offset, xBasis)
				offset += 12

				local yBasis = PackF32 (R10, R11, R12)
				buffer.copy (b, offset, yBasis)
				offset += 12

				local zBasis = PackF32 (R20, R21, R22)
				buffer.copy (b, offset, zBasis)
				offset += 12

				local position = PackF32 (X, Y, Z)
				buffer.copy (b, offset, position)
				offset += 12
			end

			return buffer.tostring (b)
		end

		local NotScriptableFixes = {

			Instance = {
				AttributesSerialize = function (instance)
					local attrs = instance:GetAttributes ()

					if not next (attrs) then return "" end

					return AttributesSerialize (attrs)
				end,
				DefinesCapabilities = "Sandboxed",
				Tags = function (instance)
					local tags = service.CollectionService:GetTags (instance)

					if #tags == 0 then return "" end

					return table.concat (tags, "\0")
				end,
			},
			Path2D = {
				PropertiesSerialize = function (instance)
					local ControlPoints = instance:GetControlPoints ()
					local ControlPointsN = #ControlPoints

					if ControlPointsN == 0 then return "\0\0\0\0" end

					local b = buffer.create (4 + ControlPointsN * 49)
					buffer.writeu32 (b, 0, ControlPointsN)

					local TypeIdPath2DControlPoint = AttrTypeIds["Path2DControlPoint"]
					local Path2DControlPointDescriptor = BinaryDescriptors["Path2DControlPoint"]

					local offset = 4
					for i, point in ControlPoints do
						local buf = Path2DControlPointDescriptor (point)

						buffer.writeu8 (b, offset, TypeIdPath2DControlPoint)
						offset += 1

						buffer.copy (b, offset, buf)
						offset += 48
					end

					return buffer.tostring (b)
				end,
			},
			PlayerEmulatorService = {
				SerializedEmulatedPolicyInfo = function (instance)
					local EmulatedPolicyInfo = instance:GetEmulatedPolicyInfo ()

					if not next (EmulatedPolicyInfo) then return "" end

					return AttributesSerialize (EmulatedPolicyInfo)
				end,
			},
			StyleRule = {
				PropertiesSerialize = function (instance)
					local props = instance:GetProperties ()

					if not next (props) then return "\0\0\0\0" end

					return AttributesSerialize (props)
				end,
				PropertyTransitionsSerialize = function (instance)
					local transitions = instance:GetPropertyTransitions ()

					if not next (transitions) then return "\2\0\0\0\0\0" end

					return AttributesSerialize (transitions, { 0x02, 0x00 })
				end,
			},
			StyleQuery = {
				ConditionsSerialize = function (instance)
					local props = instance:GetConditions ()

					if not next (props) then return "\0\0\0\0" end

					return AttributesSerialize (props)
				end,
			},
			MarkerCurve = {
				ValuesAndTimes = function (instance)
					local markers = instance:GetMarkers ()
					local MarkersN = #markers

					if MarkersN == 0 then return "\2\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0" end

					local StringsSize = 0
					for i, marker in markers do
						StringsSize += #marker.Value + 1
					end

					local b = buffer.create (8 + StringsSize + 8 + (MarkersN * 4))

					buffer.writeu32 (b, 0, 2)
					buffer.writeu32 (b, 4, MarkersN)

					local offset = 8
					for i, marker in markers do
						local value = marker.Value
						buffer.writestring (b, offset, value)
						offset += #value + 1
					end

					buffer.writeu32 (b, offset, 1)
					offset += 4
					buffer.writeu32 (b, offset, MarkersN)
					offset += 4

					for i, marker in markers do
						local ScaledTime = math.round (marker.Time * 2400)
						buffer.writeu32 (b, offset, ScaledTime)
						offset += 4
					end

					return buffer.tostring (b)
				end,
			},
			AnimationNodeDefinition = {
				InputPinData = function (instance)
					local InputPins = instance:GetInputPins ()

					local InputPinsN = #InputPins

					if InputPinsN == 0 then return "\1\0\0\0\0\0\0\0" end

					local BufferSize = 8

					for _, pin in InputPins do
						BufferSize += 4 + #pin
					end

					local b = buffer.create (BufferSize)

					buffer.writeu32 (b, 0, 1)
					buffer.writeu32 (b, 4, InputPinsN)

					local StringDescriptor = BinaryDescriptors["string"]
					local offset = 8
					for _, pin in InputPins do
						local b_pin, PinSize = StringDescriptor (pin)

						buffer.copy (b, offset, b_pin)
						offset += PinSize
					end

					return buffer.tostring (b)
				end,
			},
			AnimationClip = {
				GuidBinaryString = function (instance)
					local cleanGuid = string.gsub (instance.Guid, "[{}-]", "")
					local bytes = buffer.create (16)

					for i = 0, 15 do
						local hexByte = string.sub (cleanGuid, (i * 2) + 1, (i * 2) + 2)
						local val = tonumber (hexByte, 16) or 0
						buffer.writeu8 (bytes, i, val)
					end

					return buffer.tostring (bytes)
				end,
			},
			AnimationRigData = {
				label = function (instance)
					local labels = instance:GetLabels ()
					local LabelsN = #labels

					if LabelsN == 0 then return "\1\0\0\0\0\0\0\0" end

					local b = buffer.create (8 + LabelsN * 4)

					buffer.writeu32 (b, 0, 1)
					buffer.writeu32 (b, 4, LabelsN)

					local offset = 8

					for _, label in labels do
						buffer.writeu32 (b, offset, label)
						offset += 4
					end

					return buffer.tostring (b)
				end,
				name = function (instance)
					local names = instance:GetNames ()
					local NamesN = #names

					if NamesN == 0 then return "\1\0\0\0\0\0\0\0" end

					local BufferSize = 8

					for _, name in names do
						BufferSize += 4 + #name
					end

					local b = buffer.create (BufferSize)

					buffer.writeu32 (b, 0, 1)
					buffer.writeu32 (b, 4, NamesN)

					local offset = 8

					for _, name in names do
						buffer.writeu32 (b, offset, #name)
						offset += 4
					end
					for _, name in names do
						buffer.writestring (b, offset, name)
						offset += #name
					end

					return buffer.tostring (b)
				end,
				parent = function (instance)
					local parents = instance:GetParents ()
					local ParentsN = #parents

					if ParentsN == 0 then return "\1\0\0\0\0\0\0\0" end

					local b = buffer.create (8 + #parents * 2)

					buffer.writeu32 (b, 0, 1)
					buffer.writeu32 (b, 4, ParentsN)

					local offset = 8

					for _, parent in parents do
						buffer.writeu16 (b, offset, parent)
						offset += 2
					end

					return buffer.tostring (b)
				end,
				postTransform = function (instance)
					return TransformsSerialize (instance:GetPostTransforms ())
				end,
				preTransform = function (instance)
					return TransformsSerialize (instance:GetPreTransforms ())
				end,
				transform = function (instance)
					return TransformsSerialize (instance:GetTransforms ())
				end,
			},
			AudioDeviceInput = {
				AccessList = function (instance)
					local UseridAccesslist = instance:GetUserIdAccessList ()

					local UidN = #UseridAccesslist

					if UidN == 0 then return "" end

					local b = buffer.create (UidN * 8)

					local WriteI64Le = BinaryDescriptors.WriteI64Le

					local offset = 0
					for _, UserId in UseridAccesslist do
						WriteI64Le (b, offset, UserId)
						offset += 8
					end

					return buffer.tostring (b)
				end,
			},
			AudioEmitter = {
				AngleAttenuation = function (instance)
					return AttenuationSerialize (instance:GetAngleAttenuation ())
				end,
				DistanceAttenuation = function (instance)
					return AttenuationSerialize (instance:GetDistanceAttenuation ())
				end,
			},
			AudioListener = {
				AngleAttenuation = function (instance)
					return AttenuationSerialize (instance:GetAngleAttenuation ())
				end,
				DistanceAttenuation = function (instance)
					return AttenuationSerialize (instance:GetDistanceAttenuation ())
				end,
			},
			DebuggerBreakpoint = { line = "Line" },
			BallSocketConstraint = { MaxFrictionTorqueXml = "MaxFrictionTorque" },
			BasePart = {
				Color3uint8 = "Color",
				MaterialVariantSerialized = "MaterialVariant",
				size = "Size",
				siz = "Size",
			},
			DoubleConstrainedValue = { value = "Value" },
			IntConstrainedValue = { value = "Value" },

			CustomEvent = {
				PersistedCurrentValue = function (instance)
					local receiver = instance:GetAttachedReceivers ()[1]
					if receiver then return receiver:GetCurrentValue () end

					local clone = Instance.fromExisting (instance)
					local tempReceiver = U.Create ("CustomEventReceiver", {
						Source = clone,
					})

					local value = tempReceiver:GetCurrentValue ()

					tempReceiver:Destroy ()
					clone:Destroy ()

					return value
				end,
			},

			Terrain = {
				AcquisitionMethod = "LastUsedModificationMethod",

				MaterialColors = function (instance)
					local TerrainMaterialColors = {
						Enum.Material.Grass,
						Enum.Material.Slate,
						Enum.Material.Concrete,
						Enum.Material.Brick,
						Enum.Material.Sand,
						Enum.Material.WoodPlanks,
						Enum.Material.Rock,
						Enum.Material.Glacier,
						Enum.Material.Snow,
						Enum.Material.Sandstone,
						Enum.Material.Mud,
						Enum.Material.Basalt,
						Enum.Material.Ground,
						Enum.Material.CrackedLava,
						Enum.Material.Asphalt,
						Enum.Material.Cobblestone,
						Enum.Material.Ice,
						Enum.Material.LeafyGrass,
						Enum.Material.Salt,
						Enum.Material.Limestone,
						Enum.Material.Pavement,
					}

					local b = buffer.create (69)
					local offset = 6

					for _, material in TerrainMaterialColors do
						local color = instance:GetMaterialColor (material)
						buffer.writeu8 (b, offset, (color.R * 255))
						offset += 1
						buffer.writeu8 (b, offset, (color.G * 255))
						offset += 1
						buffer.writeu8 (b, offset, (color.B * 255))
						offset += 1
					end

					return buffer.tostring (b)
				end,
			},
			TriangleMeshPart = {
				FluidFidelityInternal = "FluidFidelity",
			},
			MeshPart = { InitialSize = "MeshSize", MeshID = "MeshId" },
			PartOperation = { InitialSize = "MeshSize" },
			Part = { shape = "Shape", shap = "Shape" },
			TrussPart = { style = "Style" },
			FormFactorPart = {
				formFactorRaw = "FormFactor",
			},
			Fire = { heat_xml = "Heat", size_xml = "Size" },
			Humanoid = {
				Health_XML = "Health",
				InternalBodyScale = function (instance)
					return instance:GetAccessoryHandleScale (instance.Parent.HumanoidRootPart, Enum.BodyPartR15.RootPart)
				end,
				InternalHeadScale = function (instance)
					return instance:GetAccessoryHandleScale (instance.Parent.Head, Enum.BodyPartR15.Head).X
				end,
			},
			HumanoidDescription = {
				AccessoryBlob = function (instance)
					local blob = {}

					for _, acc in instance:GetAccessories (false) do
						table.insert (blob, {
							AssetId = acc.AssetId,
							Order = acc.Order,
							AccessoryType = acc.AccessoryType.Name,
							Puffiness = acc.Puffiness,
						})
					end

					return service.HttpService:JSONEncode (blob)
				end,
				EmotesDataInternal = function (instance)
					local EmotesData = ""
					for name, ids in instance:GetEmotes () do
						EmotesData ..= name .. "^" .. table.concat (ids, "^") .. "^\\"
					end
					return EmotesData
				end,
				EquippedEmotesDataInternal = function (instance)
					local EquippedEmotesData = ""
					for _, emote in instance:GetEquippedEmotes () do
						EquippedEmotesData ..= emote.Slot .. "^" .. emote.Name .. "\\"
					end
					return EquippedEmotesData
				end,
			},
			LocalizationTable = {
				Contents = function (instance)
					return instance:GetContents ()
				end,
			},
			MaterialService = { Use2022MaterialsXml = "Use2022Materials" },
			VideoPlayer = {
				PlayingReplicating = "IsPlaying",
			},

			Model = {
				ModelMeshCFrame = function (instance)
					return instance:GetModelCFrame ()
				end,
				ModelMeshSize = function (instance)
					return instance:GetExtentsSize ()
				end,
				Scale = function (instance)
					return instance:GetScale ()
				end,
				ScaleFactor = function (instance)
					return instance:GetScale ()
				end,
				WorldPivotData = "WorldPivot",
			},
			PackageLink = {
				PackageContentSerialize = "PackageContent",
				PackageIdSerialize = "PackageId",
				VersionIdSerialize = "VersionNumber",
			},
			Players = { MaxPlayersInternal = "MaxPlayers", PreferredPlayersInternal = "PreferredPlayers" },

			StarterPlayer = { AvatarJointUpgrade_SerializedRollout = "AvatarJointUpgrade" },
			Smoke = { size_xml = "Size", opacity_xml = "Opacity", riseVelocity_xml = "RiseVelocity" },
			Sound = {
				xmlRead_MinDistance_3 = "RollOffMinDistance",
				xmlRead_MaxDistance_3 = "RollOffMaxDistance",
			},
			ViewportFrame = {
				CameraCFrame = function (instance)
					local CurrentCamera = instance.CurrentCamera

					return CurrentCamera and CurrentCamera.CFrame or CFrame.identity
				end,
				CameraFieldOfView = function (instance)
					local CurrentCamera = instance.CurrentCamera

					return math.rad (CurrentCamera and CurrentCamera.FieldOfView or 70)
				end,
			},
			WeldConstraint = {
				CFrame0 = function (instance)
					local Part0, Part1 = instance.Part0, instance.Part1

					return Part0 and Part1 and Part0.CFrame:ToObjectSpace (Part1.CFrame) or CFrame.identity
				end,
				CFrame1 = function (instance)
					local Part0, Part1 = instance.Part0, instance.Part1

					return Part0 and Part1 and Part1.CFrame:ToObjectSpace (Part0.CFrame) or CFrame.identity
				end,
				Part0Internal = "Part0",
				Part1Internal = "Part1",
				State = function (instance)
					return CountBits (instance.Enabled, instance.Active)
				end,
			},
			Workspace = {

				CollisionGroupData = function ()
					local CollisionGroups = game:GetService ("PhysicsService"):GetRegisteredCollisionGroups ()

					local ColGroupsN = #CollisionGroups

					if ColGroupsN == 0 then return "\1\0" end

					local BufferSize = 2

					for _, group in CollisionGroups do
						BufferSize += 7 + #group.name
					end

					local b = buffer.create (BufferSize)

					buffer.writeu8 (b, 0, 1)
					buffer.writeu8 (b, 1, ColGroupsN)

					local TypeIdInt32 = AttrTypeIds["int32"]
					local offset = 2
					for i, group in CollisionGroups do
						local name, id, mask = group.name, i - 1, group.mask
						local NameLen = #name

						buffer.writeu8 (b, offset, id)
						offset += 1

						buffer.writeu8 (b, offset, TypeIdInt32)
						offset += 1

						buffer.writei32 (b, offset, mask)
						offset += 4

						buffer.writeu8 (b, offset, NameLen)
						offset += 1
						buffer.writestring (b, offset, name)
						offset += NameLen
					end

					return buffer.tostring (b)
				end,
			},
		}
		for _, EnumItem in Enum.Material:GetEnumItems () do
			NotScriptableFixes.MaterialService[EnumItem.Name .. "Name"] = function (instance)
				return instance:GetBaseMaterialOverride (EnumItem)
			end
		end

		FetchAPI = function ()
			local ApiDump

			local MaxSecurityCapabilities = SecurityCapabilities.new (unpack (Enum.SecurityCapability:GetEnumItems ()))
			local filter = { Security = MaxSecurityCapabilities, ExcludeDisplay = true, ExcludeInherited = true }

			local ApiDumpFetchers = {
				[1] = function ()
					local res = readfile (FullVersion)
					if res and res ~= "" and service.HttpService:JSONDecode (res) then return res end
				end,
				[2] = function ()
					local ClientVersionStr = tostring (ClientVersion)

					local dump
					local MatchingVersions, matched, IsMatched, ExactMatch = {}, {}
					local function ProcessLine (line, noinsert)
						local FileVersion, PatchCommit, VersionHash =
							string.match (line, "\"%d+%.(%d+)%.([^\"]+)\": \"(version%-[^\"]+)")
						if FileVersion == ClientVersionStr then
							IsMatched = true

							if VersionHash and not matched[VersionHash] then
								matched[VersionHash] = true
								if not noinsert then table.insert (MatchingVersions, VersionHash) end
								if string.sub (FullVersion, -#PatchCommit) == PatchCommit then
									return VersionHash
								end
							end
						elseif IsMatched then
							return false
						end
					end
					local function fetchFullApiDump (hash)
						local ok, res = pcall (function ()
							local raw =
								game:HttpGet ("https://setup.rbxcdn.com/" .. hash .. "-Full-API-Dump.json", true)
							return service.HttpService:JSONEncode (service.HttpService:JSONDecode (raw).Classes)
						end)
						return ok and res or nil
					end

					do
						local o, r = pcall (
							game.HttpGet,
							game,
							"https://raw.githubusercontent.com/setup-rbxcdn/setup-rbxcdn.github.io/refs/heads/main/version-history/Windows/Studio64.json",
							true
						)
						if o then
							local VersionHistory = string.split (r, "\n")
							VersionHistory[#VersionHistory] = nil

							for i = #VersionHistory, 2, -1 do
								local res = ProcessLine (VersionHistory[i])
								if res == false then
									break
								elseif res then
									ExactMatch = res
								end
							end
						end
					end

					do
						local function FallbackChannel (channel)
							local ok, res = pcall (function ()
								return service.HttpService:JSONDecode (
									game:HttpGet (
										"https://clientsettings.rbxcdn.com/v2/client-version/WindowsStudio64"
											.. (channel and "/channel/" .. channel or ""),
										true
									)
								)
							end)
							if not ok then return end
							if res.version and res.clientVersionUpload then
								local line = "\"" .. res.version .. "\": \"" .. res.clientVersionUpload
								return ProcessLine (line, true)
							end
						end

						if not ExactMatch then ExactMatch = FallbackChannel ("zbeta") or FallbackChannel () end
					end

					if ExactMatch then dump = fetchFullApiDump (ExactMatch) end

					if not dump then
						for _, VersionHash in MatchingVersions do
							dump = fetchFullApiDump (VersionHash)
							if dump then break end
						end
					end

					return dump
				end,
				[3] = function ()
					local classes, ClassesSize = {}, 1

					for _, ApiClass in service.ReflectionService:GetClasses (filter) do
						local members, MembersSize = {}, 1
						local className = ApiClass.Name

						local class = {
							Name = className,
							Members = members,
							Superclass = ApiClass.Superclass or "<<<ROOT>>>",
						}
						local permits = ApiClass.Permits

						local tags = {}
						if ApiClass.Service then
							table.insert (tags, "Service")
						elseif permits and permits["GetService"] then
							table.insert (tags, "Service")
						elseif not permits or not permits["New"] then
							table.insert (tags, "NotCreatable")
						end

						if #tags ~= 0 then class.Tags = tags end

						local o, r = pcall (
							service.ReflectionService.GetPropertiesOfClass,
							service.ReflectionService,
							className,
							filter
						)
						if o then
							for _, property in r do
								local propertyName = property.Name

								local valueType = property.Type
								local ValueTypeName = valueType.EngineType

								local category = valueType.Category

								local MemberTags = {}

								if not next (property.Permits) then table.insert (MemberTags, "NotScriptable") end

								if ValueTypeName == "Enum" then
									category, ValueTypeName = "Enum", valueType.EnumType
								elseif ValueTypeName == "RefType" then
									category, ValueTypeName = "Class", valueType.InstanceType
								else
									local renames = {
										CoordinateFrame = "CFrame",
										Rect2D = "Rect",
										Vector3Int16 = "Vector3int16",
										Vector2Int16 = "Vector2int16",
										Region3Int16 = "Region3int16",
									}
									ValueTypeName = renames[ValueTypeName] or ValueTypeName
								end

								local member = {
									Name = propertyName,
									MemberType = "Property",
									ValueType = { Name = ValueTypeName, Category = category },
									Serialization = { CanLoad = property.Serialized, CanSave = property.Serialized },
								}

								if #MemberTags ~= 0 then member.Tags = MemberTags end

								members[MembersSize] = member
								MembersSize += 1
							end
						end
						classes[ClassesSize] = class
						ClassesSize += 1
					end

					return service.HttpService:JSONEncode (classes)
				end,
				[4] = function ()
					return service.HttpService:JSONEncode (
						service.HttpService:JSONDecode (
							game:HttpGet (
								"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json",
								true
							)
						).Classes
					)
				end,
			}
			for i, fetcher in ApiDumpFetchers do
				local o, r = pcall (fetcher)
				if o and r then
					ApiDump = r
					if i == 2 then
						if writefile then writefile (FullVersion, ApiDump) end
					end
					break
				elseif r ~= false and 2 < i then
					warn ("[DEBUG] Failed to get", FullVersion, "version API Dump, trying fallbacks..")
					warn ("[DEBUG] Method number:", i, "Reason:", r)
				end
			end

			local classList = {}
			local TempClassDict = {}

			local ClassesWhitelist, ClassesBlacklist =
				ClassPropertyExceptions.Whitelist, ClassPropertyExceptions.Blacklist

			local ApiDumpDecoded = service.HttpService:JSONDecode (ApiDump)

			for _, ApiClassItem in ApiDumpDecoded do
				local ClassName = ApiClassItem.Name
				local props = {}

				for _, Member in ApiClassItem.Members do
					local MemberType = Member.MemberType
					if MemberType == "Property" or MemberType == "Function" then
						props[Member.Name] = {
							ValueType = MemberType == "Property" and Member.ValueType.Name,
							MemberType = MemberType,
						}
					end
				end

				TempClassDict[ClassName] = props
			end

			for _, ApiClassItem in ApiDumpDecoded do
				local ClassProperties, ClassPropertiesSize = {}, 1
				local Class = {
					Properties = ClassProperties,
					Superclass = ApiClassItem.Superclass,

					NotCreatable = nil,
				}

				local ClassName = ApiClassItem.Name
				local ClassTags = ApiClassItem.Tags

				if ClassTags then
					local Tags = ArrayToDict (ClassTags, nil, nil, "string")

					Class.NotCreatable = Tags.NotCreatable
					Class.Service = Tags.Service
				end

				local NotScriptableFixClass = NotScriptableFixes[ClassName]

				local ClassWhitelist, ClassBlacklist = ClassesWhitelist[ClassName], ClassesBlacklist[ClassName]

				local ContentProperties
				for _, Member in ApiClassItem.Members do
					if Member.MemberType == "Property" then
						local Serialization = Member.Serialization

						if Serialization.CanLoad then
							local PropertyName = Member.Name

							local ValueType = Member.ValueType
							local ValueTypeName = ValueType.Name

							if ValueTypeName == "Content" or ValueTypeName == "AssetContentMap" then
								if not ContentProperties then
									ContentProperties = {}

									local o, properties = pcall (
										service.ReflectionService.GetPropertiesOfClass,
										service.ReflectionService,
										ClassName,
										filter
									)
									if o then
										for _, property in properties do
											ContentProperties[property.Name] = property.Serialized
										end
									end
								end
								if ContentProperties[PropertyName] ~= nil then
									Serialization.CanSave = ContentProperties[PropertyName]
								end
							end

							if
								(Serialization.CanSave or ClassWhitelist and ClassWhitelist[PropertyName])
								and not (ClassBlacklist and ClassBlacklist[PropertyName])
							then
								local MemberTags = Member.Tags

								local Special, PreferredDescriptorName

								if MemberTags then
									for _, tag in MemberTags do
										if type (tag) == "table" then
											PreferredDescriptorName = tag.PreferredDescriptorName
											if PreferredDescriptorName and Special then break end
										elseif tag == "NotScriptable" then
											Special = true
											if PreferredDescriptorName then break end
										end
									end
								end

								local preferredDescriptorProp
								if PreferredDescriptorName then
									preferredDescriptorProp = TempClassDict[ClassName][PreferredDescriptorName]

									if
										preferredDescriptorProp == nil
										or (
											preferredDescriptorProp.MemberType == "Property"
											and ValueTypeName ~= preferredDescriptorProp.ValueType
										)
									then
										PreferredDescriptorName = nil
									end
								end

								local Property = {
									Name = PropertyName,
									Category = ValueType.Category,

									ValueType = ValueTypeName,

									Special = Special,

									CanRead = nil,
								}

								if string.sub (ValueTypeName, 1, 8) == "Optional" then
									Property.Optional = string.sub (ValueTypeName, 9)
								end

								local NotScriptableFix = NotScriptableFixClass and NotScriptableFixClass[PropertyName]
								local accessFunc = PreferredDescriptorName
									and (
										preferredDescriptorProp.MemberType == "Property"
											and function (instance)
												return instance[PreferredDescriptorName]
											end
										or function (instance)
											return instance[PreferredDescriptorName] (instance)
										end
									)

								Property.Fallback = NotScriptableFix
										and (type (NotScriptableFix) == "function" and NotScriptableFix or accessFunc and function (
											instance
										)
											local o, r = pcall (accessFunc, instance)
											if o then return r end
											return instance[NotScriptableFix]
										end or function (instance)
											return instance[NotScriptableFix]
										end)
									or accessFunc

								ClassProperties[ClassPropertiesSize] = Property
								ClassPropertiesSize += 1
							end
						end
					end
				end

				classList[ClassName] = Class
			end

			return classList
		end
	end

	local GlobalEnv = getgenv and getgenv () or _G or shared

	local function synsaveinstance (CustomOptions, CustomOptions2)
		if GlobalEnv.USSI then return end
		GlobalEnv.USSI = true

		local totalsize, chunks = 0, table.create (1)
		local savebuffer, SavebufferSize = {}, 1
		local header =
			"<!-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw --><roblox version=\"4\">"

		local StatusText
		local StatusGui

		local Options = {
			mode = "optimized",
			Decompile = ExecutorName ~= "Velocity",
			scriptcache = true,

			DecompileTimeout = 10,

			DebugMode = false,

			Callback = false,

			DecompileJobless = false,
			DecompileIgnore = {
				"TextChatService",
			},
			IgnoreDefaultPlayerScripts = true,
			SaveBytecode = false,

			IgnoreProperties = {},

			IgnoreList = { "CoreGui", "CorePackages" },

			ExtraInstances = {},
			NilInstances = false,
			NilInstancesFixes = {},

			SaveCacheInterval = 0x1600 * 10,
			ShowStatus = true,
			KillAllScripts = true,
			SafeMode = true,
			BoostFPS = false,
			ShutdownWhenDone = false,
			AntiIdle = true,
			Anonymous = false,
			ReadMe = true,
			FilePath = false,
			AvoidFileOverwrite = true,
			Object = false,
			IsModel = false,

			IgnoreDefaultProperties = true,
			IgnoreNotArchivable = true,
			IgnorePropertiesOfNotScriptsOnScriptsMode = false,
			IgnoreSpecialProperties = ArrayToDict ({ "Fluxus", "Delta", "Solara" })[ExecutorName] or false,

			IsolateLocalPlayer = false,
			IsolateLocalPlayerCharacter = false,
			IsolatePlayers = false,
			IsolateStarterPlayer = false,
			SavePlayerCharacters = false,

			SaveNotCreatable = false,
			NotCreatableFixes = {

				"",
				"AdvancedDragger",
				"AnimationTrack",
				"Dragger",
				"Player",
				"PlayerGui",
				"PlayerMouse",
				"PlayerMouse",
				"PlayerScripts",
				"ScreenshotHud",
				"StudioData",
				"TextChatMessage",
				"TextSource",
				"TouchTransmitter",
				"Translator",
				CloudLocalizationTable = "LocalizationTable",
				Platform = "Part",
				Status = "Model",
			},

			IgnoreSharedStrings = ExecutorName ~= "Wave",
			SharedStringOverwrite = false,
			TreatUnionsAsParts = ExecutorName == "Solara",
			AlternativeWritefile = not ArrayToDict ({ "WRD", "Xeno", "Zorara" })[ExecutorName],

			OptionsAliases = {
				timeout = "DecompileTimeout",
				FileName = "FilePath",
				IgnoreArchivable = "IgnoreNotArchivable",
				IgnoreDefaultProps = "IgnoreDefaultProperties",
				InstancesBlacklist = "IgnoreList",
				SaveLocalPlayer = "IsolateLocalPlayer",
				IsolatePlayerGui = "IsolateLocalPlayer",
				SavePlayerGui = "IsolateLocalPlayer",
				SaveNonCreatable = "SaveNotCreatable",
				SavePlayers = "IsolatePlayers",
				SaveCharacters = "SavePlayerCharacters",
			},
			OptionsAliasesInverse = {
				noscripts = "Decompile",
				RemovePlayers = "IsolatePlayers",
				RemovePlayerCharacters = "SavePlayerCharacters",
			},
		}
		local OptionsLowercase, OptionsAliasesInverseLowercase, CustomOptionsValid = {}, {}, {}

		do
			local function buildMap (dest, source, warnLabel)
				for k, v in source do
					local key = string.lower (k)

					if dest[key] then
						warn ("DUPLICATE " .. warnLabel, k)
					else
						dest[key] = v
					end
				end
			end

			for o in Options do
				local option = string.lower (o)
				if OptionsLowercase[option] then
					warn ("DUPLICATE OPTION", o)
				else
					OptionsLowercase[option] = o
				end
			end

			buildMap (OptionsLowercase, Options.OptionsAliases, "ALIAS")

			buildMap (OptionsAliasesInverseLowercase, Options.OptionsAliasesInverse, "INVERSE ALIAS")
		end

		do
			local function ConstructNilInstanceFix (Name, ClassName, Separate)
				return function (instance, instancePropertyOverrides)
					local Exists

					if not Separate then Exists = Options.NilInstancesFixes[Name] end

					local Fix

					local DoesntExist = not Exists
					if DoesntExist then
						Fix = U.Create (ClassName)
						if not Separate then Options.NilInstancesFixes[Name] = Fix end

						instancePropertyOverrides[Fix] =
							{ __SaveSpecific = true, __Children = { instance }, Properties = { Name = Name } }
					else
						Fix = Exists
						table.insert (instancePropertyOverrides[Fix].__Children, instance)
					end

					if DoesntExist then return Fix end
				end
			end

			Options.NilInstancesFixes.Animator = ConstructNilInstanceFix (
				"Animator has to be placed under Humanoid or AnimationController",
				"AnimationController"
			)
			Options.NilInstancesFixes.AdPortal =
				ConstructNilInstanceFix ("AdPortal must be parented to a Part", "Part")
			Options.NilInstancesFixes.Attachment =
				ConstructNilInstanceFix ("Attachments must be parented to a BasePart or another Attachment", "Part")
			Options.NilInstancesFixes.BaseWrap =
				ConstructNilInstanceFix ("BaseWrap must be parented to a MeshPart", "MeshPart")
			Options.NilInstancesFixes.PackageLink =
				ConstructNilInstanceFix ("Package already has a PackageLink", "Folder", true)

			if CustomOptions2 and type (CustomOptions2) == "table" then
				local tmp = CustomOptions
				local Type = typeof (tmp)
				CustomOptions = CustomOptions2
				if Type == "Instance" then
					CustomOptions.Object = tmp
				elseif Type == "table" and typeof (tmp[1]) == "Instance" then
					CustomOptions.ExtraInstances = tmp
					Options.IsModel = true
				end
			end

			local Type = typeof (CustomOptions)

			if Type == "table" then
				if typeof (CustomOptions[1]) == "Instance" then
					Options.mode = "invalidmode"
					Options.ExtraInstances = CustomOptions
					Options.IsModel = true
					CustomOptions = {}
				else
					for key, value in CustomOptions do
						local k = string.lower (key)

						local option = OptionsLowercase[k]
						local invert = false

						if not option then
							option = OptionsAliasesInverseLowercase[k]
							invert = option ~= nil
						end

						if option then
							local finalValue
							if invert then
								finalValue = not value
							else
								finalValue = value
							end

							Options[option] = finalValue
							CustomOptionsValid[option] = true
						end
					end
				end
			elseif Type == "Instance" then
				Options.mode = "invalidmode"
				Options.Object = CustomOptions
				CustomOptions = {}
			else
				CustomOptions = {}
			end
		end

		if not writefile and not Options.Callback then
			local function coreCall (method, ...)
				local StarterGui = service.StarterGui
				method = StarterGui[method]
				if not method then return end

				for _ = 1, 10 do
					local success, result = pcall (method, StarterGui, ...)
					if success then return result end
					task.wait (1)
				end
			end

			local text =
				"Function \"writefile\" is NOT available\nUse the Option \"Callback\" instead for now (check docs)"

			coreCall ("SetCore", "SendNotification", {
				Title = "SAVEINSTANCE ERROR",
				Text = text,
				Duration = 15,
				Icon = "rbxassetid://9072920609",
			})
			coreCall ("SetCore", "SendNotification", {
				Title = "SAVEINSTANCE ERROR",
				Text = "Please ask your executor's developers to add writefile",
				Duration = 15,
				Icon = "rbxassetid://9072920609",
			})

			warn (text)

			GlobalEnv.USSI = nil
			return
		end

		if Options.IgnoreDefaultPlayerScripts then
			local DecompileIgnore = Options.DecompileIgnore

			local DefaultScripts = ArrayToDict ({
				ModuleScript = { "PlayerModule" },
				LocalScript = {
					"BubbleChat",
					"ChatScript",
					"PlayerScriptsLoader",
					"RbxCharacterSounds",
				},
			}, true)

			local function ignorePath (path)
				if path then
					for _, child in path:GetChildren () do
						local ClassMatch = DefaultScripts[child.ClassName]
						if ClassMatch then
							local NameMatch = ClassMatch[child.Name]
							if NameMatch then table.insert (DecompileIgnore, child) end
						end
					end
				end
			end

			ignorePath (service.StarterPlayer:FindFirstChildOfClass ("StarterPlayerScripts"))

			local LocalPlayer = service.Players.LocalPlayer
			if LocalPlayer then ignorePath (LocalPlayer:FindFirstChildOfClass ("PlayerScripts")) end
		end

		local InstancesOverrides = {}

		local DecompileIgnore, IgnoreList, IgnoreProperties, NotCreatableFixes =
			ArrayToDict (Options.DecompileIgnore, true),
			ArrayToDict (Options.IgnoreList, true),
			ArrayToDict (Options.IgnoreProperties),
			ArrayToDict (Options.NotCreatableFixes, true, "Folder")

		local DebugMode = Options.DebugMode

		if DebugMode and type (DebugMode) ~= "function" then DebugMode = warn end

		local LPUserId, LPName, ANONUserId, ANONName, AnonymizableTypes

		do
			local anonymous = Options.Anonymous
			local lp = service.Players.LocalPlayer

			if anonymous and lp then
				AnonymizableTypes = ArrayToDict ({ "double", "float", "int", "int64", "string" })
				LPUserId, LPName = lp.UserId, lp.Name

				local istable = type (anonymous) == "table"
				ANONUserId = istable and anonymous.UserId or 1
				ANONName = istable and anonymous.Name or "Roblox"
			end
		end

		local FilePath = Options.FilePath
		local SaveCacheInterval = Options.SaveCacheInterval
		local ToSaveInstance = Options.Object
		local IsModel = Options.IsModel

		if ToSaveInstance and CustomOptions.IsModel == nil then IsModel = true end

		local IgnoreDefaultProperties = Options.IgnoreDefaultProperties
		local IgnoreNotArchivable = not Options.IgnoreNotArchivable
		local IgnorePropertiesOfNotScriptsOnScriptsMode = Options.IgnorePropertiesOfNotScriptsOnScriptsMode

		local OldGetHiddenProperty
		if Options.IgnoreSpecialProperties and gethiddenproperty then
			OldGetHiddenProperty = gethiddenproperty
			gethiddenproperty = nil
		end

		local SaveNotCreatable = Options.SaveNotCreatable
		local TreatUnionsAsParts = Options.TreatUnionsAsParts

		local DecompileJobless = Options.DecompileJobless
		if DecompileJobless then Options.scriptcache = true end
		local ScriptCache = Options.scriptcache and getscriptbytecode

		local DecompileTimeout = Options.DecompileTimeout

		local IgnoreSharedStrings = Options.IgnoreSharedStrings
		local SharedStringOverwrite = Options.SharedStringOverwrite

		local ldeccache = GlobalEnv.scriptcache

		local DecompileIgnoring, ToSaveList, ldecompile, placename, ElapseT, SaveNotCreatableWillBeEnabled, RecoveredScripts

		if Options.ReadMe then RecoveredScripts = {} end

		if ScriptCache and not ldeccache then
			ldeccache = {}
			GlobalEnv.scriptcache = ldeccache
		end

		if ToSaveInstance == game then
			Options.mode = "full"
			ToSaveInstance = nil
			IsModel = nil
		end

		local function isLuaSourceContainer (instance)
			return instance:IsA ("LuaSourceContainer")
		end

		do
			local mode = string.lower (Options.mode)
			local tmp = table.clone (Options.ExtraInstances)

			local PlaceName = game.PlaceId

			pcall (function ()
				PlaceName ..= " " .. service.MarketplaceService:GetProductInfoAsync (PlaceName).Name
			end)

			local function sanitizeFileName (str)
				return string.sub (
					string.gsub (string.gsub (string.gsub (str, "[^%w _]", ""), " +", " "), " +$", ""),
					1,
					240
				)
			end

			if ToSaveInstance then
				if mode == "optimized" then mode = "full" end

				for _, key in
					{
						"IsolateLocalPlayer",
						"IsolateLocalPlayerCharacter",
						"IsolatePlayers",
						"IsolateStarterPlayer",
						"NilInstances",
					}
				do
					if CustomOptionsValid[key] == nil then Options[key] = false end
				end
			end

			local filetype = IsModel and ".rbxmx" or ".rbxlx"

			if FilePath then
				placename = FilePath
			elseif IsModel then
				placename =
					sanitizeFileName ("model " .. PlaceName .. " " .. (ToSaveInstance or tmp[1] or game):GetFullName ())
			else
				placename = sanitizeFileName ("place " .. PlaceName)
			end

			if Options.AvoidFileOverwrite and isfile then
				local counter = 0
				local temp = placename

				while isfile (temp .. filetype) do
					counter += 1
					temp = placename .. "(" .. counter .. ")"
				end

				placename = temp .. filetype
			else
				placename = placename .. filetype
			end

			if GlobalEnv[placename] then
				GlobalEnv.USSI = nil
				if OldGetHiddenProperty then
					gethiddenproperty = OldGetHiddenProperty
					OldGetHiddenProperty = nil
				end
				return
			end

			GlobalEnv[placename] = true
			GlobalEnv.USSI = nil

			if mode ~= "scripts" then IgnorePropertiesOfNotScriptsOnScriptsMode = nil end

			local TempRoot = ToSaveInstance or game

			if mode == "full" then
				if not ToSaveInstance then
					local Children = TempRoot:GetChildren ()
					if 0 < #Children then
						local TmpDict = ArrayToDict (tmp)
						for _, child in Children do
							if not TmpDict[child] then table.insert (tmp, child) end
						end
					end
				end
			elseif mode == "optimized" then
				local TmpDict = ArrayToDict (tmp)

				for _, serviceName in
					{
						"Workspace",
						"Players",
						"Lighting",
						"MaterialService",
						"ReplicatedFirst",
						"ReplicatedStorage",

						"ServerScriptService",
						"ServerStorage",

						"StarterGui",
						"StarterPack",
						"StarterPlayer",
						"Teams",
						"SoundService",
						"Chat",
						"TextChatService",

						"LocalizationService",

						"JointsService",
					}
				do
					local _service = game:FindService (serviceName)
					if _service and not TmpDict[_service] then table.insert (tmp, _service) end
				end
			elseif mode == "scripts" then
				local unique = {}
				for _, instance in TempRoot:GetDescendants () do
					if isLuaSourceContainer (instance) then
						local Parent = instance.Parent
						while Parent and Parent ~= TempRoot do
							instance = instance.Parent
							Parent = instance.Parent
						end
						if Parent then unique[instance] = true end
					end
				end
				for instance in unique do
					table.insert (tmp, instance)
				end
			end

			ToSaveList = tmp

			if ToSaveInstance then table.insert (ToSaveList, 1, ToSaveInstance) end
		end

		local IsolateLocalPlayer = Options.IsolateLocalPlayer
		local IsolateLocalPlayerCharacter = Options.IsolateLocalPlayerCharacter
		local IsolatePlayers = Options.IsolatePlayers
		local IsolateStarterPlayer = Options.IsolateStarterPlayer
		local NilInstances = Options.NilInstances

		if NilInstances and enablenilinstances then enablenilinstances () end
		local function GetSizeFormat ()
			local Size

			for i, unit in
				{
					"B",
					"KB",
					"MB",
					"GB",
					"TB",
				}
			do
				if totalsize < 0x400 ^ i then
					Size = math.floor (totalsize / (0x400 ^ (i - 1)) * 10) / 10 .. " " .. unit
					break
				end
			end

			return Size or (math.floor (totalsize / (0x400 ^ 4) * 10) / 10 .. " TB")
		end

		local RunService = service.RunService
		local function WaitForRender ()
			RunService.RenderStepped:Wait ()
		end

		local Loading
		local function RunWithLoading (text, keepStatus, waitForRender, taskFunction, ...)
			local previousStatus

			if StatusText then
				if keepStatus then previousStatus = StatusText.Text end
				Loading = task.spawn (function ()
					local SpinnerCount = 0
					local chars = { "|", "/", "—", "\\" }
					local CharsSize = #chars

					local function getLoadingText ()
						SpinnerCount += 1

						if CharsSize < SpinnerCount then SpinnerCount = 1 end

						return chars[SpinnerCount]
					end

					text ..= " "

					while true do
						StatusText.Text = text .. getLoadingText ()
						task.wait (0.25)
					end
				end)
				if waitForRender then WaitForRender () end
			end

			local result = { taskFunction (...) }

			if Loading then
				task.cancel (Loading)
				Loading = nil
				if previousStatus then StatusText.Text = previousStatus end
			end

			return unpack (result)
		end

		local function ConstructTimeoutHandler (timeout, f, TimeoutReturn)
			return timeout < 0 and function (script)
				return pcall (f, script)
			end or function (script)
				local thread = coroutine.running ()
				local timeoutThread, isCancelled

				timeoutThread = task.delay (timeout, function ()
					isCancelled = true
					coroutine.resume (thread, nil, TimeoutReturn)
				end)

				task.spawn (function ()
					local ok, result = pcall (f, script)

					if isCancelled then return end

					task.cancel (timeoutThread)

					while coroutine.status (thread) ~= "suspended" do
						task.wait ()
					end

					coroutine.resume (thread, ok, result)
				end)

				return coroutine.yield ()
			end
		end

		local getbytecode
		if getscriptbytecode then getbytecode = ConstructTimeoutHandler (3, getscriptbytecode) end

		local SaveBytecode
		if Options.SaveBytecode and getscriptbytecode then
			SaveBytecode = function (script)
				local s, bytecode = getbytecode (script)

				if s and bytecode and bytecode ~= "" then
					return "-- Bytecode (Base64):\n-- " .. base64encode (bytecode) .. "\n\n"
				end
			end
		end

		do
			if not Options.Decompile then
				ldecompile = function ()
					return "-- Decompiling is disabled"
				end
			elseif decompile then
				local decomp = ConstructTimeoutHandler (DecompileTimeout, decompile, "Decompiler timed out")

				ldecompile = function (script)
					local bytecode
					if ScriptCache then
						local s
						s, bytecode = getbytecode (script)
						local cached

						if s then
							if not bytecode or bytecode == "" then return "-- The Script is Empty" end
							cached = ldeccache[bytecode]
						else
							bytecode = nil
						end

						if cached then
							if DebugMode then DebugMode ("Found in Cache", script:GetFullName ()) end
							return cached
						end
					else
						if DecompileJobless then return "-- Not found in already decompiled ScriptCache" end
					end

					local ok, result = RunWithLoading ("Decompiling " .. script.Name, true, nil, decomp, script)
					if not result then
						ok, result = false, "Empty Output"
					end

					local output
					if ok then
						result = string.gsub (result, "\0", "\\0")
						output = result
					else
						output = "--[[ Failed to decompile. Reason:\n" .. (result or "") .. "\n]]"
					end

					if ScriptCache and bytecode then
						ldeccache[bytecode] = output
						if DebugMode then DebugMode ("Cached", script:GetFullName ()) end
					end

					return output
				end
			else
				ldecompile = function ()
					return "-- Your Executor does NOT have a Decompiler"
				end
			end
		end

		local function GetLocalPlayer ()
			return service.Players.LocalPlayer
				or service.Players:GetPropertyChangedSignal ("LocalPlayer"):Wait ()
				or service.Players.LocalPlayer
		end

		local function filterLinkedSource (str)
			local o, r = pcall (service.HttpService.JSONDecode, service.HttpService, str)
			if not o or type (r) ~= "table" then return end
			if r.errors then return end
			return true
		end

		local function replaceClassName (instance, InstanceName, ClassName)
			local InstanceOverride
			if InstanceName ~= ClassName then
				InstanceOverride = InstancesOverrides[instance]
				if not InstanceOverride then
					InstanceOverride = { Properties = { Name = "[" .. ClassName .. "] " .. InstanceName } }
					InstancesOverrides[instance] = InstanceOverride
				end
			end
			return InstanceOverride
		end

		local function gsubCaseInsensitive (input, search, replacement)
			local inputLower = string.lower (input)
			search = string.lower (search)

			if not StringFind (inputLower, search, 1, true) then return input end

			local lastFinish = 0
			local subStrings = {}
			local SearchLen = #search
			local InputLen = #input
			while SearchLen <= InputLen - lastFinish do
				local init = lastFinish + 1

				local start, finish = StringFind (inputLower, search, init)

				if start == nil then break end

				table.insert (subStrings, string.sub (input, init, start - 1))

				lastFinish = finish
			end

			if lastFinish == 0 then return input end

			table.insert (subStrings, string.sub (input, lastFinish + 1))

			return table.concat (subStrings, replacement)
		end

		local function filterPropVal (result, propertyName, category)
			return result == nil
				or result == "can't get value"
				or type (result) == "string"
					and (category == "Enum" or StringFind (result, "Unable to get property " .. propertyName))
		end

		local __BREAK = "__BREAK" .. service.HttpService:GenerateGUID (false)

		local function ReadProperty (instance, property, propertyName, special, category, optional)
			local raw = __BREAK

			local InstanceOverride = InstancesOverrides[instance]
			if InstanceOverride then
				local PropertiesOverride = InstanceOverride.Properties
				if PropertiesOverride then
					local PropertyOverride = PropertiesOverride[propertyName]
					if PropertyOverride ~= nil then return PropertyOverride end
				end
			end

			local CanRead = property.CanRead

			if CanRead == false then return __BREAK end

			if special then
				if gethiddenproperty then
					local ok, result = pcall (gethiddenproperty, instance, propertyName)

					if ok then raw = result end

					if filterPropVal (raw, propertyName, category) then
						if result ~= nil or not optional then
							if DebugMode then DebugMode ("Filtered", propertyName) end

							property.CanRead = false
						end

						return __BREAK
					end
				end
			else
				if CanRead then
					local ok, result = pcall (index, instance, propertyName)
					if ok then
						raw = result
					else
						property.CanRead = false
						return __BREAK
					end
				else
					local ok, result = pcall (index, instance, propertyName)

					if ok then
						raw = result
					elseif gethiddenproperty then
						ok, result = pcall (gethiddenproperty, instance, propertyName)

						if ok then
							raw = result

							property.Special = true
						end
					end

					property.CanRead = ok

					if not ok or filterPropVal (raw, propertyName, category) then return __BREAK end
				end
			end

			return raw
		end

		local function ReturnItem (className, instance)
			return "<Item class=\"" .. className .. "\" referent=\"" .. GetRef (instance) .. "\"><Properties>"
		end

		local function ReturnProperty (tag, propertyName, value)
			return "<" .. tag .. " name=\"" .. propertyName .. "\">" .. value .. "</" .. tag .. ">"
		end

		local function ReturnValueAndTag (raw, valueType, descriptor)
			local value, tag = (descriptor or XmlDescriptors[valueType]) (raw)

			return value, tag or valueType
		end

		local function InheritsFix (fixes, className, instance)
			local Fix = fixes[className]
			if Fix then
				return Fix
			elseif Fix == nil then
				for ClassName, fix in fixes do
					if instance:IsA (ClassName) then return fix end
				end
			end
		end

		local function GetInheritedProps (className)
			local cached = InheritedProperties[className]
			if cached then return cached end

			local PropList = {}
			local layer = ClassList[className]
			while layer do
				local LayerProps = layer.Properties
				table.move (LayerProps, 1, #LayerProps, #PropList + 1, PropList)

				layer = ClassList[layer.Superclass]
			end
			InheritedProperties[className] = PropList
			return PropList
		end

		local function SaveCache ()
			local savestr = table.concat (savebuffer)

			local SavestrLen = #savestr
			totalsize += SavestrLen

			table.insert (chunks, savestr)

			table.clear (savebuffer)
			SavebufferSize = 1

			if StatusText then StatusText.Text = "Saving.. Size: " .. GetSizeFormat () end

			WaitForRender ()
		end

		local function SaveSpecific (className, properties)
			local Item = ReturnItem (className, {})

			for propertyName, val in properties do
				local whitelisted, value, tag

				if propertyName == "Source" then
					tag = "ProtectedString"
					value = XmlDescriptors.__PROTECTEDSTRING (val)
					whitelisted = true
				elseif propertyName == "Name" then
					whitelisted = true
					value, tag = ReturnValueAndTag (val, "string")
				end

				if whitelisted then
					Item ..= ReturnProperty (tag, propertyName, value)
				end
			end
			Item ..= "</Properties>"
			return Item
		end

		local GethiddenpropertyFallback

		local function SaveHierarchy (hierarchy)
			for _, instance in hierarchy do
				local InstanceOverride, ClassTagOverride, ClassNameOverride

				if not InstanceOverride then
					InstanceOverride = InstancesOverrides[instance]
					if InstanceOverride then ClassTagOverride = InstanceOverride.__ClassName end
				end
				local ClassName = instance.ClassName

				local InstanceName = instance.Name
				local SkipEntirely

				if not ClassTagOverride then
					if IgnoreNotArchivable and not instance.Archivable then continue end

					SkipEntirely = IgnoreList[instance]
					if SkipEntirely then continue end

					do
						local OnIgnoredList = IgnoreList[ClassName]
						if OnIgnoredList and (OnIgnoredList == true or OnIgnoredList[InstanceName]) then continue end
					end

					if not DecompileIgnoring then
						DecompileIgnoring = DecompileIgnore[instance]

						if DecompileIgnoring == nil then
							local DecompileIgnored = DecompileIgnore[ClassName]
							if DecompileIgnored then
								DecompileIgnoring = DecompileIgnored == true or DecompileIgnored[InstanceName]
							end
						end

						if DecompileIgnoring then
							DecompileIgnoring = instance
						elseif DecompileIgnoring == false then
							DecompileIgnoring = 1
						end
					end

					do
						local Fix = NotCreatableFixes[ClassName]

						if Fix then
							if SaveNotCreatable then
								ClassName, InstanceOverride = Fix, replaceClassName (instance, InstanceName, ClassName)
							else
								continue
							end
						else
							if TreatUnionsAsParts and instance:IsA ("PartOperation") then
								ClassName, InstanceOverride =
									"Part", replaceClassName (instance, InstanceName, ClassName)
								ClassNameOverride = "BasePart"
							elseif not ClassList[ClassName] then
								if DebugMode then DebugMode ("Class not Found", ClassName) end

								ClassTagOverride = ClassName
								ClassName = "Folder"
							end
						end
					end
				end

				if InstanceOverride and InstanceOverride.__SaveSpecific then
					savebuffer[SavebufferSize] = SaveSpecific (ClassName, InstanceOverride.Properties)
					SavebufferSize += 1
				else
					savebuffer[SavebufferSize] = ReturnItem (ClassTagOverride or ClassName, instance)
					SavebufferSize += 1
					if not (IgnorePropertiesOfNotScriptsOnScriptsMode and not isLuaSourceContainer (instance)) then
						local DefaultInstance, NewDefInst

						if IgnoreDefaultProperties then
							DefaultInstance = DefaultInstances[ClassName]
							if not DefaultInstance then
								local Class = ClassList[ClassName]
								if not Class.NotCreatable then
									local ok, result = pcall (U.Create, ClassName)

									if ok then
										NewDefInst = result

										DefaultInstance = {}

										DefaultInstances[ClassName] = DefaultInstance
									else
										Class.NotCreatable = true
										if DebugMode then
											DebugMode ("Failed to create default Instance", ClassName, result)
										end
									end
								elseif DebugMode then
									DebugMode ("Unable to create default Instance (NotCreatable)", ClassName)
								end
							end
						end

						for _, Property in GetInheritedProps (ClassNameOverride or ClassName) do
							local PropertyName = Property.Name

							if IgnoreProperties[PropertyName] then continue end

							local ValueType = Property.ValueType

							if IgnoreSharedStrings and ValueType == "SharedString" then continue end

							local Special, Category, Optional = Property.Special, Property.Category, Property.Optional
							local raw
							if
								not (
									ValueType == "ProtectedString"
									and PropertyName == "Source"
									and isLuaSourceContainer (instance)
								)
							then
								raw = ReadProperty (instance, Property, PropertyName, Special, Category, Optional)

								if raw == __BREAK then
									local GHPFFailed, Fallback = Property.GHPFFailed, Property.Fallback
									if GHPFFailed and not Fallback then continue end

									if not GHPFFailed then
										local ok, result = pcall (GethiddenpropertyFallback, instance, PropertyName)
										if result == nil and not Optional then ok = nil end

										if ok then
											raw = result
										else
											GHPFFailed = true
											Property.GHPFFailed = GHPFFailed
										end
									end

									if GHPFFailed and Fallback then
										local ok, result = pcall (Fallback, instance)

										if ok then
											raw = result
										else
											Property.Fallback = nil
											if DebugMode then DebugMode ("Fix Failed", PropertyName, result) end
											continue
										end
									end

									if raw == __BREAK then continue end
								end

								if DefaultInstance and Property.CanRead and not Property.Special then
									if NewDefInst then
										local okDefault, defaultValue = pcall (index, NewDefInst, PropertyName)
										if okDefault then DefaultInstance[PropertyName] = defaultValue end
									end
									if DefaultInstance[PropertyName] == raw then continue end
								end
							end

							if SharedStringOverwrite and ValueType == "BinaryString" then ValueType = "SharedString" end

							if AnonymizableTypes and AnonymizableTypes[ValueType] then
								if ValueType == "string" then
									raw = gsubCaseInsensitive (raw, LPName, ANONName)
								elseif raw == LPUserId then
									raw = ANONUserId
								end
							end

							local tag, value
							if Category == "Class" then
								tag = "Ref"
								if raw then
									if SaveNotCreatableWillBeEnabled then
										local Fix = NotCreatableFixes[raw.ClassName]
										if
											Fix
											and (
												PropertyName == "PlayerToHideFrom"
												or ValueType ~= "Instance" and ValueType ~= Fix
											)
										then
											continue
										end
									end

									value = GetRef (raw)
								else
									value = "null"
								end
							elseif Category == "Enum" then
								value, tag = XmlDescriptors.EnumItem (raw)
							else
								local Descriptor = XmlDescriptors[ValueType]

								if Descriptor then
									value, tag = ReturnValueAndTag (raw, ValueType, Descriptor)
								elseif ValueType == "ProtectedString" then
									tag = ValueType

									if PropertyName == "Source" then
										if DecompileIgnoring then
											if DecompileIgnoring == 1 then DecompileIgnoring = nil end
											value = "-- Ignored"
										else
											local ShouldDecompile = true
											local LinkedSource
											local o, LinkedSourceUrl = pcall (index, instance, "LinkedSource")
											if not o then LinkedSourceUrl = "" end
											local hasLinkedSource = LinkedSourceUrl ~= ""
											local LinkedSourceType
											if hasLinkedSource then
												local Path = instance:GetFullName ()
												if RecoveredScripts then table.insert (RecoveredScripts, Path) end

												LinkedSource = string.match (LinkedSourceUrl, "%w+$")
												if LinkedSource then
													if ScriptCache then
														local cached = ldeccache[LinkedSource]

														if cached then
															value = cached
															ShouldDecompile = nil
														end
													end
													if ShouldDecompile then
														if DecompileJobless then
															value = "-- Not found in LinkedSource ScriptCache"
															ShouldDecompile = nil
														end

														LinkedSourceType = string.find (LinkedSource, "%a") and "hash"
															or "id"

														local asset = LinkedSourceType .. "=" .. LinkedSource

														local ok, source = pcall (function ()
															return game:HttpGet (
																"https://assetdelivery.roproxy.com/v1/asset/?" .. asset
															)
														end)

														if ok and filterLinkedSource (source) then
															if ScriptCache then ldeccache[LinkedSource] = source end

															value = source

															ShouldDecompile = nil
														end
													end
												else
													warn (
														"FAILED TO EXTRACT ORIGINAL SCRIPT SOURCE (OPEN A GITHUB ISSUE): ",
														instance:GetFullName (),
														LinkedSourceUrl
													)
												end
											end

											if ShouldDecompile then
												local isLocalScript = instance:IsA ("LocalScript")
												if
													isLocalScript and instance.RunContext == Enum.RunContext.Server
													or not isLocalScript
														and instance:IsA ("Script")
														and instance.RunContext ~= Enum.RunContext.Client
												then
													value =
														"-- [FilteringEnabled] Server Scripts are IMPOSSIBLE to save"
												else
													value = ldecompile (instance)
													if SaveBytecode then
														local output = SaveBytecode (instance)
														if output then value = output .. value end
													end
												end
											end

											value = "-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw\n\n"
												.. (hasLinkedSource and "-- Original Source: https://assetdelivery.roblox.com/v1/asset/?" .. (LinkedSourceType or "id") .. "=" .. (LinkedSource or LinkedSourceUrl) .. "\n\n" or "")
												.. value
										end
									end
									value = XmlDescriptors.__PROTECTEDSTRING (value)
								else
									if Optional then
										Descriptor = XmlDescriptors[Optional]

										if Descriptor then
											if raw == nil then
												continue
											else
												value, tag = ReturnValueAndTag (raw, ValueType, Descriptor)
											end
										end
									end
								end
							end

							if tag then
								savebuffer[SavebufferSize] = ReturnProperty (tag, PropertyName, value)
								SavebufferSize += 1
							else
								warn ("UNSUPPORTED TYPE (OPEN A GITHUB ISSUE): ", ValueType, ClassName, PropertyName)
							end
						end
					end
					savebuffer[SavebufferSize] = "</Properties>"
					SavebufferSize += 1

					if SaveCacheInterval < SavebufferSize then SaveCache () end
				end

				if SkipEntirely ~= false then
					local Children = InstanceOverride and InstanceOverride.__Children or instance:GetChildren ()

					if #Children ~= 0 then SaveHierarchy (Children) end
				end

				if DecompileIgnoring and DecompileIgnoring == instance then DecompileIgnoring = nil end

				savebuffer[SavebufferSize] = "</Item>"
				SavebufferSize += 1
			end
		end

		local function SaveExtra (name, instanceOrTable, saveProps, customClassName, source)
			if not customClassName then customClassName = "Folder" end

			local properties = { Name = name, Source = source }
			local hierarchy

			if instanceOrTable then
				if type (instanceOrTable) == "table" then
					hierarchy = instanceOrTable
				else
					hierarchy = instanceOrTable:GetChildren ()
					if saveProps then
						InstancesOverrides[instanceOrTable] = {
							__ClassName = customClassName,

							Properties = properties,
						}

						SaveHierarchy ({ instanceOrTable })
					end
				end
			end

			if not saveProps then
				savebuffer[SavebufferSize] = SaveSpecific (customClassName, properties)
				SavebufferSize += 1
				if hierarchy then SaveHierarchy (hierarchy) end
				savebuffer[SavebufferSize] = "</Item>"
				SavebufferSize += 1
			end
		end

		local function SaveGame ()
			do
				if IsModel then
					header ..= "<Meta name=\"ExplicitAutoJoints\">true</Meta>"
				end
				if writefile and not Options.Callback then writefile (placename, header) end
			end

			SaveNotCreatableWillBeEnabled = SaveNotCreatable
				or (IsolateLocalPlayer or IsolateLocalPlayerCharacter) and IsolateLocalPlayer
				or IsolatePlayers
				or NilInstances and GlobalContainer.getnilinstances

			SaveHierarchy (ToSaveList)

			if IsolateLocalPlayer or IsolateLocalPlayerCharacter then
				local LocalPlayer = service.Players.LocalPlayer
				if LocalPlayer then
					if IsolateLocalPlayer then
						SaveNotCreatable = true
						SaveExtra ("LocalPlayer", LocalPlayer, true)
					end
					if IsolateLocalPlayerCharacter then
						local LocalPlayerCharacter = LocalPlayer.Character
						if LocalPlayerCharacter then
							SaveExtra ("LocalPlayer Character", LocalPlayerCharacter, true, "Model")
						end
					end
				end
			end

			if IsolateStarterPlayer then SaveExtra ("StarterPlayer", service.StarterPlayer) end

			if IsolatePlayers then
				SaveNotCreatable = true
				SaveExtra ("Players", service.Players)
			end

			if NilInstances and GlobalContainer.getnilinstances then
				local NilInstanceList, NilInstancesSize = {}, 1

				local NilInstancesFixes = Options.NilInstancesFixes

				for _, instance in GlobalContainer.getnilinstances () do
					if instance == game then
						instance = nil
					else
						local ClassName = instance.ClassName

						local Fix = InheritsFix (NilInstancesFixes, ClassName, instance)

						if Fix then instance = Fix (instance, InstancesOverrides) end

						local Class = ClassList[ClassName]
						if Class then
							if Class.Service then instance = nil end
						end
					end
					if instance then
						NilInstanceList[NilInstancesSize] = instance
						NilInstancesSize += 1
					end
				end
				SaveNotCreatable = true
				SaveExtra ("Nil Instances", NilInstanceList)
			end

			if Options.ReadMe then
				SaveExtra (
					"README",
					nil,
					nil,
					"Script",
					"--[[\n"
						.. (#RecoveredScripts ~= 0 and "\t\tIMPORTANT: Original Source of these Scripts was Recovered: " .. service.HttpService:JSONEncode (
							RecoveredScripts
						) .. "\n" or "")
						.. [[
		Thank you for using UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw.

		If you didn't save in Binary (rbxl) - it's recommended to save the game right away to take advantage of the binary format & to preserve values of certain properties if you used IgnoreDefaultProperties setting (as they might change in the future).
		You can do that by going to FILE -> Save to File As -> Make sure File Name ends with .rbxl -> Save

		ServerStorage, ServerScriptService and Server Scripts are IMPOSSIBLE to save because of FilteringEnabled.

		If your player cannot spawn into the game, please move the scripts in StarterPlayer somewhere else or delete them. Then run `game:GetService("Players").CharacterAutoLoads = true`.
		And use "Play Here" to start game instead of "Play" to spawn your Character where your Camera currently is.

		If the chat system does not work, please use the explorer and delete everything inside the TextChatService/Chat service(s). 
		Or run `game:GetService("Chat"):ClearAllChildren() game:GetService("TextChatService"):ClearAllChildren()`
				
		If Union and MeshPart collisions don't work, run the script below in the Studio Command Bar:
				
				
		local C = game:GetService("CoreGui")
		local D = Enum.CollisionFidelity.Default
				
		for _, v in game:GetDescendants() do
			if v:IsA("TriangleMeshPart") and not v:IsDescendantOf(C) then
				v.CollisionFidelity = D
			end
		end
		print("Done")
				
		If you can't move the Camera, run this script in the Studio Command Bar:
			
		workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
		
		Or Destroy the Camera.

		This file was generated with the following settings:
		]]
						.. service.HttpService:JSONEncode (Options)
						.. "\n\n\t\tElapsed time: "
						.. os.clock () - ElapseT
						.. " Date (UTC): "
						.. DateTime.now ():FormatUniversalTime ("LL LTS", "en-gb")
						.. " PlaceId: "
						.. game.PlaceId
						.. " PlaceVersion: "
						.. game.PlaceVersion
						.. " Client Version: "
						.. FullVersion
						.. " Platform: "
						.. (select (
							2,
							pcall (function ()
								return service.UserInputService:GetPlatform ().Name
							end)
						) or "Unknown")
						.. " Executor: "
						.. (IdentifyExecutor and table.concat ({ IdentifyExecutor () }, " ") or "Unknown")
						.. "\n]]"
				)
			end
			do
				local tmp = { "<SharedStrings>" }
				for value, identifier in SharedStrings do
					table.insert (tmp, "<SharedString md5=\"" .. identifier .. "\">" .. value .. "</SharedString>")
				end

				if 1 < #tmp then
					savebuffer[SavebufferSize] = table.concat (tmp)
					SavebufferSize += 1
					savebuffer[SavebufferSize] = "</SharedStrings>"
					SavebufferSize += 1
				end
			end

			savebuffer[SavebufferSize] =
				"</roblox><!-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw -->"
			SavebufferSize += 1
			SaveCache ()
			do
				local function buildFinalString (chunks)
					local parts = table.create (#chunks + 1)
					parts[1] = header

					table.move (chunks, 1, #chunks, 2, parts)

					return table.concat (parts)
				end

				local Callback = Options.Callback
				if Callback then
					Callback (buildFinalString (chunks), chunks)
				elseif Options.AlternativeWritefile and appendfile then
					local totallen = 0
					for _, chunk in chunks do
						totallen += math.ceil (#chunk / 4145728)
					end

					local currentlen = 0

					for _, chunk in chunks do
						local ChunkLen = #chunk
						local offset = 1

						while offset <= ChunkLen do
							local savestr = string.sub (chunk, offset, offset + 4145728 - 1)

							RunWithLoading (
								"Writing to File " .. math.round (currentlen / totallen * 100) .. "% (Depends on Exec)",
								nil,
								true,
								appendfile,
								placename,
								savestr
							)

							currentlen += 1
							offset += 4145728

							if offset <= ChunkLen then task.wait () end
						end
					end
				else
					RunWithLoading (
						"Writing " .. GetSizeFormat () .. " to File (Depends on Exec)",
						nil,
						true,
						writefile,
						placename,
						buildFinalString (chunks)
					)
				end
			end
		end

		local Connections = {}
		local function Connect (event, func)
			table.insert (Connections, event:Connect (func))
		end
		local function Cleanup ()
			for _, connection in Connections do
				connection:Disconnect ()
			end
			GlobalEnv[placename] = nil
			GlobalEnv.USSI = nil
			if StatusGui then
				pcall (function ()
					StatusGui:Destroy ()
				end)
				if GlobalEnv._statustext == StatusGui then GlobalEnv._statustext = nil end
				StatusGui = nil
			end
			if OldGetHiddenProperty then
				gethiddenproperty = OldGetHiddenProperty
				OldGetHiddenProperty = nil
			end
		end
		do
			local Players = service.Players

			if IgnoreList.Model ~= true then
				local function ignoreCharacter (player)
					Connect (player.CharacterAdded, function (character)
						IgnoreList[character] = true
					end)

					local Character = player.Character
					if Character then IgnoreList[Character] = true end
				end

				if not Options.SavePlayerCharacters then
					Connect (Players.PlayerAdded, function (player)
						ignoreCharacter (player)
					end)

					for _, player in Players:GetPlayers () do
						ignoreCharacter (player)
					end
				else
					IgnoreNotArchivable = false
					if IsolateLocalPlayerCharacter then
						task.spawn (function ()
							ignoreCharacter (GetLocalPlayer ())
						end)
					end
				end
			end
			if IsolateLocalPlayer and IgnoreList.Player ~= true then
				task.spawn (function ()
					IgnoreList[GetLocalPlayer ()] = true
				end)
			end
		end

		if Options.KillAllScripts and not GlobalEnv.UssiKas then
			GlobalEnv.UssiKas = true

			game:GetService ("ScriptContext"):SetTimeout (math.clamp (SaveCacheInterval * 0.000047, 20, 30))

			local self = coroutine.running ()
			do
				local islclosure = islclosure
				local isexecutorclosure = isexecutorclosure or checkclosure or isourclosure
				local hookfunction = not ArrayToDict ({ "SirHurt", "Volt" })[ExecutorName] and hookfunction

				local function filterNkill (f)
					if not f then return end

					for _, v in table.clone (f ()) do
						local _type = type (v)
						if _type == "thread" then
							if v ~= self then pcall (coroutine.close, v) end
						elseif _type == "function" then
							if
								(not islclosure or islclosure (v))
								and (not isexecutorclosure or not isexecutorclosure (v))
							then
								if hookfunction then pcall (hookfunction, v, coroutine.yield) end
							end
						end
					end
				end

				filterNkill (debug and debug.getregistry or getreg or getregistry)
				filterNkill (getallthreads)
				filterNkill (getgc)
			end
		end

		if IsolateStarterPlayer then IgnoreList.StarterPlayer = false end

		if IsolatePlayers then IgnoreList.Players = false end

		if Options.ShowStatus then
			do
				local Exists = GlobalEnv._statustext
				if Exists then Exists:Destroy () end
			end

			StatusGui = U.Create ("ScreenGui", {
				DisplayOrder = 2e9,
			})

			GlobalEnv._statustext = StatusGui

			pcall (function ()
				StatusGui.OnTopOfCoreBlur = true
			end)

			StatusText = U.Create ("TextLabel", {
				Text = "Saving...",
				BackgroundTransparency = 1,
				Font = Enum.Font.Code,
				AnchorPoint = Vector2.new (1),
				Position = UDim2.new (1),
				Size = UDim2.new (0.3, 0, 0, 20),
				TextColor3 = Color3.new (1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = 0.7,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = StatusGui,
			})

			local function randomString ()
				local length = math.random (10, 20)
				local randomarray = table.create (length)
				for i = 1, length do
					randomarray[i] = string.char (math.random (32, 126))
				end
				return table.concat (randomarray)
			end

			if GlobalContainer.gethui then
				StatusGui.Name = randomString ()
				StatusGui.Parent = GlobalContainer.gethui ()
			else
				if GlobalContainer.protectgui then
					StatusGui.Name = randomString ()
					GlobalContainer.protectgui (StatusGui)
					StatusGui.Parent = game:GetService ("CoreGui")
				else
					local RobloxGui = game:GetService ("CoreGui"):FindFirstChild ("RobloxGui")
					if RobloxGui then
						StatusGui.Parent = RobloxGui
					else
						StatusGui.Name = randomString ()
						StatusGui.Parent = game:GetService ("CoreGui")
					end
				end
			end
		end

		do
			if Options.SafeMode then
				task.spawn (function ()
					local LocalPlayer = GetLocalPlayer ()

					local PlayerScripts = LocalPlayer:FindFirstChildOfClass ("PlayerScripts")
					if PlayerScripts then
						local function ConstructInstanceOverride (instance)
							local children = instance:GetChildren ()
							InstancesOverrides[instance] = {
								__Children = children,
							}
							for _, child in children do
								ConstructInstanceOverride (child)
							end
						end
						ConstructInstanceOverride (PlayerScripts)

						InstancesOverrides[LocalPlayer] = {
							__Children = LocalPlayer:GetChildren (),
							Properties = { Name = "[" .. LocalPlayer.ClassName .. "] " .. LocalPlayer.Name },
						}
					end
					local msg =
						"[SAVEINSTANCE SAFEMODE]\nSaving..\nDo NOT leave\nLVL7 Executor RECOMMENDED for more SAFETY\nTo Disable this: SafeMode=false (Less Protection)"
					local function Kick ()
						LocalPlayer:Kick (msg)
					end

					Kick ()
					pcall (function ()
						Connect (service.GuiService.ErrorMessageChanged, function ()
							if service.GuiService:GetErrorMessage () ~= msg then Kick () end
						end)
					end)
					WaitForRender ()
				end)

				if CustomOptionsValid["BoostFPS"] == nil then Options.BoostFPS = true end
			end

			if Options.BoostFPS then pcall (function ()
				service.RunService:Set3dRenderingEnabled (false)
			end) end

			if Options.AntiIdle then
				local Idled = GetLocalPlayer ().Idled
				Connect (Idled, function ()
					service.VirtualInputManager:SendMouseWheelEvent (
						service.UserInputService:GetMouseLocation ().X,
						service.UserInputService:GetMouseLocation ().Y,
						true,
						game
					)
				end)
			end

			do
				local UGCValidationService

				GethiddenpropertyFallback = function (instance, propertyName)
					if not UGCValidationService then UGCValidationService = service.UGCValidationService end
					return UGCValidationService:GetPropertyValue (instance, propertyName)
				end
			end

			if not ClassList then
				do
					if gethiddenproperty then
						local o, r = pcall (gethiddenproperty, workspace, "StreamOutBehavior")
						if not o or r ~= nil and typeof (r) ~= "EnumItem" then
							gethiddenproperty = nil
						else
							o, r = pcall (
								gethiddenproperty,
								U.Create ("AnimationRigData", nil, U.Create ("Folder")),
								"parent"
							)

							if o and r ~= nil and type (r) ~= "string" then gethiddenproperty = nil end
						end
					end
					local function benchmark (funcs, ...)
						local ranking = table.create (2)
						for i, f in funcs do
							local start = os.clock ()
							for _ = 1, 50 do
								f (...)
							end
							ranking[i] = { t = os.clock () - start, f = f }
						end
						table.sort (ranking, function (a, b)
							return a.t < b.t
						end)
						return ranking[1].f
					end

					local TestStr = string.rep ("\1\0\0\0\1\2\3\4\5\6\7", 50)

					do
						if
							not bit32.byteswap
							or not (function ()
								local o, r = pcall (bit32.byteswap, 2712847316)
								if not o then return end
								return r == 3569595041
							end) ()
						then
							local b32 = table.clone (bit32)

							b32.byteswap = function (n)
								return bit32.bor (
									bit32.lshift (n, 24),
									bit32.band (bit32.lshift (n, 8), 0xFF0000),
									bit32.band (bit32.rshift (n, 8), 0xFF00),
									bit32.rshift (n, 24)
								)
							end
							if table.isfrozen (bit32) then b32 = table.freeze (b32) end
							GlobalEnv.bit32 = b32
						end

						local RbxCryptBase64Encode
						pcall (function ()
							local B64EncBuf = loadstring (
								game:HttpGet (
									"https://raw.githubusercontent.com/daily3014/rbx-cryptography/refs/heads/main/src/Utilities/Base64.luau",
									true
								),
								"Base64"
							) ().Encode
							RbxCryptBase64Encode = function (raw)
								return buffer.tostring (B64EncBuf (buffer.fromstring (raw)))
							end
						end)

						local EncodingService = game:GetService ("EncodingService")
						local EncodingServiceBase64Encode = function (raw)
							return buffer.tostring (EncodingService:Base64Encode (buffer.fromstring (raw)))
						end

						if base64encode and base64encode ("\1\0\0\0\1") == "AQAAAAE=" then
							if RbxCryptBase64Encode then
								base64encode = benchmark (
									{ base64encode, RbxCryptBase64Encode, EncodingServiceBase64Encode },
									TestStr
								)
							end
						else
							base64encode = RbxCryptBase64Encode
						end

						if not base64encode then
							warn ("base64encode not found")
							Cleanup ()
							return
						end
					end
				end
				do
					local ok, result = pcall (FetchAPI)
					if ok then
						ClassList = result
					else
						warn ("Failed to load the API Dump")
						warn (result)
						Cleanup ()
						return
					end
				end
			end

			ElapseT = os.clock ()

			local ok, err = xpcall (SaveGame, function (err)
				return debug.traceback (err)
			end)

			if Options.BoostFPS then
				pcall (function ()
					local max = 5
					task.delay (
						math.clamp (max - (os.clock () - ElapseT), 0, max),
						service.GuiService.ClearError,
						service.GuiService
					)
					service.RunService:Set3dRenderingEnabled (true)
				end)
			end

			if OldGetHiddenProperty then gethiddenproperty = OldGetHiddenProperty end

			Cleanup ()

			ElapseT = os.clock () - ElapseT
			local Log10 = math.log10 (ElapseT)
			local ExtraTime = 10

			if StatusText then
				task.spawn (function ()
					if ok then
						StatusText.Text =
							string.format ("Saved! Time %.3f seconds; Size %s", ElapseT, GetSizeFormat ())
						StatusText.TextColor3 = Color3.new (0, 1)
						task.wait (Log10 * 2 + ExtraTime)
					else
						if Loading then
							task.cancel (Loading)
							Loading = nil
						end
						StatusText.Text = "Failed! Check F9 console for more info"
						StatusText.TextColor3 = Color3.new (1)
						warn ("Error found while saving:")
						warn (err)
						task.wait (Log10 + ExtraTime)
					end
					StatusText:Destroy ()
				end)
			end

			if Options.ShutdownWhenDone and ok then
				task.wait (Log10 * 2 + ExtraTime)
				game:Shutdown ()
			end
		end
	end

	return synsaveinstance
end

local universalSaveInstance = nil
function Dex:LoadUniversalSaveInstance ()
	if universalSaveInstance == nil then
		local ok, result = pcall (loadUniversalSaveInstance)
		if not ok then error (result) end
		universalSaveInstance = result
	end
	return universalSaveInstance
end
