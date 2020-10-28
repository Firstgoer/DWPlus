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
core.MonVersion = "v1.0.0";
core.BuildNumber = 10000;
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
					date1 = date("%m/%d/%y %H:%M:%S", tonumber(date1))
					missing[officer1] = date1 			-- if both missing seeds identify the same officer, it'll only list once
				end
			end

			if not search_loot then
				core.OOD = true
				local officer2, date2 = strsplit("-", DWPlus_Loot.seed)
				if (date2 and tonumber(date2) < (time() - 1209600)) or not DWP:ValidateSender(officer2) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date2 = date("%m/%d/%y %H:%M:%S", tonumber(date2))
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