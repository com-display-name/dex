local getgenv = getgenv or function ()
	return _G
end
local genv = getgenv ()

do
	local previous = rawget (genv, "Dex")
	if type (previous) == "table" and type (previous.Destroy) == "function" then pcall (previous.Destroy) end
end

local Dex = {
	Version = "1.0.0",
	LayoutVersion = 2,
	Name = "Dex — Studio Edition",
	Connections = {},
	Windows = {},
	Utils = {},
	Clipboard = nil,
	SearchHistory = {},
	CommandHistory = {},
	LauncherPosition = nil,
}
Dex.genv = genv
if type (cloneref) == "function" then
	local ok, cloned = pcall (cloneref, game)
	Dex.game = ok and cloned or game
else
	Dex.game = game
end
genv.Dex = Dex

local function getService (name)
	local ok, service = pcall (function ()
		return game:GetService (name)
	end)
	if ok and service then
		if type (cloneref) == "function" then
			local ok2, cloned = pcall (cloneref, service)
			if ok2 and cloned then service = cloned end
		end
		return service
	end
	return nil
end

local Players = getService ("Players")
local RunService = getService ("RunService")
local UserInputService = getService ("UserInputService")
local TweenService = getService ("TweenService")
local TextService = getService ("TextService")
local CollectionService = getService ("CollectionService")
local LogService = getService ("LogService")
local HttpService = getService ("HttpService")
local GuiService = getService ("GuiService")
local ContextActionService = getService ("ContextActionService")

Dex.Services = {
	Players = Players,
	RunService = RunService,
	UserInputService = UserInputService,
	TweenService = TweenService,
	TextService = TextService,
	CollectionService = CollectionService,
	LogService = LogService,
	HttpService = HttpService,
	GuiService = GuiService,
	ContextActionService = ContextActionService,
}

local isStudio = false
pcall (function ()
	if RunService and RunService.IsStudio then isStudio = RunService:IsStudio () end
end)

local threadIdentity = 0
pcall (function ()
	if type (getthreadidentity) == "function" then
		threadIdentity = getthreadidentity ()
	elseif type (getthreadcontext) == "function" then
		threadIdentity = getthreadcontext ()
	end
end)

Dex.IsStudio = isStudio
Dex.ThreadIdentity = threadIdentity
Dex.HasCoreAccess = (not isStudio) and (threadIdentity >= 8)

local player = Players and Players.LocalPlayer or nil

local function hex (value)
	value = tostring (value):gsub ("#", "")
	local number = tonumber (value, 16) or 0
	return Color3.fromRGB (math.floor (number / 65536) % 256, math.floor (number / 256) % 256, number % 256)
end

Dex.hex = hex

Dex.Theme = {
	Common = {
		Accent = hex ("4a6cff"),
		AccentSoft = hex ("80d7ff"),
		Blue = hex ("4a6cff"),
		BlueSoft = hex ("4363e6"),
		White = hex ("ffffff"),
		Black = hex ("000000"),
		Text = hex ("e6e6e6"),
		TextMuted = hex ("aaaaaa"),
		TextDim = hex ("7d7d82"),
		TextDisabled = hex ("68686f"),
		Danger = hex ("ff5c5c"),
		Warning = hex ("ffb454"),
		WarningSoft = hex ("ffb454"),
		Info = hex ("80d7ff"),
		Success = hex ("7be08a"),
	},
	Explorer = {
		Background = hex ("2e2e2e"),
		TitleBar = hex ("353535"),
		TitleText = hex ("b9b9b9"),
		Border = hex ("1c1c1c"),
		SearchBackground = hex ("3f3f41"),
		SearchBorder = hex ("4c4c50"),
		SearchBorderFocused = hex ("4a6cff"),
		SearchText = hex ("e3e3e3"),
		Placeholder = hex ("9b9b9f"),
		Hover = hex ("3b3b3b"),
		Selection = hex ("313b5e"),
		SelectionText = hex ("f0f0f0"),
		TreeText = hex ("e6e6e6"),
		Text = hex ("e6e6e6"),
		TextMuted = hex ("aaaaaa"),
		TextDisabled = hex ("68686f"),
		Guide = hex ("463f50"),
		GuideActive = hex ("4a6cff"),
		ScrollBar = hex ("5b5b5e"),
		Empty = hex ("8b8b90"),
	},
	Properties = {
		Background = hex ("2e2e2e"),
		TitleBar = hex ("353535"),
		TitleText = hex ("b9b9b9"),
		Border = hex ("1c1c1c"),
		SearchBackground = hex ("3f3f41"),
		SearchBorder = hex ("4c4c50"),
		SearchBorderFocused = hex ("4a6cff"),
		SearchText = hex ("e3e3e3"),
		Placeholder = hex ("9b9b9f"),
		CategoryBackground = hex ("353535"),
		CategoryText = hex ("e6e6e6"),
		Row = hex ("2e2e2e"),
		RowAlt = hex ("333333"),
		RowHover = hex ("3b3b3b"),
		RowSelected = hex ("313b5e"),
		Separator = hex ("3f3f3f"),
		Name = hex ("b9b9b9"),
		Value = hex ("e6e6e6"),
		ValueMuted = hex ("aaaaaa"),
		InputBackground = hex ("2e2e2e"),
		InputBorder = hex ("4a6cff"),
		ScrollBar = hex ("5b5b5e"),
		Empty = hex ("8b8b90"),
	},
	Output = {
		Background = hex ("2e2e2e"),
		TitleBar = hex ("2e2e2e"),
		TitleText = hex ("b3b3b3"),
		Border = hex ("1b1b1b"),
		Toolbar = hex ("3b3b3b"),
		ToolbarBorder = hex ("1f1f1f"),
		Control = hex ("3b3b3b"),
		ControlBorder = hex ("4a4a4a"),
		ControlHover = hex ("474747"),
		FilterBackground = hex ("252525"),
		FilterBorder = hex ("1a1a1a"),
		Text = hex ("cccccc"),
		Timestamp = hex ("aaaaaa"),
		Context = hex ("aaaaaa"),
		Error = hex ("ff4444"),
		Warning = hex ("ffb454"),
		Info = hex ("80d7ff"),
		Success = hex ("00cc67"),
		Selection = hex ("3d3d3d"),
		CommandBackground = hex ("252525"),
		CommandText = hex ("e1e1e1"),
		ScrollBar = hex ("565656"),
	},
	Menu = {
		Background = hex ("2b2b2b"),
		Border = hex ("4a4a4a"),
		Hover = hex ("3b3b3b"),
		Text = hex ("e6e6e6"),
		TextMuted = hex ("aaaaaa"),
		TextDisabled = hex ("68686f"),
		Separator = hex ("3f3f3f"),
		Shortcut = hex ("989898"),
		Check = hex ("4a6cff"),
		Shadow = hex ("121212"),
	},
}

local function deepCopyTable (value)
	if type (value) ~= "table" then return value end
	local result = {}
	for key, child in pairs (value) do
		result[key] = deepCopyTable (child)
	end
	return result
end

Dex.DefaultTheme = deepCopyTable (Dex.Theme)

local function preset (overrides)
	local theme = deepCopyTable (Dex.DefaultTheme)
	for group, values in pairs (overrides) do
		theme[group] = theme[group] or {}
		for key, color in pairs (values) do
			theme[group][key] = color
		end
	end
	return theme
end

local function themed (o)
	local d = Dex.DefaultTheme
	local accent = o.accent or d.Common.Accent
	local accentSoft = o.accentSoft or accent
	local bg = o.bg or d.Explorer.Background
	local surface = o.surface or d.Explorer.TitleBar
	local elevated = o.elevated or surface
	local border = o.border or d.Explorer.Border
	local text = o.text or d.Common.Text
	local muted = o.muted or d.Common.TextMuted
	local dim = o.dim or d.Common.TextDim
	local selection = o.selection or d.Explorer.Selection
	local selectionText = o.selectionText or text
	local input = o.input or d.Properties.InputBackground
	local inputBorder = o.inputBorder or accent
	local hover = o.hover or elevated
	local scroll = o.scroll or dim
	local error = o.error or d.Output.Error
	local warning = o.warning or d.Output.Warning
	local info = o.info or d.Output.Info
	local success = o.success or d.Output.Success

	return preset ({
		Common = {
			Accent = accent,
			AccentSoft = accentSoft,
			Blue = accent,
			BlueSoft = accentSoft,
			Text = text,
			TextMuted = muted,
			TextDim = dim,
			Danger = error,
			Warning = warning,
			Info = info,
			Success = success,
		},
		Explorer = {
			Background = bg,
			TitleBar = surface,
			TitleText = text,
			Border = border,
			SearchBackground = input,
			SearchBorder = border,
			SearchBorderFocused = accent,
			SearchText = text,
			Placeholder = dim,
			Hover = hover,
			Selection = selection,
			SelectionText = selectionText,
			TreeText = text,
			Guide = border,
			GuideActive = accent,
			ScrollBar = scroll,
			Empty = dim,
		},
		Properties = {
			Background = bg,
			TitleBar = surface,
			TitleText = text,
			Border = border,
			CategoryBackground = surface,
			CategoryText = text,
			Row = bg,
			RowAlt = elevated,
			RowHover = hover,
			RowSelected = selection,
			Separator = border,
			Name = text,
			Value = text,
			ValueMuted = muted,
			InputBackground = input,
			InputBorder = inputBorder,
			Placeholder = dim,
			SearchText = text,
			Empty = dim,
		},
		Output = {
			Background = bg,
			TitleBar = surface,
			TitleText = text,
			Border = border,
			Toolbar = surface,
			ToolbarBorder = border,
			Control = surface,
			ControlBorder = border,
			ControlHover = hover,
			FilterBackground = input,
			FilterBorder = border,
			Text = text,
			Timestamp = muted,
			Context = muted,
			Error = error,
			Warning = warning,
			Info = info,
			Success = success,
			Selection = selection,
			CommandBackground = input,
			CommandText = text,
			ScrollBar = scroll,
		},
		Menu = {
			Background = surface,
			Border = border,
			Hover = hover,
			Text = text,
			TextMuted = muted,
			TextDisabled = dim,
			Separator = border,
			Shortcut = muted,
			Check = accent,
			Shadow = bg,
		},
	})
end

Dex.ThemePresets = {
	["Studio Dark"] = function ()
		return deepCopyTable (Dex.DefaultTheme)
	end,
	["Ocean Blue"] = function ()
		return preset ({
			Common = { Accent = hex ("4ad9ff"), AccentSoft = hex ("8ae9ff"), Info = hex ("80d7ff") },
			Explorer = {
				Background = hex ("1d2733"),
				TitleBar = hex ("243140"),
				Selection = hex ("263a52"),
				GuideActive = hex ("4ad9ff"),
				SearchBackground = hex ("2a3848"),
				SearchBorder = hex ("3b5268"),
				SearchBorderFocused = hex ("4ad9ff"),
				SearchText = hex ("e6f6ff"),
			},
			Properties = {
				Background = hex ("1d2733"),
				TitleBar = hex ("243140"),
				CategoryBackground = hex ("243140"),
				Row = hex ("1d2733"),
				RowAlt = hex ("202b38"),
				InputBorder = hex ("4ad9ff"),
			},
			Output = {
				Background = hex ("1d2733"),
				TitleBar = hex ("243140"),
				Toolbar = hex ("243140"),
				ToolbarBorder = hex ("101923"),
				CommandBackground = hex ("151d26"),
				FilterBackground = hex ("1a2530"),
				FilterBorder = hex ("2d4356"),
				Control = hex ("243140"),
				ControlBorder = hex ("3b5268"),
				ControlHover = hex ("31465c"),
			},
			Menu = {
				Background = hex ("1d2733"),
				Border = hex ("4ad9ff"),
				Hover = hex ("2b3b4d"),
				Check = hex ("4ad9ff"),
			},
		})
	end,
	["Studio Light"] = function ()
		return preset ({
			Common = {
				Text = hex ("222222"),
				TextMuted = hex ("666666"),
				TextDim = hex ("888888"),
				Accent = hex ("0078d4"),
				AccentSoft = hex ("4aa3df"),
			},
			Explorer = {
				Background = hex ("f5f5f5"),
				TitleBar = hex ("e6e6e6"),
				TitleText = hex ("333333"),
				Border = hex ("cccccc"),
				SearchBackground = hex ("ffffff"),
				SearchBorder = hex ("cccccc"),
				SearchBorderFocused = hex ("0078d4"),
				SearchText = hex ("222222"),
				Placeholder = hex ("888888"),
				Hover = hex ("e8e8e8"),
				Selection = hex ("cce4ff"),
				SelectionText = hex ("111111"),
				TreeText = hex ("222222"),
				Guide = hex ("bbbbbb"),
				GuideActive = hex ("0078d4"),
				ScrollBar = hex ("aaaaaa"),
				Empty = hex ("888888"),
			},
			Properties = {
				Background = hex ("f5f5f5"),
				TitleBar = hex ("e6e6e6"),
				TitleText = hex ("333333"),
				Border = hex ("cccccc"),
				CategoryBackground = hex ("e8e8e8"),
				CategoryText = hex ("222222"),
				Row = hex ("ffffff"),
				RowAlt = hex ("f9f9f9"),
				RowHover = hex ("eef4fb"),
				RowSelected = hex ("cce4ff"),
				Separator = hex ("dddddd"),
				Name = hex ("444444"),
				Value = hex ("111111"),
				ValueMuted = hex ("888888"),
				InputBackground = hex ("ffffff"),
				InputBorder = hex ("0078d4"),
				Placeholder = hex ("888888"),
				SearchText = hex ("222222"),
				Empty = hex ("888888"),
			},
			Output = {
				Background = hex ("ffffff"),
				TitleBar = hex ("e6e6e6"),
				TitleText = hex ("333333"),
				Border = hex ("cccccc"),
				Toolbar = hex ("eeeeee"),
				ToolbarBorder = hex ("cccccc"),
				Control = hex ("ffffff"),
				ControlBorder = hex ("cccccc"),
				ControlHover = hex ("e4e4e4"),
				FilterBackground = hex ("ffffff"),
				FilterBorder = hex ("cccccc"),
				Text = hex ("222222"),
				Timestamp = hex ("888888"),
				Context = hex ("888888"),
				Error = hex ("d32f2f"),
				Warning = hex ("b26a00"),
				Info = hex ("0066cc"),
				Success = hex ("107c10"),
				Selection = hex ("dce6f5"),
				CommandBackground = hex ("ffffff"),
				CommandText = hex ("222222"),
				ScrollBar = hex ("aaaaaa"),
			},
			Menu = {
				Background = hex ("ffffff"),
				Border = hex ("cccccc"),
				Hover = hex ("eef4fb"),
				Text = hex ("222222"),
				TextMuted = hex ("666666"),
				TextDisabled = hex ("aaaaaa"),
				Separator = hex ("dddddd"),
				Shortcut = hex ("888888"),
				Check = hex ("0078d4"),
				Shadow = hex ("888888"),
			},
		})
	end,
	["Studio OLED"] = function ()
		return preset ({
			Common = {
				Text = hex ("f0f0f0"),
				TextMuted = hex ("a0a0a0"),
				TextDim = hex ("707070"),
				Accent = hex ("00bfff"),
				AccentSoft = hex ("38bdf8"),
				Info = hex ("38bdf8"),
			},
			Explorer = {
				Background = hex ("000000"),
				TitleBar = hex ("0a0a0a"),
				TitleText = hex ("f0f0f0"),
				Border = hex ("222222"),
				SearchBackground = hex ("0a0a0a"),
				SearchBorder = hex ("333333"),
				SearchBorderFocused = hex ("00bfff"),
				SearchText = hex ("f0f0f0"),
				Placeholder = hex ("707070"),
				Hover = hex ("141414"),
				Selection = hex ("1e293b"),
				SelectionText = hex ("ffffff"),
				TreeText = hex ("f0f0f0"),
				Guide = hex ("1f1f1f"),
				GuideActive = hex ("00bfff"),
				ScrollBar = hex ("444444"),
				Empty = hex ("707070"),
			},
			Properties = {
				Background = hex ("000000"),
				TitleBar = hex ("0a0a0a"),
				TitleText = hex ("f0f0f0"),
				Border = hex ("222222"),
				CategoryBackground = hex ("0a0a0a"),
				CategoryText = hex ("f0f0f0"),
				Row = hex ("000000"),
				RowAlt = hex ("050505"),
				RowHover = hex ("141414"),
				RowSelected = hex ("1e293b"),
				Separator = hex ("1f1f1f"),
				Name = hex ("cccccc"),
				Value = hex ("ffffff"),
				ValueMuted = hex ("707070"),
				InputBackground = hex ("0a0a0a"),
				InputBorder = hex ("00bfff"),
				Placeholder = hex ("707070"),
				SearchText = hex ("f0f0f0"),
				Empty = hex ("707070"),
			},
			Output = {
				Background = hex ("000000"),
				TitleBar = hex ("0a0a0a"),
				TitleText = hex ("f0f0f0"),
				Border = hex ("222222"),
				Toolbar = hex ("0a0a0a"),
				ToolbarBorder = hex ("222222"),
				Control = hex ("0a0a0a"),
				ControlBorder = hex ("333333"),
				ControlHover = hex ("141414"),
				FilterBackground = hex ("0a0a0a"),
				FilterBorder = hex ("333333"),
				Text = hex ("f0f0f0"),
				Timestamp = hex ("707070"),
				Context = hex ("707070"),
				Error = hex ("ef4444"),
				Warning = hex ("f59e0b"),
				Info = hex ("38bdf8"),
				Success = hex ("22c55e"),
				Selection = hex ("1e293b"),
				CommandBackground = hex ("0a0a0a"),
				CommandText = hex ("f0f0f0"),
				ScrollBar = hex ("444444"),
			},
			Menu = {
				Background = hex ("0a0a0a"),
				Border = hex ("333333"),
				Hover = hex ("141414"),
				Text = hex ("f0f0f0"),
				TextMuted = hex ("a0a0a0"),
				TextDisabled = hex ("555555"),
				Separator = hex ("222222"),
				Shortcut = hex ("707070"),
				Check = hex ("00bfff"),
				Shadow = hex ("000000"),
			},
		})
	end,
	["GitHub Dark"] = function ()
		return themed ({
			accent = hex ("58a6ff"),
			accentSoft = hex ("a5a6ff"),
			bg = hex ("0d1117"),
			surface = hex ("161b22"),
			elevated = hex ("21262d"),
			border = hex ("30363d"),
			text = hex ("c9d1d9"),
			muted = hex ("8b949e"),
			dim = hex ("6e7681"),
			selection = hex ("1f6feb"),
			selectionText = hex ("ffffff"),
			input = hex ("0d1117"),
			hover = hex ("21262d"),
			scroll = hex ("30363d"),
			error = hex ("f85149"),
			warning = hex ("d29922"),
			info = hex ("58a6ff"),
			success = hex ("3fb950"),
		})
	end,
	["GitHub Light"] = function ()
		return themed ({
			accent = hex ("0969da"),
			accentSoft = hex ("8250df"),
			bg = hex ("ffffff"),
			surface = hex ("f6f8fa"),
			elevated = hex ("eaeef2"),
			border = hex ("d0d7de"),
			text = hex ("1f2328"),
			muted = hex ("656d76"),
			dim = hex ("8c959f"),
			selection = hex ("ddf4ff"),
			selectionText = hex ("1f2328"),
			input = hex ("ffffff"),
			inputBorder = hex ("0969da"),
			hover = hex ("eaeef2"),
			scroll = hex ("b6bec8"),
			error = hex ("cf222e"),
			warning = hex ("9a6700"),
			info = hex ("0969da"),
			success = hex ("1a7f37"),
		})
	end,
}

Dex.CurrentTheme = "Studio Dark"
Dex.PerformanceMode = false

local function colorKey (color)
	if typeof (color) ~= "Color3" then return nil end
	return string.format (
		"%d,%d,%d",
		math.floor (color.R * 255 + 0.5),
		math.floor (color.G * 255 + 0.5),
		math.floor (color.B * 255 + 0.5)
	)
end

Dex.Config = {
	Path = "Dex/config.json",
	Data = { Theme = "Studio Dark" },
}

function Dex:LoadConfig ()
	if type (isfile) ~= "function" or type (readfile) ~= "function" then return end
	local ok, content = pcall (readfile, self.Config.Path)
	if not ok or type (content) ~= "string" then return end
	local decoded = nil
	pcall (function ()
		decoded = HttpService and HttpService:JSONDecode (content)
	end)
	if type (decoded) == "table" then
		for key, value in pairs (decoded) do
			self.Config.Data[key] = value
		end
	end
end

function Dex:SaveConfig ()
	if type (writefile) ~= "function" then return false end
	pcall (function ()
		if type (makefolder) == "function" then makefolder ("Dex") end
	end)
	local ok, encoded = pcall (function ()
		return HttpService:JSONEncode (self.Config.Data)
	end)
	if not ok then return false end
	local written = pcall (writefile, self.Config.Path, encoded)
	return written
end

function Dex:SetConfig (key, value)
	self.Config.Data[key] = value
	return self:SaveConfig ()
end

function Dex:SaveWindowConfigs ()
	local windows = {}
	for name, window in pairs (self.Windows) do
		if window and window.GUI and not window.Destroyed then
			windows[name] = {
				Position = { window.GUI.Position.X.Offset, window.GUI.Position.Y.Offset },
				Size = { window.GUI.Size.X.Offset, window.GUI.Size.Y.Offset },
			}
		end
	end
	self.Config.Data.Windows = windows
	return self:SaveConfig ()
end

function Dex:ScheduleWindowConfigSave ()
	if self._ApplyingSavedLayout or self._WindowSaveScheduled then return end
	self._WindowSaveScheduled = true
	task.delay (0.5, function ()
		self._WindowSaveScheduled = false
		if self._ApplyingSavedLayout then return end
		pcall (function ()
			self:SaveWindowConfigs ()
		end)
	end)
end

function Dex:GetRightDockWidth ()
	local viewport = Dex.Utils.Viewport ()
	return math.clamp (math.floor (viewport.X * 0.28), 280, 380)
end

function Dex:RestoreWindowConfigs ()
	local saved = self.Config.Data.Windows
	if type (saved) ~= "table" then return end
	for name, data in pairs (saved) do
		local window = self.Windows[name]
		if window and window.GUI and not window.Destroyed and type (data) == "table" then
			local position = data.Position
			local size = data.Size
			if type (position) == "table" and position[1] and position[2] then
				window.GUI.Position = UDim2.fromOffset (position[1], position[2])
			end
			if type (size) == "table" and size[1] and size[2] then
				window.GUI.Size = UDim2.fromOffset (size[1], size[2])
			end
			if window.SyncShadow then window:SyncShadow () end
			if window.UpdateEdgeCorners then window:UpdateEdgeCorners () end
		end
	end
	self:AlignBottomDock ()
end

function Dex:AlignBottomDock ()
	local viewport = Dex.Utils.Viewport ()
	local output = self.Windows.Output
	if not output or not output.SnapBottom or not output.GUI or output.Destroyed then return end

	local rightEdge = math.max (0, viewport.X - self:GetRightDockWidth ())
	local properties = self.Windows.Properties
	if properties and properties.GUI and not properties.Destroyed then
		local x = properties.GUI.Position.X.Offset
		local width = properties.GUI.Size.X.Offset
		if x > 0 and x + width >= viewport.X - 1 then rightEdge = x end
	end

	local x = output.GUI.Position.X.Offset
	local y = output.GUI.Position.Y.Offset
	local width = output.GUI.Size.X.Offset
	local height = output.GUI.Size.Y.Offset
	local docked = x <= 1 and math.abs ((y + height) - viewport.Y) <= 1 and math.abs ((x + width) - rightEdge) <= 1
	if not docked then
		if output.UpdateEdgeCorners then output:UpdateEdgeCorners () end
		return
	end

	output.GUI.Position = UDim2.fromOffset (0, math.max (0, viewport.Y - height))
	output.GUI.Size = UDim2.fromOffset (rightEdge, height)
	if output.SyncShadow then output:SyncShadow () end
	if output.UpdateEdgeCorners then output:UpdateEdgeCorners () end
end

function Dex:GetSnappedLayout ()
	if self._SnappingDisabled then return nil end
	local explorer = self.Windows.Explorer
	local properties = self.Windows.Properties
	local output = self.Windows.Output
	if not explorer or not properties or not output then return nil end
	if explorer.Destroyed or properties.Destroyed or output.Destroyed then return nil end
	if not explorer.GUI or not properties.GUI or not output.GUI then return nil end

	local viewport = Dex.Utils.Viewport ()
	local epsilon = 2
	local function rightDocked (window)
		local x = window.GUI.Position.X.Offset
		local width = window.GUI.Size.X.Offset
		return math.abs ((x + width) - viewport.X) <= epsilon
	end

	if not rightDocked (explorer) or not rightDocked (properties) then return nil end
	if math.abs (explorer.GUI.Position.X.Offset - properties.GUI.Position.X.Offset) > epsilon then return nil end
	local ey = explorer.GUI.Position.Y.Offset
	local eh = explorer.GUI.Size.Y.Offset
	local py = properties.GUI.Position.Y.Offset
	if py < ey - epsilon or py > ey + eh + epsilon then return nil end

	local dockX = explorer.GUI.Position.X.Offset
	local ox = output.GUI.Position.X.Offset
	local oy = output.GUI.Position.Y.Offset
	local ow = output.GUI.Size.X.Offset
	local oh = output.GUI.Size.Y.Offset
	local outputDocked = output.SnapBottom == true
		and ox <= epsilon
		and math.abs ((oy + oh) - viewport.Y) <= epsilon
		and math.abs ((ox + ow) - dockX) <= epsilon

	return {
		Viewport = viewport,
		Explorer = explorer,
		Properties = properties,
		Output = output,
		OutputDocked = outputDocked,
	}
end

function Dex:SyncSnappedWindows (source, snap)
	snap = snap or self:GetSnappedLayout ()
	if not snap then return end
	local viewport = snap.Viewport
	local explorer, properties, output = snap.Explorer, snap.Properties, snap.Output

	if source == explorer then
		local x = explorer.GUI.Position.X.Offset
		local y = explorer.GUI.Position.Y.Offset
		local width = explorer.GUI.Size.X.Offset
		local height = explorer.GUI.Size.Y.Offset
		local propertiesY = math.max (0, y + height)
		properties.GUI.Position = UDim2.fromOffset (x, propertiesY)
		properties.GUI.Size = UDim2.fromOffset (width, math.max (0, viewport.Y - propertiesY))
		if snap.OutputDocked then
			output.GUI.Size = UDim2.fromOffset (math.max (0, x), output.GUI.Size.Y.Offset)
		end
	elseif source == properties then
		local x = properties.GUI.Position.X.Offset
		local width = properties.GUI.Size.X.Offset
		local explorerY = explorer.GUI.Position.Y.Offset
		local explorerHeight = math.max (1, math.min (properties.GUI.Position.Y.Offset, viewport.Y) - explorerY)
		explorer.GUI.Position = UDim2.fromOffset (x, explorerY)
		explorer.GUI.Size = UDim2.fromOffset (width, explorerHeight)
		properties.GUI.Position = UDim2.fromOffset (x, explorerY + explorerHeight)
		if snap.OutputDocked then
			output.GUI.Size = UDim2.fromOffset (math.max (0, x), output.GUI.Size.Y.Offset)
		end
	elseif source == output then
		local dockX = math.max (
			0,
			math.min (viewport.X, output.GUI.Position.X.Offset + output.GUI.Size.X.Offset)
		)
		explorer.GUI.Position = UDim2.fromOffset (dockX, explorer.GUI.Position.Y.Offset)
		explorer.GUI.Size = UDim2.fromOffset (viewport.X - dockX, explorer.GUI.Size.Y.Offset)
		properties.GUI.Position = UDim2.fromOffset (dockX, properties.GUI.Position.Y.Offset)
		properties.GUI.Size = UDim2.fromOffset (viewport.X - dockX, properties.GUI.Size.Y.Offset)
	else
		return
	end

	for _, window in ipairs ({ explorer, properties, output }) do
		if window.SyncShadow then window:SyncShadow () end
		if window.UpdateEdgeCorners then window:UpdateEdgeCorners () end
	end
end

function Dex:ApplyTheme (name)
	local factory = self.ThemePresets[name]
	if not factory then return false end
	local newTheme = factory ()
	local map = {}
	for group, entries in pairs (self.Theme) do
		for key, color in pairs (entries) do
			local newColor = newTheme[group] and newTheme[group][key]
			if newColor and newColor ~= color then map[colorKey (color)] = newColor end
		end
	end

	for group, entries in pairs (newTheme) do
		self.Theme[group] = entries
	end
	self.CurrentTheme = name
	self:SetConfig ("Theme", name)

	if self.ScreenGui then
		local props = { "BackgroundColor3", "TextColor3", "ImageColor3", "ScrollBarImageColor3", "FillColor3" }
		local launcherGui = self.Launcher and self.Launcher.GUI
		local objects = self.ScreenGui:GetDescendants ()
		for _, object in ipairs (objects) do
			local skip = false
			if launcherGui then pcall (function ()
				skip = object:IsDescendantOf (launcherGui)
			end) end
			if not skip then
				for _, prop in ipairs (props) do
					local ok, value = pcall (function ()
						return object[prop]
					end)
					if ok and typeof (value) == "Color3" then
						local replacement = map[colorKey (value)]
						if replacement then pcall (function ()
							object[prop] = replacement
						end) end
					end
				end
				if object:IsA ("UIStroke") then
					local replacement = map[colorKey (object.Color)]
					if replacement then pcall (function ()
						object.Color = replacement
					end) end
				elseif object:IsA ("UIGradient") then
					pcall (function ()
						local keypoints = {}
						for _, keypoint in ipairs (object.Color.Keypoints) do
							local replacement = map[colorKey (keypoint.Color)] or keypoint.Color
							keypoints[#keypoints + 1] = ColorSequenceKeypoint.new (keypoint.Time, replacement)
						end
						object.Color = ColorSequence.new (keypoints)
					end)
				end
			end
		end
	end

	if self.ScreenGui then
		for _, object in ipairs (self.ScreenGui:GetDescendants ()) do
			if object:IsA ("TextLabel") and object.Name == "Check" then
				pcall (function ()
					object.TextColor3 = self.Theme.Menu.Check
				end)
			end
		end
	end

	self.ThemeChanged:Fire (name)
	return true
end

local function fontEnum (name, fallback)
	local ok, value = pcall (function ()
		return Enum.Font[name]
	end)
	return ok and value or fallback
end

Dex.Fonts = {
	UI = fontEnum ("BuilderSans", Enum.Font.SourceSans),
	UIMedium = fontEnum ("BuilderSansMedium", fontEnum ("BuilderSans", Enum.Font.SourceSans)),
	UIBold = fontEnum ("BuilderSansBold", Enum.Font.SourceSansBold),
	Mono = fontEnum ("RobotoMono", Enum.Font.Code),
}
local isMac = false
if Dex.HasCoreAccess and UserInputService and UserInputService.GetPlatform then
	pcall (function ()
		isMac = UserInputService:GetPlatform () == Enum.Platform.OSX
	end)
end

Dex.Shortcut = {
	Ctrl = isMac and "⌘" or "Ctrl+",
	Shift = isMac and "⇧" or "Shift+",
}

function Dex.newSignal ()
	local handlers = {}
	local signal = {}

	function signal:Connect (callback)
		local entry = { Callback = callback, Connected = true }
		handlers[#handlers + 1] = entry
		return {
			Disconnect = function ()
				if not entry.Connected then return end
				entry.Connected = false
				for i = #handlers, 1, -1 do
					if handlers[i] == entry then table.remove (handlers, i) end
				end
			end,
		}
	end

	function signal:Fire (...)
		local snapshot = {}
		for _, entry in ipairs (handlers) do
			if entry.Connected then snapshot[#snapshot + 1] = entry.Callback end
		end
		for i = 1, #snapshot do
			task.spawn (snapshot[i], ...)
		end
	end

	return signal
end

Dex.ThemeChanged = Dex.newSignal ()
Dex.SelectionChanged = Dex.newSignal ()
Dex.ViewportChanged = Dex.newSignal ()
Dex.Selection = {
	List = {},
	Map = {},
	Primary = nil,
}

function Dex:Track (connection)
	if connection then self.Connections[#self.Connections + 1] = connection end
	return connection
end

function Dex:Untrack (connection)
	for index, tracked in ipairs (self.Connections) do
		if tracked == connection then
			table.remove (self.Connections, index)
			return connection
		end
	end
	return connection
end

function Dex:SetSelection (list, primary)
	local clean = {}
	local map = {}

	for _, object in ipairs (list or {}) do
		if typeof (object) == "Instance" and not map[object] then
			map[object] = true
			clean[#clean + 1] = object
		end
	end

	if primary and not map[primary] then
		clean[#clean + 1] = primary
		map[primary] = true
	end

	self.Selection.List = clean
	self.Selection.Map = map
	self.Selection.Primary = primary or clean[#clean] or nil
	self.SelectionChanged:Fire (self.Selection)
	return self.Selection
end

function Dex:ClearSelection ()
	return self:SetSelection ({}, nil)
end

local U = Dex.Utils

local DefaultProperties = {
	["Frame"] = {
		BackgroundColor3 = Dex.Theme.Common.Black,
		BorderSizePixel = 0,
	},
	["TextLabel"] = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Dex.Fonts.UI,
		TextColor3 = Dex.Theme.Common.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	},
	["TextButton"] = {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Dex.Fonts.UI,
		TextColor3 = Dex.Theme.Common.Text,
		TextSize = 14,
		Text = "",
	},
	["TextBox"] = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Dex.Fonts.UI,
		TextColor3 = Dex.Theme.Common.Text,
		PlaceholderColor3 = Dex.Theme.Common.TextDim,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	},
	["ScrollingFrame"] = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Dex.Theme.Common.TextDim,
		ScrollBarImageTransparency = 0.15,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.new (0, 0, 0, 0),
	},
}

function U.Create (className, properties, parent)
	local instance = Instance.new (className)
	local original = properties or {}
	properties = {}
	for key, value in pairs (original) do properties[key] = value end

	for key, value in pairs (DefaultProperties[className] or {}) do
		if properties[key] == nil then properties[key] = value end
	end

	for key, value in pairs (properties) do
		if key ~= "Parent" then instance[key] = value end
	end

	if parent then
		instance.Parent = parent
	elseif properties.Parent then
		instance.Parent = properties.Parent
	end

	return instance
end

function U.Corner (gui, radius)
	local corner = U.Create ("UICorner", {
		CornerRadius = UDim.new (0, radius or 4),
		Parent = gui,
	})
	return corner
end

function U.Stroke (gui, color, thickness, transparency)
	local stroke = U.Create ("UIStroke", {
		Color = color or Dex.Theme.Common.Black,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = gui,
	})
	return stroke
end

function U.Padding (gui, left, top, right, bottom)
	local padding = U.Create ("UIPadding", {
		PaddingLeft = UDim.new (0, left or 0),
		PaddingTop = UDim.new (0, top or 0),
		PaddingRight = UDim.new (0, right or 0),
		PaddingBottom = UDim.new (0, bottom or 0),
		Parent = gui,
	})
	return padding
end

function U.List (gui, padding, horizontal)
	local layout = U.Create ("UIListLayout", {
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new (0, padding or 0),
		Parent = gui,
	})
	return layout
end

function U.Frame (parent, properties)
	return U.Create ("Frame", properties, parent)
end

function U.Label (parent, properties)
	return U.Create ("TextLabel", properties, parent)
end

function U.Button (parent, properties)
	return U.Create ("TextButton", properties, parent)
end

function U.Textbox (parent, properties)
	return U.Create ("TextBox", properties, parent)
end

function U.Scroll (parent, properties)
	return U.Create ("ScrollingFrame", properties, parent)
end

function U.TextWidth (text, size, font)
	local ok, result = pcall (function ()
		return TextService:GetTextSize (tostring (text), size, font or Dex.Fonts.UI, Vector2.new (100000, 100000)).X
	end)
	if ok then return result end
	return #tostring (text) * (size or 14) * 0.55
end

function U.Round (number, places)
	local power = 10 ^ (places or 3)
	local rounded = math.floor (number * power + 0.5) / power
	if rounded == math.floor (rounded) then return tostring (math.floor (rounded)) end
	local text = string.format ("%." .. tostring (places or 3) .. "f", rounded)
	return (text:gsub ("0+$", ""):gsub ("%.$", ""))
end

function U.Pretty (value)
	local valueType = typeof (value)
	if valueType == "string" then
		return value
	elseif valueType == "number" then
		return U.Round (value, 4)
	elseif valueType == "boolean" then
		return value and "true" or "false"
	elseif valueType == "nil" then
		return "nil"
	elseif valueType == "Instance" then
		return tostring (value)
	elseif valueType == "EnumItem" then
		return tostring (value):gsub ("^Enum%.", ""):gsub ("^" .. tostring (value.EnumType) .. "%.", "")
	elseif valueType == "Color3" then
		return string.format (
			"[%d, %d, %d]",
			math.floor (value.R * 255 + 0.5),
			math.floor (value.G * 255 + 0.5),
			math.floor (value.B * 255 + 0.5)
		)
	elseif valueType == "BrickColor" then
		return value.Name
	elseif valueType == "Vector2" then
		return U.Round (value.X, 4) .. ", " .. U.Round (value.Y, 4)
	elseif valueType == "Vector3" then
		return U.Round (value.X, 4) .. ", " .. U.Round (value.Y, 4) .. ", " .. U.Round (value.Z, 4)
	elseif valueType == "UDim" then
		return U.Round (value.Scale, 4) .. ", " .. U.Round (value.Offset, 0)
	elseif valueType == "UDim2" then
		return string.format (
			"{%s, %s}, {%s, %s}",
			U.Round (value.X.Scale, 4),
			U.Round (value.X.Offset, 0),
			U.Round (value.Y.Scale, 4),
			U.Round (value.Y.Offset, 0)
		)
	elseif valueType == "CFrame" then
		local x, y, z = value:GetComponents ()
		local rx, ry, rz = value:ToEulerAnglesXYZ ()
		return string.format (
			"%s, %s, %s, %s°, %s°, %s°",
			U.Round (x, 4),
			U.Round (y, 4),
			U.Round (z, 4),
			U.Round (math.deg (rx), 2),
			U.Round (math.deg (ry), 2),
			U.Round (math.deg (rz), 2)
		)
	elseif valueType == "Rect" then
		return string.format (
			"%s, %s, %s, %s",
			U.Round (value.Min.X, 4),
			U.Round (value.Min.Y, 4),
			U.Round (value.Max.X, 4),
			U.Round (value.Max.Y, 4)
		)
	elseif valueType == "NumberRange" then
		return U.Round (value.Min, 4) .. ", " .. U.Round (value.Max, 4)
	elseif valueType == "NumberSequence" then
		return tostring (#value.Keypoints) .. " keypoints"
	elseif valueType == "ColorSequence" then
		return tostring (#value.Keypoints) .. " keypoints"
	elseif valueType == "Ray" then
		return tostring (value.Origin) .. " → " .. tostring (value.Direction)
	elseif valueType == "PhysicalProperties" then
		return string.format (
			"%.3g density, %.3g friction, %.3g elasticity",
			value.Density,
			value.Friction,
			value.Elasticity
		)
	elseif valueType == "Font" then
		return value.Family
	elseif valueType == "Content" then
		local ok, text = pcall (function ()
			return value:GetUrl ()
		end)
		if ok and text then return text end
	end
	return tostring (value)
end

function U.EscapeRich (text)
	return tostring (text):gsub ("&", "&amp;"):gsub ("<", "&lt;"):gsub (">", "&gt;")
end

function U.ColorHex (color)
	return string.format (
		"%02x%02x%02x",
		math.floor (color.R * 255 + 0.5),
		math.floor (color.G * 255 + 0.5),
		math.floor (color.B * 255 + 0.5)
	)
end

function U.Viewport ()
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new (1280, 720)
	return size
end

function U.PointInGui (gui, point)
	local position = gui.AbsolutePosition
	local size = gui.AbsoluteSize
	return point.X >= position.X
		and point.Y >= position.Y
		and point.X <= position.X + size.X
		and point.Y <= position.Y + size.Y
end

function U.MousePoint ()
	if UserInputService then return UserInputService:GetMouseLocation () end
	return Vector2.new (0, 0)
end

function U.TopLevel (objects)
	local result = {}
	local set = {}

	for _, object in ipairs (objects or {}) do
		set[object] = true
	end

	for _, object in ipairs (objects or {}) do
		local parent = object.Parent
		local excluded = false
		while parent and parent ~= game do
			if set[parent] then
				excluded = true
				break
			end
			parent = parent.Parent
		end
		if not excluded then result[#result + 1] = object end
	end

	return result
end

function U.PathOf (object)
	if object == game then return "game" end

	local parts = {}
	local current = object

	while current and current ~= game do
		local parent = current.Parent
		if parent == game then
			local ok, service = pcall (function ()
				return game:GetService (current.ClassName)
			end)
			if ok and service == current then
				parts[#parts + 1] = string.format ("game:GetService(\"%s\")", current.ClassName)
			else
				parts[#parts + 1] = string.format ("game:FindFirstChild(\"%s\")", current.Name:gsub ("\"", "\\\""))
			end
		elseif current.Name:match ("^[%a_][%w_]*$") then
			parts[#parts + 1] = "." .. current.Name
		else
			parts[#parts + 1] = string.format ("[%q]", current.Name)
		end
		current = parent
	end

	local result = {}
	for index = #parts, 1, -1 do
		result[#result + 1] = parts[index]
	end

	return table.concat (result)
end

function U.SafeClone (object)
	local ok, clone = pcall (function ()
		return object:Clone ()
	end)
	return ok and clone or nil
end

function U.CloneInto (object, parent)
	local clone = U.SafeClone (object)
	if not clone then return nil end
	local ok = pcall (function ()
		clone.Parent = parent
	end)
	if not ok then
		clone:Destroy ()
		return nil
	end
	return clone
end

function U.ClearChildren (gui)
	for _, child in ipairs (gui:GetChildren ()) do
		if
			not child:IsA ("UIListLayout")
			and not child:IsA ("UIPadding")
			and not child:IsA ("UICorner")
			and not child:IsA ("UIStroke")
		then
			child:Destroy ()
		end
	end
end

function U.DrawX (parent, size, color, transparency)
	size = size or 10
	local holder = U.Frame (parent, {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (size, size),
		Position = UDim2.fromScale (0.5, 0.5),
		AnchorPoint = Vector2.new (0.5, 0.5),
		ZIndex = (parent.ZIndex or 1) + 1,
	})

	for _, rotation in ipairs ({ 45, -45 }) do
		U.Frame (holder, {
			BackgroundColor3 = color or Dex.Theme.Common.White,
			BackgroundTransparency = transparency or 0,
			AnchorPoint = Vector2.new (0.5, 0.5),
			Position = UDim2.fromScale (0.5, 0.5),
			Size = UDim2.new (1, 0, 0, 1),
			Rotation = rotation,
		})
	end

	return holder
end

function Dex:GetGuiParent ()
	local ok, parent = pcall (function ()
		if gethui then return gethui () end
	end)
	if ok and parent then return parent end

	local localPlayer = Players and Players.LocalPlayer or nil
	if localPlayer then
		local playerGui = localPlayer:FindFirstChildOfClass ("PlayerGui")
		if playerGui then return playerGui end
	end

	local coreGui = getService ("CoreGui")
	return coreGui or game
end

function Dex:CreateScreenGui ()
	local gui = U.Create ("ScreenGui", {
		Name = "DexStudio",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 2147483647,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	pcall (function ()
		gui.OnTopOfCoreBlur = true
	end)

	if type (syn) == "table" and type (syn.protect_gui) == "function" then
		pcall (syn.protect_gui, gui)
	elseif type (protect_gui) == "function" then
		pcall (protect_gui, gui)
	end

	local parent = self:GetGuiParent ()
	local ok = pcall (function ()
		gui.Parent = parent
	end)

	if not ok and player then pcall (function ()
		gui.Parent = player:WaitForChild ("PlayerGui", 5)
	end) end

	self.ScreenGui = gui
	return gui
end

function Dex:Destroy ()
	if self.Explorer and self.Explorer.StopView then pcall (function ()
		self.Explorer:StopView ()
	end) end
	if self.SelectionHighlight then
		pcall (function ()
			self.SelectionHighlight:Clear ()
		end)
		self.SelectionHighlight.Enabled = false
	end

	if self.Bypass and self.Bypass.Enabled then pcall (function ()
		self.Bypass:Disable ()
	end) end
	if self.ConsoleBypass and self.ConsoleBypass.Enabled then
		pcall (function ()
			self.ConsoleBypass:Disable ()
		end)
	end
	if self.Output and self.Output.UninstallLogHistoryHooks then
		pcall (function ()
			self.Output:UninstallLogHistoryHooks ()
		end)
	end
	if self.Explorer and self.Explorer.DisconnectRowConnections then
		pcall (function ()
			self.Explorer:DisconnectRowConnections ()
		end)
	end

	for _, connection in ipairs (self.Connections) do
		pcall (function ()
			connection:Disconnect ()
		end)
	end
	self.Connections = {}

	local windows = {}
	for _, window in pairs (self.Windows) do
		windows[#windows + 1] = window
	end
	for _, window in ipairs (windows) do
		pcall (function ()
			window:Destroy ()
		end)
	end
	self.Windows = {}

	if self.ScreenGui then
		pcall (function ()
			self.ScreenGui:Destroy ()
		end)
		self.ScreenGui = nil
	end

	if rawget (genv, "Dex") == self then genv.Dex = nil end
	self.Bypass = nil
	self.ConsoleBypass = nil
end

function Dex:Window (name)
	return self.Windows[name]
end


local ClassIcons = {
	Accessory = 1,
	Actor = 2,
	AdGui = 3,
	AdPortal = 4,
	AirController = 5,
	AlignOrientation = 6,
	AlignPosition = 7,
	AngularVelocity = 8,
	Animation = 9,
	AnimationConstraint = 10,
	AnimationController = 11,
	AnimationFromVideoCreatorService = 12,
	Animator = 13,
	ArcHandles = 14,
	Atmosphere = 15,
	Attachment = 16,
	AudioAnalyzer = 17,
	AudioChannelMixer = 18,
	AudioChannelSplitter = 19,
	AudioChorus = 20,
	AudioCompressor = 21,
	AudioDeviceInput = 22,
	AudioDeviceOutput = 23,
	AudioDistortion = 24,
	AudioEcho = 25,
	AudioEmitter = 26,
	AudioEqualizer = 27,
	AudioFader = 28,
	AudioFilter = 29,
	AudioFlanger = 30,
	AudioGate = 31,
	AudioLimiter = 32,
	AudioListener = 33,
	AudioPitchShifter = 34,
	AudioPlayer = 35,
	AudioRecorder = 36,
	AudioReverb = 37,
	AudioTextToSpeech = 38,
	AuroraScript = 39,
	AvatarEditorService = 40,
	AvatarSettings = 41,
	Backpack = 42,
	BallSocketConstraint = 43,
	BasePlate = 44,
	Beam = 45,
	BillboardGui = 46,
	BindableEvent = 47,
	BindableFunction = 48,
	BlockMesh = 49,
	BloomEffect = 50,
	BlurEffect = 51,
	BodyAngularVelocity = 52,
	BodyColors = 53,
	BodyForce = 54,
	BodyGyro = 55,
	BodyPosition = 56,
	BodyThrust = 57,
	BodyVelocity = 58,
	Bone = 59,
	BoolValue = 60,
	BoxHandleAdornment = 61,
	Breakpoint = 62,
	BubbleChatConfiguration = 64,
	Buggaroo = 65,
	Camera = 66,
	CanvasGroup = 67,
	CFrameValue = 68,
	ChannelTabsConfiguration = 69,
	CharacterControllerManager = 70,
	CharacterMesh = 71,
	Chat = 72,
	ChatInputBarConfiguration = 73,
	ChatWindowConfiguration = 74,
	ChorusSoundEffect = 75,
	Class = 76,
	Cleanup = 77,
	ClickDetector = 78,
	ClientReplicator = 79,
	ClimbController = 80,
	Clouds = 81,
	Color = 82,
	ColorCorrectionEffect = 83,
	CompressorSoundEffect = 84,
	ConeHandleAdornment = 85,
	Configuration = 86,
	Constant = 87,
	Constructor = 88,
	Controller = 89,
	CoreGui = 90,
	CornerWedgePart = 91,
	CylinderHandleAdornment = 92,
	CylindricalConstraint = 93,
	Decal = 94,
	DepthOfFieldEffect = 95,
	Dialog = 96,
	DialogChoice = 97,
	DistortionSoundEffect = 98,
	DragDetector = 99,
	EchoSoundEffect = 100,
	EditableImage = 101,
	EditableMesh = 102,
	Enum = 103,
	EnumMember = 104,
	EqualizerSoundEffect = 105,
	Event = 106,
	Explosion = 107,
	FaceControls = 108,
	Field = 109,
	File = 110,
	Fire = 111,
	FlangeSoundEffect = 112,
	Folder = 113,
	ForceField = 114,
	Frame = 115,
	Function = 116,
	GameSettings = 117,
	GroundController = 118,
	Handles = 119,
	HapticEffect = 120,
	HapticService = 121,
	HeightmapImporterService = 122,
	Highlight = 123,
	HingeConstraint = 124,
	Humanoid = 125,
	HumanoidDescription = 126,
	IKControl = 127,
	ImageButton = 128,
	ImageHandleAdornment = 129,
	ImageLabel = 130,
	InputAction = 131,
	InputBinding = 132,
	InputContext = 133,
	Interface = 134,
	IntersectOperation = 135,
	Keyword = 136,
	Lighting = 137,
	LinearVelocity = 138,
	LineForce = 139,
	LineHandleAdornment = 140,
	LocalFile = 141,
	LocalizationService = 142,
	LocalizationTable = 143,
	LocalScript = 144,
	MaterialService = 145,
	MaterialVariant = 146,
	MemoryStoreService = 147,
	MeshPart = 148,
	Meshparts = 149,
	MessagingService = 150,
	Method = 151,
	Model = 152,
	Modelgroups = 153,
	Module = 154,
	ModuleScript = 155,
	Motor6D = 156,
	NegateOperation = 157,
	NetworkClient = 158,
	NoCollisionConstraint = 159,
	Operator = 160,
	PackageLink = 161,
	Pants = 162,
	Part = 163,
	ParticleEmitter = 164,
	Path2D = 165,
	PathfindingLink = 166,
	PathfindingModifier = 167,
	PathfindingService = 168,
	PitchShiftSoundEffect = 169,
	Place = 170,
	Placeholder = 171,
	Plane = 172,
	PlaneConstraint = 173,
	Player = 174,
	Players = 175,
	PluginGuiService = 176,
	PointLight = 177,
	PrismaticConstraint = 178,
	Property = 179,
	ProximityPrompt = 180,
	PublishService = 181,
	Reference = 182,
	RemoteEvent = 183,
	RemoteFunction = 184,
	RenderingTest = 185,
	ReplicatedFirst = 186,
	ReplicatedScriptService = 187,
	ReplicatedStorage = 188,
	ReverbSoundEffect = 189,
	RigidConstraint = 190,
	RobloxPluginGuiService = 191,
	RocketPropulsion = 192,
	RodConstraint = 193,
	RopeConstraint = 194,
	Rotate = 195,
	ScreenGui = 196,
	Script = 197,
	ScrollingFrame = 198,
	Seat = 199,
	SelectedWorkspace = 200,
	SelectionBox = 201,
	SelectionSphere = 202,
	ServerScriptService = 203,
	ServerStorage = 204,
	Service = 205,
	Shirt = 206,
	ShirtGraphic = 207,
	SkinnedMeshPart = 208,
	Sky = 209,
	Smoke = 210,
	Snap = 211,
	Snippet = 212,
	SocialService = 213,
	Sound = 214,
	SoundEffect = 215,
	SoundGroup = 216,
	SoundService = 217,
	Sparkles = 218,
	SpawnLocation = 219,
	SpecialMesh = 220,
	SphereHandleAdornment = 221,
	SpotLight = 222,
	SpringConstraint = 223,
	StandalonePluginScripts = 224,
	StarterCharacterScripts = 225,
	StarterGui = 226,
	StarterPack = 227,
	StarterPlayer = 228,
	StarterPlayerScripts = 229,
	Struct = 230,
	StyleDerive = 231,
	StyleLink = 232,
	StyleRule = 233,
	StyleSheet = 234,
	SunRaysEffect = 235,
	SurfaceAppearance = 236,
	SurfaceGui = 237,
	SurfaceLight = 238,
	SurfaceSelection = 239,
	SwimController = 240,
	TaskScheduler = 241,
	Team = 242,
	Teams = 243,
	Terrain = 244,
	TerrainDetail = 245,
	TestService = 246,
	TextBox = 247,
	TextBoxService = 248,
	TextButton = 249,
	TextChannel = 250,
	TextChatCommand = 251,
	TextChatService = 252,
	TextLabel = 253,
	TextString = 254,
	Texture = 255,
	Tool = 256,
	Torque = 257,
	TorsionSpringConstraint = 258,
	Trail = 259,
	TremoloSoundEffect = 260,
	TrussPart = 261,
	TypeParameter = 262,
	UGCValidationService = 263,
	UIAspectRatioConstraint = 264,
	UICorner = 265,
	UIDragDetector = 266,
	UIFlexItem = 267,
	UIGradient = 268,
	UIGridLayout = 269,
	UIListLayout = 270,
	UIPadding = 271,
	UIPageLayout = 272,
	UIScale = 273,
	UISizeConstraint = 274,
	UIStroke = 275,
	UITableLayout = 276,
	UITextSizeConstraint = 277,
	UnionOperation = 278,
	Unit = 279,
	UniversalConstraint = 280,
	UnreliableRemoteEvent = 281,
	UpdateAvailable = 282,
	UserService = 283,
	Value = 284,
	Variable = 285,
	VectorForce = 286,
	VehicleSeat = 287,
	VideoDisplay = 288,
	VideoFrame = 289,
	VideoPlayer = 290,
	ViewportFrame = 291,
	VirtualUser = 292,
	VoiceChannel = 293,
	Voicechat = 294,
	VoiceChatService = 295,
	VRService = 296,
	WedgePart = 297,
	Weld = 298,
	WeldConstraint = 299,
	Wire = 300,
	WireframeHandleAdornment = 301,
	Workspace = 302,
	WorldModel = 303,
	WrapDeformer = 304,
	WrapLayer = 305,
	WrapTarget = 306,

	Color3Value = 284,
	IntValue = 284,
	NumberValue = 284,
	ObjectValue = 284,
	RayValue = 284,
	StringValue = 284,
	Vector3Value = 284,
	BrickColorValue = 284,
}

local Aliases = {
	BasePart = "Part",
	BaseScript = "Script",
	BasePlayerGui = "ScreenGui",
	GuiBase2d = "Frame",
	GuiObject = "Frame",
	GuiButton = "TextButton",
	LayerCollector = "ScreenGui",
	ValueBase = "StringValue",
	PostEffect = "BloomEffect",
	Light = "PointLight",
	SoundEffect = "Sound",
	BaseWrap = "WrapLayer",
	PVInstance = "Part",
	Instance = "Placeholder",
	DataModel = "Workspace",
}

local aliases = {}
for name, icon in pairs (ClassIcons) do
	aliases[name] = icon
end
for name, target in pairs (Aliases) do
	if aliases[name] == nil and aliases[target] then aliases[name] = aliases[target] end
end

local function resolveIndex (className, isService)
	if ClassIcons[className] then return ClassIcons[className] end

	if aliases[className] then return aliases[className] end

	local apiClass = Dex.Reflect and Dex.Reflect.Classes and Dex.Reflect.Classes[className]
	if apiClass then
		local superclass = apiClass.Superclass
		local guard = 0
		while superclass and guard < 30 do
			if ClassIcons[superclass] then return ClassIcons[superclass] end
			if aliases[superclass] then return aliases[superclass] end
			local parentClass = Dex.Reflect.Classes[superclass]
			superclass = parentClass and parentClass.Superclass or nil
			guard = guard + 1
		end
	end

	if className:match ("Value$") or className:match ("ValueBase$") then return ClassIcons.Value end

	if isService then return ClassIcons.Service end

	if className:match ("Service$") then return ClassIcons.Service end

	return ClassIcons.Placeholder
end

local function apply (image, className, isService, tint)
	local index = resolveIndex (className, isService) - 1
	local column = index % 18
	local row = math.floor (index / 18)

	image.Image = "rbxassetid://135148380892747"
	image.ImageRectOffset = Vector2.new (column * 32, row * 32)
	image.ImageRectSize = Vector2.new (32, 32)
	image.ScaleType = Enum.ScaleType.Crop
	image.ImageColor3 = tint or Color3.new (1, 1, 1)
	image.BackgroundTransparency = 1
end

local function imageLabel (parent, className, size, isService)
	size = size or 16
	local image = Dex.Utils.Create ("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (size, size),
		Parent = parent,
	})
	apply (image, className, isService)
	return image
end

Dex.Icons = {
	Map = "rbxassetid://135148380892747",
	Size = 32,
	Columns = 18,
	Rows = 18,
	Classes = ClassIcons,
	Apply = apply,
	ImageLabel = imageLabel,
	resolveIndex = resolveIndex,
}

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

local U = Dex.Utils

Dex._windowZ = 80
Dex._menuState = nil
Dex._picker = nil
Dex._colorPicker = nil
Dex._prompt = nil
Dex._toastHost = nil

function Dex:NextWindowZ ()
	self._windowZ = (self._windowZ or 80) + 10
	return self._windowZ
end

function Dex:IsInput (input, touch)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then return true end
	return touch ~= false and input.UserInputType == Enum.UserInputType.Touch
end

local function pointIn (gui, point)
	local ok, position = pcall (function ()
		return gui.AbsolutePosition
	end)
	if not ok or not gui.Visible then return false end
	local size = gui.AbsoluteSize
	return point.X >= position.X
		and point.Y >= position.Y
		and point.X <= position.X + size.X
		and point.Y <= position.Y + size.Y
end

local function makeShadow (parentGui, zIndex)
	local isUI = false
	local shadow = nil
	local ok, created = pcall (function ()
		return U.Create ("UIShadow", {
			Name = "WindowShadow",
			Parent = parentGui,
			Enabled = true,
		})
	end)
	if ok and created then
		isUI = true
		shadow = created
		pcall (function ()
			shadow.Color = Dex.Theme.Common.Black
		end)
		pcall (function ()
			shadow.Transparency = 0.62
		end)
		pcall (function ()
			shadow.BlurRadius = UDim.new (0, 8)
		end)
		pcall (function ()
			shadow.Offset = UDim2.fromOffset (0, 0)
		end)
		pcall (function ()
			shadow.Spread = UDim2.new (0, 2, 0, 2)
		end)
		pcall (function ()
			shadow.ShowBehindParent = true
		end)
		pcall (function ()
			shadow.Mode = Enum.ApplyShadowMode.Default
		end)
	else
		shadow = U.Frame (Dex.ScreenGui, {
			Name = "WindowShadow",
			BackgroundColor3 = Dex.Theme.Common.Black,
			BackgroundTransparency = 0.62,
			BorderSizePixel = 0,
			ZIndex = zIndex,
			Active = false,
		})
		U.Corner (shadow, 7)
	end
	return shadow
end

function Dex:CreateWindow (config)
	config = config or {}
	local name = config.Name or config.Title or "Window"
	local title = config.Title or name
	local titleHeight = config.TitleHeight or 30
	local minSize = config.MinSize or Vector2.new (240, 160)
	local initialSize = config.Size or UDim2.fromOffset (340, 480)
	local initialPosition = config.Position or UDim2.fromOffset (60, 60)
	local resizable = config.Resizable ~= false
	local showMaximize = config.ShowMaximize ~= false
	local showClose = config.ShowClose ~= false
	local bodyColor = config.ContentColor or config.BackgroundColor3 or Dex.Theme.Explorer.Background
	local titleColor = config.TitleBarColor3 or Dex.Theme.Explorer.TitleBar
	local borderColor = config.BorderColor3 or Dex.Theme.Explorer.Border

	if self.Windows[name] then self.Windows[name]:Destroy () end

	local window = {
		Name = name,
		Title = title,
		Visible = false,
		Maximized = false,
		MinSize = minSize,
		Resizable = resizable,
		Connections = {},
		ResizeCallbacks = {},
		ShowCallbacks = {},
		HideCallbacks = {},
		Destroyed = false,
		SnapBottom = config.SnapBottom == true,
		Config = config,
	}

	local gui = U.Frame (self.ScreenGui, {
		Name = name .. "Window",
		BackgroundColor3 = titleColor,
		BorderSizePixel = 0,
		Position = initialPosition,
		Size = initialSize,
		Visible = false,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 80,
	})
	gui.AnchorPoint = config.AnchorPoint or Vector2.new (0, 0)
	local guiCorner = U.Corner (gui, config.CornerRadius or 6)
	window.Corners = { guiCorner }
	window.BaseCornerRadius = config.CornerRadius or 6
	local border = U.Stroke (gui, borderColor, 1, 0)
	U.Frame (gui, {
		Name = "BottomCornerPatch",
		BackgroundColor3 = bodyColor,
		BorderSizePixel = 0,
		Position = UDim2.new (0, 0, 1, -12),
		Size = UDim2.new (1, 0, 0, 12),
		ZIndex = 1,
		Active = false,
	})
	window.GUI = gui
	window.Border = border

	window.Shadow = makeShadow (gui, 79)
	window.ShadowIsUIShadow = (window.Shadow and window.Shadow.ClassName == "UIShadow")

	local titleBar = U.Frame (gui, {
		Name = "TitleBar",
		BackgroundColor3 = titleColor,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, titleHeight),
		Position = UDim2.new (0, 0, 0, 0),
		ZIndex = 2,
		Active = true,
	})
	window.TitleBar = titleBar
	window.Corners[#window.Corners + 1] = U.Corner (titleBar, config.CornerRadius or 6)

	if config.ShowAccentLine ~= false then
		U.Frame (titleBar, {
			Name = "AccentLine",
			BackgroundColor3 = config.AccentColor or Dex.Theme.Common.Accent,
			BackgroundTransparency = config.AccentTransparency or 0.55,
			BorderSizePixel = 0,
			Size = UDim2.new (1, 0, 0, 1),
			Position = UDim2.new (0, 0, 1, -1),
			ZIndex = 3,
		})
	end

	local titleLabel = U.Label (titleBar, {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new (1, -90, 1, 0),
		Position = UDim2.fromOffset (45, 0),
		Font = Dex.Fonts.UIMedium,
		Text = title,
		TextColor3 = config.TitleTextColor3 or Dex.Theme.Explorer.TitleText,
		TextSize = config.TitleTextSize or 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})
	window.TitleLabel = titleLabel

	local controlHolder = U.Frame (titleBar, {
		Name = "WindowControls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -6, 0, 0),
		Size = UDim2.fromOffset (60, titleHeight),
		ZIndex = 4,
	})
	U.List (controlHolder, 1, true)
	local layout = controlHolder:FindFirstChildOfClass ("UIListLayout")
	if layout then
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
	end

	local function controlHover (button, hoverColor)
		local normal = button.BackgroundTransparency
		button.MouseEnter:Connect (function ()
			button.BackgroundTransparency = 0
			button.BackgroundColor3 = hoverColor
		end)
		button.MouseLeave:Connect (function ()
			button.BackgroundTransparency = normal
		end)
	end

	local function makeControl (iconDraw)
		local button = U.Button (controlHolder, {
			Name = "Control",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset (24, 24),
			Text = "",
			ZIndex = 4,
		})
		U.Corner (button, 4)
		iconDraw (button)
		return button
	end

	if showMaximize then
		local maximize = makeControl (function (button)
			local square = U.Frame (button, {
				Name = "MaximizeIcon",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new (0.5, 0.5),
				Position = UDim2.fromScale (0.5, 0.5),
				Size = UDim2.fromOffset (6, 6),
				ZIndex = 5,
			})
			U.Stroke (square, config.TitleIconColor3 or Dex.Theme.Explorer.TitleText, 1.2)
			local back = U.Frame (button, {
				Name = "RestoreIcon",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new (0.5, 0.5),
				Position = UDim2.new (0.5, 1, 0.5, -1),
				Size = UDim2.fromOffset (8, 8),
				Visible = false,
				ZIndex = 5,
			})
			U.Stroke (back, config.TitleIconColor3 or Dex.Theme.Explorer.TitleText, 1.2)
			local front = U.Frame (button, {
				Name = "RestoreFront",
				BackgroundColor3 = titleColor,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new (0.5, 0.5),
				Position = UDim2.new (0.5, -1, 0.5, 1),
				Size = UDim2.fromOffset (8, 8),
				Visible = false,
				ZIndex = 6,
			})
			U.Stroke (front, config.TitleIconColor3 or Dex.Theme.Explorer.TitleText, 1.2)
			button:SetAttribute ("RestoreIcon", true)
		end)
		window.MaximizeButton = maximize
		local square = maximize:FindFirstChild ("MaximizeIcon")
		local back = maximize:FindFirstChild ("RestoreIcon")
		local front = maximize:FindFirstChild ("RestoreFront")
		maximize.MouseButton1Click:Connect (function ()
			window:ToggleMaximize ()
		end)
		controlHover (maximize, config.ControlHoverColor3 or Dex.Theme.Explorer.Hover)
		window.SetMaximizeVisual = function (maximized)
			if square then square.Visible = not maximized end
			if back then back.Visible = maximized end
			if front then front.Visible = maximized end
		end
	end

	if showClose then
		local close = makeControl (function (button)
			U.DrawX (button, 9, config.TitleIconColor3 or Dex.Theme.Explorer.TitleText, 0)
		end)
		window.CloseButton = close
		close.MouseButton1Click:Connect (function ()
			window:Hide ()
			if type (config.OnClose) == "function" then task.spawn (config.OnClose) end
		end)
		controlHover (close, config.CloseHoverColor3 or Dex.Theme.Common.Danger)
	end

	local content = U.Frame (gui, {
		Name = "Content",
		BackgroundColor3 = bodyColor,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 1, -titleHeight),
		Position = UDim2.new (0, 0, 0, titleHeight),
		ClipsDescendants = true,
		ZIndex = 1,
	})
	content.InputBegan:Connect (function (input)
		if Dex:IsInput (input) then window:Focus () end
	end)

	function window:SetCornerRadius (radius)
		for _, corner in ipairs (self.Corners or {}) do
			pcall (function ()
				corner.CornerRadius = UDim.new (0, radius)
			end)
		end
		local shadowCorner = self.Shadow and self.Shadow:FindFirstChildOfClass ("UICorner")
		if shadowCorner then
			pcall (function ()
				shadowCorner.CornerRadius = UDim.new (0, radius == 0 and 0 or 7)
			end)
		end
	end

	function window:UpdateEdgeCorners ()
		if not self.EdgeDocked or not self.GUI then return end
		local viewport = U.Viewport ()
		local x = self.GUI.Position.X.Offset
		local y = self.GUI.Position.Y.Offset
		local width = self.GUI.Size.X.Offset
		local height = self.GUI.Size.Y.Offset
		local atEdge
		if self.SnapBottom then
			local atBottom = y + height >= viewport.Y - 1
			local atRight = true
			local dockName = self.Config and self.Config.DockRightWindow
			local dockWindow = dockName and Dex.Windows[dockName]
			if dockWindow and dockWindow.GUI and not dockWindow.Destroyed then
				atRight = math.abs ((x + width) - dockWindow.GUI.Position.X.Offset) <= 1
			end
			atEdge = x <= 1 and atBottom and atRight
		else
			atEdge = x <= 1 or (x + width) >= viewport.X - 1
		end
		self:SetCornerRadius (atEdge and 0 or (self.BaseCornerRadius or 6))
	end

	table.insert (
		window.Connections,
		gui:GetPropertyChangedSignal ("Position"):Connect (function ()
			window:UpdateEdgeCorners ()
		end)
	)
	table.insert (
		window.Connections,
		gui:GetPropertyChangedSignal ("Size"):Connect (function ()
			window:UpdateEdgeCorners ()
		end)
	)
	table.insert (
		window.Connections,
		gui:GetPropertyChangedSignal ("Position"):Connect (function ()
			Dex:ScheduleWindowConfigSave ()
		end)
	)
	table.insert (
		window.Connections,
		gui:GetPropertyChangedSignal ("Size"):Connect (function ()
			Dex:ScheduleWindowConfigSave ()
		end)
	)

	function window:Focus ()
		if self.Destroyed or not self.GUI.Visible then return end
		Dex.ActiveWindow = self
		local z = Dex:NextWindowZ ()
		self.GUI.ZIndex = z
		if self.Shadow then
			self.Shadow.ZIndex = z - 1
			if not self.ShadowIsUIShadow and self.Shadow.Parent == Dex.ScreenGui then
				self.Shadow.Parent = nil
				self.Shadow.Parent = Dex.ScreenGui
			end
		end
		if self.GUI.Parent == Dex.ScreenGui then
			self.GUI.Parent = nil
			self.GUI.Parent = Dex.ScreenGui
		end
		for _, other in pairs (Dex.Windows) do
			if other ~= self and other.ShadowIsUIShadow and other.Shadow then
				pcall (function ()
					other.Shadow.Spread = UDim2.new (0, 2, 0, 2)
				end)
			end
		end
		if self.ShadowIsUIShadow and self.Shadow then
			pcall (function ()
				self.Shadow.Spread = UDim2.new (0, 8, 0, 8)
			end)
		end
		if type (config.OnFocus) == "function" then task.spawn (config.OnFocus) end
	end

	function window:SyncShadow ()
		if not self.Shadow or self.Destroyed then return end
		if self.ShadowIsUIShadow then
			self.Shadow.Enabled = self.GUI.Visible and not self.Maximized
			return
		end
		self.Shadow.Visible = self.GUI.Visible and not self.Maximized
		if self.Maximized then return end
		self.Shadow.Position = UDim2.new (
			self.GUI.Position.X.Scale,
			self.GUI.Position.X.Offset + 3,
			self.GUI.Position.Y.Scale,
			self.GUI.Position.Y.Offset + 4
		)
		self.Shadow.Size = self.GUI.Size
	end

	function window:Show ()
		if self.Destroyed then return end
		self.GUI.Visible = true
		self.Visible = true
		self:Focus ()
		self:SyncShadow ()
		for _, callback in ipairs (self.ShowCallbacks) do
			task.spawn (callback)
		end
	end

	function window:Hide ()
		if self.Destroyed then return end
		self.GUI.Visible = false
		if self.ShadowIsUIShadow then
			self.Shadow.Enabled = false
		else
			self.Shadow.Visible = false
		end
		self.Visible = false
		for _, callback in ipairs (self.HideCallbacks) do
			task.spawn (callback)
		end
	end

	function window:Toggle ()
		if self.Visible then
			self:Hide ()
		else
			self:Show ()
		end
	end

	function window:SetTitle (text)
		self.Title = tostring (text)
		self.TitleLabel.Text = self.Title
	end

	function window:SetSubtitle (text)
		self.TitleLabel.Text = text or self.Title
	end

	function window:SetMaximized (maximized)
		maximized = maximized ~= false
		if self.Maximized == maximized or not self.Resizable then return end

		if maximized then
			self._restoreSize = self.GUI.Size
			self._restorePosition = self.GUI.Position
			self.Maximized = true
			local viewport = U.Viewport ()
			self.GUI.Size = UDim2.fromOffset (
				math.max (self.MinSize.X, viewport.X - 24),
				math.max (self.MinSize.Y, viewport.Y - 24)
			)
			self.GUI.Position = UDim2.fromOffset (12, 12)
		else
			self.Maximized = false
			self.GUI.Size = self._restoreSize or self.GUI.Size
			self.GUI.Position = self._restorePosition or self.GUI.Position
		end

		self.TitleBar.Visible = true
		if self.SetMaximizeVisual then self.SetMaximizeVisual (self.Maximized) end
		self:SyncShadow ()
		for _, callback in ipairs (self.ResizeCallbacks) do
			task.spawn (callback)
		end
	end

	function window:ToggleMaximize ()
		self:SetMaximized (not self.Maximized)
	end

	function window:OnResize (callback)
		table.insert (self.ResizeCallbacks, callback)
		return callback
	end

	function window:OnShow (callback)
		table.insert (self.ShowCallbacks, callback)
		return callback
	end

	function window:OnHide (callback)
		table.insert (self.HideCallbacks, callback)
		return callback
	end

	function window:Destroy ()
		if self.Destroyed then return end
		self.Destroyed = true
		self.Visible = false
		if Dex.ActiveWindow == self then Dex.ActiveWindow = nil end
		for _, connection in ipairs (self.Connections) do
			pcall (function ()
				connection:Disconnect ()
			end)
		end
		self.Connections = {}
		if self.Shadow then
			self.Shadow:Destroy ()
			self.Shadow = nil
		end
		if self.GUI then
			self.GUI:Destroy ()
			self.GUI = nil
		end
		if Dex.Windows[self.Name] == self then Dex.Windows[self.Name] = nil end
	end

	local dragStart = nil
	local dragPosition = nil
	local dragging = false
	local lastTitleClick = 0

	local function clampPosition (position)
		local viewport = U.Viewport ()
		local size = window.GUI.AbsoluteSize
		local maxX = math.max (0, viewport.X - size.X)
		local maxY = math.max (0, viewport.Y - size.Y)
		return UDim2.fromOffset (math.clamp (position.X.Offset, 0, maxX), math.clamp (position.Y.Offset, 0, maxY))
	end

	titleBar.InputBegan:Connect (function (input)
		if not Dex:IsInput (input) then return end
		local point = U.MousePoint ()
		for _, control in ipairs (controlHolder:GetChildren ()) do
			if control:IsA ("GuiButton") and pointIn (control, point) then return end
		end
		window:Focus ()

		local now = os.clock ()
		if now - lastTitleClick < 0.32 then
			lastTitleClick = 0
			dragging = false
			window:ToggleMaximize ()
			return
		end
		lastTitleClick = now
		if window.Maximized then return end
		dragging = true
		dragStart = point
		dragPosition = window.GUI.Position
	end)

	table.insert (
		window.Connections,
		UserInputService.InputChanged:Connect (function (input)
			if not dragging or dragStart == nil or dragPosition == nil then
				dragging = false
				dragStart = nil
				dragPosition = nil
				return
			end
			if
				input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			local point = U.MousePoint ()
			local delta = point - dragStart
			local newPosition =
				clampPosition (UDim2.fromOffset (dragPosition.X.Offset + delta.X, dragPosition.Y.Offset + delta.Y))
			if newPosition.X.Offset ~= window.GUI.Position.X.Offset
				or newPosition.Y.Offset ~= window.GUI.Position.Y.Offset
			then
				Dex._SnappingDisabled = true
			end
			window.GUI.Position = newPosition
			window:SyncShadow ()
		end)
	)

	table.insert (
		window.Connections,
		UserInputService.InputEnded:Connect (function (input)
			if Dex:IsInput (input) then dragging = false end
		end)
	)

	if resizable then
		local resizing = nil
		local resizeStart = nil
		local startSize = nil
		local startPosition = nil

		local function makeHandle (handleName, size, position, mode)
			local handle = U.Frame (gui, {
				Name = handleName,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = size,
				Position = position,
				Active = true,
				ZIndex = 50,
			})
			handle.InputBegan:Connect (function (input)
				if not Dex:IsInput (input) or window.Maximized then return end
				window:Focus ()
				resizing = mode
				resizeStart = U.MousePoint ()
				startSize = window.GUI.AbsoluteSize
				startPosition = window.GUI.Position
				window._SnapContext = Dex.GetSnappedLayout and Dex:GetSnappedLayout () or nil
			end)
			return handle
		end

		makeHandle ("ResizeE", UDim2.new (0, 5, 1, -16), UDim2.new (1, -5, 0, 8), "e")
		makeHandle ("ResizeW", UDim2.new (0, 5, 1, -16), UDim2.new (0, 0, 0, 8), "w")
		makeHandle ("ResizeS", UDim2.new (1, -16, 0, 5), UDim2.new (0, 8, 1, -5), "s")
		makeHandle ("ResizeSE", UDim2.fromOffset (8, 8), UDim2.new (1, -8, 1, -8), "se")
		makeHandle ("ResizeSW", UDim2.fromOffset (8, 8), UDim2.new (0, 0, 1, -8), "sw")
		table.insert (
			window.Connections,
			UserInputService.InputChanged:Connect (function (input)
				if not resizing then return end
				if
					input.UserInputType ~= Enum.UserInputType.MouseMovement
					and input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				local viewport = U.Viewport ()
				local delta = U.MousePoint () - resizeStart
				local x = startPosition.X.Offset
				local y = startPosition.Y.Offset
				local width = startSize.X
				local height = startSize.Y

				if resizing:find ("e") then
					width = startSize.X + delta.X
				elseif resizing:find ("w") then
					width = startSize.X - delta.X
					x = startPosition.X.Offset + delta.X
				end
				if resizing:find ("s") then height = startSize.Y + delta.Y end

				if width < minSize.X then
					if resizing:find ("w") then x = startPosition.X.Offset + startSize.X - minSize.X end
					width = minSize.X
				end
				if height < minSize.Y then height = minSize.Y end

				if x < 0 then
					width = width + x
					x = 0
				end
				if y < 0 then
					height = height + y
					y = 0
				end
				if x + width > viewport.X then width = viewport.X - x end
				if y + height > viewport.Y then height = viewport.Y - y end

				window.GUI.Size = UDim2.fromOffset (math.max (minSize.X, width), math.max (minSize.Y, height))
				window.GUI.Position = UDim2.fromOffset (x, y)
				window:SyncShadow ()
				if window._SnapContext then Dex:SyncSnappedWindows (window, window._SnapContext) end
				for _, callback in ipairs (window.ResizeCallbacks) do
					task.spawn (callback)
				end
			end)
		)

		table.insert (
			window.Connections,
			UserInputService.InputEnded:Connect (function (input)
				if Dex:IsInput (input) then
					resizing = nil
					window._SnapContext = nil
				end
			end)
		)
	end

	self.Windows[name] = window
	window:SyncShadow ()

	if type (config.ContentBuilder) == "function" then
		local ok, err = pcall (config.ContentBuilder, content, window)
		if not ok then Dex:Notify ("[Dex] " .. name .. " builder failed: " .. tostring (err), "error") end
	end

	if config.Visible then window:Show () end

	return window
end

function Dex:_Blocker (zIndex, onClick)
	local blocker = U.Button (self.ScreenGui, {
		Name = "OverlayBlocker",
		Size = UDim2.new (1, 0, 1, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Modal = false,
		ZIndex = zIndex,
		Active = true,
	})
	blocker.InputBegan:Connect (function (input)
		if Dex:IsInput (input) and onClick then onClick () end
	end)
	return blocker
end

function Dex:CloseMenus ()
	local state = self._menuState
	self._menuState = nil
	if state and state.Close then state.Close () end
end

function Dex:ClosePicker ()
	local picker = self._picker
	self._picker = nil
	if picker and picker.Close then picker.Close () end
end

function Dex:CloseColorPicker ()
	local picker = self._colorPicker
	self._colorPicker = nil
	if picker and picker.Close then picker.Close () end
end



function Dex:ShowMenu (items, position)
	self:CloseMenus ()
	self:ClosePicker ()
	self:CloseColorPicker ()

	local state = {
		Levels = {},
		Widths = {},
		Height = 0,
		Checks = {},
		OwnerRows = {},
		CheckTokens = {},
		HoverCount = {},
	}
	function state.Refresh ()
		for _, entry in ipairs (state.Checks) do
			local item = entry.Item
			if item and entry.Label and entry.Label.Parent then
				local checked = false
				if type (item.Checked) == "function" then
					checked = item.Checked ()
				else
					checked = item.Checked
				end
				entry.Label.Text = checked and "✓" or ""
			end
		end
	end

	local blocker = self:_Blocker (10000, function ()
		Dex:CloseMenus ()
	end)

	function state.Close ()
		if self._menuState == state then self._menuState = nil end
		for index = #state.Levels, 1, -1 do
			local frame = state.Levels[index]
			if frame then frame:Destroy () end
		end
		state.Levels = {}
		table.clear (state.OwnerRows)
		table.clear (state.CheckTokens)
		table.clear (state.HoverCount)
		if blocker and blocker.Parent then blocker:Destroy () end
	end

	local function closeDeeper (level)
		for index = #state.Levels, level + 1, -1 do
			local frame = state.Levels[index]
			if frame then frame:Destroy () end
			state.Levels[index] = nil
			state.OwnerRows[index] = nil
			state.CheckTokens[index] = (state.CheckTokens[index] or 0) + 1
			state.HoverCount[index] = 0
		end
	end


	local function pointNearGui (gui, point)
		if not gui or not gui.Parent then return false end
		local ok, position, size = pcall (function ()
			return gui.AbsolutePosition, gui.AbsoluteSize
		end)
		if not ok or not position or not size then return false end
		return point.X >= position.X - 10
			and point.X <= position.X + size.X + 10
			and point.Y >= position.Y - 10
			and point.Y <= position.Y + size.Y + 10
	end

	local function scheduleSubmenuCheck (ownerRow, submenuLevel)
		local token = (state.CheckTokens[submenuLevel] or 0) + 1
		state.CheckTokens[submenuLevel] = token
		task.delay (0.18, function ()
			if
				self._menuState ~= state
				or state.CheckTokens[submenuLevel] ~= token
				or not state.Levels[submenuLevel]
			then
				return
			end
			local point = U.MousePoint ()
			local inside = (state.HoverCount[submenuLevel] or 0) > 0
			if not inside then inside = pointNearGui (ownerRow, point) end
			if not inside then
				for index = submenuLevel, #state.Levels do
					if (state.HoverCount[index] or 0) > 0 or pointNearGui (state.Levels[index], point) then
						inside = true
						break
					end
				end
			end
			if not inside then
				closeDeeper (submenuLevel - 1)
				state.OwnerRows[submenuLevel] = nil
			end
		end)
	end

	state.CloseDeeper = closeDeeper
	self._menuState = state

	local function buildLevel (menuItems, level, origin)
		local rowHeight = 27
		local padding = 5
		local hasChecks = false
		local hasIcons = false
		for _, item in ipairs (menuItems) do
			if type (item.Icon) == "string" then
				hasIcons = true
				break
			end
		end
		local width = level == 1 and 196 or 184
		local contentHeight = padding * 2
		local rowHeights = {}

		for _, item in ipairs (menuItems) do
			if item.Separator then
				rowHeights[#rowHeights + 1] = 9
				contentHeight = contentHeight + 9
			else
				rowHeights[#rowHeights + 1] = rowHeight
				contentHeight = contentHeight + rowHeight
				if item.Checked ~= nil then hasChecks = true end
				local textWidth = U.TextWidth (item.Text or "", 14, Dex.Fonts.UI)
				local shortcutWidth = item.Shortcut and (U.TextWidth (item.Shortcut, 12, Dex.Fonts.UI) + 22) or 0
				local extra = 26
					+ (item.Submenu and 18 or 0)
					+ (item.Checked ~= nil and 16 or 0)
					+ (hasIcons and 20 or 0)
				width = math.max (width, textWidth + shortcutWidth + extra)
			end
		end

		width = math.min (360, math.max (level == 1 and 196 or 184, width))
		local maxHeight = 440
		local frameHeight = math.min (contentHeight, maxHeight)

		local viewport = U.Viewport ()
		local x = origin.X
		local y = origin.Y
		if x + width > viewport.X - 4 then
			if level > 1 then
				x = origin.X - width - state.Widths[level - 1] + 8
			else
				x = viewport.X - width - 4
			end
		end
		if x < 4 then x = 4 end
		if y + frameHeight > viewport.Y - 4 then y = viewport.Y - frameHeight - 4 end
		if y < 4 then y = 4 end

		local menu = U.Frame (self.ScreenGui, {
			Name = "ContextMenu" .. tostring (level),
			BackgroundColor3 = Dex.Theme.Menu.Background,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset (math.floor (x), math.floor (y)),
			Size = UDim2.fromOffset (math.floor (width), math.floor (frameHeight)),
			ClipsDescendants = true,
			ZIndex = 10000 + level,
		})
		U.Corner (menu, 4)
		U.Stroke (menu, Dex.Theme.Menu.Border, 1.2, 0)

		local contentParent = menu
		if contentHeight > maxHeight then
			contentParent = U.Scroll (menu, {
				Name = "MenuScroll",
				Size = UDim2.new (1, 0, 1, 0),
				CanvasSize = UDim2.new (0, 0, 0, contentHeight),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = Dex.Theme.Menu.Separator,
				ScrollBarImageTransparency = 0.2,
				ZIndex = 10000 + level,
			})
		end

		local layout = U.Create ("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new (0, 0),
			Parent = contentParent,
		})

		local pad = U.Create ("UIPadding", {
			PaddingTop = UDim.new (0, padding),
			PaddingBottom = UDim.new (0, padding),
			PaddingLeft = UDim.new (0, 3),
			PaddingRight = UDim.new (0, 3),
			Parent = contentParent,
		})

		state.Levels[level] = menu
		state.Widths[level] = width
		for index = level + 1, #state.Levels do
			state.Levels[index] = nil
			state.Widths[index] = nil
		end

		for index, item in ipairs (menuItems) do
			if item.Separator then
				local separatorHolder = U.Frame (contentParent, {
					Name = "Separator",
					BackgroundTransparency = 1,
					Size = UDim2.new (1, 0, 0, 9),
					LayoutOrder = index,
					ZIndex = 10000 + level,
				})
				U.Frame (separatorHolder, {
					BackgroundColor3 = Dex.Theme.Menu.Separator,
					BorderSizePixel = 0,
					Position = UDim2.new (0, 7, 0, 4),
					Size = UDim2.new (1, -14, 0, 1),
				})
			else
				local enabled = item.Enabled ~= false
				local showCheck = item.Checked ~= nil
				local row = U.Button (contentParent, {
					Name = "Item" .. tostring (item.Text or index),
					BackgroundTransparency = 1,
					BackgroundColor3 = Dex.Theme.Menu.Hover,
					Size = UDim2.new (1, 0, 0, rowHeight),
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = index,
					Selectable = enabled,
					ZIndex = 10000 + level + 1,
				})
				U.Corner (row, 3)

				row.MouseEnter:Connect (function ()
					state.HoverCount[level] = (state.HoverCount[level] or 0) + 1
				end)
				row.MouseLeave:Connect (function ()
					state.HoverCount[level] = math.max (0, (state.HoverCount[level] or 0) - 1)
				end)

				local textColor = enabled and (item.Color or Dex.Theme.Menu.Text) or Dex.Theme.Menu.TextDisabled
				local leftPad = (hasChecks and 28 or 12) + (hasIcons and 20 or 0)

				if showCheck then
					local check = U.Label (row, {
						Name = "Check",
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset (9, 0),
						Size = UDim2.fromOffset (16, rowHeight),
						Font = Dex.Fonts.UIBold,
						Text = (function ()
							local checked = false
							if type (item.Checked) == "function" then
								checked = item.Checked ()
							else
								checked = item.Checked
							end
							return checked and "✓" or ""
						end) (),
						TextColor3 = Dex.Theme.Menu.Check,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 10000 + level + 2,
					})
					check.Active = false
					state.Checks[#state.Checks + 1] = { Label = check, Item = item }
				end

				if hasIcons and type (item.Icon) == "string" then
					local icon = Dex.Icons.ImageLabel (row, item.Icon, 16, false)
					icon.Position = UDim2.fromOffset (hasChecks and 30 or 12, math.floor ((rowHeight - 16) / 2))
					icon.ZIndex = 10000 + level + 2
				end

				local text = U.Label (row, {
					Name = "Text",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset (leftPad, 0),
					Size = UDim2.new (1, -(leftPad + 42), 1, 0),
					Font = Dex.Fonts.UI,
					Text = item.Text or "",
					TextColor3 = textColor,
					TextSize = 14,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 10000 + level + 2,
				})
				text.Active = false

				if item.Shortcut and item.Shortcut ~= "" then
					local shortcut = U.Label (row, {
						Name = "Shortcut",
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new (1, 0),
						Position = UDim2.new (1, item.Submenu and -24 or -12, 0, 0),
						Size = UDim2.fromOffset (96, rowHeight),
						Font = Dex.Fonts.UI,
						Text = item.Shortcut,
						TextColor3 = enabled and Dex.Theme.Menu.Shortcut or Dex.Theme.Menu.TextDisabled,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Right,
						ZIndex = 10000 + level + 2,
					})
					shortcut.Active = false
				end

				if item.Submenu then
					local arrow = U.Label (row, {
						Name = "Arrow",
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new (1, 0.5),
						Position = UDim2.new (1, -9, 0.5, 0),
						Size = UDim2.fromOffset (14, rowHeight),
						Font = Dex.Fonts.UIMedium,
						Text = "›",
						TextColor3 = enabled and Dex.Theme.Menu.TextMuted or Dex.Theme.Menu.TextDisabled,
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Right,
						ZIndex = 10000 + level + 2,
					})
					arrow.Active = false
				end

				if enabled then
					row.MouseEnter:Connect (function ()
						row.BackgroundTransparency = 0
						text.TextColor3 = Dex.Theme.Common.White
						for _, child in ipairs (row:GetChildren ()) do
							if child:IsA ("TextLabel") and (child.Name == "Shortcut" or child.Name == "Arrow") then
								child.TextColor3 = Dex.Theme.Menu.TextMuted
							end
						end
						if item.Submenu then
							closeDeeper (level)
							local absolute = menu.AbsolutePosition
							local originX = absolute.X + width - 6
							local originY = row.AbsolutePosition.Y - 4
							if row.AbsolutePosition.Y <= 0 then
								originY = absolute.Y + padding + (index - 1) * rowHeight
							end
							task.defer (function ()
								if not row.Parent or self._menuState ~= state then return end
								state.CheckTokens[level + 1] = (state.CheckTokens[level + 1] or 0) + 1
								local submenu = buildLevel (item.Submenu, level + 1, Vector2.new (originX, originY))
								state.OwnerRows[level + 1] = row
								submenu.MouseEnter:Connect (function ()
									state.HoverCount[level + 1] = (state.HoverCount[level + 1] or 0) + 1
								end)
								submenu.MouseLeave:Connect (function ()
									state.HoverCount[level + 1] = math.max (0, (state.HoverCount[level + 1] or 0) - 1)
									scheduleSubmenuCheck (row, level + 1)
								end)
							end)
						end
					end)

					row.MouseLeave:Connect (function ()
						row.BackgroundTransparency = 1
						text.TextColor3 = item.Color or Dex.Theme.Menu.Text
						for _, child in ipairs (row:GetChildren ()) do
							if child:IsA ("TextLabel") and (child.Name == "Shortcut" or child.Name == "Arrow") then
								child.TextColor3 = Dex.Theme.Menu.Shortcut
							end
						end
						if item.Submenu then scheduleSubmenuCheck (row, level + 1) end
					end)

					row.MouseButton1Click:Connect (function ()
						if item.Submenu then return end
						local keepOpen = item.KeepOpen == true
						if not keepOpen then state.Close () end
						if type (item.Callback) == "function" then
							local ok, err = pcall (item.Callback)
							if not ok then Dex:Notify (tostring (err), "error") end
						end
						if keepOpen then state.Refresh () end
					end)
				end
			end
		end

		return menu
	end

	buildLevel (items, 1, position or U.MousePoint ())
	return state
end

Dex.ShowContextMenu = Dex.ShowMenu


function Dex:ShowPicker (config)
	config = config or {}
	self:CloseMenus ()
	self:ClosePicker ()
	self:CloseColorPicker ()

	local items = config.Items or {}
	local width = config.Width or 240
	local searchable = config.Search ~= false
	local showIcons = config.ShowIcons == true
	local maxHeight = config.MaxHeight or 340
	local rowHeight = config.RowHeight or 25
	local limit = config.Limit or 400

	local viewport = U.Viewport ()
	local position = config.Position
	if not position and config.Anchor and config.Anchor.Parent then
		position = Vector2.new (
			config.Anchor.AbsolutePosition.X,
			config.Anchor.AbsolutePosition.Y + config.Anchor.AbsoluteSize.Y + 2
		)
		width = math.max (width, config.Anchor.AbsoluteSize.X)
	end
	position = position or U.MousePoint ()

	local searchHeight = searchable and 32 or 0
	local height = math.min (maxHeight, searchHeight + math.min (#items, 14) * rowHeight + 10)
	width = math.min (width, viewport.X - 8)
	local x = math.clamp (position.X, 4, math.max (4, viewport.X - width - 4))
	local y = position.Y
	if y + height > viewport.Y - 4 then y = math.max (4, y - height - 34) end
	y = math.clamp (y, 4, math.max (4, viewport.Y - height - 4))

	local blocker = self:_Blocker (10400, function ()
		Dex:ClosePicker ()
	end)

	local frame = U.Frame (self.ScreenGui, {
		Name = "DexPicker",
		BackgroundColor3 = Dex.Theme.Menu.Background,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (math.floor (x), math.floor (y)),
		Size = UDim2.fromOffset (math.floor (width), math.floor (height)),
		ClipsDescendants = true,
		ZIndex = 10400 + 1,
	})
	U.Corner (frame, 4)
	U.Stroke (frame, Dex.Theme.Menu.Border, 1.2, 0)

	local searchBox = nil
	if searchable then
		local holder = U.Frame (frame, {
			BackgroundColor3 = Dex.Theme.Menu.Background,
			BorderSizePixel = 0,
			Size = UDim2.new (1, -12, 0, 26),
			Position = UDim2.fromOffset (6, 5),
			ZIndex = 10400 + 2,
		})
		U.Corner (holder, 3)
		U.Stroke (holder, Dex.Theme.Menu.Separator, 1, 0)

		local searchIcon = U.Frame (holder, {
			Name = "SearchIcon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset (14, 14),
			Position = UDim2.fromOffset (7, 6),
			ZIndex = 10400 + 3,
		})
		local lens = U.Frame (searchIcon, {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset (9, 9),
			Position = UDim2.fromOffset (1, 1),
			ZIndex = 10400 + 3,
		})
		U.Corner (lens, 99)
		U.Stroke (lens, Dex.Theme.Menu.TextMuted, 1.2, 0)
		U.Frame (searchIcon, {
			BackgroundColor3 = Dex.Theme.Menu.TextMuted,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset (5, 1.2),
			Position = UDim2.fromOffset (9, 10),
			Rotation = 45,
			ZIndex = 10400 + 3,
		})

		searchBox = U.Textbox (holder, {
			Name = "Search",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset (27, 0),
			Size = UDim2.new (1, -34, 1, 0),
			Font = Dex.Fonts.UI,
			PlaceholderText = config.SearchPlaceholder or "Search...",
			PlaceholderColor3 = Dex.Theme.Menu.TextMuted,
			TextColor3 = Dex.Theme.Menu.Text,
			TextSize = 13,
			ZIndex = 10400 + 3,
		})
	end

	local list = U.Scroll (frame, {
		Name = "Items",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (5, 5 + searchHeight),
		Size = UDim2.new (1, -10, 1, -(10 + searchHeight)),
		CanvasSize = UDim2.new (0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Dex.Theme.Menu.Separator,
		ScrollBarImageTransparency = 0.1,
		ZIndex = 10400 + 2,
	})
	U.List (list, 1)
	U.Create ("UIPadding", {
		PaddingTop = UDim.new (0, 2),
		PaddingBottom = UDim.new (0, 2),
		Parent = list,
	})
	list:FindFirstChildOfClass ("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top

	local state = { Frame = frame, Blocker = blocker }
	function state.Close ()
		if Dex._picker == state then Dex._picker = nil end
		if frame and frame.Parent then frame:Destroy () end
		if blocker and blocker.Parent then blocker:Destroy () end
	end
	self._picker = state

	local function normalize (item)
		if type (item) == "table" then return item end
		return { Text = tostring (item), Value = item }
	end

	local function rebuild ()
		for _, child in ipairs (list:GetChildren ()) do
			if child:IsA ("GuiObject") and not child:IsA ("UIGridLayout") then child:Destroy () end
		end

		local query = searchBox and searchBox.Text:lower () or ""
		local shown = 0
		for _, raw in ipairs (items) do
			local item = normalize (raw)
			local label = item.Text or tostring (item.Value)
			if
				query == ""
				or label:lower ():find (query, 1, true)
				or (item.SearchText and item.SearchText:lower ():find (query, 1, true))
			then
				if shown < limit then
					shown = shown + 1
					local selected = item.Selected == true
					local row = U.Button (list, {
						Name = "PickerRow",
						BackgroundTransparency = 1,
						BackgroundColor3 = selected and Dex.Theme.Menu.Check or Dex.Theme.Menu.Hover,
						Size = UDim2.new (1, 0, 0, rowHeight),
						Text = "",
						AutoButtonColor = false,
						ZIndex = 10400 + 3,
					})
					U.Corner (row, 3)

					local textX = 9
					if showIcons then
						textX = 29
						local iconClass = item.Class or item.Icon
						if type (iconClass) == "string" then
							local icon = Dex.Icons.ImageLabel (row, iconClass, 16, item.IsService)
							icon.Position = UDim2.fromOffset (7, math.floor ((rowHeight - 16) / 2))
						end
					end

					local rowText = U.Label (row, {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset (textX, 0),
						Size = UDim2.new (1, -(textX + 24), 1, 0),
						Font = selected and Dex.Fonts.UIMedium or Dex.Fonts.UI,
						Text = label,
						TextColor3 = item.Color or Dex.Theme.Menu.Text,
						TextSize = 13,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 10400 + 4,
					})
					rowText.Active = false

					if selected then
						local check = U.Label (row, {
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new (1, 0.5),
							Position = UDim2.new (1, -10, 0.5, 0),
							Size = UDim2.fromOffset (16, 18),
							Font = Dex.Fonts.UIBold,
							Text = "✓",
							TextColor3 = Dex.Theme.Menu.Check,
							TextSize = 13,
							TextXAlignment = Enum.TextXAlignment.Right,
							ZIndex = 10400 + 4,
						})
						check.Active = false
					end

					row.MouseEnter:Connect (function ()
						row.BackgroundTransparency = 0
						rowText.TextColor3 = Dex.Theme.Common.White
					end)
					row.MouseLeave:Connect (function ()
						row.BackgroundTransparency = 1
						rowText.TextColor3 = item.Color or Dex.Theme.Menu.Text
					end)
					row.MouseButton1Click:Connect (function ()
						if config.KeepOpen ~= true then state.Close () end
						if type (config.OnSelect) == "function" then
							local ok, err = pcall (config.OnSelect, item.Value, item)
							if not ok then Dex:Notify (tostring (err), "error") end
						end
						if config.KeepOpen == true and state.Refresh then state.Refresh () end
					end)
				end
			end
		end

		if shown == 0 then
			local empty = U.Label (list, {
				Name = "Empty",
				BackgroundTransparency = 1,
				Size = UDim2.new (1, 0, 0, 30),
				Font = Dex.Fonts.UI,
				Text = config.EmptyText or "No results",
				TextColor3 = Dex.Theme.Menu.TextMuted,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 10400 + 3,
			})
			empty.Active = false
		end
	end

	state.Refresh = rebuild
	rebuild ()
	if searchBox then
		searchBox:GetPropertyChangedSignal ("Text"):Connect (rebuild)

		if config.AutoFocus ~= false then
			task.defer (function ()
				if searchBox and searchBox.Parent then searchBox:CaptureFocus () end
			end)
		end
	end

	return state
end


function Dex:ShowColorPicker (color, position, onChanged)
	self:CloseMenus ()
	self:ClosePicker ()
	self:CloseColorPicker ()

	color = color or Color3.new (1, 1, 1)
	local hue, saturation, value = color:ToHSV ()
	local viewport = U.Viewport ()

	local width = 236
	local height = 316
	local x = math.clamp ((position and position.X) or (viewport.X / 2 - width / 2), 4, viewport.X - width - 4)
	local y = (position and position.Y) or (viewport.Y / 2 - height / 2)
	if y + height > viewport.Y - 4 then y = viewport.Y - height - 4 end
	y = math.clamp (y, 4, math.max (4, viewport.Y - height - 4))

	local frame
	local blocker = self:_Blocker (10600, function ()
		local point = U.MousePoint ()
		if not pointIn (frame, point) then Dex:CloseColorPicker () end
	end)

	frame = U.Frame (self.ScreenGui, {
		Name = "ColorPicker",
		BackgroundColor3 = Dex.Theme.Menu.Background,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (math.floor (x), math.floor (y)),
		Size = UDim2.fromOffset (width, height),
		ClipsDescendants = true,
		ZIndex = 10600 + 1,
	})
	U.Corner (frame, 5)
	U.Stroke (frame, Dex.Theme.Menu.Border, 1.2, 0)

	local header = U.Label (frame, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (11, 0),
		Size = UDim2.new (1, -44, 0, 28),
		Font = Dex.Fonts.UIMedium,
		Text = "Color",
		TextColor3 = Dex.Theme.Menu.Text,
		TextSize = 13,
		ZIndex = 10600 + 2,
	})
	header.Active = false

	local done = U.Button (frame, {
		Name = "Done",
		BackgroundColor3 = Dex.Theme.Menu.Hover,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -8, 0, 5),
		Size = UDim2.fromOffset (46, 20),
		Font = Dex.Fonts.UIMedium,
		Text = "Done",
		TextColor3 = Dex.Theme.Menu.Text,
		TextSize = 12,
		ZIndex = 10600 + 2,
	})
	U.Corner (done, 3)
	done.MouseButton1Click:Connect (function ()
		Dex:CloseColorPicker ()
	end)

	local padHolder = U.Button (frame, {
		Name = "SaturationValue",
		BackgroundColor3 = Color3.fromHSV (hue, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (10, 32),
		Size = UDim2.fromOffset (width - 20, 126),
		ClipsDescendants = true,
		Active = true,
		ZIndex = 10600 + 2,
	})
	U.Corner (padHolder, 4)
	U.Stroke (padHolder, Dex.Theme.Menu.Separator, 1, 0)

	local whiteLayer = U.Frame (padHolder, {
		BackgroundColor3 = Color3.new (1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale (1, 1),
		ZIndex = 10600 + 3,
	})
	U.Create ("UIGradient", {
		Color = ColorSequence.new (Color3.new (1, 1, 1)),
		Transparency = NumberSequence.new ({
			NumberSequenceKeypoint.new (0, 0),
			NumberSequenceKeypoint.new (1, 1),
		}),
		Rotation = 0,
		Parent = whiteLayer,
	})

	local blackLayer = U.Frame (padHolder, {
		BackgroundColor3 = Color3.new (0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale (1, 1),
		ZIndex = 10600 + 4,
	})
	U.Create ("UIGradient", {
		Color = ColorSequence.new (Color3.new (0, 0, 0)),
		Transparency = NumberSequence.new ({
			NumberSequenceKeypoint.new (0, 1),
			NumberSequenceKeypoint.new (1, 0),
		}),
		Rotation = 90,
		Parent = blackLayer,
	})

	local marker = U.Frame (padHolder, {
		Name = "Marker",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Size = UDim2.fromOffset (12, 12),
		ZIndex = 10600 + 6,
	})
	U.Corner (marker, 99)
	U.Stroke (marker, Dex.Theme.Common.White, 2, 0)
	U.Stroke (marker, Dex.Theme.Common.Black, 1, 0.55)

	local hueHolder = U.Button (frame, {
		Name = "Hue",
		BackgroundColor3 = Dex.Theme.Menu.Hover,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (10, 169),
		Size = UDim2.fromOffset (width - 20, 14),
		ClipsDescendants = true,
		Active = true,
		ZIndex = 10600 + 2,
	})
	U.Corner (hueHolder, 3)
	local hueGradient = U.Frame (hueHolder, {
		BorderSizePixel = 0,
		Size = UDim2.fromScale (1, 1),
		ZIndex = 10600 + 3,
	})
	local gradient = U.Create ("UIGradient", {
		Color = ColorSequence.new ({
			ColorSequenceKeypoint.new (0.00, Color3.fromRGB (255, 0, 0)),
			ColorSequenceKeypoint.new (0.17, Color3.fromRGB (255, 255, 0)),
			ColorSequenceKeypoint.new (0.33, Color3.fromRGB (0, 255, 0)),
			ColorSequenceKeypoint.new (0.50, Color3.fromRGB (0, 255, 255)),
			ColorSequenceKeypoint.new (0.67, Color3.fromRGB (0, 0, 255)),
			ColorSequenceKeypoint.new (0.83, Color3.fromRGB (255, 0, 255)),
			ColorSequenceKeypoint.new (1.00, Color3.fromRGB (255, 0, 0)),
		}),
		Parent = hueGradient,
	})
	U.Stroke (hueHolder, Dex.Theme.Menu.Separator, 1, 0)

	local hueMarker = U.Frame (hueHolder, {
		Name = "HueMarker",
		BackgroundColor3 = Dex.Theme.Common.White,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Position = UDim2.fromScale (0, 0.5),
		Size = UDim2.fromOffset (4, 18),
		ZIndex = 10600 + 4,
	})
	U.Corner (hueMarker, 2)
	U.Stroke (hueMarker, Dex.Theme.Common.Black, 1, 0.4)

	local preview = U.Frame (frame, {
		Name = "Preview",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (10, 196),
		Size = UDim2.fromOffset (24, 24),
		ZIndex = 10600 + 2,
	})
	U.Corner (preview, 4)
	U.Stroke (preview, Dex.Theme.Menu.Separator, 1, 0)

	local hexHolder = U.Frame (frame, {
		Name = "Hex",
		BackgroundColor3 = Dex.Theme.Menu.Hover,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (42, 196),
		Size = UDim2.fromOffset (width - 52, 24),
		ZIndex = 10600 + 2,
	})
	U.Corner (hexHolder, 3)
	U.Stroke (hexHolder, Dex.Theme.Menu.Separator, 1, 0)

	local hexBox = U.Textbox (hexHolder, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (7, 0),
		Size = UDim2.new (1, -10, 1, 0),
		Font = Dex.Fonts.Mono,
		PlaceholderText = "#ffffff",
		TextColor3 = Dex.Theme.Menu.Text,
		PlaceholderColor3 = Dex.Theme.Menu.TextMuted,
		TextSize = 13,
		ClearTextOnFocus = false,
		ZIndex = 10600 + 3,
	})
	local activeField = nil
	hexBox.Focused:Connect (function ()
		activeField = hexBox
	end)
	hexBox.FocusLost:Connect (function ()
		if activeField == hexBox then activeField = nil end
	end)

	local function numberField (parent, x, y, width, label)
		local holder = U.Frame (parent, {
			BackgroundColor3 = Dex.Theme.Menu.Hover,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset (x, y),
			Size = UDim2.fromOffset (width, 22),
			ZIndex = 10600 + 2,
		})
		U.Corner (holder, 3)
		U.Stroke (holder, Dex.Theme.Menu.Separator, 1, 0)
		local caption = U.Label (holder, {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset (4, 0),
			Size = UDim2.fromOffset (16, 22),
			Font = Dex.Fonts.UIMedium,
			Text = label,
			TextColor3 = Dex.Theme.Menu.TextMuted,
			TextSize = 11,
			ZIndex = 10600 + 3,
		})
		caption.Active = false
		local box = U.Textbox (holder, {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset (20, 0),
			Size = UDim2.new (1, -24, 1, 0),
			Font = Dex.Fonts.Mono,
			Text = "0",
			TextColor3 = Dex.Theme.Menu.Text,
			TextSize = 11,
			ClearTextOnFocus = false,
			ZIndex = 10600 + 3,
		})
		box.Focused:Connect (function ()
			activeField = box
		end)
		box.FocusLost:Connect (function ()
			if activeField == box then activeField = nil end
		end)
		return box
	end

	U.Label (frame, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (10, 226),
		Size = UDim2.fromOffset (40, 16),
		Font = Dex.Fonts.UIMedium,
		Text = "RGB",
		TextColor3 = Dex.Theme.Menu.TextMuted,
		TextSize = 11,
		ZIndex = 10600 + 2,
	}).Active =
		false
	local rBox = numberField (frame, 48, 224, 54, "R")
	local gBox = numberField (frame, 106, 224, 54, "G")
	local bBox = numberField (frame, 164, 224, 54, "B")

	U.Label (frame, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (10, 254),
		Size = UDim2.fromOffset (40, 16),
		Font = Dex.Fonts.UIMedium,
		Text = "HSL",
		TextColor3 = Dex.Theme.Menu.TextMuted,
		TextSize = 11,
		ZIndex = 10600 + 2,
	}).Active =
		false
	local hBox = numberField (frame, 48, 252, 54, "H")
	local sBox = numberField (frame, 106, 252, 54, "S")
	local lBox = numberField (frame, 164, 252, 54, "L")

	local state = { Frame = frame, Blocker = blocker }
	function state.Close ()
		if Dex._colorPicker == state then Dex._colorPicker = nil end
		if frame and frame.Parent then frame:Destroy () end
		if blocker and blocker.Parent then blocker:Destroy () end
	end
	self._colorPicker = state

	local currentColor = color
	local updatingHex = false
	local updatingFields = false

	local function render (notify, skipHex)
		currentColor = Color3.fromHSV (hue, saturation, value)
		preview.BackgroundColor3 = currentColor
		padHolder.BackgroundColor3 = Color3.fromHSV (hue, 1, 1)
		marker.Position = UDim2.new (saturation, 0, 1 - value, 0)
		hueMarker.Position = UDim2.fromScale (hue, 0.5)
		if not skipHex and activeField ~= hexBox then
			updatingHex = true
			hexBox.Text = "#" .. U.ColorHex (currentColor)
			updatingHex = false
		end
		if not updatingFields then
			updatingFields = true
			local r = math.floor (currentColor.R * 255 + 0.5)
			local g = math.floor (currentColor.G * 255 + 0.5)
			local b = math.floor (currentColor.B * 255 + 0.5)
			if activeField ~= rBox then rBox.Text = tostring (r) end
			if activeField ~= gBox then gBox.Text = tostring (g) end
			if activeField ~= bBox then bBox.Text = tostring (b) end
			local h, sat, val = currentColor:ToHSV ()
			if activeField ~= hBox then hBox.Text = tostring (math.floor (h * 360 + 0.5)) end
			if activeField ~= sBox then sBox.Text = tostring (math.floor (sat * 100 + 0.5)) end
			if activeField ~= lBox then lBox.Text = tostring (math.floor (val * 100 + 0.5)) end
			updatingFields = false
		end
		if notify and type (onChanged) == "function" then
			local ok, err = pcall (onChanged, currentColor)
			if not ok then Dex:Notify (tostring (err), "error") end
		end
	end

	local padDrag = false
	local hueDrag = false

	local function updatePad (point)
		local absolute = padHolder.AbsolutePosition
		local size = padHolder.AbsoluteSize
		saturation = math.clamp ((point.X - absolute.X) / math.max (1, size.X), 0, 1)
		value = 1 - math.clamp ((point.Y - absolute.Y) / math.max (1, size.Y), 0, 1)
		render (true)
	end

	local function updateHue (point)
		local absolute = hueHolder.AbsolutePosition
		local size = hueHolder.AbsoluteSize
		hue = math.clamp ((point.X - absolute.X) / math.max (1, size.X), 0, 1)
		if hue >= 1 then hue = 0.9999 end
		render (true)
	end

	padHolder.InputBegan:Connect (function (input)
		if Dex:IsInput (input) then
			padDrag = true
			updatePad (Vector2.new (input.Position.X, input.Position.Y))
		end
	end)
	hueHolder.InputBegan:Connect (function (input)
		if Dex:IsInput (input) then
			hueDrag = true
			updateHue (Vector2.new (input.Position.X, input.Position.Y))
		end
	end)

	local connections = {}
	table.insert (
		connections,
		UserInputService.InputChanged:Connect (function (input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			local point = Vector2.new (input.Position.X, input.Position.Y)
			if padDrag then
				updatePad (point)
			elseif hueDrag then
				updateHue (point)
			end
		end)
	)
	table.insert (
		connections,
		UserInputService.InputEnded:Connect (function (input)
			if Dex:IsInput (input) then
				padDrag = false
				hueDrag = false
			end
		end)
	)

	local oldClose = state.Close
	function state.Close ()
		for _, connection in ipairs (connections) do
			pcall (function ()
				connection:Disconnect ()
			end)
		end
		oldClose ()
	end

	local function commitFields ()
		if updatingFields then return end
		local r = tonumber (rBox.Text)
		local g = tonumber (gBox.Text)
		local b = tonumber (bBox.Text)
		if r and g and b then
			hue, saturation, value =
				Color3.fromRGB (math.clamp (r, 0, 255), math.clamp (g, 0, 255), math.clamp (b, 0, 255)):ToHSV ()
			render (true)
			return
		end
		local h = tonumber (hBox.Text)
		local sat = tonumber (sBox.Text)
		local lit = tonumber (lBox.Text)
		if h and sat and lit then
			hue = math.clamp (h, 0, 360) / 360
			if hue >= 1 then hue = 0.9999 end
			saturation = math.clamp (sat, 0, 100) / 100
			value = math.clamp (lit, 0, 100) / 100
			render (true)
		end
	end
	for _, field in ipairs ({ rBox, gBox, bBox, hBox, sBox, lBox }) do
		field.FocusLost:Connect (function ()
			commitFields ()
		end)
	end

	hexBox.FocusLost:Connect (function (enterPressed)
		if updatingHex then return end
		local raw = hexBox.Text:gsub ("#", ""):gsub ("%s", "")
		local hexValue = nil
		if raw:match ("^%x%x%x%x%x%x$") then
			hexValue = raw
		elseif raw:match ("^%x%x%x$") then
			hexValue = raw:sub (1, 1):rep (2) .. raw:sub (2, 2):rep (2) .. raw:sub (3, 3):rep (2)
		end
		if hexValue then
			local number = tonumber (hexValue, 16)
			local picked =
				Color3.fromRGB (math.floor (number / 65536) % 256, math.floor (number / 256) % 256, number % 256)
			hue, saturation, value = picked:ToHSV ()
			render (true)
		else
			render (false)
		end
		if enterPressed then hexBox:ReleaseFocus (true) end
	end)

	render (false)
	return state
end


function Dex:Prompt (config)
	config = config or {}
	local existing = self._prompt
	if existing and existing.Close then existing.Close () end

	local viewport = U.Viewport ()
	local width = config.Width or 340
	local messageText = config.Message or ""
	local _, lineCount = messageText:gsub ("\n", "")
	local messageHeight = math.max (34, (lineCount + 1) * 17 + 8)
	local inputY = 40 + messageHeight + 4
	local errorY = inputY + (config.Input == false and 6 or 38)
	local height = math.max (config.Height or (config.Input == false and 168 or 204), errorY + 76)
	local blocker = self:_Blocker (11000, function ()
		if config.DismissOnBackdrop ~= false and config.OnCancel then task.spawn (config.OnCancel) end
		if config.DismissOnBackdrop ~= false then Dex:ClosePrompt () end
	end)
	blocker.BackgroundColor3 = Dex.Theme.Common.Black
	blocker.BackgroundTransparency = config.BlockerTransparency or 0.48

	local frame = U.Frame (self.ScreenGui, {
		Name = "DexPrompt",
		BackgroundColor3 = Dex.Theme.Explorer.Background,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Position = UDim2.fromScale (0.5, 0.5),
		Size = UDim2.fromOffset (width, height),
		ClipsDescendants = true,
		ZIndex = 11000 + 1,
	})
	U.Corner (frame, 5)
	U.Stroke (frame, Dex.Theme.Explorer.Border, 1, 0)

	local titleBar = U.Frame (frame, {
		BackgroundColor3 = Dex.Theme.Explorer.TitleBar,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 30),
		ZIndex = 11000 + 2,
	})
	U.Label (titleBar, {
		BackgroundTransparency = 1,
		Size = UDim2.new (1, -60, 1, 0),
		Position = UDim2.fromOffset (30, 0),
		Font = Dex.Fonts.UIMedium,
		Text = config.Title or "Prompt",
		TextColor3 = Dex.Theme.Explorer.TitleText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 11000 + 3,
	})

	local close = U.Button (titleBar, {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0.5),
		Position = UDim2.new (1, -8, 0.5, 0),
		Size = UDim2.fromOffset (24, 24),
		Text = "",
		ZIndex = 11000 + 3,
	})
	U.Corner (close, 4)
	U.DrawX (close, 8, Dex.Theme.Explorer.TitleText)
	close.MouseEnter:Connect (function ()
		close.BackgroundTransparency = 0
		close.BackgroundColor3 = Dex.Theme.Common.Danger
	end)
	close.MouseLeave:Connect (function ()
		close.BackgroundTransparency = 1
	end)

	local message = U.Label (frame, {
		Name = "Message",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (16, 40),
		Size = UDim2.new (1, -32, 0, messageHeight),
		Font = Dex.Fonts.UI,
		Text = messageText,
		TextColor3 = Dex.Theme.Explorer.TreeText,
		TextSize = 13,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11000 + 2,
	})

	local inputBox = nil
	if config.Input ~= false then
		inputBox = U.Textbox (frame, {
			Name = "Input",
			BackgroundColor3 = Dex.Theme.Explorer.SearchBackground,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset (16, inputY),
			Size = UDim2.new (1, -32, 0, 30),
			Font = Dex.Fonts.UI,
			Text = config.Value or "",
			PlaceholderText = config.Placeholder or "",
			PlaceholderColor3 = Dex.Theme.Explorer.Placeholder,
			TextColor3 = Dex.Theme.Explorer.SearchText,
			TextSize = 14,
			ClearTextOnFocus = false,
			ZIndex = 11000 + 2,
		})
		U.Corner (inputBox, 3)
		U.Stroke (inputBox, Dex.Theme.Explorer.SearchBorder, 1, 0)
		U.Create ("UIPadding", {
			PaddingLeft = UDim.new (0, 9),
			PaddingRight = UDim.new (0, 9),
			Parent = inputBox,
		})
	end

	local errorLabel = U.Label (frame, {
		Name = "Error",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (16, errorY),
		Size = UDim2.new (1, -32, 0, 18),
		Font = Dex.Fonts.UI,
		Text = "",
		TextColor3 = Dex.Theme.Common.Danger,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11000 + 2,
	})

	local buttonY = height - 42
	local cancel = U.Button (frame, {
		Name = "Cancel",
		BackgroundColor3 = Dex.Theme.Explorer.Hover,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -118, 0, buttonY),
		Size = UDim2.fromOffset (96, 28),
		Font = Dex.Fonts.UIMedium,
		Text = config.CancelText or "Cancel",
		TextColor3 = Dex.Theme.Explorer.TreeText,
		TextSize = 13,
		ZIndex = 11000 + 2,
	})
	U.Corner (cancel, 4)

	local confirm = U.Button (frame, {
		Name = "Confirm",
		BackgroundColor3 = Dex.Theme.Common.Accent,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -16, 0, buttonY),
		Size = UDim2.fromOffset (96, 28),
		Font = Dex.Fonts.UIMedium,
		Text = config.ConfirmText or "OK",
		TextColor3 = Dex.Theme.Common.White,
		TextSize = 13,
		ZIndex = 11000 + 2,
	})
	U.Corner (confirm, 4)

	local state = { Frame = frame, Blocker = blocker }
	local connections = {}

	function state.Close ()
		if Dex._prompt == state then Dex._prompt = nil end
		for _, connection in ipairs (connections) do
			pcall (function ()
				connection:Disconnect ()
			end)
		end
		if frame and frame.Parent then frame:Destroy () end
		if blocker and blocker.Parent then blocker:Destroy () end
	end
	self._prompt = state

	local function dismiss ()
		state.Close ()
		if type (config.OnCancel) == "function" then task.spawn (config.OnCancel) end
	end

	close.MouseButton1Click:Connect (dismiss)
	cancel.MouseButton1Click:Connect (dismiss)

	local submitting = false
	local function submit ()
		if submitting then return end
		local text = inputBox and inputBox.Text or ""
		if type (config.Validate) == "function" then
			local ok, valid, reason = pcall (config.Validate, text)
			if not ok then
				errorLabel.Text = tostring (valid)
				return
			end
			if not valid then
				errorLabel.Text = tostring (reason or "Invalid value.")
				return
			end
		end
		submitting = true
		state.Close ()
		if type (config.OnConfirm) == "function" then
			local ok, err = pcall (config.OnConfirm, text)
			if not ok then Dex:Notify (tostring (err), "error") end
		end
	end

	confirm.MouseButton1Click:Connect (submit)

	if inputBox then
		table.insert (
			connections,
			inputBox.FocusLost:Connect (function (enterPressed)
				if enterPressed then submit () end
			end)
		)
		task.defer (function ()
			if inputBox and inputBox.Parent then inputBox:CaptureFocus () end
		end)
	end

	table.insert (
		connections,
		UserInputService.InputBegan:Connect (function (input)
			if input.KeyCode == Enum.KeyCode.Escape then
				dismiss ()
			elseif input.KeyCode == Enum.KeyCode.Return and not inputBox then
				submit ()
			end
		end)
	)

	return state
end

function Dex:ClosePrompt ()
	local prompt = self._prompt
	self._prompt = nil
	if prompt and prompt.Close then prompt.Close () end
end

function Dex:Confirm (title, message, onConfirm, confirmText)
	return self:Prompt ({
		Title = title,
		Message = message,
		Input = false,
		ConfirmText = confirmText or "OK",
		OnConfirm = function ()
			if onConfirm then onConfirm () end
		end,
	})
end

function Dex:Notify (message, kind)
	if not self.ScreenGui or not self.ScreenGui.Parent then return end

	if not self._toastHost or not self._toastHost.Parent then
		local host = U.Frame (self.ScreenGui, {
			Name = "ToastHost",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new (1, 1),
			Position = UDim2.new (1, -16, 1, -16),
			Size = UDim2.fromOffset (300, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 150000,
		})
		U.List (host, 6)
		local layout = host:FindFirstChildOfClass ("UIListLayout")
		if layout then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
		self._toastHost = host
	end

	local accent = Dex.Theme.Common.Accent
	if kind == "error" then
		accent = Dex.Theme.Common.Danger
	elseif kind == "success" then
		accent = Dex.Theme.Common.Success
	elseif kind == "warning" then
		accent = Dex.Theme.Common.Warning
	elseif kind == "info" then
		accent = Dex.Theme.Common.Info
	end

	local holder = U.Frame (self._toastHost, {
		Name = "ToastHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new (1, 0, 0, 38),
		ClipsDescendants = true,
		ZIndex = 150001,
	})
	local toast = U.Frame (holder, {
		Name = "Toast",
		BackgroundColor3 = Dex.Theme.Menu.Background,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 1, 0),
		ClipsDescendants = true,
		ZIndex = 150002,
	})
	U.Corner (toast, 4)
	U.Stroke (toast, accent, 1, 0.2)
	U.Frame (toast, {
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new (0, 3, 1, 0),
		ZIndex = 150002,
	})
	U.Label (toast, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (13, 0),
		Size = UDim2.new (1, -24, 1, 0),
		Font = Dex.Fonts.UI,
		Text = tostring (message),
		TextColor3 = Dex.Theme.Menu.Text,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 150002,
	})

	if TweenService then
		toast.Position = UDim2.new (1, 24, 0, 0)
		local okTween, tween = pcall (function ()
			return TweenService:Create (toast, TweenInfo.new (0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new (0, 0, 0, 0),
			})
		end)
		if okTween and tween then pcall (function ()
			tween:Play ()
		end) end
	end

	task.delay (kind == "error" and 4.2 or 2.6, function ()
		if not toast or not toast.Parent then return end
		if TweenService then
			local info = TweenInfo.new (0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			local okTween, tween = pcall (function ()
				return TweenService:Create (toast, info, {
					Position = UDim2.new (1, 24, 0, 0),
				})
			end)
			if okTween and tween then pcall (function ()
				tween:Play ()
			end) end
		end
		task.delay (0.3, function ()
			if holder and holder.Parent then holder:Destroy () end
		end)
	end)
end

do
	local camera = workspace.CurrentCamera
	if camera then
		Dex:Track (camera:GetPropertyChangedSignal ("ViewportSize"):Connect (function ()
			Dex.ViewportChanged:Fire (camera.ViewportSize)
		end))
	end
end

function Dex:AttachTooltip (gui, text)
	if not gui or not text or text == "" then return end
	local hovering = false
	local tip = nil
	local token = 0

	gui.MouseEnter:Connect (function ()
		hovering = true
		token = token + 1
		local current = token
		task.delay (0.5, function ()
			if tip then
				tip:Destroy ()
				tip = nil
			end
			if not hovering or current ~= token or not gui.Parent then return end
			local viewport = U.Viewport ()
			local fontSize = 12
			local width = math.min (260, U.TextWidth (text, fontSize, Dex.Fonts.UI) + 18)
			local height = 24
			local position = gui.AbsolutePosition + Vector2.new (0, gui.AbsoluteSize.Y + 4)
			if position.X + width > viewport.X - 4 then position = Vector2.new (viewport.X - width - 4, position.Y) end
			if position.Y + height > viewport.Y - 4 then
				position = Vector2.new (position.X, gui.AbsolutePosition.Y - height - 4)
			end
			tip = U.Frame (Dex.ScreenGui, {
				Name = "Tooltip",
				BackgroundColor3 = Dex.Theme.Menu.Background,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset (math.floor (position.X), math.floor (position.Y)),
				Size = UDim2.fromOffset (math.floor (width), height),
				ZIndex = 140000,
				Active = false,
			})
			U.Corner (tip, 3)
			U.Stroke (tip, Dex.Theme.Menu.Separator, 1, 0)
			U.Label (tip, {
				BackgroundTransparency = 1,
				Size = UDim2.new (1, -10, 1, 0),
				Position = UDim2.fromOffset (5, 0),
				Font = Dex.Fonts.UI,
				Text = text,
				TextColor3 = Dex.Theme.Menu.Text,
				TextSize = fontSize,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 140001,
			})
		end)
	end)

	gui.MouseLeave:Connect (function ()
		hovering = false
		token = token + 1
		if tip then
			tip:Destroy ()
			tip = nil
		end
	end)

	Dex:Track (gui.AncestryChanged:Connect (function (_, parent)
		if parent then return end
		hovering = false
		token += 1
		if tip then
			tip:Destroy ()
			tip = nil
		end
	end))
end

function Dex:CopyText (text)
	text = tostring (text)
	local copied = false
	if setclipboard then copied = pcall (setclipboard, text) end
	if not copied then copied = pcall (function ()
		toclipboard (text)
	end) end
	if copied then
		self.Clipboard = text
		return true
	end
	self.Clipboard = text
	local window = self.Windows.Clipboard
	if not window or window.Destroyed then
		window = self:CreateWindow ({
			Name = "Clipboard",
			Title = "Copy to Clipboard",
			Size = UDim2.fromOffset (420, 220),
			Position = UDim2.fromOffset (220, 220),
			MinSize = Vector2.new (260, 140),
			ContentColor = Dex.Theme.Output.Background,
			TitleBarColor3 = Dex.Theme.Output.TitleBar,
			BorderColor3 = Dex.Theme.Output.Border,
			TitleTextColor3 = Dex.Theme.Output.TitleText,
			AccentTransparency = 1,
			ContentBuilder = function (content, win)
				self.Windows.Clipboard = win
				local box = U.Textbox (content, {
					Name = "ClipboardBox",
					BackgroundColor3 = Dex.Theme.Output.CommandBackground,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset (6, 6),
					Size = UDim2.new (1, -12, 1, -12),
					Font = Dex.Fonts.Mono,
					Text = text,
					TextColor3 = Dex.Theme.Output.CommandText,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = false,
					ClearTextOnFocus = false,
					MultiLine = true,
					ZIndex = 2,
				})
				U.Corner (box, 4)
				win.ClipboardBox = box
			end,
		})
		self.Windows.Clipboard = window
	end
	if window.ClipboardBox then
		window.ClipboardBox.Text = text
		task.defer (function ()
			if window.ClipboardBox and window.ClipboardBox.Parent then
				window.ClipboardBox:CaptureFocus ()
				window.ClipboardBox.SelectionStart = 1
				window.ClipboardBox.CursorPosition = #text + 1
			end
		end)
	end
	window:Show ()
	window:Focus ()
	return false
end

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

local U = Dex.Utils
local UIS = UserInputService

local function normalizeLogHistory (result)
	if type (result) ~= "table" then return result end
	local normalized = {}
	for _, entry in ipairs (result) do
		if type (entry) == "table" then
			local message = entry.message or entry[1]
			local messageType = entry.messageType or entry[2]
			local timestamp = entry.timestamp or entry[3]
			local context = entry.context or entry[4]
			normalized[#normalized + 1] = {
				message = message,
				messageType = messageType,
				timestamp = timestamp,
				context = context,
			}
		end
	end
	return normalized
end

local logHistoryHooks = {}

local function installLogHistoryHooks ()
	if not LogService or type (hookfunction) ~= "function" then return end
	pcall (function ()
		local original = LogService.GetLogHistory
		if type (original) == "function" then
			local wrapper = function (self, ...)
				local results = table.pack (original (self, ...))
				results[1] = normalizeLogHistory (results[1])
				return table.unpack (results, 1, results.n)
			end
			local previous = hookfunction (original, wrapper)
			logHistoryHooks[#logHistoryHooks + 1] = {
				wrapper = wrapper,
				original = previous or original,
			}
		end
	end)
	pcall (function ()
		local original = LogService.GetLogHistoryAsync
		if type (original) == "function" then
			local wrapper = function (self, ...)
				local results = table.pack (original (self, ...))
				results[1] = normalizeLogHistory (results[1])
				return table.unpack (results, 1, results.n)
			end
			local previous = hookfunction (original, wrapper)
			logHistoryHooks[#logHistoryHooks + 1] = {
				wrapper = wrapper,
				original = previous or original,
			}
		end
	end)
end

installLogHistoryHooks ()

Dex._outputSignalToken = Dex._outputSignalToken or {}
local OutputSignalToken = Dex._outputSignalToken

local Output = {
	Entries = {},
	Filters = {
		output = true,
		info = true,
		warning = true,
		error = true,
	},
	Search = "",
	UseRegex = false,
	CaseSensitive = false,
	Limit = 3000,
	DisplayLimit = 1600,
	ShowTimestamps = true,
	CommandHistory = {},
	HistoryIndex = 0,
	Selected = nil,
	AutoScroll = true,
	LoadedHistory = false,
	_Pending = {},
	_FlushScheduled = false,
	_ClearStamp = 0,
}

Dex.Output = Output

function Output:UninstallLogHistoryHooks ()
	for _, hook in ipairs (logHistoryHooks) do
		pcall (function ()
			hookfunction (hook.wrapper, hook.original)
		end)
	end
	table.clear (logHistoryHooks)
end


local TypeInfo = {
	output = {
		Filter = "output",
		Label = "From Dex",
		ColorKey = "Text",
	},
	info = {
		Filter = "info",
		Label = "Info",
		ColorKey = "Info",
	},
	warning = {
		Filter = "warning",
		Label = "Warning",
		ColorKey = "Warning",
	},
	error = {
		Filter = "error",
		Label = "Error",
		ColorKey = "Error",
	},
	success = {
		Filter = "output",
		Label = "Success",
		ColorKey = "Success",
	},
	command = {
		Filter = "output",
		Label = "Command",
		ColorKey = "Info",
	},
}

local function classify (messageType)
	local messageTypes = Enum.MessageType
	if
		messageType == messageTypes.MessageError
		or messageType == messageTypes.MessageError.Value
		or messageType == "MessageError"
		or messageType == "Error"
	then
		return "error"
	elseif
		messageType == messageTypes.MessageWarning
		or messageType == messageTypes.MessageWarning.Value
		or messageType == "MessageWarning"
		or messageType == "Warning"
	then
		return "warning"
	elseif
		messageType == messageTypes.MessageInfo
		or messageType == messageTypes.MessageInfo.Value
		or messageType == "MessageInfo"
		or messageType == "Info"
	then
		return "info"
	end
	return "output"
end

local function timestampText (timestamp)
	local seconds = math.floor (timestamp)
	local millis = math.floor ((timestamp - seconds) * 1000)
	local date = os.date ("%H:%M:%S", seconds)
	return string.format ("%s.%03d", date, millis)
end

local function cleanMessage (text)
	text = tostring (text or "")
	text = text:gsub ("\r\n", "\n"):gsub ("\r", "\n")
	text = text:gsub ("[ \t]+\n", "\n")
	text = text:gsub ("^\n+", ""):gsub ("\n+$", "")
	if #text > 4000 then text = text:sub (1, 4000) .. "…" end
	return text
end

function Output:Matches (entry)
	local typeInfo = TypeInfo[entry.Kind] or TypeInfo.output
	local filter = entry.Source == "dex" and "output" or typeInfo.Filter
	if not self.Filters[filter] then return false end
	local query = self.Search
	if query ~= "" then
		local haystack = self.CaseSensitive and entry.Text or entry.Text:lower ()
		local pattern = self.CaseSensitive and query or query:lower ()
		if self.UseRegex then
			local ok, result = pcall (function ()
				return haystack:find (pattern)
			end)
			return ok and result ~= nil
		end
		return haystack:find (pattern, 1, true) ~= nil
	end
	return true
end

function Output:ScrollToBottom (force)
	local scroll = self.Scroll
	if not scroll then return end
	if not force and not self.AutoScroll then return end
	task.defer (function ()
		if not self.Scroll or not self.Scroll.Parent then return end
		local ok, canvas = pcall (function ()
			return scroll.AbsoluteCanvasSize.Y
		end)
		if not ok then return end
		local target = math.max (0, canvas - scroll.AbsoluteWindowSize.Y)
		scroll.CanvasPosition = Vector2.new (scroll.CanvasPosition.X, target)
		self.AutoScroll = true
	end)
end

function Output:RepaintRow (meta)
	if not meta or not meta.Row or not meta.Row.Parent then return end
	local selected = self.Selected == meta.Entry
	if selected then
		meta.Row.BackgroundColor3 = Dex.Theme.Output.Selection
		meta.Row.BackgroundTransparency = 0
	elseif meta.Hovered then
		meta.Row.BackgroundColor3 = Dex.Theme.Output.Toolbar
		meta.Row.BackgroundTransparency = 0.35
	else
		meta.Row.BackgroundColor3 = Dex.Theme.Output.Background
		meta.Row.BackgroundTransparency = 1
	end
end

function Output:Select (entry)
	local previous = self.Selected
	self.Selected = entry
	if previous and previous.RowMeta then self:RepaintRow (previous.RowMeta) end
	if entry and entry.RowMeta then self:RepaintRow (entry.RowMeta) end
end

function Output:SizeRow (meta)
	if not meta or not meta.Row or not meta.MessageLabel then return end
	local scrollWidth = self.Scroll and self.Scroll.AbsoluteSize.X or 0
	if scrollWidth <= 0 then scrollWidth = self.Scroll and self.Scroll.Size.X.Offset or 320 end
	local label = meta.MessageLabel
	local messageWidth = math.max (80, scrollWidth - 4 - (self.ShowTimestamps and 78 + 16 or 16))
	local font = label.Font
	local textSize = label.TextSize
	local ok, measured = pcall (function ()
		return TextService:GetTextSize (meta.Entry.Text, textSize, font, Vector2.new (messageWidth, 100000))
	end)
	local textHeight = ok and measured and measured.Y or 19
	local height = math.max (19, math.ceil (textHeight) + 8)
	meta.Row.Size = UDim2.new (1, -4, 0, height)
	label.Size = UDim2.new (1, -(self.ShowTimestamps and 78 + 24 or 24), 1, -8)
	if meta.TimeLabel then meta.TimeLabel.Size = UDim2.fromOffset (78, 19) end
end

function Output:RefreshRowSizes ()
	for _, entry in ipairs (self.RowList or {}) do
		if entry.RowMeta then self:SizeRow (entry.RowMeta) end
	end
end

function Output:CreateRow (entry)
	if not self.RowList then return end
	if #self.RowList >= self.DisplayLimit then
		local oldest = table.remove (self.RowList, 1)
		if oldest and oldest.RowMeta then
			if self.Selected == oldest then self.Selected = nil end
			oldest.RowMeta.Row:Destroy ()
			oldest.RowMeta = nil
		end
	end

	local row = U.Button (self.Scroll, {
		Name = "OutputLine",
		BackgroundColor3 = Dex.Theme.Output.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new (1, -4, 0, 19),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})
	row.ClipsDescendants = true

	local typeInfo = TypeInfo[entry.Kind] or TypeInfo.output
	local timeLabel
	if self.ShowTimestamps then
		timeLabel = U.Label (row, {
			Name = "Time",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset (8, 4),
			Size = UDim2.fromOffset (78, 19),
			Font = Dex.Fonts.Mono,
			Text = entry.TimeText,
			TextColor3 = Dex.Theme.Output.Timestamp,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
			Active = false,
		})
	end

	local messageLabel = U.Label (row, {
		Name = "Message",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (self.ShowTimestamps and 78 + 12 or 8, 4),
		Size = UDim2.new (1, -(self.ShowTimestamps and 78 + 24 or 24), 1, -8),
		Font = Dex.Fonts.Mono,
		Text = entry.Text,
		TextColor3 = Dex.Theme.Output[typeInfo.ColorKey or "Text"],
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 3,
		Active = false,
	})

	local meta = {
		Row = row,
		TimeLabel = timeLabel,
		MessageLabel = messageLabel,
		Entry = entry,
		Hovered = false,
	}
	entry.RowMeta = meta
	self.RowList[#self.RowList + 1] = entry
	self:SizeRow (meta)

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
		self:Select (entry)
	end)
	row.MouseButton2Click:Connect (function ()
		self.Window:Focus ()
		self:Select (entry)
		self:ShowLineMenu (entry, U.MousePoint ())
	end)

	if self.Selected == entry then self:RepaintRow (meta) end
	return row
end

function Output:AppendEntry (entry)
	self.Entries[#self.Entries + 1] = entry
	if #self.Entries > self.Limit then
		local removed = table.remove (self.Entries, 1)
		if removed and removed.RowMeta then
			if self.Selected == removed then self.Selected = nil end
			removed.RowMeta.Row:Destroy ()
			removed.RowMeta = nil
		end
	end
	if self:Matches (entry) then
		self:CreateRow (entry)
		if self.AutoScroll then self:ScrollToBottom () end
	end
	self:UpdateCount ()
end

function Output:FlushPending ()
	self._FlushScheduled = false
	local pending = self._Pending
	self._Pending = {}
	if not self.Scroll or not self.Scroll.Parent then return end
	if not self.Window or not self.Window.GUI or not self.Window.GUI.Parent then return end
	for _, entry in ipairs (pending) do
		self:AppendEntry (entry)
	end
	if #pending > 0 then
		self:UpdateCount ()
		self:UpdateEmpty ()
	end
end

function Output:QueueEntry (text, kind, timestamp, context)
	local time = timestamp or os.time ()
	local entry = {
		Text = cleanMessage (text),
		Kind = kind or "output",
		Context = context,
		Source = "console",
		Timestamp = time,
		TimeText = timestampText (time),
	}
	self._Pending[#self._Pending + 1] = entry
	if not self._FlushScheduled then
		self._FlushScheduled = true
		task.delay (0.05, function ()
			self:FlushPending ()
		end)
	end
end

function Output:AddLocal (text, kind)
	if not self.RowList or not self.Scroll then return end
	local time = os.time ()
	self:AppendEntry ({
		Text = cleanMessage (text),
		Kind = kind or "output",
		Source = "dex",
		Timestamp = time,
		TimeText = timestampText (time),
	})
	self:ScrollToBottom ()
end

function Output:UpdateCount ()
	if not self.CountLabel then return end
	local count = #self.Entries
	self.CountLabel.Text = tostring (count) .. (count == 1 and " message" or " messages")
end

function Output:Rebuild ()
	if not self.Scroll or not self.Scroll.Parent then return end
	if not self.Window or not self.Window.GUI or not self.Window.GUI.Parent then return end
	for _, entry in ipairs (self.Entries) do
		entry.RowMeta = nil
	end
	self.RowList = {}
	self.Selected = nil
	U.ClearChildren (self.Scroll)
	for _, entry in ipairs (self.Entries) do
		if self:Matches (entry) then self:CreateRow (entry) end
	end
	self:UpdateCount ()
	self:UpdateEmpty ()
	if self.AutoScroll then self:ScrollToBottom (true) end
end

function Output:Clear ()
	self._ClearStamp = os.time ()
	self.Entries = {}
	self.RowList = {}
	self.Selected = nil
	self._Pending = {}
	if self.Scroll then U.ClearChildren (self.Scroll) end
	self.AutoScroll = true
	self:UpdateCount ()
	self:UpdateEmpty ()
end

function Output:CopyEntry (entry)
	if not entry then return end
	Dex:CopyText (entry.Text)
end

function Output:CopyAll ()
	local lines = {}
	for _, entry in ipairs (self.Entries) do
		if self:Matches (entry) then
			lines[#lines + 1] = (self.ShowTimestamps and (entry.TimeText .. "  ") or "") .. entry.Text
		end
	end
	if #lines == 0 then return end
	Dex:CopyText (table.concat (lines, "\n"))
	Dex:Notify ("Copied " .. tostring (#lines) .. " lines", "success")
end

function Output:ShowLineMenu (entry, position)
	Dex:ShowMenu ({
		{
			Text = "Copy Line",
			Callback = function ()
				self:CopyEntry (entry)
			end,
		},
		{
			Text = "Copy All",
			Callback = function ()
				self:CopyAll ()
			end,
		},
		{ Separator = true },
		{
			Text = "Clear Output",
			Callback = function ()
				self:Clear ()
			end,
		},
	}, position or U.MousePoint ())
end

function Output:ShowFilterMenu ()
	local items = {}
	local order = {
		{ Key = "output", Text = "From Dex" },
		{ Key = "info", Text = "Info" },
		{ Key = "warning", Text = "Warning" },
		{ Key = "error", Text = "Error" },
	}
	for _, option in ipairs (order) do
		items[#items + 1] = {
			Text = option.Text,
			Checked = self.Filters[option.Key] == true,
			Callback = function ()
				self.Filters[option.Key] = not self.Filters[option.Key]
				self:Rebuild ()
			end,
		}
	end
	Dex:ShowMenu (items, U.MousePoint ())
end

function Output:ShowOptionsMenu ()
	local items = {
		{
			Text = "Show Timestamps",
			Checked = self.ShowTimestamps,
			Callback = function ()
				self.ShowTimestamps = not self.ShowTimestamps
				Dex:SetConfig ("ShowTimestamps", self.ShowTimestamps)
				self:Rebuild ()
			end,
		},
		{
			Text = "Command Bar",
			Checked = self.CommandBar and self.CommandBar.Visible,
			Callback = function ()
				self:SetCommandBarVisible (not (self.CommandBar and self.CommandBar.Visible))
			end,
		},
		{ Separator = true },
		{
			Text = "Console Detection Bypass",
			Checked = Dex.ConsoleBypass and Dex.ConsoleBypass.Enabled or false,
			Callback = function ()
				if Dex.ConsoleBypass then
					Dex.ConsoleBypass:Toggle ()
					Dex:SetConfig ("ConsoleDetection", Dex.ConsoleBypass.Enabled)
				else
					Dex:Notify ("Console bypass unavailable", "error")
				end
			end,
		},
		{ Separator = true },
		{
			Text = "Clear Output",
			Callback = function ()
				self:Clear ()
			end,
		},
		{
			Text = "Copy All",
			Callback = function ()
				self:CopyAll ()
			end,
		},
	}
	Dex:ShowMenu (items, U.MousePoint ())
end

function Output:SetCommandBarVisible (visible)
	visible = visible ~= false
	if not self.CommandBar then return end
	self.CommandBar.Visible = visible
	self.CommandVisible = visible
	self:Layout ()
	if visible and self.CommandBox then
		task.defer (function ()
			if self.CommandBox and self.CommandBox.Parent then self.CommandBox:CaptureFocus () end
		end)
	end
end

function Output:Layout ()
	if not self.Scroll then return end
	local top = 34
	local commandVisible = self.CommandBar and self.CommandBar.Visible
	local footer = commandVisible and 20 or 0
	local bottom = (commandVisible and 30 or 0) + footer
	self.Scroll.Position = UDim2.fromOffset (0, top)
	self.Scroll.Size = UDim2.new (1, -12, 1, -(top + bottom))
	if self.StatusBar then
		self.StatusBar.Position = UDim2.new (0, 0, 1, -(30 + 20))
		self.StatusBar.Visible = commandVisible == true
	end
	if self.CommandBar then self.CommandBar.Position = UDim2.new (0, 0, 1, -30) end
	if self.EmptyLabel then
		self.EmptyLabel.Position = UDim2.fromOffset (0, top)
		self.EmptyLabel.Size = UDim2.new (1, 0, 1, -(top + bottom))
	end
end

function Output:RunCommand (text)
	text = tostring (text or ""):gsub ("^%s+", ""):gsub ("%s+$", "")
	if text == "" then return end
	self:AddLocal ("> " .. text, "command")

	if #self.CommandHistory == 0 or self.CommandHistory[#self.CommandHistory] ~= text then
		self.CommandHistory[#self.CommandHistory + 1] = text
		while #self.CommandHistory > 40 do
			table.remove (self.CommandHistory, 1)
		end
	end
	self.HistoryIndex = #self.CommandHistory + 1
	Dex.CommandHistory = self.CommandHistory

	local execute = rawget (genv, "loadstring") or loadstring
	if type (execute) ~= "function" then
		self:AddLocal ("loadstring is not available in this environment", "error")
		return
	end

	local chunk, compileError = execute (text)
	if not chunk then
		local expression = execute ("return " .. text)
		if expression then
			chunk = expression
		else
			self:AddLocal (compileError or "compile error", "error")
			return
		end
	end

	local results = table.pack (pcall (chunk))
	if not results[1] then
		self:AddLocal (tostring (results[2]), "error")
		return
	end
	for index = 2, results.n do
		local value = results[index]
		self:AddLocal (typeof (value) == "string" and value or U.Pretty (value), "success")
	end
end

function Output:UseHistory (direction)
	if #self.CommandHistory == 0 or not self.CommandBox then return end
	if direction < 0 then
		if self.HistoryIndex > 1 then self.HistoryIndex = self.HistoryIndex - 1 end
	else
		if self.HistoryIndex < #self.CommandHistory then
			self.HistoryIndex = self.HistoryIndex + 1
		else
			self.HistoryIndex = #self.CommandHistory + 1
			self.CommandBox.Text = ""
			return
		end
	end
	self.CommandBox.Text = self.CommandHistory[self.HistoryIndex] or ""
	self.CommandBox.CursorPosition = #self.CommandBox.Text + 1
end

function Output:LoadHistory ()
	if self.LoadedHistory or not LogService then return end
	self.LoadedHistory = true
	local ok, history = pcall (function ()
		return LogService:GetLogHistory ()
	end)
	if not ok or type (history) ~= "table" then return end
	local start = math.max (1, #history - 799)
	for index = start, #history do
		local item = history[index]
		if type (item) == "table" and item.message and (item.timestamp or 0) >= self._ClearStamp then
			local timestamp = tonumber (item.timestamp) or os.time ()
			self:QueueEntry (item.message, classify (item.messageType), timestamp)
		end
	end
end

function Output:FocusSearch ()
	if self.Window then self.Window:Focus () end
	if self.SearchBox then self.SearchBox:CaptureFocus () end
end

function Output:_handleMessageOut (message, messageType)
	local kind = classify (messageType)
	self:QueueEntry (message, kind, os.time ())
	self:UpdateEmpty ()
end

function Output:ConnectMessageOut (signal, bypassOnly)
	local callback = function (message, messageType)
		self:_handleMessageOut (message, messageType)
	end
	local connection = nil
	if bypassOnly then
		local bypass = Dex and Dex.ConsoleBypass
		if bypass and type (bypass.ConnectOutput) == "function" then
			pcall (function ()
				connection = bypass:ConnectOutput (OutputSignalToken, callback)
			end)
		end
		self.BypassMessageOutConnection = connection
		return
	end
	if not signal then return end
	connection = signal:Connect (callback)
	self.MessageOutConnection = connection
	Dex:Track (connection)
end

function Output:OnConsoleBypassEnabled ()
	if self.BypassMessageOutConnection then return end
	self:ConnectMessageOut (nil, true)
end

function Output:OnConsoleBypassDisabled ()
	if self.BypassMessageOutConnection then
		pcall (function ()
			self.BypassMessageOutConnection:Disconnect ()
		end)
		self.BypassMessageOutConnection = nil
	end
end

function Output:Build (content)
	self.Content = content
	self.Entries = {}
	self.RowList = {}
	self.Selected = nil

	local toolbar = U.Frame (content, {
		Name = "Toolbar",
		BackgroundColor3 = Dex.Theme.Output.Toolbar,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 34),
		ZIndex = 2,
	})
	U.Frame (toolbar, {
		BackgroundColor3 = Dex.Theme.Output.ToolbarBorder,
		BorderSizePixel = 0,
		Position = UDim2.new (0, 0, 1, -1),
		Size = UDim2.new (1, 0, 0, 1),
		ZIndex = 3,
	})

	local filterButton = U.Button (toolbar, {
		Name = "Filter",
		BackgroundColor3 = Dex.Theme.Output.FilterBackground,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (8, 6),
		Size = UDim2.fromOffset (72, 22),
		Font = Dex.Fonts.UIMedium,
		Text = "Filters  ▾",
		TextColor3 = Dex.Theme.Output.Text,
		TextSize = 12,
		ZIndex = 3,
	})
	U.Corner (filterButton, 4)
	U.Stroke (filterButton, Dex.Theme.Output.FilterBorder, 1, 0)
	filterButton.MouseEnter:Connect (function ()
		filterButton.BackgroundColor3 = Dex.Theme.Output.ControlHover
	end)
	filterButton.MouseLeave:Connect (function ()
		filterButton.BackgroundColor3 = Dex.Theme.Output.FilterBackground
	end)
	filterButton.MouseButton1Click:Connect (function ()
		self:ShowFilterMenu ()
	end)
	Dex:AttachTooltip (filterButton, "Filter output")

	local searchHolder = U.Frame (toolbar, {
		Name = "SearchHolder",
		BackgroundColor3 = Dex.Theme.Output.FilterBackground,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (88, 6),
		Size = UDim2.new (1, -126, 0, 22),
		ZIndex = 3,
	})
	U.Corner (searchHolder, 4)
	local searchStroke = U.Stroke (searchHolder, Dex.Theme.Output.FilterBorder, 1, 0)

	local buttonHolder = U.Frame (searchHolder, {
		Name = "SearchButtons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -2, 0, 0),
		Size = UDim2.new (0, 60, 1, 0),
		ZIndex = 4,
	})
	local buttonLayout = U.List (buttonHolder, 2, true)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	self.SearchButtonsHolder = buttonHolder

	local searchBox = U.Textbox (searchHolder, {
		Name = "Search",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (8, 0),
		Size = UDim2.new (1, -80, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "",
		PlaceholderText = "Filter output",
		PlaceholderColor3 = Dex.Theme.Output.Timestamp,
		TextColor3 = Dex.Theme.Output.Text,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		ZIndex = 4,
	})
	self.SearchBox = searchBox

	local function searchToggle (text, order, tooltip, getter, setter)
		local btn = U.Button (buttonHolder, {
			Name = tooltip,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset (18, 18),
			LayoutOrder = order,
			Font = Dex.Fonts.UIMedium,
			Text = text,
			TextColor3 = getter () and Dex.Theme.Output.Info or Dex.Theme.Output.Timestamp,
			TextSize = 11,
			ZIndex = 4,
		})
		local function paint ()
			btn.BackgroundTransparency = getter () and 0 or 1
			btn.BackgroundColor3 = Dex.Theme.Output.ControlHover
			btn.TextColor3 = getter () and Dex.Theme.Output.Info or Dex.Theme.Output.Timestamp
		end
		paint ()
		btn.MouseEnter:Connect (function ()
			btn.BackgroundTransparency = 0
			btn.BackgroundColor3 = Dex.Theme.Output.ControlHover
		end)
		btn.MouseLeave:Connect (function ()
			paint ()
		end)
		btn.MouseButton1Click:Connect (function ()
			setter (not getter ())
			paint ()
			self:Rebuild ()
		end)
		Dex:AttachTooltip (btn, tooltip)
		return btn
	end
	searchToggle (".*", 1, "Use regex", function ()
		return self.UseRegex
	end, function (v)
		self.UseRegex = v
	end)
	searchToggle ("Aa", 2, "Match case", function ()
		return self.CaseSensitive
	end, function (v)
		self.CaseSensitive = v
	end)

	local clearSearch = U.Button (buttonHolder, {
		Name = "ClearSearch",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset (18, 18),
		LayoutOrder = 3,
		Text = "",
		Visible = false,
		ZIndex = 4,
	})
	U.DrawX (clearSearch, 6, Dex.Theme.Output.Timestamp)
	self.ClearSearchButton = clearSearch
	function self:SetClearSearchButtonVisible (visible)
		if not self.ClearSearchButton then return end
		self.ClearSearchButton.Visible = visible == true
		self.ClearSearchButton.Parent = visible and self.SearchButtonsHolder or nil
	end
	clearSearch.MouseEnter:Connect (function ()
		clearSearch.BackgroundTransparency = 0
		clearSearch.BackgroundColor3 = Dex.Theme.Output.ControlHover
	end)
	clearSearch.MouseLeave:Connect (function ()
		clearSearch.BackgroundTransparency = 1
	end)
	clearSearch.MouseButton1Click:Connect (function ()
		self.SearchBox.Text = ""
		searchBox:CaptureFocus ()
	end)

	local optionsButton = U.Button (toolbar, {
		Name = "Options",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, -6, 0, 6),
		Size = UDim2.fromOffset (26, 22),
		Font = Dex.Fonts.UIBold,
		Text = "···",
		TextColor3 = Dex.Theme.Output.Timestamp,
		TextSize = 14,
		ZIndex = 3,
	})
	U.Corner (optionsButton, 4)
	optionsButton.MouseEnter:Connect (function ()
		optionsButton.BackgroundTransparency = 0
		optionsButton.BackgroundColor3 = Dex.Theme.Output.ControlHover
		optionsButton.TextColor3 = Dex.Theme.Output.Text
	end)
	optionsButton.MouseLeave:Connect (function ()
		optionsButton.BackgroundTransparency = 1
		optionsButton.TextColor3 = Dex.Theme.Output.Timestamp
	end)
	optionsButton.MouseButton1Click:Connect (function ()
		self:ShowOptionsMenu ()
	end)
	Dex:AttachTooltip (optionsButton, "Output options")

	searchBox.Focused:Connect (function ()
		searchStroke.Color = Dex.Theme.Common.BlueSoft
		self.Window:Focus ()
	end)
	searchBox.FocusLost:Connect (function ()
		searchStroke.Color = Dex.Theme.Output.FilterBorder
	end)
	searchBox:GetPropertyChangedSignal ("Text"):Connect (function ()
		local text = searchBox.Text
		self:SetClearSearchButtonVisible (text ~= "")
		self.Search = text
		self._SearchToken = (self._SearchToken or 0) + 1
		local token = self._SearchToken
		task.delay (0.12, function ()
			if token == self._SearchToken then self:Rebuild () end
		end)
	end)

	local scroll = U.Scroll (content, {
		Name = "Log",
		BackgroundColor3 = Dex.Theme.Output.Background,
		BackgroundTransparency = 0,
		Position = UDim2.fromOffset (0, 34),
		Size = UDim2.new (1, -12, 1, -34),
		CanvasSize = UDim2.new (0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Dex.Theme.Output.ScrollBar,
		ScrollBarImageTransparency = 0.2,
		ZIndex = 2,
	})
	self.Scroll = scroll
	local layout = U.Create ("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new (0, 0),
		Parent = scroll,
	})

	scroll:GetPropertyChangedSignal ("CanvasPosition"):Connect (function ()
		local ok, canvas = pcall (function ()
			return scroll.AbsoluteCanvasSize.Y
		end)
		if ok then self.AutoScroll = scroll.CanvasPosition.Y + scroll.AbsoluteWindowSize.Y >= canvas - 28 end
	end)

	local empty = U.Label (content, {
		Name = "Empty",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (0, 34),
		Size = UDim2.new (1, 0, 1, -34),
		Font = Dex.Fonts.UI,
		Text = "",
		TextColor3 = Dex.Theme.Output.Timestamp,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = false,
		ZIndex = 3,
		Active = false,
	})
	self.EmptyLabel = empty

	local status = U.Frame (content, {
		Name = "Status",
		BackgroundTransparency = 1,
		Position = UDim2.new (0, 0, 1, -30 - 20),
		Size = UDim2.new (1, 0, 0, 20),
		Visible = false,
		ZIndex = 3,
	})
	self.StatusBar = status
	self.CountLabel = U.Label (status, {
		Name = "Count",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (10, 0),
		Size = UDim2.new (1, -20, 1, 0),
		Font = Dex.Fonts.UI,
		Text = "0 messages",
		TextColor3 = Dex.Theme.Output.Timestamp,
		TextSize = 11,
		ZIndex = 4,
		Active = false,
	})

	local commandBar = U.Frame (content, {
		Name = "CommandBar",
		BackgroundColor3 = Dex.Theme.Output.CommandBackground,
		BorderSizePixel = 0,
		Position = UDim2.new (0, 0, 1, -30),
		Size = UDim2.new (1, 0, 0, 30),
		ZIndex = 10,
	})
	self.CommandBar = commandBar
	self.CommandVisible = true
	U.Frame (commandBar, {
		BackgroundColor3 = Dex.Theme.Output.ToolbarBorder,
		BorderSizePixel = 0,
		Position = UDim2.new (0, 0, 0, 0),
		Size = UDim2.new (1, 0, 0, 1),
		ZIndex = 11,
	})
	U.Label (commandBar, {
		Name = "Prompt",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (10, 0),
		Size = UDim2.fromOffset (14, 30),
		Font = Dex.Fonts.Mono,
		Text = ">",
		TextColor3 = Dex.Theme.Output.Info,
		TextSize = 14,
		ZIndex = 12,
		Active = false,
	})
	local commandBox = U.Textbox (commandBar, {
		Name = "Command",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (26, 0),
		Size = UDim2.new (1, -140, 1, 0),
		Font = Dex.Fonts.Mono,
		Text = "",
		PlaceholderText = "Run a command...",
		PlaceholderColor3 = Dex.Theme.Output.Timestamp,
		TextColor3 = Dex.Theme.Output.CommandText,
		TextSize = 13,
		ClearTextOnFocus = false,
		ZIndex = 12,
	})
	self.CommandBox = commandBox

	commandBox.FocusLost:Connect (function (enterPressed)
		if enterPressed then
			local text = commandBox.Text
			commandBox.Text = ""
			self:RunCommand (text)
		end
	end)
	commandBox.Focused:Connect (function ()
		self.Window:Focus ()
	end)
	commandBox:GetPropertyChangedSignal ("Text"):Connect (function ()
		if commandBox.Text ~= "" and self.HistoryIndex ~= #self.CommandHistory + 1 then
			self.HistoryIndex = #self.CommandHistory + 1
		end
	end)

	local runButton = U.Button (commandBar, {
		Name = "Run",
		BackgroundColor3 = Dex.Theme.Output.Control,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new (1, 0.5),
		Position = UDim2.new (1, -8, 0.5, 0),
		Size = UDim2.fromOffset (46, 20),
		Font = Dex.Fonts.UIMedium,
		Text = "Run",
		TextColor3 = Dex.Theme.Output.Text,
		TextSize = 12,
		ZIndex = 12,
	})
	U.Corner (runButton, 4)
	U.Stroke (runButton, Dex.Theme.Output.ControlBorder, 1, 0)
	runButton.MouseEnter:Connect (function ()
		runButton.BackgroundColor3 = Dex.Theme.Output.ControlHover
	end)
	runButton.MouseLeave:Connect (function ()
		runButton.BackgroundColor3 = Dex.Theme.Output.Control
	end)
	runButton.MouseButton1Click:Connect (function ()
		local text = commandBox.Text
		commandBox.Text = ""
		self:RunCommand (text)
	end)

	local function refreshTheme ()
		toolbar.BackgroundColor3 = Dex.Theme.Output.Toolbar
		searchHolder.BackgroundColor3 = Dex.Theme.Output.FilterBackground
		searchStroke.Color = Dex.Theme.Output.FilterBorder
		searchBox.TextColor3 = Dex.Theme.Output.Text
		searchBox.PlaceholderColor3 = Dex.Theme.Output.Timestamp
		filterButton.BackgroundColor3 = Dex.Theme.Output.FilterBackground
		filterButton.TextColor3 = Dex.Theme.Output.Text
		optionsButton.TextColor3 = Dex.Theme.Output.Timestamp
		scroll.BackgroundColor3 = Dex.Theme.Output.Background
		scroll.ScrollBarImageColor3 = Dex.Theme.Output.ScrollBar
		commandBar.BackgroundColor3 = Dex.Theme.Output.CommandBackground
		commandBox.TextColor3 = Dex.Theme.Output.CommandText
		runButton.BackgroundColor3 = Dex.Theme.Output.Control
		runButton.TextColor3 = Dex.Theme.Output.Text
		self.CountLabel.TextColor3 = Dex.Theme.Output.Timestamp
	end
	Dex:Track (Dex.ThemeChanged:Connect (function ()
		if self.Window and self.Window.Visible then refreshTheme () end
	end))
	refreshTheme ()

	self.Window:OnShow (function ()
		self:LoadHistory ()
		self:Layout ()
		self:UpdateCount ()
	end)
	self.Window:OnResize (function ()
		task.defer (function ()
			self:Layout ()
			self:RefreshRowSizes ()
		end)
	end)

	self:LoadHistory ()
	self:Layout ()
	self:RefreshRowSizes ()
	self:UpdateCount ()
	self:UpdateEmpty ()

	if LogService then self:ConnectMessageOut (LogService.MessageOut, false) end

	Dex:Track (UIS.InputBegan:Connect (function (input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if Dex.ActiveWindow ~= self.Window or not self.Window.Visible then return end
		local focused = UIS:GetFocusedTextBox ()
		if focused == commandBox then
			if input.KeyCode == Enum.KeyCode.Up then
				self:UseHistory (-1)
			elseif input.KeyCode == Enum.KeyCode.Down then
				self:UseHistory (1)
			end
			return
		end
		if focused then return end
		local ctrl = UIS:IsKeyDown (Enum.KeyCode.LeftControl) or UIS:IsKeyDown (Enum.KeyCode.RightControl)
		local shift = UIS:IsKeyDown (Enum.KeyCode.LeftShift) or UIS:IsKeyDown (Enum.KeyCode.RightShift)
		if ctrl and input.KeyCode == Enum.KeyCode.F then
			self:FocusSearch ()
		elseif ctrl and shift and input.KeyCode == Enum.KeyCode.C then
			if self.Selected then
				self:CopyEntry (self.Selected)
			else
				self:CopyAll ()
			end
		elseif ctrl and input.KeyCode == Enum.KeyCode.L then
			self:Clear ()
		elseif input.KeyCode == Enum.KeyCode.F4 then
			self:SetCommandBarVisible (not self.CommandVisible)
		end
	end))
end

function Output:UpdateEmpty ()
	if not self.EmptyLabel then return end
	local visibleCount = 0
	for _, entry in ipairs (self.Entries) do
		if self:Matches (entry) then
			visibleCount = visibleCount + 1
			break
		end
	end
	local show = visibleCount == 0
	self.EmptyLabel.Visible = show
	if show then
		if #self.Entries == 0 then
			self.EmptyLabel.Text = "Output is empty"
		else
			self.EmptyLabel.Text = "No messages match the current filter"
		end
	end
end

function Output:Create ()
	local window = Dex:CreateWindow ({
		Name = "Output",
		Title = "Output",
		Size = UDim2.fromOffset (560, 300),
		Position = UDim2.fromOffset (360, 620),
		MinSize = Vector2.new (320, 160),
		SnapBottom = true,
		DockRightWindow = "Properties",
		ContentColor = Dex.Theme.Output.Background,
		TitleBarColor3 = Dex.Theme.Output.TitleBar,
		BorderColor3 = Dex.Theme.Output.Border,
		TitleTextColor3 = Dex.Theme.Output.TitleText,
		AccentTransparency = 1,
		ShowAccentLine = false,
		ContentBuilder = function (content, window)
			self.Window = window
			self:Build (content)
		end,
	})
	self.Window = window
	self.CommandHistory = Dex.CommandHistory or {}
	self.HistoryIndex = #self.CommandHistory + 1
	return window
end

local U = Dex.Utils
local UIS = UserInputService

local Launcher = {
	Size = 46,
	Dragging = false,
	Moved = false,
}

Dex.Launcher = Launcher

local function clamp (value, minimum, maximum)
	return math.max (minimum, math.min (maximum, value))
end

local RestingStroke = Dex.hex ("c0c0c0")

function Launcher:ShowMenu ()
	local gui = self.GUI
	if not gui then return end
	local position = Vector2.new (gui.AbsolutePosition.X, gui.AbsolutePosition.Y + gui.AbsoluteSize.Y + 6)
	local items = {}

	items[#items + 1] = {
		Text = "Dex — Studio Edition",
		Enabled = false,
	}
	items[#items + 1] = { Separator = true }

	for _, name in ipairs ({ "Explorer", "Properties", "Output", "Notepad" }) do
		local window = Dex.Windows[name]
		items[#items + 1] = {
			Text = name,
			KeepOpen = true,
			Checked = function ()
				if name == "Notepad" then return Dex.Windows.Notepad and Dex.Windows.Notepad.Visible or false end
				return window and window.Visible or false
			end,
			Callback = function ()
				if name == "Notepad" then
					Dex:ToggleNotepad ()
				elseif window then
					window:Toggle ()
				end
			end,
		}
	end

	items[#items + 1] = { Separator = true }
	items[#items + 1] = {
		Text = "Show All Windows",
		KeepOpen = true,
		Callback = function ()
			if Dex.ShowNotepad then Dex:ShowNotepad () end
			for _, window in pairs (Dex.Windows) do
				if window and not window.Destroyed then window:Show () end
			end
			if Dex.Windows.Explorer then Dex.Windows.Explorer:Focus () end
		end,
	}
	items[#items + 1] = {
		Text = "Reset Layout",
		KeepOpen = true,
		Callback = function ()
			Launcher:SetDefaultPosition ()
			if Dex.SetLayout then Dex:SetLayout () end
		end,
	}
	items[#items + 1] = { Separator = true }
	local themeSubmenu = {}
	local themeNames = {}
	for name in pairs (Dex.ThemePresets) do
		themeNames[#themeNames + 1] = name
	end
	table.sort (themeNames)
	for _, name in ipairs (themeNames) do
		local themeName = name
		themeSubmenu[#themeSubmenu + 1] = {
			Text = name,
			Checked = function ()
				return Dex.CurrentTheme == themeName
			end,
			Callback = function ()
				Dex:ApplyTheme (themeName)
			end,
		}
	end
	items[#items + 1] = {
		Text = "Themes",
		Submenu = themeSubmenu,
	}
	items[#items + 1] = { Separator = true }
	items[#items + 1] = {
		Text = "Performance Mode",
		KeepOpen = true,
		Checked = function ()
			return Dex.PerformanceMode == true
		end,
		Callback = function ()
			Dex.PerformanceMode = not Dex.PerformanceMode
			Dex:SetConfig ("PerformanceMode", Dex.PerformanceMode)
			if Dex.Explorer and Dex.Explorer.ApplyPerformanceMode then Dex.Explorer:ApplyPerformanceMode () end
		end,
	}
	items[#items + 1] = { Separator = true }

	items[#items + 1] = {
		Text = "Destroy Dex",
		KeepOpen = true,
		Callback = function ()
			Dex:Destroy ()
		end,
	}

	Dex:ShowMenu (items, position)
end

function Launcher:SetDefaultPosition ()
	if not self.GUI then return end
	local viewport = U.Viewport ()
	self.GUI.Position = UDim2.fromOffset (math.max (10, math.floor (viewport.X / 2 - self.Size / 2)), 12)
end

function Launcher:Create ()
	if self.GUI then return self.GUI end

	local gui = U.Button (Dex.ScreenGui, {
		Name = "DexLauncher",
		BackgroundColor3 = Dex.hex ("1a1a1f"),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset (14, 12),
		Size = UDim2.fromOffset (self.Size, self.Size),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 5000,
		Active = true,
	})
	U.Corner (gui, 11)
	local stroke = U.Stroke (gui, RestingStroke, 1.5, 0.15)

	local letter = U.Label (gui, {
		Name = "Letter",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new (0.5, 0.5),
		Position = UDim2.fromScale (0.5, 0.47),
		Size = UDim2.fromScale (1, 1),
		Font = Dex.Fonts.UIBold,
		Text = "D",
		TextColor3 = Dex.hex ("ffffff"),
		TextSize = 25,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 5003,
		Active = false,
	})
	local gradient = U.Create ("UIGradient", {
		Color = ColorSequence.new ({
			ColorSequenceKeypoint.new (0, Dex.hex ("b366ff")),
			ColorSequenceKeypoint.new (0.55, Dex.hex ("c0c0c0")),
			ColorSequenceKeypoint.new (1, Dex.hex ("80d7ff")),
		}),
		Rotation = 55,
		Parent = letter,
	})

	local badge = U.Frame (gui, {
		Name = "Badge",
		BackgroundColor3 = Dex.hex ("c0c0c0"),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new (1, 0),
		Position = UDim2.new (1, 2, 0, 2),
		Size = UDim2.fromOffset (8, 8),
		ZIndex = 5004,
		Active = false,
	})
	U.Corner (badge, 99)
	U.Stroke (badge, Dex.hex ("1a1a1f"), 2, 0)

	self.GUI = gui
	self.Letter = letter
	self.Stroke = stroke

	gui.MouseEnter:Connect (function ()
		stroke.Color = Dex.hex ("b366ff")
	end)
	gui.MouseLeave:Connect (function ()
		if self.Dragging then return end
		stroke.Color = RestingStroke
	end)

	gui.MouseButton2Click:Connect (function ()
		self:ShowMenu ()
	end)

	gui.InputBegan:Connect (function (input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		self.Dragging = true
		self.Moved = false
		self.TouchDrag = input.UserInputType == Enum.UserInputType.Touch
		self.DragStart = self.TouchDrag and Vector2.new (input.Position.X, input.Position.Y) or U.MousePoint ()
		self.StartPosition = gui.Position
	end)

	Dex:Track (UIS.InputChanged:Connect (function (input)
		if not self.Dragging then return end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		local point = self.TouchDrag and Vector2.new (input.Position.X, input.Position.Y) or U.MousePoint ()
		local delta = point - self.DragStart
		if math.abs (delta.X) > 3 or math.abs (delta.Y) > 3 then self.Moved = true end
		local viewport = U.Viewport ()
		gui.Position = UDim2.fromOffset (
			clamp (self.StartPosition.X.Offset + delta.X, 2, math.max (2, viewport.X - gui.AbsoluteSize.X - 2)),
			clamp (self.StartPosition.Y.Offset + delta.Y, 2, math.max (2, viewport.Y - gui.AbsoluteSize.Y - 2))
		)
	end))

	Dex:Track (UIS.InputEnded:Connect (function (input)
		if not self.Dragging then return end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		self.Dragging = false
		if not self.Moved then self:ShowMenu () end
		stroke.Color = RestingStroke
	end))

	gui:GetPropertyChangedSignal ("Position"):Connect (function ()
		Dex.LauncherPosition = gui.Position
	end)

	local saved = Dex.LauncherPosition
	if typeof (saved) == "UDim2" then
		gui.Position = saved
	else
		self:SetDefaultPosition ()
	end

	Dex:AttachTooltip (gui, "Dex — click or right-click for options")
	return gui
end

local U = Dex.Utils

local ConsoleBypass = {
	Enabled = false,
	DisabledConnections = {},
	HookInstalled = false,
	ConnectHookInstalled = false,
}

Dex.ConsoleBypass = ConsoleBypass

local function cloneInst (inst)
	if type (cloneref) == "function" and inst then
		local ok, cloned = pcall (cloneref, inst)
		if ok and cloned then return cloned end
	end
	return inst
end

local LogService = cloneInst (game:GetService ("LogService"))
local ScriptContext = cloneInst (game:GetService ("ScriptContext"))

local originalMessageOut = nil
local originalError = nil
local originalConnect = nil
pcall (function ()
	originalMessageOut = LogService.MessageOut
end)
pcall (function ()
	originalError = ScriptContext.Error
end)
pcall (function ()
	if originalMessageOut then originalConnect = originalMessageOut.Connect end
end)

local originalIndexHook = nil
local connectHookPrevious = nil
local connectHookWrapper = nil
local connectForDexOutput = false

local dummySignal = {
	Disconnect = function () end,
	Disable = function () end,
	Enable = function () end,
	Connect = function ()
		return { Disconnect = function () end }
	end,
}

function ConsoleBypass:InstallHook ()
	if self.HookInstalled then return true end
	if type (hookmetamethod) ~= "function" or type (newcclosure) ~= "function" then return false end

	local original
	local ok, result = pcall (function ()
		return hookmetamethod (
			game,
			"__index",
			newcclosure (function (selfObj, key)
				if not ConsoleBypass.Enabled then return original (selfObj, key) end
				if selfObj == LogService and key == "MessageOut" then return dummySignal end
				if selfObj == ScriptContext and key == "Error" then return dummySignal end
				return original (selfObj, key)
			end)
		)
	end)

	if ok and type (result) == "function" then
		original = result
		originalIndexHook = original
		self.HookInstalled = true
		return true
	end
	return false
end

function ConsoleBypass:ConnectOutput (token, callback)
	if type (token) ~= "table" or token ~= Dex._outputSignalToken then return nil end
	if not originalMessageOut or type (callback) ~= "function" then return nil end
	local connection = nil
	connectForDexOutput = true
	pcall (function ()
		connection = originalMessageOut:Connect (callback)
	end)
	connectForDexOutput = false
	return connection
end

local function installConnectHook (self)
	if not originalConnect or self.ConnectHookInstalled then return end
	local ok = pcall (function ()
		local previous
		local wrapper
		wrapper = function (signal, ...)
			if ConsoleBypass.Enabled and not connectForDexOutput then return dummySignal:Connect (...) end
			if previous then return previous (signal, ...) end
			return originalConnect (signal, ...)
		end
		previous = hookfunction (originalConnect, wrapper)
		connectHookPrevious = previous or originalConnect
		connectHookWrapper = wrapper
		self.ConnectHookInstalled = true
	end)
	if not ok then
		connectHookPrevious = nil
		connectHookWrapper = nil
	end
end

function ConsoleBypass:Enable ()
	if self.Enabled then return true end
	if type (getconnections) ~= "function" then
		if Dex and Dex.Notify then Dex:Notify ("getconnections is unavailable", "error") end
		return false
	end

	self.Enabled = true
	self:InstallHook ()
	installConnectHook (self)

	local connections = {}
	local messageOut = originalMessageOut
	local errorSignal = originalError
	if messageOut then
		local ok, found = pcall (getconnections, messageOut)
		if ok and type (found) == "table" then
			for _, connection in pairs (found) do
				connections[#connections + 1] = connection
			end
		end
	end
	if errorSignal then
		local ok, found = pcall (getconnections, errorSignal)
		if ok and type (found) == "table" then
			for _, connection in pairs (found) do
				connections[#connections + 1] = connection
			end
		end
	end

	for _, connection in ipairs (connections) do
		self.DisabledConnections[#self.DisabledConnections + 1] = connection
		pcall (function ()
			connection:Disable ()
		end)
	end

	if Dex and Dex.Output and Dex.Output.OnConsoleBypassEnabled then
		pcall (function ()
			Dex.Output:OnConsoleBypassEnabled ()
		end)
	end

	if Dex and Dex.Notify then Dex:Notify ("Console detection bypass enabled", "success") end
	return true
end

function ConsoleBypass:Disable ()
	if not self.Enabled then return true end
	self.Enabled = false

	pcall (function ()
		if self.HookInstalled then
			hookmetamethod (game, "__index", originalIndexHook)
			originalIndexHook = nil
			self.HookInstalled = false
		end
	end)

	if Dex and Dex.Output and Dex.Output.OnConsoleBypassDisabled then
		pcall (function ()
			Dex.Output:OnConsoleBypassDisabled ()
		end)
	end

	if connectHookWrapper then
		pcall (function ()
			hookfunction (connectHookWrapper, connectHookPrevious)
		end)
		connectHookWrapper = nil
		connectHookPrevious = nil
		self.ConnectHookInstalled = false
	end

	for _, connection in ipairs (self.DisabledConnections) do
		pcall (function ()
			connection:Enable ()
		end)
	end
	self.DisabledConnections = {}

	if Dex and Dex.Notify then Dex:Notify ("Console detection bypass disabled", "info") end
	return true
end

function ConsoleBypass:Toggle ()
	if self.Enabled then return self:Disable () end
	return self:Enable ()
end

getgenv = getgenv or function ()
	return _G
end
getgenv ().ConsoleBypass = ConsoleBypass

local U = Dex.Utils
local UIS = UserInputService

local ScriptViewer = {
	Text = "",
}

Dex.ScriptViewer = ScriptViewer

local Keywords = {
	lua = {
		["and"] = true,
		["break"] = true,
		["or"] = true,
		["else"] = true,
		["elseif"] = true,
		["if"] = true,
		["then"] = true,
		["until"] = true,
		["repeat"] = true,
		["while"] = true,
		["do"] = true,
		["for"] = true,
		["in"] = true,
		["end"] = true,
		["local"] = true,
		["return"] = true,
		["function"] = true,
		["export"] = true,
	},
	rbx = {
		game = true,
		workspace = true,
		script = true,
		math = true,
		string = true,
		table = true,
		task = true,
		wait = true,
		select = true,
		next = true,
		Enum = true,
		tick = true,
		assert = true,
		shared = true,
		loadstring = true,
		tonumber = true,
		tostring = true,
		type = true,
		typeof = true,
		unpack = true,
		Instance = true,
		CFrame = true,
		Vector3 = true,
		Vector2 = true,
		Color3 = true,
		UDim = true,
		UDim2 = true,
		Ray = true,
		BrickColor = true,
		OverlapParams = true,
		RaycastParams = true,
		Axes = true,
		Random = true,
		Region3 = true,
		Rect = true,
		TweenInfo = true,
		collectgarbage = true,
		["not"] = true,
		utf8 = true,
		pcall = true,
		xpcall = true,
		_G = true,
		setmetatable = true,
		getmetatable = true,
		os = true,
		pairs = true,
		ipairs = true,
	},
	operators = {
		["#"] = true,
		["+"] = true,
		["-"] = true,
		["*"] = true,
		["%"] = true,
		["/"] = true,
		["^"] = true,
		["="] = true,
		["~"] = true,
		["<"] = true,
		[">"] = true,
	},
}

local Colors = {
	numbers = Color3.fromHex ("#FAB387"),
	boolean = Color3.fromHex ("#FAB387"),
	operator = Color3.fromHex ("#94E2D5"),
	lua = Color3.fromHex ("#CBA6F7"),
	rbx = Color3.fromHex ("#F38BA8"),
	str = Color3.fromHex ("#A6E3A1"),
	comment = Color3.fromHex ("#9399B2"),
	null = Color3.fromHex ("#F38BA8"),
	call = Color3.fromHex ("#89B4FA"),
	SelfCall = Color3.fromHex ("#89B4FA"),
	LocalProperty = Color3.fromHex ("#CBA6F7"),
}

local function highlight (source)
	local tokens = {}
	local currentToken = ""
	local inString = false
	local inComment = false
	local commentPersist = false

	for i = 1, #source do
		local character = source:sub (i, i)
		if inComment then
			if character == "\n" and not commentPersist then
				table.insert (tokens, currentToken)
				table.insert (tokens, character)
				currentToken = ""
				inComment = false
			elseif source:sub (i - 1, i) == "]]" and commentPersist then
				currentToken = currentToken .. "]"
				table.insert (tokens, currentToken)
				currentToken = ""
				inComment = false
				commentPersist = false
			else
				currentToken = currentToken .. character
			end
		elseif inString then
			local backslashes = 0
			for j = i - 1, 1, -1 do
				if source:sub (j, j) ~= "\\" then break end
				backslashes += 1
			end
			if (character == inString and backslashes % 2 == 0) or character == "\n" then
				currentToken = currentToken .. character
				inString = false
			else
				currentToken = currentToken .. character
			end
		else
			if source:sub (i, i + 1) == "--" then
				table.insert (tokens, currentToken)
				currentToken = "-"
				inComment = true
				commentPersist = source:sub (i + 2, i + 3) == "[["
			elseif character == "\"" or character == "'" then
				table.insert (tokens, currentToken)
				currentToken = character
				inString = character
			elseif Keywords.operators[character] then
				table.insert (tokens, currentToken)
				table.insert (tokens, character)
				currentToken = ""
			elseif character:match ("[%w_]") then
				currentToken = currentToken .. character
			else
				table.insert (tokens, currentToken)
				table.insert (tokens, character)
				currentToken = ""
			end
		end
	end
	table.insert (tokens, currentToken)

	local highlighted = {}
	for i, token in ipairs (tokens) do
		local color = Colors[token]
		if not color and tonumber (token) then
			color = Colors.numbers
		elseif token == "nil" then
			color = Colors.null
		elseif token:sub (1, 2) == "--" then
			color = Colors.comment
		elseif Keywords.operators[token] then
			color = Colors.operator
		elseif Keywords.lua[token] then
			color = Colors.lua
		elseif Keywords.rbx[token] then
			color = Colors.rbx
		elseif token:sub (1, 1) == "\"" or token:sub (1, 1) == "'" then
			color = Colors.str
		elseif token == "true" or token == "false" then
			color = Colors.boolean
		elseif tokens[i + 1] == "(" then
			if tokens[i - 1] == ":" then
				color = Colors.SelfCall
			else
				color = Colors.call
			end
		elseif tokens[i - 1] == "." then
			if tokens[i - 2] == "Enum" then
				color = Colors.rbx
			else
				color = Colors.LocalProperty
			end
		end

		if color then
			local hexColor = color:ToHex ()
			if hexColor:sub (1, 1) ~= "#" then hexColor = "#" .. hexColor end
			table.insert (
				highlighted,
				string.format (
					"<font color=\"%s\">%s</font>",
					hexColor,
					U.EscapeRich (token)
				)
			)
		else
			table.insert (highlighted, U.EscapeRich (token))
		end
	end
	return table.concat (highlighted)
end

local function countLines (text)
	local count = 1
	for _ in tostring (text):gmatch ("\n") do
		count = count + 1
	end
	return count
end

local scriptUntitled = 0
local notepadUntitled = 0

local function defaultFileName (name, ext)
	name = tostring (name or "")
	if name:match ("%.[%w]+$") then return name end
	return (name ~= "" and name or "untitled") .. ext
end

local function scriptAccessorPath (instance)
	if typeof (instance) ~= "Instance" then return nil end
	local nodes = {}
	local current = instance
	while current and current ~= Dex.game do
		nodes[#nodes + 1] = current
		current = current.Parent
	end
	if current ~= Dex.game then return nil end
	local expression = "game"
	for index = #nodes, 1, -1 do
		local node = nodes[index]
		if node.Parent == Dex.game then
			expression = expression .. ":GetService(" .. string.format ("%q", node.Name) .. ")"
		elseif node.Name:match ("^[A-Za-z_][A-Za-z0-9_]*$") then
			expression = expression .. "." .. node.Name
		else
			expression = expression .. "[" .. string.format ("%q", node.Name) .. "]"
		end
	end
	return expression
end

local function createTabBar (parent, config)
	config = config or {}
	local showNew = config.ShowNew == true

	local bar = U.Frame (parent, {
		Name = "TabBar",
		BackgroundColor3 = Dex.Theme.Output.Toolbar,
		BorderSizePixel = 0,
		Size = UDim2.new (1, 0, 0, 30),
		ZIndex = 2,
	})
	local border = U.Frame (bar, {
		Name = "Border",
		BackgroundColor3 = Dex.Theme.Output.ToolbarBorder,
		BorderSizePixel = 0,
		Position = UDim2.new (0, 0, 1, -1),
		Size = UDim2.new (1, 0, 0, 1),
		ZIndex = 3,
	})

	local scroll = U.Scroll (bar, {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset (6, 3),
		Size = UDim2.new (1, showNew and -42 or -12, 0, 24),
		CanvasSize = UDim2.new (0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Dex.Theme.Output.ScrollBar,
		ScrollBarImageTransparency = 0.3,
		ZIndex = 3,
	})
	local layout = U.List (scroll, 4, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local plusBtn = nil
	if showNew then
		plusBtn = U.Button (bar, {
			Name = "NewTab",
			BackgroundColor3 = Dex.Theme.Output.Control,
			AnchorPoint = Vector2.new (1, 0.5),
			Position = UDim2.new (1, -8, 0.5, 0),
			Size = UDim2.fromOffset (22, 22),
			Font = Dex.Fonts.UIMedium,
			Text = "+",
			TextColor3 = Dex.Theme.Output.Text,
			TextSize = 16,
			ZIndex = 4,
		})
		U.Corner (plusBtn, 3)
		U.Stroke (plusBtn, Dex.Theme.Output.ControlBorder, 1, 0)
		plusBtn.MouseEnter:Connect (function ()
			plusBtn.BackgroundColor3 = Dex.Theme.Output.ControlHover
		end)
		plusBtn.MouseLeave:Connect (function ()
			plusBtn.BackgroundColor3 = Dex.Theme.Output.Control
		end)
		plusBtn.MouseButton1Click:Connect (function ()
			if type (config.OnNew) == "function" then config.OnNew () end
		end)
	end

	local tabs = {}
	local active = nil
	local nextOrder = 0
	local api = { Tabs = tabs, Bar = bar }

	local function paint (tab)
		local isActive = active == tab
		tab.Gui.BackgroundColor3 = isActive and Dex.Theme.Output.ControlHover or Dex.Theme.Output.Toolbar
		tab.Label.TextColor3 = isActive and Dex.Theme.Output.Text or Dex.Theme.Output.Timestamp
		tab.Close.TextColor3 = isActive and Dex.Theme.Output.Text or Dex.Theme.Output.Timestamp
	end

	local function repaint ()
		bar.BackgroundColor3 = Dex.Theme.Output.Toolbar
		border.BackgroundColor3 = Dex.Theme.Output.ToolbarBorder
		if plusBtn then
			plusBtn.BackgroundColor3 = Dex.Theme.Output.Control
			plusBtn.TextColor3 = Dex.Theme.Output.Text
		end
		for _, tab in ipairs (tabs) do
			paint (tab)
		end
	end

	function api:Add (name, data)
		nextOrder += 1
		local tab = {
			Name = tostring (name or "Untitled"),
			Data = data or {},
			Order = nextOrder,
		}
		local width = math.clamp (math.ceil (U.TextWidth (tab.Name, 11, Dex.Fonts.UIMedium)) + 30, 74, 180)
		local frame = U.Frame (scroll, {
			Name = "Tab",
			BackgroundColor3 = Dex.Theme.Output.Toolbar,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset (width, 24),
			LayoutOrder = tab.Order,
			ZIndex = 3,
		})
		U.Corner (frame, 4)
		tab.Gui = frame

		local hitbox = U.Button (frame, {
			Name = "Hitbox",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset (0, 0),
			Size = UDim2.new (1, 0, 1, 0),
			Text = "",
			ZIndex = 4,
		})
		tab.Hitbox = hitbox

		local label = U.Label (frame, {
			Name = "Label",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset (0, 0),
			Size = UDim2.new (1, -26, 1, 0),
			Font = Dex.Fonts.UIMedium,
			Text = tab.Name,
			TextSize = 11,
			TextColor3 = Dex.Theme.Output.Timestamp,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 5,
		})
		U.Padding (label, 8, 0, 0, 0)
		tab.Label = label

		local close = U.Button (frame, {
			Name = "Close",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new (1, 0.5),
			Position = UDim2.new (1, -3, 0.5, 0),
			Size = UDim2.fromOffset (16, 18),
			Font = Dex.Fonts.UI,
			Text = "×",
			TextSize = 15,
			TextColor3 = Dex.Theme.Output.Timestamp,
			ZIndex = 6,
		})
		tab.Close = close

		tabs[#tabs + 1] = tab
		hitbox.MouseButton1Click:Connect (function ()
			self:SetActive (tab)
		end)
		hitbox.InputBegan:Connect (function (input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 and type (config.OnContext) == "function" then
				self:SetActive (tab)
				config.OnContext (tab)
			end
		end)
		close.MouseButton1Click:Connect (function ()
			self:Remove (tab)
		end)
		close.MouseEnter:Connect (function ()
			close.TextColor3 = Dex.Theme.Common.Danger
		end)
		close.MouseLeave:Connect (function ()
			paint (tab)
		end)
		paint (tab)
		return tab
	end

	function api:Rename (tab, name)
		if not tab then return end
		tab.Name = tostring (name or "Untitled")
		tab.Label.Text = tab.Name
		local width = math.clamp (math.ceil (U.TextWidth (tab.Name, 11, Dex.Fonts.UIMedium)) + 30, 74, 180)
		tab.Gui.Size = UDim2.fromOffset (width, 24)
	end

	function api:SetActive (tab)
		if active == tab then return end
		local previous = active
		active = tab
		repaint ()
		if type (config.OnActivate) == "function" then config.OnActivate (tab, previous) end
	end

	function api:Remove (tab)
		local index = table.find (tabs, tab)
		if not index then return end
		local wasActive = active == tab
		table.remove (tabs, index)
		if tab.Gui then tab.Gui:Destroy () end
		if wasActive then
			local nextTab = tabs[index] or tabs[index - 1]
			active = nil
			if nextTab then
				self:SetActive (nextTab)
			else
				repaint ()
				if type (config.OnEmpty) == "function" then config.OnEmpty () end
			end
		else
			repaint ()
		end
		if type (config.OnClose) == "function" then config.OnClose (tab) end
	end

	function api:FindBy (predicate)
		for _, tab in ipairs (tabs) do
			if predicate (tab) then return tab end
		end
		return nil
	end

	function api:GetActive ()
		return active
	end

	function api:RefreshActive ()
		if active and type (config.OnActivate) == "function" then config.OnActivate (active, nil) end
	end

	function api:GetTabs ()
		return tabs
	end

	function api:GetTabCount ()
		return #tabs
	end

	function api:RefreshTheme ()
		repaint ()
	end

	Dex:Track (Dex.ThemeChanged:Connect (function ()
		if bar.Parent then repaint () end
	end))

	repaint ()
	return api
end

function Dex:ShowScriptViewer (initialText, scriptName, scriptKey)
	local window = self.Windows.ScriptViewer
	if not window or window.Destroyed then
		window = self:CreateWindow ({
			Name = "ScriptViewer",
			Title = "Script Viewer",
			Size = UDim2.fromOffset (640, 480),
			Position = UDim2.fromOffset (200, 120),
			MinSize = Vector2.new (360, 240),
			ContentColor = Dex.Theme.Output.Background,
			TitleBarColor3 = Dex.Theme.Output.TitleBar,
			BorderColor3 = Dex.Theme.Output.Border,
			TitleTextColor3 = Dex.Theme.Output.TitleText,
			AccentTransparency = 1,
			ContentBuilder = function (content, win)
				self.Windows.ScriptViewer = win

				local toolbar = U.Frame (content, {
					Name = "Toolbar",
					BackgroundColor3 = Dex.Theme.Output.Toolbar,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset (0, 30),
					Size = UDim2.new (1, 0, 0, 30),
					ZIndex = 2,
				})
				U.Frame (toolbar, {
					BackgroundColor3 = Dex.Theme.Output.ToolbarBorder,
					BorderSizePixel = 0,
					Position = UDim2.new (0, 0, 1, -1),
					Size = UDim2.new (1, 0, 0, 1),
					ZIndex = 3,
				})

				local buttonStrokes = {}
				local function toolButton (text, x)
					local btn = U.Button (toolbar, {
						BackgroundColor3 = Dex.Theme.Output.Control,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset (x, 4),
						Size = UDim2.fromOffset (74, 22),
						Font = Dex.Fonts.UIMedium,
						Text = text,
						TextColor3 = Dex.Theme.Output.Text,
						TextSize = 11,
						ZIndex = 3,
					})
					U.Corner (btn, 3)
					buttonStrokes[#buttonStrokes + 1] = U.Stroke (btn, Dex.Theme.Output.ControlBorder, 1, 0)
					btn.MouseEnter:Connect (function ()
						btn.BackgroundColor3 = Dex.Theme.Output.ControlHover
					end)
					btn.MouseLeave:Connect (function ()
						btn.BackgroundColor3 = Dex.Theme.Output.Control
					end)
					return btn
				end

				local saveBtn = toolButton ("Save", 6)
				local copyBtn = toolButton ("Copy", 84)
				local dumpBtn = toolButton ("Dump", 162)

				local lineCount = U.Label (toolbar, {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new (1, 0.5),
					Position = UDim2.new (1, -8, 0.5, 0),
					Size = UDim2.fromOffset (90, 20),
					Font = Dex.Fonts.UI,
					Text = "Lines: 1",
					TextColor3 = Dex.Theme.Output.Timestamp,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Right,
					ZIndex = 3,
				})
				lineCount.Active = false

				local editorScroll = U.Scroll (content, {
					Name = "EditorScroll",
					BackgroundColor3 = Dex.Theme.Output.CommandBackground,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset (6, 30 + 36),
					Size = UDim2.new (1, -12, 1, -(30 + 42)),
					CanvasSize = UDim2.new (0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 8,
					ScrollBarImageColor3 = Dex.Theme.Output.ScrollBar,
					ScrollBarImageTransparency = 0.2,
					ZIndex = 2,
				})
				U.Corner (editorScroll, 4)
				U.Stroke (editorScroll, Dex.Theme.Output.ControlBorder, 1, 0)

				local lineNumbers = U.Label (editorScroll, {
					Name = "LineNumbers",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset (8, 4),
					Size = UDim2.fromOffset (44, 400),
					Font = Dex.Fonts.Mono,
					Text = "1",
					TextColor3 = Dex.Theme.Output.Timestamp,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Top,
					ZIndex = 3,
				})
				lineNumbers.Active = false

				local highlightLabel = U.Label (editorScroll, {
					Name = "HighlightedText",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset (62, 4),
					Size = UDim2.new (1, -70, 0, 400),
					Font = Dex.Fonts.Mono,
					Text = "",
					TextColor3 = Dex.Theme.Output.CommandText,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = false,
					RichText = true,
					ZIndex = 3,
				})
				highlightLabel.Active = false

				local box = U.Textbox (editorScroll, {
					Name = "Editor",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Position = UDim2.fromOffset (62, 4),
					Size = UDim2.new (1, -70, 0, 400),
					Font = Dex.Fonts.Mono,
					Text = "",
					TextColor3 = Dex.Theme.Output.CommandText,
					TextTransparency = 1,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = false,
					ClearTextOnFocus = false,
					MultiLine = true,
					ZIndex = 4,
				})
				win.Editor = box
				win.EditorScroll = editorScroll
				win.LineNumbers = lineNumbers

				local function updateLineCount ()
					local lines = countLines (box.Text)
					lineCount.Text = "Lines: " .. tostring (lines)
					local height = math.max (24, lines * 16 + 8)
					box.Size = UDim2.new (1, -70, 0, height)
					local numbers = {}
					for i = 1, lines do
						numbers[i] = tostring (i)
					end
					lineNumbers.Text = table.concat (numbers, "\n")
					local numWidth = math.max (24, 12 + #tostring (lines) * 8)
					lineNumbers.Position = UDim2.fromOffset (6, 4)
					lineNumbers.Size = UDim2.fromOffset (numWidth, height)
					highlightLabel.Position = UDim2.fromOffset (numWidth + 14, 4)
					highlightLabel.Size = UDim2.new (1, -(numWidth + 22), 0, height)
					box.Position = UDim2.fromOffset (numWidth + 14, 4)
					box.Size = UDim2.new (1, -(numWidth + 22), 0, height)
				end

				local plainText = ""
				local switching = false

				local function updateHighlight ()
					if #plainText >= 199999 then
						highlightLabel.Text = U.EscapeRich (plainText)
						return
					end
					local highlighted = highlight (plainText)
					if #highlighted >= 200000 then
						highlightLabel.Text = U.EscapeRich (plainText)
					else
						highlightLabel.Text = highlighted
					end
				end

				local function setText (value)
					plainText = value
					switching = true
					box.Text = value
					switching = false
					updateLineCount ()
					updateHighlight ()
				end

				local showScriptTabMenu
				local saveScriptTab

				local tabBar = createTabBar (content, {
					OnContext = function (tab)
						if showScriptTabMenu then showScriptTabMenu (tab) end
					end,
					OnActivate = function (tab, previous)
						if previous and previous.Data then previous.Data.Text = box.Text end
						if not tab then
							setText ("")
							return
						end
						setText (tab.Data.Text or "")
						pcall (function ()
							editorScroll.CanvasPosition = Vector2.new (0, 0)
						end)
					end,
					OnEmpty = function ()
						win:Hide ()
					end,
				})
				win.TabBar = tabBar

				box:GetPropertyChangedSignal ("Text"):Connect (function ()
					if switching then return end
					plainText = box.Text
					local currentTab = tabBar:GetActive ()
					if currentTab then currentTab.Data.Text = box.Text end
					if #plainText > 199999 then
						local truncated = "-- This script is bigger than roblox can handle, save it to file to view all of it\n"
							.. plainText:sub (1, 190000)
							.. "\n-- Script cut off due to character limit"
						setText (truncated)
						if currentTab then currentTab.Data.Text = truncated end
						return
					end
					updateLineCount ()
					updateHighlight ()
				end)

				win.SetPlainText = setText

				function win:AddScriptTab (name, text, key)
					local tab = tabBar:Add (name, { Text = text or "", Key = key })
					tabBar:SetActive (tab)
					return tab
				end

				win.NewScriptTab = function ()
					scriptUntitled += 1
					return win:AddScriptTab ("Untitled " .. scriptUntitled, "", nil)
				end

				saveScriptTab = function (tab)
					if not tab then
						Dex:Notify ("No script tab is open", "error")
						return
					end
					if type (writefile) ~= "function" then
						Dex:Notify ("writefile is not available", "error")
						return
					end
					Dex:Prompt ({
						Title = "Save to File",
						Message = "File name:",
						Value = defaultFileName (tab.Data.Path or tab.Name, ".lua"),
						Placeholder = "script.lua",
						ConfirmText = "Save",
						OnConfirm = function (name)
							name = tostring (name)
							if name == "" then
								Dex:Notify ("Filename cannot be empty", "error")
								return
							end
							local ok, err = pcall (writefile, name, tab.Data.Text or "")
							if ok then
								tab.Data.Path = name
								tabBar:Rename (tab, name)
								Dex:Notify ("Saved " .. name, "success")
							else
								Dex:Notify (tostring (err), "error")
							end
						end,
					})
				end

				win.SaveScriptTab = function (tab)
					saveScriptTab (tab or tabBar:GetActive ())
				end

				local function closeOtherTabs (keep)
					local list = {}
					for _, other in ipairs (tabBar:GetTabs ()) do
						list[#list + 1] = other
					end
					for _, other in ipairs (list) do
						if other ~= keep then tabBar:Remove (other) end
					end
				end

				showScriptTabMenu = function (tab)
					if not tab then return end
					local instance = tab.Data.Key
					local hasInstance = typeof (instance) == "Instance"
					local fullName = nil
					if hasInstance then pcall (function ()
						fullName = instance:GetFullName ()
					end) end
					local codePath = hasInstance and scriptAccessorPath (instance) or nil
					local savedPath = tab.Data.Path
					local items = {}
					items[#items + 1] = {
						Text = "Copy Path",
						Callback = function ()
							Dex:CopyText (savedPath or fullName or tab.Name)
						end,
					}
					items[#items + 1] = {
						Text = "Copy Full Name",
						Enabled = fullName ~= nil,
						Callback = function ()
							Dex:CopyText (fullName)
						end,
					}
					items[#items + 1] = {
						Text = "Copy Code Path",
						Enabled = codePath ~= nil,
						Callback = function ()
							Dex:CopyText (codePath)
						end,
					}
					items[#items + 1] = {
						Text = "Copy Name",
						Callback = function ()
							Dex:CopyText (tab.Name)
						end,
					}
					items[#items + 1] = {
						Text = "Copy Source",
						Callback = function ()
							Dex:CopyText (tab.Data.Text or "")
						end,
					}
					items[#items + 1] = { Separator = true }
					items[#items + 1] = {
						Text = "Save As...",
						Enabled = type (writefile) == "function",
						Callback = function ()
							saveScriptTab (tab)
						end,
					}
					items[#items + 1] = {
						Text = "Rename Tab...",
						Callback = function ()
							Dex:Prompt ({
								Title = "Rename Tab",
								Message = "Tab name:",
								Value = tab.Name,
								ConfirmText = "Rename",
								OnConfirm = function (value)
									value = tostring (value)
									if value ~= "" then tabBar:Rename (tab, value) end
								end,
							})
						end,
					}
					items[#items + 1] = {
						Text = "Refresh Source",
						Enabled = hasInstance,
						Callback = function ()
							local ok, source = pcall (function ()
								return instance.Source
							end)
							if not ok or type (source) ~= "string" then
								Dex:Notify ("Unable to read Source", "error")
								return
							end
							if #source > 199999 then
								source = "-- This script is bigger than roblox can handle, save it to file to view all of it\n"
									.. source:sub (1, 190000)
									.. "\n-- Script cut off due to character limit"
							end
							tab.Data.Text = source
							if tabBar:GetActive () == tab then tabBar:RefreshActive () end
							Dex:Notify ("Refreshed source", "success")
						end,
					}
					items[#items + 1] = { Separator = true }
					items[#items + 1] = {
						Text = "Close Tab",
						Callback = function ()
							tabBar:Remove (tab)
						end,
					}
					items[#items + 1] = {
						Text = "Close Other Tabs",
						Enabled = #tabBar:GetTabs () > 1,
						Callback = function ()
							closeOtherTabs (tab)
						end,
					}
					items[#items + 1] = {
						Text = "Close All Tabs",
						Callback = function ()
							closeOtherTabs (nil)
						end,
					}
					Dex:ShowMenu (items, U.MousePoint ())
				end

				local function collectScriptFunctions (instance)
					local getGc = rawget (genv, "getgc") or get_gc_objects or getgc
					local getInfo = debug and (debug.getinfo or debug.info)
					if type (getGc) ~= "function" or type (getInfo) ~= "function" then return {} end
					local target = ""
					pcall (function ()
						target = instance:GetFullName ()
					end)
					if target == "" then target = tostring (instance.Name) end
					local out = {}
					local ok, objects = pcall (getGc, true)
					if not ok or type (objects) ~= "table" then return out end
					for _, value in ipairs (objects) do
						if typeof (value) == "function" then
							local infoOk, info = pcall (getInfo, value)
							if infoOk and type (info) == "table" then
								local source = tostring (info.source or "")
								if source:find (target, 1, true) or source:find (tostring (instance.Name), 1, true) then
									out[#out + 1] = { Fn = value, Info = info }
								end
							end
						end
					end
					return out
				end

				local function buildDump (mode)
					local tab = tabBar:GetActive ()
					local instance = tab and tab.Data.Key
					if typeof (instance) ~= "Instance" then return "-- Open a script tab to dump its functions." end
					local functions = collectScriptFunctions (instance)
					if #functions == 0 then return "-- No functions found. getgc/debug may be unavailable." end
					local lines = {
						"-- " .. mode .. " dump for " .. tostring (instance:GetFullName ()),
						"-- " .. tostring (#functions) .. " function(s)",
						"",
					}
					local getConst = rawget (genv, "getconstants") or (debug and debug.getconstants) or getconstants
					local getUp = rawget (genv, "getupvalues") or (debug and debug.getupvalues) or getupvalues
					for index, entry in ipairs (functions) do
						local name = entry.Info.name
						if not name or name == "" then name = "Function" .. index end
						lines[#lines + 1] = ("[%d] %s"):format (index, tostring (name))
						if mode == "Functions" then
							lines[#lines + 1] = "  source: " .. tostring (entry.Info.source)
							lines[#lines + 1] = "  defined: "
								.. tostring (entry.Info.linedefined or "?")
								.. " - "
								.. tostring (entry.Info.lastlinedefined or "?")
						elseif mode == "Constants" and type (getConst) == "function" then
							local ok, constants = pcall (getConst, entry.Fn)
							if ok and type (constants) == "table" then
								for key, value in pairs (constants) do
									lines[#lines + 1] = ("  %s = %s"):format (tostring (key), tostring (value))
								end
							end
						elseif mode == "Upvalues" and type (getUp) == "function" then
							local ok, upvalues = pcall (getUp, entry.Fn)
							if ok and type (upvalues) == "table" then
								for key, value in pairs (upvalues) do
									lines[#lines + 1] = ("  %s = %s"):format (tostring (key), tostring (value))
								end
							end
						end
						lines[#lines + 1] = ""
					end
					return table.concat (lines, "\n")
				end

				win.DumpTab = function (mode)
					win:AddScriptTab ("Dump - " .. tostring (mode), buildDump (mode), nil)
				end

				dumpBtn.MouseButton1Click:Connect (function ()
					Dex:ShowMenu ({
						{
							Text = "Dump Functions",
							Callback = function ()
								win:AddScriptTab ("Dump - Functions", buildDump ("Functions"), nil)
							end,
						},
						{
							Text = "Dump Constants",
							Callback = function ()
								win:AddScriptTab ("Dump - Constants", buildDump ("Constants"), nil)
							end,
						},
						{
							Text = "Dump Upvalues",
							Callback = function ()
								win:AddScriptTab ("Dump - Upvalues", buildDump ("Upvalues"), nil)
							end,
						},
					}, U.MousePoint ())
				end)

				saveBtn.MouseButton1Click:Connect (function ()
					saveScriptTab (tabBar:GetActive ())
				end)

				copyBtn.MouseButton1Click:Connect (function ()
					if Dex:CopyText (box.Text) then Dex:Notify ("Copied to clipboard", "success") end
				end)

				setText ("")
			end,
		})
		self.Windows.ScriptViewer = window
	end

	window:SetTitle ("Script Viewer")
	local function prepareText (value)
		local text = tostring (value or "")
		if #text > 199999 then
			return "-- This script is bigger than roblox can handle, save it to file to view all of it\n"
				.. text:sub (1, 190000)
				.. "\n-- Script cut off due to character limit"
		end
		return text
	end

	if initialText ~= nil then
		local text = prepareText (initialText)
		local key = scriptKey
		local name = scriptName
		local tab = nil
		if key ~= nil then
			tab = window.TabBar:FindBy (function (candidate)
				return candidate.Data.Key == key
			end)
		end
		if not tab and name and name ~= "" then
			tab = window.TabBar:FindBy (function (candidate)
				return candidate.Name == name and candidate.Data.Text == text
			end)
		end
		if tab then
			tab.Data.Text = text
			if key ~= nil then tab.Data.Key = key end
			if window.TabBar:GetActive () == tab then
				window.TabBar:RefreshActive ()
			else
				window.TabBar:SetActive (tab)
			end
		else
			if not name or name == "" then
				scriptUntitled += 1
				name = "Untitled " .. scriptUntitled
			end
			window:AddScriptTab (name, text, key)
		end
	elseif window.TabBar:GetTabCount () == 0 then
		window.NewScriptTab ()
	end
	window:Show ()
	window:Focus ()
	return window
end


function Dex:ToggleNotepad ()
	local window = self.Windows.Notepad
	if window and not window.Destroyed then
		if window.Visible then
			window:Hide ()
		else
			if window.TabBar and window.TabBar:GetTabCount () == 0 and window.NewNotepadTab then
				window.NewNotepadTab ()
			end
			window:Show ()
			window:Focus ()
		end
		return window
	end
	return self:ShowNotepad ()
end

function Dex:ShowNotepad ()
	local window = self.Windows.Notepad
	if not window or window.Destroyed then
		window = self:CreateWindow ({
			Name = "Notepad",
			Title = "Notepad",
			Size = UDim2.fromOffset (520, 400),
			Position = UDim2.fromOffset (240, 160),
			MinSize = Vector2.new (300, 180),
			ContentColor = Dex.Theme.Output.Background,
			TitleBarColor3 = Dex.Theme.Output.TitleBar,
			BorderColor3 = Dex.Theme.Output.Border,
			TitleTextColor3 = Dex.Theme.Output.TitleText,
			AccentTransparency = 1,
			ContentBuilder = function (content, win)
				self.Windows.Notepad = win

				local toolbar = U.Frame (content, {
					Name = "Toolbar",
					BackgroundColor3 = Dex.Theme.Output.Toolbar,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset (0, 30),
					Size = UDim2.new (1, 0, 0, 30),
					ZIndex = 2,
				})
				U.Frame (toolbar, {
					BackgroundColor3 = Dex.Theme.Output.ToolbarBorder,
					BorderSizePixel = 0,
					Position = UDim2.new (0, 0, 1, -1),
					Size = UDim2.new (1, 0, 0, 1),
					ZIndex = 3,
				})

				local buttonStrokes = {}
				local function toolButton (text, x)
					local btn = U.Button (toolbar, {
						BackgroundColor3 = Dex.Theme.Output.Control,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset (x, 4),
						Size = UDim2.fromOffset (56, 22),
						Font = Dex.Fonts.UIMedium,
						Text = text,
						TextColor3 = Dex.Theme.Output.Text,
						TextSize = 11,
						ZIndex = 3,
					})
					U.Corner (btn, 3)
					buttonStrokes[#buttonStrokes + 1] = U.Stroke (btn, Dex.Theme.Output.ControlBorder, 1, 0)
					btn.MouseEnter:Connect (function ()
						btn.BackgroundColor3 = Dex.Theme.Output.ControlHover
					end)
					btn.MouseLeave:Connect (function ()
						btn.BackgroundColor3 = Dex.Theme.Output.Control
					end)
					return btn
				end

				local saveBtn = toolButton ("Save", 6)
				local copyBtn = toolButton ("Copy", 66)
				local openBtn = toolButton ("Open", 126)

				local countLabel = U.Label (toolbar, {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new (1, 0.5),
					Position = UDim2.new (1, -8, 0.5, 0),
					Size = UDim2.new (1, -200, 1, 0),
					Font = Dex.Fonts.UI,
					Text = "Lines: 1",
					TextColor3 = Dex.Theme.Output.Timestamp,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Right,
					ZIndex = 3,
				})
				countLabel.Active = false

				local box = U.Textbox (content, {
					Name = "Notes",
					ClipsDescendants = true,
					BackgroundColor3 = Dex.Theme.Output.CommandBackground,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset (6, 30 + 36),
					Size = UDim2.new (1, -12, 1, -(30 + 42)),
					Font = Dex.Fonts.Mono,
					Text = "",
					TextColor3 = Dex.Theme.Output.CommandText,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = false,
					ClearTextOnFocus = false,
					MultiLine = true,
					ZIndex = 2,
				})
				U.Corner (box, 4)
				local boxStroke = U.Stroke (box, Dex.Theme.Output.ControlBorder, 1, 0)
				U.Padding (box, 8, 6, 8, 6)
				win.NotesBox = box

				local switching = false
				local function updateCount ()
					local lines = 1
					for _ in box.Text:gmatch ("\n") do
						lines = lines + 1
					end
					countLabel.Text = "Lines: " .. tostring (lines)
				end

				local tabBar = createTabBar (content, {
					ShowNew = true,
					OnNew = function ()
						if win.NewNotepadTab then win.NewNotepadTab () end
					end,
					OnActivate = function (tab, previous)
						if previous and previous.Data then previous.Data.Text = box.Text end
						switching = true
						box.Text = tab and (tab.Data.Text or "") or ""
						switching = false
						updateCount ()
					end,
					OnEmpty = function ()
						win:Hide ()
					end,
				})
				win.TabBar = tabBar

				function win:AddNotepadTab (name, text)
					local tab = tabBar:Add (name, { Text = text or "" })
					tabBar:SetActive (tab)
					return tab
				end

				win.NewNotepadTab = function ()
					notepadUntitled += 1
					return win:AddNotepadTab ("Untitled " .. notepadUntitled, "")
				end

				function win:OpenNotepadFile (name, text)
					local tab = tabBar:FindBy (function (candidate)
						return candidate.Name == name
					end)
					if tab then
						tab.Data.Text = text or ""
						if tabBar:GetActive () == tab then
							tabBar:RefreshActive ()
						else
							tabBar:SetActive (tab)
						end
						return tab
					end
					return win:AddNotepadTab (name, text)
				end

				local function refreshTheme ()
					toolbar.BackgroundColor3 = Dex.Theme.Output.Toolbar
					for index, btn in ipairs ({ saveBtn, copyBtn, openBtn }) do
						btn.BackgroundColor3 = Dex.Theme.Output.Control
						btn.TextColor3 = Dex.Theme.Output.Text
						local stroke = buttonStrokes[index]
						if stroke then stroke.Color = Dex.Theme.Output.ControlBorder end
					end
					countLabel.TextColor3 = Dex.Theme.Output.Timestamp
					box.BackgroundColor3 = Dex.Theme.Output.CommandBackground
					box.TextColor3 = Dex.Theme.Output.CommandText
					if boxStroke then boxStroke.Color = Dex.Theme.Output.ControlBorder end
					tabBar:RefreshTheme ()
				end
				win.RefreshTheme = refreshTheme
				Dex:Track (Dex.ThemeChanged:Connect (function ()
					if win and win.GUI and win.GUI.Parent then refreshTheme () end
				end))
				refreshTheme ()

				saveBtn.MouseButton1Click:Connect (function ()
					if type (writefile) ~= "function" then
						Dex:Notify ("writefile is not available", "error")
						return
					end
					local tab = tabBar:GetActive ()
					if not tab then
						Dex:Notify ("No note tab is open", "error")
						return
					end
					Dex:Prompt ({
						Title = "Save Notepad",
						Message = "File name:",
						Value = defaultFileName (tab.Name, ".txt"),
						Placeholder = "notes.txt",
						ConfirmText = "Save",
						OnConfirm = function (name)
							name = tostring (name)
							if name == "" then
								Dex:Notify ("Filename cannot be empty", "error")
								return
							end
							local ok, err = pcall (writefile, name, tab.Data.Text or box.Text)
							if ok then
								tabBar:Rename (tab, name)
								Dex:Notify ("Saved " .. name, "success")
							else
								Dex:Notify (tostring (err), "error")
							end
						end,
					})
				end)

				copyBtn.MouseButton1Click:Connect (function ()
					if Dex:CopyText (box.Text) then Dex:Notify ("Copied to clipboard", "success") end
				end)

				openBtn.MouseButton1Click:Connect (function ()
					if type (listfiles) ~= "function" then
						Dex:Notify ("listfiles is not available", "error")
						return
					end
					local ok, files = pcall (listfiles, "")
					if not ok or type (files) ~= "table" then
						Dex:Notify ("Unable to list files", "error")
						return
					end
					local items = {}
					for _, path in ipairs (files) do
						local name = tostring (path):match ("([^/\\]+)$") or tostring (path)
						items[#items + 1] = { Text = name, Value = path, SearchText = path }
					end
					table.sort (items, function (a, b)
						return a.Text:lower () < b.Text:lower ()
					end)
					if #items == 0 then
						Dex:Notify ("No files found", "info")
						return
					end
					Dex:ShowPicker ({
						Items = items,
						Width = 320,
						MaxHeight = 360,
						Search = true,
						SearchPlaceholder = "Open file...",
						AutoFocus = true,
						EmptyText = "No files found",
						OnSelect = function (path, item)
							if type (readfile) ~= "function" then
								Dex:Notify ("readfile is not available", "error")
								return
							end
							local ok2, data = pcall (readfile, path)
							if ok2 and type (data) == "string" then
								win:OpenNotepadFile (tostring (item.Text), data)
								Dex:Notify ("Opened " .. tostring (item.Text), "success")
							else
								Dex:Notify (tostring (data), "error")
							end
						end,
					})
				end)

				box:GetPropertyChangedSignal ("Text"):Connect (function ()
					if switching then return end
					local tab = tabBar:GetActive ()
					if tab then tab.Data.Text = box.Text end
					updateCount ()
				end)
			end,
		})
		self.Windows.Notepad = window
	end
	if window.TabBar and window.TabBar:GetTabCount () == 0 and window.NewNotepadTab then window.NewNotepadTab () end
	window:Show ()
	window:Focus ()
	return window
end

local Bypass = {
	Enabled = false,
	Originals = {},
	Wrappers = {},
	Connections = {},
	Running = false,
	Generation = 0,
}

Dex.Bypass = Bypass

local function cloneInst (inst)
	if type (cloneref) == "function" and inst then
		local ok, cloned = pcall (cloneref, inst)
		if ok and cloned then return cloned end
	end
	return inst
end

local function storeHook (name, original, wrapper)
	Bypass.Originals[name] = original
	Bypass.Wrappers[name] = wrapper
end

function Bypass:HasApi ()
	return type (hookfunction) == "function"
		and type (hookmetamethod) == "function"
		and type (getnamecallmethod) == "function"
		and type (checkcaller) == "function"
end

function Bypass:Enable ()
	if self.Enabled then return true end
	if not self:HasApi () then
		if Dex.Notify then Dex:Notify ("Bypass requires hookfunction/hookmetamethod", "error") end
		return false
	end

	self.Enabled = true
	self.Running = true
	self.Generation += 1
	local generation = self.Generation

	local RunService = cloneInst (game:GetService ("RunService"))
	local Stats = cloneInst (game:GetService ("Stats"))
	local Content = cloneInst (game:GetService ("ContentProvider"))
	local CoreGui = cloneInst (game:GetService ("CoreGui"))

	task.spawn (function ()
		repeat
			task.wait ()
		until game:IsLoaded ()
		if not self.Running or self.Generation ~= generation then return end
		local amplitude = 200
		local tickValue = 0
		local oldGc = (gcinfo and gcinfo () or 0) + amplitude

		local function getReturn ()
			local formula = ((math.acos (math.cos (math.pi * tickValue)) / math.pi) * (amplitude * 2)) + -amplitude
			return math.floor (oldGc + formula)
		end

		pcall (function ()
			local env = getrenv ()
			local original = env.gcinfo
			if type (original) ~= "function" then return end
			local previous
			local wrapper = function (...)
				if self.Running then return getReturn () end
				if previous then return previous (...) end
				return original (...)
			end
			previous = hookfunction (original, wrapper)
			storeHook ("gcinfo", previous or original, wrapper)
		end)

		pcall (function ()
			local env = getrenv ()
			local original = env.collectgarbage
			if type (original) ~= "function" then return end
			local previous
			local wrapper = function (arg, ...)
				if self.Running and arg == "count" then return getReturn () end
				if previous then return previous (arg, ...) end
				return original (arg, ...)
			end
			previous = hookfunction (original, wrapper)
			storeHook ("collectgarbage", previous or original, wrapper)
		end)

		pcall (function ()
			self.Connections[#self.Connections + 1] = RunService.Stepped:Connect (function ()
				if not self.Running or self.Generation ~= generation then return end
				local formula = ((math.acos (math.cos (math.pi * tickValue)) / math.pi) * (amplitude * 2)) + -amplitude
				local nextFormula = ((math.acos (math.cos (math.pi * tickValue + 0.01)) / math.pi) * (amplitude * 2))
					+ -amplitude
				if formula > nextFormula then
					tickValue = tickValue + 0.07
				else
					tickValue = tickValue + 0.01
				end
			end)
		end)

		while self.Running and self.Generation == generation do
			task.wait (math.random (10, 100) / 100)
			amplitude = math.random (0, 400)
		end
	end)

	local memoryBase = 0
	local memoryOffset = 0
	pcall (function ()
		memoryBase = Stats:GetTotalMemoryUsageMb ()
	end)
	pcall (function ()
		self.Connections[#self.Connections + 1] = RunService.Stepped:Connect (function ()
			if self.Running then memoryOffset = Random.new ():NextNumber (-10, 10) end
		end)
	end)

	local oldNamecall = nil
	local function callOld (selfObj, ...)
		if oldNamecall then return oldNamecall (selfObj, ...) end

		if typeof (selfObj) == "Instance" then
			local method = getnamecallmethod ()
			local fn = method and selfObj[method]
			if typeof (fn) == "function" then return fn (selfObj, ...) end
		end
	end

	pcall (function ()
		oldNamecall = hookmetamethod (game, "__namecall", function (selfObj, ...)
			local method = getnamecallmethod ()
			local ok, caller = pcall (checkcaller)
			if self.Running and ok and not caller and typeof (selfObj) == "Instance" then
				local className = selfObj.ClassName
				if className == "Stats" then
					if method == "GetTotalMemoryUsageMb" or method == "gettotalmemoryusagemb" then
						return memoryBase + memoryOffset
					elseif method == "GetMemoryUsageMbForTag" or method == "getmemoryusagembfortag" then
						return math.abs (memoryBase) * 0.01 + memoryOffset
					end
				elseif className == "ContentProvider" and (method == "PreloadAsync" or method == "preloadAsync") then
					local instances = ...
					if
						type (instances) == "table"
						and instances[1]
						and (table.find (instances, CoreGui) or table.find (instances, game))
					then
						local args = table.pack (...)
						args[1] = { CoreGui }
						return callOld (selfObj, table.unpack (args, 1, args.n))
					end
				elseif className == "UserInputService" and method == "GetFocusedTextBox" then
					local textbox = callOld (selfObj, ...)
					if typeof (textbox) == "Instance" and Dex.ScreenGui then
						local ok, descendant = pcall (function ()
							return textbox:IsDescendantOf (Dex.ScreenGui)
						end)
						if ok and descendant then return nil end
					end
					return textbox
				end
			end
			return callOld (selfObj, ...)
		end)
		storeHook ("Namecall", oldNamecall, nil)
	end)

	pcall (function ()
		local original = Content.PreloadAsync
		if typeof (original) ~= "function" then return end
		local previous
		local wrapper = function (a, b, c, ...)
			if
				self.Running
				and not checkcaller ()
				and typeof (a) == "Instance"
				and type (b) == "table"
				and (table.find (b, CoreGui) or table.find (b, game))
			then
				if previous then return previous (a, { CoreGui }, c, ...) end
				return original (a, { CoreGui }, c, ...)
			end
			if previous then return previous (a, b, c, ...) end
			return original (a, b, c, ...)
		end
		previous = hookfunction (original, wrapper)
		storeHook ("PreloadFunction", previous or original, wrapper)
	end)

	pcall (function ()
		local env = getrenv ()
		local original = env.newproxy
		if type (original) ~= "function" then return end
		local previous
		local wrapper = function (...)
			if previous then
				local ok, result = pcall (previous, ...)
				if ok and result ~= nil then return result end
			end
			local ok, result = pcall (original, ...)
			return ok and result or nil
		end
		previous = hookfunction (original, wrapper)
		storeHook ("newproxy", previous or original, wrapper)
	end)

	if Dex.Notify then Dex:Notify ("Bypass enabled", "success") end
	return true
end

function Bypass:Disable ()
	if not self.Enabled then return true end
	self.Enabled = false
	self.Running = false

	pcall (function ()
		if self.Originals.Namecall then hookmetamethod (game, "__namecall", self.Originals.Namecall) end
	end)
	pcall (function ()
		for name, wrapper in pairs (self.Wrappers) do
			if name ~= "Namecall" and type (wrapper) == "function" then
				pcall (function ()
					hookfunction (wrapper, self.Originals[name])
				end)
			end
		end
	end)

	for _, connection in ipairs (self.Connections) do
		pcall (function ()
			connection:Disconnect ()
		end)
	end
	self.Connections = {}
	self.Originals = {}
	self.Wrappers = {}

	if Dex.Notify then Dex:Notify ("Bypass disabled", "info") end
	return true
end

function Bypass:Toggle ()
	if self.Enabled then return self:Disable () end
	return self:Enable ()
end

getgenv = getgenv or function ()
	return _G
end
getgenv ().DexBypass = Bypass

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

local U = Dex.Utils
local UIS = UserInputService

local ModelViewer = {
	Window = nil,
	Connection = nil,
}

Dex.ModelViewer = ModelViewer

local function modelBounds (root)
	local minVector = Vector3.new (math.huge, math.huge, math.huge)
	local maxVector = Vector3.new (-math.huge, -math.huge, -math.huge)
	local found = false
	local function consider (part)
		if not part:IsA ("BasePart") then return end
		found = true
		local half = part.Size / 2
		for _, x in ipairs ({ -half.X, half.X }) do
			for _, y in ipairs ({ -half.Y, half.Y }) do
				for _, z in ipairs ({ -half.Z, half.Z }) do
					local corner = part.CFrame * Vector3.new (x, y, z)
					minVector = Vector3.new (
						math.min (minVector.X, corner.X),
						math.min (minVector.Y, corner.Y),
						math.min (minVector.Z, corner.Z)
					)
					maxVector = Vector3.new (
						math.max (maxVector.X, corner.X),
						math.max (maxVector.Y, corner.Y),
						math.max (maxVector.Z, corner.Z)
					)
				end
			end
		end
	end
	consider (root)
	for _, descendant in ipairs (root:GetDescendants ()) do
		consider (descendant)
	end
	if not found then return Vector3.new (0, 0, 0), Vector3.new (4, 4, 4) end
	return (minVector + maxVector) / 2, maxVector - minVector
end

local function cloneForPreview (source)
	local restore = {}
	local function enable (instance)
		local ok, archivable = pcall (function ()
			return instance.Archivable
		end)
		if not ok or archivable ~= false then return end
		if pcall (function ()
			instance.Archivable = true
		end) then restore[#restore + 1] = instance end
	end

	pcall (function ()
		enable (source)
		for _, descendant in ipairs (source:GetDescendants ()) do
			enable (descendant)
		end
	end)

	local ok, clone = pcall (function ()
		return source:Clone ()
	end)

	for index = #restore, 1, -1 do
		pcall (function ()
			restore[index].Archivable = false
		end)
	end

	if not ok or typeof (clone) ~= "Instance" then return nil, clone end
	pcall (function ()
		clone.Archivable = false
	end)
	return clone
end

function ModelViewer:Close ()
	if self.Connection then
		self.Connection:Disconnect ()
		Dex:Untrack (self.Connection)
		self.Connection = nil
	end
	if self.Window and not self.Window.Destroyed then self.Window:Hide () end
end

function ModelViewer:Show (instance)
	if typeof (instance) ~= "Instance" then
		Dex:Notify ("Select a Model or BasePart to preview", "error")
		return nil
	end

	local window = self.Window
	if not window or window.Destroyed then
		window = Dex:CreateWindow ({
			Name = "ModelViewer",
			Title = "3D Preview",
			Size = UDim2.fromOffset (560, 420),
			Position = UDim2.fromOffset (250, 140),
			MinSize = Vector2.new (360, 260),
			ContentColor = Dex.Theme.Output.Background,
			TitleBarColor3 = Dex.Theme.Output.TitleBar,
			BorderColor3 = Dex.Theme.Output.Border,
			TitleTextColor3 = Dex.Theme.Output.TitleText,
			AccentTransparency = 1,
			ContentBuilder = function (content, win)
				self.Window = win

				local viewport = U.Create ("ViewportFrame", {
					Name = "Viewport",
					BackgroundColor3 = Dex.Theme.Output.CommandBackground,
					BorderSizePixel = 0,
					Size = UDim2.new (1, 0, 1, -32),
					ClipsDescendants = true,
					Active = true,
					ZIndex = 2,
					Parent = content,
				})
				U.Corner (viewport, 3)

				local toolbar = U.Frame (content, {
					Name = "Toolbar",
					BackgroundColor3 = Dex.Theme.Output.Toolbar,
					BorderSizePixel = 0,
					Position = UDim2.new (0, 0, 1, -32),
					Size = UDim2.new (1, 0, 0, 32),
					ZIndex = 2,
				})
				U.Frame (toolbar, {
					BackgroundColor3 = Dex.Theme.Output.ToolbarBorder,
					BorderSizePixel = 0,
					Position = UDim2.new (0, 0, 0, 0),
					Size = UDim2.new (1, 0, 0, 1),
					ZIndex = 3,
				})

				local function toolButton (text, x, width)
					local btn = U.Button (toolbar, {
						BackgroundColor3 = Dex.Theme.Output.Control,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset (x, 5),
						Size = UDim2.fromOffset (width, 22),
						Font = Dex.Fonts.UIMedium,
						Text = text,
						TextColor3 = Dex.Theme.Output.Text,
						TextSize = 11,
						ZIndex = 3,
					})
					U.Corner (btn, 3)
					return btn
				end

				local resetBtn = toolButton ("Reset", 8, 72)
				local autoBtn = toolButton ("Auto-Rotate", 88, 96)
				local axesBtn = toolButton ("Axes: Off", 192, 72)
				local freecamBtn = toolButton ("Freecam: Off", 272, 88)

				local state = {
					Center = Vector3.new (0, 0, 0),
					Radius = 10,
					Yaw = 0.7,
					Pitch = 0.35,
					Auto = false,
					Freecam = false,
					Position = Vector3.new (0, 0, 0),
					Drag = false,
					Pan = false,
					LeftDown = false,
					RightDown = false,
					Last = Vector2.new (0, 0),
					Camera = nil,
					Axes = false,
					AxesFolder = nil,
				}
				self.State = state

				local camera = U.Create ("Camera", {
					Name = "PreviewCamera",
					Parent = viewport,
				})
				viewport.CurrentCamera = camera
				state.Camera = camera

				local function lookDirection ()
					local yaw, pitch = state.Yaw, state.Pitch
					local horizontal = math.cos (pitch)
					return Vector3.new (-math.sin (yaw) * horizontal, -math.sin (pitch), -math.cos (yaw) * horizontal)
				end

				local function updateCamera ()
					if state.Freecam then
						camera.CFrame = CFrame.lookAt (state.Position, state.Position + lookDirection ())
						return
					end
					local yaw, pitch, radius = state.Yaw, state.Pitch, state.Radius
					local horizontal = math.cos (pitch) * radius
					local offset = Vector3.new (
						math.sin (yaw) * horizontal,
						math.sin (pitch) * radius,
						math.cos (yaw) * horizontal
					)
					state.Position = state.Center + offset
					camera.CFrame = CFrame.lookAt (state.Position, state.Center)
				end

				local function setAxesVisible (visible)
					state.Axes = visible == true
					axesBtn.Text = state.Axes and "Axes: On" or "Axes: Off"
					if state.AxesFolder then
						state.AxesFolder:Destroy ()
						state.AxesFolder = nil
					end
					if not state.Axes then return end
					local folder = U.Create ("Folder", {
						Name = "PreviewAxes",
					})
					local length = math.max (3, state.Radius * 0.9)
					local thick = math.max (0.06, length * 0.012)
					local function axisPart (name, size, color)
						local part = U.Create ("Part", {
							Name = name,
							Shape = Enum.PartType.Block,
							Size = size,
							CFrame = CFrame.new (state.Center),
							Color = color,
							Material = Enum.Material.Neon,
							Anchored = true,
							CanCollide = false,
							Archivable = false,
							Parent = folder,
						})
						return part
					end
					axisPart ("AxisX", Vector3.new (length, thick, thick), Color3.fromRGB (255, 70, 70))
					axisPart ("AxisY", Vector3.new (thick, length, thick), Color3.fromRGB (80, 230, 110))
					axisPart ("AxisZ", Vector3.new (thick, thick, length), Color3.fromRGB (80, 150, 255))
					folder.Parent = viewport
					state.AxesFolder = folder
				end

				self.SetAxesVisible = setAxesVisible

				local function setFreecam (enabled)
					state.Freecam = enabled == true
					freecamBtn.Text = state.Freecam and "Freecam: On" or "Freecam: Off"
					state.Drag = false
					state.Pan = false
					state.LeftDown = false
					state.RightDown = false

					if state.Freecam then
						state.Position = camera.CFrame.Position
					else
						local delta = state.Position - state.Center
						local radius = delta.Magnitude
						if radius < 0.001 then
							delta = Vector3.new (math.sin (state.Yaw), 0, math.cos (state.Yaw))
							radius = 1
						end
						state.Radius = math.clamp (radius, 1, 2000)
						state.Yaw = math.atan2 (delta.X, delta.Z)
						state.Pitch = math.asin (math.clamp (delta.Y / radius, -1, 1))
					end

					updateCamera ()
				end
				self.SetFreecam = setFreecam

				resetBtn.MouseButton1Click:Connect (function ()
					if state.Freecam then setFreecam (false) end
					state.Yaw = 0.7
					state.Pitch = 0.35
					state.Radius = state.DefaultRadius or 10
					updateCamera ()
					setAxesVisible (state.Axes)
				end)
				autoBtn.MouseButton1Click:Connect (function ()
					state.Auto = not state.Auto
					autoBtn.Text = state.Auto and "Auto: On" or "Auto-Rotate"
				end)
				axesBtn.MouseButton1Click:Connect (function ()
					setAxesVisible (not state.Axes)
				end)
				freecamBtn.MouseButton1Click:Connect (function ()
					setFreecam (not state.Freecam)
				end)

				local function isLookInput (input)
					return input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
				end

				local function isPanInput (input)
					return state.Freecam
						and (
							input.UserInputType == Enum.UserInputType.MouseButton2
							or input.UserInputType == Enum.UserInputType.MouseButton3
						)
				end

				viewport.InputBegan:Connect (function (input)
					if isLookInput (input) then
						state.LeftDown = true
						state.Pan = false
					elseif isPanInput (input) then
						state.RightDown = true
						state.Pan = true
					else
						return
					end
					state.Drag = true
					state.Last = U.MousePoint ()
				end)

				local function endDrag (input)
					if isLookInput (input) then
						state.LeftDown = false
					elseif
						input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3
					then
						state.RightDown = false
					else
						return
					end
					state.Drag = state.LeftDown or state.RightDown
					state.Pan = state.RightDown
					if state.Drag then state.Last = U.MousePoint () end
				end
				Dex:Track (UIS.InputEnded:Connect (endDrag))

				Dex:Track (UIS.InputChanged:Connect (function (input)
					if not win.Visible then return end
					if input.UserInputType == Enum.UserInputType.MouseWheel then
						if Dex.ActiveWindow ~= win or not win.Visible then return end
						if state.Freecam then
							local step = input.Position.Z * math.max (1, state.Radius * 0.08)
							state.Position = state.Position + lookDirection () * step
						else
							state.Radius = math.clamp (state.Radius - input.Position.Z * 0.6, 1, 2000)
						end
						updateCamera ()
					elseif
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					then
						if not state.Drag then return end
						local point = U.MousePoint ()
						local delta = point - state.Last
						state.Last = point
						local panning = state.Pan
						if state.Freecam and not panning then
							panning = UIS:IsKeyDown (Enum.KeyCode.LeftShift) or UIS:IsKeyDown (Enum.KeyCode.RightShift)
						end
						if panning and state.Freecam then
							local offset = state.Position - state.Center
							local radius = offset.Magnitude
							if radius < 0.001 then
								offset = Vector3.new (math.sin (state.Yaw), 0, math.cos (state.Yaw))
								radius = 1
							end
							local yaw = math.atan2 (offset.X, offset.Z) - delta.X * 0.01
							local pitch = math.asin (math.clamp (offset.Y / radius, -1, 1))
							pitch = math.clamp (pitch + delta.Y * 0.01, -1.5, 1.5)
							state.Yaw, state.Pitch = yaw, pitch
							local horizontal = math.cos (pitch) * radius
							state.Position = state.Center
								+ Vector3.new (
									math.sin (yaw) * horizontal,
									math.sin (pitch) * radius,
									math.cos (yaw) * horizontal
								)
						else
							state.Yaw -= delta.X * 0.01
							state.Pitch = math.clamp (state.Pitch + delta.Y * 0.01, -1.5, 1.5)
						end
						updateCamera ()
					end
				end))

				self.UpdateCamera = updateCamera
				self.Viewport = viewport
			end,
		})
		self.Window = window
	end

	local viewport = self.Viewport
	local state = self.State
	if not viewport or not state then return window end

	for _, child in ipairs (viewport:GetChildren ()) do
		if child ~= state.Camera then child:Destroy () end
	end

	local source = instance
	pcall (function ()
		if instance:IsA ("Player") then
			source = instance.Character
		elseif instance:IsA ("Humanoid") then
			source = instance.Parent
		end
	end)
	if typeof (source) ~= "Instance" then
		Dex:Notify ("Nothing visible to preview", "info")
		return window
	end

	local clone, cloneError = cloneForPreview (source)
	if not clone then
		local message = "Unable to clone that instance"
		if typeof (cloneError) == "string" and cloneError ~= "" then message = message .. " (" .. cloneError .. ")" end
		Dex:Notify (message, "error")
		return window
	end

	local holder = U.Create ("Model", {
		Name = "PreviewModel",
		Parent = viewport,
	})
	pcall (function ()
		for _, descendant in ipairs (clone:GetDescendants ()) do
			if descendant:IsA ("LuaSourceContainer") then descendant:Destroy () end
		end
	end)
	clone.Parent = holder

	if state.Freecam and self.SetFreecam then self.SetFreecam (false) end
	local center, size = modelBounds (holder)
	state.Center = center
	state.Radius = math.max (4, size.Magnitude * 1.6)
	state.DefaultRadius = state.Radius
	state.Yaw = 0.7
	state.Pitch = 0.35
	state.Auto = false
	if self.UpdateCamera then self.UpdateCamera () end
	if self.SetAxesVisible and state.Axes then self.SetAxesVisible (true) end

	local targetName = "Preview"
	pcall (function ()
		targetName = instance.Name
	end)
	window:SetTitle ("3D Preview - " .. tostring (targetName))
	window:Show ()
	window:Focus ()

	if self.Connection then
		self.Connection:Disconnect ()
		Dex:Untrack (self.Connection)
	end
	self.Connection = Dex:Track (RunService.RenderStepped:Connect (function (delta)
		if not state.Auto or not window.Visible then return end
		state.Yaw += (delta or 0) * 0.6
		if self.UpdateCamera then self.UpdateCamera () end
	end))

	return window
end

local U = Dex.Utils

local StandardThemes = {
	"Studio Dark",
	"Studio Light",
	"Studio OLED",
	"Ocean Blue",
	"GitHub Dark",
	"GitHub Light",
}

Dex.Filesystem = {
	Root = "Dex",
	Plugins = "Dex/Plugins",
	Themes = "Dex/Themes",
	LoadedPlugins = {},
	LoadedThemeFiles = {},
}

local Filesystem = Dex.Filesystem

local function canUseFiles ()
	return type (makefolder) == "function"
		and type (isfolder) == "function"
		and type (writefile) == "function"
		and type (readfile) == "function"
		and type (isfile) == "function"
end

local function ensureFolder (path)
	if type (isfolder) ~= "function" or type (makefolder) ~= "function" then return false end
	local ok, exists = pcall (isfolder, path)
	if ok and exists then return true end
	return pcall (makefolder, path)
end

local function fileNameFor (name)
	return tostring (name):gsub ("[\\/:*?\"<>|]", "_") .. ".json"
end

local function toHex (color)
	if typeof (color) ~= "Color3" then return nil end
	return "#" .. U.ColorHex (color)
end

local function fromHex (value)
	if typeof (value) == "Color3" then return value end
	if type (value) ~= "string" then return nil end
	local hex = value:gsub ("#", "")
	if #hex ~= 6 then return nil end
	local number = tonumber (hex, 16)
	if not number then return nil end
	return Color3.fromRGB (math.floor (number / 65536) % 256, math.floor (number / 256) % 256, number % 256)
end

local function deepCopy (value)
	if typeof (value) ~= "table" then return value end
	local result = {}
	for key, child in pairs (value) do
		result[key] = deepCopy (child)
	end
	return result
end

local function serializeTheme (name, theme)
	local data = { Name = name }
	for group, entries in pairs (theme) do
		if type (entries) == "table" then
			data[group] = {}
			for key, value in pairs (entries) do
				local hex = toHex (value)
				if hex then data[group][key] = hex end
			end
		end
	end
	return data
end

local function decodeTheme (data)
	local theme = deepCopy (Dex.DefaultTheme)
	if type (data) ~= "table" then return theme end
	for group, defaults in pairs (Dex.DefaultTheme) do
		local source = data[group]
		if type (source) == "table" then
			for key in pairs (defaults) do
				local color = fromHex (source[key])
				if color then theme[group][key] = color end
			end
		end
	end
	return theme
end

local function notify (message, kind)
	if Dex.Output and Dex.Output.AddLocal then Dex.Output:AddLocal ("[Dex] " .. message, kind or "info") end
end

function Filesystem:WriteStandardThemes ()
	if not canUseFiles () then return 0 end
	if not ensureFolder ("Dex/Themes") then return 0 end
	local written = 0
	local encode = Dex.Services.HttpService and Dex.Services.HttpService.JSONEncode
	if type (encode) ~= "function" then return 0 end
	for _, name in ipairs (StandardThemes) do
		local factory = Dex.ThemePresets[name]
		if factory then
			local path = "Dex/Themes" .. "/" .. fileNameFor (name)
			local ok, exists = pcall (isfile, path)
			if not ok or not exists then
				local encoded, json = pcall (function ()
					return encode (Dex.Services.HttpService, serializeTheme (name, factory ()))
				end)
				if encoded and type (json) == "string" and pcall (writefile, path, json) then
					written += 1
				end
			end
		end
	end
	return written
end

function Filesystem:LoadThemes ()
	if not canUseFiles () or type (listfiles) ~= "function" then return 0 end
	if not ensureFolder ("Dex/Themes") then return 0 end
	local ok, paths = pcall (listfiles, "Dex/Themes")
	if not ok or type (paths) ~= "table" then return 0 end
	table.sort (paths)
	local loaded = 0
	for _, path in ipairs (paths) do
		if tostring (path):lower ():match ("%.json$") then
			local readOk, content = pcall (readfile, path)
			if readOk and type (content) == "string" then
				local decodeOk, data = pcall (function ()
					return Dex.Services.HttpService:JSONDecode (content)
				end)
				if decodeOk and type (data) == "table" then
					local base = tostring (path):match ("([^/\\]+)$") or "Theme"
					local name = type (data.Name) == "string" and data.Name or base:gsub ("%.json$", "")
					if name ~= "" then
						local theme = decodeTheme (data)
						Dex.ThemePresets[name] = function ()
							return deepCopy (theme)
						end
						Filesystem.LoadedThemeFiles[path] = name
						loaded += 1
					end
				end
			end
		end
	end
	return loaded
end

function Filesystem:LoadPlugins ()
	if not canUseFiles () or type (listfiles) ~= "function" then return 0 end
	if not ensureFolder ("Dex/Plugins") then return 0 end
	local ok, paths = pcall (listfiles, "Dex/Plugins")
	if not ok or type (paths) ~= "table" then return 0 end
	table.sort (paths)
	local loaded = 0
	for _, path in ipairs (paths) do
		local name = tostring (path):match ("([^/\\]+)$") or tostring (path)
		if name:lower ():match ("%.lua$") then
			local readOk, source = pcall (readfile, path)
			if readOk and type (source) == "string" then
				local compile = rawget (genv, "loadstring") or loadstring
				if type (compile) == "function" then
					local compiled, chunk = pcall (compile, source, "@" .. name)
					if compiled and type (chunk) == "function" then
						local runOk, err = pcall (chunk)
						if runOk then
							Filesystem.LoadedPlugins[path] = true
							loaded += 1
						else
							notify ("Plugin " .. name .. " failed: " .. tostring (err), "error")
						end
					else
						notify ("Plugin " .. name .. " compile failed: " .. tostring (chunk), "error")
					end
				else
					notify ("loadstring unavailable; plugins were not loaded", "warning")
					break
				end
			end
		end
	end
	return loaded
end

function Filesystem:Init ()
	if not canUseFiles () then return false end
	ensureFolder ("Dex")
	ensureFolder ("Dex/Plugins")
	ensureFolder ("Dex/Themes")
	self:WriteStandardThemes ()
	self:LoadThemes ()
	return true
end

Filesystem:Init ()

local U = Dex.Utils

Dex.CurrentLayout = "Multi Windows"

function Dex:SetLayout ()
	self:ShowDefaultLayout ()
	return self.CurrentLayout
end

function Dex:ShowDefaultLayout ()
	self.CurrentLayout = "Multi Windows"
	self._SnappingDisabled = false
	local viewport = U.Viewport ()

	local explorer = self.Windows.Explorer
	local properties = self.Windows.Properties
	local output = self.Windows.Output
	if not explorer or not properties or not output then return end

	local outputHeight = math.clamp (math.floor (viewport.Y * 0.27), 160, 300)
	local dockWidth = self:GetRightDockWidth ()
	local dockX = math.max (0, viewport.X - dockWidth)
	local explorerHeight = math.max (180, math.floor (viewport.Y * 0.5))
	local propertiesHeight = math.max (0, viewport.Y - explorerHeight)

	if explorer.Maximized then explorer:SetMaximized (false) end
	if properties.Maximized then properties:SetMaximized (false) end
	if output.Maximized then output:SetMaximized (false) end

	explorer.EdgeDocked = true
	properties.EdgeDocked = true
	output.EdgeDocked = true

	explorer.GUI.Position = UDim2.fromOffset (dockX, 0)
	explorer.GUI.Size = UDim2.fromOffset (dockWidth, explorerHeight)

	properties.GUI.Position = UDim2.fromOffset (dockX, explorerHeight)
	properties.GUI.Size = UDim2.fromOffset (dockWidth, propertiesHeight)

	output.GUI.Position = UDim2.fromOffset (0, math.max (0, viewport.Y - outputHeight))
	output.GUI.Size = UDim2.fromOffset (dockX, outputHeight)

	explorer:SyncShadow ()
	properties:SyncShadow ()
	output:SyncShadow ()
	explorer:UpdateEdgeCorners ()
	properties:UpdateEdgeCorners ()
	output:UpdateEdgeCorners ()

	explorer:Focus ()
end

Dex:LoadConfig ()
local savedTheme = Dex.Config.Data.Theme
if savedTheme and Dex.ThemePresets[savedTheme] then Dex:ApplyTheme (savedTheme) end

Dex:Track (Dex.ViewportChanged:Connect (function ()
	Dex:AlignBottomDock ()
end))

task.spawn (function ()
	pcall (function ()
		Dex.Bypass:Enable ()
	end)
end)

Dex.Reflect:Load ()

Dex:CreateScreenGui ()

Dex.Explorer:Create ()
Dex.Properties:Create ()
Dex.Output:Create ()

if Dex.Reflect.Source then
	Dex.Output:AddLocal ("[Dex] API dump loaded from " .. Dex.Reflect.Source, "info")
else
	local message = Dex.Reflect.FetchUnavailable
			and "A HTTP function is required to load the API dump: game:HttpGet, request, http_request or syn.request."
		or "API dump unavailable — property data is limited."
	Dex.Output:AddLocal ("[Dex] " .. message, "error")
	Dex:Notify (message, "error")
end

local cfg = Dex.Config.Data

Dex._ApplyingSavedLayout = true
Dex:SetLayout ()
if cfg.LayoutVersion == Dex.LayoutVersion then
	Dex:RestoreWindowConfigs ()
else
	cfg.Windows = nil
	cfg.LayoutVersion = Dex.LayoutVersion
	Dex:SaveConfig ()
end
Dex._ApplyingSavedLayout = false

Dex.Windows.Explorer:Show ()
Dex.Windows.Properties:Show ()
Dex.Windows.Output:Show ()
Dex.Windows.Explorer:Focus ()
Dex.Launcher:Create ()

if cfg.PerformanceMode ~= nil then Dex.PerformanceMode = cfg.PerformanceMode == true end
if cfg.SortByName then
	Dex.Explorer.SortByName = true
	Dex.Explorer:InvalidateChildrenCache ()
end
if cfg.ShowTimestamps == false then Dex.Output.ShowTimestamps = false end
if cfg.SelectionHighlight then Dex.SelectionHighlight:SetEnabled (true) end
if cfg.ConsoleDetection then task.spawn (function ()
	pcall (function ()
		Dex.ConsoleBypass:Enable ()
	end)
end) end

Dex.Output:AddLocal ("[Dex] Studio Edition " .. Dex.Version .. " loaded — Explorer, Properties, Output", "success")