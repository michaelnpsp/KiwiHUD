-----------------------------------------------------------------------------------------------
-- KiwiHUD: Configuration options
-----------------------------------------------------------------------------------------------

local addon = KiwiHUD

--------------------------------------------------------

local Media  = LibStub("LibSharedMedia-3.0", true)

local isClassic = addon.isClassic

--------------------------------------------------------

addon.OptionsTable = { name = "KiwiHUD", type = "group", childGroups = "tab", args = {
	General  = { type = "group", order = 10, name = 'General', childGroups = nil,  args = {} },
	Bars     = { type = "group", order = 20, name = 'Bars',    childGroups = nil,  args = {} },
	Profiles = { type = "group", order = 30, name = 'Profiles', childGroups = nil, args = {} },
} }

--------------------------------------------------------

local editedBar = {}
local editedBarIndex

--------------------------------------------------------

addon.setupName = {
	gcd       = 'GCD Bar [player]',
	power     = 'Power Bar',
	health    = 'Health Bar',
	cast      = isClassic and 'Casting Bar [player]' or 'Casting Bar',
	manaalt   = 'Mana Alt [player]',
	myshields = "Shields Bar [player]",
	range     = "Range",
	threat    = 'Threat',
}

addon.setupDefaults = {
	gcd       = { type = 'gcd', index = -1, invert = false, color = {1,0,0,1}, },
	power     = { type = 'power',  unit = 'player', index = -1, textEnabled = false },
	manaalt   = { type = 'manaalt', index = -1, textEnabled = false },
	health    = { type = 'health', unit = 'player', index = -1, colorType = 'reaction', textEnabled = false },
	cast      = { type = 'cast',   unit = 'player', index = -1, color = {1,1,0,1}, },
	myshields = { type = 'myshields', index = -1, hideValue = 0, textEnabled = false, color = {1,1,1,1}, },
	range     = { type = 'range', textOffsetX = 0, textOffsetY = 0, textAnchor = 'CENTER', textAlign = 'CENTER', textFontSize = 16, textFont =  Media.DefaultMedia.font, textColor = {1,1,1,1} },
	threat    = { type = 'threat', textOffsetX = 0, textOffsetY = 32, textAnchor = 'CENTER', textAlign = 'CENTER', textFontSize = 12, textFont =  Media.DefaultMedia.font, textColor = {1,1,1,1} },
}

--------------------------------------------------------

local UNIT_VALUES
if isClassic then
	UNIT_VALUES  = { player = 'player', pet = 'pet', target = 'target', focus = 'focus', pettarget = 'pettarget', targettarget ='targettarget', focustarget = 'focustarget' }
else
	UNIT_VALUES  = { player = 'player', pet = 'pet', target = 'target', pettarget = 'pettarget', targettarget ='targettarget' }
end

local FONT_FLAGS_VALUES = {
	[""]        = "Soft",
	["OUTLINE"] = "Soft Thin",
	["THICKOUTLINE"] = "Soft Thick",
	["MONOCHROME"] = "Sharp",
	["MONOCHROME, OUTLINE"] = "Sharp Thin",
	["MONOCHROME, THICKOUTLINE"] = "Sharp Thick",
}

local FONT_ANCHOR_VALUES = {
	TOP = 'TOP',
	CENTER = 'CENTER',
	BOTTOM = 'BOTTOM'
}

local FONT_ALIGN_VALUES = {
	LEFT   = "LEFT",
	CENTER = "CENTER",
	RIGHT  = "RIGHT",
}

local TEXTURES_VALUES = {
	"DHUD",
	"Clean Curves",
	"Hi Bar",
	"Glow Arc",
	"Rivet Bar",
	"Blizzard",
}

local TEXTURES_FG = {
	"Interface\\Addons\\KiwiHUD\\media\\dhudfg",
	"Interface\\Addons\\KiwiHUD\\media\\cleancurvesfg",
	"Interface\\Addons\\KiwiHUD\\media\\hibarfg",
	"Interface\\Addons\\KiwiHUD\\media\\glowarcfg",
	"Interface\\Addons\\KiwiHUD\\media\\rivetbarfg",
	"Interface\\Addons\\KiwiHUD\\media\\blizzardfg",
}

local TEXTURES_BG = {
	"Interface\\Addons\\KiwiHUD\\media\\dhudbg",
	"Interface\\Addons\\KiwiHUD\\media\\cleancurvesbg",
	"Interface\\Addons\\KiwiHUD\\media\\hibarbg",
	"Interface\\Addons\\KiwiHUD\\media\\glowarcbg",
	"Interface\\Addons\\KiwiHUD\\media\\rivetbarbg",
	"Interface\\Addons\\KiwiHUD\\media\\blizzardbg",
}

local TEXTURES_MARGIN = { 1, 1, 1, 1, 1, 1.0325 }

--------------------------------------------------------

local function Opt_GetOption( tree, order )
	local opt = addon.OptionsTable
	for _,key in ipairs( {strsplit('/', tree)} ) do
		if not opt.args[key] then
			opt.args[key] = { type = "group", order = order, name = key, args = {} }
		end
		opt = opt.args[key]
	end
	return opt, opt.args
end

local Opt_SetupOption
do
	local index = 1
	Opt_SetupOption = function( tree, name, options, order )
		local opt, args = Opt_GetOption(tree, index+100)
		if (not name) or args[name] then
			args = name and args[name].args or args
			for k,v in pairs(options) do args[k] = v end
		else
			local group = { type = 'group', name = name, order = order or index, inline = not opt.childGroups, args = options }
			args[name] = group
		end
		index = index + 1
		return options
	end
end

--------------------------------------------------------
-- General Options
--------------------------------------------------------

Opt_SetupOption( 'General', 'Bars positioning', {
	offsetY = {
		type = "range",
		order = 0,
		softMin = -250, softMax = 250, step = 1,
		name = "Vertical Position",
		get = function() return addon.db.offsetY end,
		set = function (_, value)
			addon.db.offsetY = value
			addon:LayoutBars()
		end,
	},
	height = {
		type = "range",
		order = 1,
		min = 0, softMax = 250, step = 1,
		name = "Bars Height",
		get = function() return addon.db.height end,
		set = function (_, value)
			addon.db.height = value>0 and value or 64
			addon:LayoutBars()
		end,
	},
	width = {
		type = "range",
		order = 2,
		min = 0, softMax = 250, step = 1,
		name = "Bars Width",
		get = function() return addon.db.width end,
		set = function (_, value)
			addon.db.width = value>0 and value or 32
			addon:LayoutBars()
		end,
	},
	sep= {
		type = "range",
		order = 3,
		min = 0, softMax = 150, step = 1,
		name = "Bars separation",
		get = function() return addon.db.sep end,
		set = function (_, value)
			addon.db.sep = value>0 and value or 10
			addon:LayoutBars()
		end,
	},
	gap= {
		type = "range",
		order = 4,
		min = 0, softMax = 300, step = 1,
		name = "Gap",
		desc = "Distance between the left and right bars.",
		get = function() return addon.db.gap end,
		set = function (_, value)
			addon.db.gap = value>0 and value or 150
			addon:LayoutBars()
		end,
	},
	scale = {
		type = "range",
		order = 5,
		min = .2, max = 2, step = .05,
		isPercent = true,
		name = "Scale",
		desc = "Scale.",
		get = function() return addon.db.scale or 1 end,
		set = function (_, value)
			addon.db.scale = value
			addon:LayoutBars()
		end,
	},
} )

Opt_SetupOption( 'General', 'Bars Textures', {
	texture = {
		type = 'select',
		order = 1,
		name = 'Texture',
		get = function()
			for i=1,#TEXTURES_FG do
				if addon.db.texfg == TEXTURES_FG[i] then
					return i
				end
			end
		end,
		set = function(_, value)
			addon.db.texfg = TEXTURES_FG[value]
			addon.db.texbg = TEXTURES_BG[value]
			addon.db.texmargin = TEXTURES_MARGIN[value]
			addon:DestroyBars()
			addon:CreateBars()
		end,
		values = TEXTURES_VALUES,
	},
	colorbg = {
		type = "color",
		order = 2,
		hasAlpha = true,
		name = "Background Color",
		get = function()
			if addon.db.colorbg then
				return unpack(addon.db.colorbg)
			else
				return 1,1,1,1
			end
		end,
		set = function( _, r,g,b,a )
			addon.db.colorbg = { r, g, b, a }
			addon:LayoutBars()
		end,
	},
} )

Opt_SetupOption( 'General', 'Bars Opacity', {
	alpha1 = {
		type = "range",
		order = 1,
		min = 0, max = 1, step = .05,
		name = "Opacity in Combat",
		get = function()
			return addon.db.alphaCombat or 1
		end,
		set = function (_, value)
			addon.db.alphaCombat = value
		end,
	},
	alpha2 = {
		type = "range",
		order = 1,
		min = 0, max = 1, step = .05,
		name = "Opacity Out of Combat",
		get = function()
			return addon.db.alphaOOC or .5
		end,
		set = function (_, value)
			addon.db.alphaOOC = value
		end,
	},
} )

-- Colors Setup
do
	local SEPARATOR = { type = 'description' , order = 149, name = '' }
	local RESET = {
		type = 'execute',
		order = 150,
		width = "half",
		name = 'Reset',
		desc = 'Reset colors to the default values.',
		func = function(info)
			wipe( addon.db[ info[#info] ] )
			addon:Update()
			addon:LayoutBars()
		end,
	}
	-- Power Colors
	local order, options = 1, { separator = SEPARATOR, powerColors = RESET }
	for name,key in pairs(Enum.PowerType) do
		if PowerBarColor[key] then
			options[name] = {
				type = "color",
				width = "normal",
				order = order,
				hasAlpha = true,
				name = name,
				desc = name,
				get = function()
					return unpack( addon.PowerColors[key] )
				end,
				set = function( _, r,g,b,a )
					addon.PowerColors[key] = { r,g,b,a }
					addon.db.powerColors[key] = addon.PowerColors[key]
					addon:LayoutBars()
				end,
			}
			order = order + 1
		end
	end
	Opt_SetupOption( 'General', 'Power Colors', options)
	-- Class Colors
	local order, options = 1, { separator = SEPARATOR, classColors = RESET }
	local IgnoreKeys = isClassic and {DEMONHUNTER=true,DEATHKNIGHT=true,MONK=true} or {}
	for key in pairs(RAID_CLASS_COLORS) do
		if type(key)=='string' and not IgnoreKeys[key] then
			options[key] = {
				type = "color",
				width = "normal",
				order = key == 'UNKNOWN' and 90 or order,
				hasAlpha = true,
				name = LOCALIZED_CLASS_NAMES_MALE[key],
				desc = LOCALIZED_CLASS_NAMES_MALE[key],
				get = function()
					return unpack( addon.ClassColors[key] )
				end,
				set = function( _, r,g,b,a )
					addon.ClassColors[key] = { r,g,b,a }
					addon.db.classColors[key] = addon.ClassColors[key]
					addon:LayoutBars()
				end,
			}
			order = order + 1
		end
	end
	Opt_SetupOption( 'General', 'Class Colors', options)
	-- Reaction Colors
	local order, options = 1, { separator = SEPARATOR, reactionColors = RESET }
	for key in pairs(addon.REACTION_COLORS) do
		options[key] = {
			type = "color",
			width = "normal",
			order = order,
			hasAlpha = true,
			name = key,
			desc = key,
			get = function()
				return unpack( addon.ReactionColors[key] )
			end,
			set = function( _, r,g,b,a )
				addon.ReactionColors[key] = { r,g,b,a }
				addon.db.reactionColors[key] = addon.ReactionColors[key]
				addon:LayoutBars()
			end,
		}
		order = order + 1
	end
	Opt_SetupOption( 'General', 'Reaction Colors', options)
	-- School Colors
	if isClassic then
		local school_names = { 'all', 'physical', 'magic', 'holy', 'fire', 'nature', 'frost', 'shadow', 'arcane' }
		local order, options = 1, { separator = SEPARATOR, schoolColors = RESET }
		for key in pairs(addon.SCHOOL_COLORS) do
			options[tostring(key)] = {
				type = "color",
				width = "normal",
				order = order,
				hasAlpha = true,
				name = school_names[key],
				desc = school_names[key],
				get = function()
					return unpack( addon.SchoolColors[key] )
				end,
				set = function( _, r,g,b,a )
					addon.SchoolColors[key] = { r,g,b,a }
					addon.db.schoolColors[key] = addon.SchoolColors[key]
					addon:LayoutBars()
				end,
			}
			order = order + 1
		end
		Opt_SetupOption( 'General', 'Magic Schools Colors', options)
	end
end

Opt_SetupOption( 'General', 'Miscellaneous', {
	minimapIcon = {
		type = "toggle",
		order = 10,
		name = "Display Minimap Icon",
		desc = "Display Minimap Icon",
		get = function()
			return not addon.db.minimapIcon.hide
		end,
		set = function ( _, value)
			if addon.db.minimapIcon.hide then
				addon.db.minimapIcon.hide = nil
				LibStub("LibDBIcon-1.0"):Show(addon.addonName)
			else
				addon.db.minimapIcon.hide = true
				LibStub("LibDBIcon-1.0"):Hide(addon.addonName)
			end
		end,
	}
} )

--------------------------------------------------------
-- Bars Options
--------------------------------------------------------

-- bars list & managements options
local bars = addon.OptionsTable.args.Bars.args
-- one bar options
local options = {}
-- misc util functions
local NewBarType, NewBarUnit

local function GetBarOrder(db)
	db = db.arg or db
	return db.index and db.index+100 or 300
end

local function GetBarTitle(db)
	if db then
		db = db.arg or db
		if db.type then
			return db.unit and string.format('%s [%s]', addon.setupName[db.type], db.unit ) or addon.setupName[db.type]
		end
	end
end

local function MakeBarsOptions()
	for key in pairs(bars) do
		if tonumber(key) then
			bars[key] = nil
		end
	end
	for i,db in ipairs(addon.db.bars) do
		local key = tostring(i)
		bars[key] = {
			type = "group",
			order = GetBarOrder,
			name  = GetBarTitle,
			args = options,
			arg = db,
		}
	end
	local i = #addon.db.bars+1
	while bars[tostring(i)] do
		bars[tostring(i)] = nil
		i = i + 1
	end
end

local function CreateBar(typ, unit)
	local index = #addon.db.bars+1
	local bar = CopyTable( addon.setupDefaults[typ] )
	bar.unit = unit
	addon.db.bars[index] = bar
	addon:CreateBar(index)
	MakeBarsOptions()
	LibStub("AceConfigDialog-3.0"):SelectGroup( addon.addonName, "Bars", tostring(index) )
	NewBarType, NewBarUnit = nil, nil
end

-- Bars list & management options

bars.createType = {
	type = 'select',
	order = 0,
	name = 'Create Bar',
	get = function()
		return NewBarType
	end,
	set = function(info, typ)
		NewBarUnit = addon.setupDefaults[typ].unit
		if NewBarUnit and (not isClassic or typ~='cast') then
			NewBarType = typ
		else
			CreateBar(typ, NewBarUnit)
		end
	end,
	values = addon.setupName,
}

bars.createUnit = {
	type = 'select',
	order = 1,
	name = 'Select Unit',
	get = function() return NewBarUnit end,
	set = function(_, value)
		NewBarUnit = value
	end,
	values = UNIT_VALUES,
	hidden = function() return not NewBarType end,
}

bars.createAccept = {
	type = 'execute',
	order = 2,
	width = "half",
	name = 'Create',
	desc = 'Create.',
	func = function()
		CreateBar( NewBarType, NewBarUnit )
	end,
	hidden = function() return not NewBarType end,
	disabled = function() return not NewBarUnit end,
}

bars.createCancel = {
	type = 'execute',
	order = 3,
	width = "half",
	name = 'Cancel',
	desc = 'Cancel.',
	func = function() NewBarType, NewBarUnit = nil, nil end,
	hidden = function() return not NewBarType end,
}

bars.test= {
	type = 'execute',
	order = 2,
	width = 0.6,
	name = 'Test Mode',
	desc = 'Test Mode.',
	func = function()
		addon:ToggleTestMode()
	end,
	hidden = function() return #addon.db.bars==0 or NewBarType end,
}

-- One bar optinos

options.title = { type = "header", order = 0,
	name = function() return GetBarTitle(editedBar) end,
	hidden = function(info)
		editedBarIndex = tonumber(info[#info-1])
		editedBar = addon.db.bars[ editedBarIndex ] or {}
		return false
	end
}

options.index = {
	type = "range",
	order = 1,
	width = "full",
	min = -10, max = 10, step = 1,
	name = "Bar Horizontal Position",
	desc = "Select the bar horizontal position:\nNegative values = left side.\nPositive values = right side.",
	get = function() return editedBar.index end,
	set = function (_, value)
		if value~=0 then
			editedBar.index = value
			addon:LayoutBar(editedBarIndex)
		end
	end,
	hidden = function() return not editedBar.index end,
}

options.hideFull= {
	type = "toggle",
	order = 2,
	name = "Hide when Full",
	desc = "Hide bar when resource is full.",
	get = function()
		return editedBar.hideValue == 1
	end,
	set = function ( _, value)
		editedBar.hideValue = value and 1 or nil
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='myshields' and editedBar.type~='health' and editedBar.type~='power' and editedBar.type~='manaalt' end,
}

options.hideEmpty = {
	type = "toggle",
	order = 2.1,
	name = "Hide when Empty",
	desc = "Hide bar when resource is depleted.",
	get = function()
		return editedBar.hideValue == 0
	end,
	set = function ( _, value)
		editedBar.hideValue = value and 0 or nil
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='myshields' and editedBar.type~='health' and editedBar.type~='power' and editedBar.type~='manaalt' end,
}

options.shieldMaxHealth = {
	type = "toggle",
	order = 2.2,
	name = "Max Health Scale",
	desc = "Full filled bar represents the player max health.",
	get = function()
		return not editedBar.shieldMax
	end,
	set = function ( _, value)
		editedBar.shieldMax = (not value) or nil
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='myshields' end,
}

options.shieldMaxShield = {
	type = "toggle",
	order = 2.3,
	name = "Max Shield Scale",
	desc = "Full filled bar represents the maximum shield capacity.",
	get = function()
		return editedBar.shieldMax
	end,
	set = function ( _, value)
		editedBar.shieldMax = value or nil
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='myshields' end,
}

options.displayShield = {
	type = "toggle",
	order = 2.5,
	width = "full",
	name = "Display Shields",
	desc = "Display Damage Absorb Shields on top of Health Har.",
	get = function()
		return editedBar.shieldDisplay
	end,
	set = function ( _, value)
		editedBar.shieldDisplay = value or nil
		addon:RecreateBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='health' end,
}

options.invert = {
	type = "toggle",
	order = 3,
	name = "Invert",
	desc = "Invert fill direction",
	get = function()
		return editedBar.invert
	end,
	set = function ( _, value)
		editedBar.invert = value
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.invert==nil end,
}

options.hideOnCast = {
	type = "toggle",
	order = 3.5,
	name = "Hide on Cast",
	desc = "Hide this bar if the player is casting",
	get = function()
		return editedBar.hideOnCast
	end,
	set = function ( _, value)
		editedBar.hideOnCast = value
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='gcd' end,
}


-- Colors

options.headerColor = { type = "header", order = 100, name = 'Colors', hidden = function() return not editedBar.color and not editedBar.colorType end }

options.colorType = {
	type = 'select',
	order = 110,
	name = 'Color Type',
	get = function()
		return editedBar.colorType or 'custom'
	end,
	set = function(_, value)
		if value =='custom' then
			editedBar.colorType = nil
			editedBar.color = {1,1,1,1}
		else
			editedBar.colorType = value
			editedBar.color = nil
		end
		addon:RecreateBar(editedBarIndex)
	end,
	values = { class = 'Class Color', reaction = 'Unit Reaction', custom = 'Custom Color' },
	hidden = function() return editedBar.type~='health' end,
}

options.color = {
	type = "color",
	order = 120,
	hasAlpha = true,
	name = "Color",
	get = function()
		return unpack( editedBar.color )
	end,
	set = function( _, r,g,b,a )
		editedBar.color = { r, g, b, a }
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return not editedBar.color end,
}

-- Text

options.textHeader = { type = "header", order = 200, name = 'Text Value', hidden = function() return editedBar.textEnabled==nil end }
options.textEnabled = {
	type = "toggle",
	order = 205,
	width = "full",
	name = "Enable Text",
	desc = "Enable Text",
	get = function()
		return editedBar.textEnabled
	end,
	set = function ( _, value)
		editedBar.textEnabled = value
		if value then
			editedBar.textOffsetX  = 0
			editedBar.textOffsetY  = 0
			editedBar.textAnchor   = 'BOTTOM'
			editedBar.textAlign    = 'CENTER'
			editedBar.textFontSize = 12
			editedBar.textFont     = Media.DefaultMedia.font
			editedBar.textColor    = {1,1,1,1}
		else
			editedBar.textOffsetX  = nil
			editedBar.textOffsetY  = nil
			editedBar.textAnchor   = nil
			editedBar.textAlign    = nil
			editedBar.textFontSize = nil
			editedBar.textFont     = nil
			editedBar.textColor    = nil
		end
		addon:RecreateBar(editedBarIndex)
	end,
	hidden = function() return editedBar.textEnabled==nil end,
}
options.textOffsetX =  {
	type = 'range', order = 210, name = 'X Adjust', softMin = -150, softMax = 150, step = 1,
	get = function() return editedBar.textOffsetX or 0 end,
	set = function(info,value)
		editedBar.textOffsetX = value
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.textOffsetX==nil end,
}
options.textOffsetY =  {
	type = 'range', order = 220, name = 'Y Adjust', softMin = -150, softMax = 150, step = 1,
	get = function() return editedBar.textOffsetY or 0 end,
	set = function(info,value)
		editedBar.textOffsetY = value
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.textOffsetY==nil end,
}
options.textAnchor = {
	type = "select",
	order = 225,
	name = "Anchor To",
	get = function () return editedBar.textAnchor or 'BOTTOM' end,
	set = function (_, v)
		editedBar.textAnchor = v
		addon:LayoutBar(editedBarIndex)
	end,
	values = FONT_ANCHOR_VALUES,
	hidden = function() return editedBar.textAnchor==nil end,
}
options.textAlign = {
	type = "select",
	order = 230,
	name = "Horizontal Align",
	get = function () return editedBar.textAlign or 'CENTER' end,
	set = function (_, v)
		editedBar.textAlign = v
		addon:LayoutBar(editedBarIndex)
	end,
	values = FONT_ALIGN_VALUES,
	hidden = function() return editedBar.textAlign==nil end,
}
options.textFont = {
	type = "select", dialogControl = "LSM30_Font",
	order = 240,
	name = "Font Name",
	values = AceGUIWidgetLSMlists.font,
	get = function () return editedBar.textFont end,
	set = function (_, v)
		editedBar.textFont = v
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.textFont==nil end,
}
options.textFontSize = {
	type = "range",
	order = 250,
	name = 'Font Size',
	min = 0,
	softMax = 50,
	step = 1,
	get = function () return editedBar.textFontSize or 14 end,
	set = function (_, v)
		editedBar.textFontSize = v
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.textFontSize==nil end,
}
options.textColor = {
	type = "color",
	order = 260,
	hasAlpha = true,
	name = "Text Color",
	get = function()
		return unpack( editedBar.textColor )
	end,
	set = function( _, r,g,b,a )
		editedBar.textColor = { r, g, b, a }
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return not editedBar.textColor end,
}

-- Threat specific options

options.threatHeader = { type = "header", order = 300, name = '', hidden = function() return editedBar.type~='threat' end }
options.threatAlone = {
	type = "toggle",
	order = 305,
	width = "full",
	name = "Disable when solo",
	desc = "Disable threat display when solo.",
	get = function()
		return editedBar.disableWhenSolo
	end,
	set = function ( _, value)
		editedBar.disableWhenSolo = value or nil
		addon:LayoutBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='threat' end,
}

-- Energy ticks

options.energyTicksHeader = { type = "header", order = 300, name = 'Energy Ticker', hidden = function() return editedBar.type~='power' end }
options.energyTicksEnabled = {
	type = "toggle",
	order = 305,
	width = "full",
	name = "Enable Ticker",
	desc = "Display a spark to track energy ticks time.",
	get = function()
		return editedBar.tickerEnabled
	end,
	set = function ( _, value)
		editedBar.tickerEnabled = value or nil
		addon:RecreateBar(editedBarIndex)
	end,
	hidden = function() return editedBar.type~='power' end,
}


options.deleteHeader = { type = "header", order = 499, name = ''}
options.delete = {
	type = 'execute',
	order = 500,
	width = 'full',
	name = 'Delete this Widget',
	desc = 'Delete this Widget',
	func = function()
		table.remove(addon.db.bars, editedBarIndex)
		addon:DestroyBar(editedBarIndex)
		MakeBarsOptions()
	end,
	confirm = function() return 'Are you sure you want to delete this widget?' end,
	hidden = function() return #addon.db.bars==0 or NewBarType end,
}

--------------------------------------------------------
-- Databroker
--------------------------------------------------------

local ldb = LibStub("LibDataBroker-1.1", true):NewDataObject( addon.addonName, {
	type  = "launcher",
	label = GetAddOnInfo( addon.addonName, "Title"),
	icon  = "Interface\\AddOns\\KiwiHUD\\media\\kiwi",
	OnClick = function(self, button)
		addon:OnChatCommand("kiwihud")
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddDoubleLine("KiwiHUD", addon.versionToc)
		tooltip:AddLine("Displays HUD bars around the player.", 1,1,1, true)
		tooltip:AddLine("|cFFff4040Click|r to open configuration menu", 0.2, 1, 0.2)
	end,
})

--------------------------------------------------------
-- Initialization
--------------------------------------------------------

function addon:InitializeOptions()
	-- options frame
	local optionsFrame = CreateFrame( "Frame", nil, UIParent )
	optionsFrame.name = addon.addonName
	local button = CreateFrame("BUTTON", nil, optionsFrame, "UIPanelButtonTemplate")
	button:SetText("Configure KiwiHUD")
	button:SetSize(225,32)
	button:SetPoint('TOPLEFT', optionsFrame, 'TOPLEFT', 20, -20)
	button:SetScript("OnClick", function()
		HideUIPanel(InterfaceOptionsFrame)
		HideUIPanel(GameMenuFrame)
		addon.OnChatCommand()
	end)
	InterfaceOptions_AddCategory(optionsFrame)
	addon.optionsFrame = optionsFrame
	-- minimap icon
	local icon = LibStub("LibDBIcon-1.0")
	if icon then
		icon:Register(self.addonName, ldb, self.db.minimapIcon)
		self.minimapIcon = icon
	end
	-- create options table
	MakeBarsOptions()
	-- remove this function
	self.InitializeOptions = nil
end

--------------------------------------------------------
-- Refresh options table when profile change
--------------------------------------------------------

function addon:RefreshOptions()
	MakeBarsOptions()
end

--------------------------------------------------------
-- Command line options
--------------------------------------------------------

function addon.OnChatCommand()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.addonName, addon.OptionsTable)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize(addon.addonName, 635, 575)
	addon.OnChatCommand = function()
		local LIB = LibStub("AceConfigDialog-3.0")
		LIB[ LIB.OpenFrames[addon.addonName] and 'Close' or 'Open' ](LIB, addon.addonName)
	end
	SlashCmdList[ addon.addonName:upper() ] = addon.OnChatCommand
	addon.OnChatCommand()
end

SlashCmdList[ addon.addonName:upper() ] = addon.OnChatCommand
_G[ 'SLASH_'..addon.addonName:upper()..'1' ] = '/kiwihud'

--------------------------------------------------------
-- Publish some stuff
--------------------------------------------------------

function addon:SetupOptions(...)
	return Opt_SetupOption(...)
end

