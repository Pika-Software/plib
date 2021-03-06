local validStr = string["isvalid"]
local game_GetMap = game.GetMap
local dprint = PLib["dprint"]

function PLib:IsValidMap(map)
	if not validStr(map) then
		dprint("Error", "Invalid map name!")
		return false
	end

	if (PLib.GetMap() == map) then
		dprint("Error", "Map ", map, " is current map!")
		return false
	end

	if not table.HasValue(self:GetMapList(), map) then
		dprint("Error", "Map ", map, " not exist!")
		return false
	end

	return true
end

function PLib:ChangeMap(map)
	if not self:IsValidMap(map) then
		return false
	end

	self:Log(nil, self["_C"]["warn"], "Change map to ", map, "!")
	timer.Simple(0, function()
		RunConsoleCommand("changelevel", map)
	end)

	return true
end

function PLib:GetHostName()
	return cvars.String("hostname", GetHostName())
end

function PLib:SetHostName(str, distableNotify)
	if isstring(str) then
		if (distableNotify == nil) then
			self:Log(nil, string.format("Server hostname changed from '%s' to '%s'!", self:GetHostName(), str))
		end

		RunConsoleCommand("hostname", str)

		net.Start("PLib")
			net.WriteUInt(5, 3)
			net.WriteString(str)
		net.Broadcast()
	end
end

local string_find = string.find
concommand.Add("plib_map", function(ply, cmd, args)
	if IsValid(ply) then
		if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
			if (PLib:ChangeMap(args[1]) == false) then
				PLib:Log(nil, ply, " trying change server map to ", args[1])
			else
				PLib:Log(nil, ply, " changed server map to ", args[1])
			end
		end
	else
		PLib:ChangeMap(args[1])
	end
end, function(cmd, args)
	local tbl = {}
	local maps = PLib:GetMapList()
	local arg = args:Trim():lower()
	for i = 1, #maps do
		local map = maps[i]
		if string_find(map:lower(), arg) then
			map = "\"" .. map .. "\""
			map = cmd .. " " .. map

			table.insert(tbl, map)
		end
	end

	return tbl
end, "Server map change (only for superadmins)", {FCVAR_LUA_CLIENT, FCVAR_LUA_SERVER})

function PLib:SetGameDifficulty(difficulty)
    local name, id = "Normal", 2

    if isstring(difficulty) then
        for num, diff in ipairs(self["Difficulties"]) do
            if (diff == difficulty) then
                id = num; name = diff;
                break
            end
        end
    elseif isnumber(difficulty) then
        for num, diff in ipairs(self["Difficulties"]) do
            if (num == difficulty) then
                id = num; name = diff;
                break
            end
        end
    else
        Error("bad argument #1 (string or number expected)")
        return
    end

    local oldID = self:GameDifficulty()
    if (oldID == id) then
        return 
    end

    hook.Run("PLib:GameDifficulty", oldID, id)

    game.SetSkillLevel(id)
    RunConsoleCommand("skill", id)
    self:Log(nil, string.format("Game difficulty changed to -> %s (%s)", name, id))
end

local workshop = CreateConVar("plib_workshop", "1", {FCVAR_ARCHIVE, FCVAR_LUA_SERVER}, "Adds all server addons to client download list. (0/1)", 0, 1)
cvars.AddChangeCallback("plib_workshop", function(name, old, new)
	PLib:CheckWorkshopLoadList()
end, "PLib")

function PLib:CheckWorkshopLoadList()
	if workshop:GetBool() then
		PLib:SteamWorkshop()
	end
end

hook.Add("PLib:GameLoaded", "PLib:Functions", function()
	PLib:CheckWorkshopLoadList()
end)

local math_random = math.random
PLib["MAT_"] = {
	[MAT_DEFAULT] = function()
		return 1
	end,
	[MAT_WARPSHIELD] = function()
		return 10000
	end,
	[MAT_SLOSH] = function()
		return 997
	end,
	[MAT_WOOD] = function()
		return math_random(150, 300)
	end,
	[MAT_SNOW] = function()
		return math_random(200, 600)
	end,
	[MAT_PLASTIC] = function()
		return math_random(850, 1800)
	end,
	[MAT_CLIP] = function()
		return PLib["MAT_"][MAT_PLASTIC]()
	end,
	[MAT_SAND] = function()
		return math_random(1450, 1550)
	end,
	[MAT_GLASS] = function()
		return math_random(2500, 2600)
	end,
	[MAT_DIRT] = function()
		return math_random(1340, 1900)
	end,
	[MAT_CONCRETE] = function()
		return math_random(2200, 2500)
	end,
	[MAT_METAL] = function()
		return math_random(7700, 7900)
	end,
	[MAT_TILE] = function()
		return math_random(5500, 5800)
	end,
	[MAT_COMPUTER] = function()
		return PLib["MAT_"][MAT_METAL]() * 0.8
	end,
	[MAT_GRATE] = function()
		return PLib["MAT_"][MAT_METAL]() * 1.5
	end,
	[MAT_VENT] = function()
		return PLib["MAT_"][MAT_METAL]() * 0.1
	end,
	[MAT_FLESH] = function()
		return math_random(1077, 1110)
	end,
	[MAT_BLOODYFLESH] = function()
		return PLib["MAT_"][MAT_FLESH]()
	end,
	[MAT_ALIENFLESH] = function()
		return PLib["MAT_"][MAT_FLESH]() * 0.8
	end,
	[MAT_FOLIAGE] = function()
		return PLib["MAT_"][MAT_FLESH]() * 0.5
	end,
	[MAT_ANTLION] = function()
		return PLib["MAT_"][MAT_FLESH]() * 2
	end,
	[MAT_EGGSHELL] = function()
		return PLib["MAT_"][MAT_ANTLION]() * 2
	end
}

local ENTITY = FindMetaTable("Entity")
function ENTITY:GetMass()
	if (self["PLib.Mass"] == nil) then
		local mass = PLib["MAT_"][self:GetMaterialType()] -- in pika units ^3
		if (mass != nil) then
			mass = mass() * self:GetSize() * 0.01
		else
			mass = self:GetSize()
		end

		self["PLib.Mass"] = mass or 0
	end

	return self["PLib.Mass"]
end

function PLib:SafeRemoveEntityFaded(ent, t)
	if not IsValid(ent) then return end
	local d = t / 255
	local tname = "PLibFadeRemove" .. ent:EntIndex()
	ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
	timer.Create(tname, d, 260, function()
		if not IsValid(ent) then
			timer.Remove(tname)
			return
		end
		local col = ent:GetColor()
		col.a = math.Clamp(col.a - d, 0, 255)
		ent:SetColor(col)
		if col.a == 0 then
			ent:Remove()
			timer.Remove(tname)
		end
	end)
end
