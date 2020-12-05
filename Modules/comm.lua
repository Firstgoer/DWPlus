--[[
	Usage so far:  DWP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates
--]]	

local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

DWP.Sync = LibStub("AceAddon-3.0"):NewAddon("DWP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
--local LibCompress = LibStub:GetLi7brary("LibCompress")
--local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()

function DWP:ValidateSender(sender)								-- returns true if "sender" has permission to write officer notes. false if not or not found.
	local rankIndex = DWP:GetGuildRankIndex(sender);

	if rankIndex == 1 then       			-- automatically gives permissions above all settings if player is guild leader
		return true;
	end
	if #DWPlus_Whitelist > 0 then									-- if a whitelist exists, checks that rather than officer note permissions
		for i=1, #DWPlus_Whitelist do
			if DWPlus_Whitelist[i] == sender then
				return true;
			end
		end
		return false;
	else
		if rankIndex then
			return C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12]		-- returns true/false if player can write to officer notes
		else
			return false;
		end
	end
end

-------------------------------------------------
-- Register Broadcast Prefixs
-------------------------------------------------

function DWP.Sync:OnEnable()
	DWP.Sync:RegisterComm("DWPDelUsers", DWP.Sync:OnCommReceived())			-- Broadcasts deleted users (archived users not on the DKP table)
	DWP.Sync:RegisterComm("DWPMerge", DWP.Sync:OnCommReceived())			-- Broadcasts 2 weeks of data from officers (for merging)
	-- Normal broadcast Prefixs
	DWP.Sync:RegisterComm("DWPDecay", DWP.Sync:OnCommReceived())				-- Broadcasts a weekly decay adjustment
	DWP.Sync:RegisterComm("DWPBCastMsg", DWP.Sync:OnCommReceived())			-- broadcasts a message that is printed as is
	DWP.Sync:RegisterComm("DWPCommand", DWP.Sync:OnCommReceived())			-- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
	DWP.Sync:RegisterComm("DWPLootDist", DWP.Sync:OnCommReceived())			-- broadcasts individual loot award to loot table
	DWP.Sync:RegisterComm("DWPDelLoot", DWP.Sync:OnCommReceived())			-- broadcasts deleted loot award entries
	DWP.Sync:RegisterComm("DWPDelSync", DWP.Sync:OnCommReceived())			-- broadcasts deleated DKP history entries
	DWP.Sync:RegisterComm("DWPDKPDist", DWP.Sync:OnCommReceived())			-- broadcasts individual DKP award to DKP history table
	DWP.Sync:RegisterComm("DWPMinBid", DWP.Sync:OnCommReceived())			-- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
	DWP.Sync:RegisterComm("DWPWhitelist", DWP.Sync:OnCommReceived())			-- broadcasts whitelist
	DWP.Sync:RegisterComm("DWPDKPModes", DWP.Sync:OnCommReceived())			-- broadcasts DKP Mode settings
	DWP.Sync:RegisterComm("DWPStand", DWP.Sync:OnCommReceived())				-- broadcasts standby list
	DWP.Sync:RegisterComm("DWPRaidTime", DWP.Sync:OnCommReceived())			-- broadcasts Raid Timer Commands
	DWP.Sync:RegisterComm("DWPZSumBank", DWP.Sync:OnCommReceived())		-- broadcasts ZeroSum Bank
	DWP.Sync:RegisterComm("DWPQuery", DWP.Sync:OnCommReceived())				-- Querys guild for spec/role data
	DWP.Sync:RegisterComm("DWPBuild", DWP.Sync:OnCommReceived())				-- broadcasts Addon build number to inform others an update is available.
	DWP.Sync:RegisterComm("DWPTalents", DWP.Sync:OnCommReceived())			-- broadcasts current spec
	DWP.Sync:RegisterComm("DWPRoles", DWP.Sync:OnCommReceived())				-- broadcasts current role info
	DWP.Sync:RegisterComm("DWPBossLoot", DWP.Sync:OnCommReceived())			-- broadcast current loot table
	DWP.Sync:RegisterComm("DWPBidShare", DWP.Sync:OnCommReceived())			-- broadcast accepted bids
	DWP.Sync:RegisterComm("DWPBidder", DWP.Sync:OnCommReceived())			-- Submit bids
	DWP.Sync:RegisterComm("DWPAllTabs", DWP.Sync:OnCommReceived())			-- Full table broadcast
	DWP.Sync:RegisterComm("DWPConsul", DWP.Sync:OnCommReceived())			-- Full table broadcast
	--DWP.Sync:RegisterComm("DWPEditLoot", DWP.Sync:OnCommReceived())		-- not in use
	--DWP.Sync:RegisterComm("DWPDataSync", DWP.Sync:OnCommReceived())		-- not in use
	--DWP.Sync:RegisterComm("DWPDKPLogSync", DWP.Sync:OnCommReceived())	-- not in use
	--DWP.Sync:RegisterComm("DWPLogSync", DWP.Sync:OnCommReceived())		-- not in use
end

function DWP.Sync:OnCommReceived(prefix, message, distribution, sender)
	if not core.Initialized or core.IsOfficer == nil then return end
	if prefix then
		--if prefix ~= "MDKPProfile" then print("|cffff0000Received: "..prefix.." from "..sender.."|r") end
		if prefix == "DWPQuery" then
			-- set remote seed
			if sender ~= UnitName("player") and message ~= "start" then  -- logs seed. Used to determine if the officer has entries required.
				local DKP, Loot = strsplit(",", message)
				local off1,date1 = strsplit("-", DKP)
				local off2,date2 = strsplit("-", Loot)

				if DWP:ValidateSender(off1) and DWP:ValidateSender(off2) and tonumber(date1) > DWPlus_DB.defaults.installed210 and tonumber(date2) > DWPlus_DB.defaults.installed210 then  -- send only if posting officer validates and the post was made after 2.1s installation
					local search1 = DWP:Table_Search(DWPlus_RPHistory, DKP, "index")
					local search2 = DWP:Table_Search(DWPlus_Loot, Loot, "index")
					
					if not search1 then
						DWPlus_RPHistory.seed = DKP
					end
					if not search2 then
						DWPlus_Loot.seed = Loot
					end
				end
			end
			-- talents check
			local TalTrees={}; table.insert(TalTrees, {GetTalentTabInfo(1)}); table.insert(TalTrees, {GetTalentTabInfo(2)}); table.insert(TalTrees, {GetTalentTabInfo(3)}); 
			local talBuild = "("..TalTrees[1][3].."/"..TalTrees[2][3].."/"..TalTrees[3][3]..")"
			local talRole;

			table.sort(TalTrees, function(a, b)
				return a[3] > b[3]
			end)
			
			talBuild = TalTrees[1][1].." "..talBuild;
			talRole = TalTrees[1][4];
			
			DWP.Sync:SendData("DWPTalents", talBuild)
			DWP.Sync:SendData("DWPRoles", talRole)

			table.wipe(TalTrees);
			return;
		elseif prefix == "DWPBidder" then
			if core.BidInProgress and core.IsOfficer then
				if message == "pass" then
					DWP:Print(sender.." has passed.")
					return
				else
					DWP_CHAT_MSG_WHISPER(message, sender)
					return
				end
			else
				return
			end
		elseif prefix == "DWPTalents" then
			local search = DWP:Table_Search(DWPlus_RPTable, sender, "player")

			if search then
				local curSelection = DWPlus_RPTable[search[1][1]]
				curSelection.spec = message;
			end
			return
		elseif prefix == "DWPRoles" then
			local search = DWP:Table_Search(DWPlus_RPTable, sender, "player")
			local curClass = "None";

			if search then
				local curSelection = DWPlus_RPTable[search[1][1]]
				curClass = DWPlus_RPTable[search[1][1]].class
			
				if curClass == "WARRIOR" then
					local a,b,c = strsplit("/", message)
					if strfind(message, "Protection") or (tonumber(c) and tonumber(string.utf8sub(c, 1, -2)) > 15) then
						curSelection.role = L["TANK"]
					else
						curSelection.role = L["MELEEDPS"]
					end
				elseif curClass == "PALADIN" then
					if strfind(message, "Protection") then
						curSelection.role = L["TANK"]
					elseif strfind(message, "Holy") then
						curSelection.role = L["HEALER"]
					else
						curSelection.role = L["MELEEDPS"]
					end
				elseif curClass == "HUNTER" then
					curSelection.role = L["RANGEDPS"]
				elseif curClass == "ROGUE" then
					curSelection.role = L["MELEEDPS"]
				elseif curClass == "PRIEST" then
					if strfind(message, "Shadow") then
						curSelection.role = L["CASTERDPS"]
					else
						curSelection.role = L["HEALER"]
					end
				elseif curClass == "SHAMAN" then
					if strfind(message, "Restoration") then
						curSelection.role = L["HEALER"]
					elseif strfind(message, "Elemental") then
						curSelection.role = L["CASTERDPS"]
					else
						curSelection.role = L["MELEEDPS"]
					end
				elseif curClass == "MAGE" then
					curSelection.role = L["CASTERDPS"]
				elseif curClass == "WARLOCK" then
					curSelection.role = L["CASTERDPS"]
				elseif curClass == "DRUID" then
					if strfind(message, "Feral") then
						curSelection.role = L["TANK"]
					elseif strfind(message, "Balance") then
						curSelection.role = L["CASTERDPS"]
					else
						curSelection.role = L["HEALER"]
					end
				else
					curSelection.role = L["NOROLEDETECTED"]
				end
			end
			return;
		elseif prefix == "DWPBuild" and sender ~= UnitName("player") then
			local LastVerCheck = time() - core.LastVerCheck;

			if LastVerCheck > 900 then   					-- limits the Out of Date message from firing more than every 15 minutes 
				if tonumber(message) > core.BuildNumber then
					core.LastVerCheck = time();
					DWP:Print(L["OUTOFDATEANNOUNCE"])
				end
			end

			if tonumber(message) < core.BuildNumber then 	-- returns build number if receiving party has a newer version
				DWP.Sync:SendData("DWPBuild", tostring(core.BuildNumber))
			end
			return;
		end
		if DWP:ValidateSender(sender) then		-- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table
			if (prefix == "DWPBCastMsg") and sender ~= UnitName("player") then
				DWP:Print(message)
			elseif (prefix == "DWPCommand") then
				local command, arg1, arg2, arg3 = strsplit(",", message);
				if sender ~= UnitName("player") then
					if command == "StartTimer" then
						DWP:StartTimer(arg1, arg2)
					elseif command == "StartBidTimer" then
						DWP:StartBidTimer(arg1, arg2, arg3)
						core.BiddingInProgress = true;
						if strfind(arg1, "{") then
							DWP:Print("Bid timer extended by "..tonumber(strsub(arg1, strfind(arg1, "{")+1)).." seconds.")
						end
					elseif command == "StopBidTimer" then
						if DWP.BidTimer then
							DWP.BidTimer:SetScript("OnUpdate", nil)
							DWP.BidTimer:Hide()
							core.BiddingInProgress = false;
						end
						if core.BidInterface and #core.BidInterface.LootTableButtons > 0 then
							for i=1, #core.BidInterface.LootTableButtons do
								ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
							end
						end
						C_Timer.After(2, function()
							if core.BidInterface and core.BidInterface:IsShown() and not core.BiddingInProgress then
								core.BidInterface:Hide()
							end
						end)
					elseif command == "BidInfo" then
						if not core.BidInterface then
							core.BidInterface = core.BidInterface or DWP:BidInterface_Create()	-- initiates bid window if it hasn't been created
						end
						if DWPlus_DB.defaults.AutoOpenBid and not core.BidInterface:IsShown() then	-- toggles bid window if option is set to
							DWP:BidInterface_Toggle()
						end
						DWP:CurrItem_Set(arg1, arg2, arg3)	-- populates bid window
					end
				end
			elseif prefix == "DWPRaidTime" and sender ~= UnitName("player") and core.IsOfficer and DWP.ConfigTab2 then
				local command, args = strsplit(",", message);
				if command == "start" then
					local arg1, arg2, arg3, arg4, arg5, arg6 = strsplit(" ", args, 6)

					if arg1 == "true" then arg1 = true else arg1 = false end
					if arg4 == "true" then arg4 = true else arg4 = false end
					if arg5 == "true" then arg5 = true else arg5 = false end
					if arg6 == "true" then arg6 = true else arg6 = false end

					if arg2 ~= nil then
						DWP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(arg2));
						DWPlus_DB.modes.increment = tonumber(arg2);
					end
					if arg3 ~= nil then
						DWP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(arg3));
						DWPlus_DB.DKPBonus.IntervalBonus = tonumber(arg3);
					end
					if arg4 ~= nil then
						DWP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(arg4);
						DWPlus_DB.DKPBonus.GiveRaidStart = arg4;
					end
					if arg5 ~= nil then
						DWP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(arg5);
						DWPlus_DB.DKPBonus.GiveRaidEnd = arg5;
					end
					if arg6 ~= nil then
						DWP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(arg6);
						DWPlus_DB.DKPBonus.IncStandby = arg6;
					end

					DWP:StartRaidTimer(arg1)
				elseif command == "stop" then
					DWP:StopRaidTimer()
				elseif strfind(command, "sync", 1) then
					local _, syncTimer, syncSecondCount, syncMinuteCount, syncAward = strsplit(" ", command, 5)
					DWP:StartRaidTimer(nil, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
					core.RaidInProgress = true
				end
			end
			if (sender ~= UnitName("player")) then
				if prefix == "DWPLootDist" or prefix == "DWPDKPDist" or prefix == "DWPDelLoot" or prefix == "DWPDelSync" or prefix == "DWPMinBid" or prefix == "DWPWhitelist"
				or prefix == "DWPDKPModes" or prefix == "DWPStand" or prefix == "DWPZSumBank" or prefix == "DWPBossLoot" or prefix == "DWPDecay" or prefix == "DWPDelUsers" or
				prefix == "DWPAllTabs" or prefix == "DWPBidShare" or prefix == "DWPMerge" or prefix == "DWPConsul" then
					decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(message))
					local success, deserialized = LibAceSerializer:Deserialize(decoded);
					if success then
						if prefix == "DWPAllTabs" then   -- receives full table broadcast
							table.sort(deserialized.Loot, function(a, b)
								return a["date"] > b["date"]
							end)
							table.sort(deserialized.DKP, function(a, b)
								return a["date"] > b["date"]
							end)

							if (#DWPlus_RPHistory > 0 and #DWPlus_Loot > 0) and (deserialized.DKP[1].date < DWPlus_RPHistory[1].date or deserialized.Loot[1].date < DWPlus_Loot[1].date) then
								local entry1 = "Loot: "..deserialized.Loot[1].loot.." |cff616ccf"..L["WONBY"].." "..deserialized.Loot[1].player.." ("..date("%b %d @ %H:%M:%S", deserialized.Loot[1].date)..") by "..strsub(deserialized.Loot[1].index, 1, strfind(deserialized.Loot[1].index, "-")-1).."|r"
								local entry2 = "RP: |cff616ccf"..deserialized.DKP[1].reason.." ("..date("%b %d @ %H:%M:%S", deserialized.DKP[1].date)..") - "..strsub(deserialized.DKP[1].index, 1, strfind(deserialized.DKP[1].index, "-")-1).."|r"

								StaticPopupDialogs["FULL_TABS_ALERT"] = {
									text = "|CFFFF0000"..L["WARNING"].."|r: "..string.format(L["NEWERTABS1"], sender).."\n\n"..entry1.."\n\n"..entry2.."\n\n"..L["NEWERTABS2"],
									button1 = L["YES"],
									button2 = L["NO"],
									OnAccept = function()
										DWPlus_RPTable = deserialized.DKPTable
										DWPlus_RPHistory = deserialized.DKP
										DWPlus_Loot = deserialized.Loot

										if (DWP:canUserChangeConsul(sender)) then
											DWPlus_Consul = deserialized.Consul;
											DWP:ConsulUpdate();
										end

										DWPlus_Archive = deserialized.Archive
										
										if DWP.ConfigTab7 and DWP.ConfigTab7.history and DWP.ConfigTab7:IsShown() then
											DWP:DKPHistory_Update(true)
										elseif DWP.ConfigTab6 and DWP.ConfigTab6:IsShown() then
											DWP:LootHistory_Reset()
											DWP:LootHistory_Update(L["NOFILTER"]);
										end
										if core.ClassGraph then
											DWP:ClassGraph_Update()
										else
											DWP:ClassGraph()
										end
										DWP:FilterDKPTable(core.currentSort, "reset")
										DWP:StatusVerify_Update()
									end,
									timeout = 0,
									whileDead = true,
									hideOnEscape = true,
									preferredIndex = 3,
								}
								StaticPopup_Show ("FULL_TABS_ALERT")
							else
								DWPlus_RPTable = deserialized.DKPTable
								DWPlus_RPHistory = deserialized.DKP
								DWPlus_Loot = deserialized.Loot

								if (DWP:canUserChangeConsul(sender)) then
									DWPlus_Consul = deserialized.Consul;
									DWP:ConsulUpdate();
								end
								
								DWPlus_Archive = deserialized.Archive
								
								if DWP.ConfigTab6 and DWP.ConfigTab6.history and DWP.ConfigTab6:IsShown() then
									DWP:DKPHistory_Update(true)
								elseif DWP.ConfigTab5 and DWP.ConfigTab5:IsShown() then
									DWP:LootHistory_Reset()
									DWP:LootHistory_Update(L["NOFILTER"]);
								end
								if core.ClassGraph then
									DWP:ClassGraph_Update()
								else
									DWP:ClassGraph()
								end
								DWP:FilterDKPTable(core.currentSort, "reset")
								DWP:StatusVerify_Update()
							end
							return
						elseif prefix == "DWPMerge" then
							for i=1, #deserialized.DKP do
								local search = DWP:Table_Search(DWPlus_RPHistory, deserialized.DKP[i].index, "index")

								if not search and ((DWPlus_Archive.DKPMeta and DWPlus_Archive.DKPMeta < deserialized.DKP[i].date) or (not DWPlus_Archive.DKPMeta)) then   -- prevents adding entry if this entry has already been archived
									local players = {strsplit(",", string.utf8sub(deserialized.DKP[i].players, 1, -2))}
									local dkp

									if strfind(deserialized.DKP[i].dkp, "%-%d*%.?%d+%%") then
										dkp = {strsplit(",", deserialized.DKP[i].dkp)}
									end

									if deserialized.DKP[i].deletes then  		-- adds deletedby field to entry if the received table is a delete entry
										local search_del = DWP:Table_Search(DWPlus_RPHistory, deserialized.DKP[i].deletes, "index")

										if search_del then
											DWPlus_RPHistory[search_del[1][1]].deletedby = deserialized.DKP[i].index
										end
									end
									
									if not deserialized.DKP[i].deletedby then
										local search_del = DWP:Table_Search(DWPlus_RPHistory, deserialized.DKP[i].index, "deletes")

										if search_del then
											deserialized.DKP[i].deletedby = DWPlus_RPHistory[search_del[1][1]].index
										end
									end

									table.insert(DWPlus_RPHistory, deserialized.DKP[i])

									for j=1, #players do
										if players[j] then
											local findEntry = DWP:Table_Search(DWPlus_RPTable, players[j], "player")

											if strfind(deserialized.DKP[i].dkp, "%-%d*%.?%d+%%") then 		-- handles decay entries
												if findEntry then
													DWPlus_RPTable[findEntry[1][1]].dkp = DWPlus_RPTable[findEntry[1][1]].dkp + tonumber(dkp[j])
												else
													if not DWPlus_Archive[players[j]] or (DWPlus_Archive[players[j]] and DWPlus_Archive[players[j]].deleted ~= true) then
														DWP_Profile_Create(players[j], tonumber(dkp[j]))
													end
												end
											else
												if findEntry then
													DWPlus_RPTable[findEntry[1][1]].dkp = DWPlus_RPTable[findEntry[1][1]].dkp + tonumber(deserialized.DKP[i].dkp)
													if (tonumber(deserialized.DKP[i].dkp) > 0 and not deserialized.DKP[i].deletes) or (tonumber(deserialized.DKP[i].dkp) < 0 and deserialized.DKP[i].deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
														DWPlus_RPTable[findEntry[1][1]].lifetime_gained = DWPlus_RPTable[findEntry[1][1]].lifetime_gained + deserialized.DKP[i].dkp 	-- NOT if it's a DKP penalty or deleteing a DKP penalty
													end
												else
													if not DWPlus_Archive[players[j]] or (DWPlus_Archive[players[j]] and DWPlus_Archive[players[j]].deleted ~= true) then
														local class

														if (tonumber(deserialized.DKP[i].dkp) > 0 and not deserialized.DKP[i].deletes) or (tonumber(deserialized.DKP[i].dkp) < 0 and deserialized.DKP[i].deletes) then
															DWP_Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp), tonumber(deserialized.DKP[i].dkp))
														else
															DWP_Profile_Create(players[j], tonumber(deserialized.DKP[i].dkp))
														end
													end
												end
											end
										end
									end
								end
							end

							if DWP.ConfigTab6 and DWP.ConfigTab6.history and DWP.ConfigTab6:IsShown() then
								DWP:DKPHistory_Update(true)
							end

							for i=1, #deserialized.Loot do
								local search = DWP:Table_Search(DWPlus_Loot, deserialized.Loot[i].index, "index")

								if not search and ((DWPlus_Archive.LootMeta and DWPlus_Archive.LootMeta < deserialized.DKP[i].date) or (not DWPlus_Archive.LootMeta)) then -- prevents adding entry if this entry has already been archived
									if deserialized.Loot[i].deletes then
										local search_del = DWP:Table_Search(DWPlus_Loot, deserialized.Loot[i].deletes, "index")

										if search_del and not DWPlus_Loot[search_del[1][1]].deletedby then
											DWPlus_Loot[search_del[1][1]].deletedby = deserialized.Loot[i].index
										end
									end

									if not deserialized.Loot[i].deletedby then
										local search_del = DWP:Table_Search(DWPlus_Loot, deserialized.Loot[i].index, "deletes")

										if search_del then
											deserialized.Loot[i].deletedby = DWPlus_Loot[search_del[1][1]].index
										end
									end

									table.insert(DWPlus_Loot, deserialized.Loot[i])

									local findEntry = DWP:Table_Search(DWPlus_RPTable, deserialized.Loot[i].player, "player")

									if findEntry then
										DWPlus_RPTable[findEntry[1][1]].dkp = DWPlus_RPTable[findEntry[1][1]].dkp + deserialized.Loot[i].cost
										DWPlus_RPTable[findEntry[1][1]].lifetime_spent = DWPlus_RPTable[findEntry[1][1]].lifetime_spent + deserialized.Loot[i].cost
									else
										if not DWPlus_Archive[deserialized.Loot[i].player] or (DWPlus_Archive[deserialized.Loot[i].player] and DWPlus_Archive[deserialized.Loot[i].player].deleted ~= true) then
											DWP_Profile_Create(deserialized.Loot[i].player, deserialized.Loot[i].cost, 0, deserialized.Loot[i].cost)
										end
									end
								end
							end

							for i=1, #DWPlus_RPTable do
								if DWPlus_RPTable[i].class == "NONE" then
									local search = DWP:Table_Search(deserialized.Profiles, DWPlus_RPTable[i].player, "player")

									if search then
										DWPlus_RPTable[i].class = deserialized.Profiles[search[1][1]].class
									end
								end
							end

							if (DWP:canUserChangeConsul(sender)) then
								DWPlus_Consul = deserialized.Consul;
								DWP:ConsulUpdate();
							end

							DWP:LootHistory_Reset()
							DWP:LootHistory_Update(L["NOFILTER"])
							DWP:FilterDKPTable(core.currentSort, "reset")
							DWP:StatusVerify_Update();

							return
						elseif prefix == "DWPLootDist" then
							local search = DWP:Table_Search(DWPlus_RPTable, deserialized.player, "player")
							if search then
								local DKPTable = DWPlus_RPTable[search[1][1]]
								DKPTable.dkp = DKPTable.dkp + deserialized.cost
								DKPTable.lifetime_spent = DKPTable.lifetime_spent + deserialized.cost
							else
								if not DWPlus_Archive[deserialized.player] or (DWPlus_Archive[deserialized.player] and DWPlus_Archive[deserialized.player].deleted ~= true) then
									DWP_Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);
								end
							end
							tinsert(DWPlus_Loot, 1, deserialized)

							DWP:LootHistory_Reset()
							DWP:LootHistory_Update(L["NOFILTER"])
							DWP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "DWPDKPDist" then
							local players = {strsplit(",", string.utf8sub(deserialized.players, 1, -2))}
							local dkp = deserialized.dkp

							tinsert(DWPlus_RPHistory, 1, deserialized)

							for i=1, #players do
								local search = DWP:Table_Search(DWPlus_RPTable, players[i], "player")

								if search then
									DWPlus_RPTable[search[1][1]].dkp = DWPlus_RPTable[search[1][1]].dkp + tonumber(dkp)
									if tonumber(dkp) > 0 then
										DWPlus_RPTable[search[1][1]].lifetime_gained = DWPlus_RPTable[search[1][1]].lifetime_gained + tonumber(dkp)
									end
								else
									if not DWPlus_Archive[players[i]] or (DWPlus_Archive[players[i]] and DWPlus_Archive[players[i]].deleted ~= true) then
										DWP_Profile_Create(players[i], tonumber(dkp), tonumber(dkp));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
									end
								end
							end

							if DWP.ConfigTab6 and DWP.ConfigTab6.history and DWP.ConfigTab6:IsShown() then
								DWP:DKPHistory_Update(true)
							end
							DWP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "DWPDecay" then
							local players = {strsplit(",", string.utf8sub(deserialized.players, 1, -2))}
							local dkp = {strsplit(",", deserialized.dkp)}

							tinsert(DWPlus_RPHistory, 1, deserialized)
							
							for i=1, #players do
								local search = DWP:Table_Search(DWPlus_RPTable, players[i], "player")

								if search then
									DWPlus_RPTable[search[1][1]].dkp = DWPlus_RPTable[search[1][1]].dkp + tonumber(dkp[i])
								else
									if not DWPlus_Archive[players[i]] or (DWPlus_Archive[players[i]] and DWPlus_Archive[players[i]].deleted ~= true) then
										DWP_Profile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
									end
								end
							end

							if DWP.ConfigTab6 and DWP.ConfigTab6.history and DWP.ConfigTab6:IsShown() then
								DWP:DKPHistory_Update(true)
							end
							DWP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "DWPDelUsers" and UnitName("player") ~= sender then
							local numPlayers = 0
							local removedUsers = ""

							for i=1, #deserialized do
								local search = DWP:Table_Search(DWPlus_RPTable, deserialized[i].player, "player")

								if search and deserialized[i].deleted and deserialized[i].deleted ~= "Recovered" then
									if (DWPlus_Archive[deserialized[i].player] and DWPlus_Archive[deserialized[i].player].edited < deserialized[i].edited) or not DWPlus_Archive[deserialized[i].player] then
										--delete user, archive data
										if not DWPlus_Archive[deserialized[i].player] then		-- creates/adds to archive entry for user
											DWPlus_Archive[deserialized[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=deserialized[i].deleted, edited=deserialized[i].edited }
										else
											DWPlus_Archive[deserialized[i].player].deleted = deserialized[i].deleted
											DWPlus_Archive[deserialized[i].player].edited = deserialized[i].edited
										end
										
										c = DWP:GetCColors(DWPlus_RPTable[search[1][1]].class)
										if i==1 then
											removedUsers = "|cff"..c.hex..DWPlus_RPTable[search[1][1]].player.."|r"
										else
											removedUsers = removedUsers..", |cff"..c.hex..DWPlus_RPTable[search[1][1]].player.."|r"
										end
										numPlayers = numPlayers + 1

										tremove(DWPlus_RPTable, search[1][1])

										local search2 = DWP:Table_Search(DWPlus_Standby, deserialized[i].player, "player");

										if search2 then
											table.remove(DWPlus_Standby, search2[1][1])
										end
									end
								elseif not search and deserialized[i].deleted == "Recovered" then
									if DWPlus_Archive[deserialized[i].player] and (DWPlus_Archive[deserialized[i].player].edited == nil or DWPlus_Archive[deserialized[i].player].edited < deserialized[i].edited) then
										DWP_Profile_Create(deserialized[i].player);	-- User was recovered, create/request profile as needed
										DWPlus_Archive[deserialized[i].player].deleted = "Recovered"
										DWPlus_Archive[deserialized[i].player].edited = deserialized[i].edited
									end
								end
							end
							if numPlayers > 0 then
								DWP:FilterDKPTable(core.currentSort, "reset")
								DWP:Print("Removed "..numPlayers.." player(s): "..removedUsers)
							end
							return
						elseif prefix == "DWPDelLoot" then
							local search = DWP:Table_Search(DWPlus_Loot, deserialized.deletes, "index")

							if search then
								DWPlus_Loot[search[1][1]].deletedby = deserialized.index
							end

							local search_player = DWP:Table_Search(DWPlus_RPTable, deserialized.player, "player")

							if search_player then
								DWPlus_RPTable[search_player[1][1]].dkp = DWPlus_RPTable[search_player[1][1]].dkp + deserialized.cost 			 					-- refund previous looter
								DWPlus_RPTable[search_player[1][1]].lifetime_spent = DWPlus_RPTable[search_player[1][1]].lifetime_spent + deserialized.cost 			-- remove from lifetime_spent
							else
								if not DWPlus_Archive[deserialized.player] or (DWPlus_Archive[deserialized.player] and DWPlus_Archive[deserialized.player].deleted ~= true) then
									DWP_Profile_Create(deserialized.player, deserialized.cost, 0, deserialized.cost);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
								end
							end

							table.insert(DWPlus_Loot, 1, deserialized)
							DWP:SortLootTable()
							DWP:LootHistory_Reset()
							DWP:LootHistory_Update(L["NOFILTER"]);
							DWP:FilterDKPTable(core.currentSort, "reset")
						elseif prefix == "DWPDelSync" then
							local search = DWP:Table_Search(DWPlus_RPHistory, deserialized.deletes, "index")
							local players = {strsplit(",", string.utf8sub(deserialized.players, 1, -2))} 	-- cuts off last "," from string to avoid creating an empty value
							local dkp, mod;

							if strfind(deserialized.dkp, "%-%d*%.?%d+%%") then 		-- determines if it's a mass decay
								dkp = {strsplit(",", deserialized.dkp)}
								mod = "perc";
							else
								dkp = deserialized.dkp
								mod = "whole"
							end

							for i=1, #players do
								if mod == "perc" then
									local search2 = DWP:Table_Search(DWPlus_RPTable, players[i], "player")

									if search2 then
										DWPlus_RPTable[search2[1][1]].dkp = DWPlus_RPTable[search2[1][1]].dkp + tonumber(dkp[i])
									else
										if not DWPlus_Archive[players[i]] or (DWPlus_Archive[players[i]] and DWPlus_Archive[players[i]].deleted ~= true) then
											DWP_Profile_Create(players[i], tonumber(dkp[i]));	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
										end
									end
								else
									local search2 = DWP:Table_Search(DWPlus_RPTable, players[i], "player")

									if search2 then
										DWPlus_RPTable[search2[1][1]].dkp = DWPlus_RPTable[search2[1][1]].dkp + tonumber(dkp)

										if tonumber(dkp) < 0 then
											DWPlus_RPTable[search2[1][1]].lifetime_gained = DWPlus_RPTable[search2[1][1]].lifetime_gained + tonumber(dkp)
										end
									else
										if not DWPlus_Archive[players[i]] or (DWPlus_Archive[players[i]] and DWPlus_Archive[players[i]].deleted ~= true) then
											local gained;
											if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

											DWP_Profile_Create(players[i], tonumber(dkp), gained);	-- creates temp profile for data and requests additional data from online officers (hidden until data received)
										end
									end
								end
							end

							if search then
								DWPlus_RPHistory[search[1][1]].deletedby = deserialized.index;  	-- adds deletedby field if the entry exists
							end

							table.insert(DWPlus_RPHistory, 1, deserialized)

							if DWP.ConfigTab6 and DWP.ConfigTab6.history then
								DWP:DKPHistory_Update(true)
							end
							DKPTable_Update()
						elseif prefix == "DWPMinBid" then
							if core.IsOfficer then
								DWPlus_DB.MinBidBySlot = deserialized[1]

								for i=1, #deserialized[2] do
									local search = DWP:Table_Search(DWPlus_MinBids, deserialized[2][i].item)
									if search then
										DWPlus_MinBids[search[1][1]].minbid = deserialized[2][i].minbid
									else
										table.insert(DWPlus_MinBids, deserialized[2][i])
									end
								end

								DWP:Print(L["RECOMMENDRELOAD"])
							end
						elseif prefix == "DWPWhitelist" and DWP:GetGuildRankIndex(UnitName("player")) > 1 then -- only applies if not GM
							DWPlus_Whitelist = deserialized;
						elseif prefix == "DWPStand" then
							DWPlus_Standby = deserialized;
						elseif prefix == "DWPZSumBank" then
							if core.IsOfficer then
								DWPlus_DB.modes.ZeroSumBank = deserialized;
								if core.ZeroSumBank then
									if deserialized.balance == 0 then
										core.ZeroSumBank.LootFrame.LootList:SetText("")
									end
									DWP:ZeroSumBank_Update()
								end
							end
						elseif prefix == "DWPDKPModes" then
							if DWPlus_DB.modes.mode ~= deserialized[1].mode then
								DWP:Print(L["RECOMMENDRELOAD"])
							end
							DWPlus_DB.modes = deserialized[1]
							DWPlus_DB.DKPBonus = deserialized[2]
							DWPlus_DB.raiders = deserialized[3]
						elseif prefix == "DWPBidShare" then
							if core.BidInterface then
								DWP:Bids_Set(deserialized)
							end
							return
						elseif prefix == "DWPBossLoot" then
							local lootList = {};
							local startBidList = {};
							DWPlus_DB.bossargs.LastKilledBoss = deserialized.boss;
						
							for i=1, #deserialized do
								local item = Item:CreateFromItemLink(deserialized[i]);
								item:ContinueOnItemLoad(function()
									table.insert(lootList, {icon= item:GetItemIcon(), link=item:GetItemLink()})
									if DWP:IsLootMaster() then
										table.insert(startBidList, item:GetItemLink());
									end
								end);
							end

							DWP:LootTable_Set(lootList)
							DWP:BidTable_Set(startBidList)
						elseif prefix == "DWPConsul" then
							if (DWP:canUserChangeConsul(sender)) then
								DWPlus_Consul = deserialized;
								DWP:ConsulUpdate();
							end
						end
					else
						DWP:Print("Report the following error on Curse or Github: "..deserialized)  -- error reporting if string doesn't get deserialized correctly
					end
				end
			end
		end
	end
end

function DWP.Sync:SendData(prefix, data, target)
	--if prefix ~= "MDKPProfile" then print("|cff00ff00Sent: "..prefix.."|r") end
	if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages

	-- non officers / not encoded
	if IsInGuild() then
		if prefix == "DWPQuery" or prefix == "DWPBuild" or prefix == "DWPTalents" or prefix == "DWPRoles" then
			DWP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		elseif prefix == "DWPBidder" then		-- bid submissions. Keep to raid.
			DWP.Sync:SendCommMessage(prefix, data, "RAID")
			return;
		end
	end

	-- officers
	if IsInGuild() and core.IsOfficer then
		local serialized = nil;
		local packet = nil;

		if prefix == "DWPCommand" or prefix == "DWPRaidTime" then
			DWP.Sync:SendCommMessage(prefix, data, "RAID")
			return;
		end

		if prefix == "DWPBCastMsg" then
			DWP.Sync:SendCommMessage(prefix, data, "GUILD")
			return;
		end	

		if data then
			serialized = LibAceSerializer:Serialize(data);	-- serializes tables to a string
		end

		local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
		if compressed then
			packet = LibDeflate:EncodeForWoWAddonChannel(compressed)
		end

		-- encoded
		if (prefix == "DWPZSumBank" or prefix == "DWPBossLoot" or prefix == "DWPBidShare") then		-- Zero Sum bank/loot table/bid table data and bid submissions. Keep to raid.
			DWP.Sync:SendCommMessage(prefix, packet, "RAID")
			return;
		end

		if prefix == "DWPAllTabs" or prefix == "DWPMerge" then
			if target then
				DWP.Sync:SendCommMessage(prefix, packet, "WHISPER", target, "NORMAL", DWP_BroadcastFull_Callback, nil)
			else
				DWP.Sync:SendCommMessage(prefix, packet, "GUILD", nil, "NORMAL", DWP_BroadcastFull_Callback, nil)
			end
			return
		end
		
		if target then
			DWP.Sync:SendCommMessage(prefix, packet, "WHISPER", target)
		else
			DWP.Sync:SendCommMessage(prefix, packet, "GUILD")
		end
	end
end