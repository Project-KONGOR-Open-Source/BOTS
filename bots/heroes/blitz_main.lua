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

BotEcho('loading blitz_main...')

object.heroName = 'Hero_Blitz'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 3, ShortSolo = 4, LongSolo = 5, ShortSupport = 2, LongSupport = 3, ShortCarry = 3, LongCarry = 4}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.blitzkrieg = unitSelf:GetAbility(0)
		skills.pilfering = unitSelf:GetAbility(1)
		skills.quicken = unitSelf:GetAbility(2)
		skills.lightningShackles = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.blitzkrieg and skills.pilfering and skills.quicken and skills.lightningShackles and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.blitzkrieg:GetLevel() >= 1) then
		skills.blitzkrieg:LevelUp()
	elseif not (skills.pilfering:GetLevel() >= 2) then
		skills.pilfering:LevelUp()
	elseif not (skills.quicken:GetLevel() >= 1) then
		skills.quicken:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.lightningShackles:CanLevelUp() then
		skills.lightningShackles:LevelUp()
	elseif skills.blitzkrieg:CanLevelUp() then
		skills.blitzkrieg:LevelUp()
	elseif skills.pilfering:CanLevelUp() then
		skills.pilfering:LevelUp()
	elseif skills.quicken:CanLevelUp() then
		skills.quicken:LevelUp()
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

object.blitzkriegUpBonus = 10
object.blitzkriegUseBonus = 23
object.blitzkriegUseThreshold = 29

object.pilferingUpBonus = 13
object.pilferingUseBonus = 48
object.pilferingUseThreshold = 25

object.quickenUpBonus = 10
object.quickenUseBonus = 21
object.quickenUseThreshold = 11

object.lightningShacklesUpBonus = 50
object.lightningShacklesUseBonus = 68
object.lightningShacklesUseThreshold = 59

local function AbilitiesUpUtilityFn()
	local val = 0
	
	if skills.blitzkrieg:CanActivate() then
		val = val + object.blitzkriegUpBonus
	end
	
	if skills.pilfering:CanActivate() then
		val = val + object.pilferingUpBonus
	end
	
	if skills.quicken:CanActivate() then
		val = val + object.quickenUpBonus
	end
	
	if skills.lightningShackles:CanActivate() then
		val = val + object.lightningShacklesUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Blitz1" then
			addBonus = addBonus + object.blitzkriegUseBonus
		elseif EventData.InflictorName == "Ability_Blitz2" then
			addBonus = addBonus + object.pilferingUseBonus
		elseif EventData.InflictorName == "Ability_Blitz3" then
			addBonus = addBonus + object.quickenUseBonus
		elseif EventData.InflictorName == "Ability_Blitz4" then
			addBonus = addBonus + object.lightningShacklesUseBonus
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
		nUtility = nUtility + 6
	elseif unitSelf:GetHealthPercent() < .25 then
		nUtility = nUtility - 16
	elseif unitSelf:GetHealthPercent() < .5 then
		nUtility = nUtility - 10
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
		
		local abilBlitzkrieg = skills.blitzkrieg
		local abilPilfering = skills.pilfering
		local abilQuicken = skills.quicken
		local abilLightningShackles = skills.lightningShackles
		local abilBlitzkriegRange = abilBlitzkrieg and abilBlitzkrieg:GetRange() or 0
		local abilPilferingRange = abilPilfering and abilPilfering:GetRange() or 0
		local abilQuickenRange = abilQuicken and abilQuicken:GetRange() or 0
		local abilLightningShacklesRange = abilLightningShackles and abilLightningShackles:GetRange() or 0
		
		if abilLightningShackles and abilLightningShackles:CanActivate() and not bActionTaken then
			if dist < abilLightningShacklesRange and nLastHarassUtility > botBrain.lightningShacklesUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilLightningShackles, unitTarget)
			end
		end
		
		if abilQuicken and abilQuicken:CanActivate() and not bActionTaken then
			if unitSelf:GetMana() > 290 and nLastHarassUtility > botBrain.quickenUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilQuicken, unitSelf)
			end
		end
		
		if abilPilfering and abilPilfering:CanActivate() and not bActionTaken then
			if dist-50 < abilPilferingRange and nLastHarassUtility > botBrain.pilferingUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilPilfering, unitTarget)
			end
		end
		
		if abilBlitzkrieg and abilBlitzkrieg:CanActivate() and not bActionTaken then
			if dist < abilBlitzkriegRange and nLastHarassUtility > botBrain.blitzkriegUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilBlitzkrieg, unitTarget)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

--   item buy order.
behaviorLib.StartingItems  = {"2 Item_DuckBoots", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_HelmOfTheVictim", "Item_Steamboots"}
behaviorLib.MidItems  = {"Item_Sicarius", "Item_WhisperingHelm", "Item_Immunity"}
behaviorLib.LateItems  = {"Item_ManaBurn2", "Item_LifeSteal4", "Item_Evasion"}

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
