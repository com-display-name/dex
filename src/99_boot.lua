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
