local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local curReason;

function DWP:AdjustDKP(value)
	local adjustReason = curReason;
	local curTime = time()
	local c;
	local curOfficer = UnitName("player")

	if not IsInRaid() then
		c = DWP:GetCColors();
	end

	if (curReason == L["OTHER"]) then adjustReason = L["OTHER"].." - "..DWP.ConfigTab2.otherReason:GetText(); end
	if curReason == L["BOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." ("..L["TRAINING"]..")"; end
	if curReason == L["NEWBOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." ("..L["FIRSTKILL"]..")" end
	if (#core.SelectedData > 0 and adjustReason and adjustReason ~= L["OTHER"].." - "..L["ENTEROTHERREASONHERE"]) then
		if core.IsOfficer then
			local tempString = "";       -- stores list of changes
			local dkpHistoryString = ""   -- stores list for DWPlus_RPHistory
			for i=1, #core.SelectedData do
				local current;
				local search = DWP:Table_Search(DWPlus_RPTable, core.SelectedData[i]["player"])
				if search then
					if not IsInRaid() then
						if i < #core.SelectedData then
							tempString = tempString.."|cff"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r, ";
						else
							tempString = tempString.."|cff"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r";
						end
					end
					dkpHistoryString = dkpHistoryString..core.SelectedData[i]["player"]..","
					current = DWPlus_RPTable[search[1][1]].dkp
					DWPlus_RPTable[search[1][1]].dkp = DWP_round(tonumber(current + value), DWPlus_DB.modes.rounding)
					if value > 0 then
						DWPlus_RPTable[search[1][1]]["lifetime_gained"] = DWP_round(tonumber(DWPlus_RPTable[search[1][1]]["lifetime_gained"] + value), DWPlus_DB.modes.rounding)
					end
				end
			end
			local newIndex = curOfficer.."-"..curTime
			tinsert(DWPlus_RPHistory, 1, {players=dkpHistoryString, dkp=value, reason=adjustReason, date=curTime, index=newIndex})
			DWP.Sync:SendData("DWPDKPDist", DWPlus_RPHistory[1])

			if DWP.ConfigTab6.history and DWP.ConfigTab6:IsShown() then
				DWP:DKPHistory_Update(true)
			end
			DKPTable_Update()
			if IsInRaid() then
				DWP.Sync:SendData("DWPBCastMsg", L["RAIDDKPADJUSTBY"].." "..value.." "..L["FORREASON"]..": "..adjustReason)
			else
				DWP.Sync:SendData("DWPBCastMsg", L["DKPADJUSTBY"].." "..value.." "..L["FORPLAYERS"]..": ")
				DWP.Sync:SendData("DWPBCastMsg", tempString)
				DWP.Sync:SendData("DWPBCastMsg", L["REASON"]..": "..adjustReason)
			end
		end
	else
		local validation;
		if (#core.SelectedData == 0 and not adjustReason) then
			validation = L["PLAYERREASONVALIDATE"]
		elseif #core.SelectedData == 0 then
			validation = L["PLAYERVALIDATE"]
		elseif not adjustReason or DWP.ConfigTab2.otherReason:GetText() == "" or DWP.ConfigTab2.otherReason:GetText() == L["ENTEROTHERREASONHERE"] then
			validation = L["OTHERREASONVALIDATE"]
		end

		StaticPopupDialogs["VALIDATION_PROMPT"] = {
			text = validation,
			button1 = L["OK"],
			timeout = 5,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("VALIDATION_PROMPT")
	end
end

local function DecayDKP(amount, deductionType, GetSelections)
	local playerString = "";
	local dkpString = "";
	local curTime = time()
	local curOfficer = UnitName("player")

	for key, value in ipairs(DWPlus_RPTable) do
		local dkp = tonumber(value["dkp"])
		local player = value["player"]
		local amount = amount;
		amount = tonumber(amount) / 100		-- converts percentage to a decimal
		if amount < 0 then
			amount = amount * -1			-- flips value to positive if officer accidently used negative number in editbox
		end
		local deducted;

		if (GetSelections and DWP:Table_Search(core.SelectedData, player)) or GetSelections == false then
			if dkp > 0 then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = dkp - deducted
					value["dkp"] = DWP_round(tonumber(dkp), DWPlus_DB.modes.rounding);
					dkpString = dkpString.."-"..DWP_round(deducted, DWPlus_DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end
			elseif dkp < 0 and DWP.ConfigTab2.AddNegative:GetChecked() then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = (deducted - dkp) * -1
					value["dkp"] = DWP_round(tonumber(dkp), DWPlus_DB.modes.rounding)
					dkpString = dkpString..DWP_round(-deducted, DWPlus_DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end	
			end
		end
	end
	dkpString = dkpString.."-"..amount.."%";

	if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

	local newIndex = curOfficer.."-"..curTime
	tinsert(DWPlus_RPHistory, 1, {players=playerString, dkp=dkpString, reason=L["WEEKLYDECAY"], date=curTime, index=newIndex})
	DWP.Sync:SendData("DWPDecay", DWPlus_RPHistory[1])
	if DWP.ConfigTab6.history then
		DWP:DKPHistory_Update(true)
	end
	DKPTable_Update()
end

local function RaidTimerPopout_Create()
	if not DWP.RaidTimerPopout then
		DWP.RaidTimerPopout = CreateFrame("Frame", "DWP_RaidTimerPopout", UIParent, "ShadowOverlaySmallTemplate");

	    DWP.RaidTimerPopout:SetPoint("RIGHT", UIParent, "RIGHT", -300, 100);
	    DWP.RaidTimerPopout:SetSize(100, 50);
	    DWP.RaidTimerPopout:SetBackdrop( {
	      bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
	      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	      insets = { left = 0, right = 0, top = 0, bottom = 0 }
	    });
	    DWP.RaidTimerPopout:SetBackdropColor(0,0,0,0.9);
	    DWP.RaidTimerPopout:SetBackdropBorderColor(1,1,1,1)
	    DWP.RaidTimerPopout:SetFrameStrata("DIALOG")
	    DWP.RaidTimerPopout:SetFrameLevel(15)
	    DWP.RaidTimerPopout:SetMovable(true);
	    DWP.RaidTimerPopout:EnableMouse(true);
	    DWP.RaidTimerPopout:RegisterForDrag("LeftButton");
	    DWP.RaidTimerPopout:SetScript("OnDragStart", DWP.RaidTimerPopout.StartMoving);
	    DWP.RaidTimerPopout:SetScript("OnDragStop", DWP.RaidTimerPopout.StopMovingOrSizing);

	    -- Popout Close Button
	    DWP.RaidTimerPopout.closeContainer = CreateFrame("Frame", "DWPChangeLogClose", DWP.RaidTimerPopout)
	    DWP.RaidTimerPopout.closeContainer:SetPoint("CENTER", DWP.RaidTimerPopout, "TOPRIGHT", -8, -4)
	    DWP.RaidTimerPopout.closeContainer:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	    });
	    DWP.RaidTimerPopout.closeContainer:SetBackdropColor(0,0,0,0.9)
	    DWP.RaidTimerPopout.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	    DWP.RaidTimerPopout.closeContainer:SetScale(0.7)
	    DWP.RaidTimerPopout.closeContainer:SetSize(28, 28)

	    DWP.RaidTimerPopout.closeBtn = CreateFrame("Button", nil, DWP.RaidTimerPopout, "UIPanelCloseButton")
	    DWP.RaidTimerPopout.closeBtn:SetPoint("CENTER", DWP.RaidTimerPopout.closeContainer, "TOPRIGHT", -14, -14)
	    DWP.RaidTimerPopout.closeBtn:SetScale(0.7)
	    DWP.RaidTimerPopout.closeBtn:HookScript("OnClick", function()
	    	DWP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">");
	    end)

	    -- Raid Timer Output
	    DWP.RaidTimerPopout.Output = DWP.RaidTimerPopout:CreateFontString(nil, "OVERLAY")
	    DWP.RaidTimerPopout.Output:SetFontObject("DWPLargeLeft");
	    DWP.RaidTimerPopout.Output:SetScale(0.8)
	    DWP.RaidTimerPopout.Output:SetPoint("CENTER", DWP.RaidTimerPopout, "CENTER", 0, 0);
	    DWP.RaidTimerPopout.Output:SetText("|cff00ff0000:00:00|r")
	    DWP.RaidTimerPopout:Hide();
	else
		DWP.RaidTimerPopout:Show()
	end
end

function DWP:AdjustDKPTab_Create()
	DWP.ConfigTab2.header = DWP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab2.header:SetPoint("TOPLEFT", DWP.ConfigTab2, "TOPLEFT", 15, -10);
	DWP.ConfigTab2.header:SetFontObject("DWPLargeCenter")
	DWP.ConfigTab2.header:SetText(L["ADJUSTDKP"]);
	DWP.ConfigTab2.header:SetScale(1.2)

	DWP.ConfigTab2.description = DWP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab2.description:SetPoint("TOPLEFT", DWP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
	DWP.ConfigTab2.description:SetWidth(400)
	DWP.ConfigTab2.description:SetFontObject("DWPNormalLeft")
	DWP.ConfigTab2.description:SetText(L["ADJUSTDESC"]);

	-- Reason DROPDOWN box 
	-- Create the dropdown, and configure its appearance
	DWP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "DWPConfigReasonDropDown", DWP.ConfigTab2, "DWPlusUIDropDownMenuTemplate")
	DWP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", DWP.ConfigTab2.description, "BOTTOMLEFT", -23, -60)
	UIDropDownMenu_SetWidth(DWP.ConfigTab2.reasonDropDown, 150)
	UIDropDownMenu_SetText(DWP.ConfigTab2.reasonDropDown, L["SELECTREASON"])

	-- Create and bind the initialization function to the dropdown menu
	UIDropDownMenu_Initialize(DWP.ConfigTab2.reasonDropDown, function(self, level, menuList)
	local reason = UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "DWPSmallCenter"
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["ONTIMEBONUS"], L["ONTIMEBONUS"], L["ONTIMEBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["BOSSKILLBONUS"], L["BOSSKILLBONUS"], L["BOSSKILLBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["CORRECTINGERROR"], L["CORRECTINGERROR"], L["CORRECTINGERROR"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["DKPADJUST"], L["DKPADJUST"], L["DKPADJUST"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["ABSENSE"], L["ABSENSE"], L["ABSENSE"] == curReason, true
		UIDropDownMenu_AddButton(reason)
		reason.text, reason.arg1, reason.checked, reason.isNotRadio = L["OTHER"], L["OTHER"], L["OTHER"] == curReason, true
		UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function DWP.ConfigTab2.reasonDropDown:SetValue(newValue)
		if curReason ~= newValue then curReason = newValue else curReason = nil end

		UIDropDownMenu_SetText(DWP.ConfigTab2.reasonDropDown, curReason)

		if (curReason == L["ONTIMEBONUS"]) then DWP.ConfigTab2.addDKP:SetNumber(DWPlus_DB.DKPBonus.OnTimeBonus); DWP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["BOSSKILLBONUS"]) then
			DWP.ConfigTab2.addDKP:SetNumber(DWPlus_DB.DKPBonus.BossKillBonus);
			DWP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(DWP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["RAIDCOMPLETIONBONUS"]) then DWP.ConfigTab2.addDKP:SetNumber(DWPlus_DB.DKPBonus.CompletionBonus); DWP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["NEWBOSSKILLBONUS"]) then
			DWP.ConfigTab2.addDKP:SetNumber(DWPlus_DB.DKPBonus.NewBossKillBonus);
			DWP.ConfigTab2.BossKilledDropdown:Show()
			UIDropDownMenu_SetText(DWP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["UNEXCUSEDABSENCE"]) then DWP.ConfigTab2.addDKP:SetNumber(DWPlus_DB.DKPBonus.UnexcusedAbsence); DWP.ConfigTab2.BossKilledDropdown:Hide()
		else DWP.ConfigTab2.addDKP:SetText(""); DWP.ConfigTab2.BossKilledDropdown:Hide() end

		if (curReason == L["OTHER"]) then
			DWP.ConfigTab2.otherReason:Show();
			DWP.ConfigTab2.BossKilledDropdown:Hide()
		else
			DWP.ConfigTab2.otherReason:Hide();
		end

		CloseDropDownMenus()
	end

	DWP.ConfigTab2.reasonDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["REASON"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["REASONTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["REASONTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.reasonDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	DWP.ConfigTab2.reasonHeader = DWP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	DWP.ConfigTab2.reasonHeader:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.reasonHeader:SetText(L["REASONFORADJUSTMENT"]..":")

	-- Other Reason Editbox. Hidden unless "Other" is selected in dropdown
	DWP.ConfigTab2.otherReason = CreateFrame("EditBox", nil, DWP.ConfigTab2)
	DWP.ConfigTab2.otherReason:SetPoint("TOPLEFT", DWP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 19, 2)
	DWP.ConfigTab2.otherReason:SetAutoFocus(false)
	DWP.ConfigTab2.otherReason:SetMultiLine(false)
	DWP.ConfigTab2.otherReason:SetSize(225, 24)
	DWP.ConfigTab2.otherReason:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
	});
	DWP.ConfigTab2.otherReason:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab2.otherReason:SetBackdropBorderColor(1,1,1,0.6)
	DWP.ConfigTab2.otherReason:SetMaxLetters(50)
	DWP.ConfigTab2.otherReason:SetTextColor(0.4, 0.4, 0.4, 1)
	DWP.ConfigTab2.otherReason:SetFontObject("DWPNormalLeft")
	DWP.ConfigTab2.otherReason:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab2.otherReason:SetText(L["ENTEROTHERREASONHERE"])
	DWP.ConfigTab2.otherReason:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:ClearFocus()
	end)
	DWP.ConfigTab2.otherReason:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() == L["ENTEROTHERREASONHERE"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	DWP.ConfigTab2.otherReason:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["ENTEROTHERREASONHERE"])
			self:SetTextColor(0.4, 0.4, 0.4, 1)
		end
	end)
	DWP.ConfigTab2.otherReason:Hide();

	-- Boss Killed Dropdown - Hidden unless "Boss Kill Bonus" or "New Boss Kill Bonus" is selected
	-- Killing a boss on the list will auto select that boss
	DWP.ConfigTab2.BossKilledDropdown = CreateFrame("FRAME", "DWPBossKilledDropdown", DWP.ConfigTab2, "DWPlusUIDropDownMenuTemplate")
	DWP.ConfigTab2.BossKilledDropdown:SetPoint("TOPLEFT", DWP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 0, 2)
	DWP.ConfigTab2.BossKilledDropdown:Hide()
	UIDropDownMenu_SetWidth(DWP.ConfigTab2.BossKilledDropdown, 210)
	UIDropDownMenu_SetText(DWP.ConfigTab2.BossKilledDropdown, L["SELECTBOSS"])

	UIDropDownMenu_Initialize(DWP.ConfigTab2.BossKilledDropdown, function(self, level, menuList)
		local boss = UIDropDownMenu_CreateInfo()
		boss.fontObject = "DWPSmallCenter"
		if (level or 1) == 1 then
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[1], core.CurrentRaidZone == core.ZoneList[1], "MC", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[2], core.CurrentRaidZone == core.ZoneList[2], "BWL", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[3], core.CurrentRaidZone == core.ZoneList[3], "AQ", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[4], core.CurrentRaidZone == core.ZoneList[4], "NAXX", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[7], core.CurrentRaidZone == core.ZoneList[7], "ONYXIA", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[5], core.CurrentRaidZone == core.ZoneList[5], "ZG", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[6], core.CurrentRaidZone == core.ZoneList[6], "AQ20", true
			UIDropDownMenu_AddButton(boss)
			boss.text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[8], core.CurrentRaidZone == core.ZoneList[8], "WORLD", true
			UIDropDownMenu_AddButton(boss)
		else
			boss.func = self.SetValue
			for i=1, #core.BossList[menuList] do
				boss.text, boss.arg1, boss.checked = core.BossList[menuList][i], core.EncounterList[menuList][i], core.BossList[menuList][i] == core.LastKilledBoss
				UIDropDownMenu_AddButton(boss, level)
			end
		end
	end)

	function DWP.ConfigTab2.BossKilledDropdown:SetValue(newValue)
		local search = DWP:Table_Search(core.EncounterList, newValue);
		
		if DWP:Table_Search(core.EncounterList.MC, newValue) then
			core.CurrentRaidZone = core.ZoneList[1]
		elseif DWP:Table_Search(core.EncounterList.BWL, newValue) then
			core.CurrentRaidZone = core.ZoneList[2]
		elseif DWP:Table_Search(core.EncounterList.AQ, newValue) then
			core.CurrentRaidZone = core.ZoneList[3]
		elseif DWP:Table_Search(core.EncounterList.NAXX, newValue) then
			core.CurrentRaidZone = core.ZoneList[4]
		elseif DWP:Table_Search(core.EncounterList.ZG, newValue) then
			core.CurrentRaidZone = core.ZoneList[5]
		elseif DWP:Table_Search(core.EncounterList.AQ20, newValue) then
			core.CurrentRaidZone = core.ZoneList[6]
		elseif DWP:Table_Search(core.EncounterList.ONYXIA, newValue) then
			core.CurrentRaidZone = core.ZoneList[7]
		--elseif DWP:Table_Search(core.EncounterList.WORLD, newValue) then 		-- encounter IDs not known yet
			--core.CurrentRaidZone = core.ZoneList[8]
		end

		if search then
			core.LastKilledBoss = core.BossList[search[1][1]][search[1][2]]
		else
			return;
		end

		DWPlus_DB.bossargs["LastKilledBoss"] = core.LastKilledBoss;
		DWPlus_DB.bossargs["CurrentRaidZone"] = core.CurrentRaidZone;

		if curReason ~= L["BOSSKILLBONUS"] and curReason ~= L["NEWBOSSKILLBONUS"] then
			DWP.ConfigTab2.reasonDropDown:SetValue(L["BOSSKILLBONUS"])
		end
		UIDropDownMenu_SetText(DWP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		CloseDropDownMenus()
	end

	-- Add DKP Edit Box
	DWP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, DWP.ConfigTab2)
	DWP.ConfigTab2.addDKP:SetPoint("TOPLEFT", DWP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 20, -44)
	DWP.ConfigTab2.addDKP:SetAutoFocus(false)
	DWP.ConfigTab2.addDKP:SetMultiLine(false)
	DWP.ConfigTab2.addDKP:SetSize(100, 24)
	DWP.ConfigTab2.addDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab2.addDKP:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab2.addDKP:SetBackdropBorderColor(1,1,1,0.6)
	DWP.ConfigTab2.addDKP:SetMaxLetters(10)
	DWP.ConfigTab2.addDKP:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab2.addDKP:SetFontObject("DWPNormalRight")
	DWP.ConfigTab2.addDKP:SetTextInsets(10, 10, 5, 5)
	DWP.ConfigTab2.addDKP:SetScript("OnEscapePressed", function(self)    -- clears text and focus on esc
		self:SetText("")
		self:ClearFocus()
	end)
	DWP.ConfigTab2.addDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["POINTS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["POINTSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["POINTSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.addDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	DWP.ConfigTab2.pointsHeader = DWP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	DWP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	DWP.ConfigTab2.pointsHeader:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.pointsHeader:SetText(L["POINTS"]..":")

	-- Raid Only Checkbox
	DWP.ConfigTab2.RaidOnlyCheck = CreateFrame("CheckButton", nil, DWP.ConfigTab2, "UICheckButtonTemplate");
	DWP.ConfigTab2.RaidOnlyCheck:SetChecked(false)
	DWP.ConfigTab2.RaidOnlyCheck:SetScale(0.6);
	DWP.ConfigTab2.RaidOnlyCheck.text:SetText("  |cff5151deShow Raid Only|r");
	DWP.ConfigTab2.RaidOnlyCheck.text:SetScale(1.5);
	DWP.ConfigTab2.RaidOnlyCheck.text:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.RaidOnlyCheck:SetPoint("LEFT", DWP.ConfigTab2.addDKP, "RIGHT", 15, 13);
	DWP.ConfigTab2.RaidOnlyCheck:Hide()
	

	-- Select All Checkbox
	DWP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, DWP.ConfigTab2, "UICheckButtonTemplate");
	DWP.ConfigTab2.selectAll:SetChecked(false)
	DWP.ConfigTab2.selectAll:SetScale(0.6);
	DWP.ConfigTab2.selectAll.text:SetText("  |cff5151de"..L["SELECTALLVISIBLE"].."|r");
	DWP.ConfigTab2.selectAll.text:SetScale(1.5);
	DWP.ConfigTab2.selectAll.text:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.selectAll:SetPoint("LEFT", DWP.ConfigTab2.addDKP, "RIGHT", 15, -13);
	DWP.ConfigTab2.selectAll:Hide();
	

		-- Adjust DKP Button
	DWP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", DWP.ConfigTab2.addDKP, "BOTTOMLEFT", -1, -15, L["ADJUSTDKP"]);
	DWP.ConfigTab2.adjustButton:SetSize(90,25)
	DWP.ConfigTab2.adjustButton:SetScript("OnClick", function()
		if #core.SelectedData > 0 and curReason and DWP.ConfigTab2.otherReason:GetText() then
			local selected = L["AREYOUSURE"].." "..DWP_round(DWP.ConfigTab2.addDKP:GetNumber(), DWPlus_DB.modes.rounding).." "..L["DKPTOFOLLOWING"]..": \n\n";

			for i=1, #core.SelectedData do
				if i == 1 then
					selected = selected..DWP:GetPlayerNameWithColor(core.SelectedData[i].player);
				else
					selected = selected..", "..DWP:GetPlayerNameWithColor(core.SelectedData[i].player);
				end
			end
			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					DWP:AdjustDKP(DWP.ConfigTab2.addDKP:GetNumber())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
		else
			DWP:AdjustDKP(DWP.ConfigTab2.addDKP:GetNumber());
		end
	end)
	DWP.ConfigTab2.adjustButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADJUSTDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.adjustButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- weekly decay Editbox
	DWP.ConfigTab2.decayDKP = CreateFrame("EditBox", nil, DWP.ConfigTab2)
	DWP.ConfigTab2.decayDKP:SetPoint("BOTTOMLEFT", DWP.ConfigTab2, "BOTTOMLEFT", 21, 70)
	DWP.ConfigTab2.decayDKP:SetAutoFocus(false)
	DWP.ConfigTab2.decayDKP:SetMultiLine(false)
	DWP.ConfigTab2.decayDKP:SetSize(100, 24)
	DWP.ConfigTab2.decayDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	DWP.ConfigTab2.decayDKP:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab2.decayDKP:SetBackdropBorderColor(1,1,1,0.6)
	DWP.ConfigTab2.decayDKP:SetMaxLetters(4)
	DWP.ConfigTab2.decayDKP:SetTextColor(1, 1, 1, 1)
	DWP.ConfigTab2.decayDKP:SetFontObject("DWPNormalRight")
	DWP.ConfigTab2.decayDKP:SetTextInsets(10, 15, 5, 5)
	DWP.ConfigTab2.decayDKP:SetNumber(tonumber(DWPlus_DB.DKPBonus.DecayPercentage))
	DWP.ConfigTab2.decayDKP:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)

	DWP.ConfigTab2.decayDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.decayDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	DWP.ConfigTab2.decayDKPHeader = DWP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab2.decayDKPHeader:SetFontObject("GameFontHighlightLeft");
	DWP.ConfigTab2.decayDKPHeader:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.decayDKP, "TOPLEFT", 3, 3);
	DWP.ConfigTab2.decayDKPHeader:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.decayDKPHeader:SetText(L["WEEKLYDKPDECAY"]..":")

	DWP.ConfigTab2.decayDKPFooter = DWP.ConfigTab2.decayDKP:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab2.decayDKPFooter:SetFontObject("DWPNormalLeft");
	DWP.ConfigTab2.decayDKPFooter:SetPoint("LEFT", DWP.ConfigTab2.decayDKP, "RIGHT", -15, 0);
	DWP.ConfigTab2.decayDKPFooter:SetText("%")

	-- selected players only checkbox
	DWP.ConfigTab2.SelectedOnlyCheck = CreateFrame("CheckButton", nil, DWP.ConfigTab2, "UICheckButtonTemplate");
	DWP.ConfigTab2.SelectedOnlyCheck:SetChecked(false)
	DWP.ConfigTab2.SelectedOnlyCheck:SetScale(0.6);
	DWP.ConfigTab2.SelectedOnlyCheck.text:SetText("  |cff5151de"..L["SELPLAYERSONLY"].."|r");
	DWP.ConfigTab2.SelectedOnlyCheck.text:SetScale(1.5);
	DWP.ConfigTab2.SelectedOnlyCheck.text:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.SelectedOnlyCheck:SetPoint("TOP", DWP.ConfigTab2.decayDKP, "BOTTOMLEFT", 15, -13);
	DWP.ConfigTab2.SelectedOnlyCheck:SetScript("OnClick", function(self)
		PlaySound(808)
	end)
	DWP.ConfigTab2.SelectedOnlyCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SELPLAYERSONLY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SELPLAYERSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["SELPLAYERSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.SelectedOnlyCheck:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- add to negative dkp checkbox
	DWP.ConfigTab2.AddNegative = CreateFrame("CheckButton", nil, DWP.ConfigTab2, "UICheckButtonTemplate");
	DWP.ConfigTab2.AddNegative:SetChecked(DWPlus_DB.modes.AddToNegative)
	DWP.ConfigTab2.AddNegative:SetScale(0.6);
	DWP.ConfigTab2.AddNegative.text:SetText("  |cff5151de"..L["ADDNEGVALUES"].."|r");
	DWP.ConfigTab2.AddNegative.text:SetScale(1.5);
	DWP.ConfigTab2.AddNegative.text:SetFontObject("DWPSmallLeft")
	DWP.ConfigTab2.AddNegative:SetPoint("TOP", DWP.ConfigTab2.SelectedOnlyCheck, "BOTTOM", 0, 0);
	DWP.ConfigTab2.AddNegative:SetScript("OnClick", function(self)
		DWPlus_DB.modes.AddToNegative = self:GetChecked();
		PlaySound(808)
	end)
	DWP.ConfigTab2.AddNegative:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDNEGVALUES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDNEGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADDNEGTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.AddNegative:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	DWP.ConfigTab2.decayButton = self:CreateButton("TOPLEFT", DWP.ConfigTab2.decayDKP, "TOPRIGHT", 20, 0, L["APPLYDECAY"]);
	DWP.ConfigTab2.decayButton:SetSize(90,25)
	DWP.ConfigTab2.decayButton:SetScript("OnClick", function()
		local SelectedToggle;
		local selected;

		if DWP.ConfigTab2.SelectedOnlyCheck:GetChecked() then SelectedToggle = "|cffff0000"..L["SELECTED"].."|r" else SelectedToggle = "|cffff0000"..L["ALL"].."|r" end
		selected = L["CONFIRMDECAY"].." "..SelectedToggle.." "..L["DKPENTRIESBY"].." "..DWP.ConfigTab2.decayDKP:GetNumber().."%%";

			StaticPopupDialogs["ADJUST_DKP"] = {
				text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					DecayDKP(DWP.ConfigTab2.decayDKP:GetNumber(), "percent", DWP.ConfigTab2.SelectedOnlyCheck:GetChecked())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
	end)
	DWP.ConfigTab2.decayButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["APPDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["APPDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	DWP.ConfigTab2.decayButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Raid Timer Container
	DWP.ConfigTab2.RaidTimerContainer = CreateFrame("Frame", nil, DWP.ConfigTab2);
	DWP.ConfigTab2.RaidTimerContainer:SetSize(200, 360);
	DWP.ConfigTab2.RaidTimerContainer:SetPoint("RIGHT", DWP.ConfigTab2, "RIGHT", -25, -60)
	DWP.ConfigTab2.RaidTimerContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
	DWP.ConfigTab2.RaidTimerContainer:SetBackdropColor(0,0,0,0.9)
	DWP.ConfigTab2.RaidTimerContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)

		-- Pop out button
		DWP.ConfigTab2.RaidTimerContainer.PopOut = CreateFrame("Button", nil, DWP.ConfigTab2, "UIMenuButtonStretchTemplate")
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetPoint("TOPRIGHT", DWP.ConfigTab2.RaidTimerContainer, "TOPRIGHT", -5, -5)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetHeight(22)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetWidth(18)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetNormalFontObject("DWPLargeCenter")
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetHighlightFontObject("DWPLargeCenter")
		DWP.ConfigTab2.RaidTimerContainer.PopOut:GetFontString():SetTextColor(0, 0.3, 0.7, 1)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetScale(1.2)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameStrata("DIALOG")
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameLevel(15)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">")
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["POPOUTTIMER"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["POPOUTTIMERDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end)
		DWP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnClick", function(self)
			if self:GetText() == ">" then
				self:SetText("<");
				RaidTimerPopout_Create()
			else
				self:SetText(">");
				DWP.RaidTimerPopout:Hide();
			end
		end)

		-- Raid Timer Header
	    DWP.ConfigTab2.RaidTimerContainer.Header = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.Header:SetFontObject("DWPLargeLeft");
	    DWP.ConfigTab2.RaidTimerContainer.Header:SetScale(0.6)
	    DWP.ConfigTab2.RaidTimerContainer.Header:SetPoint("TOPLEFT", DWP.ConfigTab2.RaidTimerContainer, "TOPLEFT", 15, -15);
	    DWP.ConfigTab2.RaidTimerContainer.Header:SetText(L["RAIDTIMER"])

	    -- Raid Timer Output Header
	    DWP.ConfigTab2.RaidTimerContainer.OutputHeader = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetFontObject("DWPNormalRight");
	    DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetPoint("TOP", DWP.ConfigTab2.RaidTimerContainer, "TOP", -20, -40);
	    DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
	    DWP.ConfigTab2.RaidTimerContainer.OutputHeader:Hide();

	    -- Raid Timer Output
	    DWP.ConfigTab2.RaidTimerContainer.Output = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.Output:SetFontObject("DWPLargeLeft");
	    DWP.ConfigTab2.RaidTimerContainer.Output:SetScale(0.8)
	    DWP.ConfigTab2.RaidTimerContainer.Output:SetPoint("LEFT", DWP.ConfigTab2.RaidTimerContainer.OutputHeader, "RIGHT", 5, 0);

	    -- Bonus Awarded Header
	    DWP.ConfigTab2.RaidTimerContainer.BonusHeader = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.BonusHeader:SetFontObject("DWPNormalRight");
	    DWP.ConfigTab2.RaidTimerContainer.BonusHeader:SetPoint("TOP", DWP.ConfigTab2.RaidTimerContainer, "TOP", -15, -60);
	    DWP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
	    DWP.ConfigTab2.RaidTimerContainer.BonusHeader:Hide();

	    -- Bonus Awarded Output
	    DWP.ConfigTab2.RaidTimerContainer.Bonus = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.Bonus:SetFontObject("DWPLargeLeft");
	    DWP.ConfigTab2.RaidTimerContainer.Bonus:SetScale(0.8)
	    DWP.ConfigTab2.RaidTimerContainer.Bonus:SetPoint("LEFT", DWP.ConfigTab2.RaidTimerContainer.BonusHeader, "RIGHT", 5, 0);

	    -- Start Raid Timer Button
	    DWP.ConfigTab2.RaidTimerContainer.StartTimer = self:CreateButton("BOTTOMLEFT", DWP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 135, L["INITRAID"]);
		DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetSize(90,25)
		DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnClick", function(self)
			if not IsInRaid() then
				StaticPopupDialogs["NO_RAID_TIMER"] = {
					text = L["NOTINRAID"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("NO_RAID_TIMER")
				return;
			end
			if not core.RaidInProgress then				
				if DWPlus_DB.DKPBonus.GiveRaidStart and self:GetText() ~= L["CONTINUERAID"] then
					StaticPopupDialogs["START_RAID_BONUS"] = {
						text = L["RAIDTIMERBONUSCONFIRM"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()						
							local setInterval = DWP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
							local setBonus = DWP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
							local setOnTime = tostring(DWP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
							local setGiveEnd = tostring(DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
							local setStandby = tostring(DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
							DWP.Sync:SendData("DWPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
							if DWP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
								DWP.Sync:SendData("DWPBCastMsg", L["RAIDRESUME"])
							else
								DWP.Sync:SendData("DWPBCastMsg", L["RAIDSTART"])
								DWP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
							end
							DWP:StartRaidTimer(false)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("START_RAID_BONUS")
				else
					local setInterval = DWP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
					local setBonus = DWP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
					local setOnTime = tostring(DWP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
					local setGiveEnd = tostring(DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
					local setStandby = tostring(DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
					DWP.Sync:SendData("DWPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
					if DWP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
						DWP.Sync:SendData("DWPBCastMsg", L["RAIDRESUME"])
					else
						DWP.Sync:SendData("DWPBCastMsg", L["RAIDSTART"])
						DWP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
					end
					DWP:StartRaidTimer(false)
				end
			else
				StaticPopupDialogs["END_RAID"] = {
					text = L["ENDCURRAIDCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						DWP.Sync:SendData("DWPBCastMsg", L["RAIDTIMERCONCLUDE"].." "..DWP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
						DWP.Sync:SendData("DWPRaidTime", "stop")
						DWP:StopRaidTimer()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("END_RAID")
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INITRAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INITRAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INITRAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Pause Raid Timer Button
	    DWP.ConfigTab2.RaidTimerContainer.PauseTimer = self:CreateButton("BOTTOMRIGHT", DWP.ConfigTab2.RaidTimerContainer, "BOTTOMRIGHT", -10, 135, L["PAUSERAID"]);
		DWP.ConfigTab2.RaidTimerContainer.PauseTimer:SetSize(90,25)
		DWP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
		DWP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnClick", function(self)
			if core.RaidInProgress then
				local setInterval = DWP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
				local setBonus = DWP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
				local setOnTime = tostring(DWP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
				local setGiveEnd = tostring(DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
				local setStandby = tostring(DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());

				DWP.Sync:SendData("DWPRaidTime", "start,true "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
				DWP.Sync:SendData("DWPBCastMsg", L["RAIDPAUSE"].." "..DWP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
				DWP:StartRaidTimer(true)
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["PAUSERAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["PAUSERAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["PAUSERAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Award Interval Editbox
		if not DWPlus_DB.modes.increment then DWPlus_DB.modes.increment = 60 end
		DWP.ConfigTab2.RaidTimerContainer.interval = CreateFrame("EditBox", nil, DWP.ConfigTab2.RaidTimerContainer)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 35, 225)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetAutoFocus(false)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetMultiLine(false)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetSize(60, 24)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		DWP.ConfigTab2.RaidTimerContainer.interval:SetBackdropColor(0,0,0,0.9)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetBackdropBorderColor(1,1,1,0.6)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetMaxLetters(5)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetTextColor(1, 1, 1, 1)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetFontObject("DWPSmallRight")
		DWP.ConfigTab2.RaidTimerContainer.interval:SetTextInsets(10, 15, 5, 5)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(DWPlus_DB.modes.increment))
		DWP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				DWPlus_DB.modes.increment = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
					text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFocus()
			DWP.ConfigTab2.RaidTimerContainer.bonusvalue:HighlightText()
		end)

		DWP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDINTERVAL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		DWP.ConfigTab2.RaidTimerContainer.intervalHeader = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.intervalHeader:SetFontObject("DWPTinyRight");
	    DWP.ConfigTab2.RaidTimerContainer.intervalHeader:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.RaidTimerContainer.interval, "TOPLEFT", 0, 2);
	    DWP.ConfigTab2.RaidTimerContainer.intervalHeader:SetText(L["INTERVAL"]..":")

	    -- Award Value Editbox
	    if not DWPlus_DB.DKPBonus.IntervalBonus then DWPlus_DB.DKPBonus.IntervalBonus = 15 end
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue = CreateFrame("EditBox", nil, DWP.ConfigTab2.RaidTimerContainer)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetPoint("LEFT", DWP.ConfigTab2.RaidTimerContainer.interval, "RIGHT", 10, 0)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetAutoFocus(false)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMultiLine(false)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetSize(60, 24)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropColor(0,0,0,0.9)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropBorderColor(1,1,1,0.6)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMaxLetters(5)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextColor(1, 1, 1, 1)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFontObject("DWPSmallRight")
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextInsets(10, 15, 5, 5)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(DWPlus_DB.DKPBonus.IntervalBonus))
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				DWPlus_DB.DKPBonus.IntervalBonus = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
					text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			DWP.ConfigTab2.RaidTimerContainer.interval:SetFocus()
			DWP.ConfigTab2.RaidTimerContainer.interval:HighlightText()
		end)

		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		DWP.ConfigTab2.RaidTimerContainer.bonusvalueHeader = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetFontObject("DWPTinyRight");
	    DWP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.RaidTimerContainer.bonusvalue, "TOPLEFT", 0, 2);
	    DWP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetText(L["BONUS"]..":")
    	
    	-- Give On Time Bonus Checkbox
		DWP.ConfigTab2.RaidTimerContainer.StartBonus = CreateFrame("CheckButton", nil, DWP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(DWPlus_DB.DKPBonus.GiveRaidStart)
		DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetScale(0.6);
		DWP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetText("  |cff5151de"..L["GIVEONTIMEBONUS"].."|r");
		DWP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetScale(1.5);
		DWP.ConfigTab2.RaidTimerContainer.StartBonus.text:SetFontObject("DWPSmallLeft")
		DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetPoint("TOPLEFT", DWP.ConfigTab2.RaidTimerContainer.interval, "BOTTOMLEFT", 0, -10);
		DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				DWPlus_DB.DKPBonus.GiveRaidStart = true;
				PlaySound(808)
			else
				DWPlus_DB.DKPBonus.GiveRaidStart = false;
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEONTIMEBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEONTIMETTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Give Raid End Bonus Checkbox
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus = CreateFrame("CheckButton", nil, DWP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(DWPlus_DB.DKPBonus.GiveRaidEnd)
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScale(0.6);
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetText("  |cff5151de"..L["GIVEENDBONUS"].."|r");
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetScale(1.5);
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus.text:SetFontObject("DWPSmallLeft")
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetPoint("TOP", DWP.ConfigTab2.RaidTimerContainer.StartBonus, "BOTTOM", 0, 2);
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				DWPlus_DB.DKPBonus.GiveRaidEnd = true;
				PlaySound(808)
			else
				DWPlus_DB.DKPBonus.GiveRaidEnd = false;
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEENDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEENDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Standby Checkbox
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude = CreateFrame("CheckButton", nil, DWP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(DWPlus_DB.DKPBonus.IncStandby)
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScale(0.6);
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetScale(1.5);
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude.text:SetFontObject("DWPSmallLeft")
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetPoint("TOP", DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus, "BOTTOM", 0, 2);
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnClick", function(self)
			if self:GetChecked() then
				DWPlus_DB.DKPBonus.IncStandby = true;
				PlaySound(808)
			else
				DWPlus_DB.DKPBonus.IncStandby = false;
			end
		end)
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INCLUDESTANDBY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		DWP.ConfigTab2.RaidTimerContainer.TimerWarning = DWP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    DWP.ConfigTab2.RaidTimerContainer.TimerWarning:SetFontObject("DWPTinyLeft");
	    DWP.ConfigTab2.RaidTimerContainer.TimerWarning:SetWidth(180)
	    DWP.ConfigTab2.RaidTimerContainer.TimerWarning:SetPoint("BOTTOMLEFT", DWP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 10);
	    DWP.ConfigTab2.RaidTimerContainer.TimerWarning:SetText("|CFFFF0000"..L["TIMERWARNING"].."|r")
	    RaidTimerPopout_Create()
end