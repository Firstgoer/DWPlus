local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local lockouts = CreateFrame("Frame", "LockoutsFrame");

--------------------------------------
-- Slash Command
--------------------------------------
DWP.Commands = {
	["config"] = function()
		if core.Initialized then
			local pass, err = pcall(DWP.Toggle)

			if not pass then
				DWP:Print(err)
				core.DWPUI:SetShown(false)
				StaticPopupDialogs["SUGGEST_RELOAD"] = {
					text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						ReloadUI();
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("SUGGEST_RELOAD")
			end
		else
			DWP:Print("DW Plus has not completed initialization.")
		end
	end,
	["reset"] = DWP.ResetPosition,
	["bid"] = function(...)
		if core.Initialized then
			local item = strjoin(" ", ...)
			DWP:CheckOfficer()
			DWP:StatusVerify_Update()

			if core.IsOfficer then	
				if ... == nil then
					DWP.ToggleSelectBidWindow()
				else
					local itemName,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(item)
					DWP:Print("Opening Bid Window for: ".. item)
					DWP:ToggleBidWindow(item, itemIcon, itemName)
				end
			end
			DWP:BidInterface_Toggle()
		else
			DWP:Print("DW Plus has not completed initialization.")
		end 
	end,
	["repairtables"] = function(...) 			-- test new features
		local cmd = ...
		if core.IsOfficer then
			if cmd == "true" then
				DWP:RepairTables(cmd)
			else
				DWP:RepairTables()
			end
		end
	end,
	["award"] = function (name, ...)
		if core.IsOfficer and core.Initialized then
			DWP:StatusVerify_Update()
			
			if not name or not strfind(name, ":::::") then
				DWP:Print(L["AWARDWARNING"])
				return
			end
			local item = strjoin(" ", ...)
			if not item then return end
			item = name.." "..item;
			
			DWP:AwardConfirm(nil, 0, DWPlus_DB.bossargs.LastKilledBoss, DWPlus_DB.bossargs.CurrentRaidZone, item)
		else
			DWP:Print(L["NOPERMISSION"])
		end
	end,
	["lockouts"] = function()
		lockouts:RegisterEvent("UPDATE_INSTANCE_INFO");
		lockouts:SetScript("OnEvent", DWP_OnEvent);
		RequestRaidInfo()
	end,
	["timer"] = function(time, ...)
		if time == nil then
			DWP:BroadcastTimer(1, "...")
		else
			local title = strjoin(" ", ...)
			DWP:BroadcastTimer(tonumber(time), title)
		end
	end,
	["export"] = function(time, ...)
		DWP:ToggleExportWindow()
	end,
	["modes"] = function()
		if core.Initialized then
			DWP:CheckOfficer()
			if core.IsOfficer then
				DWP:ToggleDKPModesWindow()
			else
				DWP:Print(L["NOPERMISSION"])
			end
		else
			DWP:Print("DW Plus has not completed initialization.")
		end
	end,
	["changelog"] = function()
		DWP.ChangeLogDisplay:Show();
	end,
	["consul"] = function()
		DWP:ConsulModal();
	end,
	["help"] = function()
		DWP:Print(" ");
		DWP:Print(L["SLASHCOMMANDLIST"]..":")
		DWP:Print("|cff00cc66/dwp|r - "..L["DKPLAUNCH"]);
		DWP:Print("|cff00cc66/dwp ?|r - "..L["HELPINFO"]);
		DWP:Print("|cff00cc66/dwp reset|r - "..L["DKPRESETPOS"]);
		DWP:Print("|cff00cc66/dwp lockouts|r - "..L["DKPLOCKOUT"]);
		DWP:Print("|cff00cc66/dwp timer|r - "..L["CREATERAIDTIMER"]);
		DWP:Print("|cff00cc66/dwp bid|r - "..L["OPENBIDWINDOWHELP"]);
		DWP:Print("|cff00cc66/dwp bid [itemlink]|r - "..L["OPENAUCWINHELP"]);
		DWP:Print("|cff00cc66/dwp award [item link]|r - "..L["DKPAWARDHELP"]);
		DWP:Print("|cff00cc66/dwp modes|r - "..L["DKPMODESHELP"]);
		DWP:Print("|cff00cc66/dwp export|r - "..L["DKPEXPORTHELP"]);
		DWP:Print("|cff00cc66/dwp mmb|r - "..L["MINIMAPTOGGLE"]);
		DWP:Print("|cff00cc66/dwp changelog|r - "..L["CHANGELOGCOMMAND"]);
		DWP:Print("|cff00cc66/dwp consul|r - "..L["CONSULMODAL"]);
		DWP:Print(" ");
		DWP:Print(L["WHISPERCMDSHELP"]);
		DWP:Print("|cff00cc66!bid (or !bid <"..L["VALUE"]..">)|r - "..L["BIDHELP"]);
		DWP:Print("|cff00cc66!rp (or !rp <"..L["PLAYERNAME"]..">)|r - "..L["DKPCMDHELP"]);
		DWP:Print(L["SUBMITBUGS"].." @ https://github.com/Firstgoer/DWPlus/issues");
	end,
};

local function HandleSlashCommands(str)
	if (#str == 0) then
		DWP.Commands.config();
		return;
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = DWP.Commands;
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg];
				end
			else
				DWP.Commands.help();
				return;
			end
		end
	end
end

function DWP_OnEvent(self, event, arg1, ...)

	-- unregister unneccessary events
	if event == "CHAT_MSG_WHISPER" and not DWPlus_DB.modes.channels.whisper then
		self:UnregisterEvent("CHAT_MSG_WHISPER")
		return
	end
	if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") and not DWPlus_DB.modes.channels.raid then
		self:UnregisterEvent("CHAT_MSG_RAID")
		self:UnregisterEvent("CHAT_MSG_RAID_LEADER")
		return
	end
	if event == "CHAT_MSG_GUILD" and not DWPlus_DB.modes.channels.guild and not DWPlus_DB.modes.StandbyOptIn then
		self:UnregisterEvent("CHAT_MSG_GUILD")
		return
	end

	if event == "ADDON_LOADED" then
		DWP:OnInitialize(event, arg1)
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "BOSS_KILL" then
		DWP:CheckOfficer()
		if core.IsOfficer and IsInRaid() then
			local boss_name = ...;

			if DWP:Table_Search(core.EncounterList, arg1) then
				DWP.ConfigTab2.BossKilledDropdown:SetValue(arg1)

				if DWPlus_DB.modes.StandbyOptIn then
					DWPlus_Standby_Announce(boss_name)
				end

				if DWPlus_DB.modes.AutoAward then
					if not DWPlus_DB.modes.StandbyOptIn and DWPlus_DB.DKPBonus.IncStandby then
						DWP:AutoAward(3, DWPlus_DB.DKPBonus.BossKillBonus, DWPlus_DB.bossargs.CurrentRaidZone..": "..DWPlus_DB.bossargs.LastKilledBoss)
					else
						DWP:AutoAward(1, DWPlus_DB.DKPBonus.BossKillBonus, DWPlus_DB.bossargs.CurrentRaidZone..": "..DWPlus_DB.bossargs.LastKilledBoss)
					end
				end
			else
				DWP:Print("Event ID: "..arg1.." - > "..boss_name.." Killed. Please report this Event ID at https://www.curseforge.com/wow/addons/monolith-dkp to update raid event handlers.")
			end
		elseif IsInRaid() then
			DWPlus_DB.bossargs.LastKilledBoss = ...;
		end
	elseif event == "ENCOUNTER_START" then
		if DWPlus_DB.defaults.AutoLog and IsInRaid() then
			if not LoggingCombat() then
				LoggingCombat(1)
				DWP:Print(L["NOWLOGGINGCOMBAT"])
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then   		-- logs 15 recent zones entered while in a raid party
		if IsInRaid() and core.Initialized then 					-- only processes combat log events if in raid
			DWP:CheckOfficer()
			if core.IsOfficer then
				if not DWP:Table_Search(DWPlus_DB.bossargs.RecentZones, GetRealZoneText()) then 	-- only adds it if it doesn't already exist in the table
					if #DWPlus_DB.bossargs.RecentZones > 14 then
						for i=15, #DWPlus_DB.bossargs.RecentZones do  		-- trims the tail end of the stack
							table.remove(DWPlus_DB.bossargs.RecentZones, i)
						end
					end
					table.insert(DWPlus_DB.bossargs.RecentZones, 1, GetRealZoneText())
				end

				local currentDate = date("%m/%d/%y");
				local _, _, _, _, _, _, _, instanceID = GetInstanceInfo();
				if DWPlus_DB.bossargs.LastConsulNotifications[instanceID] ~= currentDate then
					DWPlus_ConsulItemsCountMessage(instanceID);
					DWPlus_DB.bossargs.LastConsulNotifications[instanceID] = currentDate;
				end
			end
			if DWPlus_DB.defaults.AutoLog and DWP:Table_Search(core.ZoneList, GetRealZoneText()) then
				if not LoggingCombat() then
					LoggingCombat(1)
					DWP:Print(L["NOWLOGGINGCOMBAT"])
				end
			end
		end
	elseif event == "CHAT_MSG_WHISPER" then
		DWP:CheckOfficer()
		arg1 = strlower(arg1)
		if (core.BidInProgress or string.find(arg1, "!rp") == 1 or string.find(arg1, "！rp") == 1) and core.IsOfficer == true then
			DWP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		if IsInGuild() and not core.InitStart then
			GuildRoster()
			core.InitStart = true
			self:UnregisterEvent("GUILD_ROSTER_UPDATE")

			-- Prints info after all addons have loaded. Circumvents addons that load saved chat messages pushing info out of view.
			C_Timer.After(3, function ()
				DWP:CheckOfficer()
				DWP:SortLootTable()
				DWP:SortDKPHistoryTable()
				DWP:Print(L["VERSION"].." "..core.MonVersion..". ".."|cff00cc66/dwp ?".." - "..L["HELPINFO"].."|r");
				DWP:Print(L["LOADED"].." "..#DWPlus_RPTable.." "..L["PLAYERRECORDS"]..", "..#DWPlus_Loot.." "..L["LOOTHISTRECORDS"].." "..#DWPlus_RPHistory.." "..L["DKPHISTRECORDS"]..".");
				DWP.Sync:SendData("DWPBuild", tostring(core.BuildNumber)) -- broadcasts build number to guild to check if a newer version is available

				if not DWPlus_DB.defaults.installed210 then
					DWPlus_DB.defaults.installed210 = time(); -- identifies when 2.1.0 was installed to block earlier posts from broadcasting in sync (for now)
					DWP_ReindexTables() 					-- reindexes all entries created prior to 2.1 installation in "GuildMaster-EntryDate" format for consistency.
					DWPlus_DB.defaults.installed = nil
				end

				local seed
				if #DWPlus_RPHistory > 0 and #DWPlus_Loot > 0 and strfind(DWPlus_RPHistory[1].index, "-") and strfind(DWPlus_Loot[1].index, "-") then
					local off1,date1 = strsplit("-", DWPlus_RPHistory[1].index)
					local off2,date2 = strsplit("-", DWPlus_Loot[1].index)
					
					if DWP:ValidateSender(off1) and DWP:ValidateSender(off2) and tonumber(date1) > DWPlus_DB.defaults.installed210 and tonumber(date2) > DWPlus_DB.defaults.installed210 then
						seed = DWPlus_RPHistory[1].index..","..DWPlus_Loot[1].index  -- seed is only sent if the seed dates are post 2.1 installation and the posting officer is an officer in the current guild
					else
						seed = "start"
					end
				else
					seed = "start"
				end

				DWP.Sync:SendData("DWPQuery", seed) -- requests role and spec data and sends current seeds (index of newest DKP and Loot entries)
			end)
		end
	elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
		DWP:CheckOfficer()
		arg1 = strlower(arg1)
		if (core.BidInProgress or string.find(arg1, "!rp") == 1 or string.find(arg1, "!standby") == 1 or string.find(arg1, "！rp") == 1) and core.IsOfficer == true then
			DWP_CHAT_MSG_WHISPER(arg1, ...)
		end
	elseif event == "UPDATE_INSTANCE_INFO" then
		local num = GetNumSavedInstances()
		local raidString, reset, newreset, days, hours, mins, maxPlayers, numEncounter, curLength;

		if not DWPlus_DB.Lockouts then DWPlus_DB.Lockouts = {Three = 0, Five = 1570032000, Seven = 1569945600} end

		for i=1, num do 		-- corrects reset timestamp for any raids where an active lockout exists
			_,_,reset,_,_,_,_,_,maxPlayers,_,numEncounter = GetSavedInstanceInfo(i)
			newreset = time() + reset + 2 	-- returned time is 2 seconds off

			if maxPlayers == 40 and numEncounter > 1 then
				curLength = "Seven"
			elseif maxPlayers == 40 and numEncounter == 1 then
				curLength = "Five"
			elseif maxPlayers == 20 then
				curLength = "Three"
			end

			if DWPlus_DB.Lockouts[curLength] < newreset then
				DWPlus_DB.Lockouts[curLength] = newreset
			end
		end

		-- Updates lockout timer if no lockouts were found to do so.
		while DWPlus_DB.Lockouts.Three < time() do DWPlus_DB.Lockouts.Three = DWPlus_DB.Lockouts.Three + 259200 end
		while DWPlus_DB.Lockouts.Five < time() do DWPlus_DB.Lockouts.Five = DWPlus_DB.Lockouts.Five + 432000 end
		while DWPlus_DB.Lockouts.Seven < time() do DWPlus_DB.Lockouts.Seven = DWPlus_DB.Lockouts.Seven + 604800 end

		for k,v in pairs(DWPlus_DB.Lockouts) do
			reset = v - time();
			days = math.floor(reset / 86400)
			hours = math.floor(math.floor(reset % 86400) / 3600)
			mins = math.ceil((reset % 3600) / 60)
			
			if days > 1 then days = " "..days.." "..L["DAYS"] elseif days == 0 then days = "" else days = " "..days.." "..L["DAY"] end
			if hours > 1 then hours = " "..hours.." "..L["HOURS"] elseif hours == 0 then hours = "" else hours = " "..hours.." "..L["HOUR"].."." end
			if mins > 1 then mins = " "..mins.." "..L["MINUTES"].."." elseif mins == 0 then mins = "" else mins = " "..mins.." "..L["MINUTE"].."." end

			if k == "Three" then raidString = "ZG, AQ20"
			elseif k == "Five" then raidString = "Onyxia"
			elseif k == "Seven" then raidString = "MC, BWL, AQ40"
			end

			if k ~= "Three" then 	-- remove when three day raid lockouts are added
				DWP:Print(raidString.." "..L["RESETSIN"]..days..hours..mins.." ("..date("%A @ %H:%M:%S%p", v)..")")
			end
		end

		self:UnregisterEvent("UPDATE_INSTANCE_INFO");
	elseif event == "CHAT_MSG_GUILD" then
		DWP:CheckOfficer()
		if core.IsOfficer then
			arg1 = strlower(arg1)
			if (core.BidInProgress or string.find(arg1, "!rp") == 1 or string.find(arg1, "！rp") == 1) and DWPlus_DB.modes.channels.guild then
				DWP_CHAT_MSG_WHISPER(arg1, ...)
			elseif string.find(arg1, "!standby") == 1 and core.StandbyActive then
				DWPlus_Standby_Handler(arg1, ...)
			end
		end
	--elseif event == "CHAT_MSG_SYSTEM" then
		--MonoDKP_CHAT_MSG_SYSTEM(arg1)
	elseif event == "GROUP_ROSTER_UPDATE" then 			--updates raid listing if window is open
		if DWP.UIConfig and core.DWPUI:IsShown() then
			if core.CurSubView == "raid" then
				DWP:ViewLimited(true)
			elseif core.CurSubView == "raid and standby" then
				DWP:ViewLimited(true, true)
			end
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 		-- logs last 15 NPCs killed while in raid
		if IsInRaid() then 					-- only processes combat log events if in raid
			local _,arg1,_,_,_,_,_,arg2,arg3 = CombatLogGetCurrentEventInfo();
			if arg1 == "UNIT_DIED" and not strfind(arg2, "Player") and not strfind(arg2, "Pet-") then
				DWP:CheckOfficer()
				if core.IsOfficer then
					if not DWP:Table_Search(DWPlus_DB.bossargs.LastKilledNPC, arg3) then 	-- only adds it if it doesn't already exist in the table
						if #DWPlus_DB.bossargs.LastKilledNPC > 14 then
							for i=15, #DWPlus_DB.bossargs.LastKilledNPC do  		-- trims the tail end of the stack
								table.remove(DWPlus_DB.bossargs.LastKilledNPC, i)
							end
						end
						table.insert(DWPlus_DB.bossargs.LastKilledNPC, 1, arg3)
					end
				end
			end
		end
	--[[elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 					-- replaced with above BOSS_KILL event handler
		if IsInRaid() then 					-- only processes combat log events if in raid
			local _,arg1,_,_,_,_,_,_,arg2 = CombatLogGetCurrentEventInfo();			-- run operation when boss is killed
			if arg1 == "UNIT_DIED" then
				DWP:CheckOfficer()
				if core.IsOfficer == true then
					if DWP:TableStrFind(core.BossList, arg2) then
						DWP.ConfigTab2.BossKilledDropdown:SetValue(arg2)
					elseif arg2 == "Flamewalker Elite" or arg2 == "Flamewalker Healer" then
						DWP.ConfigTab2.BossKilledDropdown:SetValue("Majordomo Executus")
					elseif arg2 == "Emperor Vek'lor" or arg2 == "Emperor Vek'nilash" then
						DWP.ConfigTab2.BossKilledDropdown:SetValue("Twin Emperors")
					elseif arg2 == "Princess Yauj" or arg2 == "Vem" or arg2 == "Lord Kri" then
						DWP.ConfigTab2.BossKilledDropdown:SetValue("Bug Family")
					elseif arg2 == "Highlord Mograine" or arg2 == "Thane Korth'azz" or arg2 == "Sir Zeliek" or arg2 == "Lady Blaumeux" then
						DWP.ConfigTab2.BossKilledDropdown:SetValue("The Four Horsemen")
					elseif arg2 == "Gri'lek" or arg2 == "Hazza'rah" or arg2 == "Renataki" or arg2 == "Wushoolay" then
						DWP.ConfigTab2.BossKilledDropdown:SetValue("Edge of Madness")
					end
				end
			end
		end--]]
	elseif event == "LOOT_OPENED" then
		DWP:CheckOfficer();
		if core.IsOfficer then
			if not IsInRaid() and arg1 == false then  -- only fires hook when autoloot is not active if not in a raid to prevent nil value error
				DWP_Register_ShiftClickLootWindowHook()
			elseif IsInRaid() then
				DWP_Register_ShiftClickLootWindowHook()
			end
			local lootTable = {}
			local lootList = {};
			local startBidList = {};

			for i=1, GetNumLootItems() do
				if LootSlotHasItem(i) and GetLootSlotLink(i) then
					local _,link,quality = GetItemInfo(GetLootSlotLink(i))
					if quality >= 3 then
						table.insert(lootTable, link)
						if DWP:IsLootMaster() then
							table.insert(startBidList, link);
						end
					end
				end
			end
			local name
			if not UnitIsFriend("player", "target") and UnitIsDead("target") then
				name = UnitName("target")  -- sets bidding window name to current target
			else
				name = core.LastKilledBoss  -- sets name to last killed boss if no target is available (chests)
			end
			lootTable.boss=name
			DWP.Sync:SendData("DWPBossLoot", lootTable)

			for i=1, #lootTable do
				local item = Item:CreateFromItemLink(lootTable[i]);
				item:ContinueOnItemLoad(function()
					local icon = item:GetItemIcon()
					table.insert(lootList, {icon=icon, link=item:GetItemLink()})
					DWP:CheckExistingConsul(item);
				end);
			end

			DWP:LootTable_Set(lootList)
			DWP:BidTable_Set(name, startBidList)
		end
	elseif event == "CHAT_MSG_LOOT" then
		DWP:CheckOfficer();
		if core.IsOfficer then
			DWP:CheckConsulReceived(arg1);
		end
	end
end

function DWP:OnInitialize(event, name)		-- This is the FIRST function to run on load triggered registered events at bottom of file
	if (name ~= "DWPlus") then return end

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end
	
	----------------------------------
	-- Register Slash Commands
	----------------------------------
	SLASH_DWPlus1 = "/dwp";
	SLASH_DWPlus2 = "/dwplus";
	SlashCmdList.DWPlus = HandleSlashCommands;

	--[[SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI 				-- for debugging
	SlashCmdList.RELOADUI = ReloadUI;

	SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
	SlashCmdList.FRAMESTK = function()
		LoadAddOn("Blizzard_DebugTools");
		FrameStackTooltip_Toggle();
	end--]]

	if(event == "ADDON_LOADED") then
		core.Initialized = false
		core.InitStart = false
		core.IsOfficer = nil
		C_Timer.After(5, function ()
			core.DWPUI = DWP.UIConfig or DWP:CreateMenu();		-- creates main menu after 5 seconds (trying to initialize after raid frames are loaded)
		end)
		if not DWPlus_RPTable then DWPlus_RPTable = {} end;
		if not DWPlus_Loot then DWPlus_Loot = {} end;
		if not DWPlus_RPHistory then DWPlus_RPHistory = {} end;
		if not DWPlus_MinBids then DWPlus_MinBids = {} end;
		if not DWPlus_Whitelist then DWPlus_Whitelist = {} end;
		if not DWPlus_Standby then DWPlus_Standby = {} end;
		if not DWPlus_Archive then DWPlus_Archive = {} end;
		if not DWPlus_Consul then DWPlus_Consul = {} end;
		if not DWPlus_DB then DWPlus_DB = {} end
		if not DWPlus_DB.DKPBonus or not DWPlus_DB.DKPBonus.OnTimeBonus then
			DWPlus_DB.DKPBonus = {
				OnTimeBonus = 15, BossKillBonus = 5, CompletionBonus = 10, NewBossKillBonus = 10, UnexcusedAbsence = -25, BidTimer = 30, DecayPercentage = 20, GiveRaidStart = false, IncStandby = false,
			}
		end
		if not DWPlus_DB.defaults or not DWPlus_DB.defaults.HistoryLimit or not DWPlus_DB.defaults.DWPScaleSize then
			DWPlus_DB.defaults = {
				HistoryLimit = 2500, DKPHistoryLimit = 2500, BidTimerSize = 1.0, DWPScaleSize = 1.0, supressNotifications = false, TooltipHistoryCount = 15, SupressTells = true,
			}
		end
		if not DWPlus_DB.defaults.MiniMapButton then
			DWPlus_DB.defaults.MiniMapButton = {shown = true, minimapPos = 200, hide = nil}
		end
		if not DWPlus_DB.defaults.ChatFrames then
			DWPlus_DB.defaults.ChatFrames = {}
			for i = 1, NUM_CHAT_WINDOWS do
				local name = GetChatWindowInfo(i)

				if name ~= "" then
					DWPlus_DB.defaults.ChatFrames[name] = true
				end
			end
		end
		if not DWPlus_DB.raiders then DWPlus_DB.raiders = {} end
		if not DWPlus_DB.MinBidBySlot or not DWPlus_DB.MinBidBySlot.Head then
			DWPlus_DB.MinBidBySlot = {
				Head = 70, Neck = 70, Shoulders = 70, Cloak = 70, Chest = 70, Bracers = 70, Hands = 70, Belt = 70, Legs = 70, Boots = 70, Ring = 70, Trinket = 70, OneHanded = 70, TwoHanded = 70, OffHand = 70, Range = 70, Other = 70,
			}
		end
		if not DWPlus_DB.bossargs then DWPlus_DB.bossargs = { CurrentRaidZone = "Molten Core", LastKilledBoss = "Lucifron" } end
		if not DWPlus_DB.modes or not DWPlus_DB.modes.mode then DWPlus_DB.modes = { mode = "Minimum Bid Values", SubZeroBidding = false, rounding = 0, AddToNegative = false, increment = 60, ZeroSumBidType = "Static", AllowNegativeBidders = false } end;
		if not DWPlus_DB.modes.ZeroSumBank then DWPlus_DB.modes.ZeroSumBank = { balance = 0 } end
		if not DWPlus_DB.modes.channels then DWPlus_DB.modes.channels = { raid = true, whisper = true, guild = true } end
		if not DWPlus_DB.modes.costvalue then DWPlus_DB.modes.costvalue = "Integer" end
		if not DWPlus_DB.modes.rolls or not DWPlus_DB.modes.rolls.min then DWPlus_DB.modes.rolls = { min = 1, max = 100, UsePerc = false, AddToMax = 0 } end
		if not DWPlus_DB.bossargs.LastKilledNPC then DWPlus_DB.bossargs.LastKilledNPC = {} end
		if not DWPlus_DB.bossargs.RecentZones then DWPlus_DB.bossargs.RecentZones = {} end
		if not DWPlus_DB.bossargs.LastConsulNotifications then DWPlus_DB.bossargs.LastConsulNotifications = {} end
		if not DWPlus_DB.defaults.HideChangeLogs then DWPlus_DB.defaults.HideChangeLogs = 0 end
		if not DWPlus_DB.modes.AntiSnipe then DWPlus_DB.modes.AntiSnipe = 0 end
		if not DWPlus_DB.defaults.CurrentGuild then DWPlus_DB.defaults.CurrentGuild = {} end
		if not DWPlus_RPHistory.seed then DWPlus_RPHistory.seed = 0 end
		if not DWPlus_Loot.seed then DWPlus_Loot.seed = 0 end
		if DWPlus_RPTable.seed then DWPlus_RPTable.seed = nil end
		if DWP_Meta then DWP_Meta = nil end
		if DWP_Meta_Remote then DWP_Meta_Remote = nil end
		if DWPlus_Archive_Meta then DWPlus_Archive_Meta = nil end
		if DWP_Errant then DWP_Errant = nil end
		if not DWPlus_DB.minimap then DWPlus_DB.minimap = DWPlus_DB.defaults.MiniMapButton end
		if not DWPlus_DB.ConfigPos then DWPlus_DB.ConfigPos = {x = -250, y = 100} end
		if not DWPlus_DB.TabMenuShown then DWPlus_DB.TabMenuShown = false end
		if not DWPlus_DB.ConsulFilters then DWPlus_DB.ConsulFilters = {}; end;

		------------------------------------
		--	Import SavedVariables
		------------------------------------
		core.WorkingTable 		= DWPlus_RPTable;						-- imports full DKP table to WorkingTable for list manipulation
		core.CurrentRaidZone	= DWPlus_DB.bossargs.CurrentRaidZone;	-- stores raid zone as a redundency
		core.LastKilledBoss 	= DWPlus_DB.bossargs.LastKilledBoss;	-- stores last boss killed as a redundency
		core.LastKilledNPC		= DWPlus_DB.bossargs.LastKilledNPC 		-- Stores last 30 mobs killed in raid.
		core.RecentZones		= DWPlus_DB.bossargs.RecentZones 		-- Stores last 30 zones entered within a raid party.

		table.sort(DWPlus_RPTable, function(a, b)
			return a["player"] < b["player"]
		end)

		DWP:StartBidTimer("seconds", nil)						-- initiates timer frame for use

		if DWP.BidTimer then DWP.BidTimer:SetScript("OnUpdate", nil) end

		if #DWPlus_Loot > DWPlus_DB.defaults.HistoryLimit then
			DWP:PurgeLootHistory()									-- purges Loot History entries that exceed the "HistoryLimit" option variable (oldest entries) and populates DWPlus_Archive with deleted values
		end
		if #DWPlus_RPHistory > DWPlus_DB.defaults.DKPHistoryLimit then
			DWP:PurgeDKPHistory()									-- purges DKP History entries that exceed the "DKPHistoryLimit" option variable (oldest entries) and populates DWPlus_Archive with deleted values
		end

		DWP:InitMinimapButton()
	end
end

----------------------------------
-- Register Events and Initiallize AddOn
----------------------------------

local events = CreateFrame("Frame", "EventsFrame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:RegisterEvent("ENCOUNTER_START");  		-- FOR TESTING PURPOSES.
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- NPC kill event
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("CHAT_MSG_RAID")
events:RegisterEvent("CHAT_MSG_RAID_LEADER")
events:RegisterEvent("CHAT_MSG_WHISPER");
events:RegisterEvent("CHAT_MSG_GUILD")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("BOSS_KILL")
events:RegisterEvent("CHAT_MSG_LOOT")
events:SetScript("OnEvent", DWP_OnEvent); -- calls the above DWP_OnEvent function to determine what to do with the event

local origChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow;
ChatFrame_OnHyperlinkShow = function(...)
	local _, link = ...;
	local linkStart = string.sub(link, 1, 3);
	if linkStart == "dwp" and not IsModifiedClick() then
		local commandString = string.sub(link, 5);
		local command, par1, par2 = string.split(":", commandString)

		if command == "showConsul" then
			DWP:ConsulModal(true);
		elseif command == "deleteConsul" then
			-- player, itemId
			DWP:DeleteConsul(par1, par2);
		end
		return;
	end
	return origChatFrame_OnHyperlinkShow(...);
end