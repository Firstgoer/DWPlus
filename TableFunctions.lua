local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local SelectedRow = 0;        -- sets the row that is being clicked
local menuFrame = CreateFrame("Frame", "DWPDKPTableMenuFrame", UIParent, "UIDropDownMenuTemplate")
local ConvToRaidEvent = CreateFrame("Frame", "DWPConvToRaidEventsFrame");
local InvCount;
local LastSelection = 0;

function DWPSelectionCount_Update()
	if #core.SelectedData == 0 then
		DWP.DKPTable.counter.s:SetText("");    -- updates "Entries Shown" at bottom of DKPTable
	else
		if #core.SelectedData == 1 then
			DWP.DKPTable.counter.s:SetText("("..#core.SelectedData.." "..L["ENTRYSELECTED"]..")");
		else
			DWP.DKPTable.counter.s:SetText("("..#core.SelectedData.." "..L["ENTRIESSELECTED"]..")");
		end
	end
end

local function CountDown(time)
	if time then CooldownTimer = time end
	if CooldownTimer > 0 then
		C_Timer.After(1, function()
			CooldownTimer = CooldownTimer - 1
			CountDown()
		end)
	end
end

function DKPTable_OnClick(self)   
	local offset = FauxScrollFrame_GetOffset(DWP.DKPTable) or 0
	local index, TempSearch;
	SelectedRow = self.index

	if UIDROPDOWNMENU_OPEN_MENU then
		ToggleDropDownMenu(nil, nil, menuFrame)
	end
	
	if IsShiftKeyDown() then
		if LastSelection < SelectedRow then
			for i=LastSelection+1, SelectedRow do
				TempSearch = DWP:Table_Search(core.SelectedData, core.WorkingTable[i].player);
				
				if not TempSearch then
					tinsert(core.SelectedData, core.WorkingTable[i])
				end
			end
		else
			for i=SelectedRow, LastSelection-1 do
				TempSearch = DWP:Table_Search(core.SelectedData, core.WorkingTable[i].player);
				
				if not TempSearch then
					tinsert(core.SelectedData, core.WorkingTable[i])
				end
			end
		end

		if DWP.ConfigTab2.selectAll:GetChecked() then
			DWP.ConfigTab2.selectAll:SetChecked(false)
		end
	elseif IsControlKeyDown() then
		LastSelection = SelectedRow;
		TempSearch = DWP:Table_Search(core.SelectedData, core.WorkingTable[SelectedRow].player);
		if TempSearch == false then
			tinsert(core.SelectedData, core.WorkingTable[SelectedRow]);
			PlaySound(808)
		else
			tremove(core.SelectedData, TempSearch[1][1])
			PlaySound(868)
		end
	else
		LastSelection = SelectedRow;
		for i=1, core.TableNumRows do
			TempSearch = DWP:Table_Search(core.SelectedData, core.WorkingTable[SelectedRow].player);
			if DWP.ConfigTab2.selectAll:GetChecked() then
				DWP.ConfigTab2.selectAll:SetChecked(false)
			end
			if (TempSearch == false) then
				tinsert(core.SelectedData, core.WorkingTable[SelectedRow]);
				PlaySound(808)
			else
				core.SelectedData = {}
			end
		end
	end

	DKPTable_Update()
	DWPSelectionCount_Update()
end

local function Invite_OnEvent(self, event, arg1, ...)
	if event == "CHAT_MSG_SYSTEM" then
		if strfind(arg1, " joins the party.") then
			ConvertToRaid()
			ConvToRaidEvent:UnregisterEvent("CHAT_MSG_SYSTEM")
			for i=InvCount+1, #core.SelectedData do
				InviteUnit(core.SelectedData[i].player)
			end
		end
	end
end

local function DisplayUserHistory(self, player)
	local PlayerTable = {}
	local c, PlayerSearch, PlayerSearch2, LifetimeSearch, RowCount, curDate;

	PlayerSearch = DWP:TableStrFind(DWPlus_RPHistory, player, "players")
	PlayerSearch2 = DWP:Table_Search(DWPlus_Loot, player, "player")
	LifetimeSearch = DWP:Table_Search(DWPlus_RPTable, player, "player")

	c = DWP:GetCColors(DWPlus_RPTable[LifetimeSearch[1][1]].class)

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
	GameTooltip:SetText(L["RECENTHISTORYFOR"].." |cff"..c.hex..player.."|r\n", 0.25, 0.75, 0.90, 1, true);

	if PlayerSearch then
		for i=1, #PlayerSearch do
			if not DWPlus_RPHistory[PlayerSearch[i][1]].deletes and not DWPlus_RPHistory[PlayerSearch[i][1]].deletedby and not DWPlus_RPHistory[PlayerSearch[i][1]].hidden then
				tinsert(PlayerTable, {reason = DWPlus_RPHistory[PlayerSearch[i][1]].reason, date = DWPlus_RPHistory[PlayerSearch[i][1]].date, dkp = DWPlus_RPHistory[PlayerSearch[i][1]].dkp})
			end
		end
	end

	if PlayerSearch2 then
		for i=1, #PlayerSearch2 do
			if not DWPlus_Loot[PlayerSearch2[i][1]].deletes and not DWPlus_Loot[PlayerSearch2[i][1]].deletedby and not DWPlus_Loot[PlayerSearch2[i][1]].hidden then
				tinsert(PlayerTable, {loot = DWPlus_Loot[PlayerSearch2[i][1]].loot, date = DWPlus_Loot[PlayerSearch2[i][1]].date, zone = DWPlus_Loot[PlayerSearch2[i][1]].zone, boss = DWPlus_Loot[PlayerSearch2[i][1]].boss, cost = DWPlus_Loot[PlayerSearch2[i][1]].cost})
			end
		end
	end

	table.sort(PlayerTable, function(a, b)
		return a["date"] > b["date"]
	end)

	if #PlayerTable > 0 then
		if #PlayerTable > DWPlus_DB.defaults.TooltipHistoryCount then
			RowCount = DWPlus_DB.defaults.TooltipHistoryCount
		else
			RowCount = #PlayerTable;
		end

		for i=1, RowCount do
			if date("%d/%m/%y", PlayerTable[i].date) ~= curDate then
				curDate = date("%d/%m/%y", PlayerTable[i].date)
				GameTooltip:AddLine(date("%d/%m/%y", PlayerTable[i].date), 1.0, 1.0, 1.0, true);
			end
			if PlayerTable[i].dkp then
				if strfind(PlayerTable[i].dkp, "%%") then
					local decay = {strsplit(",", PlayerTable[i].dkp)}
					GameTooltip:AddDoubleLine("  "..PlayerTable[i].reason, "|cffff0000"..decay[#decay].." RP|r", 1.0, 0, 0);
				elseif tonumber(PlayerTable[i].dkp) < 0 then
					GameTooltip:AddDoubleLine("  "..PlayerTable[i].reason, "|cffff0000"..DWP_round(PlayerTable[i].dkp, DWPlus_DB.modes.rounding).." RP|r", 1.0, 0, 0);
				else
					GameTooltip:AddDoubleLine("  "..PlayerTable[i].reason, "|cff00ff00"..DWP_round(PlayerTable[i].dkp, DWPlus_DB.modes.rounding).." RP|r", 0, 1.0, 0);
				end
			elseif PlayerTable[i].cost then
				GameTooltip:AddDoubleLine("  "..PlayerTable[i].zone..": |cffff0000"..PlayerTable[i].boss.."|r", PlayerTable[i].loot.." |cffff0000("..PlayerTable[i].cost.." RP)|r", 1.0, 1.0, 1.0);
			end
		end
		GameTooltip:AddDoubleLine(" ", " ", 1.0, 1.0, 1.0);
		GameTooltip:AddLine("  |cff00ff00"..L["LIFETIMEEARNED"]..": "..DWPlus_RPTable[LifetimeSearch[1][1]].lifetime_gained.."|r", 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine("  |cffff0000"..L["LIFETIMESPENT"]..": "..DWPlus_RPTable[LifetimeSearch[1][1]].lifetime_spent.."|r", 1.0, 1.0, 1.0, true);
	else
		GameTooltip:AddLine("No RP Entries", 1.0, 1.0, 1.0, true);
	end

	GameTooltip:Show();
end

local function EditStandbyList(row, arg1)
	if arg1 ~= "clear" then
		if #core.SelectedData > 1 then
			local copy = CopyTable(core.SelectedData)

			for i=1, #copy do
				local search = DWP:Table_Search(DWPlus_Standby, copy[i].player)

				if arg1 == "add" then
					if not search then
						table.insert(DWPlus_Standby, copy[i])
					end
				elseif arg1 == "remove" then          
					if search then
						table.remove(DWPlus_Standby, search[1][1])
						core.SelectedData = {}
						if core.CurView == "limited" then
							table.remove(core.WorkingTable, search[1][1])
						end
					end
				end
			end
		else
			if arg1 == "add" then
				table.insert(DWPlus_Standby, core.WorkingTable[row])
			elseif arg1 == "remove" then
				local search = DWP:Table_Search(DWPlus_Standby, core.WorkingTable[row].player)

				if search then
					table.remove(DWPlus_Standby, search[1][1])
					core.SelectedData = {}
					if core.CurView == "limited" then
						table.remove(core.WorkingTable, search[1][1])
					end
				end
			end
		end
		DWP.Sync:SendData("DWPStand", DWPlus_Standby)
		DKPTable_Update()
	else
		table.wipe(DWPlus_Standby)
		core.WorkingTable = {}
		DKPTable_Update()
		DWP.Sync:SendData("DWPStand", DWPlus_Standby)
	end
	if #core.WorkingTable == 0 then
		core.WorkingTable = CopyTable(DWPlus_RPTable);
		core.CurView = "all"
		DWP:FilterDKPTable(core.currentSort, "reset")
	end
end

function DWP:ViewLimited(raid, standby, raiders)
	if #DWPlus_Standby == 0 and standby and not raid and not raiders then
		DWP:Print(L["NOPLAYERINSTANDBY"])
		core.CurView = "all"
		core.CurSubView = "all"
	elseif raid or standby or raiders then
		local tempTable = {}
		local GroupType = "none"
		
		if (not IsInGroup() and not IsInRaid()) and raid then
			DWP:Print(L["NOPARTYORRAID"])
			core.WorkingTable = CopyTable(DWPlus_RPTable)
			core.CurView = "all"
			core.CurSubView = "all"
			for i=1, 9 do
				DWP.ConfigTab1.checkBtn[i]:SetChecked(true)
			end
			DWP:FilterDKPTable(core.currentSort, "reset");
			return;
		end

		if raid then
			for k,v in pairs(DWPlus_RPTable) do
				if type(v) == "table" then
					for i=1, 40 do
						tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
						if tempName and tempName == v.player then
							tinsert(tempTable, v)
						end
					end
				end
			end
		end

		if standby then
			for i=1, #DWPlus_Standby do
				local search = DWP:Table_Search(DWPlus_RPTable, DWPlus_Standby[i].player)
				local search2 = DWP:Table_Search(tempTable, DWPlus_Standby[i].player)
				
				if search and not search2 then
					table.insert(tempTable, DWPlus_RPTable[search[1][1]])
				end
			end
		end

		if raiders then
			local guildSize = GetNumGuildMembers();
			local name, rankIndex;

			for i=1, guildSize do
				name,_,rankIndex = GetGuildRosterInfo(i)
				name = strsub(name, 1, string.find(name, "-")-1)      -- required to remove server name from player (can remove in classic if this is not an issue)
				local search = DWP:Table_Search(DWPlus_RPTable, name)

				if search then
					local rankList = GetGuildRankList()

					local match_rank = DWP:Table_Search(DWPlus_DB.raiders, rankList[rankIndex+1].name)

					if match_rank then
						table.insert(tempTable, DWPlus_RPTable[search[1][1]])
					end
				end
			end
			if #tempTable == 0 then
				DWP:Print(L["NOCORERAIDTEAM"])
				return;
			end
		end

		core.SelectedData = {}
		LastSelection = 0
		DWPSelectionCount_Update()
		core.WorkingTable = CopyTable(tempTable)
		table.wipe(tempTable)

		core.CurView = "limited"
		DKPTable_Update()
	elseif core.CurView == "limited" then
		core.WorkingTable = CopyTable(DWPlus_RPTable)
		core.CurView = "all"
		core.CurSubView = "all"
		for i=1, 9 do
			DWP.ConfigTab1.checkBtn[i]:SetChecked(true)
		end
		DWPFilterChecks(DWP.ConfigTab1.checkBtn[1])
	end
end

local function RightClickMenu(self)
	local menu;
	local disabled;

	if #DWPlus_Standby < 1 then disabled = true else disabled = false end

	menu = {
		{ text = L["MULTIPLESELECT"], isTitle = true, notCheckable = true}, --1
		{ text = L["INVITESELECTED"], notCheckable = true, func = function()
			InvCount = 4 - GetNumSubgroupMembers()
			
			for i=1, InvCount do
				InviteUnit(core.SelectedData[i].player)
			end
			if #core.SelectedData >= 5 then
				ConvToRaidEvent:RegisterEvent("CHAT_MSG_SYSTEM")
				ConvToRaidEvent:SetScript("OnEvent", Invite_OnEvent);
			end
		end }, --2
		{ text = L["SELECTALL"], notCheckable = true, func = function()
			core.SelectedData = CopyTable(core.WorkingTable);
			DWPSelectionCount_Update()
			DKPTable_Update()
		end }, --3
		{ text = " ", notCheckable = true, disabled = true}, --4
		{ text = L["VIEWS"], isTitle = true, notCheckable = true}, --5
		{ text = L["TABLEVIEWS"], notCheckable = true, hasArrow = true,
				menuList = { 
					{ text = L["VIEWRAID"], notCheckable = true, keepShownOnClick = false; func = function()
						DWP:ViewLimited(true)
						core.CurSubView = "raid"
						DWP.ConfigTab1.checkBtn[10]:SetChecked(true);
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
					{ text = L["VIEWSTANDBY"], notCheckable = true, func = function()
						DWP:ViewLimited(false, true)
						core.CurSubView = "standby"
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
					{ text = L["VIEWRAIDSTANDBY"], notCheckable = true, func = function()
						DWP:ViewLimited(true, true)
						core.CurSubView = "raid and standby"
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
					{ text = L["VIEWCORERAID"], notCheckable = true, func = function()
						DWP:ViewLimited(false, false, true)
						DWP:SortDKPTable("class", "Reset")
						core.CurSubView = "core"
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
					{ text = L["VIEWALL"], notCheckable = true, func = function()
						DWP.ConfigTab1.checkBtn[10]:SetChecked(false);
						DWP.ConfigTab1.checkBtn[11]:SetChecked(false);
						DWP.ConfigTab1.checkBtn[12]:SetChecked(false);
						DWP:ViewLimited()
						ToggleDropDownMenu(nil, nil, menuFrame, nil, nil, nil, nil, nil)
					end },
			}
		}, --6
		{ text = L["CLASSFILTER"], notCheckable = true, hasArrow = true,
				menuList = {}
		}, --7
		{ text = " ", notCheckable = true, disabled = true}, --8
		{ text = L["MANAGELISTS"], isTitle = true, notCheckable = true}, --9
		{ text = L["MANAGESTANDBY"], notCheckable = true, hasArrow = true,
				menuList = {
					{ text = L["ADDTOSTANDBY"], notCheckable = true, func = function()
						EditStandbyList(self.index, "add")
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
					{ text = L["REMOVEFROMSTANDBY"], notCheckable = true, func = function()
						EditStandbyList(self.index, "remove")
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
					{ text = L["CLEARSTANDBY"], notCheckable = true, disabled = disabled, func = function()
						EditStandbyList(self.index, "clear")
						ToggleDropDownMenu(nil, nil, menuFrame)
					end },
				}
		}, --10
		{ text = L["MANAGECORELIST"], notCheckable = true, hasArrow = true,
				menuList = {}
		}, --11
		{ text = " ", notCheckable = true, disabled = true}, --12
		{ text = L["RESETPREVIOUS"], notCheckable = true, func = function()
			for i=1, #core.SelectedData do
				DWP:reset_prev_dkp(core.SelectedData[i].player)
			end
			DWP:FilterDKPTable(core.currentSort, "reset")
		end 
		}, --13
		{ text = L["VALIDATETABLES"], notCheckable = true, disabled = not core.IsOfficer, func = function()
			StaticPopupDialogs["VALIDATE_WARN"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["VALIDATEWARN"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					DWP:ValidateLootTable()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("VALIDATE_WARN")
		end 
		}, --14
	}

	if #core.SelectedData < 2 then
		menu[1].text = core.WorkingTable[self.index].player;
		menu[2] = { text = L["INVITE"].." "..core.WorkingTable[self.index].player.." "..L["TORAID"], notCheckable = true, func = function()
			InviteUnit(core.WorkingTable[self.index].player)
		end }

		local StandbySearch = DWP:Table_Search(DWPlus_Standby, core.WorkingTable[self.index].player)
		
		if StandbySearch then
			menu[10].menuList = {
				{ text = L["REMOVE"].." "..core.WorkingTable[self.index].player.." "..L["FROMSTANDBYLIST"], notCheckable = true, func = function()
					EditStandbyList(self.index, "remove")
					ToggleDropDownMenu(nil, nil, menuFrame)
				end },
				{ text = L["CLEARSTANDBY"], notCheckable = true, disabled = disabled, func = function()
					EditStandbyList(self.index, "clear")
					ToggleDropDownMenu(nil, nil, menuFrame)
				end },
			}
		else
			menu[10].menuList = {
				{ text = L["ADD"].." "..core.WorkingTable[self.index].player.." "..L["TOSTANDBYLIST"], notCheckable = true, func = function()
					EditStandbyList(self.index, "add")
					ToggleDropDownMenu(nil, nil, menuFrame)
				end },
				{ text = L["CLEARSTANDBY"], notCheckable = true, disabled = disabled, func = function()
					EditStandbyList(self.index, "clear")
					ToggleDropDownMenu(nil, nil, menuFrame)
				end },
			}
		end
	end

	for i=1, #core.classes do       -- create Filter selections in context menu
		menu[7].menuList[i] = { text = core.LocalClass[core.classes[i]], isNotRadio = true, keepShownOnClick = true, checked = DWP.ConfigTab1.checkBtn[i]:GetChecked(), func = function()
			DWP.ConfigTab1.checkBtn[i]:SetChecked(not DWP.ConfigTab1.checkBtn[i]:GetChecked())
			DWPFilterChecks(DWP.ConfigTab1.checkBtn[9])
			for j=1, #core.classes+1 do
				menu[7].menuList[j].checked = DWP.ConfigTab1.checkBtn[j]:GetChecked()
			end
		end }
	end

	menu[7].menuList[#core.classes+1] = { text = L["ALLCLASSES"], isNotRadio = true, keepShownOnClick = false, notCheckable = true, func = function()
		DWP.ConfigTab1.checkBtn[9]:SetChecked(true)
		
		for i=1, #core.classes do
			DWP.ConfigTab1.checkBtn[i]:SetChecked(true)
			menu[7].menuList[i].checked = true
		end

		DWPFilterChecks(DWP.ConfigTab1.checkBtn[9])
		if UIDROPDOWNMENU_OPEN_MENU then
			ToggleDropDownMenu(nil, nil, menuFrame)
		end
	end }

	menu[7].menuList[#core.classes+2] = { text = L["ONLYPARTYRAID"], isNotRadio = true, keepShownOnClick = false, disabled = not IsInRaid(), checked = DWP.ConfigTab1.checkBtn[10]:GetChecked(), func = function()
		DWP.ConfigTab1.checkBtn[10]:SetChecked(not DWP.ConfigTab1.checkBtn[10]:GetChecked())
		DWP.ConfigTab1.checkBtn[12]:SetChecked(false)
		menu[7].menuList[#core.classes+4].checked = false

		DWPFilterChecks(DWP.ConfigTab1.checkBtn[10])
		if UIDROPDOWNMENU_OPEN_MENU then
			ToggleDropDownMenu(nil, nil, menuFrame)
		end
	end }

	menu[7].menuList[#core.classes+3] = { text = L["ONLINE"], isNotRadio = true, keepShownOnClick = true, checked = DWP.ConfigTab1.checkBtn[11]:GetChecked(), func = function()
		DWP.ConfigTab1.checkBtn[11]:SetChecked(not DWP.ConfigTab1.checkBtn[11]:GetChecked())
		core.CurView = "limited"

		DWPFilterChecks(DWP.ConfigTab1.checkBtn[11])
	end }

	menu[7].menuList[#core.classes+4] = { text = L["NOTINRAIDFILTER"], isNotRadio = true, keepShownOnClick = false, disabled = not IsInRaid(), checked = DWP.ConfigTab1.checkBtn[12]:GetChecked(), func = function()
		DWP.ConfigTab1.checkBtn[12]:SetChecked(not DWP.ConfigTab1.checkBtn[12]:GetChecked())
		DWP.ConfigTab1.checkBtn[10]:SetChecked(false)
		menu[7].menuList[#core.classes+2].checked = false

		DWPFilterChecks(DWP.ConfigTab1.checkBtn[12])
		if UIDROPDOWNMENU_OPEN_MENU then
			ToggleDropDownMenu(nil, nil, menuFrame)
		end
	end }

	if #DWPlus_Standby == 0 then
		menu[6].menuList[2] = { text = L["VIEWSTANDBY"], notCheckable = true, disabled = true, }
		menu[6].menuList[3] = { text = L["VIEWRAIDSTANDBY"], notCheckable = true, disabled = true}
	end

	if not IsInGroup() and not IsInRaid() then
		menu[6].menuList[1] = { text = L["VIEWRAID"], notCheckable = true, disabled = true }
		menu[6].menuList[3] = { text = L["VIEWRAIDSTANDBY"], notCheckable = true, disabled = true}
	end

	local rankList = GetGuildRankList()
	for i=1, #rankList do
		local checked;

		if DWP:Table_Search(DWPlus_DB.raiders, rankList[i].name) then
			checked = true;
		else
			checked = false;
		end

		menu[11].menuList[i] = { text = rankList[i].name, isNotRadio = true, keepShownOnClick = true, checked = checked, func = function()
			if menu[11].menuList[i].checked then
				menu[11].menuList[i].checked = false;

				local rank_search = DWP:Table_Search(DWPlus_DB.raiders, rankList[i].name)

				if rank_search then
					table.remove(DWPlus_DB.raiders, rank_search[1])
				end
			else
				menu[11].menuList[i].checked = true;
				table.insert(DWPlus_DB.raiders, rankList[i].name)
			end
		end }
	end

	menu[11].menuList[#menu[11].menuList + 1] = { text = " ", notCheckable = true, disabled = true }

	menu[11].menuList[#menu[11].menuList + 1] = { text = L["CLOSE"], notCheckable = true, func = function()
		ToggleDropDownMenu(nil, nil, menuFrame)
	end }


	local guildSize = GetNumGuildMembers();
	local name, rankIndex;
	local tempTable = {}

	for i=1, guildSize do
		name,_,rankIndex = GetGuildRosterInfo(i)
		name = strsub(name, 1, string.find(name, "-")-1)      -- required to remove server name from player (can remove in classic if this is not an issue)
		local search = DWP:Table_Search(DWPlus_RPTable, name)

		if search then
			local rankList = GetGuildRankList()

			local match_rank = DWP:Table_Search(DWPlus_DB.raiders, rankList[rankIndex+1].name)

			if match_rank then
				table.insert(tempTable, DWPlus_RPTable[search[1][1]])
			end
		end
	end
	if #tempTable == 0 then
		menu[6].menuList[4].disabled = true;
	else
		menu[6].menuList[4].disabled = false;
	end
	table.wipe(tempTable);

	if core.IsOfficer == false then
		for i=8, #menu-2 do
			menu[i].disabled = true
		end

		--table.remove(menu[6].menuList, 4)
	end

	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 1);
end

local function CreateRow(parent, id) -- Create 3 buttons for each row in the list
		local f = CreateFrame("Button", "$parentLine"..id, parent)
		f.DKPInfo = {}
		f:SetSize(core.TableWidth, core.TableRowHeight)
		f:SetHighlightTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");
		f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
		f:GetNormalTexture():SetAlpha(0.2)
		f:SetScript("OnClick", DKPTable_OnClick)
		for i=1, 3 do
			f.DKPInfo[i] = f:CreateFontString(nil, "OVERLAY");
			f.DKPInfo[i]:SetFontObject("DWPSmallOutlineLeft")
			f.DKPInfo[i]:SetTextColor(1, 1, 1, 1);
			if (i==1) then
				f.DKPInfo[i].rowCounter = f:CreateFontString(nil, "OVERLAY");
				f.DKPInfo[i].rowCounter:SetFontObject("DWPSmallOutlineLeft")
				f.DKPInfo[i].rowCounter:SetTextColor(1, 1, 1, 0.3);
				f.DKPInfo[i].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);
			end
			if (i==3) then
				f.DKPInfo[i]:SetFontObject("DWPSmallLeft")
				f.DKPInfo[i].adjusted = f:CreateFontString(nil, "OVERLAY");
				f.DKPInfo[i].adjusted:SetFontObject("DWPSmallOutlineLeft")
				f.DKPInfo[i].adjusted:SetScale("0.8")
				f.DKPInfo[i].adjusted:SetTextColor(1, 1, 1, 0.6);
				f.DKPInfo[i].adjusted:SetPoint("LEFT", f.DKPInfo[3], "RIGHT", 3, -1);

				if DWPlus_DB.modes.mode == "Roll Based Bidding" then
					f.DKPInfo[i].rollrange = f:CreateFontString(nil, "OVERLAY");
					f.DKPInfo[i].rollrange:SetFontObject("DWPSmallOutlineLeft")
					f.DKPInfo[i].rollrange:SetScale("0.8")
					f.DKPInfo[i].rollrange:SetTextColor(1, 1, 1, 0.6);
					f.DKPInfo[i].rollrange:SetPoint("CENTER", 115, -1);
				end

				f.DKPInfo[i].adjustedArrow = f:CreateTexture(nil, "OVERLAY", nil, -8);
				f.DKPInfo[i].adjustedArrow:SetPoint("RIGHT", f, "RIGHT", -10, 0);
				f.DKPInfo[i].adjustedArrow:SetColorTexture(0, 0, 0, 0.5)
				f.DKPInfo[i].adjustedArrow:SetSize(8, 12);
			end
		end
		f.DKPInfo[1]:SetPoint("LEFT", 30, 0)
		f.DKPInfo[2]:SetPoint("CENTER")
		f.DKPInfo[3]:SetPoint("RIGHT", -80, 0)


		f:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				RightClickMenu(self)
			end
		end)

		return f
end

function DKPTable_Update()
	if not DWP.UIConfig:IsShown() then     -- does not update list if DKP window is closed. Gets done when /dwp is used anyway.
		return;
	end

	if core.CurView == "limited" then  -- recreates WorkingTable if in limited view (view raid, core raiders etc)
		local tempTable = {}

		for i=1, #core.WorkingTable do
			local search = DWP:Table_Search(DWPlus_RPTable, core.WorkingTable[i].player)

			if search then
				table.insert(tempTable, DWPlus_RPTable[search[1][1]])
			end
		end
		core.WorkingTable = CopyTable(tempTable)
		table.wipe(tempTable)
	end

	local numOptions = #core.WorkingTable
	local index, row, c
	local offset = FauxScrollFrame_GetOffset(DWP.DKPTable) or 0
	local rank, rankIndex;

	for i=1, core.TableNumRows do     -- hide all rows before displaying them 1 by 1 as they show values
		row = DWP.DKPTable.Rows[i];
		row:Hide();
	end
	--[[for i=1, #DWPlus_RPTable do
		if DWPlus_RPTable[i].dkp < 0 then DWPlus_RPTable[i].dkp = 0 end  -- cleans negative numbers from SavedVariables
	end--]]
	for i=1, core.TableNumRows do     -- show rows if they have values
		row = DWP.DKPTable.Rows[i]
		index = offset + i
		if core.WorkingTable[index] then
			--if (tonumber(core.WorkingTable[index].dkp) < 0) then core.WorkingTable[index].dkp = 0 end           -- shows 0 if negative DKP

			c = DWP:GetCColors(core.WorkingTable[index].class);
			row:Show()
			row.index = index
			local CurPlayer = core.WorkingTable[index].player;
			
			if core.CenterSort == "rank" then
				local SetRank = DWP:Table_Search(DWPlus_RPTable, core.WorkingTable[index].player, "player")
				rank, rankIndex = DWP:GetGuildRank(core.WorkingTable[index].player)
				DWPlus_RPTable[SetRank[1][1]].rank = rankIndex or 20;
				DWPlus_RPTable[SetRank[1][1]].rankName = rank or "None";
			end
			row.DKPInfo[1]:SetText(core.WorkingTable[index].player)
			row.DKPInfo[1].rowCounter:SetText(index)
			row.DKPInfo[1]:SetTextColor(c.r, c.g, c.b, 1)
			
			if core.CenterSort == "class" then
				row.DKPInfo[2]:SetText(core.LocalClass[core.WorkingTable[index].class])
			elseif core.CenterSort == "rank" then
				row.DKPInfo[2]:SetText(rank)
			elseif core.CenterSort == "spec" then
				if core.WorkingTable[index].spec then
					row.DKPInfo[2]:SetText(core.WorkingTable[index].spec)
				else
					row.DKPInfo[2]:SetText(L["NOSPECREPORTED"])
					local SetSpec = DWP:Table_Search(DWPlus_RPTable, core.WorkingTable[index].player, "player")		-- writes "No Spec Reported" to players profile if spec field doesn't exist
					DWPlus_RPTable[SetSpec[1][1]].spec = L["NOSPECREPORTED"]
				end
			elseif core.CenterSort == "role" then
				if core.WorkingTable[index].role then
					row.DKPInfo[2]:SetText(core.WorkingTable[index].role)
				else
					row.DKPInfo[2]:SetText(L["NOROLEDETECTED"])
					local SetRole = DWP:Table_Search(DWPlus_RPTable, core.WorkingTable[index].player, "player")		-- writes "No Role Detected" to players profile if role field doesn't exist
					DWPlus_RPTable[SetRole[1][1]].role = L["NOROLEDETECTED"]
				end
			end
			
			row.DKPInfo[3]:SetText(DWP_round(core.WorkingTable[index].dkp, DWPlus_DB.modes.rounding))
			local CheckAdjusted = core.WorkingTable[index].dkp - core.WorkingTable[index].previous_dkp;
			if(CheckAdjusted > 0) then 
				CheckAdjusted = strjoin("", "+", CheckAdjusted) 
				row.DKPInfo[3].adjustedArrow:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\green-up-arrow.png");
			elseif (CheckAdjusted < 0) then
				row.DKPInfo[3].adjustedArrow:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\red-down-arrow.png");
			else
				row.DKPInfo[3].adjustedArrow:SetTexture(nil);
			end        
			row.DKPInfo[3].adjusted:SetText("("..DWP_round(CheckAdjusted, DWPlus_DB.modes.rounding)..")");

			if DWPlus_DB.modes.mode == "Roll Based Bidding" then
				local minimum;
				local maximum;

				if DWPlus_DB.modes.rolls.UsePerc then
					if DWPlus_DB.modes.rolls.min == 0 or DWPlus_DB.modes.rolls.min == 1 then
							minimum = 1;
					else
						minimum = core.WorkingTable[index].dkp * (DWPlus_DB.modes.rolls.min / 100);
					end
					maximum = core.WorkingTable[index].dkp * (DWPlus_DB.modes.rolls.max / 100) + DWPlus_DB.modes.rolls.AddToMax;
				elseif not DWPlus_DB.modes.rolls.UsePerc then
					minimum = DWPlus_DB.modes.rolls.min;

					if DWPlus_DB.modes.rolls.max == 0 then
						maximum = core.WorkingTable[index].dkp + DWPlus_DB.modes.rolls.AddToMax;
					else
						maximum = DWPlus_DB.modes.rolls.max + DWPlus_DB.modes.rolls.AddToMax;
					end
				end
				if maximum < 1 then maximum = 1 end
				if minimum < 1 then minimum = 1 end        

				if minimum > maximum then
					row.DKPInfo[3].rollrange:SetText("(0-0)")
				else
					row.DKPInfo[3].rollrange:SetText("("..math.floor(minimum).."-"..math.floor(maximum)..")")
				end
			elseif row.DKPInfo[3].rollrange then
				row.DKPInfo[3].rollrange:SetText("")
			end

			local a = DWP:Table_Search(core.SelectedData, core.WorkingTable[index].player);  -- searches selectedData for the player name indexed.
			if not a then
				DWP.DKPTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
				DWP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
			else
				DWP.DKPTable.Rows[i]:SetNormalTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight")
				DWP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.7)
			end
			if core.WorkingTable[index].player == UnitName("player") then
				row.DKPInfo[2]:SetText("|cff00ff00"..row.DKPInfo[2]:GetText().."|r")
				row.DKPInfo[3]:SetText("|cff00ff00"..DWP_round(core.WorkingTable[index].dkp, DWPlus_DB.modes.rounding).."|r")
				DWP.DKPTable.Rows[i]:GetNormalTexture():SetAlpha(0.8)
			end
			DWP.DKPTable.Rows[i]:SetScript("OnEnter", function(self)
				DisplayUserHistory(self, CurPlayer)
			end)
			DWP.DKPTable.Rows[i]:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		else
			row:Hide()
		end
	end

	if #core.WorkingTable == 0 then  		-- Displays "No Entries Returned" if the result of filter combinations yields an empty table
		--DWP_RestoreFilterOptions()
		DWP.DKPTable.Rows[1].DKPInfo[1].rowCounter:SetText("")
		DWP.DKPTable.Rows[1].DKPInfo[1]:SetText("")
		DWP.DKPTable.Rows[1].DKPInfo[2]:SetText("|cffff6060"..L["NOENTRIESRETURNED"].."|r")
		DWP.DKPTable.Rows[1].DKPInfo[3]:SetText("")
		DWP.DKPTable.Rows[1].DKPInfo[3].adjusted:SetText("")
		DWP.DKPTable.Rows[1].DKPInfo[3].adjustedArrow:SetTexture(nil)
		if DWP.DKPTable.Rows[1].DKPInfo[3].rollrange then DWP.DKPTable.Rows[1].DKPInfo[3].rollrange:SetText("") end
		DWP.DKPTable.Rows[1]:SetScript("OnEnter", nil)
		DWP.DKPTable.Rows[1]:SetScript("OnMouseDown", function()
			DWP_RestoreFilterOptions() 		-- restores filter selections to default on click.
		end)
		DWP.DKPTable.Rows[1]:SetScript("OnClick", function()
			DWP_RestoreFilterOptions() 		-- restores filter selections to default on click.
		end)
		DWP.DKPTable.Rows[1]:Show()
	else
		DWP.DKPTable.Rows[1]:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				RightClickMenu(self)
			end
		end)
		DWP.DKPTable.Rows[1]:SetScript("OnClick", DKPTable_OnClick)
	end

	DWP.DKPTable.counter.t:SetText(#core.WorkingTable.." "..L["ENTRIESSHOWN"]);    -- updates "Entries Shown" at bottom of DKPTable
	DWP.DKPTable.counter.t:SetFontObject("DWPSmallLeft")

	FauxScrollFrame_Update(DWP.DKPTable, numOptions, core.TableNumRows, core.TableRowHeight, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function DWP:DKPTable_Create()
	DWP.DKPTable = CreateFrame("ScrollFrame", "DWPDisplayScrollFrame", DWP.UIConfig, "FauxScrollFrameTemplate")
	DWP.DKPTable:SetSize(core.TableWidth, core.TableRowHeight*core.TableNumRows+3)
	DWP.DKPTable:SetPoint("LEFT", 20, 3)
	DWP.DKPTable:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	DWP.DKPTable:SetBackdropColor(0,0,0,0.4);
	DWP.DKPTable:SetBackdropBorderColor(1,1,1,0.5)
	DWP.DKPTable:SetClipsChildren(false);

	DWP.DKPTable.ScrollBar = FauxScrollFrame_GetChildFrames(DWP.DKPTable)
	DWP.DKPTable.Rows = {}
	for i=1, core.TableNumRows do
		DWP.DKPTable.Rows[i] = CreateRow(DWP.DKPTable, i)
		if i==1 then
			DWP.DKPTable.Rows[i]:SetPoint("TOPLEFT", DWP.DKPTable, "TOPLEFT", 0, -2)
		else  
			DWP.DKPTable.Rows[i]:SetPoint("TOPLEFT", DWP.DKPTable.Rows[i-1], "BOTTOMLEFT")
		end
	end
	DWP.DKPTable:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, core.TableRowHeight, DKPTable_Update)
	end)
	
	DWP.DKPTable.SeedVerify = CreateFrame("Frame", nil, DWP.DKPTable);
	DWP.DKPTable.SeedVerify:SetPoint("TOPLEFT", DWP.DKPTable, "BOTTOMLEFT", 0, -15);
	DWP.DKPTable.SeedVerify:SetSize(18, 18);
	DWP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.DKPTable.SeedVerify:SetScript("OnMouseDown", function()  -- broadcast button
		if core.IsOfficer then	
			local seed
			if #DWPlus_RPHistory > 0 and #DWPlus_Loot > 0 then seed = DWPlus_RPHistory[1].index..","..DWPlus_Loot[1].index else seed = "start" end
			DWP.Sync:SendData("DWPQuery", seed) 	-- requests role and spec data and sets current seeds
			DWP_BroadcastFull_Init()
		end
	end)

	DWP.DKPTable.SeedVerifyIcon = DWP.DKPTable:CreateTexture(nil, "OVERLAY", nil)             -- seed verify (bottom left) indicator
	DWP.DKPTable.SeedVerifyIcon:SetPoint("TOPLEFT", DWP.DKPTable.SeedVerify, "TOPLEFT", 0, 0);
	DWP.DKPTable.SeedVerifyIcon:SetColorTexture(0, 0, 0, 1)
	DWP.DKPTable.SeedVerifyIcon:SetSize(18, 18);
	DWP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\out-of-date")
end