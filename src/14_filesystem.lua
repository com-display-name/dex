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
