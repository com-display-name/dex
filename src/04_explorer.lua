local U = Dex.Utils
local UIS = UserInputService
local RunService = RunService

local Explorer = {
	Expanded = {},
	HiddenServices = {},
	SortByName = false,
	Flat = {},
	RowPool = {},
	RowEntries = {},
	RowMeta = {},
	Clipboard = nil,
	Anchor = nil,
	SearchHistory = {},
	Renaming = nil,
	PickingMode = nil,
	Frozen = false,
	Pinned = {},
	ChildrenCache = {},
}

setmetatable (Explorer.ChildrenCache, { __mode = "k" })

Dex.Explorer = Explorer

local SelectionHighlight = {
	Enabled = false,
	Parts = {},
	Guis = {},
}
Dex.SelectionHighlight = SelectionHighlight


function SelectionHighlight:Clear ()
	for _, entry in pairs (self.Parts) do
		if type (entry) == "table" then
			pcall (function ()
				entry.Box:Destroy ()
			end)
			pcall (function ()
				entry.Proxy:Destroy ()
			end)
		else
			pcall (function ()
				entry:Destroy ()
			end)
		end
	end
	for _, stroke in pairs (self.Guis) do
		pcall (function ()
			stroke:Destroy ()
		end)
	end
	table.clear (self.Parts)
	table.clear (self.Guis)
end

local function createSelectionBox (adornee, accent)
	local box = U.Create ("SelectionBox", {
		Name = "DexSelectionHighlight",
		Adornee = adornee,
		LineThickness = 0.08,
		SurfaceTransparency = 1,
	})

	box.Color3 = accent
	box.SurfaceColor3 = accent
	box.Transparency = 0
	box.Visible = true

	box.Parent = workspace
	return box
end

function SelectionHighlight:Refresh ()
	self:Clear ()
	if not self.Enabled or not Dex.Selection then return end
	local accent = Dex.Theme.Common.Accent or Color3.fromRGB (74, 108, 255)
	for _, object in ipairs (Dex.Selection.List or {}) do
		if typeof (object) == "Instance" then
			local ok, isGui = pcall (function ()
				return object:IsA ("GuiObject")
			end)
			if ok and isGui then
				local existing = object:FindFirstChild ("DexSelectionHighlight")
				if existing then pcall (function ()
					existing:Destroy ()
				end) end
				local stroke = U.Create ("UIStroke", {
					Name = "DexSelectionHighlight",
					Color = accent,
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = object,
				})
				self.Guis[object] = stroke
			else
				local okPart, isPart = pcall (function ()
					return object:IsA ("BasePart")
				end)
				if okPart and isPart then
					self.Parts[object] = createSelectionBox (object, accent)
				else
					local okModel, isModel = pcall (function ()
						return object:IsA ("Model")
					end)
					if okModel and isModel then
						local okBounds, focus, size = pcall (function ()
							return object:GetBoundingBox ()
						end)
						if okBounds and focus and size then
							local proxy = U.Create ("Part", {
								Name = "DexSelectionHighlight",
								Size = Vector3.new (
									math.max (0.1, size.X),
									math.max (0.1, size.Y),
									math.max (0.1, size.Z)
								),
								CFrame = focus,
								Transparency = 1,
								CanCollide = false,
								Anchored = true,
								Archivable = false,
								Parent = workspace,
							})
							local box = createSelectionBox (proxy, accent)
							self.Parts[object] = { Box = box, Proxy = proxy }
						end
					end
				end
			end
		end
	end
end

function SelectionHighlight:SetEnabled (enabled)
	self.Enabled = enabled == true
	self:Refresh ()
end

Dex:Track (Dex.SelectionChanged:Connect (function ()
	if SelectionHighlight.Enabled then SelectionHighlight:Refresh () end
end))

function Explorer:StopView ()
	if self._ViewConnection then
		pcall (function ()
			self._ViewConnection:Disconnect ()
		end)
		self._ViewConnection = nil
	end
	self.ViewTarget = nil
	if self._ViewRestoreSubject ~= nil then
		local camera = workspace and workspace.CurrentCamera
		if camera then pcall (function ()
			camera.CameraSubject = self._ViewRestoreSubject
		end) end
		self._ViewRestoreSubject = nil
	end
end

local function resolveViewSubject (instance)
	if typeof (instance) ~= "Instance" then return nil end
	local ok, subject = pcall (function ()
		if instance:IsA ("Player") then
			local character = instance.Character
			if not character then return nil end
			local humanoid = character:FindFirstChildOfClass ("Humanoid")
			if humanoid then return humanoid end
			return character:FindFirstChild ("HumanoidRootPart")
		elseif instance:IsA ("Humanoid") then
			return instance
		elseif instance:IsA ("BasePart") then
			return instance
		elseif instance:IsA ("Model") then
			return instance.PrimaryPart or instance:FindFirstChildWhichIsA ("BasePart", true)
		end
		return instance:FindFirstChildWhichIsA ("BasePart", true)
	end)
	return ok and subject or nil
end

function Explorer:ViewInstance (instance)
	local camera = workspace and workspace.CurrentCamera
	if not camera then
		Dex:Notify ("No current camera", "error")
		return
	end
	if self.ViewTarget == instance then
		self:StopView ()
		return
	end
	local subject = resolveViewSubject (instance)
	if not subject then
		Dex:Notify ("Nothing to view for " .. tostring (instance and instance.Name or "that instance"), "info")
		return
	end
	self:StopView ()
	self._ViewRestoreSubject = camera.CameraSubject
	self.ViewTarget = instance
	pcall (function ()
		camera.CameraSubject = subject
	end)
	self._ViewConnection = subject.AncestryChanged:Connect (function (_, parent)
		if not parent and self.ViewTarget == instance then self:StopView () end
	end)
end

function Explorer:IsViewing (instance)
	return self.ViewTarget ~= nil and (instance == nil or self.ViewTarget == instance)
end

local function sanitizeSaveName (name)
	name = tostring (name or ""):gsub ("[\\/:*?\"<>|]", "")
	name = name:gsub ("^%s+", ""):gsub ("%s+$", "")
	if name == "" then name = "game" end
	return name
end

local SerializeSkip = {
	Parent = true,
	ClassName = true,
	Archivable = true,
	RobloxLocked = true,
	DataCost = true,
	UniqueId = true,
	Capabilities = true,
	Container = true,
	LocalPlayer = true,
	Character = true,
	Attributes = true,
}

local function serializeValue (value)
	local valueType = typeof (value)
	if valueType == "string" then
		return string.format ("%q", value)
	elseif valueType == "number" then
		if value ~= value or value == math.huge or value == -math.huge then return nil end
		if math.floor (value) == value and math.abs (value) < 1e15 then return tostring (math.floor (value)) end
		return string.format ("%.10g", value)
	elseif valueType == "boolean" then
		return tostring (value)
	elseif valueType == "Color3" then
		return string.format (
			"Color3.fromRGB(%d, %d, %d)",
			math.floor (value.R * 255 + 0.5),
			math.floor (value.G * 255 + 0.5),
			math.floor (value.B * 255 + 0.5)
		)
	elseif valueType == "BrickColor" then
		return string.format ("BrickColor.new(%q)", value.Name)
	elseif valueType == "Vector3" then
		return string.format ("Vector3.new(%.10g, %.10g, %.10g)", value.X, value.Y, value.Z)
	elseif valueType == "Vector2" then
		return string.format ("Vector2.new(%.10g, %.10g)", value.X, value.Y)
	elseif valueType == "Vector3int16" then
		return string.format ("Vector3int16.new(%d, %d, %d)", value.X, value.Y, value.Z)
	elseif valueType == "Vector2int16" then
		return string.format ("Vector2int16.new(%d, %d)", value.X, value.Y)
	elseif valueType == "UDim" then
		return string.format ("UDim.new(%.10g, %.10g)", value.Scale, value.Offset)
	elseif valueType == "UDim2" then
		return string.format (
			"UDim2.new(%.10g, %.10g, %.10g, %.10g)",
			value.X.Scale,
			value.X.Offset,
			value.Y.Scale,
			value.Y.Offset
		)
	elseif valueType == "Rect" then
		return string.format ("Rect.new(%.10g, %.10g, %.10g, %.10g)", value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
	elseif valueType == "CFrame" then
		local components = { value:GetComponents () }
		local parts = {}
		for index, component in ipairs (components) do
			parts[index] = string.format ("%.10g", component)
		end
		return "CFrame.new(" .. table.concat (parts, ", ") .. ")"
	elseif valueType == "NumberRange" then
		return string.format ("NumberRange.new(%.10g, %.10g)", value.Min, value.Max)
	elseif valueType == "NumberSequence" then
		local parts = {}
		for _, key in ipairs (value.Keypoints) do
			parts[#parts + 1] =
				string.format ("NumberSequenceKeypoint.new(%.10g, %.10g, %.10g)", key.Time, key.Value, key.Envelope)
		end
		return "NumberSequence.new({" .. table.concat (parts, ", ") .. "})"
	elseif valueType == "ColorSequence" then
		local parts = {}
		for _, key in ipairs (value.Keypoints) do
			parts[#parts + 1] = string.format (
				"ColorSequenceKeypoint.new(%.10g, %s)",
				key.Time,
				tostring (serializeValue (key.Value) or "Color3.new()")
			)
		end
		return "ColorSequence.new({" .. table.concat (parts, ", ") .. "})"
	elseif valueType == "EnumItem" then
		return "Enum." .. tostring (value.EnumType) .. "." .. value.Name
	end
	return nil
end

local function valuesEqual (a, b)
	if a == b then return true end
	if typeof (a) ~= typeof (b) then return false end
	return tostring (a) == tostring (b)
end

local function instancePath (instance)
	if typeof (instance) ~= "Instance" then return "nil" end
	local parts = {}
	local current = instance
	while current and current ~= Dex.game and current ~= game do
		parts[#parts + 1] = current.Name
		current = current.Parent
	end
	if (current ~= Dex.game and current ~= game) or #parts == 0 then return "nil" end
	local expression = "game:GetService(" .. string.format ("%q", parts[1]) .. ")"
	for index = 2, #parts do
		local name = parts[index]
		if name:match ("^[A-Za-z_][A-Za-z0-9_]*$") then
			expression = expression .. "." .. name
		else
			expression = expression .. "[" .. string.format ("%q", name) .. "]"
		end
	end
	return expression
end

function Explorer:MakeScript (instance)
	if typeof (instance) ~= "Instance" then
		Dex:Notify ("Select an instance first", "error")
		return
	end

	local reserved = {
		game = true,
		script = true,
		workspace = true,
		Instance = true,
		Enum = true,
		BrickColor = true,
		Color3 = true,
		Vector3 = true,
		Vector2 = true,
		UDim = true,
		UDim2 = true,
		CFrame = true,
		CollectionService = true,
		Objects = true,
		obj = true,
	}
	for _, keyword in ipairs ({
		"and",
		"break",
		"do",
		"else",
		"elseif",
		"end",
		"false",
		"for",
		"function",
		"if",
		"in",
		"local",
		"nil",
		"not",
		"or",
		"repeat",
		"return",
		"then",
		"true",
		"until",
		"while",
		"continue",
	}) do
		reserved[keyword] = true
	end
	local usedNames = {}
	local nodes = {}
	local usesTags = false

	local function sanitize (text)
		text = tostring (text or "")
		text = text:gsub ("[^%w_]", "_")
		if text == "" then return "Instance" end
		if text:match ("^%d") then text = "_" .. text end
		return text
	end

	local function uniqueName (parentNode, current)
		local parentName = parentNode and parentNode.Name or nil
		local candidates = {
			sanitize (current.Name),
			sanitize ((parentName or "") .. current.ClassName),
			sanitize (current.ClassName),
		}
		for _, base in ipairs (candidates) do
			local candidate = base
			local suffix = 2
			while reserved[candidate] or usedNames[candidate] do
				candidate = base .. "_" .. suffix
				suffix += 1
			end
			if not reserved[candidate] and not usedNames[candidate] then
				usedNames[candidate] = true
				return candidate
			end
		end
		local fallback = "Instance"
		local suffix = 2
		while usedNames[fallback] do
			fallback = "Instance" .. suffix
			suffix += 1
		end
		usedNames[fallback] = true
		return fallback
	end

	local function collectNode (current, parentNode)
		local node = {
			Instance = current,
			Parent = parentNode,
			Children = {},
			Ops = {},
			Name = uniqueName (parentNode, current),
		}
		local className = current.ClassName

		if current.Name ~= className then
			node.Ops[#node.Ops + 1] = "__REF__.Name = " .. string.format ("%q", current.Name)
		end

		local template = nil
		local okTemplate, created = pcall (function ()
			return U.Create (className)
		end)
		if okTemplate then template = created end

		local props = Dex.Reflect:GetProperties (className)
		table.sort (props, function (a, b)
			return a.Name:lower () < b.Name:lower ()
		end)
		for _, prop in ipairs (props) do
			local name = prop.Name
			if not SerializeSkip[name] and not (prop.Tags and (prop.Tags.ReadOnly or prop.Tags.NotScriptable)) then
				local ok, value = pcall (function ()
					return current[name]
				end)
				if ok and value ~= nil then
					local include = true
					if template then
						local okDefault, defaultValue = pcall (function ()
							return template[name]
						end)
						if okDefault then include = not valuesEqual (value, defaultValue) end
					end
					if include then
						local code = serializeValue (value)
						if code then node.Ops[#node.Ops + 1] = "__REF__." .. name .. " = " .. code end
					end
				end
			end
		end
		if template then pcall (function ()
			template:Destroy ()
		end) end

		local attributeOk, attributes = pcall (function ()
			return current:GetAttributes ()
		end)
		if attributeOk and type (attributes) == "table" then
			local names = {}
			for name in pairs (attributes) do
				names[#names + 1] = name
			end
			table.sort (names)
			for _, name in ipairs (names) do
				local code = serializeValue (attributes[name])
				if code then
					node.Ops[#node.Ops + 1] = "__REF__:SetAttribute("
						.. string.format ("%q", name)
						.. ", "
						.. code
						.. ")"
				end
			end
		end

		local tagOk, tags = pcall (function ()
			return CollectionService and CollectionService:GetTags (current)
		end)
		if tagOk and type (tags) == "table" and #tags > 0 then
			usesTags = true
			table.sort (tags)
			for _, tag in ipairs (tags) do
				node.Ops[#node.Ops + 1] = "CollectionService:AddTag(__REF__, " .. string.format ("%q", tag) .. ")"
			end
		end

		node.HasChanges = #node.Ops > 0
		local children = current:GetChildren ()
		for _, child in ipairs (children) do
			local childNode = collectNode (child, node)
			node.Children[#node.Children + 1] = childNode
		end
		nodes[#nodes + 1] = node
		return node
	end

	local root = collectNode (instance, nil)

	local variableCount = 0
	for _, node in ipairs (nodes) do
		if node.HasChanges or #node.Children > 0 then
			variableCount += 1
		end
	end
	local useTable = variableCount > 199

	local function reference (node)
		if useTable then return ("Objects[%q]"):format (node.Name) end
		return node.Name
	end

	local lines = {
		"-- Generated by Dex ( https://github.com/com-display-name/dex )",
		"-- Source: " .. instancePath (instance),
	}
	if usesTags then lines[#lines + 1] = "local CollectionService = game:GetService(\"CollectionService\")" end
	if useTable then lines[#lines + 1] = "local Objects = {}" end
	lines[#lines + 1] = ""

	local generated = 0
	local function emit (node)
		if generated > 1500 then
			lines[#lines + 1] = "-- (truncated: too many instances)"
			return
		end
		generated += 1
		local ref = reference (node)
		local needsVariable = node.HasChanges or #node.Children > 0

		if needsVariable then
			if useTable then
				lines[#lines + 1] = ("Objects[%q] = Instance.new(%q)"):format (node.Name, node.Instance.ClassName)
			else
				lines[#lines + 1] = ("local %s = Instance.new(%q)"):format (ref, node.Instance.ClassName)
			end
			for _, op in ipairs (node.Ops) do
				lines[#lines + 1] = (op:gsub ("__REF__", ref))
			end
		end

		for _, child in ipairs (node.Children) do
			if generated > 1500 then
				lines[#lines + 1] = "-- (truncated: too many instances)"
				return
			end
			if child.HasChanges or #child.Children > 0 then
				lines[#lines + 1] = ("%s.Parent = %s"):format (reference (child), ref)
				emit (child)
			else
				lines[#lines + 1] = ("Instance.new(%q).Parent = %s"):format (child.Instance.ClassName, ref)
			end
		end
	end

	if root.HasChanges or #root.Children > 0 then
		emit (root)
		local parentPath = instancePath (instance.Parent)
		if parentPath ~= "nil" then
			lines[#lines + 1] = ""
			lines[#lines + 1] = ("%s.Parent = %s"):format (reference (root), parentPath)
		else
			lines[#lines + 1] = ""
			lines[#lines + 1] = "-- Set the parent to wherever you want it."
		end
	else
		local parentPath = instancePath (instance.Parent)
		if parentPath ~= "nil" then
			lines[#lines + 1] = ("Instance.new(%q).Parent = %s"):format (instance.ClassName, parentPath)
		else
			lines[#lines + 1] = ("local obj = Instance.new(%q)"):format (instance.ClassName)
			lines[#lines + 1] = "-- Set obj.Parent to wherever you want it."
		end
	end

	Dex:ShowScriptViewer (table.concat (lines, "\n"), "Make Script - " .. instance.Name, nil)
	Dex:Notify ("Generated script for " .. instance.Name, "success")
end

local function ensureSaveFolder ()
	pcall (function ()
		if type (makefolder) == "function" then
			makefolder ("workspace")
			makefolder ("workspace/Dex")
		end
	end)
end

function Explorer:PromptSaveFilename (defaultName, onConfirm)
	Dex:Prompt ({
		Title = "Save File",
		Message = "Enter a filename (no extension).\nSaved to /workspace/Dex/Saved/",
		Value = sanitizeSaveName (defaultName),
		Placeholder = "filename",
		ConfirmText = "Save",
		OnConfirm = function (name)
			ensureSaveFolder ()
			onConfirm (sanitizeSaveName (name))
		end,
	})
end

function Explorer:SaveGame ()
	local function runSave (includePlayers)
		self:PromptSaveFilename ("game", function (name)
			Dex:Notify ("Loading saveinstance...", "info")
			task.spawn (function ()
				local ok, saver = pcall (function ()
					return Dex:LoadUniversalSaveInstance ()
				end)
				if not ok or type (saver) ~= "function" then
					Dex:Notify ("Failed to load saveinstance: " .. tostring (saver), "error")
					return
				end
				local options = {
					FilePath = "Dex/Saved/" .. name .. ".rbxlx",
					IsModel = true,
					mode = "full",
					Decompile = true,
					SaveBytecode = true,
					AvoidFileOverwrite = false,
					ShowStatus = true,
					IgnoreSpecialProperties = true,
					usekonstantdecompiler = false,
				}
				if includePlayers then
					options.SavePlayers = true
					options.SaveCharacters = true
				end
				local saved, err = pcall (saver, options)
				if saved then
					Dex:Notify ("Saved to /workspace/Dex/Saved/" .. name .. ".rbxlx", "success")
				else
					Dex:Notify ("Save failed: " .. tostring (err), "error")
				end
			end)
		end)
	end

	Dex:Prompt ({
		Title = "Save Game",
		Message = "Warning: Continuing will kick you from the game, click the x to cancel.\nSave Players and Characters too?",
		Input = false,
		ConfirmText = "Yes",
		CancelText = "No",
		OnConfirm = function ()
			runSave (true)
		end,
		OnCancel = function ()
			runSave (false)
		end,
	})
end


local TextWidthCache = {}
local function cachedTextWidth (text, size, font)
	local key = tostring (text) .. "\0" .. tostring (size) .. "\0" .. tostring (font)
	local value = TextWidthCache[key]
	if value == nil then
		value = U.TextWidth (text, size, font)

		TextWidthCache.Count = (TextWidthCache.Count or 0) + 1
		if TextWidthCache.Count > 1500 then
			table.clear (TextWidthCache)
			TextWidthCache.Count = 0
		end
		TextWidthCache[key] = value
	end
	return value
end

local function sameFlatEntry (a, b)
	if not a or not b then return false end
	if
		a.Instance ~= b.Instance
		or a.Depth ~= b.Depth
		or a.HasChildren ~= b.HasChildren
		or a.Expanded ~= b.Expanded
		or a.IsLast ~= b.IsLast
		or a.Match ~= b.Match
		or a.SearchActive ~= b.SearchActive
		or a.Pinned ~= b.Pinned
	then
		return false
	end
	local ancestorsA = a.Ancestors or {}
	local ancestorsB = b.Ancestors or {}
	if #ancestorsA ~= #ancestorsB then return false end
	for index = 1, #ancestorsA do
		if ancestorsA[index] ~= ancestorsB[index] then return false end
	end
	local guidesA = a.Guides or {}
	local guidesB = b.Guides or {}
	if guidesA[0] ~= guidesB[0] then return false end
	for index = 1, math.max (#guidesA, #guidesB) do
		if guidesA[index] ~= guidesB[index] then return false end
	end
	return true
end

local PinnedServices = {
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
	"TextChatService",
	"Chat",
	"LocalizationService",
}

local PinnedRank = {}
for index, name in ipairs (PinnedServices) do
	PinnedRank[name] = index
end

local function descendantAmount (instance, cache)
	if cache[instance] ~= nil then return cache[instance] end
	local count = 0
	if typeof (instance) == "Instance" then
		local ok, descendants = pcall (function ()
			return instance:GetDescendants ()
		end)
		if ok and type (descendants) == "table" then count = #descendants end
	end
	cache[instance] = count
	return count
end

local function makeInstanceComparator (nameFirst)
	local cache = {}
	return function (a, b)
		local classA = tostring (a.ClassName or ""):lower ()
		local classB = tostring (b.ClassName or ""):lower ()
		local nameA = tostring (a.Name or "")
		local nameB = tostring (b.Name or "")
		if nameFirst then
			if nameA ~= nameB then return nameA < nameB end
			if classA ~= classB then return classA < classB end
		else
			if classA ~= classB then return classA < classB end
			if nameA ~= nameB then return nameA < nameB end
		end
		local countA = descendantAmount (a, cache)
		local countB = descendantAmount (b, cache)
		if countA ~= countB then return countA < countB end
		return false
	end
end

local function makeServiceComparator ()
	local cache = {}
	return function (a, b)
		local rankA = PinnedRank[a.ClassName]
		local rankB = PinnedRank[b.ClassName]
		if rankA and rankB then
			return rankA < rankB
		elseif rankA then
			return true
		elseif rankB then
			return false
		end
		local classA = tostring (a.ClassName or ""):lower ()
		local classB = tostring (b.ClassName or ""):lower ()
		if classA ~= classB then return classA < classB end
		local nameA = tostring (a.Name or "")
		local nameB = tostring (b.Name or "")
		if nameA ~= nameB then return nameA < nameB end
		local countA = descendantAmount (a, cache)
		local countB = descendantAmount (b, cache)
		return countA < countB
	end
end

local CommonClasses = {
	"Part",
	"Model",
	"Folder",
	"Script",
	"LocalScript",
	"ModuleScript",
	"TextLabel",
	"TextButton",
	"TextBox",
	"Frame",
	"ScreenGui",
	"BillboardGui",
	"SurfaceGui",
	"PointLight",
	"SpotLight",
	"Sound",
	"RemoteEvent",
	"RemoteFunction",
	"BindableEvent",
	"BindableFunction",
	"BoolValue",
	"StringValue",
	"NumberValue",
	"IntValue",
	"ObjectValue",
	"Vector3Value",
	"Color3Value",
	"Attachment",
	"WeldConstraint",
	"SpecialMesh",
	"ClickDetector",
}

local AllClassFallback = {
	"Accessory",
	"AccessoryDescription",
	"Accoutrement",
	"Actor",
	"AdGui",
	"AdPlacement",
	"AdPortal",
	"AdvancedDragger",
	"AirController",
	"AlignOrientation",
	"AlignPosition",
	"AngularVelocity",
	"Animation",
	"AnimationConstraint",
	"AnimationController",
	"AnimationGraphDefinition",
	"AnimationNodeDefinition",
	"AnimationPlayer",
	"AnimationRigData",
	"AnimationValueNodeDefinition",
	"AnimationValueOutputDefinition",
	"Animator",
	"Annotation",
	"ArcHandles",
	"Atmosphere",
	"AtmosphereSensor",
	"Attachment",
	"AudioAnalyzer",
	"AudioChannelMixer",
	"AudioChannelSplitter",
	"AudioChorus",
	"AudioCompressor",
	"AudioDeviceInput",
	"AudioDeviceOutput",
	"AudioDistortion",
	"AudioEcho",
	"AudioEmitter",
	"AudioEqualizer",
	"AudioFader",
	"AudioFilter",
	"AudioFlanger",
	"AudioGate",
	"AudioLimiter",
	"AudioListener",
	"AudioPitchShifter",
	"AudioPlayer",
	"AudioRecorder",
	"AudioReverb",
	"AudioSearchParams",
	"AudioSpeechToText",
	"AudioStreamReader",
	"AudioStreamWriter",
	"AudioTextToSpeech",
	"AudioTremolo",
	"AudioWindSynthesizer",
	"AvatarAbilityRules",
	"AvatarAccessoryRules",
	"AvatarAnimationRules",
	"AvatarBodyRules",
	"AvatarClothingRules",
	"AvatarCollisionRules",
	"AvatarEffectDescription",
	"AvatarRules",
	"Backpack",
	"BallSocketConstraint",
	"Beam",
	"BillboardGui",
	"BinaryStringValue",
	"BindableEvent",
	"BindableFunction",
	"BlockMesh",
	"BloomEffect",
	"BlurEffect",
	"BodyColors",
	"BodyPartDescription",
	"Bone",
	"BoolValue",
	"BoxHandleAdornment",
	"Breakpoint",
	"BrickColorValue",
	"BubbleChatMessageProperties",
	"BuoyancySensor",
	"CFrameValue",
	"Camera",
	"CanvasGroup",
	"CharacterMesh",
	"ChorusSoundEffect",
	"ClickDetector",
	"ClimbController",
	"Clouds",
	"Color3Value",
	"ColorCorrectionEffect",
	"ColorGradingEffect",
	"CompositeValueCurve",
	"CompressorSoundEffect",
	"ConeHandleAdornment",
	"Configuration",
	"ControlState",
	"ControllerManager",
	"ControllerPartSensor",
	"CornerWedgePart",
	"CurveAnimation",
	"CustomLog",
	"CylinderHandleAdornment",
	"CylindricalConstraint",
	"DataStoreGetOptions",
	"DataStoreIncrementOptions",
	"DataStoreOptions",
	"DataStoreSetOptions",
	"DebuggerWatch",
	"Decal",
	"DepthOfFieldEffect",
	"Dialog",
	"DialogChoice",
	"DigitsRigDescription",
	"DistortionSoundEffect",
	"DragDetector",
	"Dragger",
	"EchoSoundEffect",
	"EqualizerSoundEffect",
	"EulerRotationCurve",
	"ExperienceInviteOptions",
	"ExplorerFilter",
	"Explosion",
	"FaceControls",
	"FeatureMatchingTable",
	"FileMesh",
	"Fire",
	"FlangeSoundEffect",
	"FloatCurve",
	"FluidForceSensor",
	"Folder",
	"FollowRotationBoneBehavior",
	"FollowTwistBoneBehavior",
	"ForceField",
	"Frame",
	"GeneratedFolder",
	"GetTextBoundsParams",
	"GroundController",
	"Handles",
	"HapticEffect",
	"HiddenSurfaceRemovalAsset",
	"Highlight",
	"HingeConstraint",
	"Humanoid",
	"HumanoidController",
	"HumanoidDescription",
	"HumanoidRigDescription",
	"IKControl",
	"ImageButton",
	"ImageHandleAdornment",
	"ImageLabel",
	"InputAction",
	"InputActionLabel",
	"InputBinding",
	"InputContext",
	"IntValue",
	"IntersectOperation",
	"Keyframe",
	"KeyframeMarker",
	"KeyframeSequence",
	"LineForce",
	"LineHandleAdornment",
	"LinearVelocity",
	"LocalScript",
	"LocalizationTable",
	"MakeupDescription",
	"MarkerCurve",
	"MaterialVariant",
	"MeshPart",
	"Model",
	"ModuleScript",
	"Motor",
	"Motor6D",
	"NegateOperation",
	"NoCollisionConstraint",
	"Noise",
	"NumberPose",
	"NumberValue",
	"ObjectValue",
	"OperationGraph",
	"Pants",
	"ParabolaAdornment",
	"Part",
	"PartOperation",
	"PartOperationAsset",
	"ParticleEmitter",
	"ParticleEmitter2D",
	"Path2D",
	"Path3D",
	"PathfindingLink",
	"PathfindingModifier",
	"PhysicsActivitySensor",
	"PitchShiftSoundEffect",
	"PlaneConstraint",
	"Player",
	"PluginAction",
	"PluginCapabilities",
	"PointLight",
	"Pose",
	"PrismaticConstraint",
	"ProceduralModel",
	"ProximityPrompt",
	"PyramidHandleAdornment",
	"RTAnimationTracker",
	"RayValue",
	"RealtimeMedia",
	"ReflectionMetadata",
	"ReflectionMetadataCallbacks",
	"ReflectionMetadataClass",
	"ReflectionMetadataClasses",
	"ReflectionMetadataEnum",
	"ReflectionMetadataEnumItem",
	"ReflectionMetadataEnums",
	"ReflectionMetadataEvents",
	"ReflectionMetadataFunctions",
	"ReflectionMetadataMember",
	"ReflectionMetadataProperties",
	"ReflectionMetadataYieldFunctions",
	"RelativeGui",
	"RemoteEvent",
	"RemoteFunction",
	"RenderingTest",
	"ReverbSoundEffect",
	"RigidConstraint",
	"RodConstraint",
	"RopeConstraint",
	"RotationCurve",
	"ScreenGui",
	"Script",
	"ScrollingFrame",
	"Seat",
	"SelectionBox",
	"SelectionSphere",
	"Shirt",
	"ShirtGraphic",
	"SkateboardController",
	"Sky",
	"Smoke",
	"Sound",
	"SoundGroup",
	"Sparkles",
	"SpawnLocation",
	"SpecialMesh",
	"SphereHandleAdornment",
	"SpotLight",
	"SpringConstraint",
	"StandalonePluginScripts",
	"StarterGear",
	"StateMachineDefinition",
	"StateMachineTransitionDefinition",
	"StringValue",
	"StudioAttachment",
	"StudioCallout",
	"StyleDerive",
	"StyleLink",
	"StyleQuery",
	"StyleRule",
	"StyleSheet",
	"SunRaysEffect",
	"SurfaceAppearance",
	"SurfaceGui",
	"SurfaceLight",
	"SurfaceSelection",
	"SwimController",
	"Team",
	"TeleportOptions",
	"TerrainDetail",
	"TerrainRegion",
	"TextBox",
	"TextButton",
	"TextChannel",
	"TextChannelWindow",
	"TextChatCommand",
	"TextChatMessageProperties",
	"TextDocument",
	"TextGenerator",
	"TextLabel",
	"Texture",
	"Tool",
	"Torque",
	"TorsionSpringConstraint",
	"TrackerStreamAnimation",
	"Trail",
	"TremoloSoundEffect",
	"TrussPart",
	"Tween",
	"UIAspectRatioConstraint",
	"UIBlur",
	"UICorner",
	"UIDragDetector",
	"UIFlexItem",
	"UIGradient",
	"UIGridLayout",
	"UIListLayout",
	"UIPadding",
	"UIPageLayout",
	"UIScale",
	"UIShadow",
	"UISizeConstraint",
	"UIStroke",
	"UITableLayout",
	"UITextSizeConstraint",
	"UnionOperation",
	"UniversalConstraint",
	"UnreliableRemoteEvent",
	"ValueCurve",
	"Vector3Curve",
	"Vector3Value",
	"VectorForce",
	"VehicleController",
	"VehicleSeat",
	"VelocityMotor",
	"VideoDeviceInput",
	"VideoDisplay",
	"VideoFrame",
	"VideoPlayer",
	"ViewportCamera",
	"ViewportFrame",
	"VisualizationMode",
	"VisualizationModeCategory",
	"WedgePart",
	"Weld",
	"WeldConstraint",
	"Wire",
	"WireframeHandleAdornment",
	"WorkspaceAnnotation",
	"WorldModel",
	"WrapDeformer",
	"WrapLayer",
	"WrapTarget",
	"WrapTextureTransfer",
}
local CommonRank = {}
for index, name in ipairs (CommonClasses) do
	CommonRank[name] = index
end

local NilInstancesNode = {
	Name = "Nil Instances",
	ClassName = "Folder",
	_NilInstances = true,
}

local function isServiceInstance (instance)
	return instance and instance.Parent == game
end

local function selectionContains (instance)
	return Dex.Selection.Map[instance] == true
end

local function isOwnGui (instance)
	local screen = Dex.ScreenGui
	if not screen then return false end
	local ok, result = pcall (function ()
		return instance:IsDescendantOf (screen)
	end)
	return ok and result
end

local function instanceHasChildren (instance)
	local ok, children = pcall (function ()
		return #instance:GetChildren () > 0
	end)
	return ok and children
end

local function buttonAt (parent, properties)
	local button = U.Button (parent, properties)
	U.Corner (button, properties.CornerRadius or 4)
	return button
end

local function makeHistoryIcon (button)
	local holder = U.Frame (button, {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Position = UDim2.fromScale (0.5, 0.5),
		Size = UDim2.fromOffset (14, 14),
		ZIndex = (button.ZIndex or 1) + 1,
	})
	local ring = U.Frame (holder, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (1, 1),
		Size = UDim2.fromOffset (11, 11),
		ZIndex = (button.ZIndex or 1) + 1,
	})
	U.Corner (ring, 99)
	U.Stroke (ring, Dex.Theme.Explorer.Placeholder, 1.3, 0)
	U.Frame (holder, {
		BackgroundColor3 = Dex.Theme.Explorer.Placeholder,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (6.5, 3),
		Size = UDim2.fromOffset (1, 4),
		ZIndex = (button.ZIndex or 1) + 2,
	})
	U.Frame (holder, {
		BackgroundColor3 = Dex.Theme.Explorer.Placeholder,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (7, 6.5),
		Size = UDim2.fromOffset (3, 1),
		Rotation = 15,
		ZIndex = (button.ZIndex or 1) + 2,
	})
end

function Explorer:GetAllServices ()
	local services = {}
	for _, child in ipairs (self:GetAllServicesIncludingHidden ()) do
		if not self.HiddenServices[child.Name] then services[#services + 1] = child end
	end
	table.sort (services, makeServiceComparator ())
	return services
end

function Explorer:GetAllServicesIncludingHidden ()
	local services = {}
	local seen = {}
	for _, child in ipairs (game:GetChildren ()) do
		if not seen[child] then
			seen[child] = true
			services[#services + 1] = child
		end
	end
	table.sort (services, makeServiceComparator ())
	return services
end

function Explorer:GetSortedChildren (parentObj)
	if type (parentObj) == "table" and parentObj._NilInstances then
		local result = {}
		if type (getnilinstances) == "function" then
			local ok, instances = pcall (getnilinstances)
			if ok and type (instances) == "table" then
				for _, instance in ipairs (instances) do
					if typeof (instance) == "Instance" then result[#result + 1] = instance end
				end
			end
		end
		return result
	end
	local cached = type (parentObj) == "Instance" and self.ChildrenCache[parentObj]
	if cached then return cached end

	local ok, children = pcall (function ()
		return parentObj:GetChildren ()
	end)
	if not ok then return {} end

	local function applyPinnedFirst (list)
		if not next (self.Pinned) then return list end
		local ordered = {}
		for _, child in ipairs (list) do
			if self.Pinned[child] then ordered[#ordered + 1] = child end
		end
		for _, child in ipairs (list) do
			if not self.Pinned[child] then ordered[#ordered + 1] = child end
		end
		return ordered
	end

	if parentObj == game then
		table.sort (children, makeServiceComparator ())
	elseif self.SortByName then
		table.sort (children, makeInstanceComparator (true))
	else
		table.sort (children, makeInstanceComparator (false))
	end
	children = applyPinnedFirst (children)

	if parentObj == game then
		local result = { NilInstancesNode }
		for _, child in ipairs (self:GetAllServices ()) do
			result[#result + 1] = child
		end
		return applyPinnedFirst (result)
	end

	if type (parentObj) == "Instance" then self.ChildrenCache[parentObj] = children end
	return children
end

function Explorer:InvalidateChildrenCache ()
	table.clear (self.ChildrenCache)
end

function Explorer:GetDisplayChildren (parentObj, searching, visibleSet, cache)
	cache = cache or {}
	if cache[parentObj] then return cache[parentObj] end

	local source = self:GetSortedChildren (parentObj)
	local result = {}
	for _, child in ipairs (source) do
		local hidden = parentObj == game and self.HiddenServices[child.Name]
		local included = true
		if hidden then
			included = false
		elseif searching and visibleSet and not visibleSet[child] then
			included = false
		end
		if included then result[#result + 1] = child end
	end
	cache[parentObj] = result
	return result
end

function Explorer:IsPinned (instance)
	return instance ~= nil and self.Pinned[instance] == true
end

function Explorer:TogglePin (instance)
	if not instance then return end
	if self.Pinned[instance] then
		self.Pinned[instance] = nil
	else
		self.Pinned[instance] = true
	end
	self:InvalidateChildrenCache ()
	self:Refresh ()
end

function Explorer:GetPinPathSet ()
	local set = {}
	for instance in pairs (self.Pinned) do
		if typeof (instance) == "Instance" then
			local current = instance
			while current do
				set[current] = true
				current = current.Parent
			end
			set[Dex.game] = true
		end
	end
	return set
end

function Explorer:ComputeFlat ()
	local flat = {}
	local search = self.Search
	local searching = search.Active == true
	local visibleSet = searching and search.Visible or nil
	local matchSet = searching and search.MatchSet or nil
	local pinSet = not searching and next (self.Pinned) ~= nil and self:GetPinPathSet () or nil
	local cache = {}
	local maxWidth = 300

	local function walk (parentObj, depth, ancestors, continuation)
		local children = self:GetDisplayChildren (parentObj, searching, visibleSet, cache)
		for index, child in ipairs (children) do
			local childChildren = self:GetDisplayChildren (child, searching, visibleSet, cache)
			local expanded
			if searching then
				expanded = search.Expanded[child] ~= false
			else
				expanded = pinSet and pinSet[child] or self.Expanded[child] == true
			end

			local pinned = self:IsPinned (child)
			local entry = {
				Instance = child,
				Depth = depth,
				Ancestors = ancestors,
				Guides = continuation,
				IsLast = index == #children,
				HasChildren = #childChildren > 0,
				Expanded = expanded,
				Match = matchSet and matchSet[child] == true or false,
				SearchActive = searching,
				Pinned = pinned,
			}
			flat[#flat + 1] = entry

			local nameX = 7 + depth * 15 + 14 + 2 + (Dex.PerformanceMode and 5 or 16 + 5)
			local pinExtra = pinned and 14 or 0
			maxWidth = math.max (maxWidth, nameX + pinExtra + cachedTextWidth (child.Name, 14, Dex.Fonts.UI) + 28)

			if #childChildren > 0 and expanded then
				local nextAncestors = {}
				for ancestorIndex = 1, #ancestors do
					nextAncestors[ancestorIndex] = ancestors[ancestorIndex]
				end
				nextAncestors[#nextAncestors + 1] = child

				local nextContinuation = {}
				for guideIndex = 0, depth - 1 do
					nextContinuation[guideIndex] = continuation[guideIndex]
				end
				nextContinuation[depth] = index < #children

				walk (child, depth + 1, nextAncestors, nextContinuation)
			end
		end
	end

	walk (game, 0, {}, {})

	self.Flat = flat
	self.FlatWidth = math.max (maxWidth, self.Tree and self.Tree.AbsoluteSize.X or 300)
	self.ActivePath = self:ComputeActivePath ()
	return flat
end

function Explorer:ComputeActivePath ()
	local path = {}
	for _, selected in ipairs (Dex.Selection.List) do
		local current = selected
		while current do
			path[current] = true
			current = current.Parent
		end
	end
	return path
end

function Explorer:UpdateTreeLayout ()
	local search = self.Search
	local showHeader = search.Query ~= "" or search.Searching or search.Active
	if self.ResultsHeader then self.ResultsHeader.Visible = showHeader end
	local top = 38 + (showHeader and 26 or 0)
	if self.Tree then
		self.Tree.Position = UDim2.fromOffset (0, top)
		self.Tree.Size = UDim2.new (1, 0, 1, -top)
	end
	if self.EmptyLabel then
		self.EmptyLabel.Position = UDim2.fromOffset (0, top)
		self.EmptyLabel.Size = UDim2.new (1, 0, 1, -top)
	end
	self:UpdateHeader ()
end

function Explorer:UpdateHeader ()
	local header = self.ResultsHeader
	if not header then return end
	local count = #self.Search.Matches
	local text
	if self.Search.Searching then
		text = "Searching..."
	elseif self.Search.Truncated then
		text = tostring (2000) .. "+ matches"
	elseif self.Search.Active then
		text = tostring (count) .. (count == 1 and " match" or " matches")
	else
		text = self.Search.Query ~= "" and "0 matches" or ""
	end
	self.ResultsCount.Text = text

	if self.HeaderSelectAll then
		self.HeaderSelectAll.Active = count > 0
		self.HeaderSelectAll.TextColor3 = count > 0 and Dex.Theme.Explorer.TextMuted or Dex.Theme.Explorer.TextDisabled
	end
end

function Explorer:EnsureRowPool ()
	if not self.Tree then return end
	local height = self.Tree.AbsoluteSize.Y
	if height <= 0 then return end
	local desired = math.max (1, math.ceil (height / 20) + 8)
	while #self.RowPool < desired do
		local row = self:CreateRow ()
		self.RowPool[#self.RowPool + 1] = row
	end
	while #self.RowPool > desired + 12 do
		local row = table.remove (self.RowPool)
		self.RowEntries[row] = nil
		self.RowMeta[row] = nil
		row:Destroy ()
	end
	self:UpdateRows ()
end

function Explorer:CreateRow ()
	local row = buttonAt (self.Tree, {
		Name = "ExplorerRow",
		BackgroundTransparency = 1,
		Size = UDim2.new (0, 300, 0, 20),
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		ZIndex = 2,
	})
	row.BackgroundColor3 = Dex.Theme.Explorer.Hover
	row.BackgroundTransparency = 1

	local highlight = U.Frame (row, {
		Name = "Highlight",
		BackgroundColor3 = Dex.Theme.Explorer.Selection,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (6, 1),
		Size = UDim2.new (1, -12, 0, 20 - 2),
		ZIndex = 1,
		Active = false,
	})
	U.Corner (highlight, 5)

	local guideHolder = U.Frame (row, {
		Name = "Guides",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale (1, 1),
		ZIndex = 2,
		Active = false,
	})

	local caret = buttonAt (row, {
		Name = "Caret",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (7, 0),
		Size = UDim2.fromOffset (14, 20),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	})
	local caretGlyph = U.Label (caret, {
		Name = "Glyph",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Position = UDim2.fromScale (0.5, 0.5),
		Size = UDim2.fromOffset (10, 12),
		Font = Dex.Fonts.UIBold,
		Text = "▶",
		TextColor3 = Dex.Theme.Explorer.TextMuted,
		TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 5,
	})

	local icon = Dex.Icons.ImageLabel (row, "Placeholder", 16)
	icon.Name = "Icon"
	icon.Position = UDim2.fromOffset (7 + 14 + 2, math.floor ((20 - 16) / 2))
	icon.ZIndex = 4

	local pinIcon = U.Create ("ImageLabel", {
		Name = "PinIcon",
		BackgroundTransparency = 1,
		Image = "rbxassetid://122381946504717",
		Size = UDim2.fromOffset (12, 12),
		Position = UDim2.fromOffset (0, 0),
		Visible = false,
		ZIndex = 6,
		Active = false,
	})
	pinIcon.Parent = row

	local name = U.Label (row, {
		Name = "Name",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (7 + 14 + 2 + 16 + 5, 0),
		Size = UDim2.new (1, -120, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "",
		TextColor3 = Dex.Theme.Explorer.TreeText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Active = false,
	})

	local underline = U.Frame (row, {
		Name = "MatchUnderline",
		BackgroundColor3 = Dex.Theme.Common.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (0, 20 - 4),
		Size = UDim2.new (0, 0, 0, 1),
		Visible = false,
		ZIndex = 6,
		Active = false,
	})

	local meta = {
		Highlight = highlight,
		GuideHolder = guideHolder,
		Guides = {},
		Connector = nil,
		Caret = caret,
		CaretGlyph = caretGlyph,
		Icon = icon,
		PinIcon = pinIcon,
		Name = name,
		Underline = underline,
		Hovered = false,
		EntryIndex = nil,
		NameConnection = nil,
	}
	self.RowMeta[row] = meta

	caret.MouseButton1Click:Connect (function ()
		local entry = Explorer.RowEntries[row]
		if not entry or Explorer.Renaming then return end
		Explorer.Window:Focus ()
		Explorer:ToggleExpanded (entry.Instance)
	end)

	row.MouseEnter:Connect (function ()
		meta.Hovered = true
		Explorer:PaintRow (row)
	end)
	row.MouseLeave:Connect (function ()
		meta.Hovered = false
		Explorer:PaintRow (row)
	end)

	row.MouseButton1Click:Connect (function ()
		local entry = Explorer.RowEntries[row]
		if not entry or Explorer.Renaming then return end
		Explorer.Window:Focus ()
		local ctrl = UIS:IsKeyDown (Enum.KeyCode.LeftControl) or UIS:IsKeyDown (Enum.KeyCode.RightControl)
		local shift = UIS:IsKeyDown (Enum.KeyCode.LeftShift) or UIS:IsKeyDown (Enum.KeyCode.RightShift)

		local now = os.clock ()
		local double = Explorer._LastClick == entry.Instance and (now - (Explorer._LastClickAt or 0) < 0.34)
		Explorer._LastClick = entry.Instance
		Explorer._LastClickAt = now

		Explorer:HandleRowClick (entry, ctrl, shift)
		if double and entry.HasChildren and not ctrl and not shift then Explorer:ToggleExpanded (entry.Instance) end
	end)

	row.MouseButton2Click:Connect (function ()
		local entry = Explorer.RowEntries[row]
		if not entry or Explorer.Renaming then return end
		Explorer.Window:Focus ()
		if type (entry.Instance) == "table" and entry.Instance._NilInstances then return end
		if not selectionContains (entry.Instance) then Explorer:SelectOnly (entry.Instance) end
		Explorer:ShowContextMenu (entry.Instance, U.MousePoint ())
	end)

	return row
end

function Explorer:PaintRow (row)
	local meta = self.RowMeta[row]
	local entry = self.RowEntries[row]
	if not meta or not entry then return end

	local selected = selectionContains (entry.Instance)
	local hovered = meta.Hovered

	if selected then
		meta.Highlight.Visible = true
		meta.Highlight.BackgroundTransparency = 0
		meta.Highlight.BackgroundColor3 = Dex.Theme.Explorer.Selection
	elseif hovered then
		meta.Highlight.Visible = true
		meta.Highlight.BackgroundTransparency = 0
		meta.Highlight.BackgroundColor3 = Dex.Theme.Explorer.Hover
	else
		meta.Highlight.Visible = false
	end

	local dim = entry.SearchActive and not entry.Match
	if selected then
		meta.Name.TextColor3 = Dex.Theme.Explorer.SelectionText
	elseif dim then
		meta.Name.TextColor3 = Dex.Theme.Explorer.Empty
	else
		meta.Name.TextColor3 = Dex.Theme.Explorer.TreeText
	end
	meta.CaretGlyph.TextColor3 = selected and Dex.Theme.Explorer.SelectionText or Dex.Theme.Explorer.TextMuted
	meta.Underline.BackgroundColor3 = Dex.Theme.Common.Accent

	local activePath = self.ActivePath or self:ComputeActivePath ()
	for _, guide in ipairs (meta.Guides) do
		local ancestor = entry.Ancestors[guide.Depth + 1]
		local nextObject = entry.Ancestors[guide.Depth + 2] or entry.Instance
		local active = ancestor and activePath[ancestor] and activePath[nextObject]
		guide.Frame.BackgroundColor3 = active and Dex.Theme.Explorer.GuideActive or Dex.Theme.Explorer.Guide
	end

	if meta.Connector then
		local ancestor = entry.Ancestors[entry.Depth]
		local active = ancestor and activePath[ancestor] and activePath[entry.Instance]
		meta.Connector.BackgroundColor3 = active and Dex.Theme.Explorer.GuideActive or Dex.Theme.Explorer.Guide
	end
end

function Explorer:SetRowNameConnection (meta, instance)
	if meta.NameConnection then
		pcall (function ()
			meta.NameConnection:Disconnect ()
		end)
		meta.NameConnection = nil
	end
	if instance and typeof (instance) == "Instance" then
		local ok, connection = pcall (function ()
			return instance:GetPropertyChangedSignal ("Name"):Connect (function ()
				Explorer:InvalidateChildrenCache ()
				Explorer:MarkDirty ()
			end)
		end)
		if ok then meta.NameConnection = connection end
	end
end

function Explorer:DisconnectRowConnections ()
	for _, meta in pairs (self.RowMeta) do
		self:SetRowNameConnection (meta, nil)
	end
end

function Explorer:BindRow (row, index, entry)
	local meta = self.RowMeta[row]
	local instance = entry.Instance
	local depth = entry.Depth
	local caretX = 7 + depth * 15
	local iconX = caretX + 14 + 2
	local showIcon = not Dex.PerformanceMode
	local nameX = showIcon and (iconX + 16 + 5) or (iconX + 5)
	local width = self.FlatWidth or 300

	self.RowEntries[row] = entry
	row.Visible = true
	row.Position = UDim2.fromOffset (0, (index - 1) * 20)
	row.Size = UDim2.new (0, width, 0, 20)
	meta.EntryIndex = index

	meta.Highlight.Size = UDim2.new (1, -12, 0, 20 - 2)

	meta.Caret.Position = UDim2.fromOffset (caretX, 0)
	meta.Caret.Active = entry.HasChildren
	meta.CaretGlyph.Visible = entry.HasChildren
	meta.CaretGlyph.Rotation = entry.Expanded and 90 or 0

	meta.Icon.Visible = showIcon
	meta.Icon.Position = UDim2.fromOffset (iconX, math.floor ((20 - 16) / 2))
	if showIcon then Dex.Icons.Apply (meta.Icon, instance.ClassName, isServiceInstance (instance)) end

	local pinned = self:IsPinned (instance)
	local pinSize = 12
	local pinGap = 3
	if meta.PinIcon then
		local pinX = showIcon and (iconX + 16 + pinGap) or (iconX + 1)
		meta.PinIcon.Position = UDim2.fromOffset (pinX, math.floor ((20 - pinSize) / 2))
		meta.PinIcon.Visible = pinned
	end
	local nameOffset = pinned and (pinGap + pinSize - 1) or 0
	meta.Name.Position = UDim2.fromOffset (nameX + nameOffset, 0)
	meta.Name.Size = UDim2.new (0, math.max (20, width - nameX - nameOffset - 14), 1, 0)
	meta.Name.Text = instance.Name

	self:SetRowNameConnection (meta, instance)

	local guideHolder = meta.GuideHolder
	for guideIndex = #meta.Guides, 1, -1 do
		local guide = table.remove (meta.Guides, guideIndex)
		guide.Frame:Destroy ()
	end
	if meta.Connector then
		meta.Connector:Destroy ()
		meta.Connector = nil
	end

	for guideDepth = 0, depth - 1 do
		local visible = guideDepth == depth - 1 or entry.Guides[guideDepth] == true
		if visible then
			local lineHeight = 20
			if guideDepth == depth - 1 and entry.IsLast then lineHeight = math.floor (20 / 2) + 1 end
			local frame = U.Frame (guideHolder, {
				Name = "Guide",
				BackgroundColor3 = Dex.Theme.Explorer.Guide,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset (7 + guideDepth * 15 + 7, 0),
				Size = UDim2.fromOffset (1, lineHeight),
				ZIndex = 2,
				Active = false,
			})
			meta.Guides[#meta.Guides + 1] = {
				Frame = frame,
				Depth = guideDepth,
			}
		end
	end

	if depth > 0 then
		meta.Connector = U.Frame (guideHolder, {
			Name = "Connector",
			BackgroundColor3 = Dex.Theme.Explorer.Guide,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset (7 + (depth - 1) * 15 + 9, math.floor (20 / 2)),
			Size = UDim2.fromOffset (5, 1),
			ZIndex = 2,
			Active = false,
		})
	end

	local underline = meta.Underline
	underline.Visible = false
	if entry.SearchActive and entry.Match and self.Search.Query ~= "" then
		local lowerName = instance.Name:lower ()
		local query = self.Search.Query:lower ()
		local startIndex, endIndex = lowerName:find (query, 1, true)
		if startIndex and startIndex > 1 then
			local prefix = instance.Name:sub (1, startIndex - 1)
			local matched = instance.Name:sub (startIndex, endIndex)
			local prefixWidth = cachedTextWidth (prefix, 14, Dex.Fonts.UI)
			local matchWidth = cachedTextWidth (matched, 14, Dex.Fonts.UI)
			local available = math.max (0, width - nameX - 14)
			if prefixWidth < available and matchWidth > 0 then
				underline.Visible = true
				underline.Position = UDim2.fromOffset (nameX + prefixWidth, 20 - 4)
				underline.Size = UDim2.fromOffset (math.min (matchWidth, available - prefixWidth), 1)
			end
		elseif startIndex then
			local matchWidth = cachedTextWidth (instance.Name:sub (startIndex, endIndex), 14, Dex.Fonts.UI)
			underline.Visible = true
			underline.Position = UDim2.fromOffset (nameX, 20 - 4)
			underline.Size = UDim2.fromOffset (matchWidth, 1)
		end
	end

	self:PaintRow (row)
end

function Explorer:UpdateRows ()
	if not self.Tree then return end
	local rowWidth = math.max (self.FlatWidth or 300, self.Tree.AbsoluteSize.X)
	if rowWidth ~= self._RowWidth then
		self._RowWidth = rowWidth
		self.Tree.CanvasSize = UDim2.fromOffset (rowWidth, #self.Flat * 20)
		for _, row in ipairs (self.RowPool) do
			row.Size = UDim2.new (0, rowWidth, 0, 20)
		end
	end

	local first = math.max (1, math.floor (self.Tree.CanvasPosition.Y / 20) - 1)
	for index, row in ipairs (self.RowPool) do
		local flatIndex = first + index - 1
		local entry = self.Flat[flatIndex]
		if entry then
			local meta = self.RowMeta[row]
			if meta.EntryIndex ~= flatIndex or not sameFlatEntry (self.RowEntries[row], entry) then
				self:BindRow (row, flatIndex, entry)
			else
				self.RowEntries[row] = entry
				if not row.Visible then row.Visible = true end
				if row.Size.X.Offset ~= rowWidth or row.Size.Y.Offset ~= 20 then
					row.Size = UDim2.new (0, rowWidth, 0, 20)
				end
				local nameWidth = math.max (20, rowWidth - meta.Name.Position.X.Offset - 14)
				if meta.Name.Size.X.Offset ~= nameWidth then meta.Name.Size = UDim2.new (0, nameWidth, 1, 0) end
				self:PaintRow (row)
			end
		else
			row.Visible = false
			local meta = self.RowMeta[row]
			if meta then
				self:SetRowNameConnection (meta, nil)
				meta.EntryIndex = nil
			end
			self.RowEntries[row] = nil
		end
	end
end

function Explorer:Refresh ()
	if self.Renaming then
		self._RefreshPending = true
		return
	end
	if not self.Tree or not self.Tree.Parent then return end
	if not self.Window or not self.Window.GUI or not self.Window.GUI.Parent then return end

	self:UpdateTreeLayout ()
	local flat = self:ComputeFlat ()

	local canvasHeight = #flat * 20
	self.Tree.CanvasSize = UDim2.fromOffset (math.max (self.FlatWidth or 0, 300), canvasHeight)

	local emptyText = ""
	if #flat == 0 then
		if self.Search.Query ~= "" then
			emptyText = self.Search.Searching and "Searching..." or "No matches"
		else
			emptyText = "No instances"
		end
	end
	self.EmptyLabel.Text = emptyText
	self.EmptyLabel.Visible = #flat == 0

	self:EnsureRowPool ()
	self:UpdateRows ()
end

function Explorer:MarkDirty ()
	if self.Frozen then
		self._Dirty = true
		return
	end
	if self._DirtyScheduled then return end
	self._DirtyScheduled = true
	task.delay (0.12, function ()
		self._DirtyScheduled = false
		if not self.Window or not self.Window.GUI or not self.Window.GUI.Parent or not self.Window.Visible then
			self._Dirty = true
			return
		end
		self._Dirty = false
		self:Refresh ()
	end)
end

function Explorer:ApplyPerformanceMode ()
	for _, row in ipairs (self.RowPool) do
		local meta = self.RowMeta[row]
		if meta then meta.EntryIndex = nil end
	end
	self:Refresh ()
end

function Explorer:ToggleExpanded (instance)
	if self.Search.Active or self.Search.Searching then
		if self.Search.Expanded[instance] == false then
			self.Search.Expanded[instance] = nil
		else
			self.Search.Expanded[instance] = false
		end
	else
		if self.Expanded[instance] then
			self.Expanded[instance] = nil
		else
			self.Expanded[instance] = true
		end
	end
	self:Refresh ()
end

function Explorer:HandleRowClick (entry, ctrl, shift)
	local instance = entry.Instance

	if shift and self.AnchorIndex then
		local currentIndex = nil
		for index, candidate in ipairs (self.Flat) do
			if candidate.Instance == instance then
				currentIndex = index
				break
			end
		end
		if currentIndex then
			local from = math.min (self.AnchorIndex, currentIndex)
			local to = math.max (self.AnchorIndex, currentIndex)
			local list = {}
			for index = from, to do
				if self.Flat[index] then list[#list + 1] = self.Flat[index].Instance end
			end
			Dex:SetSelection (list, instance)
			self:UpdateSelectionPaints ()
			self:ScrollToInstance (instance)
			return
		end
	end

	if ctrl then
		local list = {}
		local found = false
		for _, selected in ipairs (Dex.Selection.List) do
			if selected == instance then
				found = true
			else
				list[#list + 1] = selected
			end
		end
		if not found then
			list[#list + 1] = instance
			self.Anchor = instance
			self.AnchorIndex = entry and self:IndexOf (instance) or nil
		else
			self.Anchor = list[#list] or nil
			self.AnchorIndex = self.Anchor and self:IndexOf (self.Anchor) or nil
		end
		Dex:SetSelection (list, found and (list[#list] or nil) or instance)
		self:UpdateSelectionPaints ()
		return
	end

	self.Anchor = instance
	self.AnchorIndex = self:IndexOf (instance)
	Dex:SetSelection ({ instance }, instance)
	self:UpdateSelectionPaints ()
end

function Explorer:SelectOnly (instance)
	self.Anchor = instance
	self.AnchorIndex = self:IndexOf (instance)
	Dex:SetSelection ({ instance }, instance)
	self:UpdateSelectionPaints ()
end

function Explorer:IndexOf (instance)
	for index, entry in ipairs (self.Flat) do
		if entry.Instance == instance then return index end
	end
	return nil
end

function Explorer:UpdateSelectionPaints ()
	self.ActivePath = self:ComputeActivePath ()
	for _, row in ipairs (self.RowPool) do
		if row.Visible then self:PaintRow (row) end
	end
end

function Explorer:ScrollToInstance (instance)
	local index = self:IndexOf (instance)
	if not index or not self.Tree then return end
	local height = self.Tree.AbsoluteSize.Y
	local y = math.max (0, (index - 1) * 20 - math.max (0, height / 2 - 20 / 2))
	local maxY = math.max (0, #self.Flat * 20 - height)
	self.Tree.CanvasPosition = Vector2.new (self.Tree.CanvasPosition.X, math.min (y, maxY))
	self:UpdateRows ()
end

function Explorer:Reveal (instance)
	if not instance or instance == game then return end

	if self.Search.Query ~= "" or self.Search.Active then self:ClearSearch (true) end

	local chain = {}
	local current = instance
	while current and current ~= game do
		table.insert (chain, 1, current)
		current = current.Parent
	end
	if current ~= game then return end

	self.HiddenServices[chain[1].Name] = nil
	for index = 1, #chain - 1 do
		self.Expanded[chain[index]] = true
	end
	self:Refresh ()
	self:ScrollToInstance (instance)
end

function Explorer:SelectAllVisible ()
	local list = {}
	if self.Search.Active then
		for _, match in ipairs (self.Search.Matches) do
			list[#list + 1] = match
		end
	else
		for _, entry in ipairs (self.Flat) do
			list[#list + 1] = entry.Instance
		end
	end
	Dex:SetSelection (list, list[1])
	self:UpdateSelectionPaints ()
end

function Explorer:ExpandServices ()
	for _, service in ipairs (self:GetAllServices ()) do
		self.Expanded[service] = true
	end
	self:Refresh ()
end

function Explorer:CollapseAll ()
	self.Expanded = {}
	self.Search.Expanded = {}
	self:Refresh ()
end

function Explorer:ExpandSubtree (instance)
	if not instance then return end
	self.Expanded[instance] = true
	local processed = 0
	local function walk (object)
		if processed > 2500 then return end
		local ok, children = pcall (function ()
			return object:GetChildren ()
		end)
		if not ok then return end
		for _, child in ipairs (children) do
			processed = processed + 1
			if processed > 2500 then return end
			if instanceHasChildren (child) then self.Expanded[child] = true end
			walk (child)
		end
	end
	walk (instance)
	if processed > 2500 then
		Dex:Notify ("Expansion limited to " .. tostring (2500) .. " descendants", "info")
	end
	self:Refresh ()
end

function Explorer:CollapseSubtree (instance)
	if not instance then return end
	local processed = 0
	local function walk (object)
		if processed > 2500 then return end
		local ok, children = pcall (function ()
			return object:GetChildren ()
		end)
		if not ok then return end
		for _, child in ipairs (children) do
			processed = processed + 1
			self.Expanded[child] = nil
			walk (child)
		end
	end
	self.Expanded[instance] = nil
	walk (instance)
	self:Refresh ()
end

function Explorer:AddSearchHistory (query)
	query = tostring (query)
	if query == "" then return end
	for index = #self.SearchHistory, 1, -1 do
		if self.SearchHistory[index]:lower () == query:lower () then table.remove (self.SearchHistory, index) end
	end
	table.insert (self.SearchHistory, 1, query)
	while #self.SearchHistory > 8 do
		table.remove (self.SearchHistory)
	end
	Dex.SearchHistory = self.SearchHistory
end

function Explorer:ClearSearch (silent)
	self.Search.Token = (self.Search.Token or 0) + 1
	self.Search.Query = ""
	self.Search.Searching = false
	self.Search.Active = false
	self.Search.Matches = {}
	self.Search.MatchSet = {}
	self.Search.Visible = {}
	self.Search.Expanded = {}
	self.Search.Truncated = false
	if self.SearchBox and self.SearchBox.Text ~= "" and not silent then
		self._SettingSearchText = true
		self.SearchBox.Text = ""
		self._SettingSearchText = false
	end
	if self.SetClearButtonVisible then self:SetClearButtonVisible (false) end
	self:Refresh ()
end

function Explorer:RunSearch (query, selectFirst)
	query = tostring (query or "")
	if query == "" then
		self:ClearSearch (true)
		return
	end

	self.Search.Token = (self.Search.Token or 0) + 1
	local token = self.Search.Token
	self.Search.Query = query
	self.Search.Searching = true
	self.Search.Active = false
	self.Search.Matches = {}
	self.Search.MatchSet = {}
	self.Search.Visible = {}
	self.Search.Expanded = {}
	self.Search.Truncated = false
	self:Refresh ()

	local mode = self.Search.Mode or "name"
	local lowerQuery = query:lower ()
	local useRegex = self.Search.UseRegex == true
	local caseSensitive = self.Search.CaseSensitive == true
	local searchPattern = caseSensitive and query or lowerQuery
	local isaClass = nil
	if useRegex then
		local raw = query:match ("^%s*[Ii][Ss][Aa]%s*%((.-)%)%s*$")
		if raw then
			local trimmed = raw:match ("^%s*(.-)%s*$")
			if trimmed and trimmed ~= "" then isaClass = trimmed end
		end
	end

	task.spawn (function ()
		local matches = {}
		local truncated = false
		local processed = 0
		local hiddenServices = self.HiddenServices
		local cancelled = false

		local function walk (parent)
			if cancelled then return end
			local ok, children = pcall (function ()
				return parent:GetChildren ()
			end)
			if not ok then return end
			for _, child in ipairs (children) do
				if token ~= Explorer.Search.Token then
					cancelled = true
					return
				end
				if #matches >= 2000 then
					truncated = true
					return
				end
				local skip = parent == game and hiddenServices[child.Name]
				if not skip and child ~= Dex.ScreenGui and isOwnGui (child) then skip = true end
				if not skip then
					processed = processed + 1
					local matched = false
					if isaClass then
						local okIsa, result = pcall (function ()
							return child:IsA (isaClass)
						end)
						matched = okIsa and result == true
					else
						local haystack
						if mode == "class" then
							haystack = caseSensitive and child.ClassName or child.ClassName:lower ()
						else
							haystack = caseSensitive and child.Name or child.Name:lower ()
						end
						if useRegex then
							local okPattern, result = pcall (function ()
								return haystack:find (searchPattern)
							end)
							matched = okPattern and result ~= nil
						else
							matched = haystack:find (searchPattern, 1, true) ~= nil
						end
					end
					if matched then
						matches[#matches + 1] = child
						if #matches >= 2000 then
							truncated = true
							return
						end
					end
					if processed % 220 == 0 then task.wait () end
					if child ~= Dex.ScreenGui and #matches < 2000 then walk (child) end
				end
				if token ~= Explorer.Search.Token then
					cancelled = true
					return
				end
			end
		end

		walk (game)

		if token ~= Explorer.Search.Token or cancelled then return end

		local matchSet = {}
		local visible = {}
		for _, match in ipairs (matches) do
			matchSet[match] = true
			local current = match
			while current and current ~= game do
				visible[current] = true
				current = current.Parent
			end
		end

		self.Search.Matches = matches
		self.Search.MatchSet = matchSet
		self.Search.Visible = visible
		self.Search.Truncated = truncated
		self.Search.Active = true
		self.Search.Searching = false
		self.Search.Expanded = {}
		self:AddSearchHistory (query)
		self:Refresh ()

		if selectFirst and matches[1] then
			self:SelectOnly (matches[1])
			self:ScrollToInstance (matches[1])
		end
	end)
end

function Explorer:ScheduleSearch (text)
	self.Search.Token = (self.Search.Token or 0) + 1
	local token = self.Search.Token
	self.Search.Query = text
	self.Search.Searching = true
	self.Search.Active = false
	self.Search.Matches = {}
	self.Search.MatchSet = {}
	self.Search.Visible = {}
	self.Search.Truncated = false
	self:Refresh ()

	task.delay (0.18, function ()
		if token ~= self.Search.Token then return end
		self:RunSearch (text, false, true)
	end)
end

function Explorer:ShowSearchHistory ()
	local items = {}
	if #self.SearchHistory == 0 then
		items[#items + 1] = { Text = "No recent searches", Enabled = false }
	else
		for _, query in ipairs (self.SearchHistory) do
			local captured = query
			items[#items + 1] = {
				Text = query,
				Callback = function ()
					self._SettingSearchText = true
					self.SearchBox.Text = captured
					self._SettingSearchText = false
					if self.SetClearButtonVisible then self:SetClearButtonVisible (true) end
					self:RunSearch (captured, true, true)
				end,
			}
		end
		items[#items + 1] = { Separator = true }
		items[#items + 1] = {
			Text = "Clear Search History",
			Callback = function ()
				self.SearchHistory = {}
				Dex.SearchHistory = self.SearchHistory
			end,
		}
	end
	Dex:ShowMenu (items, U.MousePoint ())
end

function Explorer:StartClickPick (kind)
	self.PickingMode = kind
	Dex:Notify (
		kind == "Part" and "Click a part in the workspace to select it" or "Click a GUI element to select it",
		"info"
	)
end

function Explorer:HandlePickClick (input)
	if not self.PickingMode then return end
	if not Dex:IsInput (input) then return end
	local kind = self.PickingMode
	self.PickingMode = nil
	local point = U.MousePoint ()

	if kind == "Part" then
		local camera = workspace.CurrentCamera
		if not camera then return end
		local okRay, unitRay = pcall (function ()
			return camera:ViewportPointToRay (point.X, point.Y, 0)
		end)
		if not okRay or not unitRay then return end
		local params = RaycastParams.new ()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local localPlayer = Players and Players.LocalPlayer
		if localPlayer and localPlayer.Character then params.FilterDescendantsInstances = { localPlayer.Character } end
		local okCast, result = pcall (function ()
			return workspace:Raycast (unitRay.Origin, unitRay.Direction * 1000, params)
		end)
		if okCast and result and result.Instance then
			self:Reveal (result.Instance)
			Dex:SetSelection ({ result.Instance }, result.Instance)
		end
	elseif kind == "GUI" then
		local best = nil
		local bestZ = -1
		local function scan (container)
			if not container then return end
			for _, object in ipairs (container:GetDescendants ()) do
				if object:IsA ("GuiObject") and object.Visible and not object:IsDescendantOf (Dex.ScreenGui) then
					if U.PointInGui (object, point) then
						local z = object.ZIndex or 0
						if z > bestZ then
							bestZ = z
							best = object
						end
					end
				end
			end
		end
		pcall (function ()
			scan (game:GetService ("Players").LocalPlayer and game:GetService ("Players").LocalPlayer.PlayerGui)
		end)
		pcall (function ()
			scan (game:GetService ("CoreGui"))
		end)
		if best then
			self:Reveal (best)
			Dex:SetSelection ({ best }, best)
		end
	end
end

function Explorer:ShowOptionsMenu ()
	local hiddenCount = 0
	for _ in pairs (self.HiddenServices) do
		hiddenCount = hiddenCount + 1
	end

	Dex:ShowMenu ({
		{
			Text = "Search by Name",
			Shortcut = "",
			Checked = (self.Search.Mode or "name") == "name",
			Callback = function ()
				self.Search.Mode = "name"
				if self.Search.Query ~= "" then self:RunSearch (self.Search.Query, false, true) end
			end,
		},
		{
			Text = "Search by Class",
			Checked = self.Search.Mode == "class",
			Callback = function ()
				self.Search.Mode = "class"
				if self.Search.Query ~= "" then self:RunSearch (self.Search.Query, false, true) end
			end,
		},
		{ Separator = true },
		{
			Text = "Sort by Name",
			Checked = self.SortByName,
			Callback = function ()
				self.SortByName = not self.SortByName
				Dex:SetConfig ("SortByName", self.SortByName)
				self:InvalidateChildrenCache ()
				self:Refresh ()
			end,
		},
		{
			Text = "Freeze Explorer",
			Checked = function ()
				return self.Frozen == true
			end,
			Callback = function ()
				self.Frozen = not self.Frozen
				if not self.Frozen then self:Refresh () end
			end,
		},
		{
			Text = "Save Game...",
			Callback = function ()
				self:SaveGame ()
			end,
		},
		{
			Text = "Highlight Selection",
			Checked = function ()
				return Dex.SelectionHighlight.Enabled
			end,
			Callback = function ()
				Dex.SelectionHighlight:SetEnabled (not Dex.SelectionHighlight.Enabled)
				Dex:SetConfig ("SelectionHighlight", Dex.SelectionHighlight.Enabled)
			end,
		},
		{
			Text = "Show Services...",
			Callback = function ()
				self:ShowServicePicker ()
			end,
		},
		{
			Text = "Unhide All Services",
			Enabled = hiddenCount > 0,
			Callback = function ()
				self.HiddenServices = {}
				self:Refresh ()
			end,
		},
		{ Separator = true },
		{
			Text = "Expand Services",
			Callback = function ()
				self:ExpandServices ()
			end,
		},
		{
			Text = "Collapse All",
			Callback = function ()
				self:CollapseAll ()
			end,
		},
		{
			Text = "Scroll to Selection",
			Enabled = Dex.Selection.Primary ~= nil,
			Callback = function ()
				if Dex.Selection.Primary then self:Reveal (Dex.Selection.Primary) end
			end,
		},
		{
			Text = "Select Clicked Part",
			Callback = function ()
				self:StartClickPick ("Part")
			end,
		},
		{
			Text = "Select Clicked GUI",
			Callback = function ()
				self:StartClickPick ("GUI")
			end,
		},
		{
			Text = "Refresh",
			Callback = function ()
				self:Refresh ()
			end,
		},
	}, U.MousePoint ())
end

function Explorer:ShowServicePicker ()
	local services = self:GetAllServicesIncludingHidden ()
	local items = {}
	for _, service in ipairs (services) do
		items[#items + 1] = {
			Text = service.Name,
			Value = service,
			Class = service.ClassName,
			IsService = true,
			Selected = not self.HiddenServices[service.Name],
		}
	end

	local picker
	picker = Dex:ShowPicker ({
		Items = items,
		Width = 250,
		MaxHeight = 360,
		ShowIcons = true,
		Search = true,
		SearchPlaceholder = "Show services...",
		AutoFocus = true,
		KeepOpen = true,
		OnSelect = function (_, item)
			local service = item.Value
			if self.HiddenServices[service.Name] then
				self.HiddenServices[service.Name] = nil
				item.Selected = true
			else
				self.HiddenServices[service.Name] = true
				item.Selected = false
			end
			self:Refresh ()
		end,
	})
	return picker
end

Dex:Track (Dex.SelectionChanged:Connect (function (selection)
	if not Explorer.Tree then return end
	local primary = selection.Primary
	if primary and primary ~= game then
		local inFlat = Explorer:IndexOf (primary) ~= nil
		if not inFlat then
			local isDescendant = false
			pcall (function ()
				isDescendant = primary:IsDescendantOf (game)
			end)
			if isDescendant then Explorer:Reveal (primary) end
		end
	end
	Explorer:UpdateSelectionPaints ()
end))

function Explorer:GetActionSelection ()
	return U.TopLevel (Dex.Selection.List)
end

function Explorer:CopySelection (cut)
	local items = self:GetActionSelection ()
	if #items == 0 then return end
	self.Clipboard = {
		Items = items,
		Cut = cut == true,
	}
	if cut then Dex:Notify ("Cut " .. tostring (#items) .. " object" .. (#items == 1 and "" or "s"), "info") end
end

function Explorer:GetPasteTarget ()
	local target = Dex.Selection.Primary
	if target and target ~= game then return target end
	return workspace
end

function Explorer:Paste ()
	local clipboard = self.Clipboard
	if not clipboard or #clipboard.Items == 0 then return end
	local target = self:GetPasteTarget ()
	local created = {}

	for _, source in ipairs (clipboard.Items) do
		if source and source.Parent ~= nil then
			if clipboard.Cut then
				local ok = pcall (function ()
					source.Parent = target
				end)
				if ok then created[#created + 1] = source end
			else
				local clone = U.CloneInto (source, target)
				if clone then created[#created + 1] = clone end
			end
		end
	end

	if clipboard.Cut then self.Clipboard = nil end

	if #created > 0 then
		self.Expanded[target] = true
		self:Refresh ()
		Dex:SetSelection (created, created[#created])
		self:Reveal (created[#created])
	else
		Dex:Notify ("Unable to paste into that object", "error")
	end
end

function Explorer:DuplicateSelection ()
	local items = self:GetActionSelection ()
	local created = {}
	for _, source in ipairs (items) do
		if source and source.Parent ~= nil then
			local clone = U.CloneInto (source, source.Parent)
			if clone then created[#created + 1] = clone end
		end
	end
	if #created > 0 then
		self:Refresh ()
		Dex:SetSelection (created, created[#created])
		self:Reveal (created[#created])
	else
		Dex:Notify ("Unable to duplicate the selection", "error")
	end
end

function Explorer:DeleteSelection ()
	local items = self:GetActionSelection ()
	if #items == 0 then return end

	local deleteSet = {}
	for _, object in ipairs (items) do
		deleteSet[object] = true
	end

	local primary = Dex.Selection.Primary or items[1]
	local nextSelection = nil
	if primary then
		local parent = primary.Parent
		if parent and parent ~= game then
			local children = {}
			pcall (function ()
				children = parent:GetChildren ()
			end)
			local index = nil
			for childIndex, child in ipairs (children) do
				if child == primary then
					index = childIndex
					break
				end
			end
			if index then
				for offset = 1, #children do
					local candidate = children[index + offset] or children[index - offset]
					if candidate and not deleteSet[candidate] then
						nextSelection = candidate
						break
					end
				end
			end
		end
	end

	local failures = 0
	for _, object in ipairs (items) do
		local ok = pcall (function ()
			object:Destroy ()
		end)
		if not ok then failures = failures + 1 end
	end

	if nextSelection and nextSelection.Parent then
		Dex:SetSelection ({ nextSelection }, nextSelection)
		self:Reveal (nextSelection)
	else
		Dex:ClearSelection ()
	end
	self:Refresh ()
	if failures > 0 then Dex:Notify ("Some objects could not be deleted", "error") end
end

function Explorer:RenameSelection ()
	local primary = Dex.Selection.Primary
	if primary then self:StartRename (primary) end
end

function Explorer:CanGroup ()
	local items = self:GetActionSelection ()
	if #items == 0 then return false end
	local parent = items[1].Parent
	if not parent or parent == game then return false end
	for _, item in ipairs (items) do
		if item.Parent ~= parent then return false end
	end
	return true
end

function Explorer:GroupSelection (asFolder)
	local items = self:GetActionSelection ()
	if #items == 0 then return end
	local parent = items[1].Parent
	if not parent or parent == game then
		Dex:Notify ("Services cannot be grouped", "warning")
		return
	end

	local group = U.Create (asFolder and "Folder" or "Model", {
		Name = asFolder and "Folder" or "Model",
	})
	local ok = pcall (function ()
		group.Parent = parent
	end)
	if not ok then
		group:Destroy ()
		Dex:Notify ("Unable to create group", "error")
		return
	end
	for _, item in ipairs (items) do
		pcall (function ()
			item.Parent = group
		end)
	end
	self.Expanded[parent] = true
	self.Expanded[group] = true
	self:Refresh ()
	Dex:SetSelection ({ group }, group)
	self:Reveal (group)
end

function Explorer:UngroupSelection ()
	local items = self:GetActionSelection ()
	local ungrouped = {}
	for _, item in ipairs (items) do
		if item:IsA ("Model") or item:IsA ("Folder") then
			local parent = item.Parent
			if parent then
				for _, child in ipairs (item:GetChildren ()) do
					pcall (function ()
						child.Parent = parent
					end)
					ungrouped[#ungrouped + 1] = child
				end
				pcall (function ()
					item:Destroy ()
				end)
			end
		end
	end
	if #ungrouped > 0 then
		self:Refresh ()
		Dex:SetSelection (ungrouped, ungrouped[1])
	end
end

function Explorer:SelectChildren (recursive)
	local primary = Dex.Selection.Primary
	if not primary then return end
	local list = {}
	if recursive then
		local ok, descendants = pcall (function ()
			return primary:GetDescendants ()
		end)
		if ok then list = descendants end
	else
		local ok, children = pcall (function ()
			return primary:GetChildren ()
		end)
		if ok then list = children end
	end
	Dex:SetSelection (list, list[1])
	self:UpdateSelectionPaints ()
end

function Explorer:StartRename (instance)
	if not instance or self.Renaming then return end
	if not self:IndexOf (instance) then self:Reveal (instance) end
	local index = self:IndexOf (instance)
	if not index then return end
	self:ScrollToInstance (instance)
	local entry = self.Flat[index]
	local nameX = 7 + entry.Depth * 15 + 14 + 2 + 16 + 5
	local width = math.min (math.max (140, (self.FlatWidth or 300) - nameX - 18), 300)

	self.Renaming = instance
	local box = U.Textbox (self.Tree, {
		Name = "RenameBox",
		BackgroundColor3 = Dex.Theme.Explorer.SearchBackground,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (nameX - 3, (index - 1) * 20 + 1),
		Size = UDim2.new (0, width, 0, 20 - 2),
		Font = Dex.Fonts.UI,
		Text = instance.Name,
		TextColor3 = Dex.Theme.Explorer.SearchText,
		TextSize = 14,
		ClearTextOnFocus = false,
		ZIndex = 20,
	})
	U.Corner (box, 3)
	U.Stroke (box, Dex.Theme.Explorer.SearchBorderFocused, 1, 0)

	local cancelled = false
	local finished = false
	local escapeConnection

	local function finish (commit)
		if finished then return end
		finished = true
		if escapeConnection then pcall (function ()
			escapeConnection:Disconnect ()
		end) end
		local text = box.Text
		box:Destroy ()
		self.Renaming = nil
		if commit and not cancelled and text ~= "" and text ~= instance.Name then
			local ok, err = pcall (function ()
				instance.Name = text
			end)
			if not ok then Dex:Notify (tostring (err), "error") end
		end
		self:Refresh ()
		if self._RefreshPending then
			self._RefreshPending = false
			self:Refresh ()
		end
	end

	box.FocusLost:Connect (function (enterPressed)
		finish (true)
	end)
	escapeConnection = UIS.InputBegan:Connect (function (input)
		if input.KeyCode == Enum.KeyCode.Escape then
			cancelled = true
			box:ReleaseFocus (true)
		end
	end)

	task.defer (function ()
		if box and box.Parent then
			box:CaptureFocus ()
			box.SelectionStart = 1
			box.CursorPosition = #box.Text + 1
		end
	end)
end

function Explorer:GetInsertableClasses ()
	local result = {}
	local seen = {}

	local function add (name)
		if type (name) ~= "string" or name == "" or seen[name] then return end
		seen[name] = true
		result[#result + 1] = name
	end

	for _, name in ipairs (CommonClasses) do
		add (name)
	end
	for _, name in ipairs (AllClassFallback) do
		add (name)
	end

	if Dex.Reflect and Dex.Reflect.Ready and not Dex.Reflect.Failed then
		for className, class in pairs (Dex.Reflect.Classes) do
			local tags = class.Tags or {}
			if
				not tags.Service
				and not tags.NotCreatable
				and not tags.Settings
				and not tags.Deprecated
				and className ~= "Instance"
			then
				add (className)
			end
		end
	end

	local creatable = {}
	for _, name in ipairs (result) do
		local ok, object = pcall (function ()
			return U.Create (name)
		end)
		if ok and object then creatable[#creatable + 1] = name end
	end
	result = creatable

	table.sort (result, function (a, b)
		local rankA = CommonRank[a]
		local rankB = CommonRank[b]
		if rankA and rankB then
			return rankA < rankB
		elseif rankA then
			return true
		elseif rankB then
			return false
		end
		return a:lower () < b:lower ()
	end)

	return result
end

function Explorer:GetInsertTarget ()
	local primary = Dex.Selection.Primary
	if not primary or primary == game then return workspace end
	return primary
end

function Explorer:InsertClass (className, target)
	target = target or self:GetInsertTarget ()
	if not target then target = workspace end

	local ok, object = pcall (function ()
		return U.Create (className)
	end)
	if not ok or not object then
		Dex:Notify ("Cannot create " .. tostring (className), "error")
		return nil
	end

	local parentOk = pcall (function ()
		object.Parent = target
	end)
	if not parentOk then
		object:Destroy ()
		Dex:Notify ("Cannot insert " .. tostring (className) .. " into that object", "error")
		return nil
	end

	self.Expanded[target] = true
	self:Refresh ()
	Dex:SetSelection ({ object }, object)
	self:Reveal (object)
	return object
end

function Explorer:ShowInsertPicker ()
	local classes = self:GetInsertableClasses ()
	local items = {}
	for _, className in ipairs (classes) do
		items[#items + 1] = {
			Text = className,
			Value = className,
			Class = className,
		}
	end

	local position = U.MousePoint ()
	Dex:ShowPicker ({
		Items = items,
		Position = position,
		Width = 280,
		MaxHeight = 390,
		ShowIcons = true,
		Search = true,
		SearchPlaceholder = "Insert object...",
		AutoFocus = true,
		Limit = 260,
		EmptyText = "No creatable classes",
		OnSelect = function (className)
			self:InsertClass (className)
		end,
	})
end

function Explorer:InsertMenuItems ()
	local items = {}
	local target = self:GetInsertTarget ()
	for _, className in ipairs (CommonClasses) do
		local name = className
		items[#items + 1] = {
			Text = name,
			Icon = name,
			Callback = function ()
				self:InsertClass (name, target)
			end,
		}
	end
	items[#items + 1] = { Separator = true }
	items[#items + 1] = {
		Text = "Insert Object...",
		Callback = function ()
			self:ShowInsertPicker ()
		end,
	}
	return items
end

function Explorer:ShowContextMenu (instance, position)
	if not instance then
		Dex:ShowMenu ({
			{
				Text = "Insert Object...",
				Callback = function ()
					self:ShowInsertPicker ()
				end,
			},
			{ Separator = true },
			{
				Text = "Select All",
				Callback = function ()
					self:SelectAllVisible ()
				end,
			},
			{
				Text = "Expand Services",
				Callback = function ()
					self:ExpandServices ()
				end,
			},
			{
				Text = "Collapse All",
				Callback = function ()
					self:CollapseAll ()
				end,
			},
			{
				Text = "Refresh",
				Callback = function ()
					self:Refresh ()
				end,
			},
		}, position or U.MousePoint ())
		return
	end

	local items = self:GetActionSelection ()
	local hasSelection = #items > 0
	local canGroup = self:CanGroup ()
	local hasUngroupable = false
	for _, item in ipairs (items) do
		if item:IsA ("Model") or item:IsA ("Folder") then
			hasUngroupable = true
			break
		end
	end

	local playerInstance = typeof (instance) == "Instance" and instance:IsA ("Player") and instance or nil
	local characterInstance = nil
	pcall (function ()
		characterInstance = Players and Players:GetPlayerFromCharacter (instance)
	end)
	characterInstance = typeof (characterInstance) == "Instance"
			and characterInstance:IsA ("Player")
			and characterInstance
		or nil
	local viewable = false
	local previewable = false
	if typeof (instance) == "Instance" then
		local ok, result = pcall (function ()
			return instance:IsA ("BasePart")
				or instance:IsA ("Model")
				or instance:IsA ("Player")
				or instance:IsA ("Humanoid")
		end)
		viewable = ok and result
		local okPreview, previewResult = pcall (function ()
			if instance:IsA ("Player") then
				return instance.Character ~= nil
			elseif instance:IsA ("Humanoid") then
				return true
			end
			return instance:IsA ("BasePart") or instance:FindFirstChildWhichIsA ("BasePart", true) ~= nil
		end)
		previewable = okPreview and previewResult
	end
	local shortcutCtrl = Dex.Shortcut.Ctrl
	local shortcutShift = Dex.Shortcut.Shift

	local menu = {
		{
			Text = "Cut",
			Shortcut = shortcutCtrl .. "X",
			Enabled = hasSelection,
			Callback = function ()
				self:CopySelection (true)
			end,
		},
		{
			Text = "Copy",
			Shortcut = shortcutCtrl .. "C",
			Enabled = hasSelection,
			Callback = function ()
				self:CopySelection (false)
			end,
		},
		{
			Text = "Duplicate",
			Shortcut = shortcutCtrl .. "D",
			Enabled = hasSelection,
			Callback = function ()
				self:DuplicateSelection ()
			end,
		},
		{
			Text = "Delete",
			Shortcut = "Del",
			Enabled = hasSelection,
			Callback = function ()
				self:DeleteSelection ()
			end,
		},
		{
			Text = "Rename",
			Shortcut = "F2",
			Enabled = hasSelection,
			Callback = function ()
				self:RenameSelection ()
			end,
		},
		{ Separator = true },
		{
			Text = "Group As a Model",
			Shortcut = shortcutCtrl .. "G",
			Enabled = canGroup,
			Callback = function ()
				self:GroupSelection (false)
			end,
		},
		{
			Text = "Group As a Folder",
			Shortcut = shortcutShift .. shortcutCtrl .. "G",
			Enabled = canGroup,
			Callback = function ()
				self:GroupSelection (true)
			end,
		},
		{
			Text = "Ungroup",
			Shortcut = shortcutCtrl .. "U",
			Enabled = hasUngroupable,
			Callback = function ()
				self:UngroupSelection ()
			end,
		},
		{ Separator = true },
		{
			Text = "Select Children",
			Callback = function ()
				self:SelectChildren (false)
			end,
		},
		{
			Text = "Select Descendants",
			Callback = function ()
				self:SelectChildren (true)
			end,
		},
		{
			Text = "Select Character",
			Enabled = playerInstance ~= nil,
			Callback = function ()
				if not playerInstance then return end
				local character = nil
				local getCharacter = nil
				pcall (function ()
					getCharacter = Players and Players.GetCharacterFromPlayer
				end)
				if typeof (getCharacter) == "function" then
					local ok, result = pcall (function ()
						return getCharacter (Players, playerInstance)
					end)
					if ok then character = result end
				end
				if typeof (character) ~= "Instance" then
					local ok, result = pcall (function ()
						return playerInstance.Character
					end)
					if ok then character = result end
				end
				if typeof (character) == "Instance" then
					self:SelectOnly (character)
					self:ScrollToInstance (character)
				else
					Dex:Notify ("No character found for " .. tostring (playerInstance.Name), "info")
				end
			end,
		},
		{
			Text = "Select Player",
			Enabled = characterInstance ~= nil,
			Callback = function ()
				local player = nil
				pcall (function ()
					player = Players and Players:GetPlayerFromCharacter (instance)
				end)
				if typeof (player) == "Instance" and player:IsA ("Player") then
					self:SelectOnly (player)
					self:ScrollToInstance (player)
				else
					Dex:Notify ("No player found for " .. tostring (instance.Name), "info")
				end
			end,
		},
		{
			Text = self:IsViewing (instance) and "Unview" or "View",
			Enabled = viewable or self:IsViewing (instance),
			Callback = function ()
				self:ViewInstance (instance)
			end,
		},
		{
			Text = self:IsPinned (instance) and "Unpin Instance" or "Pin Instance",
			Callback = function ()
				self:TogglePin (instance)
			end,
		},
		{
			Text = "3D Preview",
			Enabled = previewable,
			Callback = function ()
				if Dex.ModelViewer then
					Dex.ModelViewer:Show (instance)
				else
					Dex:Notify ("Model viewer is unavailable", "error")
				end
			end,
		},
		{
			Text = "Make Script",
			Callback = function ()
				self:MakeScript (instance)
			end,
		},
		{
			Text = "Insert",
			Submenu = self:InsertMenuItems (),
		},
		{
			Text = "Hierarchy",
			Submenu = {
				{
					Text = "Select Children",
					Callback = function ()
						self:SelectChildren (false)
					end,
				},
				{
					Text = "Select Descendants",
					Callback = function ()
						self:SelectChildren (true)
					end,
				},
				{ Separator = true },
				{
					Text = "Expand All Descendants",
					Callback = function ()
						self:ExpandSubtree (instance)
					end,
				},
				{
					Text = "Collapse All Descendants",
					Callback = function ()
						self:CollapseSubtree (instance)
					end,
				},
				{
					Text = "Reveal Selection",
					Enabled = Dex.Selection.Primary ~= nil,
					Callback = function ()
						if Dex.Selection.Primary then self:Reveal (Dex.Selection.Primary) end
					end,
				},
			},
		},
	}

	if isServiceInstance (instance) then
		menu[#menu + 1] = { Separator = true }
		menu[#menu + 1] = {
			Text = "Hide Service in Explorer",
			Callback = function ()
				self.HiddenServices[instance.Name] = true
				self:Refresh ()
			end,
		}
		menu[#menu + 1] = {
			Text = "Show Services...",
			Callback = function ()
				self:ShowServicePicker ()
			end,
		}
	end

	if instance:IsA ("LuaSourceContainer") then
		menu[#menu + 1] = { Separator = true }
		menu[#menu + 1] = {
			Text = "View Source",
			Callback = function ()
				Dex:ShowScriptViewer (instance.Source, instance.Name, instance)
			end,
		}
		menu[#menu + 1] = {
			Text = "Decompile",
			Enabled = type (decompile) == "function",
			Callback = function ()
				if type (decompile) ~= "function" then
					Dex:Notify ("decompile is not available in this environment", "error")
					return
				end
				task.spawn (function ()
					local ok, source = pcall (decompile, instance)
					if ok then
						Dex:ShowScriptViewer (source, instance.Name, instance)
					else
						Dex:Notify (tostring (source), "error")
					end
				end)
			end,
		}
		local bytecodeFn = rawget (genv, "getscriptbytecode") or getscriptbytecode
		menu[#menu + 1] = {
			Text = "Bytecode",
			Enabled = type (bytecodeFn) == "function",
			Submenu = {
				{
					Text = "Copy Bytecode",
					Callback = function ()
						local ok, bytecode = pcall (bytecodeFn, instance)
						if not ok or type (bytecode) ~= "string" then
							Dex:Notify (tostring (bytecode), "error")
							return
						end
						if Dex:CopyText (bytecode) then Dex:Notify ("Bytecode copied", "success") end
					end,
				},
				{
					Text = "Save Bytecode",
					Callback = function ()
						if type (writefile) ~= "function" then
							Dex:Notify ("writefile is not available", "error")
							return
						end
						Dex:Prompt ({
							Title = "Save Bytecode",
							Message = "File name:",
							Value = tostring (instance.Name) .. ".lua.bc",
							ConfirmText = "Save",
							OnConfirm = function (name)
								local ok, bytecode = pcall (bytecodeFn, instance)
								if not ok or type (bytecode) ~= "string" then
									Dex:Notify (tostring (bytecode), "error")
									return
								end
								local written, err = pcall (writefile, tostring (name), bytecode)
								if written then
									Dex:Notify ("Saved " .. tostring (name), "success")
								else
									Dex:Notify (tostring (err), "error")
								end
							end,
						})
					end,
				},
			},
		}
	end

	local canTeleport = false
	if typeof (instance) == "Instance" then
		local ok, result = pcall (function ()
			return instance:IsA ("BasePart") or instance:IsA ("Model")
		end)
		canTeleport = ok and result
	end
	if canTeleport then
		menu[#menu + 1] = {
			Text = "Teleport To",
			Callback = function ()
				local player = Players and Players.LocalPlayer
				local character = player and player.Character
				local root = character and character:FindFirstChild ("HumanoidRootPart")
				if not root then
					Dex:Notify ("No character to teleport", "warning")
					return
				end
				local ok, focus, size = pcall (function ()
					if instance:IsA ("BasePart") then return instance.CFrame, instance.Size end
					return instance:GetBoundingBox ()
				end)
				if not ok or not focus then
					Dex:Notify ("Cannot teleport to that instance", "warning")
					return
				end
				local lift = size and math.max (2, size.Y * 0.5) or 3
				pcall (function ()
					root.CFrame = CFrame.new (focus.Position + Vector3.new (0, lift, 0))
				end)
			end,
		}
	end

	menu[#menu + 1] = { Separator = true }
	menu[#menu + 1] = {
		Text = "Copy Path",
		Callback = function ()
			Dex:CopyText (U.PathOf (instance))
		end,
	}
	menu[#menu + 1] = {
		Text = "Copy Full Name",
		Callback = function ()
			local ok, fullName = pcall (function ()
				return instance:GetFullName ()
			end)
			Dex:CopyText (ok and fullName or instance.Name)
		end,
	}
	menu[#menu + 1] = {
		Text = "Save / Export",
		Submenu = {
			{
				Text = "Copy Class Name",
				Callback = function ()
					Dex:CopyText (instance.ClassName)
				end,
			},
			{
				Text = "Copy Path",
				Callback = function ()
					Dex:CopyText (U.PathOf (instance))
				end,
			},
			{
				Text = "Save Instance...",
				Enabled = type (rawget (genv, "saveinstance")) == "function",
				Callback = function ()
					local save = rawget (genv, "saveinstance")
					self:PromptSaveFilename (instance.Name, function (name)
						local ok, err = pcall (save, {
							FileName = "/Dex/Saved/" .. name .. ".rbxlx",
						})
						if ok then
							Dex:Notify ("Saved to /workspace/Dex/Saved/" .. name .. ".rbxlx", "success")
						else
							Dex:Notify (tostring (err), "error")
						end
					end)
				end,
			},
		},
	}
	menu[#menu + 1] = {
		Text = "Help",
		Callback = function ()
			Dex:Notify ("F2 rename  •  Del delete  •  Ctrl+C/V/X  •  Right-click for actions", "info")
		end,
	}

	Dex:ShowMenu (menu, position or U.MousePoint ())
end

function Explorer:SelectRelative (offset)
	local primary = Dex.Selection.Primary
	local current = primary and self:IndexOf (primary) or nil
	local target = current and (current + offset) or (offset > 0 and 1 or #self.Flat)
	target = math.clamp (target, 1, #self.Flat)
	local entry = self.Flat[target]
	if entry then
		self:SelectOnly (entry.Instance)
		self:ScrollToInstance (entry.Instance)
	end
end

function Explorer:SelectParent ()
	local primary = Dex.Selection.Primary
	if not primary then return end
	local parent = primary.Parent
	if parent and parent ~= game then
		self:SelectOnly (parent)
		self:ScrollToInstance (parent)
	end
end

function Explorer:SelectChild ()
	local primary = Dex.Selection.Primary
	if not primary then return end
	local ok, children = pcall (function ()
		return primary:GetChildren ()
	end)
	if not ok or #children == 0 then return end
	self.Expanded[primary] = true
	self:Refresh ()
	local index = self:IndexOf (primary)
	if index and self.Flat[index + 1] then
		local child = self.Flat[index + 1].Instance
		self:SelectOnly (child)
		self:ScrollToInstance (child)
	end
end

function Explorer:HandleKey (input)
	if Dex.ActiveWindow ~= self.Window or not self.Window.Visible then return end
	if UIS:GetFocusedTextBox () then return end
	if Dex._menuState or Dex._picker or Dex._colorPicker or Dex._prompt then return end

	local ctrl = UIS:IsKeyDown (Enum.KeyCode.LeftControl) or UIS:IsKeyDown (Enum.KeyCode.RightControl)
	local shift = UIS:IsKeyDown (Enum.KeyCode.LeftShift) or UIS:IsKeyDown (Enum.KeyCode.RightShift)

	if input.KeyCode == Enum.KeyCode.Delete then
		self:DeleteSelection ()
	elseif input.KeyCode == Enum.KeyCode.Insert then
		self:ShowInsertPicker ()
	elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Up then
		self:SelectRelative (input.KeyCode == Enum.KeyCode.Down and 1 or -1)
	elseif input.KeyCode == Enum.KeyCode.Left then
		self:SelectParent ()
	elseif input.KeyCode == Enum.KeyCode.Right then
		self:SelectChild ()
	elseif input.KeyCode == Enum.KeyCode.F2 then
		self:RenameSelection ()
	elseif ctrl and input.KeyCode == Enum.KeyCode.C then
		self:CopySelection (false)
	elseif ctrl and input.KeyCode == Enum.KeyCode.X then
		self:CopySelection (true)
	elseif ctrl and input.KeyCode == Enum.KeyCode.V then
		self:Paste ()
	elseif ctrl and input.KeyCode == Enum.KeyCode.D then
		self:DuplicateSelection ()
	elseif ctrl and shift and input.KeyCode == Enum.KeyCode.G then
		self:GroupSelection (true)
	elseif ctrl and input.KeyCode == Enum.KeyCode.G then
		self:GroupSelection (false)
	elseif ctrl and input.KeyCode == Enum.KeyCode.U then
		self:UngroupSelection ()
	elseif ctrl and input.KeyCode == Enum.KeyCode.A then
		self:SelectAllVisible ()
	end
end

function Explorer:Build (content)
	self.Content = content
	self.Search = {
		Query = "",
		Mode = "name",
		UseRegex = false,
		CaseSensitive = false,
		Active = false,
		Searching = false,
		Matches = {},
		MatchSet = {},
		Visible = {},
		Expanded = {},
		Token = 0,
		Truncated = false,
	}
	self.SearchHistory = Dex.SearchHistory or {}

	local searchRow = U.Frame (content, {
		Name = "SearchRow",
		BackgroundTransparency = 1,
		Size = UDim2.new (1, 0, 0, 38),
		ZIndex = 2,
	})

	local searchHolder = U.Frame (searchRow, {
		Name = "SearchHolder",
		BackgroundColor3 = Dex.Theme.Explorer.SearchBackground,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (8, 6),
		Size = UDim2.new (1, -50, 0, 26),
		ZIndex = 3,
	})
	U.Corner (searchHolder, 6)
	local searchStroke = U.Stroke (searchHolder, Dex.Theme.Explorer.SearchBorder, 1, 0)

	local buttonHolder = U.Frame (searchHolder, {
		Name = "SearchButtons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -2, 0, 0),
		Size = UDim2.new (0, 108, 1, 0),
		ZIndex = 4,
	})
	local buttonLayout = U.List (buttonHolder, 2, true)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	self.SearchButtonsHolder = buttonHolder

	local searchBox = U.Textbox (searchHolder, {
		Name = "Search",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (9, 0),
		Size = UDim2.new (1, -110, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = Dex.Theme.Explorer.Placeholder,
		TextColor3 = Dex.Theme.Explorer.SearchText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 4,
	})
	self.SearchBox = searchBox

	local function searchToggle (text, order, tooltip, getter, setter)
		local btn = buttonAt (buttonHolder, {
			Name = tooltip,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset (20, 18),
			LayoutOrder = order,
			Font = Dex.Fonts.UIMedium,
			Text = text,
			TextColor3 = Dex.Theme.Explorer.Placeholder,
			TextSize = 11,
			ZIndex = 4,
		})
		local function paint ()
			btn.TextColor3 = getter () and Dex.Theme.Explorer.SelectionText or Dex.Theme.Explorer.Placeholder
			btn.BackgroundTransparency = getter () and 0 or 1
			btn.BackgroundColor3 = Dex.Theme.Explorer.Hover
		end
		paint ()
		btn.MouseEnter:Connect (function ()
			btn.BackgroundTransparency = 0
			btn.BackgroundColor3 = Dex.Theme.Explorer.Hover
		end)
		btn.MouseLeave:Connect (function ()
			paint ()
		end)
		btn.MouseButton1Click:Connect (function ()
			setter (not getter ())
			paint ()
			if self.Search.Query ~= "" then self:RunSearch (self.Search.Query, false, true) end
			searchBox:CaptureFocus ()
		end)
		Dex:AttachTooltip (btn, tooltip)
		return btn
	end

	local regexButton = searchToggle (".*", 2, "Use regex", function ()
		return self.Search.UseRegex
	end, function (value)
		self.Search.UseRegex = value
		if self.RefreshIsA then self.RefreshIsA () end
	end)
	local caseButton = searchToggle ("Aa", 3, "Match case", function ()
		return self.Search.CaseSensitive
	end, function (value)
		self.Search.CaseSensitive = value
	end)
	self.RegexButton = regexButton
	self.CaseButton = caseButton

	local isaButton = buttonAt (buttonHolder, {
		Name = "IsAFilter",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (18, 18),
		LayoutOrder = 1,
		Font = Dex.Fonts.UIMedium,
		Text = "IsA",
		TextColor3 = Dex.Theme.Explorer.TextDisabled,
		TextSize = 10,
		ZIndex = 4,
	})
	self.IsAButton = isaButton
	self.RefreshIsA = function ()
		local enabled = self.Search.UseRegex == true
		isaButton.Active = enabled
		isaButton.Selectable = enabled
		isaButton.TextColor3 = enabled and Dex.Theme.Explorer.SelectionText or Dex.Theme.Explorer.TextDisabled
		isaButton.BackgroundTransparency = enabled and 0 or 1
		isaButton.BackgroundColor3 = Dex.Theme.Explorer.Hover
	end
	self.RefreshIsA ()
	isaButton.MouseButton1Click:Connect (function ()
		if self.Search.UseRegex ~= true then return end
		local current = searchBox.Text
		local position = searchBox.CursorPosition or (#current + 1)
		local snippet = "IsA()"
		self._SettingSearchText = true
		searchBox.Text = current:sub (1, position - 1) .. snippet .. current:sub (position)
		self._SettingSearchText = false
		searchBox.CursorPosition = position + #snippet
		searchBox:CaptureFocus ()
	end)
	Dex:AttachTooltip (isaButton, "IsA(...) — regex mode only")

	local clearButton = buttonAt (buttonHolder, {
		Name = "Clear",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (18, 18),
		LayoutOrder = 4,
		Text = "",
		Visible = false,
		ZIndex = 4,
	})
	U.DrawX (clearButton, 7, Dex.Theme.Explorer.Placeholder)
	self.ClearSearchButton = clearButton
	function self:SetClearButtonVisible (visible)
		if not self.ClearSearchButton then return end
		self.ClearSearchButton.Visible = visible == true
		self.ClearSearchButton.Parent = visible and self.SearchButtonsHolder or nil
	end

	clearButton.MouseEnter:Connect (function ()
		clearButton.BackgroundTransparency = 0
		clearButton.BackgroundColor3 = Dex.Theme.Explorer.Hover
	end)
	clearButton.MouseLeave:Connect (function ()
		clearButton.BackgroundTransparency = 1
	end)
	clearButton.MouseButton1Click:Connect (function ()
		self:ClearSearch (false)
		searchBox:CaptureFocus ()
	end)

	local historyButton = buttonAt (buttonHolder, {
		Name = "History",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (22, 22),
		LayoutOrder = 5,
		Text = "",
		ZIndex = 4,
	})
	makeHistoryIcon (historyButton)
	historyButton.MouseEnter:Connect (function ()
		historyButton.BackgroundTransparency = 0
		historyButton.BackgroundColor3 = Dex.Theme.Explorer.Hover
	end)
	historyButton.MouseLeave:Connect (function ()
		historyButton.BackgroundTransparency = 1
	end)
	historyButton.MouseButton1Click:Connect (function ()
		self:ShowSearchHistory ()
	end)
	Dex:AttachTooltip (historyButton, "Search history")

	local optionsButton = buttonAt (searchRow, {
		Name = "Options",
		BackgroundColor3 = Dex.Theme.Explorer.SearchBackground,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -8, 0, 6),
		Size = UDim2.fromOffset (28, 26),
		Font = Dex.Fonts.UIBold,
		Text = "···",
		TextColor3 = Dex.Theme.Explorer.Placeholder,
		TextSize = 14,
		ZIndex = 3,
	})
	U.Corner (optionsButton, 6)
	optionsButton.MouseEnter:Connect (function ()
		optionsButton.BackgroundColor3 = Dex.Theme.Explorer.Hover
		optionsButton.TextColor3 = Dex.Theme.Explorer.Text
	end)
	optionsButton.MouseLeave:Connect (function ()
		optionsButton.BackgroundColor3 = Dex.Theme.Explorer.SearchBackground
		optionsButton.TextColor3 = Dex.Theme.Explorer.Placeholder
	end)
	optionsButton.MouseButton1Click:Connect (function ()
		self:ShowOptionsMenu ()
	end)
	Dex:AttachTooltip (optionsButton, "Explorer options")

	searchBox.Focused:Connect (function ()
		searchStroke.Color = Dex.Theme.Explorer.SearchBorderFocused
		self.Window:Focus ()
	end)
	searchBox.FocusLost:Connect (function (enterPressed)
		searchStroke.Color = Dex.Theme.Explorer.SearchBorder
		if enterPressed and searchBox.Text ~= "" then self:RunSearch (searchBox.Text, true, true) end
	end)
	searchBox:GetPropertyChangedSignal ("Text"):Connect (function ()
		if self._SettingSearchText then return end
		local text = searchBox.Text
		self:SetClearButtonVisible (text ~= "")
		if text == "" then
			self:ClearSearch (true)
		else
			self:ScheduleSearch (text)
		end
	end)

	local header = U.Frame (content, {
		Name = "SearchResultsHeader",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (0, 38),
		Size = UDim2.new (1, 0, 0, 26),
		Visible = false,
		ZIndex = 2,
	})
	self.ResultsHeader = header
	self.ResultsCount = U.Label (header, {
		Name = "Count",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (12, 0),
		Size = UDim2.new (1, -120, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "0 matches",
		TextColor3 = Dex.Theme.Explorer.TextMuted,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})

	local headerButtons = U.Frame (header, {
		AnchorPoint = Vector2.new (1, 0.5),
		Position = UDim2.new (1, -8, 0.5, 0),
		Size = UDim2.fromOffset (104, 24),
		BackgroundTransparency = 1,
		ZIndex = 3,
	})
	U.List (headerButtons, 2, true)
	local headerLayout = headerButtons:FindFirstChildOfClass ("UIListLayout")
	if headerLayout then
		headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	end

	local function headerButton (glyph, tooltip, callback)
		local button = buttonAt (headerButtons, {
			Name = tooltip,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset (22, 22),
			Font = Dex.Fonts.UIMedium,
			Text = glyph,
			TextColor3 = Dex.Theme.Explorer.TextMuted,
			TextSize = 16,
			ZIndex = 4,
		})
		button.MouseEnter:Connect (function ()
			button.BackgroundTransparency = 0
			button.BackgroundColor3 = Dex.Theme.Explorer.Hover
			button.TextColor3 = Dex.Theme.Explorer.Text
		end)
		button.MouseLeave:Connect (function ()
			button.BackgroundTransparency = 1
			button.TextColor3 = Dex.Theme.Explorer.TextMuted
		end)
		button.MouseButton1Click:Connect (callback)
		Dex:AttachTooltip (button, tooltip)
		return button
	end

	self.HeaderSelectAll = headerButton ("▣", "Select all matches", function ()
		self:SelectAllVisible ()
	end)
	headerButton ("⌄", "Expand all results", function ()
		self.Search.Expanded = {}
		self:Refresh ()
	end)
	headerButton ("⌃", "Collapse all results", function ()
		for object in pairs (self.Search.Visible) do
			self.Search.Expanded[object] = false
		end
		self:Refresh ()
	end)
	headerButton ("↻", "Refresh search", function ()
		self:RunSearch (self.Search.Query, false, true)
	end)

	local tree = U.Scroll (content, {
		Name = "Tree",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (0, 38),
		Size = UDim2.new (1, 0, 1, -38),
		CanvasSize = UDim2.new (0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.XY,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Dex.Theme.Explorer.ScrollBar,
		ScrollBarImageTransparency = 0.15,
		ZIndex = 2,
	})
	self.Tree = tree

	local empty = U.Label (content, {
		Name = "Empty",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (0, 38),
		Size = UDim2.new (1, 0, 1, -38),
		Font = Dex.Fonts.UI,
		Text = "",
		TextColor3 = Dex.Theme.Explorer.Empty,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = false,
		ZIndex = 3,
		Active = false,
	})
	self.EmptyLabel = empty

	tree:GetPropertyChangedSignal ("CanvasPosition"):Connect (function ()
		if self.Renaming then return end
		self:UpdateRows ()
	end)
	tree:GetPropertyChangedSignal ("AbsoluteSize"):Connect (function ()
		task.defer (function ()
			self:EnsureRowPool ()
		end)
	end)

	self.Expanded = {}
	self.Search.Expanded = {}

	local function refreshTheme ()
		searchHolder.BackgroundColor3 = Dex.Theme.Explorer.SearchBackground
		searchStroke.Color = Dex.Theme.Explorer.SearchBorder
		searchBox.TextColor3 = Dex.Theme.Explorer.SearchText
		searchBox.PlaceholderColor3 = Dex.Theme.Explorer.Placeholder
		optionsButton.BackgroundColor3 = Dex.Theme.Explorer.SearchBackground
		optionsButton.TextColor3 = Dex.Theme.Explorer.Placeholder
		self.Tree.ScrollBarImageColor3 = Dex.Theme.Explorer.ScrollBar
		self.EmptyLabel.TextColor3 = Dex.Theme.Explorer.Empty
		self.ResultsCount.TextColor3 = Dex.Theme.Explorer.TextMuted
	end
	Dex:Track (Dex.ThemeChanged:Connect (function ()
		if self.Window and self.Window.Visible then refreshTheme () end
	end))
	refreshTheme ()

	self.Window:OnShow (function ()
		if self._Dirty then
			self._Dirty = false
			self:Refresh ()
		else
			self:Refresh ()
		end
	end)
	self.Window:OnResize (function ()
		task.defer (function ()
			self:EnsureRowPool ()
			self:UpdateRows ()
		end)
	end)

	self:Refresh ()

	Dex:Track (Dex.ThemeChanged:Connect (function ()
		if self.Window and self.Window.Visible then self:Refresh () end
	end))
	Dex:Track (game.DescendantAdded:Connect (function (instance)
		if isOwnGui (instance) then return end
		self:InvalidateChildrenCache ()
		self:MarkDirty ()
	end))
	Dex:Track (game.DescendantRemoving:Connect (function (instance)
		if isOwnGui (instance) then return end
		self:InvalidateChildrenCache ()
		self:MarkDirty ()
	end))

	local accumulator = 0
	Dex:Track (RunService.Heartbeat:Connect (function (deltaTime)
		accumulator = accumulator + (deltaTime or 0)
		if accumulator < (Dex.PerformanceMode and 3 or 1) then return end
		accumulator = 0
		if not self.Window or not self.Window.Visible or not self.Tree or not self.Tree.Parent then return end
		self:MarkDirty ()
	end))
	Dex:Track (UIS.InputBegan:Connect (function (input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape and self.PickingMode then
				self.PickingMode = nil
				Dex:Notify ("Selection cancelled", "info")
				return
			end
			self:HandleKey (input)
		else
			self:HandlePickClick (input)
		end
	end))
end

function Explorer:Create ()
	local window = Dex:CreateWindow ({
		Name = "Explorer",
		Title = "Explorer",
		Size = UDim2.fromOffset (300, 540),
		Position = UDim2.fromOffset (40, 60),
		MinSize = Vector2.new (230, 180),
		ContentColor = Dex.Theme.Explorer.Background,
		TitleBarColor3 = Dex.Theme.Explorer.TitleBar,
		BorderColor3 = Dex.Theme.Explorer.Border,
		TitleTextColor3 = Dex.Theme.Explorer.TitleText,
		AccentTransparency = 1,
		ContentBuilder = function (content, window)
			self.Window = window
			self:Build (content)
		end,
	})
	self.Window = window
	return window
end
