--ArachnaBot v1.0


local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic 		= true
object.bRunBehaviors	= true
object.bUpdates 		= true
object.bUseShop 		= true

object.bRunCommands 	= true
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior = true
object.bDebugUtility = false
object.bDebugExecute = false


object.logger = {}
object.logger.bWriteLog = true
object.logger.bVerboseLog = true

object.core 		= {}
object.eventsLib 	= {}
object.metadata 	= {}
object.behaviorLib 	= {}
object.skills 		= {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading accursed_main...')

object.heroName = 'Hero_Accursed'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 2, ShortSolo = 3, LongSolo = 4, ShortSupport = 4, LongSupport = 5, ShortCarry = 2, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.cauterize = unitSelf:GetAbility(0)
		skills.fireShield = unitSelf:GetAbility(1)
		skills.sear = unitSelf:GetAbility(2)
		skills.flameConsumption = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.cauterize and skills.fireShield and skills.sear and skills.flameConsumption and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.cauterize:GetLevel() >= 1) then
		skills.cauterize:LevelUp()
	elseif not (skills.fireShield:GetLevel() >= 2) then
		skills.fireShield:LevelUp()
	elseif not (skills.sear:GetLevel() >= 1) then
		skills.sear:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.flameConsumption:CanLevelUp() then
		skills.flameConsumption:LevelUp()
	elseif skills.cauterize:CanLevelUp() then
		skills.cauterize:LevelUp()
	elseif skills.fireShield:CanLevelUp() then
		skills.fireShield:LevelUp()
	elseif skills.sear:CanLevelUp() then
		skills.sear:LevelUp()
	else
		skills.attributeBoost:LevelUp()
	end	
end

---------------------------------------------------
--                   Overrides                   --
---------------------------------------------------

----------------------------------
--	Arachna specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.cauterizeUpBonus = 6
object.cauterizeUseBonus = 7
object.cauterizeUseThreshold = 16

object.nCauterizeUtility = 29

object.fireShieldUpBonus = 9
object.fireShieldUseBonus = 20
object.fireShieldUseThreshold = 24

object.nFireShieldUtility = 53

object.searUpBonus = 18
object.searUseBonus = 21
object.searUseThreshold = 13

object.flameConsumptionUpBonus = 60
object.flameConsumptionUseBonus = 75
object.flameConsumptionUseThreshold = 0

local function AbilitiesUpUtilityFn()
	local unitSelf = core.unitSelf
	local val = 0
	
	if skills.cauterize:CanActivate() then
		val = val + object.cauterizeUpBonus
	end
	
	if skills.fireShield:CanActivate() then
		val = val + object.fireShieldUpBonus
	end
	
	if skills.sear:CanActivate() then
		val = val + object.searUpBonus
	end
	
	if skills.flameConsumption:CanActivate() then
		val = val + object.flameConsumptionUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Accursed1" then
			addBonus = addBonus + object.cauterizeUseBonus
		elseif EventData.InflictorName == "Ability_Accursed2" then
			addBonus = addBonus + object.fireShieldUseBonus
		elseif EventData.InflictorName == "Ability_Accursed3" then
			addBonus = addBonus + object.searUseBonus
		elseif EventData.InflictorName == "Ability_Accursed4" then
			addBonus = addBonus + object.flameConsumptionUseBonus
		end
	end
	
	if addBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
	
		core.nHarassBonus = core.nHarassBonus + addBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride

--Util override
local function CustomHarassUtilityOverride(hero)
	local unitSelf = core.unitSelf
	local nUtility = AbilitiesUpUtilityFn()
	
	if unitSelf:GetHealthPercent() > .93 then
		nUtility = nUtility + 4
	end
	
	if unitSelf:GetManaPercent() > .93 then
		nUtility = nUtility + 8
	end
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride   

----------------------------------
--	Arachna specific push strength
----------------------------------
local function PushingStrengthUtilOverride(myHero)
	local myDamage = core.GetFinalAttackDamageAverage(myHero)
	local myAttackDuration = myHero:GetAdjustedAttackDuration()
	local myDPS = myDamage * 1000 / (myAttackDuration) --ms to s
	
	local vTop = Vector3.Create(300, 100)
	local vBot = Vector3.Create(100, 0)
	local m = ((vTop.y - vBot.y)/(vTop.x - vBot.x))
	local b = vBot.y - m * vBot.x 
	
	local util = m * myDPS + b
	util = Clamp(util, 0, 100)
	
	--BotEcho(format("MyDPS: %g  util: %g  myMin: %g  myMax: %g  myAttackAverageL %g", 
	--	myDPS, util, myHero:GetFinalAttackDamageMin(), myHero:GetFinalAttackDamageMax(), myDamage))

	return util
end
behaviorLib.PushingStrengthUtilFn = PushingStrengthUtilOverride


----------------------------------
--	Arachna harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	
	local bActionTaken = false
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	
	--since we are using an old pointer, ensure we can still see the target for entity targeting
	if core.CanSeeUnit(botBrain, unitTarget) then
		local vecMyPosition = unitSelf:GetPosition()
		local vecTargetPosition = unitTarget:GetPosition()
		
		local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
		
		local dist = Vector3.Distance2D(vecMyPosition, vecTargetPosition)
		
		local abilCauterize = skills.cauterize
		local abilFireShield = skills.fireShield
		local abilSear = skills.sear
		local abilFlameConsumption = skills.flameConsumption
		local abilCauterizeRange = abilCauterize and abilCauterize:GetRange() or 0
		local abilFireShieldRange = abilFireShield and abilFireShield:GetRange() or 0
		
		if abilFlameConsumption and abilFlameConsumption:CanActivate() and not bActionTaken then
			if unitSelf:GetHealthPercent() < 0.2 then
				bActionTaken = core.OrderAbility(botBrain, abilFlameConsumption)
			end
		end
		
		if abilSear and abilSear:CanActivate() and not bActionTaken then
			if (unitSelf:GetHealthPercent() < 0.15 or nLastHarassUtility > object.searUseThreshold) then
				bActionTaken = core.OrderAbility(botBrain, abilSear)
			end
		end
		
		if abilFireShield and abilFireShield:CanActivate() and not bActionTaken then
			if nLastHarassUtility > object.fireShieldUseThreshold or unitSelf:GetHealthPercent() < .33 or core.NumberElements(tLocalEnemyHeroes) > 2 then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilFireShield, unitSelf)
			end
		end
		
		if abilCauterize and abilCauterize:CanActivate() and not bActionTaken then
			if unitSelf:GetHealthPercent() * 2 > unitTarget:GetHealthPercent() and nLastHarassUtility > botBrain.cauterizeUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilCauterize, unitTarget)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

behaviorLib.StartingItems = {"Item__Bot_Booster", "Item_CrushingClaws", "Item_MarkOfTheNovice", "2 Item_RunesOfTheBlight", "2 Item_ManaPotion"}
behaviorLib.LaneItems = {"Item_BloodChalice", "Item_Marchers", "Item_Striders", "Item_Strength5"} --Item_Strength5 is Fortified Bracelet
behaviorLib.MidItems = {"Item_PortalKey", "Item_Immunity", "Item_FrostfieldPlate"} --Immunity is Shrunken Head
behaviorLib.LateItems = {"Item_SpellShards 3", "Item_SolsBulwark", "Item_DaemonicBreastplate", "Item_BehemothsHeart", "Item_Damage9"} --Item_Damage9 is doombringer


--[[ colors:
	red
	aqua == cyan
	gray
	navy
	teal
	blue
	lime
	black
	brown
	green
	olive
	white
	silver
	purple
	maroon
	yellow
	orange
	fuchsia == magenta
	invisible
--]]

BotEcho('finished loading accursed_main')
