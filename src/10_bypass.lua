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
