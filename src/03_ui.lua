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


