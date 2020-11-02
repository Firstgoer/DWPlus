local _, core = ...;
local _G = _G;
local L = core.L;

-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local DWP = core.DWP;
local MiniMapButton = {}
DWP.MiniMapButton = MiniMapButton
local DWPlusButton = LibStub("LibDBIcon-1.0")

local TT_H_1, TT_H_2 = "|cff00FF00"..L["DWPLUS"].."|r", string.format("|cffFFFFFF%s|r", core.MonVersion)
local TT_ENTRY = "|cffFFFFFF%s|r"
--local TT_ENTRY = "|cFFCFCFCF%s:|r %s"


-- LDB
if not LibStub:GetLibrary("LibDataBroker-1.1", true) then return end

--Make an LDB object
local MiniMapLDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("DWPlus", {
	type = "launcher",
	text = L["DWPLUS"],
	icon = "Interface\\AddOns\\DWPlus\\Media\\Icons\\minimap.tga",
	OnTooltipShow = function(tooltip)
		tooltip:AddDoubleLine(TT_H_1, TT_H_2);
		tooltip:AddLine(format(TT_ENTRY, L["MINIMAPSETTINGS"]))
		--tooltip:AddLine(format(TT_ENTRY, L["MINIMAPLEFTCLICK"], L["MINIMAPSETTINGS"]))
		--tooltip:AddLine(format(TT_ENTRY, L["Shift + Left Click"], L["Open Options"]))
		--tooltip:AddLine(format(TT_ENTRY, L["Right Click"], L["Open Favourites"]))
	end,
	OnClick = function(self, button)
		--if button == "RightButton" then
		--	AtlasLoot.Addons:GetAddon("Favourites").GUI:Toggle()
		--elseif button == "MiddleButton" and DWPlus_DB.enableAutoSelect then
		--	DWPlus_DB.enableAutoSelect = false
		--	SlashCommands:Run("")
		--	DWPlus_DB.enableAutoSelect = true
		--else
		DWP:Toggle();
		--end
	end,
})

function MiniMapButton.Toggle()
	DWPlus_DB.minimap.shown = not DWPlus_DB.minimap.shown
	DWPlus_DB.minimap.hide = not DWPlus_DB.minimap.hide
	if not DWPlus_DB.minimap.hide then
		DWPlusButton:Show("DWPlus")
	else
		DWPlusButton:Hide("DWPlus")
	end
end

function MiniMapButton.Options_Toggle()
	if DWPlus_DB.minimap.shown then
		DWPlusButton:Show("DWPlus")
		DWPlus_DB.minimap.hide = nil
	else
		DWPlusButton:Hide("DWPlus")
		DWPlus_DB.minimap.hide = true
	end
end

function MiniMapButton.Lock_Toggle()
	if DWPlus_DB.minimap.locked then
		DWPlusButton:Lock("DWPlus");
	else
		DWPlusButton:Unlock("DWPlus");
	end
end

function DWP:InitMinimapButton()
	DWP.Commands["mmb"] = MiniMapButton.Toggle;

	DWPlusButton:Register("DWPlus", MiniMapLDB, DWPlus_DB.minimap);
end
