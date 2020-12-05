local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local lootTable = {};

--local item1 = Item:CreateFromItemID(16862);
--local item2 = Item:CreateFromItemID(16963);
--local item3 = Item:CreateFromItemID(16961);
--item1:ContinueOnItemLoad(function()
--	table.insert(lootTable, {link = item1:GetItemLink(), icon = item1:GetItemIcon()})
--	C_Timer.After(2, function()
--		DWP:CurrItem_Set(item1:GetItemLink(), "", item1:GetItemIcon());
--	end)
--end)
--item2:ContinueOnItemLoad(function()
--	table.insert(lootTable, {link = item2:GetItemLink(), icon = item2:GetItemIcon()})
--end)
--item3:ContinueOnItemLoad(function()
--	table.insert(lootTable, {link = item3:GetItemLink(), icon = item3:GetItemIcon()})
--end)

	--[[["132744"] = "|cffa335ee|Hitem:12895::::::::60:::::|h[Breastplate of the Chromatic Flight]|h|r",
	["132585"] = "|cffa335ee|Hitem:16862::::::::60:::::|h[Sabatons of Might]|h|r",
	["133066"] = "|cffff8000|Hitem:17182::::::::60:::::|h[Sulfuras, Hand of Ragnaros]|h|r",
	["133173"] = "|cffa335ee|Hitem:16963::::::::60:::::|h[Helm of Wrath]|h|r",
	["135065"] = "|cffa335ee|Hitem:16961::::::::60:::::|h[Pauldrons of Wrath]|h|r",--]]

local width, height, numrows = 370, 18, 13
local Bids_Submitted = {};
local CurrItemForBid;

-- Broadcast should set LootTable_Set when loot is opened. Starting an auction will update through CurrItem_Set
-- When bid received it will be broadcasted and handled with Bids_Set(). If bid broadcasting is off, window will be reduced in size and scrollframe removed.

function DWP:LootTable_Set(lootList)
	lootTable = lootList
end

local function SortBidTable()
	local mode = DWPlus_DB.modes.mode;
	table.sort(Bids_Submitted, function(a, b)
	    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
	    	return a["bid"] > b["bid"]
	    elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
	    	return a["dkp"] > b["dkp"]
	    elseif mode == "Roll Based Bidding" then
	    	return a["roll"] > b["roll"]
	    end
  	end)
end

local function RollMinMax_Get()
	local search = DWP:Table_Search(DWPlus_RPTable, UnitName("player"))
	local minRoll;
	local maxRoll;

	if DWPlus_DB.modes.rolls.UsePerc then
		if DWPlus_DB.modes.rolls.min == 0 or DWPlus_DB.modes.rolls.min == 1 then
			minRoll = 1;
		else
			minRoll = DWPlus_RPTable[search[1][1]].dkp * (DWPlus_DB.modes.rolls.min / 100);
		end
		maxRoll = DWPlus_RPTable[search[1][1]].dkp * (DWPlus_DB.modes.rolls.max / 100) + DWPlus_DB.modes.rolls.AddToMax;
	elseif not DWPlus_DB.modes.rolls.UsePerc then
		minRoll = DWPlus_DB.modes.rolls.min;

		if DWPlus_DB.modes.rolls.max == 0 then
			maxRoll = DWPlus_RPTable[search[1][1]].dkp + DWPlus_DB.modes.rolls.AddToMax;
		else
			maxRoll = DWPlus_DB.modes.rolls.max + DWPlus_DB.modes.rolls.AddToMax;
		end
	end
	if tonumber(minRoll) < 1 then minRoll = 1 end
	if tonumber(maxRoll) < 1 then maxRoll = 1 end

	return minRoll, maxRoll;
end

local function UpdateBidderWindow()
	local i = 1;
	local haveItems = table.getn(lootTable) > 0;
	local mode = DWPlus_DB.modes.mode;
	local icon;
	local itemsHeight = 130;

	if CurrItemForBid then
		_,_,_,_,_,_,_,_,_,icon = GetItemInfo(CurrItemForBid)
	end

	if CurrItemForBid and not haveItems then
		table.insert(lootTable, {link = CurrItemForBid, icon = icon})
		UpdateBidderWindow();
		return;
	end

	if not core.BidInterface then
		core.BidInterface = core.BidInterface or DWP:BidInterface_Create()
	end

	for j=2, 10 do
		core.BidInterface.LootTableIcons[j]:Hide()
		core.BidInterface.LootTableButtons[j]:Hide();
	end
	core.BidInterface.lootContainer:SetSize(35, 35)

	for _,v in pairs(lootTable) do
		core.BidInterface.LootTableIcons[i]:SetTexture(tonumber(v.icon))
		core.BidInterface.LootTableIcons[i]:Show()
		core.BidInterface.LootTableButtons[i]:Show();
		core.BidInterface.LootTableButtons[i]:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
			GameTooltip:SetHyperlink(v.link)
		end)
		core.BidInterface.LootTableButtons[i]:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end)
		if tonumber(v.icon) == icon then
			ActionButton_ShowOverlayGlow(core.BidInterface.LootTableButtons[i])
		else
			ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
		end
		i = i+1
	end
	if haveItems then
		core.BidInterface.lootHeader:Show();
		core.BidInterface.lootContainer:SetSize(43*(i-1), 35)
		core.BidInterface.itemHeader:Show();
		core.BidInterface.item:SetText(CurrItemForBid)
		core.BidInterface.item:Show();
		core.BidInterface.Boss:SetText(DWPlus_DB.bossargs.LastKilledBoss)
		core.BidInterface.Boss:Show();
		core.BidInterface.MinBidHeader:SetPoint("TOP", core.BidInterface, "TOP", -160, -170);
	else
		itemsHeight = 0;
		core.BidInterface.lootHeader:Hide();
		core.BidInterface.lootContainer:SetSize(35, 35)
		core.BidInterface.itemHeader:Hide();
		core.BidInterface.item:Hide();
		core.BidInterface.Boss:Hide();
		core.BidInterface.MinBidHeader:SetPoint("TOP", core.BidInterface, "TOP", -160, -15);
	end

	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BidInterface.MinBidHeader:SetText(L["MINIMUMBID"]..":")
		core.BidInterface.SubmitBid:SetPoint("LEFT", core.BidInterface.Bid, "RIGHT", 8, 0)
		core.BidInterface.SubmitBid:SetText(L["SUBMITBID"])
		core.BidInterface.Bid:Show();
		core.BidInterface.CancelBid:Show();
		core.BidInterface.Pass:Show();
	elseif mode == "Roll Based Bidding" then
		core.BidInterface.MinBidHeader:SetText(L["ITEMCOST"]..":")
		core.BidInterface.MinBid:SetText(L["ROLL"])
		core.BidInterface.SubmitBid:SetPoint("LEFT", core.BidInterface.BidHeader, "RIGHT", 8, 0)
		core.BidInterface.SubmitBid:SetText(L["ROLL"])
		core.BidInterface.Bid:Hide();
		core.BidInterface.CancelBid:Hide();
		core.BidInterface.Pass:Hide();
	else
		core.BidInterface.MinBidHeader:SetText(L["ITEMCOST"]..":")
		core.BidInterface.SubmitBid:SetPoint("LEFT", core.BidInterface.BidHeader, "RIGHT", 8, 0)
		core.BidInterface.SubmitBid:SetText(L["SUBMITBID"])
		core.BidInterface.Bid:Hide();
		core.BidInterface.CancelBid:Show();
		core.BidInterface.Pass:Show();
	end

	if DWPlus_DB.modes.BroadcastBids and not core.BiddingWindow then
		core.BidInterface:SetHeight(itemsHeight + 374);
		core.BidInterface.bidTable:Show();
		for k, v in pairs(core.BidInterface.headerButtons) do
			v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
			if k == "player" then
				if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
					v:SetSize((width/2)-1, height)
					v:Show()
				elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
					v:SetSize((width*0.75)-1, height)
					v:Show()
				end
			else
				if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
					v:SetSize((width/4)-1, height)
					v:Show();
				elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
					if k == "bid" then
						v:Hide()
					else
						v:SetSize((width/4)-1, height)
						v:Show();
					end
				end

			end
		end

		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			core.BidInterface.headerButtons.bid.t:SetText(L["BID"]);
			core.BidInterface.headerButtons.bid.t:Show();
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
			core.BidInterface.headerButtons.bid.t:Hide();
		elseif mode == "Roll Based Bidding" then
			core.BidInterface.headerButtons.bid.t:SetText(L["PLAYERROLL"])
			core.BidInterface.headerButtons.bid.t:Show()
		end

		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			core.BidInterface.headerButtons.dkp.t:SetText(L["TOTALDKP"]);
			core.BidInterface.headerButtons.dkp.t:Show();
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
			core.BidInterface.headerButtons.dkp.t:SetText(L["DKP"]);
			core.BidInterface.headerButtons.dkp.t:Show()
		elseif mode == "Roll Based Bidding" then
			core.BidInterface.headerButtons.dkp.t:SetText(L["EXPECTEDROLL"])
			core.BidInterface.headerButtons.dkp.t:Show();
		end
	elseif not core.BiddingWindow then
		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and MonDKP_DB.modes.ZeroSumBidType == "Minimum Bid") then
			core.BidInterface:SetHeight(itemsHeight + 129);
		else
			core.BidInterface:SetHeight(itemsHeight + 101);
		end
	end

	if DWPlus_DB.modes.BroadcastBids then
		local pass, err = pcall(BidInterface_Update)

		if not pass then
			DWP:Print("|CFFFF0000"..err)
			core.DWPUI:SetShown(false)
			StaticPopupDialogs["SUGGEST_RELOAD"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					ReloadUI();
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("SUGGEST_RELOAD")
		end
	end

	if not DWPlus_DB.modes.BroadcastBids or core.BiddingWindow then
		core.BidInterface:SetHeight(itemsHeight + 101);
		core.BidInterface.bidTable:Hide();
	else
		core.BidInterface:SetHeight(itemsHeight + 374);
		core.BidInterface.bidTable:Show();
	end
end

function BidInterface_Update()
	local numOptions = #Bids_Submitted;
	local index, row
    local offset = FauxScrollFrame_GetOffset(core.BidInterface.bidTable) or 0
    local rank;
    local showRows = #Bids_Submitted

    if #Bids_Submitted > numrows then
    	showRows = numrows
    end

	if not core.BidInterface.bidTable:IsShown() then return end

    SortBidTable()
    for i=1, numrows do
    	row = core.BidInterface.bidTable.Rows[i]
    	row:Hide()
    end    
	if Bids_Submitted[1] and Bids_Submitted[1].bid and core.BidInterface.bidTable:IsShown() then
		core.BidInterface.Bid:SetNumber(Bids_Submitted[1].bid)
	end
    for i=1, showRows do
        row = core.BidInterface.bidTable.Rows[i]
        index = offset + i
        local dkp_total = DWP:Table_Search(DWPlus_RPTable, Bids_Submitted[i].player)
        local c
        if dkp_total then
        	c = DWP:GetCColors(DWPlus_RPTable[dkp_total[1][1]].class)
        else
        	local createProfile = DWP_Profile_Create(Bids_Submitted[i].player)

        	if createProfile then
	        	dkp_total = DWP:Table_Search(DWPlus_RPTable, Bids_Submitted[i].player)
	        	c = DWP:GetCColors(DWPlus_RPTable[dkp_total[1][1]].class)
	        else 			-- if unable to create profile, feeds grey color
	        	c = { r="aa", g="aa", b="aa"}
	        end
        end
        rank = DWP:GetGuildRank(Bids_Submitted[i].player)
        if Bids_Submitted[index] then
            row:Show()
            row.index = index
            row.Strings[1].rowCounter:SetText(index)
            row.Strings[1]:SetText(Bids_Submitted[i].player.." |cff666666("..rank..")|r")
            row.Strings[1]:SetTextColor(c.r, c.g, c.b, 1)
            if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
            	row.Strings[2]:SetText(Bids_Submitted[i].bid)
            	row.Strings[3]:SetText(DWP_round(DWPlus_RPTable[dkp_total[1][1]].dkp, DWPlus_DB.modes.rounding))
            elseif mode == "Roll Based Bidding" then
            	local minRoll;
            	local maxRoll;

            	if DWPlus_DB.modes.rolls.UsePerc then
            		if DWPlus_DB.modes.rolls.min == 0 or DWPlus_DB.modes.rolls.min == 1 then
            			minRoll = 1;
            		else
            			minRoll = DWPlus_RPTable[dkp_total[1][1]].dkp * (DWPlus_DB.modes.rolls.min / 100);
            		end
            		maxRoll = DWPlus_RPTable[dkp_total[1][1]].dkp * (DWPlus_DB.modes.rolls.max / 100) + DWPlus_DB.modes.rolls.AddToMax;
            	elseif not DWPlus_DB.modes.rolls.UsePerc then
            		minRoll = DWPlus_DB.modes.rolls.min;

            		if DWPlus_DB.modes.rolls.max == 0 then
            			maxRoll = DWPlus_RPTable[dkp_total[1][1]].dkp + DWPlus_DB.modes.rolls.AddToMax;
            		else
            			maxRoll = DWPlus_DB.modes.rolls.max + DWPlus_DB.modes.rolls.AddToMax;
            		end
            	end
            	if tonumber(minRoll) < 1 then minRoll = 1 end
            	if tonumber(maxRoll) < 1 then maxRoll = 1 end

            	row.Strings[2]:SetText(Bids_Submitted[i].roll..Bids_Submitted[i].range)
            	row.Strings[3]:SetText(math.floor(minRoll).."-"..math.floor(maxRoll))
            elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
            	row.Strings[3]:SetText(DWP_round(Bids_Submitted[i].dkp, DWPlus_DB.modes.rounding))
            end
        else
            row:Hide()
        end
    end
    FauxScrollFrame_Update(core.BidInterface.bidTable, numOptions, numrows, height, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function DWP:BidInterface_Toggle()
	core.BidInterface = core.BidInterface or DWP:BidInterface_Create()

	if DWPlus_DB.bidintpos then
		core.BidInterface:ClearAllPoints()
		local a = DWPlus_DB.bidintpos
		core.BidInterface:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	end

	if core.BidInterface:IsShown() then core.BidInterface:Hide(); end
	if DWP.BidTimer.OpenBid and DWP.BidTimer.OpenBid:IsShown() then DWP.BidTimer.OpenBid:Hide() end
	core.BidInterface:SetShown(true)
	UpdateBidderWindow();
end

local function BidWindowCreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.Strings = {}
    f:SetSize(width, height)
    f:SetHighlightTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");
    f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
    f:GetNormalTexture():SetAlpha(0.2)
    for i=1, 3 do
        f.Strings[i] = f:CreateFontString(nil, "OVERLAY");
        f.Strings[i]:SetTextColor(1, 1, 1, 1);
        if i==1 then 
        	f.Strings[i]:SetFontObject("DWPNormalLeft");
        else
        	f.Strings[i]:SetFontObject("DWPNormalCenter");
        end
    end

    f.Strings[1].rowCounter = f:CreateFontString(nil, "OVERLAY");
	f.Strings[1].rowCounter:SetFontObject("DWPSmallOutlineLeft")
	f.Strings[1].rowCounter:SetTextColor(1, 1, 1, 0.3);
	f.Strings[1].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);

    f.Strings[1]:SetWidth((width/2)-10)
    f.Strings[2]:SetWidth(width/4)
    f.Strings[3]:SetWidth(width/4)
    f.Strings[1]:SetPoint("LEFT", f, "LEFT", 20, 0)
    f.Strings[2]:SetPoint("LEFT", f.Strings[1], "RIGHT", -9, 0)
    f.Strings[3]:SetPoint("RIGHT", 0, 0)

    return f
end

function DWP:CurrItem_Set(item, value, icon, boss)
	CurrItemForBid = item;

	local foundItem = false;
	for _, bidItem in pairs(lootTable) do
		if (item == bidItem.link) then
			foundItem = true;
		end
	end

	if not foundItem then
		table.insert(lootTable, {link = item, icon = icon})
	end

	if boss then
		DWPlus_DB.bossargs.LastKilledBoss = boss;
	end

	UpdateBidderWindow()

	if not strfind(value, "%%") and not strfind(value, "RP") then
		core.BidInterface.MinBid:SetText(value.." RP");
	else
		core.BidInterface.MinBid:SetText(value);
	end

	if core.BidInterface.Bid:IsShown() then
		core.BidInterface.Bid:SetNumber(value);
	end

	if DWPlus_DB.modes.mode ~= "Roll Based Bidding" then
		core.BidInterface.SubmitBid:SetScript("OnClick", function()
			local message;

			if core.BidInterface.Bid:IsShown() then
				message = "!bid "..DWP_round(core.BidInterface.Bid:GetNumber(), DWPlus_DB.modes.rounding)
			else
				message = "!bid";
			end
			DWP.Sync:SendData("DWPBidder", tostring(message))
			core.BidInterface.Bid:ClearFocus();
		end)

		core.BidInterface.CancelBid:SetScript("OnClick", function()
			DWP.Sync:SendData("DWPBidder", "!bid cancel")
			core.BidInterface.Bid:ClearFocus();
		end)
	elseif DWPlus_DB.modes.mode == "Roll Based Bidding" then
		core.BidInterface.SubmitBid:SetScript("OnClick", function()
			local min, max = RollMinMax_Get()

			RandomRoll(min, max);
		end)
	end

	if not DWPlus_DB.modes.BroadcastBids or core.BidInProgress then
		core.BidInterface:SetHeight(231);
		core.BidInterface.bidTable:Hide();
	else
		core.BidInterface:SetHeight(504);
		core.BidInterface.bidTable:Show();
	end
end

function DWP:Bids_Set(entry)
	Bids_Submitted = entry;
	
	local pass, err = pcall(BidInterface_Update)

	if not pass then
		print(err)
		core.DWPUI:SetShown(false)
		StaticPopupDialogs["SUGGEST_RELOAD"] = {
			text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				ReloadUI();
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("SUGGEST_RELOAD")
	end
end

function DWP:BidInterface_Create()
	local f = CreateFrame("Frame", "DWP_BidderWindow", UIParent, "ShadowOverlaySmallTemplate");

	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 700, -200);
	f:SetSize(400, 504);
	f:SetClampedToScreen(true)
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing();
		local point, relativeTo, relativePoint ,xOff,yOff = f:GetPoint(1)
		if not DWPlus_DB.bidintpos then
			DWPlus_DB.bidintpos = {}
		end
		DWPlus_DB.bidintpos.point = point;
		DWPlus_DB.bidintpos.relativeTo = relativeTo;
		DWPlus_DB.bidintpos.relativePoint = relativePoint;
		DWPlus_DB.bidintpos.x = xOff;
		DWPlus_DB.bidintpos.y = yOff;
	end);
	f:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if DWP.UIConfig then DWP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	  -- Close Button
	f.closeContainer = CreateFrame("Frame", "DWPBidderWindowCloseButtonContainer", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)

	f.LootTableIcons = {}
	f.LootTableButtons = {}

	f.lootHeader = f:CreateFontString(nil, "OVERLAY")
	f.lootHeader:SetFontObject("DWPLargeRight");
	f.lootHeader:SetScale(0.7)
	f.lootHeader:SetPoint("TOP", f, "TOP", 0, -50);
	f.lootHeader:SetText(L["LOOTBANKED"]..":");

	f.lootContainer = CreateFrame("Frame", "DWPlus_LootContainer", UIParent);
	f.lootContainer:SetPoint("TOP", f, "TOP", 0, -58);
	f.lootContainer:SetSize(35, 35)

	f.Boss = f:CreateFontString(nil, "OVERLAY")
	f.Boss:SetFontObject("DWPLargeCenter")
	f.Boss:SetPoint("TOP", f, "TOP", 0, -10)

	for i=1, 10 do
		f.LootTableIcons[i] = f:CreateTexture(nil, "OVERLAY", nil);
		f.LootTableIcons[i]:SetColorTexture(0, 0, 0, 1)
		f.LootTableIcons[i]:SetSize(35, 35);
		f.LootTableIcons[i]:Hide();
		f.LootTableButtons[i] = CreateFrame("Button", "DWPBidderLootTableButton", f)
		f.LootTableButtons[i]:SetPoint("TOPLEFT", f.LootTableIcons[i], "TOPLEFT", 0, 0);
		f.LootTableButtons[i]:SetSize(35, 35);
		f.LootTableButtons[i]:Hide()

		if i==1 then
			f.LootTableIcons[i]:SetPoint("LEFT", f.lootContainer, "LEFT", 0, 0);
		else
			f.LootTableIcons[i]:SetPoint("LEFT", f.LootTableIcons[i-1], "RIGHT", 8, 0);
		end
	end

	f.itemHeader = f:CreateFontString(nil, "OVERLAY")
	f.itemHeader:SetFontObject("DWPLargeRight");
	f.itemHeader:SetScale(0.7)
	f.itemHeader:SetPoint("TOP", f, "TOP", -160, -135);
	f.itemHeader:SetText(L["BIDDINGITEM"]..":")

	f.item = f:CreateFontString(nil, "OVERLAY")
	f.item:SetFontObject("DWPNormalLeft");
	f.item:SetPoint("LEFT", f.itemHeader, "RIGHT", 5, 2);
	f.item:SetSize(200, 28)
	f.item:SetText(L["NONE"])

	f.MinBidHeader = f:CreateFontString(nil, "OVERLAY")
	f.MinBidHeader:SetFontObject("DWPLargeRight");
	f.MinBidHeader:SetScale(0.7)
	f.MinBidHeader:SetPoint("TOPRIGHT", f.itemHeader, "BOTTOMRIGHT", 0, -15);
	f.MinBidHeader:SetText(L["MINIMUMBID"]..":")

	f.MinBid = f:CreateFontString(nil, "OVERLAY")
	f.MinBid:SetFontObject("DWPNormalLeft");
	f.MinBid:SetPoint("LEFT", f.MinBidHeader, "RIGHT", 8, 0);
	f.MinBid:SetSize(200, 28)

    f.BidHeader = f:CreateFontString(nil, "OVERLAY")
	f.BidHeader:SetFontObject("DWPLargeRight");
	f.BidHeader:SetScale(0.7)
	f.BidHeader:SetText(L["BID"]..":")
	f.BidHeader:SetPoint("TOPRIGHT", f.MinBidHeader, "BOTTOMRIGHT", 0, -20);

	f.Bid = CreateFrame("EditBox", nil, f)
	f.Bid:SetPoint("LEFT", f.BidHeader, "RIGHT", 8, 0)   
    f.Bid:SetAutoFocus(false)
    f.Bid:SetMultiLine(false)
    f.Bid:SetSize(70, 28)
    f.Bid:SetBackdrop({
  	  bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    f.Bid:SetBackdropColor(0,0,0,0.6)
    f.Bid:SetBackdropBorderColor(1,1,1,0.6)
    f.Bid:SetMaxLetters(8)
    f.Bid:SetTextColor(1, 1, 1, 1)
    f.Bid:SetFontObject("DWPSmallRight")
    f.Bid:SetTextInsets(10, 10, 5, 5)
    f.Bid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)

    f.BidPlusOne = CreateFrame("Button", nil, f.Bid, "DWPlusButtonTemplate")
	f.BidPlusOne:SetPoint("TOPLEFT", f.Bid, "BOTTOMLEFT", 0, -2);
	f.BidPlusOne:SetSize(33,20)
	f.BidPlusOne:SetText("+1");
	f.BidPlusOne:GetFontString():SetTextColor(1, 1, 1, 1)
	f.BidPlusOne:SetNormalFontObject("DWPSmallCenter");
	f.BidPlusOne:SetHighlightFontObject("DWPSmallCenter");
	f.BidPlusOne:SetScript("OnClick", function()
		f.Bid:SetNumber(f.Bid:GetNumber() + 1);
	end)

	f.BidPlusFive = CreateFrame("Button", nil, f.Bid, "DWPlusButtonTemplate")
	f.BidPlusFive:SetPoint("TOPRIGHT", f.Bid, "BOTTOMRIGHT", 0, -2);
	f.BidPlusFive:SetSize(33,20)
	f.BidPlusFive:SetText("+5");
	f.BidPlusFive:GetFontString():SetTextColor(1, 1, 1, 1)
	f.BidPlusFive:SetNormalFontObject("DWPSmallCenter");
	f.BidPlusFive:SetHighlightFontObject("DWPSmallCenter");
	f.BidPlusFive:SetScript("OnClick", function()
		f.Bid:SetNumber(f.Bid:GetNumber() + 5);
	end)

	f.BidMax = CreateFrame("Button", nil, f.BidPlusFive, "DWPlusButtonTemplate")
	f.BidMax:SetPoint("TOPLEFT", f.BidPlusFive, "BOTTOMLEFT", 0, -2);
	f.BidMax:SetSize(33,20)
	f.BidMax:SetText("MAX");
	f.BidMax:GetFontString():SetTextColor(1, 1, 1, 1)
	f.BidMax:SetNormalFontObject("DWPSmallCenter");
	f.BidMax:SetHighlightFontObject("DWPSmallCenter");
	f.BidMax:SetScript("OnClick", function()
		local search = DWP:Table_Search(DWPlus_RPTable, UnitName("player"), "player")

		if search then
			f.Bid:SetNumber(DWPlus_RPTable[search[1][1]].dkp);
		else
			f.Bid:SetNumber(0);
		end
	end)

	f.BidHalf = CreateFrame("Button", nil, f.BidPlusOne, "DWPlusButtonTemplate")
	f.BidHalf:SetPoint("TOPLEFT", f.BidPlusOne, "BOTTOMLEFT", 0, -2);
	f.BidHalf:SetSize(33,20)
	f.BidHalf:SetText("HALF");
	f.BidHalf:GetFontString():SetTextColor(1, 1, 1, 1)
	f.BidHalf:SetNormalFontObject("DWPSmallCenter");
	f.BidHalf:SetHighlightFontObject("DWPSmallCenter");
	f.BidHalf:SetScript("OnClick", function()
		local search = DWP:Table_Search(DWPlus_RPTable, UnitName("player"), "player")

		if search then
			f.Bid:SetNumber(DWPlus_RPTable[search[1][1]].dkp/2);
		else
			f.Bid:SetNumber(0);
		end
	end)

    f.SubmitBid = CreateFrame("Button", nil, f, "DWPlusButtonTemplate")
	f.SubmitBid:SetPoint("LEFT", f.Bid, "RIGHT", 8, 0);
	f.SubmitBid:SetSize(90,25)
	f.SubmitBid:SetText(L["SUBMITBID"]);
	f.SubmitBid:GetFontString():SetTextColor(1, 1, 1, 1)
	f.SubmitBid:SetNormalFontObject("DWPSmallCenter");
	f.SubmitBid:SetHighlightFontObject("DWPSmallCenter");

	f.CancelBid = CreateFrame("Button", nil, f, "DWPlusButtonTemplate")
	f.CancelBid:SetPoint("LEFT", f.SubmitBid, "RIGHT", 8, 0);
	f.CancelBid:SetSize(90,25)
	f.CancelBid:SetText(L["CANCELBID"]);
	f.CancelBid:GetFontString():SetTextColor(1, 1, 1, 1)
	f.CancelBid:SetNormalFontObject("DWPSmallCenter");
	f.CancelBid:SetHighlightFontObject("DWPSmallCenter");
	f.CancelBid:SetScript("OnClick", function()
		--CancelBid()
		f.Bid:ClearFocus();
	end)

	f.Pass = CreateFrame("Button", nil, f, "DWPlusButtonTemplate")
	f.Pass:SetPoint("TOPLEFT", f.SubmitBid, "BOTTOM", 5, -5);
	f.Pass:SetSize(90,25)
	f.Pass:SetText(L["PASS"]);
	f.Pass:GetFontString():SetTextColor(1, 1, 1, 1)
	f.Pass:SetNormalFontObject("DWPSmallCenter");
	f.Pass:SetHighlightFontObject("DWPSmallCenter");
	f.Pass:SetScript("OnClick", function()
		f.Bid:ClearFocus();
		DWP.Sync:SendData("DWPBidder", "pass")
		core.BidInterface:Hide()
	end)

	if DWPlus_DB.defaults.AutoOpenBid == nil then
		DWPlus_DB.defaults.AutoOpenBid = true
	end

	f.AutoOpenCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.AutoOpenCheckbox:SetChecked(DWPlus_DB.defaults.AutoOpenBid)
	f.AutoOpenCheckbox:SetScale(0.6);
	f.AutoOpenCheckbox.text:SetText("|cff5151de"..L["AUTOOPEN"].."|r");
	f.AutoOpenCheckbox.text:SetScale(1.4);
	f.AutoOpenCheckbox.text:ClearAllPoints()
	f.AutoOpenCheckbox.text:SetPoint("RIGHT", f.AutoOpenCheckbox, "LEFT", -2, 0)
	f.AutoOpenCheckbox.text:SetFontObject("DWPSmallLeft")
	f.AutoOpenCheckbox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
	f.AutoOpenCheckbox:SetScript("OnClick", function(self)
		DWPlus_DB.defaults.AutoOpenBid = self:GetChecked()
	end)
	f.AutoOpenCheckbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.AutoOpenCheckbox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	--------------------------------------------------
	-- Bid Table
	--------------------------------------------------
    f.bidTable = CreateFrame("ScrollFrame", "DWP_BiderWindowTable", f, "FauxScrollFrameTemplate")
    f.bidTable:SetSize(width, height*numrows+3)
	f.bidTable:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	f.bidTable:SetBackdropColor(0,0,0,0.2)
	f.bidTable:SetBackdropBorderColor(1,1,1,0.4)
    f.bidTable.ScrollBar = FauxScrollFrame_GetChildFrames(f.bidTable)
    f.bidTable.ScrollBar:Hide()
    f.bidTable.Rows = {}
    for i=1, numrows do
        f.bidTable.Rows[i] = BidWindowCreateRow(f.bidTable, i)
        if i==1 then
        	f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable, "TOPLEFT", 0, -3)
        else	
        	f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable.Rows[i-1], "BOTTOMLEFT")
        end
    end
    f.bidTable:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, height, BidderScrollFrame_Update)
    end)

	---------------------------------------
	-- Header Buttons
	--------------------------------------- 
	f.headerButtons = {}
	mode = DWPlus_DB.modes.mode;

	f.BidTable_Headers = CreateFrame("Frame", "DWPBidderTableHeaders", f.bidTable)
	f.BidTable_Headers:SetSize(370, 22)
	f.BidTable_Headers:SetPoint("BOTTOMLEFT", f.bidTable, "TOPLEFT", 0, 1)
	f.BidTable_Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	f.BidTable_Headers:SetBackdropColor(0,0,0,0.8);
	f.BidTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
	f.bidTable:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
	f.BidTable_Headers:Show()

	f.headerButtons.player = CreateFrame("Button", "$ParentButtonPlayer", f.BidTable_Headers)
	f.headerButtons.bid = CreateFrame("Button", "$ParentButtonBid", f.BidTable_Headers)
	f.headerButtons.dkp = CreateFrame("Button", "$ParentSuttonDkp", f.BidTable_Headers)

	f.headerButtons.player:SetPoint("LEFT", f.BidTable_Headers, "LEFT", 2, 0)
	f.headerButtons.bid:SetPoint("LEFT", f.headerButtons.player, "RIGHT", 0, 0)
	f.headerButtons.dkp:SetPoint("RIGHT", f.BidTable_Headers, "RIGHT", -1, 0)

	f.headerButtons.player.t = f.headerButtons.player:CreateFontString(nil, "OVERLAY")
	f.headerButtons.player.t:SetFontObject("DWPNormalLeft")
	f.headerButtons.player.t:SetTextColor(1, 1, 1, 1);
	f.headerButtons.player.t:SetPoint("LEFT", f.headerButtons.player, "LEFT", 20, 0);
	f.headerButtons.player.t:SetText(L["PLAYER"]); 

	f.headerButtons.bid.t = f.headerButtons.bid:CreateFontString(nil, "OVERLAY")
	f.headerButtons.bid.t:SetFontObject("DWPNormal");
	f.headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
	f.headerButtons.bid.t:SetPoint("CENTER", f.headerButtons.bid, "CENTER", 0, 0);

	f.headerButtons.dkp.t = f.headerButtons.dkp:CreateFontString(nil, "OVERLAY")
	f.headerButtons.dkp.t:SetFontObject("DWPNormal")
	f.headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	f.headerButtons.dkp.t:SetPoint("CENTER", f.headerButtons.dkp, "CENTER", 0, 0);

	if not DWPlus_DB.modes.BroadcastBids then
		f.bidTable:Hide();
		f:SetHeight(231);
	end; 		--hides table if broadcasting is set to false.

	f:Hide();

	f:SetScript("OnHide", function ()
		if core.BiddingInProgress then
			DWP:Print(L["CLOSEDBIDINPROGRESS"])
		end
		if DWP.BidTimer:IsShown() then
			DWP.BidTimer.OpenBid:Show()
		end
	end)

	return f;
end

function DWP:ClearBidInterface()
	CurrItemForBid = nil;
	if core.BidInterface then
		core.BidInterface:Hide();
		if #core.BidInterface.LootTableButtons > 0 then
			for i=1, #core.BidInterface.LootTableButtons do
				ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
			end
		end
	end;
end