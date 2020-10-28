local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

function DWP:DKPModes_Main()
	local f = core.ModesWindow;

	f.DKPModesMain.ModeDescriptionHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.ModeDescriptionHeader:SetFontObject("DWPLargeLeft");
	f.DKPModesMain.ModeDescriptionHeader:SetWidth(400);
	f.DKPModesMain.ModeDescriptionHeader:SetPoint("TOPLEFT", f.DKPModesMain, "TOPLEFT", 30, -20);

	f.DKPModesMain.ModeDescription = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.ModeDescription:SetPoint("TOPLEFT", f.DKPModesMain, "TOPLEFT", 20, -45);
	f.DKPModesMain.ModeDescription:SetWidth(400);
	f.DKPModesMain.ModeDescription:SetFontObject("DWPSmallLeft")
	
	local MinBidDescription = L["MINBIDDESCRIPTION"]
	local StaticDescription = L["STATICDESCRIPTION"]
	local RollDescription = L["ROLLDESCRIPTION"]
	local ZeroSumDescription = L["ZEROSUMDESCRIPTION"];

	if DWPlus_DB.modes.mode == "Minimum Bid Values" then
		f.DKPModesMain.ModeDescriptionHeader:SetText(L["MINBIDVALUESHEAD"])
		f.DKPModesMain.ModeDescription:SetText(MinBidDescription)
	elseif DWPlus_DB.modes.mode == "Static Item Values" then
		f.DKPModesMain.ModeDescriptionHeader:SetText(L["STATICITEMVALUESHEAD"])
		f.DKPModesMain.ModeDescription:SetText(StaticDescription)
	elseif DWPlus_DB.modes.mode == "Roll Based Bidding" then
		f.DKPModesMain.ModeDescriptionHeader:SetText(L["ROLLBIDDINGHEAD"])
		f.DKPModesMain.ModeDescription:SetText(RollDescription)
	elseif DWPlus_DB.modes.mode == "Zero Sum" then
		f.DKPModesMain.ModeDescriptionHeader:SetText(L["ZEROSUMHEAD"])
		f.DKPModesMain.ModeDescription:SetText(ZeroSumDescription)
	end

	-- Mode DROPDOWN box 
	local CurMode = DWPlus_DB.modes.mode;
	local LocalMode;

	if CurMode == "Minimum Bid Values" then
		LocalMode = L["MINBIDVALUESHEAD"];
	elseif CurMode == "Static Item Values" then
		LocalMode = L["STATICITEMVALUESHEAD"]
	elseif CurMode == "Roll Based Bidding" then
		LocalMode = L["ROLLBIDDINGHEAD"]
	elseif CurMode == "Zero Sum" then
		LocalMode = L["ZEROSUMHEAD"]
	end


	f.DKPModesMain.ModesDropDown = CreateFrame("FRAME", "DWPModeSelectDropDown", f.DKPModesMain, "DWPlusUIDropDownMenuTemplate")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPModesMain.ModesDropDown, function(self, level, menuList)
	local DKPMode = UIDropDownMenu_CreateInfo()
		DKPMode.func = self.SetValue
		DKPMode.fontObject = "DWPSmallCenter"
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["MINBIDVALUESHEAD"], "Minimum Bid Values", "Minimum Bid Values" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["STATICITEMVALUESHEAD"], "Static Item Values", "Static Item Values" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ROLLBIDDINGHEAD"], "Roll Based Bidding", "Roll Based Bidding" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
		DKPMode.text, DKPMode.arg1, DKPMode.checked, DKPMode.isNotRadio = L["ZEROSUMHEAD"], "Zero Sum", "Zero Sum" == CurMode, false
		UIDropDownMenu_AddButton(DKPMode)
	end)

	f.DKPModesMain.ModesDropDown:SetPoint("TOPLEFT", f.DKPModesMain, "TOPLEFT", 10, -200)
	UIDropDownMenu_SetWidth(f.DKPModesMain.ModesDropDown, 150)
	UIDropDownMenu_SetText(f.DKPModesMain.ModesDropDown, LocalMode)

	-- Dropdown Menu Function
	function f.DKPModesMain.ModesDropDown:SetValue(newValue)
		if curMode ~= newValue then CurMode = newValue end

		f.DKPModesMain.ModeDescriptionHeader:SetText(newValue)
		
		if newValue == "Minimum Bid Values" then
			DWPlus_DB.modes.mode = "Minimum Bid Values";
			f.DKPModesMain.ModeDescription:SetText(MinBidDescription)
			f.DKPModesMain.ItemCostDropDown:Hide();
			f.DKPModesMain.ItemCostHeader:Hide();
			f.DKPModesMain.MaxBid:Show();
			f.DKPModesMain.MaxBid.Header:Show();
			DWPlus_DB.modes.costvalue = "Integer";
			UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
			f.DKPModesMain.SubZeroBidding:Show();
			f.DKPModesMain.SubZeroBidding:SetChecked(DWPlus_DB.modes.SubZeroBidding)
			if DWPlus_DB.modes.SubZeroBidding == true then
				f.DKPModesMain.AllowNegativeBidders:Show()
				f.DKPModesMain.AllowNegativeBidders:SetChecked(DWPlus_DB.modes.AllowNegativeBidders)
			end
			f.DKPModesMain.RollContainer:Hide();
			f.DKPModesMain.ZeroSumType:Hide();
			f.DKPModesMain.ZeroSumTypeHeader:Hide();
			f.DKPModesMain.CostSelection:Show();
			f.DKPModesMain.CostSelectionHeader:Show();
			f.DKPModesMain.Inflation:Hide()
    		f.DKPModesMain.Inflation.Header:Hide()
		elseif newValue == "Static Item Values" then
			DWPlus_DB.modes.mode = "Static Item Values"
			f.DKPModesMain.ModeDescription:SetText(StaticDescription)
			f.DKPModesMain.ItemCostHeader:Show();
			f.DKPModesMain.ItemCostDropDown:Show();
			f.DKPModesMain.RollContainer:Hide()
			f.DKPModesMain.MaxBid:Hide();
			f.DKPModesMain.MaxBid.Header:Hide();
			f.DKPModesMain.ZeroSumType:Hide()
			f.DKPModesMain.ZeroSumTypeHeader:Hide();
			f.DKPModesMain.CostSelection:Hide();
			f.DKPModesMain.CostSelectionHeader:Hide();
			f.DKPModesMain.Inflation:Hide()
    		f.DKPModesMain.Inflation.Header:Hide()

			if DWPlus_DB.modes.costvalue == "Integer" then
				f.DKPModesMain.SubZeroBidding:Show()
				f.DKPModesMain.SubZeroBidding:SetChecked(DWPlus_DB.modes.SubZeroBidding)
				if DWPlus_DB.modes.SubZeroBidding == true then
					f.DKPModesMain.AllowNegativeBidders:Show()
					f.DKPModesMain.AllowNegativeBidders:SetChecked(DWPlus_DB.modes.AllowNegativeBidders)
				end
				UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
			end
		elseif newValue == "Roll Based Bidding" then
			DWPlus_DB.modes.mode = "Roll Based Bidding"
			f.DKPModesMain.ItemCostHeader:Show();
			f.DKPModesMain.ItemCostDropDown:Show();
			f.DKPModesMain.ModeDescription:SetText(RollDescription)
			f.DKPModesMain.RollContainer:Show()
			f.DKPModesMain.MaxBid:Hide();
			f.DKPModesMain.MaxBid.Header:Hide();
			f.DKPModesMain.ZeroSumType:Hide()
			f.DKPModesMain.ZeroSumTypeHeader:Hide();
			f.DKPModesMain.CostSelection:Hide()
			f.DKPModesMain.CostSelectionHeader:Hide()
			f.DKPModesMain.Inflation:Hide()
    		f.DKPModesMain.Inflation.Header:Hide()

			if DWPlus_DB.modes.costvalue == "Integer" then
				f.DKPModesMain.SubZeroBidding:Show()
				f.DKPModesMain.SubZeroBidding:SetChecked(DWPlus_DB.modes.SubZeroBidding)
				if DWPlus_DB.modes.SubZeroBidding == true then
					f.DKPModesMain.AllowNegativeBidders:Show()
					f.DKPModesMain.AllowNegativeBidders:SetChecked(DWPlus_DB.modes.AllowNegativeBidders)
				end
				UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
			end
		elseif newValue == "Zero Sum" then
			DWPlus_DB.modes.mode = "Zero Sum"
			DWPlus_DB.modes.costvalue = "Integer"
			f.DKPModesMain.ModeDescription:SetText(ZeroSumDescription)
			f.DKPModesMain.SubZeroBidding:Hide()
			f.DKPModesMain.AllowNegativeBidders:Hide()
			f.DKPModesMain.RollContainer:Hide()
			f.DKPModesMain.ItemCostHeader:Hide();
			UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, "Integer")
			f.DKPModesMain.ItemCostDropDown:Hide();
			f.DKPModesMain.ZeroSumType:Show()
			f.DKPModesMain.ZeroSumTypeHeader:Show();
			DWPlus_DB.modes.SubZeroBidding = true
			f.DKPModesMain.Inflation:Show()
    		f.DKPModesMain.Inflation.Header:Show()

			if DWPlus_DB.modes.ZeroSumBidType == "Static" then
				f.DKPModesMain.MaxBid:Hide();
				f.DKPModesMain.MaxBid.Header:Hide();
				f.DKPModesMain.CostSelection:Hide()
				f.DKPModesMain.CostSelectionHeader:Hide()
			else
				f.DKPModesMain.MaxBid:Show()
				f.DKPModesMain.MaxBid.Header:Show();
				f.DKPModesMain.CostSelection:Show()
				f.DKPModesMain.CostSelectionHeader:Show()
				f.DKPModesMain.SubZeroBidding:Show()
				f.DKPModesMain.AllowNegativeBidders:Show()
			end
		end

		if CurMode == "Minimum Bid Values" then
			LocalMode = L["MINBIDVALUESHEAD"];
		elseif CurMode == "Static Item Values" then
			LocalMode = L["STATICITEMVALUESHEAD"]
		elseif CurMode == "Roll Based Bidding" then
			LocalMode = L["ROLLBIDDINGHEAD"]
		elseif CurMode == "Zero Sum" then
			LocalMode = L["ZEROSUMHEAD"]
		end

		UIDropDownMenu_SetText(f.DKPModesMain.ModesDropDown, LocalMode)
		CloseDropDownMenus()
	end

	f.DKPModesMain.ModesDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DKPMODESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.ModesDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPModesMain.ModeHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.ModeHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ModesDropDown, "TOPLEFT", 25, 0);
	f.DKPModesMain.ModeHeader:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.ModeHeader:SetText(L["DKPMODES"])

	-- Rounding DROPDOWN box 
	f.DKPModesMain.RoundDropDown = CreateFrame("FRAME", "DWPModeSelectDropDown", f.DKPModesMain, "DWPlusUIDropDownMenuTemplate")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPModesMain.RoundDropDown, function(self, level, menuList)
	local places = UIDropDownMenu_CreateInfo()
		places.func = self.SetValue
		places.fontObject = "DWPSmallCenter"
		places.text, places.arg1, places.checked, places.isNotRadio = 0, 0, 0 == DWPlus_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 1, 1, 1 == DWPlus_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 2, 2, 2 == DWPlus_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 3, 3, 3 == DWPlus_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
		places.text, places.arg1, places.checked, places.isNotRadio = 4, 4, 4 == DWPlus_DB.modes.rounding, false
		UIDropDownMenu_AddButton(places)
	end)

	f.DKPModesMain.RoundDropDown:SetPoint("TOPLEFT", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 0, -95)
	UIDropDownMenu_SetWidth(f.DKPModesMain.RoundDropDown, 80)
	UIDropDownMenu_SetText(f.DKPModesMain.RoundDropDown, DWPlus_DB.modes.rounding)

	-- Dropdown Menu Function
	function f.DKPModesMain.RoundDropDown:SetValue(newValue)
		DWPlus_DB.modes.rounding = newValue;
		UIDropDownMenu_SetText(f.DKPModesMain.RoundDropDown, newValue)
		CloseDropDownMenus()
	end

	f.DKPModesMain.RoundDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	f.DKPModesMain.RoundDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DKPROUNDING"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DKPROUNDINGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.DKPModesMain.RoundDropDown:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

	f.DKPModesMain.RoundHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.RoundHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.RoundDropDown, "TOPLEFT", 25, 0);
	f.DKPModesMain.RoundHeader:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.RoundHeader:SetText(L["DKPROUNDING"])

	-- AntiSnipe Option
	f.DKPModesMain.AntiSnipe = CreateFrame("EditBox", nil, f.DKPModesMain)
    f.DKPModesMain.AntiSnipe:SetAutoFocus(false)
    f.DKPModesMain.AntiSnipe:SetMultiLine(false)
    f.DKPModesMain.AntiSnipe:SetPoint("TOPLEFT", f.DKPModesMain.RoundDropDown, "BOTTOMLEFT", 18, -15)
    f.DKPModesMain.AntiSnipe:SetSize(100, 24)
    f.DKPModesMain.AntiSnipe:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPModesMain.AntiSnipe:SetBackdropColor(0,0,0,0.9)
    f.DKPModesMain.AntiSnipe:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPModesMain.AntiSnipe:SetMaxLetters(8)
    f.DKPModesMain.AntiSnipe:SetTextColor(1, 1, 1, 1)
    f.DKPModesMain.AntiSnipe:SetFontObject("DWPSmallRight")
    f.DKPModesMain.AntiSnipe:SetTextInsets(10, 15, 5, 5)
    f.DKPModesMain.AntiSnipe:SetText(DWPlus_DB.modes.AntiSnipe)
    f.DKPModesMain.AntiSnipe:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnKeyUp", function(self)    -- clears focus on esc
    	if f.DKPModesMain.AntiSnipe:GetText():match("%a+") then
    		f.DKPModesMain.AntiSnipe:SetNumber(f.DKPModesMain.AntiSnipe:GetNumber() or 0)
    		if f.DKPModesMain.AntiSnipe:GetText() == "0" then
    			f.DKPModesMain.AntiSnipe:HighlightText()
    		end
    	else
	    	DWPlus_DB.modes.AntiSnipe = f.DKPModesMain.AntiSnipe:GetNumber()
	    end
    end)
    f.DKPModesMain.AntiSnipe:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ANTISNIPE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ANTISNIPETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ANTISNIPETTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
    f.DKPModesMain.AntiSnipe:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    f.DKPModesMain.AntiSnipe.Header = f.DKPModesMain.AntiSnipe:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.AntiSnipe.Header:SetFontObject("DWPNormalLeft");
    f.DKPModesMain.AntiSnipe.Header:SetPoint("BOTTOMLEFT", f.DKPModesMain.AntiSnipe, "TOPLEFT", 0, 2);
    f.DKPModesMain.AntiSnipe.Header:SetText(L["ANTISNIPE"])

	-- Channels DROPDOWN box 
	f.DKPModesMain.ChannelsDropDown = CreateFrame("FRAME", "DWPModeSelectDropDown", f.DKPModesMain, "DWPlusUIDropDownMenuTemplate")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPModesMain.ChannelsDropDown, function(self, level, menuList)
	local OpenChannel = UIDropDownMenu_CreateInfo()
		OpenChannel.func = self.SetValue
		OpenChannel.fontObject = "DWPSmallCenter"
		OpenChannel.keepShownOnClick = true;
		OpenChannel.isNotRadio = true;
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["WHISPER"], "Whisper", true == DWPlus_DB.modes.channels.whisper
		UIDropDownMenu_AddButton(OpenChannel)
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["RAID"], "Raid", true == DWPlus_DB.modes.channels.raid
		UIDropDownMenu_AddButton(OpenChannel)
		OpenChannel.text, OpenChannel.arg1, OpenChannel.checked = L["GUILD"], "Guild", true == DWPlus_DB.modes.channels.guild
		UIDropDownMenu_AddButton(OpenChannel)
	end)

	f.DKPModesMain.ChannelsDropDown:SetPoint("LEFT", f.DKPModesMain.ModesDropDown, "RIGHT", 30, 0)
	UIDropDownMenu_SetWidth(f.DKPModesMain.ChannelsDropDown, 150)
	UIDropDownMenu_SetText(f.DKPModesMain.ChannelsDropDown, L["OPENCHANNELS"])

	-- Dropdown Menu Function
	function f.DKPModesMain.ChannelsDropDown:SetValue(arg1)
		if arg1 == "Whisper" then
			DWPlus_DB.modes.channels.whisper = not DWPlus_DB.modes.channels.whisper
		elseif arg1 == "Raid" then
			DWPlus_DB.modes.channels.raid = not DWPlus_DB.modes.channels.raid
		elseif arg1 == "Guild" then
			DWPlus_DB.modes.channels.guild = not DWPlus_DB.modes.channels.guild
		end

		UIDropDownMenu_SetText(f.DKPModesMain.ChannelsDropDown, "Open Channels")
		CloseDropDownMenus()
	end

	f.DKPModesMain.ChannelsDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["COMMANDCHANNELS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["COMMANDCHANNELSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.ChannelsDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPModesMain.ChannelsHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.ChannelsHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ChannelsDropDown, "TOPLEFT", 25, 0);
	f.DKPModesMain.ChannelsHeader:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.ChannelsHeader:SetText(L["COMMANDCHANNELS"])

	-- Cost Auto Update Value DROPDOWN box 
	if not DWPlus_DB.modes.CostSelection then DWPlus_DB.modes.CostSelection = "Second Bidder" end
	f.DKPModesMain.CostSelection = CreateFrame("FRAME", "DWPModeSelectDropDown", f.DKPModesMain, "DWPlusUIDropDownMenuTemplate")
	f.DKPModesMain.CostSelection:SetPoint("TOPLEFT", f.DKPModesMain.ChannelsDropDown, "BOTTOMLEFT", 0, -10)

	local LocalCostSel;

	if DWPlus_DB.modes.CostSelection == "First Bidder" then
		LocalCostSel = L["FIRSTBIDDER"]
	elseif DWPlus_DB.modes.CostSelection == "Second Bidder" then
		LocalCostSel = L["SECONDBIDDER"]
	end

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPModesMain.CostSelection, function(self, level, menuList)
	local CostSelect = UIDropDownMenu_CreateInfo()
		CostSelect.func = self.SetValue
		CostSelect.fontObject = "DWPSmallCenter"
		CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["FIRSTBIDDER"], "First Bidder", "First Bidder" == DWPlus_DB.modes.CostSelection, false
		UIDropDownMenu_AddButton(CostSelect)
		CostSelect.text, CostSelect.arg1, CostSelect.checked, CostSelect.isNotRadio = L["SECONDBIDDER"], "Second Bidder", "Second Bidder" == DWPlus_DB.modes.CostSelection, false
		UIDropDownMenu_AddButton(CostSelect)
	end)

	UIDropDownMenu_SetWidth(f.DKPModesMain.CostSelection, 150)
	UIDropDownMenu_SetText(f.DKPModesMain.CostSelection, LocalCostSel)

	-- Dropdown Menu Function
	function f.DKPModesMain.CostSelection:SetValue(arg1)
		DWPlus_DB.modes.CostSelection = arg1

		if arg1 == "First Bidder" then
			LocalCostSel = L["FIRSTBIDDER"]
		else
			LocalCostSel = L["SECONDBIDDER"]
		end

		UIDropDownMenu_SetText(f.DKPModesMain.CostSelection, LocalCostSel)
		CloseDropDownMenus()
	end

	f.DKPModesMain.CostSelection:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["COSTAUTOUPDATE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["COSTAUTOUPDATETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.CostSelection:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPModesMain.CostSelectionHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.CostSelectionHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.CostSelection, "TOPLEFT", 25, 0);
	f.DKPModesMain.CostSelectionHeader:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.CostSelectionHeader:SetText(L["COSTAUTOUPDATEVALUE"])

	if not (DWPlus_DB.modes.mode == "Minimum Bid Values" or (DWPlus_DB.modes.mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid")) then
		f.DKPModesMain.CostSelection:Hide()
		f.DKPModesMain.CostSelectionHeader:Hide();
	end

	-- Artificial Inflation Editbox
	if not DWPlus_DB.modes.Inflation then DWPlus_DB.modes.Inflation = 0 end
	f.DKPModesMain.Inflation = CreateFrame("EditBox", nil, f.DKPModesMain)
    f.DKPModesMain.Inflation:SetAutoFocus(false)
    f.DKPModesMain.Inflation:SetMultiLine(false)
    f.DKPModesMain.Inflation:SetPoint("TOPLEFT", f.DKPModesMain.CostSelection, "BOTTOMLEFT", 20, -15)
    f.DKPModesMain.Inflation:SetSize(100, 24)
    f.DKPModesMain.Inflation:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPModesMain.Inflation:SetBackdropColor(0,0,0,0.9)
    f.DKPModesMain.Inflation:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPModesMain.Inflation:SetMaxLetters(8)
    f.DKPModesMain.Inflation:SetTextColor(1, 1, 1, 1)
    f.DKPModesMain.Inflation:SetFontObject("DWPSmallRight")
    f.DKPModesMain.Inflation:SetTextInsets(10, 15, 5, 5)
    f.DKPModesMain.Inflation:SetText(DWPlus_DB.modes.Inflation)
    f.DKPModesMain.Inflation:Hide();
    f.DKPModesMain.Inflation:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.Inflation = f.DKPModesMain.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.Inflation:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.Inflation = f.DKPModesMain.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.Inflation:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.Inflation = f.DKPModesMain.Inflation:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.Inflation:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ARTIFICIALINFLATION"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ARTINFLATTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.DKPModesMain.Inflation:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    -- Min Roll Header
    f.DKPModesMain.Inflation.Header = f.DKPModesMain.Inflation:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.Inflation.Header:SetFontObject("DWPNormalLeft");
    f.DKPModesMain.Inflation.Header:SetPoint("BOTTOM", f.DKPModesMain.Inflation, "TOP", -20, 2);
    f.DKPModesMain.Inflation.Header:SetText(L["INFLATION"])

    if DWPlus_DB.modes.mode == "Zero Sum" then
    	f.DKPModesMain.Inflation:Show()
    	f.DKPModesMain.Inflation.Header:Show()
    end

    -- ZeroSum Type DROPDOWN box 
	f.DKPModesMain.ZeroSumType = CreateFrame("FRAME", "DWPModeSelectDropDown", f.DKPModesMain, "DWPlusUIDropDownMenuTemplate")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPModesMain.ZeroSumType, function(self, level, menuList)
	local BidType = UIDropDownMenu_CreateInfo()
		BidType.func = self.SetValue
		BidType.fontObject = "DWPSmallCenter"
		BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["STATIC"], "Static", "Static" == DWPlus_DB.modes.ZeroSumBidType, false
		UIDropDownMenu_AddButton(BidType)
		BidType.text, BidType.arg1, BidType.checked, BidType.isNotRadio = L["MINIMUMBID"], "Minimum Bid", "Minimum Bid" == DWPlus_DB.modes.ZeroSumBidType, false
		UIDropDownMenu_AddButton(BidType)
	end)

	f.DKPModesMain.ZeroSumType:SetPoint("TOPLEFT", f.DKPModesMain.Inflation, "BOTTOMLEFT", -20, -20)
	UIDropDownMenu_SetWidth(f.DKPModesMain.ZeroSumType, 150)
	UIDropDownMenu_SetText(f.DKPModesMain.ZeroSumType, DWPlus_DB.modes.ZeroSumBidType)

	-- Dropdown Menu Function
	function f.DKPModesMain.ZeroSumType:SetValue(newValue)
		DWPlus_DB.modes.ZeroSumBidType = newValue;
		if newValue == "Static" then
			f.DKPModesMain.MaxBid:Hide();
			f.DKPModesMain.MaxBid.Header:Hide();
			f.DKPModesMain.CostSelection:Hide();
			f.DKPModesMain.CostSelectionHeader:Hide();
			newValue = L["STATIC"]
			f.DKPModesMain.SubZeroBidding:Hide()
			f.DKPModesMain.AllowNegativeBidders:Hide()
		else
			f.DKPModesMain.MaxBid:Show();
			f.DKPModesMain.MaxBid.Header:Show();
			f.DKPModesMain.CostSelection:Show();
			f.DKPModesMain.CostSelectionHeader:Show();
			newValue = L["MINIMUMBID"]
			f.DKPModesMain.SubZeroBidding:Show()
			f.DKPModesMain.AllowNegativeBidders:Show()
		end

		UIDropDownMenu_SetText(f.DKPModesMain.ZeroSumType, newValue)
		CloseDropDownMenus()
	end

	f.DKPModesMain.ZeroSumType:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ZEROSUMITEMCOST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ZEROSUMITEMCOSTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.ZeroSumType:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPModesMain.ZeroSumTypeHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.ZeroSumTypeHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ZeroSumType, "TOPLEFT", 25, 0);
	f.DKPModesMain.ZeroSumTypeHeader:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.ZeroSumTypeHeader:SetText(L["BIDMETHOD"])

	if DWPlus_DB.modes.mode ~= "Zero Sum" then
		f.DKPModesMain.ZeroSumType:Hide()
		f.DKPModesMain.ZeroSumTypeHeader:Hide();
	end

	-- Item Cost Value DROPDOWN box 
	f.DKPModesMain.ItemCostDropDown = CreateFrame("FRAME", "DWPModeSelectDropDown", f.DKPModesMain, "DWPlusUIDropDownMenuTemplate")

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(f.DKPModesMain.ItemCostDropDown, function(self, level, menuList)
	local CostValue = UIDropDownMenu_CreateInfo()
		CostValue.func = self.SetValue
		CostValue.fontObject = "DWPSmallCenter"
		CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["INTEGER"], "Integer", "Integer" == DWPlus_DB.modes.costvalue, false
		UIDropDownMenu_AddButton(CostValue)
		CostValue.text, CostValue.arg1, CostValue.checked, CostValue.isNotRadio = L["PERCENT"], "Percent", "Percent" == DWPlus_DB.modes.costvalue, false
		UIDropDownMenu_AddButton(CostValue)
	end)
	
	f.DKPModesMain.ItemCostDropDown:SetPoint("TOPLEFT", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 0, -50)
	UIDropDownMenu_SetWidth(f.DKPModesMain.ItemCostDropDown, 150)
	UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L[DWPlus_DB.modes.costvalue])

	-- Dropdown Menu Function
	function f.DKPModesMain.ItemCostDropDown:SetValue(arg1)
		if arg1 == "Integer" then
			DWPlus_DB.modes.costvalue = "Integer"
			f.DKPModesMain.SubZeroBidding:Show()
			f.DKPModesMain.SubZeroBidding:SetChecked(DWPlus_DB.modes.SubZeroBidding)
			if DWPlus_DB.modes.SubZeroBidding == true then
				f.DKPModesMain.AllowNegativeBidders:Show()
				f.DKPModesMain.AllowNegativeBidders:SetChecked(DWPlus_DB.modes.AllowNegativeBidders)
			end
		elseif arg1 == "Percent" then
			DWPlus_DB.modes.costvalue = "Percent"
			f.DKPModesMain.SubZeroBidding:Hide()
			f.DKPModesMain.AllowNegativeBidders:Hide()
			DWPlus_DB.modes.SubZeroBidding = false;
			f.DKPModesMain.SubZeroBidding:SetChecked(false)
		end

		UIDropDownMenu_SetText(f.DKPModesMain.ItemCostDropDown, L[arg1])
		CloseDropDownMenus()
	end

	f.DKPModesMain.ItemCostDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ITEMCOSTTYPES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ITEMCOSTTYPESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.ItemCostDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.DKPModesMain.ItemCostHeader = f.DKPModesMain:CreateFontString(nil, "OVERLAY")
	f.DKPModesMain.ItemCostHeader:SetPoint("BOTTOMLEFT", f.DKPModesMain.ItemCostDropDown, "TOPLEFT", 25, 0);
	f.DKPModesMain.ItemCostHeader:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.ItemCostHeader:SetText(L["ITEMCOSTTYPES"])

	if DWPlus_DB.modes.mode == "Minimum Bid Values" then
		f.DKPModesMain.ItemCostDropDown:Hide();
		f.DKPModesMain.ItemCostHeader:Hide();
		DWPlus_DB.modes.costvalue = "Integer";
	elseif DWPlus_DB.modes.mode == "Zero Sum" then
		f.DKPModesMain.ItemCostDropDown:Hide();
		f.DKPModesMain.ItemCostHeader:Hide();
		DWPlus_DB.modes.costvalue = "Integer";
	end


	-- Min Roll Editbox
	if not DWPlus_DB.modes.MaximumBid then DWPlus_DB.modes.MaximumBid = 0 end
	f.DKPModesMain.MaxBid = CreateFrame("EditBox", nil, f.DKPModesMain)
    f.DKPModesMain.MaxBid:SetAutoFocus(false)
    f.DKPModesMain.MaxBid:SetMultiLine(false)
    f.DKPModesMain.MaxBid:SetPoint("TOPLEFT", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 18, -55)
    f.DKPModesMain.MaxBid:SetSize(100, 24)
    f.DKPModesMain.MaxBid:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.DKPModesMain.MaxBid:SetBackdropColor(0,0,0,0.9)
    f.DKPModesMain.MaxBid:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    f.DKPModesMain.MaxBid:SetMaxLetters(8)
    f.DKPModesMain.MaxBid:SetTextColor(1, 1, 1, 1)
    f.DKPModesMain.MaxBid:SetFontObject("DWPSmallRight")
    f.DKPModesMain.MaxBid:SetTextInsets(10, 15, 5, 5)
    f.DKPModesMain.MaxBid:SetText(DWPlus_DB.modes.MaximumBid)
    f.DKPModesMain.MaxBid:Hide();
    f.DKPModesMain.MaxBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.MaximumBid = f.DKPModesMain.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.MaxBid:SetScript("OnTabPressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.MaximumBid = f.DKPModesMain.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.MaxBid:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    	DWPlus_DB.modes.MaximumBid = f.DKPModesMain.MaxBid:GetNumber()
    	self:ClearFocus()
    end)
    f.DKPModesMain.MaxBid:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["MAXIMUMBID"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["MAXIMUMBIDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
    f.DKPModesMain.MaxBid:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
    f.DKPModesMain.MaxBid:SetScript("OnKeyUp", function(self)    -- clears focus on esc
    	if self:GetText():match("%a+") then
    		self:SetNumber(self:GetNumber() or 0)
    		if self:GetText() == "0" then
    			self:HighlightText()
    		end
    	else
	    	DWPlus_DB.modes.MaximumBid = f.DKPModesMain.MaxBid:GetNumber()
	    end
    end)

    -- Min Roll Header
    f.DKPModesMain.MaxBid.Header = f.DKPModesMain.MaxBid:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.MaxBid.Header:SetFontObject("DWPNormalLeft");
    f.DKPModesMain.MaxBid.Header:SetPoint("BOTTOM", f.DKPModesMain.MaxBid, "TOP", -8, 2);
    f.DKPModesMain.MaxBid.Header:SetText(L["MAXIMUMBID"])


    if DWPlus_DB.modes.mode == "Minimum Bid Values" or (DWPlus_DB.modes.mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
		f.DKPModesMain.MaxBid:Show();
		f.DKPModesMain.MaxBid.Header:Show();
	end

	-- Sub Zero Bidding Checkbox
	f.DKPModesMain.SubZeroBidding = CreateFrame("CheckButton", nil, f.DKPModesMain, "UICheckButtonTemplate");
	f.DKPModesMain.SubZeroBidding:SetChecked(DWPlus_DB.modes.SubZeroBidding)
	f.DKPModesMain.SubZeroBidding:SetScale(0.6);
	f.DKPModesMain.SubZeroBidding.text:SetText("  |cff5151de"..L["SUBZEROBIDDING"].."|r");
	f.DKPModesMain.SubZeroBidding.text:SetScale(1.5);
	f.DKPModesMain.SubZeroBidding.text:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.SubZeroBidding:SetPoint("TOP", f.DKPModesMain.ModesDropDown, "BOTTOMLEFT", 60, 0);
	f.DKPModesMain.SubZeroBidding:SetScript("OnClick", function(self)
		if self:GetChecked() == true then
			DWPlus_DB.modes.SubZeroBidding = true;
			DWP:Print("Sub Zero Bidding |cff00ff00"..L["ENABLED"].."|r")
			f.DKPModesMain.AllowNegativeBidders:Show()
			f.DKPModesMain.AllowNegativeBidders:SetChecked(DWPlus_DB.modes.AllowNegativeBidders)
		else
			DWPlus_DB.modes.SubZeroBidding = false;
			DWP:Print("Sub Zero Bidding |cffff0000"..L["DISABLED"].."|r")
			DWPlus_DB.modes.AllowNegativeBidders = false
			f.DKPModesMain.AllowNegativeBidders:Hide()
		end
		PlaySound(808);
	end)
	f.DKPModesMain.SubZeroBidding:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SUBZEROBIDDING"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SUBZEROBIDDINGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.SubZeroBidding:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	if DWPlus_DB.modes.costvalue == "Percent" or (DWPlus_DB.modes.mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
		f.DKPModesMain.SubZeroBidding:Hide()
	end
	
	-- Allow Bids below zero Checkbox
	f.DKPModesMain.AllowNegativeBidders = CreateFrame("CheckButton", nil, f.DKPModesMain, "UICheckButtonTemplate");
	f.DKPModesMain.AllowNegativeBidders:SetChecked(DWPlus_DB.modes.AllowNegativeBidders)
	f.DKPModesMain.AllowNegativeBidders:SetScale(0.6);
	f.DKPModesMain.AllowNegativeBidders.text:SetText("  |cff5151de"..L["ALLOWNEGATIVEBIDDERS"].."|r");
	f.DKPModesMain.AllowNegativeBidders.text:SetScale(1.5);
	f.DKPModesMain.AllowNegativeBidders.text:SetFontObject("DWPSmallLeft")
	f.DKPModesMain.AllowNegativeBidders:SetPoint("TOPLEFT", f.DKPModesMain.SubZeroBidding, "BOTTOMLEFT", 0, 0);
	f.DKPModesMain.AllowNegativeBidders:SetScript("OnClick", function(self)
		if self:GetChecked() == true then
			DWPlus_DB.modes.AllowNegativeBidders = true;
			DWP:Print("Allow Negative Bidders |cff00ff00"..L["ENABLED"].."|r")
		else
			DWPlus_DB.modes.AllowNegativeBidders = false;
			DWP:Print("Allow Negative Bidders |cffff0000"..L["DISABLED"].."|r")
		end
		PlaySound(808);
	end)
	f.DKPModesMain.AllowNegativeBidders:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ALLOWNEGATIVEBIDDERS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ALLOWNEGATIVEBIDTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.DKPModesMain.AllowNegativeBidders:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	if (DWPlus_DB.modes.costvalue == "Percent" or (DWPlus_DB.modes.mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static")) or DWPlus_DB.modes.SubZeroBidding == false then
		f.DKPModesMain.AllowNegativeBidders:Hide()
	end


	-- Roll Container
	f.DKPModesMain.RollContainer = CreateFrame("Frame", nil, f.DKPModesMain);
	f.DKPModesMain.RollContainer:SetSize(210, 150);
	f.DKPModesMain.RollContainer:SetPoint("TOPLEFT", f.DKPModesMain.ChannelsDropDown, "BOTTOMLEFT", -10, -20)
	f.DKPModesMain.RollContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
    });
	f.DKPModesMain.RollContainer:SetBackdropColor(0,0,0,0.9)
	f.DKPModesMain.RollContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	f.DKPModesMain.RollContainer:Hide();
    if DWPlus_DB.modes.mode == "Roll Based Bidding" then
    	f.DKPModesMain.RollContainer:Show()
    end

	-- Roll Container Header
    f.DKPModesMain.RollContainer.Header = f.DKPModesMain.RollContainer:CreateFontString(nil, "OVERLAY")
    f.DKPModesMain.RollContainer.Header:SetFontObject("DWPLargeLeft");
    f.DKPModesMain.RollContainer.Header:SetScale(0.6)
    f.DKPModesMain.RollContainer.Header:SetPoint("TOPLEFT", f.DKPModesMain.RollContainer, "TOPLEFT", 15, -15);
    f.DKPModesMain.RollContainer.Header:SetText(L["ROLLSETTINGS"])


		-- Min Roll Editbox
		f.DKPModesMain.RollContainer.rollMin = CreateFrame("EditBox", nil, f.DKPModesMain.RollContainer)
	    f.DKPModesMain.RollContainer.rollMin:SetAutoFocus(false)
	    f.DKPModesMain.RollContainer.rollMin:SetMultiLine(false)
	    f.DKPModesMain.RollContainer.rollMin:SetPoint("TOPLEFT", f.DKPModesMain.RollContainer, "TOPLEFT", 20, -50)
	    f.DKPModesMain.RollContainer.rollMin:SetSize(70, 24)
	    f.DKPModesMain.RollContainer.rollMin:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.DKPModesMain.RollContainer.rollMin:SetBackdropColor(0,0,0,0.9)
	    f.DKPModesMain.RollContainer.rollMin:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.DKPModesMain.RollContainer.rollMin:SetMaxLetters(6)
	    f.DKPModesMain.RollContainer.rollMin:SetTextColor(1, 1, 1, 1)
	    f.DKPModesMain.RollContainer.rollMin:SetFontObject("DWPSmallRight")
	    f.DKPModesMain.RollContainer.rollMin:SetTextInsets(10, 15, 5, 5)
	    f.DKPModesMain.RollContainer.rollMin:SetText(DWPlus_DB.modes.rolls.min)
	    f.DKPModesMain.RollContainer.rollMin:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	    	self:ClearFocus()
	    end)
	    f.DKPModesMain.RollContainer.rollMin:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	      	f.DKPModesMain.RollContainer.rollMax:SetFocus()
	    end)
	    f.DKPModesMain.RollContainer.rollMin:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	    	self:ClearFocus()
	    end)
	    f.DKPModesMain.RollContainer.rollMin:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MINIMUMROLL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MINIMUMROLLTTDESC"], 1.0, 1.0, 1.0, true);
			--GameTooltip:AddLine("The state of this option will persist indefinitely until manually disabled/enabled.", 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.DKPModesMain.RollContainer.rollMin:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Min Roll Header
	    f.DKPModesMain.RollContainer.rollMin.Header = f.DKPModesMain.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
	    f.DKPModesMain.RollContainer.rollMin.Header:SetFontObject("DWPNormalLeft");
	    f.DKPModesMain.RollContainer.rollMin.Header:SetPoint("BOTTOM", f.DKPModesMain.RollContainer.rollMin, "TOP", -20, 2);
	    f.DKPModesMain.RollContainer.rollMin.Header:SetText(L["MIN"])

	    -- Dash Between Rolls
	    f.DKPModesMain.RollContainer.dash = f.DKPModesMain.RollContainer:CreateFontString(nil, "OVERLAY")
	    f.DKPModesMain.RollContainer.dash:SetFontObject("DWPLargeLeft");
	    f.DKPModesMain.RollContainer.dash:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMin, "RIGHT", 9, 0);
	    f.DKPModesMain.RollContainer.dash:SetText("-")

	    -- Max Roll Editbox
		f.DKPModesMain.RollContainer.rollMax = CreateFrame("EditBox", nil, f.DKPModesMain.RollContainer)
	    f.DKPModesMain.RollContainer.rollMax:SetAutoFocus(false)
	    f.DKPModesMain.RollContainer.rollMax:SetMultiLine(false)
	    f.DKPModesMain.RollContainer.rollMax:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMin, "RIGHT", 24, 0)
	    f.DKPModesMain.RollContainer.rollMax:SetSize(70, 24)
	    f.DKPModesMain.RollContainer.rollMax:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.DKPModesMain.RollContainer.rollMax:SetBackdropColor(0,0,0,0.9)
	    f.DKPModesMain.RollContainer.rollMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.DKPModesMain.RollContainer.rollMax:SetMaxLetters(6)
	    f.DKPModesMain.RollContainer.rollMax:SetTextColor(1, 1, 1, 1)
	    f.DKPModesMain.RollContainer.rollMax:SetFontObject("DWPSmallRight")
	    f.DKPModesMain.RollContainer.rollMax:SetTextInsets(10, 15, 5, 5)
	    f.DKPModesMain.RollContainer.rollMax:SetText(DWPlus_DB.modes.rolls.max)
	    f.DKPModesMain.RollContainer.rollMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	    	self:ClearFocus()
	    end)
	    f.DKPModesMain.RollContainer.rollMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	      	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	    	f.DKPModesMain.RollContainer.AddMax:SetFocus()
	    end)
	    f.DKPModesMain.RollContainer.rollMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	    	self:ClearFocus()
	    end)
	    f.DKPModesMain.RollContainer.rollMax:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MAXIMUMROLL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["MAXIMUMROLLTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["MAXIMUMROLLTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.DKPModesMain.RollContainer.rollMax:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Max Roll Header
	    f.DKPModesMain.RollContainer.rollMax.Header = f.DKPModesMain.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
	    f.DKPModesMain.RollContainer.rollMax.Header:SetFontObject("DWPNormalLeft");
	    f.DKPModesMain.RollContainer.rollMax.Header:SetPoint("BOTTOM", f.DKPModesMain.RollContainer.rollMax, "TOP", -20, 2);
	    f.DKPModesMain.RollContainer.rollMax.Header:SetText(L["MAX"])

		f.DKPModesMain.RollContainer.rollMin.perc = f.DKPModesMain.RollContainer.rollMin:CreateFontString(nil, "OVERLAY")
		f.DKPModesMain.RollContainer.rollMin.perc:SetFontObject("DWPSmallLeft");
		f.DKPModesMain.RollContainer.rollMin.perc:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMin, "RIGHT", -15, 0);
		f.DKPModesMain.RollContainer.rollMin.perc:SetText("%")
		f.DKPModesMain.RollContainer.rollMin.perc:SetShown(DWPlus_DB.modes.rolls.UsePerc);

		f.DKPModesMain.RollContainer.rollMax.perc = f.DKPModesMain.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
		f.DKPModesMain.RollContainer.rollMax.perc:SetFontObject("DWPSmallLeft");
		f.DKPModesMain.RollContainer.rollMax.perc:SetPoint("LEFT", f.DKPModesMain.RollContainer.rollMax, "RIGHT", -15, 0);
		f.DKPModesMain.RollContainer.rollMax.perc:SetText("%")
		f.DKPModesMain.RollContainer.rollMax.perc:SetShown(DWPlus_DB.modes.rolls.UsePerc);

	    -- Percent Rolls Checkbox
		f.DKPModesMain.RollContainer.UsePerc = CreateFrame("CheckButton", nil, f.DKPModesMain.RollContainer, "UICheckButtonTemplate");
		f.DKPModesMain.RollContainer.UsePerc:SetChecked(DWPlus_DB.modes.rolls.UsePerc)
		f.DKPModesMain.RollContainer.UsePerc:SetScale(0.6);
		f.DKPModesMain.RollContainer.UsePerc.text:SetText("  |cff5151de"..L["USEPERCENTAGE"].."|r");
		f.DKPModesMain.RollContainer.UsePerc.text:SetScale(1.5);
		f.DKPModesMain.RollContainer.UsePerc.text:SetFontObject("DWPSmallLeft")
		f.DKPModesMain.RollContainer.UsePerc:SetPoint("TOP", f.DKPModesMain.RollContainer.rollMin, "BOTTOMLEFT", 0, -10);
		f.DKPModesMain.RollContainer.UsePerc:SetScript("OnClick", function(self)
			DWPlus_DB.modes.rolls.UsePerc = self:GetChecked();
			f.DKPModesMain.RollContainer.rollMin.perc:SetShown(self:GetChecked())
			f.DKPModesMain.RollContainer.rollMax.perc:SetShown(self:GetChecked())
			if f.DKPModesMain.RollContainer.rollMax:GetNumber() == 0 then
				f.DKPModesMain.RollContainer.rollMax:SetNumber(100)
			end
			PlaySound(808);
		end)
		f.DKPModesMain.RollContainer.UsePerc:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			GameTooltip:SetText(L["USEPERCFORROLLS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["USEPERCROLLSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["USEPERCROLLSTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.DKPModesMain.RollContainer.UsePerc:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

    	-- Add to Max Editbox
		f.DKPModesMain.RollContainer.AddMax = CreateFrame("EditBox", nil, f.DKPModesMain.RollContainer)
	    f.DKPModesMain.RollContainer.AddMax:SetAutoFocus(false)
	    f.DKPModesMain.RollContainer.AddMax:SetMultiLine(false)
	    f.DKPModesMain.RollContainer.AddMax:SetPoint("TOP", f.DKPModesMain.RollContainer.rollMax, "BOTTOM", 0, -30)
	    f.DKPModesMain.RollContainer.AddMax:SetSize(70, 24)
	    f.DKPModesMain.RollContainer.AddMax:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 1, edgeSize = 2, 
	    });
	    f.DKPModesMain.RollContainer.AddMax:SetBackdropColor(0,0,0,0.9)
	    f.DKPModesMain.RollContainer.AddMax:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	    f.DKPModesMain.RollContainer.AddMax:SetMaxLetters(6)
	    f.DKPModesMain.RollContainer.AddMax:SetTextColor(1, 1, 1, 1)
	    f.DKPModesMain.RollContainer.AddMax:SetFontObject("DWPSmallRight")
	    f.DKPModesMain.RollContainer.AddMax:SetTextInsets(10, 15, 5, 5)
	    f.DKPModesMain.RollContainer.AddMax:SetText(DWPlus_DB.modes.rolls.AddToMax)
	    f.DKPModesMain.RollContainer.AddMax:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	      	self:ClearFocus()
	    end)
	    f.DKPModesMain.RollContainer.AddMax:SetScript("OnTabPressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	      	f.DKPModesMain.RollContainer.rollMin:SetFocus()
	    end)
	    f.DKPModesMain.RollContainer.AddMax:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
	    	DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
			DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
			DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()
	      	self:ClearFocus()
	    end)
	    f.DKPModesMain.RollContainer.AddMax:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ADDTOMAXROLL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ADDTOMAXROLLTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["ADDTOMAXROLLTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
	    f.DKPModesMain.RollContainer.AddMax:SetScript("OnLeave", function(self)
	      GameTooltip:Hide()
	    end)

	    -- Add to Max Header
	    f.DKPModesMain.RollContainer.AddMax.Header = f.DKPModesMain.RollContainer.rollMax:CreateFontString(nil, "OVERLAY")
	    f.DKPModesMain.RollContainer.AddMax.Header:SetFontObject("DWPSmallRight");
	    f.DKPModesMain.RollContainer.AddMax.Header:SetPoint("RIGHT", f.DKPModesMain.RollContainer.AddMax, "LEFT", -5, 0);
	    f.DKPModesMain.RollContainer.AddMax.Header:SetText(L["ADDTOMAXROLL"]..": ")

	-- Broadcast DKP Modes Button
	f.DKPModesMain.BroadcastSettings = self:CreateButton("BOTTOMRIGHT", f.DKPModesMain, "BOTTOMRIGHT", -30, 30, L["BROADCASTSETTINGS"]);
	f.DKPModesMain.BroadcastSettings:SetSize(110,25)
	f.DKPModesMain.BroadcastSettings:SetScript("OnClick", function()
		DWPlus_DB.modes.rolls.min = f.DKPModesMain.RollContainer.rollMin:GetNumber()
		DWPlus_DB.modes.rolls.max = f.DKPModesMain.RollContainer.rollMax:GetNumber()
		DWPlus_DB.modes.rolls.AddToMax = f.DKPModesMain.RollContainer.AddMax:GetNumber()

		if (DWPlus_DB.modes.rolls.min > DWPlus_DB.modes.rolls.max and DWPlus_DB.modes.rolls.max ~= 0 and DWPlus_DB.modes.rolls.UserPerc == false) or (DWPlus_DB.modes.rolls.UsePerc and (DWPlus_DB.modes.rolls.min < 0 or DWPlus_DB.modes.rolls.max > 100 or DWPlus_DB.modes.rolls.min > DWPlus_DB.modes.rolls.max)) then
			StaticPopupDialogs["NOTIFY_ROLLS"] = {
				text = "|CFFFF0000"..L["WARNING"].."|r: "..L["INVALIDROLLRANGE"],
				button1 = L["OK"],
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("NOTIFY_ROLLS")
			return;
		end

		StaticPopupDialogs["SEND_MODES"] = {
			text = L["AREYOUSUREBROADCAST"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				local temptable1 = {}
				table.insert(temptable1, DWPlus_DB.modes)
				table.insert(temptable1, DWPlus_DB.DKPBonus)
				table.insert(temptable1, DWPlus_DB.raiders)
				DWP.Sync:SendData("DWPDKPModes", temptable1)
				DWP:Print(L["DKPMODESENTCONF"])
				local temptable2 = {}
	            table.insert(temptable2, DWPlus_DB.MinBidBySlot)
	            table.insert(temptable2, DWPlus_MinBids)
	            DWP.Sync:SendData("DWPMinBid", temptable2)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("SEND_MODES")
	end);
	f.DKPModesMain.BroadcastSettings:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["BROADCASTSETTINGS"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["BROADCASTSETTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show()
	end)
	f.DKPModesMain.BroadcastSettings:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end