local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

function DWP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
	local tempList = "";
	local tempList2 = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	if DWP:CheckRaidLeader() then -- only allows raid leader to disseminate DKP
		if phase == 1 or phase == 3 then
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
		end

		if #DWPlus_Standby > 0 and DWPlus_DB.DKPBonus.AutoIncStandby and (phase == 2 or phase == 3) then
			local raidParty = "";
			for i=1, 40 do
				local tempName = GetRaidRosterInfo(i)
				if tempName then	
					raidParty = raidParty..tempName..","
				end
			end
			for i=1, #DWPlus_Standby do
				if strfind(raidParty, DWPlus_Standby[i].player..",") ~= 1 and not strfind(raidParty, ","..DWPlus_Standby[i].player..",") then
					DWP:AwardPlayer(DWPlus_Standby[i].player, amount)
					tempList2 = tempList2..DWPlus_Standby[i].player..",";
				end
			end
			local i = 1
			while i <= #DWPlus_Standby do
				if DWPlus_Standby[i] and (strfind(raidParty, DWPlus_Standby[i].player..",") == 1 or strfind(raidParty, ","..DWPlus_Standby[i].player..",")) then
					table.remove(DWPlus_Standby, i)
				else
					i=i+1
				end
			end
		end

		if tempList ~= "" or tempList2 ~= "" then
			if (phase == 1 or phase == 3) and tempList ~= "" then
				local newIndex = curOfficer.."-"..curTime
				tinsert(DWPlus_RPHistory, 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})
				DWP.Sync:SendData("DWPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				DWP.Sync:SendData("DWPDKPDist", DWPlus_RPHistory[1])
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				local newIndex = curOfficer.."-"..curTime+1
				tinsert(DWPlus_RPHistory, 1, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1, index=newIndex})
				DWP.Sync:SendData("DWPBCastMsg", L["STANDBYADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				DWP.Sync:SendData("DWPDKPDist", DWPlus_RPHistory[1])
			end

			if DWP.ConfigTab7.history and DWP.ConfigTab7:IsShown() then
				DWP:DKPHistory_Update(true)
			end
			DKPTable_Update()
		end
	end
end