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


