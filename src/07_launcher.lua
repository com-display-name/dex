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

