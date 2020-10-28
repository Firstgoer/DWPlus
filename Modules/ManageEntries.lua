local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local function Remove_Entries()
	DWP:StatusVerify_Update()
	local numPlayers = 0;
	local removedUsers, c;
	local deleted = {}

	for i=1, #core.SelectedData do
		local search = DWP:Table_Search(DWPlus_RPTable, core.SelectedData[i]["player"]);
		local flag = false -- flag = only create archive entry if they appear anywhere in the history. If there's no history, there's no reason anyone would have it.
		local curTime = time()

		if search then
			local path = DWPlus_RPTable[search[1][1]]

			for i=1, #DWPlus_RPHistory do
				if strfind(DWPlus_RPHistory[i].players, ","..path.player..",") or strfind(DWPlus_RPHistory[i].players, path.player..",") == 1 then
					flag = true
				end
			end

			for i=1, #DWPlus_Loot do
				if DWPlus_Loot[i].player == path.player then
					flag = true
				end
			end
			
			if flag then 		-- above 2 loops flags character if they have any loot/dkp history. Only inserts to archive and broadcasts if found. Other players will not have the entry if no history exists
				if not DWPlus_Archive[core.SelectedData[i].player] then
					DWPlus_Archive[core.SelectedData[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime }
				else
					DWPlus_Archive[core.SelectedData[i].player].deleted = true
					DWPlus_Archive[core.SelectedData[i].player].edited = curTime
				end
				table.insert(deleted, { player=path.player, deleted=true })
			end

			c = DWP:GetCColors(core.SelectedData[i]["class"])
			if i==1 then
				removedUsers = "|cff"..c.hex..core.SelectedData[i]["player"].."|r"
			else
				removedUsers = removedUsers..", |cff"..c.hex..core.SelectedData[i]["player"].."|r"
			end
			numPlayers = numPlayers + 1

			tremove(DWPlus_RPTable, search[1][1])

			local search2 = DWP:Table_Search(DWPlus_Standby, core.SelectedData[i].player, "player");

			if search2 then
				table.remove(DWPlus_Standby, search2[1][1])
			end
		end
	end
	table.wipe(core.SelectedData)
	DWPSelectionCount_Update()
	DWP:FilterDKPTable(core.currentSort, "reset")
	DWP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
	DWP:ClassGraph_Update()
	if #deleted >0 then
		DWP.Sync:SendData("DWPDelUsers", deleted)
	end
end

function AddRaidToDKPTable()
	local GroupType = "none";

	if IsInRaid() then
		GroupType = "raid"
	elseif IsInGroup() then
		GroupType = "party"
	end

	if GroupType ~= "none" then
		local tempName,tempClass;
		local addedUsers, c
		local numPlayers = 0;
		local guildSize = GetNumGuildMembers();
		local name, rank, rankIndex;
		local InGuild = false; -- Only adds player to list if the player is found in the guild roster.
		local GroupSize;
		local FlagRecovery = false
		local curTime = time()

		if GroupType == "raid" then
			GroupSize = 40
		elseif GroupType == "party" then
			GroupSize = 5
		end

		for i=1, GroupSize do
			tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
			for j=1, guildSize do
				name, rank, rankIndex = GetGuildRosterInfo(j)
				name = strsub(name, 1, string.find(name, "-")-1)						-- required to remove server name from player (can remove in classic if this is not an issue)
				if name == tempName then
					InGuild = true;
				end
			end
			if tempName and InGuild then
				if not DWP:Table_Search(DWPlus_RPTable, tempName) then
					tinsert(DWPlus_RPTable, {
						player=tempName,
						class=tempClass,
						dkp=0,
						previous_dkp=0,
						lifetime_gained = 0,
						lifetime_spent = 0,
						rank = rankIndex,
						rankName = rank,
						spec = "No Spec Reported",
						role = "No Role Reported",
					});
					numPlayers = numPlayers + 1;
					c = DWP:GetCColors(tempClass)
					if addedUsers == nil then
						addedUsers = "|cff"..c.hex..tempName.."|r"; 
					else
						addedUsers = addedUsers..", |cff"..c.hex..tempName.."|r"
					end
					if DWPlus_Archive[tempName] and DWPlus_Archive[tempName].deleted then
						DWPlus_Archive[tempName].deleted = "Recovered"
						DWPlus_Archive[tempName].edited = curTime
						FlagRecovery = true
					end
				end
			end
			InGuild = false;
		end
		if addedUsers then
			DWP:Print(L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
		end
		if core.ClassGraph then
			DWP:ClassGraph_Update()
		else
			DWP:ClassGraph()
		end
		if FlagRecovery then 
			DWP:Print(L["YOUHAVERECOVERED"])
		end
		DWP:FilterDKPTable(core.currentSort, "reset")
	else
		DWP:Print(L["NOPARTYORRAID"])
	end
end

local function AddGuildToDKPTable(rank)
	local guildSize = GetNumGuildMembers();
	local class, addedUsers, c, name, rankName, rankIndex;
	local numPlayers = 0;
	local FlagRecovery = false
	local curTime = time()

	for i=1, guildSize do
		name,rankName,rankIndex,_,_,_,_,_,_,_,class = GetGuildRosterInfo(i)
		name = strsub(name, 1, string.find(name, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
		local search = DWP:Table_Search(DWPlus_RPTable, name)

		if not search and rankIndex == rank then
			tinsert(DWPlus_RPTable, {
				player=name,
				class=class,
				dkp=0,
				previous_dkp=0,
				lifetime_gained = 0,
				lifetime_spent = 0,
				rank=rank,
				rankName=rankName,
				spec = "No Spec Reported",
				role = "No Role Reported",
			});
			numPlayers = numPlayers + 1;
			c = DWP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|cff"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |cff"..c.hex..name.."|r"
			end
			if DWPlus_Archive[name] and DWPlus_Archive[name].deleted then
				DWPlus_Archive[name].deleted = "Recovered"
				DWPlus_Archive[name].edited = curTime
				FlagRecovery = true
			end
		end
	end
	DWP:FilterDKPTable(core.currentSort, "reset")
	if addedUsers then
		DWP:Print(L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
	end
	if FlagRecovery then 
		DWP:Print(L["YOUHAVERECOVERED"])
	end
	if core.ClassGraph then
		DWP:ClassGraph_Update()
	else
		DWP:ClassGraph()
	end
end

local function AddTargetToDKPTable()
	local name = UnitName("target");
	local _,class = UnitClass("target");
	local c;
	local curTime = time()

	local search = DWP:Table_Search(DWPlus_RPTable, name)

	if not search then
		tinsert(DWPlus_RPTable, {
			player=name,
			class=class,
			dkp=0,
			previous_dkp=0,
			lifetime_gained = 0,
			lifetime_spent = 0,
			rank=20,
			rankName="None",
			spec = "No Spec Reported",
			role = "No Role Reported",
		});

		DWP:FilterDKPTable(core.currentSort, "reset")
		c = DWP:GetCColors(class)
		DWP:Print(L["ADDED"].." |cff"..c.hex..name.."|r")

		if core.ClassGraph then
			DWP:ClassGraph_Update()
		else
			DWP:ClassGraph()
		end
		if DWPlus_Archive[name] and DWPlus_Archive[name].deleted then
			DWPlus_Archive[name].deleted = "Recovered"
			DWPlus_Archive[name].edited = curTime
			DWP:Print(L["YOUHAVERECOVERED"])
		end
	end
end

function GetGuildRankList()
	local numRanks = GuildControlGetNumRanks()
	local tempTable = {}
	for i=1, numRanks do
		table.insert(tempTable, {index = i-1, name = GuildControlGetRankName(i)})
	end
	
	return tempTable;
end

function DWP:reset_prev_dkp(player)
	if player then
		local search = DWP:Table_Search(DWPlus_RPTable, player, "player")

		if search then
			DWPlus_RPTable[search[1][1]].previous_dkp = DWPlus_RPTable[search[1][1]].dkp
		end
	else
		for i=1, #DWPlus_RPTable do
			DWPlus_RPTable[i].previous_dkp = DWPlus_RPTable[i].dkp
		end
	end
end

local function UpdateWhitelist()
	if #core.SelectedData > 0 then
		table.wipe(DWPlus_Whitelist)
		for i=1, #core.SelectedData do
			local validate = DWP:ValidateSender(core.SelectedData[i].player)

			if not validate then
				StaticPopupDialogs["VALIDATE_OFFICER"] = {
					text = core.SelectedData[i].player.." "..L["NOTANOFFICER"],
					button1 = "Ok",
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("VALIDATE_OFFICER")
				return;
			end
		end
		for i=1, #core.SelectedData do
			table.insert(DWPlus_Whitelist, core.SelectedData[i].player)
		end

		local verifyLeadAdded = DWP:Table_Search(DWPlus_Whitelist, UnitName("player"))

		if not verifyLeadAdded then
			local pname = UnitName("player");
			table.insert(DWPlus_Whitelist, pname)		-- verifies leader is included in white list. Adds if they aren't
		end
	else
		table.wipe(DWPlus_Whitelist)
	end
	DWP.Sync:SendData("DWPWhitelist", DWPlus_Whitelist)
	DWP:Print(L["WHITELISTBROADCASTED"])
end

local function ViewWhitelist()
	if #DWPlus_Whitelist > 0 then
		core.SelectedData = {}
		for i=1, #DWPlus_Whitelist do
			local search = DWP:Table_Search(DWPlus_RPTable, DWPlus_Whitelist[i])

			if search then
				table.insert(core.SelectedData, DWPlus_RPTable[search[1][1]])
			end
		end
		DWP:FilterDKPTable(core.currentSort, "reset")
	end
end

function DWP:ManageEntries()

	-- add raid to dkp table if they don't exist
	DWP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 30, -90, L["ADDRAIDMEMBERS"]);
	DWP.ConfigTab3.add_raid_to_table:SetSize(120,25);
	DWP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDRAIDMEMBERS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDRAIDMEMBERSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.add_raid_to_table:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab3.add_raid_to_table:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		local selected = L["ADDRAIDMEMBERSCONFIRM"];

		StaticPopupDialogs["ADD_RAID_ENTRIES"] = {
		  text = selected,
		  button1 = L["YES"],
		  button2 = L["NO"],
		  OnAccept = function()
		      AddRaidToDKPTable()
		  end,
		  timeout = 0,
		  whileDead = true,
		  hideOnEscape = true,
		  preferredIndex = 3,
		}
		StaticPopup_Show ("ADD_RAID_ENTRIES")
	end);

	DWP.ConfigTab3.AddEntriesHeader = DWP.ConfigTab3:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab3.AddEntriesHeader:SetPoint("BOTTOMLEFT", DWP.ConfigTab3.add_raid_to_table, "TOPLEFT", -10, 10);
	DWP.ConfigTab3.AddEntriesHeader:SetWidth(400)
	DWP.ConfigTab3.AddEntriesHeader:SetFontObject("DWPNormalLeft")
	DWP.ConfigTab3.AddEntriesHeader:SetText(L["ADDREMDKPTABLEENTRIES"]);

	-- remove selected entries button
	DWP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 170, -60, L["REMOVEENTRIES"]);
	DWP.ConfigTab3.remove_entries:SetSize(120,25);
	DWP.ConfigTab3.remove_entries:ClearAllPoints()
	DWP.ConfigTab3.remove_entries:SetPoint("LEFT", DWP.ConfigTab3.add_raid_to_table, "RIGHT", 20, 0)
	DWP.ConfigTab3.remove_entries:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["REMOVESELECTEDENTRIES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["REMSELENTRIESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["REMSELENTRIESTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.remove_entries:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab3.remove_entries:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		if #core.SelectedData > 0 then
			local selected = L["CONFIRMREMOVESELECT"]..": \n\n";

			for i=1, #core.SelectedData do
				local classSearch = DWP:Table_Search(DWPlus_RPTable, core.SelectedData[i].player)

			    if classSearch then
			     	c = DWP:GetCColors(DWPlus_RPTable[classSearch[1][1]].class)
			    else
			     	c = { hex="ffffff" }
			    end
				if i == 1 then
					selected = selected.."|cff"..c.hex..core.SelectedData[i].player.."|r"
				else
					selected = selected..", |cff"..c.hex..core.SelectedData[i].player.."|r"
				end
			end
			selected = selected.."?"

			StaticPopupDialogs["REMOVE_ENTRIES"] = {
			  text = selected,
			  button1 = L["YES"],
			  button2 = L["NO"],
			  OnAccept = function()
			      Remove_Entries()
			  end,
			  timeout = 0,
			  whileDead = true,
			  hideOnEscape = true,
			  preferredIndex = 3,
			}
			StaticPopup_Show ("REMOVE_ENTRIES")
		else
			DWP:Print(L["NOENTRIESSELECTED"])
		end
	end);

	-- Reset previous DKP -- number showing how much a player has gained or lost since last clear
	DWP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 310, -60, L["RESETPREVIOUS"]);
	DWP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
	DWP.ConfigTab3.reset_previous_dkp:ClearAllPoints()
	DWP.ConfigTab3.reset_previous_dkp:SetPoint("LEFT", DWP.ConfigTab3.remove_entries, "RIGHT", 20, 0)
	DWP.ConfigTab3.reset_previous_dkp:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["RESETPREVDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["RESETPREVDKPTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["RESETPREVDKPTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.reset_previous_dkp:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab3.reset_previous_dkp:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
		StaticPopupDialogs["RESET_PREVIOUS_DKP"] = {
			text = L["RESETPREVCONFIRM"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
			    DWP:reset_prev_dkp()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("RESET_PREVIOUS_DKP")
	end);

	local curIndex;
	local curRank;

	DWP.ConfigTab3.GuildRankDropDown = CreateFrame("FRAME", "DWPConfigReasonDropDown", DWP.ConfigTab3, "DWPlusUIDropDownMenuTemplate")
	DWP.ConfigTab3.GuildRankDropDown:SetPoint("TOPLEFT", DWP.ConfigTab3.add_raid_to_table, "BOTTOMLEFT", -17, -15)
	DWP.ConfigTab3.GuildRankDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["RANKLIST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["RANKLISTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.GuildRankDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	UIDropDownMenu_SetWidth(DWP.ConfigTab3.GuildRankDropDown, 105)
	UIDropDownMenu_SetText(DWP.ConfigTab3.GuildRankDropDown, "Select Rank")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(DWP.ConfigTab3.GuildRankDropDown, function(self, level, menuList)
	local rank = UIDropDownMenu_CreateInfo()
		rank.func = self.SetValue
		rank.fontObject = "DWPSmallCenter"

		local rankList = GetGuildRankList()

		for i=1, #rankList do
			rank.text, rank.arg1, rank.arg2, rank.checked, rank.isNotRadio = rankList[i].name, rankList[i].name, rankList[i].index, rankList[i].name == curRank, true
			UIDropDownMenu_AddButton(rank)
		end
	end)

	-- Dropdown Menu Function
	function DWP.ConfigTab3.GuildRankDropDown:SetValue(arg1, arg2)
		if curRank ~= arg1 then
			curRank = arg1
			curIndex = arg2
			UIDropDownMenu_SetText(DWP.ConfigTab3.GuildRankDropDown, arg1)
		else
			curRank = nil
			curIndex = nil
			UIDropDownMenu_SetText(DWP.ConfigTab3.GuildRankDropDown, L["SELECTRANK"])
		end

		CloseDropDownMenus()
	end

	-- Add Guild to DKP Table Button
	DWP.ConfigTab3.AddGuildToDKP = self:CreateButton("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDGUILDMEMBERS"]);
	DWP.ConfigTab3.AddGuildToDKP:SetSize(120,25);
	DWP.ConfigTab3.AddGuildToDKP:ClearAllPoints()
	DWP.ConfigTab3.AddGuildToDKP:SetPoint("LEFT", DWP.ConfigTab3.GuildRankDropDown, "RIGHT", 2, 2)
	DWP.ConfigTab3.AddGuildToDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDGUILDDKPTABLE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDGUILDDKPTABLETT"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.AddGuildToDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab3.AddGuildToDKP:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
		if curIndex ~= nil then
			StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
				text = L["ADDGUILDCONFIRM"].." \""..curRank.."\"?",
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
				    AddGuildToDKPTable(curIndex)
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADD_GUILD_MEMBERS")
		else
			StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
				text = L["NORANKSELECTED"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADD_GUILD_MEMBERS")
		end
	end);

	DWP.ConfigTab3.AddTargetToDKP = self:CreateButton("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDTARGET"]);
	DWP.ConfigTab3.AddTargetToDKP:SetSize(120,25);
	DWP.ConfigTab3.AddTargetToDKP:ClearAllPoints()
	DWP.ConfigTab3.AddTargetToDKP:SetPoint("LEFT", DWP.ConfigTab3.AddGuildToDKP, "RIGHT", 20, 0)
	DWP.ConfigTab3.AddTargetToDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDTARGETTODKPTABLE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDTARGETTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.AddTargetToDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab3.AddTargetToDKP:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
		if UnitIsPlayer("target") == true then
			StaticPopupDialogs["ADD_TARGET_DKP"] = {
				text = L["CONFIRMADDTARGET"].." "..UnitName("target").." "..L["TODKPLIST"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
				    AddTargetToDKPTable()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADD_TARGET_DKP")
		else
			StaticPopupDialogs["ADD_TARGET_DKP"] = {
				text = L["NOPLAYERTARGETED"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADD_TARGET_DKP")
		end
	end);

	DWP.ConfigTab3.CleanList = self:CreateButton("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 0, 0, L["PURGELIST"]);
	DWP.ConfigTab3.CleanList:SetSize(120,25);
	DWP.ConfigTab3.CleanList:ClearAllPoints()
	DWP.ConfigTab3.CleanList:SetPoint("TOP", DWP.ConfigTab3.AddTargetToDKP, "BOTTOM", 0, -16)
	DWP.ConfigTab3.CleanList:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["PURGELIST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["PURGELISTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab3.CleanList:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab3.CleanList:SetScript("OnClick", function()
		StaticPopupDialogs["PURGE_CONFIRM"] = {
			text = L["PURGECONFIRM"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				local purgeString, c, name;
				local count = 0;
				local i = 1;

				while i <= #DWPlus_RPTable do
					local search = DWP:TableStrFind(DWPlus_RPHistory, DWPlus_RPTable[i].player, "players")

					if DWPlus_RPTable[i].dkp == 0 and not search then
						c = DWP:GetCColors(DWPlus_RPTable[i].class)
						name = DWPlus_RPTable[i].player;

						if purgeString == nil then
							purgeString = "|cff"..c.hex..name.."|r"; 
						else
							purgeString = purgeString..", |cff"..c.hex..name.."|r"
						end

						count = count + 1;
						table.remove(DWPlus_RPTable, i)
					else
						i=i+1;
					end
				end
				if count > 0 then
					DWP:Print(L["PURGELIST"].." ("..count.."):")
					DWP:Print(purgeString)
					DWP:FilterDKPTable(core.currentSort, "reset")
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("PURGE_CONFIRM")
	end)

	DWP.ConfigTab3.WhitelistContainer = CreateFrame("Frame", nil, DWP.ConfigTab3);
	DWP.ConfigTab3.WhitelistContainer:SetSize(475, 200);
	DWP.ConfigTab3.WhitelistContainer:SetPoint("TOPLEFT", DWP.ConfigTab3.GuildRankDropDown, "BOTTOMLEFT", 20, -30)

		-- Whitelist Header
		DWP.ConfigTab3.WhitelistContainer.WhitelistHeader = DWP.ConfigTab3.WhitelistContainer:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetPoint("TOPLEFT", DWP.ConfigTab3.WhitelistContainer, "TOPLEFT", -10, 0);
		DWP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetWidth(400)
		DWP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetFontObject("DWPNormalLeft")
		DWP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetText(L["WHITELISTHEADER"]);

		DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton = self:CreateButton("BOTTOMLEFT", DWP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SETWHITELIST"]);
		DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton:ClearAllPoints()
		DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetPoint("TOPLEFT", DWP.ConfigTab3.WhitelistContainer.WhitelistHeader, "BOTTOMLEFT", 10, -10)
		DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["SETWHITELIST"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["SETWHITELISTTTDESC1"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["SETWHITELISTTTDESC2"], 0.2, 1.0, 0.2, true);
			GameTooltip:AddLine(L["SETWHITELISTTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			if #core.SelectedData > 0 then
				StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					text = L["CONFIRMWHITELIST"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
					    UpdateWhitelist()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_GUILD_MEMBERS")
			else
				StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					text = L["CONFIRMWHITELISTCLEAR"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
					    UpdateWhitelist()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_GUILD_MEMBERS")
			end
		end);

		-- View Whitelist Button
		DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton = self:CreateButton("BOTTOMLEFT", DWP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["VIEWWHITELISTBTN"]);
		DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:ClearAllPoints()
		DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetPoint("LEFT", DWP.ConfigTab3.WhitelistContainer.AddWhitelistButton, "RIGHT", 10, 0)
		DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["VIEWWHITELISTBTN"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["VIEWWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			if #DWPlus_Whitelist > 0 then
				ViewWhitelist()
			else
				StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					text = L["WHITELISTEMPTY"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_GUILD_MEMBERS")
			end
		end);

		-- Broadcast Whitelist Button
		DWP.ConfigTab3.WhitelistContainer.SendWhitelistButton = self:CreateButton("BOTTOMLEFT", DWP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SENDWHITELIST"]);
		DWP.ConfigTab3.WhitelistContainer.SendWhitelistButton:ClearAllPoints()
		DWP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetPoint("LEFT", DWP.ConfigTab3.WhitelistContainer.ViewWhitelistButton, "RIGHT", 30, 0)
		DWP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["SENDWHITELIST"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["SENDWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["SENDWHITELISTTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		DWP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnClick", function ()	-- confirmation dialog to add user(s)
			DWP.Sync:SendData("DWPWhitelist", DWPlus_Whitelist)
			DWP:Print(L["WHITELISTBROADCASTED"])
		end);

	local CheckLeader = DWP:GetGuildRankIndex(UnitName("player"))
	if CheckLeader == 1 then
		DWP.ConfigTab3.WhitelistContainer:Show()
	else
		DWP.ConfigTab3.WhitelistContainer:Hide()
	end
end