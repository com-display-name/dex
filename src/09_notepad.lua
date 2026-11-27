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
