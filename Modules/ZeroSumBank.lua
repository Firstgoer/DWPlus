local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local function ZeroSumDistribution()
	if IsInRaid() and core.IsOfficer then
		local curTime = time();
		local distribution;
		local reason = DWPlus_DB.bossargs.CurrentRaidZone..": "..DWPlus_DB.bossargs.LastKilledBoss
		local players = "";
		local VerifyTable = {};
		local curOfficer = UnitName("player")

		if DWPlus_DB.modes.ZeroSumStandby then
			for i=1, #DWPlus_Standby do
				tinsert(VerifyTable, DWPlus_Standby[i].player)
			end
		end		

		for i=1, 40 do
			local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
			local search = DWP:Table_Search(VerifyTable, tempName)
			local search2 = DWP:Table_Search(DWPlus_RPTable, tempName)
			local OnlineOnly = DWPlus_DB.modes.OnlineOnly
			local limitToZone = DWPlus_DB.modes.SameZoneOnly
			local isSameZone = zone == GetRealZoneText()

			if not search and search2 and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
				tinsert(VerifyTable, tempName)
			end
		end

		distribution = DWP_round(DWPlus_DB.modes.ZeroSumBank.balance / #VerifyTable, DWPlus_DB.modes.rounding) + DWPlus_DB.modes.Inflation

		for i=1, #VerifyTable do
			local name = VerifyTable[i]
			local search = DWP:Table_Search(DWPlus_RPTable, name)

			if search then
				DWPlus_RPTable[search[1][1]].dkp = DWPlus_RPTable[search[1][1]].dkp + distribution
				players = players..name..","
			end
		end
		
		local newIndex = curOfficer.."-"..curTime
		tinsert(DWPlus_RPHistory, 1, {players=players, dkp=distribution, reason=reason, date=curTime, index=newIndex})
		if DWP.ConfigTab6.history then
			DWP:DKPHistory_Update(true)
		end

		DWP.Sync:SendData("DWPDKPDist", DWPlus_RPHistory[1])
		DWP.Sync:SendData("DWPBCastMsg", L["RAIDDKPADJUSTBY"].." "..distribution.." "..L["AMONG"].." "..#VerifyTable.." "..L["PLAYERSFORREASON"]..": "..reason)
		DWP:Print("Raid RP Adjusted by "..distribution.." "..L["AMONG"].." "..#VerifyTable.." "..L["PLAYERSFORREASON"]..": "..reason)
		
		table.wipe(VerifyTable)
		table.wipe(DWPlus_DB.modes.ZeroSumBank)
		DWPlus_DB.modes.ZeroSumBank.balance = 0
		core.ZeroSumBank.LootFrame.LootList:SetText("")
		DKPTable_Update()
		DWP.Sync:SendData("DWPZSumBank", DWPlus_DB.modes.ZeroSumBank)
		DWP:ZeroSumBank_Update()
		core.ZeroSumBank:Hide();
	else
		DWP:Print(L["NOTINRAIDPARTY"])
	end
end

function DWP:ZeroSumBank_Update()
	core.ZeroSumBank.Boss:SetText(DWPlus_DB.bossargs.LastKilledBoss.." in "..DWPlus_DB.bossargs.CurrentRaidZone)
	core.ZeroSumBank.Balance:SetText(DWPlus_DB.modes.ZeroSumBank.balance)

	for i=1, #DWPlus_DB.modes.ZeroSumBank do
 		if i==1 then
 			core.ZeroSumBank.LootFrame.LootList:SetText(DWPlus_DB.modes.ZeroSumBank[i].loot.." "..L["FOR"].." "..DWPlus_DB.modes.ZeroSumBank[i].cost.." "..L["RP"].."\n")
 		else
 			core.ZeroSumBank.LootFrame.LootList:SetText(core.ZeroSumBank.LootFrame.LootList:GetText()..DWPlus_DB.modes.ZeroSumBank[i].loot.." "..L["FOR"].." "..DWPlus_DB.modes.ZeroSumBank[i].cost.." "..L["RP"].."\n")
 		end
 	end
 	
 	if core.ZeroSumBank.LootFrame.LootList:GetHeight() > 180 then
 		core.ZeroSumBank.LootFrame:SetHeight(core.ZeroSumBank.LootFrame.LootList:GetHeight() + 18)
 		core.ZeroSumBank:SetHeight(350 + core.ZeroSumBank.LootFrame.LootList:GetHeight() - 170)
 	end
end

function DWP:ZeroSumBank_Create()
	local f = CreateFrame("Frame", "DWP_DKPZeroSumBankFrame", UIParent, "ShadowOverlaySmallTemplate");

	if not DWPlus_DB.modes.ZeroSumBank then DWPlus_DB.modes.ZeroSumBank = 0 end

	f:SetPoint("TOP", UIParent, "TOP", 400, -50);
	f:SetSize(325, 350);
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("FULLSCREEN")
	f:SetFrameLevel(20)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", f.StopMovingOrSizing);
	f:Hide()

	-- Close Button
	f.closeContainer = CreateFrame("Frame", "DWPZeroSumBankWindowCloseButtonContainer", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)

	f.BankHeader = f:CreateFontString(nil, "OVERLAY")
	f.BankHeader:SetFontObject("DWPLargeLeft");
	f.BankHeader:SetScale(1)
	f.BankHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10);
	f.BankHeader:SetText(L["ZEROSUMBANK"])

	f.Boss = f:CreateFontString(nil, "OVERLAY")
	f.Boss:SetFontObject("DWPSmallLeft");
	f.Boss:SetPoint("TOPLEFT", f, "TOPLEFT", 60, -45);

	f.Boss.Header = f:CreateFontString(nil, "OVERLAY")
	f.Boss.Header:SetFontObject("DWPLargeRight");
	f.Boss.Header:SetScale(0.7)
	f.Boss.Header:SetPoint("RIGHT", f.Boss, "LEFT", -7, 0);
	f.Boss.Header:SetText(L["BOSS"]..": ")

	f.Balance = CreateFrame("EditBox", nil, f)
	f.Balance:SetPoint("TOPLEFT", f, "TOPLEFT", 70, -65)   
    f.Balance:SetAutoFocus(false)
    f.Balance:SetMultiLine(false)
    f.Balance:SetSize(85, 28)
    f.Balance:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\slider-border", tile = true, tileSize = 1, edgeSize = 2,
    });
    f.Balance:SetBackdropColor(0,0,0,0.9)
    f.Balance:SetBackdropBorderColor(1,1,1,0.4)
    f.Balance:SetMaxLetters(10)
    f.Balance:SetTextColor(1, 1, 1, 1)
    f.Balance:SetFontObject("DWPSmallLeft")
    f.Balance:SetTextInsets(10, 10, 5, 5)
    f.Balance:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    f.Balance:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ZEROSUMBALANCE"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ZEROSUMBALANCETTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.Balance:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	f.Balance.Header = f:CreateFontString(nil, "OVERLAY")
	f.Balance.Header:SetFontObject("DWPLargeRight");
	f.Balance.Header:SetScale(0.7)
	f.Balance.Header:SetPoint("RIGHT", f.Balance, "LEFT", -7, 0);
	f.Balance.Header:SetText(L["BALANCE"]..": ")

	f.Distribute = CreateFrame("Button", "DWPBiddingDistributeButton", f, "DWPlusButtonTemplate")
	f.Distribute:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -95);
	f.Distribute:SetSize(90, 25);
	f.Distribute:SetText(L["DISTRIBUTEDKP"]);
	f.Distribute:GetFontString():SetTextColor(1, 1, 1, 1)
	f.Distribute:SetNormalFontObject("DWPSmallCenter");
	f.Distribute:SetHighlightFontObject("DWPSmallCenter");
	f.Distribute:SetScript("OnClick", function (self)
		if DWPlus_DB.modes.ZeroSumBank.balance > 0 then
			StaticPopupDialogs["CONFIRM_ADJUST1"] = {
				text = L["DISTRIBUTEALLDKPCONF"],
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					ZeroSumDistribution()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("CONFIRM_ADJUST1")
		else
			DWP:Print(L["NOPOINTSTODISTRIBUTE"])
		end
	end)
	f.Distribute:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["DISTRIBUTEDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["DISTRUBUTEBANKED"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.Distribute:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Include Standby Checkbox
	f.IncludeStandby = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.IncludeStandby:SetChecked(DWPlus_DB.modes.ZeroSumStandby)
	f.IncludeStandby:SetScale(0.6);
	f.IncludeStandby.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
	f.IncludeStandby.text:SetScale(1.5);
	f.IncludeStandby.text:SetFontObject("DWPSmallLeft")
	f.IncludeStandby:SetPoint("TOPLEFT", f.Distribute, "BOTTOMLEFT", -15, -10);
	f.IncludeStandby:SetScript("OnClick", function(self)
		DWPlus_DB.modes.ZeroSumStandby = self:GetChecked();
		PlaySound(808)
	end)
	f.IncludeStandby:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["INCLUDESTANDBYLIST"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["INCSTANDBYLISTTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["INCSTANDBYLISTTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	f.IncludeStandby:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Loot List Frame
	f.LootFrame = CreateFrame("Frame", "DWPZeroSumBankLootListContainer", f, "ShadowOverlaySmallTemplate")
	f.LootFrame:SetPoint("TOPRIGHT", f.IncludeStandby, "BOTTOM", 95, -5)
	f.LootFrame:SetSize(305, 190)
	f.LootFrame:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	f.LootFrame:SetBackdropColor(0,0,0,0.9)
	f.LootFrame:SetBackdropBorderColor(1,1,1,1)

	f.LootFrame.Header = f.LootFrame:CreateFontString(nil, "OVERLAY")
	f.LootFrame.Header:SetFontObject("DWPLargeLeft");
	f.LootFrame.Header:SetScale(0.7)
	f.LootFrame.Header:SetPoint("TOPLEFT", f.LootFrame, "TOPLEFT", 8, -8);
	f.LootFrame.Header:SetText(L["LOOTBANKED"])

	f.LootFrame.LootList = f.LootFrame:CreateFontString(nil, "OVERLAY")
	f.LootFrame.LootList:SetFontObject("DWPNormalLeft");
	f.LootFrame.LootList:SetPoint("TOPLEFT", f.LootFrame, "TOPLEFT", 8, -18);
	f.LootFrame.LootList:SetText("")

	return f
end