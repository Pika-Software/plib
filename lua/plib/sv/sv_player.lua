hook.Add("PlayerInitialSpawn", "PLib:PlayerInitialized", function(ply)
	hook.Add("SetupMove", ply, function( self, ply, _, cmd )
		if (self == ply) and not cmd:IsForced() then
			hook.Run("PLib:PlayerInitialized", self)
			hook.Remove("SetupMove", self)
			self["Initialized"] = true
		end
	end)
end)

function PLib:SendAchievements(ply)
	net.Start("PLib")
		net.WriteUInt(0, 3)
		net.WriteCompressTable(self["Achievements"])
	net.Send(ply)
end

function PLib:BroadcastAchievements()
	net.Start("PLib")
		net.WriteUInt(0, 3)
		net.WriteCompressTable(self["Achievements"])
	net.Broadcast()
end

function PLib:AddAchievement(tag, options)
	if (self["Achievements"][tag] == nil) then
		self["Achievements"][tag] = {
			[1] = options["title"] or "Title",
			[2] = options["icon"],
			[3] = options["clientside"] or false,
		}

		if (self["Loaded"] == true) then
			self:BroadcastAchievements()
		end
	end
end

hook.Add("PLib:PlayerInitialized", "PLib:SendAchievements", function(ply)
	PLib:SendAchievements(ply)
end)

-- PLib:AddAchievement("string", {
-- 	["title"] = "string",
-- 	["icon"] = "string",
-- 	["clientside"] = false,
-- })

PLib:AddAchievement("plib.i_see_my_shadow", {
	["title"] = "#plib.i_see_my_shadow",
	["icon"] = "https://apps.g-mod.su/pictures/images/1633769190910cdaf.png",
	["clientside"] = true,
})

hook.Add("PlayerInitialSpawn", "PLib:GoodGuysAchievementAdd", function(ply)
	local steamid64 = ply:SteamID64()
	if (PLib["GoodGuys"][steamid64] == true) then
		PLib:SteamUserData(steamid64, function(tbl)
			PLib:AddAchievement("plib.gg_"..steamid64, {
				["title"] = "#plib.meet_the".." "..tbl["personaname"],
				["icon"] = tbl["avatarfull"],
				["clientside"] = true,
			})
		end)
	end
end)

PLib:AddAchievement("plib.i_see_my_shadow", {
	["title"] = "#plib.i_see_my_shadow",
	["icon"] = "https://apps.g-mod.su/pictures/images/1633769190910cdaf.png",
	["clientside"] = true,
})

local PLAYER = FindMetaTable("Player")
local isstring = isstring

function PLAYER:SetNick(name)
	if isstring(name) then
		self:SetNWString("Nickname", name)

		return true
	end

	return false
end

PLAYER["SetName"] = PLAYER["SetNick"]

function PLAYER:PNotify(title, text, style, lifetime, image, animated)
    net_Start("PLib")
        net.WriteUInt(2, 3)
        net.WriteString(title)
        net.WriteString(text)
        net.WriteString(style)
        net.WriteUInt(lifetime, 8)
        net.WriteString(image)
        net.WriteBool(animated)
    net.Send(self)
end