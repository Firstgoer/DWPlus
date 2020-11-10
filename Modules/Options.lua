local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local moveTimerToggle = 0;
local validating = false

local function DrawPercFrame(box)
	--Draw % signs if set to percent
	DWP.ConfigTab4.DefaultMinBids.SlotBox[box].perc = DWP.ConfigTab4.DefaultMinBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetFontObject("DWPNormalLeft");
	DWP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetPoint("LEFT", DWP.ConfigTab4.DefaultMinBids.SlotBox[box], "RIGHT", -15, 0);
	DWP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetText("%")
end

local function SaveSettings()
	if DWP.ConfigTab4.default[1] then
		DWPlus_DB.DKPBonus.OnTimeBonus = DWP.ConfigTab4.default[1]:GetNumber();
		DWPlus_DB.DKPBonus.BossKillBonus = DWP.ConfigTab4.default[2]:GetNumber();
		DWPlus_DB.DKPBonus.CompletionBonus = DWP.ConfigTab4.default[3]:GetNumber();
		DWPlus_DB.DKPBonus.NewBossKillBonus = DWP.ConfigTab4.default[4]:GetNumber();
		DWPlus_DB.DKPBonus.UnexcusedAbsence = DWP.ConfigTab4.default[5]:GetNumber();
		if DWP.ConfigTab4.default[6]:GetNumber() < 0 then
			DWPlus_DB.DKPBonus.DecayPercentage = 0 - DWP.ConfigTab4.default[6]:GetNumber();
		else
			DWPlus_DB.DKPBonus.DecayPercentage = DWP.ConfigTab4.default[6]:GetNumber();
		end
		DWP.ConfigTab2.decayDKP:SetNumber(DWPlus_DB.DKPBonus.DecayPercentage);
		DWP.ConfigTab4.default[6]:SetNumber(DWPlus_DB.DKPBonus.DecayPercentage)
		DWPlus_DB.DKPBonus.BidTimer = DWP.ConfigTab4.bidTimer:GetNumber();

		DWPlus_DB.MinBidBySlot.Head = DWP.ConfigTab4.DefaultMinBids.SlotBox[1]:GetNumber()
		DWPlus_DB.MinBidBySlot.Neck = DWP.ConfigTab4.DefaultMinBids.SlotBox[2]:GetNumber()
		DWPlus_DB.MinBidBySlot.Shoulders = DWP.ConfigTab4.DefaultMinBids.SlotBox[3]:GetNumber()
		DWPlus_DB.MinBidBySlot.Cloak = DWP.ConfigTab4.DefaultMinBids.SlotBox[4]:GetNumber()
		DWPlus_DB.MinBidBySlot.Chest = DWP.ConfigTab4.DefaultMinBids.SlotBox[5]:GetNumber()
		DWPlus_DB.MinBidBySlot.Bracers = DWP.ConfigTab4.DefaultMinBids.SlotBox[6]:GetNumber()
		DWPlus_DB.MinBidBySlot.Hands = DWP.ConfigTab4.DefaultMinBids.SlotBox[7]:GetNumber()
		DWPlus_DB.MinBidBySlot.Belt = DWP.ConfigTab4.DefaultMinBids.SlotBox[8]:GetNumber()
		DWPlus_DB.MinBidBySlot.Legs = DWP.ConfigTab4.DefaultMinBids.SlotBox[9]:GetNumber()
		DWPlus_DB.MinBidBySlot.Boots = DWP.ConfigTab4.DefaultMinBids.SlotBox[10]:GetNumber()
		DWPlus_DB.MinBidBySlot.Ring = DWP.ConfigTab4.DefaultMinBids.SlotBox[11]:GetNumber()
		DWPlus_DB.MinBidBySlot.Trinket = DWP.ConfigTab4.DefaultMinBids.SlotBox[12]:GetNumber()
		DWPlus_DB.MinBidBySlot.OneHanded = DWP.ConfigTab4.DefaultMinBids.SlotBox[13]:GetNumber()
		DWPlus_DB.MinBidBySlot.TwoHanded = DWP.ConfigTab4.DefaultMinBids.SlotBox[14]:GetNumber()
		DWPlus_DB.MinBidBySlot.OffHand = DWP.ConfigTab4.DefaultMinBids.SlotBox[15]:GetNumber()
		DWPlus_DB.MinBidBySlot.Range = DWP.ConfigTab4.DefaultMinBids.SlotBox[16]:GetNumber()
		DWPlus_DB.MinBidBySlot.Other = DWP.ConfigTab4.DefaultMinBids.SlotBox[17]:GetNumber()
	end

	core.DWPUI:SetScale(DWPlus_DB.defaults.DWPScaleSize);
	DWPlus_DB.defaults.HistoryLimit = DWP.ConfigTab4.history:GetNumber();
	DWPlus_DB.defaults.DKPHistoryLimit = DWP.ConfigTab4.DKPHistory:GetNumber();
	DWPlus_DB.defaults.TooltipHistoryCount = DWP.ConfigTab4.TooltipHistory:GetNumber();
	DKPTable_Update()
end

function DWP:Options()
	local default = {}
	DWP.ConfigTab4.default = default;

	DWP.ConfigTab4.header = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.header:SetFontObject("DWPLargeCenter");
	DWP.ConfigTab4.header:SetPoint("TOPLEFT", DWP.ConfigTab4, "TOPLEFT", 15, -10);
	DWP.ConfigTab4.header:SetText(L["DEFAULTSETTINGS"]);
	DWP.ConfigTab4.header:SetScale(1.2)

	if core.IsOfficer == true then
		DWP.ConfigTab4.description = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.description:SetFontObject("DWPNormalLeft");
		DWP.ConfigTab4.description:SetPoint("TOPLEFT", DWP.ConfigTab4.header, "BOTTOMLEFT", 7, -15);
		DWP.ConfigTab4.description:SetText("|CFFcca600"..L["DEFAULTDKPAWARDVALUES"].."|r");
	
		for i=1, 6 do
			DWP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, DWP.ConfigTab4)
			DWP.ConfigTab4.default[i]:SetAutoFocus(false)
			DWP.ConfigTab4.default[i]:SetMultiLine(false)
			DWP.ConfigTab4.default[i]:SetSize(80, 24)
			DWP.ConfigTab4.default[i]:SetBackdrop({
				bgFile   = "Textures\\white.blp", tile = true,
				edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
			});
			DWP.ConfigTab4.default[i]:SetBackdropColor(0,0,0,0.9)
			DWP.ConfigTab4.default[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
			DWP.ConfigTab4.default[i]:SetMaxLetters(6)
			DWP.ConfigTab4.default[i]:SetTextColor(1, 1, 1, 1)
			DWP.ConfigTab4.default[i]:SetFontObject("DWPSmallRight")
			DWP.ConfigTab4.default[i]:SetTextInsets(10, 10, 5, 5)
			DWP.ConfigTab4.default[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
				self:HighlightText(0,0)
				SaveSettings()
				self:ClearFocus()
			end)
			DWP.ConfigTab4.default[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
				self:HighlightText(0,0)
				SaveSettings()
				self:ClearFocus()
			end)
			DWP.ConfigTab4.default[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
				SaveSettings()
				if i == 6 then
					self:HighlightText(0,0)
					DWP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetFocus()
					DWP.ConfigTab4.DefaultMinBids.SlotBox[1]:HighlightText()
				else
					self:HighlightText(0,0)
					DWP.ConfigTab4.default[i+1]:SetFocus()
					DWP.ConfigTab4.default[i+1]:HighlightText()
				end
			end)
			DWP.ConfigTab4.default[i]:SetScript("OnEnter", function(self)
				if (self.tooltipText) then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
				end
				if (self.tooltipDescription) then
					GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
				if (self.tooltipWarning) then
					GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
					GameTooltip:Show();
				end
			end)
			DWP.ConfigTab4.default[i]:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			if i==1 then
				DWP.ConfigTab4.default[i]:SetPoint("TOPLEFT", DWP.ConfigTab4, "TOPLEFT", 144, -84)
			elseif i==4 then
				DWP.ConfigTab4.default[i]:SetPoint("TOPLEFT", DWP.ConfigTab4.default[1], "TOPLEFT", 212, 0)
			else
				DWP.ConfigTab4.default[i]:SetPoint("TOP", DWP.ConfigTab4.default[i-1], "BOTTOM", 0, -22)
			end
		end

		-- Modes Button
		DWP.ConfigTab4.ModesButton = self:CreateButton("TOPRIGHT", DWP.ConfigTab4, "TOPRIGHT", -40, -20, L["DKPMODES"]);
		DWP.ConfigTab4.ModesButton:SetSize(110,25)
		DWP.ConfigTab4.ModesButton:SetScript("OnClick", function()
			DWP:ToggleDKPModesWindow()
		end);
		DWP.ConfigTab4.ModesButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true)
			GameTooltip:AddLine(L["DKPMODESTTDESC2"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["DKPMODESTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show()
		end)
		DWP.ConfigTab4.ModesButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
		end)
		if not core.IsOfficer then
			DWP.ConfigTab4.ModesButton:Hide()
		end

		DWP.ConfigTab4.default[1]:SetText(DWPlus_DB.DKPBonus.OnTimeBonus)
		DWP.ConfigTab4.default[1].tooltipText = L["ONTIMEBONUS"]
		DWP.ConfigTab4.default[1].tooltipDescription = L["ONTIMEBONUSTTDESC"]
			
		DWP.ConfigTab4.default[2]:SetText(DWPlus_DB.DKPBonus.BossKillBonus)
		DWP.ConfigTab4.default[2].tooltipText = L["BOSSKILLBONUS"]
		DWP.ConfigTab4.default[2].tooltipDescription = L["BOSSKILLBONUSTTDESC"]
			 
		DWP.ConfigTab4.default[3]:SetText(DWPlus_DB.DKPBonus.CompletionBonus)
		DWP.ConfigTab4.default[3].tooltipText = L["RAIDCOMPLETIONBONUS"]
		DWP.ConfigTab4.default[3].tooltipDescription = L["RAIDCOMPLETEBONUSTT"]
			
		DWP.ConfigTab4.default[4]:SetText(DWPlus_DB.DKPBonus.NewBossKillBonus)
		DWP.ConfigTab4.default[4].tooltipText = L["NEWBOSSKILLBONUS"]
		DWP.ConfigTab4.default[4].tooltipDescription = L["NEWBOSSKILLTTDESC"]

		DWP.ConfigTab4.default[5]:SetText(DWPlus_DB.DKPBonus.UnexcusedAbsence)
		DWP.ConfigTab4.default[5]:SetNumeric(false)
		DWP.ConfigTab4.default[5].tooltipText = L["UNEXCUSEDABSENCE"]
		DWP.ConfigTab4.default[5].tooltipDescription = L["UNEXCUSEDTTDESC"]
		DWP.ConfigTab4.default[5].tooltipWarning = L["UNEXCUSEDTTWARN"]

		DWP.ConfigTab4.default[6]:SetText(DWPlus_DB.DKPBonus.DecayPercentage)
		DWP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
		DWP.ConfigTab4.default[6].tooltipText = L["DECAYPERCENTAGE"]
		DWP.ConfigTab4.default[6].tooltipDescription = L["DECAYPERCENTAGETTDESC"]
		DWP.ConfigTab4.default[6].tooltipWarning = L["DECAYPERCENTAGETTWARN"]

		--OnTimeBonus Header
		DWP.ConfigTab4.OnTimeHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.OnTimeHeader:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", DWP.ConfigTab4.default[1], "LEFT", 0, 0);
		DWP.ConfigTab4.OnTimeHeader:SetText(L["ONTIMEBONUS"]..": ")

		--BossKillBonus Header
		DWP.ConfigTab4.BossKillHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.BossKillHeader:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", DWP.ConfigTab4.default[2], "LEFT", 0, 0);
		DWP.ConfigTab4.BossKillHeader:SetText(L["BOSSKILLBONUS"]..": ")

		--CompletionBonus Header
		DWP.ConfigTab4.CompleteHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.CompleteHeader:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", DWP.ConfigTab4.default[3], "LEFT", 0, 0);
		DWP.ConfigTab4.CompleteHeader:SetText(L["RAIDCOMPLETIONBONUS"]..": ")

		--NewBossKillBonus Header
		DWP.ConfigTab4.NewBossHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.NewBossHeader:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", DWP.ConfigTab4.default[4], "LEFT", 0, 0);
		DWP.ConfigTab4.NewBossHeader:SetText(L["NEWBOSSKILLBONUS"]..": ")

		--UnexcusedAbsence Header
		DWP.ConfigTab4.UnexcusedHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.UnexcusedHeader:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", DWP.ConfigTab4.default[5], "LEFT", 0, 0);
		DWP.ConfigTab4.UnexcusedHeader:SetText(L["UNEXCUSEDABSENCE"]..": ")

		--DKP Decay Header
		DWP.ConfigTab4.DecayHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.DecayHeader:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.DecayHeader:SetPoint("RIGHT", DWP.ConfigTab4.default[6], "LEFT", 0, 0);
		DWP.ConfigTab4.DecayHeader:SetText(L["DECAYAMOUNT"]..": ")

		DWP.ConfigTab4.DecayFooter = DWP.ConfigTab4.default[6]:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.DecayFooter:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.DecayFooter:SetPoint("LEFT", DWP.ConfigTab4.default[6], "RIGHT", -15, -1);
		DWP.ConfigTab4.DecayFooter:SetText("%")

		-- Default Minimum Bids Container Frame
		DWP.ConfigTab4.DefaultMinBids = CreateFrame("Frame", nil, DWP.ConfigTab4);
		DWP.ConfigTab4.DefaultMinBids:SetPoint("TOPLEFT", DWP.ConfigTab4.default[3], "BOTTOMLEFT", -130, -52)
		DWP.ConfigTab4.DefaultMinBids:SetSize(420, 410);

		DWP.ConfigTab4.DefaultMinBids.description = DWP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.DefaultMinBids.description:SetFontObject("DWPSmallRight");
		DWP.ConfigTab4.DefaultMinBids.description:SetPoint("TOPLEFT", DWP.ConfigTab4.DefaultMinBids, "TOPLEFT", 15, 15);

			-- DEFAULT min bids Create EditBoxes
			local SlotBox = {}
			DWP.ConfigTab4.DefaultMinBids.SlotBox = SlotBox;

			for i=1, 17 do
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i] = CreateFrame("EditBox", nil, DWP.ConfigTab4)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetAutoFocus(false)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMultiLine(false)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetSize(60, 24)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdrop({
					bgFile   = "Textures\\white.blp", tile = true,
					edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
				});
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMaxLetters(6)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetFontObject("DWPSmallRight")
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					SaveSettings()
					self:ClearFocus()
				end)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					SaveSettings()
					self:ClearFocus()
				end)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
					if i == 8 then
						self:HighlightText(0,0)
						DWP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetFocus()
						DWP.ConfigTab4.DefaultMinBids.SlotBox[17]:HighlightText()
						SaveSettings()
					elseif i == 5 then
						self:HighlightText(0,0)
						DWP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
						DWP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
						DWP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
						SaveSettings()
					elseif i == 13 then
						self:HighlightText(0,0)
						DWP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
						DWP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetFocus()
						DWP.ConfigTab4.DefaultMinBids.SlotBox[14]:HighlightText()
						SaveSettings()
					elseif i == 17 then
						self:HighlightText(0,0)
						DWP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetFocus()
						DWP.ConfigTab4.DefaultMinBids.SlotBox[9]:HighlightText()
						SaveSettings()
					elseif i == 16 then
						self:HighlightText(0,0)
						DWP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
						DWP.ConfigTab4.default[1]:SetFocus()
						DWP.ConfigTab4.default[1]:HighlightText()
						SaveSettings()
					else
						self:HighlightText(0,0)
						DWP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
						DWP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
						SaveSettings()
					end
				end)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnter", function(self)
					if (self.tooltipText) then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
					end
					if (self.tooltipDescription) then
						GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
						GameTooltip:Show();
					end
					if (self.tooltipWarning) then
						GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
						GameTooltip:Show();
					end
				end)
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)

				-- Slot Headers
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i].Header = DWP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetFontObject("DWPNormalLeft");
				DWP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetPoint("RIGHT", DWP.ConfigTab4.DefaultMinBids.SlotBox[i], "LEFT", 0, 0);

				if i==1 then
					DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", DWP.ConfigTab4.DefaultMinBids, "TOPLEFT", 100, -10)
				elseif i==9 then
					DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", DWP.ConfigTab4.DefaultMinBids.SlotBox[1], "TOPLEFT", 150, 0)
				elseif i==17 then
					DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", DWP.ConfigTab4.DefaultMinBids.SlotBox[8], "BOTTOM", 0, -22)
				else
					DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", DWP.ConfigTab4.DefaultMinBids.SlotBox[i-1], "BOTTOM", 0, -22)
				end
			end

			local prefix;

			if DWPlus_DB.modes.mode == "Minimum Bid Values" then
				prefix = L["MINIMUMBID"];
				DWP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTMINBIDVALUES"].."|r");
			elseif DWPlus_DB.modes.mode == "Static Item Values" then
				DWP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
				if DWPlus_DB.modes.costvalue == "Integer" then
					prefix = L["DKPPRICE"]
				elseif DWPlus_DB.modes.costvalue == "Percent" then
					prefix = L["PERCENTCOST"]
				end
			elseif DWPlus_DB.modes.mode == "Roll Based Bidding" then
				DWP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
				if DWPlus_DB.modes.costvalue == "Integer" then
					prefix = L["DKPPRICE"]
				elseif DWPlus_DB.modes.costvalue == "Percent" then
					prefix = L["PERCENTCOST"]
				end
			elseif DWPlus_DB.modes.mode == "Zero Sum" then
				DWP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
				if DWPlus_DB.modes.costvalue == "Integer" then
					prefix = L["DKPPRICE"]
				elseif DWPlus_DB.modes.costvalue == "Percent" then
					prefix = L["PERCENTCOST"]
				end
			end

			DWP.ConfigTab4.DefaultMinBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetText(DWPlus_DB.MinBidBySlot.Head)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipText = L["HEAD"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetText(DWPlus_DB.MinBidBySlot.Neck)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipText = L["NECK"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[3]:SetText(DWPlus_DB.MinBidBySlot.Shoulders)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipText = L["SHOULDERS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[4]:SetText(DWPlus_DB.MinBidBySlot.Cloak)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipText = L["CLOAK"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[5]:SetText(DWPlus_DB.MinBidBySlot.Chest)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipText = L["CHEST"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[6]:SetText(DWPlus_DB.MinBidBySlot.Bracers)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipText = L["BRACERS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[7]:SetText(DWPlus_DB.MinBidBySlot.Hands)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipText = L["HANDS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[8]:SetText(DWPlus_DB.MinBidBySlot.Belt)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipText = L["BELT"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetText(DWPlus_DB.MinBidBySlot.Legs)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipText = L["LEGS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[10]:SetText(DWPlus_DB.MinBidBySlot.Boots)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipText = L["BOOTS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[11]:SetText(DWPlus_DB.MinBidBySlot.Ring)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipText = L["RINGS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[12]:SetText(DWPlus_DB.MinBidBySlot.Trinket)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipText = L["TRINKET"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[13]:SetText(DWPlus_DB.MinBidBySlot.OneHanded)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetText(DWPlus_DB.MinBidBySlot.TwoHanded)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[15]:SetText(DWPlus_DB.MinBidBySlot.OffHand)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[16]:SetText(DWPlus_DB.MinBidBySlot.Range)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipText = L["RANGE"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"]

			DWP.ConfigTab4.DefaultMinBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
			DWP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetText(DWPlus_DB.MinBidBySlot.Other)
			DWP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipText = L["OTHER"]
			DWP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"]

			if DWPlus_DB.modes.costvalue == "Percent" then
				for i=1, #DWP.ConfigTab4.DefaultMinBids.SlotBox do
					DrawPercFrame(i)
					DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
				end
			end

			-- Broadcast Minimum Bids Button
			DWP.ConfigTab4.BroadcastMinBids = self:CreateButton("TOP", DWP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
			DWP.ConfigTab4.BroadcastMinBids:ClearAllPoints();
			DWP.ConfigTab4.BroadcastMinBids:SetPoint("LEFT", DWP.ConfigTab4.DefaultMinBids.SlotBox[17], "RIGHT", 41, 0)
			DWP.ConfigTab4.BroadcastMinBids:SetSize(110,25)
			DWP.ConfigTab4.BroadcastMinBids:SetScript("OnClick", function()
				StaticPopupDialogs["SEND_MINBIDS"] = {
					text = L["BCASTMINBIDCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						local temptable = {}
						table.insert(temptable, DWPlus_DB.MinBidBySlot)
						table.insert(temptable, DWPlus_MinBids)
						DWP.Sync:SendData("DWPMinBid", temptable)
						DWP:Print(L["MINBIDVALUESSENT"])
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("SEND_MINBIDS")
			end);
			DWP.ConfigTab4.BroadcastMinBids:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
				GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show()
			end)
			DWP.ConfigTab4.BroadcastMinBids:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

		-- Bid Timer Slider
		DWP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", DWP.ConfigTab4, "DWPOptionsSliderTemplate");
		DWP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", DWP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 54, -40);
		DWP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 90);
		DWP.ConfigTab4.bidTimerSlider:SetValue(DWPlus_DB.DKPBonus.BidTimer);
		DWP.ConfigTab4.bidTimerSlider:SetValueStep(1);
		DWP.ConfigTab4.bidTimerSlider.tooltipText = L["BIDTIMER"]
		DWP.ConfigTab4.bidTimerSlider.tooltipRequirement = L["BIDTIMERDEFAULTTTDESC"]
		DWP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true);
		getglobal(DWP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
		getglobal(DWP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("90")
		DWP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
			DWP.ConfigTab4.bidTimer:SetText(DWP.ConfigTab4.bidTimerSlider:GetValue())
		end)

		DWP.ConfigTab4.bidTimerHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
		DWP.ConfigTab4.bidTimerHeader:SetFontObject("DWPTinyCenter");
		DWP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", DWP.ConfigTab4.bidTimerSlider, "TOP", 0, 3);
		DWP.ConfigTab4.bidTimerHeader:SetText(L["BIDTIMER"])

		DWP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, DWP.ConfigTab4)
		DWP.ConfigTab4.bidTimer:SetAutoFocus(false)
		DWP.ConfigTab4.bidTimer:SetMultiLine(false)
		DWP.ConfigTab4.bidTimer:SetSize(50, 18)
		DWP.ConfigTab4.bidTimer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		DWP.ConfigTab4.bidTimer:SetBackdropColor(0,0,0,0.9)
		DWP.ConfigTab4.bidTimer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
		DWP.ConfigTab4.bidTimer:SetMaxLetters(4)
		DWP.ConfigTab4.bidTimer:SetTextColor(1, 1, 1, 1)
		DWP.ConfigTab4.bidTimer:SetFontObject("DWPTinyCenter")
		DWP.ConfigTab4.bidTimer:SetTextInsets(10, 10, 5, 5)
		DWP.ConfigTab4.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:ClearFocus()
		end)
		DWP.ConfigTab4.bidTimer:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:ClearFocus()
		end)
		DWP.ConfigTab4.bidTimer:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
			DWP.ConfigTab4.bidTimerSlider:SetValue(DWP.ConfigTab4.bidTimer:GetNumber());
		end)
		DWP.ConfigTab4.bidTimer:SetPoint("TOP", DWP.ConfigTab4.bidTimerSlider, "BOTTOM", 0, -3)
		DWP.ConfigTab4.bidTimer:SetText(DWP.ConfigTab4.bidTimerSlider:GetValue())
	end

	-- Tooltip History Slider
	DWP.ConfigTab4.TooltipHistorySlider = CreateFrame("SLIDER", "$parentTooltipHistorySlider", DWP.ConfigTab4, "DWPOptionsSliderTemplate");
	if DWP.ConfigTab4.bidTimer then
		DWP.ConfigTab4.TooltipHistorySlider:SetPoint("LEFT", DWP.ConfigTab4.bidTimerSlider, "RIGHT", 30, 0);
	else
		DWP.ConfigTab4.TooltipHistorySlider:SetPoint("TOP", DWP.ConfigTab4, "TOP", 1, -107);
	end
	DWP.ConfigTab4.TooltipHistorySlider:SetMinMaxValues(5, 35);
	DWP.ConfigTab4.TooltipHistorySlider:SetValue(DWPlus_DB.defaults.TooltipHistoryCount);
	DWP.ConfigTab4.TooltipHistorySlider:SetValueStep(1);
	DWP.ConfigTab4.TooltipHistorySlider.tooltipText = L["TTHISTORYCOUNT"]
	DWP.ConfigTab4.TooltipHistorySlider.tooltipRequirement = L["TTHISTORYCOUNTTTDESC"]
	DWP.ConfigTab4.TooltipHistorySlider:SetObeyStepOnDrag(true);
	getglobal(DWP.ConfigTab4.TooltipHistorySlider:GetName().."Low"):SetText("5")
	getglobal(DWP.ConfigTab4.TooltipHistorySlider:GetName().."High"):SetText("35")
	DWP.ConfigTab4.TooltipHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
		DWP.ConfigTab4.TooltipHistory:SetText(DWP.ConfigTab4.TooltipHistorySlider:GetValue())
	end)

	DWP.ConfigTab4.TooltipHistoryHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.TooltipHistoryHeader:SetFontObject("DWPTinyCenter");
	DWP.ConfigTab4.TooltipHistoryHeader:SetPoint("BOTTOM", DWP.ConfigTab4.TooltipHistorySlider, "TOP", 0, 3);
	DWP.ConfigTab4.TooltipHistoryHeader:SetText(L["TTHISTORYCOUNT"])

	DWP.ConfigTab4.TooltipHistory = CreateFrame("EditBox", nil, DWP.ConfigTab4)
	DWP.ConfigTab4.TooltipHistory:SetAutoFocus(false)
	DWP.ConfigTab4.TooltipHistory:SetMultiLine(false)
	DWP.ConfigTab4.TooltipHistory:SetSize(50, 18)
	DWP.ConfigTab4.TooltipHistory:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab4.TooltipHistory:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab4.TooltipHistory:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
	DWP.ConfigTab4.TooltipHistory:SetMaxLetters(4)
	DWP.ConfigTab4.TooltipHistory:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab4.TooltipHistory:SetFontObject("DWPTinyCenter")
	DWP.ConfigTab4.TooltipHistory:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab4.TooltipHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.TooltipHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.TooltipHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		DWP.ConfigTab4.TooltipHistorySlider:SetValue(DWP.ConfigTab4.TooltipHistory:GetNumber());
	end)
	DWP.ConfigTab4.TooltipHistory:SetPoint("TOP", DWP.ConfigTab4.TooltipHistorySlider, "BOTTOM", 0, -3)
	DWP.ConfigTab4.TooltipHistory:SetText(DWP.ConfigTab4.TooltipHistorySlider:GetValue())


	-- Loot History Limit Slider
	DWP.ConfigTab4.historySlider = CreateFrame("SLIDER", "$parentHistorySlider", DWP.ConfigTab4, "DWPOptionsSliderTemplate");
	if DWP.ConfigTab4.bidTimer then
		DWP.ConfigTab4.historySlider:SetPoint("TOPLEFT", DWP.ConfigTab4.bidTimerSlider, "BOTTOMLEFT", 0, -50);
	else
		DWP.ConfigTab4.historySlider:SetPoint("TOPRIGHT", DWP.ConfigTab4.TooltipHistorySlider, "BOTTOMLEFT", 56, -49);
	end
	DWP.ConfigTab4.historySlider:SetMinMaxValues(500, 2500);
	DWP.ConfigTab4.historySlider:SetValue(DWPlus_DB.defaults.HistoryLimit);
	DWP.ConfigTab4.historySlider:SetValueStep(25);
	DWP.ConfigTab4.historySlider.tooltipText = L["LOOTHISTORYLIMIT"]
	DWP.ConfigTab4.historySlider.tooltipRequirement = L["LOOTHISTLIMITTTDESC"]
	DWP.ConfigTab4.historySlider.tooltipWarning = L["LOOTHISTLIMITTTWARN"]
	DWP.ConfigTab4.historySlider:SetObeyStepOnDrag(true);
	getglobal(DWP.ConfigTab4.historySlider:GetName().."Low"):SetText("500")
	getglobal(DWP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
	DWP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
		DWP.ConfigTab4.history:SetText(DWP.ConfigTab4.historySlider:GetValue())
	end)

	DWP.ConfigTab4.HistoryHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.HistoryHeader:SetFontObject("DWPTinyCenter");
	DWP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", DWP.ConfigTab4.historySlider, "TOP", 0, 3);
	DWP.ConfigTab4.HistoryHeader:SetText(L["LOOTHISTORYLIMIT"])

	DWP.ConfigTab4.history = CreateFrame("EditBox", nil, DWP.ConfigTab4)
	DWP.ConfigTab4.history:SetAutoFocus(false)
	DWP.ConfigTab4.history:SetMultiLine(false)
	DWP.ConfigTab4.history:SetSize(50, 18)
	DWP.ConfigTab4.history:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab4.history:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab4.history:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
	DWP.ConfigTab4.history:SetMaxLetters(4)
	DWP.ConfigTab4.history:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab4.history:SetFontObject("DWPTinyCenter")
	DWP.ConfigTab4.history:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab4.history:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.history:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.history:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		DWP.ConfigTab4.historySlider:SetValue(DWP.ConfigTab4.history:GetNumber());
	end)
	DWP.ConfigTab4.history:SetPoint("TOP", DWP.ConfigTab4.historySlider, "BOTTOM", 0, -3)
	DWP.ConfigTab4.history:SetText(DWP.ConfigTab4.historySlider:GetValue())

	-- DKP History Limit Slider
	DWP.ConfigTab4.DKPHistorySlider = CreateFrame("SLIDER", "$parentDKPHistorySlider", DWP.ConfigTab4, "DWPOptionsSliderTemplate");
	DWP.ConfigTab4.DKPHistorySlider:SetPoint("LEFT", DWP.ConfigTab4.historySlider, "RIGHT", 30, 0);
	DWP.ConfigTab4.DKPHistorySlider:SetMinMaxValues(500, 2500);
	DWP.ConfigTab4.DKPHistorySlider:SetValue(DWPlus_DB.defaults.DKPHistoryLimit);
	DWP.ConfigTab4.DKPHistorySlider:SetValueStep(25);
	DWP.ConfigTab4.DKPHistorySlider.tooltipText = L["DKPHISTORYLIMIT"]
	DWP.ConfigTab4.DKPHistorySlider.tooltipRequirement = L["DKPHISTLIMITTTDESC"]
	DWP.ConfigTab4.DKPHistorySlider.tooltipWarning = L["DKPHISTLIMITTTWARN"]
	DWP.ConfigTab4.DKPHistorySlider:SetObeyStepOnDrag(true);
	getglobal(DWP.ConfigTab4.DKPHistorySlider:GetName().."Low"):SetText("500")
	getglobal(DWP.ConfigTab4.DKPHistorySlider:GetName().."High"):SetText("2500")
	DWP.ConfigTab4.DKPHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
		DWP.ConfigTab4.DKPHistory:SetText(DWP.ConfigTab4.DKPHistorySlider:GetValue())
	end)

	DWP.ConfigTab4.DKPHistoryHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.DKPHistoryHeader:SetFontObject("DWPTinyCenter");
	DWP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", DWP.ConfigTab4.DKPHistorySlider, "TOP", 0, 3);
	DWP.ConfigTab4.DKPHistoryHeader:SetText(L["DKPHISTORYLIMIT"])

	DWP.ConfigTab4.DKPHistory = CreateFrame("EditBox", nil, DWP.ConfigTab4)
	DWP.ConfigTab4.DKPHistory:SetAutoFocus(false)
	DWP.ConfigTab4.DKPHistory:SetMultiLine(false)
	DWP.ConfigTab4.DKPHistory:SetSize(50, 18)
	DWP.ConfigTab4.DKPHistory:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab4.DKPHistory:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab4.DKPHistory:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	DWP.ConfigTab4.DKPHistory:SetMaxLetters(4)
	DWP.ConfigTab4.DKPHistory:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab4.DKPHistory:SetFontObject("DWPTinyCenter")
	DWP.ConfigTab4.DKPHistory:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab4.DKPHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.DKPHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.DKPHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		DWP.ConfigTab4.DKPHistorySlider:SetValue(DWP.ConfigTab4.history:GetNumber());
	end)
	DWP.ConfigTab4.DKPHistory:SetPoint("TOP", DWP.ConfigTab4.DKPHistorySlider, "BOTTOM", 0, -3)
	DWP.ConfigTab4.DKPHistory:SetText(DWP.ConfigTab4.DKPHistorySlider:GetValue())

	-- Bid Timer Size Slider
	DWP.ConfigTab4.TimerSizeSlider = CreateFrame("SLIDER", "$parentBidTimerSizeSlider", DWP.ConfigTab4, "DWPOptionsSliderTemplate");
	DWP.ConfigTab4.TimerSizeSlider:SetPoint("TOPLEFT", DWP.ConfigTab4.historySlider, "BOTTOMLEFT", 0, -50);
	DWP.ConfigTab4.TimerSizeSlider:SetMinMaxValues(0.5, 2.0);
	DWP.ConfigTab4.TimerSizeSlider:SetValue(DWPlus_DB.defaults.BidTimerSize);
	DWP.ConfigTab4.TimerSizeSlider:SetValueStep(0.05);
	DWP.ConfigTab4.TimerSizeSlider.tooltipText = L["TIMERSIZE"]
	DWP.ConfigTab4.TimerSizeSlider.tooltipRequirement = L["TIMERSIZETTDESC"]
	DWP.ConfigTab4.TimerSizeSlider.tooltipWarning = L["TIMERSIZETTWARN"]
	DWP.ConfigTab4.TimerSizeSlider:SetObeyStepOnDrag(true);
	getglobal(DWP.ConfigTab4.TimerSizeSlider:GetName().."Low"):SetText("50%")
	getglobal(DWP.ConfigTab4.TimerSizeSlider:GetName().."High"):SetText("200%")
	DWP.ConfigTab4.TimerSizeSlider:SetScript("OnValueChanged", function(self)
		DWP.ConfigTab4.TimerSize:SetText(DWP.ConfigTab4.TimerSizeSlider:GetValue())
		DWPlus_DB.defaults.BidTimerSize = DWP.ConfigTab4.TimerSizeSlider:GetValue();
		DWP.BidTimer:SetScale(DWPlus_DB.defaults.BidTimerSize);
	end)

	DWP.ConfigTab4.DKPHistoryHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.DKPHistoryHeader:SetFontObject("DWPTinyCenter");
	DWP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", DWP.ConfigTab4.TimerSizeSlider, "TOP", 0, 3);
	DWP.ConfigTab4.DKPHistoryHeader:SetText(L["TIMERSIZE"])

	DWP.ConfigTab4.TimerSize = CreateFrame("EditBox", nil, DWP.ConfigTab4)
	DWP.ConfigTab4.TimerSize:SetAutoFocus(false)
	DWP.ConfigTab4.TimerSize:SetMultiLine(false)
	DWP.ConfigTab4.TimerSize:SetSize(50, 18)
	DWP.ConfigTab4.TimerSize:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab4.TimerSize:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab4.TimerSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	DWP.ConfigTab4.TimerSize:SetMaxLetters(4)
	DWP.ConfigTab4.TimerSize:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab4.TimerSize:SetFontObject("DWPTinyCenter")
	DWP.ConfigTab4.TimerSize:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab4.TimerSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.TimerSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.TimerSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		DWP.ConfigTab4.TimerSizeSlider:SetValue(DWP.ConfigTab4.TimerSize:GetNumber());
	end)
	DWP.ConfigTab4.TimerSize:SetPoint("TOP", DWP.ConfigTab4.TimerSizeSlider, "BOTTOM", 0, -3)
	DWP.ConfigTab4.TimerSize:SetText(DWP.ConfigTab4.TimerSizeSlider:GetValue())

	-- UI Scale Size Slider
	DWP.ConfigTab4.DWPScaleSize = CreateFrame("SLIDER", "$parentDWPScaleSizeSlider", DWP.ConfigTab4, "DWPOptionsSliderTemplate");
	DWP.ConfigTab4.DWPScaleSize:SetPoint("TOPLEFT", DWP.ConfigTab4.DKPHistorySlider, "BOTTOMLEFT", 0, -50);
	DWP.ConfigTab4.DWPScaleSize:SetMinMaxValues(0.5, 2.0);
	DWP.ConfigTab4.DWPScaleSize:SetValue(DWPlus_DB.defaults.DWPScaleSize);
	DWP.ConfigTab4.DWPScaleSize:SetValueStep(0.05);
	DWP.ConfigTab4.DWPScaleSize.tooltipText = L["DWPSCALESIZE"]
	DWP.ConfigTab4.DWPScaleSize.tooltipRequirement = L["DWPSCALESIZETTDESC"]
	DWP.ConfigTab4.DWPScaleSize.tooltipWarning = L["DWPSCALESIZETTWARN"]
	DWP.ConfigTab4.DWPScaleSize:SetObeyStepOnDrag(true);
	getglobal(DWP.ConfigTab4.DWPScaleSize:GetName().."Low"):SetText("50%")
	getglobal(DWP.ConfigTab4.DWPScaleSize:GetName().."High"):SetText("200%")
	DWP.ConfigTab4.DWPScaleSize:SetScript("OnValueChanged", function(self)
		DWP.ConfigTab4.UIScaleSize:SetText(DWP.ConfigTab4.DWPScaleSize:GetValue())
		DWPlus_DB.defaults.DWPScaleSize = DWP.ConfigTab4.DWPScaleSize:GetValue();
	end)

	DWP.ConfigTab4.DKPHistoryHeader = DWP.ConfigTab4:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab4.DKPHistoryHeader:SetFontObject("DWPTinyCenter");
	DWP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", DWP.ConfigTab4.DWPScaleSize, "TOP", 0, 3);
	DWP.ConfigTab4.DKPHistoryHeader:SetText(L["MAINGUISIZE"])

	DWP.ConfigTab4.UIScaleSize = CreateFrame("EditBox", nil, DWP.ConfigTab4)
	DWP.ConfigTab4.UIScaleSize:SetAutoFocus(false)
	DWP.ConfigTab4.UIScaleSize:SetMultiLine(false)
	DWP.ConfigTab4.UIScaleSize:SetSize(50, 18)
	DWP.ConfigTab4.UIScaleSize:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab4.UIScaleSize:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab4.UIScaleSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
	DWP.ConfigTab4.UIScaleSize:SetMaxLetters(4)
	DWP.ConfigTab4.UIScaleSize:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab4.UIScaleSize:SetFontObject("DWPTinyCenter")
	DWP.ConfigTab4.UIScaleSize:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab4.UIScaleSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.UIScaleSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab4.UIScaleSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
		DWP.ConfigTab4.DWPScaleSize:SetValue(DWP.ConfigTab4.UIScaleSize:GetNumber());
	end)
	DWP.ConfigTab4.UIScaleSize:SetPoint("TOP", DWP.ConfigTab4.DWPScaleSize, "BOTTOM", 0, -3)
	DWP.ConfigTab4.UIScaleSize:SetText(DWP.ConfigTab4.DWPScaleSize:GetValue())

	-- Supress Broadcast Notifications checkbox
	DWP.ConfigTab4.supressNotifications = CreateFrame("CheckButton", nil, DWP.ConfigTab4, "UICheckButtonTemplate");
	DWP.ConfigTab4.supressNotifications:SetPoint("TOP", DWP.ConfigTab4.TimerSizeSlider, "BOTTOMLEFT", 0, -35)
	DWP.ConfigTab4.supressNotifications:SetChecked(DWPlus_DB.defaults.supressNotifications)
	DWP.ConfigTab4.supressNotifications:SetScale(0.8)
	DWP.ConfigTab4.supressNotifications.text:SetText("|cff5151de"..L["SUPPRESSNOTIFICATIONS"].."|r");
	DWP.ConfigTab4.supressNotifications.text:SetFontObject("DWPSmall")
	DWP.ConfigTab4.supressNotifications:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SUPPRESSNOTIFICATIONS"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["SUPPRESSNOTIFYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["SUPPRESSNOTIFYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show()
	end)
	DWP.ConfigTab4.supressNotifications:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	DWP.ConfigTab4.supressNotifications:SetScript("OnClick", function()
		if DWP.ConfigTab4.supressNotifications:GetChecked() then
			DWP:Print(L["NOTIFICATIONSLIKETHIS"].." |cffff0000"..L["HIDDEN"].."|r.")
			DWPlus_DB["defaults"]["supressNotifications"] = true;
		else
			DWPlus_DB["defaults"]["supressNotifications"] = false;
			DWP:Print(L["NOTIFICATIONSLIKETHIS"].." |cff00ff00"..L["VISIBLE"].."|r.")
		end
		PlaySound(808)
	end)

	-- Combat Logging checkbox
	DWP.ConfigTab4.CombatLogging = CreateFrame("CheckButton", nil, DWP.ConfigTab4, "UICheckButtonTemplate");
	DWP.ConfigTab4.CombatLogging:SetPoint("TOP", DWP.ConfigTab4.supressNotifications, "BOTTOM", 0, 0)
	DWP.ConfigTab4.CombatLogging:SetChecked(DWPlus_DB.defaults.AutoLog)
	DWP.ConfigTab4.CombatLogging:SetScale(0.8)
	DWP.ConfigTab4.CombatLogging.text:SetText("|cff5151de"..L["AUTOCOMBATLOG"].."|r");
	DWP.ConfigTab4.CombatLogging.text:SetFontObject("DWPSmall")
	DWP.ConfigTab4.CombatLogging:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["AUTOCOMBATLOG"], 0.25, 0.75, 0.90, 1, true)
		GameTooltip:AddLine(L["AUTOCOMBATLOGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["AUTOCOMBATLOGTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show()
	end)
	DWP.ConfigTab4.CombatLogging:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	DWP.ConfigTab4.CombatLogging:SetScript("OnClick", function(self)
		DWPlus_DB.defaults.AutoLog = self:GetChecked()
		PlaySound(808)
	end)

	if DWPlus_DB.defaults.AutoOpenBid == nil then
		DWPlus_DB.defaults.AutoOpenBid = true
	end

	DWP.ConfigTab4.AutoOpenCheckbox = CreateFrame("CheckButton", nil, DWP.ConfigTab4, "UICheckButtonTemplate");
	DWP.ConfigTab4.AutoOpenCheckbox:SetChecked(DWPlus_DB.defaults.AutoOpenBid)
	DWP.ConfigTab4.AutoOpenCheckbox:SetScale(0.8);
	DWP.ConfigTab4.AutoOpenCheckbox.text:SetText("|cff5151de"..L["AUTOOPEN"].."|r");
	DWP.ConfigTab4.AutoOpenCheckbox.text:SetScale(1);
	DWP.ConfigTab4.AutoOpenCheckbox.text:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab4.AutoOpenCheckbox:SetPoint("TOP", DWP.ConfigTab4.CombatLogging, "BOTTOM", 0, 0);
	DWP.ConfigTab4.AutoOpenCheckbox:SetScript("OnClick", function(self)
		DWPlus_DB.defaults.AutoOpenBid = self:GetChecked()
	end)
	DWP.ConfigTab4.AutoOpenCheckbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab4.AutoOpenCheckbox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	if core.IsOfficer == true then
		-- Supress Broadcast Notifications checkbox
		DWP.ConfigTab4.supressTells = CreateFrame("CheckButton", nil, DWP.ConfigTab4, "UICheckButtonTemplate");
		DWP.ConfigTab4.supressTells:SetPoint("LEFT", DWP.ConfigTab4.supressNotifications, "RIGHT", 200, 0)
		DWP.ConfigTab4.supressTells:SetChecked(DWPlus_DB.defaults.SupressTells)
		DWP.ConfigTab4.supressTells:SetScale(0.8)
		DWP.ConfigTab4.supressTells.text:SetText("|cff5151de"..L["SUPPRESSBIDWHISP"].."|r");
		DWP.ConfigTab4.supressTells.text:SetFontObject("DWPSmall")
		DWP.ConfigTab4.supressTells:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["SUPPRESSBIDWHISP"], 0.25, 0.75, 0.90, 1, true)
			GameTooltip:AddLine(L["SUPRESSBIDWHISPTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["SUPRESSBIDWHISPTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show()
		end)
		DWP.ConfigTab4.supressTells:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		DWP.ConfigTab4.supressTells:SetScript("OnClick", function()
			if DWP.ConfigTab4.supressTells:GetChecked() then
				DWP:Print(L["BIDWHISPARENOW"].." |cffff0000"..L["HIDDEN"].."|r.")
				DWPlus_DB["defaults"]["SupressTells"] = true;
			else
				DWPlus_DB["defaults"]["SupressTells"] = false;
				DWP:Print(L["BIDWHISPARENOW"].." |cff00ff00"..L["VISIBLE"].."|r.")
			end
			PlaySound(808)
		end)
	end

	-- Save Settings Button
	DWP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", DWP.ConfigTab4, "BOTTOMLEFT", 30, 30, L["SAVESETTINGS"]);
	DWP.ConfigTab4.submitSettings:ClearAllPoints();
	DWP.ConfigTab4.submitSettings:SetPoint("TOP", DWP.ConfigTab4.AutoOpenCheckbox, "BOTTOMLEFT", 20, -40)
	DWP.ConfigTab4.submitSettings:SetSize(90,25)
	DWP.ConfigTab4.submitSettings:SetScript("OnClick", function()
		if core.IsOfficer == true then
			for i=1, 6 do
				if not tonumber(DWP.ConfigTab4.default[i]:GetText()) then
					StaticPopupDialogs["OPTIONS_VALIDATION"] = {
						text = L["INVALIDOPTIONENTRY"].." "..DWP.ConfigTab4.default[i].tooltipText..". "..L["PLEASEUSENUMS"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("OPTIONS_VALIDATION")

				return;
				end
			end
			for i=1, 17 do
				if not tonumber(DWP.ConfigTab4.DefaultMinBids.SlotBox[i]:GetText()) then
					StaticPopupDialogs["OPTIONS_VALIDATION"] = {
						text = L["INVALIDMINBIDENTRY"].." "..DWP.ConfigTab4.DefaultMinBids.SlotBox[i].tooltipText..". "..L["PLEASEUSENUMS"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("OPTIONS_VALIDATION")

				return;
				end
			end
		end
		
		SaveSettings()
		DWP:Print(L["DEFAULTSETSAVED"])
	end)

	-- Chatframe Selection 
	DWP.ConfigTab4.ChatFrame = CreateFrame("FRAME", "DWPChatFrameSelectDropDown", DWP.ConfigTab4, "DWPlusUIDropDownMenuTemplate")
	if not DWPlus_DB.defaults.ChatFrames then DWPlus_DB.defaults.ChatFrames = {} end

	UIDropDownMenu_Initialize(DWP.ConfigTab4.ChatFrame, function(self, level, menuList)
	local SelectedFrame = UIDropDownMenu_CreateInfo()
		SelectedFrame.func = self.SetValue
		SelectedFrame.fontObject = "DWPSmallCenter"
		SelectedFrame.keepShownOnClick = true;
		SelectedFrame.isNotRadio = true;

		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i)
			if name ~= "" then
				SelectedFrame.text, SelectedFrame.arg1, SelectedFrame.checked = name, name, DWPlus_DB.defaults.ChatFrames[name]
				UIDropDownMenu_AddButton(SelectedFrame)
			end
		end
	end)

	DWP.ConfigTab4.ChatFrame:SetPoint("LEFT", DWP.ConfigTab4.CombatLogging, "RIGHT", 130, 0)
	UIDropDownMenu_SetWidth(DWP.ConfigTab4.ChatFrame, 150)
	UIDropDownMenu_SetText(DWP.ConfigTab4.ChatFrame, "Addon Notifications")

	function DWP.ConfigTab4.ChatFrame:SetValue(arg1)
		DWPlus_DB.defaults.ChatFrames[arg1] = not DWPlus_DB.defaults.ChatFrames[arg1]
		CloseDropDownMenus()
	end



	-- Position Bid Timer Button
	DWP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", DWP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["MOVEBIDTIMER"]);
	DWP.ConfigTab4.moveTimer:ClearAllPoints();
	DWP.ConfigTab4.moveTimer:SetPoint("LEFT", DWP.ConfigTab4.submitSettings, "RIGHT", 200, 0)
	DWP.ConfigTab4.moveTimer:SetSize(110,25)
	DWP.ConfigTab4.moveTimer:SetScript("OnClick", function()
		if moveTimerToggle == 0 then
			DWP:StartTimer(120, L["MOVEME"])
			DWP.ConfigTab4.moveTimer:SetText(L["HIDEBIDTIMER"])
			moveTimerToggle = 1;
		else
			DWP.BidTimer:SetScript("OnUpdate", nil)
			DWP.BidTimer:Hide()
			DWP.ConfigTab4.moveTimer:SetText(L["MOVEBIDTIMER"])
			moveTimerToggle = 0;
		end
	end)

	-- wipe tables button
	DWP.ConfigTab4.WipeTables = self:CreateButton("BOTTOMRIGHT", DWP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["WIPETABLES"]);
	DWP.ConfigTab4.WipeTables:ClearAllPoints();
	DWP.ConfigTab4.WipeTables:SetPoint("RIGHT", DWP.ConfigTab4.moveTimer, "LEFT", -40, 0)
	DWP.ConfigTab4.WipeTables:SetSize(110,25)
	DWP.ConfigTab4.WipeTables:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WIPETABLES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["WIPETABLESTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab4.WipeTables:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	DWP.ConfigTab4.WipeTables:SetScript("OnClick", function()

		StaticPopupDialogs["WIPE_TABLES"] = {
			text = L["WIPETABLESCONF"],
			button1 = L["YES"],
			button2 = L["NO"],
			OnAccept = function()
				DWPlus_Whitelist = nil
				DWPlus_RPTable = nil
				DWPlus_Loot = nil
				DWPlus_RPHistory = nil
				DWPlus_Archive = nil
				DWPlus_Standby = nil
				DWPlus_MinBids = nil

				DWPlus_RPTable = {}
				DWPlus_Loot = {}
				DWPlus_RPHistory = {}
				DWPlus_Archive = {}
				DWPlus_Consul = {}
				DWPlus_Whitelist = {}
				DWPlus_Standby = {}
				DWPlus_MinBids = {}
				DWP:LootHistory_Reset()
				DWP:FilterDKPTable(core.currentSort, "reset")
				DWP:StatusVerify_Update()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("WIPE_TABLES")
	end)

	-- Options Footer (empty frame to push bottom of scrollframe down)
	DWP.ConfigTab4.OptionsFooterFrame = CreateFrame("Frame", nil, DWP.ConfigTab4);
	DWP.ConfigTab4.OptionsFooterFrame:SetPoint("TOPLEFT", DWP.ConfigTab4.moveTimer, "BOTTOMLEFT")
	DWP.ConfigTab4.OptionsFooterFrame:SetSize(420, 50);
end