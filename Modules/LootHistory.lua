local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local menu = {}
local curfilterName = L["NOFILTER"];

local menuFrame = CreateFrame("Frame", "DWPDeleteLootMenuFrame", UIParent, "UIDropDownMenuTemplate")

function DWP:SortLootTable()             -- sorts the Loot History Table by date
  table.sort(DWPlus_Loot, function(a, b)
    return a["date"] > b["date"]
  end)
end

local function SortPlayerTable(arg)             -- sorts player list alphabetically
  table.sort(arg, function(a, b)
    return a < b
  end)
end

local function GetSortOptions()
	local PlayerList = {}
	for i=1, #DWPlus_Loot do
		local playerSearch = DWP:Table_Search(PlayerList, DWPlus_Loot[i].player)
		if not playerSearch and not DWPlus_Loot[i].de then
			tinsert(PlayerList, DWPlus_Loot[i].player)
		end
	end
	SortPlayerTable(PlayerList)
	return PlayerList;
end

local function DeleteLootHistoryEntry(index)
	local search = DWP:Table_Search(DWPlus_Loot, index, "index");
	local search_player = DWP:Table_Search(DWPlus_RPTable, DWPlus_Loot[search[1][1]].player);
	local curTime = time()
	local curOfficer = UnitName("player")
	local newIndex = curOfficer.."-"..curTime

	
	DWP:StatusVerify_Update()
	DWP:LootHistory_Reset()

	local tempTable = {
		player = DWPlus_Loot[search[1][1]].player,
		loot =  DWPlus_Loot[search[1][1]].loot,
		zone = DWPlus_Loot[search[1][1]].zone,
		date = time(),
		boss = DWPlus_Loot[search[1][1]].boss,
		cost = -DWPlus_Loot[search[1][1]].cost,
		index = newIndex,
		deletes = DWPlus_Loot[search[1][1]].index
	}

	if search_player then
		DWPlus_RPTable[search_player[1][1]].dkp = DWPlus_RPTable[search_player[1][1]].dkp + tempTable.cost 							-- refund previous looter
		DWPlus_RPTable[search_player[1][1]].lifetime_spent = DWPlus_RPTable[search_player[1][1]].lifetime_spent + tempTable.cost 		-- remove from lifetime_spent
	end

	DWPlus_Loot[search[1][1]].deletedby = newIndex

	table.insert(DWPlus_Loot, 1, tempTable)
	DWP.Sync:SendData("DWPDelLoot", tempTable)
	DWP:SortLootTable()
	DKPTable_Update()
	DWP:LootHistory_Update(L["NOFILTER"]);
end

local function DWPDeleteMenu(index)
	local search = DWP:Table_Search(DWPlus_Loot, index, "index")
	local search2 = DWP:Table_Search(DWPlus_RPTable, DWPlus_Loot[search[1][1]]["player"])
	local c, deleteString;
	if search2 then
		c = DWP:GetCColors(DWPlus_RPTable[search2[1][1]].class)
		deleteString = L["CONFIRMDELETEENTRY1"]..": |cff"..c.hex..DWPlus_Loot[search[1][1]]["player"].."|r "..L["WON"].." "..DWPlus_Loot[search[1][1]]["loot"].." "..L["FOR"].." "..-DWPlus_Loot[search[1][1]]["cost"].." "..L["DKP"].."?\n\n("..L["THISWILLREFUND"].." |cff"..c.hex..DWPlus_Loot[search[1][1]].player.."|r "..-DWPlus_Loot[search[1][1]]["cost"].." "..L["DKP"]..")";
	else
		deleteString = L["CONFIRMDELETEENTRY1"]..": |cff444444"..DWPlus_Loot[search[1][1]]["player"].."|r "..L["WON"].." "..DWPlus_Loot[search[1][1]]["loot"].." "..L["FOR"].." "..-DWPlus_Loot[search[1][1]]["cost"].." "..L["DKP"].."?\n\n("..L["THISWILLREFUND"].." |cff444444"..DWPlus_Loot[search[1][1]].player.."|r "..-onDKP_Loot[search[1][1]]["cost"].." "..L["DKP"]..")";
	end

	StaticPopupDialogs["DELETE_LOOT_ENTRY"] = {
	  text = deleteString,
	  button1 = L["YES"],
	  button2 = L["NO"],
	  OnAccept = function()
	    DeleteLootHistoryEntry(index)
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,
	}
	StaticPopup_Show ("DELETE_LOOT_ENTRY")
end

local function RightClickLootMenu(self, index)  -- called by right click function on ~201 row:SetScript
	local search = DWP:Table_Search(DWPlus_Loot, index, "index")
	menu = {
		{ text = DWPlus_Loot[search[1][1]]["loot"].." "..L["FOR"].." "..DWPlus_Loot[search[1][1]]["cost"].." "..L["DKP"], isTitle = true},
		{ text = "Delete Entry", func = function()
			DWPDeleteMenu(index)
		end },
		{ text = L["REASSIGNSELECTED"], func = function()
			local path = DWPlus_Loot[search[1][1]]

			if #core.SelectedData == 1 then
				DWP:AwardConfirm(core.SelectedData[1].player, -path.cost, path.boss, path.zone, path.loot, index)
			elseif #core.SelectedData > 1 then
				StaticPopupDialogs["TOO_MANY_SELECTED_LOOT"] = {
				text = L["TOOMANYPLAYERSSELECT"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("TOO_MANY_SELECTED_LOOT")
			else
				DWP:AwardConfirm(path.player, -path.cost, path.boss, path.zone, path.loot, index)
			end
		end }
	}
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU");
	end

function CreateSortBox()
	local PlayerList = GetSortOptions();
	local curSelected = 0;

	-- Create the dropdown, and configure its appearance
	if not sortDropdown then
		sortDropdown = CreateFrame("FRAME", "DWPConfigFilterNameDropDown", DWP.ConfigTab5, "DWPlusUIDropDownMenuTemplate")
	end

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(sortDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}

		while ranges[#ranges] < #PlayerList do
			table.insert(ranges, ranges[#ranges]+20)
		end

		if (level or 1) == 1 then
			local numSubs = ceil(#PlayerList/20)
			filterName.func = self.FilterSetValue
			filterName.text, filterName.arg1, filterName.checked, filterName.isNotRadio = L["NOFILTER"], L["NOFILTER"], L["NOFILTER"] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
		
			for i=1, numSubs do
				local max = i*20;
				if max > #PlayerList then max = #PlayerList end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = strsub(PlayerList[((i*20)-19)], 1, 1).."-"..strsub(PlayerList[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				UIDropDownMenu_AddButton(filterName)
			end
		else
			filterName.func = self.FilterSetValue
			for i=ranges[menuList], ranges[menuList]+19 do
				if PlayerList[i] then
					local classSearch = DWP:Table_Search(DWPlus_RPTable, PlayerList[i])
				    local c;

				    if classSearch then
				     	c = DWP:GetCColors(DWPlus_RPTable[classSearch[1][1]].class)
				    else
				     	c = { hex="444444" }
				    end
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i], "|cff"..c.hex..PlayerList[i].."|r", PlayerList[i] == curfilterName, true
					UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)

	sortDropdown:SetPoint("TOPRIGHT", DWP.ConfigTab5, "TOPRIGHT", -13, -11)

	UIDropDownMenu_SetWidth(sortDropdown, 150)
	UIDropDownMenu_SetText(sortDropdown, curfilterName or "Filter Name")

  -- Dropdown Menu Function
  function sortDropdown:FilterSetValue(newValue, arg2)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    UIDropDownMenu_SetText(sortDropdown, arg2)
    DWP:LootHistory_Update(newValue)
    CloseDropDownMenus()
  end
end


local tooltip = CreateFrame('GameTooltip', "nil", UIParent, 'GameTooltipTemplate')
local CurrentPosition = 0
local CurrentLimit = 25;
local lineHeight = -65;
local ButtonText = 25;
local curDate = 1;
local curZone;
local curBoss;

function DWP:LootHistory_Reset()
	CurrentPosition = 0
	CurrentLimit = 25;
	lineHeight = -65;
	ButtonText = 25;
	curDate = 1;
	curZone = nil;
	curBoss = nil;

	if DWP.DKPTable then
		for i=1, #DWPlus_Loot+1 do
			if DWP.ConfigTab5.looter[i] then
				DWP.ConfigTab5.looter[i]:SetText("")
				DWP.ConfigTab5.lootFrame[i]:Hide()
			end
		end
	end
end

local LootHistTimer = LootHistTimer or CreateFrame("StatusBar", nil, UIParent)
function DWP:LootHistory_Update(filter)				-- if "filter" is included in call, runs set assigned for when a filter is selected in dropdown.
	if not DWP.UIConfig:IsShown() then return end

	local thedate;
	local linesToUse = 1;
	local LootTable = {}
	DWP:SortLootTable()
	if LootHistTimer then LootHistTimer:SetScript("OnUpdate", nil) end

	if filter and filter == L["NOFILTER"] then
		curfilterName = L["NOFILTER"]
		CreateSortBox()
	end
	
	if filter then
		DWP:LootHistory_Reset()
	end

	if filter and filter ~= L["NOFILTER"] and filter ~= L["DELETEDENTRY"] then
		for i=1, #DWPlus_Loot do
			if not DWPlus_Loot[i].deletes and not DWPlus_Loot[i].deletedby and not DWPlus_Loot[i].hidden and DWPlus_Loot[i].player == filter then
				table.insert(LootTable, DWPlus_Loot[i])
			end
		end
	elseif filter and filter == L["DELETEDENTRY"] then
		for i=1, #DWPlus_Loot do
			if DWPlus_Loot[i].deletes then
				table.insert(LootTable, DWPlus_Loot[i])
			end
		end
	else
		for i=1, #DWPlus_Loot do
			if not DWPlus_Loot[i].deletes and not DWPlus_Loot[i].deletedby and not DWPlus_Loot[i].hidden then
				table.insert(LootTable, DWPlus_Loot[i])
			end
		end
	end

	DWP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);
	if core.IsOfficer == true then
		DWP.ConfigTab5.inst:SetText(DWP.ConfigTab5.inst:GetText().."\n"..L["LOOTHISTINST2"])
		DWP.ConfigTab6.inst:SetText(L["LOOTHISTINST3"])
	end

	if CurrentLimit > #LootTable then CurrentLimit = #LootTable end;

	if filter and filter ~= L["NOFILTER"] then
		CurrentLimit = #LootTable
	end

	local j=CurrentPosition+1
	local LootTimer = 0
	local processing = false
	LootHistTimer:SetScript("OnUpdate", function(self, elapsed)
		LootTimer = LootTimer + elapsed
		if LootTimer > 0.001 and j <= CurrentLimit and not processing then
			local i = j
			processing = true
		  	local itemToLink = LootTable[i]["loot"]
			local del_search = DWP:Table_Search(DWPlus_Loot, LootTable[i].deletes, "index")

		  	if filter == L["DELETEDENTRY"] then
		  		thedate = DWP:FormatTime(DWPlus_Loot[del_search[1][1]].date)
		  	else
				thedate = DWP:FormatTime(LootTable[i]["date"])
			end

		    if strtrim(strsub(thedate, 1, 8), " ") ~= curDate then
		      linesToUse = 4
		    elseif strtrim(strsub(thedate, 1, 8), " ") == curDate and ((LootTable[i]["boss"] ~= curBoss and LootTable[i]["zone"] ~= curZone) or (LootTable[i]["boss"] == curBoss and LootTable[i]["zone"] ~= curZone)) then
		      linesToUse = 3
		    elseif LootTable[i]["zone"] ~= curZone or LootTable[i]["boss"] ~= curBoss then
		      linesToUse = 2
		    else
		      linesToUse = 1
		    end

		    if (type(DWP.ConfigTab5.lootFrame[i]) ~= "table") then
		    	DWP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "DWPLootHistoryFrame"..i, DWP.ConfigTab5);	-- creates line if it doesn't exist yet
		    end
		    -- determine line height 
	    	if linesToUse == 1 then
				DWP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 10, lineHeight-2);
				DWP.ConfigTab5.lootFrame[i]:SetSize(200, 14)
				lineHeight = lineHeight-14;
			elseif linesToUse == 2 then
				lineHeight = lineHeight-14;
				DWP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 10, lineHeight);
				DWP.ConfigTab5.lootFrame[i]:SetSize(200, 28)
				lineHeight = lineHeight-24;
			elseif linesToUse == 3 then
				lineHeight = lineHeight-14;
				DWP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 10, lineHeight);
				DWP.ConfigTab5.lootFrame[i]:SetSize(200, 38)
				lineHeight = lineHeight-36;
			elseif linesToUse == 4 then
				lineHeight = lineHeight-14;
				DWP.ConfigTab5.lootFrame[i]:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 10, lineHeight);
				DWP.ConfigTab5.lootFrame[i]:SetSize(200, 50)
				lineHeight = lineHeight-48;
			end;

			DWP.ConfigTab5.looter[i] = DWP.ConfigTab5.lootFrame[i]:CreateFontString(nil, "OVERLAY")
			DWP.ConfigTab5.looter[i]:SetFontObject("DWPSmallLeft");
			DWP.ConfigTab5.looter[i]:SetPoint("TOPLEFT", DWP.ConfigTab5.lootFrame[i], "TOPLEFT", 0, 0);

			local date1, date2, date3 = strsplit("/", strtrim(strsub(thedate, 1, 8), " "))    -- date is stored as yy/mm/dd for sorting purposes. rearranges numbers for printing to string

		    local feedString;

		    local classSearch = DWP:Table_Search(DWPlus_RPTable, LootTable[i]["player"])
		    local c, lootCost;

		    if classSearch then
		     	c = DWP:GetCColors(DWPlus_RPTable[classSearch[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end

		    if tonumber(LootTable[i].cost) < 0 then lootCost = tonumber(LootTable[i].cost) * -1 else lootCost = tonumber(LootTable[i].cost) end

		    if strtrim(strsub(thedate, 1, 8), " ") ~= curDate or LootTable[i]["zone"] ~= curZone then
		    	if strtrim(strsub(thedate, 1, 8), " ") ~= curDate then
					feedString = date2.."/"..date3.."/"..date1.."\n  |cff616ccf"..LootTable[i]["zone"].."|r\n   |cffff0000"..LootTable[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
					feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
				else
					feedString = "  |cff616ccf"..LootTable[i]["zone"].."|r\n   |cffff0000"..LootTable[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
					feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
				end
				        
				DWP.ConfigTab5.looter[i]:SetText(feedString);
				curDate = strtrim(strsub(thedate, 1, 8), " ")
				curZone = LootTable[i]["zone"];
				curBoss = LootTable[i]["boss"];
		    elseif LootTable[i]["boss"] ~= curBoss then
		    	feedString = "   |cffff0000"..LootTable[i]["boss"].."|r |cff555555("..strtrim(strsub(thedate, 10), " ")..")|r".."\n"
		    	feedString = feedString.."    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
		    	 
		    	DWP.ConfigTab5.looter[i]:SetText(feedString);
		    	curDate = strtrim(strsub(thedate, 1, 8), " ")
		    	curBoss = LootTable[i]["boss"]
		    else
		    	feedString = "    "..itemToLink.." "..L["WONBY"].." |cff"..c.hex..LootTable[i]["player"].."|r |cff555555("..lootCost.." "..L["DKP"]..")|r"
		    	
		    	DWP.ConfigTab5.looter[i]:SetText(feedString);
		    	curZone = LootTable[i]["zone"];
		    end

		    if LootTable[i].reassigned then
		    	DWP.ConfigTab5.looter[i]:SetText(DWP.ConfigTab5.looter[i]:GetText(feedString).." |cff555555("..L["REASSIGNED"]..")|r")
		    end
		    -- Set script for tooltip/linking
		    DWP.ConfigTab5.lootFrame[i]:SetScript("OnEnter", function(self)
		    	local history = 0;
		    	tooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
		    	tooltip:SetHyperlink(itemToLink)
		    	tooltip:AddLine(" ")

		    	local awardOfficer

		    	if filter == L["DELETEDENTRY"] then
		    		awardOfficer = strsplit("-", LootTable[i].deletes)
		    	else
		    		awardOfficer = strsplit("-", LootTable[i].index)
		    	end

		    	local awarded_by_search = DWP:Table_Search(DWPlus_RPTable, awardOfficer, "player")
		    	if awarded_by_search then
			     	c = DWP:GetCColors(DWPlus_RPTable[awarded_by_search[1][1]].class)
			    else
			     	c = { hex="444444" }
			    end

		    	if LootTable[i].bids or LootTable[i].dkp or LootTable[i].rolls then  		-- displays bids/rolls/dkp values if "Log Bids" checked in modes
		    		local path;

		    		tooltip:AddLine(" ")
		    		if LootTable[i].bids then
		    			tooltip:AddLine(L["BIDS"]..":", 0.25, 0.75, 0.90)
		    			table.sort(LootTable[i].bids, function(a, b)
							return a["bid"] > b["bid"]
						end)
						path = LootTable[i].bids
		    		elseif LootTable[i].dkp then
		    			tooltip:AddLine(L["DKPVALUES"]..":", 0.25, 0.75, 0.90)
		    			table.sort(LootTable[i].dkp, function(a, b)
							return a["dkp"] > b["dkp"]
						end)
						path = LootTable[i].dkp
		    		elseif LootTable[i].rolls then
		    			tooltip:AddLine(L["ROLLS"]..":", 0.25, 0.75, 0.90)
		    			table.sort(LootTable[i].rolls, function(a, b)
							return a["roll"] > b["roll"]
						end)
						path = LootTable[i].rolls
		    		end
		    		for j=1, #path do
		    			local col;
		    			local bidder = path[j].bidder
		    			local s = DWP:Table_Search(DWPlus_RPTable, bidder)
		    			local path2 = path[j].bid or path[j].dkp or path[j].roll

		    			if s then
		    				col = DWP:GetCColors(DWPlus_RPTable[s[1][1]].class)
		    			else
		    				col = { hex="444444" }
		    			end
		    			if bidder == LootTable[i].player then
		    				tooltip:AddLine("|cff"..col.hex..bidder.."|r: |cff00ff00"..path2.."|r")
		    			else
		    				tooltip:AddLine("|cff"..col.hex..bidder.."|r: |cffff0000"..path2.."|r")
		    			end
		    		end
		    	end
		    	for j=1, #DWPlus_Loot do
		    		if DWPlus_Loot[j]["loot"] == itemToLink and LootTable[i].date ~= DWPlus_Loot[j].date and not DWPlus_Loot[j].deletedby and not DWPlus_Loot[j].deletes then
		    			local col;
		    			local s = DWP:Table_Search(DWPlus_RPTable, DWPlus_Loot[j].player)
		    			if s then
		    				col = DWP:GetCColors(DWPlus_RPTable[s[1][1]].class)
		    			else
		    				col = { hex="444444" }
		    			end
		    			if history == 0 then
		    				tooltip:AddLine(" ");
		    				tooltip:AddLine(L["ALSOWONBY"]..":", 0.25, 0.75, 0.90, 1, true);
		    				history = 1;
		    			end
		    			tooltip:AddDoubleLine("|cff"..col.hex..DWPlus_Loot[j].player.."|r |cffffffff("..date("%m/%d/%y", DWPlus_Loot[j].date)..")|r", "|cffff0000"..-DWPlus_Loot[j].cost.." "..L["DKP"].."|r", 1.0, 0, 0)
		    		end
		    	end
			    if filter == L["DELETEDENTRY"] then
			    	local delOfficer,_ = strsplit("-", DWPlus_Loot[del_search[1][1]].deletedby)
			    	local col
			    	local del_date = DWP:FormatTime(LootTable[i].date)
				    local del_date1, del_date2, del_date3 = strsplit("/", strtrim(strsub(del_date, 1, 8), " "))
			    	local s = DWP:Table_Search(DWPlus_RPTable, delOfficer, "player")
			    	if s then
			    		col = DWP:GetCColors(DWPlus_RPTable[s[1][1]].class)
			    	else
			    		col = { hex="444444"}
			    	end
			    	tooltip:AddLine(" ")
			    	tooltip:AddLine(L["DELETEDBY"], 0.25, 0.75, 0.90, 1, true)
			    	tooltip:AddDoubleLine("|cff"..col.hex..delOfficer.."|r", del_date2.."/"..del_date3.."/"..del_date1.." @ "..strtrim(strsub(del_date, 10), " "),1,0,0,1,1,1)
			    end
			    tooltip:AddLine(" ")
			    tooltip:AddDoubleLine(L["AWARDEDBY"], "|cff"..c.hex..awardOfficer.."|r", 0.25, 0.75, 0.90)
		    	tooltip:Show();
		    end)
		    DWP.ConfigTab5.lootFrame[i]:SetScript("OnMouseDown", function(self, button)
	   			if button == "RightButton" and filter ~= L["DELETEDENTRY"] then
	   				if core.IsOfficer == true then
	   					RightClickLootMenu(self, LootTable[i].index)
	   				end
	   			elseif button == "LeftButton" then
	   				if IsShiftKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..select(2,GetItemInfo(itemToLink)))
			    		ChatFrame1EditBox:SetFocus();
			    	elseif IsAltKeyDown() then
			    		ChatFrame1EditBox:Show();
			    		ChatFrame1EditBox:SetText(ChatFrame1EditBox:GetText()..LootTable[i]["player"].." "..L["WON"].." "..select(2,GetItemInfo(itemToLink)).." "..L["OFF"].." "..LootTable[i]["boss"].." "..L["IN"].." "..LootTable[i]["zone"].." ("..date2.."/"..date3.."/"..date1..") "..L["FOR"].." "..-LootTable[i]["cost"].." "..L["DKP"])
			    		ChatFrame1EditBox:SetFocus();
			    	end
	   			end		    	
		    end)
		    DWP.ConfigTab5.lootFrame[i]:SetScript("OnLeave", function()
		    	tooltip:Hide()
		    end)
			if DWP.ConfigTab5.LoadHistory then
				DWP.ConfigTab5.LoadHistory:SetPoint("TOP", DWP.ConfigTab5.lootFrame[i], "BOTTOM", 110, -15)
			end
		    CurrentPosition = CurrentPosition + 1;
		    DWP.ConfigTab5.lootFrame[i]:Show();
		    processing = false
		    j=i+1
		    LootTimer = 0
		elseif j > CurrentLimit then
			LootHistTimer:SetScript("OnUpdate", nil)
			LootTimer = 0
			if DWP.ConfigTab5.LoadHistory then
				DWP.ConfigTab5.LoadHistory:ClearAllPoints();
				DWP.ConfigTab5.LoadHistory:SetPoint("TOP", DWP.ConfigTab5.lootFrame[CurrentLimit], "BOTTOM", 110, -15)
				if (#LootTable - CurrentPosition) < 25 then
					ButtonText = #LootTable - CurrentPosition;
				end
				DWP.ConfigTab5.LoadHistory:SetText(string.format(L["LOAD50MORE"], ButtonText).."...")

				if CurrentLimit >= #LootTable then
					DWP.ConfigTab5.LoadHistory:Hide();
				end
			end
		end
 	end)
	if CurrentLimit < #LootTable and not DWP.ConfigTab5.LoadHistory then
	 	-- Load More History Button
		DWP.ConfigTab5.LoadHistory = self:CreateButton("TOP", DWP.ConfigTab5, "BOTTOM", 110, 0, string.format(L["LOAD50MORE"].."...", ButtonText));
		DWP.ConfigTab5.LoadHistory:SetSize(110,25)
		DWP.ConfigTab5.LoadHistory:SetScript("OnClick", function(self)
			CurrentLimit = CurrentLimit + 25
			if CurrentLimit > #LootTable then
				CurrentLimit = #LootTable
			end
			DWP:LootHistory_Update()
		end)
	end
end