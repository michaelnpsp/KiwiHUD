--=========================================

local addon = _G[(...)]

if not addon.isClassic then return end

local min = min
local max = max
local pairs = pairs
local ipairs = ipairs
local unpack = unpack
local UnitHealthMax = UnitHealthMax
local GetSpellBonusHealing = GetSpellBonusHealing

--=========================================

local RegisterCallback, UnregisterCallback, GetPlayerAbsorbValues
do
	local updates = {} -- registered callback objects&methods for updates
	local absorbCnt = 0 -- number of non-zero values in absorbSch table
	local absorbCurTot = 0 -- total absorbs
	local absorbMaxTot = 0 -- max total absorbs
	local absorbMax = {} -- absorbMax[spellName] = max absorb value
	local absorbCur = {} -- absorbCur[spellName] = absorb value
	local absorbIdx = {} -- absorbIdx[spellName] = schoolIndex in absorbSch table
	local absorbSch = { 0,0,0,0,0,0,0,0,0 }

	local InitAbsorbData, CalcAbsorbValue
	do
		-- school(1), basePoints(2), pointsPerLevel(3), baseLevel(4), maxLevel(5), spellLevel(6), healingMultiplier(7), talentMult(8), healingMultiplierTot[9], baseAbsorb[10]
		local absorbDb = {
			[  7848] = {   1,    49,    0,  0,  0,  0, 0  , 1}, -- Absorption
			[ 25750] = {   1,   247,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 25747] = {   1,   309,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 25746] = {   1,   391,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 23991] = {   1,   494,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 11657] = {   1,    54,    0, 48,  0, 48, 0  , 1}, -- Jang'thraze
			[  7447] = {   1,    24,    0,  0,  0,  0, 0  , 1}, -- Lesser Absorption
			[  8373] = {   1,   999,    0,  0,  0,  0, 0  , 1}, -- Mana Shield (PT)
			[  7423] = {   1,     9,    0,  0,  0,  0, 0  , 1}, -- Minor Absorption
			[  3288] = {   1,    19,    0, 21,  0, 21, 0  , 1}, -- Moss Hide
			[ 21956] = {   1,   349,    0, 20,  0,  0, 0  , 1}, -- Physical Protection
			[  7245] = {   2,   299,    0, 20,  0,  0, 0  , 1}, -- Holy Protection (Rank 1)
			[ 16892] = {   2,   299,    0, 20,  0,  0, 0  , 1}, -- Holy Protection (Rank 1)
			[  7246] = {   2,   524,    0, 25,  0,  0, 0  , 1}, -- Holy Protection (Rank 2)
			[  7247] = {   2,   674,    0, 30,  0,  0, 0  , 1}, -- Holy Protection (Rank 3)
			[  7248] = {   2,   974,    0, 35,  0,  0, 0  , 1}, -- Holy Protection (Rank 4)
			[  7249] = {   2,  1349,    0, 40,  0,  0, 0  , 1}, -- Holy Protection (Rank 5)
			[ 17545] = {   2,  1949,    0, 40,  0,  0, 0  , 1}, -- Holy Protection (Rank 6)
			[ 27536] = {   2,   299,    0, 60,  0,  0, 0  , 1}, -- Holy Resistance
			[ 29432] = {   4,  1499,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[ 17543] = {   4,  1949,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[ 18942] = {   4,  1949,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[  7230] = {   4,   299,    0, 20,  0,  0, 0  , 1}, -- Fire Protection (Rank 1)
			[ 12561] = {   4,   299,    0, 20,  0,  0, 0  , 1}, -- Fire Protection (Rank 1)
			[  7231] = {   4,   524,    0, 25,  0,  0, 0  , 1}, -- Fire Protection (Rank 2)
			[  7232] = {   4,   674,    0, 30,  0,  0, 0  , 1}, -- Fire Protection (Rank 3)
			[  7233] = {   4,   974,    0, 35,  0,  0, 0  , 1}, -- Fire Protection (Rank 4)
			[ 16894] = {   4,   974,    0, 35,  0,  0, 0  , 1}, -- Fire Protection (Rank 4)
			[  7234] = {   4,  1349,    0, 35,  0,  0, 0  , 1}, -- Fire Protection (Rank 5)
			[ 27533] = {   4,   299,    0, 60,  0,  0, 0  , 1}, -- Fire Resistance
			[  4057] = {   4,   499,    0,  0,  0, 25, 0  , 1}, -- Fire Resistance
			[ 17546] = {   8,  1949,    0, 40,  0,  0, 0  , 1}, -- Nature Protection
			[  7250] = {   8,   299,    0, 20,  0,  0, 0  , 1}, -- Nature Protection (Rank 1)
			[  7251] = {   8,   524,    0, 25,  0,  0, 0  , 1}, -- Nature Protection (Rank 2)
			[  7252] = {   8,   674,    0, 30,  0,  0, 0  , 1}, -- Nature Protection (Rank 3)
			[  7253] = {   8,   974,    0, 35,  0,  0, 0  , 1}, -- Nature Protection (Rank 4)
			[  7254] = {   8,  1349,    0, 40,  0,  0, 0  , 1}, -- Nature Protection (Rank 5)
			[ 16893] = {   8,  1349,    0, 40,  0,  0, 0  , 1}, -- Nature Protection (Rank 5)
			[ 27538] = {   8,   299,    0, 60,  0,  0, 0  , 1}, -- Nature Resistance
			[ 17544] = {  16,  1949,    0, 40,  0,  0, 0  , 1}, -- Frost Protection
			[  7240] = {  16,   299,    0, 20,  0,  0, 0  , 1}, -- Frost Protection (Rank 1)
			[  7236] = {  16,   524,    0, 25,  0,  0, 0  , 1}, -- Frost Protection (Rank 2)
			[  7238] = {  16,   674,    0, 30,  0,  0, 0  , 1}, -- Frost Protection (Rank 3)
			[  7237] = {  16,   974,    0, 35,  0,  0, 0  , 1}, -- Frost Protection (Rank 4)
			[  7239] = {  16,  1349,    0, 40,  0,  0, 0  , 1}, -- Frost Protection (Rank 5)
			[ 16895] = {  16,  1349,    0, 40,  0,  0, 0  , 1}, -- Frost Protection (Rank 5)
			[ 27534] = {  16,   299,    0, 60,  0,  0, 0  , 1}, -- Frost Resistance
			[  4077] = {  16,   599,    0,  0,  0, 25, 0  , 1}, -- Frost Resistance
			[ 17548] = {  32,  1949,    0, 40,  0,  0, 0  , 1}, -- Shadow Protection
			[  7235] = {  32,   299,    0, 20,  0,  0, 0  , 1}, -- Shadow Protection (Rank 1)
			[  7241] = {  32,   524,    0, 25,  0,  0, 0  , 1}, -- Shadow Protection (Rank 2)
			[  7242] = {  32,   674,    0, 30,  0,  0, 0  , 1}, -- Shadow Protection (Rank 3)
			[ 16891] = {  32,   674,    0, 30,  0,  0, 0  , 1}, -- Shadow Protection (Rank 3)
			[  7243] = {  32,   974,    0, 35,  0,  0, 0  , 1}, -- Shadow Protection (Rank 4)
			[  7244] = {  32,  1349,    0, 40,  0,  0, 0  , 1}, -- Shadow Protection (Rank 5)
			[ 27535] = {  32,   299,    0, 60,  0,  0, 0  , 1}, -- Shadow Resistance
			[  6229] = {  32,   289,    0, 32,  0, 32, 0  , 1}, -- Shadow Ward (Rank 1)
			[ 11739] = {  32,   469,    0, 42,  0, 42, 0  , 1}, -- Shadow Ward (Rank 2)
			[ 11740] = {  32,   674,    0, 52,  0, 52, 0  , 1}, -- Shadow Ward (Rank 3)
			[ 28610] = {  32,   919,    0, 60,  0, 60, 0  , 1}, -- Shadow Ward (Rank 4)
			[ 17549] = {  64,  1949,    0, 35,  0,  0, 0  , 1}, -- Arcane Protection
			[ 27540] = {  64,   299,    0, 60,  0,  0, 0  , 1}, -- Arcane Resistance
			[ 10618] = { 126,   599,    0, 30,  0,  0, 0  , 1}, -- Elemental Protection
			[ 20620] = { 127, 29999,    0, 20,  0, 20, 0  , 1}, -- Aegis of Ragnaros
			[ 23506] = { 127,   749,    0, 20,  0,  0, 0  , 1}, -- Aura of Protection
			[ 11445] = { 127,   277,    0, 35,  0, 35, 0  , 1}, -- Bone Armor
			[ 16431] = { 127,  1387,    0, 55,  0, 55, 0  , 1}, -- Bone Armor
			[ 27688] = { 127,  2499,    0,  0,  0,  0, 0  , 1}, -- Bone Shield
			[ 13234] = { 127,   499,    0,  0,  0,  0, 0  , 1}, -- Harm Prevention Belt
			[  9800] = { 127,   174,    0, 52,  0,  0, 0  , 1}, -- Holy Shield
			[ 17252] = { 127,   499,    0,  0,  0,  0, 0  , 1}, -- Mark of the Dragon Lord
			[ 11835] = { 127,   115,    0, 20,  0, 20, 0.1, 1}, -- Power Word: Shield
			[ 11974] = { 127,   136, 6.85, 20,  0, 20, 0.1, 1}, -- Power Word: Shield
			[ 22187] = { 127,   205, 10.2, 20,  0, 20, 0.1, 1}, -- Power Word: Shield
			[ 17139] = { 127,   273, 13.7, 20,  0, 20, 0.1, 1}, -- Power Word: Shield
			[ 11647] = { 127,   780,  3.9, 54, 59,  1, 0.1, 1}, -- Power Word: Shield
			[ 20697] = { 127,  4999,    0,  0,  0,  0, 0.1, 1}, -- Power Word: Shield
			[ 12040] = { 127,   199,   10, 20,  0, 20, 0  , 1}, -- Shadow Shield
			[ 22417] = { 127,   399,   20, 20,  0, 20, 0  , 1}, -- Shadow Shield
			[ 27759] = { 127,    49,    0,  0,  0,  0, 0  , 1}, -- Shield Generator
			[ 29506] = { 127,   899,    0, 20,  0,  0, 0  , 1}, -- The Burrower's Shell
			[ 10368] = { 127,   199,  2.3, 30, 35, 30, 0  , 1}, -- Uther's Light Effect (Rank 1)
			[ 28810] = { 127,   499,    0,  0,  0,  1, 0  , 1}, -- [Priest] Armor of Faith
			[ 27779] = { 127,   349,  2.3,  0,  0,  0, 0  , 1}, -- [Priest] Divine Protection
			[    17] = { 127,    43,  0.8,  6, 11,  6, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 1)
			[ 10901] = { 127,   941,  4.3, 60, 65, 60, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 10)
			[ 27607] = { 127,   941,  4.3, 60, 65, 60, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 10)
			[   592] = { 127,    87,  1.2, 12, 17, 12, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 2)
			[   600] = { 127,   157,  1.6, 18, 23, 18, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 3)
			[  3747] = { 127,   233,    2, 24, 29, 24, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 4)
			[  6065] = { 127,   300,  2.3, 30, 35, 30, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 5)
			[  6066] = { 127,   380,  2.6, 36, 41, 36, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 6)
			[ 10898] = { 127,   483,    3, 42, 47, 42, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 7)
			[ 10899] = { 127,   604,  3.4, 48, 53, 48, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 8)
			[ 10900] = { 127,   762,  3.9, 54, 59, 54, 0.1, 1.15}, -- [Priest] Power Word: Shield (Rank 9)
			[ 20706] = { 127,   499,    3, 42, 47, 42, 0  , 1.15}, -- [Priest] Power Word: Shield 500 (Rank 7)
			[ 17740] = {   1,   119,    6, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 17741] = {   1,   119,    6, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[  1463] = {   1,   119,    0, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield (Rank 1)
			[  8494] = {   1,   209,    0, 28,  0, 28, 0  , 1}, -- [Mage] Mana Shield (Rank 2)
			[  8495] = {   1,   299,    0, 36,  0, 36, 0  , 1}, -- [Mage] Mana Shield (Rank 3)
			[ 10191] = {   1,   389,    0, 44,  0, 44, 0  , 1}, -- [Mage] Mana Shield (Rank 4)
			[ 10192] = {   1,   479,    0, 52,  0, 52, 0  , 1}, -- [Mage] Mana Shield (Rank 5)
			[ 10193] = {   1,   569,    0, 60,  0, 60, 0  , 1}, -- [Mage] Mana Shield (Rank 6)
			[ 15041] = {   4,   119,    0, 20,  0, 20, 0  , 1}, -- [Mage] Fire Ward
			[   543] = {   4,   164,    0, 20,  0, 20, 0  , 1}, -- [Mage] Fire Ward (Rank 1)
			[  8457] = {   4,   289,    0, 30,  0, 30, 0  , 1}, -- [Mage] Fire Ward (Rank 2)
			[  8458] = {   4,   469,    0, 40,  0, 40, 0  , 1}, -- [Mage] Fire Ward (Rank 3)
			[ 10223] = {   4,   674,    0, 50,  0, 50, 0  , 1}, -- [Mage] Fire Ward (Rank 4)
			[ 10225] = {   4,   919,    0, 60,  0, 60, 0  , 1}, -- [Mage] Fire Ward (Rank 5)
			[ 15044] = {  16,   119,    0, 20,  0, 20, 0  , 1}, -- [Mage] Frost Ward
			[  6143] = {  16,   164,    0, 22,  0, 22, 0  , 1}, -- [Mage] Frost Ward (Rank 1)
			[  8461] = {  16,   289,    0, 32,  0, 32, 0  , 1}, -- [Mage] Frost Ward (Rank 2)
			[  8462] = {  16,   469,    0, 42,  0, 42, 0  , 1}, -- [Mage] Frost Ward (Rank 3)
			[ 10177] = {  16,   674,    0, 52,  0, 52, 0  , 1}, -- [Mage] Frost Ward (Rank 4)
			[ 28609] = {  16,   919,    0, 60,  0, 60, 0  , 1}, -- [Mage] Frost Ward (Rank 5)
			[ 11426] = { 127,   437,  2.8, 40, 46, 40, 0.1, 1}, -- [Mage] Ice Barrier (Rank 1)
			[ 13031] = { 127,   548,  3.2, 46, 52, 46, 0.1, 1}, -- [Mage] Ice Barrier (Rank 2)
			[ 13032] = { 127,   677,  3.6, 52, 58, 52, 0.1, 1}, -- [Mage] Ice Barrier (Rank 3)
			[ 13033] = { 127,   817,    4, 58, 64, 58, 0.1, 1}, -- [Mage] Ice Barrier (Rank 4)
			[ 26470] = { 127,     0,    0,  0,  0,  1, 0  , 1}, -- [Mage] Persistent Shield
			[ 17729] = { 126,   649,    0, 48,  0, 48, 0  , 1}, -- [Warlock] Greater Spellstone
			[ 17730] = { 126,   899,    0, 60,  0, 60, 0  , 1}, -- [Warlock] Major Spellstone
			[   128] = { 126,   399,    0, 36,  0, 36, 0  , 1}, -- [Warlock] Spellstone
			[  7812] = { 127,   304,  2.3, 16, 22, 16, 0  , 1}, -- [Warlock] Sacrifice (Rank 1)
			[ 19438] = { 127,   509,  3.1, 24, 30, 24, 0  , 1}, -- [Warlock] Sacrifice (Rank 2)
			[ 19440] = { 127,   769,  3.9, 32, 38, 32, 0  , 1}, -- [Warlock] Sacrifice (Rank 3)
			[ 19441] = { 127,  1094,  4.7, 40, 46, 40, 0  , 1}, -- [Warlock] Sacrifice (Rank 4)
			[ 19442] = { 127,  1469,  5.5, 48, 54, 48, 0  , 1}, -- [Warlock] Sacrifice (Rank 5)
			[ 19443] = { 127,  1904,  6.4, 56, 62, 56, 0  , 1}, -- [Warlock] Sacrifice (Rank 6)
		}
		function CalcAbsorbValue(spellId)
			if spellId then
				local data = absorbDb[spellId]
				if data then
					return data[10] + data[9] * GetSpellBonusHealing()
				end
			end
		end
		-- spell schools: All(1), Physical(2), Magic(3), Holy(4), Fire(5), Nature(6), Frost(7), Shadow(8), Arcane(9)
		local schoolIdx = { [127]=1, [1]=2, [126]=3, [2]=4, [4]=5, [8]=6, [16]=7, [32]=8, [64]=9 }
		function InitAbsorbData()
			local level = UnitLevel('player')
			for spellId, data in pairs(absorbDb) do
				data[ 9] = data[7] * min(1, 1 - (20 - data[6]) * .0375) -- healingMultiplierTot
				data[10] = data[8] * ( data[2] + max(0,min(level,data[5])-data[4]) * data[3] ) -- baseAbsorb
				absorbIdx[GetSpellInfo(spellId)] = schoolIdx[ data[1] ]
			end
		end
	end

	local function UpdateValues(noNotify)
		local curPrev = absorbCurTot
		local maxPrev = absorbMaxTot
		if absorbCnt>0 then
			for i=1,#absorbSch do
				absorbSch[i] = 0
			end
		end
		absorbCurTot, absorbMaxTot, absorbCnt = 0, 0, 0
		for spellName,value in pairs(absorbCur) do
			if value>0 then
				local idx  = absorbIdx[spellName]
				local prev = absorbSch[idx]
				absorbSch[idx] = prev + value
				absorbCurTot = absorbCurTot + value
				absorbMaxTot = absorbMaxTot + absorbMax[spellName]
				if prev==0 then absorbCnt = absorbCnt + 1 end
			end
		end
		if absorbCurTot<curPrev then
			absorbMaxTot = maxPrev
		end
		if not noNotify then
			for obj,func in pairs(updates) do
				func(obj)
			end
		end
	end

	local ApplyAura, ResetValues
	do
		local UnitBuff = UnitBuff
		local function GetBuffSpellId(spellName)
			for i=1,40 do
				local name, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
				if (not name) or name==spellName then return spellId end
			end
		end
		function ApplyAura(spellName, noUpdate)
			if absorbIdx[spellName] then
				local value = CalcAbsorbValue( GetBuffSpellId(spellName) )
				if value then
					local valuePrev = absorbCur[spellName] or 0
					if valuePrev>=0 then
						absorbCur[spellName] = value
					else
						absorbCur[spellName] = value + valuePrev -- If absorb damage event happened before aura was applied
					end
					absorbMax[spellName] = value
					if not noUpdate then UpdateValues() end
				end
			end
		end
		function ResetValues(noNotify)
			wipe(absorbCur)
			for i = 1, 64 do
				local spellName = UnitBuff("player", i)
				if not spellName then break end
				ApplyAura(spellName, true)
			end
			UpdateValues(noNotify)
		end
	end

	local CleuEvent
	do
		local select = select
		local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
		local playerGUID = UnitGUID("player")
		local events = {
			SPELL_AURA_APPLIED = function(...)
				ApplyAura( (select(13, ...)) )
			end,
			SPELL_AURA_REFRESH = function(...)
				ApplyAura( (select(13, ...)) )
			end,
			SPELL_AURA_REMOVED = function(...)
				local spellName = select(13, ...)
				if absorbCur[spellName] then
					absorbCur[spellName] = nil
					absorbMax[spellName] = nil
					UpdateValues()
				end
			end,
			SPELL_ABSORBED = function(...)
				local spellName, value
				if select(20, ...) then
					spellName = select(20, ...)
					value = (absorbCur[spellName] or 0) - (select(22, ...) or 0)
				else
					spellName = select(17, ...)
					value = (absorbCur[spellName] or 0) - (select(19, ...) or 0)
				end
				absorbCur[spellName] = value
				if value>=0 then -- negative value if damage happens before aura applied, avoid update and next cleu SPELL_AURA_APPLIED event must fix the negative value
					UpdateValues()
				end
			end,
		}
		function CleuEvent()
			local _, eventType,_,_,_,_,_,dstGUID = CombatLogGetCurrentEventInfo()
			if playerGUID == dstGUID then
				local func = events[ eventType ]
				if func then func( CombatLogGetCurrentEventInfo() ) end
			end
		end
	end

	local RegisterEvents, UnregisterEvents
	do
		local frame
		function RegisterEvents()
			if not frame then
				InitAbsorbData()
				frame = CreateFrame('Frame')
			end
			frame:SetScript("OnEvent", CleuEvent)
			frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			ResetValues(true)
		end
		function UnregisterEvents()
			frame:SetScript("OnEvent", nil)
			frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end

	-- public functions

	function RegisterCallback(obj, func)
		if not next(updates) then RegisterEvents() end
		updates[obj] = func
	end

	function UnregisterCallback(obj)
		updates[obj] = nil
		if not next(updates) then UnregisterEvents() end
	end

	function GetPlayerAbsorbValues()
		return absorbCnt, absorbSch, absorbCurTot, absorbMaxTot
	end

end

--=================================================================

local school_colors = addon.SchoolColors

local function CreateTexture(self,index)
	local tex = addon.Texture_Create(self, 'ARTWORK')
	tex:SetTexture(addon.db.texfg)
	tex:SetPoint('BOTTOMLEFT',  self.textures[index-1], 'TOPLEFT')
	tex:SetPoint('BOTTOMRIGHT', self.textures[index-1], 'TOPRIGHT')
	self.textures[index] = tex
	return tex
end

local function UpdateTexture(self, index, valueFrom , value, valueMax, schoolIndex)
	local tex = self.textures[index] or CreateTexture(self,index, schoolIndex)
	local valueTo = min( 1, valueFrom + value/valueMax )
	tex:SetTexCoord( self.coord1, self.coord2, 1-valueTo, 1-valueFrom)
	tex:SetHeight( self.height * (valueTo-valueFrom) )
	tex:SetVertexColor( unpack(school_colors[schoolIndex]) )
	tex:Show()
	return valueTo
end

local function UpdateValue(self)
	local idx = 0
	local count, absorbs, total, maxTotal = GetPlayerAbsorbValues()
	if count>0 then
		local valuePrev = 0
		local valueMax  = self.db.shieldMax and maxTotal or UnitHealthMax('player') or 1
		for i,value in ipairs(absorbs) do
			if value>0 then
				idx = idx + 1
				valuePrev = UpdateTexture(self, idx, valuePrev, value, valueMax, i)
				if idx>=count or valuePrev>=1 then break end
			end
		end
	end
	if self.Text then
		if total>0 then
			self.Text:SetFormattedText("%.0f",total)
		else
			self.Text:SetText('')
		end
	end
    for i=idx+1,self.visibleTextureCount do
		self.textures[i]:Hide()
	end
	self.visibleTextureCount = idx
	self:UpdateVisibility(total)
	self.value = total
end

local function Destroy(self)
	UnregisterCallback(self)
	self:_Destroy()
end

local embed = { UpdateValue = UpdateValue }

addon.setupFunc['myshields'] = function(db)
	local self = addon.Bar_Create(db, embed)
	RegisterCallback(self,UpdateValue)
	self._Destroy, self.Destroy = self.Destroy, Destroy
	self.visibleTextureCount = 0
	self:Update()
	return self
end
