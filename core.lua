--====================================================================
-- KiwiHUD @ 2018 MiChaeL
--====================================================================

local addonName = ...

local addon = CreateFrame("Frame")
addon.addonName = addonName
addon.isClassic = select(4, GetBuildInfo())<20000
_G[addonName] = addon

--====================================================================

local Media  = LibStub("LibSharedMedia-3.0", true)

--====================================================================

local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitCastingInfo = UnitCastingInfo or CastingInfo
local UnitChannelInfo = UnitChannelInfo or ChannelInfo

local next, unpack, tremove, tinsert, floor,  max = next, unpack, table.remove, table.insert, floor, max

--====================================================================

local InCombat
local AlphaCombat
local PlayerClass = select(2,UnitClass('player'))
local isRetail = not addon.isClassic

--====================================================================

addon.defaults = {
	offsetY = 0,
	height  = 128,
	width   = 128,
	gap     = 250,
	sep     = 20,
	texfg   = "Interface\\Addons\\KiwiHUD\\media\\dhudfg",
	texbg   = "Interface\\Addons\\KiwiHUD\\media\\dhudbg",
	colorbg = {1,1,1,1},
	alphaCombat = 1,
	alphaOOC = .5,
	reactionColors = {},
	classColors = {},
	powerColors = {},
	schoolColors = {},
	bars = {
		{
			type  = "health",
			unit  = "player",
			index = -4,
			colorType = 'reaction',
			textEnabled = false,
		},
		{
			type = "power",
			unit = "player",
			index = -3,
			textEnabled = false,
		},
		{
			type = "cast",
			unit = "player",
			index = -2,
			color = { 1,1,0,1 },
		},
		{
			type = "gcd",
			index = -1,
			color = { 1,0,0,1 },
			invert = false,
		},
		{
			type = "power",
			unit = "target",
			index = 1,
			textEnabled = false,
		},
		{
			type = "health",
			unit = "target",
			colorType = 'reaction',
			index = 2,
			textEnabled = false,
		},
	},
	minimapIcon = { hide = false },
}

--====================================================================

addon.setupFunc = {}

--====================================================================

local REACTION_COLORS = {
	hostile = {.7,.2,.1,1},
	neutral = {1,.8,0,1},
	friendly = {.2,.6,.1,1},
	tapped = {.5,.5,.5,1},
	playerfriendly = {.2,.6,.1,1},
	playerhostile = {.7,.2,.1,1}
}

local SCHOOL_COLORS = {
	{ 0.94, 0.88, 0.55, 1 }, -- all
	{ 0.98, 0.78, 0.63, 1 }, -- physical
	{ 0.02, 0.49, 0.97, 1 }, -- magic
	{ 1.00, 0.98, 0.02, 1 }, -- holy
	{ 1.00, 0.49, 0.00, 1 }, -- fire
	{ 0.51, 0.98, 0.00, 1 }, -- nature
	{ 0.00, 1.00, 0.97, 1 }, -- frost
	{ 0.73, 0.45, 1.00, 1 }, -- shadow
	{ 0.99, 0.62, 1.00, 1 }, -- arcane
}

local Reactions = { 'hostile', 'hostile', 'hostile', 'neutral', 'friendly', 'friendly',	'friendly',	'friendly' }

local SchoolColors = {}
local ReactionColors = {}
local ClassColors = {}
local PowerColors = {}
local ColorDefault = { 1,1,1,1 }
local ColorGreen = { 0,1,0,1 }

local FontBarAnchors = {
	[ 1] = { TOP = 'TOPLEFT',  CENTER = 'LEFT',  BOTTOM = 'BOTTOMLEFT'  },
	[-1] = { TOP = 'TOPRIGHT', CENTER = 'RIGHT', BOTTOM = 'BOTTOMRIGHT' },
}

--====================================================================
-- Misc functions
--====================================================================

local function OnEvent(self,event,...)
	self[event](self,event,...)
end

local function Embed(dst, src)
	if src then
		for k,v in pairs(src) do
			dst[k] = v
		end
	end
end

local function FillColorsTable(dst, src, override)
	wipe(dst)
	for k,c in pairs(src) do
		if override and override[k] then
			dst[k] = { unpack(override[k]) }
		elseif c.r then
			dst[k] = { c.r, c.g, c.b, 1 }
		else
			dst[k] = { unpack(c) }
		end
	end
end

--====================================================================
-- First Run
--====================================================================

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name == addonName then
		addon.__loaded = true
	end
	if addon.__loaded and IsLoggedIn() then
		self:UnregisterAllEvents()
		self:SetScript("OnEvent", OnEvent)
		addon:InitializeDB()
		addon:InitializeOptions()
		addon:Initialize()
	end
end )

--====================================================================
-- For future use
--====================================================================

--function addon:PLAYER_ENTERING_WORLD(event,isLogin,isReload)
--end

--====================================================================
-- Track combat status
--====================================================================

function addon:PLAYER_REGEN_DISABLED(event)
	InCombat    = (event == 'PLAYER_REGEN_DISABLED')
	AlphaCombat = InCombat and (self.db.alphaCombat or 1) or (self.db.alphaOOC or .5)
	for _,bar in ipairs(self.bars) do
		local func = bar.UpdateOpacity
		if func then func(bar) end
	end
end
addon.PLAYER_REGEN_ENABLED = addon.PLAYER_REGEN_DISABLED

--====================================================================
-- UI elements factories
--====================================================================

local Frame_Create, Texture_Create, Font_Create, Frame_Release, Texture_Release, Font_Release
do
	local fonts = {}
	local textures = {}
	local frames = setmetatable( {} , { __index = function(t,k) local v={}; t[k]=v; return v; end } )

	function Frame_Create(type)
		local frame = tremove(frames[type or 'default']) or CreateFrame('Frame', nil, UIParent)
		frame.__factory_type = type
		frame:SetParent(UIParent)
		frame:ClearAllPoints()
		frame:Hide()
		return frame
	end

	function Frame_Release(frame)
		if frame then
			frame:SetScript("OnEvent", nil)
			frame:SetScript("OnUpdate",nil)
			frame:UnregisterAllEvents()
			frame:SetAlpha(1)
			frame:SetScale(1)
			frame:Hide()
			tinsert( frames[frame.__factory_type or 'default'], frame )
		end
	end

	function Texture_Create(self, layer, sublayer)
		local tex = tremove(textures) or self:CreateTexture()
		tex:SetParent(self)
		tex:SetDrawLayer(layer or "ARTWORK", sublayer)
		tex:SetVertexColor(1,1,1,1)
		tex:SetTexCoord(0,1,0,1)
		tex:ClearAllPoints()
		tex:Hide()
		return tex
	end

	function Texture_Release(tex)
		if tex then
			tex:SetParent(addon)
			tex:Hide()
			textures[#textures+1] = tex
		end
	end

	function Font_Create(self, layer)
		local text = tremove(fonts) or self:CreateFontString()
		text:SetParent(self)
		text:SetDrawLayer(layer or 'ARTWORK')
		text:SetTextColor(1,1,1,1)
		text:ClearAllPoints()
		text:Hide()
		return text
	end

	function Font_Release(text)
		if text then
			text:SetParent(addon)
			text:Hide()
			fonts[#fonts+1] = text
		end
	end

end

--====================================================================
-- Generic Bar class
--====================================================================

local Bar_Create
do
	local class = {}

	function class:Destroy()
		for _,tex in pairs(self.textures) do
			Texture_Release(tex)
		end
		wipe(self.textures)
		self.Text = Font_Release(self.Text)
		Frame_Release(self)
	end

	function class:Layout()
		local db       = addon.db
		local bar      = self.db
		self.unit      = bar.unit
		self.hideValue = bar.hideValue
		self.height    = db.height
		if bar.index>0 then
			self.side, self.coord1, self.coord2 =  1, 0, 1
		else
			self.side, self.coord1, self.coord2 = -1, 1, 0
		end
		-- frame
		self:ClearAllPoints()
		self:SetScale( db.scale or 1 )
		self:SetPoint("CENTER", self.side * db.gap + bar.index * db.sep - self.side * db.sep, db.offsetY or 0 )
		self:SetSize( db.width, db.height )
		-- textures
		for _,tex in pairs(self.textures) do
			tex:SetTexCoord( self.coord1, self.coord2, 0, 1 )
		end
		if db.colorbg then
			self.textures[0]:SetVertexColor( unpack(db.colorbg) )
		end
		if bar.color then
			self:SetColor( bar.color or ColorDefault )
		end
		-- text
		local Text = self.Text
		if Text then
			Text:ClearAllPoints()
			Text:SetPoint( bar.textAlign or 'CENTER', self, FontBarAnchors[self.side][bar.textAnchor or 'BOTTOM'], bar.textOffsetX, bar.textOffsetY )
			Text:SetFont( Media:Fetch('font', bar.textFont) or STANDARD_TEXT_FONT, bar.textFontSize or 14, 'OUTLINE' )
			Text:SetTextColor( unpack(bar.textColor or ColorDefault) )
		end
	end

	function class:SetColor(color)
		local tex = self.textures[1]
		tex:SetVertexColor( unpack(color) )
	end

	function class:SetValue(value, valueMax)
		local pvalue = valueMax and value/valueMax or value
		local tex = self.textures[1]
		tex:SetHeight( self.height * pvalue )
		tex:SetTexCoord( self.coord1, self.coord2, 1-pvalue, 1 )
		tex:SetShown(value>0)
		local hideValue = self.hideValue
		if self.Text then
			if valueMax then -- value & valueMax
				self.Text:SetFormattedText(value)
			else -- percent, no valueMAx
				self.Text:SetFormattedText("%.0f%%",value*100)
			end
		end
		if hideValue then
			self:SetShown( InCombat or pvalue ~= hideValue )
		end
		self.value = value
		self.valuePer = pvalue
		self.valueMax = valueMax
	end

	function class:UpdateValue()
		if self.value then
			self:SetValue(self.value, self.valueMax)
		end
	end

	function class:UpdateVisibility(value) -- value == 0 to 1
		value = value or self.valuePer
		local hideValue = self.hideValue
		if hideValue then
			self:SetShown( InCombat or value ~= hideValue )
		end
	end

	function class:UpdateOpacity()
		-- we check unit=='player' because UnitExists('player') can return false when exiting from an instance if the player was in combat (because PLAYER_REGEN_ENABLED is triggered before PLAYER_ENTERING_WORLD)
		local unit  = self.unit
		self:SetAlpha( (not unit or unit=='player' or UnitExists(unit)) and AlphaCombat or 0 )
		if self.hideValue then
			self:SetShown( InCombat or self.valuePer ~= self.hideValue )
		end
	end

	function class:Update()
		self:UpdateValue()
		self:UpdateColor()
		self:UpdateOpacity()
	end

	function class:UpdateColor()
	end

	function class:UpdateDB()
	end

	function Bar_Create(db, embed)
		local self = Frame_Create()
		self.prototype = class
		self.db = db
		self.textures = self.textures or {}
		Embed(self, class)
		Embed(self, embed)
		local tex = Texture_Create(self, 'BACKGROUND')
		tex:SetTexture(addon.db.texbg)
		tex:SetAllPoints()
		tex:SetVertexColor(.5,.5,.5,1)
		tex:Show()
		self.textures[0] = tex
		local tex = Texture_Create(self, 'ARTWORK')
		tex:SetTexture(addon.db.texfg)
		tex:SetPoint('BOTTOMLEFT')
		tex:SetPoint('BOTTOMRIGHT')
		tex:SetHeight(0)
		tex:SetVertexColor(1,1,1,1)
		tex:Hide()
		self.textures[index or 1] = tex
		self.margin = addon.db.texmargin or 1
		if db.textEnabled then
			local text = Font_Create(self,'BORDER')
			text:SetShadowOffset(1,-1)
			text:SetShadowColor(0,0,0, 1)
			text:Show()
			self.Text = text
		end
		self:UpdateDB()
		self:Layout()
		return self
	end
end

--====================================================================
-- Energy ticker
--====================================================================

local EnergyTicker_Register
do
	local POWER_ENERGY = Enum.PowerType.Energy
	local GetTime = GetTime
	local UnitPower = UnitPower
	local frame
	local bars = {}
	local lastEnergy = 0
	local lastTick = GetTime()

	local function Destroy(self)
		self.prototype.Destroy(self)
		self.spark = Texture_Release(self.spark)
		bars[self] = nil
		if frame and not next(bars) then frame:Hide() end
	end

	local function Update(self)
		local now = GetTime()
	    local energy = UnitPower("player", POWER_ENERGY)
		if energy>lastEnergy or now>=lastTick+2 then
			lastEnergy, lastTick = energy, now
		end
		local p = (now - lastTick) / 2
		if p<1 then
			local offset = p * addon.db.height
			for bar in next,bars do
				local spark = bar.spark
				spark:ClearAllPoints()
				spark:SetPoint( 'BOTTOM', 0, offset )
				spark:SetTexCoord( bar.coord1, bar.coord2, 0.975-p, 1-p)
				spark:Show()
			end
		else
			for bar in next,bars do
				bar.spark:Hide()
			end
		end
	end

	function EnergyTicker_Register(bar)
		if frame then
			if not next(bars) then frame:Show() end
		else
			frame = CreateFrame('Frame')
			frame:SetScript('OnUpdate', Update)
		end
		local tex = Texture_Create(bar, 'OVERLAY')
		tex:SetTexture( addon.db.texfg )
		tex:SetVertexColor(1,0,0,1)
		tex:SetHeight(addon.db.height*0.025)
		tex:SetWidth(addon.db.width)
		bar.spark = tex
		bar.Destroy = Destroy
		bars[bar] = true
	end
end

--====================================================================
-- Power Bar
--====================================================================

do
	local UnitPower = UnitPower
	local UnitPowerMax = UnitPowerMax
	local UnitPowerType = UnitPowerType
	local POWER_MANA = Enum.PowerType.Mana

	local function UpdateColor(self)
		local type = UnitPowerType(self.unit)
		self:SetColor( PowerColors[type] or PowerColors[POWER_MANA] )
	end

	local function UpdateValue(self, _, _, powerType)
		local u = self.unit
		local _, typ = UnitPowerType(u)
		if powerType == nil or typ == powerType then
			local m = UnitPowerMax(u)
			if m>0 then
				if m>150 then
					self:SetValue( UnitPower(u) / m )
				else
					self:SetValue( UnitPower(u), m )
				end
			end
		end
	end

	local embed = { UpdateColor = UpdateColor, UpdateValue = UpdateValue }

	addon.setupFunc['power'] = function(db)
		local self = Bar_Create(db, embed)
		self:Show()
		self:SetScript("OnEvent", OnEvent)
		self:RegisterUnitEvent("UNIT_POWER_UPDATE", db.unit)
		self:RegisterUnitEvent("UNIT_MAXPOWER", db.unit)
		self:RegisterUnitEvent("UNIT_DISPLAYPOWER", db.unit)
		if db.unit == 'target' then
			self.PLAYER_TARGET_CHANGED = self.Update
			self:RegisterEvent( "PLAYER_TARGET_CHANGED" )
		elseif db.unit == 'focus' then
			self.PLAYER_FOCUS_CHANGED = self.Update
			self:RegisterEvent( "PLAYER_FOCUS_CHANGED" )
		elseif db.unit == 'pet' then
			self.UNIT_PET = self.Update
			self:RegisterUnitEvent( "UNIT_PET", 'player' )
		elseif db.unit == 'player' and (PlayerClass=='ROGUE' or PlayerClass=='DRUID') and db.tickerEnabled then
			EnergyTicker_Register(self)
		end
		self.UNIT_DISPLAYPOWER = self.UpdateColor
		self.UNIT_POWER_UPDATE = self.UpdateValue
		self.UNIT_MAXPOWER     = self.UpdateValue
		self:Update()
		return self
	end
end

--====================================================================
-- Player Mana Alt
--====================================================================

do
	local ENABLED = (PlayerClass == 'PRIEST' or PlayerClass == 'SHAMAN' or PlayerClass == 'DRUID' or PlayerClass == 'MONK')
	local POWER_MANA = Enum.PowerType.Mana
	local UnitPower = UnitPower
	local UnitPowerMax = UnitPowerMax
	local UnitPowerType = UnitPowerType
	local GetSpecialization = isRetail and GetSpecialization or function() end

	local function UpdateColor(self)
		self:SetColor( PowerColors[POWER_MANA] )
	end

	local function UpdateValue(self)
		local show = UnitPowerType('player') ~= POWER_MANA and (PlayerClass~='MONK' or GetSpecialization() == SPEC_MONK_MISTWEAVER)
		if show then
			local m = UnitPowerMax('player', POWER_MANA)
			self:SetValue( m>0 and UnitPower('player', POWER_MANA) / m or 0 )
		end
		self:SetShown(show)
	end

	local embed = { UpdateColor = UpdateColor, UpdateValue = UpdateValue }

	addon.setupFunc['manaalt'] = function(db)
		local self = Bar_Create(db, embed)
		if ENABLED then
			self:Show()
			self:SetScript("OnEvent", OnEvent)
			self:RegisterUnitEvent("UNIT_POWER_UPDATE", 'player')
			self:RegisterUnitEvent("UNIT_MAXPOWER", 'player')
			self:RegisterUnitEvent("UNIT_DISPLAYPOWER", 'player')
			self.UNIT_DISPLAYPOWER = self.UpdateColor
			self.UNIT_POWER_UPDATE = self.UpdateValue
			self.UNIT_MAXPOWER     = self.UpdateValue
		end
		self:Update()
		return self
	end
end

--====================================================================
-- Health Bar
--====================================================================

do
	local min = math.min
	local UnitHealth = UnitHealth
	local UnitHealthMax = UnitHealthMax
	local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

	local function UpdateShieldValue(self, unit, valueFrom , valueMax)
		local value = UnitGetTotalAbsorbs(unit) or 0
		if value~=0 or self.shieldValue then
			local tex = self.textures[2]
			tex:SetShown( value>0 )
			self.shieldValue = value~=0 and value or nil
			local valueTo = min(1, valueFrom + value/valueMax)
			tex:SetTexCoord( self.coord1, self.coord2, 1-valueTo, 1-valueFrom)
			tex:SetHeight( self.height * (valueTo-valueFrom) )
		end
	end

	local function UpdateShieldColor(self, color)
		local tex = self.textures[2]
		tex:SetVertexColor( unpack(color) )
		tex:SetAlpha( color[4]/4 )
	end

	local function UpdateColor(self)
		local color = self.db.color
		self:SetColor( self.db.color )
		if self.shieldDisplay then
			UpdateShieldColor(self, color)
		end
	end

	local function UpdateReactionColor(self)
		local color = ReactionColors[ Reactions[ UnitReaction(self.unit,"player") ] ] or ColorDefault
		self:SetColor( color )
		if self.shieldDisplay then
			UpdateShieldColor(self, color)
		end
	end

	local function UpdateClassColor(self)
		local _,class = UnitClass(self.unit)
		local color = ClassColors[class] or ColorDefault
		self:SetColor( color )
		if self.shieldDisplay then
			UpdateShieldColor(self, color)
		end
	end

	local function UpdateValue(self)
		local u = self.unit
		local m = UnitHealthMax(u)
		if m==0 then m = 1 end
		local v = UnitHealth(u)/m
		self:SetValue(v)
		if self.shieldDisplay then
			UpdateShieldValue(self, u, v, m)
		end
	end

	local function UpdateDB(self)
		self.shieldDisplay = self.db.shieldDisplay
	end

	local embed = { UpdateDB = UpdateDB, UpdateValue = UpdateValue }

	addon.setupFunc['health'] = function(db)
		local self = Bar_Create(db, embed)
		self:Show()
		if self.db.shieldDisplay then
			local tex = Texture_Create(self, 'ARTWORK')
			tex:SetTexture(addon.db.texfg)
			tex:SetPoint('BOTTOMLEFT',  self.textures[1], 'TOPLEFT')
			tex:SetPoint('BOTTOMRIGHT', self.textures[1], 'TOPRIGHT')
			tex:SetHeight(0)
			tex:SetVertexColor(1,1,1,.5)
			tex:Hide()
			self.textures[2] = tex
			self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", db.unit)
			self.UNIT_ABSORB_AMOUNT_CHANGED = UpdateValue
		end
		if db.colorType == 'class' then
			self.UpdateColor = UpdateClassColor
		elseif db.colorType == 'reaction' then
			self.UpdateColor = UpdateReactionColor
		else
			self.UpdateColor = UpdateColor
		end
		self:SetScript("OnEvent", OnEvent)
		self:RegisterUnitEvent("UNIT_HEALTH", db.unit)
		self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", db.unit)
		self:RegisterUnitEvent("UNIT_MAXHEALTH", db.unit)
		if db.unit == 'target' then
			self.PLAYER_TARGET_CHANGED = self.Update
			self:RegisterEvent( "PLAYER_TARGET_CHANGED" )
		elseif db.unit == 'focus' then
			self.PLAYER_FOCUS_CHANGED = self.Update
			self:RegisterEvent( "PLAYER_FOCUS_CHANGED" )
		elseif db.unit == 'pet' then
			self.UNIT_PET = self.Update
			self:RegisterUnitEvent( "UNIT_PET", 'player' )
		end
		self.UNIT_HEALTH = self.UpdateValue
		self.UNIT_HEALTH_FREQUENT = self.UpdateValue
		self.UNIT_MAXHEALTH = self.UpdateValue
		self:Update()
		return self
	end
end

--====================================================================
-- My Shields Bar
--====================================================================

if isRetail then
	local UnitHealthMax = UnitHealthMax
	local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

	local function UpdateValue(self)
		local m = UnitHealthMax('player') or 0
		local a = UnitGetTotalAbsorbs('player') or 0
		if a>m then	a = m end
		self:SetValue(m>0 and a/m or 0)
	end

	local embed = { UpdateValue = UpdateValue }

	addon.setupFunc['myshields'] = function(db)
		local self = Bar_Create(db, embed)
		self:Show()
		self:SetScript("OnEvent", UpdateValue)
		self:RegisterUnitEvent("UNIT_MAXHEALTH", 'player')
		self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", 'player')
		self:Update()
		return self
	end
end

--====================================================================
-- Cast Bar
--====================================================================

do
	local max = max
	local GetTime = GetTime
	local UnitCastingInfo = UnitCastingInfo
	local UnitChannelInfo = UnitChannelInfo

	local function OnUpdate(self,elapsed)
		local dur = self.dur + elapsed
		if dur>=self.max then self:Hide(); return end
		self.dur = dur
		local value = dur / self.maxa
		local tex = self.textures[1]
		tex:SetHeight( self.height * value )
		tex:SetTexCoord( self.coord1, self.coord2, 1-value, 1 )
	end

	local function CastStart(self, event, unit)
		local name, _, _, start, finish, _, castID = UnitCastingInfo(unit)
		if name then
			self.castID = castID
			self.dur    = max( GetTime() - start/1000 , 0 )
			self.max    = (finish - start) / 1000
			self.maxa   = self.max * self.margin
			self:Show()
		else
			self:Hide()
		end
	end

	local function ChannelStart(self, event, unit)
		local name, _, _, start, finish = UnitChannelInfo(unit)
		if name then
			self.castID = nil
			self.dur    = max( GetTime() - start/1000 , 0 )
			self.max    = (finish - start) / 1000
			self.maxa   = self.max * self.margin
			self:Show()
		else
			self:Hide()
		end
	end

	local function CastStop(self, event, unit, castID)
		if castID == self.castID then
			self:Hide()
		end
	end

	addon.setupFunc['cast'] = function(db)
		local self = Bar_Create(db)
		self.textures[1]:Show()
		self:SetScript("OnUpdate", OnUpdate)
		self:SetScript("OnEvent", OnEvent)
		self:RegisterUnitEvent("UNIT_SPELLCAST_START", db.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", db.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", db.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", db.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", db.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", db.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", db.unit)


		self.UNIT_SPELLCAST_START = CastStart
		self.UNIT_SPELLCAST_DELAYED = CastStart
		self.UNIT_SPELLCAST_FAILED = CastStop
		self.UNIT_SPELLCAST_STOP = CastStop
		self.UNIT_SPELLCAST_INTERRUPTED = CastStop
		self.UNIT_SPELLCAST_CHANNEL_STOP = CastStop
		self.UNIT_SPELLCAST_CHANNEL_INTERRUPTED = CastStop
		self.UNIT_SPELLCAST_CHANNEL_START = ChannelStart
		self.UNIT_SPELLCAST_CHANNEL_UPDATE = ChannelStart
		return self
	end
end

--====================================================================
-- GCD Bar
--====================================================================

do
	local GetTime = GetTime
	local GetSpellCooldown = GetSpellCooldown

	local function Layout(self)
		self.prototype.Layout(self)
		self.hideOnCast = self.db.hideOnCast
		self.invert = self.db.invert
		if self.invert then
			local tex = self.textures[1]
			tex:ClearAllPoints()
			tex:SetPoint('TOPLEFT')
			tex:SetPoint('TOPRIGHT')
		end
	end

	local function OnUpdate(self,elapsed)
		local dur = self.dur - elapsed
		if dur<=0 then self:Hide(); return end
		self.dur = dur
		local value = dur / self.max
		local tex = self.textures[1]
		tex:SetHeight( self.height * value )
		if self.invert then
			tex:SetTexCoord( self.coord1, self.coord2, 0, value )
		else
			tex:SetTexCoord( self.coord1, self.coord2, 1-value, 1 )
		end
	end

	local function CastStart(self, event, unit, guid, spellID)
		if event ~= 'UNIT_SPELLCAST_INTERRUPTED' and not (self.hideOnCast and (event == "UNIT_SPELLCAST_START" or UnitChannelInfo('player'))) then
			local start, duration = GetSpellCooldown( isRetail and 61304 or spellID )
			if duration>0 and (isRetail or duration<=1.51) then
				self.dur = duration - (GetTime() - start)
				self.max = duration
				self:Show()
			end
		elseif self:IsVisible() then
			self:Hide()
		end
	end

	local embed = { Layout = Layout }

	addon.setupFunc['gcd'] = function(db)
		local self = Bar_Create(db, embed )
		self.textures[1]:Show()
		self:SetScript("OnUpdate", OnUpdate)
		self:SetScript("OnEvent", CastStart)
		self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
		self.Layout = Layout
		return self
	end
end

--====================================================================
-- Range Text
--====================================================================

do
	local Ranges
	local UnitIsFriend = UnitIsFriend
	local IsItemInRange = IsItemInRange
	if isRetail then
		Ranges = {
			[false] = { -- hostile
				37727, 63427, 34368, 32321, 33069, 10645, 31463, 835, 18904, 28767, 32698, 116139, 32825, 41265, 35278, 33119,
				[37727] = 5,  -- Ruby Acorn
				[63427] = 6,  -- Worgsaw
				[34368] = 8,  -- Attuned Crystal Cores
				[32321] = 10, -- Sparrowhawk Net
				[33069] = 15, -- Sturdy Rope
				[10645] = 20, -- Gnomish Death Ray
				[31463] = 25, -- Zezzak's Shard
				[835]   = 30, -- Large Rope Net
				[18904] = 35, -- Zorbin's Ultra-Shrinker
				[28767] = 40, -- The Decapitator
				[32698] = 45, -- Wrangling Rope
				[116139]= 50, -- Haunting Memento
				[32825] = 60, -- Soul Cannon
				[41265] = 70, -- Eyesore Blaster
				[35278] = 80, -- Reinforced Net
				[33119] = 100,-- Malister's Frost Wand
			},
			[true] = { -- friendly
				37727, 33278, 32321, 1251, 21519, 31463, 1180, 18904, 34471, 32698, 32825, 35278,
				[37727]= 5 , -- Ruby Acorn
				[33278]= 8 , -- Burning Torch
				[32321]= 10, -- Sparrowhawk Net
				[1251 ]= 15, -- Linen Bandage
				[21519]= 20, -- Mistletoe
				[31463]= 25, -- Zezzak's Shard
				[1180 ]= 30, -- Scroll of Stamina
				[18904]= 35, -- Zorbin's Ultra-Shrinker
				[34471]= 40, -- Vial of the Sunwell
				[32698]= 45, -- Wrangling Rope
				[32825]= 60, -- Soul Cannon
				[35278]= 80, -- Reinforced Net
			},
		}
	else
		Ranges = {
			[false] = { -- hostile
				9618, 10645, 835, 18904, -- 23721,
				[9618]  = 10, -- Vasija de lechucico muisek
				[10645] = 20, -- Gnomish Death Ray
				[835]   = 30, -- Large Rope Net
				[18904] = 35, -- Zorbin's Ultra-Shrinker
				-- [23721] = 100 -- Chicle permanente de mollejas
			},
			[true] = { -- friendly
				20403, 17689, 1251, 21519, 1180, 18904, 1184,
				[20403] =  5, -- Poder de Nozdormu
				[17689] = 10, -- Collar de entrenamiento de pico tormenta
				[1251 ] = 15, -- Linen Bandage
				[21519] = 20, -- Mistletoe
				[1180 ] = 30, -- Scroll of Stamina
				[18904] = 35, -- Zorbin's Ultra-Shrinker
				[1184 ] = 40, -- Deprecated Scarlet Badge
			},
		}
	end

	local function Destroy(self)
		Font_Release(self.Text)
		Frame_Release(self)
	end

	local function Update(self)
		local ranges = Ranges[ UnitIsFriend('player','target') ]
		local from, to
		for i=1,#ranges do
			to = ranges[i]
			if IsItemInRange(to, 'target') then break end
			from, to = to, nil
		end
		if to then
			self.Text:SetFormattedText( '%d-%d', ranges[from] or 0, ranges[to] )
		else
			self.Text:SetFormattedText( '%d+', ranges[from] or 100 )
		end
	end

	local function Refresh(self)
		if UnitExists('target') and not UnitIsUnit('target','player') then
			Update(self)
			self.timer:Play()
			self:Show()
		else
			self.timer:Stop()
			self:Hide()
		end
	end

	local function Layout(self)
		self.Text:ClearAllPoints()
		self.Text:SetPoint( self.db.textAlign or 'CENTER', UIParent, 'CENTER', self.db.textOffsetX, self.db.textOffsetY )
		self.Text:SetFont( Media:Fetch('font', self.db.textFont) or STANDARD_TEXT_FONT, self.db.textFontSize or 14, 'OUTLINE' )
		self.Text:SetTextColor( unpack(self.db.textColor or ColorDefault) )
	end

	local function UpdateDB()
	end

	local embed = { Destroy = Destroy, Update = Update, Layout = Layout, UpdateDB = UpdateDB }

	addon.setupFunc['range'] = function(db)
		local self = Frame_Create('range')
		self.db = db
		Embed(self, embed)
		-- timer
		local timer = self.timer or self:CreateAnimationGroup()
		timer.animation = timer.animation or timer:CreateAnimation()
		timer:SetLooping("REPEAT")
		timer.animation:SetDuration(.1)
		timer:SetScript("OnLoop", Update)
		timer:Play()
		self.timer = timer
		-- text
		local text = Font_Create(self,'ARTWORK')
		text:SetShadowOffset(1,-1)
		text:SetShadowColor(0,0,0, 1)
		text:Show()
		self.Text = text
		self.timer.Text = text
		-- events
		self:RegisterEvent( "PLAYER_TARGET_CHANGED" )
		self:SetScript("OnEvent", Refresh)
		Layout(self)
		Refresh(self)
		self:Show()
		return self
	end
end

--====================================================================

function addon:CreateBars()
	for i,cfg in ipairs(self.db.bars) do
		self.bars[i] = addon.setupFunc[cfg.type](cfg)
	end
end

function addon:LayoutBars()
	for _,bar in ipairs(self.bars) do
		bar:UpdateDB()
		bar:Layout()
		bar:Update()
	end
end

function addon:DestroyBars()
	for _,bar in ipairs(self.bars) do
		bar:Destroy()
	end
	wipe(self.bars)
end


function addon:RecreateBar(index)
	self:DestroyBar(index)
	self:CreateBar(index)
end

function addon:CreateBar(index)
	local db = self.db.bars[index]
	self.bars[index] = addon.setupFunc[db.type](db)
end

function addon:LayoutBar(index)
	local bar = self.bars[index]
	bar:UpdateDB()
	bar:Layout()
	bar:Update()
end

function addon:DestroyBar(index)
	tremove(self.bars, index):Destroy()
end

--====================================================================

function addon:OnProfileChanged()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(addon.addonName)
	self:DestroyBars()
	self:Update()
	self:CreateBars()
	self:RefreshOptions()
end

--====================================================================

function addon:Update()
	InCombat = InCombatLockdown()
	AlphaCombat = InCombat and (self.db.alphaCombat or 1) or (self.db.alphaOOC or .5)
	FillColorsTable( ReactionColors, REACTION_COLORS, self.db.reactionColors )
	FillColorsTable( ClassColors, RAID_CLASS_COLORS, self.db.classColors )
	FillColorsTable( PowerColors, PowerBarColor,  self.db.powerColors )
	FillColorsTable( SchoolColors, SCHOOL_COLORS,  self.db.schoolColors )
end

--====================================================================

function addon:Initialize()
	self.bars = {}
	self:Update()
	self:CreateBars()
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	-- self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self.Initialize = nil
end

--====================================================================

addon.Bar_Create = Bar_Create
addon.Texture_Create = Texture_Create
addon.ClassColors = ClassColors
addon.PowerColors = PowerColors
addon.ReactionColors = ReactionColors
addon.REACTION_COLORS = REACTION_COLORS
addon.SchoolColors = SchoolColors
addon.SCHOOL_COLORS = SCHOOL_COLORS

--====================================================================
