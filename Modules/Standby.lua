local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local function CMD_Handler(...)
	local _, cmd = string.split(" ", ..., 2)

	if tonumber(cmd) then
		cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
	end

	return cmd;
end

function DWPlus_Standby_Announce(bossName)
	core.StandbyActive = true; -- activates opt in
	table.wipe(DWPlus_Standby);
	if DWP:CheckRaidLeader() then
		SendChatMessage(bossName..L["STANDBYOPTINBEGIN"], "GUILD") -- only raid leader announces
	end
	C_Timer.After(120, function ()
		core.StandbyActive = false;  -- deactivates opt in
		if DWP:CheckRaidLeader() then
			SendChatMessage(L["STANDBYOPTINEND"]..bossName, "GUILD") -- only raid leader announces
			if DWPlus_DB.DKPBonus.AutoIncStandby then
				DWP:AutoAward(2, DWPlus_DB.DKPBonus.BossKillBonus, DWPlus_DB.bossargs.CurrentRaidZone..": "..DWPlus_DB.bossargs.LastKilledBoss)
			end
		end
	end)
end

function DWPlus_Standby_Handler(text, ...)
	local name = ...;
	local cmd;
	local response = L["ERRORPROCESSING"];

	if string.find(name, "-") then					-- finds and removes server name from name if exists
		local dashPos = string.find(name, "-")
		name = strsub(name, 1, dashPos-1)
	end

	if string.find(text, "!standby") == 1 and core.IsOfficer then
		cmd = tostring(CMD_Handler(text))

		if cmd and cmd:gsub("%s+", "") ~= "nil" and cmd:gsub("%s+", "") ~= "" then
			-- if it's !standby *name*
			cmd = cmd:gsub("%s+", "") -- removes unintended spaces from string
			local search = DWP:Table_Search(DWPlus_RPTable, cmd)
			local verify = DWP:Table_Search(DWPlus_Standby, cmd)

			if search and not verify then
				table.insert(DWPlus_Standby, DWPlus_RPTable[search[1][1]])
				response = "DW Plus: "..cmd.." "..L["STANDBYWHISPERRESP1"]
			elseif search and verify then
				response = "DW Plus: "..cmd.." "..L["STANDBYWHISPERRESP2"]
			else
				response = "DW Plus: "..cmd.." "..L["STANDBYWHISPERRESP3"];
			end
		else
			-- if it's just !standby
			local search = DWP:Table_Search(DWPlus_RPTable, name)
			local verify = DWP:Table_Search(DWPlus_Standby, name)

			if search and not verify then
				table.insert(DWPlus_Standby, DWPlus_RPTable[search[1][1]])
				response = "DW Plus: "..L["STANDBYWHISPERRESP4"]
			elseif search and verify then
				response = "DW Plus: "..L["STANDBYWHISPERRESP5"]
			else
				response = "DW Plus: "..L["STANDBYWHISPERRESP6"];
			end
		end
		if DWP:CheckRaidLeader() then 						 -- only raid leader responds to add.
			SendChatMessage(response, "WHISPER", nil, name)
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)		-- suppresses outgoing whisper responses to limit spam
		if core.StandbyActive and DWPlus_DB.defaults.SupressTells then
			if strfind(msg, "DW Plus: ") then
				return true
			end
		end
	end)
end