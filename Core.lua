--[[
	Core.lua is intended to store all core functions and variables to be used throughout the addon. 
	Don't put anything in here that you don't want to be loaded immediately after the Libs but before initialization.
--]]

local _, core = ...;
local _G = _G;
local L = core.L;

core.DWP = {};       -- UI Frames global
local DWP = core.DWP;

local tc_colors = {
	["Druid"] = { r = 1, g = 0.49, b = 0.04, hex = "FF7D0A" },
	["Hunter"] = {  r = 0.67, g = 0.83, b = 0.45, hex = "ABD473" },
	["Mage"] = { r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB" },
	["Priest"] = { r = 1, g = 1, b = 1, hex = "FFFFFF" },
	["Rogue"] = { r = 1, g = 0.96, b = 0.41, hex = "FFF569" },
	["Shaman"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
	["Paladin"] = { r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA" },
	["Warlock"] = { r = 0.53, g = 0.53, b = 0.93, hex = "8787ED" },
	["Warrior"] = { r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E" }
}

local tc_classes = {}

core.faction = UnitFactionGroup("player")
if core.faction == "Horde" then
	tc_classes = { "Druid", "Hunter", "Mage", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
elseif core.faction == "Alliance" then
	tc_classes = { "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Warlock", "Warrior" }
end

core.CColors = {
	["UNKNOWN"] = { r = 0.627, g = 0.627, b = 0.627, hex = "A0A0A0" }
}
core.classes = {}
for i = 1, #tc_classes do
	local cname = tc_classes[i]
	local lname = string.upper(cname)
	core.CColors[lname] = tc_colors[cname]
	table.insert(core.classes, lname)
end

--------------------------------------
-- Addon Defaults
--------------------------------------
local defaults = {
	theme = { r = 0.6823, g = 0.6823, b = 0.8666, hex = "aeaedd" },
	theme2 = { r = 1, g = 0.37, b = 0.37, hex = "ff6060" }
}

core.WorkingTable = {};       -- table of all entries from DWPlus_RPTable that are currently visible in the window. From DWPlus_RPTable
core.EncounterList = {      -- Event IDs must be in the exact same order as core.BossList declared in localization files
	MC = {
		663, 664, 665,
		666, 668, 667, 669,
		670, 671, 672
	},
	BWL = {
		610, 611, 612,
		613, 614, 615, 616,
		617
	},
	AQ = {
		709, 711, 712,
		714, 715, 717,
		710, 713, 716
	},
	NAXX = {
		1107, 1110, 1116,
		1117, 1112, 1115,
		1113, 1109, 1121,
		1118, 1111, 1108, 1120,
		1119, 1114
	},
	ZG = {
		787, 790, 793, 789, 784, 791,
		785, 792, 786, 788
	},
	AQ20 = {
		722, 721, 719, 718, 720, 723
	},
	ONYXIA = {1084},
	WORLD = {     -- No encounter IDs have been identified for these world bosses yet
		"Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Ysondre", "Taerar"
	}
}

core.DWPUI = {}        -- global storing entire Configuration UI to hide/show UI
core.MonVersion = "v1.1.0";
core.BuildNumber = 10100;
core.TableWidth, core.TableRowHeight, core.TableNumRows = 500, 18, 27; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.IsOfficer = nil;
core.ShowState = false;
core.StandbyActive = false;
core.currentSort = "class"		-- stores current sort selection
core.BidInProgress = false;   -- flagged true if bidding in progress. else; false.
core.RaidInProgress = false;
core.NumLootItems = 0;        -- updates on LOOT_OPENED event
core.Initialized = false
core.InitStart = false
core.CurrentRaidZone = ""
core.LastKilledBoss = ""
core.ArchiveActive = false
core.CurView = "all"
core.CurSubView = "all"
core.LastVerCheck = 0
core.CenterSort = "class";
core.OOD = false

function DWP:GetCColors(class)
	if core.CColors then
	local c
		if class then
		c = core.CColors[class] or core.CColors["UNKNOWN"];
	else
		c = core.CColors
	end
		return c;
	else
		return false;
	end
end

function DWP_round(number, decimals)
		return tonumber((("%%.%df"):format(decimals)):format(number))
end

function DWP:ResetPosition()
	DWP.UIConfig:ClearAllPoints();
	DWP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	DWP.UIConfig:SetSize(550, 590);
	DWP.UIConfig.TabMenu:Hide()
	DWP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\expand-arrow");
	core.ShowState = false;
	DWP.BidTimer:ClearAllPoints()
	DWP.BidTimer:SetPoint("CENTER", UIParent)
	DWP:Print(L["POSITIONRESET"])
end

function DWP:GetGuildRank(player)
	local name, rank, rankIndex;
	local guildSize;

	if IsInGuild() then
		guildSize = GetNumGuildMembers();
		for i=1, guildSize do
			name, rank, rankIndex = GetGuildRosterInfo(i)
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if name == player then
				return rank, rankIndex;
			end
		end
		return L["NOTINGUILD"];
	end
	return L["NOGUILD"]
end

function DWP:GetGuildRankIndex(player)
	local name, rank;
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if name == player then
				return rank+1;
			end
		end
		return false;
	end
end

function DWP:CheckOfficer()      -- checks if user is an officer IF core.IsOfficer is empty. Use before checks against core.IsOfficer
	if not core.InitStart then return end
	if core.IsOfficer == nil then      -- used as a redundency as it should be set on load in init.lua GUILD_ROSTER_UPDATE event
		if DWP:GetGuildRankIndex(UnitName("player")) == 1 then       -- automatically gives permissions above all settings if player is guild leader
			core.IsOfficer = true
			DWP.ConfigTab3.WhitelistContainer:Show()
			return;
		end
		if IsInGuild() then
			if #DWPlus_Whitelist > 0 then
				core.IsOfficer = false;
				for i=1, #DWPlus_Whitelist do
					if DWPlus_Whitelist[i] == UnitName("player") then
						core.IsOfficer = true;
					end
				end
			else
				local curPlayerRank = DWP:GetGuildRankIndex(UnitName("player"))
				if curPlayerRank then
					core.IsOfficer = C_GuildInfo.GuildControlGetRankFlags(curPlayerRank)[12]
				end
			end
		else
			core.IsOfficer = false;
		end
	end
end

function DWP:GetGuildRankGroup(index)                -- returns all members within a specific rank index as well as their index in the guild list (for use with GuildRosterSetPublicNote(index, "msg") and GuildRosterSetOfficerNote)
	local name, rank --, seed;                               -- local temp = DWP:GetGuildRankGroup(1)
	local group = {}                                      -- print(temp[1]["name"])
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			--seed = DWP:RosterSeedExtract(i)
			rank = rank+1;
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if rank == index then
				--tinsert(group, { name = name, index = i, seed = seed })
				tinsert(group, { name = name, index = i })
			end
		end
		return group;
	end
end

function DWP:CheckRaidLeader()
	local tempName,tempRank;

	for i=1, 40 do
		tempName, tempRank = GetRaidRosterInfo(i)

		if tempName == UnitName("player") and tempRank == 2 then
			return true
		end
	end
	return false;
end

function DWP:GetThemeColor()
	local c = {defaults.theme, defaults.theme2};
	return c;
end

function DWP:GetPlayerDKP(player)
	local search = DWP:Table_Search(DWPlus_RPTable, player)

	if search then
		return DWPlus_RPTable[search[1][1]].dkp
	else
		return false;
	end
end

function DWP:PurgeLootHistory()     -- cleans old loot history beyond history limit to reduce native system load
	local limit = DWPlus_DB.defaults.HistoryLimit

	if #DWPlus_Loot > limit then
		while #DWPlus_Loot > limit do
			DWP:SortLootTable()
			local path = DWPlus_Loot[#DWPlus_Loot]

			if not DWPlus_Archive[path.player] then
				DWPlus_Archive[path.player] = { dkp=path.cost, lifetime_spent=path.cost, lifetime_gained=0 }
			else
				DWPlus_Archive[path.player].dkp = DWPlus_Archive[path.player].dkp + path.cost
				DWPlus_Archive[path.player].lifetime_spent = DWPlus_Archive[path.player].lifetime_spent + path.cost
			end
			if not DWPlus_Archive.LootMeta or DWPlus_Archive.LootMeta < path.date then
				DWPlus_Archive.LootMeta = path.date
			end

			tremove(DWPlus_Loot, #DWPlus_Loot)
		end
	end
end

function DWP:PurgeDKPHistory()     -- purges old entries and stores relevant data in each users DWPlus_Archive entry (dkp, lifetime spent, and lifetime gained)
	local limit = DWPlus_DB.defaults.DKPHistoryLimit

	if #DWPlus_RPHistory > limit then
		while #DWPlus_RPHistory > limit do
			DWP:SortDKPHistoryTable()
			local path = DWPlus_RPHistory[#DWPlus_RPHistory]
			local players = {strsplit(",", string.utf8sub(path.players, 1, -2))}
			local dkp = {strsplit(",", path.dkp)}

			if #dkp == 1 then
				for i=1, #players do
					dkp[i] = tonumber(dkp[1])
				end
			else
				for i=1, #dkp do
					dkp[i] = tonumber(dkp[i])
				end
			end

			for i=1, #players do
				if not DWPlus_Archive[players[i]] then
					if ((dkp[i] > 0 and not path.deletes) or (dkp[i] < 0 and path.deletes)) and not strfind(path.dkp, "%-%d*%.?%d+%%") then
						DWPlus_Archive[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=dkp[i] }
					else
						DWPlus_Archive[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=0 }
					end
				else
					DWPlus_Archive[players[i]].dkp = DWPlus_Archive[players[i]].dkp + dkp[i]
					if ((dkp[i] > 0 and not path.deletes) or (dkp[i] < 0 and path.deletes)) and not strfind(path.dkp, "%-%d*%.?%d+%%") then 	--lifetime gained if dkp addition and not a delete entry, dkp decrease and IS a delete entry
						DWPlus_Archive[players[i]].lifetime_gained = DWPlus_Archive[players[i]].lifetime_gained + path.dkp 				--or is NOT a decay
					end
				end
			end
			if not DWPlus_Archive.DKPMeta or DWPlus_Archive.DKPMeta < path.date then
				DWPlus_Archive.DKPMeta = path.date
			end

			tremove(DWPlus_RPHistory, #DWPlus_RPHistory)
		end
	end
end

function DWP:FormatTime(time)
	local str = date("%y/%m/%d %H:%M:%S", time)

	return str;
end

function DWP:Print(...)        --print function to add "DWPlus:" to the beginning of print() outputs.
	if not DWPlus_DB.defaults.supressNotifications then
		local defaults = DWP:GetThemeColor();
		local prefix = string.format("|cff%s%s|r|cff%s", defaults[1].hex:upper(), "DW Plus:", defaults[2].hex:upper());
		local suffix = "|r";

		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i)

			if DWPlus_DB.defaults.ChatFrames[name] then
				_G["ChatFrame"..i]:AddMessage(string.join(" ", prefix, ..., suffix));
			end
		end
	end
end

function DWP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
	local btn = CreateFrame("Button", nil, relativeFrame, "DWPlusButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
	btn:SetSize(100, 30);
	btn:SetText(text);
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	btn:SetNormalFontObject("DWPSmallCenter");
	btn:SetHighlightFontObject("DWPSmallCenter");
	return btn;
end

function DWP:BroadcastTimer(seconds, ...)       -- broadcasts timer and starts it natively
	if IsInRaid() and core.IsOfficer == true then
		local title = ...;
		if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
			DWP:Print(L["INVALIDTIMER"]);
			return;
		end
		DWP:StartTimer(seconds, ...)
		DWP.Sync:SendData("DWPCommand", "StartTimer,"..seconds..","..title)
	end
end

function DWP:CreateContainer(parent, name, header)
	local f = CreateFrame("Frame", "DWP"..name, parent);
	f:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,0.5)

	f.header = CreateFrame("Frame", "DWP"..name.."Header", f)
	f.header:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.header:SetBackdropColor(0,0,0,1)
	f.header:SetBackdropBorderColor(0,0,0,1)
	f.header:SetPoint("LEFT", f, "TOPLEFT", 20, 0)
	f.header.text = f.header:CreateFontString(nil, "OVERLAY")
	f.header.text:SetFontObject("DWPSmallCenter");
	f.header.text:SetPoint("CENTER", f.header, "CENTER", 0, 0);
	f.header.text:SetText(header);
	f.header:SetWidth(f.header.text:GetWidth() + 10)
	f.header:SetHeight(f.header.text:GetHeight() + 4)

	return f;
end

function DWP:StartTimer(seconds, ...)
	local duration = tonumber(seconds)
	local alpha = 1;

	if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
		DWP:Print(L["INVALIDTIMER"]);
		return;
	end

	DWP.BidTimer = DWP.BidTimer or DWP:CreateTimer();    -- recycles timer frame so multiple instances aren't created
	DWP.BidTimer:SetShown(not DWP.BidTimer:IsShown())         -- shows if not shown
	if DWP.BidTimer:IsShown() == false then                    -- terminates function if hiding timer
		return;
	end

	DWP.BidTimer:SetMinMaxValues(0, duration)
	DWP.BidTimer.timerTitle:SetText(...)
	PlaySound(8959)

	if DWPlus_DB.timerpos then
		local a = DWPlus_DB["timerpos"]                   -- retrieves timer's saved position from SavedVariables
		DWP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	else
		DWP.BidTimer:SetPoint("CENTER")                      -- sets to center if no position has been saved
	end

	local timer = 0             -- timer starts at 0
	local timerText;            -- count down when below 1 minute
	local modulo                -- remainder after divided by 60
	local timerMinute           -- timerText / 60 to get minutes.
	local audioPlayed = false;  -- so audio only plays once
	local expiring;             -- determines when red blinking bar starts. @ 30 sec if timer > 120 seconds, @ 10 sec if below 120 seconds

	DWP.BidTimer:SetScript("OnUpdate", function(self, elapsed)   -- timer loop
		timer = timer + elapsed
		timerText = DWP_round(duration - timer, 1)
		if tonumber(timerText) > 60 then
			timerMinute = math.floor(tonumber(timerText) / 60, 0);
			modulo = bit.mod(tonumber(timerText), 60);
			if tonumber(modulo) < 10 then modulo = "0"..modulo end
			DWP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
		else
			DWP.BidTimer.timertext:SetText(timerText)
		end
		if duration >= 120 then
			expiring = 30;
		else
			expiring = 10;
		end
		if tonumber(timerText) < expiring then
			if audioPlayed == false then
				PlaySound(23639);
			end
			if tonumber(timerText) < 10 then
				audioPlayed = true
				StopSound(23639)
			end
			DWP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
			if alpha > 0 then
				alpha = alpha - 0.005
			elseif alpha <= 0 then
				alpha = 1
			end
		else
			DWP.BidTimer:SetStatusBarColor(0, 0.8, 0)
		end
		self:SetValue(timer)
		if timer >= duration then
			DWP.BidTimer:SetScript("OnUpdate", nil)
			DWP.BidTimer:Hide();
		end
	end)
end

function DWP:StatusVerify_Update()
	if (DWP.UIConfig and not DWP.UIConfig:IsShown()) or (#DWPlus_RPHistory == 0 and #DWPlus_Loot == 0) then     -- blocks update if dkp window is closed. Updated when window is opened anyway
		return;
	end

	if IsInGuild() and core.Initialized then
		core.OOD = false

		local missing = {}

		if DWPlus_Loot.seed and DWPlus_RPHistory.seed and strfind(DWPlus_Loot.seed, "-") and strfind(DWPlus_RPHistory.seed, "-") then
			local search_dkp = DWP:Table_Search(DWPlus_RPHistory, DWPlus_RPHistory.seed, "index")
			local search_loot = DWP:Table_Search(DWPlus_Loot, DWPlus_Loot.seed, "index")

			if not search_dkp then
				core.OOD = true
				local officer1, date1 = strsplit("-", DWPlus_RPHistory.seed)
				if (date1 and tonumber(date1) < (time() - 1209600)) or not DWP:ValidateSender(officer1) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date1 = date("%d/%m/%y %H:%M:%S", tonumber(date1))
					missing[officer1] = date1 			-- if both missing seeds identify the same officer, it'll only list once
				end
			end

			if not search_loot then
				core.OOD = true
				local officer2, date2 = strsplit("-", DWPlus_Loot.seed)
				if (date2 and tonumber(date2) < (time() - 1209600)) or not DWP:ValidateSender(officer2) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date2 = date("%d/%m/%y %H:%M:%S", tonumber(date2))
					missing[officer2] = date2
				end
			end
		end

		if not core.OOD then
			DWP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\up-to-date")
			DWP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ALLTABLES"].." |cff00ff00"..L["UPTODATE"].."|r.", 1.0, 1.0, 1.0, false);
				if core.IsOfficer then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			DWP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			return true;
		else
			DWP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\out-of-date")
			DWP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				if #DWPlus_Loot == 0 and #DWPlus_RPHistory == 0 then
					GameTooltip:AddLine(L["TABLESAREEMPTY"], 1.0, 1.0, 1.0, false);
				else
					GameTooltip:AddLine(L["ONETABLEOOD"].." |cffff0000"..L["OUTOFDATE"].."|r.", 1.0, 1.0, 1.0, false);
				end
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["MISSINGENT"]..":", 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(L["PLAYER"], L["CREATED"],1,1,1,1,1,1)
				for k,v in pairs(missing) do
					local classSearch = DWP:Table_Search(DWPlus_RPTable, k)

					if classSearch then
						c = DWP:GetCColors(DWPlus_RPTable[classSearch[1][1]].class)
					else
						c = { hex="ffffff" }
					end
					GameTooltip:AddDoubleLine("|cff"..c.hex..k.."|r",v,1,1,1,1,1,1);
				end
				if core.IsOfficer then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			DWP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			return false;
		end
	elseif core.Initialized then
		DWP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["CURRNOTINGUILD"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show()
		end)
		DWP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		return false;
	end
end

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: DWPlus_RPTable, "Player", "player" would only search for Player in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, DWPlus_RPTable[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be DWPlus_RPTable[search[1][1]][search[1][2]][search[1][3]].  DWPlus_RPTable[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
-------------------------------------
function DWP:Table_Search(tar, val, field)
	local value = string.upper(tostring(val));
	local location = {}
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			local temp1 = k
			for k,v in pairs(v) do
				if(type(v) == "table") then
					local temp2 = k;
					for k,v in pairs(v) do
						if(type(v) == "table") then
							local temp3 = k
							for k,v in pairs(v) do
								if string.upper(tostring(v)) == value then
									if field then
										if k == field then
											tinsert(location, {temp1, temp2, temp3, k} )
										end
									else
										tinsert(location, {temp1, temp2, temp3, k} )
									end
								end;
							end
						end
						if string.upper(tostring(v)) == value then
							if field then
								if k == field then
									tinsert(location, {temp1, temp2, k} )
								end
							else
								tinsert(location, {temp1, temp2, k} )
							end
						end;
					end
				end
				if string.upper(tostring(v)) == value then
					if field then
						if k == field then
							tinsert(location, {temp1, k} )
						end
					else
						tinsert(location, {temp1, k} )
					end
				end;
			end
		end
		if string.upper(tostring(v)) == value then
			if field then
				if k == field then
					tinsert(location, k)
				end
			else
				tinsert(location, k)
			end
		end;
	end
	if (#location > 0) then
		return location;
	else
		return false;
	end
end

function DWP:TableStrFind(tar, val, field)              -- same function as above, but searches values that contain the searched string rather than exact string matches
	local value = string.upper(tostring(val));        -- ex. DWP:TableStrFind(DWPlus_RPHistory, "Player") will return the path to any table element that contains "Roeshambo"
	local location = {}
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			local temp1 = k
			for k,v in pairs(v) do
				if(type(v) == "table") then
					local temp2 = k;
					for k,v in pairs(v) do
						if(type(v) == "table") then
							local temp3 = k
							for k,v in pairs(v) do
								if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
									if field then
										if k == field then
											tinsert(location, {temp1, temp2, temp3, k} )
										end
									else
										tinsert(location, {temp1, temp2, temp3, k} )
									end
								end;
							end
						end
						if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
							if field then
								if k == field then
									tinsert(location, {temp1, temp2, k} )
								end
							else
								tinsert(location, {temp1, temp2, k} )
							end
						end;
					end
				end
				if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
					if field then
						if k == field then
							tinsert(location, {temp1, k} )
						end
					else
						tinsert(location, {temp1, k} )
					end
				end;
			end
		end
		if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
			if field then
				if k == field then
					tinsert(location, k)
				end
			else
				tinsert(location, k)
			end
		end;
	end
	if (#location > 0) then
		return location;
	else
		return false;
	end
end

function DWP:DKPTable_Set(tar, field, value, loot)                -- updates field with value where tar is found (IE: DWP:DKPTable_Set("Player", "dkp", 10) adds 10 dkp to user Roeshambo). loot = true/false if it's to alter lifetime_spent
	local result = DWP:Table_Search(DWPlus_RPTable, tar);
	for i=1, #result do
		local current = DWPlus_RPTable[result[i][1]][field];
		if(field == "dkp") then
			DWPlus_RPTable[result[i][1]][field] = DWP_round(tonumber(current + value), DWPlus_DB.modes.rounding)
			if value > 0 and loot == false then
				DWPlus_RPTable[result[i][1]]["lifetime_gained"] = DWP_round(tonumber(DWPlus_RPTable[result[i][1]]["lifetime_gained"] + value), DWPlus_DB.modes.rounding)
			elseif value < 0 and loot == true then
				DWPlus_RPTable[result[i][1]]["lifetime_spent"] = DWP_round(tonumber(DWPlus_RPTable[result[i][1]]["lifetime_spent"] + value), DWPlus_DB.modes.rounding)
			end
		else
			DWPlus_RPTable[result[i][1]][field] = value
		end
	end
	DKPTable_Update()
end

-- instance id can be get by -> _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
-- Boss IDs must be in the exact same order as core.BossList declared in localization files
core.BossZonesData = {
	[0] = {
		bossListId = "WORLD",
		mapId = 0,
	},
	[409] = {
		bossListId = "MC",
		mapId = 2717,
	},
	[249] = {
		bossListId = "ONYXIA",
		mapId = 2159,
	},
	[309] = {
		bossListId = "ZG",
		mapId = 1977,
	},
	[469] = {
		bossListId = "BWL",
		mapId = 2677,
	},
	[509] = {
		bossListId = "AQ20",
		mapId = 3429,
	},
	[531] = {
		bossListId = "AQ",
		mapId = 3428,
	},
	[533] = {
		bossListId = "NAXX",
		mapId = 3456,
	},
}

-- Items data in the exact same order as core.BossList declared in localization files
core.ItemsData = {
	-- World Bosses
	[0] = {
		-- Azuregos
		{
			19132, -- Crystal Adorned Crown
			18208, -- Drape of Benediction
			18541, -- Puissant Cape
			18547, -- Unmelting Ice Girdle
			18545, -- Leggings of Arcane Supremacy
			19131, -- Snowblind Shoes
			19130, -- Cold Snap
			17070, -- Fang of the Mystics
			18202, -- Eskhandar's Left Claw
			18542, -- Typhoon
			18704, -- Mature Blue Dragon Sinew
			11938, -- Sack of Gems
		},
		-- Kazzak
		{
			18546, -- Infernal Headcage
			17111, -- Blazefury Medallion
			18204, -- Eskhandar's Pelt
			19135, -- Blacklight Bracer
			18544, -- Doomhide Gauntlets
			19134, -- Flayed Doomguard Belt
			19133, -- Fel Infused Leggings
			18543, -- Ring of Entropy
			17112, -- Empyrean Demolisher
			17113, -- Amberseal Keeper
			18665, -- The Eye of Shadow
			11938, -- Sack of Gems
		},
		-- Emeriss
		{
			20623, -- Circlet of Restless Dreams
			20622, -- Dragonheart Necklace
			20624, -- Ring of the Unliving
			20621, -- Boots of the Endless Moor
			20599, -- Polished Ironwood Crossbow
			20579, -- Green Dragonskin Cloak
			20615, -- Dragonspur Wraps
			20616, -- Dragonbone Wristguards
			20618, -- Gloves of Delusional Power
			20617, -- Ancient Corroded Leggings
			20619, -- Acid Inscribed Greaves
			20582, -- Trance Stone
			20644, -- Nightmare Engulfed Object
			20600, -- Malfurion's Signet Ring
			20580, -- Hammer of Bestial Fury
			20581, -- Staff of Rampant Growth
			11938, -- Sack of Gems
		},
		-- Lethon
		{
			20628, -- Deviate Growth Cap
			20626, -- Black Bark Wristbands
			20630, -- Gauntlets of the Shining Light
			20625, -- Belt of the Dark Bog
			20627, -- Dark Heart Pants
			20629, -- Malignant Footguards
			20579, -- Green Dragonskin Cloak
			20615, -- Dragonspur Wraps
			20616, -- Dragonbone Wristguards
			20618, -- Gloves of Delusional Power
			20617, -- Ancient Corroded Leggings
			20619, -- Acid Inscribed Greaves
			20582, -- Trance Stone
			20644, -- Nightmare Engulfed Object
			20600, -- Malfurion's Signet Ring
			20580, -- Hammer of Bestial Fury
			20581, -- Staff of Rampant Growth
			20381, -- Dreamscale
			11938, -- Sack of Gems
		},
		-- Ysondre
		{
			20637, -- Acid Inscribed Pauldrons
			20635, -- Jade Inlaid Vestments
			20638, -- Leggings of the Demented Mind
			20639, -- Strangely Glyphed Legplates
			20636, -- Hibernation Crystal
			20578, -- Emerald Dragonfang
			20579, -- Green Dragonskin Cloak
			20615, -- Dragonspur Wraps
			20616, -- Dragonbone Wristguards
			20618, -- Gloves of Delusional Power
			20617, -- Ancient Corroded Leggings
			20619, -- Acid Inscribed Greaves
			20582, -- Trance Stone
			20644, -- Nightmare Engulfed Object
			20600, -- Malfurion's Signet Ring
			20580, -- Hammer of Bestial Fury
			20581, -- Staff of Rampant Growth
			11938, -- Sack of Gems
		},
		-- Taerar
		{
			20633, -- Unnatural Leather Spaulders
			20631, -- Mendicant's Slippers
			20634, -- Boots of Fright
			20632, -- Mindtear Band
			20577, -- Nightmare Blade
			20579, -- Green Dragonskin Cloak
			20615, -- Dragonspur Wraps
			20616, -- Dragonbone Wristguards
			20618, -- Gloves of Delusional Power
			20617, -- Ancient Corroded Leggings
			20619, -- Acid Inscribed Greaves
			20582, -- Trance Stone
			20644, -- Nightmare Engulfed Object
			20600, -- Malfurion's Signet Ring
			20580, -- Hammer of Bestial Fury
			20581, -- Staff of Rampant Growth
			11938, -- Sack of Gems
		},
	},
	-- MoltenCore
	[409] = {
		-- Lucifron
		{
			16800, -- Arcanist Boots
			16805, -- Felheart Gloves
			16829, -- Cenarion Boots
			16837, -- Earthfury Boots
			16859, -- Lawbringer Boots
			16863, -- Gauntlets of Might
			18870, -- Helm of the Lifegiver
			17109, -- Choker of Enlightenment
			19145, -- Robe of Volatile Power
			19146, -- Wristguards of Stability
			18872, -- Manastorm Leggings
			18875, -- Salamander Scale Pants
			18861, -- Flamewaker Legplates
			18879, -- Heavy Dark Iron Ring
			19147, -- Ring of Spell Power
			17077, -- Crimson Shocker
			18878, -- Sorcerous Dagger
			16665, -- Tome of Tranquilizing Shot
		},
		-- Magmadar
		{
			16814, -- Pants of Prophecy
			16796, -- Arcanist Leggings
			16810, -- Felheart Pants
			16822, -- Nightslayer Pants
			16835, -- Cenarion Leggings
			16847, -- Giantstalker's Leggings
			16843, -- Earthfury Legguards
			16855, -- Lawbringer Legplates
			16867, -- Legplates of Might
			18203, -- Eskhandar's Right Claw
			17065, -- Medallion of Steadfast Might
			18829, -- Deep Earth Spaulders
			18823, -- Aged Core Leather Gloves
			19143, -- Flameguard Gauntlets
			19136, -- Mana Igniting Cord
			18861, -- Flamewaker Legplates
			19144, -- Sabatons of the Flamewalker
			18824, -- Magma Tempered Boots
			18821, -- Quick Strike Ring
			18820, -- Talisman of Ephemeral Power
			19142, -- Fire Runed Grimoire
			17069, -- Striker's Mark
			17073, -- Earthshaker
			18822, -- Obsidian Edged Blade
		},
		-- Gehennas
		{
			16812, -- Gloves of Prophecy
			16826, -- Nightslayer Gloves
			16849, -- Giantstalker's Boots
			16839, -- Earthfury Gauntlets
			16860, -- Lawbringer Gauntlets
			16862, -- Sabatons of Might
			18870, -- Helm of the Lifegiver
			19145, -- Robe of Volatile Power
			19146, -- Wristguards of Stability
			18872, -- Manastorm Leggings
			18875, -- Salamander Scale Pants
			18861, -- Flamewaker Legplates
			18879, -- Heavy Dark Iron Ring
			19147, -- Ring of Spell Power
			17077, -- Crimson Shocker
			18878, -- Sorcerous Dagger
		},
		-- Garr
		{
			18564, -- Bindings of the Windseeker
			16813, -- Circlet of Prophecy
			16795, -- Arcanist Crown
			16808, -- Felheart Horns
			16821, -- Nightslayer Cover
			16834, -- Cenarion Helm
			16846, -- Giantstalker's Helmet
			16842, -- Earthfury Helmet
			16854, -- Lawbringer Helm
			16866, -- Helm of Might
			18829, -- Deep Earth Spaulders
			18823, -- Aged Core Leather Gloves
			19143, -- Flameguard Gauntlets
			19136, -- Mana Igniting Cord
			18861, -- Flamewaker Legplates
			19144, -- Sabatons of the Flamewalker
			18824, -- Magma Tempered Boots
			18821, -- Quick Strike Ring
			18820, -- Talisman of Ephemeral Power
			19142, -- Fire Runed Grimoire
			17066, -- Drillborer Disk
			17071, -- Gutgore Ripper
			17105, -- Aurastone Hammer
			18832, -- Brutality Blade
			18822, -- Obsidian Edged Blade
		},
		-- Geddon
		{
			18563, -- Bindings of the Windseeker
			16797, -- Arcanist Mantle
			16807, -- Felheart Shoulder Pads
			16836, -- Cenarion Spaulders
			16844, -- Earthfury Epaulets
			16856, -- Lawbringer Spaulders
			18829, -- Deep Earth Spaulders
			18823, -- Aged Core Leather Gloves
			19143, -- Flameguard Gauntlets
			19136, -- Mana Igniting Cord
			18861, -- Flamewaker Legplates
			19144, -- Sabatons of the Flamewalker
			18824, -- Magma Tempered Boots
			18821, -- Quick Strike Ring
			17110, -- Seal of the Archmagus
			18820, -- Talisman of Ephemeral Power
			19142, -- Fire Runed Grimoire
			18822, -- Obsidian Edged Blade
		},
		-- Shazzrah
		{
			16811, -- Boots of Prophecy
			16801, -- Arcanist Gloves
			16803, -- Felheart Slippers
			16824, -- Nightslayer Boots
			16831, -- Cenarion Gloves
			16852, -- Giantstalker's Gloves
			18870, -- Helm of the Lifegiver
			19145, -- Robe of Volatile Power
			19146, -- Wristguards of Stability
			18872, -- Manastorm Leggings
			18875, -- Salamander Scale Pants
			18861, -- Flamewaker Legplates
			18879, -- Heavy Dark Iron Ring
			19147, -- Ring of Spell Power
			17077, -- Crimson Shocker
			18878, -- Sorcerous Dagger
		},
		-- Sulfuron
		{
			16816, -- Mantle of Prophecy
			16823, -- Nightslayer Shoulder Pads
			16848, -- Giantstalker's Epaulets
			16868, -- Pauldrons of Might
			18870, -- Helm of the Lifegiver
			19145, -- Robe of Volatile Power
			19146, -- Wristguards of Stability
			18872, -- Manastorm Leggings
			18875, -- Salamander Scale Pants
			18861, -- Flamewaker Legplates
			18879, -- Heavy Dark Iron Ring
			19147, -- Ring of Spell Power
			17077, -- Crimson Shocker
			18878, -- Sorcerous Dagger
			17074, -- Shadowstrike
		},
		-- Golemagg
		{
			16815, -- Robes of Prophecy
			16798, -- Arcanist Robes
			16809, -- Felheart Robes
			16820, -- Nightslayer Chestpiece
			16833, -- Cenarion Vestments
			16845, -- Giantstalker's Breastplate
			16841, -- Earthfury Vestments
			16853, -- Lawbringer Chestguard
			16865, -- Breastplate of Might
			17203, -- Sulfuron Ingot
			18829, -- Deep Earth Spaulders
			18823, -- Aged Core Leather Gloves
			19143, -- Flameguard Gauntlets
			19136, -- Mana Igniting Cord
			18861, -- Flamewaker Legplates
			19144, -- Sabatons of the Flamewalker
			18824, -- Magma Tempered Boots
			18821, -- Quick Strike Ring
			18820, -- Talisman of Ephemeral Power
			19142, -- Fire Runed Grimoire
			17072, -- Blastershot Launcher
			17103, -- Azuresong Mageblade
			18822, -- Obsidian Edged Blade
			18842, -- Staff of Dominance
		},
		-- Majordomo
		{
			19139, -- Fireguard Shoulders
			18810, -- Wild Growth Spaulders
			18811, -- Fireproof Cloak
			18808, -- Gloves of the Hypnotic Flame
			18809, -- Sash of Whispered Secrets
			18812, -- Wristguards of True Flight
			18806, -- Core Forged Greaves
			19140, -- Cauterizing Band
			18805, -- Core Hound Tooth
			18803, -- Finkle's Lava Dredger
			18703, -- Ancient Petrified Leaf
			18646, -- The Eye of Divinity
		},
		-- Ragnaros
		{
			17204, -- Eye of Sulfuras
			19017, -- Essence of the Firelord
			16922, -- Leggings of Transcendence
			16915, -- Netherwind Pants
			16930, -- Nemesis Leggings
			16909, -- Bloodfang Pants
			16901, -- Stormrage Legguards
			16938, -- Dragonstalker's Legguards
			16946, -- Legplates of Ten Storms
			16954, -- Judgement Legplates
			16962, -- Legplates of Wrath
			17082, -- Shard of the Flame
			18817, -- Crown of Destruction
			18814, -- Choker of the Fire Lord
			17102, -- Cloak of the Shrouded Mists
			17107, -- Dragon's Blood Cape
			19137, -- Onslaught Girdle
			17063, -- Band of Accuria
			19138, -- Band of Sulfuras
			18815, -- Essence of the Pure Flame
			17106, -- Malistar's Defender
			18816, -- Perdition's Blade
			17104, -- Spinal Reaper
			17076, -- Bonereaver's Edge
		},
	},
	-- Onyxia's Liar
	[249] = {
		-- Onyxia
		{
			16921, -- Halo of Transcendence
			16914, -- Netherwind Crown
			16929, -- Nemesis Skullcap
			16908, -- Bloodfang Hood
			16900, -- Stormrage Cover
			16939, -- Dragonstalker's Helm
			16947, -- Helmet of Ten Storms
			16955, -- Judgement Crown
			16963, -- Helm of Wrath
			18423, -- Head of Onyxia
			15410, -- Scale of Onyxia
			18705, -- Mature Black Dragon Sinew
			18205, -- Eskhandar's Collar
			17078, -- Sapphiron Drape
			18813, -- Ring of Binding
			17064, -- Shard of the Scale
			17067, -- Ancient Cornerstone Grimoire
			17068, -- Deathbringer
			17075, -- Vis'kag the Bloodletter
			17966, -- Onyxia Hide Backpack
			11938, -- Sack of Gems
			17962, -- Blue Sack of Gems
			17963, -- Green Sack of Gems
			17964, -- Gray Sack of Gems
			17965, -- Yellow Sack of Gems
			17969, -- Red Sack of Gems
		},
	},
	-- Zul'Gurub
	[309] = {
		-- Mandokir
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			22637, -- Primal Hakkari Idol
			19872, -- Swift Razzashi Raptor
			20038, -- Mandokir's Sting
			19867, -- Bloodlord's Defender
			19866, -- Warblade of the Hakkari
			19874, -- Halberd of Smiting
			19878, -- Bloodsoaked Pauldrons
			19870, -- Hakkari Loa Cloak
			19869, -- Blooddrenched Grips
			19895, -- Bloodtinged Kilt
			19877, -- Animist's Leggings
			19873, -- Overlord's Crimson Band
			19863, -- Primalist's Seal
			19893, -- Zanzil's Seal
		},
		-- Gahzranka
		{
			19945, -- Foror's Eyepatch
			19944, -- Nat Pagle's Fish Terminator
			19947, -- Nat Pagle's Broken Reel
			19946, -- Tigule's Harpoon
			22739, -- Tome of Polymorph: Turtle
		},
		-- Hakkar
		{
			19857, -- Cloak of Consumption
			function ()
				if core.faction == "Horde" then
					return 20257; -- Seafury Gauntlets
				else
					return 20264; -- Peacekeeper Gauntlets
				end
			end,
			19855, -- Bloodsoaked Legplates
			19876, -- Soul Corrupter's Necklace
			19856, -- The Eye of Hakkar
			19802, -- Heart of Hakkar
			19861, -- Touch of Chaos
			19853, -- Gurubashi Dwarf Destroyer
			19862, -- Aegis of the Blood God
			19864, -- Bloodcaller
			19865, -- Warblade of the Hakkari
			19866, -- Warblade of the Hakkari
			19852, -- Ancient Hakkari Manslayer
			19859, -- Fang of the Faceless
			19854, -- Zin'rokh, Destroyer of Worlds
		},
		-- Thekal
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			19902, -- Swift Zulian Tiger
			19897, -- Betrayer's Boots
			19896, -- Thekal's Grasp
			19899, -- Ritualistic Legguards
			20260, -- Seafury Leggings
			20266, -- Peacekeeper Leggings
			19898, -- Seal of Jin
			19901, -- Zulian Slicer
		},
		-- Venoxis
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			19904, -- Runed Bloodstained Hauberk
			19903, -- Fang of Venoxis
			19907, -- Zulian Tigerhide Cloak
			19906, -- Blooddrenched Footpads
			19905, -- Zanzil's Band
			19900, -- Zulian Stone Axe
		},
		-- Arlokk
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			19910, -- Arlokk's Grasp
			19909, -- Will of Arlokk
			19913, -- Bloodsoaked Greaves
			19912, -- Overlord's Onyx Band
			19922, -- Arlokk's Hoodoo Stick
			19914, -- Panther Hide Sack
		},
		-- Jeklik
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			19918, -- Jeklik's Crusher
			19923, -- Jeklik's Opaline Talisman
			19928, -- Animist's Spaulders
			20262, -- Seafury Boots
			20265, -- Peacekeeper Boots
			19920, -- Primalist's Band
			19915, -- Zulian Defender
		},
		-- Jindo
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			22637, -- Primal Hakkari Idol
			19885, -- Jin'do's Evil Eye
			19891, -- Jin'do's Bag of Whammies
			19890, -- Jin'do's Hexxer
			19884, -- Jin'do's Judgement
			19886, -- The Hexxer's Cover
			19875, -- Bloodstained Coif
			19888, -- Overlord's Embrace
			19929, -- Bloodtinged Gloves
			19894, -- Bloodsoaked Gauntlets
			19889, -- Blooddrenched Leggings
			19887, -- Bloodstained Legplates
			19892, -- Animist's Boots
		},
		-- Marli
		{
			19721, -- Primal Hakkari Shawl
			19724, -- Primal Hakkari Aegis
			19723, -- Primal Hakkari Kossack
			19722, -- Primal Hakkari Tabard
			19717, -- Primal Hakkari Armsplint
			19716, -- Primal Hakkari Bindings
			19718, -- Primal Hakkari Stanchion
			19719, -- Primal Hakkari Girdle
			19720, -- Primal Hakkari Sash
			20032, -- Flowing Ritual Robes
			19927, -- Mar'li's Touch
			19871, -- Talisman of Protection
			19919, -- Bloodstained Greaves
			19925, -- Band of Jin
			19930, -- Mar'li's Eye
		},
		-- Edge of Madness
		{
			-- Grilek
			19961, -- Gri'lek's Grinder
			19962, -- Gri'lek's Carver
			19939, -- Gri'lek's Blood
			-- Hazzarah
			19967, -- Thoughtblighter
			19968, -- Fiery Retributer
			19942, -- Hazza'rah's Dream Thread
			-- Renataki
			19964, -- Renataki's Soul Conduit
			19963, -- Pitchfork of Madness
			19940, -- Renataki's Tooth
			-- Wushoolay
			19993, -- Hoodoo Hunting Bow
			19965, -- Wushoolay's Poker
			19941, -- Wushoolay's Mane
		},
	},
	-- BlackwingLair
	[469] = {
		-- Razorgore
		{
			16926, -- Bindings of Transcendence
			16918, -- Netherwind Bindings
			16934, -- Nemesis Bracers
			16911, -- Bloodfang Bracers
			16904, -- Stormrage Bracers
			16935, -- Dragonstalker's Bracers
			16943, -- Bracers of Ten Storms
			16951, -- Judgement Bindings
			16959, -- Bracelets of Wrath
			19336, -- Arcane Infused Gem
			19337, -- The Black Book
			19370, -- Mantle of the Blackwing Cabal
			19369, -- Gloves of Rapid Evolution
			19335, -- Spineshatter
			19334, -- The Untamed Blade
		},
		-- Vaelastrasz
		{
			16925, -- Belt of Transcendence
			16818, -- Netherwind Belt
			16933, -- Nemesis Belt
			16910, -- Bloodfang Belt
			16903, -- Stormrage Belt
			16936, -- Dragonstalker's Belt
			16944, -- Belt of Ten Storms
			16952, -- Judgement Belt
			16960, -- Waistband of Wrath
			19339, -- Mind Quickening Gem
			19340, -- Rune of Metamorphosis
			19372, -- Helm of Endless Rage
			19371, -- Pendant of the Fallen Dragon
			19348, -- Red Dragonscale Protector
			19346, -- Dragonfang Blade
		},
		-- Lashlayer
		{
			16919, -- Boots of Transcendence
			16912, -- Netherwind Boots
			16927, -- Nemesis Boots
			16906, -- Bloodfang Boots
			16898, -- Stormrage Boots
			16941, -- Dragonstalker's Greaves
			16949, -- Greaves of Ten Storms
			16957, -- Judgement Sabatons
			16965, -- Sabatons of Wrath
			19341, -- Lifegiving Gem
			19342, -- Venomous Totem
			19373, -- Black Brood Pauldrons
			19374, -- Bracers of Arcane Accuracy
			19350, -- Heartstriker
			19351, -- Maladath, Runed Blade of the Black Flight
			20383, -- Head of the Broodlord Lashlayer
		},
		-- Firemaw
		{
			16920, -- Handguards of Transcendence
			16913, -- Netherwind Gloves
			16928, -- Nemesis Gloves
			16907, -- Bloodfang Gloves
			16899, -- Stormrage Handguards
			16940, -- Dragonstalker's Gauntlets
			16948, -- Gauntlets of Ten Storms
			16956, -- Judgement Gauntlets
			16964, -- Gauntlets of Wrath
			19344, -- Natural Alignment Crystal
			19343, -- Scrolls of Blinding Light
			19394, -- Drake Talon Pauldrons
			19398, -- Cloak of Firemaw
			19399, -- Black Ash Robe
			19400, -- Firemaw's Clutch
			19396, -- Taut Dragonhide Belt
			19401, -- Primalist's Linked Legguards
			19402, -- Legguards of the Fallen Crusader
			19365, -- Claw of the Black Drake
			19353, -- Drake Talon Cleaver
			19355, -- Shadow Wing Focus Staff
			19397, -- Ring of Blackrock
			19395, -- Rejuvenating Gem
		},
		-- Ebonroc
		{
			16920, -- Handguards of Transcendence
			16913, -- Netherwind Gloves
			16928, -- Nemesis Gloves
			16907, -- Bloodfang Gloves
			16899, -- Stormrage Handguards
			16940, -- Dragonstalker's Gauntlets
			16948, -- Gauntlets of Ten Storms
			16956, -- Judgement Gauntlets
			16964, -- Gauntlets of Wrath
			19345, -- Aegis of Preservation
			19406, -- Drake Fang Talisman
			19395, -- Rejuvenating Gem
			19394, -- Drake Talon Pauldrons
			19407, -- Ebony Flame Gloves
			19396, -- Taut Dragonhide Belt
			19405, -- Malfurion's Blessed Bulwark
			19368, -- Dragonbreath Hand Cannon
			19353, -- Drake Talon Cleaver
			19355, -- Shadow Wing Focus Staff
			19403, -- Band of Forced Concentration
			19397, -- Ring of Blackrock
		},
		-- Flamegor
		{
			16920, -- Handguards of Transcendence
			16913, -- Netherwind Gloves
			16928, -- Nemesis Gloves
			16907, -- Bloodfang Gloves
			16899, -- Stormrage Handguards
			16940, -- Dragonstalker's Gauntlets
			16948, -- Gauntlets of Ten Storms
			16956, -- Judgement Gauntlets
			16964, -- Gauntlets of Wrath
			19395, -- Rejuvenating Gem
			19431, -- Styleen's Impeding Scarab
			19394, -- Drake Talon Pauldrons
			19430, -- Shroud of Pure Thought
			19396, -- Taut Dragonhide Belt
			19433, -- Emberweave Leggings
			19367, -- Dragon's Touch
			19353, -- Drake Talon Cleaver
			19357, -- Herald of Woe
			19355, -- Shadow Wing Focus Staff
			19432, -- Circle of Applied Force
			19397, -- Ring of Blackrock
		},
		-- Chromaggus
		{
			16924, -- Pauldrons of Transcendence
			16917, -- Netherwind Mantle
			16932, -- Nemesis Spaulders
			16832, -- Bloodfang Spaulders
			16902, -- Stormrage Pauldrons
			16937, -- Dragonstalker's Spaulders
			16945, -- Epaulets of Ten Storms
			16953, -- Judgement Spaulders
			16961, -- Pauldrons of Wrath
			19389, -- Taut Dragonhide Shoulderpads
			19386, -- Elementium Threaded Cloak
			19390, -- Taut Dragonhide Gloves
			19388, -- Angelista's Grasp
			19393, -- Primalist's Linked Waistguard
			19392, -- Girdle of the Fallen Crusader
			19385, -- Empowered Leggings
			19391, -- Shimmering Geta
			19387, -- Chromatic Boots
			19361, -- Ashjre'thul, Crossbow of Smiting
			19349, -- Elementium Reinforced Bulwark
			19347, -- Claw of Chromaggus
			19352, -- Chromatically Tempered Sword
		},
		-- Nefarian
		{
			16923, -- Robes of Transcendence
			16916, -- Netherwind Robes
			16931, -- Nemesis Robes
			16905, -- Bloodfang Chestpiece
			16897, -- Stormrage Chestguard
			16942, -- Dragonstalker's Breastplate
			16950, -- Breastplate of Ten Storms
			16958, -- Judgement Breastplate
			16966, -- Breastplate of Wrath
			19003, -- Head of Nefarian
			19360, -- Lok'amir il Romathis
			19363, -- Crul'shorukh, Edge of Chaos
			19364, -- Ashkandi, Greatsword of the Brotherhood
			19356, -- Staff of the Shadow Flame
			19375, -- Mish'undare, Circlet of the Mind Flayer
			19377, -- Prestor's Talisman of Connivery
			19378, -- Cloak of the Brood Lord
			19380, -- Therazane's Link
			19381, -- Boots of the Shadow Flame
			19376, -- Archimtiros' Ring of Reckoning
			19382, -- Pure Elementium Band
			19379, -- Neltharion's Tear
			11938, -- Sack of Gems
			17962, -- Blue Sack of Gems
			17963, -- Green Sack of Gems
			17964, -- Gray Sack of Gems
			17965, -- Yellow Sack of Gems
			17969, -- Red Sack of Gems
		},
	},
	-- AQ20
	[509] = {
		-- Ayamiss
		{
			21479, -- Gauntlets of the Immovable
			21478, -- Bow of Taut Sinew
			21466, -- Stinger of Ayamiss
			21484, -- Helm of Regrowth
			21480, -- Scaled Silithid Gauntlets
			21482, -- Boots of the Fiery Sands
			21481, -- Boots of the Desert Protector
			21483, -- Ring of the Desert Winds
			20890, -- Qiraji Ornate Hilt
			20886, -- Qiraji Spiked Hilt
			20885, -- Qiraji Martial Drape
			20889, -- Qiraji Regal Drape
			20888, -- Qiraji Ceremonial Ring
			20884, -- Qiraji Magisterial Ring
		},
		-- Buru
		{
			function ()
				if core.faction == "Horde" then
					return 21487; -- Slimy Scaled Gauntlets
				else
					return 21486; -- Gloves of the Swarm
				end
			end,
			21485, -- Buru's Skull Fragment
			21491, -- Scaled Bracers of the Gorger
			21489, -- Quicksand Waders
			21490, -- Slime Kickers
			21488, -- Fetish of Chitinous Spikes
			20890, -- Qiraji Ornate Hilt
			20886, -- Qiraji Spiked Hilt
			20885, -- Qiraji Martial Drape
			20889, -- Qiraji Regal Drape
			20888, -- Qiraji Ceremonial Ring
			20884, -- Qiraji Magisterial Ring
		},
		-- Rajaxx
		{
			21493, -- Boots of the Vanguard
			21492, -- Manslayer of the Qiraji
			21496, -- Bracers of Qiraji Command
			21494, -- Southwind's Grasp
			21495, -- Legplates of the Qiraji Command
			21497, -- Boots of the Qiraji General
			21810, -- Treads of the Wandering Nomad
			21809, -- Fury of the Forgotten Swarm
			21806, -- Gavel of Qiraji Authority
			20885, -- Qiraji Martial Drape
			20889, -- Qiraji Regal Drape
			20888, -- Qiraji Ceremonial Ring
			20884, -- Qiraji Magisterial Ring
		},
		-- Kurinnaxx
		{
			21499, -- Vestments of the Shifting Sands
			21498, -- Qiraji Sacrificial Dagger
			21502, -- Sand Reaver Wristguards
			21501, -- Toughened Silithid Hide Gloves
			21500, -- Belt of the Inquisition
			21503, -- Belt of the Sand Reaver
			20885, -- Qiraji Martial Drape
			20889, -- Qiraji Regal Drape
			20888, -- Qiraji Ceremonial Ring
			20884, -- Qiraji Magisterial Ring
		},
		-- Moam
		{
			21472, -- Dustwind Turban
			21467, -- Thick Silithid Chestguard
			21479, -- Gauntlets of the Immovable
			21471, -- Talon of Furious Concentration
			21455, -- Southwind Helm
			21468, -- Mantle of Maz'Nadir
			21474, -- Chitinous Shoulderguards
			21470, -- Cloak of the Savior
			21469, -- Gauntlets of Southwind
			21476, -- Obsidian Scaled Leggings
			21475, -- Legplates of the Destroyer
			21477, -- Ring of Fury
			21473, -- Eye of Moam
			20890, -- Qiraji Ornate Hilt
			20886, -- Qiraji Spiked Hilt
			20888, -- Qiraji Ceremonial Ring
			20884, -- Qiraji Magisterial Ring
			22220, -- Plans: Black Grasp of the Destroyer
		},
		-- Ossirian
		{
			function ()
				if core.faction == "Horde" then
					return 21454; -- Runic Stone Shoulders
				else
					return 21453; -- Mantle of the Horusath
				end
			end,
			21460, -- Helm of Domination
			21456, -- Sandstorm Cloak
			21464, -- Shackles of the Unscarred
			21457, -- Bracers of Brutality
			21462, -- Gloves of Dark Wisdom
			21458, -- Gauntlets of New Life
			21463, -- Ossirian's Binding
			21461, -- Leggings of the Black Blizzard
			21459, -- Crossbow of Imminent Doom
			21715, -- Sand Polished Hammer
			21452, -- Staff of the Ruins
			20890, -- Qiraji Ornate Hilt
			20886, -- Qiraji Spiked Hilt
			20888, -- Qiraji Ceremonial Ring
			20884, -- Qiraji Magisterial Ring
			21220, -- Head of Ossirian the Unscarred
		},
	},
	-- AQ40
	[531] = {
		-- Skeram
		{
			21699, -- Barrage Shoulders
			21814, -- Breastplate of Annihilation
			21708, -- Beetle Scaled Wristguards
			21698, -- Leggings of Immersion
			21705, -- Boots of the Fallen Prophet
			21704, -- Boots of the Redeemed Prophecy
			21706, -- Boots of the Unwavering Will
			21702, -- Amulet of Foul Warding
			21700, -- Pendant of the Qiraji Guardian
			21701, -- Cloak of Concentrated Hatred
			21707, -- Ring of Swarming Thought
			21703, -- Hammer of Ji'zhi
			21128, -- Staff of the Qiraji Prophets
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
			22222, -- Plans: Thick Obsidian Breastplate
		},
		-- Sartura
		{
			21669, -- Creeping Vine Helm
			21678, -- Necklace of Purity
			21671, -- Robes of the Battleguard
			21672, -- Gloves of Enforcement
			21674, -- Gauntlets of Steadfast Determination
			21675, -- Thick Qirajihide Belt
			21676, -- Leggings of the Festering Swarm
			21668, -- Scaled Leggings of Qiraji Fury
			21667, -- Legplates of Blazing Light
			21648, -- Recomposed Boots
			21670, -- Badge of the Swarmguard
			21666, -- Sartura's Might
			21673, -- Silithid Claw
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
		},
		-- Fankriss
		{
			21665, -- Mantle of Wicked Revenge
			21639, -- Pauldrons of the Unrelenting
			21627, -- Cloak of Untold Secrets
			21663, -- Robes of the Guardian Saint
			21652, -- Silithid Carapace Chestguard
			21651, -- Scaled Sand Reaver Leggings
			21645, -- Hive Tunneler's Boots
			21650, -- Ancient Qiraji Ripper
			21635, -- Barb of the Sand Reaver
			21664, -- Barbed Choker
			21647, -- Fetish of the Sand Reaver
			22402, -- Libram of Grace
			22396, -- Totem of Life
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
		},
		-- Huhuran
		{
			21621, -- Cloak of the Golden Hive
			21618, -- Hive Defiler Wristguards
			21619, -- Gloves of the Messiah
			21617, -- Wasphide Gauntlets
			21620, -- Ring of the Martyr
			21616, -- Huhuran's Stinger
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
			20928, -- Qiraji Bindings of Command
			20932, -- Qiraji Bindings of Dominance
		},
		-- Twin Emperors
		{
			--  Vek'nilash
			20926, -- Vek'nilash's Circlet
			21608, -- Amulet of Vek'nilash
			21604, -- Bracelets of Royal Redemption
			21605, -- Gloves of the Hidden Temple
			21609, -- Regenerating Belt of Vek'nilash
			21607, -- Grasp of the Fallen Emperor
			21606, -- Belt of the Fallen Emperor
			21679, -- Kalimdor's Revenge
			20726, -- Formula: Enchant Gloves - Threat
			21237, -- Imperial Qiraji Regalia
			-- Vek'lor
			20930, -- Vek'lor's Diadem
			21602, -- Qiraji Execution Bracers
			21599, -- Vek'lor's Gloves of Devastation
			21598, -- Royal Qiraji Belt
			21600, -- Boots of Epiphany
			21601, -- Ring of Emperor Vek'lor
			21597, -- Royal Scepter of Vek'lor
			20735, -- Formula: Enchant Cloak - Subtlety
			21232, -- Imperial Qiraji Armaments
		},
		-- CThun
		{
			22732, -- Mark of C'Thun
			21583, -- Cloak of Clarity
			22731, -- Cloak of the Devoured
			22730, -- Eyestalk Waist Cord
			21582, -- Grasp of the Old God
			21586, -- Belt of Never-ending Agony
			21585, -- Dark Storm Gauntlets
			21581, -- Gauntlets of Annihilation
			21596, -- Ring of the Godslayer
			21579, -- Vanquished Tentacle of C'Thun
			21839, -- Scepter of the False Prophet
			21126, -- Death's Sting
			21134, -- Dark Edge of Insanity
			20929, -- Carapace of the Old God
			20933, -- Husk of the Old God
			21221, -- Eye of C'Thun
			22734, -- Base of Atiesh
		},
		-- Bug Family
		{
			-- Common
			21693, -- Guise of the Devourer
			21694, -- Ternary Mantle
			21697, -- Cape of the Trinity
			21696, -- Robes of the Triumvirate
			21692, -- Triad Girdle
			21695, -- Angelista's Touch
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
			-- Trio: Princess Yauj
			21686, -- Mantle of Phrenic Power
			21684, -- Mantle of the Desert's Fury
			21683, -- Mantle of the Desert Crusade
			21682, -- Bile-Covered Gauntlets
			21687, -- Ukko's Ring of Darkness
			-- Trio: Vem
			21690, -- Angelista's Charm
			21689, -- Gloves of Ebru
			21691, -- Ooze-ridden Gauntlets
			21688, -- Boots of the Fallen Hero
			-- Trio: Lord Kri
			21680, -- Vest of Swift Execution
			21681, -- Ring of the Devoured
			21685, -- Petrified Scarab
			21603, -- Wand of Qiraji Nobility
		},
		-- Viscidus
		{
			21624, -- Gauntlets of Kalimdor
			21623, -- Gauntlets of the Righteous Champion
			21626, -- Slime-coated Leggings
			21622, -- Sharpened Silithid Femur
			21677, -- Ring of the Qiraji Fury
			21625, -- Scarab Brooch
			22399, -- Idol of Health
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
			20928, -- Qiraji Bindings of Command
			20932, -- Qiraji Bindings of Dominance
		},
		-- Ouro
		{
			21615, -- Don Rigoberto's Lost Hat
			21611, -- Burrower Bracers
			23558, -- The Burrower's Shell
			23570, -- Jom Gabbar
			21610, -- Wormscale Blocker
			23557, -- Larvae of the Great Worm
			21237, -- Imperial Qiraji Regalia
			21232, -- Imperial Qiraji Armaments
			20927, -- Ouro's Intact Hide
			20931, -- Skin of the Great Sandworm
		},
	},
	-- Naxxramas
	[533] = {
		-- The Arachnid Quarter
		-- AnubRekhan
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22369, -- Desecrated Bindings
			22362, -- Desecrated Wristguards
			22355, -- Desecrated Bracers
			22935, -- Touch of Frost
			22938, -- Cryptfiend Silk Cloak
			22936, -- Wristguards of Vengeance
			22939, -- Band of Unanswered Prayers
			22937, -- Gem of Nerubis
		},
		-- GrandWidowFaerlina
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22369, -- Desecrated Bindings
			22362, -- Desecrated Wristguards
			22355, -- Desecrated Bracers
			22943, -- Malice Stone Pendant
			22941, -- Polar Shoulder Pads
			22940, -- Icebane Pauldrons
			22942, -- The Widow's Embrace
			22806, -- Widow's Remorse
		},
		-- Maexxna
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22371, -- Desecrated Gloves
			22364, -- Desecrated Handguards
			22357, -- Desecrated Gauntlets
			22947, -- Pendant of Forgotten Names
			23220, -- Crystal Webbed Robe
			22954, -- Kiss of the Spider
			22807, -- Wraith Blade
			22804, -- Maexxna's Fang
		},
		-- The Plague Quarter
		-- NoththePlaguebringer
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22370, -- Desecrated Belt
			22363, -- Desecrated Girdle
			22356, -- Desecrated Waistguard
			23030, -- Cloak of the Scourge
			23031, -- Band of the Inevitable
			23028, -- Hailstone Band
			23029, -- Noth's Frigid Heart
			23006, -- Libram of Light
			23005, -- Totem of Flowing Water
			22816, -- Hatchet of Sundered Bone
		},
		-- HeigantheUnclean
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22370, -- Desecrated Belt
			22363, -- Desecrated Girdle
			22356, -- Desecrated Waistguard
			23035, -- Preceptor's Hat
			23033, -- Icy Scale Coif
			23019, -- Icebane Helmet
			23036, -- Necklace of Necropsy
			23068, -- Legplates of Carnage
		},
		-- Loatheb
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22366, -- Desecrated Leggings
			22359, -- Desecrated Legguards
			22352, -- Desecrated Legplates
			23038, -- Band of Unnatural Forces
			23037, -- Ring of Spiritual Fervor
			23042, -- Loatheb's Reflection
			23039, -- The Eye of Nerub
			22800, -- Brimstone Staff
		},
		-- The Military Quarter
		-- InstructorRazuvious
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22372, -- Desecrated Sandals
			22365, -- Desecrated Boots
			22358, -- Desecrated Sabatons
			23017, -- Veil of Eclipse
			23219, -- Girdle of the Mentor
			23018, -- Signet of the Fallen Defender
			23004, -- Idol of Longevity
			23009, -- Wand of the Whispering Dead
			23014, -- Iblis, Blade of the Fallen Seraph
		},
		-- GothiktheHarvester
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22372, -- Desecrated Sandals
			22365, -- Desecrated Boots
			22358, -- Desecrated Sabatons
			23032, -- Glacial Headdress
			23020, -- Polar Helmet
			23023, -- Sadist's Collar
			23021, -- The Soul Harvester's Bindings
			23073, -- Boots of Displacement
		},
		-- TheFourHorsemen
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22351, -- Desecrated Robe
			22350, -- Desecrated Tunic
			22349, -- Desecrated Breastplate
			23071, -- Leggings of Apocalypse
			23025, -- Seal of the Damned
			23027, -- Warmth of Forgiveness
			22811, -- Soulstring
			22809, -- Maul of the Redeemed Crusader
			22691, -- Corrupted Ashbringer
		},
		-- The Construct Quarter
		-- Patchwerk
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22368, -- Desecrated Shoulderpads
			22361, -- Desecrated Spaulders
			22354, -- Desecrated Pauldrons
			22960, -- Cloak of Suturing
			22961, -- Band of Reanimation
			22820, -- Wand of Fates
			22818, -- The Plague Bearer
			22815, -- Severance
		},
		-- Grobbulus
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22368, -- Desecrated Shoulderpads
			22361, -- Desecrated Spaulders
			22354, -- Desecrated Pauldrons
			22968, -- Glacial Mantle
			22967, -- Icy Scale Spaulders
			22810, -- Toxin Injector
			22803, -- Midnight Haze
			22988, -- The End of Dreams
		},
		-- Gluth
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22983, -- Rime Covered Mantle
			22981, -- Gluth's Missing Collar
			22994, -- Digested Hand of Power
			23075, -- Death's Bargain
			22813, -- Claymore of Unholy Might
			22368, -- Desecrated Shoulderpads
			22369, -- Desecrated Bindings
			22370, -- Desecrated Belt
			22372, -- Desecrated Sandals
			22361, -- Desecrated Spaulders
			22362, -- Desecrated Wristguards
			22363, -- Desecrated Girdle
			22365, -- Desecrated Boots
			22354, -- Desecrated Pauldrons
			22355, -- Desecrated Bracers
			22356, -- Desecrated Waistguard
			22358, -- Desecrated Sabatons
		},
		-- Thaddius
		{
			22726, -- Splinter of Atiesh
			22727, -- Frame of Atiesh
			22367, -- Desecrated Circlet
			22360, -- Desecrated Headpiece
			22353, -- Desecrated Helmet
			23000, -- Plated Abomination Ribcage
			23070, -- Leggings of Polarity
			23001, -- Eye of Diminution
			22808, -- The Castigator
			22801, -- Spire of Twilight
		},
		-- Frostwyrm Lair
		-- Sapphiron
		{
			23050, -- Cloak of the Necropolis
			23045, -- Shroud of Dominion
			23040, -- Glyph of Deflection
			23047, -- Eye of the Dead
			23041, -- Slayer's Crest
			23046, -- The Restrained Essence of Sapphiron
			23049, -- Sapphiron's Left Eye
			23048, -- Sapphiron's Right Eye
			23043, -- The Face of Death
			23242, -- Claw of the Frost Wyrm
			23549, -- Fortitude of the Scourge
			23548, -- Might of the Scourge
			23545, -- Power of the Scourge
			23547, -- Resilience of the Scourge
		},
		-- KelThuzard
		{
			23057, -- Gem of Trapped Innocents
			23053, -- Stormrage's Talisman of Seething
			22812, -- Nerubian Slavemaker
			22821, -- Doomfinger
			22819, -- Shield of Condemnation
			22802, -- Kingsfall
			23056, -- Hammer of the Twisting Nether
			23054, -- Gressil, Dawn of Ruin
			23577, -- The Hungering Cold
			22798, -- Might of Menethil
			22799, -- Soulseeker
			22520, -- The Phylactery of Kel'Thuzad
			23061, -- Ring of Faith
			23062, -- Frostfire Ring
			23063, -- Plagueheart Ring
			23060, -- Bonescythe Ring
			23064, -- Ring of the Dreamwalker
			23067, -- Ring of the Cryptstalker
			23065, -- Ring of the Earthshatterer
			23066, -- Ring of Redemption
			23059, -- Ring of the Dreadnaught
			22733, -- Staff Head of Atiesh
		},
	}
};

core.ZoneItemsExtraData = {
	-- World Bosses
	[0] = {
		17962, -- Blue Sack of Gems
		17963, -- Green Sack of Gems
		17964, -- Gray Sack of Gems
		17965, -- Yellow Sack of Gems
		17969, -- Red Sack of Gems
	},
	-- MoltenCore
	[409] = {
		18264, -- Plans: Elemental Sharpening Stone
		18292, -- Schematic: Core Marksman Rifle
		18291, -- Schematic: Force Reactive Disk
		18290, -- Schematic: Biznicks 247x128 Accurascope
		18259, -- Formula: Enchant Weapon - Spell Power
		18260, -- Formula: Enchant Weapon - Healing Power
		18252, -- Pattern: Core Armor Kit
		18265, -- Pattern: Flarecore Wraps
		11371, -- Pattern: Core Felcloth Bag
		18257, -- Recipe: Major Rejuvenation Potion
		16817, -- Girdle of Prophecy
		16802, -- Arcanist Belt
		16806, -- Felheart Belt
		16827, -- Nightslayer Belt
		16828, -- Cenarion Belt
		16851, -- Giantstalker's Belt
		16838, -- Earthfury Belt
		16858, -- Lawbringer Belt
		16864, -- Belt of Might
		17011, -- Lava Core
		17010, -- Fiery Core
		11382, -- Blood of the Mountain
		17012, -- Core Leather
		16819, -- Vambraces of Prophecy
		16799, -- Arcanist Bindings
		16804, -- Felheart Bracers
		16825, -- Nightslayer Bracelets
		16830, -- Cenarion Bracers
		16850, -- Giantstalker's Bracers
		16840, -- Earthfury Bracers
		16857, -- Lawbringer Bracers
		16861, -- Bracers of Might
	},
	-- Zul'Gurub
	[309] = {
		22721, -- Band of Servitude
		22722, -- Seal of the Gurubashi Berserker
		22720, -- Zulian Headdress
		22718, -- Blooddrenched Mask
		22711, -- Cloak of the Hakkari Worshipers
		22712, -- Might of the Tribe
		22715, -- Gloves of the Tormented
		22714, -- Sacrificial Gauntlets
		22716, -- Belt of Untapped Power
		22713, -- Zulian Scepter of Rites
		20263, -- Gurubashi Helm
		20259, -- Shadow Panther Hide Gloves
		20261, -- Shadow Panther Hide Belt
		19921, -- Zulian Hacker
		19908, -- Sceptre of Smiting
		20258, -- Zulian Ceremonial Staff
		19726, -- Bloodvine
		19774, -- Souldarite
		19767, -- Primal Bat Leather
		19768, -- Primal Tiger Leather
		19706, -- Bloodscalp Coin
		19701, -- Gurubashi Coin
		19700, -- Hakkari Coin
		19699, -- Razzashi Coin
		19704, -- Sandfury Coin
		19705, -- Skullsplitter Coin
		19702, -- Vilebranch Coin
		19703, -- Witherbark Coin
		19698, -- Zulian Coin
		19708, -- Blue Hakkari Bijou
		19713, -- Bronze Hakkari Bijou
		19715, -- Gold Hakkari Bijou
		19711, -- Green Hakkari Bijou
		19710, -- Orange Hakkari Bijou
		19712, -- Purple Hakkari Bijou
		19707, -- Red Hakkari Bijou
		19714, -- Silver Hakkari Bijou
		19709, -- Yellow Hakkari Bijou
		19789, -- Prophetic Aura
		19787, -- Presence of Sight
		19788, -- Hoodoo Hex
		19784, -- Death's Embrace
		19790, -- Animist's Caress
		19785, -- Falcon's Call
		19786, -- Vodouisant's Vigilant Embrace
		19783, -- Syncretist's Sigil
		19782, -- Presence of Might
		20077, -- Zandalar Signet of Might
		20076, -- Zandalar Signet of Mojo
		20078, -- Zandalar Signet of Serenity
		22635, -- Savage Guard
		19975, -- Zulian Mudskunk
		19727, -- Blood Scythe
		19820, -- Punctured Voodoo Doll
		19818, -- Punctured Voodoo Doll
		19819, -- Punctured Voodoo Doll
		19814, -- Punctured Voodoo Doll
		19821, -- Punctured Voodoo Doll
		19816, -- Punctured Voodoo Doll
		19817, -- Punctured Voodoo Doll
		19815, -- Punctured Voodoo Doll
		19813, -- Punctured Voodoo Doll
	},
	-- BlackwingLair
	[469] = {
		19436, -- Cloak of Draconic Might
		19439, -- Interlaced Shadow Jerkin
		19437, -- Boots of Pure Thought
		19438, -- Ringo's Blizzard Boots
		19434, -- Band of Dark Dominion
		19435, -- Essence Gatherer
		19362, -- Doom's Edge
		19354, -- Draconic Avenger
		19358, -- Draconic Maul
		18562, -- Elementium Ore
	},
	-- AQ20
	[509] = {
		function ()
			if core.faction == "Horde" then
				return 21804; -- Coif of Elemental Fury
			else
				return 21803; -- Helm of the Holy Avenger
			end
		end,
		21805, -- Polished Obsidian Pauldrons
		20873, -- Alabaster Idol
		20869, -- Amber Idol
		20866, -- Azure Idol
		20870, -- Jasper Idol
		20868, -- Lambent Idol
		20871, -- Obsidian Idol
		20867, -- Onyx Idol
		20872, -- Vermillion Idol
		21761, -- Scarab Coffer Key
		21156, -- Scarab Bag
		21801, -- Antenna of Invigoration
		21800, -- Silithid Husked Launcher
		21802, -- The Lost Kris of Zedd
		20864, -- Bone Scarab
		20861, -- Bronze Scarab
		20863, -- Clay Scarab
		20862, -- Crystal Scarab
		20859, -- Gold Scarab
		20865, -- Ivory Scarab
		20860, -- Silver Scarab
		20858, -- Stone Scarab
		22203, -- Large Obsidian Shard
		22202, -- Small Obsidian Shard
		21284, -- Codex of Greater Heal V
		21287, -- Codex of Prayer of Healing V
		21285, -- Codex of Renew X
		21279, -- Tome of Fireball XII
		21214, -- Tome of Frostbolt XI
		21280, -- Tome of Arcane Missiles VIII
		21281, -- Grimoire of Shadow Bolt X
		21283, -- Grimoire of Corruption VII
		21282, -- Grimoire of Immolate VIII
		21300, -- Handbook of Backstab IX
		21303, -- Handbook of Feint V
		21302, -- Handbook of Deadly Poison V
		21294, -- Book of Healing Touch XI
		21296, -- Book of Rejuvenation XI
		21295, -- Book of Starfire VII
		21306, -- Guide: Serpent Sting IX
		21304, -- Guide: Multi-Shot V
		21307, -- Guide: Aspect of the Hawk VII
		21291, -- Tablet of Healing Wave X
		21292, -- Tablet of Strength of Earth Totem V
		21293, -- Tablet of Grace of Air Totem III
		21288, -- Libram: Blessing of Wisdom VI
		21289, -- Libram: Blessing of Might VII
		21290, -- Libram: Holy Light IX
		21298, -- Manual of Battle Shout VII
		21299, -- Manual of Revenge VI
		21297, -- Manual of Heroic Strike IX
	},
	-- AQ40
	[531] = {
		21838, -- Garb of Royal Ascension
		21888, -- Gloves of the Immortal
		21889, -- Gloves of the Redeemed Prophecy
		21856, -- Neretzek, The Blood Drinker
		21837, -- Anubisath Warhammer
		21836, -- Ritssyn's Ring of Chaos
		21891, -- Shard of the Fallen Star
		21218, -- Blue Qiraji Resonating Crystal
		21324, -- Yellow Qiraji Resonating Crystal
		21323, -- Green Qiraji Resonating Crystal
		21321, -- Red Qiraji Resonating Crystal
	},
	-- Naxxramas
	[533] = {
		23664, -- Pauldrons of Elemental Fury
		23667, -- Spaulders of the Grand Crusader
		23069, -- Necro-Knight's Garb
		23226, -- Ghoul Skin Tunic
		23663, -- Girdle of Elemental Fury
		23666, -- Belt of the Grand Crusader
		23665, -- Leggings of Elemental Fury
		23668, -- Leggings of the Grand Crusader
		23237, -- Ring of the Eternal Flame
		23238, -- Stygian Buckler
		23044, -- Harbinger of Doom
		23221, -- Misplaced Servo Arm
		22376, -- Wartorn Cloth Scrap
		22373, -- Wartorn Leather Scrap
		22374, -- Wartorn Chain Scrap
		22375, -- Wartorn Plate Scrap
		23055, -- Word of Thawing
		22682, -- Frozen Rune
	},
}