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
	local absorbIdx = {} -- absorbIdx[spellName] = schoolIndex in absorbSch table (static data)
	local absorbCnt = 0 -- number of non-zero values in absorbSch table
	local absorbCurTot = 0 -- total absorbs
	local absorbMaxTot = 0 -- max total absorbs
	local absorbMax = {} -- absorbMax[spellName] = max absorb value
	local absorbCur = {} -- absorbCur[spellName] = absorb value
	local absorbSch = { 0,0,0,0,0,0,0,0,0 }

	local InitAbsorbData, CalcAbsorbValue
	do
		-- school(1), basePoints(2), pointsPerLevel(3), baseLevel(4), maxLevel(5), spellLevel(6), healingMultiplier(7), talentMult(8), healingMultiplierTot[9], baseAbsorb[10]
		local absorbDb = {
			[  7848] = {   1,    49,    0,  0,  0,  0, 0  , 1}, -- Absorption
			[ 25750] = {   1,      -1,   0, 20,  0,  0,   0,  1}, -- Damage Absorb
			[ 25747] = {   1,   309,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 25746] = {   1,   391,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 23991] = {   1,   494,    0, 20,  0,  0, 0  , 1}, -- Damage Absorb
			[ 42137] = {   1,   399,    0,  0,  0,  0, 0  , 1}, -- Greater Rune of Warding
			[ 11657] = {   1,    54,    0, 48,  0, 48, 0  , 1}, -- Jang'thraze
			[  7447] = {   1,    24,    0,  0,  0,  0, 0  , 1}, -- Lesser Absorption
			[ 42134] = {   1,   199,    0,  0,  0,  0, 0  , 1}, -- Lesser Rune of Warding
			[  8373] = {   1,   999,    0,  0,  0,  0, 0  , 1}, -- Mana Shield (PT)
			[  7423] = {   1,     9,    0,  0,  0,  0, 0  , 1}, -- Minor Absorption
			[  3288] = {   1,    19,    0, 21,  0, 21, 0  , 1}, -- Moss Hide
			[ 21956] = {   1,     499,   0, 20,  0,  0,   0,  1}, -- Physical Protection
			[ 34206] = {   1,  1949,    0, 40,  0,  0, 0  , 1}, -- Physical Protection
			[ 37414] = {   1,   499,    0,  0,  0,  0, 0  , 1}, -- Shield Block
			[ 37729] = {   1,  1079,    0, 20,  0,  0, 0  , 1}, -- Unholy Armor
			[ 37416] = {   1,   499,    0,  0,  0,  0, 0  , 1}, -- Weapon Deflection
			[ 28538] = {   2,  2799,    0, 40,  0,  0, 0  , 1}, -- Holy Protection
			[  7245] = {   2,   299,    0, 20,  0,  0, 0  , 1}, -- Holy Protection (Rank 1)
			[ 16892] = {   2,   299,    0, 20,  0,  0, 0  , 1}, -- Holy Protection (Rank 1)
			[  7246] = {   2,   524,    0, 25,  0,  0, 0  , 1}, -- Holy Protection (Rank 2)
			[  7247] = {   2,   674,    0, 30,  0,  0, 0  , 1}, -- Holy Protection (Rank 3)
			[  7248] = {   2,   974,    0, 35,  0,  0, 0  , 1}, -- Holy Protection (Rank 4)
			[  7249] = {   2,  1349,    0, 40,  0,  0, 0  , 1}, -- Holy Protection (Rank 5)
			[ 17545] = {   2,  1949,    0, 40,  0,  0, 0  , 1}, -- Holy Protection (Rank 6)
			[ 27536] = {   2,   299,    0, 60,  0,  0, 0  , 1}, -- Holy Resistance
			[ 30997] = {   4,   899,    0, 40,  0,  0, 0  , 1}, -- Fire Absorption
			[ 29432] = {   4,  1499,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[ 17543] = {   4,  1949,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[ 18942] = {   4,  1949,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[ 28511] = {   4,  2799,    0, 35,  0,  0, 0  , 1}, -- Fire Protection
			[  7230] = {   4,   299,    0, 20,  0,  0, 0  , 1}, -- Fire Protection (Rank 1)
			[ 12561] = {   4,   299,    0, 20,  0,  0, 0  , 1}, -- Fire Protection (Rank 1)
			[  7231] = {   4,   524,    0, 25,  0,  0, 0  , 1}, -- Fire Protection (Rank 2)
			[  7232] = {   4,   674,    0, 30,  0,  0, 0  , 1}, -- Fire Protection (Rank 3)
			[  7233] = {   4,   974,    0, 35,  0,  0, 0  , 1}, -- Fire Protection (Rank 4)
			[ 16894] = {   4,   974,    0, 35,  0,  0, 0  , 1}, -- Fire Protection (Rank 4)
			[  7234] = {   4,  1349,    0, 35,  0,  0, 0  , 1}, -- Fire Protection (Rank 5)
			[ 27533] = {   4,   299,    0, 60,  0,  0, 0  , 1}, -- Fire Resistance
			[  4057] = {   4,   499,    0,  0,  0, 25, 0  , 1}, -- Fire Resistance
			[ 30999] = {   8,   899,    0, 40,  0,  0, 0  , 1}, -- Nature Absorption
			[ 17546] = {   8,  1949,    0, 40,  0,  0, 0  , 1}, -- Nature Protection
			[ 28513] = {   8,  2799,    0, 40,  0,  0, 0  , 1}, -- Nature Protection
			[  7250] = {   8,   299,    0, 20,  0,  0, 0  , 1}, -- Nature Protection (Rank 1)
			[  7251] = {   8,   524,    0, 25,  0,  0, 0  , 1}, -- Nature Protection (Rank 2)
			[  7252] = {   8,   674,    0, 30,  0,  0, 0  , 1}, -- Nature Protection (Rank 3)
			[  7253] = {   8,   974,    0, 35,  0,  0, 0  , 1}, -- Nature Protection (Rank 4)
			[  7254] = {   8,  1349,    0, 40,  0,  0, 0  , 1}, -- Nature Protection (Rank 5)
			[ 16893] = {   8,  1349,    0, 40,  0,  0, 0  , 1}, -- Nature Protection (Rank 5)
			[ 27538] = {   8,   299,    0, 60,  0,  0, 0  , 1}, -- Nature Resistance
			[ 30994] = {  16,   899,    0, 40,  0,  0, 0  , 1}, -- Frost Absorption
			[ 17544] = {  16,  1949,    0, 40,  0,  0, 0  , 1}, -- Frost Protection
			[ 28512] = {  16,  2799,    0, 40,  0,  0, 0  , 1}, -- Frost Protection
			[  7240] = {  16,   299,    0, 20,  0,  0, 0  , 1}, -- Frost Protection (Rank 1)
			[  7236] = {  16,   524,    0, 25,  0,  0, 0  , 1}, -- Frost Protection (Rank 2)
			[  7238] = {  16,   674,    0, 30,  0,  0, 0  , 1}, -- Frost Protection (Rank 3)
			[  7237] = {  16,   974,    0, 35,  0,  0, 0  , 1}, -- Frost Protection (Rank 4)
			[  7239] = {  16,  1349,    0, 40,  0,  0, 0  , 1}, -- Frost Protection (Rank 5)
			[ 16895] = {  16,  1349,    0, 40,  0,  0, 0  , 1}, -- Frost Protection (Rank 5)
			[ 27534] = {  16,   299,    0, 60,  0,  0, 0  , 1}, -- Frost Resistance
			[  4077] = {  16,   599,    0,  0,  0, 25, 0  , 1}, -- Frost Resistance
			[ 31000] = {  32,   899,    0, 40,  0,  0, 0  , 1}, -- Shadow Absorption
			[ 33482] = {  32,  2294,    0, 60,  0, 60, 0  , 1}, -- Shadow Defense
			[ 17548] = {  32,  1949,    0, 40,  0,  0, 0  , 1}, -- Shadow Protection
			[ 28537] = {  32,  2799,    0, 40,  0,  0, 0  , 1}, -- Shadow Protection
			[  7235] = {  32,   299,    0, 20,  0,  0, 0  , 1}, -- Shadow Protection (Rank 1)
			[  7241] = {  32,   524,    0, 25,  0,  0, 0  , 1}, -- Shadow Protection (Rank 2)
			[  7242] = {  32,   674,    0, 30,  0,  0, 0  , 1}, -- Shadow Protection (Rank 3)
			[ 16891] = {  32,   674,    0, 30,  0,  0, 0  , 1}, -- Shadow Protection (Rank 3)
			[  7243] = {  32,   974,    0, 35,  0,  0, 0  , 1}, -- Shadow Protection (Rank 4)
			[  7244] = {  32,  1349,    0, 40,  0,  0, 0  , 1}, -- Shadow Protection (Rank 5)
			[ 27535] = {  32,   299,    0, 60,  0,  0, 0  , 1}, -- Shadow Resistance
			[  6229] = {  32,   289,    0, 32, 41, 32, 0  , 1}, -- Shadow Ward (Rank 1)
			[ 11739] = {  32,   469,    0, 42, 51, 42, 0  , 1}, -- Shadow Ward (Rank 2)
			[ 11740] = {  32,   674,    0, 52, 59, 52, 0  , 1}, -- Shadow Ward (Rank 3)
			[ 28610] = {  32,   874,    0, 60, 69, 60, 0  , 1}, -- Shadow Ward (Rank 4)
			[ 40322] = {  32, 11399,    0, 70,  0, 70, 0  , 1}, -- Spirit Shield
			[ 31002] = {  64,   899,    0, 40,  0,  0, 0  , 1}, -- Arcane Absorption
			[ 17549] = {  64,  1949,    0, 35,  0,  0, 0  , 1}, -- Arcane Protection
			[ 28536] = {  64,  2799,    0, 35,  0,  0, 0  , 1}, -- Arcane Protection
			[ 27540] = {  64,   299,    0, 60,  0,  0, 0  , 1}, -- Arcane Resistance
			[ 31662] = { 126,199999,    0, 70,  0, 70, 0  , 1}, -- Anti-Magic Shell
			[ 10618] = { 126,   599,    0, 30,  0,  0, 0  , 1}, -- Elemental Protection
			[ 20620] = { 127, 29999,    0, 20,  0, 20, 0  , 1}, -- Aegis of Ragnaros
			[ 36481] = { 127, 99999,    0,  0,  0,  0, 0  , 1}, -- Arcane Barrier
			[ 39228] = { 127,  1149,    0,  0,  0,  1, 0  , 1}, -- Argussian Compass
			[ 23506] = { 127,   749,    0, 20,  0,  0, 0  , 1}, -- Aura of Protection
			[ 41341] = { 127,     0,    0,  0,  0,  0, 0  , 1}, -- Balance of Power
			[ 11445] = { 127,   277,    0, 35,  0, 35, 0  , 1}, -- Bone Armor
			[ 38882] = { 127,   878,    0, 60,  0, 60, 0  , 1}, -- Bone Armor
			[ 16431] = { 127,  1387,    0, 55,  0, 55, 0  , 1}, -- Bone Armor
			[ 27688] = { 127,  2499,    0,  0,  0,  0, 0  , 1}, -- Bone Shield
			[ 33896] = { 127,   999,    0, 20,  0, 20, 0  , 1}, -- Desperate Defense
			[ 28527] = { 127,   749,    0, 20,  0,  0, 0  , 1}, -- Fel Blossom
			[ 33147] = { 127, 24999,    0,  0,  0,  0, 0  , 1}, -- Greater Power Word: Shield
			[ 29701] = { 127,  3999,    0,  0,  0,  0, 0  , 1}, -- Greater Shielding
			[ 29719] = { 127,  3999,    0,  0,  0,  0, 0  , 1}, -- Greater Shielding
			[ 32278] = { 127,   399,    0,  0,  0,  0, 0  , 1}, -- Greater Warding Shield
			[ 13234] = { 127,   499,    0,  0,  0,  0, 0  , 1}, -- Harm Prevention Belt
			[  9800] = { 127,   174,    0, 52,  0,  0, 0  , 1}, -- Holy Shield
			[ 33245] = { 127,   649,    0, 60,  0, 60, 0.1, 1}, -- Ice Barrier
			[ 29674] = { 127,   999,    0,  0,  0,  0, 0  , 1}, -- Lesser Shielding
			[ 29503] = { 127,   199,    0,  0,  0,  0, 0  , 1}, -- Lesser Warding Shield
			[ 17252] = { 127,   499,    0,  0,  0,  0, 0  , 1}, -- Mark of the Dragon Lord
			[ 30456] = { 127,  3999,    0,  0,  0,  0, 0  , 1}, -- Nigh-Invulnerability
			[ 11835] = { 127,   115,    0, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 11974] = { 127,   136, 6.85, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 22187] = { 127,   205, 10.2, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 17139] = { 127,   273, 13.7, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 32595] = { 127,   410, 13.7, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 35944] = { 127,   547, 18.3, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 11647] = { 127,   780,  3.9, 54, 59,  1, 0.1, 1.15}, -- Power Word: Shield
			[ 36052] = { 127,   821, 27.4, 20,  0, 20, 0.1, 1.15}, -- Power Word: Shield
			[ 29408] = { 127,  2499,    0, 70,  0, 70, 0.1, 1.15}, -- Power Word: Shield
			[ 20697] = { 127,  4999,    0,  0,  0,  0, 0.1, 1.15}, -- Power Word: Shield
			[ 41373] = { 127,  4999,    0, 70,  0, 70, 0.1, 1.15}, -- Power Word: Shield
			[ 41475] = { 127, 24999,    0, 70,  0, 70, 0  , 1}, -- Reflective Shield
			[ 33810] = { 127,   136, 6.85, 20,  0, 20, 0  , 1}, -- Rock Shell
			[ 41431] = { 127, 49999,    0,  0,  0,  0, 0  , 1}, -- Rune Shield
			[ 31976] = { 127,   136, 6.85, 20,  0, 20, 0  , 1}, -- Shadow Shield
			[ 12040] = { 127,   199,   10, 20,  0, 20, 0  , 1}, -- Shadow Shield
			[ 22417] = { 127,   399,   20, 20,  0, 20, 0  , 1}, -- Shadow Shield
			[ 31771] = { 127,   439,    0, 20,  0,  0, 0  , 1}, -- Shell of Deterrence
			[ 27759] = { 127,    49,    0,  0,  0,  0, 0  , 1}, -- Shield Generator
			[ 46165] = { 127,  9999,    0,  0,  0,  0, 0  , 1}, -- Shock Barrier
			[ 36815] = { 127,  100000,   0,  0,  0,  0,   0,  1}, -- Shock Barrier
			[ 35618] = { 127,    19,    0,  0,  0,  1, 0  , 1}, -- Spirit of Redemption
			[ 29506] = { 127,   899,    0, 20,  0,  0, 0  , 1}, -- The Burrower's Shell
			[  1234] = { 127,     0,    0,  0,  0,  0, 0  , 1}, -- Tony's God Mode
			[ 10368] = { 127,   199,  2.3, 30, 35, 30, 0  , 1}, -- Uther's Light Effect (Rank 1)
			[ 37515] = { 127,   199,    0,  0,  0,  1, 0  , 1}, -- [Warrior] Blade Turning
			[ 31228] = { 127,    32,    0,  0,  0,  1, 0  , 1}, -- [Rogue] Cheat Death (Rank 1)
			[ 31229] = { 127,    65,    0,  0,  0,  1, 0  , 1}, -- [Rogue] Cheat Death (Rank 2)
			[ 31230] = { 127,    99,    0,  0,  0,  1, 0  , 1}, -- [Rogue] Cheat Death (Rank 3)
			[ 40251] = { 127,    99,    0, 70,  0, 70, 0  , 1}, -- [Rogue] Shadow of Death
			[ 32504] = {  -2,  1318,  4.7, 65, 69, 65, 0  , 1}, -- [Priest] Power Word: Warding (Rank 11)
			[ 28810] = { 127,   499,    0,  0,  0,  1, 0  , 1}, -- [Priest] Armor of Faith
			[ 27779] = { 127,   349,    0,  0,  0,  0, 0  , 1}, -- [Priest] Divine Protection
			[ 44175] = { 127,  1454,    0, 60,  0, 60, 0.1, 1}, -- [Priest] Power Word: Shield
			[ 44291] = { 127,  1454,    0, 60,  0, 60, 0.1, 1}, -- [Priest] Power Word: Shield
			[ 46193] = { 127,  2909,    0, 60,  0, 60, 0.1, 1}, -- [Priest] Power Word: Shield
			[    17] = { 127,    43,  0.8,  6, 11,  6, 0.1, 1}, -- [Priest] Power Word: Shield (Rank 1)
			[   592] = { 127,    87,  1.2, 12, 17, 12, 0.1, 1}, -- [Priest] Power Word: Shield (Rank 2)
			[   600] = { 127,   157,  1.6, 18, 23, 18, 0.1, 1}, -- [Priest] Power Word: Shield (Rank 3)
			[  3747] = { 127,   233,    2, 24, 29, 24, 0.1, 1}, -- [Priest] Power Word: Shield (Rank 4)
			[  6065] = { 127,   300,  2.3, 30, 35, 30, 0.1, 1}, -- [Priest] Power Word: Shield (Rank 5)
			[  6066] = { 127,     380,   2, 36, 41, 36, 0.2,  1}, -- [Priest] Power Word: Shield (Rank 6)
			[ 10898] = { 127,     483,   3, 42, 47, 42, 0.2,  1}, -- [Priest] Power Word: Shield (Rank 7)
			[ 20706] = { 127,   499,    3, 42, 47, 42, 0  , 1}, -- [Priest] Power Word: Shield 500 (Rank 7)
			[ 10899] = { 127,   604,  3.4, 48, 53, 48, 0.1, 1}, -- [Priest] Power Word: Shield (Rank 8)
			[ 10899] = { 127,     604,   3, 48, 53, 48, 0.2,  1}, -- [Priest] Power Word: Shield (Rank 8)
			[ 10900] = { 127,     762,   3, 54, 59, 54, 0.2,  1}, -- [Priest] Power Word: Shield (Rank 9)
			[ 10901] = { 127,     941,   4, 60, 65, 60, 0.3,  1}, -- [Priest] Power Word: Shield (Rank 10)
			[ 27607] = { 127,     941,   4, 60, 65, 60, 0.3,  1}, -- [Priest] Power Word: Shield (Rank 10)
			[ 25217] = { 127,    1124,   4, 65, 69, 65, 0.3,  1}, -- [Priest] Power Word: Shield (Rank 11)
			[ 25218] = { 127,    1264,   5, 70, 74, 70, 0.3,  1}, -- [Priest] Power Word: Shield (Rank 12)
			[ 17740] = {   1,   119,    6, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 30973] = {   1,   119,    6, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 17741] = {   1,   239,   12, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 46151] = {   1,   719,   36, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 15041] = {   4,   119,    0, 20,  0, 20, 0  , 1}, -- [Mage] Fire Ward
			[ 37844] = {   4,   159,    8, 20,  0, 20, 0  , 1}, -- [Mage] Fire Ward
			[   543] = {   4,   164,    0, 20, 29, 20, 0  , 1}, -- [Mage] Fire Ward (Rank 1)
			[  8457] = {   4,   289,    0, 30, 39, 30, 0  , 1}, -- [Mage] Fire Ward (Rank 2)
			[  8458] = {   4,   469,    0, 40, 49, 40, 0  , 1}, -- [Mage] Fire Ward (Rank 3)
			[ 10223] = {   4,   674,    0, 50, 59, 50, 0  , 1}, -- [Mage] Fire Ward (Rank 4)
			[ 10225] = {   4,   874,    0, 60, 68, 60, 0  , 1}, -- [Mage] Fire Ward (Rank 5)
			[ 27128] = {   4,  1124,    0, 69, 78, 69, 0  , 1}, -- [Mage] Fire Ward (Rank 6)
			[ 25641] = {   4,   499,   10, 60,  0, 60, 0  , 1}, -- [Mage] Frost Ward
			[ 15044] = {  16,   119,    0, 20,  0, 20, 0  , 1}, -- [Mage] Frost Ward
			[  6143] = {  16,   164,    0, 22, 31, 22, 0  , 1}, -- [Mage] Frost Ward (Rank 1)
			[  8461] = {  16,   289,    0, 32, 41, 32, 0  , 1}, -- [Mage] Frost Ward (Rank 2)
			[  8462] = {  16,   469,    0, 42, 51, 42, 0  , 1}, -- [Mage] Frost Ward (Rank 3)
			[ 10177] = {  16,   674,    0, 52, 59, 52, 0  , 1}, -- [Mage] Frost Ward (Rank 4)
			[ 28609] = {  16,   874,    0, 60, 69, 60, 0  , 1}, -- [Mage] Frost Ward (Rank 5)
			[ 32796] = {  16,  1124,    0, 70, 78, 70, 0  , 1}, -- [Mage] Frost Ward (Rank 6)
			[ 11426] = { 127,     437,   2, 40, 46, 40,   0,  1}, -- [Mage] Ice Barrier (Rank 1)
			[ 13031] = { 127,     548,   3, 46, 52, 46,   0,  1}, -- [Mage] Ice Barrier (Rank 2)
			[ 13032] = { 127,     677,   3, 52, 58, 52, 0.4,  1}, -- [Mage] Ice Barrier (Rank 3)
			[ 13033] = { 127,     817,   4, 58, 64, 58, 0.6,  1}, -- [Mage] Ice Barrier (Rank 4)
			[ 27134] = { 127,     924,   4, 64, 70, 64, 0.8,  1}, -- [Mage] Ice Barrier (Rank 5)
			[ 33405] = { 127,    1074,   4, 70, 76, 70, 0.8,  1}, -- [Mage] Ice Barrier (Rank 6)
			[ 35064] = { 127,  7999,    0, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 38151] = { 127,  9999,    0, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 29880] = { 127, 59999,    0, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[ 29880] = { 127, 60000,    6, 20,  0, 20, 0  , 1}, -- [Mage] Mana Shield
			[  1463] = { 127,   119,    0, 20, 27, 20, 0  , 1}, -- [Mage] Mana Shield (Rank 1)
			[  8494] = { 127,   209,    0, 28, 35, 28, 0  , 1}, -- [Mage] Mana Shield (Rank 2)
			[  8495] = { 127,   299,    0, 36, 43, 36, 0  , 1}, -- [Mage] Mana Shield (Rank 3)
			[ 10191] = { 127,     389,   0, 44, 51, 44, 0.1,  1}, -- [Mage] Mana Shield (Rank 4)
			[ 10192] = { 127,     479,   0, 52, 59, 52, 0.5,  1}, -- [Mage] Mana Shield (Rank 5)
			[ 10193] = { 127,     569,   0, 60, 67, 60, 0.8,  1}, -- [Mage] Mana Shield (Rank 6)
			[ 27131] = { 127,     714,   0, 68, 75, 68, 0.8,  1}, -- [Mage] Mana Shield (Rank 7)
			[ 26470] = { 127,     0,    0,  0,  0,  1, 0  , 1}, -- [Mage] Persistent Shield
			[  7812] = { 127,   304,  2.3, 16, 22, 16, 0  , 1}, -- [Warlock] Sacrifice (Rank 1)
			[ 19438] = { 127,   509,  3.1, 24, 30, 24, 0  , 1}, -- [Warlock] Sacrifice (Rank 2)
			[ 19440] = { 127,   769,  3.9, 32, 38, 32, 0  , 1}, -- [Warlock] Sacrifice (Rank 3)
			[ 19441] = { 127,  1094,  4.7, 40, 46, 40, 0  , 1}, -- [Warlock] Sacrifice (Rank 4)
			[ 19442] = { 127,  1469,  5.5, 48, 54, 48, 0  , 1}, -- [Warlock] Sacrifice (Rank 5)
			[ 19443] = { 127,  1904,  6.4, 56, 62, 56, 0  , 1}, -- [Warlock] Sacrifice (Rank 6)
			[ 27273] = { 127,  2854,  7.5, 64, 70, 64, 0  , 1}, -- [Warlock] Sacrifice (Rank 7)
			-- new wotlk spells
			[ 52286] = { 127,      14,   0, 55,  0, 55,   0,  1}, -- [Death Knight] Will of the Necropolis (Rank 3)
			[ 43019] = { 127,    1079,   0, 73, 77, 73,   1,  1}, -- [Mage] Mana Shield (Rank 8)
			[ 72723] = {  32,      99,   0, 60,  0, 60,   0,  1}, -- Resistant Skin
			[ 43039] = { 127,    3299,  15, 80, 84, 80, 0.9,  1}, -- [Mage] Ice Barrier (Rank 8)
			[ 54223] = { 127,       0,   0, 50,  0, 50,   0,  1}, -- [Death Knight] Shadow of Death
			[ 69366] = { 127,      14,   0, 40, 70, 40,   0,  1}, -- [Druid] Moonkin Form (Passive) (Passive)
			[ 63907] = { 127,      -1,   0,  0,  0,  0,   0,  1}, -- UK ON
			[ 31131] = { 127,      29,   0,  0,  0,  1,   0,  1}, -- Nerves of Steel (Rank 2)
			[ 69787] = { 127,99999998,   0,  0,  0,  0, 0.1,  1}, -- Ice Barrier
			[ 65858] = { 127, 1199999,   0,  0,  0,  0,   0,  1}, -- Shield of Lights
			[ 50461] = { 126,      74,   0, 55,  0, 55,   0,  1}, -- [Death Knight] Anti-Magic Zone
			[ 65874] = { 127, 1199999,   0,  0,  0,  0,   0,  1}, -- Shield of Darkness
			[ 58597] = { 127,     499,   0, 80, 90, 80,   0,  1}, -- [Paladin] Sacred Shield (Rank 1)
			[ 57843] = {   4,    1999,   8,  0,  0,  0,   0,  1}, -- Mojo Empowered Fire Ward
			[ 53910] = {  64,    4199,   0, 35,  0,  0,   0,  1}, -- Arcane Protection
			[ 48707] = { 126,      74,   0, 68,  0, 68,   0,  1}, -- [Death Knight] Anti-Magic Shell
			[ 33852] = { 127,      19,   0,  0,  0,  0,   0,  1}, -- [Druid] Primal Tenacity (Rank 2)
			[ 69740] = { 255,      29,   0,  0,  0,  0,   0,  1}, -- Transform X2
			[ 71780] = { 127,  145499,   0, 60,  0, 60, 0.1,  1}, -- [Priest] Power Word: Shield
			[ 43012] = {  16,    1949,   0, 79, 88, 79,   0,  1}, -- [Mage] Frost Ward (Rank 7)
			[ 64225] = { 127,  379999,   0,  0,  0,  0,   0,  1}, -- Stone Grip Absorb
			[ 49497] = { 126,      44,   0,  0,  0,  1,   0,  1}, -- Spell Deflection (Rank 3)
			[ 47985] = { 127,    6749,  10, 72, 78, 72,   0,  1}, -- [Warlock] Sacrifice (Rank 8)
			[ 62606] = {   1,      24,   0,  1,  0,  1,   0,  1}, -- [Druid] Savage Defense
			[ 62368] = {-128,      99,   0,  0,  0,  0,   0,  1}, -- cdubinten
			[ 50438] = { 127, 9999998,   0, 50,  0, 50,   0,  1}, -- [Death Knight] Death (Part 2)
			[ 51474] = { 127,       9,   0,  0,  0,  1,   0,  1}, -- [Shaman] Astral Shift (Rank 1)
			[ 50462] = { 126,      74,   0, 80,  0, 80,   0,  1}, -- [Death Knight] Anti-Magic Zone
			[ 70845] = { 127,       0,   0, 20,  0,  0,   0,  1}, -- Stoicism
			[ 48065] = { 127,    1919,   7, 75, 79, 75, 0.3,  1}, -- [Priest] Power Word: Shield (Rank 13)
			[ 53911] = {   4,    4199,   0, 35,  0,  0,   0,  1}, -- Fire Protection
			[ 53915] = {  32,    4199,   0, 40,  0,  0,   0,  1}, -- Shadow Protection
			[ 31850] = { 127,       6,   0,  0,  0,  0,   0,  1}, -- [Paladin] Ardent Defender (Rank 1)
			[ 31852] = { 127,      19,   0,  0,  0,  0,   0,  1}, -- [Paladin] Ardent Defender (Rank 3)
			[ 49609] = { 127,    4499,   0, 35,  0, 35,   0,  1}, -- Bone Armor
			[ 52284] = { 127,       4,   0,  0,  0,  0,   0,  1}, -- [Death Knight] Will of the Necropolis (Rank 1)
			[ 62321] = { 126,   39999,   0, 70,  0, 70,   0,  1}, -- Runic Shield
			[ 66099] = { 127,   67062,   0, 80,  0, 80, 0.1,  1}, -- Power Word: Shield
			[ 47986] = { 127,    8349,  15, 79, 85, 79,   0,  1}, -- [Warlock] Sacrifice (Rank 9)
			[ 64677] = {  85,      14,   0,  0,  0,  0,   0,  1}, -- Shield Generator
			[ 49145] = { 126,      14,   0,  0,  0,  1,   0,  1}, -- Spell Deflection (Rank 1)
			[ 59288] = { 127,     999,   0,  0,  0,  0,   0,  1}, -- Infra-Green Shield
			[ 31130] = { 127,      14,   0,  0,  0,  1,   0,  1}, -- Nerves of Steel (Rank 1)
			[ 64224] = { 127,   79999,   0,  0,  0,  0,   0,  1}, -- Stone Grip Absorb
			[ 47891] = {  32,    3299,   0, 78, 83, 78,   0,  1}, -- [Warlock] Shadow Ward (Rank 6)
			[ 43958] = { 127,       9,   0,  0,  0, 70,   0,  1}, -- You're Infected!
			[ 60218] = { 127,    3999,   0,  0,  0,  1,   0,  1}, -- Essence of Gossamer
			[ 64413] = { 127,       0,   0,  0,  0,  1,   0,  1}, -- [Mage] Protection of Ancient Kings
			[ 55019] = { 127,    1099,   0,  0,  0,  0,   0,  1}, -- Sonic Shield
			[ 50324] = { 127,    1202,   0, 60,  0, 60,   0,  1}, -- Bone Armor
			[ 47788] = { 127,      49,   0, 60,  0, 60,   0,  1}, -- [Priest] Guardian Spirit
			[ 62274] = { 127,   19999,   0,  0,  0,  0,   0,  1}, -- Shield of Runes
			[ 51479] = { 127,      29,   0,  0,  0,  1,   0,  1}, -- Astral Shift (Rank 3)
			[ 33957] = { 127,      29,   0,  0,  0,  0,   0,  1}, -- [Druid] Primal Tenacity (Rank 3)
			[ 47299] = { 127,    3099,   0, 76, 81, 76,   0,  1}, -- [Priest] Test Aegis of the Forgiven (Rank 1)
			[ 69069] = { 127,    9999,   0,  0,  0,  0,   0,  1}, -- [Death Knight] Shield of Bones
			[ 48066] = { 127,    2229,   9, 80, 84, 80, 0.3,  1}, -- [Priest] Power Word: Shield (Rank 14)
			[ 63564] = { 127,  184999,   0,  0,  0,  0,   0,  1}, -- Winter's Embrace
			[ 42740] = { 127,   49999,   0, 70,  0, 70,   0,  1}, -- Njord's Rune of Protection
			[ 31851] = { 127,      12,   0,  0,  0,  0,   0,  1}, -- [Paladin] Ardent Defender (Rank 2)
			[ 43010] = {   4,    1949,   0, 78, 87, 78,   0,  1}, -- [Mage] Fire Ward (Rank 7)
			[ 70768] = { 127,   49999,   0,  0,  0,  0,   0,  1}, -- Shroud of the Occult
			[ 53678] = {   8,     499,   0,  0,  0,  0,   0,  1}, -- Herbalist's Ward (Rank 1)
			[ 72054] = { 127,      99,   0, 60,  0, 60,   0,  1}, -- Kinetic Bomb Visual
			[ 49495] = { 126,      29,   0,  0,  0,  1,   0,  1}, -- Spell Deflection (Rank 2)
			[ 55277] = { 127,     449,   0,  1,  0,  1,   0,  1}, -- [Shaman] Stoneclaw Totem
			[ 64765] = { 127,    5199,   0,  0,  0,  1,   0,  1}, -- The General's Heart
			[ 51478] = { 127,      19,   0,  0,  0,  1,   0,  1}, -- [Shaman] Astral Shift (Rank 2)
			[ 71586] = { 127,    6399,   0, 20,  0,  0,   0,  1}, -- Hardened Skin
			[ 43038] = { 127,    2799,  15, 75, 79, 75, 0.9,  1}, -- [Mage] Ice Barrier (Rank 7)
			[ 63489] = { 127,   49999,   0,  0,  0,  0,   0,  1}, -- Shield of Runes
			[ 64174] = { 127,      99,   0, 80,  0, 80,   0,  1}, -- [Rogue] Hodir's Protective Gaze
			[ 65684] = {  32,  999999,   0,  0,  0,  0,   0,  1}, -- Dark Essence
			[ 47753] = { 127,       1,   0,  1,  0,  1,   0,  1}, -- [Priest] Divine Aegis (Rank 1)
			[ 65686] = {   4,  999999,   0,  0,  0,  0,   0,  1}, -- Light Essence
			[ 56778] = {   1,   29999,   1, 81,  0, 81,   0,  1}, -- [Mage] Mana Shield
			[ 47890] = {  32,    2749,   0, 72, 77, 72,   0,  1}, -- [Warlock] Shadow Ward (Rank 5)
			[ 63136] = { 127,   74999,   0,  0,  0,  0,   0,  1}, -- Winter's Embrace
			[ 55336] = { 127, 1199999,   0, 35,  0, 35,   0,  1}, -- Bone Armor
			[ 17624] = { 127,    5999,   0,  0,  0,  0,   0,  1}, -- Petrification
			[ 54512] = { 127,    1499,   0,  0,  0,  0,   0,  1}, -- Plague Shield
			[ 71299] = { 127,  249999,   0,  0,  0,  0,   0,  1}, -- Death's Embrace
			[ 50329] = { 127,    2499,   0,  0,  0,  0,   0,  1}, -- Shield of Suffering
			[ 55315] = { 127,   49999,   0, 35,  0, 35,   0,  1}, -- Bone Armor
			[ 62529] = { 126,  119999,   0, 70,  0, 70,   0,  1}, -- Runic Shield
			[ 66515] = { 127,  999998,   0, 70,  0, 70,   0,  1}, -- Reflective Shield
			[ 59616] = { 127,   99999,   0, 70,  0, 70,   0,  1}, -- Njord's Rune of Protection
			[ 43020] = { 127,    1329,   0, 79, 83, 79,   1,  1}, -- [Mage] Mana Shield (Rank 9)
			[ 52285] = { 127,       9,   0, 55,  0, 55,   0,  1}, -- [Death Knight] Will of the Necropolis (Rank 2)
			[ 53913] = {  16,    4199,   0, 40,  0,  0,   0,  1}, -- Frost Protection
			[ 33851] = { 127,       9,   0,  0,  0,  0,   0,  1}, -- [Druid] Primal Tenacity (Rank 1)
			[ 57350] = { 127,    1499,   0,  0,  0,  0,   0,  1}, -- Illusionary Barrier
			[ 59386] = { 127,    7399,   0, 55,  0, 55,   0,  1}, -- Bone Armor
			[ 53914] = {   8,    4199,   0, 40,  0,  0,   0,  1}, -- Nature Protection
			[ 71548] = { 127,   14549,   0, 60,  0, 60, 0.1,  1}, -- [Priest] Power Word: Shield
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
				local name = GetSpellInfo(spellId)
				if name then
					absorbIdx[name] = schoolIdx[ data[1] ]
				end
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
		if absorbCurTot<curPrev and absorbMaxTot<maxPrev  then
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
			absorbCurTot, absorbMaxTot, absorbCnt = 0, 0, 0
			wipe(absorbCur)
			wipe(absorbMax)
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
			UNIT_DIED = function()
				ResetValues(true)
			end,
		}
		function CleuEvent(_, event)
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
	local totalPer = maxTotal>0 and total/maxTotal or 0
	self:UpdateVisibility(totalPer)
	self.value = total
	self.valuePer = totalPer
	self.valueMax = maxTotal
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
