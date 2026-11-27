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
