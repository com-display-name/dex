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
