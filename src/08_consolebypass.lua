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
