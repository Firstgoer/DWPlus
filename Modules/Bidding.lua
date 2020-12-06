local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

local width, height, numrows = 370, 18, 13
local SelectedBidder = {}
local CurZone;
local Timer = 0;
local timerToggle = 0;
local mode;
local events = CreateFrame("Frame", "BiddingEventsFrame");
local menuFrame = CreateFrame("Frame", "DWPBidWindowMenuFrame", UIParent, "UIDropDownMenuTemplate")
local hookedSlots = {}

local function UpdateBidWindow()
	if DWPlus_DB.BidParams.CurrItemForBid then
		core.BiddingWindow.item:SetText(DWPlus_DB.BidParams.CurrItemForBid)
	else
		core.BiddingWindow.item:SetText(L["NONE"])
	end
	core.BiddingWindow.itemIcon:SetTexture(DWPlus_DB.BidParams.CurrItemIcon)
end

function DWP:BidsSubmitted_Get()
	return DWPlus_DB.BidsSubmitted;
end

function DWP:BidsSubmitted_Clear()
	DWPlus_DB.BidsSubmitted = {};
end

local function Roll_OnEvent(self, event, arg1, ...)
	if event == "CHAT_MSG_SYSTEM" and core.BidInProgress then

		if GetLocale() == 'deDE' then RANDOM_ROLL_RESULT = "%s w\195\188rfelt. Ergebnis: %d (%d-%d)" end  -- corrects roll pattern for german clients
		local pattern = string.gsub(RANDOM_ROLL_RESULT, "[%(%)-]", "%%%1")
		pattern = string.gsub(pattern, "%%s", "(.+)")
		pattern = string.gsub(pattern, "%%d", "%(%%d+%)")

		for name, roll, low, high in string.gmatch(arg1, pattern) do
			local search = DWP:Table_Search(DWPlus_RPTable, name)
			local minRoll;
        	local maxRoll;

        	if DWPlus_DB.modes.rolls.UsePerc then
        		if DWPlus_DB.modes.rolls.min == 0 or DWPlus_DB.modes.rolls.min == 1 then
        			minRoll = 1;
        		else
        			minRoll = DWPlus_RPTable[search[1][1]].dkp * (DWPlus_DB.modes.rolls.min / 100);
        		end
        		maxRoll = DWPlus_RPTable[search[1][1]].dkp * (DWPlus_DB.modes.rolls.max / 100) + DWPlus_DB.modes.rolls.AddToMax;
        	elseif not DWPlus_DB.modes.rolls.UsePerc then
        		minRoll = DWPlus_DB.modes.rolls.min;

        		if DWPlus_DB.modes.rolls.max == 0 then
        			maxRoll = DWPlus_RPTable[search[1][1]].dkp + DWPlus_DB.modes.rolls.AddToMax;
        		else
        			maxRoll = DWPlus_DB.modes.rolls.max + DWPlus_DB.modes.rolls.AddToMax;
        		end
        	end
        	if tonumber(minRoll) < 1 then minRoll = 1 end
        	if tonumber(maxRoll) < 1 then maxRoll = 1 end
        	if tonumber(low) > tonumber(minRoll) or tonumber(high) > tonumber(maxRoll) then
        		SendChatMessage(L["ROLLDECLINED"].." "..math.floor(minRoll).."-"..math.floor(maxRoll)..".", "WHISPER", nil, name)
        		return;
        	end

        	--math.floor(minRoll).."-"..math.floor(maxRoll)

			if search and mode == "Roll Based Bidding" and core.BiddingWindow.cost:GetNumber() > DWPlus_RPTable[search[1][1]].dkp and not DWPlus_DB.modes.SubZeroBidding and DWPlus_DB.modes.costvalue ~= "Percent" then
        		SendChatMessage(L["ROLLNOTACCEPTED"].." "..DWPlus_RPTable[search[1][1]].dkp.." "..L["DKP"]..".", "WHISPER", nil, name)

        		return;
            end

			if not DWP:Table_Search(DWPlus_DB.BidsSubmitted, name) and search then
				if DWPlus_DB.modes.AnnounceBid and ((DWPlus_DB.BidsSubmitted[1] and DWPlus_DB.BidsSubmitted[1].roll < roll) or not DWPlus_DB.BidsSubmitted[1]) then
					if not DWPlus_DB.modes.AnnounceBidName then
						SendChatMessage(L["NEWHIGHROLL"].." "..roll.." ("..low.."-"..high..")", "RAID")
					else
						SendChatMessage(L["NEWHIGHROLLER"].." "..name..": "..roll.." ("..low.."-"..high..")", "RAID")
					end
				end
				table.insert(DWPlus_DB.BidsSubmitted, {player=name, roll=roll, range=" ("..low.."-"..high..")"})
				if DWPlus_DB.modes.BroadcastBids then
					DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
				end
			else
				if not search then
					SendChatMessage(L["NAMENOTFOUND"], "WHISPER", nil, name)
				else
					SendChatMessage(L["ONLYONEROLLWARN"], "WHISPER", nil, name)
				end
			end
			BidScrollFrame_Update()
		end
	end
end

local function BidCmd(...)
	local _, cmd = string.split(" ", ..., 2)

	if tonumber(cmd) then
		cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
	elseif cmd then
		cmd = cmd:trim()
	end

	return cmd;
end

function DWP_CHAT_MSG_WHISPER(text, ...)
	local name = ...;
	local cmd;
	local dkp;
	local response = L["ERRORPROCESSING"];
	mode = DWPlus_DB.modes.mode;

	if string.find(name, "-") then					-- finds and removes server name from name if exists
		local dashPos = string.find(name, "-")
		name = strsub(name, 1, dashPos-1)
	end

	if string.find(text, "!bid") == 1 and core.IsOfficer == true then
		if core.BidInProgress then
			cmd = BidCmd(text)
			if (mode == "Static Item Values" and cmd ~= "cancel") or (mode == "Zero Sum" and cmd ~= "cancel" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
				cmd = nil;
			end
			if cmd == "cancel" and DWPlus_DB.modes.mode ~= "Roll Based Bidding" then
				local flagCanceled = false
				for i=1, #DWPlus_DB.BidsSubmitted do 					-- !bid cancel will cancel their bid
					if DWPlus_DB.BidsSubmitted[i] and DWPlus_DB.BidsSubmitted[i].player == name then
						table.remove(DWPlus_DB.BidsSubmitted, i)
						if DWPlus_DB.modes.BroadcastBids then
							DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
						end
						BidScrollFrame_Update()
						response = L["BIDCANCELLED"]
						flagCanceled = true
						--SendChatMessage(response, "WHISPER", nil, name)
						--return;
					end
				end
				if not flagCanceled then
					response = L["NOTSUBMITTEDBID"]
				end
			elseif cmd == "cancel" and DWPlus_DB.modes.mode == "Roll Based Bidding" then
				response = L["CANTCANCELROLL"]
			end
			dkp = tonumber(DWP:GetPlayerDKP(name))
			if not dkp then		-- exits function if player is not on the DKP list
				SendChatMessage(L["INVALIDPLAYER"], "WHISPER", nil, name)
				return
			end
			if (tonumber(cmd) and (DWPlus_DB.modes.MaximumBid == nil or tonumber(cmd) <= DWPlus_DB.modes.MaximumBid or DWPlus_DB.modes.MaximumBid == 0)) or ((mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static")) and not cmd) then
				if dkp then
					if (cmd and cmd <= dkp) or (DWPlus_DB.modes.SubZeroBidding == true and dkp >= 0) or (DWPlus_DB.modes.SubZeroBidding == true and DWPlus_DB.modes.AllowNegativeBidders == true) or (mode == "Static Item Values" and dkp > 0 and (dkp > core.BiddingWindow.cost:GetNumber() or DWPlus_DB.modes.SubZeroBidding == true or DWPlus_DB.modes.costvalue == "Percent")) or ((mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") and not cmd) then
						if (cmd and core.BiddingWindow.minBid and tonumber(core.BiddingWindow.minBid:GetNumber()) <= cmd) or mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid" and cmd >= core.BiddingWindow.minBid:GetNumber()) then
							for i=1, #DWPlus_DB.BidsSubmitted do 					-- checks if a bid was submitted, removes last bid if it was
								if (mode ~= "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType ~= "Static") and DWPlus_DB.BidsSubmitted[i] and DWPlus_DB.BidsSubmitted[i].player == name and DWPlus_DB.BidsSubmitted[i].bid < cmd then
									table.remove(DWPlus_DB.BidsSubmitted, i)
								elseif (mode ~= "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType ~= "Static") and DWPlus_DB.BidsSubmitted[i] and DWPlus_DB.BidsSubmitted[i].player == name and DWPlus_DB.BidsSubmitted[i].bid >= cmd then
									SendChatMessage(L["BIDEQUALORLESS"], "WHISPER", nil, name)
									return
								end
							end
							if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
								if DWPlus_DB.modes.AnnounceBid and ((DWPlus_DB.BidsSubmitted[1] and DWPlus_DB.BidsSubmitted[1].bid < cmd) or not DWPlus_DB.BidsSubmitted[1]) then
									if not DWPlus_DB.modes.AnnounceBidName then
										SendChatMessage(L["NEWHIGHBID"].." "..cmd.." DKP", "RAID")
									else
										SendChatMessage(L["NEWHIGHBIDDER"].." "..name.." ("..cmd.." DKP)", "RAID")
									end
								end
								if DWPlus_DB.modes.DeclineLowerBids and DWPlus_DB.BidsSubmitted[1] and cmd <= DWPlus_DB.BidsSubmitted[1].bid then 	-- declines bids lower than highest bid
									response = "Bid Declined! Current highest bid is "..DWPlus_DB.BidsSubmitted[1].bid;
								else
									table.insert(DWPlus_DB.BidsSubmitted, {player=name, bid=cmd})
									response = L["YOURBIDOF"].." "..cmd.." "..L["DKPWASACCEPTED"].."."
								end
								if DWPlus_DB.modes.BroadcastBids then
									DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
								end
								if Timer ~= 0 and Timer > (core.BiddingWindow.bidTimer:GetText() - 10) and DWPlus_DB.modes.AntiSnipe > 0 then
									DWP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText().."{"..DWPlus_DB.modes.AntiSnipe, core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), core.BiddingWindow.itemIcon:GetTexture());
								end
							elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
								if DWPlus_DB.modes.AnnounceBid and ((DWPlus_DB.BidsSubmitted[1] and DWPlus_DB.BidsSubmitted[1].dkp < dkp) or not DWPlus_DB.BidsSubmitted[1]) then
									if not DWPlus_DB.modes.AnnounceBidName then
										SendChatMessage(L["NEWHIGHBID"].." "..dkp.." DKP", "RAID")
									else
										SendChatMessage(L["NEWHIGHBIDDER"].." "..name.." ("..dkp.." DKP)", "RAID")
									end
								end
								table.insert(DWPlus_DB.BidsSubmitted, {player=name, dkp=dkp})
								if DWPlus_DB.modes.BroadcastBids then
									DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
								end
								response = L["BIDWASACCEPTED"]
								if Timer ~= 0 and Timer > (core.BiddingWindow.bidTimer:GetText() - 10) and DWPlus_DB.modes.AntiSnipe > 0 then
									DWP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText().."{"..DWPlus_DB.modes.AntiSnipe, core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), core.BiddingWindow.itemIcon:GetTexture());
								end
							end
								
							BidScrollFrame_Update()
						else
							response = L["BIDDENIEDMINBID"].." "..core.BiddingWindow.minBid:GetNumber().."!"
						end
					elseif DWPlus_DB.modes.SubZeroBidding == true and dkp < 0 then
						response = L["BIDDENIEDNEGATIVE"].." ("..dkp.." "..L["DKP"]..")."
					else
						response = L["BIDDENIEDONLYHAVE"].." "..dkp.." "..L["DKP"]
					end
				end
			elseif not cmd and (mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid")) then
				response = L["BIDDENIEDNOVALUE"]
			elseif cmd ~= "cancel" and (tonumber(cmd) and tonumber(cmd) > DWPlus_DB.modes.MaximumBid) then
				response = L["BIDDENIEDEXCEEDMAX"].." "..DWPlus_DB.modes.MaximumBid.." "..L["DKP"].."."
			else
				if cmd ~= "cancel" then
					response = L["BIDDENIEDINVALID"]
				end
			end
			SendChatMessage(response, "WHISPER", nil, name)
		else
			SendChatMessage(L["NOBIDINPROGRESS"], "WHISPER", nil, name)
		end	
	elseif string.find(text, "!rp") == 1 and core.IsOfficer == true then
		cmd = tostring(BidCmd(text))

		if cmd and cmd:gsub("%d+", "") == "" then
			return DWP_CHAT_MSG_WHISPER("!bid "..cmd, name)
		elseif cmd and cmd:gsub("%s+", "") ~= "nil" and cmd:gsub("%s+", "") ~= "" then		-- allows command if it has content (removes empty spaces)
			cmd = cmd:gsub("%s+", "") -- removes unintended spaces from string
			local search = DWP:Table_Search(DWPlus_RPTable, cmd, "player")

			if search then
				response = "DWPlus: "..DWPlus_RPTable[search[1][1]].player.." "..L["CURRENTLYHAS"].." "..DWPlus_RPTable[search[1][1]].dkp.." "..L["DKPAVAILABLE"].."."
			else
				response = "DWPlus: "..L["PLAYERNOTFOUND"]
			end
		else
			local search = DWP:Table_Search(DWPlus_RPTable, name)
			local minimum;
			local maximum;
			local range = "";
			local perc = "";

			if DWPlus_DB.modes.mode == "Roll Based Bidding" and search then
				if DWPlus_DB.modes.rolls.UsePerc then
					if DWPlus_DB.modes.rolls.min == 0 then
            			minimum = 1;
            		else
            			minimum = DWPlus_RPTable[search[1][1]].dkp * (DWPlus_DB.modes.rolls.min / 100);
            		end
	        		
	        		perc = " ("..DWPlus_DB.modes.rolls.min.."% - "..DWPlus_DB.modes.rolls.max.."%)";
	        		maximum = DWPlus_RPTable[search[1][1]].dkp * (DWPlus_DB.modes.rolls.max / 100) + DWPlus_DB.modes.rolls.AddToMax;
	        	elseif not DWPlus_DB.modes.rolls.UsePerc then
	        		minimum = DWPlus_DB.modes.rolls.min;

	        		if DWPlus_DB.modes.rolls.max == 0 then
	        			maximum = DWPlus_RPTable[search[1][1]].dkp + DWPlus_DB.modes.rolls.AddToMax;
	        		else
	        			maximum = DWPlus_DB.modes.rolls.max + DWPlus_DB.modes.rolls.AddToMax;
	        		end
	        		if maximum < 0 then maximum = 0 end
          			if minimum < 0 then minimum = 0 end
	        	end
	        	range = range.." "..L["USE"].." /random "..DWP_round(minimum, 0).."-"..DWP_round(maximum, 0).." "..L["TOBID"].." "..perc..".";
	        end

			if search then
				response = "DWPlus: "..L["YOUCURRENTLYHAVE"].." "..DWPlus_RPTable[search[1][1]].dkp.." "..L["DKP"].."."..range;
			else
				response = "DWPlus: "..L["PLAYERNOTFOUND"]
			end
		end

		SendChatMessage(response, "WHISPER", nil, name)
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)			-- suppresses outgoing whisper responses to limit spam
		if core.BidInProgress and DWPlus_DB.defaults.SupressTells then
			if strfind(msg, L["YOURBIDOF"]) == 1 then
				return true
			elseif strfind(msg, L["BIDDENIEDFILTER"]) == 1 then
				return true
			elseif strfind(msg, L["BIDACCEPTEDFILTER"]) == 1 then
				return true;
			elseif strfind(msg, L["NOTSUBMITTEDBID"]) == 1 then
				return true;
			elseif strfind(msg, L["ONLYONEROLLWARN"]) == 1 then
				return true;
			elseif strfind(msg, L["ROLLNOTACCEPTED"]) == 1 then
				return true;
			elseif strfind(msg, L["YOURBID"].." "..L["MANUALLYDENIED"]) == 1 then
				return true;
			elseif strfind(msg, L["CANTCANCELROLL"]) == 1 then
				return true;
			end
		end

		if strfind(msg, "DWPlus: ") == 1 then
			return true
		elseif strfind(msg, L["NOBIDINPROGRESS"]) == 1 then
			return true
		elseif strfind(msg, L["BIDCANCELLED"]) == 1 then
			return true
		end
	end)

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg, ...)			-- suppresses incoming whisper responses to limit spam
		if core.BidInProgress and DWPlus_DB.defaults.SupressTells then
			if strfind(msg, "!bid") == 1 then
				return true
			end
		end
		
		if strfind(msg, "!rp") == 1 and DWPlus_DB.defaults.SupressTells then
			return true
		end
	end)
end

function DWP:GetMinBid(itemLink)
	local _,_,_,_,_,_,_,_,loc = GetItemInfo(itemLink);

	if loc == "INVTYPE_HEAD" then
		return DWPlus_DB.MinBidBySlot.Head
	elseif loc == "INVTYPE_NECK" then
		return DWPlus_DB.MinBidBySlot.Neck
	elseif loc == "INVTYPE_SHOULDER" then
		return DWPlus_DB.MinBidBySlot.Shoulders
	elseif loc == "INVTYPE_CLOAK" then
		return DWPlus_DB.MinBidBySlot.Cloak
	elseif loc == "INVTYPE_CHEST" or loc == "INVTYPE_ROBE" then
		return DWPlus_DB.MinBidBySlot.Chest
	elseif loc == "INVTYPE_WRIST" then
		return DWPlus_DB.MinBidBySlot.Bracers
	elseif loc == "INVTYPE_HAND" then
		return DWPlus_DB.MinBidBySlot.Hands
	elseif loc == "INVTYPE_WAIST" then
		return DWPlus_DB.MinBidBySlot.Belt
	elseif loc == "INVTYPE_LEGS" then
		return DWPlus_DB.MinBidBySlot.Legs
	elseif loc == "INVTYPE_FEET" then
		return DWPlus_DB.MinBidBySlot.Boots
	elseif loc == "INVTYPE_FINGER" then
		return DWPlus_DB.MinBidBySlot.Ring
	elseif loc == "INVTYPE_TRINKET" then
		return DWPlus_DB.MinBidBySlot.Trinket
	elseif loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONMAINHAND" or loc == "INVTYPE_WEAPONOFFHAND" then
		return DWPlus_DB.MinBidBySlot.OneHanded
	elseif loc == "INVTYPE_2HWEAPON" then
		return DWPlus_DB.MinBidBySlot.TwoHanded
	elseif loc == "INVTYPE_HOLDABLE" or loc == "INVTYPE_SHIELD" then
		return DWPlus_DB.MinBidBySlot.OffHand
	elseif loc == "INVTYPE_RANGED" or loc == "INVTYPE_THROWN" or loc == "INVTYPE_RANGEDRIGHT" or loc == "INVTYPE_RELIC" then
		return DWPlus_DB.MinBidBySlot.Range
	else
		return DWPlus_DB.MinBidBySlot.Other
	end
end

local function createSelectBidItemRow(parent, index)
	local f = CreateFrame("Button", "$parent"..index, parent);
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, (index - 1) * -30);
	f:SetSize(335, 32);
	f:SetHighlightTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");

	f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);
	f.itemIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -2);
	f.itemIcon:SetColorTexture(0, 0, 0, 1)
	f.itemIcon:SetSize(28, 28);

	f.ItemIconButton = CreateFrame("Button", "DWPBiddingItemTooltipButtonButton", f)
	f.ItemIconButton:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 0, 0);
	f.ItemIconButton:SetSize(28, 28);

	f.itemText = f:CreateFontString(nil, "OVERLAY")
	f.itemText:SetFontObject("DWPNormalLeft");
	f.itemText:SetPoint("LEFT", f.itemIcon, "RIGHT", 5, 2);
	f.itemText:SetSize(300, 28)

	f.ItemTooltipButton = CreateFrame("Button", "DWPBiddingItemTooltipButtonButton", f)
	f.ItemTooltipButton:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 0, 0);

	return f;
end

local function UpdateSelectBidWindow()
	if not core.SelectBidWindow then
		return;
	end

	for _, item in pairs(core.SelectBidWindow.items) do
		item:Hide();
	end

	local items = core.SelectBidWindow.items or {};

	local index = 0;

	for boss, biddingBossItems in pairs(DWPlus_DB.BiddingItems) do
		index = index + 1;
		if not items[index] then
			items[index] = createSelectBidItemRow(core.SelectBidWindow.scrollFrame, index);
		end
		items[index]:Show();

		items[index].itemText:SetText(boss..":");
		items[index].itemText:SetTextColor(0.8, 0.65, 0);
		items[index].itemText:SetScale(1.2);
		items[index].itemIcon:Hide();
		items[index]:SetScript("OnMouseDown", nil);
		items[index]:SetHighlightTexture(nil);

		for _, itemLink in ipairs(biddingBossItems) do
			local item = Item:CreateFromItemLink(itemLink);
			item:ContinueOnItemLoad(function()
				index = index + 1;
				if not items[index] then
					items[index] = createSelectBidItemRow(core.SelectBidWindow.scrollFrame, index);
				end
				items[index].itemText:SetText(itemLink);
				items[index].itemText:SetTextColor(1, 1, 1);
				items[index].itemText:SetScale(1);
				items[index].itemIcon:SetTexture(item:GetItemIcon());
				items[index].itemIcon:Show();
				items[index]:SetHighlightTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");

				items[index].boss = boss;
				items[index].itemLink = itemLink;
				items[index]:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
					GameTooltip:SetHyperlink(self.itemLink)
				end)
				items[index]:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
				items[index]:SetScript("OnMouseDown", function(self, button)
					if button == "RightButton" then
						StaticPopupDialogs["REMOVE_BIDDING_ITEM"] = {
							text = "|CFFFF0000"..L["WARNING"].."|r: "..L["CONFIRMREMOVESELECT"].."\n"..self.boss..": "..self.itemLink.."?",
							button1 = L["YES"],
							button2 = L["NO"],
							OnAccept = function()
								DWP:BidTable_Remove(self.itemLink, self.boss)
							end,
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3,
						}
						StaticPopup_Show ("REMOVE_BIDDING_ITEM")
					else
						local clickItem = Item:CreateFromItemLink(self.itemLink);
						clickItem:ContinueOnItemLoad(function()
							core.SelectBidWindow:Hide();
							core.BiddingBoss = self.boss;
							if self.boss ~= BAGSLOT then
								DWP:ToggleBidWindow(clickItem:GetItemLink(), clickItem:GetItemIcon(), clickItem:GetItemName(), self.boss);
							else
								DWP:ToggleBidWindow(clickItem:GetItemLink(), clickItem:GetItemIcon(), clickItem:GetItemName());
							end
						end);
					end;
				end)
				items[index]:Show();
			end)
		end
	end;

	core.SelectBidWindow.items = items;
end

local function ClearSelectBidWindow()
	StaticPopupDialogs["CONFIRM_DELETE_SELECT_BID"] = {
		text = L["CONFIRMBIDDINGCLEAAR"],
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()
			DWPlus_DB.BiddingItems = {};
			UpdateSelectBidWindow();
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show ("CONFIRM_DELETE_SELECT_BID")
end

local function AddBidItemsFromBags()
	local items = {};
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot);
			if itemLink then
				local item = Item:CreateFromItemLink(itemLink);
				item:ContinueOnItemLoad(function()
					if item:GetItemQuality() >= 3 and not(DWP:IsSoulbound(bag, slot)) then
						table.insert(items, itemLink);
					end
				end)
			end
		end
	end
	DWP:BidTable_Set(BAGSLOT, items)
end

local function CreateSelectBidWindow()
	local f = CreateFrame("Frame", "DWP_SelectBiddingWindow", UIParent, "ShadowOverlaySmallTemplate");
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(400, 500);
	f:SetClampedToScreen(true)
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing();
		local point, relativeTo, relativePoint ,xOff,yOff = f:GetPoint(1)
		if not DWPlus_DB.selectbidpos then
			DWPlus_DB.selectbidpos = {}
		end
		DWPlus_DB.selectbidpos.point = point;
		DWPlus_DB.selectbidpos.relativeTo = relativeTo;
		DWPlus_DB.selectbidpos.relativePoint = relativePoint;
		DWPlus_DB.selectbidpos.x = xOff;
		DWPlus_DB.selectbidpos.y = yOff;
	end);
	f:SetScript("OnHide", function ()
		if core.BidInProgress then
			DWP:Print(L["CLOSEDBIDINPROGRESS"])
		end
	end)
	f:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if DWP.UIConfig then DWP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	if DWPlus_DB.selectbidpos then
		f:ClearAllPoints()
		local coords = DWPlus_DB.selectbidpos
		f:SetPoint(coords.point, coords.relativeTo, coords.relativePoint, coords.x, coords.y)
	end

	-- Close Button
	f.closeContainer = CreateFrame("Frame", "DWPSelectBidClose", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)

	f.inst = f:CreateFontString(nil, "OVERLAY")
	f.inst:ClearAllPoints();
	f.inst:SetFontObject("DWPSmallRight");
	f.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	f.inst:SetPoint("TOPRIGHT", f, "TOPRIGHT", -40, -43);
	f.inst:SetText(L["LMBREMOVE"]);

	f.header = f:CreateFontString(nil, "OVERLAY")
	f.header:SetFontObject("DWPLargeCenter");
	f.header:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -10);
	f.header:SetText(L["SELECTBID"]);

	f.scrollFrame = CreateFrame("Frame");

	f.scroll = CreateFrame("ScrollFrame", "DWPSelectBidScrollFrame", f, "UIPanelScrollFrameTemplate")
	f.scroll:ClearAllPoints(f)
	f.scroll:SetPoint("LEFT", 20, 0)
	f.scroll:SetPoint("RIGHT", -32, 0)
	f.scroll:SetPoint("TOP", 0, -50)
	f.scroll:SetPoint("BOTTOM", 0, 60)
	f.scroll:SetScrollChild(f.scrollFrame);

	f.scrollFrame:SetSize(f.scroll:GetWidth(), f.scroll:GetHeight())

	f.ClearSelectBidWindow = DWP:CreateButton("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 10, L["CLEARBIDWINDOW"]);
	f.ClearSelectBidWindow:SetSize(90, 25)
	f.ClearSelectBidWindow:SetScript("OnClick", ClearSelectBidWindow)

	f.AddItemsFromBag = DWP:CreateButton("TOPLEFT", f.ClearSelectBidWindow, "TOPRIGHT", 15, 0, L["ADDITEMSTOBIDWINDOW"]);
	f.AddItemsFromBag:SetSize(150, 25)
	f.AddItemsFromBag:SetScript("OnClick", AddBidItemsFromBags)

	f.AddItemsFromBag:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDITEMSTOBIDWINDOW"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDITEMSTOBIDWINDOWDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	f.AddItemsFromBag:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	f.items = {};

	return f;
end

function DWP:ToggleSelectBidWindow()
	if core.IsOfficer then
		if not core.SelectBidWindow then
			core.SelectBidWindow = CreateSelectBidWindow();
		end
		UpdateSelectBidWindow();
		core.SelectBidWindow:Show();
	else
		DWP:Print(L["NOPERMISSION"])
	end
end

function DWP:BidTable_Set(boss, list)
	if table.getn(list) > 0 then
		DWPlus_DB.BiddingItems[boss] = list;
		UpdateSelectBidWindow();
	end
end

function DWP:BidTable_Remove(item, boss)
	local bossRemovable = boss or core.BiddingBoss;
	if not DWPlus_DB.BiddingItems[bossRemovable] then
		return;
	end;

	for index, biddingItem in pairs(DWPlus_DB.BiddingItems[bossRemovable]) do
		if item == biddingItem then
			table.remove(DWPlus_DB.BiddingItems[bossRemovable], index)

			if table.getn(DWPlus_DB.BiddingItems[bossRemovable]) == 0 then
				DWPlus_DB.BiddingItems[bossRemovable] = nil
			end;

			UpdateSelectBidWindow();
			return;
		end
	end
	UpdateSelectBidWindow();
end

function DWP:ToggleBidWindow(loot, lootIcon, itemName, bossName)
	if core.IsOfficer then
		local minBid;
		mode = DWPlus_DB.modes.mode;

		core.BiddingWindow = core.BiddingWindow or DWP:CreateBidWindow();

	 	if DWPlus_DB.bidpos then
	 		core.BiddingWindow:ClearAllPoints()
			local a = DWPlus_DB.bidpos
			core.BiddingWindow:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
		end

		core.BiddingWindow:SetShown(true)
	 	core.BiddingWindow:SetFrameLevel(10)
		
	 	if DWPlus_DB.modes.mode == "Zero Sum" then
		 	core.ZeroSumBank = core.ZeroSumBank or DWP:ZeroSumBank_Create()
		 	core.ZeroSumBank:SetShown(true)
		 	core.ZeroSumBank:SetFrameLevel(10)

		 	DWP:ZeroSumBank_Update();
		end

		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if DWP.UIConfig then DWP.UIConfig:SetFrameLevel(2) end

	 	if loot then
	 		DWPlus_DB.BidsSubmitted = {}
	 		if DWPlus_DB.modes.BroadcastBids then
				DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
			end
	 		local search = DWP:Table_Search(DWPlus_MinBids, itemName)

			DWPlus_DB.BidParams.CurrItemForBid = loot;
			DWPlus_DB.BidParams.CurrItemIcon = lootIcon
	 		CurZone = GetRealZoneText()
	 		
	 		if search then
	 			minBid = DWPlus_MinBids[search[1][1]].minbid
		 		
		 		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
		 			core.BiddingWindow.CustomMinBid:Show();
		 			core.BiddingWindow.CustomMinBid:SetChecked(true)
		 			core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
		 				if self:GetChecked() == true then
		 					core.BiddingWindow.minBid:SetText(DWP_round(minBid, DWPlus_DB.modes.rounding))
		 				else
		 					core.BiddingWindow.minBid:SetText(DWP:GetMinBid(DWPlus_DB.BidParams.CurrItemForBid))
		 				end
		 			end)
		 		elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
		 			core.BiddingWindow.CustomMinBid:Show();
		 			core.BiddingWindow.CustomMinBid:SetChecked(true)
		 			core.BiddingWindow.CustomMinBid:SetScript("OnClick", function(self)
		 				if self:GetChecked() == true then
		 					core.BiddingWindow.cost:SetText(DWP_round(minBid, DWPlus_DB.modes.rounding))
		 				else
		 					core.BiddingWindow.cost:SetText(DWP:GetMinBid(DWPlus_DB.BidParams.CurrItemForBid))
		 				end
		 			end)
		 		end
	 		else
	 			minBid = DWP:GetMinBid(DWPlus_DB.BidParams.CurrItemForBid)
	 			core.BiddingWindow.CustomMinBid:Hide();
	 		end
	 		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
 				core.BiddingWindow.minBid:SetText(DWP_round(minBid, DWPlus_DB.modes.rounding))
 			end

	 		core.BiddingWindow.cost:SetText(DWP_round(minBid, DWPlus_DB.modes.rounding))
	 		core.BiddingWindow.itemName:SetText(itemName)
	 		core.BiddingWindow.bidTimer:SetText(DWPlus_DB.DKPBonus.BidTimer)
	 		core.BiddingWindow.boss:SetText(bossName or core.LastKilledBoss)
	 		UpdateBidWindow()
	 		core.BiddingWindow.ItemTooltipButton:SetSize(core.BiddingWindow.itemIcon:GetWidth() + core.BiddingWindow.item:GetStringWidth() + 10, core.BiddingWindow.item:GetHeight());
	 		core.BiddingWindow.ItemTooltipButton:SetScript("OnEnter", function(self)
	 			ActionButton_ShowOverlayGlow(core.BiddingWindow.ItemIconButton)
				GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
				GameTooltip:SetHyperlink(DWPlus_DB.BidParams.CurrItemForBid)
			end)
			core.BiddingWindow.ItemTooltipButton:SetScript("OnLeave", function(self)
				ActionButton_HideOverlayGlow(core.BiddingWindow.ItemIconButton)
				GameTooltip:Hide()
			end)
	 	else
	 		UpdateBidWindow()
	 	end

	 	BidScrollFrame_Update()
	else
		DWP:Print(L["NOPERMISSION"])
	end
end

local function StartBidding()
	local perc;
	mode = DWPlus_DB.modes.mode;
	core.BidInProgress = true;

	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BiddingWindow.cost:SetNumber(DWP_round(core.BiddingWindow.minBid:GetNumber(), DWPlus_DB.modes.rounding))
		DWP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Min Bid: "..core.BiddingWindow.minBid:GetText(), DWPlus_DB.BidParams.CurrItemIcon)
		DWP.Sync:SendData("DWPCommand", "BidInfo,"..core.BiddingWindow.item:GetText()..","..core.BiddingWindow.minBid:GetText()..","..DWPlus_DB.BidParams.CurrItemIcon..","..core.BiddingWindow.boss:GetText())
		DWP:CurrItem_Set(core.BiddingWindow.item:GetText(), core.BiddingWindow.minBid:GetText(), DWPlus_DB.BidParams.CurrItemIcon, core.BiddingWindow.boss:GetText())

		if DWPlus_DB.defaults.AutoOpenBid then	-- toggles bid window if option is set to
			DWP:BidInterface_Toggle()
		end

		local search = DWP:Table_Search(DWPlus_MinBids, core.BiddingWindow.itemName:GetText())
		local val = DWP:GetMinBid(DWPlus_DB.BidParams.CurrItemForBid);
		
		if not search and core.BiddingWindow.minBid:GetNumber() ~= tonumber(val) then
			tinsert(DWPlus_MinBids, {item=core.BiddingWindow.itemName:GetText(), minbid=core.BiddingWindow.minBid:GetNumber()})
			core.BiddingWindow.CustomMinBid:SetShown(true);
		 	core.BiddingWindow.CustomMinBid:SetChecked(true);
		elseif search and core.BiddingWindow.minBid:GetNumber() ~= tonumber(val) and core.BiddingWindow.CustomMinBid:GetChecked() == true then
			if DWPlus_MinBids[search[1][1]].minbid ~= core.BiddingWindow.minBid:GetNumber() then
				DWPlus_MinBids[search[1][1]].minbid = core.BiddingWindow.minBid:GetNumber();
				core.BiddingWindow.CustomMinBid:SetShown(true);
		 		core.BiddingWindow.CustomMinBid:SetChecked(true);
			end
		end

		if search and core.BiddingWindow.CustomMinBid:GetChecked() == false then
			table.remove(DWPlus_MinBids, search[1][1])
			core.BiddingWindow.CustomMinBid:SetShown(false);
		end
	else
		if DWPlus_DB.modes.costvalue == "Percent" then perc = "%" else perc = " RP" end;
		DWP:BroadcastBidTimer(core.BiddingWindow.bidTimer:GetText(), core.BiddingWindow.item:GetText().." Cost: "..core.BiddingWindow.cost:GetNumber()..perc, DWPlus_DB.BidParams.CurrItemIcon)
		DWP.Sync:SendData("DWPCommand", "BidInfo,"..core.BiddingWindow.item:GetText()..","..core.BiddingWindow.cost:GetText()..perc..","..DWPlus_DB.BidParams.CurrItemIcon..","..core.BiddingWindow.boss:GetText())
		DWP:BidInterface_Toggle()
		DWP:CurrItem_Set(core.BiddingWindow.item:GetText(), core.BiddingWindow.cost:GetText()..perc, DWPlus_DB.BidParams.CurrItemIcon, core.BiddingWindow.boss:GetText())
	end

	if mode == "Roll Based Bidding" then
		events:RegisterEvent("CHAT_MSG_SYSTEM")
		events:SetScript("OnEvent", Roll_OnEvent);
	end
	
	if DWPlus_DB.BidParams.CurrItemForBid then
		local channels = {};
		local channelText = "";

		if DWPlus_DB.modes.channels.raid then table.insert(channels, "/raid") end
		if DWPlus_DB.modes.channels.guild then table.insert(channels, "/guild") end
		if DWPlus_DB.modes.channels.whisper then table.insert(channels, "/whisper") end

		for i=1, #channels do
			if #channels == 1 then
				channelText = channels[i]
			else
				if i == 1 then
					channelText = channels[i];
				elseif i == #channels then
					channelText = channelText.." "..L["OR"].." "..channels[i]
				else
					channelText = channelText..", "..channels[i]
				end
			end
		end

		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			DWP:SendToRWorRaidChat(L["TAKINGBIDSON"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.minBid:GetText().." "..L["DKPMINBID"]..")")
			DWP:SendToRWorRaidChat(L["TOBIDUSE"].." "..channelText.." "..L["TOSEND"].." !bid <"..L["VALUE"].."> (ex: !bid "..core.BiddingWindow.minBid:GetText().."). "..L["OR"].." !bid cancel "..L["TOWITHDRAWBID"])
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
			DWP:SendToRWorRaidChat(L["TAKINGBIDSON"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")")
			DWP:SendToRWorRaidChat(L["TOBIDUSE"].." "..channelText.." "..L["TOSEND"].." !bid. "..L["OR"].." !bid cancel "..L["TOWITHDRAWBID"])
		elseif mode == "Roll Based Bidding" then
			DWP:SendToRWorRaidChat(L["STARTROLL"])
			DWP:SendToRWorRaidChat(L["ROLLFOR"].." "..core.BiddingWindow.item:GetText().." ("..core.BiddingWindow.cost:GetText()..perc..")")
		end
	end
end

local function ToggleTimerBtn(self)
	mode = DWPlus_DB.modes.mode;

	if timerToggle == 0 then
		--if not IsInRaid() then DWP:Print("You are not in a raid.") return false end
		if (mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.minBid:GetText() == "") then DWP:Print(L["NOMINBIDORITEM"]) return false end
		if (mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static")) and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then DWP:Print(L["NOITEMORITEMCOST"]) return false end
		if mode == "Roll Based Bidding" and (not core.BiddingWindow.item:GetText() or core.BiddingWindow.cost:GetText() == "") then DWP:Print(L["NOITEMORITEMCOST"]) return false end

		timerToggle = 1;
		self:SetText(L["ENDBIDDING"])
		StartBidding()
	else
		timerToggle = 0;
		core.BidInProgress = false;
		self:SetText(L["STARTBIDDING"])
		DWP:SendToRWorRaidChat(L["BIDDINGCLOSED"])
		events:UnregisterEvent("CHAT_MSG_SYSTEM")
		DWP:BroadcastStopBidTimer()
		DWP:ClearBidInterface();
	end
end

function ClearBidWindow()
	DWP:BidsSubmitted_Clear();
	SelectedBidder = {}
	if DWPlus_DB.modes.BroadcastBids then
		DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
	end
	core.BiddingWindow.CustomMinBid:Hide();
	core.BiddingWindow.ItemTooltipButton:SetSize(0,0)
	BidScrollFrame_Update()
	UpdateBidWindow()
	core.BidInProgress = false;
	_G["DWPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
	_G["DWPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
		local pass, err = pcall(ToggleTimerBtn, self)

		if core.BiddingWindow.bidTimer then core.BiddingWindow.bidTimer:ClearFocus(); end
		if core.BiddingWindow.minBid then core.BiddingWindow.minBid:ClearFocus(); end

		if core.BiddingWindow.minBid then core.BiddingWindow.minBid:ClearFocus(); end
		core.BiddingWindow.bidTimer:ClearFocus()
		core.BiddingWindow.boss:ClearFocus()
		core.BiddingWindow.cost:ClearFocus()
		if not pass then
			core.BiddingWindow:SetShown(false)
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
	end)
	timerToggle = 0;
	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BiddingWindow.minBid:SetText("")
	end
	for i=1, numrows do
		core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
	end
end

function DWP:BroadcastBidTimer(seconds, title, itemIcon)       -- broadcasts timer and starts it natively
	local title = title;
	DWP.Sync:SendData("DWPCommand", "StartBidTimer,"..seconds..","..title..","..itemIcon)
	DWP:StartBidTimer(seconds, title, itemIcon, true)

	if strfind(seconds, "{") then
		DWP:Print("Bid timer extended by "..tonumber(strsub(seconds, strfind(seconds, "{")+1)).." seconds.")
	end
end

function DWP:BroadcastStopBidTimer()
	DWP.BidTimer:SetScript("OnUpdate", nil)
	DWP.BidTimer:Hide()
	DWP.Sync:SendData("DWPCommand", "StopBidTimer")
end

function DWP_Register_ShiftClickLootWindowHook()			-- hook function into LootFrame window. All slots on ElvUI. But only first 4 in default UI.
	local num = GetNumLootItems();
	
	if getglobal("ElvLootSlot1") then 			-- fixes hook for ElvUI loot frame
		for i = 1, num do
			local searchHook = DWP:Table_Search(hookedSlots, i)  -- blocks repeated hooking

			if not searchHook then
				getglobal("ElvLootSlot"..i):HookScript("OnClick", function()
			        if ( IsShiftKeyDown() and IsAltKeyDown() ) then
			        	local pass, err = pcall(function()
			        		lootIcon, itemName, _, _, _ = GetLootSlotInfo(i)
			        		itemLink = GetLootSlotLink(i)
				            DWP:ToggleBidWindow(itemLink, lootIcon, itemName)
			        	end)

						if not pass then
							DWP:Print(err)
							core.BiddingWindow:SetShown(false)
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
			        end
				end)
				table.insert(hookedSlots, i)
			end
		end
	else
		if num > 4 then num = 4 end

		for i = 1, num do
			local searchHook = DWP:Table_Search(hookedSlots, i)  -- blocks repeated hooking

			if not searchHook then
				getglobal("LootButton"..i):HookScript("OnClick", function()
			        if ( IsShiftKeyDown() and IsAltKeyDown() ) then
			        	local pass, err = pcall(function()
			        		lootIcon, itemName, _, _, _ = GetLootSlotInfo(i)
			        		itemLink = GetLootSlotLink(i)
				            DWP:ToggleBidWindow(itemLink, lootIcon, itemName)
			        	end)

						if not pass then
							core.BiddingWindow:SetShown(false)
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
			        end
				end)
				table.insert(hookedSlots, i)
			end
		end
	end
end

function DWP:StartBidTimer(seconds, title, itemIcon, sendToChat)
	local duration, timer, timerText, modulo, timerMinute, expiring;
	local title = title;
	local alpha = 1;
	local messageSent = { false, false, false, false, false, false }
	local audioPlayed = false;
	local extend = false;

	if tonumber(seconds) then
		timer = 0
		duration = tonumber(seconds);
	else
		if seconds ~= "seconds" then
			timer = Timer - tonumber(strsub(seconds, strfind(seconds, "{")+1))
			duration = tonumber(strsub(seconds, 1, strfind(seconds, "{")-1))  				--strsub("30{10", strfind("30{10", "{")+1)
			extend = true;
		end
	end

	DWP.BidTimer = DWP.BidTimer or DWP:CreateTimer();		-- recycles bid timer frame so multiple instances aren't created
	if not extend then DWP.BidTimer:SetShown(not DWP.BidTimer:IsShown()); end					-- shows if not shown
	if core.BidInterface and core.BidInterface:IsShown() == false then DWP.BidTimer.OpenBid:Show() end
	DWP.BidTimer:SetMinMaxValues(0, duration or 20)
	DWP.BidTimer.timerTitle:SetText(title)
	DWP.BidTimer.itemIcon:SetTexture(itemIcon)
    DWP.BidTimer:SetAlpha(1);
    DWP.BidTimer:SetScale(DWPlus_DB.defaults.BidTimerSize);
	DWP.BidTimer:SetScript("OnMouseDown", function(self, button)
      if button == "RightButton" then
        DWP.BidTimer:SetAlpha(0);
        DWP.BidTimer:SetScale(0.1);
      end
    end)
	PlaySound(8959)

	if DWPlus_DB.timerpos then
		local a = DWPlus_DB["timerpos"]										-- retrieves timer's saved position from SavedVariables
		DWP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	else
		DWP.BidTimer:SetPoint("CENTER")											-- sets to center if no position has been saved
	end
	
	DWP.BidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		Timer = timer; 			-- stores external copy of timer for extending
		timerText = DWP_round(duration - timer, 1)
		if tonumber(timerText) > 60 then
			timerMinute = math.floor(tonumber(timerText) / 60, 0);
			modulo = bit.mod(tonumber(timerText), 60);
			if tonumber(modulo) < 10 then modulo = "0"..modulo end
			DWP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
		else
			DWP.BidTimer.timertext:SetText(timerText)
		end
		if duration >= 120 then
			expiring = 30;
		else
			expiring = 10;
		end
		if tonumber(timerText) < expiring then
			DWP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
			if alpha > 0 then
				alpha = alpha - 0.005
			elseif alpha <= 0 then
				alpha = 1
			end
		else
			DWP.BidTimer:SetStatusBarColor(0, 0.8, 0)
		end

		if sendToChat then
			if tonumber(timerText) == 10 and messageSent[1] == false then
				if audioPlayed == false then
					PlaySound(23639);
				end
				DWP:SendToRWorRaidChat(L["TENSECONDSTOBID"])
				messageSent[1] = true;
			end
			if tonumber(timerText) == 3 and messageSent[2] == false then
				DWP:SendToRWorRaidChat("3")
				messageSent[2] = true;
			end
			if tonumber(timerText) == 2 and messageSent[3] == false then
				DWP:SendToRWorRaidChat("2")
				messageSent[3] = true;
			end
			if tonumber(timerText) == 1 and messageSent[4] == false then
				DWP:SendToRWorRaidChat("1")
				messageSent[4] = true;
			end
		end
		self:SetValue(timer)
		if timer >= duration then
			if DWPlus_DB.BidParams.CurrItemForBid and core.BidInProgress then
				DWP:SendToRWorRaidChat(L["BIDDINGCLOSED"])
				events:UnregisterEvent("CHAT_MSG_SYSTEM")
			end
			core.BidInProgress = false;
			if _G["DWPBiddingStartBiddingButton"] then
				_G["DWPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
				_G["DWPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
					local pass, err = pcall(ToggleTimerBtn, self)
					
					if core.BiddingWindow.minBid then core.BiddingWindow.minBid:ClearFocus(); end
					core.BiddingWindow.bidTimer:ClearFocus()
					core.BiddingWindow.boss:ClearFocus()
					core.BiddingWindow.cost:ClearFocus()
					if not pass then
						core.BiddingWindow:SetShown(false)
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
				end)
				timerToggle = 0;
			end
			core.BiddingInProgress = false;
			DWP.BidTimer:SetScript("OnUpdate", nil)
			DWP.BidTimer:Hide();
			if #core.BidInterface.LootTableButtons > 0 then
				for i=1, #core.BidInterface.LootTableButtons do
					ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
				end
			end
			C_Timer.After(2, function()
				if core.BidInterface and core.BidInterface:IsShown() then
					core.BidInterface:Hide()
				end
			end)
		end
	end)
end

function DWP:CreateTimer()

	local f = CreateFrame("StatusBar", nil, UIParent)
	f:SetSize(300, 25)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(18)
	f:SetBackdrop({
	    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground", tile = true,
	  });
	f:SetBackdropColor(0, 0, 0, 0.7)
	f:SetStatusBarTexture([[Interface\TargetingFrame\UI-TargetingFrame-BarFill]])
	f:SetMovable(true);
	f:EnableMouse(true);
	f:SetScale(DWPlus_DB.defaults.BidTimerSize)
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing();
		local point, _, relativePoint ,xOff,yOff = f:GetPoint(1)
		if not DWPlus_DB.timerpos then
			DWPlus_DB.timerpos = {}
		end
		DWPlus_DB.timerpos["point"] = point;
		DWPlus_DB.timerpos["relativePoint"] = relativePoint;
		DWPlus_DB.timerpos["x"] = xOff;
		DWPlus_DB.timerpos["y"] = yOff;
	end);

	f.border = CreateFrame("Frame", nil, f);
	f.border:SetPoint("CENTER", f, "CENTER");
	f.border:SetFrameStrata("DIALOG")
	f.border:SetFrameLevel(19)
	f.border:SetSize(300, 25);
	f.border:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.border:SetBackdropColor(0,0,0,0);
	f.border:SetBackdropBorderColor(1,1,1,1)

	f.timerTitle = f:CreateFontString(nil, "OVERLAY")
	f.timerTitle:SetFontObject("DWPNormalOutlineLeft")
	f.timerTitle:SetWidth(270)
	f.timerTitle:SetHeight(25)
	f.timerTitle:SetTextColor(1, 1, 1, 1);
	f.timerTitle:SetPoint("LEFT", f, "LEFT", 3, 0);
	f.timerTitle:SetText(nil);

	f.timertext = f:CreateFontString(nil, "OVERLAY")
	f.timertext:SetFontObject("DWPSmallOutlineRight")
	f.timertext:SetTextColor(1, 1, 1, 1);
	f.timertext:SetPoint("RIGHT", f, "RIGHT", -5, 0);
	f.timertext:SetText(nil);

	f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
	f.itemIcon:SetPoint("RIGHT", f, "LEFT", 0, 0);
	f.itemIcon:SetColorTexture(0, 0, 0, 1)
	f.itemIcon:SetSize(25, 25);

	f.OpenBid = CreateFrame("Button", nil, f, "DWPlusButtonTemplate")
	f.OpenBid:SetPoint("RIGHT", f.itemIcon, "LEFT", -5, 0);
	f.OpenBid:SetSize(40,25)
	f.OpenBid:SetText(L["BID"]);
	f.OpenBid:GetFontString():SetTextColor(1, 1, 1, 1)
	f.OpenBid:SetNormalFontObject("DWPSmallCenter");
	f.OpenBid:SetHighlightFontObject("DWPSmallCenter");
	f.OpenBid:SetScript("OnClick", function()
		f.OpenBid:Hide()
		DWP:BidInterface_Toggle()
	end)
	f.OpenBid:Show()

	return f;
end

local function BidRow_OnClick(self)
	if SelectedBidder.player == strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1) then
		for i=1, numrows do
			core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
			core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
		end
		SelectedBidder = {}
	else
		for i=1, numrows do
			core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
			core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
		end
	    self:SetNormalTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");
	    self:GetNormalTexture():SetAlpha(0.7)

	    if DWPlus_DB.modes.costvalue == "Percent" then
	    	SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1), dkp=tonumber(self.Strings[3]:GetText())}
	    else
	    	SelectedBidder = {player=strsub(self.Strings[1]:GetText(), 1, strfind(self.Strings[1]:GetText(), " ")-1), bid=tonumber(self.Strings[2]:GetText())}
	    end
    end
end

local function RightClickMenu(self)
	local menu;
  
	menu = {
		{ text = L["REMOVEENTRY"], notCheckable = true, func = function()
			if DWPlus_DB.BidsSubmitted[self.index].bid then
				SendChatMessage(L["YOURBIDOF"].." "..DWPlus_DB.BidsSubmitted[self.index].bid.." "..L["DKP"].." "..L["MANUALLYDENIED"], "WHISPER", nil, DWPlus_DB.BidsSubmitted[self.index].player)
			else
				SendChatMessage(L["YOURBID"].." "..L["MANUALLYDENIED"], "WHISPER", nil, DWPlus_DB.BidsSubmitted[self.index].player)
			end
			table.remove(DWPlus_DB.BidsSubmitted, self.index)
			if DWPlus_DB.modes.BroadcastBids then
				DWP.Sync:SendData("DWPBidShare", DWPlus_DB.BidsSubmitted)
			end
			SelectedBidder = {}
			for i=1, #core.BiddingWindow.bidTable.Rows do
				core.BiddingWindow.bidTable.Rows[i]:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
				core.BiddingWindow.bidTable.Rows[i]:GetNormalTexture():SetAlpha(0.2)
			end
			BidScrollFrame_Update()
		end },
	}
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 1);
end

local function BidWindowCreateRow(parent, id) -- Create 3 buttons for each row in the list
    local f = CreateFrame("Button", "$parentLine"..id, parent)
    f.Strings = {}
    f:SetSize(width, height)
    f:SetHighlightTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\ListBox-Highlight");
    f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
    f:GetNormalTexture():SetAlpha(0.2)
    f:SetScript("OnClick", BidRow_OnClick)
    for i=1, 3 do
        f.Strings[i] = f:CreateFontString(nil, "OVERLAY");
        f.Strings[i]:SetTextColor(1, 1, 1, 1);
        if i==1 then 
        	f.Strings[i]:SetFontObject("DWPNormalLeft");
        else
        	f.Strings[i]:SetFontObject("DWPNormalCenter");
        end
    end
    f.Strings[1].rowCounter = f:CreateFontString(nil, "OVERLAY");
	f.Strings[1].rowCounter:SetFontObject("DWPSmallOutlineLeft")
	f.Strings[1].rowCounter:SetTextColor(1, 1, 1, 0.3);
	f.Strings[1].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);

    f.Strings[1]:SetWidth((width/2)-10)
    f.Strings[2]:SetWidth(width/4)
    f.Strings[3]:SetWidth(width/4)
    f.Strings[1]:SetPoint("LEFT", f, "LEFT", 20, 0)
    f.Strings[2]:SetPoint("LEFT", f.Strings[1], "RIGHT", -9, 0)
    f.Strings[3]:SetPoint("RIGHT", 0, 0)

    f:SetScript("OnMouseDown", function(self, button)
      if button == "RightButton" then
        RightClickMenu(self)
      end
    end)

    return f
end

local function SortBidTable()             -- sorts the Loot History Table by date
	mode = DWPlus_DB.modes.mode;
	table.sort(DWPlus_DB.BidsSubmitted, function(a, b)
	    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
	    	return a["bid"] > b["bid"]
	    elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
	    	return a["dkp"] > b["dkp"]
	    elseif mode == "Roll Based Bidding" then
	    	return a["roll"] > b["roll"]
	    end
  	end)
end

function BidScrollFrame_Update()
	local numOptions = #DWPlus_DB.BidsSubmitted;
	local index, row
    local offset = FauxScrollFrame_GetOffset(core.BiddingWindow.bidTable) or 0
    local rank;
    local showRows = #DWPlus_DB.BidsSubmitted

    if #DWPlus_DB.BidsSubmitted > numrows then
    	showRows = numrows
    end

    SortBidTable()
    for i=1, numrows do
    	row = core.BiddingWindow.bidTable.Rows[i]
    	row:Hide()
    end
    for i=1, showRows do
        row = core.BiddingWindow.bidTable.Rows[i]
        index = offset + i
        local dkp_total = DWP:Table_Search(DWPlus_RPTable, DWPlus_DB.BidsSubmitted[i].player)
        local c = DWP:GetCColors(DWPlus_RPTable[dkp_total[1][1]].class)
        rank = DWP:GetGuildRank(DWPlus_DB.BidsSubmitted[i].player)
        if DWPlus_DB.BidsSubmitted[index] then
            row:Show()
            row.index = index
            row.Strings[1]:SetText(DWPlus_DB.BidsSubmitted[i].player.." |cff666666("..rank..")|r")
            row.Strings[1]:SetTextColor(c.r, c.g, c.b, 1)
            row.Strings[1].rowCounter:SetText(index)
            if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
            	row.Strings[2]:SetText(DWPlus_DB.BidsSubmitted[i].bid)
            	row.Strings[3]:SetText(DWP_round(DWPlus_RPTable[dkp_total[1][1]].dkp, DWPlus_DB.modes.rounding))
            elseif mode == "Roll Based Bidding" then
            	local minRoll;
            	local maxRoll;

            	if DWPlus_DB.modes.rolls.UsePerc then
            		if DWPlus_DB.modes.rolls.min == 0 or DWPlus_DB.modes.rolls.min == 1 then
            			minRoll = 1;
            		else
            			minRoll = DWPlus_RPTable[dkp_total[1][1]].dkp * (DWPlus_DB.modes.rolls.min / 100);
            		end
            		maxRoll = DWPlus_RPTable[dkp_total[1][1]].dkp * (DWPlus_DB.modes.rolls.max / 100) + DWPlus_DB.modes.rolls.AddToMax;
            	elseif not DWPlus_DB.modes.rolls.UsePerc then
            		minRoll = DWPlus_DB.modes.rolls.min;

            		if DWPlus_DB.modes.rolls.max == 0 then
            			maxRoll = DWPlus_RPTable[dkp_total[1][1]].dkp + DWPlus_DB.modes.rolls.AddToMax;
            		else
            			maxRoll = DWPlus_DB.modes.rolls.max + DWPlus_DB.modes.rolls.AddToMax;
            		end
            	end
            	if tonumber(minRoll) < 1 then minRoll = 1 end
            	if tonumber(maxRoll) < 1 then maxRoll = 1 end

            	row.Strings[2]:SetText(DWPlus_DB.BidsSubmitted[i].roll..DWPlus_DB.BidsSubmitted[i].range)
            	row.Strings[3]:SetText(math.floor(minRoll).."-"..math.floor(maxRoll))
            elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
            	row.Strings[3]:SetText(DWP_round(DWPlus_DB.BidsSubmitted[i].dkp, DWPlus_DB.modes.rounding))
            end
        else
            row:Hide()
        end
    end
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
	    if DWPlus_DB.modes.CostSelection == "First Bidder" and DWPlus_DB.BidsSubmitted[1] then
	    	core.BiddingWindow.cost:SetText(DWPlus_DB.BidsSubmitted[1].bid)
	    elseif DWPlus_DB.modes.CostSelection == "Second Bidder" and DWPlus_DB.BidsSubmitted[2] then
	    	core.BiddingWindow.cost:SetText(DWPlus_DB.BidsSubmitted[2].bid)
	    end
	end
    --FauxScrollFrame_Update(core.BiddingWindow.bidTable, numOptions, numrows, height, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function DWP:CreateBidWindow()
	local f = CreateFrame("Frame", "DWP_BiddingWindow", UIParent, "ShadowOverlaySmallTemplate");
	mode = DWPlus_DB.modes.mode;

	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -200);
	f:SetSize(400, 500);
	f:SetClampedToScreen(true)
	f:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,1)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(5)
	f:SetMovable(true);
	f:EnableMouse(true);
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", f.StartMoving);
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing();
		local point, relativeTo, relativePoint ,xOff,yOff = f:GetPoint(1)
		if not DWPlus_DB.bidpos then
			DWPlus_DB.bidpos = {}
		end
		DWPlus_DB.bidpos.point = point;
		DWPlus_DB.bidpos.relativeTo = relativeTo;
		DWPlus_DB.bidpos.relativePoint = relativePoint;
		DWPlus_DB.bidpos.x = xOff;
		DWPlus_DB.bidpos.y = yOff;
	end);
	f:SetScript("OnHide", function ()
		if core.BidInProgress then
			DWP:Print(L["CLOSEDBIDINPROGRESS"])
		end
	end)
	f:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if DWP.UIConfig then DWP.UIConfig:SetFrameLevel(2) end
	end)
	tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

	  -- Close Button
	f.closeContainer = CreateFrame("Frame", "DWPBiddingWindowCloseButtonContainer", f)
	f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
	f.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
	});
	f.closeContainer:SetBackdropColor(0,0,0,0.9)
	f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	f.closeContainer:SetSize(28, 28)

	f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)
	
	if core.IsOfficer then
		f.bossHeader = f:CreateFontString(nil, "OVERLAY")
		f.bossHeader:SetFontObject("DWPLargeRight");
		f.bossHeader:SetScale(0.7)
		f.bossHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 85, -25);
		f.bossHeader:SetText(L["BOSS"]..":")

		f.boss = CreateFrame("EditBox", nil, f)
		f.boss:SetFontObject("DWPNormalLeft");
		f.boss:SetAutoFocus(false)
		f.boss:SetMultiLine(false)
		f.boss:SetTextInsets(10, 15, 5, 5)
		f.boss:SetBackdrop({
	    	bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		f.boss:SetBackdropColor(0,0,0,0.6)
		f.boss:SetBackdropBorderColor(1,1,1,0.6)
		f.boss:SetPoint("LEFT", f.bossHeader, "RIGHT", 9, 0);
		f.boss:SetSize(200, 28)
		f.boss:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		f.boss:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		f.boss:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		f.boss:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			DWPlus_DB.BidParams.bossName = self:GetText();
		end)

		if DWPlus_DB.BidParams.bossName then
			f.boss:SetText(DWPlus_DB.BidParams.bossName);
		end


		f.itemHeader = f:CreateFontString(nil, "OVERLAY")
		f.itemHeader:SetFontObject("DWPLargeRight");
		f.itemHeader:SetScale(0.7)
		f.itemHeader:SetPoint("TOP", f.bossHeader, "BOTTOM", 0, -25);
		f.itemHeader:SetText(L["ITEM"]..":")

		f.itemIcon = f:CreateTexture(nil, "OVERLAY", nil);
		f.itemIcon:SetPoint("LEFT", f.itemHeader, "RIGHT", 8, 0);
		f.itemIcon:SetColorTexture(0, 0, 0, 1)
		f.itemIcon:SetSize(28, 28);

		f.ItemIconButton = CreateFrame("Button", "DWPBiddingItemTooltipButtonButton", f)
		f.ItemIconButton:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 0, 0);
		f.ItemIconButton:SetSize(28, 28);

		f.item = f:CreateFontString(nil, "OVERLAY")
		f.item:SetFontObject("DWPNormalLeft");
		f.item:SetPoint("LEFT", f.itemIcon, "RIGHT", 5, 2);
		f.item:SetSize(200, 28)

		f.ItemTooltipButton = CreateFrame("Button", "DWPBiddingItemTooltipButtonButton", f)
		f.ItemTooltipButton:SetPoint("TOPLEFT", f.itemIcon, "TOPLEFT", 0, 0);

		f.itemName = f:CreateFontString(nil, "OVERLAY") 			-- hidden itemName field
		f.itemName:SetFontObject("DWPNormalLeft");

		f.minBidHeader = f:CreateFontString(nil, "OVERLAY")
		f.minBidHeader:SetFontObject("DWPLargeRight");
		f.minBidHeader:SetScale(0.7)
		f.minBidHeader:SetPoint("TOP", f.itemHeader, "BOTTOM", -30, -25);
		
		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			f.minBidHeader:SetText(L["MINIMUMBID"]..": ")
			
			f.minBid = CreateFrame("EditBox", nil, f)
			f.minBid:SetPoint("LEFT", f.minBidHeader, "RIGHT", 8, 0)   
		    f.minBid:SetAutoFocus(false)
		    f.minBid:SetMultiLine(false)
		    f.minBid:SetSize(70, 28)
		    f.minBid:SetBackdrop({
	      	  bgFile   = "Textures\\white.blp", tile = true,
		      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		    });
		    f.minBid:SetBackdropColor(0,0,0,0.6)
		    f.minBid:SetBackdropBorderColor(1,1,1,0.6)
		    f.minBid:SetMaxLetters(8)
		    f.minBid:SetTextColor(1, 1, 1, 1)
		    f.minBid:SetFontObject("DWPSmallRight")
		    f.minBid:SetTextInsets(10, 10, 5, 5)
		    f.minBid.tooltipText = L["MINIMUMBID"];
		    f.minBid.tooltipDescription = L["MINBIDTTDESC"]
		    f.minBid.tooltipWarning = L["MINBIDTTWARN"]
		    f.minBid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		      self:ClearFocus()
		    end)
		    f.minBid:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["MINIMUMBID"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["MINBIDTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["MINBIDTTWARN"], 1.0, 0, 0, true);
				GameTooltip:AddLine(L["MINBIDTTEXT"], 1.0, 0.5, 0, true);
				GameTooltip:Show();
			end)
			f.minBid:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
		end

		f.CustomMinBid = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
		f.CustomMinBid:SetChecked(true)
		f.CustomMinBid:SetScale(0.6);
		f.CustomMinBid.text:SetText("  |cff5151de"..L["CUSTOM"].."|r");
		f.CustomMinBid.text:SetScale(1.5);
		f.CustomMinBid.text:SetFontObject("DWPSmallLeft")
		f.CustomMinBid.text:SetPoint("LEFT", f.CustomMinBid, "RIGHT", -10, 0)
		f.CustomMinBid:Hide();
		f.CustomMinBid:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CUSTOMMINBID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["CUSTOMMINBIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["CUSTOMMINBIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.CustomMinBid:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

	    f.bidTimerHeader = f:CreateFontString(nil, "OVERLAY")
		f.bidTimerHeader:SetFontObject("DWPLargeRight");
		f.bidTimerHeader:SetScale(0.7)
		f.bidTimerHeader:SetPoint("TOP", f.minBidHeader, "BOTTOM", 13, -25);
		f.bidTimerHeader:SetText(L["BIDTIMER"]..": ")

		f.bidTimer = CreateFrame("EditBox", nil, f)
		f.bidTimer:SetPoint("LEFT", f.bidTimerHeader, "RIGHT", 8, 0)   
	    f.bidTimer:SetAutoFocus(false)
	    f.bidTimer:SetMultiLine(false)
	    f.bidTimer:SetSize(70, 28)
	    f.bidTimer:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	    });
	    f.bidTimer:SetBackdropColor(0,0,0,0.6)
	    f.bidTimer:SetBackdropBorderColor(1,1,1,0.6)
	    f.bidTimer:SetMaxLetters(4)
	    f.bidTimer:SetTextColor(1, 1, 1, 1)
	    f.bidTimer:SetFontObject("DWPSmallRight")
	    f.bidTimer:SetTextInsets(10, 10, 5, 5)
	    f.bidTimer.tooltipText = L["BIDTIMER"];
	    f.bidTimer.tooltipDescription = L["BIDTIMERTTDESC"]
	    f.bidTimer.tooltipWarning = L["BIDTIMERTTWARN"]
	    f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	      self:ClearFocus()
	    end)
	    f.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	      self:ClearFocus()
	    end)
	    f.bidTimer:SetScript("OnEnter", function(self)
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
		f.bidTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		f.bidTimer:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			DWPlus_DB.BidParams.bidTimer = self:GetText();
		end)

		if DWPlus_DB.BidParams.bidTimer then
			f.bidTimer:SetText(DWPlus_DB.BidParams.bidTimer);
		end

		f.bidTimerFooter = f:CreateFontString(nil, "OVERLAY")
		f.bidTimerFooter:SetFontObject("DWPNormalLeft");
		f.bidTimerFooter:SetPoint("LEFT", f.bidTimer, "RIGHT", 5, 0);
		f.bidTimerFooter:SetText(L["SECONDS"])

		f.StartBidding = CreateFrame("Button", "DWPBiddingStartBiddingButton", f, "DWPlusButtonTemplate")
		f.StartBidding:SetPoint("TOPRIGHT", f, "TOPRIGHT", -25, -100);
		f.StartBidding:SetSize(100, 25);
		f.StartBidding:SetText(L["STARTBIDDING"]);
		f.StartBidding:GetFontString():SetTextColor(1, 1, 1, 1)
		f.StartBidding:SetNormalFontObject("DWPSmallCenter");
		f.StartBidding:SetHighlightFontObject("DWPSmallCenter");
		f.StartBidding:SetScript("OnClick", function (self)
			local pass, err = pcall(ToggleTimerBtn, self)

			if f.minBid then f.minBid:ClearFocus(); end
			f.bidTimer:ClearFocus()
			f.boss:ClearFocus()
			f.cost:ClearFocus()
			if not pass then
				DWP:Print(err)
				core.BiddingWindow:SetShown(false)
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
		end)
		f.StartBidding:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["STARTBIDDING"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["STARTBIDDINGTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["STARTBIDDINGTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		f.StartBidding:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		f.ClearBidWindow = DWP:CreateButton("TOP", f.StartBidding, "BOTTOM", 0, -10, L["CLEARBIDWINDOW"]);
		f.ClearBidWindow:SetSize(100,25)
		f.ClearBidWindow:SetScript("OnClick", ClearBidWindow)
		f.ClearBidWindow:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CLEARBIDWINDOW"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["CLEARBIDWINDOWTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.ClearBidWindow:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)


		--------------------------------------------------
		-- Bid Table
		--------------------------------------------------
	    f.bidTable = CreateFrame("ScrollFrame", "DWP_BidWindowTable", f, "FauxScrollFrameTemplate")
	    f.bidTable:SetSize(width, height*numrows+3)
		f.bidTable:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		});
		f.bidTable:SetBackdropColor(0,0,0,0.2)
		f.bidTable:SetBackdropBorderColor(1,1,1,0.4)
	    f.bidTable.ScrollBar = FauxScrollFrame_GetChildFrames(f.bidTable)
	    f.bidTable.ScrollBar:Hide()
	    f.bidTable.Rows = {}
	    for i=1, numrows do
	        f.bidTable.Rows[i] = BidWindowCreateRow(f.bidTable, i)
	        if i==1 then
	        	f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable, "TOPLEFT", 0, -3)
	        else	
	        	f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable.Rows[i-1], "BOTTOMLEFT")
	        end
	    end
	    f.bidTable:SetScript("OnVerticalScroll", function(self, offset)
	        FauxScrollFrame_OnVerticalScroll(self, offset, height, BidScrollFrame_Update)
	    end)

		---------------------------------------
		-- Header Buttons
		--------------------------------------- 
		local headerButtons = {}
		mode = DWPlus_DB.modes.mode;

		f.BidTable_Headers = CreateFrame("Frame", "DWPDKPTableHeaders", f)
		f.BidTable_Headers:SetSize(370, 22)
		f.BidTable_Headers:SetPoint("BOTTOMLEFT", f.bidTable, "TOPLEFT", 0, 1)
		f.BidTable_Headers:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		});
		f.BidTable_Headers:SetBackdropColor(0,0,0,0.8);
		f.BidTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
		f.bidTable:SetPoint("TOP", f, "TOP", 0, -200)
		f.BidTable_Headers:Show()

		headerButtons.player = CreateFrame("Button", "$ParentButtonPlayer", f.BidTable_Headers)
		headerButtons.bid = CreateFrame("Button", "$ParentButtonBid", f.BidTable_Headers)
		headerButtons.dkp = CreateFrame("Button", "$ParentSuttonDkp", f.BidTable_Headers)

		headerButtons.player:SetPoint("LEFT", f.BidTable_Headers, "LEFT", 2, 0)
		headerButtons.bid:SetPoint("LEFT", headerButtons.player, "RIGHT", 0, 0)
		headerButtons.dkp:SetPoint("RIGHT", f.BidTable_Headers, "RIGHT", -1, 0)

		for k, v in pairs(headerButtons) do
			v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
			if k == "player" then
				if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
					v:SetSize((width/2)-1, height)
				elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
					v:SetSize((width*0.75)-1, height)
				end
			else
				if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
					v:SetSize((width/4)-1, height)
				elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
					if k == "bid" then
						v:Hide()
					else
						v:SetSize((width/4)-1, height)
					end
				end
				
			end
		end

		headerButtons.player.t = headerButtons.player:CreateFontString(nil, "OVERLAY")
		headerButtons.player.t:SetFontObject("DWPNormalLeft")
		headerButtons.player.t:SetTextColor(1, 1, 1, 1);
		headerButtons.player.t:SetPoint("LEFT", headerButtons.player, "LEFT", 20, 0);
		headerButtons.player.t:SetText(L["PLAYER"]); 

		headerButtons.bid.t = headerButtons.bid:CreateFontString(nil, "OVERLAY")
		headerButtons.bid.t:SetFontObject("DWPNormal");
		headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
		headerButtons.bid.t:SetPoint("CENTER", headerButtons.bid, "CENTER", 0, 0);
		
		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			headerButtons.bid.t:SetText(L["BID"]); 
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
			headerButtons.bid.t:Hide(); 
		elseif mode == "Roll Based Bidding" then
			headerButtons.bid.t:SetText(L["PLAYERROLL"])
		end

		headerButtons.dkp.t = headerButtons.dkp:CreateFontString(nil, "OVERLAY")
		headerButtons.dkp.t:SetFontObject("DWPNormal")
		headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
		headerButtons.dkp.t:SetPoint("CENTER", headerButtons.dkp, "CENTER", 0, 0);
		
		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			headerButtons.dkp.t:SetText(L["TOTALDKP"]);
		elseif mode == "Static Item Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
			headerButtons.dkp.t:SetText(L["DKP"]);
		elseif mode == "Roll Based Bidding" then
			headerButtons.dkp.t:SetText(L["EXPECTEDROLL"])
		end
	    
	    ------------------------------------
	    --	AWARD ITEM
	    ------------------------------------

	    f.cost = CreateFrame("EditBox", nil, f)
		f.cost:SetPoint("TOPLEFT", f.bidTable, "BOTTOMLEFT", 71, -15)   
	    f.cost:SetAutoFocus(false)
	    f.cost:SetMultiLine(false)
	    f.cost:SetSize(70, 28)
	    f.cost:SetTextInsets(10, 10, 5, 5)
	    f.cost:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	    });
	    f.cost:SetBackdropColor(0,0,0,0.6)
	    f.cost:SetBackdropBorderColor(1,1,1,0.6)
	    f.cost:SetMaxLetters(8)
	    f.cost:SetTextColor(1, 1, 1, 1)
	    f.cost:SetFontObject("DWPSmallRight")
	    f.cost:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
	      self:ClearFocus()
	    end)
	    f.cost:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["ITEMCOST"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["ITEMCOSTTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		f.cost:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		f.cost:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			DWPlus_DB.BidParams.cost = self:GetText();
		end)

		if DWPlus_DB.BidParams.cost then
			f.cost:SetText(DWPlus_DB.BidParams.cost);
		end

		f.costHeader = f:CreateFontString(nil, "OVERLAY")
		f.costHeader:SetFontObject("DWPLargeRight");
		f.costHeader:SetScale(0.7)
		f.costHeader:SetPoint("RIGHT", f.cost, "LEFT", -7, 0);
		f.costHeader:SetText(L["ITEMCOST"]..": ")

		if DWPlus_DB.modes.costvalue == "Percent" then
			f.cost.perc = f.cost:CreateFontString(nil, "OVERLAY")
			f.cost.perc:SetFontObject("DWPNormalLeft");
			f.cost.perc:SetPoint("LEFT", f.cost, "RIGHT", -15, 1);
			f.cost.perc:SetText("%")
			f.cost:SetTextInsets(10, 15, 5, 5)
		end

		if mode == "Minimum Bid Values" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Minimum Bid") then
			f.CustomMinBid:SetPoint("LEFT", f.minBid, "RIGHT", 10, 0);
		elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and DWPlus_DB.modes.ZeroSumBidType == "Static") then
			f.CustomMinBid:SetPoint("LEFT", f.cost, "RIGHT", 10, 0);
		end

		f.StartBidding = DWP:CreateButton("LEFT", f.cost, "RIGHT", 80, 0, L["AWARDITEM"]);
		f.StartBidding:SetSize(90,25)
		f.StartBidding:SetScript("OnClick", function ()	-- confirmation dialog to remove user(s)
			if SelectedBidder["player"] then
				if strlen(strtrim(core.BiddingWindow.boss:GetText(), " ")) < 1 then 			-- verifies there is a boss name
					StaticPopupDialogs["VALIDATE_BOSS"] = {
						text = L["INVALIDBOSSNAME"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("VALIDATE_BOSS")
					return;
				end
				
				DWP:AwardConfirm(SelectedBidder["player"], tonumber(f.cost:GetText()), f.boss:GetText(), DWPlus_DB.bossargs.CurrentRaidZone, DWPlus_DB.BidParams.CurrItemForBid)
			else
				local selected = L["PLAYERVALIDATE"];

				StaticPopupDialogs["CONFIRM_AWARD"] = {
				  text = selected,
				  button1 = L["OK"],
				  timeout = 5,
				  whileDead = true,
				  hideOnEscape = true,
				  preferredIndex = 3,
				}
				StaticPopup_Show ("CONFIRM_AWARD")
			end
		end);

		f:SetScript("OnMouseUp", function(self)    -- clears focus on esc
			local item,_,link = GetCursorInfo();

			if item == "item" then

				local itemName,_,_,_,_,_,_,_,_,itemIcon = GetItemInfo(link)

				DWPlus_DB.BidParams.CurrItemForBid = link
				DWPlus_DB.BidParams.CurrItemIcon = itemIcon
				DWP:ToggleBidWindow(DWPlus_DB.BidParams.CurrItemForBid, DWPlus_DB.BidParams.CurrItemIcon, itemName)
				ClearCursor()
			end
	    end)
	end

	return f;
end