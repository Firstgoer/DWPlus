local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local DKPTableTemp = {}
local ValInProgress = false

function DWP_TableCompare(t1,t2) 		-- compares two tables. returns true if all keys and values match
	local ty1 = type(t1)
	local ty2 = type(t2)
	
	if ty1 ~= ty2 then
		return false
	end
	
	if ty1 ~= 'table' and ty2 ~= 'table' then
		return t1 == t2
	end
	
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not TableCompare(v1,v2) then
			return false
		end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not TableCompare(v1,v2) then
			return false
		end
	end
	return true
end

function DWP:ValidateDKPTable_Loot()
	DKPTableTemp = {}
	local i=1
	local timer = 0
	local processing = false
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #DWPlus_Loot and not processing then
			processing = true
			local search = DWP:Table_Search(DKPTableTemp, DWPlus_Loot[i].player, "player")

			if search then
				DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(DWPlus_Loot[i].cost)
				DKPTableTemp[search[1][1]].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent + tonumber(DWPlus_Loot[i].cost)
			else
				table.insert(DKPTableTemp, { player=DWPlus_Loot[i].player, dkp=tonumber(DWPlus_Loot[i].cost), lifetime_gained=0, lifetime_spent=tonumber(DWPlus_Loot[i].cost) })
			end
			processing = false
			i=i+1
			timer = 0
		elseif i > #DWPlus_Loot then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			DWP:ValidateDKPTable_DKP()
		end
	end)
end

function DWP:ValidateDKPTable_DKP()
	local i=1
	local j=1
	local timer = 0
	local timer2 = 0
	local processing = false
	local pause = false
	local proc2 = false
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.0001 and i <= #DWPlus_RPHistory and not processing and not pause then
			processing = true
			pause = true

			local players = {strsplit(",", strsub(DWPlus_RPHistory[i].players, 1, -2))}
			local dkp = {strsplit(",", DWPlus_RPHistory[i].dkp)}

			if #dkp == 1 then
				for i=1, #players do
					dkp[i] = tonumber(dkp[1])
				end
			else
				for i=1, #dkp do
					dkp[i] = tonumber(dkp[i])
				end
			end
			
			local ValidateTimer2 = ValidateTimer2 or CreateFrame("StatusBar", nil, UIParent)
			ValidateTimer2:SetScript("OnUpdate", function(self, elapsed)
				timer2 = timer2 + elapsed
				if timer2 > 0.0001 and j <= #players and not proc2 then
					proc2 = true

					local search = DWP:Table_Search(DKPTableTemp, players[j], "player")

					if search then
						DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(dkp[j])
						if ((tonumber(dkp[j]) > 0 and not DWPlus_RPHistory[i].deletes) or (tonumber(dkp[j]) < 0 and DWPlus_RPHistory[i].deletes)) and not strfind(DWPlus_RPHistory[i].dkp, "%-%d*%.?%d+%%") then
							DKPTableTemp[search[1][1]].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained + tonumber(dkp[j])
						end
					else
						if ((tonumber(dkp[j]) > 0 and not DWPlus_RPHistory[i].deletes) or (tonumber(dkp[j]) < 0 and DWPlus_RPHistory[i].deletes)) and not strfind(DWPlus_RPHistory[i].dkp, "%-%d*%.?%d+%%") then
							table.insert(DKPTableTemp, { player=players[j], dkp=tonumber(dkp[j]), lifetime_gained=tonumber(dkp[j]), lifetime_spent=0 })
						else
							table.insert(DKPTableTemp, { player=players[j], dkp=tonumber(dkp[j]), lifetime_gained=0, lifetime_spent=0 })
						end
					end
					j=j+1
					proc2 = false
				elseif j > #players then
					ValidateTimer2:SetScript("OnUpdate", nil)
					j=1
					timer2 = 0
					pause = false					
					i=i+1
					processing = false
					timer = 0
				end
			end)
		elseif i > #DWPlus_RPHistory and not processing and not proc2 and not pause then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			DWP:ValidateDKPTable_Final()
		end
	end)
end

function DWP:ValidateDKPTable_Final()
	-- validates all profile DKP values against saved values created above
	local i=1
	local timer = 0
	local processing = false
	local rectified = 0
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.1 and i <= #DKPTableTemp and not processing then
			processing = true
			local flag = false
			local search = DWP:Table_Search(DWPlus_RPTable, DKPTableTemp[i].player, "player")

			if search then
				if DWPlus_Archive[DKPTableTemp[i].player] then
					DKPTableTemp[i].dkp = DKPTableTemp[i].dkp + tonumber(DWPlus_Archive[DKPTableTemp[i].player].dkp)
					DKPTableTemp[i].lifetime_gained = DKPTableTemp[i].lifetime_gained + tonumber(DWPlus_Archive[DKPTableTemp[i].player].lifetime_gained)
					DKPTableTemp[i].lifetime_spent = DKPTableTemp[i].lifetime_spent + tonumber(DWPlus_Archive[DKPTableTemp[i].player].lifetime_spent)
				end
				if tonumber(DKPTableTemp[i].dkp) ~= DWPlus_RPTable[search[1][1]].dkp then
					DWPlus_RPTable[search[1][1]].dkp = tonumber(DKPTableTemp[i].dkp)
					flag = true
				end
				if tonumber(DKPTableTemp[i].lifetime_gained) ~= DWPlus_RPTable[search[1][1]].lifetime_gained then
					DWPlus_RPTable[search[1][1]].lifetime_gained = tonumber(DKPTableTemp[i].lifetime_gained)
					flag = true
				end
				if tonumber(DKPTableTemp[i].lifetime_spent) ~= DWPlus_RPTable[search[1][1]].lifetime_spent then
					DWPlus_RPTable[search[1][1]].lifetime_spent = tonumber(DKPTableTemp[i].lifetime_spent)
					flag = true
				end
			end
			if flag then rectified = rectified + 1 end
			i=i+1
			processing = false
			timer = 0
		elseif i > #DKPTableTemp then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			if rectified == 0 then
				DWP:Print(L["VALIDATIONCOMPLETE1"])
			else
				DWP:Print(string.format(L["VALIDATIONCOMPLETE2"], rectified))
			end
			ValInProgress = false
			table.wipe(DKPTableTemp)
			DWP:FilterDKPTable(core.currentSort, "reset")
		end
	end)
end

function DWP:ValidateDKPHistory()
	local deleted_entries = 0
	local i=1
	local timer = 0
	local processing = false
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #DWPlus_RPHistory and not processing then
			processing = true
			-- delete duplicate entries and correct DKP (DKPHistory table)
			local search = DWP:Table_Search(DWPlus_RPHistory, DWPlus_RPHistory[i].index, "index")
			
			if DWPlus_RPHistory[i].deletes then  -- adds deltedby index to field if it was received after a delete entry was received but was sent by someone that did not have the delete entry
				local search = DWP:Table_Search(DWPlus_RPHistory, DWPlus_RPHistory[i].deletes, "index")

				if search and not DWPlus_RPHistory[search[1][1]].deletedby then
					DWPlus_RPHistory[search[1][1]].deletedby = DWPlus_RPHistory[i].index
				end
			end

			if #search > 1 then
				for j=2, #search do
					table.remove(DWPlus_RPHistory, search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				i=i+1
			end

			processing = false
			timer = 0
		elseif i > #DWPlus_RPHistory then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			DWP:ValidateDKPTable_Loot()
		end
	end)
end

function DWP:ValidateLootTable()  -- validation starts here
	if ValInProgress then
		DWP:Print(L["VALIDATEINPROG"])
		return
	end
	local deleted_entries = 0
	-- delete duplicate entries and correct DKP (loot table)
	local i=1
	local timer = 0
	local processing = false
	ValInProgress = true
	
	DWP:Print(L["VALIDATINGTABLES"])
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #DWPlus_Loot and not processing then
			processing = true
			local search = DWP:Table_Search(DWPlus_Loot, DWPlus_Loot[i].index, "index")
			
			if search and #search > 1 then
				for j=2, #search do
					table.remove(DWPlus_Loot, search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #DWPlus_Loot then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			DWP:ValidateDKPHistory()
		end
	end)
end

function DWP_ReindexTables()
	local GM
	local i = 1

	for i=1, GetNumGuildMembers() do
		local name,_,rank = GetGuildRosterInfo(i)
		if rank == 0 then
			name = strsub(name, 1, string.find(name, "-")-1)
			GM = name; 
			break
		end
	end

	i=1
	while i <= #DWPlus_RPHistory do
		if DWPlus_RPHistory[i].deletes or DWPlus_RPHistory[i].deletedby or DWPlus_RPHistory[i].reason == "Migration Correction" then
			table.remove(DWPlus_RPHistory, i)
		else
			if (DWPlus_DB.defaults.installed and DWPlus_RPHistory[i].date < DWPlus_DB.defaults.installed) or (not DWPlus_DB.defaults.installed and DWPlus_RPHistory[i].date < DWPlus_DB.defaults.installed210) then
				DWPlus_RPHistory[i].index = GM.."-"..DWPlus_RPHistory[i].date  	-- reindexes under GMs name if the entry was created prior to 2.1 (for uniformity)
			end
			i=i+1
		end
	end

	i=1
	while i <= #DWPlus_Loot do
		if DWPlus_Loot[i].deletes or DWPlus_Loot[i].deletedby then
			table.remove(DWPlus_Loot, i)
		else
			if (DWPlus_DB.defaults.installed and DWPlus_Loot[i].date < DWPlus_DB.defaults.installed) or (not DWPlus_DB.defaults.installed and DWPlus_Loot[i].date < DWPlus_DB.defaults.installed210) then
				DWPlus_Loot[i].index = GM.."-"..DWPlus_Loot[i].date 				-- reindexes under GMs name if the entry was created prior to 2.1 (for uniformity)
			end
			i=i+1
		end
	end
	DWPlus_RPHistory.seed = 0
	DWPlus_Loot.seed = 0
end