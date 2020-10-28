local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local ConsolidatedTable = {}
local DKPTableTemp = {}
local ValInProgress = false

local function ConsolidateTables(keepDKP)
	table.sort(ConsolidatedTable, function(a,b)   	-- inverts tables; oldest to newest
		return a["date"] < b["date"]
	end)

	local i=1
	local timer = 0
	local processing = false
	local DKPStringTemp = ""	-- stores DKP comparisons to create a new entry if they are different
	local PlayerStringTemp = "" -- stores player list to create new DKPHistory entry if any values differ from the DKPTable
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #ConsolidatedTable and not processing then
			processing = true

			if ConsolidatedTable[i].loot then
				local search = DWP:Table_Search(DKPTableTemp, ConsolidatedTable[i].player, "player")

				if search then
					DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(ConsolidatedTable[i].cost)
					DKPTableTemp[search[1][1]].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent + tonumber(ConsolidatedTable[i].cost)
				else
					table.insert(DKPTableTemp, { player=ConsolidatedTable[i].player, dkp=tonumber(ConsolidatedTable[i].cost), lifetime_spent=tonumber(ConsolidatedTable[i].cost), lifetime_gained=0 })
				end
			elseif ConsolidatedTable[i].reason then
				local players = {strsplit(",", string.utf8sub(ConsolidatedTable[i].players, 1, -2))}

				if strfind(ConsolidatedTable[i].dkp, "%-%d*%.?%d+%%") then -- is a decay, calculate new values
					local f = {strfind(ConsolidatedTable[i].dkp, "%-%d*%.?%d+%%")}
					local playerString = ""
					local DKPString = ""
					local value = tonumber(string.utf8sub(ConsolidatedTable[i].dkp, f[1]+1, f[2]-1)) / 100

					for j=1, #players do
						local search2 = DWP:Table_Search(DKPTableTemp, players[j], "player")

						if search2 and DKPTableTemp[search2[1][1]].dkp > 0 then
							local deduction = DKPTableTemp[search2[1][1]].dkp * -value;
							deduction = DWP_round(deduction, DWPlus_DB.modes.rounding)

							DKPTableTemp[search2[1][1]].dkp = DKPTableTemp[search2[1][1]].dkp + deduction
							playerString = playerString..players[j]..","
							DKPString = DKPString..deduction..","
						else
							playerString = playerString..players[j]..","
							DKPString = DKPString.."0,"

							if not search2 then
								table.insert(DKPTableTemp, { player=players[j], dkp=0, lifetime_gained=0, lifetime_spent=0 })
							end
						end

					end
					local perc = value * 100
					DKPString = DKPString.."-"..perc.."%"

					local EntrySearch = DWP:Table_Search(DWPlus_RPHistory, ConsolidatedTable[i].date, "date")

					if EntrySearch then
						DWPlus_RPHistory[EntrySearch[1][1]].players = playerString
						DWPlus_RPHistory[EntrySearch[1][1]].dkp = DKPString
					end
				else
					local dkp = tonumber(ConsolidatedTable[i].dkp)

					for j=1, #players do
						local search = DWP:Table_Search(DKPTableTemp, players[j], "player")

						if search then
							DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + dkp
							DKPTableTemp[search[1][1]].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained + dkp
						else
							if dkp > 0 then
								table.insert(DKPTableTemp, { player=players[j], dkp=dkp, lifetime_gained=dkp, lifetime_spent=0 })
							else
								table.insert(DKPTableTemp, { player=players[j], dkp=dkp, lifetime_gained=0, lifetime_spent=0 })
							end
						end
					end
				end
			end
			i=i+1
			processing = false
			timer = 0
		elseif i > #ConsolidatedTable then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			-- Create new DKPHistory entry compensating for difference between history and DKPTable (if some history was lost due to overwriting)
			if keepDKP then
				for i=1, #DWPlus_RPTable do
					local search = DWP:Table_Search(DKPTableTemp, DWPlus_RPTable[i].player, "player")

					if search then
						if DWPlus_RPTable[i].dkp ~= DKPTableTemp[search[1][1]].dkp then
							local val = DWPlus_RPTable[i].dkp - DKPTableTemp[search[1][1]].dkp
							val = DWP_round(val, DWPlus_DB.modes.rounding)
							PlayerStringTemp = PlayerStringTemp..DWPlus_RPTable[i].player..","
							DKPStringTemp = DKPStringTemp..val..","
						end
					end
				end

				if DKPStringTemp ~= "" and PlayerStringTemp ~= "" then
					local insert = {
						players = PlayerStringTemp,
						index 	= UnitName("player").."-"..DWPlus_DB.defaults.installed210-10,
						dkp 	= DKPStringTemp.."-1%",
						date 	= time(),
						reason	= "Migration Correction",
						hidden	= true,
					}
					table.insert(DWPlus_RPHistory, insert)
				end
			else
				for i=1, #DWPlus_RPTable do
					local search = DWP:Table_Search(DKPTableTemp, DWPlus_RPTable[i].player, "player")

					if search then
						DWPlus_RPTable[i].dkp = DKPTableTemp[search[1][1]].dkp
						DWPlus_RPTable[i].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent
						DWPlus_RPTable[i].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained
					end
				end
			end

			local curTime = time();
			for i=1, #DKPTableTemp do 	-- finds who had history but was deleted; adds them to archive if so
				local search = DWP:Table_Search(DWPlus_RPTable, DKPTableTemp[i].player)

				if not search then
					DWPlus_Archive[DKPTableTemp[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime }
				end
			end

			table.sort(DWPlus_Loot, function(a,b)
				return a["date"] > b["date"]
			end)
			table.sort(DWPlus_RPHistory, function(a,b)
				return a["date"] > b["date"]
			end)
			DWPlus_RPHistory.seed = DWPlus_RPHistory[1].index;
			DWPlus_Loot.seed = DWPlus_Loot[1].index
			DWP:FilterDKPTable(core.currentSort, "reset")
			ValInProgress = false
			DWP:Print(L["REPAIRCOMP"])
		end
	end)
end

local function RepairDKPHistory(keepDKP)
	local deleted_entries = 0
	local i=1
	local timer = 0
	local processing = false
	local officer = UnitName("player")
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #DWPlus_RPHistory and not processing then
			processing = true
			-- delete duplicate entries and correct DKP (DKPHistory table)
			local search = DWP:Table_Search(DWPlus_RPHistory, DWPlus_RPHistory[i].date, "date")
			
			if DWPlus_RPHistory[i].deletes or DWPlus_RPHistory[i].deletedby or DWPlus_RPHistory[i].reason == "Migration Correction" then  -- removes deleted entries/Migration Correction
				table.remove(DWPlus_RPHistory, i)
			elseif #search > 1 then 		-- removes duplicate entries
				for j=2, #search do
					table.remove(DWPlus_RPHistory, search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				local curTime = DWPlus_RPHistory[i].date
				DWPlus_RPHistory[i].index = officer.."-"..curTime
				if not strfind(DWPlus_RPHistory[i].dkp, "%-%d*%.?%d+%%") then
					DWPlus_RPHistory[i].dkp = tonumber(DWPlus_RPHistory[i].dkp)
				end
				table.insert(ConsolidatedTable, DWPlus_RPHistory[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #DWPlus_RPHistory then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			ConsolidateTables(keepDKP)
		end
	end)
end

function DWP:RepairTables(keepDKP)  -- Repair starts
	if ValInProgress then
		DWP:Print(L["VALIDATEINPROG"])
		return
	end

	local officer = UnitName("player")
	local i=1
	local timer = 0
	local processing = false
	ValInProgress = true
	
	DWP:Print(L["REPAIRSTART"])

	if keepDKP then
		DWP:Print("Keep RP: true")
	else
		DWP:Print("Keep RP: false")
	end

	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #DWPlus_Loot and not processing then
			processing = true
			local search = DWP:Table_Search(DWPlus_Loot, DWPlus_Loot[i].date, "date")
			
			if DWPlus_Loot[i].deletedby or DWPlus_Loot[i].deletes then
				table.remove(DWPlus_Loot, i)
			elseif search and #search > 1 then
				for j=2, #search do
					if DWPlus_Loot[search[j][1]].loot == DWPlus_Loot[i].loot then
						table.remove(DWPlus_Loot, search[j][1])
					end
				end
			else
				local curTime = DWPlus_Loot[i].date
				DWPlus_Loot[i].index = officer.."-"..curTime
				if tonumber(DWPlus_Loot[i].cost) > 0 then
					DWPlus_Loot[i].cost = tonumber(DWPlus_Loot[i].cost) * -1
				end
				table.insert(ConsolidatedTable, DWPlus_Loot[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #DWPlus_Loot then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			RepairDKPHistory(keepDKP)
		end
	end)
end