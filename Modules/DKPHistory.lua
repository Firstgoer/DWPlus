local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local players;
local reason;
local dkp;
local formdate = date;
local date;
local year;
local month;
local day;
local timeofday;
local player_table = {};
local classSearch;
local playerString = "";
local filter;
local c;
local maxDisplayed = 10
local currentLength = 10;
local currentRow = 0;
local btnText = 10;
local curDate;
local history = {};
local menuFrame = CreateFrame("Frame", "DWPDeleteDKPMenuFrame", UIParent, "UIDropDownMenuTemplate")

function DWP:SortDKPHistoryTable()             -- sorts the DKP History Table by date/time
  table.sort(DWPlus_RPHistory, function(a, b)
    return a["date"] > b["date"]
  end)
end

local function GetSortOptions()
	local PlayerList = {}
	for i=1, #DWPlus_RPTable do
		local playerSearch = DWP:Table_Search(PlayerList, DWPlus_RPTable[i].player)
		if not playerSearch then
			tinsert(PlayerList, DWPlus_RPTable[i].player)
		end
	end
	table.sort(PlayerList, function(a, b)
		return a < b
	end)
	return PlayerList;
end

function DWP:DKPHistory_Reset()
	if not DWP.ConfigTab7 then return end
	currentRow = 0
	currentLength = maxDisplayed;
	curDate = nil;
	btnText = maxDisplayed;
	if DWP.ConfigTab7.loadMoreBtn then
		DWP.ConfigTab7.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
	end

	if DWP.ConfigTab7.history then
		for i=1, #DWP.ConfigTab7.history do
			if DWP.ConfigTab7.history[i] then
				DWP.ConfigTab7.history[i].h:SetText("")
				DWP.ConfigTab7.history[i].h:Hide()
				DWP.ConfigTab7.history[i].d:SetText("")
				DWP.ConfigTab7.history[i].d:Hide()
				DWP.ConfigTab7.history[i].s:SetText("")
				DWP.ConfigTab7.history[i].s:Hide()
				DWP.ConfigTab7.history[i]:SetHeight(10)
				DWP.ConfigTab7.history[i]:Hide()
			end
		end
	end
end

function DKPHistoryFilterBox_Create()
	local PlayerList = GetSortOptions();
	local curSelected = 0;

	-- Create the dropdown, and configure its appearance
	if not filterDropdown then
		filterDropdown = CreateFrame("FRAME", "DWPDKPHistoryFilterNameDropDown", DWP.ConfigTab7, "DWPlusUIDropDownMenuTemplate")
	end

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(filterDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}
		while ranges[#ranges] < #PlayerList do
			table.insert(ranges, ranges[#ranges]+20)
		end

		if (level or 1) == 1 then
			local numSubs = ceil(#PlayerList/20)
			filterName.func = self.FilterSetValue
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["NOFILTER"], L["NOFILTER"], L["NOFILTER"], L["NOFILTER"] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"] == curfilterName, true
			UIDropDownMenu_AddButton(filterName)
		
			for i=1, numSubs do
				local max = i*20;
				if max > #PlayerList then max = #PlayerList end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = string.utf8sub(PlayerList[((i*20)-19)], 1, 1).."-"..string.utf8sub(PlayerList[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
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

	filterDropdown:SetPoint("TOPRIGHT", DWP.ConfigTab7, "TOPRIGHT", -13, -11)

	UIDropDownMenu_SetWidth(filterDropdown, 150)
	UIDropDownMenu_SetText(filterDropdown, curfilterName or L["NOFILTER"])
	
  -- Dropdown Menu Function
  function filterDropdown:FilterSetValue(newValue, arg2)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    UIDropDownMenu_SetText(filterDropdown, arg2)
    
    if newValue == L["NOFILTER"] then
    	filter = nil;
    	maxDisplayed = 10; 				
    	curSelected = 0
    elseif newValue == L["DELETEDENTRY"] then
    	filter = newValue;
    	maxDisplayed = 10; 				
    	curSelected = 0
    else
	    filter = newValue;
	    maxDisplayed = 30;
	    local search = DWP:Table_Search(PlayerList, newValue)
	    curSelected = search[1]
    end

    DWP:DKPHistory_Update(true)
    CloseDropDownMenus()
  end
end

local function DWPDeleteDKPEntry(index, timestamp, item)  -- index = entry index , item = # of the entry on DKP History tab; may be different than the key of DKPHistory if hidden fields exist
	-- pop confirmation. If yes, cycles through DWPlus_RPHistory.players and every name it finds, it refunds them (or strips them of) dkp.
	-- if deleted is the weekly decay,     curdkp * (100 / (100 - decayvalue))
	local reason_header = DWP.ConfigTab7.history[item].d:GetText();
	if strfind(reason_header, L["OTHER"].."- ") then reason_header = reason_header:gsub(L["OTHER"].." -- ", "") end
	if strfind(reason_header, "%%") then
		reason_header = gsub(reason_header, "%%", "%%%%")
	end
	local confirm_string = L["CONFIRMDELETEENTRY1"]..":\n\n"..reason_header.."\n\n|CFFFF0000"..L["WARNING"].."|r: "..L["DELETEENTRYREFUNDCONF"];

	StaticPopupDialogs["CONFIRM_DELETE"] = {

		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()

		-- add new entry and add "delted_by" field to entry being "deleted". make new entry exact opposite of "deleted" entry
		-- new entry gets "deletes", old entry gets "deleted_by", deletes = deleted_by index. and vice versa
			local search = DWP:Table_Search(DWPlus_RPHistory, index, "index")

			if search then
				local players = {strsplit(",", string.utf8sub(DWPlus_RPHistory[search[1][1]].players, 1, -2))} 	-- cuts off last "," from string to avoid creating an empty value
				local dkp, mod;
				local dkpString = "";
				local curOfficer = UnitName("player")
				local curTime = time()
				local newIndex = curOfficer.."-"..curTime

				if strfind(DWPlus_RPHistory[search[1][1]].dkp, "%-%d*%.?%d+%%") then 		-- determines if it's a mass decay
					dkp = {strsplit(",", DWPlus_RPHistory[search[1][1]].dkp)}
					mod = "perc";
				else
					dkp = DWPlus_RPHistory[search[1][1]].dkp
					mod = "whole"
				end

				for i=1, #players do
					if mod == "perc" then
						local search = DWP:Table_Search(DWPlus_RPTable, players[i])

						if search then
							local inverted = tonumber(dkp[i]) * -1
							DWPlus_RPTable[search[1][1]].dkp = DWPlus_RPTable[search[1][1]].dkp + inverted
							dkpString = dkpString..inverted..",";

							if i == #players then
								dkpString = dkpString..dkp[#dkp]
							end
						end
					else
						local search = DWP:Table_Search(DWPlus_RPTable, players[i])

						if search then
							local inverted = tonumber(dkp) * -1

							DWPlus_RPTable[search[1][1]].dkp = DWPlus_RPTable[search[1][1]].dkp + inverted

							if tonumber(dkp) > 0 then
								DWPlus_RPTable[search[1][1]].lifetime_gained = DWPlus_RPTable[search[1][1]].lifetime_gained + inverted
							end
							
							dkpString = inverted;
						end
					end
				end
				
				DWPlus_RPHistory[search[1][1]].deletedby = newIndex
				table.insert(DWPlus_RPHistory, 1, { players=DWPlus_RPHistory[search[1][1]].players, dkp=dkpString, date=curTime, reason="Delete Entry", index=newIndex, deletes=index })
				DWP.Sync:SendData("DWPDelSync", DWPlus_RPHistory[1])

				if DWP.ConfigTab7.history and DWP.ConfigTab7:IsShown() then
					DWP:DKPHistory_Update(true)
				end

				DWP:StatusVerify_Update()
				DKPTable_Update()
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show ("CONFIRM_DELETE")
end

local function RightClickDKPMenu(self, index, timestamp, item)
	local header
	local search = DWP:Table_Search(DWPlus_RPHistory, index, "index")

	if search then
		menu = {
		{ text = DWP.ConfigTab7.history[item].d:GetText():gsub(L["OTHER"].." -- ", ""), isTitle = true},
		{ text = L["DELETEDKPENTRY"], func = function()
			DWPDeleteDKPEntry(index, timestamp, item)
		end },
		}
		EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 2);
	end
end

function DWP:DKPHistory_Update(reset)
	local DKPHistory = {}
	DWP:SortDKPHistoryTable()

	if not DWP.UIConfig:IsShown() then 			-- prevents history update from firing if the DKP window is not opened (eliminate lag). Update run when opened
		return;
	end

	if reset then
		DWP:DKPHistory_Reset()
	end

	if filter and filter ~= L["DELETEDENTRY"] then
		for i=1, #DWPlus_RPHistory do
			if not DWPlus_RPHistory[i].deletes and not DWPlus_RPHistory[i].deletedby and DWPlus_RPHistory[i].reason ~= "Migration Correction" and (strfind(DWPlus_RPHistory[i].players, ","..filter..",") or strfind(DWPlus_RPHistory[i].players, filter..",") == 1) then
				table.insert(DKPHistory, DWPlus_RPHistory[i])
			end
		end
	elseif filter and filter == L["DELETEDENTRY"] then
		for i=1, #DWPlus_RPHistory do
			if DWPlus_RPHistory[i].deletes then
				table.insert(DKPHistory, DWPlus_RPHistory[i])
			end
		end
	elseif not filter then
		for i=1, #DWPlus_RPHistory do
			if not DWPlus_RPHistory[i].deletes and not DWPlus_RPHistory[i].hidden and not DWPlus_RPHistory[i].deletedby then
				table.insert(DKPHistory, DWPlus_RPHistory[i])
			end
		end
	end
	
	DWP.ConfigTab7.history = history;

	if currentLength > #DKPHistory then currentLength = #DKPHistory end

	local j=currentRow+1
	local HistTimer = 0
	local processing = false
	local DKPHistTimer = DKPHistTimer or CreateFrame("StatusBar", nil, UIParent)
	DKPHistTimer:SetScript("OnUpdate", function(self, elapsed)
		HistTimer = HistTimer + elapsed
		if HistTimer > 0.001 and j <= currentLength and not processing then
			local i = j
			processing = true

			if DWP.ConfigTab7.loadMoreBtn then
				DWP.ConfigTab7.loadMoreBtn:Hide()
			end

			local curOfficer, curIndex

			if DKPHistory[i].index then
				curOfficer, curIndex = strsplit("-", DKPHistory[i].index)
			else
				curOfficer = "Unknown"
			end

			if not DWP.ConfigTab7.history[i] then
				if i==1 then
					DWP.ConfigTab7.history[i] = CreateFrame("Frame", "DWPlus_RPHistoryTab", DWP.ConfigTab7);
					DWP.ConfigTab7.history[i]:SetPoint("TOPLEFT", DWP.ConfigTab7, "TOPLEFT", 0, -45)
					DWP.ConfigTab7.history[i]:SetWidth(400)
				else
					DWP.ConfigTab7.history[i] = CreateFrame("Frame", "DWPlus_RPHistoryTab", DWP.ConfigTab7);
					DWP.ConfigTab7.history[i]:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i-1], "BOTTOMLEFT", 0, 0)
					DWP.ConfigTab7.history[i]:SetWidth(400)
				end

				DWP.ConfigTab7.history[i].h = DWP.ConfigTab7:CreateFontString(nil, "OVERLAY") 		-- entry header
				DWP.ConfigTab7.history[i].h:SetFontObject("DWPNormalLeft");
				DWP.ConfigTab7.history[i].h:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i], "TOPLEFT", 15, 0);
				DWP.ConfigTab7.history[i].h:SetWidth(400)

				DWP.ConfigTab7.history[i].d = DWP.ConfigTab7:CreateFontString(nil, "OVERLAY") 		-- entry description
				DWP.ConfigTab7.history[i].d:SetFontObject("DWPSmallLeft");
				DWP.ConfigTab7.history[i].d:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i].h, "BOTTOMLEFT", 5, -2);
				DWP.ConfigTab7.history[i].d:SetWidth(400)

				DWP.ConfigTab7.history[i].s = DWP.ConfigTab7:CreateFontString(nil, "OVERLAY")			-- entry player string
				DWP.ConfigTab7.history[i].s:SetFontObject("DWPTinyLeft");
				DWP.ConfigTab7.history[i].s:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i].d, "BOTTOMLEFT", 15, -4);
				DWP.ConfigTab7.history[i].s:SetWidth(400)

				DWP.ConfigTab7.history[i]:SetScript("OnMouseDown", function(self, button)
			    	if button == "RightButton" then
		   				if core.IsOfficer == true then
		   					RightClickDKPMenu(self, DKPHistory[i].index, DKPHistory[i].date, i)
		   				end
		   			end
			    end)
			end

			local delete_on_date, delete_day, delete_timeofday, delete_year, delete_month, delete_day, delOfficer;

			if filter == L["DELETEDENTRY"] then
				local search = DWP:Table_Search(DWPlus_RPHistory, DKPHistory[i].deletes, "index")

				if search then
					delOfficer,_ = strsplit("-", DWPlus_RPHistory[search[1][1]].deletedby)
					players = DWPlus_RPHistory[search[1][1]].players;
					if strfind(DWPlus_RPHistory[search[1][1]].reason, L["OTHER"].." - ") == 1 then
						reason = DWPlus_RPHistory[search[1][1]].reason:gsub(L["OTHER"].." -- ", "");
					else
						reason = DWPlus_RPHistory[search[1][1]].reason
					end
					dkp = DWPlus_RPHistory[search[1][1]].dkp;
					date = DWP:FormatTime(DWPlus_RPHistory[search[1][1]].date);
					delete_on_date = DWP:FormatTime(DKPHistory[i].date)
					delete_day = strsub(delete_on_date, 1, 8)
					delete_timeofday = strsub(delete_on_date, 10)
					delete_year, delete_month, delete_day = strsplit("/", delete_day)
				end
			else
				players = DKPHistory[i].players;
				if strfind(DKPHistory[i].reason, L["OTHER"].." - ") == 1 then
					reason = DKPHistory[i].reason:gsub(L["OTHER"].." -- ", "");
				else
					reason = DKPHistory[i].reason
				end
				dkp = DKPHistory[i].dkp;
				date = DWP:FormatTime(DKPHistory[i].date);

				if DWP.ConfigTab7.history[i].b then
					DWP.ConfigTab7.history[i].b:Hide()
				end
			end
			
			
			player_table = { strsplit(",", players) } or players
			if player_table[1] ~= nil and #player_table > 1 then	-- removes last entry in table which ends up being nil, which creates an additional comma at the end of the string
				tremove(player_table, #player_table)
			end

			for k=1, #player_table do
				classSearch = DWP:Table_Search(DWPlus_RPTable, player_table[k])

				if classSearch then
					c = DWP:GetCColors(DWPlus_RPTable[classSearch[1][1]].class)
					if k < #player_table then
						playerString = playerString.."|cff"..c.hex..player_table[k].."|r, "
					elseif k == #player_table then
						playerString = playerString.."|cff"..c.hex..player_table[k].."|r"
					end
				end
			end

			DWP.ConfigTab7.history[i]:SetScript("OnMouseDown", function(self, button)
		    	if button == "RightButton" and filter ~= L["DELETEDENTRY"] then
	   				if core.IsOfficer == true then
	   					RightClickDKPMenu(self, DKPHistory[i].index, DKPHistory[i].date, i)
	   				end
	   			end
		    end)
		    DWP.ConfigTab7.inst:Show();

			day = strsub(date, 1, 8)
			timeofday = strsub(date, 10)
			year, month, day = strsplit("/", day)

			if day ~= curDate then
				if i~=1 then
					DWP.ConfigTab7.history[i]:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i-1], "BOTTOMLEFT", 0, -20)
				end
				DWP.ConfigTab7.history[i].h:SetText(day.."/"..month.."/"..year);
				DWP.ConfigTab7.history[i].h:Show()
				curDate = day;
			else
				if i~=1 then
					DWP.ConfigTab7.history[i]:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i-1], "BOTTOMLEFT", 0, 0)
				end
				DWP.ConfigTab7.history[i].h:Hide()
			end

			local officer_search = DWP:Table_Search(DWPlus_RPTable, curOfficer, "player")
	    	if officer_search then
		     	c = DWP:GetCColors(DWPlus_RPTable[officer_search[1][1]].class)
		    else
		     	c = { hex="444444" }
		    end
			
			if not strfind(dkp, "-") then
				DWP.ConfigTab7.history[i].d:SetText("|cff00ff00"..dkp.." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |cff"..c.hex..curOfficer.."|r");
			else
				if strfind(reason, L["WEEKLYDECAY"]) or strfind(reason, "Migration Correction") then
					local decay = {strsplit(",", dkp)}
					DWP.ConfigTab7.history[i].d:SetText("|cffff0000"..decay[#decay].." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |cff"..c.hex..curOfficer.."|r");
				else
					DWP.ConfigTab7.history[i].d:SetText("|cffff0000"..dkp.." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |cff"..c.hex..curOfficer.."|r");
				end
			end

			DWP.ConfigTab7.history[i].d:Show()

			if not filter or (filter and filter == L["DELETEDENTRY"]) then
				DWP.ConfigTab7.history[i].s:SetText(playerString);
				DWP.ConfigTab7.history[i].s:Show()
			else
				DWP.ConfigTab7.history[i].s:Hide()
			end

			if filter and filter ~= L["DELETEDENTRY"] then
				DWP.ConfigTab7.history[i]:SetHeight(DWP.ConfigTab7.history[i].s:GetHeight() + DWP.ConfigTab7.history[i].h:GetHeight() + DWP.ConfigTab7.history[i].d:GetHeight())
			else
				DWP.ConfigTab7.history[i]:SetHeight(DWP.ConfigTab7.history[i].s:GetHeight() + DWP.ConfigTab7.history[i].h:GetHeight() + DWP.ConfigTab7.history[i].d:GetHeight() + 10)
				if filter == L["DELETEDENTRY"] then
					if not DWP.ConfigTab7.history[i].b then
						DWP.ConfigTab7.history[i].b = CreateFrame("Button", "RightClickButtonDKPHistory"..i, DWP.ConfigTab7.history[i]);
					end
					DWP.ConfigTab7.history[i].b:Show()
					DWP.ConfigTab7.history[i].b:SetPoint("TOPLEFT", DWP.ConfigTab7.history[i], "TOPLEFT", 0, 0)
					DWP.ConfigTab7.history[i].b:SetPoint("BOTTOMRIGHT", DWP.ConfigTab7.history[i], "BOTTOMRIGHT", 0, 0)
					DWP.ConfigTab7.history[i].b:SetScript("OnEnter", function(self)
				    	local col
				    	local s = DWP:Table_Search(DWPlus_RPTable, delOfficer, "player")
				    	if s then
				    		col = DWP:GetCColors(DWPlus_RPTable[s[1][1]].class)
				    	else
				    		col = { hex="444444"}
				    	end
						GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0);
						GameTooltip:SetText(L["DELETEDBY"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddDoubleLine("|cff"..col.hex..delOfficer.."|r", delete_month.."/"..delete_day.."/"..delete_year.." @ "..delete_timeofday, 1,0,0,1,1,1)
						GameTooltip:Show()
					end);
					DWP.ConfigTab7.history[i].b:SetScript("OnLeave", function(self)
						GameTooltip:Hide();
					end)
				end
			end

			playerString = ""
			table.wipe(player_table)

			DWP.ConfigTab7.history[i]:Show()

			currentRow = currentRow + 1;
			processing = false
		    j=i+1
		    HistTimer = 0
		elseif j > currentLength then
			DKPHistTimer:SetScript("OnUpdate", nil)
			HistTimer = 0

			if not DWP.ConfigTab7.loadMoreBtn then
				DWP.ConfigTab7.loadMoreBtn = CreateFrame("Button", nil, DWP.ConfigTab7, "DWPlusButtonTemplate")
				DWP.ConfigTab7.loadMoreBtn:SetSize(100, 30);
				DWP.ConfigTab7.loadMoreBtn:SetText(string.format(L["LOAD50MORE"], btnText).."...");
				DWP.ConfigTab7.loadMoreBtn:GetFontString():SetTextColor(1, 1, 1, 1)
				DWP.ConfigTab7.loadMoreBtn:SetNormalFontObject("DWPSmallCenter");
				DWP.ConfigTab7.loadMoreBtn:SetHighlightFontObject("DWPSmallCenter");
				DWP.ConfigTab7.loadMoreBtn:SetPoint("TOP", DWP.ConfigTab7.history[currentRow], "BOTTOM", 0, -10);
				DWP.ConfigTab7.loadMoreBtn:SetScript("OnClick", function(self)
					currentLength = currentLength + maxDisplayed;
					DWP:DKPHistory_Update()
					DWP.ConfigTab7.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
					DWP.ConfigTab7.loadMoreBtn:SetPoint("TOP", DWP.ConfigTab7.history[currentRow], "BOTTOM", 0, -10)
				end)
			end

			if DWP.ConfigTab7.loadMoreBtn and currentRow == #DKPHistory then
				DWP.ConfigTab7.loadMoreBtn:Hide();
			elseif DWP.ConfigTab7.loadMoreBtn and currentRow < #DKPHistory then
				if (#DKPHistory - currentRow) < btnText then btnText = (#DKPHistory - currentRow) end
				DWP.ConfigTab7.loadMoreBtn:SetText(string.format(L["LOAD50MORE"], btnText).."...")
				DWP.ConfigTab7.loadMoreBtn:SetPoint("TOP", DWP.ConfigTab7.history[currentRow], "BOTTOM", 0, -10);
				DWP.ConfigTab7.loadMoreBtn:Show()
			end
		end
	end)
end