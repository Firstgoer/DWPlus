function DWPlusButton_OnLoad(self)
	if ( not self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
		self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	end
end

function DWPlusButton_OnMouseDown(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Down");
		self.Middle:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Down");
		self.Right:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Down");
	end
end

function DWPlusButton_OnMouseUp(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
	end
end

function DWPlusButton_OnShow(self)
	if ( self:IsEnabled() ) then
		self.Left:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
		self.Middle:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
		self.Right:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
	end
end

function DWPlusButton_OnDisable(self)
	self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
	self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
end

function DWPlusButton_OnEnable(self)
	self.Left:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
	self.Middle:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
	self.Right:SetTexture("Interface\\AddOns\\DWPlus\\Media\\Textures\\DWPlus-Button-Up");
end