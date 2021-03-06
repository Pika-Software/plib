local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_CreateFont = surface.CreateFont
local mesh_AdvanceVertex = mesh.AdvanceVertex
local table_SortByMember = table.SortByMember
local render_SetMaterial = render.SetMaterial
local getDesiredSize = PLib["GetDesiredSize"]
local surface_DrawRect = surface.DrawRect
local draw_SimpleText = draw.SimpleText
local system_IsLinux = system.IsLinux
local mesh_Position = mesh.Position
local validStr = string["isvalid"]
local table_insert = table.insert
local color_white = color_white
local math_Clamp = math.Clamp
local mesh_Begin = mesh.Begin
local mesh_Color = mesh.Color
local isURL = string["isURL"]
local mesh_End = mesh.End
local hook_Run = hook.Run
local isnumber = isnumber
local tostring = tostring
local istable = istable
local Vector = Vector
local pairs = pairs
local Error = Error
local Color = Color
local ScrW = ScrW
local ScrH = ScrH
local Msg = Msg

local isvalid = FindMetaTable("Entity").IsValid

local colors = PLib["_C"]
PLib["Fonts"] = {
	{
		["name"] = "PLib.Main1",
		["font"] = "Roboto",
		["size"] = 1.7,
	},
	{
		["name"] = "PLib.Main2",
		["font"] = "Roboto",
		["size"] = 2,
	},
	{
		["name"] = "PLib.Main3",
		["font"] = "Roboto",
		["size"] = 3,
	},
	{
		["name"] = "PLib.Main5",
		["font"] = "Roboto",
		["size"] = 5,
	}
}

local surface_GetTextSize = surface.GetTextSize
local surface_SetFont = surface.SetFont

local GetSizeCache = {}
function PLib.GetFontSize(text, font)
	local tag = font .. "_" .. text
	if (GetSizeCache[tag] == nil) then
		surface_SetFont(font)
		GetSizeCache[tag] = {surface_GetTextSize(text)}
	end

	return GetSizeCache[tag][1], GetSizeCache[tag][2]
end

local util_TableToJSON = util.TableToJSON
local util_CRC = util.CRC

function PLib:FontInit(name, font, size, tbl)
	local title = ""
	if validStr(name) then
		title = name
	else
		title = font .. "_" .. size
		if (#tbl > 2) then
			title = title .. "_#" .. util_CRC(util_TableToJSON(tbl))
		end
	end

	surface_CreateFont(title, {
		font = font,
		size = getDesiredSize(size),
		extended = isbool(tbl["extended"]) and tbl["extended"] or true,
		additive = isbool(tbl["additive"]) and tbl["additive"] or false,
		weight = isnumber(tbl["weight"]) and tbl["weight"] or 500,
		blursize = isnumber(tbl["blursize"]) and tbl["blursize"] or 0,
		scanlines = isnumber(tbl["scanlines"]) and tbl["scanlines"] or 0,
		antialias = isbool(tbl["antialias"]) and tbl["antialias"] or true,
		underline = isbool(tbl["underline"]) and tbl["underline"] or false,
		italic = isbool(tbl["italic"]) and tbl["italic"] or false,
		strikeout = isbool(tbl["strikeout"]) and tbl["strikeout"] or false,
		symbol = isbool(tbl["symbol"]) and tbl["symbol"] or false,
		rotary = isbool(tbl["rotary"]) and tbl["rotary"] or false,
		shadow = isbool(tbl["shadow"]) and tbl["shadow"] or false,
		outline = isbool(tbl["outline"]) and tbl["outline"] or false,
	})

	if self["Debug"] then
		self:Log("Fonts", "[", table_insert(self["GeneratedFonts"], title), "] Added: ", self["_C"]["print"], title)
	end
end

function PLib:AddFont(tbl)
	if not istable(tbl) or not validStr(tbl["font"]) or (tbl["size"] == nil) then
		Error("[Fonts] " .. self:Translate("plib.invalid_font_args"))
	end

	table_insert(self["Fonts"], tbl)
	self:ReBuildFonts()
end

function PLib:ReBuildFonts()
	Msg("\n")
	self["GeneratedFonts"] = {}
	local fonts = self["Fonts"]
	for i = 1, #fonts do
		local tbl = fonts[i]
		if not istable(tbl) then continue end

		local font = tbl["font"]
		if not validStr(font) then continue end

		local size = tbl["size"]
		if istable(size) then
			for j = 1, #size do
				self:FontInit(tbl["name"], font, size[j], tbl)
			end
		elseif isnumber(size) then
			self:FontInit(tbl["name"], font, size, tbl)
		end
	end

	hook_Run("PLib:FontsUpdated", self["GeneratedFonts"])
end

PLib:ReBuildFonts()

local mat_white = Material("vgui/white")
function draw.SimpleLinearGradient(x, y, w, h, startColor, endColor, horizontal)
	draw.LinearGradient(x, y, w, h, { {offset = 0, color = startColor}, {offset = 1, color = endColor} }, horizontal)
end

function draw.LinearGradient(x, y, w, h, stops, horizontal)
	if #stops == 0 then
		return
	elseif #stops == 1 then
		surface_SetDrawColor(stops[1].color)
		surface_DrawRect(x, y, w, h)
		return
	end

	table_SortByMember(stops, "offset", true)

	render_SetMaterial(mat_white)
	-- 7 = MATERIAL_QUADS
	mesh_Begin(7, #stops - 1)
	for i = 1, #stops - 1 do
		local offset1 = math_Clamp(stops[i].offset, 0, 1)
		local offset2 = math_Clamp(stops[i + 1].offset, 0, 1)
		if offset1 == offset2 then continue end

		local deltaX1, deltaY1, deltaX2, deltaY2

		local color1 = stops[i].color
		local color2 = stops[i + 1].color

		local r1, g1, b1, a1 = color1.r, color1.g, color1.b, color1.a
		local r2, g2, b2, a2
		local r3, g3, b3, a3 = color2.r, color2.g, color2.b, color2.a
		local r4, g4, b4, a4

		if horizontal then
			r2, g2, b2, a2 = r3, g3, b3, a3
			r4, g4, b4, a4 = r1, g1, b1, a1
			deltaX1 = offset1 * w
			deltaY1 = 0
			deltaX2 = offset2 * w
			deltaY2 = h
		else
			r2, g2, b2, a2 = r1, g1, b1, a1
			r4, g4, b4, a4 = r3, g3, b3, a3
			deltaX1 = 0
			deltaY1 = offset1 * h
			deltaX2 = w
			deltaY2 = offset2 * h
		end

		mesh_Color(r1, g1, b1, a1)
		mesh_Position(Vector(x + deltaX1, y + deltaY1))
		mesh_AdvanceVertex()

		mesh_Color(r2, g2, b2, a2)
		mesh_Position(Vector(x + deltaX2, y + deltaY1))
		mesh_AdvanceVertex()

		mesh_Color(r3, g3, b3, a3)
		mesh_Position(Vector(x + deltaX2, y + deltaY2))
		mesh_AdvanceVertex()

		mesh_Color(r4, g4, b4, a4)
		mesh_Position(Vector(x + deltaX1, y + deltaY2))
		mesh_AdvanceVertex()
	end
	mesh_End()
end

local w, h = 0, 0
function PLib:Draw2D(func)
	func(w, h)
end

local function ScreenSizeChanged()
	w, h = ScrW(), ScrH()

	PLib:UpdateLogo()

	hook.Run("PLib:ResolutionChanged", w, h)
	hook.Remove("PLib:PlayerInitialized", "PLib:2D_RE")
end

if (PLib["Loaded"] == true) then
	ScreenSizeChanged()
end

hook.Add("OnScreenSizeChanged", "PLib:2D_RE", ScreenSizeChanged)
hook.Add("PLib:PlayerInitialized", "PLib:2D_RE", ScreenSizeChanged)

local logo, logo_w, logo_h, ssw, ssh
local offset = CreateClientConVar("plib_logo_offset", "25", true, false, "Logo offset from the top right corner..."):GetInt()
cvars.AddChangeCallback("plib_logo_offset", function(name, old, new)
	offset = tonumber(new)
end, "PLib")

local plib_logo_enabled = CreateClientConVar("plib_logo", "0", true, false, "Displays the logo in the upper right corner. (0/1)", 0, 1)

local logo_enabled = false
local col = colors["logo"]
local function UpdateLogoState(bool)
	if bool then
		logo_enabled = true
		hook.Add("HUDPaint", "PLib:DrawLogo", function()
			surface_SetDrawColor(col)
			surface_SetMaterial(logo)
			surface_DrawTexturedRect(w - logo_w - offset, offset, logo_w, logo_h)
		end)
	else
		hook.Remove("HUDPaint", "PLib:DrawLogo")
		logo_enabled = false
		return
	end
end

UpdateLogoState(plib_logo_enabled:GetBool())

cvars.AddChangeCallback("plib_logo", function(name, old, new)
	UpdateLogoState(plib_logo_enabled:GetBool())
end, "PLib")

local plib_logo_url = CreateClientConVar("plib_logo_url", "https://i.imgur.com/j5DjzQ1.png", true, false, "Url to your logo :p (Need 1x0.25, example 190x65)")

function PLib:UpdateLogo(path)
	if (self["ServerLogo"] == nil) then
		local cvarLogo = plib_logo_url:GetString()
		path = isURL(path) and path or (isURL(cvarLogo) and cvarLogo or "https://i.imgur.com/j5DjzQ1.png")
		if (path ~= nil) then
			Material(path, PLib["MatPresets"]["Pic"], function(mat)
				logo = mat
				logo_w, logo_h = mat:GetSize()
				ssw, ssh = (w - logo_w) / 2, (h - logo_h) / 2

				if self["Debug"] then
					self:Log(nil, "Logo updated!")
				end
			end)
		end
	else
		logo = self["ServerLogo"]
		logo_w, logo_h = logo:GetSize()
		ssw, ssh = (w - logo_w) / 2, (h - logo_h) / 2

		if self["Debug"] then
			self:Log(nil, "Logo updated!")
		end

		timer.Simple(0, function()
			UpdateLogoState(plib_logo_enabled:GetBool())
		end)
	end
end

PLib:UpdateLogo(plib_logo_url:GetString())

cvars.AddChangeCallback("plib_logo_url", function(name, old, new)
	PLib:UpdateLogo(plib_logo_url:GetString())
end, "PLib")

function PLib:StandbyScreen()
	surface_SetDrawColor(color_white)
	surface_SetMaterial(logo)
	surface_DrawTexturedRect(ssw, ssh, logo_w, logo_h)
end

local grey = colors["dgrey"]
local greyBG = grey
greyBG:SetAlpha(200)

local getFontSize = PLib["GetFontSize"]

local devEntData, devEnt
local devHFont = "DermaDefault"

local cam_End3D = cam.End3D
local math_floor = math.floor
local cam_Start3D = cam.Start3D
local draw_RoundedBox = draw.RoundedBox
local render_DrawLine = render.DrawLine
local render_DrawWireframeBox = render.DrawWireframeBox

local red = Color(255, 0, 0)
local green = Color(0, 255, 0)
local blue = Color(0, 0, 255)
local yellow = Color(255, 221, 30)

function PLib:DebugEntityDraw(ent)
	if (self["Debug"] == true) then
		local mins, maxs = ent:OBBMins(), ent:OBBMaxs() --ent:GetModelBounds()
		local cmins, cmaxs = ent:GetCollisionBounds()
		local pos = ent:GetPos()
		local angle = ent:GetAngles()
		render_DrawWireframeBox(pos, angle, cmins, cmaxs, red, true)
		render_DrawWireframeBox(pos, angle, mins, maxs, ent:GetColor(), true)

		local center = ent:OBBCenter()
		center:Rotate(angle)

		local centerpos = pos + center
		render_DrawLine(centerpos, centerpos + 8 * angle:Forward(), red, true)
		render_DrawLine(centerpos, centerpos + 8 * -angle:Right(), green, true)
		render_DrawLine(centerpos, centerpos + 8 * angle:Up(), blue, true)

		local parent = ent:GetParent()
		if isvalid(parent) then
			local pcenter = parent:OBBCenter()
			render_DrawLine(centerpos, parent:GetPos() + pcenter, yellow, true)
		end
	end
end

local dy = colors["dy"]
function PLib.DrawCenteredList(lst, y)
	local len = #lst
	for num, tbl in ipairs(lst) do
		if not istable(tbl) then tbl = {tbl} end
		local x = (w / 2 - 90 * len / 2) + (5 + 90 * (num - 1))
		draw_RoundedBox(5, x, y - 35, 80, 30, tbl[3] or greyBG)
		draw_SimpleText(tbl[1] or "None", devHFont, 40 + x, y - 20, tbl[2] or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local developer
local os_date = os.date
local util_TraceLine = util.TraceLine
local string_format = string.format

local function drawDeveloperHUD()
	if not PLib:DebugAllowed() then return end

	PLib.DrawCenteredList({
		"FPS: " .. math_floor(1 / FrameTime()),
		"PING: " .. developer:Ping(),
		os_date("%H:%M"),
		"Speed: " .. math_floor(developer:GetRawSpeed()),
	}, getDesiredSize(4))

	if (devEntData == nil) then return end
	if isvalid(devEnt) then
		cam_Start3D()
			PLib:DebugEntityDraw(devEnt)
		cam_End3D()
	end

	local devHW = 50
	for i = 1, #devEntData do
		local strsize = getFontSize(devEntData[i], devHFont) + 30
		if (strsize > devHW) then
			devHW = strsize
		end
	end

	local x, y = w - devHW, ((logo_enabled ~= false) and logo_h * 2 or 0)
	draw_RoundedBox(15, x, y, devHW, #devEntData * 20 + 20, greyBG)

	for i = 1, #devEntData do
		draw_SimpleText(devEntData[i], devHFont, x + 15, y + 20 * i, (i % 2 == 1) and dy or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

local function devGetEntData()
	if (developer == nil) then return end
	if (developer:Alive() == false) then
		devEntData = nil
		return
	end

	local startPos = developer:EyePos()
	local tr = util_TraceLine({
		["start"] = startPos,
		["endpos"] = startPos + (developer:GetAimVector() * 1000),
		["filter"] = developer,
	})

	if (tr["Hit"] == true) then
		local ent = tr["Entity"]
		devEntData = {}
		table_insert(devEntData, "Index: " .. ent:EntIndex())
		if (tr["HitPos"] == startPos) then
			table_insert(devEntData, "Name: Void")
			devEnt = ent
			return
		end

		table_insert(devEntData, "Name: " .. PLib:TranslateText(ent:IsPlayer() and ent:Nick() or (ent["PrintName"] or "World")))
		table_insert(devEntData, "Model: " .. ent:GetModel())
		table_insert(devEntData, "ClassName: " .. ent:GetClass())

		local parent = ent:GetParent()
		if isvalid(parent) then
			table_insert(devEntData, "Parent: " .. tostring(parent))
		end

		if isvalid(ent) then
			local pos = ent:GetPos():Floor()
			local ang = ent:GetAngles():Floor()
			table_insert(devEntData, string_format("Pos: Vector(%s, %s, %s)", pos[1], pos[2], pos[3]))
			table_insert(devEntData, string_format("Ang: Angle(%s, %s, %s)", ang[1], ang[2], ang[3]))
			table_insert(devEntData, string_format("Health: %s/%s", ent:Health(), ent:GetMaxHealth()))

			if ent:IsPlayer() then
				table_insert(devEntData, "UserID: " .. ent:UserID())
			end

			local ent_info = {}
			local maxLen = 0
			for key, value in pairs(ent:GetTable()) do
				if isfunction(value) or (key == "ClassName") or (key == "PrintName") or (key == "Entity") then continue end
				if (key == "BaseClass") and istable(value) then value = value["ClassName"] end
				if (value == "") then continue end
				local text = (key .. ": " .. tostring(istable(value) and ("table <" .. #value .. ">") or value))
				if text:len() > 85 then
					text = text:sub(1, 85) .. "..."
				end
				surface.SetFont(devHFont)
				local len = surface.GetTextSize(text)
				if (len > maxLen) then
					maxLen = len
				end

				table_insert(ent_info, text)
			end

			if (#ent_info > 0) then
				local separator = "???"
				local separator_len = surface.GetTextSize(separator)
				for i = 1, math.floor(maxLen / separator_len) do
					separator = separator .. "???"
				end

				table_insert(devEntData, separator)

				for num, text in ipairs(ent_info) do
					table_insert(devEntData, text)
				end
			end
		end

		devEnt = ent
	end
end

hook.Add("PLib:PlayerInitialized", "PLib:DeveloperHUD", function(ply)
	developer = ply
end)

if (PLib["Loaded"] == true) then
	developer = LocalPlayer()
end

local function toggleDevHUD(bool)
	if (bool == true) then
		hook.Add("HUDPaint", "PLib:DeveloperHUD", drawDeveloperHUD)
		timer.Create("PLib:DeveloperHUD_ResetEnt", 0.5, 0, devGetEntData)
	else
		hook.Remove("HUDPaint", "PLib:DeveloperHUD")
		timer.Remove("PLib:DeveloperHUD_ResetEnt")
	end
end

toggleDevHUD(PLib["Debug"])
hook.Add("PLib:Debug", "PLib:DeveloperHUD", toggleDevHUD)

function PLib:ReplaceDefaultFont(new, sizeMult, underline)
	if system_IsLinux() then
		surface_CreateFont("DermaDefault", {
			font        = new or "DejaVu Sans",
			size        = 14 * (sizeMult or 1),
			weight        = 500,
			extended    = true
		})

		surface_CreateFont("DermaDefaultBold", {
			font        = new or "DejaVu Sans",
			size        = 14 * (sizeMult or 1),
			weight        = 800,
			extended    = true
		})
	else
		surface_CreateFont("DermaDefault", {
			font        = new or "Tahoma",
			size        = 13 * (sizeMult or 1),
			weight        = 500,
			extended    = true
		})

		surface_CreateFont("DermaDefaultBold", {
			font        = new or "Tahoma",
			size        = 13 * (sizeMult or 1),
			weight        = 800,
			extended    = true
		})
	end

	surface_CreateFont("DermaLarge", {
		font        = new or "Roboto",
		size        = 32 * (sizeMult or 1),
		weight        = 500,
		extended    = true
	})

	self:SpawnMenuReload()
end

function PLib:ResetDefaultFonts()
	self:ReplaceDefaultFont()
end

-- PLib:ReplaceDefaultFont("Bender")
-- PLib:ReplaceDefaultFont("Circular Std Bold")

-- PLib:ReplaceDefaultFont("Codename Coder Free 4F", 1.2)

-- PLib:ReplaceDefaultFont("GTA Russian", 1.2)
-- PLib:ReplaceDefaultFont("HACKED", 1.2)