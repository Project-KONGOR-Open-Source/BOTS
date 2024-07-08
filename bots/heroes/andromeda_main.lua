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

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false


object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

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

BotEcho('loading andromeda_main...')

object.heroName = 'Hero_Andromeda'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 4, ShortSolo = 1, LongSolo = 1, ShortSupport = 5, LongSupport = 5, ShortCarry = 3, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.comet = unitSelf:GetAbility(0)
		skills.aurora = unitSelf:GetAbility(1)
		skills.dimensionalLink = unitSelf:GetAbility(2)
		skills.voidRip = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.comet and skills.aurora and skills.dimensionalLink and skills.voidRip and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.dimensionalLink:GetLevel() >= 1) then
		skills.dimensionalLink:LevelUp()
	elseif not (skills.comet:GetLevel() >= 2) then
		skills.comet:LevelUp()
	elseif not (skills.aurora:GetLevel() >= 1) then
		skills.aurora:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.voidRip:CanLevelUp() then
		skills.voidRip:LevelUp()
	elseif skills.comet:CanLevelUp() then
		skills.comet:LevelUp()
	elseif skills.dimensionalLink:CanLevelUp() then
		skills.dimensionalLink:LevelUp()
	elseif skills.aurora:CanLevelUp() then
		skills.aurora:LevelUp()
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

object.cometUpBonus = 11
object.cometUseBonus = 11
object.cometUseThreshold = 37

object.auroraUpBonus = 15
object.auroraUseBonus = 3
object.auroraUseThreshold = 11

object.voidRipUpBonus = 55
object.voidRipUseBonus = 22
object.voidRipUseThreshold = 72

local function AbilitiesUpUtilityFn()
	local val = 0
	
	if skills.comet:CanActivate() then
		val = val + object.cometUpBonus
	end
	
	if skills.aurora:CanActivate() then
		val = val + object.auroraUpBonus
	end
	
	if skills.voidRip:CanActivate() then
		val = val + object.voidRipUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Andromeda1" then
			addBonus = addBonus + object.cometUseBonus
		elseif EventData.InflictorName == "Ability_Andromeda2" then
			addBonus = addBonus + object.auroraUseBonus
		elseif EventData.InflictorName == "Ability_Andromeda4" then
			addBonus = addBonus + object.voidRipUseBonus
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
		
		local dist = Vector3.Distance2D(vecMyPosition, vecTargetPosition)
		
		local abilVoidRip = skills.voidRip
		local abilAurora = skills.aurora
		local abilComet = skills.comet
		local abilVoidRipRange = abilVoidRip and abilVoidRip:GetRange() or 0
		local abilAuroraRange = abilAurora and abilAurora:GetRange() or 0
		local abilCometRange = abilComet and abilComet:GetRange() or 0
		
		if abilVoidRip and abilVoidRip:CanActivate() and not bActionTaken then
			if unitTarget:GetHealthPercent() < unitSelf:GetHealthPercent() and dist < abilVoidRipRange and unitSelf:GetMana() > 380 and nLastHarassUtility > botBrain.voidRipUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilVoidRip, unitTarget)
			end
		end
		
		if abilAurora and abilAurora:CanActivate() and not bActionTaken then
			if dist < abilAuroraRange and unitSelf:GetMana() > 170 and nLastHarassUtility > botBrain.auroraUseThreshold then
				local vecToward = Vector3.Normalize(vecTargetPosition - vecMyPosition)
				local vecAbilityTarget = vecMyPosition + vecToward * 250
				bActionTaken = core.OrderAbilityPosition(botBrain, abilAurora, vecAbilityTarget)
			end
		end
		
		if abilComet and abilComet:CanActivate() and not bActionTaken then
			if dist < abilCometRange and nLastHarassUtility > botBrain.voidRipUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilComet, unitTarget)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

behaviorLib.StartingItems = 
  {"Item_RunesOfTheBlight", "Item_ManaPotion", "Item_HealthPotion", "Item_DuckBoots"}
behaviorLib.LaneItems = 
  {"Item_Marchers",  "Item_Soulscream", "Item_EnhancedMarchers"}
behaviorLib.MidItems = 
  { "Item_Energizer", "Item_Lightning2", "Item_Critical1 4", "Item_SolsBulwark"}
behaviorLib.LateItems = 
  { "Item_Evasion", "Item_DaemonicBreastplate", "Item_Weapon3"}

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

BotEcho('finished loading arachna_main')
