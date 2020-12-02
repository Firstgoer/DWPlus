local _, core = ...;
local DWP = core.DWP;
local L = core.L;
local GameTooltip = GameTooltip
local Deformat = LibStub("LibDeformat-3.0")

local players = {};

local playerHeader;
local playerDropdown;
local playerSelected;

local zoneBossHeader;
local zoneBossDropdown;
local zoneSelected;
local bossSelected;

local itemHeader;
local itemDropDown;
local itemSelected;

local updateItemDropdown;

local addButton;
local addConsulFrame;
local menuFrame;

local consulItemsWidth = 420;
local SortButtons = {};
local tableZoneColumn = "zone"
local tableSorting = "zone"
local tableSortingDirection = true; -- true -> ASC, false -> DESC

local tableFilters;
local tableHeaders;
local drawnRows = {};

local consulDialog;
local consulSelectedZone;
local consulSelectedChannel = "RAID";
local consulSelectedParty = true;

local function tableHasItems(table)
	for _, _ in pairs(table) do
		return true;
	end
	return false;
end

local function pconcat(tab, delim)
	local ctab = {}
	local n = 1
	for _, v in pairs(tab) do
		ctab[n] = v
		n = n + 1
	end
	return table.concat(ctab, delim)
end

local function GetPlayersOptions()
	for i=1, #DWPlus_RPTable do
		local playerSearch = DWP:Table_Search(players, DWPlus_RPTable[i].player)
		if not playerSearch then
			table.insert(players, DWPlus_RPTable[i].player)
		end
	end
	table.sort(players, function(a, b)
		return a < b
	end)
	return players;
end

local function getZoneName(zoneIndex)
	if zoneIndex == 0 then
		return L["WORLDBOSSES"];
	else
		if not core.BossZonesData[zoneIndex] or not core.BossZonesData[zoneIndex].mapId then
			return "Zone #"..zoneIndex;
		end
		return C_Map.GetAreaInfo(core.BossZonesData[zoneIndex].mapId);
	end
end

local function getBossName(zoneId, bossId)
	if (bossId == 0) then
		return L["EXTRA"] .. ": "..getZoneName(zoneId);
	end
	local bossListId = core.BossZonesData[zoneId].bossListId;
	local bossName = core.BossList[bossListId][bossId];

	if not bossName then
		bossName = getZoneName(zoneId).." "..L["BOSS"].." #"..bossId;
	end

	return bossName;
end

local function getEntryText(item)
	local itemName = GetItemInfo(item.item);
	if (tableZoneColumn == "boss") then
		return string.format("%s - %s: %s", item.player, getBossName(item.zone, item.boss), itemName);
	end

	return string.format("%s - %s: %s", item.player, getZoneName(item.zone), itemName);
end

local function ConsulDeleteEntry(index)
	local confirm_string = "|CFFFF0000"..L["WARNING"].."\n\n|CFFFFFFFF"..L["CONFIRMDELETEENTRY1"]..":\n\n"..getEntryText(DWPlus_Consul[index]).."?";

	StaticPopupDialogs["CONFIRM_DELETE"] = {
		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()
			table.remove(DWPlus_Consul, index);
			DWP:ConsulUpdate();
			DWP:ConsulZoneShareUpdate();
			DWP.Sync:SendData("DWPConsul", DWPlus_Consul);
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show ("CONFIRM_DELETE")
end

local function RightClickMenu(index)
	--local header
	local item = DWPlus_Consul[index];
	local menu = {};

	if item then
		menu = {
			{ text = getEntryText(item), isTitle = true},
			{ text = L["DELETECONSUL"], func = function()
				ConsulDeleteEntry(index)
			end },
		}
		EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 2);
	end
end

local function resetItemDropDown()
	UIDropDownMenu_SetText(itemDropDown, "")
	UIDropDownMenu_Initialize(itemDropDown, function()                                   -- BOSS dropdown
		UIDropDownMenu_SetAnchor(itemDropDown, 10, 10, "TOPLEFT", itemDropDown, "BOTTOMLEFT")
		local reason = UIDropDownMenu_CreateInfo();
		reason.text = L["NOBOSSSELECTED"];
		reason.arg1 = "";
		reason.checked = false;
		reason.notClickable = true;
		reason.func = function() end
		UIDropDownMenu_AddButton(reason)
	end)
end

local function BossZoneDropDownCreate()
	if not zoneBossHeader then
		zoneBossHeader = addConsulFrame:CreateFontString(nil, "OVERLAY")
		zoneBossHeader:SetFontObject("DWPLargeRight");
		zoneBossHeader:SetScale(0.7)
		zoneBossHeader:SetPoint("TOPLEFT", addConsulFrame, "TOPLEFT", 30, -20);
		zoneBossHeader:SetText(L["BOSS"]..":")
		zoneBossHeader:SetWidth(80);
	end

	if not zoneBossDropdown then
		zoneBossDropdown = CreateFrame("FRAME", "DWPCLZoneDropDown", addConsulFrame, "DWPlusUIDropDownMenuTemplate")
		zoneBossDropdown:SetPoint("LEFT", zoneBossHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(zoneBossDropdown, 120)
		UIDropDownMenu_JustifyText(zoneBossDropdown, "LEFT")
	end

	if zoneSelected and bossSelected then
		UIDropDownMenu_SetText(zoneBossDropdown, getBossName(zoneSelected, bossSelected));
	end

	UIDropDownMenu_Initialize(zoneBossDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()

		if (level or 1) == 1 then
			filterName.func = self.FilterSetValue

			for zoneId, _ in pairs(core.BossZonesData) do
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = getZoneName(zoneId), zoneSelected == zoneId, zoneId, true
				UIDropDownMenu_AddButton(filterName)
			end
		else
			filterName.func = self.FilterSetValue

			for bossId = 1, #core.ItemsData[menuList] do
				filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = getBossName(menuList, bossId), menuList, bossId, bossId == bossSelected and zoneSelected == menuList, true
				UIDropDownMenu_AddButton(filterName, level)
			end

			if core.ZoneItemsExtraData[menuList] then
				-- Extra
				filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["EXTRA"], menuList, 0, bossSelected == 0 and zoneSelected == menuList, true
				UIDropDownMenu_AddButton(filterName, level)
			end
		end

		-- Dropdown Menu Function
		function zoneBossDropdown:FilterSetValue(zoneId, bossId)
			if not zoneId or not bossId then
				return;
			end
			UIDropDownMenu_SetText(zoneBossDropdown, getBossName(zoneId, bossId));
			zoneSelected = zoneId;
			bossSelected = bossId;

			UIDropDownMenu_SetText(itemDropDown, "")
			updateItemDropdown();

			CloseDropDownMenus()
		end
	end)
end

local function ItemDropDownCreate()
	if not itemHeader then
		itemHeader = addConsulFrame:CreateFontString(nil, "OVERLAY")
		itemHeader:SetFontObject("DWPLargeRight");
		itemHeader:SetScale(0.7)
		itemHeader:SetPoint("TOPRIGHT", zoneBossHeader, "BOTTOMRIGHT", 0, -25);
		itemHeader:SetText(L["ITEM"]..":")
	end

	if not itemDropDown then
		itemDropDown = CreateFrame("FRAME", "DWPCLItemDropDown", addConsulFrame, "DWPlusUIDropDownMenuTemplate")
		itemDropDown:SetPoint("LEFT", itemHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(itemDropDown, 120);
		UIDropDownMenu_JustifyText(itemDropDown, "LEFT");

		UIDropDownMenu_SetText(itemDropDown, itemSelected or "");

		itemDropDown:SetScript("OnEnter", function ()
			if (itemSelected) then
				local _, itemLink = GetItemInfo(itemSelected);
				GameTooltip:SetOwner(itemDropDown);
				GameTooltip:SetHyperlink(itemLink);
				GameTooltip:Show();
			end
		end);
		itemDropDown:SetScript("OnLeave", function ()
			if (itemSelected) then
				GameTooltip:Hide();
			end
		end);
	end

	updateItemDropdown();
end

updateItemDropdown = function()
	if not bossSelected or not zoneSelected then
		resetItemDropDown();
		return;
	end

	local items;
	if bossSelected == 0 then
		items = core.ZoneItemsExtraData[zoneSelected];
	else
		items = core.ItemsData[zoneSelected][bossSelected];
	end

	UIDropDownMenu_Initialize(itemDropDown, function(self)
		UIDropDownMenu_SetAnchor(itemDropDown, 10, 10, "TOPLEFT", itemDropDown, "BOTTOMLEFT")
		local reason = UIDropDownMenu_CreateInfo()

		reason.func = self.SetValue

		if items then
			for _, itemId in pairs(items) do
				if (type(itemId) == "function") then
					itemId = itemId();
				end
				local itemName, itemLink = GetItemInfo(itemId);
				reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = itemLink, itemId, itemName, itemId == itemSelected, true
				UIDropDownMenu_AddButton(reason)
			end

			function itemDropDown:SetValue(id, name)
				UIDropDownMenu_SetText(itemDropDown, name)
				itemSelected = id;
				CloseDropDownMenus()
			end
		else
			reason.text, reason.checked, reason.isNotRadio, reason.notClickable = L["NOITEMSFOIND"], false, false, true
			UIDropDownMenu_AddButton(reason)
		end
	end)
end

local function PlayersSelectorCreate()
	if not playerHeader then
		playerHeader = addConsulFrame:CreateFontString(nil, "OVERLAY")
		playerHeader:SetFontObject("DWPLargeRight");
		playerHeader:SetScale(0.7)
		playerHeader:SetPoint("TOPLEFT", zoneBossDropdown, "TOPRIGHT", 0, -7);
		playerHeader:SetText(L["PLAYER"]..":")
	end

	if not playerDropdown then
		playerDropdown = CreateFrame("FRAME", "DWPCLPlayerDropDown", addConsulFrame, "DWPlusUIDropDownMenuTemplate")
		playerDropdown:SetPoint("LEFT", playerHeader, "RIGHT", -15, -2)

		UIDropDownMenu_SetWidth(playerDropdown, 120)
		UIDropDownMenu_SetText(playerDropdown, playerSelected or "")

		-- Dropdown Menu Function
		function playerDropdown:FilterSetValue(id, text)
			if not id or not text then
				return;
			end
			UIDropDownMenu_SetText(playerDropdown, text)

			playerSelected = id;
			CloseDropDownMenus()
		end
	end

	UIDropDownMenu_Initialize(playerDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}
		while ranges[#ranges] < #players do
			table.insert(ranges, ranges[#ranges]+20)
		end

		local curSelected = 0;
		if playerSelected and playerSelected ~= 0 then
			local search = DWP:Table_Search(players, playerSelected)
			if search ~= false then
				curSelected = search[1]
			end
		end

		filterName.func = self.FilterSetValue
		if (level or 1) == 1 then
			local numSubs = ceil(#players/20)

			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["NOTSET"], 0, L["NOTSET"], playerSelected == 0, true
			UIDropDownMenu_AddButton(filterName)

			for i=1, numSubs do
				local max = i*20;
				if max > #players then max = #players end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = string.utf8sub(players[((i*20)-19)], 1, 1).."-"..string.utf8sub(players[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				UIDropDownMenu_AddButton(filterName)
			end
		else
			for i=ranges[menuList], ranges[menuList]+19 do
				if players[i] then
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = DWP:GetPlayerNameWithColor(players[i]), players[i], DWP:GetPlayerNameWithColor(players[i]), players[i] == playerSelected, true
					UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)
end

local function CreateRow(parent, id, item)
	local f = CreateFrame("Button", "$parentLine"..id, parent)
	f.Item = item;
	f.Columns = {}
	f:SetSize(consulItemsWidth, core.TableRowHeight)
	f:SetHighlightTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");
	f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
	f:GetNormalTexture():SetAlpha(0.2)
	for i=1, 3 do
		f.Columns[i] = f:CreateFontString(nil, "OVERLAY");
		f.Columns[i]:SetTextColor(1, 1, 1, 1);
		f.Columns[i]:SetWidth(consulItemsWidth/3);
		f.Columns[i]:SetHeight(core.TableRowHeight);
	end

	f.Columns[1]:SetPoint("LEFT");
	f.Columns[1]:SetFontObject("DWPSmallLeft");

	f.Columns[2]:SetPoint("CENTER");
	f.Columns[2]:SetFontObject("DWPSmall");

	f.Columns[3]:SetPoint("RIGHT");
	f.Columns[3]:SetFontObject("DWPSmallRight");

	f:SetScript("OnMouseDown", function(self, button)
		if not self.Item then
			return;
		end
		--if button == "LeftButton" then
		--	LeftClickTooltip(id)
		--end
		if button == "RightButton" and DWP:canUserChangeConsul(UnitName("player")) then
			RightClickMenu(id)
		end
	end)
	f:SetScript("OnEnter", function (self)
		if not self.Item then
			return;
		end
		local _, itemLink = GetItemInfo(self.Item.item);
		GameTooltip:SetOwner(self);
		GameTooltip:SetHyperlink(itemLink);
		GameTooltip:Show();
	end);
	f:SetScript("OnLeave", function ()
		GameTooltip:Hide();
	end);

	return f
end

local function checkFilteredConsulItem(item)
	if DWPlus_DB.ConsulFilters.bossSelected then
		if item.boss ~= DWPlus_DB.ConsulFilters.bossSelected or item.zone ~= DWPlus_DB.ConsulFilters.zoneSelected then
			return false;
		end
	elseif DWPlus_DB.ConsulFilters.zoneSelected then
		if item.zone ~= DWPlus_DB.ConsulFilters.zoneSelected then
			return false;
		end
	end
	if DWPlus_DB.ConsulFilters.playerSelected then
		if (item.player ~= DWPlus_DB.ConsulFilters.playerSelected) then
			return false;
		end
	end
	if DWPlus_DB.ConsulFilters.itemSearch then
		local itemId = tonumber(DWPlus_DB.ConsulFilters.itemSearch);
		if (itemId == nil or item.item ~= itemId) then
			local itemName = GetItemInfo(item.item);
			if itemName and string.find(itemName, DWPlus_DB.ConsulFilters.itemSearch) == nil then
				return false;
			end
		end
	end
	return true;
end

local function getFilteredTable()
	local resultTable = {};
	for i = 1, #DWPlus_Consul do
		local item = DWPlus_Consul[i];
		if checkFilteredConsulItem(item) then
			table.insert(resultTable, item);
		end
	end
	return resultTable;
end

function DWP:ConsulUpdate(noLoadItems)
	if not DWP.UIConfig:IsShown() then     -- does not update list if DKP window is closed. Gets done when /rp is used anyway.
		return;
	end
	for i = 1, #drawnRows do
		drawnRows[i].Item = nil;
		drawnRows[i]:Hide();
	end

	local loadedItems = 0
	if not noLoadItems then
		for i = 1, #DWPlus_Consul do
			local consulItemObject = Item:CreateFromItemID(DWPlus_Consul[i].item);
			consulItemObject:ContinueOnItemLoad(function ()
				loadedItems = loadedItems + 1;
				if loadedItems == #DWPlus_Consul then
					DWP:ConsulUpdate(true);
				end
			end)
		end
	end

	local resultTable = getFilteredTable();

	for i = 1, #resultTable do
		local item = resultTable[i];
		if not drawnRows[i] then
			drawnRows[i] = CreateRow(DWP.ConfigTab5, i, item);
		end
		drawnRows[i].Item = item;
		drawnRows[i]:Show();

		if i==1 then
			drawnRows[i]:SetPoint("TOPLEFT", tableHeaders, "TOPLEFT", 0, -24)
		else
			drawnRows[i]:SetPoint("TOPLEFT", drawnRows[i-1], "BOTTOMLEFT")
		end
		drawnRows[i].Columns[2]:SetFontObject("DWPSmallLeft");

		if (tableZoneColumn == "boss") then
			drawnRows[i].Columns[1]:SetText(getBossName(item.zone, item.boss));
		elseif tableZoneColumn == "zone" then
			drawnRows[i].Columns[1]:SetText(getZoneName(item.zone));
		end

		drawnRows[i].Columns[2]:SetText(L["LOADINGITEM"].." #"..item.item);
		local itemObject = Item:CreateFromItemID(item.item);
		itemObject:ContinueOnItemLoad(function()
			local _, itemLink = GetItemInfo(item.item);
			drawnRows[i].Columns[2]:SetText(itemLink);
		end);

		local player = item.player;
		if player == 0 then
			player = L["NOTSET"];
		else
			local search = DWP:Table_Search(players, item.player)
			if search == false then
				player = player .. "(" .. L["NOTFOUND"] .. ")";
			end
		end
		drawnRows[i].Columns[3]:SetText(player);
	end

	if (#resultTable == 0) then
		if not drawnRows[1] then
			drawnRows[1] = CreateRow(DWP.ConfigTab5, 1);
		end

		drawnRows[1]:SetPoint("TOPLEFT", tableHeaders, "TOPLEFT", 0, -24)
		drawnRows[1].Columns[2]:SetFontObject("DWPSmall");

		drawnRows[1].Columns[1]:SetText("")
		drawnRows[1].Columns[2]:SetText(L["NOENTRIESFOUND"])
		drawnRows[1].Columns[3]:SetText("")
		drawnRows[1]:Show();
	end
end

local function sortConsulTable()
	table.sort(DWPlus_Consul, function (a, b)
		local sortingField = "zone";
		if tableSorting == "boss" then
			sortingField = "boss";
		elseif tableSorting == "item" then
			sortingField = "item";
		elseif tableSorting == "player" then
			sortingField = "player";
		end
		if (tableSortingDirection) then
			return b[sortingField] > a[sortingField];
		else
			return b[sortingField] < a[sortingField];
		end
	end);

	DWP:ConsulUpdate();
end

local function ConsulAddButtonCreate()
	if addButton then
		return;
	end
	addButton = CreateFrame("Button", nil, addConsulFrame, "DWPlusButtonTemplate")
	addButton:SetSize(100, 26);
	addButton:SetText(L["ADD"]);
	addButton:GetFontString():SetTextColor(1, 1, 1, 1)
	addButton:SetNormalFontObject("DWPSmallCenter");
	addButton:SetHighlightFontObject("DWPSmallCenter");
	addButton:SetPoint("CENTER", playerDropdown, "CENTER", 0, -33);
	addButton:SetScript("OnClick", function()
		if playerSelected == nil or zoneSelected == nil or bossSelected == nil or itemSelected == nil then
			return;
		end

		for _, consulItem in pairs(DWPlus_Consul) do
			if consulItem.player == playerSelected and consulItem.zone == zoneSelected and consulItem.boss == bossSelected and consulItem.item == itemSelected then
				message(L["CONSULEXISTS"]);
				return;
			end
		end
		table.insert(DWPlus_Consul, {
			player = playerSelected, zone = zoneSelected, boss = bossSelected, item = itemSelected
		});
		playerSelected = nil;
		zoneSelected = nil;
		bossSelected = nil;
		itemSelected = nil;

		sortConsulTable();

		UIDropDownMenu_SetText(zoneBossDropdown, "");
		UIDropDownMenu_SetText(itemDropDown, "");
		UIDropDownMenu_SetText(playerDropdown, "");
		resetItemDropDown();
		DWP.Sync:SendData("DWPConsul", DWPlus_Consul);
		DWP:ConsulZoneShareUpdate();
	end)
end

local function changeSortConsulTable(column)
	if (column == tableSorting) then
		tableSortingDirection = not tableSortingDirection;
	else
		tableSorting = column;
	end
    sortConsulTable();
end

local function createTableFilters()
	tableFilters = CreateFrame("Frame", "ConsulTableHeaders", DWP.ConfigTab5)
	if not tableFilters.zoneBossHeader then
		tableFilters.zoneBossHeader = tableFilters:CreateFontString(nil, "OVERLAY")
		tableFilters.zoneBossHeader:SetFontObject("DWPNormalLeft");
		tableFilters.zoneBossHeader:SetPoint("TOPLEFT", tableFilters, "TOPLEFT", 0, -20);
		tableFilters.zoneBossHeader:SetText(L["ZONE"].." / "..L["BOSS"]..":")
		tableFilters.zoneBossHeader:SetWidth(70);
	end

	if not tableFilters.zoneBossDropdown then
		tableFilters.zoneBossDropdown = CreateFrame("FRAME", "DWPFilterZoneDropDown", tableFilters, "DWPlusUIDropDownMenuTemplate")
		tableFilters.zoneBossDropdown:SetPoint("LEFT", tableFilters.zoneBossHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(tableFilters.zoneBossDropdown, 120)
		UIDropDownMenu_JustifyText(tableFilters.zoneBossDropdown, "LEFT")
	end

	if DWPlus_DB.ConsulFilters.bossSelected then
		UIDropDownMenu_SetText(tableFilters.zoneBossDropdown, getBossName(DWPlus_DB.ConsulFilters.zoneSelected, DWPlus_DB.ConsulFilters.bossSelected));
	elseif DWPlus_DB.ConsulFilters.zoneSelected then
		UIDropDownMenu_SetText(tableFilters.zoneBossDropdown, getZoneName(DWPlus_DB.ConsulFilters.zoneSelected));
	end

	UIDropDownMenu_Initialize(tableFilters.zoneBossDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()

		if (level or 1) == 1 then
			filterName.func = self.FilterSetValue

			-- No filter
			filterName.text, filterName.arg1, filterName.checked, filterName.isNotRadio = "- "..L["NOFILTER"].." -", -1, DWPlus_DB.ConsulFilters.zoneSelected == nil and DWPlus_DB.ConsulFilters.bossSelected == nil, true
			UIDropDownMenu_AddButton(filterName)

			for zoneId, _ in pairs(core.BossZonesData) do
				filterName.text, filterName.arg1, filterName.checked, filterName.menuList, filterName.hasArrow, filterName.isNotRadio = getZoneName(zoneId), zoneId, DWPlus_DB.ConsulFilters.zoneSelected == zoneId, zoneId, true, true
				UIDropDownMenu_AddButton(filterName)
			end
		else
			filterName.func = self.FilterSetValue

			for bossId = 1, #core.ItemsData[menuList] do
				filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = getBossName(menuList, bossId), menuList, bossId, bossId == DWPlus_DB.ConsulFilters.bossSelected and DWPlus_DB.ConsulFilters.zoneSelected == menuList, true
				UIDropDownMenu_AddButton(filterName, level)
			end

			if core.ZoneItemsExtraData[menuList] then
				-- Extra
				filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["EXTRA"], menuList, 0, DWPlus_DB.ConsulFilters.bossSelected == 0 and DWPlus_DB.ConsulFilters.zoneSelected == menuList, true
				UIDropDownMenu_AddButton(filterName, level)
			end
		end

		-- Dropdown Menu Function
		function tableFilters.zoneBossDropdown:FilterSetValue(zoneId, bossId)
			if zoneId == -1 then
				UIDropDownMenu_SetText(tableFilters.zoneBossDropdown, "");
				DWPlus_DB.ConsulFilters.zoneSelected = nil;
				DWPlus_DB.ConsulFilters.bossSelected = nil;
			elseif not bossId then
				UIDropDownMenu_SetText(tableFilters.zoneBossDropdown, getZoneName(zoneId));
				DWPlus_DB.ConsulFilters.zoneSelected = zoneId;
				DWPlus_DB.ConsulFilters.bossSelected = bossId;
			else
				UIDropDownMenu_SetText(tableFilters.zoneBossDropdown, getBossName(zoneId, bossId));
				DWPlus_DB.ConsulFilters.zoneSelected = zoneId;
				DWPlus_DB.ConsulFilters.bossSelected = bossId;
			end

			CloseDropDownMenus();
			DWP:ConsulUpdate();
		end
	end)

	if not tableFilters.playerHeader then
		tableFilters.playerHeader = tableFilters:CreateFontString(nil, "OVERLAY")
		tableFilters.playerHeader:SetFontObject("DWPNormalRight");
		tableFilters.playerHeader:SetPoint("TOPLEFT", tableFilters.zoneBossDropdown, "TOPRIGHT", -22, -7);
		tableFilters.playerHeader:SetText(L["PLAYER"]..":");
		tableFilters.playerHeader:SetWidth(80);
	end

	if not tableFilters.playerDropdown then
		tableFilters.playerDropdown = CreateFrame("FRAME", "DWPFilterPlayerDropDown", tableFilters, "DWPlusUIDropDownMenuTemplate")
		tableFilters.playerDropdown:SetPoint("LEFT", tableFilters.playerHeader, "RIGHT", -15, -2)

		local playerSelectedText = "";
		if DWPlus_DB.ConsulFilters.playerSelected == 0 then
			playerSelectedText = L["NOTSET"];
		elseif DWPlus_DB.ConsulFilters.playerSelected then
			playerSelectedText = DWPlus_DB.ConsulFilters.playerSelected;
		end
		UIDropDownMenu_SetWidth(tableFilters.playerDropdown, 120)
		UIDropDownMenu_SetText(tableFilters.playerDropdown, playerSelectedText)

		-- Dropdown Menu Function
		function tableFilters.playerDropdown:FilterSetValue(id, text)
			if not id or not text then
				return;
			end
			UIDropDownMenu_SetText(tableFilters.playerDropdown, text)

			if id == -1 then
				DWPlus_DB.ConsulFilters.playerSelected = nil;
			else
				DWPlus_DB.ConsulFilters.playerSelected = id;
			end
			CloseDropDownMenus();
			DWP:ConsulUpdate();
		end
	end

	UIDropDownMenu_Initialize(tableFilters.playerDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}
		while ranges[#ranges] < #players do
			table.insert(ranges, ranges[#ranges]+20)
		end

		local curSelected = 0;
		if DWPlus_DB.ConsulFilters.playerSelected and DWPlus_DB.ConsulFilters.playerSelected ~= 0 then
			local search = DWP:Table_Search(players, DWPlus_DB.ConsulFilters.playerSelected)
			if search ~= false then
				curSelected = search[1]
			end
		end

		filterName.func = self.FilterSetValue
		if (level or 1) == 1 then
			local numSubs = ceil(#players/20)

			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "- "..L["NOFILTER"].." -", -1, "", not DWPlus_DB.ConsulFilters.playerSelected, true
			UIDropDownMenu_AddButton(filterName)

			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["NOTSET"], 0, L["NOTSET"], DWPlus_DB.ConsulFilters.playerSelected == 0, true
			UIDropDownMenu_AddButton(filterName)

			for i=1, numSubs do
				local max = i*20;
				if max > #players then max = #players end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = string.utf8sub(players[((i*20)-19)], 1, 1).."-"..string.utf8sub(players[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				UIDropDownMenu_AddButton(filterName)
			end
		else
			for i=ranges[menuList], ranges[menuList]+19 do
				if players[i] then
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = DWP:GetPlayerNameWithColor(players[i]), players[i], DWP:GetPlayerNameWithColor(players[i]), players[i] == DWPlus_DB.ConsulFilters.playerSelected, true
					UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)

	if not tableFilters.itemHeader then
		tableFilters.itemHeader = tableFilters:CreateFontString(nil, "OVERLAY")
		tableFilters.itemHeader:SetFontObject("DWPNormalRight");
		tableFilters.itemHeader:SetPoint("TOPRIGHT", tableFilters.zoneBossHeader, "BOTTOMRIGHT", -3, -20);
		tableFilters.itemHeader:SetText(L["ITEM"]..":");
		tableFilters.itemHeader:SetWidth(80);
	end

	tableFilters.itemSearch = CreateFrame("EditBox", nil, tableFilters, "DWPlusSearchEditBoxTemplate")
	tableFilters.itemSearch.L = L;
	tableFilters.itemSearch:SetPoint("LEFT", tableFilters.itemHeader, "RIGHT", 7, 0)
	tableFilters.itemSearch:SetWidth(347);

	if DWPlus_DB.ConsulFilters.itemSearch then
		tableFilters.itemSearch:SetText(DWPlus_DB.ConsulFilters.itemSearch);
	end

	tableFilters.itemSearch:SetScript("OnKeyUp", function(self)    -- clears text and focus on esc
		DWPlus_DB.ConsulFilters.itemSearch = self:GetText();
		DWP:ConsulUpdate();
	end)
	tableFilters.itemSearch:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText(L["SEARCH"])
		self:SetTextColor(0.3, 0.3, 0.3, 1)
		self:ClearFocus()

		DWPlus_DB.ConsulFilters.itemSearch = nil;
		DWP:ConsulUpdate();
	end)
	tableFilters.itemSearch:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SEARCH"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SEARCHCONSULDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	tableFilters.itemSearch:SetScript("OnLeave", function()
		GameTooltip:Hide();
	end)
end

function DWP:DeleteConsul(player, itemId)
	if not DWP:canUserChangeConsul(UnitName("player")) then
		return;
	end
	for index, consulItem in ipairs(DWPlus_Consul) do
		if consulItem.player == player and consulItem.item == tonumber(itemId) then
			ConsulDeleteEntry(index)
			return;
		end
	end
	message(L["NOENTRIESRETURNED"]);
end

function DWP:CheckExistingConsul(item)
	local playersTable = {};
	local itemId = item:GetItemID();
	if not itemId then
		return;
	end

	local notSet = false;
	for _, consulItem in pairs(DWPlus_Consul) do
		if consulItem.item == itemId then
			if consulItem.player ~= 0 then
				playersTable[consulItem.player] = DWP:GetPlayerNameWithColor(consulItem.player);
			end
			if (consulItem.player == 0) then
				notSet = true;
			end
		end
	end

	if tableHasItems(playersTable) then
		DWP:Print(string.format(L["CONSULPRINT"], item:GetItemLink(), pconcat(playersTable, ", ")));
	elseif notSet then
		DWP:Print(string.format(L["CONSULPRINTEMPTY"], item:GetItemLink()));
	end
end

local function CheckExistingConsulForPlayer(item, player)
	local itemId = item:GetItemID();
	if not itemId then
		return false;
	end

	local consulTable = DWPlus_Consul;

	for _, consulItem in pairs(consulTable) do
		if consulItem.item == itemId and consulItem.player == player then
			return true
		end
	end

	return false;
end

local function ConsulTableCreate(point)
	if not tableFilters then
		createTableFilters();
	end
	tableFilters:SetSize(consulItemsWidth, 120)
	tableFilters:SetPoint(unpack(point));

	if not tableHeaders then
		tableHeaders = CreateFrame("Frame", "ConsulTableHeaders", DWP.ConfigTab5)
	end
	tableHeaders:SetSize(consulItemsWidth, 22)
	tableHeaders:SetPoint("CENTER", tableFilters, "CENTER", 0, -33);
	tableHeaders:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	tableHeaders:SetBackdropColor(0,0,0,0.8);
	tableHeaders:SetBackdropBorderColor(1,1,1,0.5)
	tableHeaders:Show()

	if not SortButtons.bossZone then
		SortButtons.bossZone = CreateFrame("Button", "$ParentSortButtonDkp", tableHeaders)
	end
	if not SortButtons.item then
		SortButtons.item = CreateFrame("Button", "$ParentSortButtonItem", tableHeaders)
	end
	if not SortButtons.player then
		SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", tableHeaders)
	end

	SortButtons.bossZone:SetPoint("LEFT", tableHeaders, "LEFT")
	SortButtons.item:SetPoint("LEFT", SortButtons.bossZone, "RIGHT")
	SortButtons.player:SetPoint("LEFT", SortButtons.item, "RIGHT")

	for k, v in pairs(SortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		v:SetSize((consulItemsWidth/3)-1, core.TableRowHeight)
		v:SetScript("OnClick", function(self)
			local sortField = self.Id;
			if (self.Id == "bossZone") then
				sortField = tableZoneColumn;
			end
			changeSortConsulTable(sortField)
		end)
	end

	if not SortButtons.bossZone.t then
		SortButtons.bossZone.t = CreateFrame("FRAME", "ConsulSortColDropdown", SortButtons.bossZone, "DWPlusTableHeaderDropDownMenuTemplate")
	end
	SortButtons.bossZone.t:SetPoint("CENTER", SortButtons.bossZone, "CENTER", 4, -3)
	UIDropDownMenu_JustifyText(SortButtons.bossZone.t, "CENTER")
	UIDropDownMenu_SetWidth(SortButtons.bossZone.t, 80)
	UIDropDownMenu_SetText(SortButtons.bossZone.t, L["ZONE"])

	UIDropDownMenu_Initialize(SortButtons.bossZone.t, function(self)
		local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "DWPSmallCenter"
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["ZONE"], "zone", L["ZONE"], "zone" == tableZoneColumn, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["BOSS"], "boss", L["BOSS"], "boss" == tableZoneColumn, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function SortButtons.bossZone.t:SetValue(newValue, arg2)
		tableZoneColumn = newValue;
		SortButtons.bossZone.Id = newValue;
		UIDropDownMenu_SetText(SortButtons.bossZone.t, arg2);
		changeSortConsulTable(newValue);
		tableSorting = newValue;
		tableSortingDirection = 0;
		CloseDropDownMenus();
	end

	SortButtons.item.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
	SortButtons.item.t:SetFontObject("DWPNormal")
	SortButtons.item.t:SetTextColor(1, 1, 1, 1);
	SortButtons.item.t:SetPoint("LEFT", SortButtons.item, "LEFT", 50, 0);
	SortButtons.item.t:SetText(L["ITEM"]);

	SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
	SortButtons.player.t:SetFontObject("DWPNormal")
	SortButtons.player.t:SetTextColor(1, 1, 1, 1);
	SortButtons.player.t:SetPoint("LEFT", SortButtons.player, "LEFT", 50, 0);
	SortButtons.player.t:SetText(L["PLAYER"]);
end

function DWP:CheckConsulReceived(lootText)
	if not lootText or not DWP:canUserChangeConsul(UnitName("player")) then
		return;
	end
	local lootPatters = {
		"LOOT_ITEM_MULTIPLE", "LOOT_ITEM", "LOOT_ITEM_WHILE_PLAYER_INELIGIBLE"
	}
	for _, lootPattern in ipairs(lootPatters) do
		if _G[lootPattern] then
			local receiver, itemReceived = Deformat(lootText, _G[lootPattern])
			if receiver and itemReceived then
				local itemObject = Item:CreateFromItemLink(itemReceived);
				itemObject:ContinueOnItemLoad(function()
					if CheckExistingConsulForPlayer(itemObject, receiver) then
						DWP:Print(string.format(L["DELETERECEIVEDCONSUL"], DWP:GetPlayerNameWithColor(receiver), itemReceived, receiver, itemObject:GetItemID()));
					end
				end);
				return;
			end
		end
	end

	local selfLootPatters = {
		"LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_REFUND_MULTIPLE", "LOOT_ITEM_REFUND"
	}
	for _, lootPattern in ipairs(selfLootPatters) do
		if _G[lootPattern] then
			local itemReceived = Deformat(lootText, _G[lootPattern])
			if itemReceived then
				local receiver = UnitName("player");
				local itemObject = Item:CreateFromItemLink(itemReceived);
				itemObject:ContinueOnItemLoad(function()
					if CheckExistingConsulForPlayer(itemObject, receiver) then
						DWP:Print(string.format(L["DELETERECEIVEDCONSUL"], DWP:GetPlayerNameWithColor(receiver), itemReceived, receiver, itemObject:GetItemID()));
					end
				end);
				return;
			end
		end
	end
end

function DWPlus_ConsulItemsCountMessage(zoneId)
	local found = DWP:Table_Search(DWPlus_Consul, zoneId, "zone");
	if found ~= false then
		DWP:Print(string.format(L["CONSULFOUND"], #found));
	end
end

local function IsPlayerInPartyOrRaid(player)
	local GroupSize;

	if IsInRaid() then
		GroupSize = 40
	elseif IsInGroup() then
		GroupSize = 5
	end

    for i=1, GroupSize do
        local tempName = GetRaidRosterInfo(i)
        if tempName == player then
            return true;
        end
    end

	return false;
end

local function printConsulForZone()
	if not consulSelectedZone or not consulSelectedChannel then
		return;
	end
	local found = false;
	local consulItems = {};
	for _, item in pairs(DWPlus_Consul) do
		if item.zone == consulSelectedZone then
			if not consulItems[item.item] then
				consulItems[item.item] = {};
			end
			--if item.player == 0 then
			--	consulItems[item.item][item.player] = L["NOTSET"];
			--else
			if not consulSelectedParty or (consulSelectedParty and IsPlayerInPartyOrRaid(item.player)) then
				consulItems[item.item][item.player] = item.player;
			end
			--end
			found = true;
		end
	end

	if found == false then
		message(L["NOCONSULFOUND"]);
		return
	end

	for itemId, playersTable in pairs(consulItems) do
		local itemObject = Item:CreateFromItemID(itemId);
		itemObject:ContinueOnItemLoad(function()
			local _, itemLink = GetItemInfo(itemId);
			if tableHasItems(playersTable) then
				SendChatMessage(string.format(L["CONSULPRINT"], itemLink, pconcat(playersTable, ", ")), consulSelectedChannel);
			else
				SendChatMessage(string.format(L["CONSULPRINTEMPTY"], itemLink), consulSelectedChannel);
			end
		end);
	end
end

local function getConsulZones()
	local zones = {};
	for _, consulItem in pairs(DWPlus_Consul) do
		zones[consulItem.zone] = true;
	end
	return zones;
end

function DWP:ConsulZoneShareUpdate(forceCurrentZone)
	if not consulDialog then
		return;
	end
	local zonesWithConsul = getConsulZones();
	if not zonesWithConsul[consulSelectedZone] or forceCurrentZone then
		UIDropDownMenu_SetText(consulDialog.zoneDropdown, "");
		consulSelectedZone = nil;
	end

	if not consulSelectedZone then
		local zoneId;
		if IsInRaid() then
			_, _, _, _, _, _, _, zoneId = GetInstanceInfo();
		else
			zoneId = 0
		end
		if zonesWithConsul[zoneId] then
			consulSelectedZone = zoneId;
		end
	end

	if consulSelectedZone then
		UIDropDownMenu_SetText(consulDialog.zoneDropdown, getZoneName(consulSelectedZone) or "");
	end
	UIDropDownMenu_Initialize(consulDialog.zoneDropdown, function(self)
		UIDropDownMenu_SetAnchor(consulDialog.zoneDropdown, 10, 10, "TOPLEFT", consulDialog.zoneDropdown, "BOTTOMLEFT")
		local reason = UIDropDownMenu_CreateInfo()

		reason.func = self.SetValue

		if tableHasItems(zonesWithConsul) then
			for zoneId, _ in pairs(zonesWithConsul) do
				local zoneName = getZoneName(zoneId);
				reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = zoneName, zoneId, zoneName, zoneId == consulSelectedZone, true
				UIDropDownMenu_AddButton(reason)
			end

			function consulDialog.zoneDropdown:SetValue(id, name)
				UIDropDownMenu_SetText(consulDialog.zoneDropdown, name)
				consulSelectedZone = id;
				CloseDropDownMenus()
			end
		else
			reason.text, reason.checked, reason.isNotRadio, reason.notClickable = L["NOITEMSFOIND"], false, false, true
			UIDropDownMenu_AddButton(reason)
		end
	end)
end

function DWP:ConsulModal(forceCurrentZone)
	if not consulDialog then
		consulDialog = CreateFrame("Frame", "DWPConsulDialog", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
		consulDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 30);
		consulDialog:SetSize(270, 180);
		consulDialog:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
		});
		consulDialog:SetBackdropColor(0,0,0,0.8);
		consulDialog:SetMovable(true);
		consulDialog:EnableMouse(true);
		consulDialog:RegisterForDrag("LeftButton");
		consulDialog:SetScript("OnDragStart", consulDialog.StartMoving);
		consulDialog:SetScript("OnDragStop", consulDialog.StopMovingOrSizing);
		consulDialog:SetFrameStrata("FULLSCREEN_DIALOG")
		consulDialog:SetFrameLevel(11)

		-- Close Button
		consulDialog.closeContainer = CreateFrame("Frame", "DWPConsulClose", consulDialog)
		consulDialog.closeContainer:SetPoint("TOPRIGHT", consulDialog, "TOPRIGHT", -2, -2)
		consulDialog.closeContainer:SetSize(28, 28)

		consulDialog.closeBtn = CreateFrame("Button", nil, consulDialog, "UIPanelCloseButton")
		consulDialog.closeBtn:SetPoint("CENTER", consulDialog.closeContainer, "TOPRIGHT", -14, -14)
		table.insert(UISpecialFrames, consulDialog:GetName()); -- Sets frame to close on "Escape"

		local dialogHeader = consulDialog:CreateFontString(nil, "OVERLAY")
		dialogHeader:SetFontObject("DWPLargeCenter");
		dialogHeader:SetScale(0.7)
		dialogHeader:SetPoint("TOP", consulDialog, "TOP", 0, -15);
		dialogHeader:SetText(L["CONSULDIALOGHEADER"]..":")

		local zoneHeader = consulDialog:CreateFontString(nil, "OVERLAY")
		zoneHeader:SetFontObject("DWPLargeRight");
		zoneHeader:SetScale(0.7)
		zoneHeader:SetPoint("TOPLEFT", consulDialog, "TOPLEFT", 25, -60);
		zoneHeader:SetText(L["ZONE"]..":")

		consulDialog.zoneDropdown = CreateFrame("FRAME", "DWPCLItemDropDown", consulDialog, "DWPlusUIDropDownMenuTemplate")
		consulDialog.zoneDropdown:SetPoint("LEFT", zoneHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(consulDialog.zoneDropdown, 120);
		UIDropDownMenu_JustifyText(consulDialog.zoneDropdown, "LEFT");

		local channelHeader = consulDialog:CreateFontString(nil, "OVERLAY")
		channelHeader:SetFontObject("DWPLargeRight");
		channelHeader:SetScale(0.7)
		channelHeader:SetPoint("TOPLEFT", zoneHeader, "BOTTOMLEFT", 0, -25);
		channelHeader:SetText(L["CHANNEL"]..":")

		consulDialog.channelDropdown = CreateFrame("FRAME", "DWPCLItemDropDown", consulDialog, "DWPlusUIDropDownMenuTemplate")
		consulDialog.channelDropdown:SetPoint("LEFT", channelHeader, "RIGHT", -15, -2)
		UIDropDownMenu_SetWidth(consulDialog.channelDropdown, 120);
		UIDropDownMenu_JustifyText(consulDialog.channelDropdown, "LEFT");

		consulDialog.OnlyInPartyCheck = CreateFrame("CheckButton", nil, consulDialog, "UICheckButtonTemplate");
		consulDialog.OnlyInPartyCheck:SetChecked(consulSelectedParty)
		consulDialog.OnlyInPartyCheck:SetScale(0.8);
		consulDialog.OnlyInPartyCheck.text:SetText(L["PLAYERS"]..": "..L["ONLYPARTYRAID"]);
		consulDialog.OnlyInPartyCheck.text:SetScale(1.5);
		consulDialog.OnlyInPartyCheck.text:SetFontObject("DWPNormalLeft")
		consulDialog.OnlyInPartyCheck:SetPoint("TOPLEFT", channelHeader, "BOTTOMLEFT", 0, -15);
		consulDialog.OnlyInPartyCheck:SetScript("OnClick", function(self)
			consulSelectedParty = self:GetChecked();
		end)

		consulDialog.addButton = CreateFrame("Button", nil, consulDialog, "DWPlusButtonTemplate")
		consulDialog.addButton:SetSize(100, 26);
		consulDialog.addButton:SetText(L["OK"]);
		consulDialog.addButton:GetFontString():SetTextColor(1, 1, 1, 1)
		consulDialog.addButton:SetNormalFontObject("DWPSmallCenter");
		consulDialog.addButton:SetHighlightFontObject("DWPSmallCenter");
		consulDialog.addButton:SetPoint("BOTTOM", consulDialog, "BOTTOM", 0, 15);
		consulDialog.addButton:SetScript("OnClick", function()
			DWP.Sync:SendData("DWPConsul", DWPlus_Consul);
			printConsulForZone();
			consulDialog:Hide();
		end)
	end

	consulDialog:Show();

	DWP:ConsulZoneShareUpdate(forceCurrentZone);

	local channels = {
		["SAY"] = CHAT_MSG_SAY,
		["YELL"] = CHAT_MSG_YELL,
		["PARTY"] = CHAT_MSG_PARTY,
		["RAID"] = CHAT_MSG_RAID,
		["RAID_WARNING"] = CHAT_MSG_RAID_WARNING,
		["GUILD"] = CHAT_MSG_GUILD
	};
	if consulSelectedChannel then
		UIDropDownMenu_SetText(consulDialog.channelDropdown, channels[consulSelectedChannel] or "");
	end
	UIDropDownMenu_Initialize(consulDialog.channelDropdown, function(self)
		UIDropDownMenu_SetAnchor(consulDialog.channelDropdown, 10, 10, "TOPLEFT", consulDialog.channelDropdown, "BOTTOMLEFT")
		local reason = UIDropDownMenu_CreateInfo()

		reason.func = self.SetValue

		for channelId, channelName in pairs(channels) do
			reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = channelName, channelId, channelName, channelId == consulSelectedChannel, true
			UIDropDownMenu_AddButton(reason)
		end

		function consulDialog.channelDropdown:SetValue(id, name)
			UIDropDownMenu_SetText(consulDialog.channelDropdown, name)
			consulSelectedChannel = id;
			CloseDropDownMenus()
		end
	end)
end

function DWP:canUserChangeConsul(sender)
	local rankIndex = DWP:GetGuildRankIndex(sender);

	if rankIndex == 1 then       			-- automatically gives permissions above all settings if player is guild leader
		return true;
	end

	--return DWP:ValidateSender(sender); -- enabled not only for gm
	 return false;
end

function DWPlus_ConsulTab_Show()
	menuFrame = CreateFrame("Frame", "DWPDeleteDKPMenuFrame", UIParent, "UIDropDownMenuTemplate");

	DWP.ConfigTab5.text = DWP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab5.text:ClearAllPoints();
	DWP.ConfigTab5.text:SetFontObject("DWPLargeLeft");
	DWP.ConfigTab5.text:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 15, -25);
	DWP.ConfigTab5.text:SetText(L["CONSULLOOT"]);
	DWP.ConfigTab5.text:SetScale(1.2)

	if (DWP:canUserChangeConsul(UnitName("player"))) then
		addConsulFrame = CreateFrame("Frame", "DWPAddConsulFrame", DWP.ConfigTab5);
		addConsulFrame:SetPoint("TOPLEFT", DWP.ConfigTab5.text, "BOTTOMLEFT", 0, -15);
		addConsulFrame:SetSize(consulItemsWidth, 80);
		addConsulFrame:SetBackdrop({
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		});

		GetPlayersOptions();
		BossZoneDropDownCreate();
		PlayersSelectorCreate();
		ItemDropDownCreate();
		ConsulAddButtonCreate();
		ConsulTableCreate({"TOPLEFT", addConsulFrame, "BOTTOMLEFT", 0, -15});
	else
		GetPlayersOptions();
		ConsulTableCreate({"TOPLEFT", DWP.ConfigTab5.text, "BOTTOMLEFT", 0, -15});
	end

	DWP:ConsulUpdate();
end
