local _, core = ...;
local DWP = core.DWP;
local L = core.L;
local GameTooltip = GameTooltip

local players = {};

local playerDropdown;
local playerSelected;

local zoneBossHeader;
local zoneBossDropdown;
local zoneSelected;
local bossSelected;

local itemDropDown;
local itemSelected;

local updateItemDropdown;

local addConsulFrame;
local menuFrame;

local consulItemsWidth = 420;
local SortButtons = {};
local tableZoneColumn = "zone"
local tableSorting = "zone"
local tableSortingDirection = true; -- true -> ASC, false -> DESC

local tableHeaders;
local drawnRows = {};

local consulDialog;
local consulSelectedZone;
local consulSelectedChannel = "RAID";

local function GetPlayersOptions()
	for i=1, #DWPlus_RPTable do
		local playerSearch = DWP:Table_Search(players, DWPlus_RPTable[i].player)
		if not playerSearch then
			tinsert(players, DWPlus_RPTable[i].player)
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
		if not core.BossZonesData[zoneIndex].mapId then
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

local function ConsulDeleteEntry(index, item)
	local confirm_string = "|CFFFF0000"..L["WARNING"].."\n\n|CFFFFFFFF"..L["CONFIRMDELETEENTRY1"]..":\n\n"..getEntryText(item).."?";

	StaticPopupDialogs["CONFIRM_DELETE"] = {
		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()
			table.remove(DWPlus_Consul, index);
			DWP:ConsulUpdate();
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
				ConsulDeleteEntry(index, item)
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
	zoneBossHeader = addConsulFrame:CreateFontString(nil, "OVERLAY")
	zoneBossHeader:SetFontObject("DWPLargeRight");
	zoneBossHeader:SetScale(0.7)
	zoneBossHeader:SetPoint("TOPLEFT", addConsulFrame, "TOPLEFT", 30, -20);
	zoneBossHeader:SetText(L["BOSS"]..":")
	zoneBossHeader:SetWidth(80);

	zoneBossDropdown = CreateFrame("FRAME", "DWPCLZoneDropDown", addConsulFrame, "DWPlusUIDropDownMenuTemplate")
	zoneBossDropdown:SetPoint("LEFT", zoneBossHeader, "RIGHT", -15, -2)
	UIDropDownMenu_SetWidth(zoneBossDropdown, 120)
	UIDropDownMenu_JustifyText(zoneBossDropdown, "LEFT")

	UIDropDownMenu_SetText(zoneBossDropdown, zoneSelected or "");

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
				filterName.text, filterName.arg1, filterName.arg2, filterName.arg3, filterName.checked, filterName.isNotRadio = L["EXTRA"], menuList, 0, L["EXTRA"], bossSelected == 0 and zoneSelected == menuList, true
				UIDropDownMenu_AddButton(filterName, level)
			end
		end

		-- Dropdown Menu Function
		function zoneBossDropdown:FilterSetValue(zoneId, bossId)
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
	local itemHeader = addConsulFrame:CreateFontString(nil, "OVERLAY")
	itemHeader:SetFontObject("DWPLargeRight");
	itemHeader:SetScale(0.7)
	itemHeader:SetPoint("TOPRIGHT", zoneBossHeader, "BOTTOMRIGHT", 0, -25);
	itemHeader:SetText(L["ITEM"]..":")

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

	resetItemDropDown();
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
	local playerHeader = addConsulFrame:CreateFontString(nil, "OVERLAY")
	playerHeader:SetFontObject("DWPLargeRight");
	playerHeader:SetScale(0.7)
	playerHeader:SetPoint("TOPLEFT", zoneBossDropdown, "TOPRIGHT", 0, -7);
	playerHeader:SetText(L["PLAYER"]..":")

	if not playerDropdown then
		playerDropdown = CreateFrame("FRAME", "DWPCLPlayerDropDown", addConsulFrame, "DWPlusUIDropDownMenuTemplate")
	end

	playerDropdown:SetPoint("LEFT", playerHeader, "RIGHT", -15, -2)

	UIDropDownMenu_Initialize(playerDropdown, function(self, level, menuList)
		local filterName = UIDropDownMenu_CreateInfo()
		local ranges = {1}
		while ranges[#ranges] < #players do
			table.insert(ranges, ranges[#ranges]+20)
		end

		local curSelected = 0;
		if playerSelected then
			local search = DWP:Table_Search(players, playerSelected)
			if search ~= false then
				curSelected = search[1]
			end
		end

		if (level or 1) == 1 then
			local numSubs = ceil(#players/20)
			filterName.func = self.FilterSetValue

			for i=1, numSubs do
				local max = i*20;
				if max > #players then max = #players end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = string.utf8sub(players[((i*20)-19)], 1, 1).."-"..string.utf8sub(players[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				UIDropDownMenu_AddButton(filterName)
			end

		else
			filterName.func = self.FilterSetValue
			for i=ranges[menuList], ranges[menuList]+19 do
				if players[i] then
					local classSearch = DWP:Table_Search(DWPlus_RPTable, players[i])
					local c;

					if classSearch then
						c = DWP:GetCColors(DWPlus_RPTable[classSearch[1][1]].class)
					else
						c = { hex="444444" }
					end
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|cff"..c.hex..players[i].."|r", players[i], "|cff"..c.hex..players[i].."|r", players[i] == playerSelected, true
					UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)

	UIDropDownMenu_SetWidth(playerDropdown, 120)
	UIDropDownMenu_SetText(playerDropdown, playerSelected or "")

	-- Dropdown Menu Function
	function playerDropdown:FilterSetValue(newValue, arg2)
		UIDropDownMenu_SetText(playerDropdown, arg2)

		playerSelected = newValue;
		maxDisplayed = 30;
		CloseDropDownMenus()
	end
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
	f.Columns[2]:SetFontObject("DWPSmallLeft");

	f.Columns[3]:SetPoint("RIGHT");
	f.Columns[3]:SetFontObject("DWPSmallRight");

	f:SetScript("OnMouseDown", function(_, button)
		--if button == "LeftButton" then
		--	LeftClickTooltip(id)
		--end
		if button == "RightButton" and core.IsOfficer then
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

function DWP:ConsulUpdate()
	if not DWP.UIConfig:IsShown() then     -- does not update list if DKP window is closed. Gets done when /rp is used anyway.
		return;
	end
	for i = 1, #drawnRows do
		drawnRows[i].Item = nil;
		drawnRows[i]:Hide();
	end

	for i = 1, #DWPlus_Consul do
		local item = DWPlus_Consul[i];
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

		local playerName = item.player;
		local search = DWP:Table_Search(players, item.player)
		if search == false then
			playerName = playerName .. "(" .. L["NOTFOUND"] .. ")";
		end
		drawnRows[i].Columns[3]:SetText(playerName);
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
	local addButton = CreateFrame("Button", nil, addConsulFrame, "DWPlusButtonTemplate")
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

local function ConsulTableCreate(point)
	tableHeaders = CreateFrame("Frame", "ConsulTableHeaders", DWP.ConfigTab5)
	tableHeaders:SetSize(consulItemsWidth, 22)
	tableHeaders:SetPoint(unpack(point));
	tableHeaders:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	tableHeaders:SetBackdropColor(0,0,0,0.8);
	tableHeaders:SetBackdropBorderColor(1,1,1,0.5)
	tableHeaders:Show()

	SortButtons.bossZone = CreateFrame("Button", "$ParentSortButtonDkp", tableHeaders)
	SortButtons.item = CreateFrame("Button", "$ParentSortButtonItem", tableHeaders)
	SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", tableHeaders)

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

	SortButtons.bossZone.t = CreateFrame("FRAME", "ConsulSortColDropdown", SortButtons.bossZone, "DWPlusTableHeaderDropDownMenuTemplate")
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

function DWPlus_ConsulItemsCountMessage(zoneId)
	local found = DWP:Table_Search(DWPlus_Consul, zoneId, "zone");
	if found ~= false then
		DWP:Print(string.format(L["CONSULFOUND"], #found));
	end
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
			consulItems[item.item][item.player] = item.player;
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
			SendChatMessage(string.format(L["CONSULPRINT"], itemLink, pconcat(playersTable, ", ")), consulSelectedChannel);
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

function DWP:ConsulModal()
	if not consulDialog then
		consulDialog = CreateFrame("Frame", "DWPConsulDialog", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
		consulDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 30);
		consulDialog:SetSize(270, 150);
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
		consulDialog:SetFrameStrata("DIALOG")
		consulDialog:SetFrameLevel(10)

		-- Close Button
		consulDialog.closeContainer = CreateFrame("Frame", "DWPConsulClose", consulDialog)
		consulDialog.closeContainer:SetPoint("TOPRIGHT", consulDialog, "TOPRIGHT", -2, -2)
		consulDialog.closeContainer:SetSize(28, 28)

		consulDialog.closeBtn = CreateFrame("Button", nil, consulDialog, "UIPanelCloseButton")
		consulDialog.closeBtn:SetPoint("CENTER", consulDialog.closeContainer, "TOPRIGHT", -14, -14)
		tinsert(UISpecialFrames, consulDialog:GetName()); -- Sets frame to close on "Escape"

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

		consulDialog.addButton = CreateFrame("Button", nil, consulDialog, "DWPlusButtonTemplate")
		consulDialog.addButton:SetSize(100, 26);
		consulDialog.addButton:SetText(L["OK"]);
		consulDialog.addButton:GetFontString():SetTextColor(1, 1, 1, 1)
		consulDialog.addButton:SetNormalFontObject("DWPSmallCenter");
		consulDialog.addButton:SetHighlightFontObject("DWPSmallCenter");
		consulDialog.addButton:SetPoint("BOTTOM", consulDialog, "BOTTOM", 0, 15);
		consulDialog.addButton:SetScript("OnClick", function()
			printConsulForZone();
		end)
	end

	consulDialog:Show();

	local zonesWithConsul = getConsulZones();

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

		if zonesWithConsul then
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

function DWPlus_ConsulTab_Show()
	menuFrame = CreateFrame("Frame", "DWPDeleteDKPMenuFrame", UIParent, "UIDropDownMenuTemplate");

	DWP.ConfigTab5.text = DWP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab5.text:ClearAllPoints();
	DWP.ConfigTab5.text:SetFontObject("DWPLargeLeft");
	DWP.ConfigTab5.text:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 15, -25);
	DWP.ConfigTab5.text:SetText(L["CONSULLOOT"]);
	DWP.ConfigTab5.text:SetScale(1.2)

	if (core.IsOfficer) then
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
