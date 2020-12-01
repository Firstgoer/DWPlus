local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local OptionsLoaded = false;

function DWP_RestoreFilterOptions()  		-- restores default filter selections
	DWP.UIConfig.search:SetText(L["SEARCH"])
	DWP.UIConfig.search:SetTextColor(0.3, 0.3, 0.3, 1)
	DWP.UIConfig.search:ClearFocus()
	core.WorkingTable = CopyTable(DWPlus_RPTable)
	core.CurView = "all"
	core.CurSubView = "all"
	for i=1, 9 do
		DWP.ConfigTab1.checkBtn[i]:SetChecked(true)
	end
	DWP.ConfigTab1.checkBtn[10]:SetChecked(false)
	DWP.ConfigTab1.checkBtn[11]:SetChecked(false)
	DWP.ConfigTab1.checkBtn[12]:SetChecked(false)
	DWPFilterChecks(DWP.ConfigTab1.checkBtn[1])
end

function DWP:Toggle()        -- toggles IsShown() state of DWP.UIConfig, the entire addon window
	core.DWPUI = DWP.UIConfig or DWP:CreateMenu();
	core.DWPUI:SetShown(not core.DWPUI:IsShown())
	DWP.UIConfig:SetFrameLevel(10)
	DWP.UIConfig:SetClampedToScreen(true)
	if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
	if core.ModesWindow then core.ModesWindow:SetFrameLevel(2) end

	if core.IsOfficer == nil then
		DWP:CheckOfficer()
	end
	--core.IsOfficer = C_GuildInfo.CanEditOfficerNote()  -- seemingly removed from classic API
	if core.IsOfficer == false then
		for i=2, 3 do
			_G["DWP.ConfigTabMenuTab"..i]:Hide();
		end
		_G["DWP.ConfigTabMenuTab4"]:SetPoint("TOPLEFT", _G["DWP.ConfigTabMenuTab1"], "TOPRIGHT", -14, 0)
		_G["DWP.ConfigTabMenuTab5"]:SetPoint("TOPLEFT", _G["DWP.ConfigTabMenuTab4"], "TOPRIGHT", -14, 0)
		_G["DWP.ConfigTabMenuTab6"]:SetPoint("TOPLEFT", _G["DWP.ConfigTabMenuTab5"], "TOPRIGHT", -14, 0)
	end

	if not OptionsLoaded then
		core.DWPOptions = core.DWPOptions or DWP:Options()
		OptionsLoaded = true;
	end

	if #DWPlus_Whitelist > 0 and core.IsOfficer then
		DWP.Sync:SendData("DWPWhitelist", DWPlus_Whitelist)   -- broadcasts whitelist any time the window is opened if one exists (help ensure everyone has the information even if they were offline when it was created)
	end

	if core.CurSubView == "raid" then
		DWP:ViewLimited(true)
	elseif core.CurSubView == "standby" then
		DWP:ViewLimited(false, true)
	elseif core.CurSubView == "raid and standby" then
		DWP:ViewLimited(true, true)
	elseif core.CurSubView == "core" then
		DWP:ViewLimited(false, false, true)
	elseif core.CurSubView == "all" then
		DWP:ViewLimited()
	end

	core.DWPUI:SetScale(DWPlus_DB.defaults.DWPScaleSize)
	if DWP.ConfigTab7.history and DWP.ConfigTab7:IsShown() then
		DWP:DKPHistory_Update(true)
	elseif DWP.ConfigTab6 and DWP.ConfigTab6:IsShown() then
		DWP:LootHistory_Update(L["NOFILTER"]);
	end

	DWP:StatusVerify_Update()
	DKPTable_Update()
	DWPlus_ConsulTab_Show();
end

---------------------------------------
-- Sort Function
---------------------------------------
local SortButtons = {}

function DWP:FilterDKPTable(sort, reset)          -- filters core.WorkingTable based on classes in classFiltered table. core.currentSort should be used in most cases
	local parentTable;

	if not DWP.UIConfig then
		return
	end

	if core.CurSubView ~= "all" then
		if core.CurSubView == "raid" then
			DWP:ViewLimited(true)
		elseif core.CurSubView == "standby" then
			DWP:ViewLimited(false, true)
		elseif core.CurSubView == "raid and standby" then
			DWP:ViewLimited(true, true)
		elseif core.CurSubView == "core" then
			DWP:ViewLimited(false, false, true)
		end
		parentTable = core.WorkingTable;
	else
		parentTable = DWPlus_RPTable;
	end

	core.WorkingTable = {}
	for k,v in ipairs(parentTable) do
		local IsOnline = false;
		local name;
		local InRaid = false;
		local searchFilter = true

		if DWP.UIConfig.search:GetText() ~= L["SEARCH"] and DWP.UIConfig.search:GetText() ~= "" then
			if not strfind(string.upper(v.player), string.upper(DWP.UIConfig.search:GetText()))
				and not strfind(string.upper(v.class), string.upper(DWP.UIConfig.search:GetText()))
				and not strfind(string.upper(core.LocalClass[v.class] ), string.upper(DWP.UIConfig.search:GetText()))
				and not strfind(string.upper(v.role), string.upper(DWP.UIConfig.search:GetText()))
				and not strfind(string.upper(v.rankName), string.upper(DWP.UIConfig.search:GetText()))
				and not strfind(string.upper(v.spec), string.upper(DWP.UIConfig.search:GetText())) then
					searchFilter = false;
			end
		end
		
		if DWP.ConfigTab1.checkBtn[11]:GetChecked() then
			local guildSize,_,_ = GetNumGuildMembers();
			for i=1, guildSize do
				local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
				name = strsub(name, 1, string.find(name, "-")-1)
				
				if name == v.player then
					IsOnline = online;
					break;
				end
			end
		end
		if(core.classFiltered[parentTable[k]["class"]] == true) and searchFilter == true then
			if DWP.ConfigTab1.checkBtn[10]:GetChecked() or DWP.ConfigTab1.checkBtn[12]:GetChecked() then
				for i=1, 40 do
					tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
					if tempName and tempName == v.player and DWP.ConfigTab1.checkBtn[10]:GetChecked() then
						tinsert(core.WorkingTable, v)
					elseif tempName and tempName == v.player and DWP.ConfigTab1.checkBtn[12]:GetChecked() then
						InRaid = true;
					end
				end
			else
				if ((DWP.ConfigTab1.checkBtn[11]:GetChecked() and IsOnline) or not DWP.ConfigTab1.checkBtn[11]:GetChecked()) then
					tinsert(core.WorkingTable, v)
				end
			end
			if DWP.ConfigTab1.checkBtn[12]:GetChecked() and InRaid == false then
				if DWP.ConfigTab1.checkBtn[11]:GetChecked() then
					if IsOnline then
						tinsert(core.WorkingTable, v)
					end
				else
					tinsert(core.WorkingTable, v)
				end
			end
		end
		InRaid = false;
	end

	if #core.WorkingTable == 0 then  		-- removes all filter settings if the filter combination results in an empty table
		--DWP_RestoreFilterOptions()
		DWP.DKPTable.Rows[1].DKPInfo[1]:SetText("|cffff0000No Entries Returned.|r")
		DWP.DKPTable.Rows[1]:Show()
	end
	DWP:SortDKPTable(sort, reset);
end

function DWP:SortDKPTable(id, reset)        -- reorganizes core.WorkingTable based on id passed. Avail IDs are "class", "player" and "dkp"
	local button;                                 -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)

	if id == "class" or id == "rank" or id == "role" or id == "spec" then
		button = SortButtons.class
	elseif id == "spec" then                -- doesn't allow "spec" to be sorted.
		DKPTable_Update()
		return;
	else
		button = SortButtons[id]
	end

	if reset and reset ~= "Clear" then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
		button.Ascend = button.Ascend
	else
		button.Ascend = not button.Ascend
	end
	for k, v in pairs(SortButtons) do
		if v ~= button then
			v.Ascend = nil
		end
	end
	table.sort(core.WorkingTable, function(a, b)
		if button.Ascend then
			if(id == "dkp") then return a[button.Id] > b[button.Id] else return a[button.Id] < b[button.Id] end
		else
			if(id == "dkp") then return a[button.Id] < b[button.Id] else return a[button.Id] > b[button.Id] end
		end
	end)
	core.currentSort = id;
	DKPTable_Update()
end

function DWP:CreateMenu()
	DWP.UIConfig = CreateFrame("Frame", "DWPConfig", UIParent, "ShadowOverlaySmallTemplate")  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
	DWP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", DWPlus_DB.ConfigPos.x, DWPlus_DB.ConfigPos.y);
	DWP.UIConfig:SetSize(550, 590);
	DWP.UIConfig:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	DWP.UIConfig:SetBackdropColor(0,0,0,0.8);
	DWP.UIConfig:SetMovable(true);
	DWP.UIConfig:EnableMouse(true);
	--DWP.UIConfig:SetResizable(true);
	--DWP.UIConfig:SetMaxResize(1400, 875)
	--DWP.UIConfig:SetMinResize(1000, 590)
	DWP.UIConfig:RegisterForDrag("LeftButton");
	DWP.UIConfig:SetScript("OnDragStart", DWP.UIConfig.StartMoving);
	DWP.UIConfig:SetScript("OnDragStop", function (self, button)
		DWP.UIConfig:StopMovingOrSizing();
		local _, _, _, newX, newY = DWP.UIConfig:GetPoint();
		DWPlus_DB.ConfigPos = { x = newX, y = newY };
	end);
	DWP.UIConfig:SetFrameStrata("DIALOG")
	DWP.UIConfig:SetFrameLevel(10)
	DWP.UIConfig:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(2) end
	end)

	-- Close Button
	DWP.UIConfig.closeContainer = CreateFrame("Frame", "DWPTitle", DWP.UIConfig)
	DWP.UIConfig.closeContainer:SetPoint("CENTER", DWP.UIConfig, "TOPRIGHT", -4, 0)
	DWP.UIConfig.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	DWP.UIConfig.closeContainer:SetBackdropColor(0,0,0,0.9)
	DWP.UIConfig.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	DWP.UIConfig.closeContainer:SetSize(28, 28)

	DWP.UIConfig.closeBtn = CreateFrame("Button", nil, DWP.UIConfig, "UIPanelCloseButton")
	DWP.UIConfig.closeBtn:SetPoint("CENTER", DWP.UIConfig.closeContainer, "TOPRIGHT", -14, -14)
	tinsert(UISpecialFrames, DWP.UIConfig:GetName()); -- Sets frame to close on "Escape"

	---------------------------------------
	-- Create and Populate Tab Menu and DKP Table
	---------------------------------------

	DWP.TabMenu = DWP:ConfigMenuTabs();        -- Create and populate Config Menu Tabs
	DWP:DKPTable_Create();                        -- Create DKPTable and populate rows
	DWP.UIConfig.TabMenu:Hide()                   -- Hide menu until expanded
	---------------------------------------
	-- DKP Table Header and Sort Buttons
	---------------------------------------

	DWP.DKPTable_Headers = CreateFrame("Frame", "DWPDKPTableHeaders", DWP.UIConfig)
	DWP.DKPTable_Headers:SetSize(500, 22)
	DWP.DKPTable_Headers:SetPoint("BOTTOMLEFT", DWP.DKPTable, "TOPLEFT", 0, 1)
	DWP.DKPTable_Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	DWP.DKPTable_Headers:SetBackdropColor(0,0,0,0.8);
	DWP.DKPTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
	DWP.DKPTable_Headers:Show()

	---------------------------------------
	-- Sort Buttons
	--------------------------------------- 

	SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", DWP.DKPTable_Headers)
	SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", DWP.DKPTable_Headers)
	SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", DWP.DKPTable_Headers)
	 
	SortButtons.class:SetPoint("BOTTOM", DWP.DKPTable_Headers, "BOTTOM", 0, 2)
	SortButtons.player:SetPoint("RIGHT", SortButtons.class, "LEFT")
	SortButtons.dkp:SetPoint("LEFT", SortButtons.class, "RIGHT")
	 
	for k, v in pairs(SortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		v:SetSize((core.TableWidth/3)-1, core.TableRowHeight)
		if v.Id == "class" then
			v:SetScript("OnClick", function(self) DWP:SortDKPTable(core.CenterSort, "Clear") end)
		else
			v:SetScript("OnClick", function(self) DWP:SortDKPTable(self.Id, "Clear") end)
		end
	end

	SortButtons.player:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)
	SortButtons.class:SetSize((core.TableWidth*0.2)-1, core.TableRowHeight)
	SortButtons.dkp:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)

	SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
	SortButtons.player.t:SetFontObject("DWPNormal")
	SortButtons.player.t:SetTextColor(1, 1, 1, 1);
	SortButtons.player.t:SetPoint("LEFT", SortButtons.player, "LEFT", 50, 0);
	SortButtons.player.t:SetText(L["PLAYER"]); 

	--[[SortButtons.class.t = SortButtons.class:CreateFontString(nil, "OVERLAY")
	SortButtons.class.t:SetFontObject("DWPNormal");
	SortButtons.class.t:SetTextColor(1, 1, 1, 1);
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 0, 0);
	SortButtons.class.t:SetText(L["CLASS"]); --]]

	-- center column dropdown (class, rank, spec etc..)
	SortButtons.class.t = CreateFrame("FRAME", "DWPSortColDropdown", SortButtons.class, "DWPlusTableHeaderDropDownMenuTemplate")
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 4, -3)
	UIDropDownMenu_JustifyText(SortButtons.class.t, "CENTER")
	UIDropDownMenu_SetWidth(SortButtons.class.t, 80)
	UIDropDownMenu_SetText(SortButtons.class.t, L["CLASS"])

	UIDropDownMenu_Initialize(SortButtons.class.t, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "DWPSmallCenter"
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["CLASS"], "class", L["CLASS"], "class" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["SPEC"], "spec", L["SPEC"], "spec" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["RANK"], "rank", L["RANK"], "rank" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["ROLE"], "role", L["ROLE"], "role" == core.CenterSort, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function SortButtons.class.t:SetValue(newValue, arg2)
		
		core.CenterSort = newValue
		SortButtons.class.Id = newValue;
		UIDropDownMenu_SetText(SortButtons.class.t, arg2)
		DWP:SortDKPTable(newValue, "reset")
		core.currentSort = newValue;
		CloseDropDownMenus()
	end

	SortButtons.dkp.t = SortButtons.dkp:CreateFontString(nil, "OVERLAY")
	SortButtons.dkp.t:SetFontObject("DWPNormal")
	SortButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	if DWPlus_DB.modes.mode == "Roll Based Bidding" then
		SortButtons.dkp.t:SetPoint("RIGHT", SortButtons.dkp, "RIGHT", -50, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);

		SortButtons.dkp.roll = SortButtons.dkp:CreateFontString(nil, "OVERLAY");
		SortButtons.dkp.roll:SetFontObject("DWPNormal")
		SortButtons.dkp.roll:SetScale("0.8")
		SortButtons.dkp.roll:SetTextColor(1, 1, 1, 1);
		SortButtons.dkp.roll:SetPoint("LEFT", SortButtons.dkp, "LEFT", 20, -1);
		SortButtons.dkp.roll:SetText(L["ROLLRANGE"])
	else
		SortButtons.dkp.t:SetPoint("CENTER", SortButtons.dkp, "CENTER", 20, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);
	end

	----- Counter below DKP Table
	DWP.DKPTable.counter = CreateFrame("Frame", "DWPDisplayFrameCounter", DWP.UIConfig);
	DWP.DKPTable.counter:SetPoint("TOP", DWP.DKPTable, "BOTTOM", 0, 0)
	DWP.DKPTable.counter:SetSize(400, 30)

	DWP.DKPTable.counter.t = DWP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	DWP.DKPTable.counter.t:SetFontObject("DWPNormal");
	DWP.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
	DWP.DKPTable.counter.t:SetPoint("CENTER", DWP.DKPTable.counter, "CENTER");

	DWP.DKPTable.counter.s = DWP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	DWP.DKPTable.counter.s:SetFontObject("DWPTiny");
	DWP.DKPTable.counter.s:SetTextColor(1, 1, 1, 0.7);
	DWP.DKPTable.counter.s:SetPoint("CENTER", DWP.DKPTable.counter, "CENTER", 0, -15);

	------------------------------
	-- Search Box
	------------------------------

	DWP.UIConfig.search = CreateFrame("EditBox", nil, DWP.UIConfig, "DWPlusSearchEditBoxTemplate")
	DWP.UIConfig.search.L = L;
	DWP.UIConfig.search:SetPoint("BOTTOMLEFT", DWP.UIConfig, "BOTTOMLEFT", 50, 18);
	DWP.UIConfig.search:SetScript("OnKeyUp", function()    -- clears text and focus on esc
		if (DWP.UIConfig.search:GetText():match("[%^%$%(%)%%%.%[%]%*%+%-%?]")) then
			DWP.UIConfig.search:SetText(string.gsub(DWP.UIConfig.search:GetText(), "[%^%$%(%)%%%.%[%]%*%+%-%?]", ""))
			--DWP.UIConfig.search:SetText(strsub(DWP.UIConfig.search:GetText(), 1, -2))
		else
			DWP:FilterDKPTable(core.currentSort, "reset")
		end
	end)
	DWP.UIConfig.search:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText(L["SEARCH"])
		self:SetTextColor(0.3, 0.3, 0.3, 1)
		self:ClearFocus()
		DWP:FilterDKPTable(core.currentSort, "reset")
	end)
	DWP.UIConfig.search:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SEARCH"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SEARCHDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.UIConfig.search:SetScript("OnLeave", function()
		GameTooltip:Hide();
	end)

	---------------------------------------
	-- Expand / Collapse Arrow
	---------------------------------------

	DWP.UIConfig.expand = CreateFrame("Frame", "DWPTitle", DWP.UIConfig)
	DWP.UIConfig.expand:SetPoint("LEFT", DWP.UIConfig, "RIGHT", 0, 0)
	DWP.UIConfig.expand:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
	});
	DWP.UIConfig.expand:SetBackdropColor(0,0,0,0.7)
	DWP.UIConfig.expand:SetSize(15, 60)
	
	DWP.UIConfig.expandtab = DWP.UIConfig.expand:CreateTexture(nil, "OVERLAY", nil);
	DWP.UIConfig.expandtab:SetColorTexture(0, 0, 0, 1)
	DWP.UIConfig.expandtab:SetPoint("CENTER", DWP.UIConfig.expand, "CENTER");
	DWP.UIConfig.expandtab:SetSize(15, 60);
	DWP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\expand-arrow.tga");

	DWP.UIConfig.expand.trigger = CreateFrame("Button", "$ParentCollapseExpandButton", DWP.UIConfig.expand)
	DWP.UIConfig.expand.trigger:SetSize(15, 60)
	DWP.UIConfig.expand.trigger:SetPoint("CENTER", DWP.UIConfig.expand, "CENTER", 0, 0)
	DWP.UIConfig.expand.trigger:SetScript("OnClick", function(self)
		if core.ShowState == false then
			DWP.UIConfig:SetWidth(1050)
			DWP.UIConfig.TabMenu:Show()
			DWP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\collapse-arrow");
			DWPlus_DB.TabMenuShown = true;
		else
			DWP.UIConfig:SetWidth(550)
			DWP.UIConfig.TabMenu:Hide()
			DWP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\expand-arrow");
			DWPlus_DB.TabMenuShown = false;
		end
		PlaySound(62540)
		core.ShowState = not core.ShowState
	end)

	if DWPlus_DB.TabMenuShown then
		DWP.UIConfig:SetWidth(1050)
		DWP.UIConfig.TabMenu:Show()
		DWP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\collapse-arrow");
	else
		DWP.UIConfig:SetWidth(550)
		DWP.UIConfig.TabMenu:Hide()
		DWP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\expand-arrow");
	end

	-- Title Frame (top/center)
	DWP.UIConfig.TitleBar = CreateFrame("Frame", "DWPTitle", DWP.UIConfig, "ShadowOverlaySmallTemplate")
	DWP.UIConfig.TitleBar:SetPoint("BOTTOM", SortButtons.class, "TOP", 0, 10)
	DWP.UIConfig.TitleBar:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	DWP.UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
	DWP.UIConfig.TitleBar:SetSize(166, 54)

	-- Addon Title
	DWP.UIConfig.Title = DWP.UIConfig.TitleBar:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
	DWP.UIConfig.Title:SetColorTexture(0, 0, 0, 1)
	DWP.UIConfig.Title:SetPoint("CENTER", DWP.UIConfig.TitleBar, "CENTER");
	DWP.UIConfig.Title:SetSize(160, 48);
	DWP.UIConfig.Title:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\dw-plus-tracker.tga");

	---------------------------------------
	-- CHANGE LOG WINDOW
	---------------------------------------
	DWP.ChangeLogDisplay = CreateFrame("Frame", "DWP_ChangeLogDisplay", UIParent, "ShadowOverlaySmallTemplate");
	DWP.ChangeLogDisplay:Hide();

	DWP.ChangeLogDisplay:SetPoint("TOP", UIParent, "TOP", 0, -200);
	DWP.ChangeLogDisplay:SetSize(600, 100);
	DWP.ChangeLogDisplay:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	DWP.ChangeLogDisplay:SetBackdropColor(0,0,0,0.9);
	DWP.ChangeLogDisplay:SetBackdropBorderColor(1,1,1,1)
	DWP.ChangeLogDisplay:SetFrameStrata("DIALOG")
	DWP.ChangeLogDisplay:SetFrameLevel(1)
	DWP.ChangeLogDisplay:SetMovable(true);
	DWP.ChangeLogDisplay:EnableMouse(true);
	DWP.ChangeLogDisplay:RegisterForDrag("LeftButton");
	DWP.ChangeLogDisplay:SetScript("OnDragStart", DWP.ChangeLogDisplay.StartMoving);
	DWP.ChangeLogDisplay:SetScript("OnDragStop", DWP.ChangeLogDisplay.StopMovingOrSizing);

	DWP.ChangeLogDisplay.ChangeLogHeader = DWP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
	DWP.ChangeLogDisplay.ChangeLogHeader:ClearAllPoints();
	DWP.ChangeLogDisplay.ChangeLogHeader:SetFontObject("DWPLargeLeft")
	DWP.ChangeLogDisplay.ChangeLogHeader:SetPoint("TOPLEFT", DWP.ChangeLogDisplay, "TOPLEFT", 10, -10);
	DWP.ChangeLogDisplay.ChangeLogHeader:SetText("DWPlus Change Log");

	DWP.ChangeLogDisplay.Notes = DWP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
	DWP.ChangeLogDisplay.Notes:ClearAllPoints();
	DWP.ChangeLogDisplay.Notes:SetWidth(580)
	DWP.ChangeLogDisplay.Notes:SetFontObject("DWPNormalLeft")
	DWP.ChangeLogDisplay.Notes:SetPoint("TOPLEFT", DWP.ChangeLogDisplay.ChangeLogHeader, "BOTTOMLEFT", 8, -10);

	DWP.ChangeLogDisplay.VerNumber = DWP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
	DWP.ChangeLogDisplay.VerNumber:ClearAllPoints();
	DWP.ChangeLogDisplay.VerNumber:SetWidth(580)
	DWP.ChangeLogDisplay.VerNumber:SetScale(0.8)
	DWP.ChangeLogDisplay.VerNumber:SetFontObject("DWPLargeLeft")
	DWP.ChangeLogDisplay.VerNumber:SetPoint("TOPLEFT", DWP.ChangeLogDisplay.Notes, "BOTTOMLEFT", 27, -10);

	DWP.ChangeLogDisplay.ChangeLogText = DWP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
	DWP.ChangeLogDisplay.ChangeLogText:ClearAllPoints();
	DWP.ChangeLogDisplay.ChangeLogText:SetWidth(540)
	DWP.ChangeLogDisplay.ChangeLogText:SetFontObject("DWPNormalLeft")
	DWP.ChangeLogDisplay.ChangeLogText:SetPoint("TOPLEFT", DWP.ChangeLogDisplay.VerNumber, "BOTTOMLEFT", -23, -10);

	-- Change Log Close Button
	DWP.ChangeLogDisplay.closeContainer = CreateFrame("Frame", "DWPChangeLogClose", DWP.ChangeLogDisplay)
	DWP.ChangeLogDisplay.closeContainer:SetPoint("CENTER", DWP.ChangeLogDisplay, "TOPRIGHT", -4, 0)
	DWP.ChangeLogDisplay.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	DWP.ChangeLogDisplay.closeContainer:SetBackdropColor(0,0,0,0.9)
	DWP.ChangeLogDisplay.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	DWP.ChangeLogDisplay.closeContainer:SetSize(28, 28)

	DWP.ChangeLogDisplay.closeBtn = CreateFrame("Button", nil, DWP.ChangeLogDisplay, "UIPanelCloseButton")
	DWP.ChangeLogDisplay.closeBtn:SetPoint("CENTER", DWP.ChangeLogDisplay.closeContainer, "TOPRIGHT", -14, -14)

	DWP.ChangeLogDisplay.DontShowCheck = CreateFrame("CheckButton", nil, DWP.ChangeLogDisplay, "UICheckButtonTemplate");
	DWP.ChangeLogDisplay.DontShowCheck:SetChecked(false)
	DWP.ChangeLogDisplay.DontShowCheck:SetScale(0.6);
	DWP.ChangeLogDisplay.DontShowCheck.text:SetText("  |cff5151de"..L["DONTSHOW"].."|r");
	DWP.ChangeLogDisplay.DontShowCheck.text:SetScale(1.5);
	DWP.ChangeLogDisplay.DontShowCheck.text:SetFontObject("DWPSmallLeft")
	DWP.ChangeLogDisplay.DontShowCheck:SetPoint("LEFT", DWP.ChangeLogDisplay.ChangeLogHeader, "RIGHT", 10, 0);
	DWP.ChangeLogDisplay.DontShowCheck:SetScript("OnClick", function(self)
		if self:GetChecked() then
			DWPlus_DB.defaults.HideChangeLogs = core.BuildNumber
		else
			DWPlus_DB.defaults.HideChangeLogs = 0
		end
	end);
	DWP.ChangeLogDisplay.DontShowCheck:SetChecked(DWPlus_DB.defaults.HideChangeLogs == core.BuildNumber);

	DWP.ChangeLogDisplay.Notes:SetText("|CFFAEAEDD"..L["BESTPRACTICES"].."|r")
	DWP.ChangeLogDisplay.VerNumber:SetText(core.MonVersion)

	--------------------------------------
	-- ChangeLog variable calls (bottom of localization files)
	--------------------------------------
	DWP.ChangeLogDisplay.ChangeLogText:SetText(L["CHANGELOG1"].."\n\n"..L["CHANGELOG2"].."\n\n"..L["CHANGELOG3"].."\n\n"..L["CHANGELOG4"].."\n\n"..L["CHANGELOG5"].."\n\n"..L["CHANGELOG6"].."\n\n"..L["CHANGELOG7"].."\n\n"..L["CHANGELOG8"].."\n\n"..L["CHANGELOG0"].."\n\n"..L["CHANGELOG0"].."\n\n"..L["CHANGELOG0"]);

	local logHeight = DWP.ChangeLogDisplay.ChangeLogHeader:GetHeight() + DWP.ChangeLogDisplay.Notes:GetHeight() + DWP.ChangeLogDisplay.VerNumber:GetHeight() + DWP.ChangeLogDisplay.ChangeLogText:GetHeight();
	DWP.ChangeLogDisplay:SetSize(600, logHeight);  -- resize container

	if DWPlus_DB.defaults.HideChangeLogs < core.BuildNumber then
		DWPlus_DB.defaults.HideChangeLogs = core.BuildNumber;
		DWP.ChangeLogDisplay.DontShowCheck:SetChecked(true);
		DWP.ChangeLogDisplay:Show();
	end

	---------------------------------------
	-- VERSION IDENTIFIER
	---------------------------------------
	local c = DWP:GetThemeColor();
	DWP.UIConfig.Version = DWP.UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
	DWP.UIConfig.Version:ClearAllPoints();
	DWP.UIConfig.Version:SetFontObject("DWPSmallCenter");
	DWP.UIConfig.Version:SetScale("0.9")
	DWP.UIConfig.Version:SetTextColor(c[1].r, c[1].g, c[1].b, 0.5);
	DWP.UIConfig.Version:SetPoint("BOTTOMRIGHT", DWP.UIConfig.TitleBar, "BOTTOMRIGHT", -8, 4);
	DWP.UIConfig.Version:SetText(core.MonVersion);

	DWP.UIConfig:Hide(); -- hide menu after creation until called.
	DWP:FilterDKPTable(core.currentSort)   -- initial sort and populates data values in DKPTable.Rows{} DWP:FilterDKPTable() -> DWP:SortDKPTable() -> DKPTable_Update()
	core.Initialized = true
	
	return DWP.UIConfig;
end