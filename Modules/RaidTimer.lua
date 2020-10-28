local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local awards = 0;  		-- counts the number of hourly DKP awards given
local timer = 0;
local SecondTracker = 0;
local MinuteCount = 0;
local SecondCount = 0;
local StartAwarded = false;
local StartBonus = 0;
local totalAwarded = 0;

function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    
    if tonumber(mins) <= 0 then
    	return secs
    elseif tonumber(hours) <= 0 then
    	return mins..":"..secs
    else
    	return hours..":"..mins..":"..secs
    end
  end
end

function DWP:AwardPlayer(name, amount)
	local search = DWP:Table_Search(DWPlus_RPTable, name, "player")
	local path;

	if search then
		path = DWPlus_RPTable[search[1][1]]
		path.dkp = path.dkp + amount
		path.lifetime_gained = path.lifetime_gained + amount;
	end
end

local function AwardRaid(amount, reason)
	if UnitAffectingCombat("player") then
		C_Timer.After(5, function() AwardRaid(amount, reason) end)
		return;
	end

	local tempName
	local tempList = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	for i=1, 40 do
		local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
		local search_DKP = DWP:Table_Search(DWPlus_RPTable, tempName)
		local OnlineOnly = DWPlus_DB.modes.OnlineOnly
		local limitToZone = DWPlus_DB.modes.SameZoneOnly
		local isSameZone = zone == GetRealZoneText()

		if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
			DWP:AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #DWPlus_Standby > 0 and DWPlus_DB.DKPBonus.IncStandby then
		local i = 1

		while i <= #DWPlus_Standby do
			if strfind(tempList, DWPlus_Standby[i].player) then
				table.remove(DWPlus_Standby, i)
			else
				DWP:AwardPlayer(DWPlus_Standby[i].player, amount)
				tempList = tempList..DWPlus_Standby[i].player..",";
				i=i+1
			end
		end
	end

	if tempList ~= "" then
		local newIndex = curOfficer.."-"..curTime
		tinsert(DWPlus_RPHistory, 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})

		if DWP.ConfigTab6.history and DWP.ConfigTab6:IsShown() then
			DWP:DKPHistory_Update(true)
		end
		DKPTable_Update()

		DWP.Sync:SendData("DWPDKPDist", DWPlus_RPHistory[1])

		DWP.Sync:SendData("DWPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
		DWP:Print(L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
	end
end

function DWP:StopRaidTimer()
	if DWP.RaidTimer then
		DWP.RaidTimer:SetScript("OnUpdate", nil)
	end
	core.RaidInProgress = false
	DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDENDED"]..":")
	DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["INITRAID"])
	DWP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..string.utf8sub(DWP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
	DWP.RaidTimerPopout.Output:SetText(DWP.ConfigTab2.RaidTimerContainer.Output:GetText());
	DWP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
	DWP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["TOTALDKPAWARD"]..":")
	timer = 0;
	awards = 0;
	StartAwarded = false;
	MinuteCount = 0;
	SecondCount = 0;
	SecondTracker = 0;
	StartBonus = 0;

	if IsInRaid() and DWP:CheckRaidLeader() and core.IsOfficer then
		if DWPlus_DB.DKPBonus.GiveRaidEnd then -- Award Raid Completion Bonus
			AwardRaid(DWPlus_DB.DKPBonus.CompletionBonus, L["RAIDCOMPLETIONBONUS"])
			totalAwarded = totalAwarded + tonumber(DWPlus_DB.DKPBonus.CompletionBonus);
			DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	elseif IsInRaid() and core.IsOfficer then
		if DWPlus_DB.DKPBonus.GiveRaidEnd then
			totalAwarded = totalAwarded + tonumber(DWPlus_DB.DKPBonus.CompletionBonus);
			DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	end
end

function DWP:StartRaidTimer(pause, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
	local increment;
	
	DWP.RaidTimer = DWP.RaidTimer or CreateFrame("StatusBar", nil, UIParent)

	if not syncTimer then
		if not pause then
			DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			DWP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if DWPlus_DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(DWPlus_DB.DKPBonus.OnTimeBonus)
				DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				if totalAwarded == 0 then
					DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
				else
					DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
				end
			end
			DWP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			DWP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			DWP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = DWPlus_DB.modes.increment;
			core.RaidInProgress = true
		else
			DWP.RaidTimer:SetScript("OnUpdate", nil)
			DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["CONTINUERAID"])
			DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDPAUSED"]..":")
			DWP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
			DWP.ConfigTab2.RaidTimerContainer.Output:SetText("|cffff0000"..string.utf8sub(DWP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
			DWP.RaidTimerPopout.Output:SetText(DWP.ConfigTab2.RaidTimerContainer.Output:GetText())
			core.RaidInProgress = false
			return;
		end

		if IsInRaid() and DWP:CheckRaidLeader() and not pause and core.IsOfficer then
			if not StartAwarded and DWPlus_DB.DKPBonus.GiveRaidStart then -- Award On Time Bonus
				AwardRaid(DWPlus_DB.DKPBonus.OnTimeBonus, L["ONTIMEBONUS"])
				StartBonus = DWPlus_DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		else
			if not StartAwarded and DWPlus_DB.DKPBonus.GiveRaidStart then
				StartBonus = DWPlus_DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		end
	else
		if core.RaidInProgress == false and timer == 0 and SecondCount == 0 and MinuteCount == 0 then
			timer = tonumber(syncTimer);
			SecondCount = tonumber(syncSecondCount);
			MinuteCount = tonumber(syncMinuteCount);
			totalAwarded = tonumber(syncAward) - tonumber(DWPlus_DB.DKPBonus.OnTimeBonus);

			DWP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			DWP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			DWP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if DWPlus_DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(DWPlus_DB.DKPBonus.OnTimeBonus)
				DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
			end
			DWP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			DWP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			DWP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = DWPlus_DB.modes.increment;
			StartBonus = DWPlus_DB.DKPBonus.OnTimeBonus;
			if not StartAwarded and DWPlus_DB.DKPBonus.GiveRaidStart then
				StartAwarded = true;
				core.RaidInProgress = true
			end
		else
			return;
		end
	end
	
	DWP.RaidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		SecondTracker = SecondTracker + elapsed

		if SecondTracker >= 1 then
			local curTicker = SecondsToClock(timer);
			DWP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..curTicker.."|r")
			DWP.RaidTimerPopout.Output:SetText("|cff00ff00"..curTicker.."|r")
			SecondTracker = 0;
			SecondCount = SecondCount + 1;
		end

		if SecondCount >= 60 then						-- counds minutes past toward interval
			SecondCount = 0;
			MinuteCount = MinuteCount + 1;
			DWP.Sync:SendData("DWPRaidTime", "sync "..timer.." "..SecondCount.." "..MinuteCount.." "..totalAwarded)
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment and increment > 0 then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			totalAwarded = totalAwarded + tonumber(DWPlus_DB.DKPBonus.IntervalBonus)
			DWP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			DWP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r");

			if IsInRaid() and DWP:CheckRaidLeader() then
				AwardRaid(DWPlus_DB.DKPBonus.IntervalBonus, L["TIMEINTERVALBONUS"])
			end
		end
	end)
end