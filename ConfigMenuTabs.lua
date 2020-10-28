local _, core = ...;
local _G = _G;
local DWP = core.DWP;
local L = core.L;

--
--  When clicking a box off, unchecks "All" as well and flags checkAll to false
--
local checkAll = true;                    -- changes to false when less than all of the boxes are checked
local curReason;                          -- stores user input in dropdown 

local function ScrollFrame_OnMouseWheel(self, delta)          -- scroll function for all but the DKPTable frame
	local newValue = self:GetVerticalScroll() - (delta * 20);   -- DKPTable frame uses FauxScrollFrame_OnVerticalScroll()
	
	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end
	
	self:SetVerticalScroll(newValue);
end

function DWPFilterChecks(self)         -- sets/unsets check boxes in conjunction with "All" button, then runs DWP:FilterDKPTable() above
	local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
	if (self:GetChecked() == false and not DWP.ConfigTab1.checkBtn[10]) then
		core.CurView = "limited"
		core.CurSubView = "raid"
		DWP.ConfigTab1.checkBtn[9]:SetChecked(false);
		checkAll = false;
		verifyCheck = false
	end
	for i=1, 8 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
		if DWP.ConfigTab1.checkBtn[i]:GetChecked() == false then
			verifyCheck = false;
		end
	end
	if (verifyCheck == true) then
		DWP.ConfigTab1.checkBtn[9]:SetChecked(true);
	else
		DWP.ConfigTab1.checkBtn[9]:SetChecked(false);
	end
	for k,v in pairs(core.classes) do
		if (DWP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
			core.classFiltered[v] = true;
		else
			core.classFiltered[v] = false;
		end
	end
	PlaySound(808)
	DWP:FilterDKPTable(core.currentSort, "reset");
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID());
	
	if self:GetID() > 4 then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	elseif self:GetID() == 4 and core.IsOfficer == true then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	else
		self:GetParent().ScrollFrame.ScrollBar:Hide()
	end

	if self:GetID() == 5 then
		DWP:LootHistory_Update(L["NOFILTER"]);
	elseif self:GetID() == 6 then
		DWP:DKPHistory_Update(true)
	end

	local scrollChild = self:GetParent().ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	PlaySound(808)
	self:GetParent().ScrollFrame:SetScrollChild(self.content);
	self.content:Show();
	self:GetParent().ScrollFrame:SetVerticalScroll(0)
end

function DWP:SetTabs(frame, numTabs, width, height, ...)
	frame.numTabs = numTabs;
	
	local contents = {};
	local frameName = frame:GetName();
	
	for i = 1, numTabs do 
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "DWPTabButtonTemplate");
		tab:SetID(i);
		tab:SetText(select(i, ...));
		tab:GetFontString():SetFontObject("DWPSmallOutlineCenter")
		tab:GetFontString():SetTextColor(0.7, 0.7, 0.86, 1)
		tab:SetScript("OnClick", Tab_OnClick);
		
		tab.content = CreateFrame("Frame", nil, frame.ScrollFrame);
		tab.content:SetSize(width, height);
		tab.content:Hide();
				
		table.insert(contents, tab.content);
		
		if (i == 1) then
			tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, 1);
		else
			tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -17, 0);
		end 
	end
	
	Tab_OnClick(_G[frameName.."Tab1"]);
	
	return unpack(contents);
end

---------------------------------------
-- Populate Tabs 
---------------------------------------
function DWP:ConfigMenuTabs()
	---------------------------------------
	-- TabMenu
	---------------------------------------

	DWP.UIConfig.TabMenu = CreateFrame("Frame", "DWP.ConfigTabMenu", DWP.UIConfig);
	DWP.UIConfig.TabMenu:SetPoint("TOPRIGHT", DWP.UIConfig, "TOPRIGHT", -25, -25);
	DWP.UIConfig.TabMenu:SetSize(477, 510);
	DWP.UIConfig.TabMenu:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\DWPlus\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	DWP.UIConfig.TabMenu:SetBackdropColor(0,0,0,0.9);
	DWP.UIConfig.TabMenu:SetBackdropBorderColor(1,1,1,0.5)

	DWP.UIConfig.TabMenuBG = DWP.UIConfig.TabMenu:CreateTexture(nil, "OVERLAY", nil);
	DWP.UIConfig.TabMenuBG:SetColorTexture(0, 0, 0, 1)
	DWP.UIConfig.TabMenuBG:SetPoint("TOPLEFT", DWP.UIConfig.TabMenu, "TOPLEFT", 2, -2);
	DWP.UIConfig.TabMenuBG:SetSize(478, 511);
	DWP.UIConfig.TabMenuBG:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\menu-bg");

	-- TabMenu ScrollFrame and ScrollBar
	DWP.UIConfig.TabMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, DWP.UIConfig.TabMenu, "UIPanelScrollFrameTemplate");
	DWP.UIConfig.TabMenu.ScrollFrame:ClearAllPoints();
	DWP.UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  DWP.UIConfig.TabMenu, "TOPLEFT", 4, -8);
	DWP.UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", DWP.UIConfig.TabMenu, "BOTTOMRIGHT", -3, 4);
	DWP.UIConfig.TabMenu.ScrollFrame:SetClipsChildren(false);
	DWP.UIConfig.TabMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	
	DWP.UIConfig.TabMenu.ScrollFrame.ScrollBar:Hide();
	DWP.UIConfig.TabMenu.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, DWP.UIConfig.TabMenu.ScrollFrame, "UIPanelScrollBarTrimTemplate")
	DWP.UIConfig.TabMenu.ScrollFrame.ScrollBar:ClearAllPoints();
	DWP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", DWP.UIConfig.TabMenu.ScrollFrame, "TOPRIGHT", -20, -12);
	DWP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", DWP.UIConfig.TabMenu.ScrollFrame, "BOTTOMRIGHT", -2, 15);

	DWP.ConfigTab1, DWP.ConfigTab2, DWP.ConfigTab3, DWP.ConfigTab4, DWP.ConfigTab5, DWP.ConfigTab6 = DWP:SetTabs(DWP.UIConfig.TabMenu, 6, 475, 490, L["FILTERS"], L["ADJUSTDKP"], L["MANAGE"], L["OPTIONS"], L["LOOTHISTORY"], L["DKPHISTORY"]);

	---------------------------------------
	-- MENU TAB 1
	---------------------------------------

	DWP.ConfigTab1.text = DWP.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- Filters header
	DWP.ConfigTab1.text:ClearAllPoints();
	DWP.ConfigTab1.text:SetFontObject("DWPLargeCenter")
	DWP.ConfigTab1.text:SetPoint("TOPLEFT", DWP.ConfigTab1, "TOPLEFT", 15, -10);
	DWP.ConfigTab1.text:SetText(L["FILTERS"]);
	DWP.ConfigTab1.text:SetScale(1.2)

	local checkBtn = {}
	DWP.ConfigTab1.checkBtn = checkBtn;

	-- Create CheckBoxes
	for i=1, 10 do
		DWP.ConfigTab1.checkBtn[i] = CreateFrame("CheckButton", nil, DWP.ConfigTab1, "UICheckButtonTemplate");
		if i <= 9 then DWP.ConfigTab1.checkBtn[i]:SetChecked(true) else DWP.ConfigTab1.checkBtn[i]:SetChecked(false) end;
		DWP.ConfigTab1.checkBtn[i]:SetID(i)
		if i <= 8 then
			DWP.ConfigTab1.checkBtn[i].text:SetText("|cff5151de"..core.LocalClass[core.classes[i]].."|r");
		end
		if i==9 then
			DWP.ConfigTab1.checkBtn[i]:SetScript("OnClick",
				function()
					for j=1, 9 do
						if (checkAll) then
							DWP.ConfigTab1.checkBtn[j]:SetChecked(false)
						else
							DWP.ConfigTab1.checkBtn[j]:SetChecked(true)
						end
					end
					checkAll = not checkAll;
					DWPFilterChecks(DWP.ConfigTab1.checkBtn[9]);
				end)

			for k,v in pairs(core.classes) do               -- sets core.classFiltered table with all values
				if (DWP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
					core.classFiltered[v] = true;
				else
					core.classFiltered[v] = false;
				end
			end
		elseif i==10 then
			DWP.ConfigTab1.checkBtn[i]:SetScript("OnClick", function(self)
				DWP.ConfigTab1.checkBtn[12]:SetChecked(false);
				DWPFilterChecks(self)
			end)
		else
			DWP.ConfigTab1.checkBtn[i]:SetScript("OnClick", DWPFilterChecks)
		end
		DWP.ConfigTab1.checkBtn[i].text:SetFontObject("DWPSmall")
	end

	-- Class Check Buttons:
	DWP.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", DWP.ConfigTab1, "TOPLEFT", 85, -70);
	DWP.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
	DWP.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
	DWP.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
	DWP.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
	DWP.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
	DWP.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
	DWP.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);

	DWP.ConfigTab1.checkBtn[9]:SetPoint("BOTTOMRIGHT", DWP.ConfigTab1.checkBtn[2], "TOPLEFT", 50, 0);
	DWP.ConfigTab1.checkBtn[9].text:SetText("|cff5151de"..L["ALLCLASSES"].."|r");
	DWP.ConfigTab1.checkBtn[10]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[5], "BOTTOMLEFT", 0, 0);
	DWP.ConfigTab1.checkBtn[10].text:SetText("|cff5151de"..L["INPARTYRAID"].."|r");         -- executed in filterDKPTable (DWPlus.lua)

	DWP.ConfigTab1.checkBtn[11] = CreateFrame("CheckButton", nil, DWP.ConfigTab1, "UICheckButtonTemplate");
	DWP.ConfigTab1.checkBtn[11]:SetID(11)
	DWP.ConfigTab1.checkBtn[11].text:SetText("|cff5151de"..L["ONLINE"].."|r");
	DWP.ConfigTab1.checkBtn[11].text:SetFontObject("DWPSmall")
	DWP.ConfigTab1.checkBtn[11]:SetScript("OnClick", DWPFilterChecks)
	DWP.ConfigTab1.checkBtn[11]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[10], "TOPRIGHT", 100, 0);

	DWP.ConfigTab1.checkBtn[12] = CreateFrame("CheckButton", nil, DWP.ConfigTab1, "UICheckButtonTemplate");
	DWP.ConfigTab1.checkBtn[12]:SetID(12)
	DWP.ConfigTab1.checkBtn[12].text:SetText("|cff5151de"..L["NOTINRAIDFILTER"].."|r");
	DWP.ConfigTab1.checkBtn[12].text:SetFontObject("DWPSmall")
	DWP.ConfigTab1.checkBtn[12]:SetScript("OnClick", function(self)
		DWP.ConfigTab1.checkBtn[10]:SetChecked(false);
		DWPFilterChecks(self)
	end)
	DWP.ConfigTab1.checkBtn[12]:SetPoint("TOPLEFT", DWP.ConfigTab1.checkBtn[11], "TOPRIGHT", 65, 0);

	core.ClassGraph = DWP:ClassGraph()  -- draws class graph on tab1

	---------------------------------------
	-- Adjust DKP TAB
	---------------------------------------

	DWP:AdjustDKPTab_Create()

	---------------------------------------
	-- Manage DKP TAB
	---------------------------------------

	DWP.ConfigTab3.header = DWP.ConfigTab3:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab3.header:ClearAllPoints();
	DWP.ConfigTab3.header:SetFontObject("DWPLargeCenter");
	DWP.ConfigTab3.header:SetPoint("TOPLEFT", DWP.ConfigTab3, "TOPLEFT", 15, -10);
	DWP.ConfigTab3.header:SetText(L["MANAGEDKP"]);
	DWP.ConfigTab3.header:SetScale(1.2)

	-- Populate Manage Tab
	DWP:ManageEntries()

	---------------------------------------
	-- Loot History TAB
	---------------------------------------

	DWP.ConfigTab5.text = DWP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab5.text:ClearAllPoints();
	DWP.ConfigTab5.text:SetFontObject("DWPLargeLeft");
	DWP.ConfigTab5.text:SetPoint("TOPLEFT", DWP.ConfigTab5, "TOPLEFT", 15, -10);
	DWP.ConfigTab5.text:SetText(L["LOOTHISTORY"]);
	DWP.ConfigTab5.text:SetScale(1.2)

	DWP.ConfigTab5.inst = DWP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab5.inst:ClearAllPoints();
	DWP.ConfigTab5.inst:SetFontObject("DWPSmallRight");
	DWP.ConfigTab5.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	DWP.ConfigTab5.inst:SetPoint("TOPRIGHT", DWP.ConfigTab5, "TOPRIGHT", -40, -43);
	DWP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);

	-- Populate Loot History (LootHistory.lua)
	local looter = {}
	DWP.ConfigTab5.looter = looter
	local lootFrame = {}
	DWP.ConfigTab5.lootFrame = lootFrame
	for i=1, #DWPlus_Loot do
	DWP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "DWPLootHistoryFrame"..i, DWP.ConfigTab5);
	end

	if #DWPlus_Loot > 0 then
		DWP:LootHistory_Update(L["NOFILTER"])
		CreateSortBox();
	end

	---------------------------------------
	-- DKP History Tab
	---------------------------------------

	DWP.ConfigTab6.text = DWP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab6.text:ClearAllPoints();
	DWP.ConfigTab6.text:SetFontObject("DWPLargeLeft");
	DWP.ConfigTab6.text:SetPoint("TOPLEFT", DWP.ConfigTab6, "TOPLEFT", 15, -10);
	DWP.ConfigTab6.text:SetText(L["DKPHISTORY"]);
	DWP.ConfigTab6.text:SetScale(1.2)

	DWP.ConfigTab6.inst = DWP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	DWP.ConfigTab6.inst:ClearAllPoints();
	DWP.ConfigTab6.inst:SetFontObject("DWPSmallRight");
	DWP.ConfigTab6.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	DWP.ConfigTab6.inst:SetPoint("TOPRIGHT", DWP.ConfigTab6, "TOPRIGHT", -40, -43);
	
	if #DWPlus_RPHistory > 0 then
		DWP:DKPHistory_Update()
	end
	DKPHistoryFilterBox_Create()

end
	